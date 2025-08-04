/**
 * Controller for CVMA Officer Dashboard
 * Provides member status tracking, renewal management, and communication tools
 * Restricted to users with appropriate officer permissions
 */
public with sharing class CVMAOfficerDashboardController {
    
    /**
     * Get comprehensive dashboard data including member statistics and member list
     */
    @AuraEnabled(cacheable=true)
    public static DashboardResponse getMemberDashboardData() {
        try {
            // Verify user has officer permissions
            if (!hasOfficerPermissions()) {
                throw new AuraHandledException('You do not have permission to access the officer dashboard.');
            }
            
            DashboardResponse response = new DashboardResponse();
            
            // Get all members with their status information
            List<Contact> members = [
                SELECT Id, FirstName, LastName, Email, Phone, MobilePhone,
                       Membership_Id__c, Level__c, Road_Name__c,
                       npo02__MembershipJoinDate__c, npo02__MembershipEndDate__c,
                       npo02__LastMembershipAmount__c, npo02__LastMembershipDate__c
                FROM Contact 
                WHERE Membership_Id__c != null 
                AND Level__c != null
                ORDER BY LastName, FirstName
            ];
            
            // Calculate dashboard statistics and process member data
            response.dashboardStats = calculateDashboardStats(members);
            response.members = processMemberData(members);
            
            return response;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error loading dashboard data: ' + e.getMessage());
        }
    }
    
    /**
     * Export member data to CSV format
     */
    @AuraEnabled
    public static String exportMemberData(List<Id> memberIds) {
        try {
            if (!hasOfficerPermissions()) {
                throw new AuraHandledException('You do not have permission to export member data.');
            }
            
            List<Contact> members = [
                SELECT Id, FirstName, LastName, Email, Phone, MobilePhone,
                       Membership_Id__c, Level__c, Road_Name__c,
                       npo02__MembershipJoinDate__c, npo02__MembershipEndDate__c,
                       MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
                FROM Contact 
                WHERE Id IN :memberIds
                ORDER BY LastName, FirstName
            ];
            
            return generateCSV(members);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error exporting member data: ' + e.getMessage());
        }
    }
    
    /**
     * Send renewal reminder emails to specified members
     */
    @AuraEnabled
    public static Integer sendRenewalReminders(List<Id> memberIds) {
        try {
            if (!hasOfficerPermissions()) {
                throw new AuraHandledException('You do not have permission to send renewal reminders.');
            }
            
            List<Contact> members = [
                SELECT Id, FirstName, LastName, Email, 
                       Membership_Id__c, Level__c,
                       npo02__MembershipEndDate__c
                FROM Contact 
                WHERE Id IN :memberIds
                AND Email != null
                AND npo02__MembershipEndDate__c != null
            ];
            
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            for (Contact member : members) {
                Messaging.SingleEmailMessage email = createRenewalReminderEmail(member);
                if (email != null) {
                    emails.add(email);
                }
            }
            
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }
            
            return emails.size();
            
        } catch (Exception e) {
            throw new AuraHandledException('Error sending renewal reminders: ' + e.getMessage());
        }
    }
    
    /**
     * Check if current user has officer permissions
     */
    private static Boolean hasOfficerPermissions() {
        // Check for custom permission or profile-based access
        // This can be customized based on CVMA's permission model
        
        // Option 1: Check for custom permission
        if (FeatureManagement.checkPermission('CVMA_Officer_Access')) {
            return true;
        }
        
        // Option 2: Check for specific profile names
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        Set<String> officerProfiles = new Set<String>{
            'System Administrator',
            'CVMA Officer',
            'Chapter President',
            'Chapter Vice President',
            'Chapter Secretary',
            'Chapter Treasurer'
        };
        
        if (officerProfiles.contains(profileName)) {
            return true;
        }
        
        // Option 3: Check for membership level (if officers are marked in Contact)
        try {
            Contact userContact = [
                SELECT Level__c, Road_Name__c
                FROM Contact 
                WHERE Id IN (SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId())
                LIMIT 1
            ];
            
            // Check if user has officer-level access based on custom logic
            if (userContact != null && isOfficerLevel(userContact)) {
                return true;
            }
        } catch (QueryException e) {
            // User might not have a contact record
        }
        
        return false;
    }
    
    /**
     * Determine if contact has officer-level privileges
     */
    private static Boolean isOfficerLevel(Contact contact) {
        // Customize this logic based on CVMA's officer identification method
        // This could be based on Level__c field, custom fields, or other criteria
        
        // Example: Check if Road_Name__c contains officer titles
        if (String.isNotBlank(contact.Road_Name__c)) {
            String roadName = contact.Road_Name__c.toLowerCase();
            return roadName.contains('president') || 
                   roadName.contains('vice') || 
                   roadName.contains('secretary') || 
                   roadName.contains('treasurer') ||
                   roadName.contains('officer');
        }
        
        return false;
    }
    
    /**
     * Calculate dashboard statistics from member data
     */
    private static DashboardStats calculateDashboardStats(List<Contact> members) {
        DashboardStats stats = new DashboardStats();
        Date today = Date.today();
        Date thirtyDaysFromNow = today.addDays(30);
        Date sixtyDaysFromNow = today.addDays(60);
        Date ninetyDaysFromNow = today.addDays(90);
        Date ninetyDaysAgo = today.addDays(-90);
        
        for (Contact member : members) {
            stats.totalMembers++;
            
            // Determine member status
            String status = getMemberStatus(member, today);
            
            if (status == 'Active') {
                stats.activeMembers++;
            } else if (status == 'Expired') {
                stats.expiredMembers++;
            }
            
            // Check renewal periods
            if (member.npo02__MembershipEndDate__c != null) {
                if (member.npo02__MembershipEndDate__c <= thirtyDaysFromNow && member.npo02__MembershipEndDate__c > today) {
                    stats.due30Days++;
                } else if (member.npo02__MembershipEndDate__c <= sixtyDaysFromNow && member.npo02__MembershipEndDate__c > today) {
                    stats.due60Days++;
                }
            }
            
            // Check for new members
            if (member.npo02__MembershipJoinDate__c != null && member.npo02__MembershipJoinDate__c >= ninetyDaysAgo) {
                stats.newMembers++;
            }
        }
        
        return stats;
    }
    
    /**
     * Process member data and add calculated fields
     */
    private static List<MemberData> processMemberData(List<Contact> members) {
        List<MemberData> memberDataList = new List<MemberData>();
        Date today = Date.today();
        
        for (Contact member : members) {
            MemberData memberData = new MemberData();
            memberData.contactId = member.Id;
            memberData.firstName = member.FirstName;
            memberData.lastName = member.LastName;
            memberData.email = member.Email;
            memberData.phone = member.Phone;
            memberData.mobilePhone = member.MobilePhone;
            memberData.membershipId = member.Membership_Id__c;
            memberData.level = member.Level__c;
            memberData.roadName = member.Road_Name__c;
            memberData.joinDate = member.npo02__MembershipJoinDate__c;
            memberData.endDate = member.npo02__MembershipEndDate__c;
            
            // Calculate status and days
            memberData.status = getMemberStatus(member, today);
            memberData.daysToRenewal = member.npo02__MembershipEndDate__c != null ? 
                today.daysBetween(member.npo02__MembershipEndDate__c) : null;
            memberData.daysSinceJoin = member.npo02__MembershipJoinDate__c != null ? 
                member.npo02__MembershipJoinDate__c.daysBetween(today) : null;
            
            memberDataList.add(memberData);
        }
        
        return memberDataList;
    }
    
    /**
     * Determine member status based on membership dates
     */
    private static String getMemberStatus(Contact member, Date today) {
        if (member.npo02__MembershipEndDate__c == null) {
            return 'Unknown';
        }
        
        if (member.npo02__MembershipEndDate__c < today) {
            return 'Expired';
        } else if (member.npo02__MembershipEndDate__c <= today.addDays(90)) {
            return 'Renewal Due';
        } else {
            return 'Active';
        }
    }
    
    /**
     * Generate CSV content from member data
     */
    private static String generateCSV(List<Contact> members) {
        List<String> csvLines = new List<String>();
        
        // CSV Header
        csvLines.add('First Name,Last Name,Email,Phone,Mobile,Membership ID,Level,Road Name,Join Date,End Date,Status,Street,City,State,Postal Code,Country');
        
        // CSV Data
        Date today = Date.today();
        for (Contact member : members) {
            List<String> fields = new List<String>();
            fields.add(escapeCsvField(member.FirstName));
            fields.add(escapeCsvField(member.LastName));
            fields.add(escapeCsvField(member.Email));
            fields.add(escapeCsvField(member.Phone));
            fields.add(escapeCsvField(member.MobilePhone));
            fields.add(escapeCsvField(member.Membership_Id__c));
            fields.add(escapeCsvField(member.Level__c));
            fields.add(escapeCsvField(member.Road_Name__c));
            fields.add(member.npo02__MembershipJoinDate__c != null ? String.valueOf(member.npo02__MembershipJoinDate__c) : '');
            fields.add(member.npo02__MembershipEndDate__c != null ? String.valueOf(member.npo02__MembershipEndDate__c) : '');
            fields.add(getMemberStatus(member, today));
            fields.add(escapeCsvField(member.MailingStreet));
            fields.add(escapeCsvField(member.MailingCity));
            fields.add(escapeCsvField(member.MailingState));
            fields.add(escapeCsvField(member.MailingPostalCode));
            fields.add(escapeCsvField(member.MailingCountry));
            
            csvLines.add(String.join(fields, ','));
        }
        
        return String.join(csvLines, '\n');
    }
    
    /**
     * Escape CSV field values
     */
    private static String escapeCsvField(String field) {
        if (String.isBlank(field)) {
            return '';
        }
        
        // Escape double quotes and wrap in quotes if contains comma, quote, or newline
        String escaped = field.replace('"', '""');
        if (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n')) {
            escaped = '"' + escaped + '"';
        }
        
        return escaped;
    }
    
    /**
     * Create renewal reminder email for a member
     */
    private static Messaging.SingleEmailMessage createRenewalReminderEmail(Contact member) {
        if (String.isBlank(member.Email)) {
            return null;
        }
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ member.Email });
        email.setSubject('CVMA Membership Renewal Reminder');
        
        // Create personalized email body
        String emailBody = buildRenewalEmailBody(member);
        email.setHtmlBody(emailBody);
        
        // Set sender (use organization-wide email address if available)
        email.setSenderDisplayName('CVMA Chapter 20-7');
        
        return email;
    }
    
    /**
     * Build HTML email body for renewal reminder
     */
    private static String buildRenewalEmailBody(Contact member) {
        String memberName = (member.FirstName + ' ' + member.LastName).trim();
        Integer daysToRenewal = member.npo02__MembershipEndDate__c != null ? 
            Date.today().daysBetween(member.npo02__MembershipEndDate__c) : 0;
        
        String emailBody = '<html><body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">';
        emailBody += '<div style="max-width: 600px; margin: 0 auto; padding: 20px;">';
        emailBody += '<h2 style="color: #1b5f9f; border-bottom: 2px solid #c41e3a; padding-bottom: 10px;">CVMA Chapter 20-7 Membership Renewal</h2>';
        emailBody += '<p>Dear ' + memberName + ',</p>';
        emailBody += '<p>This is a friendly reminder that your CVMA membership is due for renewal.</p>';
        emailBody += '<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #1b5f9f; margin: 20px 0;">';
        emailBody += '<strong>Membership Details:</strong><br>';
        emailBody += 'Member ID: ' + member.Membership_Id__c + '<br>';
        emailBody += 'Level: ' + member.Level__c + '<br>';
        emailBody += 'Renewal Due: ' + member.npo02__MembershipEndDate__c.format() + '<br>';
        emailBody += 'Days Remaining: ' + daysToRenewal + '</div>';
        emailBody += '<p>To renew your membership, please contact our chapter officers or visit our next chapter meeting.</p>';
        emailBody += '<p><strong>Contact Information:</strong><br>';
        emailBody += 'Email: chapter20-7@cvma.org<br>';
        emailBody += 'Phone: (904) 555-CVMA</p>';
        emailBody += '<p>Thank you for your continued support of CVMA Chapter 20-7 and our mission of Vets Serving Vets.</p>';
        emailBody += '<p>Ride Safe,<br><strong>CVMA Chapter 20-7 Officers</strong></p>';
        emailBody += '<hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">';
        emailBody += '<p style="font-size: 12px; color: #666;">Combat Veterans Motorcycle Association - Chapter 20-7<br>';
        emailBody += 'Jacksonville, Florida | Vets Serving Vets</p>';
        emailBody += '</div></body></html>';
        
        return emailBody;
    }
    
    /**
     * Data wrapper classes
     */
    public class DashboardResponse {
        @AuraEnabled public DashboardStats dashboardStats { get; set; }
        @AuraEnabled public List<MemberData> members { get; set; }
    }
    
    public class DashboardStats {
        @AuraEnabled public Integer totalMembers { get; set; }
        @AuraEnabled public Integer activeMembers { get; set; }
        @AuraEnabled public Integer due30Days { get; set; }
        @AuraEnabled public Integer due60Days { get; set; }
        @AuraEnabled public Integer expiredMembers { get; set; }
        @AuraEnabled public Integer newMembers { get; set; }
        
        public DashboardStats() {
            this.totalMembers = 0;
            this.activeMembers = 0;
            this.due30Days = 0;
            this.due60Days = 0;
            this.expiredMembers = 0;
            this.newMembers = 0;
        }
    }
    
    public class MemberData {
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String mobilePhone { get; set; }
        @AuraEnabled public String membershipId { get; set; }
        @AuraEnabled public String level { get; set; }
        @AuraEnabled public String roadName { get; set; }
        @AuraEnabled public Date joinDate { get; set; }
        @AuraEnabled public Date endDate { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Integer daysToRenewal { get; set; }
        @AuraEnabled public Integer daysSinceJoin { get; set; }
    }
}