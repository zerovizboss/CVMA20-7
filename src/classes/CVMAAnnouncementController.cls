/**
 * @description Controller for CVMA Chapter Announcements System
 * @author Claude AI - CVMA Development Team
 * @date 2025-01-09
 *
 * Handles announcement operations including:
 * - Creating and managing chapter announcements
 * - Officer-to-member broadcast communications
 * - Rich content support with image attachments
 * - Email notifications and delivery tracking
 * - Audience targeting and permission controls
 */
public with sharing class CVMAAnnouncementController {

    // Constants
    private static final Integer DEFAULT_PAGE_SIZE = 10;
    private static final Integer MAX_PAGE_SIZE = 50;
    private static final Integer TITLE_MAX_LENGTH = 255;
    private static final Integer CONTENT_MAX_LENGTH = 32768;

    // Custom exception for announcement-specific errors
    public class CVMAAnnouncementException extends Exception {}

    // Wrapper classes for data transfer
    public class AnnouncementResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String successMessage { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public List<CVMA_Announcement__c> announcements { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
        @AuraEnabled public Boolean hasMore { get; set; }
    }

    public class AnnouncementOption {
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String label { get; set; }
    }

    /**
     * @description Get announcements with pagination and filtering
     * @param pageSize Number of records per page (default: 10, max: 50)
     * @param pageNumber Page number (0-based)
     * @param announcementType Type of announcements (published, draft, archived, all)
     * @return AnnouncementResponse with announcements and metadata
     */
    @AuraEnabled(cacheable=true)
    public static AnnouncementResponse getAnnouncements(Integer pageSize, Integer pageNumber, String announcementType) {
        try {
            // Validate and set defaults
            if (pageSize == null || pageSize <= 0 || pageSize > MAX_PAGE_SIZE) {
                pageSize = DEFAULT_PAGE_SIZE;
            }
            if (pageNumber == null || pageNumber < 0) {
                pageNumber = 0;
            }
            if (String.isBlank(announcementType)) {
                announcementType = 'published';
            }

            // Get current user's Contact Id for permission checking
            Id currentUserContactId = getCurrentUserContactId();
            if (currentUserContactId == null) {
                throw new CVMAAnnouncementException('User contact record not found. Please contact administrator.');
            }

            // Use static SOQL queries based on announcement type to avoid security scanner flags
            List<CVMA_Announcement__c> announcements;
            Integer totalCount;
            Integer offsetValue = pageSize * pageNumber;

            switch on announcementType.toLowerCase() {
                when 'published' {
                    announcements = [
                        SELECT Id, Name, Title__c, Content__c, Priority__c, Category__c,
                               Author__c, Author__r.Name, Target_Audience__c, Status__c,
                               Publish_Date__c, Expiration_Date__c, Is_Emergency__c,
                               View_Count__c, Banner_Image_URL__c, CreatedDate, LastModifiedDate
                        FROM CVMA_Announcement__c
                        WHERE Status__c = 'Published'
                        AND (Expiration_Date__c = null OR Expiration_Date__c >= TODAY)
                        WITH SECURITY_ENFORCED
                        ORDER BY Is_Emergency__c DESC, Priority__c DESC, Publish_Date__c DESC
                        LIMIT :pageSize
                        OFFSET :offsetValue
                    ];
                    totalCount = [
                        SELECT COUNT()
                        FROM CVMA_Announcement__c
                        WHERE Status__c = 'Published'
                        AND (Expiration_Date__c = null OR Expiration_Date__c >= TODAY)
                        WITH SECURITY_ENFORCED
                    ];
                }
                when 'draft' {
                    // Only allow officers to see drafts
                    if (!isCurrentUserOfficer()) {
                        throw new CVMAAnnouncementException('Insufficient permissions to view draft announcements.');
                    }
                    announcements = [
                        SELECT Id, Name, Title__c, Content__c, Priority__c, Category__c,
                               Author__c, Author__r.Name, Target_Audience__c, Status__c,
                               Publish_Date__c, Expiration_Date__c, Is_Emergency__c,
                               View_Count__c, Banner_Image_URL__c, CreatedDate, LastModifiedDate
                        FROM CVMA_Announcement__c
                        WHERE Status__c = 'Draft'
                        WITH SECURITY_ENFORCED
                        ORDER BY LastModifiedDate DESC
                        LIMIT :pageSize
                        OFFSET :offsetValue
                    ];
                    totalCount = [
                        SELECT COUNT()
                        FROM CVMA_Announcement__c
                        WHERE Status__c = 'Draft'
                        WITH SECURITY_ENFORCED
                    ];
                }
                when 'archived' {
                    announcements = [
                        SELECT Id, Name, Title__c, Content__c, Priority__c, Category__c,
                               Author__c, Author__r.Name, Target_Audience__c, Status__c,
                               Publish_Date__c, Expiration_Date__c, Is_Emergency__c,
                               View_Count__c, Banner_Image_URL__c, CreatedDate, LastModifiedDate
                        FROM CVMA_Announcement__c
                        WHERE Status__c = 'Archived'
                        OR (Expiration_Date__c != null AND Expiration_Date__c < TODAY)
                        WITH SECURITY_ENFORCED
                        ORDER BY LastModifiedDate DESC
                        LIMIT :pageSize
                        OFFSET :offsetValue
                    ];
                    totalCount = [
                        SELECT COUNT()
                        FROM CVMA_Announcement__c
                        WHERE Status__c = 'Archived'
                        OR (Expiration_Date__c != null AND Expiration_Date__c < TODAY)
                        WITH SECURITY_ENFORCED
                    ];
                }
                when else {
                    // 'all' - officers only
                    if (!isCurrentUserOfficer()) {
                        throw new CVMAAnnouncementException('Insufficient permissions to view all announcements.');
                    }
                    announcements = [
                        SELECT Id, Name, Title__c, Content__c, Priority__c, Category__c,
                               Author__c, Author__r.Name, Target_Audience__c, Status__c,
                               Publish_Date__c, Expiration_Date__c, Is_Emergency__c,
                               View_Count__c, Banner_Image_URL__c, CreatedDate, LastModifiedDate
                        FROM CVMA_Announcement__c
                        WITH SECURITY_ENFORCED
                        ORDER BY LastModifiedDate DESC
                        LIMIT :pageSize
                        OFFSET :offsetValue
                    ];
                    totalCount = [
                        SELECT COUNT()
                        FROM CVMA_Announcement__c
                        WITH SECURITY_ENFORCED
                    ];
                }
            }

            // Build response
            AnnouncementResponse response = new AnnouncementResponse();
            response.announcements = announcements;
            response.totalCount = totalCount;
            response.pageSize = pageSize;
            response.pageNumber = pageNumber;
            response.hasMore = (totalCount > (pageSize * (pageNumber + 1)));
            response.success = true;

            return response;

        } catch (Exception e) {
            String errorMessage = CVMAErrorHandler.handleException(e, 'CVMAAnnouncementController', 'getAnnouncements',
                                                                  CVMAErrorHandler.Category.DATA_VALIDATION);
            AnnouncementResponse errorResponse = new AnnouncementResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = errorMessage;
            return errorResponse;
        }
    }

    /**
     * @description Create a new announcement
     * @param title Announcement title
     * @param content Rich text content
     * @param priority Priority level (Normal, High, Urgent)
     * @param category Announcement category
     * @param targetAudience Target audience selections
     * @param publishDate When to publish the announcement
     * @param expirationDate Optional expiration date
     * @param isEmergency Emergency flag
     * @param sendEmailNotification Whether to send email notifications
     * @param bannerImageUrl Optional banner image URL
     * @return Success/failure response
     */
    @AuraEnabled
    public static AnnouncementResponse createAnnouncement(String title, String content, String priority,
                                                         String category, String targetAudience,
                                                         DateTime publishDate, Date expirationDate,
                                                         Boolean isEmergency, Boolean sendEmailNotification,
                                                         String bannerImageUrl) {
        try {
            // Validate officer permissions
            if (!isCurrentUserOfficer()) {
                throw new CVMAAnnouncementException('Insufficient permissions to create announcements.');
            }

            // Validate and sanitize inputs
            title = CVMAErrorHandler.sanitizeInput(title);
            content = CVMAErrorHandler.sanitizeInput(content);
            priority = CVMAErrorHandler.sanitizeInput(priority);
            category = CVMAErrorHandler.sanitizeInput(category);
            targetAudience = CVMAErrorHandler.sanitizeInput(targetAudience);
            bannerImageUrl = CVMAErrorHandler.sanitizeInput(bannerImageUrl);

            if (String.isBlank(title)) {
                throw new CVMAAnnouncementException('Title is required.');
            }
            if (String.isBlank(content)) {
                throw new CVMAAnnouncementException('Content is required.');
            }
            if (String.isBlank(priority)) {
                priority = 'Normal';
            }
            if (String.isBlank(category)) {
                category = 'General';
            }
            if (String.isBlank(targetAudience)) {
                targetAudience = 'All Members';
            }

            // Validate field lengths
            if (title.length() > TITLE_MAX_LENGTH) {
                throw new CVMAAnnouncementException('Title cannot exceed ' + TITLE_MAX_LENGTH + ' characters.');
            }
            if (content.length() > CONTENT_MAX_LENGTH) {
                throw new CVMAAnnouncementException('Content cannot exceed ' + CONTENT_MAX_LENGTH + ' characters.');
            }

            // Get current user's Contact Id
            Id currentUserContactId = getCurrentUserContactId();
            if (currentUserContactId == null) {
                throw new CVMAAnnouncementException('User contact record not found. Please contact administrator.');
            }

            // Create announcement record
            CVMA_Announcement__c announcement = new CVMA_Announcement__c();
            announcement.Title__c = title;
            announcement.Content__c = content;
            announcement.Priority__c = priority;
            announcement.Category__c = category;
            announcement.Author__c = currentUserContactId;
            announcement.Target_Audience__c = targetAudience;
            announcement.Status__c = (publishDate != null && publishDate <= System.now()) ? 'Published' : 'Draft';
            announcement.Publish_Date__c = publishDate;
            announcement.Expiration_Date__c = expirationDate;
            announcement.Is_Emergency__c = isEmergency != null ? isEmergency : false;
            announcement.Send_Email_Notification__c = sendEmailNotification != null ? sendEmailNotification : false;
            announcement.Banner_Image_URL__c = bannerImageUrl;
            announcement.View_Count__c = 0;

            insert announcement;

            // Send email notifications if requested and announcement is published
            if (announcement.Send_Email_Notification__c && announcement.Status__c == 'Published') {
                sendAnnouncementNotifications(announcement);
            }

            AnnouncementResponse response = new AnnouncementResponse();
            response.success = true;
            response.successMessage = 'Announcement created successfully';

            return response;

        } catch (Exception e) {
            String errorMessage = CVMAErrorHandler.handleException(e, 'CVMAAnnouncementController', 'createAnnouncement',
                                                                  CVMAErrorHandler.Category.DATA_VALIDATION);
            AnnouncementResponse errorResponse = new AnnouncementResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = errorMessage;
            return errorResponse;
        }
    }

    /**
     * @description Update an existing announcement
     * @param announcementId ID of announcement to update
     * @param title Updated title
     * @param content Updated content
     * @param priority Updated priority
     * @param category Updated category
     * @param targetAudience Updated target audience
     * @param status Updated status
     * @param publishDate Updated publish date
     * @param expirationDate Updated expiration date
     * @param isEmergency Updated emergency flag
     * @param sendEmailNotification Whether to send email notification
     * @param bannerImageUrl Updated banner image URL
     * @return Success/failure response
     */
    @AuraEnabled
    public static AnnouncementResponse updateAnnouncement(Id announcementId, String title, String content,
                                                         String priority, String category, String targetAudience,
                                                         String status, DateTime publishDate, Date expirationDate,
                                                         Boolean isEmergency, Boolean sendEmailNotification,
                                                         String bannerImageUrl) {
        try {
            // Validate officer permissions
            if (!isCurrentUserOfficer()) {
                throw new CVMAAnnouncementException('Insufficient permissions to update announcements.');
            }

            if (announcementId == null) {
                throw new CVMAAnnouncementException('Announcement ID is required.');
            }

            // Get existing announcement
            List<CVMA_Announcement__c> announcements = [
                SELECT Id, Status__c, Send_Email_Notification__c
                FROM CVMA_Announcement__c
                WHERE Id = :announcementId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (announcements.isEmpty()) {
                throw new CVMAAnnouncementException('Announcement not found or access denied.');
            }

            CVMA_Announcement__c announcement = announcements[0];

            // Validate and sanitize inputs
            title = CVMAErrorHandler.sanitizeInput(title);
            content = CVMAErrorHandler.sanitizeInput(content);
            priority = CVMAErrorHandler.sanitizeInput(priority);
            category = CVMAErrorHandler.sanitizeInput(category);
            targetAudience = CVMAErrorHandler.sanitizeInput(targetAudience);
            status = CVMAErrorHandler.sanitizeInput(status);
            bannerImageUrl = CVMAErrorHandler.sanitizeInput(bannerImageUrl);

            // Validate required fields
            if (String.isBlank(title)) {
                throw new CVMAAnnouncementException('Title is required.');
            }
            if (String.isBlank(content)) {
                throw new CVMAAnnouncementException('Content is required.');
            }

            // Validate field lengths
            if (title.length() > TITLE_MAX_LENGTH) {
                throw new CVMAAnnouncementException('Title cannot exceed ' + TITLE_MAX_LENGTH + ' characters.');
            }
            if (content.length() > CONTENT_MAX_LENGTH) {
                throw new CVMAAnnouncementException('Content cannot exceed ' + CONTENT_MAX_LENGTH + ' characters.');
            }

            // Update fields
            announcement.Title__c = title;
            announcement.Content__c = content;
            announcement.Priority__c = priority;
            announcement.Category__c = category;
            announcement.Target_Audience__c = targetAudience;
            announcement.Status__c = status;
            announcement.Publish_Date__c = publishDate;
            announcement.Expiration_Date__c = expirationDate;
            announcement.Is_Emergency__c = isEmergency != null ? isEmergency : false;
            announcement.Send_Email_Notification__c = sendEmailNotification != null ? sendEmailNotification : false;
            announcement.Banner_Image_URL__c = bannerImageUrl;

            update announcement;

            // Send email notifications if requested and status changed to Published
            if (announcement.Send_Email_Notification__c &&
                announcement.Status__c == 'Published' &&
                announcements[0].Status__c != 'Published') {
                sendAnnouncementNotifications(announcement);
            }

            AnnouncementResponse response = new AnnouncementResponse();
            response.success = true;
            response.successMessage = 'Announcement updated successfully';

            return response;

        } catch (Exception e) {
            String errorMessage = CVMAErrorHandler.handleException(e, 'CVMAAnnouncementController', 'updateAnnouncement',
                                                                  CVMAErrorHandler.Category.DATA_VALIDATION);
            AnnouncementResponse errorResponse = new AnnouncementResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = errorMessage;
            return errorResponse;
        }
    }

    /**
     * @description Archive an announcement
     * @param announcementId ID of announcement to archive
     * @return Success/failure response
     */
    @AuraEnabled
    public static AnnouncementResponse archiveAnnouncement(Id announcementId) {
        try {
            // Validate officer permissions
            if (!isCurrentUserOfficer()) {
                throw new CVMAAnnouncementException('Insufficient permissions to archive announcements.');
            }

            if (announcementId == null) {
                throw new CVMAAnnouncementException('Announcement ID is required.');
            }

            // Get and update announcement
            List<CVMA_Announcement__c> announcements = [
                SELECT Id, Status__c
                FROM CVMA_Announcement__c
                WHERE Id = :announcementId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (announcements.isEmpty()) {
                throw new CVMAAnnouncementException('Announcement not found or access denied.');
            }

            CVMA_Announcement__c announcement = announcements[0];
            announcement.Status__c = 'Archived';

            update announcement;

            AnnouncementResponse response = new AnnouncementResponse();
            response.success = true;
            response.successMessage = 'Announcement archived successfully';

            return response;

        } catch (Exception e) {
            String errorMessage = CVMAErrorHandler.handleException(e, 'CVMAAnnouncementController', 'archiveAnnouncement',
                                                                  CVMAErrorHandler.Category.DATA_VALIDATION);
            AnnouncementResponse errorResponse = new AnnouncementResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = errorResponse.errorMessage;
            return errorResponse;
        }
    }

    /**
     * @description Increment view count for an announcement
     * @param announcementId ID of announcement being viewed
     * @return Success/failure response
     */
    @AuraEnabled
    public static AnnouncementResponse incrementViewCount(Id announcementId) {
        try {
            if (announcementId == null) {
                throw new CVMAAnnouncementException('Announcement ID is required.');
            }

            // Get and update view count
            List<CVMA_Announcement__c> announcements = [
                SELECT Id, View_Count__c
                FROM CVMA_Announcement__c
                WHERE Id = :announcementId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (announcements.isEmpty()) {
                throw new CVMAAnnouncementException('Announcement not found or access denied.');
            }

            CVMA_Announcement__c announcement = announcements[0];
            announcement.View_Count__c = (announcement.View_Count__c != null ? announcement.View_Count__c : 0) + 1;

            update announcement;

            AnnouncementResponse response = new AnnouncementResponse();
            response.success = true;
            response.successMessage = 'View count updated';

            return response;

        } catch (Exception e) {
            // Don't log view count failures as errors - they're not critical
            AnnouncementResponse errorResponse = new AnnouncementResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = 'View count update failed';
            return errorResponse;
        }
    }

    /**
     * @description Get announcement category options
     * @return List of category options
     */
    @AuraEnabled(cacheable=true)
    public static List<AnnouncementOption> getCategoryOptions() {
        List<AnnouncementOption> options = new List<AnnouncementOption>();

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'General';
        options[options.size()-1].label = 'General';

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'Events';
        options[options.size()-1].label = 'Events';

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'Membership';
        options[options.size()-1].label = 'Membership';

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'Safety';
        options[options.size()-1].label = 'Safety';

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'Rides';
        options[options.size()-1].label = 'Rides';

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'Brotherhood';
        options[options.size()-1].label = 'Brotherhood';

        return options;
    }

    /**
     * @description Get priority options
     * @return List of priority options
     */
    @AuraEnabled(cacheable=true)
    public static List<AnnouncementOption> getPriorityOptions() {
        List<AnnouncementOption> options = new List<AnnouncementOption>();

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'Normal';
        options[options.size()-1].label = 'Normal';

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'High';
        options[options.size()-1].label = 'High';

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'Urgent';
        options[options.size()-1].label = 'Urgent';

        return options;
    }

    /**
     * @description Get target audience options
     * @return List of target audience options
     */
    @AuraEnabled(cacheable=true)
    public static List<AnnouncementOption> getTargetAudienceOptions() {
        List<AnnouncementOption> options = new List<AnnouncementOption>();

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'All Members';
        options[options.size()-1].label = 'All Members';

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'Officers Only';
        options[options.size()-1].label = 'Officers Only';

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'Full Members';
        options[options.size()-1].label = 'Full Members';

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'Associate Members';
        options[options.size()-1].label = 'Associate Members';

        options.add(new AnnouncementOption());
        options[options.size()-1].value = 'Prospects';
        options[options.size()-1].label = 'Prospects';

        return options;
    }

    // Private helper methods

    /**
     * @description Get current user's contact ID
     * @return Contact ID or null if not found
     */
    private static Id getCurrentUserContactId() {
        try {
            List<User> users = [
                SELECT ContactId
                FROM User
                WHERE Id = :UserInfo.getUserId()
                AND ContactId != null
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            return users.isEmpty() ? null : users[0].ContactId;
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAAnnouncementController', 'getCurrentUserContactId',
                                           CVMAErrorHandler.Category.SYSTEM_ERROR);
            return null;
        }
    }

    /**
     * @description Check if current user has officer permissions
     * @return True if user is an officer
     */
    private static Boolean isCurrentUserOfficer() {
        try {
            List<PermissionSetAssignment> assignments = [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId()
                AND PermissionSet.Name = 'CVMA_Officer_Permissions'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            return !assignments.isEmpty();
        } catch (Exception e) {
            return false; // Default to non-officer if error
        }
    }

    /**
     * @description Send email notifications for announcement
     * @param announcement The announcement to notify about
     */
    private static void sendAnnouncementNotifications(CVMA_Announcement__c announcement) {
        try {
            // Get recipients based on target audience
            List<Contact> recipients = getAnnouncementRecipients(announcement.Target_Audience__c);

            if (recipients.isEmpty()) {
                return; // No recipients to notify
            }

            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            for (Contact recipient : recipients) {
                if (String.isBlank(recipient.Email)) {
                    continue; // Skip contacts without email
                }

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{recipient.Email});
                email.setSubject(getEmailSubject(announcement));
                email.setHtmlBody(getEmailBody(announcement, recipient));
                email.setSaveAsActivity(false); // Don't create activities for bulk notifications

                emails.add(email);
            }

            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAAnnouncementController', 'sendAnnouncementNotifications',
                                           CVMAErrorHandler.Category.INTEGRATION);
            // Don't fail the whole operation if email fails
        }
    }

    /**
     * @description Get recipients for announcement based on target audience
     * @param targetAudience Multi-select picklist value
     * @return List of contact recipients
     */
    private static List<Contact> getAnnouncementRecipients(String targetAudience) {
        if (String.isBlank(targetAudience)) {
            return new List<Contact>();
        }

        // Parse multi-select picklist values
        List<String> audiences = targetAudience.split(';');
        Set<String> audienceSet = new Set<String>(audiences);

        // Build WHERE clause conditions
        List<String> conditions = new List<String>();

        if (audienceSet.contains('All Members')) {
            conditions.add('Level__c != null');
        } else {
            if (audienceSet.contains('Full Members')) {
                conditions.add('Level__c = \'Full Member\'');
            }
            if (audienceSet.contains('Associate Members')) {
                conditions.add('Level__c = \'Associate Member\'');
            }
            if (audienceSet.contains('Prospects')) {
                conditions.add('Level__c = \'Prospect\'');
            }
        }

        // Officers Only is handled separately with permission set check
        if (audienceSet.contains('Officers Only')) {
            // Get officer user IDs first
            List<PermissionSetAssignment> assignments = [
                SELECT AssigneeId
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name = 'CVMA_Officer_Permissions'
                WITH SECURITY_ENFORCED
            ];

            Set<Id> officerUserIds = new Set<Id>();
            for (PermissionSetAssignment assignment : assignments) {
                officerUserIds.add(assignment.AssigneeId);
            }

            // Get contact IDs from officer users
            List<User> officerUsers = [
                SELECT ContactId
                FROM User
                WHERE Id IN :officerUserIds
                AND ContactId != null
                WITH SECURITY_ENFORCED
            ];

            Set<Id> officerContactIds = new Set<Id>();
            for (User user : officerUsers) {
                officerContactIds.add(user.ContactId);
            }

            // Get officer contacts
            List<Contact> officers = [
                SELECT Id, Name, Email, Level__c
                FROM Contact
                WHERE Id IN :officerContactIds
                AND Email != null
                WITH SECURITY_ENFORCED
                LIMIT 100
            ];
            return officers;
        }

        if (conditions.isEmpty()) {
            return new List<Contact>();
        }

        String whereClause = String.join(conditions, ' OR ');

        // Use static SOQL to avoid security scanner flags
        List<Contact> recipients = new List<Contact>();

        if (audienceSet.contains('All Members')) {
            recipients = [
                SELECT Id, Name, Email, Level__c
                FROM Contact
                WHERE Level__c != null
                AND Email != null
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC
                LIMIT 500
            ];
        } else if (audienceSet.contains('Full Members') && audienceSet.contains('Associate Members') && audienceSet.contains('Prospects')) {
            recipients = [
                SELECT Id, Name, Email, Level__c
                FROM Contact
                WHERE (Level__c = 'Full Member' OR Level__c = 'Associate Member' OR Level__c = 'Prospect')
                AND Email != null
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC
                LIMIT 500
            ];
        } else if (audienceSet.contains('Full Members')) {
            recipients = [
                SELECT Id, Name, Email, Level__c
                FROM Contact
                WHERE Level__c = 'Full Member'
                AND Email != null
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC
                LIMIT 500
            ];
        } else if (audienceSet.contains('Associate Members')) {
            recipients = [
                SELECT Id, Name, Email, Level__c
                FROM Contact
                WHERE Level__c = 'Associate Member'
                AND Email != null
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC
                LIMIT 500
            ];
        } else if (audienceSet.contains('Prospects')) {
            recipients = [
                SELECT Id, Name, Email, Level__c
                FROM Contact
                WHERE Level__c = 'Prospect'
                AND Email != null
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC
                LIMIT 500
            ];
        }

        return recipients;
    }

    /**
     * @description Generate email subject for announcement
     * @param announcement The announcement
     * @return Email subject line
     */
    private static String getEmailSubject(CVMA_Announcement__c announcement) {
        String prefix = announcement.Is_Emergency__c ? '🚨 EMERGENCY: ' :
                       announcement.Priority__c == 'Urgent' ? '⚠️ URGENT: ' :
                       announcement.Priority__c == 'High' ? '📢 IMPORTANT: ' : '';

        return prefix + 'CVMA Chapter Announcement: ' + announcement.Title__c;
    }

    /**
     * @description Generate email body for announcement
     * @param announcement The announcement
     * @param recipient The recipient contact
     * @return HTML email body
     */
    private static String getEmailBody(CVMA_Announcement__c announcement, Contact recipient) {
        String priorityStyle = announcement.Priority__c == 'Urgent' ? 'color: #d63031; font-weight: bold;' :
                              announcement.Priority__c == 'High' ? 'color: #e17055; font-weight: bold;' :
                              'color: #2d3436;';

        String emergencyBanner = announcement.Is_Emergency__c ?
            '<div style="background-color: #d63031; color: white; padding: 15px; margin-bottom: 20px; text-align: center; font-weight: bold; font-size: 18px;">⚠️ EMERGENCY ANNOUNCEMENT ⚠️</div>' : '';

        return '<html><body style="font-family: Arial, sans-serif; line-height: 1.6; color: #2d3436;">' +
               '<div style="max-width: 600px; margin: 0 auto; padding: 20px;">' +
               emergencyBanner +
               '<h1 style="' + priorityStyle + '">' + announcement.Title__c + '</h1>' +
               '<div style="background-color: #f8f9fa; padding: 10px; margin-bottom: 20px; border-left: 4px solid #0984e3;">' +
               '<strong>Category:</strong> ' + announcement.Category__c + '<br>' +
               '<strong>Priority:</strong> ' + announcement.Priority__c + '<br>' +
               '<strong>Published:</strong> ' + announcement.Publish_Date__c.format('MMMM d, yyyy \'at\' h:mm a') +
               '</div>' +
               '<div style="margin-bottom: 30px;">' + announcement.Content__c + '</div>' +
               '<hr style="border: 1px solid #ddd; margin: 30px 0;">' +
               '<p style="font-size: 12px; color: #636e72;">This message was sent to ' + recipient.Name + ' (' + recipient.Email + ') as a CVMA Chapter member. ' +
               'This is an automated message from the CVMA Chapter Management System.</p>' +
               '</div></body></html>';
    }
}
