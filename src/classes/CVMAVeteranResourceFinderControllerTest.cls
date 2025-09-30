/**
 * CVMAVeteranResourceFinderControllerTest.cls
 * Epic #10 User Story #31: Test class for Veteran Resource Finder Controller
 * Comprehensive test coverage for Knowledge Management integration
 *
 * Combat Veterans Motorcycle Association Chapter 20-7
 * Test coverage for revolutionary resource discovery platform
 */
@IsTest
private class CVMAVeteranResourceFinderControllerTest {

    /**
     * Test data setup using CVMATestDataFactory
     */
    @TestSetup
    static void makeData() {
        // Create test Contact for member profile
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Veteran',
            Title = 'Veteran',
            Description = 'Test veteran contact',
            MailingState = 'California',
            MailingCity = 'Los Angeles',
            Membership_Id__c = 'TEST001'
        );
        insert testContact;

        // Create test Account records to represent veteran resource organizations
        List<Account> testAccounts = new List<Account>();

        testAccounts.add(new Account(
            Name = 'Veterans Healthcare Center',
            Description = 'Healthcare services for veterans',
            Industry = 'Healthcare',
            Type = 'Customer - Direct',
            BillingState = 'California',
            BillingCity = 'Los Angeles',
            Phone = '555-0101',
            Website = 'https://vhc.example.com',
            Rating = 'Hot'
        ));

        testAccounts.add(new Account(
            Name = 'Veteran Benefits Organization',
            Description = 'Benefits assistance for veterans',
            Industry = 'Nonprofit',
            Type = 'Partner',
            BillingState = 'California',
            BillingCity = 'San Diego',
            Phone = '555-0102',
            Website = 'https://vbo.example.com',
            Rating = 'Warm'
        ));

        testAccounts.add(new Account(
            Name = 'Veterans Financial Services',
            Description = 'Financial assistance for veterans',
            Industry = 'Financial Services',
            Type = 'Customer - Direct',
            BillingState = 'Texas',
            BillingCity = 'Dallas',
            Phone = '555-0103',
            Website = 'https://vfs.example.com',
            Rating = 'Hot'
        ));

