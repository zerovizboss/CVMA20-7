/**
 * @description Test class for CVMA Communication Hub Controller
 * @author CVMA Development Team
 * @date 2024
 * @group Communication Hub Tests
 */
@IsTest
private class CVMACommunicationHubControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test user with contact
        Profile memberProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = CVMATestDataFactory.createUser()
            .withProfile(memberProfile.Id)
            .withEmail('test.member@cvma20-7.org')
            .create();

        System.runAs(testUser) {
            // Create test contact for the user
            Contact testContact = CVMATestDataFactory.createContact()
                .withFirstName('Test')
                .withLastName('Member')
                .withEmail('test.member@cvma20-7.org')
                .withLevel('Full Member')
                .withOfficerRole('Secretary')
                .create();

            // Link user to contact
            testUser.ContactId = testContact.Id;
            update testUser;

            // Create test opportunities (donations)
            List<Opportunity> testOpportunities = new List<Opportunity>();

            Opportunity donation1 = CVMATestDataFactory.createOpportunity()
                .withName('Test Donation 1')
                .withAmount(100.00)
                .withStage('Closed Won')
                .withCloseDate(Date.today())
                .withPrimaryContact(testContact.Id)
                .create();

            Opportunity donation2 = CVMATestDataFactory.createOpportunity()
                .withName('Membership Payment')
                .withAmount(50.00)
                .withStage('Closed Won')
                .withCloseDate(Date.today())
                .withPrimaryContact(testContact.Id)
                .create();

            // Create test campaigns
            Campaign testCampaign = CVMATestDataFactory.createCampaign()
                .withName('Chapter Meeting - September 2024')
                .withType('Event')
                .withStatus('In Progress')
                .withStartDate(Date.today().addDays(7))
                .withEndDate(Date.today().addDays(7))
                .create();

            // Create campaign member
            CampaignMember testCampaignMember = new CampaignMember();
            testCampaignMember.CampaignId = testCampaign.Id;
            testCampaignMember.ContactId = testContact.Id;
            testCampaignMember.Status = 'Responded';
            insert testCampaignMember;

            // Create test tasks (communication records)
            List<Task> testTasks = new List<Task>();

            Task emailTask = new Task();
            emailTask.Subject = 'Event Registration Confirmation';
            emailTask.Description = 'Thank you for registering for the chapter meeting';
            emailTask.Type = 'Email';
            emailTask.Priority = 'Normal';
            emailTask.Status = 'Completed';
            emailTask.ActivityDate = Date.today();
            emailTask.WhoId = testContact.Id;
            emailTask.WhatId = testCampaign.Id;
            testTasks.add(emailTask);

            Task donationTask = new Task();
            donationTask.Subject = 'Donation Acknowledgment';
            donationTask.Description = 'Thank you for your generous donation';
            donationTask.Type = 'Email';
            donationTask.Priority = 'Normal';
            donationTask.Status = 'Completed';
            donationTask.ActivityDate = Date.today();
            donationTask.WhoId = testContact.Id;
            donationTask.WhatId = donation1.Id;
            testTasks.add(donationTask);

            insert testTasks;

            // Create Chatter groups
            CollaborationGroup chapterGroup = new CollaborationGroup();
            chapterGroup.Name = 'Chapter 20-7 Main';
            chapterGroup.CollaborationType = 'Private';
            chapterGroup.Description = 'Main chapter communication group';
            insert chapterGroup;

            CollaborationGroup officerGroup = new CollaborationGroup();
            officerGroup.Name = 'Officer Communications';
            officerGroup.CollaborationType = 'Private';
            officerGroup.Description = 'Officer-only communication group';
            insert officerGroup;

            // Add user to groups
            List<CollaborationGroupMember> groupMembers = new List<CollaborationGroupMember>();

            CollaborationGroupMember chapterMember = new CollaborationGroupMember();
            chapterMember.CollaborationGroupId = chapterGroup.Id;
            chapterMember.MemberId = testUser.Id;
            chapterMember.CollaborationRole = 'Standard';
            groupMembers.add(chapterMember);

            CollaborationGroupMember officerMember = new CollaborationGroupMember();
            officerMember.CollaborationGroupId = officerGroup.Id;
            officerMember.MemberId = testUser.Id;
            officerMember.CollaborationRole = 'Admin';
            groupMembers.add(officerMember);

            insert groupMembers;
        }
    }

    @IsTest
    static void testGetCurrentUser() {
        User testUser = [SELECT Id, ContactId FROM User WHERE Email = 'test.member@cvma20-7.org' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            CVMACommunicationHubController.CurrentUserInfo userInfo =
                CVMACommunicationHubController.getCurrentUser();

            System.assertNotEquals(null, userInfo, 'User info should not be null');
            System.assertEquals(testUser.Id, userInfo.userId, 'User ID should match');
            System.assertEquals(testUser.ContactId, userInfo.contactId, 'Contact ID should match');
            System.assertEquals(true, userInfo.isOfficer, 'User should be identified as officer');
            System.assertEquals(true, userInfo.hasEmailAccess, 'User should have email access');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetCurrentUserWithoutContact() {
        // Create user without contact
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = CVMATestDataFactory.createUser()
            .withProfile(sysAdminProfile.Id)
            .withEmail('admin@cvma20-7.org')
            .create();

        Test.startTest();
        System.runAs(adminUser) {
            CVMACommunicationHubController.CurrentUserInfo userInfo =
                CVMACommunicationHubController.getCurrentUser();

            System.assertNotEquals(null, userInfo, 'User info should not be null');
            System.assertEquals(adminUser.Id, userInfo.userId, 'User ID should match');
            System.assertEquals(null, userInfo.contactId, 'Contact ID should be null');
            System.assertEquals(false, userInfo.isOfficer, 'User should not be identified as officer');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetRecentCommunications() {
        User testUser = [SELECT Id, ContactId FROM User WHERE Email = 'test.member@cvma20-7.org' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Id = :testUser.ContactId LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            List<CVMACommunicationHubController.CommunicationRecord> communications =
                CVMACommunicationHubController.getRecentCommunications(testContact.Id, null, 50);

            System.assertNotEquals(null, communications, 'Communications list should not be null');
            System.assert(communications.size() > 0, 'Should have communication records');

            // Verify communication details
            CVMACommunicationHubController.CommunicationRecord firstComm = communications[0];
            System.assertNotEquals(null, firstComm.id, 'Communication ID should not be null');
            System.assertNotEquals(null, firstComm.subject, 'Communication subject should not be null');
            System.assertNotEquals(null, firstComm.type, 'Communication type should not be null');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetRecentCommunicationsWithRecordFilter() {
        User testUser = [SELECT Id, ContactId FROM User WHERE Email = 'test.member@cvma20-7.org' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Id = :testUser.ContactId LIMIT 1];
        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name LIKE '%Chapter Meeting%' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            List<CVMACommunicationHubController.CommunicationRecord> communications =
                CVMACommunicationHubController.getRecentCommunications(
                    testContact.Id, testCampaign.Id, 50);

            System.assertNotEquals(null, communications, 'Communications list should not be null');

            // Verify filtered results
            for (CVMACommunicationHubController.CommunicationRecord comm : communications) {
                if (comm.relatedRecordId != null) {
                    System.assertEquals(testCampaign.Id, comm.relatedRecordId,
                        'Communication should be related to the specified campaign');
                }
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetChatterGroups() {
        User testUser = [SELECT Id, ContactId FROM User WHERE Email = 'test.member@cvma20-7.org' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Id = :testUser.ContactId LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            List<CVMACommunicationHubController.ChatterGroupInfo> groups =
                CVMACommunicationHubController.getChatterGroups(testContact.Id);

            System.assertNotEquals(null, groups, 'Groups list should not be null');
            System.assert(groups.size() > 0, 'Should have Chatter groups');

            // Verify group details
            boolean hasChapterGroup = false;
            boolean hasOfficerGroup = false;

            for (CVMACommunicationHubController.ChatterGroupInfo group : groups) {
                System.assertNotEquals(null, group.id, 'Group ID should not be null');
                System.assertNotEquals(null, group.name, 'Group name should not be null');
                System.assertEquals(true, group.canPost, 'User should be able to post');

                if (group.name.contains('Chapter 20-7')) {
                    hasChapterGroup = true;
                }
                if (group.name.contains('Officer') && group.isManager) {
                    hasOfficerGroup = true;
                }
            }

            System.assertEquals(true, hasChapterGroup, 'Should have chapter group');
            System.assertEquals(true, hasOfficerGroup, 'Should have officer group with admin role');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSendCommunication() {
        User testUser = [SELECT Id, ContactId FROM User WHERE Email = 'test.member@cvma20-7.org' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Id = :testUser.ContactId LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            String result = CVMACommunicationHubController.sendCommunication(
                'Chapter Announcement',
                'Test Communication Subject',
                'This is a test communication message for Epic #6 testing.',
                'Normal',
                new List<Id>{ testContact.Id },
                testContact.Id
            );

            System.assertNotEquals(null, result, 'Result should not be null');
            System.assert(result.contains('successfully'), 'Should indicate successful send');
            System.assert(result.contains('1 recipients'), 'Should indicate correct recipient count');

            // Verify task was created
            List<Task> createdTasks = [
                SELECT Id, Subject, Description, Type, Priority, Status
                FROM Task
                WHERE Subject = 'Test Communication Subject'
                AND WhoId = :testContact.Id
            ];

            System.assertEquals(1, createdTasks.size(), 'Should have created one task');
            Task createdTask = createdTasks[0];
            System.assertEquals('Email', createdTask.Type, 'Task type should be Email');
            System.assertEquals('Normal', createdTask.Priority, 'Task priority should match');
            System.assertEquals('Completed', createdTask.Status, 'Task should be completed');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSendCommunicationMultipleRecipients() {
        User testUser = [SELECT Id, ContactId FROM User WHERE Email = 'test.member@cvma20-7.org' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Id = :testUser.ContactId LIMIT 1];

        // Create additional test contact
        Contact additionalContact = CVMATestDataFactory.createContact()
            .withFirstName('Additional')
            .withLastName('Member')
            .withEmail('additional.member@cvma20-7.org')
            .withLevel('Associate Member')
            .create();

        Test.startTest();
        System.runAs(testUser) {
            String result = CVMACommunicationHubController.sendCommunication(
                'Emergency Notification',
                'Important Chapter Update',
                'This is an important update for all members.',
                'High',
                new List<Id>{ testContact.Id, additionalContact.Id },
                testContact.Id
            );

            System.assertNotEquals(null, result, 'Result should not be null');
            System.assert(result.contains('2 recipients'), 'Should indicate correct recipient count');

            // Verify tasks were created for both recipients
            List<Task> createdTasks = [
                SELECT Id, Subject, WhoId, Priority
                FROM Task
                WHERE Subject = 'Important Chapter Update'
                AND WhoId IN (:testContact.Id, :additionalContact.Id)
            ];

            System.assertEquals(2, createdTasks.size(), 'Should have created two tasks');

            for (Task task : createdTasks) {
                System.assertEquals('High', task.Priority, 'All tasks should have high priority');
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testSendCommunicationValidation() {
        User testUser = [SELECT Id, ContactId FROM User WHERE Email = 'test.member@cvma20-7.org' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Id = :testUser.ContactId LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            // Test empty subject
            try {
                CVMACommunicationHubController.sendCommunication(
                    'Chapter Announcement',
                    '',
                    'Test message',
                    'Normal',
                    new List<Id>{ testContact.Id },
                    testContact.Id
                );
                System.assert(false, 'Should have thrown exception for empty subject');
            } catch (CVMACommunicationHubController.CommunicationHubException e) {
                System.assert(e.getMessage().contains('Subject'), 'Exception should mention subject requirement');
            }

            // Test empty body
            try {
                CVMACommunicationHubController.sendCommunication(
                    'Chapter Announcement',
                    'Test Subject',
                    '',
                    'Normal',
                    new List<Id>{ testContact.Id },
                    testContact.Id
                );
                System.assert(false, 'Should have thrown exception for empty body');
            } catch (CVMACommunicationHubController.CommunicationHubException e) {
                System.assert(e.getMessage().contains('body'), 'Exception should mention body requirement');
            }

            // Test empty recipients
            try {
                CVMACommunicationHubController.sendCommunication(
                    'Chapter Announcement',
                    'Test Subject',
                    'Test message',
                    'Normal',
                    new List<Id>(),
                    testContact.Id
                );
                System.assert(false, 'Should have thrown exception for empty recipients');
            } catch (CVMACommunicationHubController.CommunicationHubException e) {
                System.assert(e.getMessage().contains('recipient'), 'Exception should mention recipient requirement');
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testDetermineCommunicationType() {
        // This tests the private method indirectly through sendCommunication
        User testUser = [SELECT Id, ContactId FROM User WHERE Email = 'test.member@cvma20-7.org' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Id = :testUser.ContactId LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            // Send different types of communications to test type determination
            CVMACommunicationHubController.sendCommunication(
                'Event Communication',
                'RSVP Confirmation for Event',
                'Thank you for your RSVP to the upcoming event.',
                'Normal',
                new List<Id>{ testContact.Id },
                testContact.Id
            );

            CVMACommunicationHubController.sendCommunication(
                'Financial Communication',
                'Donation Receipt',
                'Thank you for your generous donation to our cause.',
                'Normal',
                new List<Id>{ testContact.Id },
                testContact.Id
            );

            CVMACommunicationHubController.sendCommunication(
                'Emergency Notification',
                'URGENT: Chapter Update',
                'This is an urgent notification about emergency procedures.',
                'Urgent',
                new List<Id>{ testContact.Id },
                testContact.Id
            );
        }
        Test.stopTest();

        // Verify all communications were created successfully
        List<Task> allTasks = [
            SELECT Id, Subject, Description
            FROM Task
            WHERE WhoId = :testContact.Id
            AND Subject IN ('RSVP Confirmation for Event', 'Donation Receipt', 'URGENT: Chapter Update')
        ];

        System.assertEquals(3, allTasks.size(), 'Should have created all test communications');
    }

    @IsTest
    static void testCommunicationDateComparator() {
        // Create test communication records with different dates
        CVMACommunicationHubController.CommunicationRecord comm1 =
            new CVMACommunicationHubController.CommunicationRecord();
        comm1.createdDate = DateTime.now().addDays(-2);

        CVMACommunicationHubController.CommunicationRecord comm2 =
            new CVMACommunicationHubController.CommunicationRecord();
        comm2.createdDate = DateTime.now().addDays(-1);

        CVMACommunicationHubController.CommunicationRecord comm3 =
            new CVMACommunicationHubController.CommunicationRecord();
        comm3.createdDate = DateTime.now();

        List<CVMACommunicationHubController.CommunicationRecord> communications =
            new List<CVMACommunicationHubController.CommunicationRecord>{ comm1, comm2, comm3 };

        Test.startTest();
        communications.sort(new CVMACommunicationHubController.CommunicationDateComparator());
        Test.stopTest();

        // Verify sorting (newest first)
        System.assertEquals(comm3.createdDate, communications[0].createdDate, 'Newest should be first');
        System.assertEquals(comm2.createdDate, communications[1].createdDate, 'Middle should be second');
        System.assertEquals(comm1.createdDate, communications[2].createdDate, 'Oldest should be last');
    }

    @IsTest
    static void testErrorHandling() {
        // Test with invalid contact ID
        Test.startTest();
        try {
            CVMACommunicationHubController.getRecentCommunications('invalid_id', null, 50);
            System.assert(false, 'Should have thrown exception for invalid contact ID');
        } catch (Exception e) {
            System.assert(e instanceof CVMACommunicationHubController.CommunicationHubException,
                'Should throw CommunicationHubException');
        }
        Test.stopTest();
    }
}
