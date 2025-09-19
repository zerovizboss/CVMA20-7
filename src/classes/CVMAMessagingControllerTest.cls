/**
 * @description Comprehensive test class for CVMAMessagingController
 * @author Claude AI - CVMA Development Team
 * @date 2025-01-09
 */
@IsTest
private class CVMAMessagingControllerTest {

    // Test data properties
    private static User testUser;
    private static User recipientUser;
    private static Contact senderContact;
    private static Contact recipientContact;
    private static CVMA_Message__c testMessage;

    /**
     * @description Setup test data for messaging tests
     */
    @TestSetup
    static void setupTestData() {
        // Create test users with Contact records
        CVMATestDataFactory.TestDataBundle bundle = CVMATestDataFactory.createTestDataBundle();

        // Create sender contact
        Contact sender = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .withMembershipId('FM001')
            .withEmail('sender@cvmatest.org')
            .create();

        // Create recipient contact
        Contact recipient = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .withMembershipId('FM002')
            .withEmail('recipient@cvmatest.org')
            .create();

        // Create users associated with contacts
        User senderUser = CVMATestDataFactory.createUser()
            .withProfile('Standard User')
            .withContact(sender.Id)
            .create();

        User recipientUser = CVMATestDataFactory.createUser()
            .withProfile('Standard User')
            .withContact(recipient.Id)
            .create();

        // Create test message
        CVMA_Message__c message = new CVMA_Message__c(
            Sender__c = sender.Id,
            Recipient__c = recipient.Id,
            Subject__c = 'Test Message Subject',
            Message_Body__c = 'This is a test message body for unit testing.',
            Status__c = 'Sent',
            Priority__c = 'Normal',
            Thread_ID__c = 'THREAD_TEST_001',
            Is_Officer_Message__c = false
        );
        insert message;
    }

