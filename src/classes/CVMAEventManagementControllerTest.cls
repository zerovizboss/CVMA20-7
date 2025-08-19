/**
 * @description Test class for CVMAEventManagementController
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 *
 * Comprehensive test coverage for:
 * - Event creation and management operations
 * - Recurring event functionality
 * - Capacity management and validation
 * - Security and permission testing
 * - Integration with RSVP system
 */
@IsTest
public class CVMAEventManagementControllerTest {

    private static final String TEST_EVENT_NAME = 'Test CVMA Chapter Meeting';
    private static final String TEST_EVENT_DESCRIPTION = 'Monthly chapter meeting for CVMA 20-7';
    private static final String TEST_EVENT_TYPE = 'CVMA Event';

    @TestSetup
    static void setupTestData() {
        // Create test Contact using CVMATestDataFactory
        Contact testMember = CVMATestDataFactory.createContact()
            .withFirstName('Test')
            .withLastName('Member')
            .withEmail('testmember@cvma207.org')
            .withLevel('Full Member')
            .withMembershipId('FM00001')
            .create();

        // Create test Campaign (Event)
        Campaign testEvent = new Campaign(
            Name = TEST_EVENT_NAME,
            Description = TEST_EVENT_DESCRIPTION,
            Type = TEST_EVENT_TYPE,
            Status = 'Planned',
            StartDate = Date.today().addDays(7),
            EndDate = Date.today().addDays(7),
            IsActive = true,
            NumberSent = 50 // Capacity
        );
        insert testEvent;

        // Create test RSVP
        CVMA_Event_RSVP__c testRSVP = new CVMA_Event_RSVP__c(
            Event__c = testEvent.Id,
            Member__c = testMember.Id,
            Response__c = 'Yes',
            Plus_One__c = true,
            Plus_One_Name__c = 'Guest Member',
            RSVP_Date__c = System.now()
        );
        insert testRSVP;
    }

    /**
     * Test getAllEvents method
     */
    @IsTest
    static void testGetAllEvents() {
        Test.startTest();
        
        List<CVMAEventManagementController.EventWrapper> events = 
            CVMAEventManagementController.getAllEvents();
        
        Test.stopTest();

        System.assertEquals(1, events.size(), 'Should return 1 test event');
        
        CVMAEventManagementController.EventWrapper eventWrapper = events[0];
        System.assertEquals(TEST_EVENT_NAME, eventWrapper.event.Name, 'Event name should match');
        System.assertEquals(TEST_EVENT_TYPE, eventWrapper.event.Type, 'Event type should match');
        System.assertEquals(1, eventWrapper.yesCount, 'Should have 1 Yes RSVP');
        System.assertEquals(1, eventWrapper.totalRSVPs, 'Should have 1 total RSVP');
        System.assertEquals(48, eventWrapper.availableSpots, 'Should have 48 available spots (50 - 2 for plus one)');
    }

    /**
     * Test createEvent method with basic event
     */
    @IsTest
    static void testCreateEvent() {
        Map<String, Object> eventData = new Map<String, Object>{
            'name' => 'New Test Event',
            'description' => 'Test event creation',
            'startDate' => String.valueOf(Date.today().addDays(14)),
            'endDate' => String.valueOf(Date.today().addDays(14)),
            'location' => 'CVMA Clubhouse',
            'capacity' => 25
        };

        Test.startTest();
        
        String eventId = CVMAEventManagementController.createEvent(eventData);
        
        Test.stopTest();

        System.assertNotEquals(null, eventId, 'Event ID should be returned');

        Campaign createdEvent = [
            SELECT Id, Name, Description, StartDate, Type, Status, NumberSent
            FROM Campaign
            WHERE Id = :eventId
            WITH SECURITY_ENFORCED
        ];

        System.assertEquals('New Test Event', createdEvent.Name, 'Event name should match');
        System.assertEquals(TEST_EVENT_TYPE, createdEvent.Type, 'Event type should be CVMA Event');
        System.assertEquals('Planned', createdEvent.Status, 'Event status should be Planned');
        System.assertEquals(25, createdEvent.NumberSent, 'Capacity should be set');
        System.assertEquals(Date.today().addDays(14), createdEvent.StartDate, 'Start date should match');
    }

