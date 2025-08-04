/**
 * Optimized Officer Dashboard Controller with enhanced security and performance
 * Implements Salesforce best practices for bulk operations, query optimization, and error handling
 * Version 2.0 - Enhanced with pagination, caching, and comprehensive security
 */
public with sharing class CVMAOfficerDashboardControllerOptimized {
    
    // Class constants
    private static final String CLASS_NAME = 'CVMAOfficerDashboardControllerOptimized';
    private static final Integer DEFAULT_PAGE_SIZE = 50;
    private static final Integer MAX_PAGE_SIZE = 200;
    private static final Integer EMAIL_BATCH_SIZE = 10; // Salesforce email limit per transaction
    
    // Cache for permission checks to avoid repeated SOQL
    private static Boolean cachedOfficerPermission = null;
    
    /**
     * Get member dashboard data with pagination and optimized queries
     */
    @AuraEnabled
    public static DashboardResponse getMemberDashboardData(Integer pageSize, Integer offset) {
        final String METHOD_NAME = 'getMemberDashboardData';
        
        try {
            // Validate officer permissions
            if (!hasOfficerPermissions()) {
                throw new CVMAErrorHandler.SecurityException('Insufficient permissions to access officer dashboard');
            }
            
            // Validate and sanitize pagination parameters
            pageSize = (pageSize == null || pageSize <= 0) ? DEFAULT_PAGE_SIZE : Math.min(pageSize, MAX_PAGE_SIZE);
            offset = (offset == null || offset < 0) ? 0 : offset;
            
            // Validate CRUD permissions
            List<String> contactFields = new List<String>{
                'FirstName', 'LastName', 'Email', 'Phone', 'MobilePhone',
                'Membership_Id__c', 'Level__c', 'Road_Name__c'
            };
            CVMAErrorHandler.validateCRUDPermissions(Contact.SObjectType, contactFields, 'read');
            
            DashboardResponse response = new DashboardResponse();
            
            // Get dashboard statistics (optimized with aggregate queries)
            response.dashboardStats = getDashboardStatistics();
            
            // Get paginated member data with security enforcement
            response.members = getPaginatedMembers(pageSize, offset);
            response.totalRecords = getTotalMemberCount();
            response.pageSize = pageSize;
            response.offset = offset;
            response.hasMore = (offset + pageSize) < response.totalRecords;
            
            return response;
            
        } catch (Exception ex) {
            Map<String, Object> context = new Map<String, Object>{
                'pageSize' => pageSize,
                'offset' => offset,
                'userId' => UserInfo.getUserId()
            };
            String errorMessage = CVMAErrorHandler.handleException(
                ex, CLASS_NAME, METHOD_NAME, CVMAErrorHandler.Severity.MEDIUM,
                CVMAErrorHandler.Category.SECURITY, context
            );
            throw new AuraHandledException(errorMessage);
        }
    }
    
    /**
     * Get dashboard statistics using optimized aggregate queries
     */
    private static DashboardStats getDashboardStatistics() {
        DashboardStats stats = new DashboardStats();
        
        try {
            // Get total members count
            List<AggregateResult> totalResults = [
                SELECT COUNT(Id) totalCount
                FROM Contact 
                WHERE Membership_Id__c != null 
                AND Level__c != null
                WITH SECURITY_ENFORCED
            ];
            stats.totalMembers = totalResults.isEmpty() ? 0 : (Integer) totalResults[0].get('totalCount');
            
            // Get members due for renewal in 30 days
            List<AggregateResult> dueResults = [
                SELECT COUNT(Id) dueCount
                FROM Contact 
                WHERE Membership_Id__c != null 
                AND Level__c != null
                AND npo02__MembershipEndDate__c >= :Date.today()
                AND npo02__MembershipEndDate__c <= :Date.today().addDays(30)
                WITH SECURITY_ENFORCED
            ];
            stats.due30Days = dueResults.isEmpty() ? 0 : (Integer) dueResults[0].get('dueCount');
            
            // Get expired members
            List<AggregateResult> expiredResults = [
                SELECT COUNT(Id) expiredCount
                FROM Contact 
                WHERE Membership_Id__c != null 
                AND Level__c != null
                AND npo02__MembershipEndDate__c < :Date.today()
                WITH SECURITY_ENFORCED
            ];
            stats.expiredMembers = expiredResults.isEmpty() ? 0 : (Integer) expiredResults[0].get('expiredCount');
            
            // Get new members from last 30 days
            List<AggregateResult> newResults = [
                SELECT COUNT(Id) newCount
                FROM Contact 
                WHERE Membership_Id__c != null 
                AND Level__c != null
                AND npo02__MembershipJoinDate__c >= :Date.today().addDays(-30)
                WITH SECURITY_ENFORCED
            ];
            stats.newMembers = newResults.isEmpty() ? 0 : (Integer) newResults[0].get('newCount');
            
        } catch (Exception ex) {
            // Log error but don't fail the entire operation
            CVMAErrorHandler.logError(ex, CLASS_NAME, 'getDashboardStatistics', 
                CVMAErrorHandler.Severity.LOW, CVMAErrorHandler.Category.PERFORMANCE);
            
            // Return default stats if query fails
            stats.totalMembers = 0;
            stats.due30Days = 0;
            stats.expiredMembers = 0;
            stats.newMembers = 0;
        }
        
        return stats;
    }
    
    /**
     * Get paginated member data with optimized query
     */
    private static List<MemberData> getPaginatedMembers(Integer pageSize, Integer offset) {
        List<MemberData> memberList = new List<MemberData>();
        
        try {
            List<Contact> members = [
                SELECT Id, FirstName, LastName, Email, Phone, MobilePhone,
                       Membership_Id__c, Level__c, Road_Name__c, Birthdate,
                       npo02__MembershipJoinDate__c, npo02__MembershipEndDate__c,
                       npo02__LastMembershipAmount__c, npo02__LastMembershipDate__c,
                       CreatedDate, LastModifiedDate
                FROM Contact 
                WHERE Membership_Id__c != null 
                AND Level__c != null
                WITH SECURITY_ENFORCED
                ORDER BY LastName, FirstName
                LIMIT :pageSize
                OFFSET :offset
            ];
            
            for (Contact member : members) {
                MemberData memberData = new MemberData();
                memberData.contactId = member.Id;
                memberData.firstName = CVMAErrorHandler.sanitizeInput(member.FirstName);
                memberData.lastName = CVMAErrorHandler.sanitizeInput(member.LastName);
                memberData.email = member.Email;
                memberData.phone = member.Phone;
                memberData.mobilePhone = member.MobilePhone;
                memberData.membershipId = member.Membership_Id__c;
                memberData.level = CVMAErrorHandler.sanitizeInput(member.Level__c);
                memberData.roadName = CVMAErrorHandler.sanitizeInput(member.Road_Name__c);
                memberData.joinDate = member.npo02__MembershipJoinDate__c;
                memberData.expirationDate = member.npo02__MembershipEndDate__c;
                memberData.lastPaymentAmount = member.npo02__LastMembershipAmount__c;
                memberData.lastPaymentDate = member.npo02__LastMembershipDate__c;
                
                // Calculate status efficiently
                memberData.status = calculateMemberStatus(member.npo02__MembershipEndDate__c);
                memberData.daysTillExpiration = calculateDaysTillExpiration(member.npo02__MembershipEndDate__c);
                
                memberList.add(memberData);
            }
            
        } catch (Exception ex) {
            CVMAErrorHandler.logError(ex, CLASS_NAME, 'getPaginatedMembers', 
                CVMAErrorHandler.Severity.MEDIUM, CVMAErrorHandler.Category.PERFORMANCE);
            throw ex;
        }
        
        return memberList;
    }
    
    /**
     * Get total member count for pagination
     */
    private static Integer getTotalMemberCount() {
        try {
            List<AggregateResult> results = [
                SELECT COUNT(Id) totalCount
                FROM Contact 
                WHERE Membership_Id__c != null 
                AND Level__c != null
                WITH SECURITY_ENFORCED
            ];
            
            return results.isEmpty() ? 0 : (Integer) results[0].get('totalCount');
            
        } catch (Exception ex) {
            CVMAErrorHandler.logError(ex, CLASS_NAME, 'getTotalMemberCount', 
                CVMAErrorHandler.Severity.LOW, CVMAErrorHandler.Category.PERFORMANCE);
            return 0;
        }
    }
    
    /**
     * Export member data with improved CSV handling and bulk operations
     */
    @AuraEnabled
    public static String exportMemberData(List<Id> memberIds, String exportFormat) {
        final String METHOD_NAME = 'exportMemberData';
        
        try {
            // Validate officer permissions
            if (!hasOfficerPermissions()) {
                throw new CVMAErrorHandler.SecurityException('Insufficient permissions to export member data');
            }
            
            // Validate input parameters
            if (memberIds == null || memberIds.isEmpty()) {
                throw new CVMAErrorHandler.ValidationException('No members selected for export');
            }
            
            if (memberIds.size() > 10000) {
                throw new CVMAErrorHandler.ValidationException('Export limited to 10,000 records');
            }
            
            // Sanitize export format
            exportFormat = String.isBlank(exportFormat) ? 'CSV' : exportFormat.toUpperCase();
            if (exportFormat != 'CSV') {
                throw new CVMAErrorHandler.ValidationException('Only CSV export format is currently supported');
            }
            
            // Validate CRUD permissions
            List<String> exportFields = new List<String>{
                'FirstName', 'LastName', 'Email', 'Phone', 'MobilePhone',
                'Membership_Id__c', 'Level__c', 'Road_Name__c'
            };
            CVMAErrorHandler.validateCRUDPermissions(Contact.SObjectType, exportFields, 'read');
            
            // Query member data with security enforcement
            List<Contact> members = [
                SELECT FirstName, LastName, Email, Phone, MobilePhone,
                       Membership_Id__c, Level__c, Road_Name__c,
                       npo02__MembershipJoinDate__c, npo02__MembershipEndDate__c,
                       MailingStreet, MailingCity, MailingState, MailingPostalCode
                FROM Contact 
                WHERE Id IN :memberIds 
                WITH SECURITY_ENFORCED
                ORDER BY LastName, FirstName
            ];
            
            return generateCSVData(members);
            
        } catch (Exception ex) {
            Map<String, Object> context = new Map<String, Object>{
                'memberIdsCount' => memberIds?.size(),
                'exportFormat' => exportFormat
            };
            String errorMessage = CVMAErrorHandler.handleException(
                ex, CLASS_NAME, METHOD_NAME, CVMAErrorHandler.Severity.MEDIUM,
                CVMAErrorHandler.Category.BUSINESS_LOGIC, context
            );
            throw new AuraHandledException(errorMessage);
        }
    }
    
    /**
     * Send renewal reminders with bulk email handling and governor limit protection
     */
    @AuraEnabled
    public static Integer sendRenewalReminders(List<Id> memberIds) {
        final String METHOD_NAME = 'sendRenewalReminders';
        
        try {
            // Validate officer permissions
            if (!hasOfficerPermissions()) {
                throw new CVMAErrorHandler.SecurityException('Insufficient permissions to send renewal reminders');
            }
            
            if (memberIds == null || memberIds.isEmpty()) {
                throw new CVMAErrorHandler.ValidationException('No members selected for renewal reminders');
            }
            
            // Protect against email governor limits
            if (memberIds.size() > EMAIL_BATCH_SIZE) {
                throw new CVMAErrorHandler.ValidationException(
                    'Cannot send more than ' + EMAIL_BATCH_SIZE + ' emails in a single request. Please process in smaller batches.'
                );
            }
            
            // Get member data for email
            List<Contact> members = [
                SELECT Id, FirstName, LastName, Email, Membership_Id__c, Level__c,
                       npo02__MembershipEndDate__c
                FROM Contact 
                WHERE Id IN :memberIds 
                AND Email != null
                AND npo02__MembershipEndDate__c != null
                WITH SECURITY_ENFORCED
            ];
            
            if (members.isEmpty()) {
                throw new CVMAErrorHandler.ValidationException('No valid members found with email addresses');
            }
            
            return sendBulkRenewalEmails(members);
            
        } catch (Exception ex) {
            Map<String, Object> context = new Map<String, Object>{
                'memberIdsCount' => memberIds?.size()
            };
            String errorMessage = CVMAErrorHandler.handleException(
                ex, CLASS_NAME, METHOD_NAME, CVMAErrorHandler.Severity.MEDIUM,
                CVMAErrorHandler.Category.INTEGRATION, context
            );
            throw new AuraHandledException(errorMessage);
        }
    }
    
    /**
     * Enhanced permission checking with caching
     */
    private static Boolean hasOfficerPermissions() {
        if (cachedOfficerPermission != null) {
            return cachedOfficerPermission;
        }
        
        try {
            // Check for custom permission first
            if (FeatureManagement.checkPermission('CVMA_Officer_Access')) {
                cachedOfficerPermission = true;
                return true;
            }
            
            // Check for officer profiles
            List<User> currentUser = [
                SELECT Profile.Name 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (currentUser.isEmpty()) {
                cachedOfficerPermission = false;
                return false;
            }
            
            Set<String> officerProfiles = new Set<String>{
                'System Administrator',
                'CVMA Officer',
                'Chapter President',
                'Chapter Vice President',
                'Chapter Secretary',
                'Chapter Treasurer'
            };
            
            cachedOfficerPermission = officerProfiles.contains(currentUser[0].Profile.Name);
            return cachedOfficerPermission;
            
        } catch (Exception ex) {
            CVMAErrorHandler.logError(ex, CLASS_NAME, 'hasOfficerPermissions', 
                CVMAErrorHandler.Severity.HIGH, CVMAErrorHandler.Category.SECURITY);
            cachedOfficerPermission = false;
            return false;
        }
    }
    
    /**
     * Helper method to calculate member status efficiently
     */
    private static String calculateMemberStatus(Date expirationDate) {
        if (expirationDate == null) {
            return 'Unknown';
        }
        
        Date today = Date.today();
        if (expirationDate < today) {
            return 'Expired';
        } else if (expirationDate <= today.addDays(30)) {
            return 'Renewal Due';
        } else {
            return 'Active';
        }
    }
    
    /**
     * Helper method to calculate days till expiration
     */
    private static Integer calculateDaysTillExpiration(Date expirationDate) {
        if (expirationDate == null) {
            return null;
        }
        
        return Date.today().daysBetween(expirationDate);
    }
    
    /**
     * Generate CSV data with proper escaping and formatting
     */
    private static String generateCSVData(List<Contact> members) {
        List<String> csvLines = new List<String>();
        
        // CSV Header
        csvLines.add('First Name,Last Name,Email,Phone,Mobile Phone,Membership ID,Level,Road Name,Join Date,Expiration Date,Mailing Address');
        
        // CSV Data with proper escaping
        for (Contact member : members) {
            List<String> fields = new List<String>{
                escapeCsvField(member.FirstName),
                escapeCsvField(member.LastName),
                escapeCsvField(member.Email),
                escapeCsvField(member.Phone),
                escapeCsvField(member.MobilePhone),
                escapeCsvField(member.Membership_Id__c),
                escapeCsvField(member.Level__c),
                escapeCsvField(member.Road_Name__c),
                member.npo02__MembershipJoinDate__c != null ? member.npo02__MembershipJoinDate__c.format() : '',
                member.npo02__MembershipEndDate__c != null ? member.npo02__MembershipEndDate__c.format() : '',
                buildMailingAddress(member)
            };
            
            csvLines.add(String.join(fields, ','));
        }
        
        return String.join(csvLines, '\n');
    }
    
    /**
     * Escape CSV field values properly
     */
    private static String escapeCsvField(String field) {
        if (String.isBlank(field)) {
            return '';
        }
        
        // Sanitize the field first
        String sanitized = CVMAErrorHandler.sanitizeInput(field);
        
        // Escape quotes by doubling them
        sanitized = sanitized.replace('"', '""');
        
        // Wrap in quotes if contains comma, quote, or newline
        if (sanitized.contains(',') || sanitized.contains('"') || sanitized.contains('\n')) {
            sanitized = '"' + sanitized + '"';
        }
        
        return sanitized;
    }
    
    /**
     * Build formatted mailing address
     */
    private static String buildMailingAddress(Contact member) {
        List<String> addressParts = new List<String>();
        
        if (String.isNotBlank(member.MailingStreet)) {
            addressParts.add(CVMAErrorHandler.sanitizeInput(member.MailingStreet));
        }
        if (String.isNotBlank(member.MailingCity)) {
            addressParts.add(CVMAErrorHandler.sanitizeInput(member.MailingCity));
        }
        if (String.isNotBlank(member.MailingState)) {
            addressParts.add(CVMAErrorHandler.sanitizeInput(member.MailingState));
        }
        if (String.isNotBlank(member.MailingPostalCode)) {
            addressParts.add(member.MailingPostalCode);
        }
        
        return escapeCsvField(String.join(addressParts, ', '));
    }
    
    /**
     * Send bulk renewal emails with proper error handling
     */
    private static Integer sendBulkRenewalEmails(List<Contact> members) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Integer emailsSent = 0;
        
        try {
            for (Contact member : members) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{ member.Email });
                email.setSubject('CVMA Chapter 20-7 - Membership Renewal Reminder');
                email.setHtmlBody(buildRenewalEmailBody(member));
                email.setSenderDisplayName('CVMA Chapter 20-7');
                emails.add(email);
            }
            
            if (!emails.isEmpty()) {
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails, false);
                
                // Count successful sends and log any failures
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        emailsSent++;
                    } else {
                        CVMAErrorHandler.logError(
                            new System.EmailException('Email send failed: ' + results[i].getErrors()[0].getMessage()),
                            CLASS_NAME, 'sendBulkRenewalEmails', 
                            CVMAErrorHandler.Severity.MEDIUM, CVMAErrorHandler.Category.INTEGRATION
                        );
                    }
                }
            }
            
        } catch (Exception ex) {
            CVMAErrorHandler.logError(ex, CLASS_NAME, 'sendBulkRenewalEmails', 
                CVMAErrorHandler.Severity.HIGH, CVMAErrorHandler.Category.INTEGRATION);
        }
        
        return emailsSent;
    }
    
    /**
     * Build renewal email HTML body
     */
    private static String buildRenewalEmailBody(Contact member) {
        String emailBody = '<html><body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">';
        emailBody += '<div style="max-width: 600px; margin: 0 auto; padding: 20px;">';
        emailBody += '<h2 style="color: #1b5f9f; border-bottom: 2px solid #c41e3a; padding-bottom: 10px;">Membership Renewal Reminder</h2>';
        emailBody += '<p>Dear ' + CVMAErrorHandler.sanitizeInput(member.FirstName) + ' ' + CVMAErrorHandler.sanitizeInput(member.LastName) + ',</p>';
        emailBody += '<p>This is a friendly reminder that your CVMA Chapter 20-7 membership is approaching its renewal date.</p>';
        emailBody += '<div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #1b5f9f; margin: 20px 0;">';
        emailBody += '<strong>Membership Details:</strong><br>';
        emailBody += 'Membership ID: ' + member.Membership_Id__c + '<br>';
        emailBody += 'Current Level: ' + CVMAErrorHandler.sanitizeInput(member.Level__c) + '<br>';
        
        if (member.npo02__MembershipEndDate__c != null) {
            emailBody += 'Expiration Date: ' + member.npo02__MembershipEndDate__c.format() + '</div>';
        }
        
        emailBody += '<p>Please contact us to renew your membership and continue supporting our mission of Vets Serving Vets.</p>';
        emailBody += '<p>Contact us at chapter20-7@cvma.org or (904) 555-CVMA.</p>';
        emailBody += '<p>Vets Serving Vets,<br><strong>CVMA Chapter 20-7</strong></p>';
        emailBody += '</div></body></html>';
        
        return emailBody;
    }
    
    /**
     * Data wrapper classes
     */
    public class DashboardResponse {
        @AuraEnabled public DashboardStats dashboardStats { get; set; }
        @AuraEnabled public List<MemberData> members { get; set; }
        @AuraEnabled public Integer totalRecords { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer offset { get; set; }
        @AuraEnabled public Boolean hasMore { get; set; }
        
        public DashboardResponse() {
            this.members = new List<MemberData>();
            this.totalRecords = 0;
            this.pageSize = 0;
            this.offset = 0;
            this.hasMore = false;
        }
    }
    
    public class DashboardStats {
        @AuraEnabled public Integer totalMembers { get; set; }
        @AuraEnabled public Integer due30Days { get; set; }
        @AuraEnabled public Integer expiredMembers { get; set; }
        @AuraEnabled public Integer newMembers { get; set; }
        
        public DashboardStats() {
            this.totalMembers = 0;
            this.due30Days = 0;
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
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Date joinDate { get; set; }
        @AuraEnabled public Date expirationDate { get; set; }
        @AuraEnabled public Decimal lastPaymentAmount { get; set; }
        @AuraEnabled public Date lastPaymentDate { get; set; }
        @AuraEnabled public Integer daysTillExpiration { get; set; }
    }
}