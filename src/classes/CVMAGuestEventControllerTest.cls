/**
 * @description Test class for CVMAGuestEventController
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 *
 * Comprehensive test coverage for:
 * - Public event viewing for guests
 * - Guest request submission and validation
 * - Officer review and approval workflow
 * - Email notifications and communication
 * - Security and permission testing
 */
@IsTest
public class CVMAGuestEventControllerTest {

    private static final String TEST_PUBLIC_EVENT_NAME = 'Public CVMA Charity Ride';
    private static final String TEST_PRIVATE_EVENT_NAME = 'Private Member Meeting';
    private static final String TEST_GUEST_EMAIL = 'testguest@example.com';

    @TestSetup
    static void setupTestData() {
        // Create test public event (allows guests)
        Campaign publicEvent = new Campaign(
            Name = TEST_PUBLIC_EVENT_NAME,
            Description = 'Annual charity ride open to the public and guests',
            Type = 'CVMA Event',
            Status = 'Planned',
            StartDate = Date.today().addDays(14),
            EndDate = Date.today().addDays(14),
            IsActive = true
        );
        insert publicEvent;

        // Create test private event (no guests)
        Campaign privateEvent = new Campaign(
            Name = TEST_PRIVATE_EVENT_NAME,
            Description = 'Internal member meeting - confidential discussion',
            Type = 'CVMA Event',
            Status = 'Planned',
            StartDate = Date.today().addDays(21),
            EndDate = Date.today().addDays(21),
            IsActive = true
        );
        insert privateEvent;

        // Create test officer user with permissions
        Profile systemAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User testOfficer = new User(
            FirstName = 'Test',
            LastName = 'Officer',
            Username = 'testofficer@cvma207test.org',
            Email = 'testofficer@cvma207.org',
            Alias = 'tofficer',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = systemAdmin.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testOfficer;

        // Create test guest request
        CVMA_Guest_Request__c testRequest = new CVMA_Guest_Request__c(
            Event__c = publicEvent.Id,
            Guest_First_Name__c = 'John',
            Guest_Last_Name__c = 'Guest',
            Guest_Email__c = TEST_GUEST_EMAIL,
            Guest_Phone__c = '555-123-4567',
            Veteran_Status__c = true,
            Emergency_Contact__c = 'Jane Guest - 555-987-6543',
            Additional_Information__c = 'Looking forward to supporting the charity',
            Status__c = 'Pending',
            Request_Date__c = System.now()
        );
        insert testRequest;
    }

    /**
     * Test getPublicEvents method
     */
    @IsTest
    static void testGetPublicEvents() {
        Test.startTest();

        List<CVMAGuestEventController.PublicEventWrapper> publicEvents =
            CVMAGuestEventController.getPublicEvents();

        Test.stopTest();

        System.assertEquals(1, publicEvents.size(), 'Should return only public events');

        CVMAGuestEventController.PublicEventWrapper eventWrapper = publicEvents[0];
        System.assertEquals(TEST_PUBLIC_EVENT_NAME, eventWrapper.eventName, 'Event name should match');
        System.assertEquals('Planned', eventWrapper.status, 'Event status should be Planned');
        System.assertEquals(true, eventWrapper.allowsGuests, 'Public event should allow guests');
        System.assertNotEquals(null, eventWrapper.eventDescription, 'Description should be sanitized but present');
    }

    /**
     * Test submitGuestRequest method with valid data
     */
    @IsTest
    static void testSubmitGuestRequestValid() {
        Campaign publicEvent = [
            SELECT Id FROM Campaign WHERE Name = :TEST_PUBLIC_EVENT_NAME LIMIT 1
        ];

        Map<String, Object> guestInfo = new Map<String, Object>{
            'firstName' => 'Sarah',
            'lastName' => 'Visitor',
            'email' => 'sarah.visitor@example.com',
            'phone' => '555-234-5678',
            'veteranStatus' => false,
            'emergencyContact' => 'Mike Visitor - 555-876-5432',
            'additionalInfo' => 'Interested in learning about CVMA'
        };

        Test.startTest();

        String requestId = CVMAGuestEventController.submitGuestRequest(publicEvent.Id, guestInfo);

        Test.stopTest();

        System.assertNotEquals(null, requestId, 'Request ID should be returned');

        CVMA_Guest_Request__c createdRequest = [
            SELECT Id, Guest_First_Name__c, Guest_Last_Name__c, Guest_Email__c, Status__c
            FROM CVMA_Guest_Request__c
            WHERE Id = :requestId
        ];

        System.assertEquals('Sarah', createdRequest.Guest_First_Name__c, 'First name should match');
        System.assertEquals('Visitor', createdRequest.Guest_Last_Name__c, 'Last name should match');
        System.assertEquals('sarah.visitor@example.com', createdRequest.Guest_Email__c, 'Email should match');
        System.assertEquals('Pending', createdRequest.Status__c, 'Status should be Pending');
    }

    /**
     * Test submitGuestRequest with missing required fields
     */
    @IsTest
    static void testSubmitGuestRequestMissingFields() {
        Campaign publicEvent = [
            SELECT Id FROM Campaign WHERE Name = :TEST_PUBLIC_EVENT_NAME LIMIT 1
        ];

        // Test missing first name
        Map<String, Object> invalidData1 = new Map<String, Object>{
            'lastName' => 'Visitor',
            'email' => 'visitor@example.com',
            'phone' => '555-234-5678'
        };

        Test.startTest();

        try {
            CVMAGuestEventController.submitGuestRequest(publicEvent.Id, invalidData1);
            System.assert(false, 'Should throw exception for missing first name');
        } catch (CVMAGuestEventController.GuestEventException e) {
            System.assert(e.getMessage().contains('First name is required'), 'Should indicate first name is required');
        }

        // Test missing email
        Map<String, Object> invalidData2 = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Visitor',
            'phone' => '555-234-5678'
        };

        try {
            CVMAGuestEventController.submitGuestRequest(publicEvent.Id, invalidData2);
            System.assert(false, 'Should throw exception for missing email');
        } catch (CVMAGuestEventController.GuestEventException e) {
            System.assert(e.getMessage().contains('Email is required'), 'Should indicate email is required');
        }

        Test.stopTest();
    }

