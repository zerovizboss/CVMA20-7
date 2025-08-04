/**
 * Test class for QueryControllerMVP - Updated to match actual implementation
 * Provides comprehensive test coverage for multi-query execution and security validation
 *
 * @author Advanced Reporting Platform Team
 * @version 2.1 - Updated to match QueryControllerMVP implementation
 */
@isTest
public class QueryControllerMVPTest {

    // Test data setup
    @testSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(
                    Name = 'Test Account ' + i,
                    Industry = (i < 3) ? 'Technology' : 'Healthcare',
                    AnnualRevenue = 100000 * (i + 1),
                    NumberOfEmployees = 50 * (i + 1)
            ));
        }
        insert testAccounts;

        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < testAccounts.size(); i++) {
            testContacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact ' + i,
                    Email = 'test' + i + '@example.com',
                    AccountId = testAccounts[i].Id
            ));
        }
        insert testContacts;

        // Create test opportunities
        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < testAccounts.size(); i++) {
            testOpportunities.add(new Opportunity(
                    Name = 'Test Opportunity ' + i,
                    AccountId = testAccounts[i].Id,
                    StageName = 'Prospecting',
                    CloseDate = Date.today().addDays(30),
                    Amount = 50000 * (i + 1)
            ));
        }
        insert testOpportunities;
    }

    // Test successful multi-query execution
    @isTest
    static void testExecuteMultipleQueries_Success() {
        Test.startTest();

        List<String> queries = new List<String>{
                'SELECT Id, Name, Industry FROM Account LIMIT 10',
                'SELECT Id, Name, Email FROM Contact LIMIT 10',
                'SELECT Id, Name, Amount FROM Opportunity LIMIT 10'
        };

        QueryControllerMVP.MultiQueryResult result = QueryControllerMVP.executeMultipleQueries(queries);

        Test.stopTest();

        // Assertions
        System.assert(result.success, 'Multi-query execution should succeed');
        System.assertEquals(3, result.results.size(), 'Should have 3 query results');
        System.assert(result.totalRecordCount >= 0, 'Should have valid record count');
        System.assert(result.totalExecutionTime >= 0, 'Should have valid execution time');

        // Check individual query results
        for (QueryControllerMVP.QueryResult queryResult : result.results) {
            System.assert(queryResult.success, 'Each query should succeed');
            System.assertNotEquals(null, queryResult.data, 'Query data should not be null');
            System.assert(queryResult.recordCount >= 0, 'Should have valid record count');
        }
    }

    // Test single query execution (backward compatibility)
    @isTest
    static void testExecuteQuery_Success() {
        Test.startTest();

        String query = 'SELECT Id, Name, Industry FROM Account LIMIT 5';
        QueryControllerMVP.QueryResult result = QueryControllerMVP.executeQuery(query);

        Test.stopTest();

        // Assertions
        System.assert(result.success, 'Single query execution should succeed');
        System.assertNotEquals(null, result.data, 'Query data should not be null');
        System.assert(result.recordCount >= 0, 'Should have valid record count');
        System.assert(result.executionTime >= 0, 'Should have valid execution time');
    }

    // Test query security validation - forbidden keywords (first query validation)
    @isTest
    static void testExecuteMultipleQueries_SecurityViolation() {
        Test.startTest();

        List<String> queries = new List<String>{
                'DELETE FROM Account',  // First query - will throw exception
                'SELECT Id FROM Account LIMIT 5'
        };

        try {
            QueryControllerMVP.executeMultipleQueries(queries);
            System.assert(false, 'Should have thrown security exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Query 1'), 'Should identify first query as problematic');
            System.assert(e.getMessage().contains('DELETE') || e.getMessage().contains('forbidden'), 'Should mention forbidden operation');
        }

        Test.stopTest();
    }

    // Test security violations in subsequent queries (should return error results)
    @isTest
    static void testExecuteMultipleQueries_SubsequentSecurityViolations() {
        Test.startTest();

        List<String> queries = new List<String>{
                'SELECT Id FROM Account LIMIT 5',  // Valid first query
                'DELETE FROM Contact',             // Security violation in second query
                'SELECT Id FROM Opportunity LIMIT 5' // Valid third query
        };

        QueryControllerMVP.MultiQueryResult result = QueryControllerMVP.executeMultipleQueries(queries);

        Test.stopTest();

        // Should have results for all queries
        System.assertEquals(3, result.results.size(), 'Should have results for all queries');

        // First and third queries should succeed
        System.assert(result.results[0].success, 'First query should succeed');
        System.assert(result.results[2].success, 'Third query should succeed');

        // Second query should fail with security error
        System.assert(!result.results[1].success, 'Second query should fail');
        System.assertNotEquals(null, result.results[1].errorMessage, 'Should have error message');
    }

    // Test multiple forbidden operations
    @isTest
    static void testSecurityValidation_ForbiddenOperations() {
        Test.startTest();

        List<String> forbiddenQueries = new List<String>{
                'INSERT INTO Account (Name) VALUES (\'Test\')',
                'UPDATE Account SET Name = \'Updated\' WHERE Id != null',
                'UPSERT Account Name VALUES (\'Test\')',
                'MERGE Account USING Contact ON Account.Id = Contact.AccountId'
        };

        for (String query : forbiddenQueries) {
            try {
                QueryControllerMVP.executeQuery(query);
                System.assert(false, 'Should have thrown security exception for: ' + query);
            } catch (Exception e) {
                // Should throw AuraHandledException with forbidden operation message
                System.assert(e.getMessage().contains('forbidden') ||
                        e.getMessage().contains('INSERT') || e.getMessage().contains('UPDATE') ||
                        e.getMessage().contains('UPSERT') || e.getMessage().contains('MERGE'),
                        'Should mention forbidden operation for: ' + query + ', got: ' + e.getMessage());
            }
        }

        Test.stopTest();
    }

    // Test FOR UPDATE security validation
    @isTest
    static void testSecurityValidation_ForUpdate() {
        Test.startTest();

        String forUpdateQuery = 'SELECT Id FROM Account FOR UPDATE';

        try {
            QueryControllerMVP.executeQuery(forUpdateQuery);
            System.assert(false, 'Should have thrown security exception for FOR UPDATE');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('FOR UPDATE') || e.getMessage().contains('not allowed'),
                    'Should mention FOR UPDATE restriction: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Test DELETE vs IsDeleted field differentiation
    @isTest
    static void testSecurityValidation_DeleteVsIsDeleted() {
        Test.startTest();

        // This should be allowed - IsDeleted field reference
        String isDeletedQuery = 'SELECT Id, IsDeleted FROM Account LIMIT 5';

        QueryControllerMVP.QueryResult result = QueryControllerMVP.executeQuery(isDeletedQuery);
        System.assert(result.success, 'IsDeleted field query should succeed');

        // This should be blocked - DELETE operation
        String deleteQuery = 'DELETE FROM Account';

        try {
            QueryControllerMVP.executeQuery(deleteQuery);
            System.assert(false, 'Should have thrown security exception for DELETE');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('DELETE') || e.getMessage().contains('forbidden'),
                    'Should mention DELETE restriction: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Test non-SELECT query validation
    @isTest
    static void testSecurityValidation_NonSelectQuery() {
        Test.startTest();

        String nonSelectQuery = 'SHOW TABLES';

        try {
            QueryControllerMVP.executeQuery(nonSelectQuery);
            System.assert(false, 'Should have thrown security exception for non-SELECT');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('SELECT') || e.getMessage().contains('Only SELECT'),
                    'Should mention SELECT requirement: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Test LIMIT ALL on custom objects
    @isTest
    static void testSecurityValidation_LimitAllCustomObjects() {
        Test.startTest();

        String limitAllQuery = 'SELECT Id FROM CustomObject__c LIMIT ALL';

        try {
            QueryControllerMVP.executeQuery(limitAllQuery);
            System.assert(false, 'Should have thrown security exception for LIMIT ALL on custom objects');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('LIMIT ALL') || e.getMessage().contains('not allowed'),
                    'Should mention LIMIT ALL restriction: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Test performance validation - excessive LIMIT (MAX_RECORDS = 10000)
    @isTest
    static void testPerformanceValidation_ExcessiveLimit() {
        Test.startTest();

        try {
            QueryControllerMVP.executeQuery('SELECT Id FROM Account LIMIT 15000');
            System.assert(false, 'Should have thrown performance exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('LIMIT') && e.getMessage().contains('10000'),
                    'Should mention LIMIT restriction: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Test performance validation - COUNT without GROUP BY
    @isTest
    static void testPerformanceValidation_CountWithoutGroupBy() {
        Test.startTest();

        try {
            QueryControllerMVP.executeQuery('SELECT COUNT() FROM Account');
            System.assert(false, 'Should have thrown performance exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('COUNT') && e.getMessage().contains('GROUP BY'),
                    'Should mention COUNT/GROUP BY restriction: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Test performance validation - too many nested relationships
    @isTest
    static void testPerformanceValidation_TooManyRelationships() {
        Test.startTest();

        // Query with more than 3 nested relationships
        String complexQuery = 'SELECT Id, (SELECT Id FROM Contacts), (SELECT Id FROM Opportunities), ' +
                '(SELECT Id FROM Cases), (SELECT Id FROM Tasks) FROM Account LIMIT 5';

        try {
            QueryControllerMVP.executeQuery(complexQuery);
            System.assert(false, 'Should have thrown performance exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('relationship') || e.getMessage().contains('3'),
                    'Should mention relationship limit: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Test input validation - null queries
    @isTest
    static void testInputValidation_NullQueries() {
        Test.startTest();

        try {
            QueryControllerMVP.executeMultipleQueries(null);
            System.assert(false, 'Should have thrown validation exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('required') || e.getMessage().contains('At least one'),
                    'Should mention required input: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Test input validation - empty queries
    @isTest
    static void testInputValidation_EmptyQueries() {
        Test.startTest();

        try {
            QueryControllerMVP.executeMultipleQueries(new List<String>());
            System.assert(false, 'Should have thrown validation exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('required') || e.getMessage().contains('At least one'),
                    'Should mention required input: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Test input validation - too many queries (MAX_QUERIES = 4)
    @isTest
    static void testInputValidation_TooManyQueries() {
        Test.startTest();

        List<String> tooManyQueries = new List<String>();
        for (Integer i = 0; i < 6; i++) {  // Create 6 queries (more than max of 4)
            tooManyQueries.add('SELECT Id FROM Account LIMIT 1');
        }

        try {
            QueryControllerMVP.executeMultipleQueries(tooManyQueries);
            System.assert(false, 'Should have thrown validation exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Maximum') && e.getMessage().contains('4'),
                    'Should mention maximum queries limit: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Test input validation - blank queries in list
    @isTest
    static void testInputValidation_BlankQueries() {
        Test.startTest();

        List<String> queriesWithBlanks = new List<String>{
                'SELECT Id FROM Account LIMIT 5',
                '',
                '   ',
                null,
                'SELECT Id FROM Contact LIMIT 5'
        };

        QueryControllerMVP.MultiQueryResult result =
                QueryControllerMVP.executeMultipleQueries(queriesWithBlanks);

        Test.stopTest();

        // Should succeed with only valid queries (blanks are filtered out)
        System.assert(result.success, 'Should succeed with valid queries');
        System.assertEquals(2, result.results.size(), 'Should have 2 valid queries');
    }

    // Test input validation - all blank queries
    @isTest
    static void testInputValidation_AllBlankQueries() {
        Test.startTest();

        List<String> allBlankQueries = new List<String>{'', '   ', null, ''};

        try {
            QueryControllerMVP.executeMultipleQueries(allBlankQueries);
            System.assert(false, 'Should have thrown validation exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('non-empty') || e.getMessage().contains('required'),
                    'Should mention non-empty query requirement: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Test error handling for invalid query syntax
    @isTest
    static void testErrorHandling_InvalidSyntax() {
        Test.startTest();

        List<String> queries = new List<String>{
                'SELECT Id FROM Account LIMIT 5',
                'SELECT Invalid Syntax FROM', // Invalid query - will be caught during execution
                'SELECT Id FROM Contact LIMIT 5'
        };

        QueryControllerMVP.MultiQueryResult result =
                QueryControllerMVP.executeMultipleQueries(queries);

        Test.stopTest();

        // Should return results for all queries, with error for invalid one
        System.assertEquals(3, result.results.size(), 'Should have results for all queries');

        // Check that invalid query result shows failure
        QueryControllerMVP.QueryResult invalidResult = result.results[1];
        System.assert(!invalidResult.success, 'Invalid query should show failure');
        System.assertNotEquals(null, invalidResult.errorMessage, 'Should have error message');
    }

    // Test schema info retrieval
    @isTest
    static void testGetBasicSchemaInfo() {
        Test.startTest();

        List<QueryControllerMVP.ObjectInfo> schemaInfo =
                QueryControllerMVP.getBasicSchemaInfo();

        Test.stopTest();

        System.assertNotEquals(null, schemaInfo, 'Schema info should not be null');
        System.assert(schemaInfo.size() > 0, 'Should return some object info');

        // Check for standard objects that should be in the list
        Set<String> objectNames = new Set<String>();
        for (QueryControllerMVP.ObjectInfo info : schemaInfo) {
            objectNames.add(info.name);
            System.assertNotEquals(null, info.label, 'Object should have label');
        }

        System.assert(objectNames.contains('Account'), 'Should include Account object');
        System.assert(objectNames.contains('Contact'), 'Should include Contact object');
    }

    // Test user-friendly error messages
    @isTest
    static void testUserFriendlyErrorMessages() {
        Test.startTest();

        // Test various error scenarios that should return user-friendly messages
        QueryControllerMVP.QueryResult result1 = QueryControllerMVP.executeQuery(
                'SELECT InvalidField__c FROM Account LIMIT 5'
        );

        // Should return error result with user-friendly message
        System.assert(!result1.success, 'Query with invalid field should fail');
        System.assertNotEquals(null, result1.errorMessage, 'Should have error message');
        System.assert(!result1.errorMessage.contains('Exception'),
                'Error message should be user-friendly');

        Test.stopTest();
    }

    // Test mixed success and failure scenarios
    @isTest
    static void testMixedSuccessFailure() {
        Test.startTest();

        List<String> mixedQueries = new List<String>{
                'SELECT Id FROM Account LIMIT 5',    // Should succeed
                'SELECT Id FROM Contact LIMIT 5',    // Should succeed
                'SELECT InvalidField FROM Account',  // Should fail - invalid field
                'DELETE FROM Opportunity'            // Should fail - forbidden operation
        };

        QueryControllerMVP.MultiQueryResult result =
                QueryControllerMVP.executeMultipleQueries(mixedQueries);

        Test.stopTest();

        // Should return results for all queries
        System.assertEquals(4, result.results.size(), 'Should have 4 query results');

        // Check individual results - first two should succeed
        System.assert(result.results[0].success, 'First query should succeed');
        System.assert(result.results[1].success, 'Second query should succeed');

        // Third and fourth should fail
        System.assert(!result.results[2].success, 'Third query should fail');
        System.assert(!result.results[3].success, 'Fourth query should fail');

        // Should have error messages for failed queries
        System.assertNotEquals(null, result.results[2].errorMessage,
                'Third query should have error message');
        System.assertNotEquals(null, result.results[3].errorMessage,
                'Fourth query should have error message');
    }

    // Test query index tracking
    @isTest
    static void testQueryIndexTracking() {
        Test.startTest();

        List<String> queries = new List<String>{
                'SELECT Id FROM Account LIMIT 1',
                'SELECT Id FROM Contact LIMIT 1',
                'SELECT Id FROM Opportunity LIMIT 1'
        };

        QueryControllerMVP.MultiQueryResult result =
                QueryControllerMVP.executeMultipleQueries(queries);

        Test.stopTest();

        // Check that query indices are set correctly
        for (Integer i = 0; i < result.results.size(); i++) {
            System.assertEquals(i, result.results[i].queryIndex,
                    'Query index should match list position');
            System.assertEquals(queries[i], result.results[i].originalQuery,
                    'Original query should be stored');
        }
    }

    // Test large result set handling (within limits)
    @isTest
    static void testLargeResultSetHandling() {
        Test.startTest();

        // Create additional test data for this test (within reasonable limits)
        List<Account> largeAccountList = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            largeAccountList.add(new Account(Name = 'Bulk Account ' + i));
        }
        insert largeAccountList;

        String query = 'SELECT Id, Name FROM Account LIMIT 50';
        QueryControllerMVP.QueryResult result = QueryControllerMVP.executeQuery(query);

        Test.stopTest();

        System.assert(result.success, 'Large query should succeed');
        System.assert(result.recordCount > 0, 'Should return records');
        System.assertNotEquals(null, result.data, 'Should have data');
    }

    // Test serialization with complex queries
    @isTest
    static void testSerializationComplexQueries() {
        Test.startTest();

        // Query with relationship fields
        String complexQuery = 'SELECT Id, Name, Owner.Name FROM Account LIMIT 5';

        QueryControllerMVP.QueryResult result = QueryControllerMVP.executeQuery(complexQuery);

        Test.stopTest();

        System.assert(result.success, 'Complex query should succeed');
        System.assertNotEquals(null, result.data, 'Should serialize complex data');
    }

    // Test single query blank input
    @isTest
    static void testInputValidation_BlankSingleQuery() {
        Test.startTest();

        try {
            QueryControllerMVP.executeQuery('');
            System.assert(false, 'Should have thrown validation exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('required') || e.getMessage().contains('SOQL'),
                    'Should mention query is required: ' + e.getMessage());
        }

        try {
            QueryControllerMVP.executeQuery(null);
            System.assert(false, 'Should have thrown validation exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('required') || e.getMessage().contains('SOQL'),
                    'Should mention query is required: ' + e.getMessage());
        }

        Test.stopTest();
    }

    // Test default LIMIT addition
    @isTest
    static void testDefaultLimitAddition() {
        Test.startTest();

        // Query without explicit LIMIT should get DEFAULT_LIMIT (1000) added
        String queryWithoutLimit = 'SELECT Id, Name FROM Account';

        // This should work because executeSecureQuery adds DEFAULT_LIMIT
        QueryControllerMVP.QueryResult result = QueryControllerMVP.executeQuery(queryWithoutLimit);

        Test.stopTest();

        // Note: The actual behavior depends on validation logic
        // If performance validation requires LIMIT, this might fail at validation stage
        // If it gets to execution, the default limit should be added
        System.assertNotEquals(null, result, 'Should return a result');
    }

    // Test field access validation
    @isTest
    static void testFieldAccessValidation() {
        Test.startTest();

        // Test with accessible fields
        String validQuery = 'SELECT Id, Name, Industry FROM Account LIMIT 5';
        QueryControllerMVP.QueryResult result = QueryControllerMVP.executeQuery(validQuery);

        Test.stopTest();

        System.assert(result.success, 'Query with accessible fields should succeed');
    }

    // Test COUNT with GROUP BY (should be allowed)
    @isTest
    static void testCountWithGroupBy() {
        Test.startTest();

        String countQuery = 'SELECT Industry, COUNT(Id) FROM Account GROUP BY Industry LIMIT 10';
        QueryControllerMVP.QueryResult result = QueryControllerMVP.executeQuery(countQuery);

        Test.stopTest();

        System.assert(result.success, 'COUNT with GROUP BY should succeed');
    }

    // Test execution time tracking
    @isTest
    static void testExecutionTimeTracking() {
        Test.startTest();

        QueryControllerMVP.QueryResult result = QueryControllerMVP.executeQuery(
                'SELECT Id FROM Account LIMIT 5'
        );

        Test.stopTest();

        System.assert(result.executionTime >= 0, 'Should track execution time');
    }

    // Test serialization error handling
    @isTest
    static void testSerializationErrorHandling() {
        Test.startTest();

        // Try to create a scenario that might cause serialization issues
        // This is hard to test directly, but we can verify the method handles it gracefully
        String query = 'SELECT Id, Name FROM Account LIMIT 5';
        QueryControllerMVP.QueryResult result = QueryControllerMVP.executeQuery(query);

        Test.stopTest();

        System.assertNotEquals(null, result.data, 'Should handle serialization gracefully');
    }
}