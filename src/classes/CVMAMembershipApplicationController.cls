/**
 * Controller for CVMA Membership Application
 * Handles application submission, status tracking, and officer notifications
 */
public with sharing class CVMAMembershipApplicationController {
    
    /**
     * Submit a new membership application
     */
    @AuraEnabled
    public static ApplicationResponse submitMembershipApplication(String applicationData) {
        try {
            ApplicationResponse response = new ApplicationResponse();
            
            // Parse application data
            Map<String, Object> appData = (Map<String, Object>) JSON.deserializeUntyped(applicationData);
            
            // Validate required fields
            if (!validateApplicationData(appData)) {
                response.success = false;
                response.message = 'Please complete all required fields';
                return response;
            }
            
            // Check for duplicate applications
            String email = (String) appData.get('email');
            List<Contact> existingContacts = [
                SELECT Id, Email, Membership_Id__c
                FROM Contact 
                WHERE Email = :email 
                AND Membership_Id__c != null
                LIMIT 1
            ];
            
            if (!existingContacts.isEmpty()) {
                response.success = false;
                response.message = 'A membership application already exists for this email address';
                return response;
            }
            
            // Create application record
            Membership_Application__c application = createApplicationRecord(appData);
            insert application;
            
            // Create or update Contact record for the applicant
            Contact applicantContact = createApplicantContact(appData, application.Id);
            upsert applicantContact Email;
            
            // Update application with contact reference
            application.Applicant_Contact__c = applicantContact.Id;
            update application;
            
            // Send confirmation email to applicant
            sendConfirmationEmail(applicantContact, application);
            
            // Notify officers of new application
            notifyOfficersOfNewApplication(applicantContact, application);
            
            response.success = true;
            response.message = 'Application submitted successfully';
            response.applicationId = application.Id;
            
            return response;
            
        } catch (Exception e) {
            System.debug('Application submission error: ' + e.getMessage());
            ApplicationResponse response = new ApplicationResponse();
            response.success = false;
            response.message = 'Error submitting application: ' + e.getMessage();
            return response;
        }
    }
    
    /**
     * Check application status by email
     */
    @AuraEnabled(cacheable=true)
    public static ApplicationStatusResponse checkApplicationStatus(String email) {
        try {
            ApplicationStatusResponse response = new ApplicationStatusResponse();
            
            List<Membership_Application__c> applications = [
                SELECT Id, Name, Status__c, Submission_Date__c, 
                       Review_Notes__c, Reviewed_By__c, Review_Date__c,
                       Applicant_Contact__r.FirstName, Applicant_Contact__r.LastName
                FROM Membership_Application__c 
                WHERE Applicant_Email__c = :email
                ORDER BY Submission_Date__c DESC
                LIMIT 1
            ];
            
            if (applications.isEmpty()) {
                response.hasApplication = false;
                response.message = 'No application found for this email address';
            } else {
                response.hasApplication = true;
                response.application = mapApplicationData(applications[0]);
            }
        
            return response;
            
        } catch (Exception e) {
            ApplicationStatusResponse response = new ApplicationStatusResponse();
            response.hasApplication = false;
            response.message = 'Error checking application status: ' + e.getMessage();
            return response;
        }
    }
    
    /**
     * Get pending applications for officer review
     */
    @AuraEnabled(cacheable=true)
    public static List<ApplicationData> getPendingApplications() {
        try {
            // Verify officer permissions
            if (!hasOfficerPermissions()) {
                throw new AuraHandledException('You do not have permission to view pending applications.');
            }
            
            List<Membership_Application__c> applications = [
                SELECT Id, Name, Status__c, Submission_Date__c,
                       First_Name__c, Last_Name__c, Applicant_Email__c,
                       Service_Branch__c, Service_Status__c, Membership_Level__c,
                       Combat_Veteran__c, Applicant_Contact__r.Phone
                FROM Membership_Application__c 
                WHERE Status__c = 'Pending Review'
                ORDER BY Submission_Date__c ASC
            ];
            
            List<ApplicationData> applicationList = new List<ApplicationData>();
            for (Membership_Application__c app : applications) {
                applicationList.add(mapApplicationData(app));
            }
            
            return applicationList;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error loading pending applications: ' + e.getMessage());
        }
    }
    
    /**
     * Update application status (for officers)
     */
    @AuraEnabled
    public static String updateApplicationStatus(Id applicationId, String newStatus, String reviewNotes) {
        try {
            if (!hasOfficerPermissions()) {
                throw new AuraHandledException('You do not have permission to update application status.');
            }
            
            Membership_Application__c application = [
                SELECT Id, Status__c, Applicant_Contact__c, 
                       Applicant_Contact__r.Email, Applicant_Contact__r.FirstName, 
                       Applicant_Contact__r.LastName
                FROM Membership_Application__c 
                WHERE Id = :applicationId 
                LIMIT 1
            ];
            
            application.Status__c = newStatus;
            application.Review_Notes__c = reviewNotes;
            application.Reviewed_By__c = UserInfo.getUserId();
            application.Review_Date__c = DateTime.now();
            
            update application;
            
            // If approved, create member record
            if (newStatus == 'Approved') {
                createMemberRecord(application);
            }
            
            // Send status update email to applicant
            sendStatusUpdateEmail(application, newStatus, reviewNotes);
            
            return 'Application status updated successfully';
            
        } catch (Exception e) {
            throw new AuraHandledException('Error updating application status: ' + e.getMessage());
        }
    }
    
    /**
     * Validate application data completeness
     */
    private static Boolean validateApplicationData(Map<String, Object> appData) {
        List<String> requiredFields = new List<String>{
            'firstName', 'lastName', 'email', 'phone', 'mailingAddress',
            'city', 'state', 'postalCode', 'dateOfBirth',
            'serviceStatus', 'servicesBranch', 'serviceStartDate',
            'emergencyContactName', 'emergencyContactPhone', 'membershipLevel'
        };
        
        for (String field : requiredFields) {
            if (!appData.containsKey(field) || 
                String.isBlank(String.valueOf(appData.get(field)))) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Create membership application record
     */
    private static Membership_Application__c createApplicationRecord(Map<String, Object> appData) {
        Membership_Application__c application = new Membership_Application__c();
        
        // Personal Information
        application.First_Name__c = (String) appData.get('firstName');
        application.Last_Name__c = (String) appData.get('lastName');
        application.Applicant_Email__c = (String) appData.get('email');
        application.Phone__c = (String) appData.get('phone');
        application.Mailing_Address__c = (String) appData.get('mailingAddress');
        application.City__c = (String) appData.get('city');
        application.State__c = (String) appData.get('state');
        application.Postal_Code__c = (String) appData.get('postalCode');
        application.Date_of_Birth__c = Date.valueOf((String) appData.get('dateOfBirth'));
        application.Road_Name__c = (String) appData.get('roadName');
        
        // Military Service
        application.Service_Status__c = (String) appData.get('serviceStatus');
        application.Service_Branch__c = (String) appData.get('servicesBranch');
        application.Military_Occupation__c = (String) appData.get('militaryOccupation');
        application.Service_Start_Date__c = Date.valueOf((String) appData.get('serviceStartDate'));
        
        if (appData.containsKey('serviceEndDate') && 
            String.isNotBlank((String) appData.get('serviceEndDate'))) {
            application.Service_End_Date__c = Date.valueOf((String) appData.get('serviceEndDate'));
        }
        
        application.Deployments__c = (String) appData.get('deployments');
        application.Awards__c = (String) appData.get('awards');
        application.Combat_Veteran__c = (Boolean) appData.get('isCombatVeteran');
        
        // Emergency Contact
        application.Emergency_Contact_Name__c = (String) appData.get('emergencyContactName');
        application.Emergency_Contact_Relationship__c = (String) appData.get('emergencyContactRelationship');
        application.Emergency_Contact_Phone__c = (String) appData.get('emergencyContactPhone');
        application.Emergency_Contact_Email__c = (String) appData.get('emergencyContactEmail');
        
        // Application Details
        application.Membership_Level__c = (String) appData.get('membershipLevel');
        application.Status__c = 'Pending Review';
        application.Submission_Date__c = DateTime.now();
        
        return application;
    }
    
    /**
     * Create or update applicant contact record
     */
    private static Contact createApplicantContact(Map<String, Object> appData, Id applicationId) {
        Contact contact = new Contact();
        
        contact.FirstName = (String) appData.get('firstName');
        contact.LastName = (String) appData.get('lastName');
        contact.Email = (String) appData.get('email');
        contact.Phone = (String) appData.get('phone');
        contact.MailingStreet = (String) appData.get('mailingAddress');
        contact.MailingCity = (String) appData.get('city');
        contact.MailingState = (String) appData.get('state');
        contact.MailingPostalCode = (String) appData.get('postalCode');
        contact.Birthdate = Date.valueOf((String) appData.get('dateOfBirth'));
        contact.Road_Name__c = (String) appData.get('roadName');
        contact.Level__c = 'Applicant';
        
        // Link to application
        contact.Application_Reference__c = applicationId;
        
        return contact;
    }
    
    /**
     * Create member record upon approval
     */
    private static void createMemberRecord(Membership_Application__c application) {
        Contact contact = application.Applicant_Contact__r;
        
        // Update contact to member status
        contact.Level__c = application.Membership_Level__c;
        contact.Membership_Id__c = generateMembershipId();
        contact.npo02__MembershipJoinDate__c = Date.today();
        contact.npo02__MembershipEndDate__c = Date.today().addYears(1);
        
        update contact;
    }
    
    /**
     * Generate unique membership ID
     */
    private static String generateMembershipId() {
        // Get the next membership number for Full Members (FM prefix)
        List<Contact> existingMembers = [
            SELECT Membership_Id__c 
            FROM Contact 
            WHERE Membership_Id__c LIKE 'FM%'
            ORDER BY Membership_Id__c DESC 
            LIMIT 1
        ];
        
        Integer nextNumber = 1;
        if (!existingMembers.isEmpty()) {
            String lastId = existingMembers[0].Membership_Id__c;
            String numberPart = lastId.substring(2); // Remove 'FM' prefix
            nextNumber = Integer.valueOf(numberPart) + 1;
        }
        
        return 'FM' + String.valueOf(nextNumber).leftPad(3, '0');
    }
    
    /**
     * Send confirmation email to applicant
     */
    private static void sendConfirmationEmail(Contact applicant, Membership_Application__c application) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ applicant.Email });
            email.setSubject('CVMA Chapter 20-7 - Application Received');
            
            String emailBody = buildConfirmationEmailBody(applicant, application);
            email.setHtmlBody(emailBody);
            email.setSenderDisplayName('CVMA Chapter 20-7');
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            
        } catch (Exception e) {
            System.debug('Error sending confirmation email: ' + e.getMessage());
        }
    }
    
    /**
     * Build confirmation email HTML body
     */
    private static String buildConfirmationEmailBody(Contact applicant, Membership_Application__c application) {
        String emailBody = '<html><body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">';
        emailBody += '<div style="max-width: 600px; margin: 0 auto; padding: 20px;">';
        emailBody += '<h2 style="color: #1b5f9f; border-bottom: 2px solid #c41e3a; padding-bottom: 10px;">Application Received</h2>';
        emailBody += '<p>Dear ' + applicant.FirstName + ' ' + applicant.LastName + ',</p>';
        emailBody += '<p>Thank you for your interest in joining CVMA Chapter 20-7. We have received your membership application and it is currently under review.</p>';
        emailBody += '<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #1b5f9f; margin: 20px 0;">';
        emailBody += '<strong>Application Details:</strong><br>';
        emailBody += 'Application ID: ' + application.Name + '<br>';
        emailBody += 'Submission Date: ' + application.Submission_Date__c.format() + '<br>';
        emailBody += 'Status: ' + application.Status__c + '</div>';
        emailBody += '<p>Our chapter officers will review your application and contact you within 7-10 business days. ';
        emailBody += 'You may be invited to attend a chapter meeting as part of the review process.</p>';
        emailBody += '<p><strong>What happens next?</strong></p>';
        emailBody += '<ul><li>Application review by chapter officers</li>';
        emailBody += '<li>Background verification</li>';
        emailBody += '<li>Invitation to chapter meeting (if approved)</li>';
        emailBody += '<li>Welcome and membership materials</li></ul>';
        emailBody += '<p>If you have any questions, please contact us at chapter20-7@cvma.org or (904) 555-CVMA.</p>';
        emailBody += '<p>Vets Serving Vets,<br><strong>CVMA Chapter 20-7</strong></p>';
        emailBody += '<hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">';
        emailBody += '<p style="font-size: 12px; color: #666;">Combat Veterans Motorcycle Association - Chapter 20-7<br>';
        emailBody += 'Jacksonville, Florida</p>';
        emailBody += '</div></body></html>';
        
        return emailBody;
    }
    
    /**
     * Send status update email to applicant
     */
    private static void sendStatusUpdateEmail(Membership_Application__c application, String status, String notes) {
        try {
            if (application.Applicant_Contact__r.Email == null) return;
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ application.Applicant_Contact__r.Email });
            email.setSubject('CVMA Chapter 20-7 - Application Status Update');
            
            String emailBody = buildStatusUpdateEmailBody(application, status, notes);
            email.setHtmlBody(emailBody);
            email.setSenderDisplayName('CVMA Chapter 20-7');
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            
        } catch (Exception e) {
            System.debug('Error sending status update email: ' + e.getMessage());
        }
    }
    
    /**
     * Build status update email body
     */
    private static String buildStatusUpdateEmailBody(Membership_Application__c application, String status, String notes) {
        String applicantName = application.Applicant_Contact__r.FirstName + ' ' + application.Applicant_Contact__r.LastName;
        String statusColor = status == 'Approved' ? '#2e844a' : (status == 'Rejected' ? '#c23934' : '#1b5f9f');
        
        String emailBody = '<html><body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">';
        emailBody += '<div style="max-width: 600px; margin: 0 auto; padding: 20px;">';
        emailBody += '<h2 style="color: #1b5f9f; border-bottom: 2px solid #c41e3a; padding-bottom: 10px;">Application Status Update</h2>';
        emailBody += '<p>Dear ' + applicantName + ',</p>';
        emailBody += '<p>We have an update regarding your CVMA Chapter 20-7 membership application.</p>';
        emailBody += '<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid ' + statusColor + '; margin: 20px 0;">';
        emailBody += '<strong>Status:</strong> <span style="color: ' + statusColor + '; font-weight: bold;">' + status + '</span><br>';
        emailBody += '<strong>Application ID:</strong> ' + application.Name + '</div>';
        
        if (String.isNotBlank(notes)) {
            emailBody += '<div style="background-color: #fff; padding: 15px; border: 1px solid #ddd; margin: 20px 0;">';
            emailBody += '<strong>Review Notes:</strong><br>' + notes + '</div>';
        }
        
        if (status == 'Approved') {
            emailBody += '<p><strong>Congratulations!</strong> Your application has been approved. Welcome to CVMA Chapter 20-7!</p>';
            emailBody += '<p>You will receive additional information about your membership, including your membership number and materials, within the next few days.</p>';
        } else if (status == 'Rejected') {
            emailBody += '<p>We regret to inform you that your application was not approved at this time. ';
            emailBody += 'You may reapply in the future if your circumstances change.</p>';
        } else {
            emailBody += '<p>Your application is still under review. We will contact you if we need any additional information.</p>';
        }
        
        emailBody += '<p>If you have any questions, please contact us at chapter20-7@cvma.org or (904) 555-CVMA.</p>';
        emailBody += '<p>Vets Serving Vets,<br><strong>CVMA Chapter 20-7</strong></p>';
        emailBody += '</div></body></html>';
        
        return emailBody;
    }
    
    /**
     * Notify officers of new application
     */
    private static void notifyOfficersOfNewApplication(Contact applicant, Membership_Application__c application) {
        try {
            // Get officer email addresses
            List<String> officerEmails = getOfficerEmailAddresses();
            
            if (!officerEmails.isEmpty()) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(officerEmails);
                email.setSubject('New CVMA Membership Application - ' + applicant.FirstName + ' ' + applicant.LastName);
                
                String emailBody = buildOfficerNotificationEmailBody(applicant, application);
                email.setHtmlBody(emailBody);
                email.setSenderDisplayName('CVMA Application System');
                
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            }
            
        } catch (Exception e) {
            System.debug('Error sending officer notification: ' + e.getMessage());
        }
    }
    
    /**
     * Get officer email addresses for notifications
     */
    private static List<String> getOfficerEmailAddresses() {
        List<String> emails = new List<String>();
        
        // Get users with officer profiles
        List<User> officers = [
            SELECT Email 
            FROM User 
            WHERE Profile.Name IN ('CVMA Officer', 'Chapter President', 'Chapter Vice President', 'Chapter Secretary', 'Chapter Treasurer')
            AND IsActive = true
            AND Email != null
        ];
        
        for (User officer : officers) {
            emails.add(officer.Email);
        }
        
        // If no specific officer profiles, get admin users
        if (emails.isEmpty()) {
            List<User> admins = [
                SELECT Email 
                FROM User 
                WHERE Profile.Name = 'System Administrator'
                AND IsActive = true
                AND Email != null
                LIMIT 5
            ];
            
            for (User admin : admins) {
                emails.add(admin.Email);
            }
        }
        
        return emails;
    }
    
    /**
     * Build officer notification email body
     */
    private static String buildOfficerNotificationEmailBody(Contact applicant, Membership_Application__c application) {
        String emailBody = '<html><body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">';
        emailBody += '<div style="max-width: 600px; margin: 0 auto; padding: 20px;">';
        emailBody += '<h2 style="color: #1b5f9f; border-bottom: 2px solid #c41e3a; padding-bottom: 10px;">New Membership Application</h2>';
        emailBody += '<p>A new membership application has been submitted and requires officer review.</p>';
        emailBody += '<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #1b5f9f; margin: 20px 0;">';
        emailBody += '<strong>Applicant:</strong> ' + applicant.FirstName + ' ' + applicant.LastName + '<br>';
        emailBody += '<strong>Email:</strong> ' + applicant.Email + '<br>';
        emailBody += '<strong>Phone:</strong> ' + applicant.Phone + '<br>';
        emailBody += '<strong>Service Branch:</strong> ' + application.Service_Branch__c + '<br>';
        emailBody += '<strong>Service Status:</strong> ' + application.Service_Status__c + '<br>';
        emailBody += '<strong>Desired Level:</strong> ' + application.Membership_Level__c + '<br>';
        emailBody += '<strong>Combat Veteran:</strong> ' + (application.Combat_Veteran__c ? 'Yes' : 'No') + '<br>';
        emailBody += '<strong>Application ID:</strong> ' + application.Name + '</div>';
        emailBody += '<p>Please log in to the CVMA system to review this application and make a decision.</p>';
        emailBody += '<p><strong>Next Steps:</strong></p>';
        emailBody += '<ul><li>Review application details</li>';
        emailBody += '<li>Verify military service</li>';
        emailBody += '<li>Make approval/rejection decision</li>';
        emailBody += '<li>Applicant will be notified automatically</li></ul>';
        emailBody += '</div></body></html>';
        
        return emailBody;
    }
    
    /**
     * Check if current user has officer permissions
     */
    private static Boolean hasOfficerPermissions() {
        // Use same logic as Officer Dashboard
        try {
            // Check for custom permission
            if (FeatureManagement.checkPermission('CVMA_Officer_Access')) {
                return true;
            }
            
            // Check for officer profiles
            String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
            Set<String> officerProfiles = new Set<String>{
                'System Administrator',
                'CVMA Officer',
                'Chapter President',
                'Chapter Vice President',
                'Chapter Secretary',
                'Chapter Treasurer'
            };
            
            return officerProfiles.contains(profileName);
            
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Map application record to data transfer object
     */
    private static ApplicationData mapApplicationData(Membership_Application__c app) {
        ApplicationData data = new ApplicationData();
        data.applicationId = app.Id;
        data.applicationNumber = app.Name;
        data.firstName = app.First_Name__c;
        data.lastName = app.Last_Name__c;
        data.email = app.Applicant_Email__c;
        data.phone = app.Phone__c;
        data.serviceBranch = app.Service_Branch__c;
        data.serviceStatus = app.Service_Status__c;
        data.membershipLevel = app.Membership_Level__c;
        data.combatVeteran = app.Combat_Veteran__c;
        data.status = app.Status__c;
        data.submissionDate = app.Submission_Date__c;
        data.reviewNotes = app.Review_Notes__c;
        data.reviewDate = app.Review_Date__c;
        
        return data;
    }
    
    /**
     * Data wrapper classes
     */
    public class ApplicationResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Id applicationId { get; set; }
        
        public ApplicationResponse() {
            this.success = false;
        }
    }
    
    public class ApplicationStatusResponse {
        @AuraEnabled public Boolean hasApplication { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public ApplicationData application { get; set; }
        
        public ApplicationStatusResponse() {
            this.hasApplication = false;
        }
    }
    
    public class ApplicationData {
        @AuraEnabled public Id applicationId { get; set; }
        @AuraEnabled public String applicationNumber { get; set; }
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String serviceBranch { get; set; }
        @AuraEnabled public String serviceStatus { get; set; }
        @AuraEnabled public String membershipLevel { get; set; }
        @AuraEnabled public Boolean combatVeteran { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public DateTime submissionDate { get; set; }
        @AuraEnabled public String reviewNotes { get; set; }
        @AuraEnabled public DateTime reviewDate { get; set; }
    }
}