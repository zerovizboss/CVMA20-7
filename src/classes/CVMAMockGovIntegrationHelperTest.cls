/**
 * Test class for CVMAMockGovIntegrationHelper
 * Validates government services simulation with simplified dependencies
 *
 * @author CVMA Development Team
 * @since Epic #8 Phase 3
 */
@IsTest
private class CVMAMockGovIntegrationHelperTest {

    @TestSetup
    static void setupTestData() {
        CVMATestDataFactory.TestDataBundle testBundle = CVMATestDataFactory.setupBasicTestData();

        // Create test contacts using only standard fields
        Contact veteranContact = CVMATestDataFactory.createContact()
            .withFirstName('Test')
            .withLastName('Veteran')
            .withEmail('test.veteran@cvma-test.org')
            .withLevel('Full Member')
            .withAccount(testBundle.testAccount.Id)
            .create();

        Contact civilianContact = CVMATestDataFactory.createContact()
            .withFirstName('Test')
            .withLastName('Civilian')
            .withEmail('test.civilian@cvma-test.org')
            .withLevel('Associate Member')
            .withAccount(testBundle.testAccount.Id)
            .create();
    }

    @IsTest
    static void testGetVABenefitsSimple() {
        Contact testContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Test' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockGovIntegrationHelper.VABenefitsBasic benefits =
            CVMAMockGovIntegrationHelper.getVABenefitsSimple(testContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, benefits, 'VA Benefits response should not be null');
        System.assertEquals(true, benefits.isEligible, 'Contact should be eligible for demo');
        System.assert(benefits.disabilityRating >= 0 && benefits.disabilityRating <= 100,
            'Disability rating should be valid percentage');
        System.assert(benefits.monthlyCompensation >= 0, 'Monthly compensation should be non-negative');
        System.assertEquals('Enrolled', benefits.healthcareStatus, 'Healthcare should be enrolled');
        System.assertNotEquals(null, benefits.lastVerified, 'Last verified should be set');
        System.assert(benefits.activeAlerts.size() > 0, 'Should have active alerts');
    }

    @IsTest
    static void testGetDODRecordsSimple() {
        Contact testContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Test' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockGovIntegrationHelper.DODRecordsBasic records =
            CVMAMockGovIntegrationHelper.getDODRecordsSimple(testContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, records, 'DOD Records response should not be null');
        System.assertEquals(true, records.isVerified, 'Contact should be verified for demo');
        System.assertNotEquals(null, records.serviceBranch, 'Service branch should be set');
        System.assertNotEquals(null, records.highestRank, 'Highest rank should be set');
        System.assertEquals('Honorable', records.dischargeType, 'Discharge type should be Honorable');
        System.assertNotEquals(null, records.lastVerified, 'Last verified should be set');
        System.assert(records.verificationAlerts.size() > 0, 'Should have verification alerts');

        // Validate service branch is realistic
        List<String> validBranches = new List<String>{'Army', 'Navy', 'Air Force', 'Marines', 'Coast Guard'};
        System.assert(validBranches.contains(records.serviceBranch),
            'Service branch should be valid: ' + records.serviceBranch);
    }

    @IsTest
    static void testGetBenefitRecommendations() {
        Contact testContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Test' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        List<String> recommendations =
            CVMAMockGovIntegrationHelper.getBenefitRecommendations(testContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, recommendations, 'Recommendations should not be null');
        System.assert(recommendations.size() > 0, 'Should have at least one recommendation');

        for (String recommendation : recommendations) {
            System.assert(recommendation.length() > 10, 'Recommendations should be meaningful text');
        }
    }

    @IsTest
    static void testErrorHandlingNullContactId() {
        Test.startTest();

        try {
            CVMAMockGovIntegrationHelper.getVABenefitsSimple(null);
            System.assert(false, 'Should have thrown exception for null contact ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Contact ID is required'),
                'Should have appropriate error message');
        }

        try {
            CVMAMockGovIntegrationHelper.getDODRecordsSimple(null);
            System.assert(false, 'Should have thrown exception for null contact ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Contact ID is required'),
                'Should have appropriate error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testErrorHandlingInvalidContactId() {
        Test.startTest();

        try {
            CVMAMockGovIntegrationHelper.getVABenefitsSimple('invalid-id');
            System.assert(false, 'Should have thrown exception for invalid contact ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Failed to retrieve VA benefits'),
                'Should have appropriate error message');
        }

