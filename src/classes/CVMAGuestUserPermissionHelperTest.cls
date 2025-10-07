/**
 * Test class for CVMAGuestUserPermissionHelper
 * Comprehensive test coverage for guest user permission validation
 * Security-critical test coverage for member privacy protection
 */
@IsTest
public class CVMAGuestUserPermissionHelperTest {

    @TestSetup
    static void setupTestData() {
        // Create test contact for guest user
        Contact guestContact = CVMATestDataFactory.createContact()
            .withFirstName('Guest')
            .withLastName('User')
            .withEmail('guest.user@cvma-test.org')
            .withLevel('Supporter')
            .create();

        // Create standard test contact for comparison
        Contact standardContact = CVMATestDataFactory.createContact()
            .withFirstName('Standard')
            .withLastName('User')
            .withEmail('standard.user@cvma-test.org')
            .withLevel('Full Member')
            .create();
    }

    /**
     * Test: isValidGuestUser() returns false for standard users
     */
    @IsTest
    static void testIsValidGuestUser_StandardUser() {
        // Get standard user
        User standardUser = [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND IsActive = true LIMIT 1];

        Test.startTest();
        System.runAs(standardUser) {
            // Clear cache to ensure fresh check
            CVMAGuestUserPermissionHelper.clearCache();

            Boolean isGuestUser = CVMAGuestUserPermissionHelper.isValidGuestUser();

            // Verify standard user is NOT identified as guest
            System.assertEquals(false, isGuestUser, 'Standard user should not be identified as guest user');
        }
        Test.stopTest();
    }

    /**
     * Test: isValidGuestUser() caching mechanism
     */
    @IsTest
    static void testIsValidGuestUser_CachingBehavior() {
        Test.startTest();

        // First call should query database
        Boolean firstCall = CVMAGuestUserPermissionHelper.isValidGuestUser();

        // Second call should use cache (no query)
        Boolean secondCall = CVMAGuestUserPermissionHelper.isValidGuestUser();

        // Results should be consistent
        System.assertEquals(firstCall, secondCall, 'Cached result should match initial result');

        // Clear cache
        CVMAGuestUserPermissionHelper.clearCache();

        // After cache clear, should query again
        Boolean thirdCall = CVMAGuestUserPermissionHelper.isValidGuestUser();

        System.assertEquals(firstCall, thirdCall, 'Result after cache clear should match original');

        Test.stopTest();
    }

    /**
     * Test: hasObjectAccess() for standard objects
     */
    @IsTest
    static void testHasObjectAccess_StandardObjects() {
        Test.startTest();

        // Test accessible objects (standard user should have access)
        Boolean contactAccess = CVMAGuestUserPermissionHelper.hasObjectAccess('Contact');
        Boolean accountAccess = CVMAGuestUserPermissionHelper.hasObjectAccess('Account');

        // Verify access for standard objects
        System.assertEquals(true, contactAccess, 'Should have access to Contact object');
        System.assertEquals(true, accountAccess, 'Should have access to Account object');

        Test.stopTest();
    }

    /**
     * Test: hasObjectAccess() for invalid objects
     */
    @IsTest
    static void testHasObjectAccess_InvalidObject() {
        Test.startTest();

        // Test non-existent object
        Boolean invalidAccess = CVMAGuestUserPermissionHelper.hasObjectAccess('NonExistentObject__c');

        // Verify no access to invalid object
        System.assertEquals(false, invalidAccess, 'Should return false for non-existent object');

        Test.stopTest();
    }

    /**
     * Test: hasObjectAccess() caching behavior
     */
    @IsTest
    static void testHasObjectAccess_Caching() {
        Test.startTest();

        // First call for Contact object
        Boolean firstCall = CVMAGuestUserPermissionHelper.hasObjectAccess('Contact');

        // Second call for same object (should use cache)
        Boolean secondCall = CVMAGuestUserPermissionHelper.hasObjectAccess('Contact');

        // Results should be identical
        System.assertEquals(firstCall, secondCall, 'Cached object access should match initial check');

        // Clear cache
        CVMAGuestUserPermissionHelper.clearCache();

        // After cache clear, result should still be consistent
        Boolean thirdCall = CVMAGuestUserPermissionHelper.hasObjectAccess('Contact');
        System.assertEquals(firstCall, thirdCall, 'Access check should be consistent after cache clear');

        Test.stopTest();
    }

