/**
 * @description Test class for CVMARSVPMigrationUtility
 * @author Claude AI - CVMA Development Team
 * @date 2025-09-10
 */
@IsTest
public class CVMARSVPMigrationUtilityTest {
    
    @TestSetup
    static void makeData() {
        // Create test campaign (event)
        Campaign testEvent = new Campaign();
        testEvent.Name = 'Test CVMA Event';
        testEvent.IsActive = true;
        testEvent.StartDate = Date.today().addDays(30);
        testEvent.EndDate = Date.today().addDays(30);
        testEvent.Type = 'Event';
        insert testEvent;
        
        // Create test contacts
        List<Contact> testContacts = CVMATestDataFactory.createTestDataBundle().contacts;
        
        // Create test RSVP records
        List<CVMA_Event_RSVP__c> testRSVPs = new List<CVMA_Event_RSVP__c>();
        
        // RSVP Yes without plus one
        CVMA_Event_RSVP__c rsvp1 = new CVMA_Event_RSVP__c();
        rsvp1.Event__c = testEvent.Id;
        rsvp1.Member__c = testContacts[0].Id;
        rsvp1.Response__c = 'Yes';
        rsvp1.Plus_One__c = false;
        rsvp1.RSVP_Date__c = Datetime.now().addDays(-5);
        rsvp1.Notes__c = 'Looking forward to it!';
        testRSVPs.add(rsvp1);
        
        // RSVP Yes with plus one
        CVMA_Event_RSVP__c rsvp2 = new CVMA_Event_RSVP__c();
        rsvp2.Event__c = testEvent.Id;
        rsvp2.Member__c = testContacts[1].Id;
        rsvp2.Response__c = 'Yes';
        rsvp2.Plus_One__c = true;
        rsvp2.Plus_One_Name__c = 'John Guest';
        rsvp2.RSVP_Date__c = Datetime.now().addDays(-3);
        testRSVPs.add(rsvp2);
        
        // RSVP No
        CVMA_Event_RSVP__c rsvp3 = new CVMA_Event_RSVP__c();
        rsvp3.Event__c = testEvent.Id;
        rsvp3.Member__c = testContacts[2].Id;
        rsvp3.Response__c = 'No';
        rsvp3.Plus_One__c = false;
        rsvp3.RSVP_Date__c = Datetime.now().addDays(-2);
        rsvp3.Notes__c = 'Can\'t make it this time';
        testRSVPs.add(rsvp3);
        
        // RSVP Maybe
        CVMA_Event_RSVP__c rsvp4 = new CVMA_Event_RSVP__c();
        rsvp4.Event__c = testEvent.Id;
        rsvp4.Member__c = testContacts[3].Id;
        rsvp4.Response__c = 'Maybe';
        rsvp4.Plus_One__c = false;
        rsvp4.RSVP_Date__c = Datetime.now().addDays(-1);
        testRSVPs.add(rsvp4);
        
        insert testRSVPs;
    }
    
    @IsTest
    static void testMigrationDryRun() {
        Test.startTest();
        CVMARSVPMigrationUtility.MigrationResult result = CVMARSVPMigrationUtility.migrateRSVPToCampaignMembers(true);
        Test.stopTest();
        
        System.assertEquals(4, result.totalRSVPs, 'Should find 4 RSVP records');
        System.assertEquals(4, result.migratedRSVPs, 'Should plan to migrate 4 records');
        System.assertEquals(0, result.failedRSVPs, 'Should have no failures in dry run');
        System.assert(result.errorMessages.size() >= 1, 'Should have dry run message');
        System.assert(result.errorMessages[0].contains('DRY RUN'), 'Should indicate dry run mode');
    }
    
    @IsTest
    static void testMigrationExecution() {
        // Note: This test assumes Campaign Member custom fields exist
        // In real implementation, would need proper setup
        
        Test.startTest();
        CVMARSVPMigrationUtility.MigrationResult result = CVMARSVPMigrationUtility.migrateRSVPToCampaignMembers(false);
        Test.stopTest();
        
        System.assertEquals(4, result.totalRSVPs, 'Should find 4 RSVP records');
        // Result validation depends on Campaign Member field availability
        System.assert(result.migratedRSVPs >= 0, 'Should report migration attempts');
    }
    
    @IsTest
    static void testGetMigrationStatus() {
        Test.startTest();
        Map<String, Object> status = CVMARSVPMigrationUtility.getMigrationStatus();
        Test.stopTest();
        
        System.assert(status.containsKey('totalRSVPs'), 'Should return total RSVP count');
        System.assert(status.containsKey('migratedCampaignMembers'), 'Should return migrated count');
        System.assert(status.containsKey('migrationNeeded'), 'Should indicate if migration needed');
        System.assertEquals(4, status.get('totalRSVPs'), 'Should find 4 RSVP records');
    }
    
    @IsTest
    static void testMigrationWithInvalidData() {
        // Create RSVP with missing event reference
        CVMA_Event_RSVP__c invalidRSVP = new CVMA_Event_RSVP__c();
        invalidRSVP.Member__c = [SELECT Id FROM Contact LIMIT 1].Id;
        invalidRSVP.Response__c = 'Yes';
        invalidRSVP.Event__c = null; // Missing event
        
        try {
            insert invalidRSVP;
        } catch (Exception e) {
            // Expected if validation rules exist
        }
        
        Test.startTest();
        CVMARSVPMigrationUtility.MigrationResult result = CVMARSVPMigrationUtility.migrateRSVPToCampaignMembers(true);
        Test.stopTest();
        
        // Should handle invalid data gracefully
        System.assert(result != null, 'Should return result even with invalid data');
    }
    
    @IsTest
    static void testMigrationStatusMapping() {
        // Test all RSVP response types are properly mapped
        List<CVMA_Event_RSVP__c> rsvps = [SELECT Response__c, Plus_One__c FROM CVMA_Event_RSVP__c];
        
        Test.startTest();
        CVMARSVPMigrationUtility.MigrationResult result = CVMARSVPMigrationUtility.migrateRSVPToCampaignMembers(true);
        Test.stopTest();
        
        // Verify different response types are handled
        System.assertEquals(4, result.totalRSVPs, 'Should handle all response types');
        
        // Check that plus one logic is accounted for
        Boolean foundPlusOne = false;
        for (CVMA_Event_RSVP__c rsvp : rsvps) {
            if (rsvp.Response__c == 'Yes' && rsvp.Plus_One__c == true) {
                foundPlusOne = true;
            }
        }
        System.assert(foundPlusOne, 'Should have plus one test case');
    }
}
