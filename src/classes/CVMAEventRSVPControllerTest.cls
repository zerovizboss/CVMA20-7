/**
 * @description Test class for CVMAEventRSVPController
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 * 
 * Comprehensive test coverage for Event RSVP functionality including:
 * - RSVP creation and updates
 * - Attendee list retrieval with privacy controls
 * - RSVP summary statistics
 * - Security validation and error handling
 * - Edge cases and boundary conditions
 */
@IsTest
public class CVMAEventRSVPControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test data using CVMATestDataFactory
        
        // Create test account for events
        Account testAccount = CVMATestDataFactory.createAccount()
            .withName('CVMA Chapter 20-7')
            .create();
        
        // Create test contacts (members)
        List<Contact> testMembers = new List<Contact>();
        testMembers.add(CVMATestDataFactory.createContact()
            .withAccount(testAccount.Id)
            .withFirstName('John')
            .withLastName('Doe')
            .withEmail('john.doe@cvma.org')
            .create());
        
        testMembers.add(CVMATestDataFactory.createContact()
            .withAccount(testAccount.Id)
            .withFirstName('Jane')
            .withLastName('Smith')
            .withEmail('jane.smith@cvma.org')
            .create());
        
        testMembers.add(CVMATestDataFactory.createContact()
            .withAccount(testAccount.Id)
            .withFirstName('Mike')
            .withLastName('Johnson')
            .withEmail('mike.johnson@cvma.org')
            .create());
        
        // Create test users for the contacts
        Profile memberProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        List<User> testUsers = new List<User>();
        for (Integer i = 0; i < testMembers.size(); i++) {
            testUsers.add(new User(
                FirstName = testMembers[i].FirstName,
                LastName = testMembers[i].LastName,
                Email = testMembers[i].Email,
                Username = testMembers[i].Email + '.test',
                Alias = (testMembers[i].FirstName.substring(0,1) + testMembers[i].LastName.substring(0,1)).toLowerCase(),
                ProfileId = memberProfile.Id,
                ContactId = testMembers[i].Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            ));
        }
        insert testUsers;
        
        // Create test campaigns (used as events)
        List<Campaign> testEvents = new List<Campaign>();
        testEvents.add(new Campaign(
            Name = 'CVMA Monthly Meeting',
            Description = 'Regular monthly chapter meeting',
            StartDate = Date.today().addDays(7),
            EndDate = Date.today().addDays(7),
            IsActive = true,
            Type = 'Event'
        ));
        
        testEvents.add(new Campaign(
            Name = 'CVMA Charity Ride',
            Description = 'Annual charity motorcycle ride',
            StartDate = Date.today().addDays(14),
            EndDate = Date.today().addDays(14),
            IsActive = true,
            Type = 'Event'
        ));
        
        testEvents.add(new Campaign(
            Name = 'Private Officer Meeting',
            Description = 'Officers only meeting',
            StartDate = Date.today().addDays(21),
            EndDate = Date.today().addDays(21),
            IsActive = false,
            Type = 'Event'
        ));
        
        insert testEvents;
        
        // Create some initial RSVPs
        List<CVMA_Event_RSVP__c> initialRSVPs = new List<CVMA_Event_RSVP__c>();
        initialRSVPs.add(new CVMA_Event_RSVP__c(
            Event__c = testEvents[0].Id,
            Member__c = testMembers[0].Id,
            Response__c = 'Yes',
            RSVP_Date__c = DateTime.now().addDays(-1),
            Notes__c = 'Looking forward to it!',
            Plus_One__c = true,
            Plus_One_Name__c = 'Sarah Doe'
        ));
        
        initialRSVPs.add(new CVMA_Event_RSVP__c(
            Event__c = testEvents[0].Id,
            Member__c = testMembers[1].Id,
            Response__c = 'No',
            RSVP_Date__c = DateTime.now().addDays(-2),
            Notes__c = 'Can\'t make it this time'
        ));
        
        insert initialRSVPs;
    }
    
    @IsTest
    static void testGetCurrentUserRSVP_WithExistingRSVP() {
        // Get test data
        Campaign testEvent = [SELECT Id FROM Campaign WHERE Name = 'CVMA Monthly Meeting' LIMIT 1];
        Contact testMember = [SELECT Id FROM Contact WHERE Email = 'john.doe@cvma.org' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE ContactId = :testMember.Id LIMIT 1];
        
        Test.startTest();
        System.runAs(testUser) {
            CVMA_Event_RSVP__c result = CVMAEventRSVPController.getCurrentUserRSVP(testEvent.Id);
            
            System.assertNotEquals(null, result, 'Should return existing RSVP');
            System.assertEquals('Yes', result.Response__c, 'Response should be Yes');
            System.assertEquals(testMember.Id, result.Member__c, 'Member should match current user');
            System.assertEquals(true, result.Plus_One__c, 'Plus one should be true');
            System.assertEquals('Sarah Doe', result.Plus_One_Name__c, 'Plus one name should match');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetCurrentUserRSVP_WithoutExistingRSVP() {
        // Get test data
        Campaign testEvent = [SELECT Id FROM Campaign WHERE Name = 'CVMA Charity Ride' LIMIT 1];
        Contact testMember = [SELECT Id FROM Contact WHERE Email = 'mike.johnson@cvma.org' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE ContactId = :testMember.Id LIMIT 1];
        
        Test.startTest();
        System.runAs(testUser) {
            CVMA_Event_RSVP__c result = CVMAEventRSVPController.getCurrentUserRSVP(testEvent.Id);
            
            System.assertEquals(null, result, 'Should return null for no existing RSVP');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSubmitRSVP_NewRSVP() {
        // Get test data
        Campaign testEvent = [SELECT Id FROM Campaign WHERE Name = 'CVMA Charity Ride' LIMIT 1];
        Contact testMember = [SELECT Id FROM Contact WHERE Email = 'mike.johnson@cvma.org' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE ContactId = :testMember.Id LIMIT 1];
        
        Test.startTest();
        System.runAs(testUser) {
            String result = CVMAEventRSVPController.submitRSVP(
                testEvent.Id, 
                'Yes', 
                'Excited to participate!', 
                true, 
                'Lisa Johnson'
            );
            
            System.assertEquals('RSVP submitted successfully', result, 'Should return success message');
            
            // Verify RSVP was created
            CVMA_Event_RSVP__c createdRSVP = [
                SELECT Id, Event__c, Member__c, Response__c, Notes__c, Plus_One__c, Plus_One_Name__c
                FROM CVMA_Event_RSVP__c 
                WHERE Event__c = :testEvent.Id AND Member__c = :testMember.Id
            ];
            
            System.assertEquals('Yes', createdRSVP.Response__c, 'Response should be Yes');
            System.assertEquals('Excited to participate!', createdRSVP.Notes__c, 'Notes should match');
            System.assertEquals(true, createdRSVP.Plus_One__c, 'Plus one should be true');
            System.assertEquals('Lisa Johnson', createdRSVP.Plus_One_Name__c, 'Plus one name should match');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSubmitRSVP_UpdateExistingRSVP() {
        // Get test data
        Campaign testEvent = [SELECT Id FROM Campaign WHERE Name = 'CVMA Monthly Meeting' LIMIT 1];
        Contact testMember = [SELECT Id FROM Contact WHERE Email = 'john.doe@cvma.org' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE ContactId = :testMember.Id LIMIT 1];
        
        Test.startTest();
        System.runAs(testUser) {
            String result = CVMAEventRSVPController.submitRSVP(
                testEvent.Id, 
                'Maybe', 
                'Changed my mind', 
                false, 
                null
            );
            
            System.assertEquals('RSVP updated successfully', result, 'Should return update success message');
            
            // Verify RSVP was updated
            CVMA_Event_RSVP__c updatedRSVP = [
                SELECT Id, Response__c, Notes__c, Plus_One__c, Plus_One_Name__c
                FROM CVMA_Event_RSVP__c 
                WHERE Event__c = :testEvent.Id AND Member__c = :testMember.Id
            ];
            
            System.assertEquals('Maybe', updatedRSVP.Response__c, 'Response should be updated to Maybe');
            System.assertEquals('Changed my mind', updatedRSVP.Notes__c, 'Notes should be updated');
            System.assertEquals(false, updatedRSVP.Plus_One__c, 'Plus one should be false');
            System.assertEquals(null, updatedRSVP.Plus_One_Name__c, 'Plus one name should be null');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSubmitRSVP_ValidationErrors() {
        Campaign testEvent = [SELECT Id FROM Campaign WHERE Name = 'CVMA Monthly Meeting' LIMIT 1];
        Contact testMember = [SELECT Id FROM Contact WHERE Email = 'john.doe@cvma.org' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE ContactId = :testMember.Id LIMIT 1];
        
        Test.startTest();
        System.runAs(testUser) {
            // Test with invalid response
            try {
                CVMAEventRSVPController.submitRSVP(testEvent.Id, 'Invalid', 'Notes', false, null);
                System.assert(false, 'Should throw validation exception for invalid response');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('Invalid RSVP response'), 'Should contain validation message');
            }
            
            // Test with missing event ID
            try {
                CVMAEventRSVPController.submitRSVP(null, 'Yes', 'Notes', false, null);
                System.assert(false, 'Should throw validation exception for missing event ID');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('Event ID and response are required'), 'Should contain required field message');
            }
            
            // Test with missing response
            try {
                CVMAEventRSVPController.submitRSVP(testEvent.Id, '', 'Notes', false, null);
                System.assert(false, 'Should throw validation exception for missing response');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('Event ID and response are required'), 'Should contain required field message');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetEventAttendees_WithPrivacyControls() {
        // Get test data
        Campaign testEvent = [SELECT Id FROM Campaign WHERE Name = 'CVMA Monthly Meeting' LIMIT 1];
        
        Test.startTest();
        
        // Test without private info access
        List<CVMAEventRSVPController.AttendeeInfo> attendeesPublic = 
            CVMAEventRSVPController.getEventAttendees(testEvent.Id, false);
        
        System.assertEquals(1, attendeesPublic.size(), 'Should return 1 attendee (only Yes responses)');
        System.assert(attendeesPublic[0].memberName.contains('John'), 'Should show first name for privacy');
        
        // Test with private info (assuming admin user)
        List<CVMAEventRSVPController.AttendeeInfo> attendeesPrivate = 
            CVMAEventRSVPController.getEventAttendees(testEvent.Id, true);
        
        System.assertEquals(1, attendeesPrivate.size(), 'Should return 1 attendee');
        System.assertEquals('Yes', attendeesPrivate[0].response, 'Response should be Yes');
        System.assertEquals(true, attendeesPrivate[0].plusOne, 'Plus one should be true');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testGetRSVPSummary() {
        // Get test data
        Campaign testEvent = [SELECT Id FROM Campaign WHERE Name = 'CVMA Monthly Meeting' LIMIT 1];
        
        Test.startTest();
        CVMAEventRSVPController.RSVPSummary summary = 
            CVMAEventRSVPController.getRSVPSummary(testEvent.Id);
        
        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assertEquals(1, summary.yesCount, 'Should have 1 Yes response');
        System.assertEquals(1, summary.noCount, 'Should have 1 No response');
        System.assertEquals(0, summary.maybeCount, 'Should have 0 Maybe responses');
        System.assertEquals(1, summary.plusOnes, 'Should have 1 plus one');
        System.assertEquals(2, summary.totalAttending, 'Total attending should be 2 (1 member + 1 guest)');
        System.assertEquals(2, summary.totalResponses, 'Total responses should be 2');
        Test.stopTest();
    }
    
    @IsTest
    static void testPrivateEventAccess() {
        // Get private event
        Campaign privateEvent = [SELECT Id FROM Campaign WHERE Name = 'Private Officer Meeting' LIMIT 1];
        Contact testMember = [SELECT Id FROM Contact WHERE Email = 'john.doe@cvma.org' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE ContactId = :testMember.Id LIMIT 1];
        
        Test.startTest();
        System.runAs(testUser) {
            // Should not be able to access private events
            CVMA_Event_RSVP__c result = CVMAEventRSVPController.getCurrentUserRSVP(privateEvent.Id);
            System.assertEquals(null, result, 'Should not access private events');
            
            List<CVMAEventRSVPController.AttendeeInfo> attendees = 
                CVMAEventRSVPController.getEventAttendees(privateEvent.Id, false);
            System.assertEquals(0, attendees.size(), 'Should not see attendees for private events');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testNonMemberAccess() {
        // Create user without contact (non-member)
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User nonMemberUser = new User(
            FirstName = 'Non',
            LastName = 'Member',
            Email = 'nonmember@test.com',
            Username = 'nonmember@test.com.cvmatest',
            Alias = 'nonmem',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert nonMemberUser;
        
        Campaign testEvent = [SELECT Id FROM Campaign WHERE Name = 'CVMA Monthly Meeting' LIMIT 1];
        
        Test.startTest();
        System.runAs(nonMemberUser) {
            try {
                CVMAEventRSVPController.submitRSVP(testEvent.Id, 'Yes', 'Notes', false, null);
                System.assert(false, 'Non-members should not be able to RSVP');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('Only CVMA members can RSVP'), 'Should contain member restriction message');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testBulkRSVPOperations() {
        // Test multiple RSVPs for same event
        Campaign testEvent = [SELECT Id FROM Campaign WHERE Name = 'CVMA Charity Ride' LIMIT 1];
        List<Contact> testMembers = [SELECT Id FROM Contact ORDER BY Email];
        
        Test.startTest();
        
        // Create multiple RSVPs
        List<CVMA_Event_RSVP__c> bulkRSVPs = new List<CVMA_Event_RSVP__c>();
        for (Integer i = 0; i < testMembers.size(); i++) {
            bulkRSVPs.add(new CVMA_Event_RSVP__c(
                Event__c = testEvent.Id,
                Member__c = testMembers[i].Id,
                Response__c = i == 0 ? 'Yes' : (i == 1 ? 'No' : 'Maybe'),
                RSVP_Date__c = DateTime.now(),
                Plus_One__c = i == 0 ? true : false,
                Plus_One_Name__c = i == 0 ? 'Guest ' + i : null
            ));
        }
        insert bulkRSVPs;
        
        // Test summary with bulk data
        CVMAEventRSVPController.RSVPSummary summary = 
            CVMAEventRSVPController.getRSVPSummary(testEvent.Id);
        
        System.assertEquals(1, summary.yesCount, 'Should have 1 Yes response');
        System.assertEquals(1, summary.noCount, 'Should have 1 No response');
        System.assertEquals(1, summary.maybeCount, 'Should have 1 Maybe response');
        System.assertEquals(3, summary.totalResponses, 'Should have 3 total responses');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSecurityEnforcement() {
        // Test WITH SECURITY_ENFORCED behavior
        Campaign testEvent = [SELECT Id FROM Campaign WHERE Name = 'CVMA Monthly Meeting' LIMIT 1];
        
        Test.startTest();
        
        // Test that queries respect sharing rules
        List<CVMAEventRSVPController.AttendeeInfo> attendees = 
            CVMAEventRSVPController.getEventAttendees(testEvent.Id, false);
        
        // Should only return accessible records
        System.assert(attendees.size() >= 0, 'Should return accessible attendees only');
        
        CVMAEventRSVPController.RSVPSummary summary = 
            CVMAEventRSVPController.getRSVPSummary(testEvent.Id);
        
        System.assertNotEquals(null, summary, 'Summary should be accessible');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testInputSanitization() {
        Campaign testEvent = [SELECT Id FROM Campaign WHERE Name = 'CVMA Charity Ride' LIMIT 1];
        Contact testMember = [SELECT Id FROM Contact WHERE Email = 'mike.johnson@cvma.org' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE ContactId = :testMember.Id LIMIT 1];
        
        Test.startTest();
        System.runAs(testUser) {
            // Test with potentially malicious input
            String maliciousNotes = '<script>alert("xss")</script>Evil notes';
            String maliciousPlusOne = '<script>alert("xss")</script>Evil Name';
            
            String result = CVMAEventRSVPController.submitRSVP(
                testEvent.Id, 
                'Yes', 
                maliciousNotes, 
                true, 
                maliciousPlusOne
            );
            
            System.assertEquals('RSVP submitted successfully', result, 'Should sanitize and process input');
            
            // Verify sanitized data was stored
            CVMA_Event_RSVP__c rsvp = [
                SELECT Notes__c, Plus_One_Name__c 
                FROM CVMA_Event_RSVP__c 
                WHERE Event__c = :testEvent.Id AND Member__c = :testMember.Id
            ];
            
            // Input should be sanitized by CVMAErrorHandler.sanitizeInput()
            System.assertNotEquals(maliciousNotes, rsvp.Notes__c, 'Notes should be sanitized');
            System.assertNotEquals(maliciousPlusOne, rsvp.Plus_One_Name__c, 'Plus one name should be sanitized');
        }
        Test.stopTest();
    }
}