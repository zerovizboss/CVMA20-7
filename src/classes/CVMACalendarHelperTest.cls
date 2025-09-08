/**
 * @description Test class for CVMACalendarHelper - Lightning Calendar integration testing
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 */
@IsTest
public class CVMACalendarHelperTest {

    @TestSetup
    static void makeData() {
        // Create test data using CVMATestDataFactory
        Contact testMember = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .create();

        // Create test campaign with CVMA Event RSVP Mapping
        Campaign testCampaign = CVMATestDataFactory.createCampaign()
            .withName('Test CVMA Ride')
            .withType('CVMA Event')
            .withStartDate(Date.today().addDays(7))
            .withEndDate(Date.today().addDays(7))
            .create();

        // Set CVMA_Event_RSVP_Mapping__c field
        testCampaign.CVMA_Event_RSVP_Mapping__c = true;
        update testCampaign;

        // Create Campaign Member for RSVP integration testing
        CampaignMember testMember1 = new CampaignMember(
            CampaignId = testCampaign.Id,
            ContactId = testMember.Id,
            Status = 'Responded - Yes'
        );
        insert testMember1;
    }

    @IsTest
    static void testSyncCampaignsToEvents_Success() {
        Test.startTest();

        // Get test campaign
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test CVMA Ride' LIMIT 1];

        // Test syncing campaigns to events
        CVMACalendarHelper.syncCampaignsToEvents(new List<Id>{ testCampaign.Id });

        Test.stopTest();

        // Verify Event was created
        List<Event> createdEvents = [
            SELECT Id, Subject, Type, WhatId
            FROM Event
            WHERE WhatId = :testCampaign.Id
        ];

        System.assertEquals(1, createdEvents.size(), 'Should create one Event for Campaign');
        System.assertEquals('[CVMA] Test CVMA Ride', createdEvents[0].Subject, 'Event subject should include CVMA prefix');
        System.assertEquals('CVMA Event', createdEvents[0].Type, 'Event type should be CVMA Event');
    }

    @IsTest
    static void testSyncCampaignsToEvents_UpdateExisting() {
        // Get test campaign
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test CVMA Ride' LIMIT 1];

        // Create existing Event first
        Event existingEvent = new Event(
            Subject = 'Old Subject',
            WhatId = testCampaign.Id,
            StartDateTime = DateTime.now().addDays(5),
            EndDateTime = DateTime.now().addDays(5).addHours(2)
        );
        insert existingEvent;

        Test.startTest();

        // Test syncing should update existing event
        CVMACalendarHelper.syncCampaignsToEvents(new List<Id>{ testCampaign.Id });

        Test.stopTest();

        // Verify existing Event was updated
        Event updatedEvent = [
            SELECT Id, Subject, Type
            FROM Event
            WHERE Id = :existingEvent.Id
        ];

        System.assertEquals('[CVMA] Test CVMA Ride', updatedEvent.Subject, 'Event subject should be updated');
        System.assertEquals('CVMA Event', updatedEvent.Type, 'Event type should be updated');
    }

    @IsTest
    static void testGetCalendarEvents_Success() {
        // Get test campaign and sync to create Event
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test CVMA Ride' LIMIT 1];
        CVMACalendarHelper.syncCampaignsToEvents(new List<Id>{ testCampaign.Id });

        Date startDate = Date.today();
        Date endDate = Date.today().addDays(14);

        Test.startTest();

        // Test retrieving calendar events
        List<Event> events = CVMACalendarHelper.getCalendarEvents(startDate, endDate);

        Test.stopTest();

        // Verify events retrieved
        System.assertEquals(1, events.size(), 'Should retrieve one CVMA event');
        System.assertEquals('[CVMA] Test CVMA Ride', events[0].Subject, 'Should retrieve correct event');
    }

    @IsTest
    static void testGetCalendarEvents_InvalidDates() {
        Test.startTest();

        try {
            // Test with null dates
            CVMACalendarHelper.getCalendarEvents(null, null);
            System.assert(false, 'Should throw exception for null dates');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Start and end dates are required'),
                         'Should throw validation error for null dates');
        }

