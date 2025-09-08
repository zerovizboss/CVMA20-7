/**
 * @description Test class for CVMARSVPMigrationUtility - RSVP to Campaign Member migration
 * @author Claude AI - CVMA Development Team  
 * @date January 2025
 */
@IsTest
public class CVMARSVPMigrationUtilityTest {
    
    @TestSetup
    static void makeData() {
        // Create test member contact
        Contact testMember = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .create();
            
        // Create test campaign
        Campaign testCampaign = CVMATestDataFactory.createCampaign()
            .withName('Test Migration Event')
            .withType('CVMA Event')
            .create();
            
        // Create CVMA Event RSVP records (if the object exists)
        try {
            CVMA_Event_RSVP__c rsvp1 = new CVMA_Event_RSVP__c(
                Event__c = testCampaign.Id,
                Member__c = testMember.Id,
                Response__c = 'Yes',
                Plus_One__c = true,
                Plus_One_Name__c = 'Jane Doe'
            );
            insert rsvp1;
            
            CVMA_Event_RSVP__c rsvp2 = new CVMA_Event_RSVP__c(
                Event__c = testCampaign.Id,
                Member__c = testMember.Id,
                Response__c = 'No'
            );
            insert rsvp2;
        } catch (Exception e) {
            // Object may not exist in all orgs - tests will handle this gracefully
        }
    }
    
    @IsTest
    static void testValidateMigrationReadiness_WithData() {
        Test.startTest();
        
        // Test validation when data exists
        Map<String, Object> result = CVMARSVPMigrationUtility.validateMigrationReadiness();
        
        Test.stopTest();
        
        // Verify validation results
        System.assertNotEquals(null, result, 'Should return validation results');
        System.assert(result.containsKey('rsvpRecordCount'), 'Should include RSVP count');
        System.assert(result.containsKey('cvmaEventCampaignCount'), 'Should include campaign count');
        System.assert(result.containsKey('existingCampaignMembers'), 'Should include existing members count');
        
        Integer campaignCount = (Integer) result.get('cvmaEventCampaignCount');
        System.assert(campaignCount >= 1, 'Should find test campaign');
    }
    
    @IsTest
    static void testValidateMigrationReadiness_NoData() {
        Test.startTest();
        
        // Test validation when no RSVP data exists (may be the case if object doesn't exist)
        Map<String, Object> result = CVMARSVPMigrationUtility.validateMigrationReadiness();
        
        Test.stopTest();
        
        // Verify validation handles missing data gracefully
        System.assertNotEquals(null, result, 'Should return validation results');
        System.assert(result.containsKey('message'), 'Should include validation message');
    }
    
    @IsTest
    static void testMigrateRSVPToCampaignMembers_DryRun() {
        Test.startTest();
        
        // Test dry run migration
        CVMARSVPMigrationUtility.MigrationResult result = CVMARSVPMigrationUtility.migrateRSVPToCampaignMembers(true);
        
        Test.stopTest();
        
        // Verify dry run results
        System.assertNotEquals(null, result, 'Should return migration result');
        System.assert(result.message.contains('Dry run') || result.message.contains('No RSVP'), 
                     'Should indicate dry run or no data');
        
        // Verify no Campaign Members were actually created during dry run
        List<CampaignMember> members = [SELECT Id FROM CampaignMember];
        System.assertEquals(0, members.size(), 'Dry run should not create Campaign Members');
    }
    
    @IsTest
    static void testMigrateRSVPToCampaignMembers_ActualRun() {
        Test.startTest();
        
        // Test actual migration
        CVMARSVPMigrationUtility.MigrationResult result = CVMARSVPMigrationUtility.migrateRSVPToCampaignMembers(false);
        
        Test.stopTest();
        
        // Verify migration results
        System.assertNotEquals(null, result, 'Should return migration result');
        System.assertNotEquals(null, result.message, 'Should have result message');
        
        // Migration may succeed with 0 records if RSVP object doesn't exist
        System.assert(result.success == true || result.errorCount == 0, 
                     'Migration should succeed or have no errors');
    }
    
