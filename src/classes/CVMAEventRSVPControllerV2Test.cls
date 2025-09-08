/**
 * @description Test class for CVMAEventRSVPControllerV2 - Campaign Member RSVP functionality
 * @author Claude AI - CVMA Development Team  
 * @date January 2025
 */
@IsTest
public class CVMAEventRSVPControllerV2Test {
    
    @TestSetup
    static void makeData() {
        // Create test member contact
        Contact testMember = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .create();
            
        // Create test campaign for RSVP testing
        Campaign testCampaign = CVMATestDataFactory.createCampaign()
            .withName('Test RSVP Event')
            .withType('CVMA Event')
            .withStartDate(Date.today().addDays(14))
            .withEndDate(Date.today().addDays(14))
            .create();
            
        // Enable RSVP mapping
        testCampaign.CVMA_Event_RSVP_Mapping__c = true;
        update testCampaign;
        
        // Create test user associated with contact
        User testUser = new User(
            Alias = 'testuser',
            Email = testMember.Email,
            EmailEncodingKey = 'UTF-8',
            FirstName = testMember.FirstName,
            LastName = testMember.LastName,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = testMember.Email + '.cvmatest',
            ContactId = testMember.Id
        );
        insert testUser;
    }
    
    @IsTest
    static void testSubmitRSVP_NewYesResponse() {
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test RSVP Event' LIMIT 1];
        
        Test.startTest();
        
        // Test submitting Yes RSVP
        Boolean result = CVMAEventRSVPControllerV2.submitRSVP(testCampaign.Id, 'Yes', false, null);
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(true, result, 'RSVP submission should succeed');
        
        // Verify Campaign Member was created with correct status
        List<CampaignMember> members = [
            SELECT Id, Status
            FROM CampaignMember
            WHERE CampaignId = :testCampaign.Id
        ];
        
        System.assertEquals(1, members.size(), 'Should create one Campaign Member');
        System.assertEquals('Responded - Yes', members[0].Status, 'Status should be Responded - Yes');
    }
    
    @IsTest
    static void testSubmitRSVP_UpdateExistingResponse() {
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test RSVP Event' LIMIT 1];
        Contact testMember = [SELECT Id FROM Contact WHERE Level__c = 'Full Member' LIMIT 1];
        
        // Create existing Campaign Member
        CampaignMember existingMember = new CampaignMember(
            CampaignId = testCampaign.Id,
            ContactId = testMember.Id,
            Status = 'Responded - Maybe'
        );
        insert existingMember;
        
        Test.startTest();
        
        // Test updating to Yes RSVP
        Boolean result = CVMAEventRSVPControllerV2.submitRSVP(testCampaign.Id, 'Yes', false, null);
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(true, result, 'RSVP update should succeed');
        
        // Verify Campaign Member was updated
        CampaignMember updatedMember = [
            SELECT Id, Status
            FROM CampaignMember
            WHERE Id = :existingMember.Id
        ];
        
        System.assertEquals('Responded - Yes', updatedMember.Status, 'Status should be updated to Yes');
    }
    
    @IsTest
    static void testSubmitRSVP_WithPlusOne() {
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test RSVP Event' LIMIT 1];
        
        Test.startTest();
        
        // Test submitting Yes RSVP with plus one
        Boolean result = CVMAEventRSVPControllerV2.submitRSVP(testCampaign.Id, 'Yes', true, 'John Doe');
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(true, result, 'RSVP with plus one should succeed');
        
        // Verify Campaign Members were created
        List<CampaignMember> members = [
            SELECT Id, Status
            FROM CampaignMember
            WHERE CampaignId = :testCampaign.Id
            ORDER BY Status
        ];
        
        System.assertEquals(2, members.size(), 'Should create two Campaign Members (main + plus one)');
        System.assertEquals('Plus One - Yes', members[0].Status, 'First member should be plus one');
        System.assertEquals('Responded - Yes', members[1].Status, 'Second member should be main response');
    }
    
    @IsTest
    static void testGetCurrentUserRSVP_ExistingRSVP() {
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test RSVP Event' LIMIT 1];
        Contact testMember = [SELECT Id FROM Contact WHERE Level__c = 'Full Member' LIMIT 1];
        
        // Create existing Campaign Member
        CampaignMember existingMember = new CampaignMember(
            CampaignId = testCampaign.Id,
            ContactId = testMember.Id,
            Status = 'Responded - Yes'
        );
        insert existingMember;
        
        Test.startTest();
        
        // Test getting current user RSVP
        CampaignMember result = CVMAEventRSVPControllerV2.getCurrentUserRSVP(testCampaign.Id);
        
        Test.stopTest();
        
        // Verify result
        System.assertNotEquals(null, result, 'Should return existing RSVP');
        System.assertEquals('Responded - Yes', result.Status, 'Should return correct status');
    }
    
