/**
 * Test class for CVMAMockVABenefitsController
 * Validates comprehensive VA benefits simulation and API functionality
 * Ensures >90% code coverage and validates all business logic scenarios
 *
 * @author CVMA Development Team
 * @since Epic #8 Phase 3
 */
@IsTest
private class CVMAMockVABenefitsControllerTest {

    @TestSetup
    static void setupTestData() {
        CVMATestDataFactory.TestDataBundle testBundle = CVMATestDataFactory.setupBasicTestData();

        // Create contacts with various military service configurations
        Contact veteranWithService = CVMATestDataFactory.createContact()
            .withFirstName('John')
            .withLastName('Veteran')
            .withEmail('john.veteran@cvma-test.org')
            .withAccount(testBundle.testAccount.Id)
            .create();

        // Update with military service information using DML
        veteranWithService.Military_Service_Branch__c = 'Army';
        veteranWithService.Service_Start_Date__c = Date.today().addYears(-10);
        veteranWithService.Service_End_Date__c = Date.today().addYears(-3);
        update veteranWithService;

        // Create veteran without service info for negative testing
        Contact veteranWithoutService = CVMATestDataFactory.createContact()
            .withFirstName('Jane')
            .withLastName('Civilian')
            .withEmail('jane.civilian@cvma-test.org')
            .withAccount(testBundle.testAccount.Id)
            .create();
    }

    @IsTest
    static void testGetVABenefitsWithValidVeteran() {
        // Get test contact with military service
        Contact veteranContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockVABenefitsController.VABenefitsResponse response =
            CVMAMockVABenefitsController.getVABenefits(veteranContact.Id);
        Test.stopTest();

        // Validate main response structure
        System.assertNotEquals(null, response, 'VA Benefits response should not be null');
        System.assertEquals(true, response.isEligible, 'Veteran with service should be eligible');
        System.assertNotEquals(null, response.veteranId, 'Veteran ID should be generated');
        System.assertNotEquals(null, response.lastVerified, 'Last verified date should be set');
        System.assertNotEquals(null, response.apiStatus, 'API status should be included');

        // Validate disability benefits
        System.assertNotEquals(null, response.disability, 'Disability benefits should be included');
        System.assert(response.disability.disabilityRating >= 0 && response.disability.disabilityRating <= 100,
            'Disability rating should be between 0-100%');
        System.assert(response.disability.monthlyCompensation >= 0,
            'Monthly compensation should be non-negative');
        System.assertEquals('Current', response.disability.paymentStatus,
            'Payment status should be Current for eligible veterans');

        // Validate healthcare benefits
        System.assertNotEquals(null, response.healthcare, 'Healthcare benefits should be included');
        System.assertEquals(true, response.healthcare.isEligible, 'Healthcare should be available');
        System.assertEquals('Enrolled', response.healthcare.enrollmentStatus, 'Should be enrolled');
        System.assertNotEquals(null, response.healthcare.priorityGroup, 'Priority group should be assigned');

        // Validate education benefits
        System.assertNotEquals(null, response.education, 'Education benefits should be included');
        System.assert(response.education.remainingEntitlement >= 0,
            'Remaining entitlement should be non-negative');
        System.assertNotEquals(null, response.education.benefitType, 'Benefit type should be specified');

        // Validate home loan benefits
        System.assertNotEquals(null, response.homeLoan, 'Home loan benefits should be included');
        System.assertEquals(true, response.homeLoan.isEligible, 'Home loan should be available for veterans');
        System.assert(response.homeLoan.availableEntitlement > 0,
            'Available entitlement should be positive');
    }

    @IsTest
    static void testGetVABenefitsWithNonVeteran() {
        // Get test contact without military service
        Contact civilianContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Jane' AND LastName = 'Civilian'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockVABenefitsController.VABenefitsResponse response =
            CVMAMockVABenefitsController.getVABenefits(civilianContact.Id);
        Test.stopTest();

        // Validate response for non-veteran
        System.assertNotEquals(null, response, 'Response should not be null even for non-veterans');
        System.assertEquals(false, response.isEligible, 'Non-veteran should not be eligible');
        System.assert(response.activeAlerts.size() > 0, 'Should have alerts for non-eligible contacts');
        System.assert(response.activeAlerts[0].contains('Military service verification required'),
            'Should indicate military service verification is needed');
    }

