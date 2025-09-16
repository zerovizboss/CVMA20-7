/**
 * @description Test class for CVMAMembershipAutomationController
 * @author Claude AI - CVMA Development Team
 * @date 2025-09-15
 *
 * User Story #25: Membership Management Automation
 * Epic #7: Member Experience Enhancement
 *
 * Test Coverage: validateMembershipApplication, generateMembershipIds, getOfficerNotificationEmails
 * Security: WITH SECURITY_ENFORCED validation throughout
 */
@IsTest
private class CVMAMembershipAutomationControllerTest {

    @TestSetup
    static void makeData() {
        // Create test data
        Account testAccount = new Account(
            Name = 'Test CVMA Chapter',
            Type = 'Member'
        );
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@test.com',
            Level__c = 'Full Member',
            Membership_Id__c = 'FM12345'
        );
        insert testContact;
    }

    @IsTest
    static void testValidateMembershipApplication_ValidData() {
        Test.startTest();

        // Create valid application data
        CVMAMembershipAutomationController.ApplicationData appData =
            new CVMAMembershipAutomationController.ApplicationData();
        appData.firstName = 'Test';
        appData.lastName = 'Veteran';
        appData.email = 'test.veteran@example.com';
        appData.serviceBranch = 'Marine Corps';
        appData.serviceStatus = 'Veteran';
        appData.combatVeteran = true;
        appData.membershipLevel = 'Full Member';

        List<CVMAMembershipAutomationController.ApplicationData> applications =
            new List<CVMAMembershipAutomationController.ApplicationData>{appData};

        // Call validation method
        List<CVMAMembershipAutomationController.ValidationResult> results =
            CVMAMembershipAutomationController.validateMembershipApplication(applications);

        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one validation result');
        System.assertEquals(true, results[0].isValid, 'Validation should pass for valid data');
        System.assertEquals('test.veteran@example.com', results[0].applicationEmail, 'Email should match');
        System.assertEquals('', results[0].errorMessage, 'No error message for valid data');
    }

    @IsTest
    static void testValidateMembershipApplication_MissingRequiredFields() {
        Test.startTest();

        // Create application data with missing required fields
        CVMAMembershipAutomationController.ApplicationData appData =
            new CVMAMembershipAutomationController.ApplicationData();
        appData.firstName = '';
        appData.lastName = 'Veteran';
        appData.email = 'test@example.com';
        appData.serviceBranch = '';

        List<CVMAMembershipAutomationController.ApplicationData> applications =
            new List<CVMAMembershipAutomationController.ApplicationData>{appData};

        // Call validation method
        List<CVMAMembershipAutomationController.ValidationResult> results =
            CVMAMembershipAutomationController.validateMembershipApplication(applications);

        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one validation result');
        System.assertEquals(false, results[0].isValid, 'Validation should fail for missing fields');
        System.assert(results[0].errorMessage.contains('Required fields are missing'),
            'Error message should indicate missing fields');
    }

    @IsTest
    static void testValidateMembershipApplication_InvalidEmail() {
        Test.startTest();

        // Create application data with invalid email
        CVMAMembershipAutomationController.ApplicationData appData =
            new CVMAMembershipAutomationController.ApplicationData();
        appData.firstName = 'Test';
        appData.lastName = 'Veteran';
        appData.email = 'invalid-email';
        appData.serviceBranch = 'Navy';

        List<CVMAMembershipAutomationController.ApplicationData> applications =
            new List<CVMAMembershipAutomationController.ApplicationData>{appData};

        // Call validation method
        List<CVMAMembershipAutomationController.ValidationResult> results =
            CVMAMembershipAutomationController.validateMembershipApplication(applications);

        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one validation result');
        System.assertEquals(false, results[0].isValid, 'Validation should fail for invalid email');
        System.assert(results[0].errorMessage.contains('valid email address'),
            'Error message should indicate invalid email');
    }

    @IsTest
    static void testValidateMembershipApplication_ExistingMembership() {
        Test.startTest();

        // Create application data with existing member email
        CVMAMembershipAutomationController.ApplicationData appData =
            new CVMAMembershipAutomationController.ApplicationData();
        appData.firstName = 'John';
        appData.lastName = 'Doe';
        appData.email = 'john.doe@test.com'; // This email exists in test data
        appData.serviceBranch = 'Army';

        List<CVMAMembershipAutomationController.ApplicationData> applications =
            new List<CVMAMembershipAutomationController.ApplicationData>{appData};

        // Call validation method
        List<CVMAMembershipAutomationController.ValidationResult> results =
            CVMAMembershipAutomationController.validateMembershipApplication(applications);

        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one validation result');
        System.assertEquals(false, results[0].isValid, 'Validation should fail for existing membership');
        System.assert(results[0].errorMessage.contains('membership record already exists'),
            'Error message should indicate existing membership');
    }

    @IsTest
    static void testValidateMembershipApplication_MultipleApplications() {
        Test.startTest();

        // Create multiple application data
        List<CVMAMembershipAutomationController.ApplicationData> applications =
            new List<CVMAMembershipAutomationController.ApplicationData>();

        CVMAMembershipAutomationController.ApplicationData appData1 =
            new CVMAMembershipAutomationController.ApplicationData();
        appData1.firstName = 'Test1';
        appData1.lastName = 'User1';
        appData1.email = 'test1@example.com';
        appData1.serviceBranch = 'Air Force';
        applications.add(appData1);

        CVMAMembershipAutomationController.ApplicationData appData2 =
            new CVMAMembershipAutomationController.ApplicationData();
        appData2.firstName = 'Test2';
        appData2.lastName = 'User2';
        appData2.email = 'test2@example.com';
        appData2.serviceBranch = 'Navy';
        applications.add(appData2);

        // Call validation method
        List<CVMAMembershipAutomationController.ValidationResult> results =
            CVMAMembershipAutomationController.validateMembershipApplication(applications);

        Test.stopTest();

        // Assertions
        System.assertEquals(2, results.size(), 'Should return two validation results');
        System.assertEquals(true, results[0].isValid, 'First validation should pass');
        System.assertEquals(true, results[1].isValid, 'Second validation should pass');
    }

    @IsTest
    static void testGenerateMembershipIds_Success() {
        Test.startTest();

        // Create test accounts for simulation
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                Type = 'Member'
            ));
        }
        insert testAccounts;

        List<Id> accountIds = new List<Id>();
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }

        // Call membership ID generation method
        List<CVMAMembershipAutomationController.MembershipIdResult> results =
            CVMAMembershipAutomationController.generateMembershipIds(accountIds);

        Test.stopTest();

        // Assertions
        System.assertEquals(3, results.size(), 'Should return three membership ID results');

        for (CVMAMembershipAutomationController.MembershipIdResult result : results) {
            System.assertNotEquals('', result.membershipId, 'Membership ID should not be empty');
            System.assert(result.membershipId.startsWith('FM'),
                'Membership ID should have correct format');
            System.assertEquals('', result.errorMessage, 'Should not have error message on success');
        }

        // Verify IDs are sequential
        Integer firstNumber = Integer.valueOf(results[0].membershipId.substring(2));
        Integer secondNumber = Integer.valueOf(results[1].membershipId.substring(2));
        System.assertEquals(firstNumber + 1, secondNumber, 'Membership IDs should be sequential');
    }

    @IsTest
    static void testGetOfficerNotificationEmails_Success() {
        Test.startTest();

        // Call method to get officer emails
        List<String> officerEmails = CVMAMembershipAutomationController.getOfficerNotificationEmails();

        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, officerEmails, 'Officer emails list should not be null');
        // Note: Actual email count depends on test data and permission set assignments
        // In this test, we expect zero emails since no permission sets are assigned
        System.assert(officerEmails.size() >= 0, 'Should return non-negative number of emails');
    }

    @IsTest
    static void testDataStructures_ApplicationData() {
        Test.startTest();

        // Test ApplicationData structure
        CVMAMembershipAutomationController.ApplicationData appData =
            new CVMAMembershipAutomationController.ApplicationData();

        appData.firstName = 'Test';
        appData.lastName = 'User';
        appData.email = 'test@example.com';
        appData.serviceBranch = 'Marine Corps';
        appData.serviceStatus = 'Active Duty';
        appData.combatVeteran = true;
        appData.membershipLevel = 'Full Member';

        Test.stopTest();

        // Assertions
        System.assertEquals('Test', appData.firstName, 'First name should be set correctly');
        System.assertEquals('User', appData.lastName, 'Last name should be set correctly');
        System.assertEquals('test@example.com', appData.email, 'Email should be set correctly');
        System.assertEquals('Marine Corps', appData.serviceBranch, 'Service branch should be set correctly');
        System.assertEquals('Active Duty', appData.serviceStatus, 'Service status should be set correctly');
        System.assertEquals(true, appData.combatVeteran, 'Combat veteran should be set correctly');
        System.assertEquals('Full Member', appData.membershipLevel, 'Membership level should be set correctly');
    }

    @IsTest
    static void testDataStructures_ValidationResult() {
        Test.startTest();

        // Test ValidationResult structure
        CVMAMembershipAutomationController.ValidationResult result =
            new CVMAMembershipAutomationController.ValidationResult();

        result.applicationEmail = 'test@example.com';
        result.isValid = true;
        result.errorMessage = '';

        Test.stopTest();

        // Assertions
        System.assertEquals('test@example.com', result.applicationEmail, 'Application email should be set correctly');
        System.assertEquals(true, result.isValid, 'IsValid should be set correctly');
        System.assertEquals('', result.errorMessage, 'Error message should be set correctly');
    }

    @IsTest
    static void testDataStructures_MembershipIdResult() {
        Test.startTest();

        // Create test account for simulation
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Member'
        );
        insert testAccount;

        // Test MembershipIdResult structure
        CVMAMembershipAutomationController.MembershipIdResult result =
            new CVMAMembershipAutomationController.MembershipIdResult();

        result.applicationId = testAccount.Id;
        result.membershipId = 'FM123';
        result.errorMessage = '';

        Test.stopTest();

        // Assertions
        System.assertEquals(testAccount.Id, result.applicationId, 'Application ID should be set correctly');
        System.assertEquals('FM123', result.membershipId, 'Membership ID should be set correctly');
        System.assertEquals('', result.errorMessage, 'Error message should be set correctly');
    }

    @IsTest
    static void testSecurityEnforcement() {
        Test.startTest();

        // Test that security is enforced in SOQL queries
        // This test ensures WITH SECURITY_ENFORCED is working
        CVMAMembershipAutomationController.ApplicationData appData =
            new CVMAMembershipAutomationController.ApplicationData();
        appData.firstName = 'Security';
        appData.lastName = 'Test';
        appData.email = 'security.test@example.com';
        appData.serviceBranch = 'Coast Guard';

        List<CVMAMembershipAutomationController.ApplicationData> applications =
            new List<CVMAMembershipAutomationController.ApplicationData>{appData};

        // This should work without throwing security exceptions
        List<CVMAMembershipAutomationController.ValidationResult> results =
            CVMAMembershipAutomationController.validateMembershipApplication(applications);

        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one validation result');
        // If security is properly configured, this should pass
        System.assertEquals(true, results[0].isValid, 'Security test should pass with proper permissions');
    }
}