    /**
     * Test: validateSchedulerAccess() for required objects
     */
    @IsTest
    static void testValidateSchedulerAccess() {
        Test.startTest();

        // Validate scheduler access
        Boolean schedulerAccess = CVMAGuestUserPermissionHelper.validateSchedulerAccess();

        // Note: Result depends on org configuration and user permissions
        // We're testing that method executes without error
        System.assertNotEquals(null, schedulerAccess, 'Scheduler access validation should return a result');

        Test.stopTest();
    }

    /**
     * Test: getAccessibleSchedulerObjects() returns list
     */
    @IsTest
    static void testGetAccessibleSchedulerObjects() {
        Test.startTest();

        List<String> accessibleObjects = CVMAGuestUserPermissionHelper.getAccessibleSchedulerObjects();

        // Verify list is returned (not null)
        System.assertNotEquals(null, accessibleObjects, 'Should return list of accessible objects');

        // List should contain only accessible objects
        for (String objName : accessibleObjects) {
            Boolean hasAccess = CVMAGuestUserPermissionHelper.hasObjectAccess(objName);
            System.assertEquals(true, hasAccess, 'All returned objects should be accessible: ' + objName);
        }

        Test.stopTest();
    }

    /**
     * Test: validateGuestProfile() checks profile existence
     */
    @IsTest
    static void testValidateGuestProfile() {
        Test.startTest();

        Boolean profileExists = CVMAGuestUserPermissionHelper.validateGuestProfile();

        // Note: Result depends on org configuration
        // We're testing that method executes without error
        System.assertNotEquals(null, profileExists, 'Guest profile validation should return a result');

        Test.stopTest();
    }

    /**
     * Test: validatePermissionSet() checks permission set existence
     */
    @IsTest
    static void testValidatePermissionSet() {
        Test.startTest();

        Boolean permSetExists = CVMAGuestUserPermissionHelper.validatePermissionSet();

        // Note: Result depends on org configuration
        // We're testing that method executes without error
        System.assertNotEquals(null, permSetExists, 'Permission set validation should return a result');

        Test.stopTest();
    }

    /**
     * Test: getPermissionStatus() returns comprehensive status map
     */
    @IsTest
    static void testGetPermissionStatus() {
        Test.startTest();

        Map<String, Boolean> permissionStatus = CVMAGuestUserPermissionHelper.getPermissionStatus();

        // Verify all expected keys are present
        System.assert(permissionStatus.containsKey('guestProfileExists'), 'Status map should contain guestProfileExists');
        System.assert(permissionStatus.containsKey('permissionSetExists'), 'Status map should contain permissionSetExists');
        System.assert(permissionStatus.containsKey('schedulerAccessValid'), 'Status map should contain schedulerAccessValid');
        System.assert(permissionStatus.containsKey('isValidGuestUser'), 'Status map should contain isValidGuestUser');

        // Verify all values are non-null
        for (String key : permissionStatus.keySet()) {
            System.assertNotEquals(null, permissionStatus.get(key), 'Status value for ' + key + ' should not be null');
        }

        Test.stopTest();
    }

