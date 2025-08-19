/**
 * @description Test class for CVMAEventControllerLDS
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 *
 * Tests the streamlined controller that uses CampaignMember for RSVPs
 * and focuses on server-side logic only
 */
@IsTest
public class CVMAEventControllerLDSTest {

    private static final String TEST_EVENT_NAME = 'Test CVMA Chapter Meeting';
    private static final String TEST_EVENT_DESCRIPTION = 'Monthly chapter meeting for CVMA 20-7';

    @TestSetup
    static void setupTestData() {
        // Create test Contacts using CVMATestDataFactory
        Contact testMember1 = CVMATestDataFactory.createContact()
            .withFirstName('Test')
            .withLastName('Member1')
            .withEmail('testmember1@cvma207.org')
            .withLevel('Full Member')
            .withMembershipId('FM00001')
            .create();

        Contact testMember2 = CVMATestDataFactory.createContact()
            .withFirstName('Test')
            .withLastName('Member2')
            .withEmail('testmember2@cvma207.org')
            .withLevel('Full Member')
            .withMembershipId('FM00002')
            .create();

        // Create test Campaign (Event)
        Campaign testEvent = new Campaign(
            Name = TEST_EVENT_NAME,
            Description = TEST_EVENT_DESCRIPTION,
            Type = 'CVMA Event',
            Status = 'Planned',
            StartDate = Date.today().addDays(7),
            EndDate = Date.today().addDays(7),
            IsActive = true,
            NumberSent = 50 // Capacity
        );
        insert testEvent;

        // Create CampaignMembers (RSVPs)
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        
        campaignMembers.add(new CampaignMember(
            CampaignId = testEvent.Id,
            ContactId = testMember1.Id,
            Status = 'Responded'
        ));
        
        campaignMembers.add(new CampaignMember(
            CampaignId = testEvent.Id,
            ContactId = testMember2.Id,
            Status = 'Sent'
        ));

        insert campaignMembers;
    }

    /**
     * Test createRecurringEvents method
     */
    @IsTest
    static void testCreateRecurringEvents() {
        Campaign testEvent = [
            SELECT Id, Name, StartDate
            FROM Campaign
            WHERE Name = :TEST_EVENT_NAME
            LIMIT 1
        ];

        Test.startTest();
        
        List<Id> recurringEventIds = CVMAEventControllerLDS.createRecurringEvents(
            testEvent.Id, 
            'weekly', 
            3, 
            null
        );
        
        Test.stopTest();

        System.assertEquals(3, recurringEventIds.size(), 'Should create 3 recurring events');

        // Verify recurring events were created
        List<Campaign> allEvents = [
            SELECT Id, Name, StartDate
            FROM Campaign
            WHERE Type = 'CVMA Event'
            ORDER BY StartDate
        ];

        System.assertEquals(4, allEvents.size(), 'Should have 4 total events (1 original + 3 recurring)');
        
        // Verify dates are 7 days apart
        for (Integer i = 1; i < allEvents.size(); i++) {
            Integer daysBetween = allEvents[i-1].StartDate.daysBetween(allEvents[i].StartDate);
            System.assertEquals(7, daysBetween, 'Weekly events should be 7 days apart');
        }
    }

    /**
     * Test createRecurringEvents with monthly pattern
     */
    @IsTest
    static void testCreateRecurringEventsMonthly() {
        Campaign testEvent = [
            SELECT Id, Name, StartDate
            FROM Campaign
            WHERE Name = :TEST_EVENT_NAME
            LIMIT 1
        ];

        Test.startTest();
        
        List<Id> recurringEventIds = CVMAEventControllerLDS.createRecurringEvents(
            testEvent.Id, 
            'monthly', 
            2, 
            null
        );
        
        Test.stopTest();

        System.assertEquals(2, recurringEventIds.size(), 'Should create 2 recurring events');

        // Verify recurring events were created
        List<Campaign> monthlyEvents = [
            SELECT Id, Name, StartDate
            FROM Campaign
            WHERE Name LIKE '%Test CVMA Chapter Meeting%'
            ORDER BY StartDate
        ];

        System.assertEquals(3, monthlyEvents.size(), 'Should have 3 total events');
    }

