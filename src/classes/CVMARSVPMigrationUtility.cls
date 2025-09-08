/**
 * @description Utility class for migrating CVMA Event RSVP data from custom object to Campaign Members
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 *
 * This utility handles the migration from CVMA_Event_RSVP__c custom object to standard Campaign Member
 * status values as part of the Standard Feature Integration initiative.
 */
public with sharing class CVMARSVPMigrationUtility {

    public class MigrationException extends Exception {}

    // Campaign Member Status mapping for RSVP responses
    private static final String STATUS_RESPONDED_YES = 'Responded - Yes';
    private static final String STATUS_RESPONDED_NO = 'Responded - No';
    private static final String STATUS_RESPONDED_MAYBE = 'Responded - Maybe';
    private static final String STATUS_PLUS_ONE_YES = 'Plus One - Yes';
    private static final String STATUS_SENT = 'Sent';

    /**
     * @description Migration wrapper class for tracking progress and results
     */
    public class MigrationResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Integer totalRecords { get; set; }
        @AuraEnabled public Integer successCount { get; set; }
        @AuraEnabled public Integer errorCount { get; set; }
        @AuraEnabled public List<String> errors { get; set; }

        public MigrationResult() {
            this.success = false;
            this.totalRecords = 0;
            this.successCount = 0;
            this.errorCount = 0;
            this.errors = new List<String>();
        }
    }

    /**
     * @description Migrate all CVMA Event RSVP records to Campaign Members
     * @param dryRun If true, only validate the migration without creating records
     * @return MigrationResult Migration progress and results
     */
    @AuraEnabled
    public static MigrationResult migrateRSVPToCampaignMembers(Boolean dryRun) {
        MigrationResult result = new MigrationResult();

        try {
            // Validate permissions
            CVMAErrorHandler.validateCRUDPermissions(
                CVMA_Event_RSVP__c.getSObjectType(),
                new List<String>{'Event__c', 'Member__c', 'Response__c'},
                'read'
            );

            CVMAErrorHandler.validateCRUDPermissions(
                CampaignMember.getSObjectType(),
                new List<String>{'CampaignId', 'ContactId', 'Status'},
                'create'
            );

            // Get all RSVP records
            List<CVMA_Event_RSVP__c> rsvpRecords = [
                SELECT Id, Event__c, Member__c, Response__c, RSVP_Date__c,
                       Notes__c, Plus_One__c, Plus_One_Name__c,
                       Event__r.Name, Member__r.Name
                FROM CVMA_Event_RSVP__c
                WHERE Event__c != null
                AND Member__c != null
                WITH SECURITY_ENFORCED
            ];

            result.totalRecords = rsvpRecords.size();

            if (result.totalRecords == 0) {
                result.success = true;
                result.message = 'No RSVP records found to migrate.';
                return result;
            }

            // Group RSVPs by Campaign to batch process
            Map<Id, List<CVMA_Event_RSVP__c>> rsvpsByCampaign = groupRSVPsByCampaign(rsvpRecords);

            List<CampaignMember> campaignMembersToInsert = new List<CampaignMember>();

            for (Id campaignId : rsvpsByCampaign.keySet()) {
                List<CVMA_Event_RSVP__c> campaignRSVPs = rsvpsByCampaign.get(campaignId);

                // Create Campaign Members for this Campaign
                List<CampaignMember> campaignMembers = createCampaignMembersFromRSVPs(campaignId, campaignRSVPs);
                campaignMembersToInsert.addAll(campaignMembers);
            }

            if (!dryRun && !campaignMembersToInsert.isEmpty()) {
                // Insert Campaign Members
                List<Database.SaveResult> saveResults = Database.insert(campaignMembersToInsert, false);

                // Process results
                for (Integer i = 0; i < saveResults.size(); i++) {
                    if (saveResults[i].isSuccess()) {
                        result.successCount++;
                    } else {
                        result.errorCount++;
                        String errorMsg = 'Record ' + i + ': ';
                        for (Database.Error error : saveResults[i].getErrors()) {
                            errorMsg += error.getMessage() + '; ';
                        }
                        result.errors.add(errorMsg);
                    }
                }
            } else if (dryRun) {
                result.successCount = campaignMembersToInsert.size();
                result.message = 'Dry run completed. ' + result.successCount + ' Campaign Members would be created.';
            }

            result.success = (result.errorCount == 0);

            if (result.success && !dryRun) {
                result.message = 'Successfully migrated ' + result.successCount + ' RSVP records to Campaign Members.';
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARSVPMigrationUtility', 'migrateRSVPToCampaignMembers',
                                           CVMAErrorHandler.Category.BUSINESS_LOGIC);
            result.success = false;
            result.message = 'Migration failed: ' + e.getMessage();
            result.errors.add(e.getMessage());
        }

        return result;
    }

    /**
     * @description Group RSVP records by Campaign for batch processing
     */
    private static Map<Id, List<CVMA_Event_RSVP__c>> groupRSVPsByCampaign(List<CVMA_Event_RSVP__c> rsvpRecords) {
        Map<Id, List<CVMA_Event_RSVP__c>> rsvpsByCampaign = new Map<Id, List<CVMA_Event_RSVP__c>>();

        for (CVMA_Event_RSVP__c rsvp : rsvpRecords) {
            if (!rsvpsByCampaign.containsKey(rsvp.Event__c)) {
                rsvpsByCampaign.put(rsvp.Event__c, new List<CVMA_Event_RSVP__c>());
            }
            rsvpsByCampaign.get(rsvp.Event__c).add(rsvp);
        }

        return rsvpsByCampaign;
    }

    /**
     * @description Create Campaign Members from RSVP records for a specific Campaign
     */
    private static List<CampaignMember> createCampaignMembersFromRSVPs(Id campaignId, List<CVMA_Event_RSVP__c> rsvps) {
        List<CampaignMember> campaignMembers = new List<CampaignMember>();

        for (CVMA_Event_RSVP__c rsvp : rsvps) {
            // Create primary Campaign Member for the RSVP response
            CampaignMember primaryMember = new CampaignMember();
            primaryMember.CampaignId = campaignId;
            primaryMember.ContactId = rsvp.Member__c;
            primaryMember.Status = mapRSVPResponseToCampaignMemberStatus(rsvp.Response__c);

            campaignMembers.add(primaryMember);

            // If there's a plus one, create additional Campaign Member
            if (rsvp.Plus_One__c && String.isNotBlank(rsvp.Plus_One_Name__c)) {
                // For plus ones, we'll create a separate record with special status
                // This maintains the plus one tracking capability
                CampaignMember plusOneMember = new CampaignMember();
                plusOneMember.CampaignId = campaignId;
                plusOneMember.ContactId = rsvp.Member__c; // Same contact, different status
                plusOneMember.Status = STATUS_PLUS_ONE_YES;

                campaignMembers.add(plusOneMember);
            }
        }

        return campaignMembers;
    }

    /**
     * @description Map RSVP Response values to Campaign Member Status values
     */
    private static String mapRSVPResponseToCampaignMemberStatus(String rsvpResponse) {
        switch on rsvpResponse {
            when 'Yes' {
                return STATUS_RESPONDED_YES;
            }
            when 'No' {
                return STATUS_RESPONDED_NO;
            }
            when 'Maybe' {
                return STATUS_RESPONDED_MAYBE;
            }
            when else {
                return STATUS_SENT; // Default status
            }
        }
    }

    /**
     * @description Setup Campaign Member Status values for CVMA events
     * This method creates the required status values for each Campaign marked as CVMA event
     * @param campaignIds List of Campaign IDs to configure
     */
    @AuraEnabled
    public static void setupCampaignMemberStatuses(List<Id> campaignIds) {
        try {
            CVMAErrorHandler.validateCRUDPermissions(
                CampaignMemberStatus.getSObjectType(),
                new List<String>{'CampaignId', 'Label', 'IsDefault', 'HasResponded'},
                'create'
            );

            List<CampaignMemberStatus> statusesToCreate = new List<CampaignMemberStatus>();

            for (Id campaignId : campaignIds) {
                // Create required status values
                statusesToCreate.addAll(createCampaignMemberStatusesForCampaign(campaignId));
            }

            if (!statusesToCreate.isEmpty()) {
                insert statusesToCreate;
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARSVPMigrationUtility', 'setupCampaignMemberStatuses',
                                           CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Failed to setup Campaign Member statuses: ' + e.getMessage());
        }
    }

    /**
     * @description Create Campaign Member Status records for a specific Campaign
     */
    private static List<CampaignMemberStatus> createCampaignMemberStatusesForCampaign(Id campaignId) {
        List<CampaignMemberStatus> statuses = new List<CampaignMemberStatus>();

        // Sent (default, not responded)
        statuses.add(new CampaignMemberStatus(
            CampaignId = campaignId,
            Label = 'Sent',
            IsDefault = true,
            HasResponded = false,
            SortOrder = 1
        ));

        // Responded - Yes
        statuses.add(new CampaignMemberStatus(
            CampaignId = campaignId,
            Label = 'Responded - Yes',
            IsDefault = false,
            HasResponded = true,
            SortOrder = 2
        ));

        // Responded - No
        statuses.add(new CampaignMemberStatus(
            CampaignId = campaignId,
            Label = 'Responded - No',
            IsDefault = false,
            HasResponded = true,
            SortOrder = 3
        ));

        // Responded - Maybe
        statuses.add(new CampaignMemberStatus(
            CampaignId = campaignId,
            Label = 'Responded - Maybe',
            IsDefault = false,
            HasResponded = true,
            SortOrder = 4
        ));

        // Plus One - Yes
        statuses.add(new CampaignMemberStatus(
            CampaignId = campaignId,
            Label = 'Plus One - Yes',
            IsDefault = false,
            HasResponded = true,
            SortOrder = 5
        ));

        return statuses;
    }

    /**
     * @description Validate migration readiness by checking existing data
     * @return Map<String, Object> Validation results and recommendations
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> validateMigrationReadiness() {
        Map<String, Object> validationResult = new Map<String, Object>();

        try {
            // Count existing RSVP records
            Integer rsvpCount = [SELECT COUNT() FROM CVMA_Event_RSVP__c WITH SECURITY_ENFORCED];

            // Count campaigns that could be events
            Integer campaignCount = [SELECT COUNT() FROM Campaign WHERE Type = 'CVMA Event' WITH SECURITY_ENFORCED];

            // Check for existing Campaign Members
            Integer existingCampaignMembers = [SELECT COUNT() FROM CampaignMember WITH SECURITY_ENFORCED];

            validationResult.put('rsvpRecordCount', rsvpCount);
            validationResult.put('cvmaEventCampaignCount', campaignCount);
            validationResult.put('existingCampaignMembers', existingCampaignMembers);
            validationResult.put('migrationRecommended', rsvpCount > 0);

            if (rsvpCount > 0) {
                validationResult.put('message', 'Migration ready: ' + rsvpCount + ' RSVP records can be migrated to Campaign Members.');
            } else {
                validationResult.put('message', 'No RSVP records found. Migration not needed.');
            }

        } catch (Exception e) {
            validationResult.put('error', e.getMessage());
        }

        return validationResult;
    }
}
