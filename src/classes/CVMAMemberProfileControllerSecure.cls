/**
 * Enhanced controller for CVMA Member Profile management with comprehensive security
 * Implements Salesforce best practices for security, error handling, and validation
 * Version 2.0 - Enhanced with CVMAErrorHandler integration
 */
public with sharing class CVMAMemberProfileControllerSecure {
    
    // Class constants for better maintainability
    private static final String CLASS_NAME = 'CVMAMemberProfileControllerSecure';
    private static final List<String> USER_FIELDS = new List<String>{
        'FirstName', 'LastName', 'Email', 'Phone', 'MobilePhone'
    };
    private static final List<String> CONTACT_FIELDS = new List<String>{
        'Phone', 'MobilePhone', 'Email', 'MailingStreet', 'MailingCity', 
        'MailingState', 'MailingPostalCode', 'MailingCountry'
    };
    
    /**
     * Get current user's profile information including Contact details
     */
    @AuraEnabled(cacheable=true)
    public static MemberProfileData getMemberProfile() {
        final String METHOD_NAME = 'getMemberProfile';
        
        try {
            Id userId = UserInfo.getUserId();
            
            // Validate CRUD permissions
            CVMAErrorHandler.validateCRUDPermissions(User.SObjectType, USER_FIELDS, 'read');
            CVMAErrorHandler.validateCRUDPermissions(Contact.SObjectType, CONTACT_FIELDS, 'read');
            
            // Get User information with Contact relationship using WITH SECURITY_ENFORCED
            List<User> users = [
                SELECT Id, FirstName, LastName, Email, Phone, MobilePhone, ContactId, UserType,
                       Contact.Id, Contact.Phone, Contact.MobilePhone, Contact.Email,
                       Contact.MailingStreet, Contact.MailingCity, Contact.MailingState,
                       Contact.MailingPostalCode, Contact.MailingCountry,
                       Contact.Membership_Id__c, Contact.Road_Name__c, Contact.Level__c
                FROM User 
                WHERE Id = :userId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (users.isEmpty()) {
                throw new CVMAErrorHandler.SecurityException('User not found or access denied');
            }
            
            User currentUser = users[0];
            
            // Prevent guest users from accessing profile
            if (currentUser.UserType == 'Guest') {
                Map<String, Object> context = new Map<String, Object>{
                    'userId' => userId,
                    'userType' => currentUser.UserType
                };
                CVMAErrorHandler.logError(
                    new CVMAErrorHandler.SecurityException('Guest user profile access attempt'),
                    CLASS_NAME, METHOD_NAME, CVMAErrorHandler.Severity.HIGH, 
                    CVMAErrorHandler.Category.SECURITY, context
                );
                throw new AuraHandledException('Guest users cannot access member profiles.');
            }
            
            MemberProfileData profileData = new MemberProfileData();
            profileData.userId = currentUser.Id;
            profileData.contactId = currentUser.ContactId;
            profileData.firstName = CVMAErrorHandler.sanitizeInput(currentUser.FirstName);
            profileData.lastName = CVMAErrorHandler.sanitizeInput(currentUser.LastName);
            profileData.email = currentUser.Email;
            profileData.phone = currentUser.Phone;
            profileData.mobilePhone = currentUser.MobilePhone;
            
            // Contact information (if available)
            if (currentUser.Contact != null) {
                profileData.contactPhone = currentUser.Contact.Phone;
                profileData.contactMobilePhone = currentUser.Contact.MobilePhone;
                profileData.contactEmail = currentUser.Contact.Email;
                profileData.mailingStreet = CVMAErrorHandler.sanitizeInput(currentUser.Contact.MailingStreet);
                profileData.mailingCity = CVMAErrorHandler.sanitizeInput(currentUser.Contact.MailingCity);
                profileData.mailingState = CVMAErrorHandler.sanitizeInput(currentUser.Contact.MailingState);
                profileData.mailingPostalCode = currentUser.Contact.MailingPostalCode;
                profileData.mailingCountry = CVMAErrorHandler.sanitizeInput(currentUser.Contact.MailingCountry);
                profileData.membershipId = currentUser.Contact.Membership_Id__c;
                profileData.roadName = CVMAErrorHandler.sanitizeInput(currentUser.Contact.Road_Name__c);
                profileData.memberLevel = CVMAErrorHandler.sanitizeInput(currentUser.Contact.Level__c);
            }
            
            return profileData;
            
        } catch (Exception ex) {
            String errorMessage = CVMAErrorHandler.handleException(
                ex, CLASS_NAME, METHOD_NAME, CVMAErrorHandler.Category.SECURITY
            );
            throw new AuraHandledException(errorMessage);
        }
    }
    
    /**
     * Update member profile information with comprehensive validation
     */
    @AuraEnabled
    public static String updateMemberProfile(String profileDataJson) {
        final String METHOD_NAME = 'updateMemberProfile';
        
        try {
            // Input validation
            if (String.isBlank(profileDataJson)) {
                throw new CVMAErrorHandler.ValidationException('Profile data cannot be empty');
            }
            
            MemberProfileData profileData;
            try {
                profileData = (MemberProfileData) JSON.deserialize(profileDataJson, MemberProfileData.class);
            } catch (Exception jsonEx) {
                throw new CVMAErrorHandler.ValidationException('Invalid profile data format');
            }
            
            // Security validation - ensure user can only update their own profile
            Id currentUserId = UserInfo.getUserId();
            if (profileData.userId != currentUserId) {
                Map<String, Object> context = new Map<String, Object>{
                    'requestedUserId' => profileData.userId,
                    'currentUserId' => currentUserId
                };
                CVMAErrorHandler.logError(
                    new CVMAErrorHandler.SecurityException('Unauthorized profile update attempt'),
                    CLASS_NAME, METHOD_NAME, CVMAErrorHandler.Severity.HIGH, 
                    CVMAErrorHandler.Category.SECURITY, context
                );
                throw new AuraHandledException('You can only update your own profile');
            }
            
            // Validate required fields
            if (String.isBlank(profileData.firstName) || String.isBlank(profileData.lastName)) {
                throw new CVMAErrorHandler.ValidationException('First name and last name are required fields');
            }
            
            // Validate email format
            if (String.isNotBlank(profileData.email) && !CVMAErrorHandler.isValidEmail(profileData.email)) {
                throw new CVMAErrorHandler.ValidationException('Please enter a valid email address');
            }
            
            // Sanitize all input data
            profileData.firstName = CVMAErrorHandler.sanitizeInput(profileData.firstName);
            profileData.lastName = CVMAErrorHandler.sanitizeInput(profileData.lastName);
            profileData.mailingStreet = CVMAErrorHandler.sanitizeInput(profileData.mailingStreet);
            profileData.mailingCity = CVMAErrorHandler.sanitizeInput(profileData.mailingCity);
            profileData.mailingState = CVMAErrorHandler.sanitizeInput(profileData.mailingState);
            profileData.mailingCountry = CVMAErrorHandler.sanitizeInput(profileData.mailingCountry);
            profileData.roadName = CVMAErrorHandler.sanitizeInput(profileData.roadName);
            
            // Validate CRUD permissions before updates
            CVMAErrorHandler.validateCRUDPermissions(User.SObjectType, USER_FIELDS, 'update');
            if (profileData.contactId != null) {
                CVMAErrorHandler.validateCRUDPermissions(Contact.SObjectType, CONTACT_FIELDS, 'update');
            }
            
            // Start transaction for atomic updates
            Savepoint sp = Database.setSavepoint();
            
            try {
                // Update User record
                User userToUpdate = new User(
                    Id = profileData.userId,
                    FirstName = profileData.firstName,
                    LastName = profileData.lastName,
                    Email = profileData.email,
                    Phone = profileData.phone,
                    MobilePhone = profileData.mobilePhone
                );
                
                Database.SaveResult userResult = Database.update(userToUpdate, false);
                if (!userResult.isSuccess()) {
                    throw new DmlException('User update failed: ' + userResult.getErrors()[0].getMessage());
                }
                
                // Update Contact record if exists
                if (profileData.contactId != null) {
                    Contact contactToUpdate = new Contact(
                        Id = profileData.contactId,
                        Phone = profileData.contactPhone,
                        MobilePhone = profileData.contactMobilePhone,
                        Email = profileData.contactEmail,
                        MailingStreet = profileData.mailingStreet,
                        MailingCity = profileData.mailingCity,
                        MailingState = profileData.mailingState,
                        MailingPostalCode = profileData.mailingPostalCode,
                        MailingCountry = profileData.mailingCountry,
                        Road_Name__c = profileData.roadName
                    );
                    
                    Database.SaveResult contactResult = Database.update(contactToUpdate, false);
                    if (!contactResult.isSuccess()) {
                        throw new DmlException('Contact update failed: ' + contactResult.getErrors()[0].getMessage());
                    }
                }
                
                // Log successful update
                Map<String, Object> context = new Map<String, Object>{
                    'userId' => profileData.userId,
                    'contactId' => profileData.contactId,
                    'operation' => 'profile_update'
                };
                System.debug(LoggingLevel.INFO, 'Profile updated successfully for user: ' + profileData.userId);
                
                return 'Profile updated successfully';
                
            } catch (Exception updateEx) {
                Database.rollback(sp);
                throw updateEx;
            }
            
        } catch (Exception ex) {
            Map<String, Object> context = new Map<String, Object>{
                'profileDataJson' => profileDataJson?.length() > 1000 ? 
                    profileDataJson.substring(0, 1000) + '...' : profileDataJson
            };
            String errorMessage = CVMAErrorHandler.handleException(
                ex, CLASS_NAME, METHOD_NAME, CVMAErrorHandler.Severity.MEDIUM, 
                CVMAErrorHandler.Category.DATA_VALIDATION, context
            );
            throw new AuraHandledException(errorMessage);
        }
    }
    
    /**
     * Get profile permissions for current user
     */
    @AuraEnabled(cacheable=true)
    public static ProfilePermissions getProfilePermissions() {
        final String METHOD_NAME = 'getProfilePermissions';
        
        try {
            ProfilePermissions permissions = new ProfilePermissions();
            
            // Check User object permissions
            permissions.canEditProfile = User.SObjectType.getDescribe().isUpdateable();
            
            // Check Contact object permissions
            permissions.canEditContact = Contact.SObjectType.getDescribe().isUpdateable();
            
            // Check specific field permissions
            permissions.canViewMembershipInfo = 
                Schema.sObjectType.Contact.fields.Membership_Id__c.isAccessible() &&
                Schema.sObjectType.Contact.fields.Road_Name__c.isAccessible();
            
            // Check if user has Contact record
            List<User> currentUser = [
                SELECT ContactId 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            permissions.hasContactRecord = !currentUser.isEmpty() && currentUser[0].ContactId != null;
            
            return permissions;
            
        } catch (Exception ex) {
            String errorMessage = CVMAErrorHandler.handleException(
                ex, CLASS_NAME, METHOD_NAME, CVMAErrorHandler.Category.SECURITY
            );
            throw new AuraHandledException(errorMessage);
        }
    }
    
    /**
     * Data wrapper classes with enhanced validation
     */
    public class MemberProfileData {
        @AuraEnabled public Id userId { get; set; }
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String mobilePhone { get; set; }
        @AuraEnabled public String contactPhone { get; set; }
        @AuraEnabled public String contactMobilePhone { get; set; }
        @AuraEnabled public String contactEmail { get; set; }
        @AuraEnabled public String mailingStreet { get; set; }
        @AuraEnabled public String mailingCity { get; set; }
        @AuraEnabled public String mailingState { get; set; }
        @AuraEnabled public String mailingPostalCode { get; set; }
        @AuraEnabled public String mailingCountry { get; set; }
        @AuraEnabled public String membershipId { get; set; }
        @AuraEnabled public String roadName { get; set; }
        @AuraEnabled public String memberLevel { get; set; }
        
        // Additional validation methods
        public Boolean isValid() {
            return String.isNotBlank(firstName) && String.isNotBlank(lastName) &&
                   (String.isBlank(email) || CVMAErrorHandler.isValidEmail(email));
        }
    }
    
    public class ProfilePermissions {
        @AuraEnabled public Boolean canEditProfile { get; set; }
        @AuraEnabled public Boolean canEditContact { get; set; }
        @AuraEnabled public Boolean canViewMembershipInfo { get; set; }
        @AuraEnabled public Boolean hasContactRecord { get; set; }
        
        public ProfilePermissions() {
            this.canEditProfile = false;
            this.canEditContact = false;
            this.canViewMembershipInfo = false;
            this.hasContactRecord = false;
        }
    }
}