/**
 * Enhanced controller for CVMA Member Profile management
 * Provides secure access to member profile information and updates
 * Supports both User and Contact record updates with proper validation
 */
public with sharing class CVMAMemberProfileController {
    
    /**
     * Get current user's profile information including Contact details
     */
    @AuraEnabled(cacheable=true)
    public static MemberProfileData getMemberProfile() {
        try {
            Id userId = UserInfo.getUserId();
            
            // Get User information with Contact relationship
            User currentUser = [
                SELECT Id, FirstName, LastName, Email, Phone, MobilePhone, ContactId,
                       Contact.Id, Contact.Phone, Contact.MobilePhone, Contact.Email,
                       Contact.MailingStreet, Contact.MailingCity, Contact.MailingState,
                       Contact.MailingPostalCode, Contact.MailingCountry,
                       Contact.Membership_Id__c, Contact.Road_Name__c
                FROM User 
                WHERE Id = :userId 
                LIMIT 1
            ];
            
            // Prevent guest users from accessing profile
            if (currentUser.UserType == 'Guest') {
                throw new AuraHandledException('Guest users cannot access member profiles.');
            }
            
            MemberProfileData profileData = new MemberProfileData();
            profileData.userId = currentUser.Id;
            profileData.contactId = currentUser.ContactId;
            profileData.firstName = currentUser.FirstName;
            profileData.lastName = currentUser.LastName;
            profileData.email = currentUser.Email;
            profileData.phone = currentUser.Phone;
            profileData.mobilePhone = currentUser.MobilePhone;
            
            // Contact information (if available)
            if (currentUser.Contact != null) {
                profileData.contactPhone = currentUser.Contact.Phone;
                profileData.contactMobilePhone = currentUser.Contact.MobilePhone;
                profileData.contactEmail = currentUser.Contact.Email;
                profileData.mailingStreet = currentUser.Contact.MailingStreet;
                profileData.mailingCity = currentUser.Contact.MailingCity;
                profileData.mailingState = currentUser.Contact.MailingState;
                profileData.mailingPostalCode = currentUser.Contact.MailingPostalCode;
                profileData.mailingCountry = currentUser.Contact.MailingCountry;
                profileData.membershipId = currentUser.Contact.Membership_Id__c;
                profileData.roadName = currentUser.Contact.Road_Name__c;
            }
            
            return profileData;
            
        } catch (QueryException e) {
            throw new AuraHandledException('Error retrieving profile information: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }
    
    /**
     * Update member profile information
     */
    @AuraEnabled
    public static String updateMemberProfile(String profileDataJson) {
        try {
            MemberProfileData profileData = (MemberProfileData) JSON.deserialize(profileDataJson, MemberProfileData.class);
            
            // Validate current user can update this profile
            Id currentUserId = UserInfo.getUserId();
            if (profileData.userId != currentUserId) {
                throw new AuraHandledException('You can only update your own profile.');
            }
            
            // Validate required fields
            if (String.isBlank(profileData.firstName) || String.isBlank(profileData.lastName) || String.isBlank(profileData.email)) {
                throw new AuraHandledException('First Name, Last Name, and Email are required fields.');
            }
            
            // Validate email format
            if (!isValidEmail(profileData.email)) {
                throw new AuraHandledException('Please enter a valid email address.');
            }
            
            List<SObject> recordsToUpdate = new List<SObject>();
            
            // Update User record
            User userRecord = new User(
                Id = profileData.userId,
                FirstName = profileData.firstName,
                LastName = profileData.lastName,
                Email = profileData.email,
                Phone = profileData.phone,
                MobilePhone = profileData.mobilePhone
            );
            recordsToUpdate.add(userRecord);
            
            // Update Contact record if available
            if (profileData.contactId != null) {
                Contact contactRecord = new Contact(
                    Id = profileData.contactId,
                    Phone = profileData.contactPhone,
                    MobilePhone = profileData.contactMobilePhone,
                    Email = profileData.contactEmail,
                    MailingStreet = profileData.mailingStreet,
                    MailingCity = profileData.mailingCity,
                    MailingState = profileData.mailingState,
                    MailingPostalCode = profileData.mailingPostalCode,
                    MailingCountry = profileData.mailingCountry
                );
                recordsToUpdate.add(contactRecord);
            }
            
            // Perform updates with proper error handling
            Database.SaveResult[] results = Database.update(recordsToUpdate, false);
            
            // Check for errors
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String errorMsg = 'Error updating ';
                    errorMsg += (i == 0) ? 'user information: ' : 'contact information: ';
                    for (Database.Error error : results[i].getErrors()) {
                        errorMsg += error.getMessage() + ' ';
                    }
                    throw new AuraHandledException(errorMsg);
                }
            }
            
            return 'Profile updated successfully';
            
        } catch (JSONException e) {
            throw new AuraHandledException('Invalid profile data format: ' + e.getMessage());
        } catch (DmlException e) {
            throw new AuraHandledException('Database error: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error updating profile: ' + e.getMessage());
        }
    }
    
    /**
     * Validate email format
     */
    private static Boolean isValidEmail(String email) {
        if (String.isBlank(email)) {
            return false;
        }
        
        // Basic email validation pattern
        String emailPattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        Pattern pat = Pattern.compile(emailPattern);
        Matcher matcher = pat.matcher(email);
        return matcher.matches();
    }
    
    /**
     * Get current user's permission level for profile management
     */
    @AuraEnabled(cacheable=true)
    public static ProfilePermissions getProfilePermissions() {
        ProfilePermissions permissions = new ProfilePermissions();
        
        try {
            // Check if user can edit their own profile
            permissions.canEditProfile = Schema.sObjectType.User.fields.FirstName.isUpdateable() &&
                                       Schema.sObjectType.User.fields.LastName.isUpdateable() &&
                                       Schema.sObjectType.User.fields.Email.isUpdateable();
            
            // Check if user can edit contact information
            permissions.canEditContact = Schema.sObjectType.Contact.fields.Phone.isUpdateable() &&
                                       Schema.sObjectType.Contact.fields.Email.isUpdateable() &&
                                       Schema.sObjectType.Contact.fields.MailingStreet.isUpdateable();
            
            // Check if user has access to CVMA-specific fields
            permissions.canViewMembershipInfo = Schema.sObjectType.Contact.fields.Membership_Id__c.isAccessible() &&
                                              Schema.sObjectType.Contact.fields.Road_Name__c.isAccessible();
            
            return permissions;
            
        } catch (Exception e) {
            // Default to restrictive permissions on error
            permissions.canEditProfile = false;
            permissions.canEditContact = false;
            permissions.canViewMembershipInfo = false;
            return permissions;
        }
    }
    
    /**
     * Data wrapper class for member profile information
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
    }
    
    /**
     * Data wrapper class for profile permissions
     */
    public class ProfilePermissions {
        @AuraEnabled public Boolean canEditProfile { get; set; }
        @AuraEnabled public Boolean canEditContact { get; set; }
        @AuraEnabled public Boolean canViewMembershipInfo { get; set; }
    }
}