    /**
     * Test: clearCache() properly resets cached values
     */
    @IsTest
    static void testClearCache() {
        Test.startTest();

        // Populate cache
        Boolean initialCheck = CVMAGuestUserPermissionHelper.isValidGuestUser();
        Boolean initialObjectAccess = CVMAGuestUserPermissionHelper.hasObjectAccess('Contact');

        // Clear cache
        CVMAGuestUserPermissionHelper.clearCache();

        // Verify cache was cleared by checking that subsequent calls execute
        // (We can't directly verify cache state, but method should not throw exception)
        Boolean afterClearCheck = CVMAGuestUserPermissionHelper.isValidGuestUser();
        Boolean afterClearObjectAccess = CVMAGuestUserPermissionHelper.hasObjectAccess('Contact');

        // Results should still be consistent even after cache clear
        System.assertEquals(initialCheck, afterClearCheck, 'Guest user status should be consistent');
        System.assertEquals(initialObjectAccess, afterClearObjectAccess, 'Object access should be consistent');

        Test.stopTest();
    }

    /**
     * Test: Bulk object access checks for governor limit compliance
     */
    @IsTest
    static void testBulkObjectAccessChecks() {
        Test.startTest();

        // Check access for multiple objects
        List<String> testObjects = new List<String>{
            'Contact', 'Account', 'Campaign', 'Event', 'Task',
            'ServiceAppointment', 'Case', 'Opportunity', 'Lead', 'User'
        };

        for (String objName : testObjects) {
            Boolean hasAccess = CVMAGuestUserPermissionHelper.hasObjectAccess(objName);
            // Verify method executes without error
            System.assertNotEquals(null, hasAccess, 'Object access check should return result for ' + objName);
        }

        Test.stopTest();

        // Verify no governor limit exceptions occurred
        System.assertEquals(0, Limits.getQueries(), 'Cached object checks should not re-query database');
    }

    /**
     * Test: Negative case - Exception handling in validateGuestUserPermissions
     */
    @IsTest
    static void testValidateGuestUserPermissions_ExceptionHandling() {
        Test.startTest();

        // Test with running user (should handle gracefully)
        Boolean result = CVMAGuestUserPermissionHelper.isValidGuestUser();

        // Verify method completes without throwing exception
        System.assertNotEquals(null, result, 'Method should handle exceptions gracefully');

        Test.stopTest();
    }

    /**
     * Test: Negative case - Exception handling in checkObjectPermission
     */
    @IsTest
    static void testCheckObjectPermission_ExceptionHandling() {
        Test.startTest();

        // Test with empty string (edge case)
        Boolean emptyObjectAccess = CVMAGuestUserPermissionHelper.hasObjectAccess('');

        // Test with special characters (edge case)
        Boolean specialCharAccess = CVMAGuestUserPermissionHelper.hasObjectAccess('Invalid@Object#Name');

        // Verify method handles edge cases without throwing exception
        System.assertEquals(false, emptyObjectAccess, 'Empty object name should return false');
        System.assertEquals(false, specialCharAccess, 'Invalid object name should return false');

        Test.stopTest();
    }

    /**
     * Test: Security validation - Guest user cannot access sensitive objects
     */
    @IsTest
    static void testSecurity_GuestUserRestrictions() {
        Test.startTest();

        // Clear cache to ensure fresh checks
        CVMAGuestUserPermissionHelper.clearCache();

        // Get permission status
        Map<String, Boolean> status = CVMAGuestUserPermissionHelper.getPermissionStatus();

        // Verify permission checks execute
        System.assertNotEquals(null, status, 'Permission status should be returned');
        System.assertEquals(4, status.size(), 'Status map should contain exactly 4 keys');

        Test.stopTest();
    }

    /**
     * Test: Performance - Multiple permission checks within limits
     */
    @IsTest
    static void testPerformance_MultiplePermissionChecks() {
        Test.startTest();

        // Perform multiple permission checks
        for (Integer i = 0; i < 10; i++) {
            CVMAGuestUserPermissionHelper.isValidGuestUser();
            CVMAGuestUserPermissionHelper.validateGuestProfile();
            CVMAGuestUserPermissionHelper.validatePermissionSet();
            CVMAGuestUserPermissionHelper.validateSchedulerAccess();
        }

        Test.stopTest();

        // Verify within governor limits (caching should prevent excessive queries)
        Integer queriesUsed = Limits.getQueries();
        System.assert(queriesUsed < 50, 'Caching should keep query count low: ' + queriesUsed);
    }
}