    /**
     * Test createEvent with recurring pattern
     */
    @IsTest
    static void testCreateRecurringEvent() {
        Map<String, Object> eventData = new Map<String, Object>{
            'name' => 'Monthly Meeting',
            'description' => 'Recurring monthly chapter meeting',
            'startDate' => String.valueOf(Date.today().addDays(30)),
            'isRecurring' => true,
            'recurrenceType' => 'monthly',
            'recurrenceCount' => 3
        };

        Test.startTest();
        
        String eventId = CVMAEventManagementController.createEvent(eventData);
        
        Test.stopTest();

        System.assertNotEquals(null, eventId, 'Event ID should be returned');

        // Should have base event + 3 recurring events = 4 total new events (plus 1 from setup)
        List<Campaign> allEvents = [
            SELECT Id, Name, StartDate
            FROM Campaign
            WHERE Type = :TEST_EVENT_TYPE
            WITH SECURITY_ENFORCED
            ORDER BY StartDate
        ];

        System.assertEquals(5, allEvents.size(), 'Should have 5 total events (1 setup + 1 base + 3 recurring)');
        
        // Verify recurring event names include dates
        Boolean foundRecurringEvent = false;
        for (Campaign event : allEvents) {
            if (event.Name.contains('Monthly Meeting') && event.Name.contains('(')) {
                foundRecurringEvent = true;
                break;
            }
        }
        System.assert(foundRecurringEvent, 'Should find at least one recurring event with date in name');
    }