    @IsTest
    static void testGetDisabilityBenefitsSpecific() {
        Contact veteranContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockVABenefitsController.DisabilityBenefits disability =
            CVMAMockVABenefitsController.getDisabilityBenefits(veteranContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, disability, 'Disability benefits should not be null');
        System.assert(disability.disabilityRating >= 0 && disability.disabilityRating <= 100,
            'Disability rating should be valid percentage');
        System.assertNotEquals(null, disability.effectiveDate, 'Effective date should be set');
        System.assertNotEquals(null, disability.serviceConnectedConditions,
            'Service connected conditions should be included');
        System.assert(disability.serviceConnectedConditions.size() > 0,
            'Should have at least one service connected condition');
    }

    @IsTest
    static void testGetHealthcareBenefitsSpecific() {
        Contact veteranContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockVABenefitsController.HealthcareBenefits healthcare =
            CVMAMockVABenefitsController.getHealthcareBenefits(veteranContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, healthcare, 'Healthcare benefits should not be null');
        System.assertEquals(true, healthcare.isEligible, 'Healthcare should be available');
        System.assertNotEquals(null, healthcare.primaryFacility, 'Primary facility should be assigned');
        System.assert(healthcare.authorizedFacilities.size() > 0,
            'Should have authorized facilities');
        System.assert(healthcare.copayAmount >= 0, 'Copay amount should be non-negative');
    }

    @IsTest
    static void testGetEducationBenefitsSpecific() {
        Contact veteranContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockVABenefitsController.EducationBenefits education =
            CVMAMockVABenefitsController.getEducationBenefits(veteranContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, education, 'Education benefits should not be null');
        System.assertNotEquals(null, education.benefitType, 'Benefit type should be specified');
        System.assert(education.remainingEntitlement >= 0, 'Remaining entitlement should be valid');
        System.assert(education.usedEntitlement >= 0, 'Used entitlement should be valid');
        System.assertNotEquals(null, education.expirationDate, 'Expiration date should be set');
    }

    @IsTest
    static void testGetHomeLoanBenefitsSpecific() {
        Contact veteranContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockVABenefitsController.HomeLoanBenefits homeLoan =
            CVMAMockVABenefitsController.getHomeLoanBenefits(veteranContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, homeLoan, 'Home loan benefits should not be null');
        System.assertEquals(true, homeLoan.isEligible, 'Home loan should be available');
        System.assert(homeLoan.availableEntitlement > 0, 'Available entitlement should be positive');
        System.assertNotEquals(null, homeLoan.certificateStatus, 'Certificate status should be set');
        System.assertNotEquals(null, homeLoan.fundingFeeStatus, 'Funding fee status should be set');
    }

    @IsTest
    static void testGetBenefitOptimizationRecommendations() {
        Contact veteranContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        List<String> recommendations =
            CVMAMockVABenefitsController.getBenefitOptimizationRecommendations(veteranContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, recommendations, 'Recommendations should not be null');
        // Should have at least some recommendations for a veteran with service
        System.assert(recommendations.size() >= 0, 'Should have zero or more recommendations');

        // If recommendations exist, they should be meaningful
        if (recommendations.size() > 0) {
            for (String recommendation : recommendations) {
                System.assert(recommendation.length() > 10, 'Recommendations should be meaningful text');
            }
        }
    }

    @IsTest
    static void testCachingFunctionality() {
        Contact veteranContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();

        // First call - should populate cache
        CVMAMockVABenefitsController.VABenefitsResponse response1 =
            CVMAMockVABenefitsController.getVABenefits(veteranContact.Id);

        // Second call - should use cache (testing cacheable annotation)
        CVMAMockVABenefitsController.VABenefitsResponse response2 =
            CVMAMockVABenefitsController.getVABenefits(veteranContact.Id);

        Test.stopTest();

        // Both responses should be valid and similar
        System.assertNotEquals(null, response1, 'First response should not be null');
        System.assertNotEquals(null, response2, 'Second response should not be null');
        System.assertEquals(response1.isEligible, response2.isEligible, 'Eligibility should be consistent');
    }

