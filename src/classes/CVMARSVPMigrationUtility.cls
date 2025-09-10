/**
 * @description Utility class for migrating CVMA_Event_RSVP__c records to Campaign Members
 * @author Claude AI - CVMA Development Team
 * @date 2025-09-10
 * 
 * Migration process:
 * 1. Query all CVMA_Event_RSVP__c records
 * 2. Create corresponding Campaign Members with appropriate status
 * 3. Preserve original data in custom fields
 * 4. Generate migration report
 */
public with sharing class CVMARSVPMigrationUtility {
    
    // Migration status tracking
    public class MigrationResult {
        @AuraEnabled public Integer totalRSVPs { get; set; }
        @AuraEnabled public Integer migratedRSVPs { get; set; }
        @AuraEnabled public Integer failedRSVPs { get; set; }
        @AuraEnabled public List<String> errorMessages { get; set; }
        @AuraEnabled public String migrationDate { get; set; }
        
        public MigrationResult() {
            this.errorMessages = new List<String>();
            this.migrationDate = Datetime.now().format();
        }
    }
    
    // RSVP to Campaign Member Status mapping
    private static final Map<String, String> RSVP_STATUS_MAPPING = new Map<String, String>{
        'Yes' => 'Responded - Yes',
        'No' => 'Responded - No',
        'Maybe' => 'Responded - Maybe'
    };
    
    /**
     * @description Execute RSVP migration from custom objects to Campaign Members
     * @param dryRun If true, validate migration without making changes
     * @return MigrationResult with migration statistics and any errors
     */
    @AuraEnabled
    public static MigrationResult migrateRSVPToCampaignMembers(Boolean dryRun) {
        MigrationResult result = new MigrationResult();
        
        try {
            // Validate user permissions
            validateMigrationPermissions();
            
            // Get all RSVP records to migrate
            List<CVMA_Event_RSVP__c> rsvpRecords = getAllRSVPRecords();
            result.totalRSVPs = rsvpRecords.size();
            
            CVMAErrorHandler.log('Starting RSVP migration', 'CVMARSVPMigrationUtility.migrateRSVPToCampaignMembers', 
                                CVMAErrorHandler.LogLevel.INFO, null);
            
            // Process migration in batches
            List<CampaignMember> campaignMembersToInsert = new List<CampaignMember>();
            
            for (CVMA_Event_RSVP__c rsvp : rsvpRecords) {
                try {
                    CampaignMember cm = createCampaignMemberFromRSVP(rsvp);
                    if (cm != null) {
                        campaignMembersToInsert.add(cm);
                    }
                } catch (Exception e) {
                    result.failedRSVPs++;
                    result.errorMessages.add('RSVP ' + rsvp.Id + ': ' + e.getMessage());
                    CVMAErrorHandler.handleException(e, 'CVMARSVPMigrationUtility.migrateRSVPToCampaignMembers');
                }
            }
            
            // Insert Campaign Members if not dry run
            if (!dryRun && !campaignMembersToInsert.isEmpty()) {
                Database.SaveResult[] saveResults = Database.insert(campaignMembersToInsert, false);
                
                for (Integer i = 0; i < saveResults.size(); i++) {
                    if (saveResults[i].isSuccess()) {
                        result.migratedRSVPs++;
                    } else {
                        result.failedRSVPs++;
                        String errorMsg = 'Campaign Member creation failed: ';
                        for (Database.Error err : saveResults[i].getErrors()) {
                            errorMsg += err.getMessage() + '; ';
                        }
                        result.errorMessages.add(errorMsg);
                    }
                }
            } else if (dryRun) {
                result.migratedRSVPs = campaignMembersToInsert.size();
                result.errorMessages.add('DRY RUN: ' + campaignMembersToInsert.size() + ' Campaign Members would be created');
            }
            
            CVMAErrorHandler.log('RSVP migration completed', 'CVMARSVPMigrationUtility.migrateRSVPToCampaignMembers', 
                                CVMAErrorHandler.LogLevel.INFO, null);
            
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARSVPMigrationUtility.migrateRSVPToCampaignMembers');
            result.errorMessages.add('Migration failed: ' + e.getMessage());
            result.failedRSVPs = result.totalRSVPs;
        }
        
        return result;
    }
    
    /**
     * @description Create Campaign Member record from RSVP record
     * @param rsvp The RSVP record to convert
     * @return CampaignMember record ready for insertion
     */
    private static CampaignMember createCampaignMemberFromRSVP(CVMA_Event_RSVP__c rsvp) {
        if (rsvp.Event__c == null || rsvp.Member__c == null) {
            throw new CVMAErrorHandler.ValidationException('RSVP missing required Event or Member reference');
        }
        
        CampaignMember cm = new CampaignMember();
        cm.CampaignId = rsvp.Event__c;
        cm.ContactId = rsvp.Member__c;
        
        // Map RSVP response to Campaign Member status
        String mappedStatus = RSVP_STATUS_MAPPING.get(rsvp.Response__c);
        if (mappedStatus == null) {
            throw new CVMAErrorHandler.ValidationException('Unknown RSVP response: ' + rsvp.Response__c);
        }
        
        // Handle plus one responses
        if (rsvp.Response__c == 'Yes' && rsvp.Plus_One__c == true) {
            cm.Status = 'Plus One - Yes';
        } else {
            cm.Status = mappedStatus;
        }
        
        // Set custom fields
        cm.put('CVMA_Plus_One__c', rsvp.Plus_One__c);
        cm.put('CVMA_Plus_One_Name__c', rsvp.Plus_One_Name__c);
        cm.put('CVMA_RSVP_Notes__c', rsvp.Notes__c);
        cm.put('CVMA_Original_RSVP_Date__c', rsvp.RSVP_Date__c);
        
        return cm;
    }
    
    /**
     * @description Get all RSVP records for migration
     * @return List of RSVP records
     */
    private static List<CVMA_Event_RSVP__c> getAllRSVPRecords() {
        return [
            SELECT Id, Event__c, Member__c, Response__c, Plus_One__c, 
                   Plus_One_Name__c, Notes__c, RSVP_Date__c, CreatedDate
            FROM CVMA_Event_RSVP__c
            WHERE Event__c != null AND Member__c != null
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate
        ];
    }
    
    /**
     * @description Validate user has required permissions for migration
     */
    private static void validateMigrationPermissions() {
        // Check RSVP object permissions
        CVMAErrorHandler.validateCRUDPermissions(
            CVMA_Event_RSVP__c.getSObjectType(),
            new List<String>{'Event__c', 'Member__c', 'Response__c'},
            'read'
        );
        
        // Check Campaign Member permissions
        CVMAErrorHandler.validateCRUDPermissions(
            CampaignMember.getSObjectType(),
            new List<String>{'CampaignId', 'ContactId', 'Status'},
            'create'
        );
    }
    
    /**
     * @description Generate migration status report
     * @return Map containing migration statistics
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getMigrationStatus() {
        Map<String, Object> status = new Map<String, Object>();
        
        try {
            // Count existing RSVPs
            Integer rsvpCount = [SELECT COUNT() FROM CVMA_Event_RSVP__c WITH SECURITY_ENFORCED];
            
            // Count existing Campaign Members with CVMA fields
            Integer campaignMemberCount = 0;
            try {
                campaignMemberCount = [
                    SELECT COUNT() 
                    FROM CampaignMember 
                    WHERE CVMA_Original_RSVP_Date__c != null 
                    WITH SECURITY_ENFORCED
                ];
            } catch (Exception e) {
                // Custom fields may not exist yet
                campaignMemberCount = 0;
            }
            
            status.put('totalRSVPs', rsvpCount);
            status.put('migratedCampaignMembers', campaignMemberCount);
            status.put('migrationNeeded', rsvpCount > campaignMemberCount);
            status.put('lastChecked', Datetime.now().format());
            
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARSVPMigrationUtility.getMigrationStatus');
            status.put('error', e.getMessage());
        }
        
        return status;
    }
}
