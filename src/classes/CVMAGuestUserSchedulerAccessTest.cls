/**
 * Test class to verify Combat Veterans Motorcycle Association Guest User
 * has proper access to Salesforce Scheduler functionality
 * 
 * Tests Service Appointment, Case, and Event access for guest users
 * in the Combat Veterans community
 */
@IsTest
public class CVMAGuestUserSchedulerAccessTest {
    
    private static final String COMMUNITY_NAME = 'Combat Veterans Motorcycle Association';
    private static final String GUEST_PROFILE_NAME = 'Guest License User';
    
    @TestSetup
    static void setupTestData() {
        // Get the guest user profile
        Profile guestProfile = [SELECT Id FROM Profile WHERE Name = :GUEST_PROFILE_NAME LIMIT 1];
        
        // Create test Service Territory
        ServiceTerritory territory = new ServiceTerritory(
            Name = 'CVMA Test Territory',
            IsActive = true,
            OperatingHoursId = getOperatingHours()
        );
        insert territory;
        
        // Create test Work Type
        WorkType workType = new WorkType(
            Name = 'CVMA Service Type',
            EstimatedDuration = 60,
            DurationType = 'Minutes'
        );
        insert workType;
        
        // Create test Account for appointments
        Account testAccount = new Account(
            Name = 'CVMA Test Member'
        );
        insert testAccount;
        
        // Create test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Member',
            Email = 'testmember@cvma207.org',
            AccountId = testAccount.Id,
            Level__c = 'Full Member',
            Membership_Id__c = 'FM00001'
        );
        insert testContact;
        
        // Create test Work Order for Service Appointments
        WorkOrder testWorkOrder = new WorkOrder(
            Subject = 'CVMA Test Work Order',
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            WorkTypeId = workType.Id,
            ServiceTerritoryId = territory.Id,
            Status = 'New'
        );
        insert testWorkOrder;
        
        // Create test Service Appointments
        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        appointments.add(new ServiceAppointment(
            Subject = 'CVMA Meeting - Public',
            ContactId = testContact.Id,
            ServiceTerritoryId = territory.Id,
            WorkTypeId = workType.Id,
            ParentRecordId = testWorkOrder.Id,
            SchedStartTime = Datetime.now().addDays(1),
            SchedEndTime = Datetime.now().addDays(1).addHours(1),
            Status = 'Scheduled',
            Description = 'Public CVMA meeting accessible to guests'
        ));
        
        appointments.add(new ServiceAppointment(
            Subject = 'CVMA Private Meeting',
            ContactId = testContact.Id,
            ServiceTerritoryId = territory.Id,
            WorkTypeId = workType.Id,
            ParentRecordId = testWorkOrder.Id,
            SchedStartTime = Datetime.now().addDays(2),
            SchedEndTime = Datetime.now().addDays(2).addHours(1),
            Status = 'Canceled',
            Description = 'Canceled meeting - should not be visible to guests'
        ));
        insert appointments;
        
        // Create test Cases
        List<Case> cases = new List<Case>();
        cases.add(new Case(
            Subject = 'Public CVMA Inquiry',
            Description = 'Public case visible to guests',
            Status = 'New',
            Origin = 'Web',
            AccountId = testAccount.Id,
            ContactId = testContact.Id
        ));
        
        cases.add(new Case(
            Subject = 'Internal CVMA Issue',
            Description = 'Internal case not visible to guests',
            Status = 'New',
            Origin = 'Internal',
            Type = 'Internal',
            AccountId = testAccount.Id,
            ContactId = testContact.Id
        ));
        insert cases;
        
        // Create test Events
        List<Event> events = new List<Event>();
        events.add(new Event(
            Subject = 'Public CVMA Event',
            Description = 'Public event visible to guests',
            StartDateTime = Datetime.now().addDays(3),
            EndDateTime = Datetime.now().addDays(3).addHours(2),
            IsPrivate = false,
            WhatId = testAccount.Id,
            WhoId = testContact.Id
        ));
        
