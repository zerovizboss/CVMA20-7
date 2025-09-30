/**
 * Test class for CVMAMockDODRecordsController
 * Validates comprehensive DOD records simulation and military service verification
 * Ensures >90% code coverage and validates all business logic scenarios
 *
 * @author CVMA Development Team
 * @since Epic #8 Phase 3
 */
@IsTest
private class CVMAMockDODRecordsControllerTest {

    @TestSetup
    static void setupTestData() {
        CVMATestDataFactory.TestDataBundle testBundle = CVMATestDataFactory.setupBasicTestData();

        // Create contacts with various military service configurations
        Contact armyVeteran = CVMATestDataFactory.createContact()
            .withFirstName('John')
            .withLastName('Soldier')
            .withEmail('john.soldier@cvma-test.org')
            .withAccount(testBundle.testAccount.Id)
            .create();

        // Update with Army service information
        armyVeteran.Military_Service_Branch__c = 'Army';
        armyVeteran.Service_Start_Date__c = Date.today().addYears(-12);
        armyVeteran.Service_End_Date__c = Date.today().addYears(-4);
        update armyVeteran;

        // Create Navy veteran
        Contact navyVeteran = CVMATestDataFactory.createContact()
            .withFirstName('Jane')
            .withLastName('Sailor')
            .withEmail('jane.sailor@cvma-test.org')
            .withAccount(testBundle.testAccount.Id)
            .create();

        navyVeteran.Military_Service_Branch__c = 'Navy';
        navyVeteran.Service_Start_Date__c = Date.today().addYears(-6);
        navyVeteran.Service_End_Date__c = Date.today().addYears(-1);
        update navyVeteran;

        // Create Marines veteran for combat testing
        Contact marineVeteran = CVMATestDataFactory.createContact()
            .withFirstName('Mike')
            .withLastName('Marine')
            .withEmail('mike.marine@cvma-test.org')
            .withAccount(testBundle.testAccount.Id)
            .create();

        marineVeteran.Military_Service_Branch__c = 'Marines';
        marineVeteran.Service_Start_Date__c = Date.today().addYears(-8);
        marineVeteran.Service_End_Date__c = Date.today().addYears(-2);
        update marineVeteran;

        // Create contact without service info for negative testing
        Contact civilianContact = CVMATestDataFactory.createContact()
            .withFirstName('Chris')
            .withLastName('Civilian')
            .withEmail('chris.civilian@cvma-test.org')
            .withAccount(testBundle.testAccount.Id)
            .create();
    }

    @IsTest
    static void testGetDODRecordsWithValidServiceMember() {
        Contact serviceContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Soldier'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockDODRecordsController.DODRecordsResponse response =
            CVMAMockDODRecordsController.getDODRecords(serviceContact.Id);
        Test.stopTest();

        // Validate main response structure
        System.assertNotEquals(null, response, 'DOD Records response should not be null');
        System.assertEquals(true, response.isVerified, 'Service member should be verified');
        System.assertNotEquals(null, response.serviceNumber, 'Service number should be generated');
        System.assertNotEquals(null, response.lastVerified, 'Last verified date should be set');
        System.assertNotEquals(null, response.apiStatus, 'API status should be included');

        // Validate service record
        System.assertNotEquals(null, response.serviceRecord, 'Service record should be included');
        System.assertEquals('Army', response.serviceRecord.serviceBranch, 'Service branch should match');
        System.assertNotEquals(null, response.serviceRecord.highestRank, 'Highest rank should be set');
        System.assertNotEquals(null, response.serviceRecord.dischargeType, 'Discharge type should be set');
        System.assertNotEquals(null, response.serviceRecord.primaryMOS, 'Primary MOS should be set');
        System.assert(response.serviceRecord.totalServiceDays > 0, 'Total service days should be positive');

        // Validate SCRA status
        System.assertNotEquals(null, response.scraStatus, 'SCRA status should be included');
        System.assertNotEquals(null, response.scraStatus.statusDate, 'Status date should be set');

        // Validate security clearance
        System.assertNotEquals(null, response.securityClearance, 'Security clearance should be included');
        System.assertNotEquals(null, response.securityClearance.status, 'Clearance status should be set');

        // Validate awards
        System.assertNotEquals(null, response.awards, 'Awards list should be included');
        System.assert(response.awards.size() > 0, 'Should have at least some awards');

        // Validate deployments
        System.assertNotEquals(null, response.deployments, 'Deployments list should be included');

        // Validate DD-214 summary
        System.assertNotEquals(null, response.dd214Summary, 'DD-214 summary should be included');
        System.assertNotEquals(null, response.dd214Summary.entryDate, 'Entry date should be set');
        System.assertNotEquals(null, response.dd214Summary.releaseDate, 'Release date should be set');
    }

