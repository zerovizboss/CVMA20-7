/**
 * @description Refactored CVMA Event RSVP Controller using Campaign Members instead of custom objects
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 *
 * This controller demonstrates Standard Feature Integration by leveraging Campaign Members
 * instead of the custom CVMA_Event_RSVP__c object for event RSVP functionality.
 */
public with sharing class CVMAEventRSVPControllerV2 {

    // Campaign Member Status values for RSVP responses
    public static final String STATUS_SENT = 'Sent';
    public static final String STATUS_RESPONDED_YES = 'Responded - Yes';
    public static final String STATUS_RESPONDED_NO = 'Responded - No';
    public static final String STATUS_RESPONDED_MAYBE = 'Responded - Maybe';
    public static final String STATUS_PLUS_ONE_YES = 'Plus One - Yes';

    /**
     * @description Get current user's RSVP status from Campaign Members
     * @param eventId The Campaign Id to check RSVP for
     * @return CampaignMember Current user's RSVP record or null
     */
    @AuraEnabled(cacheable=true)
    public static CampaignMember getCurrentUserRSVP(Id eventId) {
        try {
            // Validate parameters
            if (eventId == null) {
                throw new AuraHandledException('Event ID is required');
            }

            // Get current user's member record
            Contact currentMember = getCurrentMember();
            if (currentMember == null) {
                throw new AuraHandledException('Current user is not associated with a contact');
            }

            // Query Campaign Members with proper syntax
            List<CampaignMember> campaignMembers = [
                SELECT Id, CampaignId, ContactId, Status, CreatedDate, FirstRespondedDate,
                       Contact.Name, Campaign.Name
                FROM CampaignMember
                WHERE CampaignId = :eventId
                AND ContactId = :currentMember.Id
                AND Status IN (:STATUS_RESPONDED_YES, :STATUS_RESPONDED_NO, :STATUS_RESPONDED_MAYBE, :STATUS_PLUS_ONE_YES)
                WITH SECURITY_ENFORCED
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];

            return campaignMembers.isEmpty() ? null : campaignMembers[0];

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPControllerV2', 'getCurrentUserRSVP',
                                           CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Unable to retrieve RSVP status: ' + e.getMessage());
        }
    }

    /**
     * @description Submit or update RSVP for an event using Campaign Member status
     * @param eventId The Campaign Id to RSVP for
     * @param response RSVP response (Yes/No/Maybe)
     * @param notes Additional notes (not stored in Campaign Member)
     * @param bringPlusOne Whether bringing a plus one
     * @param plusOneName Name of plus one guest
     * @return Boolean Success status
     */
    @AuraEnabled
    public static Boolean submitRSVP(Id eventId, String response, String notes, Boolean bringPlusOne, String plusOneName) {
        try {
            // Validate parameters
            if (eventId == null || String.isBlank(response)) {
                throw new AuraHandledException('Event ID and response are required');
            }

            // Get current member
            Contact currentMember = getCurrentMember();
            if (currentMember == null) {
                throw new AuraHandledException('Current user is not associated with a contact');
            }

            // Validate CRUD permissions
            CVMAErrorHandler.validateCRUDPermissions(
                CampaignMember.getSObjectType(),
                new List<String>{'CampaignId', 'ContactId', 'Status'},
                'create'
            );

            // Check if member already exists in campaign
            List<CampaignMember> existingMembers = [
                SELECT Id, Status
                FROM CampaignMember
                WHERE CampaignId = :eventId
                AND ContactId = :currentMember.Id
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            String campaignMemberStatus = mapResponseToCampaignMemberStatus(response);
            CampaignMember member;

            if (existingMembers.isEmpty()) {
                // Create new Campaign Member
                member = new CampaignMember();
                member.CampaignId = eventId;
                member.ContactId = currentMember.Id;
                member.Status = campaignMemberStatus;

                insert member;
            } else {
                // Update existing Campaign Member
                member = existingMembers[0];
                member.Status = campaignMemberStatus;

                update member;
            }

            // Handle plus one separately if needed
            if (bringPlusOne != null && bringPlusOne) {
                handlePlusOneRSVP(eventId, currentMember.Id, bringPlusOne, plusOneName);
            }

            return true;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPControllerV2', 'submitRSVP',
                                           CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Unable to submit RSVP: ' + e.getMessage());
        }
    }

    /**
     * @description Get RSVP summary for an event from Campaign Member aggregates
     * @param eventId The Campaign Id to get summary for
     * @return Map<String, Object> RSVP summary data
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRSVPSummary(Id eventId) {
        try {
            if (eventId == null) {
                throw new AuraHandledException('Event ID is required');
            }

            // Validate CRUD permissions
            CVMAErrorHandler.validateCRUDPermissions(
                CampaignMember.getSObjectType(),
                new List<String>{'CampaignId', 'Status'},
                'read'
            );

            // Get Campaign Member count by status
            List<AggregateResult> rsvpCounts = [
                SELECT Status, COUNT(Id) memberCount
                FROM CampaignMember
                WHERE CampaignId = :eventId
                WITH SECURITY_ENFORCED
                GROUP BY Status
            ];

            Map<String, Object> summary = new Map<String, Object>();
            Integer yesCount = 0;
            Integer noCount = 0;
            Integer maybeCount = 0;
            Integer plusOneCount = 0;
            Integer totalResponses = 0;

            for (AggregateResult result : rsvpCounts) {
                String status = (String) result.get('Status');
                Integer count = (Integer) result.get('memberCount');

                switch on status {
                    when 'Responded - Yes' {
                        yesCount = count;
                        totalResponses += count;
                    }
                    when 'Responded - No' {
                        noCount = count;
                        totalResponses += count;
                    }
                    when 'Responded - Maybe' {
                        maybeCount = count;
                        totalResponses += count;
                    }
                    when 'Plus One - Yes' {
                        plusOneCount = count;
                    }
                }
            }

            summary.put('yesCount', yesCount);
            summary.put('noCount', noCount);
            summary.put('maybeCount', maybeCount);
            summary.put('plusOneCount', plusOneCount);
            summary.put('totalResponses', totalResponses);
            summary.put('attendingCount', yesCount + plusOneCount);

            return summary;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPControllerV2', 'getRSVPSummary',
                                           CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Unable to retrieve RSVP summary: ' + e.getMessage());
        }
    }

    /**
     * @description Get current member record for the logged in user
     * @return Contact Current user's contact record
     */
    private static Contact getCurrentMember() {
        try {
            User currentUser = [
                SELECT Id, ContactId
                FROM User
                WHERE Id = :UserInfo.getUserId()
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (currentUser.ContactId != null) {
                List<Contact> contacts = [
                    SELECT Id, Name, Email
                    FROM Contact
                    WHERE Id = :currentUser.ContactId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];

                return contacts.isEmpty() ? null : contacts[0];
            }

            return null;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPControllerV2', 'getCurrentMember',
                                           CVMAErrorHandler.Category.BUSINESS_LOGIC);
            return null;
        }
    }

    /**
     * @description Map RSVP response to Campaign Member Status
     */
    private static String mapResponseToCampaignMemberStatus(String response) {
        switch on response {
            when 'Yes', 'Responded - Yes' {
                return STATUS_RESPONDED_YES;
            }
            when 'No', 'Responded - No' {
                return STATUS_RESPONDED_NO;
            }
            when 'Maybe', 'Responded - Maybe' {
                return STATUS_RESPONDED_MAYBE;
            }
            when else {
                return STATUS_SENT;
            }
        }
    }

    /**
     * @description Handle plus one RSVP by creating/updating separate Campaign Member record
     */
    private static void handlePlusOneRSVP(Id campaignId, Id contactId, Boolean bringPlusOne, String plusOneName) {
        try {
            // Check for existing plus one record
            List<CampaignMember> existingPlusOne = [
                SELECT Id
                FROM CampaignMember
                WHERE CampaignId = :campaignId
                AND ContactId = :contactId
                AND Status = :STATUS_PLUS_ONE_YES
                WITH SECURITY_ENFORCED
            ];

            if (bringPlusOne && String.isNotBlank(plusOneName)) {
                if (existingPlusOne.isEmpty()) {
                    // Create new plus one record
                    CampaignMember plusOneMember = new CampaignMember();
                    plusOneMember.CampaignId = campaignId;
                    plusOneMember.ContactId = contactId;
                    plusOneMember.Status = STATUS_PLUS_ONE_YES;

                    insert plusOneMember;
                }
                // If already exists, no need to update

            } else if (!existingPlusOne.isEmpty()) {
                // Remove plus one if no longer bringing one
                delete existingPlusOne;
            }

        } catch (Exception e) {
            // Log but don't fail the main RSVP process
            CVMAErrorHandler.handleException(e, 'CVMAEventRSVPControllerV2', 'handlePlusOneRSVP',
                                           CVMAErrorHandler.Category.BUSINESS_LOGIC);
        }
    }

    /**
     * @description Get available response options for RSVP
     * @return List<Map<String, String>> List of response options
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRSVPResponseOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        options.add(new Map<String, String>{
            'label' => 'Yes - I\'ll be there',
            'value' => 'Yes'
        });

        options.add(new Map<String, String>{
            'label' => 'No - Can\'t make it',
            'value' => 'No'
        });

        options.add(new Map<String, String>{
            'label' => 'Maybe - Not sure yet',
            'value' => 'Maybe'
        });

        return options;
    }
}