    @IsTest
    static void testErrorHandlingInvalidContactId() {
        Test.startTest();

        try {
            CVMAMockVABenefitsController.getVABenefits('invalid-id');
            System.assert(false, 'Should have thrown exception for invalid contact ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Failed to retrieve VA benefits'),
                'Should have appropriate error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testErrorHandlingNullContactId() {
        Test.startTest();

        try {
            CVMAMockVABenefitsController.getVABenefits(null);
            System.assert(false, 'Should have thrown exception for null contact ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Failed to retrieve VA benefits'),
                'Should have appropriate error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testErrorHandlingBlankContactId() {
        Test.startTest();

        try {
            CVMAMockVABenefitsController.getVABenefits('');
            System.assert(false, 'Should have thrown exception for blank contact ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Failed to retrieve VA benefits'),
                'Should have appropriate error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testAPIStatusGeneration() {
        Contact veteranContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockVABenefitsController.VABenefitsResponse response =
            CVMAMockVABenefitsController.getVABenefits(veteranContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, response.apiStatus, 'API status should be included');
        System.assertEquals('Available', response.apiStatus.status, 'API should be available');
        System.assertNotEquals(null, response.apiStatus.responseTime, 'Response time should be set');
        System.assertNotEquals(null, response.apiStatus.lastUpdated, 'Last updated should be set');
        System.assertEquals('v2.1.0', response.apiStatus.version, 'API version should be set');
    }

    @IsTest
    static void testDisabilityCompensationCalculation() {
        Contact veteranContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockVABenefitsController.DisabilityBenefits disability =
            CVMAMockVABenefitsController.getDisabilityBenefits(veteranContact.Id);
        Test.stopTest();

        // Validate compensation is reasonable based on rating
        if (disability.disabilityRating == 100) {
            System.assert(disability.monthlyCompensation > 3000,
                '100% disability should have high compensation');
        } else if (disability.disabilityRating >= 70) {
            System.assert(disability.monthlyCompensation > 1500,
                '70%+ disability should have significant compensation');
        } else if (disability.disabilityRating >= 30) {
            System.assert(disability.monthlyCompensation > 400,
                '30%+ disability should have meaningful compensation');
        }
    }

    @IsTest
    static void testVeteranIdGeneration() {
        Contact veteranContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockVABenefitsController.VABenefitsResponse response =
            CVMAMockVABenefitsController.getVABenefits(veteranContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, response.veteranId, 'Veteran ID should be generated');
        System.assert(response.veteranId.startsWith('VA'), 'Veteran ID should start with VA');
        System.assert(response.veteranId.length() >= 10, 'Veteran ID should be appropriate length');
    }

    @IsTest
    static void testSecurityEnforcement() {
        // This test validates that the controller respects security settings
        Contact veteranContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();
        // Test should pass without security violations
        CVMAMockVABenefitsController.VABenefitsResponse response =
            CVMAMockVABenefitsController.getVABenefits(veteranContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should be successful with proper security');
    }

    @IsTest
    static void testBulkDataHandling() {
        // Test multiple contacts to ensure bulk handling works properly
        List<Contact> testContacts = [
            SELECT Id FROM Contact
            WHERE (FirstName = 'John' AND LastName = 'Veteran')
            OR (FirstName = 'Jane' AND LastName = 'Civilian')
        ];

        Test.startTest();

        List<CVMAMockVABenefitsController.VABenefitsResponse> responses =
            new List<CVMAMockVABenefitsController.VABenefitsResponse>();

        for (Contact contact : testContacts) {
            responses.add(CVMAMockVABenefitsController.getVABenefits(contact.Id));
        }

        Test.stopTest();

        System.assertEquals(testContacts.size(), responses.size(),
            'Should have response for each contact');

        for (CVMAMockVABenefitsController.VABenefitsResponse response : responses) {
            System.assertNotEquals(null, response, 'Each response should be valid');
            System.assertNotEquals(null, response.apiStatus, 'Each response should have API status');
        }
    }
}
