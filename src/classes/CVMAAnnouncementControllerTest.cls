/**
 * @description Test class for CVMAAnnouncementController
 * @author Claude AI - CVMA Development Team
 * @date 2025-01-09
 */
@IsTest
private class CVMAAnnouncementControllerTest {
    
    private static Contact testOfficer;
    private static Contact testMember;
    private static User testOfficerUser;
    private static User testMemberUser;
    
    @TestSetup
    static void setupTestData() {
        // Create test contacts
        testOfficer = CVMATestDataFactory.createContact()
            .withFirstName('Test')
            .withLastName('Officer')
            .withLevel('Full Member')
            .withEmail('testofficer@cvma.test')
            .create();
            
        testMember = CVMATestDataFactory.createContact()
            .withFirstName('Test')
            .withLastName('Member')
            .withLevel('Associate Member') 
            .withEmail('testmember@cvma.test')
            .create();
        
        // Create test users and link to contacts
        Profile memberProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
        
        testOfficerUser = new User(
            FirstName = 'Test',
            LastName = 'Officer',
            Email = 'testofficer@cvma.test',
            Username = 'testofficer@cvma.test.user',
            Alias = 'toff',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = memberProfile.Id,
            ContactId = testOfficer.Id
        );
        insert testOfficerUser;
        
        testMemberUser = new User(
            FirstName = 'Test',
            LastName = 'Member',
            Email = 'testmember@cvma.test',
            Username = 'testmember@cvma.test.user',
            Alias = 'tmem',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = memberProfile.Id,
            ContactId = testMember.Id
        );
        insert testMemberUser;
        
        // Assign officer permissions
        PermissionSet officerPS = [SELECT Id FROM PermissionSet WHERE Name = 'CVMA_Officer_Permissions' LIMIT 1];
        if (officerPS != null) {
            insert new PermissionSetAssignment(
                AssigneeId = testOfficerUser.Id,
                PermissionSetId = officerPS.Id
            );
        }
    }
    
    @IsTest
    static void testGetAnnouncementsPublished() {
        setupTestDataInMethod();
        
        // Create test announcements
        List<CVMA_Announcement__c> announcements = createTestAnnouncements();
        
        System.runAs(testMemberUser) {
            Test.startTest();
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.getAnnouncements(10, 0, 'published');
            Test.stopTest();
            
            System.assert(response.success, 'Response should be successful');
            System.assert(response.announcements.size() > 0, 'Should return published announcements');
            System.assertEquals(10, response.pageSize, 'Page size should match request');
            System.assertEquals(0, response.pageNumber, 'Page number should match request');
        }
    }
    