        events.add(new Event(
            Subject = 'Private CVMA Event',
            Description = 'Private event not visible to guests',
            StartDateTime = Datetime.now().addDays(4),
            EndDateTime = Datetime.now().addDays(4).addHours(2),
            IsPrivate = true
        ));
        insert events;
    }
    
    /**
     * Test Service Appointment access for guest users
     */
    @IsTest
    static void testGuestUserServiceAppointmentAccess() {
        User guestUser = getGuestUser();
        
        System.runAs(guestUser) {
            // Test read access to Service Appointments
            List<ServiceAppointment> visibleAppointments = [
                SELECT Id, Subject, Status, Description 
                FROM ServiceAppointment 
                WHERE Status != 'Canceled'
            ];
            
            System.assertEquals(1, visibleAppointments.size(), 
                'Guest user should see 1 non-canceled Service Appointment');
            
            System.assertEquals('CVMA Meeting - Public', visibleAppointments[0].Subject,
                'Guest user should see the public meeting');
            
            // Test create access
            ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
            WorkType workType = [SELECT Id FROM WorkType LIMIT 1];
            Account testAccount = [SELECT Id FROM Account LIMIT 1];
            Contact testContact = [SELECT Id FROM Contact LIMIT 1];
            WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
            
            ServiceAppointment newAppointment = new ServiceAppointment(
                Subject = 'Guest Created Appointment',
                ContactId = testContact.Id,
                ServiceTerritoryId = territory.Id,
                WorkTypeId = workType.Id,
                ParentRecordId = testWorkOrder.Id,
                SchedStartTime = Datetime.now().addDays(5),
                SchedEndTime = Datetime.now().addDays(5).addHours(1),
                Status = 'Scheduled',
                Description = 'Appointment created by guest user'
            );
            
            try {
                insert newAppointment;
                System.assert(true, 'Guest user should be able to create Service Appointments');
                
                // Test edit access
                newAppointment.Description = 'Updated by guest user';
                update newAppointment;
                System.assert(true, 'Guest user should be able to edit Service Appointments');
                
            } catch (Exception e) {
                System.assert(false, 'Guest user should have create/edit access: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Test Case visibility for guest users
     */
    @IsTest
    static void testGuestUserCaseAccess() {
        User guestUser = getGuestUser();
        
        System.runAs(guestUser) {
            // Test read access to Cases (excluding internal)
            List<Case> visibleCases = [
                SELECT Id, Subject, Type, Description 
                FROM Case 
                WHERE Type != 'Internal' OR Type = NULL
            ];
            
            System.assertEquals(1, visibleCases.size(), 
                'Guest user should see 1 public Case');
            
            System.assertEquals('Public CVMA Inquiry', visibleCases[0].Subject,
                'Guest user should see the public case');
            
            // Test that guest users cannot create Cases
            Case newCase = new Case(
                Subject = 'Guest User Case',
                Description = 'Case creation attempt by guest',
                Status = 'New',
                Origin = 'Web'
            );
            
            try {
                insert newCase;
                System.assert(false, 'Guest user should not be able to create Cases');
            } catch (Exception e) {
                System.assert(true, 'Expected: Guest user cannot create Cases');
            }
        }
    }
    
    /**
     * Test Event visibility for guest users
     */
    @IsTest
    static void testGuestUserEventAccess() {
        User guestUser = getGuestUser();
        
        System.runAs(guestUser) {
            // Test read access to Events (excluding private)
            List<Event> visibleEvents = [
                SELECT Id, Subject, IsPrivate, Description 
                FROM Event 
                WHERE IsPrivate = FALSE
            ];
            
            System.assertEquals(1, visibleEvents.size(), 
                'Guest user should see 1 public Event');
            
            System.assertEquals('Public CVMA Event', visibleEvents[0].Subject,
                'Guest user should see the public event');
            
            System.assertEquals(false, visibleEvents[0].IsPrivate,
                'Visible event should not be private');
            
            // Test that guest users cannot create Events
            Event newEvent = new Event(
                Subject = 'Guest User Event',
                Description = 'Event creation attempt by guest',
                StartDateTime = Datetime.now().addDays(6),
                EndDateTime = Datetime.now().addDays(6).addHours(1),
                IsPrivate = false
            );
            
            try {
                insert newEvent;
                System.assert(false, 'Guest user should not be able to create Events');
            } catch (Exception e) {
                System.assert(true, 'Expected: Guest user cannot create Events');
            }
        }
    }
    
    /**
     * Test sharing rule effectiveness
     */
    @IsTest
    static void testSharingRulesEffectiveness() {
        User guestUser = getGuestUser();
        
        System.runAs(guestUser) {
            // Verify sharing rules are working
            
            // Should NOT see canceled Service Appointments
            List<ServiceAppointment> canceledAppointments = [
                SELECT Id, Subject, Status 
                FROM ServiceAppointment 
                WHERE Status = 'Canceled'
            ];
            
            System.assertEquals(0, canceledAppointments.size(), 
                'Guest user should not see canceled Service Appointments');
            
            // Should NOT see internal Cases
            List<Case> internalCases = [
                SELECT Id, Subject, Type 
                FROM Case 
                WHERE Type = 'Internal'
            ];
            
            System.assertEquals(0, internalCases.size(), 
                'Guest user should not see internal Cases');
            
            // Should NOT see private Events
            List<Event> privateEvents = [
                SELECT Id, Subject, IsPrivate 
                FROM Event 
                WHERE IsPrivate = TRUE
            ];
            
            System.assertEquals(0, privateEvents.size(), 
                'Guest user should not see private Events');
        }
    }
    
    /**
     * Test Guest User Profile permissions
     */
    @IsTest
    static void testGuestUserProfilePermissions() {
        User guestUser = getGuestUser();
        Profile guestProfile = [SELECT Id, Name FROM Profile WHERE Id = :guestUser.ProfileId];
        
        System.assertEquals(GUEST_PROFILE_NAME, guestProfile.Name,
            'User should have Guest License User profile');
        
        // Test object permissions through describe calls
        System.runAs(guestUser) {
            Schema.DescribeSObjectResult serviceAppointmentDescribe = ServiceAppointment.SObjectType.getDescribe();
            System.assert(serviceAppointmentDescribe.createable, 
                'ServiceAppointment should be createable for guest user');
            System.assert(serviceAppointmentDescribe.updateable, 
                'ServiceAppointment should be updateable for guest user');
            
            Schema.DescribeSObjectResult caseDescribe = Case.SObjectType.getDescribe();
            System.assert(caseDescribe.accessible, 
                'Case should be accessible for guest user');
            
            Schema.DescribeSObjectResult eventDescribe = Event.SObjectType.getDescribe();
            System.assert(eventDescribe.accessible, 
                'Event should be accessible for guest user');
        }
    }
    
    /**
     * Helper method to get or create a guest user for testing
     * @return existingGuestUser
     */
    private static User getGuestUser() {
        Profile guestProfile = [SELECT Id FROM Profile WHERE Name = :GUEST_PROFILE_NAME LIMIT 1];
        
        // Try to find existing guest user
        List<User> existingGuestUsers = [
            SELECT Id, Username, ProfileId 
            FROM User 
            WHERE ProfileId = :guestProfile.Id 
            AND IsActive = TRUE
            LIMIT 1
        ];
        
        if (!existingGuestUsers.isEmpty()) {
            return existingGuestUsers[0];
        }
        
        // Create a guest user for testing
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
        return guestUser;
    }
    
    /**
     * Helper method to get or create Operating Hours
     * @return existingHours Id
     */
    private static Id getOperatingHours() {
        List<OperatingHours> existingHours = [SELECT Id FROM OperatingHours LIMIT 1];
        
        if (!existingHours.isEmpty()) {
            return existingHours[0].Id;
        }
        
        // Create Operating Hours if none exist
        OperatingHours hours = new OperatingHours(
            Name = 'CVMA Operating Hours',
            TimeZone = 'America/New_York'
        );
        insert hours;
        return hours.Id;
    }
}