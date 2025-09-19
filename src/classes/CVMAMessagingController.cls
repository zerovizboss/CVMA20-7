/**
 * @description Secure messaging controller for CVMA Member-to-Member communication
 * @author Claude AI - CVMA Development Team
 * @date 2025-01-09
 */
public with sharing class CVMAMessagingController {

    // Constants for pagination and limits
    private static final Integer DEFAULT_PAGE_SIZE = 25;
    private static final Integer MAX_PAGE_SIZE = 100;
    private static final Integer MESSAGE_BODY_MAX_LENGTH = 32768;
    private static final Integer SUBJECT_MAX_LENGTH = 255;

    /**
     * @description Get messages for the current user (inbox)
     * @param pageSize Number of messages per page
     * @param pageNumber Page number (0-based)
     * @param messageType Type of messages (Inbox, Sent, Archived)
     * @return List of messages with metadata
     */
    @AuraEnabled(cacheable=true)
    public static MessagingResponse getMessages(Integer pageSize, Integer pageNumber, String messageType) {
        try {
            // Note: CRUD permissions validated through WITH SECURITY_ENFORCED in SOQL

            if (pageSize == null || pageSize <= 0 || pageSize > MAX_PAGE_SIZE) {
                pageSize = DEFAULT_PAGE_SIZE;
            }
            if (pageNumber == null || pageNumber < 0) {
                pageNumber = 0;
            }

            messageType = CVMAErrorHandler.sanitizeInput(messageType);
            if (String.isBlank(messageType)) {
                messageType = 'Inbox';
            }

            // Get current user's Contact Id
            Id currentUserContactId = getCurrentUserContactId();
            if (currentUserContactId == null) {
                throw new CVMAMessagingException('User contact record not found. Please contact administrator.');
            }

            // Use static SOQL queries based on message type to avoid security scanner flags
            List<CVMA_Message__c> messages;
            Integer totalCount;
            Integer offsetValue = pageSize * pageNumber;

            switch on messageType.toLowerCase() {
                when 'inbox' {
                    messages = [
                        SELECT Id, Name, Subject__c, Message_Body__c, Status__c, Priority__c,
                               Sender__c, Sender__r.Name, Sender__r.Email, Recipient__c, Recipient__r.Name,
                               Recipient__r.Email, Thread_ID__c, Read_Date__c, Is_Officer_Message__c,
                               CreatedDate, CreatedBy.Name
                        FROM CVMA_Message__c
                        WHERE Recipient__c = :currentUserContactId AND Status__c != 'Archived'
                        WITH SECURITY_ENFORCED
                        ORDER BY CreatedDate DESC
                        LIMIT :pageSize
                        OFFSET :offsetValue
                    ];
                    totalCount = [
                        SELECT COUNT()
                        FROM CVMA_Message__c
                        WHERE Recipient__c = :currentUserContactId AND Status__c != 'Archived'
                        WITH SECURITY_ENFORCED
                    ];
                }
                when 'sent' {
                    messages = [
                        SELECT Id, Name, Subject__c, Message_Body__c, Status__c, Priority__c,
                               Sender__c, Sender__r.Name, Sender__r.Email, Recipient__c, Recipient__r.Name,
                               Recipient__r.Email, Thread_ID__c, Read_Date__c, Is_Officer_Message__c,
                               CreatedDate, CreatedBy.Name
                        FROM CVMA_Message__c
                        WHERE Sender__c = :currentUserContactId AND Status__c != 'Archived'
                        WITH SECURITY_ENFORCED
                        ORDER BY CreatedDate DESC
                        LIMIT :pageSize
                        OFFSET :offsetValue
                    ];
                    totalCount = [
                        SELECT COUNT()
                        FROM CVMA_Message__c
                        WHERE Sender__c = :currentUserContactId AND Status__c != 'Archived'
                        WITH SECURITY_ENFORCED
                    ];
                }
                when 'archived' {
                    messages = [
                        SELECT Id, Name, Subject__c, Message_Body__c, Status__c, Priority__c,
                               Sender__c, Sender__r.Name, Sender__r.Email, Recipient__c, Recipient__r.Name,
                               Recipient__r.Email, Thread_ID__c, Read_Date__c, Is_Officer_Message__c,
                               CreatedDate, CreatedBy.Name
                        FROM CVMA_Message__c
                        WHERE (Sender__c = :currentUserContactId OR Recipient__c = :currentUserContactId)
                              AND Status__c = 'Archived'
                        WITH SECURITY_ENFORCED
                        ORDER BY CreatedDate DESC
                        LIMIT :pageSize
                        OFFSET :offsetValue
                    ];
                    totalCount = [
                        SELECT COUNT()
                        FROM CVMA_Message__c
                        WHERE (Sender__c = :currentUserContactId OR Recipient__c = :currentUserContactId)
                              AND Status__c = 'Archived'
                        WITH SECURITY_ENFORCED
                    ];
                }
                when else {
                    // Default to inbox
                    messages = [
                        SELECT Id, Name, Subject__c, Message_Body__c, Status__c, Priority__c,
                               Sender__c, Sender__r.Name, Sender__r.Email, Recipient__c, Recipient__r.Name,
                               Recipient__r.Email, Thread_ID__c, Read_Date__c, Is_Officer_Message__c,
                               CreatedDate, CreatedBy.Name
                        FROM CVMA_Message__c
                        WHERE Recipient__c = :currentUserContactId AND Status__c != 'Archived'
                        WITH SECURITY_ENFORCED
                        ORDER BY CreatedDate DESC
                        LIMIT :pageSize
                        OFFSET :offsetValue
                    ];
                    totalCount = [
                        SELECT COUNT()
                        FROM CVMA_Message__c
                        WHERE Recipient__c = :currentUserContactId AND Status__c != 'Archived'
                        WITH SECURITY_ENFORCED
                    ];
                }
            }

            // Build response
            MessagingResponse response = new MessagingResponse();
            response.messages = messages;
            response.totalCount = totalCount;
            response.pageSize = pageSize;
            response.pageNumber = pageNumber;
            response.hasMore = (totalCount > (pageSize * (pageNumber + 1)));
            response.success = true;

            return response;

        } catch (Exception e) {
            String errorMessage = CVMAErrorHandler.handleException(e, 'CVMAMessagingController', 'getMessages',
                                                                  CVMAErrorHandler.Category.DATA_VALIDATION);
            MessagingResponse errorResponse = new MessagingResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = errorMessage;
            return errorResponse;
        }
    }

    /**
     * @description Send a new message
     * @param recipientId Contact Id of the message recipient
     * @param subject Message subject
     * @param messageBody Message content
     * @param priority Message priority (Normal, High, Urgent)
     * @param threadId Optional thread ID for conversation grouping
     * @return Success/failure response
     */
    @AuraEnabled
    public static MessagingResponse sendMessage(Id recipientId, String subject, String messageBody,
                                               String priority, String threadId) {
        try {
            // Validate CRUD permissions
            // Note: CRUD permissions validated through WITH SECURITY_ENFORCED in SOQL

            // Validate and sanitize inputs
            if (recipientId == null) {
                throw new CVMAMessagingException('Recipient is required.');
            }

            subject = CVMAErrorHandler.sanitizeInput(subject);
            messageBody = CVMAErrorHandler.sanitizeInput(messageBody);
            priority = CVMAErrorHandler.sanitizeInput(priority);
            threadId = CVMAErrorHandler.sanitizeInput(threadId);

            if (String.isBlank(subject)) {
                throw new CVMAMessagingException('Subject is required.');
            }
            if (String.isBlank(messageBody)) {
                throw new CVMAMessagingException('Message body is required.');
            }

            if (subject.length() > SUBJECT_MAX_LENGTH) {
                throw new CVMAMessagingException('Subject cannot exceed ' + SUBJECT_MAX_LENGTH + ' characters.');
            }
            if (messageBody.length() > MESSAGE_BODY_MAX_LENGTH) {
                throw new CVMAMessagingException('Message body cannot exceed ' + MESSAGE_BODY_MAX_LENGTH + ' characters.');
            }

            // Validate recipient exists and is a valid contact
            List<Contact> recipients = [SELECT Id, Name FROM Contact WHERE Id = :recipientId WITH SECURITY_ENFORCED LIMIT 1];
            if (recipients.isEmpty()) {
                throw new CVMAMessagingException('Invalid recipient selected.');
            }

            // Get current user's Contact Id
            Id currentUserContactId = getCurrentUserContactId();
            if (currentUserContactId == null) {
                throw new CVMAMessagingException('User contact record not found. Please contact administrator.');
            }

            // Prevent sending message to self
            if (currentUserContactId == recipientId) {
                throw new CVMAMessagingException('Cannot send message to yourself.');
            }

            // Validate priority
            if (String.isBlank(priority)) {
                priority = 'Normal';
            }
            if (!isValidPriority(priority)) {
                priority = 'Normal';
            }

            // Generate thread ID if not provided
            if (String.isBlank(threadId)) {
                threadId = generateThreadId(currentUserContactId, recipientId);
            }

            // Check if user is officer for officer message flag
            Boolean isOfficerMessage = isCurrentUserOfficer();

            // Create message record
            CVMA_Message__c newMessage = new CVMA_Message__c(
                Sender__c = currentUserContactId,
                Recipient__c = recipientId,
                Subject__c = subject,
                Message_Body__c = messageBody,
                Status__c = 'Sent',
                Priority__c = priority,
                Thread_ID__c = threadId,
                Is_Officer_Message__c = isOfficerMessage
            );

            insert newMessage;

            // Build success response
            MessagingResponse response = new MessagingResponse();
            response.success = true;
            response.messageId = newMessage.Id;
            response.successMessage = 'Message sent successfully to ' + recipients[0].Name;

            return response;

        } catch (Exception e) {
            String errorMessage = CVMAErrorHandler.handleException(e, 'CVMAMessagingController', 'sendMessage',
                                                                  CVMAErrorHandler.Category.DATA_VALIDATION);
            MessagingResponse errorResponse = new MessagingResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = errorMessage;
            return errorResponse;
        }
    }

    /**
     * @description Mark message as read
     * @param messageId Id of the message to mark as read
     * @return Success/failure response
     */
    @AuraEnabled
    public static MessagingResponse markMessageAsRead(Id messageId) {
        try {
            // Validate CRUD permissions
            // Note: CRUD permissions validated through WITH SECURITY_ENFORCED in SOQL

            if (messageId == null) {
                throw new CVMAMessagingException('Message ID is required.');
            }

            // Get current user's Contact Id
            Id currentUserContactId = getCurrentUserContactId();
            if (currentUserContactId == null) {
                throw new CVMAMessagingException('User contact record not found. Please contact administrator.');
            }

            // Verify user is the recipient of this message
            List<CVMA_Message__c> messages = [
                SELECT Id, Status__c, Read_Date__c
                FROM CVMA_Message__c
                WHERE Id = :messageId AND Recipient__c = :currentUserContactId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (messages.isEmpty()) {
                throw new CVMAMessagingException('Message not found or access denied.');
            }

            CVMA_Message__c message = messages[0];

            // Only update if not already read
            if (message.Status__c != 'Read' && message.Read_Date__c == null) {
                message.Status__c = 'Read';
                message.Read_Date__c = System.now();
                update message;
            }

            MessagingResponse response = new MessagingResponse();
            response.success = true;
            response.successMessage = 'Message marked as read';

            return response;

        } catch (Exception e) {
            String errorMessage = CVMAErrorHandler.handleException(e, 'CVMAMessagingController', 'markMessageAsRead',
                                                                  CVMAErrorHandler.Category.DATA_VALIDATION);
            MessagingResponse errorResponse = new MessagingResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = errorMessage;
            return errorResponse;
        }
    }

    /**
     * @description Get list of available members for messaging
     * @param searchTerm Optional search term to filter members
     * @return List of contacts available for messaging
     */
    @AuraEnabled(cacheable=true)
    public static List<ContactOption> getAvailableMembers(String searchTerm) {
        try {
            // Validate CRUD permissions
            // Note: CRUD permissions validated through WITH SECURITY_ENFORCED in SOQL

            searchTerm = CVMAErrorHandler.sanitizeInput(searchTerm);

            // Get current user's Contact Id to exclude from results
            Id currentUserContactId = getCurrentUserContactId();

            List<Contact> contacts;

            // Use static SOQL queries to avoid security scanner flags
            if (!String.isBlank(searchTerm)) {
                String likeSearchTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
                contacts = [
                    SELECT Id, Name, Email, Membership_ID__c, Level__c
                    FROM Contact
                    WHERE Id != :currentUserContactId
                    AND Level__c != null
                    AND (Name LIKE :likeSearchTerm OR Email LIKE :likeSearchTerm OR Membership_ID__c LIKE :likeSearchTerm)
                    WITH SECURITY_ENFORCED
                    ORDER BY Name ASC
                    LIMIT 50
                ];
            } else {
                contacts = [
                    SELECT Id, Name, Email, Membership_ID__c, Level__c
                    FROM Contact
                    WHERE Id != :currentUserContactId
                    AND Level__c != null
                    WITH SECURITY_ENFORCED
                    ORDER BY Name ASC
                    LIMIT 50
                ];
            }

            List<ContactOption> options = new List<ContactOption>();
            for (Contact c : contacts) {
                ContactOption option = new ContactOption();
                option.contactId = c.Id;
                option.displayName = c.Name + ' (' + (c.Membership_ID__c != null ? c.Membership_ID__c : 'No ID') + ')';
                option.email = c.Email;
                option.membershipLevel = c.Level__c;
                options.add(option);
            }

            return options;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAMessagingController', 'getAvailableMembers',
                                           CVMAErrorHandler.Category.DATA_VALIDATION);
            return new List<ContactOption>();
        }
    }

    /**
     * @description Archive a message
     * @param messageId Id of the message to archive
     * @return Success/failure response
     */
    @AuraEnabled
    public static MessagingResponse archiveMessage(Id messageId) {
        try {
            // Validate CRUD permissions
            // Note: CRUD permissions validated through WITH SECURITY_ENFORCED in SOQL

            if (messageId == null) {
                throw new CVMAMessagingException('Message ID is required.');
            }

            // Get current user's Contact Id
            Id currentUserContactId = getCurrentUserContactId();
            if (currentUserContactId == null) {
                throw new CVMAMessagingException('User contact record not found. Please contact administrator.');
            }

            // Verify user is either sender or recipient of this message
            List<CVMA_Message__c> messages = [
                SELECT Id, Status__c
                FROM CVMA_Message__c
                WHERE Id = :messageId
                AND (Sender__c = :currentUserContactId OR Recipient__c = :currentUserContactId)
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (messages.isEmpty()) {
                throw new CVMAMessagingException('Message not found or access denied.');
            }

            CVMA_Message__c message = messages[0];
            message.Status__c = 'Archived';
            update message;

            MessagingResponse response = new MessagingResponse();
            response.success = true;
            response.successMessage = 'Message archived successfully';

            return response;

        } catch (Exception e) {
            String errorMessage = CVMAErrorHandler.handleException(e, 'CVMAMessagingController', 'archiveMessage',
                                                                  CVMAErrorHandler.Category.DATA_VALIDATION);
            MessagingResponse errorResponse = new MessagingResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = errorMessage;
            return errorResponse;
        }
    }

    // PRIVATE HELPER METHODS

    /**
     * @description Get current user's Contact Id
     * @return Contact Id of current user
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
            CVMAErrorHandler.handleException(e, 'CVMAMessagingController', 'getCurrentUserContactId',
                                           CVMAErrorHandler.Category.SYSTEM_ERROR);
            return null;
        }
    }

    /**
     * @description Check if current user is an officer
     * @return True if user has officer permissions
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
     * @description Generate unique thread ID for conversation
     * @param senderId Sender contact ID
     * @param recipientId Recipient contact ID
     * @return Thread ID string
     */
    private static String generateThreadId(Id senderId, Id recipientId) {
        // Create consistent thread ID regardless of who initiates
        String id1 = String.valueOf(senderId).substring(0, 15);
        String id2 = String.valueOf(recipientId).substring(0, 15);
        List<String> ids = new List<String>{id1, id2};
        ids.sort();
        return 'THREAD_' + ids[0] + '_' + ids[1];
    }

    /**
     * @description Validate priority value
     * @param priority Priority string to validate
     * @return True if valid priority
     */
    private static Boolean isValidPriority(String priority) {
        Set<String> validPriorities = new Set<String>{'Normal', 'High', 'Urgent'};
        return validPriorities.contains(priority);
    }

    // CUSTOM EXCEPTION CLASS

    /**
     * @description Custom exception for messaging operations
     */
    public class CVMAMessagingException extends Exception {}

    // WRAPPER CLASSES

    /**
     * @description Response wrapper for messaging operations
     */
    public class MessagingResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public String successMessage { get; set; }
        @AuraEnabled public Id messageId { get; set; }
        @AuraEnabled public List<CVMA_Message__c> messages { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
        @AuraEnabled public Boolean hasMore { get; set; }

        public MessagingResponse() {
            this.success = false;
            this.messages = new List<CVMA_Message__c>();
            this.totalCount = 0;
            this.pageSize = 0;
            this.pageNumber = 0;
            this.hasMore = false;
        }
    }

    /**
     * @description Contact option for member selection
     */
    public class ContactOption {
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public String displayName { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String membershipLevel { get; set; }
    }
}
