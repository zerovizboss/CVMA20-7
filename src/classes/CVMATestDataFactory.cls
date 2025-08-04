/**
 * Test Data Factory for CVMA application
 * Provides standardized test data creation methods following Salesforce best practices
 * Implements builder pattern for flexible test data configuration
 */
@IsTest
public class CVMATestDataFactory {
    
    // Constants for default values
    private static final String DEFAULT_FIRST_NAME = 'Test';
    private static final String DEFAULT_LAST_NAME = 'Member';
    private static final String DEFAULT_EMAIL_DOMAIN = '@cvma-test.org';
    private static final String DEFAULT_PHONE = '(904) 555-0000';
    private static final String DEFAULT_STREET = '123 Test Street';
    private static final String DEFAULT_CITY = 'Jacksonville';
    private static final String DEFAULT_STATE = 'FL';
    private static final String DEFAULT_POSTAL_CODE = '32204';
    private static final String DEFAULT_COUNTRY = 'United States';
    
    // Static counters for unique data generation
    private static Integer userCounter = 0;
    private static Integer contactCounter = 0;
    private static Integer accountCounter = 0;
    
    /**
     * Contact Builder Class
     */
    public class ContactBuilder {
        private Contact contact;
        
        public ContactBuilder() {
            contactCounter++;
            this.contact = new Contact(
                FirstName = DEFAULT_FIRST_NAME + contactCounter,
                LastName = DEFAULT_LAST_NAME + contactCounter,
                Email = 'testmember' + contactCounter + DEFAULT_EMAIL_DOMAIN,
                Phone = DEFAULT_PHONE,
                MobilePhone = DEFAULT_PHONE,
                MailingStreet = DEFAULT_STREET,
                MailingCity = DEFAULT_CITY,
                MailingState = DEFAULT_STATE,
                MailingPostalCode = DEFAULT_POSTAL_CODE,
                MailingCountry = DEFAULT_COUNTRY,
                Membership_Id__c = generateMembershipId(contactCounter),
                Level__c = 'Full Member',
                Road_Name__c = 'Test Rider ' + contactCounter,
                npo02__MembershipJoinDate__c = Date.today().addMonths(-12),
                npo02__MembershipEndDate__c = Date.today().addMonths(12),
                npo02__LastMembershipAmount__c = 50.00,
                npo02__LastMembershipDate__c = Date.today().addMonths(-12)
            );
        }
        
        public ContactBuilder withFirstName(String firstName) {
            this.contact.FirstName = firstName;
            return this;
        }
        
        public ContactBuilder withLastName(String lastName) {
            this.contact.LastName = lastName;
            return this;
        }
        
        public ContactBuilder withEmail(String email) {
            this.contact.Email = email;
            return this;
        }
        
        public ContactBuilder withPhone(String phone) {
            this.contact.Phone = phone;
            this.contact.MobilePhone = phone;
            return this;
        }
        
        public ContactBuilder withMembershipId(String membershipId) {
            this.contact.Membership_Id__c = membershipId;
            return this;
        }
        
        public ContactBuilder withLevel(String level) {
            this.contact.Level__c = level;
            return this;
        }
        
        public ContactBuilder withRoadName(String roadName) {
            this.contact.Road_Name__c = roadName;
            return this;
        }
        
        public ContactBuilder withMembershipDates(Date joinDate, Date endDate) {
            this.contact.npo02__MembershipJoinDate__c = joinDate;
            this.contact.npo02__MembershipEndDate__c = endDate;
            return this;
        }
        
        public ContactBuilder withExpiredMembership() {
            this.contact.npo02__MembershipEndDate__c = Date.today().addDays(-30);
            return this;
        }
        
        public ContactBuilder withExpiringMembership() {
            this.contact.npo02__MembershipEndDate__c = Date.today().addDays(15);
            return this;
        }
        
        public ContactBuilder withNewMembership() {
            this.contact.npo02__MembershipJoinDate__c = Date.today().addDays(-15);
            this.contact.npo02__MembershipEndDate__c = Date.today().addMonths(12);
            return this;
        }
        
        public ContactBuilder withMailingAddress(String street, String city, String state, String postalCode) {
            this.contact.MailingStreet = street;
            this.contact.MailingCity = city;
            this.contact.MailingState = state;
            this.contact.MailingPostalCode = postalCode;
            return this;
        }
        
        public ContactBuilder withAccount(Id accountId) {
            this.contact.AccountId = accountId;
            return this;
        }
        
        public Contact build() {
            return this.contact;
        }
        
        public Contact create() {
            insert this.contact;
            return this.contact;
        }
    }
    
    /**
     * User Builder Class
     */
    public class UserBuilder {
        private User user;
        private Contact relatedContact;
        