    /**
     * Test getEventStats method
     */
    @IsTest
    static void testGetEventStats() {
        Campaign testEvent = [
            SELECT Id
            FROM Campaign
            WHERE Name = :TEST_EVENT_NAME
            LIMIT 1
        ];

        Test.startTest();
        
        CVMAEventControllerLDS.EventStats stats = CVMAEventControllerLDS.getEventStats(testEvent.Id);
        
        Test.stopTest();

        System.assertNotEquals(null, stats, 'Stats should be returned');
        System.assertEquals(testEvent.Id, stats.eventId, 'Event ID should match');
        System.assertEquals(TEST_EVENT_NAME, stats.eventName, 'Event name should match');
        System.assertEquals(50, stats.capacity, 'Capacity should be 50');
        System.assertEquals(2, stats.totalMembers, 'Should have 2 total members');
        System.assertEquals(1, stats.respondedCount, 'Should have 1 responded member');
        System.assertEquals(1, stats.sentCount, 'Should have 1 sent member');
        System.assertEquals(49, stats.availableSpots, 'Should have 49 available spots');
    }

    /**
     * Test getUpcomingEventsSummary method
     */
    @IsTest
    static void testGetUpcomingEventsSummary() {
        // Create additional future event
        Campaign futureEvent = new Campaign(
            Name = 'Future Event',
            Type = 'CVMA Event',
            Status = 'Planned',
            StartDate = Date.today().addDays(30),
            IsActive = true
        );
        insert futureEvent;

        // Create past event (should not appear)
        Campaign pastEvent = new Campaign(
            Name = 'Past Event',
            Type = 'CVMA Event',
            Status = 'Completed',
            StartDate = Date.today().addDays(-7),
            IsActive = true
        );
        insert pastEvent;

        Test.startTest();
        
        List<CVMAEventControllerLDS.EventSummary> summaries = 
            CVMAEventControllerLDS.getUpcomingEventsSummary(10);
        
        Test.stopTest();

        System.assertEquals(2, summaries.size(), 'Should return 2 upcoming events');
        
        // Verify events are sorted by start date
        System.assert(summaries[0].startDate <= summaries[1].startDate, 
                     'Events should be sorted by start date');
    }

    /**
     * Test addMemberToEvent method
     */
    @IsTest
    static void testAddMemberToEvent() {
        Campaign testEvent = [
            SELECT Id
            FROM Campaign
            WHERE Name = :TEST_EVENT_NAME
            LIMIT 1
        ];

        Contact newMember = CVMATestDataFactory.createContact()
            .withFirstName('New')
            .withLastName('Member')
            .withEmail('newmember@cvma207.org')
            .withLevel('Full Member')
            .withMembershipId('FM00003')
            .create();

        Test.startTest();
        
        Id campaignMemberId = CVMAEventControllerLDS.addMemberToEvent(
            testEvent.Id, 
            newMember.Id, 
            'Responded'
        );
        
        Test.stopTest();

        System.assertNotEquals(null, campaignMemberId, 'CampaignMember ID should be returned');

        CampaignMember createdMember = [
            SELECT Id, CampaignId, ContactId, Status
            FROM CampaignMember
            WHERE Id = :campaignMemberId
        ];

        System.assertEquals(testEvent.Id, createdMember.CampaignId, 'Campaign ID should match');
        System.assertEquals(newMember.Id, createdMember.ContactId, 'Contact ID should match');
        System.assertEquals('Responded', createdMember.Status, 'Status should be Responded');
    }

    /**
     * Test addMemberToEvent with duplicate member
     */
    @IsTest
    static void testAddMemberToEventDuplicate() {
        Campaign testEvent = [
            SELECT Id
            FROM Campaign
            WHERE Name = :TEST_EVENT_NAME
            LIMIT 1
        ];

        Contact existingMember = [
            SELECT Id
            FROM Contact
            WHERE Email = 'testmember1@cvma207.org'
            LIMIT 1
        ];

        Test.startTest();
        
        try {
            CVMAEventControllerLDS.addMemberToEvent(
                testEvent.Id, 
                existingMember.Id, 
                'Responded'
            );
            System.assert(false, 'Should throw exception for duplicate member');
        } catch (CVMAEventControllerLDS.EventException e) {
            System.assert(e.getMessage().contains('already added'), 'Should indicate member already exists');
        }
        
        Test.stopTest();
    }