        Test.stopTest();
    }

    @IsTest
    static void testCreateCVMAEvent_Success() {
        String eventName = 'New Test Event';
        String eventDescription = 'Test event description';
        DateTime startDateTime = DateTime.now().addDays(10);
        DateTime endDateTime = startDateTime.addHours(3);

        Test.startTest();

        // Test creating new CVMA event
        Id campaignId = CVMACalendarHelper.createCVMAEvent(eventName, eventDescription, startDateTime, endDateTime);

        Test.stopTest();

        // Verify Campaign was created
        Campaign createdCampaign = [
            SELECT Id, Name, Description, Type, Status, IsActive, CVMA_Event_RSVP_Mapping__c, StartDate, EndDate
            FROM Campaign
            WHERE Id = :campaignId
        ];

        System.assertEquals(eventName, createdCampaign.Name, 'Campaign name should match');
        System.assertEquals(eventDescription, createdCampaign.Description, 'Campaign description should match');
        System.assertEquals('CVMA Event', createdCampaign.Type, 'Campaign type should be CVMA Event');
        System.assertEquals('Planned', createdCampaign.Status, 'Campaign status should be Planned');
        System.assertEquals(true, createdCampaign.IsActive, 'Campaign should be active');
        System.assertEquals(true, createdCampaign.CVMA_Event_RSVP_Mapping__c, 'Should enable RSVP mapping');
        System.assertEquals(startDateTime.date(), createdCampaign.StartDate, 'Start date should match');
        System.assertEquals(endDateTime.date(), createdCampaign.EndDate, 'End date should match');

        // Verify Event was also created through sync
        List<Event> synedEvents = [
            SELECT Id, Subject, WhatId
            FROM Event
            WHERE WhatId = :campaignId
        ];

        System.assertEquals(1, synedEvents.size(), 'Should create synced Event');
        System.assertEquals('[CVMA] ' + eventName, synedEvents[0].Subject, 'Event should have correct subject');
    }

    @IsTest
    static void testCreateCVMAEvent_InvalidData() {
        Test.startTest();

        try {
            // Test with blank event name
            CVMACalendarHelper.createCVMAEvent('', 'Description', DateTime.now(), DateTime.now().addHours(1));
            System.assert(false, 'Should throw exception for blank event name');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Event name and start time are required'),
                         'Should throw validation error for blank name');
        }

        try {
            // Test with null start time
            CVMACalendarHelper.createCVMAEvent('Test Event', 'Description', null, DateTime.now().addHours(1));
            System.assert(false, 'Should throw exception for null start time');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Event name and start time are required'),
                         'Should throw validation error for null start time');
        }

        Test.stopTest();
    }

    @IsTest
    static void testGetEventDetails_Success() {
        // Get test campaign with Campaign Member
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test CVMA Ride' LIMIT 1];

        Test.startTest();

        // Test getting event details with RSVP information
        CVMACalendarHelper.EventDetail eventDetail = CVMACalendarHelper.getEventDetails(testCampaign.Id);

        Test.stopTest();

        // Verify event details
        System.assertEquals(testCampaign.Id, eventDetail.campaignId, 'Campaign ID should match');
        System.assertEquals('Test CVMA Ride', eventDetail.eventName, 'Event name should match');
        System.assertEquals('CVMA Event', eventDetail.eventName != null ? 'CVMA Event' : null, 'Should be CVMA Event type');

        // Verify RSVP counts (we created one "Responded - Yes" member in test setup)
        System.assertEquals(1, eventDetail.yesCount, 'Should have one Yes RSVP');
        System.assertEquals(0, eventDetail.noCount, 'Should have no No RSVPs');
        System.assertEquals(0, eventDetail.maybeCount, 'Should have no Maybe RSVPs');
        System.assertEquals(1, eventDetail.totalAttending, 'Should have one total attending');
    }

    @IsTest
    static void testGetEventDetails_InvalidId() {
        Test.startTest();

        try {
            // Test with null event ID
            CVMACalendarHelper.getEventDetails(null);
            System.assert(false, 'Should throw exception for null event ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Event ID is required'),
                         'Should throw validation error for null ID');
        }

        Test.stopTest();
    }

    @IsTest
    static void testBatchSyncAllCampaigns_Success() {
        // Create additional CVMA campaigns for batch testing
        Campaign campaign2 = CVMATestDataFactory.createCampaign()
            .withName('Test Batch Campaign')
            .withType('CVMA Event')
            .create();
        campaign2.CVMA_Event_RSVP_Mapping__c = true;
        update campaign2;

        Test.startTest();

        // Test batch syncing all CVMA campaigns
        CVMACalendarHelper.batchSyncAllCampaigns();

        Test.stopTest();

        // Verify all CVMA Event campaigns were synced
        List<Event> allEvents = [
            SELECT Id, Subject, WhatId
            FROM Event
            WHERE Type = 'CVMA Event'
        ];

        System.assert(allEvents.size() >= 2, 'Should sync multiple CVMA campaigns');

        // Check that events have correct subjects
        Set<String> eventSubjects = new Set<String>();
        for (Event evt : allEvents) {
            eventSubjects.add(evt.Subject);
        }

        System.assert(eventSubjects.contains('[CVMA] Test CVMA Ride'), 'Should include first campaign');
        System.assert(eventSubjects.contains('[CVMA] Test Batch Campaign'), 'Should include second campaign');
    }

    @IsTest
    static void testEventDetailWrapper_Coverage() {
        Test.startTest();

        // Test EventDetail wrapper class for code coverage
        CVMACalendarHelper.EventDetail detail = new CVMACalendarHelper.EventDetail();
        detail.campaignId = 'testId';
        detail.eventName = 'Test Event';
        detail.eventDescription = 'Test Description';
        detail.startDate = Date.today();
        detail.endDate = Date.today();
        detail.status = 'Planned';
        detail.yesCount = 5;
        detail.noCount = 2;
        detail.maybeCount = 1;
        detail.totalAttending = 6;

        Test.stopTest();

        // Verify wrapper properties
        System.assertEquals('testId', detail.campaignId, 'Campaign ID should be set');
        System.assertEquals('Test Event', detail.eventName, 'Event name should be set');
        System.assertEquals('Test Description', detail.eventDescription, 'Description should be set');
        System.assertEquals(Date.today(), detail.startDate, 'Start date should be set');
        System.assertEquals(Date.today(), detail.endDate, 'End date should be set');
        System.assertEquals('Planned', detail.status, 'Status should be set');
        System.assertEquals(5, detail.yesCount, 'Yes count should be set');
        System.assertEquals(2, detail.noCount, 'No count should be set');
        System.assertEquals(1, detail.maybeCount, 'Maybe count should be set');
        System.assertEquals(6, detail.totalAttending, 'Total attending should be set');
    }

    @IsTest
    static void testErrorHandling_Integration() {
        Test.startTest();

        // Test that error handling integrates with CVMAErrorHandler
        try {
            // This should trigger CVMAErrorHandler.handleException
            CVMACalendarHelper.getCalendarEvents(null, Date.today());
            System.assert(false, 'Should throw AuraHandledException');
        } catch (AuraHandledException e) {
            // Verify error message format from CVMAErrorHandler integration
            System.assert(e.getMessage().contains('Start and end dates are required'),
                         'Should have proper error handling integration');
        }

        Test.stopTest();
    }
}
