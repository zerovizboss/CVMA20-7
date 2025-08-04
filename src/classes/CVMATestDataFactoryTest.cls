/**
 * Test class for CVMATestDataFactory
 * Demonstrates usage patterns and validates factory functionality
 */
@IsTest
private class CVMATestDataFactoryTest {
    
    @IsTest
    static void testContactBuilder() {
        Test.startTest();
        
        // Test basic contact creation
        Contact basicContact = CVMATestDataFactory.createContact().build();
        System.assertNotEquals(null, basicContact.FirstName, 'First name should be populated');
        System.assertNotEquals(null, basicContact.LastName, 'Last name should be populated');
        System.assertNotEquals(null, basicContact.Email, 'Email should be populated');
        System.assertNotEquals(null, basicContact.Membership_Id__c, 'Membership ID should be populated');
        
        // Test contact with custom values
        Contact customContact = CVMATestDataFactory.createContact()
            .withFirstName('John')
            .withLastName('Doe')
            .withEmail('john.doe@example.com')
            .withLevel('Associate Member')
            .withRoadName('Road King')
            .build();
            
        System.assertEquals('John', customContact.FirstName, 'Custom first name should be set');
        System.assertEquals('Doe', customContact.LastName, 'Custom last name should be set');
        System.assertEquals('john.doe@example.com', customContact.Email, 'Custom email should be set');
        System.assertEquals('Associate Member', customContact.Level__c, 'Custom level should be set');
        System.assertEquals('Road King', customContact.Road_Name__c, 'Custom road name should be set');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testContactWithMembershipStatuses() {
        Test.startTest();
        
        // Test expired membership
        Contact expiredContact = CVMATestDataFactory.createContact()
            .withExpiredMembership()
            .build();
        System.assert(expiredContact.npo02__MembershipEndDate__c < Date.today(), 'Should have expired membership');
        
        // Test expiring membership
        Contact expiringContact = CVMATestDataFactory.createContact()
            .withExpiringMembership()
            .build();
        System.assert(expiringContact.npo02__MembershipEndDate__c > Date.today(), 'Should have future expiration');
        System.assert(expiringContact.npo02__MembershipEndDate__c <= Date.today().addDays(30), 'Should expire within 30 days');
        
        // Test new membership
        Contact newContact = CVMATestDataFactory.createContact()
            .withNewMembership()
            .build();
        System.assert(newContact.npo02__MembershipJoinDate__c >= Date.today().addDays(-30), 'Should be recent member');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testUserBuilder() {
        Test.startTest();
        
        // Test basic user creation
        User basicUser = CVMATestDataFactory.createUser().build();
        System.assertNotEquals(null, basicUser.FirstName, 'First name should be populated');
        System.assertNotEquals(null, basicUser.LastName, 'Last name should be populated');
        System.assertNotEquals(null, basicUser.Email, 'Email should be populated');
        System.assertNotEquals(null, basicUser.Username, 'Username should be populated');
        System.assertNotEquals(null, basicUser.ProfileId, 'Profile ID should be populated');
        
        // Test custom user
        User customUser = CVMATestDataFactory.createUser()
            .withFirstName('Jane')
            .withLastName('Smith')
            .withEmail('jane.smith@example.com')
            .build();
            
        System.assertEquals('Jane', customUser.FirstName, 'Custom first name should be set');
        System.assertEquals('Smith', customUser.LastName, 'Custom last name should be set');
        System.assertEquals('jane.smith@example.com', customUser.Email, 'Custom email should be set');
        System.assertEquals('jane.smith@example.com', customUser.Username, 'Username should match email');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testAccountBuilder() {
        Test.startTest();
        
        // Test basic account creation
        Account basicAccount = CVMATestDataFactory.createAccount().build();
        System.assertNotEquals(null, basicAccount.Name, 'Account name should be populated');
        System.assertEquals('Customer', basicAccount.Type, 'Default type should be Customer');
        
        // Test custom account
        Account customAccount = CVMATestDataFactory.createAccount()
            .withName('CVMA Test Chapter')
            .withType('Partner')
            .withBillingAddress('456 Main St', 'Orlando', 'FL', '32801')
            .build();
            
        System.assertEquals('CVMA Test Chapter', customAccount.Name, 'Custom name should be set');
        System.assertEquals('Partner', customAccount.Type, 'Custom type should be set');
        System.assertEquals('456 Main St', customAccount.BillingStreet, 'Custom street should be set');
        System.assertEquals('Orlando', customAccount.BillingCity, 'Custom city should be set');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testBulkDataCreation() {
        Test.startTest();
        
        // Test bulk contact creation
        List<Contact> contacts = CVMATestDataFactory.createContacts(10);
        System.assertEquals(10, contacts.size(), 'Should create 10 contacts');
        
        // Verify unique data
        Set<String> emails = new Set<String>();
        Set<String> membershipIds = new Set<String>();
        for (Contact contact : contacts) {
            emails.add(contact.Email);
            membershipIds.add(contact.Membership_Id__c);
        }
        System.assertEquals(10, emails.size(), 'All emails should be unique');
        System.assertEquals(10, membershipIds.size(), 'All membership IDs should be unique');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testMembersWithVariousStatuses() {
        Test.startTest();
        
        // Test creating members with various statuses
        List<Contact> members = CVMATestDataFactory.createMembersWithVariousStatuses(10);
        System.assertEquals(10, members.size(), 'Should create 10 members');
        
        // Count different statuses
        Integer activeCount = 0;
        Integer expiringCount = 0;
        Integer expiredCount = 0;
        Integer newCount = 0;
        
        for (Contact member : members) {
            if (member.npo02__MembershipEndDate__c < Date.today()) {
                expiredCount++;
            } else if (member.npo02__MembershipEndDate__c <= Date.today().addDays(30)) {
                expiringCount++;
            } else if (member.npo02__MembershipJoinDate__c >= Date.today().addDays(-30)) {
                newCount++;
            } else {
                activeCount++;
            }
        }
        
        System.assert(activeCount > 0, 'Should have some active members');
        System.assert(expiringCount > 0 || expiredCount > 0, 'Should have some expiring or expired members');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testErrorLogCreation() {
        Test.startTest();
        
        // Test error log creation
        List<CVMA_Error_Log__c> errorLogs = CVMATestDataFactory.createErrorLogs(5);
        System.assertEquals(5, errorLogs.size(), 'Should create 5 error logs');
        
        // Verify fields are populated
        for (CVMA_Error_Log__c errorLog : errorLogs) {
            System.assertNotEquals(null, errorLog.Class_Name__c, 'Class name should be populated');
            System.assertNotEquals(null, errorLog.Method_Name__c, 'Method name should be populated');
            System.assertNotEquals(null, errorLog.Error_Message__c, 'Error message should be populated');
            System.assertNotEquals(null, errorLog.Severity__c, 'Severity should be populated');
            System.assertNotEquals(null, errorLog.Category__c, 'Category should be populated');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testBasicTestDataSetup() {
        Test.startTest();
        
        // Test complete test data setup
        CVMATestDataFactory.TestDataBundle bundle = CVMATestDataFactory.setupBasicTestData();
        
        // Verify account
        System.assertNotEquals(null, bundle.testAccount, 'Test account should be created');
        System.assertNotEquals(null, bundle.testAccount.Id, 'Test account should be inserted');
        
        // Verify contacts
        System.assertEquals(5, bundle.activeContacts.size(), 'Should have 5 active contacts');
        System.assertEquals(3, bundle.expiringContacts.size(), 'Should have 3 expiring contacts');
        System.assertEquals(2, bundle.expiredContacts.size(), 'Should have 2 expired contacts');
        
        // Verify all contacts have IDs (were inserted)
        for (Contact contact : bundle.getAllContacts()) {
            System.assertNotEquals(null, contact.Id, 'Contact should be inserted');
            System.assertEquals(bundle.testAccount.Id, contact.AccountId, 'Contact should be linked to test account');
        }
        
        // Verify users
        System.assertNotEquals(null, bundle.adminUser, 'Admin user should be created');
        System.assertNotEquals(null, bundle.standardUser, 'Standard user should be created');
        System.assertNotEquals(null, bundle.adminUser.Id, 'Admin user should be inserted');
        System.assertNotEquals(null, bundle.standardUser.Id, 'Standard user should be inserted');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateAndInsertMethods() {
        Test.startTest();
        
        // Test create and insert methods
        Contact insertedContact = CVMATestDataFactory.createContact().create();
        System.assertNotEquals(null, insertedContact.Id, 'Contact should be inserted and have ID');
        
        Account insertedAccount = CVMATestDataFactory.createAccount().create();
        System.assertNotEquals(null, insertedAccount.Id, 'Account should be inserted and have ID');
        
        // Test bulk insert
        List<Contact> insertedContacts = CVMATestDataFactory.createAndInsertContacts(3);
        System.assertEquals(3, insertedContacts.size(), 'Should create 3 contacts');
        for (Contact contact : insertedContacts) {
            System.assertNotEquals(null, contact.Id, 'Each contact should have ID');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testDataUniqueness() {
        Test.startTest();
        
        // Create multiple records and verify uniqueness
        List<Contact> contacts1 = CVMATestDataFactory.createContacts(5);
        List<Contact> contacts2 = CVMATestDataFactory.createContacts(5);
        
        // Collect all emails and membership IDs
        Set<String> allEmails = new Set<String>();
        Set<String> allMembershipIds = new Set<String>();
        
        for (Contact contact : contacts1) {
            allEmails.add(contact.Email);
            allMembershipIds.add(contact.Membership_Id__c);
        }
        
        for (Contact contact : contacts2) {
            allEmails.add(contact.Email);
            allMembershipIds.add(contact.Membership_Id__c);
        }
        
        // Verify all are unique across both batches
        System.assertEquals(10, allEmails.size(), 'All emails should be unique across batches');
        System.assertEquals(10, allMembershipIds.size(), 'All membership IDs should be unique across batches');
        
        Test.stopTest();
    }
}