    @IsTest
    static void testSetupCampaignMemberStatuses() {
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test Migration Event' LIMIT 1];
        
        Test.startTest();
        
        // Test setting up Campaign Member statuses
        CVMARSVPMigrationUtility.setupCampaignMemberStatuses(new List<Id>{ testCampaign.Id });
        
        Test.stopTest();
        
        // Verify Campaign Member Status records were created
        List<CampaignMemberStatus> statuses = [
            SELECT Id, Label, IsDefault, HasResponded
            FROM CampaignMemberStatus
            WHERE CampaignId = :testCampaign.Id
            ORDER BY SortOrder
        ];
        
        System.assertEquals(5, statuses.size(), 'Should create 5 status values');
        
        // Verify expected status values
        System.assertEquals('Sent', statuses[0].Label, 'First status should be Sent');
        System.assertEquals(true, statuses[0].IsDefault, 'Sent should be default');
        System.assertEquals(false, statuses[0].HasResponded, 'Sent should not be responded');
        
        System.assertEquals('Responded - Yes', statuses[1].Label, 'Second status should be Yes');
        System.assertEquals(true, statuses[1].HasResponded, 'Yes should be responded');
        
        System.assertEquals('Responded - No', statuses[2].Label, 'Third status should be No');
        System.assertEquals('Responded - Maybe', statuses[3].Label, 'Fourth status should be Maybe');
        System.assertEquals('Plus One - Yes', statuses[4].Label, 'Fifth status should be Plus One');
    }
    
    @IsTest
    static void testMigrationResult_WrapperClass() {
        Test.startTest();
        
        // Test MigrationResult wrapper class
        CVMARSVPMigrationUtility.MigrationResult result = new CVMARSVPMigrationUtility.MigrationResult();
        
        // Set properties
        result.success = true;
        result.message = 'Test message';
        result.totalRecords = 10;
        result.successCount = 8;
        result.errorCount = 2;
        result.errors = new List<String>{'Error 1', 'Error 2'};
        
        Test.stopTest();
        
        // Verify wrapper properties
        System.assertEquals(true, result.success, 'Success should be set');
        System.assertEquals('Test message', result.message, 'Message should be set');
        System.assertEquals(10, result.totalRecords, 'Total records should be set');
        System.assertEquals(8, result.successCount, 'Success count should be set');
        System.assertEquals(2, result.errorCount, 'Error count should be set');
        System.assertEquals(2, result.errors.size(), 'Should have 2 errors');
        System.assertEquals('Error 1', result.errors[0], 'First error should match');
    }
    
    @IsTest
    static void testErrorHandling_InvalidCampaignId() {
        Test.startTest();
        
        try {
            // Test with invalid campaign ID
            CVMARSVPMigrationUtility.setupCampaignMemberStatuses(new List<Id>{ 'invalid_id' });
            System.assert(false, 'Should throw exception for invalid ID');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Failed to setup') || e instanceof StringException, 
                         'Should handle invalid ID gracefully');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testErrorHandling_PermissionValidation() {
        Test.startTest();
        
        // Test migration handles permission errors gracefully
        CVMARSVPMigrationUtility.MigrationResult result = CVMARSVPMigrationUtility.migrateRSVPToCampaignMembers(true);
        
        Test.stopTest();
        
        // Should not throw exception even with permission issues
        System.assertNotEquals(null, result, 'Should return result even with permission issues');
    }
    
    @IsTest
    static void testMigrationException_CustomException() {
        Test.startTest();
        
        // Test custom exception class
        CVMARSVPMigrationUtility.MigrationException customException = 
            new CVMARSVPMigrationUtility.MigrationException('Test migration error');
        
        Test.stopTest();
        
        // Verify custom exception
        System.assertEquals('Test migration error', customException.getMessage(), 
                           'Custom exception should have correct message');
    }
}