        public UserBuilder() {
            userCounter++;
            this.user = new User(
                FirstName = DEFAULT_FIRST_NAME + userCounter,
                LastName = DEFAULT_LAST_NAME + userCounter,
                Email = 'testuser' + userCounter + DEFAULT_EMAIL_DOMAIN,
                Username = 'testuser' + userCounter + DEFAULT_EMAIL_DOMAIN,
                Alias = 'tuser' + userCounter,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                Phone = DEFAULT_PHONE,
                MobilePhone = DEFAULT_PHONE,
                ProfileId = getStandardUserProfileId()
            );
        }
        
        public UserBuilder withFirstName(String firstName) {
            this.user.FirstName = firstName;
            return this;
        }
        
        public UserBuilder withLastName(String lastName) {
            this.user.LastName = lastName;
            return this;
        }
        
        public UserBuilder withEmail(String email) {
            this.user.Email = email;
            this.user.Username = email;
            return this;
        }
        
        public UserBuilder withProfileId(Id profileId) {
            this.user.ProfileId = profileId;
            return this;
        }
        
        public UserBuilder withContact(Contact contact) {
            this.relatedContact = contact;
            return this;
        }
        
        public UserBuilder asSystemAdmin() {
            this.user.ProfileId = getSystemAdminProfileId();
            return this;
        }
        
        public UserBuilder asCommunityUser() {
            this.user.ProfileId = getCommunityProfileId();
            return this;
        }
        
        public User build() {
            return this.user;
        }
        
        public User create() {
            if (this.relatedContact != null && this.relatedContact.Id == null) {
                insert this.relatedContact;
            }
            
            if (this.relatedContact != null) {
                this.user.ContactId = this.relatedContact.Id;
            }
            
            insert this.user;
            return this.user;
        }
    }
    
    /**
     * Account Builder Class
     */
    public class AccountBuilder {
        private Account account;
        
        public AccountBuilder() {
            accountCounter++;
            this.account = new Account(
                Name = 'Test Account ' + accountCounter,
                Type = 'Customer',
                BillingStreet = DEFAULT_STREET,
                BillingCity = DEFAULT_CITY,
                BillingState = DEFAULT_STATE,
                BillingPostalCode = DEFAULT_POSTAL_CODE,
                BillingCountry = DEFAULT_COUNTRY,
                Phone = DEFAULT_PHONE
            );
        }
        
        public AccountBuilder withName(String name) {
            this.account.Name = name;
            return this;
        }
        
        public AccountBuilder withType(String accountType) {
            this.account.Type = accountType;
            return this;
        }
        
        public AccountBuilder withBillingAddress(String street, String city, String state, String postalCode) {
            this.account.BillingStreet = street;
            this.account.BillingCity = city;
            this.account.BillingState = state;
            this.account.BillingPostalCode = postalCode;
            return this;
        }
        
        public Account build() {
            return this.account;
        }
        
        public Account create() {
            insert this.account;
            return this.account;
        }
    }
    
    /**
     * Static factory methods
     */
    public static ContactBuilder createContact() {
        return new ContactBuilder();
    }
    
    public static UserBuilder createUser() {
        return new UserBuilder();
    }
    
    public static AccountBuilder createAccount() {
        return new AccountBuilder();
    }
    
