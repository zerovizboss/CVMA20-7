/**
 * Helper class for CVMA Guest User permission validation and utility methods
 * Provides centralized logic for guest user access to Scheduler functionality
 */
public class CVMAGuestUserPermissionHelper {
    
    // Constants for permission validation
    public static final String GUEST_PROFILE_NAME = 'Guest License User';
    public static final String PERMISSION_SET_NAME = 'CVMA_Guest_Scheduler_Access';
    
    // Static cache for permission checks
    private static Map<String, Boolean> objectPermissionCache = new Map<String, Boolean>();
    private static Boolean isGuestUserCacheInitialized = false;
    private static Boolean cachedGuestUserStatus = false;
    
    /**
     * Validates if current user is a guest user with proper permissions
     */
    public static Boolean isValidGuestUser() {
        if (!isGuestUserCacheInitialized) {
            cachedGuestUserStatus = validateGuestUserPermissions();
            isGuestUserCacheInitialized = true;
        }
        return cachedGuestUserStatus;
    }
    
    /**
     * Checks if guest user has access to specific object
     */
    public static Boolean hasObjectAccess(String objectName) {
        if (objectPermissionCache.containsKey(objectName)) {
            return objectPermissionCache.get(objectName);
        }
        
        Boolean hasAccess = checkObjectPermission(objectName);
        objectPermissionCache.put(objectName, hasAccess);
        return hasAccess;
    }
    
    /**
     * Validates guest user permissions for scheduler objects
     */
    public static Boolean validateSchedulerAccess() {
        List<String> requiredObjects = new List<String>{
            'ServiceAppointment',
            'ServiceTerritory', 
            'WorkType',
            'OperatingHours'
        };
        
        for (String objName : requiredObjects) {
            if (!hasObjectAccess(objName)) {
                return false;
            }
        }
        return true;
    }
    
    /**
     * Gets list of accessible scheduler objects for guest user
     */
    public static List<String> getAccessibleSchedulerObjects() {
        List<String> allObjects = new List<String>{
            'ServiceAppointment',
            'ServiceTerritory',
            'WorkType', 
            'OperatingHours',
            'ServiceResource',
            'Event',
            'Case'
        };
        
        List<String> accessibleObjects = new List<String>();
        for (String objName : allObjects) {
            if (hasObjectAccess(objName)) {
                accessibleObjects.add(objName);
            }
        }
        return accessibleObjects;
    }
    
    /**
     * Validates if guest user profile exists and is configured
     */
    public static Boolean validateGuestProfile() {
        try {
            List<Profile> guestProfiles = [
                SELECT Id, Name 
                FROM Profile 
                WHERE Name = :GUEST_PROFILE_NAME 
                LIMIT 1
            ];
            return !guestProfiles.isEmpty();
        } catch (Exception e) {
            System.debug('Error validating guest profile: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Checks if custom permission set exists
     */
    public static Boolean validatePermissionSet() {
        try {
            List<PermissionSet> permSets = [
                SELECT Id, Name, Label
                FROM PermissionSet 
                WHERE Name = :PERMISSION_SET_NAME 
                LIMIT 1
            ];
            return !permSets.isEmpty();
        } catch (Exception e) {
            System.debug('Permission set validation error: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Gets permission validation results as a map
     */
    public static Map<String, Boolean> getPermissionStatus() {
        Map<String, Boolean> status = new Map<String, Boolean>();
        
        status.put('guestProfileExists', validateGuestProfile());
        status.put('permissionSetExists', validatePermissionSet());
        status.put('schedulerAccessValid', validateSchedulerAccess());
        status.put('isValidGuestUser', isValidGuestUser());
        
        return status;
    }
    
    /**
     * Clears permission cache (useful for testing)
     */
    public static void clearCache() {
        objectPermissionCache.clear();
        isGuestUserCacheInitialized = false;
        cachedGuestUserStatus = false;
    }
    
    // Private helper methods
    
    /**
     * Validates guest user permissions
     */
    private static Boolean validateGuestUserPermissions() {
        try {
            User currentUser = [SELECT Id, ProfileId, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            return currentUser.Profile.Name == GUEST_PROFILE_NAME;
        } catch (Exception e) {
            System.debug('Guest user validation error: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Checks object permission using describe calls
     */
    private static Boolean checkObjectPermission(String objectName) {
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType == null) {
                return false;
            }
            
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            return objDescribe.accessible;
        } catch (Exception e) {
            System.debug('Object permission check error for ' + objectName + ': ' + e.getMessage());
            return false;
        }
    }
}