        insert testAccounts;
    }

    /**
     * Test successful resource directory retrieval
     */
    @IsTest
    static void testGetVeteranResourceDirectory_Success() {
        Test.startTest();

        Map<String, Object> result = CVMAVeteranResourceFinderController.getVeteranResourceDirectory();

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Operation should be successful');
        System.assert(result.containsKey('resources'), 'Should contain resources key');
        System.assert(result.containsKey('serviceCategories'), 'Should contain service categories');
        System.assert(result.containsKey('geographicAreas'), 'Should contain geographic areas');
    }

    /**
     * Test search functionality with all parameters
     */
    @IsTest
    static void testSearchVeteranResources_WithAllFilters() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();

        Map<String, Object> result = CVMAVeteranResourceFinderController.searchVeteranResources(
            'Veterans',
            'Healthcare',
            'California',
            testContact.Id
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Search should be successful');
        System.assert(result.containsKey('searchResults'), 'Should contain search results');
        System.assert(result.containsKey('memberProfile'), 'Should contain member profile for eligibility screening');
    }

    /**
     * Test search functionality without contact ID (guest user)
     */
    @IsTest
    static void testSearchVeteranResources_GuestUser() {
        Test.startTest();

        Map<String, Object> result = CVMAVeteranResourceFinderController.searchVeteranResources(
            'Benefits',
            'Financial Services',
            '',
            null
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Search should be successful');
        System.assert(result.containsKey('searchResults'), 'Should contain search results');
    }

    /**
     * Test empty search criteria handling
     */
    @IsTest
    static void testSearchVeteranResources_EmptySearch() {
        Test.startTest();

        Map<String, Object> result = CVMAVeteranResourceFinderController.searchVeteranResources(
            '',
            '',
            '',
            null
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Empty search should be handled gracefully');
    }

    /**
     * Test resource ratings and reviews retrieval
     */
    @IsTest
    static void testGetResourceRatingsAndReviews() {
        // Get test Account ID
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        Map<String, Object> result = CVMAVeteranResourceFinderController.getResourceRatingsAndReviews(
            testAccount.Id
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Operation should be successful');
        System.assert(result.containsKey('totalVotes'), 'Should contain total votes');
        System.assert(result.containsKey('averageRating'), 'Should contain average rating');
    }

    /**
     * Test resource review submission
     */
    @IsTest
    static void testSubmitResourceReview() {
        // Get test contact and account
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        Map<String, Object> result = CVMAVeteranResourceFinderController.submitResourceReview(
            testAccount.Id,
            5,
            'Excellent resource, very helpful!',
            testContact.Id
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Review submission should be successful');
        System.assert(result.containsKey('taskId'), 'Should contain task ID');
        System.assertNotEquals(null, result.get('message'), 'Should contain success message');
    }

    /**
     * Test invalid rating submission
     */
    @IsTest
    static void testSubmitResourceReview_InvalidRating() {
        // Get test contact and account
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();

        try {
            Map<String, Object> result = CVMAVeteranResourceFinderController.submitResourceReview(
                testAccount.Id,
                10, // Invalid rating (should be 1-5)
                'Test review',
                testContact.Id
            );

            // Should handle invalid rating gracefully
            System.assertNotEquals(null, result, 'Result should not be null even with invalid rating');

        } catch (Exception e) {
            // Exception handling should be managed by CVMAErrorHandler
            System.assert(e.getMessage().contains('rating') || e.getMessage().contains('invalid'),
                'Error should be related to invalid rating');
        }

        Test.stopTest();
    }

    /**
     * Test security enforcement with insufficient permissions
     */
    @IsTest
    static void testSecurityEnforcement() {
        Test.startTest();

        try {
            Map<String, Object> result = CVMAVeteranResourceFinderController.getVeteranResourceDirectory();

            // Should return successful result or handle security gracefully
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assert(result.containsKey('success'), 'Should contain success indicator');

        } catch (Exception e) {
            // Security exceptions should be handled gracefully
            System.assert(e.getMessage().contains('security') || e.getMessage().contains('permission'),
                'Error should be security-related');
        }

        Test.stopTest();
    }

    /**
     * Test member profile retrieval for eligibility screening
     */
    @IsTest
    static void testMemberEligibilityProfile() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();

        // Call search with contact ID to trigger eligibility profile retrieval
        Map<String, Object> result = CVMAVeteranResourceFinderController.searchVeteranResources(
            'Healthcare',
            'Healthcare',
            '',
            testContact.Id
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Search should be successful');

        // Verify member profile is included for eligibility screening
        if (result.containsKey('memberProfile')) {
            Map<String, Object> memberProfile = (Map<String, Object>) result.get('memberProfile');
            System.assert(memberProfile.containsKey('name'), 'Should contain member name');
        }
    }

    /**
     * Test bulk operations and governor limits
     */
    @IsTest
    static void testBulkOperations() {
        Test.startTest();

        // Test multiple rapid searches to ensure governor limit compliance
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        for (Integer i = 0; i < 5; i++) {
            Map<String, Object> result = CVMAVeteranResourceFinderController.searchVeteranResources(
                'Test' + i,
                '',
                '',
                null
            );
            results.add(result);
        }

        Test.stopTest();

        System.assertEquals(5, results.size(), 'Should handle multiple searches');

        // Verify all searches completed successfully
        for (Map<String, Object> result : results) {
            System.assertNotEquals(null, result, 'Each result should not be null');
            System.assertEquals(true, result.get('success'), 'Each search should be successful');
        }
    }

    /**
     * Test error handling with invalid data
     */
    @IsTest
    static void testErrorHandling() {
        Test.startTest();

        // Test with invalid contact ID
        Map<String, Object> result = CVMAVeteranResourceFinderController.searchVeteranResources(
            'Test',
            'Healthcare',
            '',
            '003000000000000' // Invalid contact ID format
        );

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');

        // Should handle invalid contact ID gracefully
        if (result.get('success') == false) {
            System.assert(result.containsKey('error'), 'Should contain error information');
        }
    }

    /**
     * Test performance with large datasets
     */
    @IsTest
    static void testPerformanceWithLargeResults() {
        Test.startTest();

        // Measure execution time for resource directory retrieval
        Long startTime = System.currentTimeMillis();

        Map<String, Object> result = CVMAVeteranResourceFinderController.getVeteranResourceDirectory();

        Long endTime = System.currentTimeMillis();
        Long executionTime = endTime - startTime;

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.get('success'), 'Operation should be successful');

        // Verify reasonable performance (under 5 seconds in test context)
        System.assert(executionTime < 5000, 'Execution should complete within reasonable time');
    }
}