    /**
     * Bulk data creation methods
     */
    public static List<Contact> createContacts(Integer count) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            contacts.add(createContact().build());
        }
        return contacts;
    }
    
    public static List<Contact> createAndInsertContacts(Integer count) {
        List<Contact> contacts = createContacts(count);
        insert contacts;
        return contacts;
    }
    
    public static List<User> createUsers(Integer count) {
        List<User> users = new List<User>();
        for (Integer i = 0; i < count; i++) {
            users.add(createUser().build());
        }
        return users;
    }
    
    /**
     * Specialized contact creation methods
     */
    public static List<Contact> createMembersWithVariousStatuses(Integer totalCount) {
        List<Contact> contacts = new List<Contact>();
        
        Integer activeCount = (Integer) Math.floor(totalCount * 0.6);
        Integer expiringCount = (Integer) Math.floor(totalCount * 0.2);
        Integer expiredCount = (Integer) Math.floor(totalCount * 0.1);
        Integer newCount = totalCount - activeCount - expiringCount - expiredCount;
        
        // Active members
        for (Integer i = 0; i < activeCount; i++) {
            contacts.add(createContact().build());
        }
        
        // Expiring members
        for (Integer i = 0; i < expiringCount; i++) {
            contacts.add(createContact().withExpiringMembership().build());
        }
        
        // Expired members
        for (Integer i = 0; i < expiredCount; i++) {
            contacts.add(createContact().withExpiredMembership().build());
        }
        
        // New members
        for (Integer i = 0; i < newCount; i++) {
            contacts.add(createContact().withNewMembership().build());
        }
        
        return contacts;
    }
    
    public static List<Contact> createAndInsertMembersWithVariousStatuses(Integer totalCount) {
        List<Contact> contacts = createMembersWithVariousStatuses(totalCount);
        insert contacts;
        return contacts;
    }
    
    /**
     * Create users with associated contacts for community testing
     */
    public static List<User> createCommunityUsersWithContacts(Integer count) {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        List<User> users = new List<User>();
        
        // Create accounts first
        for (Integer i = 0; i < count; i++) {
            accounts.add(createAccount().build());
        }
        insert accounts;
        
        // Create contacts associated with accounts
        for (Integer i = 0; i < count; i++) {
            contacts.add(createContact().withAccount(accounts[i].Id).build());
        }
        insert contacts;
        
        // Create community users associated with contacts
        for (Integer i = 0; i < count; i++) {
            users.add(createUser()
                .asCommunityUser()
                .withContact(contacts[i])
                .build());
        }
        
        return users;
    }
    
    /**
     * Create test error log records
     */
    public static List<CVMA_Error_Log__c> createErrorLogs(Integer count) {
        List<CVMA_Error_Log__c> errorLogs = new List<CVMA_Error_Log__c>();
        
        for (Integer i = 0; i < count; i++) {
            String severity = Math.mod(i, 2) == 0 ? 'HIGH' : 'MEDIUM';
            String category = Math.mod(i, 3) == 0 ? 'SECURITY' : 'DATA_VALIDATION';
            
            errorLogs.add(new CVMA_Error_Log__c(
                Class_Name__c = 'TestClass' + i,
                Method_Name__c = 'testMethod' + i,
                Error_Message__c = 'Test error message ' + i,
                Stack_Trace__c = 'Test stack trace for error ' + i,
                Severity__c = severity,
                Category__c = category,
                User__c = UserInfo.getUserId(),
                Context_Data__c = '{"testData": "value' + i + '"}'
            ));
        }
        
        return errorLogs;
    }
    
    public static List<CVMA_Error_Log__c> createAndInsertErrorLogs(Integer count) {
        List<CVMA_Error_Log__c> errorLogs = createErrorLogs(count);
        insert errorLogs;
        return errorLogs;
    }
    
    /**
     * Utility methods
     */
    private static String generateMembershipId(Integer sequence) {
        // Generate membership ID per validation rule: FM+1-5 digits (3-8 chars total)
        return 'FM' + String.valueOf(sequence).leftPad(3, '0'); // Format: FMXXX (max 5 digits)
    }
    
    private static Id getStandardUserProfileId() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return profiles.isEmpty() ? null : profiles[0].Id;
    }
    
    private static Id getSystemAdminProfileId() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        return profiles.isEmpty() ? getStandardUserProfileId() : profiles[0].Id;
    }
    
    private static Id getCommunityProfileId() {
        // Try to find a community profile, fallback to standard user
        List<Profile> profiles = [
            SELECT Id 
            FROM Profile 
            WHERE Name LIKE '%Community%' 
            OR Name LIKE '%Customer%' 
            OR Name LIKE '%Partner%'
            LIMIT 1
        ];
        return profiles.isEmpty() ? getStandardUserProfileId() : profiles[0].Id;
    }
    
    /**
     * Setup method for common test data
     */
    public static TestDataBundle setupBasicTestData() {
        TestDataBundle bundle = new TestDataBundle();
        
        // Create test account
        bundle.testAccount = createAccount().create();
        
        // Create test contacts with various statuses
        bundle.activeContacts = new List<Contact>();
        bundle.expiringContacts = new List<Contact>();
        bundle.expiredContacts = new List<Contact>();
        
        // Create 5 active members
        for (Integer i = 0; i < 5; i++) {
            bundle.activeContacts.add(createContact()
                .withAccount(bundle.testAccount.Id)
                .create());
        }
        
        // Create 3 expiring members
        for (Integer i = 0; i < 3; i++) {
            bundle.expiringContacts.add(createContact()
                .withAccount(bundle.testAccount.Id)
                .withExpiringMembership()
                .create());
        }
        
        // Create 2 expired members
        for (Integer i = 0; i < 2; i++) {
            bundle.expiredContacts.add(createContact()
                .withAccount(bundle.testAccount.Id)
                .withExpiredMembership()
                .create());
        }
        
        // Create test users
        bundle.adminUser = createUser().asSystemAdmin().create();
        bundle.standardUser = createUser().withContact(bundle.activeContacts[0]).create();
        
        return bundle;
    }
    
    /**
     * Data bundle class for organized test data
     */
    public class TestDataBundle {
        public Account testAccount { get; set; }
        public List<Contact> activeContacts { get; set; }
        public List<Contact> expiringContacts { get; set; }
        public List<Contact> expiredContacts { get; set; }
        public User adminUser { get; set; }
        public User standardUser { get; set; }
        
        public TestDataBundle() {
            this.activeContacts = new List<Contact>();
            this.expiringContacts = new List<Contact>();
            this.expiredContacts = new List<Contact>();
        }
        
        public List<Contact> getAllContacts() {
            List<Contact> allContacts = new List<Contact>();
            allContacts.addAll(activeContacts);
            allContacts.addAll(expiringContacts);
            allContacts.addAll(expiredContacts);
            return allContacts;
        }
    }
}