    @IsTest
    static void testGetCurrentUserRSVP_NoExistingRSVP() {
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test RSVP Event' LIMIT 1];
        
        Test.startTest();
        
        // Test getting current user RSVP when none exists
        CampaignMember result = CVMAEventRSVPControllerV2.getCurrentUserRSVP(testCampaign.Id);
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(null, result, 'Should return null when no RSVP exists');
    }
    
    @IsTest
    static void testGetRSVPSummary() {
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test RSVP Event' LIMIT 1];
        Contact testMember = [SELECT Id FROM Contact WHERE Level__c = 'Full Member' LIMIT 1];
        
        // Create multiple Campaign Members with different statuses
        List<CampaignMember> members = new List<CampaignMember>{
            new CampaignMember(CampaignId = testCampaign.Id, ContactId = testMember.Id, Status = 'Responded - Yes'),
            new CampaignMember(CampaignId = testCampaign.Id, ContactId = testMember.Id, Status = 'Responded - No'),
            new CampaignMember(CampaignId = testCampaign.Id, ContactId = testMember.Id, Status = 'Responded - Maybe'),
            new CampaignMember(CampaignId = testCampaign.Id, ContactId = testMember.Id, Status = 'Plus One - Yes')
        };
        insert members;
        
        Test.startTest();
        
        // Test getting RSVP summary
        Map<String, Object> summary = CVMAEventRSVPControllerV2.getRSVPSummary(testCampaign.Id);
        
        Test.stopTest();
        
        // Verify summary counts
        System.assertEquals(1, (Integer) summary.get('yesCount'), 'Should have 1 Yes response');
        System.assertEquals(1, (Integer) summary.get('noCount'), 'Should have 1 No response');
        System.assertEquals(1, (Integer) summary.get('maybeCount'), 'Should have 1 Maybe response');
        System.assertEquals(1, (Integer) summary.get('plusOneCount'), 'Should have 1 Plus One');
        System.assertEquals(4, (Integer) summary.get('totalResponses'), 'Should have 4 total responses');
        System.assertEquals(2, (Integer) summary.get('attendingCount'), 'Should have 2 attending (Yes + Plus One)');
    }
    
    @IsTest
    static void testGetRSVPResponseOptions() {
        Test.startTest();
        
        // Test getting response options
        List<Map<String, String>> options = CVMAEventRSVPControllerV2.getRSVPResponseOptions();
        
        Test.stopTest();
        
        // Verify options
        System.assertEquals(3, options.size(), 'Should return 3 response options');
        
        Set<String> expectedValues = new Set<String>{'Yes', 'No', 'Maybe'};
        Set<String> actualValues = new Set<String>();
        
        for (Map<String, String> option : options) {
            actualValues.add(option.get('value'));
        }
        
        System.assertEquals(expectedValues, actualValues, 'Should have correct response values');
    }
    
    @IsTest
    static void testMapRSVPResponseToCampaignMemberStatus() {
        // Test the private method indirectly through submitRSVP
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test RSVP Event' LIMIT 1];
        
        Test.startTest();
        
        // Test each response mapping
        CVMAEventRSVPControllerV2.submitRSVP(testCampaign.Id, 'Yes', false, null);
        CVMAEventRSVPControllerV2.submitRSVP(testCampaign.Id, 'No', false, null);
        CVMAEventRSVPControllerV2.submitRSVP(testCampaign.Id, 'Maybe', false, null);
        
        Test.stopTest();
        
        // Verify the mapping worked through the final Campaign Member status
        List<CampaignMember> members = [
            SELECT Status
            FROM CampaignMember
            WHERE CampaignId = :testCampaign.Id
            ORDER BY LastModifiedDate DESC
        ];
        
        System.assertEquals(3, members.size(), 'Should create 3 members for different responses');
        System.assertEquals('Responded - Maybe', members[0].Status, 'Last response should be Maybe');
    }
    
    @IsTest
    static void testErrorHandling() {
        Test.startTest();
        
        try {
            // Test with invalid campaign ID
            CVMAEventRSVPControllerV2.submitRSVP(null, 'Yes', false, null);
            System.assert(false, 'Should throw exception for invalid campaign ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Unable to submit RSVP'), 
                         'Should have proper error handling');
        }
        
        Test.stopTest();
    }
}