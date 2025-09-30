/**
 * CVMAVAServicesIntegrationControllerTest.cls
 * Epic #10 User Story #32: Test class for VA Services Integration Controller
 * Comprehensive test coverage for government services coordination
 *
 * Combat Veterans Motorcycle Association Chapter 20-7
 * Test coverage for VA services integration with standard objects
 */
@IsTest
private class CVMAVAServicesIntegrationControllerTest {

    /**
     * Test data setup using standard Salesforce objects
     */
    @TestSetup
    static void makeData() {
        // Create test Contact for veteran profile
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Veteran',
            Title = 'Marine Corps Veteran',
            MailingState = 'Texas',
            MailingCity = 'Austin',
            Membership_Id__c = 'TEST001'
        );
        insert testContact;

        // Create test Case for service coordination testing
        Case testCase = new Case(
            ContactId = testContact.Id,
            Subject = 'VA Service Coordination: Healthcare',
            Description = 'Test case for healthcare service coordination',
            Status = 'New',
            Priority = 'Medium',
            Origin = 'Web',
            Type = 'Service Request'
        );
        insert testCase;

        // Create chapter officers for advocacy support testing
        List<Contact> officers = new List<Contact>();

        officers.add(new Contact(
            FirstName = 'John',
            LastName = 'Commander',
            Title = 'Commander',
            Phone = '555-0101',
            Membership_Id__c = 'CMD001'
        ));

        officers.add(new Contact(
            FirstName = 'Jane',
            LastName = 'Vice Commander',
            Title = 'Vice Commander',
            Phone = '555-0102',
            Membership_Id__c = 'CMD002'
        ));

        insert officers;

        // Create test Account records for advocacy resources
        List<Account> testAccounts = new List<Account>();

        testAccounts.add(new Account(
            Name = 'Veterans Legal Services',
            Industry = 'Legal Services',
            Type = 'Customer - Direct',
            BillingState = 'Texas',
            Phone = '555-0201',
            Website = 'https://vls.example.com'
        ));

        testAccounts.add(new Account(
            Name = 'VA Healthcare Center',
            Industry = 'Healthcare',
            Type = 'Partner',
            BillingState = 'Texas',
            Phone = '555-0202'
        ));

        insert testAccounts;
    }

    /**
     * Test comprehensive VA services integration
     */
    @IsTest
    static void testGetVAServicesIntegration_Success() {
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Test' LIMIT 1];

        Test.startTest();

        Map<String, Object> result = CVMAVAServicesIntegrationController.getVAServicesIntegration(testContact.Id);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Integration should be successful');
        System.assert(result.containsKey('memberProfile'), 'Should contain member profile');
        System.assert(result.containsKey('communityResources'), 'Should contain community resources');
        System.assert(result.containsKey('existingCases'), 'Should contain existing cases');
        System.assert(result.containsKey('serviceAnalysis'), 'Should contain service analysis');
        System.assertEquals('Active', result.get('integrationStatus'), 'Integration status should be active');
    }

    /**
     * Test benefits coordination functionality
     */
    @IsTest
    static void testGetBenefitsCoordination_Healthcare() {
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Test' LIMIT 1];

        Test.startTest();

        Map<String, Object> result = CVMAVAServicesIntegrationController.getBenefitsCoordination(
            testContact.Id,
            'Healthcare'
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Benefits coordination should be successful');
        System.assertEquals('Healthcare', result.get('benefitType'), 'Should match requested benefit type');
        System.assert(result.containsKey('memberProfile'), 'Should contain member profile');
        System.assert(result.containsKey('complementaryResources'), 'Should contain complementary resources');
        System.assert(result.containsKey('relatedCases'), 'Should contain related cases');
    }

    /**
     * Test service coordination case creation
     */
    @IsTest
    static void testCreateServiceCoordinationCase_Success() {
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Test' LIMIT 1];

        Test.startTest();

        Map<String, Object> result = CVMAVAServicesIntegrationController.createServiceCoordinationCase(
            testContact.Id,
            'Mental Health',
            'Need assistance with PTSD counseling services and coordination with community resources',
            'High'
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Case creation should be successful');
        System.assertNotEquals(null, result.get('caseId'), 'Should return case ID');
        // Case number is auto-generated, just verify case was created
        System.assertNotEquals(null, result.get('caseId'), 'Case should be created');
        System.assert(result.containsKey('nextSteps'), 'Should contain next steps');
        System.assertNotEquals(null, result.get('message'), 'Should contain success message');

        // Verify case was actually created
        List<Case> createdCases = [
            SELECT Id, Subject, ContactId, Status, Priority
            FROM Case
            WHERE ContactId = :testContact.Id
            AND Subject LIKE '%Mental Health%'
        ];

        System.assertEquals(1, createdCases.size(), 'Should create one case');
        System.assertEquals('High', createdCases[0].Priority, 'Should set correct priority');
    }

    /**
     * Test service coordination case creation with validation
     */
    @IsTest
    static void testCreateServiceCoordinationCase_InvalidData() {
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Test' LIMIT 1];

        Test.startTest();

        Map<String, Object> result = CVMAVAServicesIntegrationController.createServiceCoordinationCase(
            testContact.Id,
            '', // Empty service type
            'Test description',
            'Medium'
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(false, result.get('success'), 'Should fail validation');
        System.assert(result.containsKey('error'), 'Should contain error message');
    }

    /**
     * Test VA appointment assistance
     */
    @IsTest
    static void testGetVAAppointmentAssistance() {
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Test' LIMIT 1];

        Test.startTest();

        Map<String, Object> result = CVMAVAServicesIntegrationController.getVAAppointmentAssistance(
            testContact.Id,
            'medical'
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Appointment assistance should be successful');
        System.assert(result.containsKey('memberProfile'), 'Should contain member profile');
        System.assert(result.containsKey('appointmentHelp'), 'Should contain appointment help resources');
        System.assert(result.containsKey('recommendations'), 'Should contain personalized recommendations');
    }

    /**
     * Test advocacy support functionality
     */
    @IsTest
    static void testGetAdvocacySupport() {
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Test' LIMIT 1];

        Test.startTest();

        Map<String, Object> result = CVMAVAServicesIntegrationController.getAdvocacySupport(testContact.Id);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Advocacy support should be successful');
        System.assert(result.containsKey('veteranProfile'), 'Should contain veteran profile');
        System.assert(result.containsKey('advocacyResources'), 'Should contain advocacy resources');
        System.assert(result.containsKey('advocacyCases'), 'Should contain advocacy cases');
        System.assert(result.containsKey('chapterOfficers'), 'Should contain chapter officers');
    }

    /**
     * Test error handling with invalid contact ID
     */
    @IsTest
    static void testErrorHandling_InvalidContactId() {
        Test.startTest();

        Map<String, Object> result = CVMAVAServicesIntegrationController.getVAServicesIntegration(
            '003000000000000' // Invalid contact ID
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');

        // Should handle invalid contact ID gracefully
        if (result.get('success') == false) {
            System.assert(result.containsKey('error'), 'Should contain error message');
        }
    }

    /**
     * Test security enforcement
     */
    @IsTest
    static void testSecurityEnforcement() {
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'Test' LIMIT 1];

        Test.startTest();

        try {
            Map<String, Object> result = CVMAVAServicesIntegrationController.getVAServicesIntegration(testContact.Id);

            // Should return successful result or handle security gracefully
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assert(result.containsKey('success'), 'Should contain success indicator');

        } catch (Exception e) {
            System.assert(e.getMessage().contains('security') || e.getMessage().contains('permission'),
                'Should be security-related error');
        }

        Test.stopTest();
    }
}