    @IsTest
    static void testGetAnnouncementsDraft() {
        setupTestDataInMethod();
        
        // Create test announcements
        List<CVMA_Announcement__c> announcements = createTestAnnouncements();
        
        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.getAnnouncements(10, 0, 'draft');
            Test.stopTest();
            
            System.assert(response.success, 'Response should be successful');
        }
    }
    
    @IsTest
    static void testGetAnnouncementsDraftNonOfficer() {
        setupTestDataInMethod();
        
        System.runAs(testMemberUser) {
            Test.startTest();
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.getAnnouncements(10, 0, 'draft');
            Test.stopTest();
            
            System.assert(!response.success, 'Non-officer should not access drafts');
            System.assert(response.errorMessage.contains('Insufficient permissions'), 'Should have permission error');
        }
    }
    
    @IsTest
    static void testCreateAnnouncementSuccess() {
        setupTestDataInMethod();
        
        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.createAnnouncement(
                    'Test Announcement',
                    'This is a test announcement content.',
                    'High',
                    'General',
                    'All Members',
                    System.now(),
                    Date.today().addDays(7),
                    false,
                    true,
                    'https://example.com/image.jpg'
                );
            Test.stopTest();
            
            System.assert(response.success, 'Announcement creation should be successful');
            System.assertEquals('Announcement created successfully', response.successMessage, 'Success message should match');
            
            // Verify announcement was created
            List<CVMA_Announcement__c> createdAnnouncements = [
                SELECT Id, Title__c, Content__c, Priority__c, Author__c
                FROM CVMA_Announcement__c
                WHERE Title__c = 'Test Announcement'
            ];
            System.assertEquals(1, createdAnnouncements.size(), 'Announcement should be created');
            System.assertEquals(testOfficer.Id, createdAnnouncements[0].Author__c, 'Author should be set correctly');
        }
    }
    
    @IsTest
    static void testCreateAnnouncementNonOfficer() {
        setupTestDataInMethod();
        
        System.runAs(testMemberUser) {
            Test.startTest();
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.createAnnouncement(
                    'Test Announcement',
                    'This is a test announcement content.',
                    'Normal',
                    'General',
                    'All Members',
                    System.now(),
                    null,
                    false,
                    false,
                    null
                );
            Test.stopTest();
            
            System.assert(!response.success, 'Non-officer should not create announcements');
            System.assert(response.errorMessage.contains('Insufficient permissions'), 'Should have permission error');
        }
    }
    
    @IsTest
    static void testCreateAnnouncementValidation() {
        setupTestDataInMethod();
        
        System.runAs(testOfficerUser) {
            Test.startTest();
            
            // Test missing title
            CVMAAnnouncementController.AnnouncementResponse response1 = 
                CVMAAnnouncementController.createAnnouncement(
                    '',
                    'Content',
                    'Normal',
                    'General',
                    'All Members',
                    null,
                    null,
                    false,
                    false,
                    null
                );
            
            // Test missing content
            CVMAAnnouncementController.AnnouncementResponse response2 = 
                CVMAAnnouncementController.createAnnouncement(
                    'Title',
                    '',
                    'Normal',
                    'General',
                    'All Members',
                    null,
                    null,
                    false,
                    false,
                    null
                );
            
            // Test title too long
            String longTitle = 'A'.repeat(300);
            CVMAAnnouncementController.AnnouncementResponse response3 = 
                CVMAAnnouncementController.createAnnouncement(
                    longTitle,
                    'Content',
                    'Normal',
                    'General',
                    'All Members',
                    null,
                    null,
                    false,
                    false,
                    null
                );
            
            Test.stopTest();
            
            System.assert(!response1.success, 'Should fail validation for missing title');
            System.assert(response1.errorMessage.contains('Title is required'), 'Should have title error');
            
            System.assert(!response2.success, 'Should fail validation for missing content');
            System.assert(response2.errorMessage.contains('Content is required'), 'Should have content error');
            
            System.assert(!response3.success, 'Should fail validation for long title');
            System.assert(response3.errorMessage.contains('cannot exceed'), 'Should have length error');
        }
    }
    
    @IsTest
    static void testUpdateAnnouncementSuccess() {
        setupTestDataInMethod();
        
        // Create test announcement
        CVMA_Announcement__c announcement = new CVMA_Announcement__c(
            Title__c = 'Original Title',
            Content__c = 'Original Content',
            Priority__c = 'Normal',
            Category__c = 'General',
            Author__c = testOfficer.Id,
            Target_Audience__c = 'All Members',
            Status__c = 'Draft'
        );
        insert announcement;
        
        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.updateAnnouncement(
                    announcement.Id,
                    'Updated Title',
                    'Updated Content',
                    'High',
                    'Events',
                    'Full Members',
                    'Published',
                    System.now(),
                    Date.today().addDays(14),
                    true,
                    true,
                    'https://example.com/newimage.jpg'
                );
            Test.stopTest();
            
            System.assert(response.success, 'Update should be successful');
            
            // Verify updates
            CVMA_Announcement__c updated = [
                SELECT Title__c, Content__c, Priority__c, Category__c, Target_Audience__c, 
                       Status__c, Is_Emergency__c, Banner_Image_URL__c
                FROM CVMA_Announcement__c 
                WHERE Id = :announcement.Id
            ];
            System.assertEquals('Updated Title', updated.Title__c, 'Title should be updated');
            System.assertEquals('High', updated.Priority__c, 'Priority should be updated');
            System.assertEquals('Published', updated.Status__c, 'Status should be updated');
            System.assertEquals(true, updated.Is_Emergency__c, 'Emergency flag should be updated');
        }
    }
    
    @IsTest
    static void testUpdateAnnouncementNotFound() {
        setupTestDataInMethod();
        
        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.updateAnnouncement(
                    '003000000000000',  // Non-existent ID
                    'Title',
                    'Content',
                    'Normal',
                    'General',
                    'All Members',
                    'Draft',
                    null,
                    null,
                    false,
                    false,
                    null
                );
            Test.stopTest();
            
            System.assert(!response.success, 'Should fail for non-existent announcement');
            System.assert(response.errorMessage.contains('not found'), 'Should have not found error');
        }
    }
    
    @IsTest
    static void testArchiveAnnouncementSuccess() {
        setupTestDataInMethod();
        
        // Create test announcement
        CVMA_Announcement__c announcement = new CVMA_Announcement__c(
            Title__c = 'Test Announcement',
            Content__c = 'Test Content',
            Priority__c = 'Normal',
            Category__c = 'General',
            Author__c = testOfficer.Id,
            Target_Audience__c = 'All Members',
            Status__c = 'Published'
        );
        insert announcement;
        
        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.archiveAnnouncement(announcement.Id);
            Test.stopTest();
            
            System.assert(response.success, 'Archive should be successful');
            
            // Verify archived
            CVMA_Announcement__c archived = [
                SELECT Status__c 
                FROM CVMA_Announcement__c 
                WHERE Id = :announcement.Id
            ];
            System.assertEquals('Archived', archived.Status__c, 'Should be archived');
        }
    }
    
    @IsTest
    static void testArchiveAnnouncementNonOfficer() {
        setupTestDataInMethod();
        
        // Create test announcement
        CVMA_Announcement__c announcement = new CVMA_Announcement__c(
            Title__c = 'Test Announcement',
            Content__c = 'Test Content',
            Priority__c = 'Normal',
            Category__c = 'General',
            Author__c = testOfficer.Id,
            Target_Audience__c = 'All Members',
            Status__c = 'Published'
        );
        insert announcement;
        
        System.runAs(testMemberUser) {
            Test.startTest();
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.archiveAnnouncement(announcement.Id);
            Test.stopTest();
            
            System.assert(!response.success, 'Non-officer should not archive announcements');
        }
    }
    
    @IsTest
    static void testIncrementViewCount() {
        setupTestDataInMethod();
        
        // Create test announcement
        CVMA_Announcement__c announcement = new CVMA_Announcement__c(
            Title__c = 'Test Announcement',
            Content__c = 'Test Content',
            Priority__c = 'Normal',
            Category__c = 'General',
            Author__c = testOfficer.Id,
            Target_Audience__c = 'All Members',
            Status__c = 'Published',
            View_Count__c = 5
        );
        insert announcement;
        
        System.runAs(testMemberUser) {
            Test.startTest();
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.incrementViewCount(announcement.Id);
            Test.stopTest();
            
            System.assert(response.success, 'View count increment should be successful');
            
            // Verify count incremented
            CVMA_Announcement__c updated = [
                SELECT View_Count__c 
                FROM CVMA_Announcement__c 
                WHERE Id = :announcement.Id
            ];
            System.assertEquals(6, updated.View_Count__c, 'View count should be incremented');
        }
    }
    
    @IsTest
    static void testGetCategoryOptions() {
        Test.startTest();
        List<CVMAAnnouncementController.AnnouncementOption> options = 
            CVMAAnnouncementController.getCategoryOptions();
        Test.stopTest();
        
        System.assert(options.size() > 0, 'Should return category options');
        System.assert(options[0].value != null, 'Options should have values');
        System.assert(options[0].label != null, 'Options should have labels');
    }
    
    @IsTest
    static void testGetPriorityOptions() {
        Test.startTest();
        List<CVMAAnnouncementController.AnnouncementOption> options = 
            CVMAAnnouncementController.getPriorityOptions();
        Test.stopTest();
        
        System.assert(options.size() > 0, 'Should return priority options');
        System.assert(options[0].value != null, 'Options should have values');
        System.assert(options[0].label != null, 'Options should have labels');
    }
    
    @IsTest
    static void testGetTargetAudienceOptions() {
        Test.startTest();
        List<CVMAAnnouncementController.AnnouncementOption> options = 
            CVMAAnnouncementController.getTargetAudienceOptions();
        Test.stopTest();
        
        System.assert(options.size() > 0, 'Should return target audience options');
        System.assert(options[0].value != null, 'Options should have values');
        System.assert(options[0].label != null, 'Options should have labels');
    }
    
    @IsTest
    static void testEmailNotificationSending() {
        setupTestDataInMethod();
        
        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.createAnnouncement(
                    'Email Test Announcement',
                    'This announcement should send email notifications.',
                    'High',
                    'General',
                    'All Members',
                    System.now(),
                    null,
                    false,
                    true,  // Send email notification
                    null
                );
            Test.stopTest();
            
            System.assert(response.success, 'Announcement with email should be successful');
            // Note: We can't directly test email sending in unit tests,
            // but we can verify the announcement was created with the email flag
            List<CVMA_Announcement__c> announcements = [
                SELECT Send_Email_Notification__c 
                FROM CVMA_Announcement__c 
                WHERE Title__c = 'Email Test Announcement'
            ];
            System.assertEquals(true, announcements[0].Send_Email_Notification__c, 'Email flag should be set');
        }
    }
    
    @IsTest
    static void testEmergencyAnnouncement() {
        setupTestDataInMethod();
        
        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.createAnnouncement(
                    'EMERGENCY: Chapter Meeting Cancelled',
                    'Due to severe weather, tonight\'s chapter meeting has been cancelled.',
                    'Urgent',
                    'General',
                    'All Members',
                    System.now(),
                    null,
                    true,  // Emergency flag
                    true,
                    null
                );
            Test.stopTest();
            
            System.assert(response.success, 'Emergency announcement should be successful');
            
            // Verify emergency flag
            List<CVMA_Announcement__c> announcements = [
                SELECT Is_Emergency__c, Priority__c
                FROM CVMA_Announcement__c 
                WHERE Title__c LIKE 'EMERGENCY:%'
            ];
            System.assertEquals(true, announcements[0].Is_Emergency__c, 'Emergency flag should be set');
            System.assertEquals('Urgent', announcements[0].Priority__c, 'Priority should be Urgent');
        }
    }
    
    @IsTest
    static void testPaginationAndFiltering() {
        setupTestDataInMethod();
        
        // Create multiple test announcements
        List<CVMA_Announcement__c> announcements = new List<CVMA_Announcement__c>();
        for (Integer i = 0; i < 25; i++) {
            announcements.add(new CVMA_Announcement__c(
                Title__c = 'Test Announcement ' + i,
                Content__c = 'Test Content ' + i,
                Priority__c = 'Normal',
                Category__c = 'General',
                Author__c = testOfficer.Id,
                Target_Audience__c = 'All Members',
                Status__c = 'Published',
                Publish_Date__c = System.now()
            ));
        }
        insert announcements;
        
        System.runAs(testMemberUser) {
            Test.startTest();
            
            // Test first page
            CVMAAnnouncementController.AnnouncementResponse page1 = 
                CVMAAnnouncementController.getAnnouncements(10, 0, 'published');
                
            // Test second page
            CVMAAnnouncementController.AnnouncementResponse page2 = 
                CVMAAnnouncementController.getAnnouncements(10, 1, 'published');
            
            Test.stopTest();
            
            System.assert(page1.success, 'First page should be successful');
            System.assert(page2.success, 'Second page should be successful');
            System.assertEquals(10, page1.announcements.size(), 'First page should have 10 items');
            System.assertEquals(10, page2.announcements.size(), 'Second page should have 10 items');
            System.assertEquals(true, page1.hasMore, 'First page should have more items');
            System.assert(page1.totalCount >= 25, 'Total count should be at least 25');
        }
    }
    
    @IsTest
    static void testDefaultParameterValues() {
        setupTestDataInMethod();
        
        System.runAs(testMemberUser) {
            Test.startTest();
            // Test with null/empty parameters
            CVMAAnnouncementController.AnnouncementResponse response = 
                CVMAAnnouncementController.getAnnouncements(null, null, '');
            Test.stopTest();
            
            System.assert(response.success, 'Should handle null parameters gracefully');
            System.assertEquals(10, response.pageSize, 'Should use default page size');
            System.assertEquals(0, response.pageNumber, 'Should use default page number');
        }
    }
    
    // Helper methods
    private static void setupTestDataInMethod() {
        // Get test data created in @TestSetup
        testOfficer = [SELECT Id FROM Contact WHERE Email = 'testofficer@cvma.test' LIMIT 1];
        testMember = [SELECT Id FROM Contact WHERE Email = 'testmember@cvma.test' LIMIT 1];
        testOfficerUser = [SELECT Id FROM User WHERE Username = 'testofficer@cvma.test.user' LIMIT 1];
        testMemberUser = [SELECT Id FROM User WHERE Username = 'testmember@cvma.test.user' LIMIT 1];
    }
    
    private static List<CVMA_Announcement__c> createTestAnnouncements() {
        List<CVMA_Announcement__c> announcements = new List<CVMA_Announcement__c>();
        
        // Published announcement
        announcements.add(new CVMA_Announcement__c(
            Title__c = 'Published Test Announcement',
            Content__c = 'This is a published test announcement.',
            Priority__c = 'Normal',
            Category__c = 'General',
            Author__c = testOfficer.Id,
            Target_Audience__c = 'All Members',
            Status__c = 'Published',
            Publish_Date__c = System.now().addHours(-1)
        ));
        
        // Draft announcement
        announcements.add(new CVMA_Announcement__c(
            Title__c = 'Draft Test Announcement',
            Content__c = 'This is a draft test announcement.',
            Priority__c = 'High',
            Category__c = 'Events',
            Author__c = testOfficer.Id,
            Target_Audience__c = 'Full Members',
            Status__c = 'Draft'
        ));
        
        // Archived announcement
        announcements.add(new CVMA_Announcement__c(
            Title__c = 'Archived Test Announcement',
            Content__c = 'This is an archived test announcement.',
            Priority__c = 'Normal',
            Category__c = 'General',
            Author__c = testOfficer.Id,
            Target_Audience__c = 'All Members',
            Status__c = 'Archived'
        ));
        
        insert announcements;
        return announcements;
    }
}