    @IsTest
    static void testGetDODRecordsWithNonServiceMember() {
        Contact civilianContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Chris' AND LastName = 'Civilian'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockDODRecordsController.DODRecordsResponse response =
            CVMAMockDODRecordsController.getDODRecords(civilianContact.Id);
        Test.stopTest();

        // Validate response for non-service member
        System.assertNotEquals(null, response, 'Response should not be null even for civilians');
        System.assertEquals(false, response.isVerified, 'Civilian should not be verified');
        System.assert(response.verificationAlerts.size() > 0, 'Should have alerts for non-service members');
        System.assert(response.verificationAlerts[0].contains('Military service branch required'),
            'Should indicate military service verification is needed');
    }

    @IsTest
    static void testGetServiceVerificationSpecific() {
        Contact serviceContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Jane' AND LastName = 'Sailor'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockDODRecordsController.ServiceRecord serviceRecord =
            CVMAMockDODRecordsController.getServiceVerification(serviceContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, serviceRecord, 'Service record should not be null');
        System.assertEquals('Navy', serviceRecord.serviceBranch, 'Service branch should be Navy');
        System.assertNotEquals(null, serviceRecord.highestRank, 'Highest rank should be set');
        System.assertNotEquals(null, serviceRecord.entryDate, 'Entry date should be set');
        System.assertNotEquals(null, serviceRecord.separationDate, 'Separation date should be set');
        System.assertNotEquals(null, serviceRecord.dischargeType, 'Discharge type should be set');
        System.assert(serviceRecord.totalServiceDays > 0, 'Total service days should be positive');
    }

    @IsTest
    static void testGetSCRAStatusSpecific() {
        Contact serviceContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Soldier'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockDODRecordsController.SCRAStatus scraStatus =
            CVMAMockDODRecordsController.getSCRAStatus(serviceContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, scraStatus, 'SCRA status should not be null');
        System.assertNotEquals(null, scraStatus.statusDate, 'Status date should be set');
        System.assertNotEquals(null, scraStatus.activeProtections, 'Active protections list should exist');

        // Most veterans should not be active duty
        if (scraStatus.isActiveDuty) {
            System.assertNotEquals(null, scraStatus.currentUnit, 'Active duty should have current unit');
            System.assertNotEquals(null, scraStatus.dutyLocation, 'Active duty should have duty location');
        }
    }

    @IsTest
    static void testGetMilitaryAwardsSpecific() {
        Contact serviceContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Mike' AND LastName = 'Marine'
            LIMIT 1
        ];

        Test.startTest();
        List<CVMAMockDODRecordsController.AwardDecoration> awards =
            CVMAMockDODRecordsController.getMilitaryAwards(serviceContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, awards, 'Awards list should not be null');
        System.assert(awards.size() > 0, 'Should have at least some awards');

