/**
 * Test class for CVMAMembershipApplicationController
 * Comprehensive test coverage for membership application functionality
 */
@IsTest
public class CVMAMembershipApplicationControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Use CVMATestDataFactory for consistent test data creation
        CVMATestDataFactory.TestDataBundle testData = CVMATestDataFactory.setupBasicTestData();
        
        // Create additional test contacts for membership applications
        List<Contact> additionalContacts = CVMATestDataFactory.createAndInsertContacts(3);
    }
    
    @IsTest
    static void testSubmitMembershipApplication_Success() {
        Map<String, Object> applicationData = createTestApplicationData();
        String jsonData = JSON.serialize(applicationData);
        
        Test.startTest();
        CVMAMembershipApplicationController.ApplicationResponse response = 
            CVMAMembershipApplicationController.submitMembershipApplication(jsonData);
        Test.stopTest();
        
        // Verify response
        System.assert(response.success, 'Application submission should succeed');
        System.assertNotEquals(null, response.applicationId, 'Application ID should be set');
        
        // Verify application record created
        List<Membership_Application__c> applications = [
            SELECT Id, Status__c, First_Name__c, Last_Name__c, Applicant_Email__c,
                   Service_Branch__c, Combat_Veteran__c
            FROM Membership_Application__c
            WHERE Id = :response.applicationId
        ];
        
        System.assertEquals(1, applications.size(), 'Should create one application');
        System.assertEquals('Pending Review', applications[0].Status__c, 'Status should be Pending Review');
        System.assertEquals('John', applications[0].First_Name__c, 'First name should match');
        System.assertEquals('TestApplicant', applications[0].Last_Name__c, 'Last name should match');
        System.assertEquals('john.test@cvma.com', applications[0].Applicant_Email__c, 'Email should match');
        System.assertEquals('Army', applications[0].Service_Branch__c, 'Service branch should match');
        System.assertEquals(true, applications[0].Combat_Veteran__c, 'Combat veteran flag should match');
        
        // Verify contact created
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Email, Level__c
            FROM Contact
            WHERE Email = 'john.test@cvma.com'
        ];
        
        System.assertEquals(1, contacts.size(), 'Should create applicant contact');
        System.assertEquals('Applicant', contacts[0].Level__c, 'Contact level should be Applicant');
    }
    
    @IsTest
    static void testSubmitMembershipApplication_DuplicateEmail() {
        // Create existing contact with membership
        Contact existingContact = new Contact(
            FirstName = 'Existing',
            LastName = 'Member',
            Email = 'john.test@cvma.com',
            Membership_Id__c = 'FM001',
            Level__c = 'Full Member'
        );
        insert existingContact;
        
        Map<String, Object> applicationData = createTestApplicationData();
        String jsonData = JSON.serialize(applicationData);
        
        Test.startTest();
        CVMAMembershipApplicationController.ApplicationResponse response = 
            CVMAMembershipApplicationController.submitMembershipApplication(jsonData);
        Test.stopTest();
        
        // Verify duplicate rejection
        System.assertEquals(false, response.success, 'Application should be rejected for duplicate email');
        System.assert(response.message.contains('already exists'), 'Message should indicate duplicate');
    }
    
    @IsTest
    static void testSubmitMembershipApplication_ValidationFailure() {
        Map<String, Object> applicationData = createTestApplicationData();
        applicationData.remove('firstName'); // Remove required field
        String jsonData = JSON.serialize(applicationData);
        
        Test.startTest();
        CVMAMembershipApplicationController.ApplicationResponse response = 
            CVMAMembershipApplicationController.submitMembershipApplication(jsonData);
        Test.stopTest();
        
        // Verify validation failure
        System.assertEquals(false, response.success, 'Application should fail validation');
        System.assert(response.message.contains('required fields'), 'Message should indicate validation error');
    }
    
    @IsTest
    static void testCheckApplicationStatus_Found() {
        // Create test application
        Membership_Application__c testApp = createTestApplication();
        insert testApp;
        
        Test.startTest();
        CVMAMembershipApplicationController.ApplicationStatusResponse response = 
            CVMAMembershipApplicationController.checkApplicationStatus('john.test@cvma.com');
        Test.stopTest();
        
        // Verify response
        System.assert(response.hasApplication, 'Should find application');
        System.assertNotEquals(null, response.application, 'Application data should be populated');
        System.assertEquals('John', response.application.firstName, 'First name should match');
        System.assertEquals('TestApplicant', response.application.lastName, 'Last name should match');
        System.assertEquals('Pending Review', response.application.status, 'Status should match');
    }
    
    @IsTest
    static void testCheckApplicationStatus_NotFound() {
        Test.startTest();
        CVMAMembershipApplicationController.ApplicationStatusResponse response = 
            CVMAMembershipApplicationController.checkApplicationStatus('nonexistent@cvma.com');
        Test.stopTest();
        
        // Verify response
        System.assertEquals(false, response.hasApplication, 'Should not find application');
        System.assertEquals(null, response.application, 'Application data should be null');
        System.assert(response.message.contains('No application found'), 'Message should indicate not found');
    }
    
    @IsTest
    static void testGetPendingApplications_OfficerAccess() {
        // Create test applications
        List<Membership_Application__c> testApps = new List<Membership_Application__c>();
        testApps.add(createTestApplication());
        testApps.add(createTestApplication('Jane', 'SecondApplicant', 'jane.test@cvma.com'));
        insert testApps;
        
        User officerUser = [SELECT Id FROM User WHERE Username = 'test.officer.app@cvma.com.test' LIMIT 1];
        
        Test.startTest();
        System.runAs(officerUser) {
            List<CVMAMembershipApplicationController.ApplicationData> applications = 
                CVMAMembershipApplicationController.getPendingApplications();
            
            // Verify results
            System.assertEquals(2, applications.size(), 'Should return 2 pending applications');
            System.assertEquals('Pending Review', applications[0].status, 'Status should be Pending Review');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetPendingApplications_NonOfficerAccess() {
        // Create regular user
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User regularUser = new User(
            FirstName = 'Regular',
            LastName = 'User',
            Email = 'regular.user@cvma.com',
            Username = 'regular.user.app@cvma.com.test',
            Alias = 'ruser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = testProfile.Id
        );
        insert regularUser;
        
        Test.startTest();
        System.runAs(regularUser) {
            try {
                CVMAMembershipApplicationController.getPendingApplications();
                System.assert(false, 'Expected AuraHandledException for non-officer access');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('permission'), 'Exception should mention permission denial');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateApplicationStatus_Approval() {
        // Create test application with contact
        Membership_Application__c testApp = createTestApplication();
        insert testApp;
        
        Contact applicantContact = new Contact(
            FirstName = 'John',
            LastName = 'TestApplicant',
            Email = 'john.test@cvma.com',
            Level__c = 'Applicant'
        );
        insert applicantContact;
        
        testApp.Applicant_Contact__c = applicantContact.Id;
        update testApp;
        
        User officerUser = [SELECT Id FROM User WHERE Username = 'test.officer.app@cvma.com.test' LIMIT 1];
        
        Test.startTest();
        System.runAs(officerUser) {
            String result = CVMAMembershipApplicationController.updateApplicationStatus(
                testApp.Id, 
                'Approved', 
                'Application approved - welcome to CVMA!'
            );
            
            System.assert(result.contains('successfully'), 'Update should succeed');
        }
        Test.stopTest();
        
        // Verify application updated
        Membership_Application__c updatedApp = [
            SELECT Status__c, Review_Notes__c, Reviewed_By__c, Review_Date__c
            FROM Membership_Application__c 
            WHERE Id = :testApp.Id
        ];
        
        System.assertEquals('Approved', updatedApp.Status__c, 'Status should be updated');
        System.assertEquals('Application approved - welcome to CVMA!', updatedApp.Review_Notes__c, 'Notes should be updated');
        System.assertEquals(officerUser.Id, updatedApp.Reviewed_By__c, 'Reviewer should be set');
        System.assertNotEquals(null, updatedApp.Review_Date__c, 'Review date should be set');
        
        // Verify contact upgraded to member
        Contact updatedContact = [
            SELECT Level__c, Membership_Id__c, npo02__MembershipJoinDate__c, npo02__MembershipEndDate__c
            FROM Contact 
            WHERE Id = :applicantContact.Id
        ];
        
        System.assertNotEquals('Applicant', updatedContact.Level__c, 'Contact level should be upgraded');
        System.assertNotEquals(null, updatedContact.Membership_Id__c, 'Membership ID should be assigned');
        System.assertNotEquals(null, updatedContact.npo02__MembershipJoinDate__c, 'Join date should be set');
        System.assertNotEquals(null, updatedContact.npo02__MembershipEndDate__c, 'End date should be set');
    }
    
    @IsTest
    static void testUpdateApplicationStatus_Rejection() {
        // Create test application with contact
        Membership_Application__c testApp = createTestApplication();
        insert testApp;
        
        Contact applicantContact = new Contact(
            FirstName = 'John',
            LastName = 'TestApplicant',
            Email = 'john.test@cvma.com',
            Level__c = 'Applicant'
        );
        insert applicantContact;
        
        testApp.Applicant_Contact__c = applicantContact.Id;
        update testApp;
        
        User officerUser = [SELECT Id FROM User WHERE Username = 'test.officer.app@cvma.com.test' LIMIT 1];
        
        Test.startTest();
        System.runAs(officerUser) {
            String result = CVMAMembershipApplicationController.updateApplicationStatus(
                testApp.Id, 
                'Rejected', 
                'Application rejected - insufficient documentation'
            );
            
            System.assert(result.contains('successfully'), 'Update should succeed');
        }
        Test.stopTest();
        
        // Verify application updated
        Membership_Application__c updatedApp = [
            SELECT Status__c, Review_Notes__c
            FROM Membership_Application__c 
            WHERE Id = :testApp.Id
        ];
        
        System.assertEquals('Rejected', updatedApp.Status__c, 'Status should be updated');
        System.assertEquals('Application rejected - insufficient documentation', updatedApp.Review_Notes__c, 'Notes should be updated');
        
        // Verify contact remains as applicant
        Contact updatedContact = [
            SELECT Level__c, Membership_Id__c
            FROM Contact 
            WHERE Id = :applicantContact.Id
        ];
        
        System.assertEquals('Applicant', updatedContact.Level__c, 'Contact level should remain Applicant');
        System.assertEquals(null, updatedContact.Membership_Id__c, 'Membership ID should remain null');
    }
    
    @IsTest
    static void testUpdateApplicationStatus_NonOfficerAccess() {
        // Create test application
        Membership_Application__c testApp = createTestApplication();
        insert testApp;
        
        // Create regular user
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User regularUser = new User(
            FirstName = 'Regular',
            LastName = 'User',
            Email = 'regular.user@cvma.com',
            Username = 'regular.user.app2@cvma.com.test',
            Alias = 'ruser2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = testProfile.Id
        );
        insert regularUser;
        
        Test.startTest();
        System.runAs(regularUser) {
            try {
                CVMAMembershipApplicationController.updateApplicationStatus(testApp.Id, 'Approved', 'Test');
                System.assert(false, 'Expected AuraHandledException for non-officer access');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('permission'), 'Exception should mention permission denial');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testMembershipIdGeneration() {
        // Create existing members to test ID generation
        List<Contact> existingMembers = new List<Contact>();
        existingMembers.add(new Contact(
            FirstName = 'Member',
            LastName = 'One',
            Email = 'member1@cvma.com',
            Membership_Id__c = 'FM001',
            Level__c = 'Full Member'
        ));
        existingMembers.add(new Contact(
            FirstName = 'Member',
            LastName = 'Two',
            Email = 'member2@cvma.com',
            Membership_Id__c = 'FM002',
            Level__c = 'Full Member'
        ));
        insert existingMembers;
        
        // Create and approve application
        Membership_Application__c testApp = createTestApplication();
        insert testApp;
        
        Contact applicantContact = new Contact(
            FirstName = 'John',
            LastName = 'TestApplicant',
            Email = 'john.test@cvma.com',
            Level__c = 'Applicant'
        );
        insert applicantContact;
        
        testApp.Applicant_Contact__c = applicantContact.Id;
        update testApp;
        
        User officerUser = [SELECT Id FROM User WHERE Username = 'test.officer.app@cvma.com.test' LIMIT 1];
        
        Test.startTest();
        System.runAs(officerUser) {
            CVMAMembershipApplicationController.updateApplicationStatus(testApp.Id, 'Approved', 'Approved');
        }
        Test.stopTest();
        
        // Verify membership ID generated correctly
        Contact updatedContact = [
            SELECT Membership_Id__c
            FROM Contact 
            WHERE Id = :applicantContact.Id
        ];
        
        System.assertEquals('FM003', updatedContact.Membership_Id__c, 'Should generate next sequential membership ID');
    }
    
    /**
     * Helper method to create test application data
     */
    private static Map<String, Object> createTestApplicationData() {
        Map<String, Object> appData = new Map<String, Object>();
        
        // Personal Information
        appData.put('firstName', 'John');
        appData.put('lastName', 'TestApplicant');
        appData.put('email', 'john.test@cvma.com');
        appData.put('phone', '555-123-4567');
        appData.put('mailingAddress', '123 Test Street');
        appData.put('city', 'Jacksonville');
        appData.put('state', 'FL');
        appData.put('postalCode', '32207');
        appData.put('dateOfBirth', '1985-01-01');
        appData.put('roadName', 'Test Rider');
        
        // Military Service
        appData.put('serviceStatus', 'Veteran');
        appData.put('servicesBranch', 'Army');
        appData.put('militaryOccupation', '11B Infantry');
        appData.put('serviceStartDate', '2003-01-01');
        appData.put('serviceEndDate', '2010-01-01');
        appData.put('deployments', 'Iraq 2004-2005, Afghanistan 2007-2008');
        appData.put('awards', 'Purple Heart, Combat Infantry Badge');
        appData.put('isCombatVeteran', true);
        
        // Emergency Contact
        appData.put('emergencyContactName', 'Jane TestApplicant');
        appData.put('emergencyContactRelationship', 'Spouse');
        appData.put('emergencyContactPhone', '555-234-5678');
        appData.put('emergencyContactEmail', 'jane.test@cvma.com');
        appData.put('membershipLevel', 'Full Member');
        
        return appData;
    }
    
    /**
     * Helper method to create test application record
     */
    private static Membership_Application__c createTestApplication() {
        return createTestApplication('John', 'TestApplicant', 'john.test@cvma.com');
    }
    
    private static Membership_Application__c createTestApplication(String firstName, String lastName, String email) {
        Membership_Application__c app = new Membership_Application__c();
        app.First_Name__c = firstName;
        app.Last_Name__c = lastName;
        app.Applicant_Email__c = email;
        app.Phone__c = '555-123-4567';
        app.Mailing_Address__c = '123 Test Street';
        app.City__c = 'Jacksonville';
        app.State__c = 'FL';
        app.Postal_Code__c = '32207';
        app.Date_of_Birth__c = Date.valueOf('1985-01-01');
        app.Road_Name__c = 'Test Rider';
        app.Service_Status__c = 'Veteran';
        app.Service_Branch__c = 'Army';
        app.Military_Occupation__c = '11B Infantry';
        app.Service_Start_Date__c = Date.valueOf('2003-01-01');
        app.Service_End_Date__c = Date.valueOf('2010-01-01');
        app.Deployments__c = 'Iraq 2004-2005, Afghanistan 2007-2008';
        app.Awards__c = 'Purple Heart, Combat Infantry Badge';
        app.Combat_Veteran__c = true;
        app.Emergency_Contact_Name__c = 'Jane TestApplicant';
        app.Emergency_Contact_Relationship__c = 'Spouse';
        app.Emergency_Contact_Phone__c = '555-234-5678';
        app.Emergency_Contact_Email__c = 'jane.test@cvma.com';
        app.Membership_Level__c = 'Full Member';
        app.Status__c = 'Pending Review';
        app.Submission_Date__c = DateTime.now();
        
        return app;
    }
}