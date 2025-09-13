/**
 * @description Test class for CVMAGuestCalendarHelper
 * @author Claude AI - CVMA Development Team
 * @date 2025-09-10
 *
 * Comprehensive test coverage for Guest User calendar functionality
 * Tests security boundaries and data sanitization for community users
 */
@IsTest
public class CVMAGuestCalendarHelperTest {

    @TestSetup
    static void makeData() {
        // Create test account
        Account testAccount = CVMATestDataFactory.createAccount()
            .withName('CVMA Chapter 20-7')
            .create();

        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        Contact johnContact = CVMATestDataFactory.createContact()
            .withFirstName('John')
            .withLastName('Member')
            .withLevel('Full Member')
            .create();
        johnContact.AccountId = testAccount.Id;
        testContacts.add(johnContact);

        Contact janeContact = CVMATestDataFactory.createContact()
            .withFirstName('Jane')
            .withLastName('Associate')
            .withLevel('Associate Member')
            .create();
        janeContact.AccountId = testAccount.Id;
        testContacts.add(janeContact);

        // Create test campaigns (events)
        List<Campaign> testCampaigns = new List<Campaign>();
        testCampaigns.add(new Campaign(
            Name = 'Public CVMA Ride',
            Type = 'CVMA Event',
            Status = 'Planned',
            StartDate = Date.today().addDays(7),
            EndDate = Date.today().addDays(7),
            Description = 'Public motorcycle ride event',
            IsActive = true,
            CVMA_Event_RSVP_Mapping__c = true
        ));

        testCampaigns.add(new Campaign(
            Name = 'Private Member Meeting',
            Type = 'CVMA Event',
            Status = 'Planned',
            StartDate = Date.today().addDays(14),
            EndDate = Date.today().addDays(14),
            Description = '[MEMBERS ONLY] Private chapter meeting with sensitive info',
            IsActive = true,
            CVMA_Event_RSVP_Mapping__c = true
        ));
        insert testCampaigns;

        // Create test events
        List<Event> testEvents = new List<Event>();
        testEvents.add(new Event(
            Subject = '[CVMA] Public Ride Event',
            Type = 'CVMA Event',
            StartDateTime = Datetime.newInstance(Date.today().addDays(7), Time.newInstance(10, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(Date.today().addDays(7), Time.newInstance(14, 0, 0, 0)),
            Description = 'Join us for a scenic motorcycle ride. Contact john.doe@example.com for details or call 555-123-4567.',
            IsVisibleInSelfService = true,
            IsPrivate = false,
            WhatId = testCampaigns[0].Id
        ));

        testEvents.add(new Event(
            Subject = '[CVMA] Member Meeting',
            Type = 'CVMA Event',
            StartDateTime = Datetime.newInstance(Date.today().addDays(14), Time.newInstance(19, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(Date.today().addDays(14), Time.newInstance(21, 0, 0, 0)),
            Description = '[MEMBERS ONLY] Chapter business meeting with financial reports',
            IsVisibleInSelfService = false,
            IsPrivate = true,
            WhatId = testCampaigns[1].Id
        ));

        testEvents.add(new Event(
            Subject = '[CVMA] Past Event',
            Type = 'CVMA Event',
            StartDateTime = Datetime.newInstance(Date.today().addDays(-7), Time.newInstance(12, 0, 0, 0)),
            EndDateTime = Datetime.newInstance(Date.today().addDays(-7), Time.newInstance(16, 0, 0, 0)),
            Description = 'Past event for testing',
            IsVisibleInSelfService = true,
            IsPrivate = false
        ));
        insert testEvents;

        // Create Campaign Members for RSVP testing
        List<CampaignMember> testMembers = new List<CampaignMember>();
        testMembers.add(new CampaignMember(
            CampaignId = testCampaigns[0].Id,
            ContactId = testContacts[0].Id,
            Status = 'Responded - Yes'
        ));
        testMembers.add(new CampaignMember(
            CampaignId = testCampaigns[0].Id,
            ContactId = testContacts[1].Id,
            Status = 'Plus One - Yes'
        ));
        insert testMembers;
    }

    @IsTest
    static void testGetPublicCalendarEvents_Success() {
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(30);

        Test.startTest();
        List<Event> result = CVMAGuestCalendarHelper.getPublicCalendarEvents(startDate, endDate);
        Test.stopTest();

        // Should return only public events
        System.assertNotEquals(null, result, 'Should return event list');
        System.assertEquals(1, result.size(), 'Should return only public events');

        Event publicEvent = result[0];
        System.assertEquals('[CVMA] Public Ride Event', publicEvent.Subject, 'Subject should match');
        System.assertEquals(true, publicEvent.IsVisibleInSelfService, 'Should be visible in self-service');
        System.assertEquals(false, publicEvent.IsPrivate, 'Should not be private');

        // Verify content is sanitized
        System.assert(publicEvent.Description.contains('[Email Hidden]'), 'Email should be sanitized');
        System.assert(publicEvent.Description.contains('[Phone Hidden]'), 'Phone should be sanitized');
    }

    @IsTest
    static void testGetPublicCalendarEvents_NullDates() {
        Test.startTest();
        List<Event> result = CVMAGuestCalendarHelper.getPublicCalendarEvents(null, null);
        Test.stopTest();

        // Should handle null dates gracefully
        System.assertNotEquals(null, result, 'Should return event list even with null dates');
    }

    @IsTest
    static void testGetPublicEventDetails_Success() {
        Event testEvent = [SELECT Id, WhatId FROM Event WHERE Subject = '[CVMA] Public Ride Event' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = CVMAGuestCalendarHelper.getPublicEventDetails(testEvent.Id);
        Test.stopTest();

        // Verify event details returned
        System.assertNotEquals(null, result, 'Should return event details');
        System.assertEquals(testEvent.Id, result.get('id'), 'ID should match');
        System.assertEquals('[CVMA] Public Ride Event', result.get('subject'), 'Subject should match');
        System.assertNotEquals(null, result.get('startDateTime'), 'Start date should be present');
        System.assertEquals('CVMA Event', result.get('type'), 'Type should match');

        // Verify content is sanitized
        String description = (String) result.get('description');
        System.assert(description.contains('[Email Hidden]'), 'Email should be sanitized');
        System.assert(description.contains('[Phone Hidden]'), 'Phone should be sanitized');

        // Verify RSVP summary is included
        System.assertNotEquals(null, result.get('rsvpSummary'), 'RSVP summary should be included');
    }

    @IsTest
    static void testGetPublicEventDetails_InvalidId() {
        Test.startTest();
        Map<String, Object> result = CVMAGuestCalendarHelper.getPublicEventDetails(null);
        Test.stopTest();

        System.assertEquals(null, result, 'Should return null for invalid ID');
    }

    @IsTest
    static void testGetPublicEventDetails_PrivateEvent() {
        Event privateEvent = [SELECT Id FROM Event WHERE Subject = '[CVMA] Member Meeting' LIMIT 1];

        Test.startTest();
        try {
            Map<String, Object> result = CVMAGuestCalendarHelper.getPublicEventDetails(privateEvent.Id);
            System.assertEquals(null, result, 'Should return null for private event');
        } catch (QueryException e) {
            // Expected - private event not accessible
            System.assert(true, 'Private event should not be accessible');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetCurrentMonthPublicEvents() {
        Test.startTest();
        List<Event> result = CVMAGuestCalendarHelper.getCurrentMonthPublicEvents();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return event list');
        // Results depend on test data timing, but method should execute without error
    }

    @IsTest
    static void testGetPublicRSVPSummary_Success() {
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Public CVMA Ride' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = CVMAGuestCalendarHelper.getPublicRSVPSummary(testCampaign.Id);
        Test.stopTest();

        // Verify RSVP summary data
        System.assertNotEquals(null, result, 'Should return RSVP summary');
        System.assertEquals(2, result.get('attendingCount'), 'Should have 2 attending (1 Yes + 1 Plus One)');
        System.assertEquals(0, result.get('maybeCount'), 'Should have 0 maybe responses');
        System.assertEquals(1, result.get('plusOneCount'), 'Should have 1 plus one');
        System.assertEquals(2, result.get('totalInterested'), 'Should have 2 total interested');
    }

    @IsTest
    static void testGetPublicRSVPSummary_NullCampaign() {
        Test.startTest();
        Map<String, Object> result = CVMAGuestCalendarHelper.getPublicRSVPSummary(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return empty map for null campaign');
        System.assertEquals(0, result.size(), 'Map should be empty');
    }

    @IsTest
    static void testGetPublicRSVPSummary_NoCampaignMembers() {
        // Create campaign without members
        Campaign emptyCampaign = new Campaign(
            Name = 'Empty Event',
            Type = 'CVMA Event',
            Status = 'Planned',
            IsActive = true
        );
        insert emptyCampaign;

        Test.startTest();
        Map<String, Object> result = CVMAGuestCalendarHelper.getPublicRSVPSummary(emptyCampaign.Id);
        Test.stopTest();

        // Verify empty summary
        System.assertNotEquals(null, result, 'Should return RSVP summary');
        System.assertEquals(0, result.get('attendingCount'), 'Should have 0 attending');
        System.assertEquals(0, result.get('maybeCount'), 'Should have 0 maybe');
        System.assertEquals(0, result.get('plusOneCount'), 'Should have 0 plus one');
        System.assertEquals(0, result.get('totalInterested'), 'Should have 0 total interested');
    }

    @IsTest
    static void testContentSanitization() {
        // Test data with various sensitive content
        Event testEvent = new Event(
            Subject = '[CVMA] Test Event with Contact Info',
            Type = 'CVMA Event',
            StartDateTime = Datetime.now().addDays(1),
            EndDateTime = Datetime.now().addDays(1).addHours(2),
            Description = 'Contact john.doe@example.com or jane@test.org. Call 555-123-4567 or (123) 456-7890. [MEMBERS ONLY] Secret meeting details here.',
            IsVisibleInSelfService = true,
            IsPrivate = false
        );
        insert testEvent;

        Test.startTest();
        Map<String, Object> result = CVMAGuestCalendarHelper.getPublicEventDetails(testEvent.Id);
        Test.stopTest();

        String sanitizedDescription = (String) result.get('description');

        // Verify email sanitization
        System.assert(!sanitizedDescription.contains('john.doe@example.com'), 'Email should be removed');
        System.assert(!sanitizedDescription.contains('jane@test.org'), 'Email should be removed');
        System.assert(sanitizedDescription.contains('[Email Hidden]'), 'Should show email hidden placeholder');

        // Verify phone sanitization
        System.assert(!sanitizedDescription.contains('555-123-4567'), 'Phone should be removed');
        System.assert(!sanitizedDescription.contains('(123) 456-7890'), 'Phone should be removed');
        System.assert(sanitizedDescription.contains('[Phone Hidden]'), 'Should show phone hidden placeholder');

        // Verify members-only content sanitization
        System.assert(!sanitizedDescription.contains('Secret meeting'), 'Members-only content should be removed');
        System.assert(sanitizedDescription.contains('[Members Only Content]'), 'Should show members-only placeholder');
    }

    @IsTest
    static void testErrorHandling() {
        Test.startTest();

        // Test with invalid date range (should handle gracefully)
        Date invalidStart = Date.today().addYears(10);
        Date invalidEnd = Date.today().addYears(-10);
        List<Event> result = CVMAGuestCalendarHelper.getPublicCalendarEvents(invalidStart, invalidEnd);

        Test.stopTest();

        // Should return empty list without throwing exception
        System.assertNotEquals(null, result, 'Should handle invalid date range gracefully');
    }

    @IsTest
    static void testSecurityBoundaries() {
        // Ensure private events are not returned
        Test.startTest();
        List<Event> publicEvents = CVMAGuestCalendarHelper.getCurrentMonthPublicEvents();
        Test.stopTest();

        // Verify no private events returned
        for (Event evt : publicEvents) {
            System.assertEquals(false, evt.IsPrivate, 'No private events should be returned');
            System.assertEquals(true, evt.IsVisibleInSelfService, 'All events should be visible in self-service');
            System.assertEquals('CVMA Event', evt.Type, 'Should only return CVMA events');
        }
    }

    @IsTest
    static void testLimitEnforcement() {
        // Create many test events to test limit
        List<Event> manyEvents = new List<Event>();
        for (Integer i = 0; i < 60; i++) {
            manyEvents.add(new Event(
                Subject = '[CVMA] Test Event ' + i,
                Type = 'CVMA Event',
                StartDateTime = Datetime.now().addDays(i),
                EndDateTime = Datetime.now().addDays(i).addHours(2),
                IsVisibleInSelfService = true,
                IsPrivate = false
            ));
        }
        insert manyEvents;

        Test.startTest();
        List<Event> result = CVMAGuestCalendarHelper.getPublicCalendarEvents(Date.today(), Date.today().addDays(90));
        Test.stopTest();

        // Should enforce 50 event limit
        System.assert(result.size() <= 50, 'Should enforce 50 event limit for security');
    }
}
