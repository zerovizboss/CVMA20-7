/**
 * Test class for CVMAMemberProfileController
 * Comprehensive test coverage for member profile management functionality
 */
@IsTest
public class CVMAMemberProfileControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Use CVMATestDataFactory for consistent test data creation
        CVMATestDataFactory.TestDataBundle testData = CVMATestDataFactory.setupBasicTestData();
    }
    
    @IsTest
    static void testGetMemberProfile_Success() {
        // Get test user created by CVMATestDataFactory
        List<User> testUsers = [SELECT Id, FirstName, LastName, Email, ContactId FROM User WHERE Email LIKE '%cvma-test.org' LIMIT 1];
        System.assert(!testUsers.isEmpty(), 'Test user should exist');
        User testUser = testUsers[0];
        
        Test.startTest();
        System.runAs(testUser) {
            CVMAMemberProfileController.MemberProfileData profileData = CVMAMemberProfileController.getMemberProfile();
            
            // Verify user data
            System.assertEquals(testUser.Id, profileData.userId, 'User ID should match');
            System.assertNotEquals(null, profileData.firstName, 'First name should not be null');
            System.assertNotEquals(null, profileData.lastName, 'Last name should not be null');
            System.assertNotEquals(null, profileData.email, 'Email should not be null');
            
            // Verify contact data
            System.assertEquals(testUser.ContactId, profileData.contactId, 'Contact ID should match');
            System.assertNotEquals(null, profileData.membershipId, 'Membership ID should not be null');
            System.assertNotEquals(null, profileData.contactEmail, 'Contact email should not be null');
            System.assertNotEquals(null, profileData.mailingCity, 'Mailing city should not be null');
            System.assertNotEquals(null, profileData.roadName, 'Road name should not be null');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateMemberProfile_Success() {
        // Get test user
        User testUser = [SELECT Id, ContactId FROM User WHERE Username = 'john.rider.test@cvma.com.test' LIMIT 1];
        
        // Create updated profile data
        CVMAMemberProfileController.MemberProfileData updatedData = new CVMAMemberProfileController.MemberProfileData();
        updatedData.userId = testUser.Id;
        updatedData.contactId = testUser.ContactId;
        updatedData.firstName = 'Jonathan';
        updatedData.lastName = 'Rider';
        updatedData.email = 'jonathan.rider@cvma.com';
        updatedData.phone = '555-111-2222';
        updatedData.mobilePhone = '555-333-4444';
        updatedData.contactPhone = '555-111-2222';
        updatedData.contactMobilePhone = '555-333-4444';
        updatedData.contactEmail = 'jonathan.rider@cvma.com';
        updatedData.mailingStreet = '456 Oak Ave';
        updatedData.mailingCity = 'Miami';
        updatedData.mailingState = 'FL';
        updatedData.mailingPostalCode = '33101';
        updatedData.mailingCountry = 'USA';
        
        String profileDataJson = JSON.serialize(updatedData);
        
        Test.startTest();
        System.runAs(testUser) {
            String result = CVMAMemberProfileController.updateMemberProfile(profileDataJson);
            System.assertEquals('Profile updated successfully', result, 'Update should be successful');
        }
        Test.stopTest();
        
        // Verify updates
        User updatedUser = [SELECT FirstName, LastName, Email, Phone, MobilePhone FROM User WHERE Id = :testUser.Id];
        System.assertEquals('Jonathan', updatedUser.FirstName, 'User first name should be updated');
        System.assertEquals('Rider', updatedUser.LastName, 'User last name should be updated');
        System.assertEquals('jonathan.rider@cvma.com', updatedUser.Email, 'User email should be updated');
        System.assertEquals('555-111-2222', updatedUser.Phone, 'User phone should be updated');
        System.assertEquals('555-333-4444', updatedUser.MobilePhone, 'User mobile phone should be updated');
        
        Contact updatedContact = [SELECT Phone, MobilePhone, Email, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry FROM Contact WHERE Id = :testUser.ContactId];
        System.assertEquals('555-111-2222', updatedContact.Phone, 'Contact phone should be updated');
        System.assertEquals('555-333-4444', updatedContact.MobilePhone, 'Contact mobile phone should be updated');
        System.assertEquals('jonathan.rider@cvma.com', updatedContact.Email, 'Contact email should be updated');
        System.assertEquals('456 Oak Ave', updatedContact.MailingStreet, 'Contact mailing street should be updated');
        System.assertEquals('Miami', updatedContact.MailingCity, 'Contact mailing city should be updated');
        System.assertEquals('FL', updatedContact.MailingState, 'Contact mailing state should be updated');
        System.assertEquals('33101', updatedContact.MailingPostalCode, 'Contact mailing postal code should be updated');
        System.assertEquals('USA', updatedContact.MailingCountry, 'Contact mailing country should be updated');
    }
    
    @IsTest
    static void testUpdateMemberProfile_ValidationError_RequiredFields() {
        // Get test user
        User testUser = [SELECT Id, ContactId FROM User WHERE Username = 'john.rider.test@cvma.com.test' LIMIT 1];
        
        // Create profile data with missing required fields
        CVMAMemberProfileController.MemberProfileData invalidData = new CVMAMemberProfileController.MemberProfileData();
        invalidData.userId = testUser.Id;
        invalidData.contactId = testUser.ContactId;
        invalidData.firstName = ''; // Missing required field
        invalidData.lastName = 'Rider';
        invalidData.email = 'jonathan.rider@cvma.com';
        
        String profileDataJson = JSON.serialize(invalidData);
        
        Test.startTest();
        System.runAs(testUser) {
            try {
                CVMAMemberProfileController.updateMemberProfile(profileDataJson);
                System.assert(false, 'Expected AuraHandledException for missing required fields');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('required fields'), 'Exception should mention required fields');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateMemberProfile_ValidationError_InvalidEmail() {
        // Get test user
        User testUser = [SELECT Id, ContactId FROM User WHERE Username = 'john.rider.test@cvma.com.test' LIMIT 1];
        
        // Create profile data with invalid email
        CVMAMemberProfileController.MemberProfileData invalidData = new CVMAMemberProfileController.MemberProfileData();
        invalidData.userId = testUser.Id;
        invalidData.contactId = testUser.ContactId;
        invalidData.firstName = 'Jonathan';
        invalidData.lastName = 'Rider';
        invalidData.email = 'invalid-email'; // Invalid email format
        
        String profileDataJson = JSON.serialize(invalidData);
        
        Test.startTest();
        System.runAs(testUser) {
            try {
                CVMAMemberProfileController.updateMemberProfile(profileDataJson);
                System.assert(false, 'Expected AuraHandledException for invalid email');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('valid email'), 'Exception should mention valid email');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateMemberProfile_SecurityError_WrongUser() {
        // Get test users
        User testUser = [SELECT Id, ContactId FROM User WHERE Username = 'john.rider.test@cvma.com.test' LIMIT 1];
        
        // Create another test user
        Contact anotherContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'jane.smith@cvma.com'
        );
        insert anotherContact;
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User anotherUser = new User(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'jane.smith@cvma.com',
            Username = 'jane.smith.test@cvma.com.test',
            Alias = 'jsmith',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = testProfile.Id,
            ContactId = anotherContact.Id
        );
        insert anotherUser;
        
        // Try to update another user's profile
        CVMAMemberProfileController.MemberProfileData profileData = new CVMAMemberProfileController.MemberProfileData();
        profileData.userId = testUser.Id; // Different user's ID
        profileData.firstName = 'Hacker';
        profileData.lastName = 'Attempt';
        profileData.email = 'hacker@test.com';
        
        String profileDataJson = JSON.serialize(profileData);
        
        Test.startTest();
        System.runAs(anotherUser) {
            try {
                CVMAMemberProfileController.updateMemberProfile(profileDataJson);
                System.assert(false, 'Expected AuraHandledException for unauthorized access');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('own profile'), 'Exception should mention own profile restriction');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetProfilePermissions() {
        // Get test user
        User testUser = [SELECT Id FROM User WHERE Username = 'john.rider.test@cvma.com.test' LIMIT 1];
        
        Test.startTest();
        System.runAs(testUser) {
            CVMAMemberProfileController.ProfilePermissions permissions = CVMAMemberProfileController.getProfilePermissions();
            
            // Verify permissions are returned (exact values depend on profile settings)
            System.assertNotEquals(null, permissions, 'Permissions should not be null');
            System.assertNotEquals(null, permissions.canEditProfile, 'canEditProfile should not be null');
            System.assertNotEquals(null, permissions.canEditContact, 'canEditContact should not be null');
            System.assertNotEquals(null, permissions.canViewMembershipInfo, 'canViewMembershipInfo should not be null');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testInvalidJsonHandling() {
        // Get test user
        User testUser = [SELECT Id FROM User WHERE Username = 'john.rider.test@cvma.com.test' LIMIT 1];
        
        String invalidJson = '{"invalid": "json", "structure"}'; // Invalid JSON structure
        
        Test.startTest();
        System.runAs(testUser) {
            try {
                CVMAMemberProfileController.updateMemberProfile(invalidJson);
                System.assert(false, 'Expected AuraHandledException for invalid JSON');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('profile data format') || e.getMessage().contains('error'), 'Exception should mention data format or error');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUserWithoutContact() {
        // Create user without contact
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User userWithoutContact = new User(
            FirstName = 'No',
            LastName = 'Contact',
            Email = 'nocontact@cvma.com',
            Username = 'nocontact.test@cvma.com.test',
            Alias = 'nocon',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = testProfile.Id
            // No ContactId assigned
        );
        insert userWithoutContact;
        
        Test.startTest();
        System.runAs(userWithoutContact) {
            CVMAMemberProfileController.MemberProfileData profileData = CVMAMemberProfileController.getMemberProfile();
            
            // Verify user data is still accessible
            System.assertEquals('No', profileData.firstName, 'First name should be accessible');
            System.assertEquals('Contact', profileData.lastName, 'Last name should be accessible');
            System.assertEquals('nocontact@cvma.com', profileData.email, 'Email should be accessible');
            
            // Verify contact fields are null/empty
            System.assertEquals(null, profileData.contactId, 'Contact ID should be null');
            System.assertEquals(null, profileData.membershipId, 'Membership ID should be null');
            System.assertEquals(null, profileData.roadName, 'Road name should be null');
        }
        Test.stopTest();
    }
}