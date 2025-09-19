/**
 * @description Controller for CVMA Communication Hub Lightning Web Component
 * @author CVMA Development Team
 * @date 2024
 * @group Communication Hub
 */
public with sharing class CVMACommunicationHubController {

    /**
     * @description Custom exception for Communication Hub operations
     */
    public class CommunicationHubException extends Exception {}

    /**
     * @description Wrapper class for current user information
     */
    public class CurrentUserInfo {
        @AuraEnabled public String userId { get; set; }
        @AuraEnabled public String contactId { get; set; }
        @AuraEnabled public String userName { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public Boolean isOfficer { get; set; }
        @AuraEnabled public Boolean hasEmailAccess { get; set; }
    }

    /**
     * @description Wrapper class for communication records
     */
    public class CommunicationRecord {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String body { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public DateTime createdDate { get; set; }
        @AuraEnabled public String createdBy { get; set; }
        @AuraEnabled public String relatedRecordId { get; set; }
        @AuraEnabled public String relatedRecordName { get; set; }
    }

    /**
     * @description Wrapper class for Chatter group information
     */
    public class ChatterGroupInfo {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public Integer memberCount { get; set; }
        @AuraEnabled public DateTime lastPostDate { get; set; }
        @AuraEnabled public Boolean canPost { get; set; }
        @AuraEnabled public Boolean isManager { get; set; }
    }

    /**
     * @description Get current user information for communication hub
     * @return CurrentUserInfo Current user details
     */
    @AuraEnabled(cacheable=true)
    public static CurrentUserInfo getCurrentUser() {
        try {
            CVMAErrorHandler.validateCRUDPermissions('User', 'read');
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'read');

            User currentUser = [
                SELECT Id, ContactId, Name, Email, Profile.Name
                FROM User
                WHERE Id = :UserInfo.getUserId()
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            CurrentUserInfo userInfo = new CurrentUserInfo();
            userInfo.userId = currentUser.Id;
            userInfo.contactId = currentUser.ContactId;
            userInfo.userName = currentUser.Name;
            userInfo.email = currentUser.Email;
            userInfo.hasEmailAccess = true;

            // Check if user is an officer
            if (currentUser.ContactId != null) {
                List<Contact> contacts = [
                    SELECT Id, CVMA_Officer_Role__c
                    FROM Contact
                    WHERE Id = :currentUser.ContactId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];

                if (!contacts.isEmpty() && String.isNotBlank(contacts[0].CVMA_Officer_Role__c)) {
                    userInfo.isOfficer = true;
                } else {
                    userInfo.isOfficer = false;
                }
            } else {
                userInfo.isOfficer = false;
            }

            return userInfo;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACommunicationHubController.getCurrentUser');
            throw new CommunicationHubException('Failed to retrieve current user information: ' + e.getMessage());
        }
    }

    /**
     * @description Get recent communications for the user
     * @param contactId Contact ID to filter communications
     * @param recordId Optional record ID for related communications
     * @param limitSize Number of records to return
     * @return List<CommunicationRecord> Recent communications
     */
    @AuraEnabled
    public static List<CommunicationRecord> getRecentCommunications(Id contactId, Id recordId, Integer limitSize) {
        try {
            CVMAErrorHandler.validateCRUDPermissions('Task', 'read');
            CVMAErrorHandler.validateCRUDPermissions('EmailMessage', 'read');

            List<CommunicationRecord> communications = new List<CommunicationRecord>();
            Integer recordLimit = limitSize != null ? limitSize : 50;

            // Get email communications
            String emailQuery = 'SELECT Id, Subject, TextBody, FromAddress, ToAddress, MessageDate, ' +
                               'RelatedToId, CreatedBy.Name ' +
                               'FROM EmailMessage ' +
                               'WHERE ToAddress != null ' +
                               'WITH SECURITY_ENFORCED ';

            if (contactId != null) {
                emailQuery += 'AND (ToAddress INCLUDES :contactId OR RelatedToId = :contactId) ';
            }

            if (recordId != null) {
                emailQuery += 'AND RelatedToId = :recordId ';
            }

            emailQuery += 'ORDER BY MessageDate DESC ' +
                         'LIMIT :recordLimit';

            for (EmailMessage email : Database.query(emailQuery)) {
                CommunicationRecord comm = new CommunicationRecord();
                comm.id = email.Id;
                comm.subject = email.Subject;
                comm.body = email.TextBody;
                comm.type = 'Email';
                comm.priority = 'Normal';
                comm.status = 'Sent';
                comm.createdDate = email.MessageDate;
                comm.createdBy = email.CreatedBy?.Name;
                comm.relatedRecordId = email.RelatedToId;
                communications.add(comm);
            }

            // Get task-based communications
            String taskQuery = 'SELECT Id, Subject, Description, Type, Priority, Status, CreatedDate, ' +
                              'CreatedBy.Name, WhatId, What.Name, WhoId ' +
                              'FROM Task ' +
                              'WHERE Type = \'Email\' ';

            if (contactId != null) {
                taskQuery += 'AND WhoId = :contactId ';
            }

            if (recordId != null) {
                taskQuery += 'AND WhatId = :recordId ';
            }

            taskQuery += 'ORDER BY CreatedDate DESC ' +
                        'LIMIT :recordLimit ' +
                        'WITH SECURITY_ENFORCED';

            for (Task task : Database.query(taskQuery)) {
                CommunicationRecord comm = new CommunicationRecord();
                comm.id = task.Id;
                comm.subject = task.Subject;
                comm.body = task.Description;
                comm.type = determineCommunicationType(task.Subject, task.Description);
                comm.priority = task.Priority;
                comm.status = task.Status;
                comm.createdDate = task.CreatedDate;
                comm.createdBy = task.CreatedBy?.Name;
                comm.relatedRecordId = task.WhatId;
                comm.relatedRecordName = task.What?.Name;
                communications.add(comm);
            }

            // Sort all communications by date
            communications.sort(new CommunicationDateComparator());

            // Limit results
            if (communications.size() > recordLimit) {
                communications = new List<CommunicationRecord>(communications.subList(0, recordLimit));
            }

            return communications;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACommunicationHubController.getRecentCommunications');
            throw new CommunicationHubException('Failed to retrieve recent communications: ' + e.getMessage());
        }
    }

    /**
     * @description Get Chatter groups for the user
     * @param contactId Contact ID to get group memberships
     * @return List<ChatterGroupInfo> Chatter groups
     */
    @AuraEnabled
    public static List<ChatterGroupInfo> getChatterGroups(Id contactId) {
        try {
            CVMAErrorHandler.validateCRUDPermissions('CollaborationGroup', 'read');
            CVMAErrorHandler.validateCRUDPermissions('CollaborationGroupMember', 'read');

            List<ChatterGroupInfo> groups = new List<ChatterGroupInfo>();

            // Get user's group memberships
            List<CollaborationGroupMember> memberships = [
                SELECT CollaborationGroupId, CollaborationRole
                FROM CollaborationGroupMember
                WHERE MemberId = :UserInfo.getUserId()
                WITH SECURITY_ENFORCED
            ];

            if (memberships.isEmpty()) {
                return groups;
            }

            Set<Id> groupIds = new Set<Id>();
            Map<Id, String> groupRoles = new Map<Id, String>();

            for (CollaborationGroupMember membership : memberships) {
                groupIds.add(membership.CollaborationGroupId);
                groupRoles.put(membership.CollaborationGroupId, membership.CollaborationRole);
            }

            // Get group details
            List<CollaborationGroup> chatterGroups = [
                SELECT Id, Name, Description, MemberCount,
                       (SELECT Id, CreatedDate FROM FeedItems ORDER BY CreatedDate DESC LIMIT 1)
                FROM CollaborationGroup
                WHERE Id IN :groupIds
                WITH SECURITY_ENFORCED
                ORDER BY Name
            ];

            for (CollaborationGroup group : chatterGroups) {
                ChatterGroupInfo groupInfo = new ChatterGroupInfo();
                groupInfo.id = group.Id;
                groupInfo.name = group.Name;
                groupInfo.description = group.Description;
                groupInfo.memberCount = group.MemberCount;
                groupInfo.canPost = true;
                groupInfo.isManager = groupRoles.get(group.Id) == 'Admin';

                if (!group.FeedItems.isEmpty()) {
                    groupInfo.lastPostDate = group.FeedItems[0].CreatedDate;
                }

                groups.add(groupInfo);
            }

            return groups;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACommunicationHubController.getChatterGroups');
            throw new CommunicationHubException('Failed to retrieve Chatter groups: ' + e.getMessage());
        }
    }

    /**
     * @description Send a communication message
     * @param communicationType Type of communication
     * @param subject Message subject
     * @param body Message body
     * @param priority Message priority
     * @param recipientIds List of recipient contact IDs
     * @param senderId Sender contact ID
     * @return String Success message
     */
    @AuraEnabled
    public static String sendCommunication(String communicationType, String subject, String body,
                                         String priority, List<Id> recipientIds, Id senderId) {
        try {
            CVMAErrorHandler.validateCRUDPermissions('Task', 'create');

            // Validate inputs
            if (String.isBlank(subject) || String.isBlank(body)) {
                throw new CommunicationHubException('Subject and body are required');
            }

            if (recipientIds == null || recipientIds.isEmpty()) {
                throw new CommunicationHubException('At least one recipient is required');
            }

            // Sanitize inputs
            subject = CVMAErrorHandler.sanitizeInput(subject);
            body = CVMAErrorHandler.sanitizeInput(body);

            List<Task> communicationTasks = new List<Task>();

            for (Id recipientId : recipientIds) {
                Task commTask = new Task();
                commTask.Subject = subject;
                commTask.Description = body;
                commTask.Type = 'Email';
                commTask.Priority = priority;
                commTask.Status = 'Completed';
                commTask.ActivityDate = Date.today();
                commTask.WhoId = recipientId;
                communicationTasks.add(commTask);
            }

            insert communicationTasks;

            // Publish platform event
            CVMA_Communication_Event__e commEvent = new CVMA_Communication_Event__e();
            commEvent.Communication_Type__c = communicationType;
            commEvent.Priority__c = priority;
            commEvent.Content__c = body;
            commEvent.Integration_Source__c = 'Epic #6 - Communication Hub';

            EventBus.publish(commEvent);

            return 'Communication sent successfully to ' + recipientIds.size() + ' recipients';

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACommunicationHubController.sendCommunication');
            throw new CommunicationHubException('Failed to send communication: ' + e.getMessage());
        }
    }

    /**
     * @description Determine communication type based on content
     * @param subject Email subject
     * @param body Email body
     * @return String Communication type
     */
    private static String determineCommunicationType(String subject, String body) {
        if (String.isBlank(subject) && String.isBlank(body)) {
            return 'General Communication';
        }

        String content = (subject + ' ' + body).toLowerCase();

        if (content.contains('event') || content.contains('rsvp')) {
            return 'Event Communication';
        } else if (content.contains('donation') || content.contains('payment')) {
            return 'Financial Communication';
        } else if (content.contains('membership') || content.contains('application')) {
            return 'Membership Communication';
        } else if (content.contains('birthday') || content.contains('anniversary')) {
            return 'Member Recognition';
        } else if (content.contains('urgent') || content.contains('emergency')) {
            return 'Emergency Notification';
        } else {
            return 'Chapter Announcement';
        }
    }

    /**
     * @description Comparator class for sorting communications by date
     */
    public class CommunicationDateComparator implements Comparator<CommunicationRecord> {
        public Integer compare(CommunicationRecord a, CommunicationRecord b) {
            if (a.createdDate == b.createdDate) return 0;
            if (a.createdDate > b.createdDate) return -1;
            return 1;
        }
    }
}
