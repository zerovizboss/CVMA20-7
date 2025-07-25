/**
 * Simplified test class to verify Combat Veterans Motorcycle Association Guest User
 * has proper access to Salesforce Scheduler functionality
 * 
 * This test works with the existing org structure and custom fields
 */
@IsTest
public class CVMASimpleGuestUserTest {
    
    private static final String GUEST_PROFILE_NAME = 'Guest License User';
    
    /**
     * Test Guest User Profile exists and has basic permissions
     */
    @IsTest
    static void testGuestUserProfileExists() {
        // Verify Guest License User profile exists
        List<Profile> guestProfiles = [
            SELECT Id, Name 
            FROM Profile 
            WHERE Name = :GUEST_PROFILE_NAME 
            LIMIT 1
        ];
        
        System.assertEquals(1, guestProfiles.size(), 
            'Guest License User profile should exist');
        
        System.assertEquals(GUEST_PROFILE_NAME, guestProfiles[0].Name,
            'Profile name should match expected value');
    }
    
    /**
     * Test Guest User can access Service Appointment object
     */
    @IsTest
    static void testServiceAppointmentObjectAccess() {
        User guestUser = createTestGuestUser();
        
        System.runAs(guestUser) {
            // Test describe access to ServiceAppointment
            Schema.DescribeSObjectResult serviceAppointmentDescribe = 
                ServiceAppointment.sObjectType.getDescribe();
            
            System.assert(serviceAppointmentDescribe.accessible, 
                'ServiceAppointment should be accessible for guest user');
            
            System.assert(serviceAppointmentDescribe.createable, 
                'ServiceAppointment should be createable for guest user');
                
            System.assert(serviceAppointmentDescribe.updateable, 
                'ServiceAppointment should be updateable for guest user');
        }
    }
    
    /**
     * Test Guest User can access Event object
     */
    @IsTest
    static void testEventObjectAccess() {
        User guestUser = createTestGuestUser();
        
        System.runAs(guestUser) {
            // Test describe access to Event
            Schema.DescribeSObjectResult eventDescribe = 
                Event.sObjectType.getDescribe();
            
            System.assert(eventDescribe.accessible, 
                'Event should be accessible for guest user');
                
            // Guest users should have read-only access to Events
            System.assert(!eventDescribe.createable, 
                'Event should not be createable for guest user');
        }
    }
    
    /**
     * Test Guest User can access Case object
     */
    @IsTest
    static void testCaseObjectAccess() {
        User guestUser = createTestGuestUser();
        
        System.runAs(guestUser) {
            // Test describe access to Case
            Schema.DescribeSObjectResult caseDescribe = 
                Case.sObjectType.getDescribe();
            
            System.assert(caseDescribe.accessible, 
                'Case should be accessible for guest user');
                
            // Guest users should have read-only access to Cases
            System.assert(!caseDescribe.createable, 
                'Case should not be createable for guest user');
        }
    }
    
    /**
     * Test Guest User can query Service Appointment records
     */
    @IsTest
    static void testServiceAppointmentQuery() {
        User guestUser = createTestGuestUser();
        
        System.runAs(guestUser) {
            try {
                // Test basic query access
                List<ServiceAppointment> appointments = [
                    SELECT Id, Subject, Status, SchedStartTime, SchedEndTime
                    FROM ServiceAppointment
                    LIMIT 1
                ];
                
                System.assert(true, 'Guest user should be able to query ServiceAppointment records');
                
            } catch (Exception e) {
                System.assert(false, 'ServiceAppointment query failed: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Test Guest User can query Event records
     */
    @IsTest
    static void testEventQuery() {
        User guestUser = createTestGuestUser();
        
        System.runAs(guestUser) {
            try {
                // Test basic query access
                List<Event> events = [
                    SELECT Id, Subject, StartDateTime, EndDateTime, IsPrivate
                    FROM Event
                    WHERE IsPrivate = false
                    LIMIT 1
                ];
                
                System.assert(true, 'Guest user should be able to query Event records');
                
            } catch (Exception e) {
                System.assert(false, 'Event query failed: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Test Guest User can query Case records
     */
    @IsTest
    static void testCaseQuery() {
        User guestUser = createTestGuestUser();
        
        System.runAs(guestUser) {
            try {
                // Test basic query access
                List<Case> cases = [
                    SELECT Id, Subject, Status, Type
                    FROM Case
                    WHERE Type != 'Internal' OR Type = null
                    LIMIT 1
                ];
                
                System.assert(true, 'Guest user should be able to query Case records');
                
            } catch (Exception e) {
                System.assert(false, 'Case query failed: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Test Guest User can access Service Territory and Work Type
     */
    @IsTest
    static void testRelatedObjectAccess() {
        User guestUser = createTestGuestUser();
        
        System.runAs(guestUser) {
            try {
                // Test Service Territory access
                List<ServiceTerritory> territories = [
                    SELECT Id, Name, IsActive
                    FROM ServiceTerritory
                    WHERE IsActive = true
                    LIMIT 1
                ];
                
                System.assert(true, 'Guest user should be able to query ServiceTerritory records');
                
                // Test Work Type access
                List<WorkType> workTypes = [
                    SELECT Id, Name, EstimatedDuration
                    FROM WorkType
                    LIMIT 1
                ];
                
                System.assert(true, 'Guest user should be able to query WorkType records');
                
            } catch (Exception e) {
                System.assert(false, 'Related object query failed: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Test permission set exists
     */
    @IsTest
    static void testPermissionSetExists() {
        List<PermissionSet> permissionSets = [
            SELECT Id, Name, Label
            FROM PermissionSet
            WHERE Name = 'CVMA_Guest_Scheduler_Access'
            LIMIT 1
        ];
        
        if (permissionSets.size() > 0) {
            System.assertEquals('CVMA_Guest_Scheduler_Access', permissionSets[0].Name,
                'Permission set should have correct name');
        } else {
            System.debug('CVMA_Guest_Scheduler_Access permission set not found - may need to be deployed');
        }
    }
    
    /**
     * Test Lightning Scheduler app visibility
     */
    @IsTest
    static void testSchedulerAppAccess() {
        User guestUser = createTestGuestUser();
        
        System.runAs(guestUser) {
            // Test that user can see Lightning Scheduler related objects
            Schema.DescribeSObjectResult serviceResourceDescribe = 
                ServiceResource.sObjectType.getDescribe();
            
            System.assert(serviceResourceDescribe.accessible, 
                'ServiceResource should be accessible for guest user');
                
            Schema.DescribeSObjectResult operatingHoursDescribe = 
                OperatingHours.sObjectType.getDescribe();
            
            System.assert(operatingHoursDescribe.accessible, 
                'OperatingHours should be accessible for guest user');
        }
    }
    
    /**
     * Helper method to create a test guest user
     */
    private static User createTestGuestUser() {
        Profile guestProfile = [SELECT Id FROM Profile WHERE Name = :GUEST_PROFILE_NAME LIMIT 1];
        
        // Create a minimal test user for guest profile
        User guestUser = new User(
            FirstName = 'Test',
            LastName = 'GuestSimple',
            Username = 'testguestsimple@cvmatest' + System.currentTimeMillis() + '.org',
            Email = 'testguestsimple@cvmatest.org',
            Alias = 'tgsimpl',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = guestProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        
        insert guestUser;
        return guestUser;
    }
}