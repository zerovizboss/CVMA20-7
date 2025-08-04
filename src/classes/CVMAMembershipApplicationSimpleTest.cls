/**
 * Simplified test class for CVMAMembershipApplicationController
 * Focuses on core functionality without user-contact linking issues
 */
@IsTest
public class CVMAMembershipApplicationSimpleTest {
    
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
        Membership_Application__c app = new Membership_Application__c();
        app.First_Name__c = 'John';
        app.Last_Name__c = 'TestApplicant';
        app.Applicant_Email__c = 'john.test@cvma.com';
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