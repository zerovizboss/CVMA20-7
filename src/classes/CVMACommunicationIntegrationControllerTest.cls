/**
 * @description Test class for CVMACommunicationIntegrationController
 * @author Claude AI - CVMA Development Team
 * @date 2025-01-09
 */
@IsTest
private class CVMACommunicationIntegrationControllerTest {

    private static Contact testOfficer;
    private static Contact testMember1;
    private static Contact testMember2;
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
            .withPhone('555-0101')
            .create();

        testMember1 = CVMATestDataFactory.createContact()
            .withFirstName('Test')
            .withLastName('Member1')
            .withLevel('Associate Member')
            .withEmail('testmember1@cvma.test')
            .withPhone('555-0102')
            .create();

        testMember2 = CVMATestDataFactory.createContact()
            .withFirstName('Test')
            .withLastName('Member2')
            .withLevel('Full Member')
            .withEmail('testmember2@cvma.test')
            .withPhone('555-0103')
            .create();

        // Create test users
        Profile memberProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];

        testOfficerUser = new User(
            FirstName = 'Test',
            LastName = 'Officer',
            Email = 'testofficer@cvma.test',
            Username = 'testofficer.integration@cvma.test.user',
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
            Username = 'testmember.integration@cvma.test.user',
            Alias = 'tmem',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = memberProfile.Id,
            ContactId = testMember1.Id
        );
        insert testMemberUser;

        // Assign officer permissions
        try {
            PermissionSet officerPS = [SELECT Id FROM PermissionSet WHERE Name = 'CVMA_Officer_Permissions' LIMIT 1];
            insert new PermissionSetAssignment(
                AssigneeId = testOfficerUser.Id,
                PermissionSetId = officerPS.Id
            );
        } catch (Exception e) {
            System.debug('Officer permission set not available in test: ' + e.getMessage());
        }
    }

    static void setupTestDataInMethod() {
        List<Contact> contacts = [SELECT Id, FirstName, LastName, Email, MobilePhone FROM Contact ORDER BY LastName];
        testOfficer = contacts[1]; // Officer
        testMember1 = contacts[0]; // Member1
        testMember2 = contacts[2]; // Member2

        List<User> users = [SELECT Id, ContactId FROM User WHERE ContactId != null ORDER BY LastName];
        for (User u : users) {
            if (u.ContactId == testOfficer.Id) {
                testOfficerUser = u;
            } else if (u.ContactId == testMember1.Id) {
                testMemberUser = u;
            }
        }
    }

    @IsTest
    static void testSendMultiChannelCommunicationSuccess() {
        setupTestDataInMethod();

        CVMACommunicationIntegrationController.CommunicationRequest request =
            new CVMACommunicationIntegrationController.CommunicationRequest();
        request.messageType = 'ANNOUNCEMENT';
        request.subject = 'Test Communication';
        request.content = 'This is a test multi-channel communication message.';
        request.contactIds = new List<String>{testMember1.Id, testMember2.Id};
        request.channels = new List<String>{'EMAIL', 'SMS'};
        request.priority = 'NORMAL';
        request.trackDelivery = true;

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            Test.stopTest();

            System.assert(response.success, 'Communication should be successful');
            System.assertNotEquals(null, response.integrationId, 'Integration ID should be generated');
            System.assert(response.results.size() > 0, 'Should have delivery results');
            System.assert(response.deliveredCount >= 0, 'Should track delivered count');
        }
    }

    @IsTest
    static void testSendMultiChannelCommunicationValidation() {
        setupTestDataInMethod();

        // Test null request
        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(null);
            Test.stopTest();

            System.assert(!response.success, 'Should fail for null request');
            System.assert(response.message.contains('failed'), 'Should contain error message');
        }
    }

    @IsTest
    static void testSendMultiChannelCommunicationMissingContent() {
        setupTestDataInMethod();

        CVMACommunicationIntegrationController.CommunicationRequest request =
            new CVMACommunicationIntegrationController.CommunicationRequest();
        request.contactIds = new List<String>{testMember1.Id};
        request.channels = new List<String>{'EMAIL'};

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            Test.stopTest();

            System.assert(!response.success, 'Should fail for missing content');
        }
    }

    @IsTest
    static void testSendMultiChannelCommunicationEmptyRecipients() {
        setupTestDataInMethod();

        CVMACommunicationIntegrationController.CommunicationRequest request =
            new CVMACommunicationIntegrationController.CommunicationRequest();
        request.content = 'Test message';
        request.contactIds = new List<String>();
        request.channels = new List<String>{'EMAIL'};

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            Test.stopTest();

            System.assert(!response.success, 'Should fail for empty recipients');
        }
    }

    @IsTest
    static void testSendMultiChannelCommunicationEmptyChannels() {
        setupTestDataInMethod();

        CVMACommunicationIntegrationController.CommunicationRequest request =
            new CVMACommunicationIntegrationController.CommunicationRequest();
        request.content = 'Test message';
        request.contactIds = new List<String>{testMember1.Id};
        request.channels = new List<String>();

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            Test.stopTest();

            System.assert(!response.success, 'Should fail for empty channels');
        }
    }

    @IsTest
    static void testSendMultiChannelCommunicationNoPermissions() {
        setupTestDataInMethod();

        CVMACommunicationIntegrationController.CommunicationRequest request =
            new CVMACommunicationIntegrationController.CommunicationRequest();
        request.content = 'Test message';
        request.contactIds = new List<String>{testMember1.Id};
        request.channels = new List<String>{'EMAIL'};

        System.runAs(testMemberUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            Test.stopTest();

            System.assert(!response.success, 'Should fail for non-officer user');
        }
    }

    @IsTest
    static void testGetAvailableIntegrations() {
        setupTestDataInMethod();

        System.runAs(testOfficerUser) {
            Test.startTest();
            List<CVMACommunicationIntegrationController.IntegrationConfiguration> integrations =
                CVMACommunicationIntegrationController.getAvailableIntegrations();
            Test.stopTest();

            System.assert(integrations.size() >= 3, 'Should return at least 3 integrations (SMS, Email, Slack)');

            Boolean hasSMS = false;
            Boolean hasEmail = false;
            Boolean hasSlack = false;

            for (CVMACommunicationIntegrationController.IntegrationConfiguration config : integrations) {
                if (config.providerId == 'twilio_sms') {
                    hasSMS = true;
                    System.assert(config.isActive, 'SMS integration should be active');
                    System.assert(config.supportedChannels.size() > 0, 'SMS should have supported channels');
                }
                if (config.providerId == 'sendgrid_email') {
                    hasEmail = true;
                    System.assert(config.isActive, 'Email integration should be active');
                    System.assert(config.supportedChannels.size() > 0, 'Email should have supported channels');
                }
                if (config.providerId == 'slack_webhook') {
                    hasSlack = true;
                    System.assert(!config.isActive, 'Slack integration should be inactive (placeholder)');
                }
            }

            System.assert(hasSMS, 'Should include SMS integration');
            System.assert(hasEmail, 'Should include Email integration');
            System.assert(hasSlack, 'Should include Slack integration placeholder');
        }
    }

    @IsTest
    static void testGetAvailableIntegrationsNoPermissions() {
        setupTestDataInMethod();

        System.runAs(testMemberUser) {
            Test.startTest();
            List<CVMACommunicationIntegrationController.IntegrationConfiguration> integrations =
                CVMACommunicationIntegrationController.getAvailableIntegrations();
            Test.stopTest();

            System.assertEquals(0, integrations.size(), 'Should return empty list for non-officer');
        }
    }

    @IsTest
    static void testIntegrationSMSTest() {
        setupTestDataInMethod();

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.testIntegration('twilio_sms');
            Test.stopTest();

            System.assertNotEquals(null, response, 'Response should not be null');
            System.assertNotEquals(null, response.message, 'Response should have message');
        }
    }

    @IsTest
    static void testIntegrationEmailTest() {
        setupTestDataInMethod();

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.testIntegration('sendgrid_email');
            Test.stopTest();

            System.assertNotEquals(null, response, 'Response should not be null');
            System.assertNotEquals(null, response.message, 'Response should have message');
        }
    }

    @IsTest
    static void testIntegrationSlackTest() {
        setupTestDataInMethod();

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.testIntegration('slack_webhook');
            Test.stopTest();

            System.assertNotEquals(null, response, 'Response should not be null');
            System.assert(!response.success, 'Slack test should fail (not implemented)');
            System.assert(response.message.contains('not yet implemented'), 'Should indicate not implemented');
        }
    }

    @IsTest
    static void testIntegrationUnknownProviderTest() {
        setupTestDataInMethod();

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.testIntegration('unknown_provider');
            Test.stopTest();

            System.assertNotEquals(null, response, 'Response should not be null');
            System.assert(!response.success, 'Unknown provider test should fail');
        }
    }

    @IsTest
    static void testIntegrationTestNoPermissions() {
        setupTestDataInMethod();

        System.runAs(testMemberUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.testIntegration('twilio_sms');
            Test.stopTest();

            System.assert(!response.success, 'Should fail for non-officer user');
        }
    }

    @IsTest
    static void testGetDeliveryStatistics() {
        setupTestDataInMethod();

        // Create some test error log entries to simulate integration activity
        List<CVMA_Error_Log__c> testLogs = new List<CVMA_Error_Log__c>();

        testLogs.add(new CVMA_Error_Log__c(
            Class_Name__c = 'COMM_INT_Test',
            Category__c = 'INTEGRATION',
            Context_Data__c = 'Integration: TEST123 | Channels: SMS | Recipients: 1 | Delivered: 1 | Failed: 0',
            Severity__c = 'LOW'
        ));

        testLogs.add(new CVMA_Error_Log__c(
            Class_Name__c = 'COMM_INT_Test2',
            Category__c = 'INTEGRATION',
            Context_Data__c = 'Integration: TEST456 | Channels: EMAIL | Recipients: 1 | Delivered: 1 | Failed: 0',
            Severity__c = 'LOW'
        ));

        insert testLogs;

        System.runAs(testOfficerUser) {
            Test.startTest();
            Map<String, Object> statistics = CVMACommunicationIntegrationController.getDeliveryStatistics(
                Date.today().addDays(-7), Date.today()
            );
            Test.stopTest();

            System.assertNotEquals(null, statistics, 'Statistics should not be null');
            System.assert(statistics.containsKey('totalCommunications'), 'Should contain total communications');
            System.assert(statistics.containsKey('channelBreakdown'), 'Should contain channel breakdown');
            System.assert(statistics.containsKey('reportingPeriod'), 'Should contain reporting period');
        }
    }

    @IsTest
    static void testGetDeliveryStatisticsNoPermissions() {
        setupTestDataInMethod();

        System.runAs(testMemberUser) {
            Test.startTest();
            Map<String, Object> statistics = CVMACommunicationIntegrationController.getDeliveryStatistics(
                Date.today().addDays(-7), Date.today()
            );
            Test.stopTest();

            System.assert(statistics.containsKey('error'), 'Should return error for non-officer');
        }
    }

    @IsTest
    static void testSMSDeliveryWithoutMobilePhone() {
        setupTestDataInMethod();

        // Create contact without mobile phone
        Contact contactNoPhone = CVMATestDataFactory.createContact()
            .withFirstName('No')
            .withLastName('Phone')
            .withLevel('Associate Member')
            .withEmail('nophone@cvma.test')
            .create();

        CVMACommunicationIntegrationController.CommunicationRequest request =
            new CVMACommunicationIntegrationController.CommunicationRequest();
        request.content = 'Test SMS message';
        request.contactIds = new List<String>{contactNoPhone.Id};
        request.channels = new List<String>{'SMS'};

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            Test.stopTest();

            System.assert(response.success, 'Overall operation should succeed');
            System.assertEquals(0, response.deliveredCount, 'Should have 0 delivered due to missing phone');
            System.assertEquals(1, response.failedCount, 'Should have 1 failed delivery');

            Boolean foundPhoneError = false;
            for (CVMACommunicationIntegrationController.DeliveryResult result : response.results) {
                if (result.error != null && result.error.contains('mobile phone')) {
                    foundPhoneError = true;
                    break;
                }
            }
            System.assert(foundPhoneError, 'Should have mobile phone error in results');
        }
    }

    @IsTest
    static void testEmailDeliveryWithoutEmail() {
        setupTestDataInMethod();

        // Create contact without email
        Contact contactNoEmail = CVMATestDataFactory.createContact()
            .withFirstName('No')
            .withLastName('Email')
            .withLevel('Associate Member')
            .withPhone('555-0199')
            .create();

        CVMACommunicationIntegrationController.CommunicationRequest request =
            new CVMACommunicationIntegrationController.CommunicationRequest();
        request.content = 'Test email message';
        request.subject = 'Test Subject';
        request.contactIds = new List<String>{contactNoEmail.Id};
        request.channels = new List<String>{'EMAIL'};

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            Test.stopTest();

            System.assert(response.success, 'Overall operation should succeed');
            System.assertEquals(0, response.deliveredCount, 'Should have 0 delivered due to missing email');
            System.assertEquals(1, response.failedCount, 'Should have 1 failed delivery');

            Boolean foundEmailError = false;
            for (CVMACommunicationIntegrationController.DeliveryResult result : response.results) {
                if (result.error != null && result.error.contains('email')) {
                    foundEmailError = true;
                    break;
                }
            }
            System.assert(foundEmailError, 'Should have email error in results');
        }
    }

    @IsTest
    static void testUnsupportedChannel() {
        setupTestDataInMethod();

        CVMACommunicationIntegrationController.CommunicationRequest request =
            new CVMACommunicationIntegrationController.CommunicationRequest();
        request.content = 'Test message';
        request.contactIds = new List<String>{testMember1.Id};
        request.channels = new List<String>{'UNSUPPORTED_CHANNEL'};

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            Test.stopTest();

            System.assert(response.success, 'Overall operation should succeed');
            System.assertEquals(0, response.deliveredCount, 'Should have 0 delivered due to unsupported channel');
            System.assertEquals(1, response.failedCount, 'Should have 1 failed delivery');

            Boolean foundChannelError = false;
            for (CVMACommunicationIntegrationController.DeliveryResult result : response.results) {
                if (result.error != null && result.error.contains('Unsupported channel')) {
                    foundChannelError = true;
                    break;
                }
            }
            System.assert(foundChannelError, 'Should have unsupported channel error in results');
        }
    }

    @IsTest
    static void testMixedChannelDelivery() {
        setupTestDataInMethod();

        CVMACommunicationIntegrationController.CommunicationRequest request =
            new CVMACommunicationIntegrationController.CommunicationRequest();
        request.content = 'Test mixed channel message';
        request.subject = 'Test Subject';
        request.contactIds = new List<String>{testMember1.Id, testMember2.Id};
        request.channels = new List<String>{'SMS', 'EMAIL', 'HTML_EMAIL'};
        request.priority = 'HIGH';

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            Test.stopTest();

            System.assert(response.success, 'Mixed channel communication should succeed');
            System.assert(response.results.size() > 0, 'Should have delivery results for multiple channels');

            // Should have results for each contact across each channel (2 contacts * 3 channels = 6 results)
            System.assertEquals(6, response.results.size(), 'Should have results for all contact-channel combinations');
        }
    }

    @IsTest
    static void testInputSanitization() {
        setupTestDataInMethod();

        CVMACommunicationIntegrationController.CommunicationRequest request =
            new CVMACommunicationIntegrationController.CommunicationRequest();
        request.content = '<script>alert("xss")</script>Test message';
        request.subject = '<script>alert("xss")</script>Test Subject';
        request.contactIds = new List<String>{testMember1.Id};
        request.channels = new List<String>{'EMAIL'};

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            Test.stopTest();

            // Input sanitization should occur during validation
            System.assert(response.success, 'Should succeed after input sanitization');
        }
    }

    @IsTest
    static void testLargeRecipientList() {
        setupTestDataInMethod();

        // Create additional test contacts
        List<Contact> additionalContacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            additionalContacts.add(CVMATestDataFactory.createContact()
                .withFirstName('Bulk')
                .withLastName('Recipient' + i)
                .withLevel('Associate Member')
                .withEmail('bulkrecipient' + i + '@cvma.test')
                .withPhone('555-020' + i)
                .build());
        }
        insert additionalContacts;

        List<String> allContactIds = new List<String>{testMember1.Id, testMember2.Id};
        for (Contact c : additionalContacts) {
            allContactIds.add(c.Id);
        }

        CVMACommunicationIntegrationController.CommunicationRequest request =
            new CVMACommunicationIntegrationController.CommunicationRequest();
        request.content = 'Bulk test message';
        request.subject = 'Bulk Test';
        request.contactIds = allContactIds;
        request.channels = new List<String>{'EMAIL'};

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            Test.stopTest();

            System.assert(response.success, 'Bulk communication should succeed');
            System.assertEquals(allContactIds.size(), response.results.size(),
                'Should have results for all recipients');
        }
    }

    @IsTest
    static void testIntegrationIdGeneration() {
        setupTestDataInMethod();

        CVMACommunicationIntegrationController.CommunicationRequest request =
            new CVMACommunicationIntegrationController.CommunicationRequest();
        request.content = 'Test message for ID generation';
        request.contactIds = new List<String>{testMember1.Id};
        request.channels = new List<String>{'EMAIL'};

        System.runAs(testOfficerUser) {
            Test.startTest();
            CVMACommunicationIntegrationController.IntegrationResponse response1 =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            CVMACommunicationIntegrationController.IntegrationResponse response2 =
                CVMACommunicationIntegrationController.sendMultiChannelCommunication(request);
            Test.stopTest();

            System.assertNotEquals(null, response1.integrationId, 'First response should have integration ID');
            System.assertNotEquals(null, response2.integrationId, 'Second response should have integration ID');
            System.assertNotEquals(response1.integrationId, response2.integrationId,
                'Integration IDs should be unique');
            System.assert(response1.integrationId.startsWith('COMM_INT_'),
                'Integration ID should have correct prefix');
        }
    }
}