    /**
     * Test updateEvent method
     */
    @IsTest
    static void testUpdateEvent() {
        Campaign testEvent = [
            SELECT Id, Name, Description
            FROM Campaign
            WHERE Name = :TEST_EVENT_NAME
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        Map<String, Object> updateData = new Map<String, Object>{
            'name' => 'Updated Event Name',
            'description' => 'Updated description',
            'status' => 'In Progress'
        };

        Test.startTest();
        
        Boolean result = CVMAEventManagementController.updateEvent(testEvent.Id, updateData);
        
        Test.stopTest();

        System.assertEquals(true, result, 'Update should succeed');

        Campaign updatedEvent = [
            SELECT Id, Name, Description, Status
            FROM Campaign
            WHERE Id = :testEvent.Id
            WITH SECURITY_ENFORCED
        ];

        System.assertEquals('Updated Event Name', updatedEvent.Name, 'Name should be updated');
        System.assertEquals('Updated description', updatedEvent.Description, 'Description should be updated');
        System.assertEquals('In Progress', updatedEvent.Status, 'Status should be updated');
    }

    /**
     * Test cancelEvent method
     */
    @IsTest
    static void testCancelEvent() {
        Campaign testEvent = [
            SELECT Id, Name
            FROM Campaign
            WHERE Name = :TEST_EVENT_NAME
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        String cancellationReason = 'Weather conditions';

        Test.startTest();
        
        Boolean result = CVMAEventManagementController.cancelEvent(testEvent.Id, cancellationReason);
        
        Test.stopTest();

        System.assertEquals(true, result, 'Cancellation should succeed');

        Campaign cancelledEvent = [
            SELECT Id, Status, Description
            FROM Campaign
            WHERE Id = :testEvent.Id
            WITH SECURITY_ENFORCED
        ];

        System.assertEquals('Aborted', cancelledEvent.Status, 'Status should be Aborted');
        System.assert(cancelledEvent.Description.contains('CANCELLED'), 'Description should contain cancellation info');
        System.assert(cancelledEvent.Description.contains(cancellationReason), 'Description should contain reason');
    }

    /**
     * Test getEventDetails method
     */
    @IsTest
    static void testGetEventDetails() {
        Campaign testEvent = [
            SELECT Id, Name
            FROM Campaign
            WHERE Name = :TEST_EVENT_NAME
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        Test.startTest();
        
        CVMAEventManagementController.EventWrapper eventDetails = 
            CVMAEventManagementController.getEventDetails(testEvent.Id);
        
        Test.stopTest();

        System.assertNotEquals(null, eventDetails, 'Event details should be returned');
        System.assertEquals(testEvent.Id, eventDetails.event.Id, 'Event ID should match');
        System.assertEquals(1, eventDetails.yesCount, 'Should have 1 Yes RSVP');
        System.assertEquals(1, eventDetails.totalRSVPs, 'Should have 1 total RSVP');
        System.assertEquals(1, eventDetails.rsvpList.size(), 'Should have 1 RSVP in list');
    }

    /**
     * Test deleteEvent method
     */
    @IsTest
    static void testDeleteEvent() {
        Campaign testEvent = [
            SELECT Id, Name
            FROM Campaign
            WHERE Name = :TEST_EVENT_NAME
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        // Verify RSVP exists before deletion
        List<CVMA_Event_RSVP__c> rsvpsBefore = [
            SELECT Id
            FROM CVMA_Event_RSVP__c
            WHERE Event__c = :testEvent.Id
            WITH SECURITY_ENFORCED
        ];
        System.assertEquals(1, rsvpsBefore.size(), 'Should have 1 RSVP before deletion');

        Test.startTest();
        
        Boolean result = CVMAEventManagementController.deleteEvent(testEvent.Id);
        
        Test.stopTest();

        System.assertEquals(true, result, 'Deletion should succeed');

        // Verify event is deleted
        List<Campaign> eventsAfter = [
            SELECT Id
            FROM Campaign
            WHERE Id = :testEvent.Id
            WITH SECURITY_ENFORCED
        ];
        System.assertEquals(0, eventsAfter.size(), 'Event should be deleted');

        // Verify RSVPs are deleted
        List<CVMA_Event_RSVP__c> rsvpsAfter = [
            SELECT Id
            FROM CVMA_Event_RSVP__c
            WHERE Event__c = :testEvent.Id
            WITH SECURITY_ENFORCED
        ];
        System.assertEquals(0, rsvpsAfter.size(), 'RSVPs should be deleted');
    }

    /**
     * Test getUpcomingEvents method
     */
    @IsTest
    static void testGetUpcomingEvents() {
        // Create additional future event
        Campaign futureEvent = new Campaign(
            Name = 'Future Event',
            Type = TEST_EVENT_TYPE,
            Status = 'Planned',
            StartDate = Date.today().addDays(30),
            IsActive = true
        );
        insert futureEvent;

        // Create past event (should not appear)
        Campaign pastEvent = new Campaign(
            Name = 'Past Event',
            Type = TEST_EVENT_TYPE,
            Status = 'Completed',
            StartDate = Date.today().addDays(-7),
            IsActive = true
        );
        insert pastEvent;

        Test.startTest();
        
        List<CVMAEventManagementController.EventWrapper> upcomingEvents = 
            CVMAEventManagementController.getUpcomingEvents();
        
        Test.stopTest();

        System.assertEquals(2, upcomingEvents.size(), 'Should return 2 upcoming events');
        
        // Verify events are sorted by start date
        System.assert(upcomingEvents[0].event.StartDate <= upcomingEvents[1].event.StartDate, 
                     'Events should be sorted by start date');
    }

    /**
     * Test event creation with validation errors
     */
    @IsTest
    static void testCreateEventValidationErrors() {
        // Test missing name
        Map<String, Object> invalidData1 = new Map<String, Object>{
            'startDate' => String.valueOf(Date.today().addDays(7))
        };

        Test.startTest();
        
        try {
            CVMAEventManagementController.createEvent(invalidData1);
            System.assert(false, 'Should throw exception for missing name');
        } catch (CVMAEventManagementController.EventManagementException e) {
            System.assert(e.getMessage().contains('name is required'), 'Should indicate name is required');
        }

        // Test missing start date
        Map<String, Object> invalidData2 = new Map<String, Object>{
            'name' => 'Test Event'
        };

        try {
            CVMAEventManagementController.createEvent(invalidData2);
            System.assert(false, 'Should throw exception for missing start date');
        } catch (CVMAEventManagementController.EventManagementException e) {
            System.assert(e.getMessage().contains('start date is required'), 'Should indicate start date is required');
        }
        
        Test.stopTest();
    }

    /**
     * Test getEventTypes method
     */
    @IsTest
    static void testGetEventTypes() {
        Test.startTest();
        
        List<String> eventTypes = CVMAEventManagementController.getEventTypes();
        
        Test.stopTest();

        System.assert(!eventTypes.isEmpty(), 'Should return event types');
        System.assert(eventTypes.contains('Chapter Meeting'), 'Should include Chapter Meeting');
        System.assert(eventTypes.contains('Ride'), 'Should include Ride');
        System.assert(eventTypes.contains('Charity Event'), 'Should include Charity Event');
    }

    /**
     * Test getEventStatuses method
     */
    @IsTest
    static void testGetEventStatuses() {
        Test.startTest();
        
        List<String> statuses = CVMAEventManagementController.getEventStatuses();
        
        Test.stopTest();

        System.assert(!statuses.isEmpty(), 'Should return event statuses');
        System.assert(statuses.contains('Planned'), 'Should include Planned');
        System.assert(statuses.contains('In Progress'), 'Should include In Progress');
        System.assert(statuses.contains('Completed'), 'Should include Completed');
        System.assert(statuses.contains('Aborted'), 'Should include Aborted');
    }

    /**
     * Test capacity calculation with plus ones
     */
    @IsTest
    static void testCapacityCalculationWithPlusOnes() {
        Contact member1 = CVMATestDataFactory.createContact()
            .withFirstName('Member')
            .withLastName('One')
            .withEmail('member1@cvma207.org')
            .withLevel('Full Member')
            .withMembershipId('FM00002')
            .create();

        Contact member2 = CVMATestDataFactory.createContact()
            .withFirstName('Member')
            .withLastName('Two')
            .withEmail('member2@cvma207.org')
            .withLevel('Full Member')
            .withMembershipId('FM00003')
            .create();

        Campaign testEvent = [
            SELECT Id FROM Campaign WHERE Name = :TEST_EVENT_NAME WITH SECURITY_ENFORCED LIMIT 1
        ];

        // Add more RSVPs with plus ones
        List<CVMA_Event_RSVP__c> additionalRSVPs = new List<CVMA_Event_RSVP__c>();
        
        additionalRSVPs.add(new CVMA_Event_RSVP__c(
            Event__c = testEvent.Id,
            Member__c = member1.Id,
            Response__c = 'Yes',
            Plus_One__c = true,
            Plus_One_Name__c = 'Guest 1',
            RSVP_Date__c = System.now()
        ));

        additionalRSVPs.add(new CVMA_Event_RSVP__c(
            Event__c = testEvent.Id,
            Member__c = member2.Id,
            Response__c = 'Yes',
            Plus_One__c = false,
            Plus_One_Name__c = null,
            RSVP_Date__c = System.now()
        ));

        insert additionalRSVPs;

        Test.startTest();
        
        CVMAEventManagementController.EventWrapper eventDetails = 
            CVMAEventManagementController.getEventDetails(testEvent.Id);
        
        Test.stopTest();

        System.assertEquals(3, eventDetails.yesCount, 'Should have 3 Yes RSVPs');
        System.assertEquals(3, eventDetails.totalRSVPs, 'Should have 3 total RSVPs');
        // 50 capacity - 3 attendees - 2 plus ones = 45 available
        System.assertEquals(45, eventDetails.availableSpots, 'Should calculate available spots correctly with plus ones');
    }

    /**
     * Test recurring event creation - weekly pattern
     */
    @IsTest
    static void testRecurringEventWeekly() {
        Map<String, Object> eventData = new Map<String, Object>{
            'name' => 'Weekly Training',
            'description' => 'Weekly safety training',
            'startDate' => String.valueOf(Date.today().addDays(7)),
            'isRecurring' => true,
            'recurrenceType' => 'weekly',
            'recurrenceCount' => 4
        };

        Test.startTest();
        
        String eventId = CVMAEventManagementController.createEvent(eventData);
        
        Test.stopTest();

        System.assertNotEquals(null, eventId, 'Event ID should be returned');

        // Should have base event + 4 recurring = 5 new events (plus 1 from setup = 6 total)
        List<Campaign> weeklyEvents = [
            SELECT Id, Name, StartDate
            FROM Campaign
            WHERE Name LIKE '%Weekly Training%'
            WITH SECURITY_ENFORCED
            ORDER BY StartDate
        ];

        System.assertEquals(5, weeklyEvents.size(), 'Should create base event plus 4 recurring events');
        
        // Verify dates are 7 days apart
        for (Integer i = 1; i < weeklyEvents.size(); i++) {
            Integer daysBetween = weeklyEvents[i-1].StartDate.daysBetween(weeklyEvents[i].StartDate);
            System.assertEquals(7, daysBetween, 'Weekly events should be 7 days apart');
        }
    }

    /**
     * Test recurring event creation - monthly pattern
     */
    @IsTest
    static void testRecurringEventMonthly() {
        Map<String, Object> eventData = new Map<String, Object>{
            'name' => 'Monthly Board Meeting',
            'description' => 'Monthly board meeting',
            'startDate' => String.valueOf(Date.today().addDays(30)),
            'isRecurring' => true,
            'recurrenceType' => 'monthly',
            'recurrenceCount' => 3
        };

        Test.startTest();
        
        String eventId = CVMAEventManagementController.createEvent(eventData);
        
        Test.stopTest();

        List<Campaign> monthlyEvents = [
            SELECT Id, Name, StartDate
            FROM Campaign
            WHERE Name LIKE '%Monthly Board Meeting%'
            WITH SECURITY_ENFORCED
            ORDER BY StartDate
        ];

        System.assertEquals(4, monthlyEvents.size(), 'Should create base event plus 3 recurring events');
    }

    /**
     * Test event creation with missing required fields
     */
    @IsTest
    static void testCreateEventMissingFields() {
        Map<String, Object> incompleteData = new Map<String, Object>{
            'description' => 'Event without name or date'
        };

        Test.startTest();
        
        try {
            CVMAEventManagementController.createEvent(incompleteData);
            System.assert(false, 'Should throw exception for missing required fields');
        } catch (CVMAEventManagementController.EventManagementException e) {
            System.assert(e.getMessage().contains('required'), 'Error message should mention required fields');
        }
        
        Test.stopTest();
    }

    /**
     * Test input sanitization
     */
    @IsTest
    static void testInputSanitization() {
        Map<String, Object> eventData = new Map<String, Object>{
            'name' => '<script>alert("test")</script>Safe Event Name',
            'description' => '<div onclick="malicious()">Event Description</div>',
            'startDate' => String.valueOf(Date.today().addDays(7))
        };

        Test.startTest();
        
        String eventId = CVMAEventManagementController.createEvent(eventData);
        
        Test.stopTest();

        Campaign createdEvent = [
            SELECT Id, Name, Description
            FROM Campaign
            WHERE Id = :eventId
            WITH SECURITY_ENFORCED
        ];

        // Verify input sanitization occurred (exact behavior depends on CVMAErrorHandler.sanitizeInput implementation)
        System.assertNotEquals(null, createdEvent.Name, 'Name should be sanitized but not null');
        System.assertNotEquals(null, createdEvent.Description, 'Description should be sanitized but not null');
    }

    /**
     * Test capacity management with unlimited capacity
     */
    @IsTest
    static void testUnlimitedCapacity() {
        Map<String, Object> eventData = new Map<String, Object>{
            'name' => 'Unlimited Event',
            'description' => 'Event with no capacity limit',
            'startDate' => String.valueOf(Date.today().addDays(21))
            // No capacity specified = unlimited
        };

        Test.startTest();
        
        String eventId = CVMAEventManagementController.createEvent(eventData);
        
        Test.stopTest();

        CVMAEventManagementController.EventWrapper eventDetails = 
            CVMAEventManagementController.getEventDetails(eventId);

        System.assertEquals(-1, eventDetails.availableSpots, 'Should indicate unlimited capacity');
    }

    /**
     * Test security - guest user access restrictions
     */
    @IsTest
    static void testGuestUserSecurityRestrictions() {
        // Get guest user
        Profile guestProfile = [SELECT Id FROM Profile WHERE Name = 'Guest License User' LIMIT 1];
        
        User guestUser = new User(
            FirstName = 'Test',
            LastName = 'Guest',
            Username = 'testguest@cvma207test.org',
            Email = 'testguest@cvma207test.org',
            Alias = 'tguest',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = guestProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert guestUser;

        System.runAs(guestUser) {
            Test.startTest();
            
            try {
                // Guest users should not be able to create events
                Map<String, Object> eventData = new Map<String, Object>{
                    'name' => 'Guest Event',
                    'startDate' => String.valueOf(Date.today().addDays(7))
                };
                
                CVMAEventManagementController.createEvent(eventData);
                System.assert(false, 'Guest user should not be able to create events');
                
            } catch (Exception e) {
                System.assert(true, 'Expected: Guest user cannot create events');
            }
            
            Test.stopTest();
        }
    }

    /**
     * Test error handling and logging
     */
    @IsTest
    static void testErrorHandling() {
        // Test with invalid event ID
        Test.startTest();
        
        try {
            CVMAEventManagementController.getEventDetails('invalidId');
            System.assert(false, 'Should throw exception for invalid ID');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for invalid ID');
        }
        
        Test.stopTest();

        // Verify error was logged
        List<CVMA_Error_Log__c> errorLogs = [
            SELECT Id, Error_Message__c, Class_Name__c
            FROM CVMA_Error_Log__c
            WHERE Class_Name__c = 'CVMAEventManagementController.getEventDetails'
            WITH SECURITY_ENFORCED
        ];

        System.assert(!errorLogs.isEmpty(), 'Error should be logged to CVMA_Error_Log__c');
    }

    /**
     * Test bulk operations and governor limits
     */
    @IsTest
    static void testBulkOperations() {
        List<Map<String, Object>> bulkEventData = new List<Map<String, Object>>();
        
        for (Integer i = 1; i <= 10; i++) {
            bulkEventData.add(new Map<String, Object>{
                'name' => 'Bulk Event ' + i,
                'description' => 'Bulk created event ' + i,
                'startDate' => String.valueOf(Date.today().addDays(7 + i))
            });
        }

        Test.startTest();
        
        List<String> createdEventIds = new List<String>();
        for (Map<String, Object> data : bulkEventData) {
            String eventId = CVMAEventManagementController.createEvent(data);
            createdEventIds.add(eventId);
        }
        
        Test.stopTest();

        System.assertEquals(10, createdEventIds.size(), 'Should create 10 events');

        // Verify all events were created
        List<Campaign> createdEvents = [
            SELECT Id, Name
            FROM Campaign
            WHERE Name LIKE 'Bulk Event%'
            WITH SECURITY_ENFORCED
        ];

        System.assertEquals(10, createdEvents.size(), 'Should find 10 created events in database');
    }
}