    /**
     * Test getEventTypes method
     */
    @IsTest
    static void testGetEventTypes() {
        Test.startTest();
        
        List<String> eventTypes = CVMAEventControllerLDS.getEventTypes();
        
        Test.stopTest();

        System.assert(!eventTypes.isEmpty(), 'Should return event types');
        System.assert(eventTypes.contains('Chapter Meeting'), 'Should include Chapter Meeting');
        System.assert(eventTypes.contains('Ride'), 'Should include Ride');
        System.assert(eventTypes.contains('Charity Event'), 'Should include Charity Event');
    }

    /**
     * Test createRecurringEvents with invalid parameters
     */
    @IsTest
    static void testCreateRecurringEventsInvalidParams() {
        Campaign testEvent = [
            SELECT Id
            FROM Campaign
            WHERE Name = :TEST_EVENT_NAME
            LIMIT 1
        ];

        Test.startTest();
        
        try {
            CVMAEventControllerLDS.createRecurringEvents(
                testEvent.Id, 
                '', // Empty recurrence type
                0,  // Invalid count
                null
            );
            System.assert(false, 'Should throw exception for invalid parameters');
        } catch (CVMAEventControllerLDS.EventException e) {
            System.assert(e.getMessage().contains('Invalid recurrence'), 'Should indicate invalid parameters');
        }
        
        Test.stopTest();
    }

    /**
     * Test getEventStats with unlimited capacity
     */
    @IsTest
    static void testGetEventStatsUnlimitedCapacity() {
        Campaign unlimitedEvent = new Campaign(
            Name = 'Unlimited Event',
            Type = 'CVMA Event',
            Status = 'Planned',
            StartDate = Date.today().addDays(14),
            IsActive = true
            // No NumberSent = unlimited capacity
        );
        insert unlimitedEvent;

        Test.startTest();
        
        CVMAEventControllerLDS.EventStats stats = CVMAEventControllerLDS.getEventStats(unlimitedEvent.Id);
        
        Test.stopTest();

        System.assertEquals(-1, stats.capacity, 'Should indicate unlimited capacity');
        System.assertEquals(-1, stats.availableSpots, 'Should indicate unlimited spots');
    }

    /**
     * Test error handling
     */
    @IsTest
    static void testErrorHandling() {
        Test.startTest();
        
        try {
            CVMAEventControllerLDS.getEventStats('invalidId');
            System.assert(false, 'Should throw exception for invalid ID');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for invalid ID');
        }
        
        Test.stopTest();

        // Verify error was logged
        List<CVMA_Error_Log__c> errorLogs = [
            SELECT Id, Error_Message__c, Class_Name__c
            FROM CVMA_Error_Log__c
            WHERE Class_Name__c = 'CVMAEventControllerLDS'
        ];

        System.assert(!errorLogs.isEmpty(), 'Error should be logged to CVMA_Error_Log__c');
    }

    /**
     * Test bulk operations and performance
     */
    @IsTest
    static void testBulkOperations() {
        Campaign testEvent = [
            SELECT Id
            FROM Campaign
            WHERE Name = :TEST_EVENT_NAME
            LIMIT 1
        ];

        // Create multiple recurring events
        Test.startTest();
        
        List<Id> recurringIds = CVMAEventControllerLDS.createRecurringEvents(
            testEvent.Id, 
            'weekly', 
            10, 
            null
        );
        
        Test.stopTest();

        System.assertEquals(10, recurringIds.size(), 'Should create 10 recurring events');

        // Verify all events were created
        List<Campaign> allEvents = [
            SELECT Id, Name, StartDate
            FROM Campaign
            WHERE Type = 'CVMA Event'
            ORDER BY StartDate
        ];

        System.assertEquals(11, allEvents.size(), 'Should have 11 total events (1 original + 10 recurring)');
    }
}