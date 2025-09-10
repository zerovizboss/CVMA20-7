/**
 * @description Test class for CVMAFinancialControllerSimplified
 * @author Claude AI - CVMA Development Team
 * @date 2025-09-10
 */
@IsTest
public class CVMAFinancialControllerSimplifiedTest {

    @TestSetup
    static void makeData() {
        // Create test data using CVMATestDataFactory
        CVMATestDataFactory.TestDataBundle testData = CVMATestDataFactory.createTestDataBundle();

        // Create CVMA-specific test opportunities
        List<Opportunity> testOpps = new List<Opportunity>();

        for (Contact member : testData.contacts) {
            Opportunity dues = new Opportunity();
            dues.Name = 'Annual Dues - ' + member.Name;
            dues.npsp__Primary_Contact__c = member.Id;
            dues.Amount = CVMAFinancialControllerSimplified.calculateMemberDues(member.Level__c);
            dues.StageName = 'Pledged';
            dues.CloseDate = Date.today().addDays(30);
            dues.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Donation').getRecordTypeId();
            testOpps.add(dues);
        }

        insert testOpps;
    }

    @IsTest
    static void testCalculateMemberDues_FullMember() {
        Test.startTest();
        Decimal result = CVMAFinancialControllerSimplified.calculateMemberDues('Full Member');
        Test.stopTest();

        System.assertEquals(120.00, result, 'Full member dues should be $120');
    }

    @IsTest
    static void testCalculateMemberDues_Associate() {
        Test.startTest();
        Decimal result = CVMAFinancialControllerSimplified.calculateMemberDues('Associate');
        Test.stopTest();

        System.assertEquals(60.00, result, 'Associate member dues should be $60');
    }

    @IsTest
    static void testCalculateMemberDues_Prospect() {
        Test.startTest();
        Decimal result = CVMAFinancialControllerSimplified.calculateMemberDues('Prospect');
        Test.stopTest();

        System.assertEquals(30.00, result, 'Prospect member dues should be $30');
    }