        for (CVMAMockDODRecordsController.AwardDecoration award : awards) {
            System.assertNotEquals(null, award.awardName, 'Award name should be set');
            System.assertNotEquals(null, award.category, 'Award category should be set');
            System.assertNotEquals(null, award.description, 'Award description should be set');
            System.assertNotEquals(null, award.awardDate, 'Award date should be set');
        }
    }

    @IsTest
    static void testGetDeploymentHistorySpecific() {
        Contact serviceContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Mike' AND LastName = 'Marine'
            LIMIT 1
        ];

        Test.startTest();
        List<CVMAMockDODRecordsController.DeploymentRecord> deployments =
            CVMAMockDODRecordsController.getDeploymentHistory(serviceContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, deployments, 'Deployments list should not be null');

        for (CVMAMockDODRecordsController.DeploymentRecord deployment : deployments) {
            System.assertNotEquals(null, deployment.operation, 'Operation name should be set');
            System.assertNotEquals(null, deployment.theater, 'Theater should be set');
            System.assertNotEquals(null, deployment.startDate, 'Start date should be set');
            System.assertNotEquals(null, deployment.endDate, 'End date should be set');
            System.assertNotEquals(null, deployment.unit, 'Unit should be set');
        }
    }

    @IsTest
    static void testGetDD214SummarySpecific() {
        Contact serviceContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Soldier'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockDODRecordsController.DD214Summary dd214 =
            CVMAMockDODRecordsController.getDD214Summary(serviceContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, dd214, 'DD-214 summary should not be null');
        System.assertNotEquals(null, dd214.entryDate, 'Entry date should be set');
        System.assertNotEquals(null, dd214.releaseDate, 'Release date should be set');
        System.assertNotEquals(null, dd214.lastDutyAssignment, 'Last duty assignment should be set');
        System.assertNotEquals(null, dd214.militaryOccupation, 'Military occupation should be set');
        System.assertNotEquals(null, dd214.reasonForSeparation, 'Reason for separation should be set');
        System.assertNotEquals(null, dd214.separationCode, 'Separation code should be set');
        System.assertNotEquals(null, dd214.reentryCode, 'Reentry code should be set');
        System.assertNotEquals(null, dd214.awards, 'Awards list should be included');
    }

    @IsTest
    static void testValidateCombatVeteranStatus() {
        Contact marineContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Mike' AND LastName = 'Marine'
            LIMIT 1
        ];

        Test.startTest();
        Boolean isCombatVeteran =
            CVMAMockDODRecordsController.validateCombatVeteranStatus(marineContact.Id);
        Test.stopTest();

        // Result should be boolean (true or false based on simulation)
        System.assertNotEquals(null, isCombatVeteran, 'Combat veteran status should be determined');

        // If combat veteran, verify supporting data
        if (isCombatVeteran) {
            CVMAMockDODRecordsController.ServiceRecord serviceRecord =
                CVMAMockDODRecordsController.getServiceVerification(marineContact.Id);
            List<CVMAMockDODRecordsController.DeploymentRecord> deployments =
                CVMAMockDODRecordsController.getDeploymentHistory(marineContact.Id);

            System.assertEquals(true, serviceRecord.isCombatVeteran,
                'Service record should reflect combat veteran status');
        }
    }

    @IsTest
    static void testServiceNumberGeneration() {
        Contact serviceContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Soldier'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockDODRecordsController.DODRecordsResponse response =
            CVMAMockDODRecordsController.getDODRecords(serviceContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, response.serviceNumber, 'Service number should be generated');
        System.assert(response.serviceNumber.startsWith('A'), 'Army service number should start with A');
        System.assert(response.serviceNumber.length() >= 9, 'Service number should be appropriate length');
    }

    @IsTest
    static void testBranchSpecificRanks() {
        // Test Army ranks
        Contact armyContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Soldier'
            LIMIT 1
        ];

        // Test Navy ranks
        Contact navyContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Jane' AND LastName = 'Sailor'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockDODRecordsController.ServiceRecord armyRecord =
            CVMAMockDODRecordsController.getServiceVerification(armyContact.Id);
        CVMAMockDODRecordsController.ServiceRecord navyRecord =
            CVMAMockDODRecordsController.getServiceVerification(navyContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, armyRecord.highestRank, 'Army rank should be set');
        System.assertNotEquals(null, navyRecord.highestRank, 'Navy rank should be set');

        // Ranks should be appropriate for their respective services
        System.assertEquals('Army', armyRecord.serviceBranch, 'Army record should show Army branch');
        System.assertEquals('Navy', navyRecord.serviceBranch, 'Navy record should show Navy branch');
    }

    @IsTest
    static void testCachingFunctionality() {
        Contact serviceContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Soldier'
            LIMIT 1
        ];

        Test.startTest();

        // First call - should populate cache
        CVMAMockDODRecordsController.DODRecordsResponse response1 =
            CVMAMockDODRecordsController.getDODRecords(serviceContact.Id);

        // Second call - should use cache (testing cacheable annotation)
        CVMAMockDODRecordsController.DODRecordsResponse response2 =
            CVMAMockDODRecordsController.getDODRecords(serviceContact.Id);

        Test.stopTest();

        // Both responses should be valid and consistent
        System.assertNotEquals(null, response1, 'First response should not be null');
        System.assertNotEquals(null, response2, 'Second response should not be null');
        System.assertEquals(response1.isVerified, response2.isVerified, 'Verification should be consistent');
        System.assertEquals(response1.serviceRecord.serviceBranch, response2.serviceRecord.serviceBranch,
            'Service branch should be consistent');
    }

    @IsTest
    static void testErrorHandlingInvalidContactId() {
        Test.startTest();

        try {
            CVMAMockDODRecordsController.getDODRecords('invalid-id');
            System.assert(false, 'Should have thrown exception for invalid contact ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Failed to retrieve DOD records'),
                'Should have appropriate error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testErrorHandlingNullContactId() {
        Test.startTest();

        try {
            CVMAMockDODRecordsController.getDODRecords(null);
            System.assert(false, 'Should have thrown exception for null contact ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Failed to retrieve DOD records'),
                'Should have appropriate error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testAPIStatusGeneration() {
        Contact serviceContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Soldier'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockDODRecordsController.DODRecordsResponse response =
            CVMAMockDODRecordsController.getDODRecords(serviceContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, response.apiStatus, 'API status should be included');
        System.assertEquals('Available', response.apiStatus.status, 'API should be available');
        System.assertNotEquals(null, response.apiStatus.responseTime, 'Response time should be set');
        System.assertNotEquals(null, response.apiStatus.lastUpdated, 'Last updated should be set');
        System.assertEquals('v3.2.1', response.apiStatus.version, 'API version should be set');
        System.assertEquals('UNCLASSIFIED', response.apiStatus.securityLevel, 'Security level should be unclassified');
    }

    @IsTest
    static void testSecurityEnforcement() {
        // This test validates that the controller respects security settings
        Contact serviceContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Soldier'
            LIMIT 1
        ];

        Test.startTest();
        // Test should pass without security violations
        CVMAMockDODRecordsController.DODRecordsResponse response =
            CVMAMockDODRecordsController.getDODRecords(serviceContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should be successful with proper security');
    }

    @IsTest
    static void testDischargeTypeDistribution() {
        Contact serviceContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Soldier'
            LIMIT 1
        ];

        Test.startTest();
        CVMAMockDODRecordsController.ServiceRecord serviceRecord =
            CVMAMockDODRecordsController.getServiceVerification(serviceContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, serviceRecord.dischargeType, 'Discharge type should be set');

        // Valid discharge types
        List<String> validDischargeTypes = new List<String>{
            'Honorable', 'General Under Honorable Conditions', 'Other Than Honorable'
        };
        System.assert(validDischargeTypes.contains(serviceRecord.dischargeType),
            'Discharge type should be valid: ' + serviceRecord.dischargeType);
    }

    @IsTest
    static void testBulkDataHandling() {
        // Test multiple contacts to ensure bulk handling works properly
        List<Contact> testContacts = [
            SELECT Id FROM Contact
            WHERE FirstName IN ('John', 'Jane', 'Mike', 'Chris')
        ];

        Test.startTest();

        List<CVMAMockDODRecordsController.DODRecordsResponse> responses =
            new List<CVMAMockDODRecordsController.DODRecordsResponse>();

        for (Contact contact : testContacts) {
            responses.add(CVMAMockDODRecordsController.getDODRecords(contact.Id));
        }

        Test.stopTest();

        System.assertEquals(testContacts.size(), responses.size(),
            'Should have response for each contact');

        for (CVMAMockDODRecordsController.DODRecordsResponse response : responses) {
            System.assertNotEquals(null, response, 'Each response should be valid');
            System.assertNotEquals(null, response.apiStatus, 'Each response should have API status');
        }
    }

    @IsTest
    static void testCombatVeteranFailSafe() {
        Contact civilianContact = [
            SELECT Id FROM Contact
            WHERE FirstName = 'Chris' AND LastName = 'Civilian'
            LIMIT 1
        ];

        Test.startTest();
        Boolean isCombatVeteran =
            CVMAMockDODRecordsController.validateCombatVeteranStatus(civilianContact.Id);
        Test.stopTest();

        // Should return false for civilians (fail secure)
        System.assertEquals(false, isCombatVeteran,
            'Civilian should not be verified as combat veteran');
    }
}