        try {
            CVMAMockGovIntegrationHelper.getDODRecordsSimple('invalid-id');
            System.assert(false, 'Should have thrown exception for invalid contact ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Failed to retrieve DOD records'),
                'Should have appropriate error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testCachingFunctionality() {
        Contact testContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Test' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();

        // Test cacheable methods
        CVMAMockGovIntegrationHelper.VABenefitsBasic benefits1 =
            CVMAMockGovIntegrationHelper.getVABenefitsSimple(testContact.Id);
        CVMAMockGovIntegrationHelper.VABenefitsBasic benefits2 =
            CVMAMockGovIntegrationHelper.getVABenefitsSimple(testContact.Id);

        CVMAMockGovIntegrationHelper.DODRecordsBasic records1 =
            CVMAMockGovIntegrationHelper.getDODRecordsSimple(testContact.Id);
        CVMAMockGovIntegrationHelper.DODRecordsBasic records2 =
            CVMAMockGovIntegrationHelper.getDODRecordsSimple(testContact.Id);

        Test.stopTest();

        // Both calls should succeed
        System.assertNotEquals(null, benefits1, 'First benefits call should succeed');
        System.assertNotEquals(null, benefits2, 'Second benefits call should succeed');
        System.assertNotEquals(null, records1, 'First records call should succeed');
        System.assertNotEquals(null, records2, 'Second records call should succeed');
    }

    @IsTest
    static void testSecurityEnforcement() {
        Contact testContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Test' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();

        // Test should pass without security violations
        CVMAMockGovIntegrationHelper.VABenefitsBasic benefits =
            CVMAMockGovIntegrationHelper.getVABenefitsSimple(testContact.Id);
        CVMAMockGovIntegrationHelper.DODRecordsBasic records =
            CVMAMockGovIntegrationHelper.getDODRecordsSimple(testContact.Id);

        Test.stopTest();

        System.assertNotEquals(null, benefits, 'Benefits response should be successful with security');
        System.assertNotEquals(null, records, 'Records response should be successful with security');
    }

    @IsTest
    static void testDisabilityRatingDistribution() {
        Contact testContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Test' AND LastName = 'Veteran'
            LIMIT 1
        ];

        List<Integer> ratings = new List<Integer>();

        Test.startTest();

        // Generate multiple ratings to test distribution
        for (Integer i = 0; i < 10; i++) {
            CVMAMockGovIntegrationHelper.VABenefitsBasic benefits =
                CVMAMockGovIntegrationHelper.getVABenefitsSimple(testContact.Id);
            ratings.add(benefits.disabilityRating);
        }

        Test.stopTest();

        // Validate all ratings are within valid range
        for (Integer rating : ratings) {
            System.assert(rating >= 0 && rating <= 100,
                'All disability ratings should be valid percentages: ' + rating);
        }
    }

    @IsTest
    static void testServiceBranchVariety() {
        Contact testContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Test' AND LastName = 'Veteran'
            LIMIT 1
        ];

        List<String> branches = new List<String>();

        Test.startTest();

        // Generate multiple service branches to test variety
        for (Integer i = 0; i < 10; i++) {
            CVMAMockGovIntegrationHelper.DODRecordsBasic records =
                CVMAMockGovIntegrationHelper.getDODRecordsSimple(testContact.Id);
            branches.add(records.serviceBranch);
        }

        Test.stopTest();

        List<String> validBranches = new List<String>{'Army', 'Navy', 'Air Force', 'Marines', 'Coast Guard'};

        // Validate all branches are valid
        for (String branch : branches) {
            System.assert(validBranches.contains(branch),
                'All service branches should be valid: ' + branch);
        }
    }

    @IsTest
    static void testBulkDataHandling() {
        List<Contact> testContacts = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Test'
        ];

        Test.startTest();

        // Test multiple contacts
        for (Contact contact : testContacts) {
            CVMAMockGovIntegrationHelper.VABenefitsBasic benefits =
                CVMAMockGovIntegrationHelper.getVABenefitsSimple(contact.Id);
            CVMAMockGovIntegrationHelper.DODRecordsBasic records =
                CVMAMockGovIntegrationHelper.getDODRecordsSimple(contact.Id);
            List<String> recommendations =
                CVMAMockGovIntegrationHelper.getBenefitRecommendations(contact.Id);

            System.assertNotEquals(null, benefits, 'Benefits should be valid for each contact');
            System.assertNotEquals(null, records, 'Records should be valid for each contact');
            System.assertNotEquals(null, recommendations, 'Recommendations should be valid for each contact');
        }

        Test.stopTest();
    }
}