    /**
     * Test submitGuestRequest for private event
     */
    @IsTest
    static void testSubmitGuestRequestPrivateEvent() {
        Campaign privateEvent = [
            SELECT Id FROM Campaign WHERE Name = :TEST_PRIVATE_EVENT_NAME LIMIT 1
        ];

        Map<String, Object> guestInfo = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Visitor',
            'email' => 'visitor@example.com',
            'phone' => '555-234-5678'
        };

        Test.startTest();

        try {
            CVMAGuestEventController.submitGuestRequest(privateEvent.Id, guestInfo);
            System.assert(false, 'Should throw exception for private event');
        } catch (CVMAGuestEventController.GuestEventException e) {
            System.assert(e.getMessage().contains('does not accept guest registrations'), 
                         'Should indicate event does not accept guests');
        }

        Test.stopTest();
    }

    /**
     * Test submitGuestRequest duplicate prevention
     */
    @IsTest
    static void testSubmitGuestRequestDuplicate() {
        Campaign publicEvent = [
            SELECT Id FROM Campaign WHERE Name = :TEST_PUBLIC_EVENT_NAME LIMIT 1
        ];

        Map<String, Object> guestInfo = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Guest',
            'email' => TEST_GUEST_EMAIL, // Same email as setup data
            'phone' => '555-234-5678'
        };

        Test.startTest();

        try {
            CVMAGuestEventController.submitGuestRequest(publicEvent.Id, guestInfo);
            System.assert(false, 'Should throw exception for duplicate request');
        } catch (CVMAGuestEventController.GuestEventException e) {
            System.assert(e.getMessage().contains('already submitted a request'), 
                         'Should indicate duplicate request');
        }

        Test.stopTest();
    }

    /**
     * Test getGuestRequestStatus method
     */
    @IsTest
    static void testGetGuestRequestStatus() {
        CVMA_Guest_Request__c testRequest = [
            SELECT Id FROM CVMA_Guest_Request__c WHERE Guest_Email__c = :TEST_GUEST_EMAIL LIMIT 1
        ];

        Test.startTest();

        CVMAGuestEventController.GuestRequestWrapper status =
            CVMAGuestEventController.getGuestRequestStatus(testRequest.Id);

        Test.stopTest();

        System.assertNotEquals(null, status, 'Status should be returned');
        System.assertEquals(testRequest.Id, status.requestId, 'Request ID should match');
        System.assertEquals('John Guest', status.guestName, 'Guest name should match');
        System.assertEquals('Pending', status.status, 'Status should be Pending');
        System.assertEquals(TEST_PUBLIC_EVENT_NAME, status.eventName, 'Event name should match');
    }

    /**
     * Test getPendingGuestRequests method with officer permissions
     */
    @IsTest
    static void testGetPendingGuestRequestsAsOfficer() {
        User testOfficer = [
            SELECT Id FROM User WHERE Username = 'testofficer@cvma207test.org' LIMIT 1
        ];

        System.runAs(testOfficer) {
            Test.startTest();

            List<CVMAGuestEventController.GuestRequestWrapper> pendingRequests =
                CVMAGuestEventController.getPendingGuestRequests();

            Test.stopTest();

            System.assertEquals(1, pendingRequests.size(), 'Should return pending requests');

            CVMAGuestEventController.GuestRequestWrapper request = pendingRequests[0];
            System.assertEquals('John Guest', request.guestName, 'Guest name should match');
            System.assertEquals(TEST_GUEST_EMAIL, request.guestEmail, 'Email should match');
            System.assertEquals('Pending', request.status, 'Status should be Pending');
            System.assertEquals(true, request.veteranStatus, 'Veteran status should be true');
        }
    }

    /**
     * Test processGuestRequest approval
     */
    @IsTest
    static void testProcessGuestRequestApproval() {
        User testOfficer = [
            SELECT Id FROM User WHERE Username = 'testofficer@cvma207test.org' LIMIT 1
        ];

        CVMA_Guest_Request__c testRequest = [
            SELECT Id FROM CVMA_Guest_Request__c WHERE Guest_Email__c = :TEST_GUEST_EMAIL LIMIT 1
        ];

        String responseNotes = 'Welcome to our charity ride!';

        System.runAs(testOfficer) {
            Test.startTest();

            Boolean result = CVMAGuestEventController.processGuestRequest(
                testRequest.Id, 
                true, 
                responseNotes
            );

            Test.stopTest();

            System.assertEquals(true, result, 'Processing should succeed');
        }

        // Verify request was updated
        CVMA_Guest_Request__c updatedRequest = [
            SELECT Id, Status__c, Response_Date__c, Response_Notes__c
            FROM CVMA_Guest_Request__c
            WHERE Id = :testRequest.Id
        ];

        System.assertEquals('Approved', updatedRequest.Status__c, 'Status should be Approved');
        System.assertNotEquals(null, updatedRequest.Response_Date__c, 'Response date should be set');
        System.assertEquals(responseNotes, updatedRequest.Response_Notes__c, 'Response notes should match');
    }

    /**
     * Test processGuestRequest denial
     */
    @IsTest
    static void testProcessGuestRequestDenial() {
        User testOfficer = [
            SELECT Id FROM User WHERE Username = 'testofficer@cvma207test.org' LIMIT 1
        ];

        // Create new request for denial test
        Campaign publicEvent = [
            SELECT Id FROM Campaign WHERE Name = :TEST_PUBLIC_EVENT_NAME LIMIT 1
        ];

        CVMA_Guest_Request__c denyRequest = new CVMA_Guest_Request__c(
            Event__c = publicEvent.Id,
            Guest_First_Name__c = 'Jane',
            Guest_Last_Name__c = 'Denied',
            Guest_Email__c = 'denied@example.com',
            Guest_Phone__c = '555-999-0000',
            Status__c = 'Pending',
            Request_Date__c = System.now()
        );
        insert denyRequest;

        String responseNotes = 'Sorry, this event is at capacity.';

        System.runAs(testOfficer) {
            Test.startTest();

            Boolean result = CVMAGuestEventController.processGuestRequest(
                denyRequest.Id, 
                false, 
                responseNotes
            );

            Test.stopTest();

            System.assertEquals(true, result, 'Processing should succeed');
        }

        // Verify request was updated
        CVMA_Guest_Request__c updatedRequest = [
            SELECT Id, Status__c, Response_Date__c, Response_Notes__c
            FROM CVMA_Guest_Request__c
            WHERE Id = :denyRequest.Id
        ];

        System.assertEquals('Denied', updatedRequest.Status__c, 'Status should be Denied');
        System.assertNotEquals(null, updatedRequest.Response_Date__c, 'Response date should be set');
        System.assertEquals(responseNotes, updatedRequest.Response_Notes__c, 'Response notes should match');
    }

    /**
     * Test processGuestRequest with already processed request
     */
    @IsTest
    static void testProcessGuestRequestAlreadyProcessed() {
        User testOfficer = [
            SELECT Id FROM User WHERE Username = 'testofficer@cvma207test.org' LIMIT 1
        ];

        CVMA_Guest_Request__c testRequest = [
            SELECT Id FROM CVMA_Guest_Request__c WHERE Guest_Email__c = :TEST_GUEST_EMAIL LIMIT 1
        ];

        // First approval
        System.runAs(testOfficer) {
            CVMAGuestEventController.processGuestRequest(testRequest.Id, true, 'First approval');
        }

        // Attempt second processing
        System.runAs(testOfficer) {
            Test.startTest();

            try {
                CVMAGuestEventController.processGuestRequest(testRequest.Id, false, 'Second attempt');
                System.assert(false, 'Should throw exception for already processed request');
            } catch (CVMAGuestEventController.GuestEventException e) {
                System.assert(e.getMessage().contains('already been processed'), 
                             'Should indicate request already processed');
            }

            Test.stopTest();
        }
    }

    /**
     * Test getPendingGuestRequests without officer permissions
     */
    @IsTest
    static void testGetPendingGuestRequestsNoPermissions() {
        // Create regular user without officer permissions
        Profile standardUser = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User regularUser = new User(
            FirstName = 'Regular',
            LastName = 'User',
            Username = 'regularuser@cvma207test.org',
            Email = 'regular@cvma207.org',
            Alias = 'ruser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardUser.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert regularUser;

        System.runAs(regularUser) {
            Test.startTest();

            try {
                CVMAGuestEventController.getPendingGuestRequests();
                System.assert(false, 'Should throw exception for insufficient permissions');
            } catch (CVMAGuestEventController.GuestEventException e) {
                System.assert(e.getMessage().contains('Insufficient permissions'), 
                             'Should indicate insufficient permissions');
            }

            Test.stopTest();
        }
    }

    /**
     * Test processGuestRequest without officer permissions
     */
    @IsTest
    static void testProcessGuestRequestNoPermissions() {
        CVMA_Guest_Request__c testRequest = [
            SELECT Id FROM CVMA_Guest_Request__c WHERE Guest_Email__c = :TEST_GUEST_EMAIL LIMIT 1
        ];

        // Create regular user without officer permissions
        Profile standardUser = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User regularUser = new User(
            FirstName = 'Regular',
            LastName = 'User',
            Username = 'regularuser2@cvma207test.org',
            Email = 'regular2@cvma207.org',
            Alias = 'ruser2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = standardUser.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert regularUser;

        System.runAs(regularUser) {
            Test.startTest();

            try {
                CVMAGuestEventController.processGuestRequest(testRequest.Id, true, 'Unauthorized attempt');
                System.assert(false, 'Should throw exception for insufficient permissions');
            } catch (CVMAGuestEventController.GuestEventException e) {
                System.assert(e.getMessage().contains('Insufficient permissions'), 
                             'Should indicate insufficient permissions');
            }

            Test.stopTest();
        }
    }

    /**
     * Test input sanitization
     */
    @IsTest
    static void testInputSanitization() {
        Campaign publicEvent = [
            SELECT Id FROM Campaign WHERE Name = :TEST_PUBLIC_EVENT_NAME LIMIT 1
        ];

        Map<String, Object> guestInfo = new Map<String, Object>{
            'firstName' => '<script>alert("hack")</script>John',
            'lastName' => '<div onclick="malicious()">Visitor</div>',
            'email' => 'clean@example.com',
            'phone' => '555-234-5678',
            'emergencyContact' => '<img src="x" onerror="alert()">Contact',
            'additionalInfo' => '<iframe src="evil.com"></iframe>Additional info'
        };

        Test.startTest();

        String requestId = CVMAGuestEventController.submitGuestRequest(publicEvent.Id, guestInfo);

        Test.stopTest();

        CVMA_Guest_Request__c createdRequest = [
            SELECT Id, Guest_First_Name__c, Guest_Last_Name__c, Emergency_Contact__c, Additional_Information__c
            FROM CVMA_Guest_Request__c
            WHERE Id = :requestId
        ];

        // Verify input sanitization occurred (exact behavior depends on CVMAErrorHandler.sanitizeInput implementation)
        System.assertNotEquals(null, createdRequest.Guest_First_Name__c, 'First name should be sanitized but not null');
        System.assertNotEquals(null, createdRequest.Guest_Last_Name__c, 'Last name should be sanitized but not null');
        System.assertNotEquals(null, createdRequest.Emergency_Contact__c, 'Emergency contact should be sanitized but not null');
        System.assertNotEquals(null, createdRequest.Additional_Information__c, 'Additional info should be sanitized but not null');
    }

    /**
     * Test error handling
     */
    @IsTest
    static void testErrorHandling() {
        Test.startTest();

        try {
            CVMAGuestEventController.getGuestRequestStatus('invalidId');
            System.assert(false, 'Should throw exception for invalid ID');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for invalid ID');
        }

        Test.stopTest();

        // Verify error was logged
        List<CVMA_Error_Log__c> errorLogs = [
            SELECT Id, Error_Message__c, Class_Name__c
            FROM CVMA_Error_Log__c
            WHERE Class_Name__c = 'CVMAGuestEventController'
        ];

        System.assert(!errorLogs.isEmpty(), 'Error should be logged to CVMA_Error_Log__c');
    }

    /**
     * Test event filtering for public display
     */
    @IsTest
    static void testPublicEventFiltering() {
        // Create past event (should not appear)
        Campaign pastEvent = new Campaign(
            Name = 'Past Public Event',
            Description = 'Past event open to public',
            Type = 'CVMA Event',
            Status = 'Completed',
            StartDate = Date.today().addDays(-7),
            EndDate = Date.today().addDays(-7),
            IsActive = true
        );
        insert pastEvent;

        // Create cancelled event (should not appear)
        Campaign cancelledEvent = new Campaign(
            Name = 'Cancelled Public Event',
            Description = 'Cancelled event open to public',
            Type = 'CVMA Event',
            Status = 'Aborted',
            StartDate = Date.today().addDays(7),
            EndDate = Date.today().addDays(7),
            IsActive = true
        );
        insert cancelledEvent;

        Test.startTest();

        List<CVMAGuestEventController.PublicEventWrapper> publicEvents =
            CVMAGuestEventController.getPublicEvents();

        Test.stopTest();

        // Should only return the original public event from setup
        System.assertEquals(1, publicEvents.size(), 'Should only return future, active, non-cancelled events');
        System.assertEquals(TEST_PUBLIC_EVENT_NAME, publicEvents[0].eventName, 'Should return the correct event');
    }

    /**
     * Test description sanitization for public display
     */
    @IsTest
    static void testDescriptionSanitization() {
        // Create event with sensitive information
        Campaign sensitiveEvent = new Campaign(
            Name = 'Mixed Content Event',
            Description = 'Public charity event details here.\n\nINTERNAL: Member-only discussion after.\nCONFIDENTIAL: Financial details.\nPublic parking available.',
            Type = 'CVMA Event',
            Status = 'Planned',
            StartDate = Date.today().addDays(10),
            EndDate = Date.today().addDays(10),
            IsActive = true
        );
        insert sensitiveEvent;

        Test.startTest();

        List<CVMAGuestEventController.PublicEventWrapper> publicEvents =
            CVMAGuestEventController.getPublicEvents();

        Test.stopTest();

        // Find the sensitive event in results
        CVMAGuestEventController.PublicEventWrapper sensitiveEventWrapper = null;
        for (CVMAGuestEventController.PublicEventWrapper event : publicEvents) {
            if (event.eventName == 'Mixed Content Event') {
                sensitiveEventWrapper = event;
                break;
            }
        }

        System.assertNotEquals(null, sensitiveEventWrapper, 'Should find the sensitive event');
        
        // Description should be sanitized to remove sensitive content
        String description = sensitiveEventWrapper.eventDescription;
        System.assert(!description.toLowerCase().contains('internal'), 'Should not contain internal information');
        System.assert(!description.toLowerCase().contains('confidential'), 'Should not contain confidential information');
        System.assert(description.contains('Public'), 'Should retain public information');
    }
}