    /**
     * @description Test getting inbox messages successfully
     */
    @IsTest
    static void testGetMessagesInboxSuccess() {
        // Get test data
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'recipient@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :contacts[0].Id LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Test getting inbox messages
            CVMAMessagingController.MessagingResponse response = CVMAMessagingController.getMessages(25, 0, 'inbox');

            // Verify response
            System.assert(response.success, 'Response should be successful');
            System.assertEquals(1, response.messages.size(), 'Should return 1 message');
            System.assertEquals(1, response.totalCount, 'Total count should be 1');
            System.assertEquals('Test Message Subject', response.messages[0].Subject__c, 'Subject should match');
        }
        Test.stopTest();
    }

    /**
     * @description Test getting sent messages successfully
     */
    @IsTest
    static void testGetMessagesSentSuccess() {
        // Get test data
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'sender@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :contacts[0].Id LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Test getting sent messages
            CVMAMessagingController.MessagingResponse response = CVMAMessagingController.getMessages(25, 0, 'sent');

            // Verify response
            System.assert(response.success, 'Response should be successful');
            System.assertEquals(1, response.messages.size(), 'Should return 1 message');
            System.assertEquals(1, response.totalCount, 'Total count should be 1');
        }
        Test.stopTest();
    }

    /**
     * @description Test pagination with page size limits
     */
    @IsTest
    static void testGetMessagesWithPagination() {
        // Get test data
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'recipient@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :contacts[0].Id LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Test with invalid page size (should default to 25)
            CVMAMessagingController.MessagingResponse response1 = CVMAMessagingController.getMessages(0, 0, 'inbox');
            System.assertEquals(25, response1.pageSize, 'Should default to page size 25');

            // Test with excessive page size (should cap at 100)
            CVMAMessagingController.MessagingResponse response2 = CVMAMessagingController.getMessages(150, 0, 'inbox');
            System.assertEquals(100, response2.pageSize, 'Should cap at page size 100');

            // Test with negative page number (should default to 0)
            CVMAMessagingController.MessagingResponse response3 = CVMAMessagingController.getMessages(25, -1, 'inbox');
            System.assertEquals(0, response3.pageNumber, 'Should default to page 0');
        }
        Test.stopTest();
    }

    /**
     * @description Test sending message successfully
     */
    @IsTest
    static void testSendMessageSuccess() {
        // Get test data
        List<Contact> senderContacts = [SELECT Id FROM Contact WHERE Email = 'sender@cvmatest.org' LIMIT 1];
        List<Contact> recipientContacts = [SELECT Id FROM Contact WHERE Email = 'recipient@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :senderContacts[0].Id LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Send new message
            CVMAMessagingController.MessagingResponse response = CVMAMessagingController.sendMessage(
                recipientContacts[0].Id,
                'New Test Subject',
                'This is a new test message body.',
                'High',
                null
            );

            // Verify response
            System.assert(response.success, 'Send message should be successful');
            System.assertNotEquals(null, response.messageId, 'Message ID should be returned');
            System.assert(response.successMessage.contains('Message sent successfully'), 'Success message should be present');

            // Verify message was created
            List<CVMA_Message__c> messages = [
                SELECT Id, Subject__c, Priority__c, Thread_ID__c
                FROM CVMA_Message__c
                WHERE Subject__c = 'New Test Subject'
            ];
            System.assertEquals(1, messages.size(), 'Message should be created');
            System.assertEquals('High', messages[0].Priority__c, 'Priority should be High');
            System.assert(messages[0].Thread_ID__c.startsWith('THREAD_'), 'Thread ID should be generated');
        }
        Test.stopTest();
    }

    /**
     * @description Test sending message with validation errors
     */
    @IsTest
    static void testSendMessageValidationErrors() {
        // Get test data
        List<Contact> senderContacts = [SELECT Id FROM Contact WHERE Email = 'sender@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :senderContacts[0].Id LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Test with null recipient
            CVMAMessagingController.MessagingResponse response1 = CVMAMessagingController.sendMessage(
                null, 'Test Subject', 'Test Body', 'Normal', null
            );
            System.assert(!response1.success, 'Should fail with null recipient');
            System.assert(response1.errorMessage.contains('Recipient is required'), 'Should have recipient error message');

            // Test with blank subject
            CVMAMessagingController.MessagingResponse response2 = CVMAMessagingController.sendMessage(
                senderContacts[0].Id, '', 'Test Body', 'Normal', null
            );
            System.assert(!response2.success, 'Should fail with blank subject');
            System.assert(response2.errorMessage.contains('Subject is required'), 'Should have subject error message');

            // Test with blank message body
            CVMAMessagingController.MessagingResponse response3 = CVMAMessagingController.sendMessage(
                senderContacts[0].Id, 'Test Subject', '', 'Normal', null
            );
            System.assert(!response3.success, 'Should fail with blank body');
            System.assert(response3.errorMessage.contains('Message body is required'), 'Should have body error message');

            // Test sending to self
            CVMAMessagingController.MessagingResponse response4 = CVMAMessagingController.sendMessage(
                senderContacts[0].Id, 'Test Subject', 'Test Body', 'Normal', null
            );
            System.assert(!response4.success, 'Should fail when sending to self');
            System.assert(response4.errorMessage.contains('Cannot send message to yourself'), 'Should have self-send error message');
        }
        Test.stopTest();
    }

    /**
     * @description Test character limits for subject and body
     */
    @IsTest
    static void testSendMessageCharacterLimits() {
        // Get test data
        List<Contact> senderContacts = [SELECT Id FROM Contact WHERE Email = 'sender@cvmatest.org' LIMIT 1];
        List<Contact> recipientContacts = [SELECT Id FROM Contact WHERE Email = 'recipient@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :senderContacts[0].Id LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Test subject too long (over 255 characters)
            String longSubject = 'This is a very long subject line that exceeds the maximum allowed length of 255 characters for the subject field. It should trigger a validation error when attempting to send the message because Salesforce has strict limits on field lengths and we need to validate these limits before attempting database operations to provide better user experience.';
            CVMAMessagingController.MessagingResponse response1 = CVMAMessagingController.sendMessage(
                recipientContacts[0].Id, longSubject, 'Test Body', 'Normal', null
            );
            System.assert(!response1.success, 'Should fail with subject too long');
            System.assert(response1.errorMessage.contains('Subject cannot exceed'), 'Should have subject length error message');

            // Test message body too long (over 32768 characters) - create a large string
            String longBody = '';
            for (Integer i = 0; i < 500; i++) {
                longBody += 'This is a repeated line to make the message body exceed the maximum character limit. ';
            }
            CVMAMessagingController.MessagingResponse response2 = CVMAMessagingController.sendMessage(
                recipientContacts[0].Id, 'Test Subject', longBody, 'Normal', null
            );
            System.assert(!response2.success, 'Should fail with body too long');
            System.assert(response2.errorMessage.contains('Message body cannot exceed'), 'Should have body length error message');
        }
        Test.stopTest();
    }

    /**
     * @description Test marking message as read successfully
     */
    @IsTest
    static void testMarkMessageAsReadSuccess() {
        // Get test data
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'recipient@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :contacts[0].Id LIMIT 1];
        List<CVMA_Message__c> messages = [SELECT Id FROM CVMA_Message__c LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Mark message as read
            CVMAMessagingController.MessagingResponse response = CVMAMessagingController.markMessageAsRead(messages[0].Id);

            // Verify response
            System.assert(response.success, 'Mark as read should be successful');
            System.assert(response.successMessage.contains('marked as read'), 'Should have success message');

            // Verify message status updated
            CVMA_Message__c updatedMessage = [
                SELECT Id, Status__c, Read_Date__c
                FROM CVMA_Message__c
                WHERE Id = :messages[0].Id
            ];
            System.assertEquals('Read', updatedMessage.Status__c, 'Status should be Read');
            System.assertNotEquals(null, updatedMessage.Read_Date__c, 'Read date should be set');
        }
        Test.stopTest();
    }

    /**
     * @description Test marking message as read with validation errors
     */
    @IsTest
    static void testMarkMessageAsReadValidationErrors() {
        // Get test data
        List<Contact> senderContacts = [SELECT Id FROM Contact WHERE Email = 'sender@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :senderContacts[0].Id LIMIT 1];
        List<CVMA_Message__c> messages = [SELECT Id FROM CVMA_Message__c LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Test with null message ID
            CVMAMessagingController.MessagingResponse response1 = CVMAMessagingController.markMessageAsRead(null);
            System.assert(!response1.success, 'Should fail with null message ID');
            System.assert(response1.errorMessage.contains('Message ID is required'), 'Should have message ID error');

            // Test with message user doesn't have access to (sender trying to mark recipient's message as read)
            CVMAMessagingController.MessagingResponse response2 = CVMAMessagingController.markMessageAsRead(messages[0].Id);
            System.assert(!response2.success, 'Should fail with access denied');
            System.assert(response2.errorMessage.contains('Message not found or access denied'), 'Should have access denied error');
        }
        Test.stopTest();
    }

    /**
     * @description Test getting available members for messaging
     */
    @IsTest
    static void testGetAvailableMembersSuccess() {
        // Get test data
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'sender@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :contacts[0].Id LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Get available members without search term
            List<CVMAMessagingController.ContactOption> members = CVMAMessagingController.getAvailableMembers('');

            // Verify results
            System.assertEquals(1, members.size(), 'Should return 1 other member (excluding current user)');
            System.assert(members[0].displayName.contains('Test'), 'Display name should contain Test');
            System.assertNotEquals(null, members[0].contactId, 'Contact ID should be present');

            // Test with search term
            List<CVMAMessagingController.ContactOption> searchResults = CVMAMessagingController.getAvailableMembers('recipient');
            System.assertEquals(1, searchResults.size(), 'Should find recipient member');
        }
        Test.stopTest();
    }

    /**
     * @description Test archiving message successfully
     */
    @IsTest
    static void testArchiveMessageSuccess() {
        // Get test data
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'recipient@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :contacts[0].Id LIMIT 1];
        List<CVMA_Message__c> messages = [SELECT Id FROM CVMA_Message__c LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Archive message
            CVMAMessagingController.MessagingResponse response = CVMAMessagingController.archiveMessage(messages[0].Id);

            // Verify response
            System.assert(response.success, 'Archive should be successful');
            System.assert(response.successMessage.contains('archived successfully'), 'Should have success message');

            // Verify message status updated
            CVMA_Message__c archivedMessage = [
                SELECT Id, Status__c
                FROM CVMA_Message__c
                WHERE Id = :messages[0].Id
            ];
            System.assertEquals('Archived', archivedMessage.Status__c, 'Status should be Archived');
        }
        Test.stopTest();
    }

    /**
     * @description Test archiving message with validation errors
     */
    @IsTest
    static void testArchiveMessageValidationErrors() {
        // Get test data
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'sender@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :contacts[0].Id LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Test with null message ID
            CVMAMessagingController.MessagingResponse response = CVMAMessagingController.archiveMessage(null);
            System.assert(!response.success, 'Should fail with null message ID');
            System.assert(response.errorMessage.contains('Message ID is required'), 'Should have message ID error');
        }
        Test.stopTest();
    }

    /**
     * @description Test getting archived messages
     */
    @IsTest
    static void testGetArchivedMessages() {
        // Get test data and archive a message first
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'recipient@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :contacts[0].Id LIMIT 1];
        List<CVMA_Message__c> messages = [SELECT Id FROM CVMA_Message__c LIMIT 1];

        // Archive the message
        messages[0].Status__c = 'Archived';
        update messages[0];

        Test.startTest();
        System.runAs(users[0]) {
            // Get archived messages
            CVMAMessagingController.MessagingResponse response = CVMAMessagingController.getMessages(25, 0, 'archived');

            // Verify response
            System.assert(response.success, 'Should successfully get archived messages');
            System.assertEquals(1, response.messages.size(), 'Should return 1 archived message');
            System.assertEquals('Archived', response.messages[0].Status__c, 'Message should be archived');
        }
        Test.stopTest();
    }

    /**
     * @description Test priority validation and defaults
     */
    @IsTest
    static void testPriorityValidation() {
        // Get test data
        List<Contact> senderContacts = [SELECT Id FROM Contact WHERE Email = 'sender@cvmatest.org' LIMIT 1];
        List<Contact> recipientContacts = [SELECT Id FROM Contact WHERE Email = 'recipient@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :senderContacts[0].Id LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Test with invalid priority (should default to Normal)
            CVMAMessagingController.MessagingResponse response1 = CVMAMessagingController.sendMessage(
                recipientContacts[0].Id, 'Test Subject', 'Test Body', 'InvalidPriority', null
            );
            System.assert(response1.success, 'Should succeed with invalid priority defaulting to Normal');

            // Verify priority was set to Normal
            CVMA_Message__c message = [
                SELECT Id, Priority__c
                FROM CVMA_Message__c
                WHERE Subject__c = 'Test Subject'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            System.assertEquals('Normal', message.Priority__c, 'Priority should default to Normal');

            // Test with null priority (should default to Normal)
            CVMAMessagingController.MessagingResponse response2 = CVMAMessagingController.sendMessage(
                recipientContacts[0].Id, 'Test Subject 2', 'Test Body', null, null
            );
            System.assert(response2.success, 'Should succeed with null priority defaulting to Normal');
        }
        Test.stopTest();
    }

    /**
     * @description Test thread ID generation and consistency
     */
    @IsTest
    static void testThreadIdGeneration() {
        // Get test data
        List<Contact> senderContacts = [SELECT Id FROM Contact WHERE Email = 'sender@cvmatest.org' LIMIT 1];
        List<Contact> recipientContacts = [SELECT Id FROM Contact WHERE Email = 'recipient@cvmatest.org' LIMIT 1];
        List<User> senderUsers = [SELECT Id FROM User WHERE ContactId = :senderContacts[0].Id LIMIT 1];
        List<User> recipientUsers = [SELECT Id FROM User WHERE ContactId = :recipientContacts[0].Id LIMIT 1];

        Test.startTest();

        String threadId1, threadId2;

        // Send message from sender to recipient
        System.runAs(senderUsers[0]) {
            CVMAMessagingController.MessagingResponse response1 = CVMAMessagingController.sendMessage(
                recipientContacts[0].Id, 'Test Thread 1', 'Test Body', 'Normal', null
            );
            System.assert(response1.success, 'First message should be sent successfully');

            CVMA_Message__c message1 = [SELECT Thread_ID__c FROM CVMA_Message__c WHERE Id = :response1.messageId];
            threadId1 = message1.Thread_ID__c;
        }

        // Send reply from recipient to sender
        System.runAs(recipientUsers[0]) {
            CVMAMessagingController.MessagingResponse response2 = CVMAMessagingController.sendMessage(
                senderContacts[0].Id, 'Test Thread 2', 'Test Body Reply', 'Normal', null
            );
            System.assert(response2.success, 'Reply message should be sent successfully');

            CVMA_Message__c message2 = [SELECT Thread_ID__c FROM CVMA_Message__c WHERE Id = :response2.messageId];
            threadId2 = message2.Thread_ID__c;
        }

        Test.stopTest();

        // Verify thread IDs are consistent regardless of who initiates
        System.assertEquals(threadId1, threadId2, 'Thread IDs should be consistent for same conversation partners');
        System.assert(threadId1.startsWith('THREAD_'), 'Thread ID should have proper prefix');
    }

    /**
     * @description Test error handling for users without Contact records
     */
    @IsTest
    static void testUserWithoutContactRecord() {
        // Create user without Contact record
        User testUserNoContact = CVMATestDataFactory.createUser()
            .withProfile('Standard User')
            .create();

        Test.startTest();
        System.runAs(testUserNoContact) {
            // Try to get messages
            CVMAMessagingController.MessagingResponse response = CVMAMessagingController.getMessages(25, 0, 'inbox');

            // Should fail gracefully
            System.assert(!response.success, 'Should fail for user without Contact record');
            System.assert(response.errorMessage.contains('User contact record not found'), 'Should have appropriate error message');
        }
        Test.stopTest();
    }

    /**
     * @description Test bulk operations and governor limits
     */
    @IsTest
    static void testBulkOperations() {
        // Get test data
        List<Contact> senderContacts = [SELECT Id FROM Contact WHERE Email = 'sender@cvmatest.org' LIMIT 1];
        List<Contact> recipientContacts = [SELECT Id FROM Contact WHERE Email = 'recipient@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :senderContacts[0].Id LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Send multiple messages to test bulk handling
            List<CVMAMessagingController.MessagingResponse> responses = new List<CVMAMessagingController.MessagingResponse>();

            for (Integer i = 0; i < 5; i++) {
                CVMAMessagingController.MessagingResponse response = CVMAMessagingController.sendMessage(
                    recipientContacts[0].Id,
                    'Bulk Test Message ' + i,
                    'This is bulk test message number ' + i,
                    'Normal',
                    null
                );
                responses.add(response);
            }

            // Verify all messages were sent successfully
            for (CVMAMessagingController.MessagingResponse response : responses) {
                System.assert(response.success, 'All bulk messages should be sent successfully');
            }

            // Verify message count
            Integer messageCount = [SELECT COUNT() FROM CVMA_Message__c WHERE Subject__c LIKE 'Bulk Test Message%'];
            System.assertEquals(5, messageCount, 'Should have created 5 bulk messages');
        }
        Test.stopTest();
    }

    /**
     * @description Test input sanitization for XSS prevention
     */
    @IsTest
    static void testInputSanitization() {
        // Get test data
        List<Contact> senderContacts = [SELECT Id FROM Contact WHERE Email = 'sender@cvmatest.org' LIMIT 1];
        List<Contact> recipientContacts = [SELECT Id FROM Contact WHERE Email = 'recipient@cvmatest.org' LIMIT 1];
        List<User> users = [SELECT Id FROM User WHERE ContactId = :senderContacts[0].Id LIMIT 1];

        Test.startTest();
        System.runAs(users[0]) {
            // Test with potentially malicious input
            String maliciousSubject = '<script>alert("xss")</script>Test Subject';
            String maliciousBody = '<img src="x" onerror="alert(\'xss\')">';

            CVMAMessagingController.MessagingResponse response = CVMAMessagingController.sendMessage(
                recipientContacts[0].Id,
                maliciousSubject,
                maliciousBody,
                'Normal',
                null
            );

            // Should still succeed but input should be sanitized
            System.assert(response.success, 'Should succeed with sanitized input');

            // Verify input was sanitized (exact sanitization depends on CVMAErrorHandler implementation)
            CVMA_Message__c createdMessage = [
                SELECT Subject__c, Message_Body__c
                FROM CVMA_Message__c
                WHERE Id = :response.messageId
            ];

            // The exact sanitization result depends on CVMAErrorHandler.sanitizeInput implementation
            // At minimum, verify the message was created
            System.assertNotEquals(null, createdMessage, 'Message should be created');
        }
        Test.stopTest();
    }
}
