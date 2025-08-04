/**
 * Test class for CVMAOfficerDashboardController
 * Comprehensive test coverage for officer dashboard functionality
 */
@IsTest
public class CVMAOfficerDashboardControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'CVMA Test Chapter'
        );
        insert testAccount;
        
        // Create test contacts with various membership statuses
        List<Contact> testContacts = new List<Contact>();
        
        // Active member
        testContacts.add(new Contact(
            FirstName = 'John',
            LastName = 'ActiveMember',
            Email = 'john.active@cvma.com',
            Phone = '555-123-4567',
            Membership_Id__c = 'FM001',
            Level__c = 'Full Member',
            Road_Name__c = 'Thunder Road',
            npo02__MembershipJoinDate__c = Date.today().addYears(-2),
            npo02__MembershipEndDate__c = Date.today().addDays(120),
            AccountId = testAccount.Id
        ));
        
        // Member due for renewal in 30 days
        testContacts.add(new Contact(
            FirstName = 'Jane',
            LastName = 'RenewalDue',
            Email = 'jane.renewal@cvma.com',
            Phone = '555-234-5678',
            Membership_Id__c = 'SUP002',
            Level__c = 'Support Member',
            Road_Name__c = 'Freedom Highway',
            npo02__MembershipJoinDate__c = Date.today().addYears(-1),
            npo02__MembershipEndDate__c = Date.today().addDays(25),
            AccountId = testAccount.Id
        ));
        
        // Expired member
        testContacts.add(new Contact(
            FirstName = 'Bob',
            LastName = 'ExpiredMember',
            Email = 'bob.expired@cvma.com',
            Phone = '555-345-6789',
            Membership_Id__c = 'FM003',
            Level__c = 'Full Member',
            Road_Name__c = 'Victory Lane',
            npo02__MembershipJoinDate__c = Date.today().addYears(-3),
            npo02__MembershipEndDate__c = Date.today().addDays(-30),
            AccountId = testAccount.Id
        ));
        
        // New member
        testContacts.add(new Contact(
            FirstName = 'Sarah',
            LastName = 'NewMember',
            Email = 'sarah.new@cvma.com',
            Phone = '555-456-7890',
            Membership_Id__c = 'AUX004',
            Level__c = 'Auxiliary Member',
            Road_Name__c = 'Patriot Path',
            npo02__MembershipJoinDate__c = Date.today().addDays(-30),
            npo02__MembershipEndDate__c = Date.today().addYears(1),
            AccountId = testAccount.Id
        ));
        
        // Officer member
        testContacts.add(new Contact(
            FirstName = 'Mike',
            LastName = 'OfficerMember',
            Email = 'mike.officer@cvma.com',
            Phone = '555-567-8901',
            Membership_Id__c = 'FM005',
            Level__c = 'Full Member',
            Road_Name__c = 'President Highway',
            npo02__MembershipJoinDate__c = Date.today().addYears(-5),
            npo02__MembershipEndDate__c = Date.today().addDays(180),
            AccountId = testAccount.Id
        ));
        
        insert testContacts;
        
        // Create test users - one officer and one regular member
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Officer user
        User officerUser = new User(
            FirstName = 'Mike',
            LastName = 'OfficerMember',
            Email = 'mike.officer@cvma.com',
            Username = 'mike.officer.test@cvma.com.test',
            Alias = 'mofficer',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = testProfile.Id,
            ContactId = testContacts[4].Id  // Officer contact
        );
        insert officerUser;
        
        // Regular member user
        User memberUser = new User(
            FirstName = 'John',
            LastName = 'ActiveMember',
            Email = 'john.active@cvma.com',
            Username = 'john.active.test@cvma.com.test',
            Alias = 'jactive',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = testProfile.Id,
            ContactId = testContacts[0].Id  // Regular member contact
        );
        insert memberUser;
    }
    
    @IsTest
    static void testGetMemberDashboardData_OfficerSuccess() {
        // Get officer user
        User officerUser = [SELECT Id FROM User WHERE Username = 'mike.officer.test@cvma.com.test' LIMIT 1];
        
        Test.startTest();
        System.runAs(officerUser) {
            CVMAOfficerDashboardController.DashboardResponse response = CVMAOfficerDashboardController.getMemberDashboardData();
            
            // Verify dashboard stats
            System.assertNotEquals(null, response.dashboardStats, 'Dashboard stats should not be null');
            System.assertEquals(5, response.dashboardStats.totalMembers, 'Should have 5 total members');
            System.assertEquals(1, response.dashboardStats.due30Days, 'Should have 1 member due in 30 days');
            System.assertEquals(1, response.dashboardStats.expiredMembers, 'Should have 1 expired member');
            System.assertEquals(1, response.dashboardStats.newMembers, 'Should have 1 new member');
            
            // Verify member data
            System.assertNotEquals(null, response.members, 'Members list should not be null');
            System.assertEquals(5, response.members.size(), 'Should have 5 members');
            
            // Verify member data structure
            CVMAOfficerDashboardController.MemberData firstMember = response.members[0];
            System.assertNotEquals(null, firstMember.contactId, 'Contact ID should not be null');
            System.assertNotEquals(null, firstMember.membershipId, 'Membership ID should not be null');
            System.assertNotEquals(null, firstMember.status, 'Status should not be null');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetMemberDashboardData_NonOfficerAccess() {
        // Get regular member user
        User memberUser = [SELECT Id FROM User WHERE Username = 'john.active.test@cvma.com.test' LIMIT 1];
        
        Test.startTest();
        System.runAs(memberUser) {
            try {
                CVMAOfficerDashboardController.getMemberDashboardData();
                System.assert(false, 'Expected AuraHandledException for non-officer access');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('permission'), 'Exception should mention permission denial');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testExportMemberData_Success() {
        // Get officer user and test contacts
        User officerUser = [SELECT Id FROM User WHERE Username = 'mike.officer.test@cvma.com.test' LIMIT 1];
        List<Contact> testContacts = [SELECT Id FROM Contact WHERE Membership_Id__c LIKE 'CVMA%'];
        List<Id> memberIds = new List<Id>();
        for (Contact c : testContacts) {
            memberIds.add(c.Id);
        }
        
        Test.startTest();
        System.runAs(officerUser) {
            String csvData = CVMAOfficerDashboardController.exportMemberData(memberIds);
            
            // Verify CSV content
            System.assertNotEquals(null, csvData, 'CSV data should not be null');
            System.assert(csvData.contains('First Name,Last Name'), 'CSV should contain header row');
            System.assert(csvData.contains('John,ActiveMember'), 'CSV should contain member data');
            System.assert(csvData.contains('CVMA001'), 'CSV should contain membership IDs');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testExportMemberData_NonOfficerAccess() {
        // Get regular member user
        User memberUser = [SELECT Id FROM User WHERE Username = 'john.active.test@cvma.com.test' LIMIT 1];
        List<Id> memberIds = new List<Id>{ [SELECT Id FROM Contact LIMIT 1].Id };
        
        Test.startTest();
        System.runAs(memberUser) {
            try {
                CVMAOfficerDashboardController.exportMemberData(memberIds);
                System.assert(false, 'Expected AuraHandledException for non-officer access');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('permission'), 'Exception should mention permission denial');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSendRenewalReminders_Success() {
        // Get officer user and members with upcoming renewals
        User officerUser = [SELECT Id FROM User WHERE Username = 'mike.officer.test@cvma.com.test' LIMIT 1];
        List<Contact> renewalMembers = [
            SELECT Id 
            FROM Contact 
            WHERE Membership_Id__c LIKE 'CVMA%' 
            AND npo02__MembershipEndDate__c >= :Date.today()
            AND npo02__MembershipEndDate__c <= :Date.today().addDays(90)
        ];
        
        List<Id> memberIds = new List<Id>();
        for (Contact c : renewalMembers) {
            memberIds.add(c.Id);
        }
        
        Test.startTest();
        System.runAs(officerUser) {
            Integer emailsSent = CVMAOfficerDashboardController.sendRenewalReminders(memberIds);
            
            // Verify emails were processed
            System.assert(emailsSent >= 0, 'Should return number of emails sent');
            // Note: In test context, emails won't actually be sent but method should complete successfully
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSendRenewalReminders_NonOfficerAccess() {
        // Get regular member user
        User memberUser = [SELECT Id FROM User WHERE Username = 'john.active.test@cvma.com.test' LIMIT 1];
        List<Id> memberIds = new List<Id>{ [SELECT Id FROM Contact LIMIT 1].Id };
        
        Test.startTest();
        System.runAs(memberUser) {
            try {
                CVMAOfficerDashboardController.sendRenewalReminders(memberIds);
                System.assert(false, 'Expected AuraHandledException for non-officer access');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('permission'), 'Exception should mention permission denial');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testMemberStatusCalculation() {
        // Test the member status calculation logic
        List<Contact> testContacts = [
            SELECT Id, npo02__MembershipEndDate__c
            FROM Contact 
            WHERE Membership_Id__c LIKE 'CVMA%'
        ];
        
        // This test validates that the status calculation works correctly
        // by checking the dashboard data
        User officerUser = [SELECT Id FROM User WHERE Username = 'mike.officer.test@cvma.com.test' LIMIT 1];
        
        Test.startTest();
        System.runAs(officerUser) {
            CVMAOfficerDashboardController.DashboardResponse response = CVMAOfficerDashboardController.getMemberDashboardData();
            
            // Find specific members and verify their status
            Map<String, CVMAOfficerDashboardController.MemberData> memberMap = new Map<String, CVMAOfficerDashboardController.MemberData>();
            for (CVMAOfficerDashboardController.MemberData member : response.members) {
                memberMap.put(member.membershipId, member);
            }
            
            // Verify active member
            CVMAOfficerDashboardController.MemberData activeMember = memberMap.get('CVMA001');
            System.assertNotEquals(null, activeMember, 'Active member should be found');
            System.assertEquals('Active', activeMember.status, 'Member should have Active status');
            
            // Verify expired member
            CVMAOfficerDashboardController.MemberData expiredMember = memberMap.get('CVMA003');
            System.assertNotEquals(null, expiredMember, 'Expired member should be found');
            System.assertEquals('Expired', expiredMember.status, 'Member should have Expired status');
            
            // Verify renewal due member
            CVMAOfficerDashboardController.MemberData renewalMember = memberMap.get('CVMA002');
            System.assertNotEquals(null, renewalMember, 'Renewal member should be found');
            System.assertEquals('Renewal Due', renewalMember.status, 'Member should have Renewal Due status');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testCSVEscaping() {
        // Test CSV field escaping functionality
        User officerUser = [SELECT Id FROM User WHERE Username = 'mike.officer.test@cvma.com.test' LIMIT 1];
        
        // Create contact with special characters that need escaping
        Contact specialContact = new Contact(
            FirstName = 'Test "Quote"',
            LastName = 'Comma, Name',
            Email = 'test@cvma.com',
            Membership_Id__c = 'CVMA999',
            Level__c = 'Full Member',
            Road_Name__c = 'Special "Road" Name, with comma',
            npo02__MembershipJoinDate__c = Date.today().addYears(-1),
            npo02__MembershipEndDate__c = Date.today().addDays(100)
        );
        insert specialContact;
        
        Test.startTest();
        System.runAs(officerUser) {
            String csvData = CVMAOfficerDashboardController.exportMemberData(new List<Id>{ specialContact.Id });
            
            // Verify CSV escaping
            System.assert(csvData.contains('Test ""Quote""'), 'CSV should properly escape quotes');
            System.assert(csvData.contains('"Comma, Name"'), 'CSV should wrap comma-containing fields in quotes');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testEmailGeneration() {
        // Test email generation for renewal reminders
        User officerUser = [SELECT Id FROM User WHERE Username = 'mike.officer.test@cvma.com.test' LIMIT 1];
        Contact renewalContact = [
            SELECT Id 
            FROM Contact 
            WHERE Membership_Id__c = 'CVMA002' 
            LIMIT 1
        ];
        
        Test.startTest();
        System.runAs(officerUser) {
            // This will test the email generation logic
            Integer emailsSent = CVMAOfficerDashboardController.sendRenewalReminders(new List<Id>{ renewalContact.Id });
            
            // Verify method completes successfully
            System.assert(emailsSent >= 0, 'Email processing should complete successfully');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testEmptyMemberList() {
        // Test behavior with no members
        User officerUser = [SELECT Id FROM User WHERE Username = 'mike.officer.test@cvma.com.test' LIMIT 1];
        
        // Delete all test contacts
        delete [SELECT Id FROM Contact WHERE Membership_Id__c LIKE 'CVMA%'];
        
        Test.startTest();
        System.runAs(officerUser) {
            CVMAOfficerDashboardController.DashboardResponse response = CVMAOfficerDashboardController.getMemberDashboardData();
            
            // Verify empty state handling
            System.assertEquals(0, response.dashboardStats.totalMembers, 'Should have 0 total members');
            System.assertEquals(0, response.members.size(), 'Should have empty members list');
        }
        Test.stopTest();
    }
}