    @IsTest
    static void testCalculateMemberDues_InvalidLevel() {
        Test.startTest();
        try {
            CVMAFinancialControllerSimplified.calculateMemberDues('Invalid Level');
            System.assert(false, 'Expected exception for invalid level');
        } catch (CVMAErrorHandler.ValidationException e) {
            System.assert(e.getMessage().contains('Invalid membership level'), 'Should throw validation exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCalculateMemberDues_NullInput() {
        Test.startTest();
        try {
            CVMAFinancialControllerSimplified.calculateMemberDues(null);
            System.assert(false, 'Expected exception for null input');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required input');
        }
        Test.stopTest();
    }

    @IsTest
    static void testProcessCVMAPayment_Success() {
        // Create test user with treasurer permissions
        User treasurerUser = CVMATestDataFactory.createUser()
            .withProfile('System Administrator')
            .create();

        // Create permission set assignment (simulated)
        System.runAs(treasurerUser) {
            // Get test opportunity
            Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Annual Dues%' LIMIT 1];

            // Create payment wrapper
            CVMAFinancialControllerSimplified.PaymentWrapper payment = new CVMAFinancialControllerSimplified.PaymentWrapper();
            payment.opportunityId = testOpp.Id;
            payment.amount = 120.00;
            payment.paymentDate = Date.today();
            payment.paymentMethod = 'Check';

            Test.startTest();
            CVMAFinancialControllerSimplified.PaymentResponse result = CVMAFinancialControllerSimplified.processCVMAPayment(payment);
            Test.stopTest();

            System.assertEquals(true, result.success, 'Payment processing should succeed');
            System.assert(result.paymentId != null, 'Payment ID should be returned');
        }
    }

    @IsTest
    static void testProcessCVMAPayment_ValidationError() {
        User treasurerUser = CVMATestDataFactory.createUser()
            .withProfile('System Administrator')
            .create();

        System.runAs(treasurerUser) {
            Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Annual Dues%' LIMIT 1];

            // Create invalid payment (negative amount)
            CVMAFinancialControllerSimplified.PaymentWrapper payment = new CVMAFinancialControllerSimplified.PaymentWrapper();
            payment.opportunityId = testOpp.Id;
            payment.amount = -100.00;  // Invalid negative amount
            payment.paymentDate = Date.today();
            payment.paymentMethod = 'Check';

            Test.startTest();
            CVMAFinancialControllerSimplified.PaymentResponse result = CVMAFinancialControllerSimplified.processCVMAPayment(payment);
            Test.stopTest();

            System.assertEquals(false, result.success, 'Payment should fail validation');
            System.assert(result.message.contains('positive'), 'Should contain validation message');
        }
    }

    @IsTest
    static void testProcessCVMAPayment_LargeAmountValidation() {
        User treasurerUser = CVMATestDataFactory.createUser()
            .withProfile('System Administrator')
            .create();

        System.runAs(treasurerUser) {
            Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name LIKE 'Annual Dues%' LIMIT 1];

            // Create large payment requiring approval
            CVMAFinancialControllerSimplified.PaymentWrapper payment = new CVMAFinancialControllerSimplified.PaymentWrapper();
            payment.opportunityId = testOpp.Id;
            payment.amount = 600.00;  // Over $500 limit
            payment.paymentDate = Date.today();
            payment.paymentMethod = 'Check';

            Test.startTest();
            CVMAFinancialControllerSimplified.PaymentResponse result = CVMAFinancialControllerSimplified.processCVMAPayment(payment);
            Test.stopTest();

            System.assertEquals(false, result.success, 'Large payment should require approval');
            System.assert(result.message.contains('approval'), 'Should mention approval requirement');
        }
    }

    @IsTest
    static void testGetCVMAFinancialConfig() {
        Test.startTest();
        CVMAFinancialControllerSimplified.CVMAFinancialConfig config = CVMAFinancialControllerSimplified.getCVMAFinancialConfig();
        Test.stopTest();

        System.assertEquals(120.00, config.fullMemberDues, 'Full member config should be correct');
        System.assertEquals(60.00, config.associateDues, 'Associate config should be correct');
        System.assertEquals(30.00, config.prospectDues, 'Prospect config should be correct');
        System.assert(config.reportingNote.contains('NPSP'), 'Should reference NPSP reports');
    }

    @IsTest
    static void testPaymentWrapper_DataTransfer() {
        // Test data transfer object functionality
        CVMAFinancialControllerSimplified.PaymentWrapper wrapper = new CVMAFinancialControllerSimplified.PaymentWrapper();
        wrapper.opportunityId = 'test123';
        wrapper.amount = 100.00;
        wrapper.paymentDate = Date.today();
        wrapper.paymentMethod = 'Cash';

        System.assertEquals('test123', wrapper.opportunityId, 'Opportunity ID should be set');
        System.assertEquals(100.00, wrapper.amount, 'Amount should be set');
        System.assertEquals(Date.today(), wrapper.paymentDate, 'Payment date should be set');
        System.assertEquals('Cash', wrapper.paymentMethod, 'Payment method should be set');
    }

    @IsTest
    static void testPaymentResponse_Constructor() {
        CVMAFinancialControllerSimplified.PaymentResponse response =
            new CVMAFinancialControllerSimplified.PaymentResponse(true, 'Success', 'pay123');

        System.assertEquals(true, response.success, 'Success should be set');
        System.assertEquals('Success', response.message, 'Message should be set');
        System.assertEquals('pay123', response.paymentId, 'Payment ID should be set');
    }

    @IsTest
    static void testCVMAFinancialConfig_Constructor() {
        CVMAFinancialControllerSimplified.CVMAFinancialConfig config =
            new CVMAFinancialControllerSimplified.CVMAFinancialConfig(120, 60, 30, 'Test note');

        System.assertEquals(120, config.fullMemberDues, 'Full member dues should be set');
        System.assertEquals(60, config.associateDues, 'Associate dues should be set');
        System.assertEquals(30, config.prospectDues, 'Prospect dues should be set');
        System.assertEquals('Test note', config.reportingNote, 'Note should be set');
    }
}
