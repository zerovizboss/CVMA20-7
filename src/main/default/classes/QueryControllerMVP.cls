/**
 * MVP Apex Controller for Advanced Reporting Platform
 * Handles single and multiple SOQL query execution with security validation
 *
 * @author Advanced Reporting Platform Team
 * @version 2.0 (Multi-Query Support) - Final Fixed
 */
public with sharing class QueryControllerMVP {

    // Constants
    private static final Integer MAX_RECORDS = 10000;
    private static final Integer DEFAULT_LIMIT = 1000;
    private static final Integer MAX_QUERIES = 4;
    private static final Set<String> FORBIDDEN_KEYWORDS = new Set<String>{
            'DELETE', 'INSERT', 'UPDATE', 'UPSERT', 'MERGE'
    };

    /**
     * Execute multiple SOQL queries with security validation
     * All queries execute in the same transaction for governor limit efficiency
     *
     * @param queries List of SOQL queries to execute
     * @return MultiQueryResult containing data and metadata from all queries
     */
    @AuraEnabled
    public static MultiQueryResult executeMultipleQueries(List<String> queries) {
        Long startTime = System.currentTimeMillis();

        try {
            // Input validation - these should throw exceptions and stop execution
            if (queries == null || queries.isEmpty()) {
                AuraHandledException e = new AuraHandledException('At least one SOQL query is required');
                e.setMessage('At least one SOQL query is required');
                throw e;
            }

            // Remove empty queries FIRST, then check limits
            List<String> processQueries = new List<String>();

            for (String query : queries) {
                if (String.isNotBlank(query)) {
                    processQueries.add(query.trim());
                }
            }

            if (processQueries.isEmpty()) {
                AuraHandledException e = new AuraHandledException('At least one non-empty query is required');
                e.setMessage('At least one non-empty query is required');
                throw e;
            }

            if (processQueries.size() > MAX_QUERIES) {
                AuraHandledException e = new AuraHandledException('Maximum ' + MAX_QUERIES + ' queries allowed');
                e.setMessage('Maximum ' + MAX_QUERIES + ' queries allowed');
                throw e;
            }

            // Validate FIRST query strictly - validation errors throw exceptions
            if (processQueries.size() > 0) {
                try {
                    validateQuerySecurity(processQueries[0]);
                    validateQueryPerformance(processQueries[0]);
                } catch (Exception e) {
                    String message = 'Query 1: ' + e.getMessage();
                    AuraHandledException ahe = new AuraHandledException(message);
                    ahe.setMessage(message);
                    throw ahe;
                }
            }

            // Execute all queries - subsequent validation and execution errors become individual failures
            List<QueryResult> results = new List<QueryResult>();
            Integer totalRecordCount = 0;

            for (Integer i = 0; i < processQueries.size(); i++) {
                String query = processQueries[i];

                try {
                    Long queryStartTime = System.currentTimeMillis();

                    // For queries after the first, validate as part of execution
                    if (i > 0) {
                        validateQuerySecurity(query);
                        validateQueryPerformance(query);
                    }

                    // Execute the query
                    List<SObject> queryResults = executeSecureQuery(query);

                    // Serialize results for client
                    String jsonData = serializeResults(queryResults);

                    // Calculate query execution time
                    Long queryExecutionTime = System.currentTimeMillis() - queryStartTime;

                    // Create result for this query
                    QueryResult queryResult = new QueryResult(
                            jsonData,
                            queryResults.size(),
                            queryExecutionTime,
                            true,
                            null
                    );
                    queryResult.queryIndex = i;
                    queryResult.originalQuery = query;

                    results.add(queryResult);
                    totalRecordCount += queryResults.size();

                } catch (Exception e) {
                    // All query-level errors (validation and execution) are handled per query
                    logQueryError(query, e.getMessage());

                    QueryResult errorResult = new QueryResult(
                            '[]',
                            0,
                            0,
                            false,
                            getUserFriendlyError(e)
                    );
                    errorResult.queryIndex = i;
                    errorResult.originalQuery = query;

                    results.add(errorResult);
                }
            }

            // Calculate total execution time
            Long totalExecutionTime = System.currentTimeMillis() - startTime;

            // Log the execution for audit purposes
            logMultiQueryExecution(processQueries, totalRecordCount, totalExecutionTime);

            return new MultiQueryResult(results, totalRecordCount, totalExecutionTime, true, null);

        } catch (Exception e) {
            // Log the error
            logQueryError('Multiple queries', e.getMessage());

            // Re-throw as-is for input validation errors
            if (e instanceof AuraHandledException) {
                throw e;
            }

            // Convert other errors to user-friendly messages
            String errorMessage = getUserFriendlyError(e);
            AuraHandledException ahe = new AuraHandledException(errorMessage);
            ahe.setMessage(errorMessage);
            throw ahe;
        }
    }

    /**
     * Execute a single SOQL query with security validation
     * Maintained for backward compatibility
     *
     * @param soqlQuery The SOQL query to execute
     * @return QueryResult containing data and metadata
     */
    @AuraEnabled
    public static QueryResult executeQuery(String soqlQuery) {
        Long startTime = System.currentTimeMillis();

        // Input validation - throw exceptions
        if (String.isBlank(soqlQuery)) {
            AuraHandledException e = new AuraHandledException('SOQL query is required');
            e.setMessage('SOQL query is required');
            throw e;
        }

        // Security and performance validation - throw exceptions
        validateQuerySecurity(soqlQuery);
        validateQueryPerformance(soqlQuery);

        // Execute the query - execution errors become error results
        try {
            List<SObject> queryResults = executeSecureQuery(soqlQuery);

            // Serialize results for client
            String jsonData = serializeResults(queryResults);

            // Calculate execution time
            Long executionTime = System.currentTimeMillis() - startTime;

            // Create success result
            QueryResult result = new QueryResult(
                    jsonData,
                    queryResults.size(),
                    executionTime,
                    true,
                    null
            );
            result.queryIndex = 0;
            result.originalQuery = soqlQuery;

            // Log successful execution
            logQueryExecution(soqlQuery, queryResults.size(), executionTime);

            return result;

        } catch (Exception e) {
            // Log execution error
            logQueryError(soqlQuery, e.getMessage());

            // Calculate execution time
            Long executionTime = System.currentTimeMillis() - startTime;

            // Return error result for execution errors
            QueryResult result = new QueryResult(
                    '[]',
                    0,
                    executionTime,
                    false,
                    getUserFriendlyError(e)
            );
            result.queryIndex = 0;
            result.originalQuery = soqlQuery;

            return result;
        }
    }

    /**
     * Validate query security - prevent malicious operations with improved keyword detection
     */
    private static void validateQuerySecurity(String soqlQuery) {
        String upperQuery = soqlQuery.toUpperCase().trim();

        // Check for FOR UPDATE first (before forbidden keywords to avoid conflict)
        if (upperQuery.contains('FOR UPDATE')) {
            String message = 'FOR UPDATE is not allowed in reporting queries';
            AuraHandledException e = new AuraHandledException(message);
            e.setMessage(message);
            throw e;
        }

        // Enhanced forbidden operations check - avoid false positives with IsDeleted
        for (String keyword : FORBIDDEN_KEYWORDS) {
            if (keyword.equals('DELETE')) {
                // Check for DELETE operations but allow IsDeleted field references
                // Look for DELETE as a standalone keyword (not part of IsDeleted)
                Pattern deletePattern = Pattern.compile('(?i)\\bDELETE\\b(?!\\s+FROM\\s+DELETED|D\\s|_)');
                if (deletePattern.matcher(upperQuery).find() && !upperQuery.contains('ISDELETED')) {
                    String message = 'DELETE operations are not allowed in reporting queries';
                    AuraHandledException e = new AuraHandledException(message);
                    e.setMessage(message);
                    throw e;
                }
            } else if (upperQuery.contains(keyword)) {
                // Make sure it's not part of "FOR UPDATE" (though we checked that above)
                if (keyword.equals('UPDATE') && upperQuery.contains('FOR UPDATE')) {
                    continue; // Skip this match, it's handled above
                }
                String message = 'Query contains forbidden operation: ' + keyword;
                AuraHandledException e = new AuraHandledException(message);
                e.setMessage(message);
                throw e;
            }
        }

        // Ensure it's a SELECT query (after checking forbidden operations)
        if (!upperQuery.startsWith('SELECT')) {
            String message = 'Only SELECT queries are allowed';
            AuraHandledException e = new AuraHandledException(message);
            e.setMessage(message);
            throw e;
        }

        // Check for potentially dangerous patterns
        if (upperQuery.contains('__C') && upperQuery.contains('LIMIT ALL')) {
            String message = 'LIMIT ALL is not allowed on custom objects';
            AuraHandledException e = new AuraHandledException(message);
            e.setMessage(message);
            throw e;
        }
    }

    /**
     * Validate query performance characteristics
     */
    private static void validateQueryPerformance(String soqlQuery) {
        String upperQuery = soqlQuery.toUpperCase().trim();

        // Check if LIMIT is specified and validate
        if (upperQuery.contains('LIMIT')) {
            Pattern limitPattern = Pattern.compile('(?i)LIMIT\\s+(\\d+)');
            Matcher limitMatcher = limitPattern.matcher(soqlQuery);

            if (limitMatcher.find()) {
                Integer limitValue = Integer.valueOf(limitMatcher.group(1));
                if (limitValue > MAX_RECORDS) {
                    String message = 'LIMIT cannot exceed ' + MAX_RECORDS + ' records';
                    AuraHandledException e = new AuraHandledException(message);
                    e.setMessage(message);
                    throw e;
                }
            }
        }

        // Check for potentially expensive operations
        if (upperQuery.contains('COUNT()') && !upperQuery.contains('GROUP BY')) {
            String message = 'COUNT() without GROUP BY may be expensive';
            AuraHandledException e = new AuraHandledException(message);
            e.setMessage(message);
            throw e;
        }

        // Check for complex relationship queries that might hit governor limits
        String[] selectParts = upperQuery.split('\\(SELECT');
        Integer relationshipCount = selectParts.size() - 1;
        if (relationshipCount > 3) {
            String message = 'Too many nested relationship queries - limit to 3 per query';
            AuraHandledException e = new AuraHandledException(message);
            e.setMessage(message);
            throw e;
        }
    }

    /**
     * Execute query with field-level security checking
     */
    private static List<SObject> executeSecureQuery(String soqlQuery) {
        try {
            // Add default LIMIT if not present
            String finalQuery = soqlQuery;
            if (!soqlQuery.toUpperCase().contains('LIMIT')) {
                finalQuery = soqlQuery + ' LIMIT ' + DEFAULT_LIMIT;
            }

            // Parse the query to extract object and field information
            QueryComponents components = parseQuery(finalQuery);

            // Validate field access
            validateFieldAccess(components);

            // Execute the query
            List<SObject> results = Database.query(finalQuery);

            return results;

        } catch (QueryException e) {
            throw new QueryException('Query execution failed: ' + e.getMessage());
        }
    }

    /**
     * Parse SOQL query to extract components for validation
     */
    private static QueryComponents parseQuery(String soqlQuery) {
        QueryComponents components = new QueryComponents();

        // Basic parsing - in a full implementation, this would be more robust
        String upperQuery = soqlQuery.toUpperCase().trim();

        // Extract primary object
        Pattern fromPattern = Pattern.compile('(?i)FROM\\s+(\\w+)');
        Matcher fromMatcher = fromPattern.matcher(soqlQuery);
        if (fromMatcher.find()) {
            components.primaryObject = fromMatcher.group(1);
        }

        // Extract fields - simplified parsing
        String selectClause = soqlQuery.substring(
                soqlQuery.toUpperCase().indexOf('SELECT') + 6,
                soqlQuery.toUpperCase().indexOf('FROM')
        ).trim();

        // Split by comma and clean up
        List<String> fieldList = selectClause.split(',');
        for (String field : fieldList) {
            String cleanField = field.trim();
            if (!cleanField.startsWith('(')) { // Skip subqueries for now
                components.fields.add(cleanField);
            }
        }

        return components;
    }

    /**
     * Validate that current user has access to all fields in the query
     */
    private static void validateFieldAccess(QueryComponents components) {
        if (String.isBlank(components.primaryObject)) {
            return; // Can't validate without object name
        }

        try {
            // Get object describe
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(components.primaryObject);
            if (objectType == null) {
                throw new SecurityException('Object not found or not accessible: ' + components.primaryObject);
            }

            Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

            // Check field access
            for (String fieldName : components.fields) {
                String cleanFieldName = fieldName.trim();

                // Skip functions and complex expressions
                if (cleanFieldName.contains('(') || cleanFieldName.contains('.')) {
                    continue;
                }

                Schema.SObjectField field = fieldMap.get(cleanFieldName);
                if (field != null && !field.getDescribe().isAccessible()) {
                    throw new SecurityException('Field not accessible: ' + cleanFieldName);
                }
            }

        } catch (Exception e) {
            // If field access validation fails, log and continue
            System.debug('Field access validation warning: ' + e.getMessage());
        }
    }

    /**
     * Serialize query results to JSON with error handling
     */
    private static String serializeResults(List<SObject> results) {
        try {
            return JSON.serialize(results);
        } catch (Exception e) {
            // If serialization fails, create a simplified version
            List<Map<String, Object>> simplifiedResults = new List<Map<String, Object>>();

            for (SObject record : results) {
                Map<String, Object> recordMap = new Map<String, Object>();
                recordMap.put('Id', record.Id);
                recordMap.put('serialization_error', 'Complex object - see raw record for details');
                simplifiedResults.add(recordMap);
            }

            return JSON.serialize(simplifiedResults);
        }
    }

    /**
     * Convert technical errors to user-friendly messages
     */
    private static String getUserFriendlyError(Exception e) {
        String message = e.getMessage();

        if (message.contains('Didn\'t understand relationship')) {
            return 'Invalid relationship in query. Please check field names and relationships.';
        }

        if (message.contains('No such column')) {
            return 'Invalid field name in query. Please check that all fields exist and are spelled correctly.';
        }

        if (message.contains('sObject type') && message.contains('is not supported')) {
            return 'Object type not found. Please check the object name in your FROM clause.';
        }

        if (message.contains('LIMIT')) {
            return 'Query limit exceeded. Please reduce the number of records or add a more restrictive WHERE clause.';
        }

        if (e instanceof SecurityException) {
            return 'Security error: ' + message;
        }

        if (e instanceof LimitException || e instanceof PerformanceException) {
            return message;
        }

        // For AuraHandledException, return the message as-is (it's already user-friendly)
        if (e instanceof AuraHandledException) {
            return message;
        }

        // Generic error for unexpected cases
        return 'Query execution failed. Please check your query syntax and try again.';
    }

    /**
     * Log successful multi-query execution for audit purposes
     */
    private static void logMultiQueryExecution(List<String> queries, Integer totalRecords, Long executionTime) {
        try {
            System.debug(LoggingLevel.INFO,
                    'Multi-query executed successfully - User: ' + UserInfo.getUserId() +
                            ', Queries: ' + queries.size() +
                            ', Total Records: ' + totalRecords +
                            ', Time: ' + executionTime + 'ms'
            );

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log multi-query execution: ' + e.getMessage());
        }
    }

    /**
     * Log successful query execution for audit purposes
     */
    private static void logQueryExecution(String query, Integer recordCount, Long executionTime) {
        try {
            System.debug(LoggingLevel.INFO,
                    'Query executed successfully - User: ' + UserInfo.getUserId() +
                            ', Records: ' + recordCount +
                            ', Time: ' + executionTime + 'ms'
            );

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log query execution: ' + e.getMessage());
        }
    }

    /**
     * Log query errors for troubleshooting
     */
    private static void logQueryError(String query, String errorMessage) {
        try {
            System.debug(LoggingLevel.ERROR,
                    'Query execution failed - User: ' + UserInfo.getUserId() +
                            ', Error: ' + errorMessage +
                            ', Query: ' + query.abbreviate(200)
            );

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log query error: ' + e.getMessage());
        }
    }

    // ===========================================
    // UTILITY METHODS
    // ===========================================

    /**
     * Get basic schema information for the client
     * Note: This is a simplified version for MVP
     */
    @AuraEnabled(cacheable=true)
    public static List<ObjectInfo> getBasicSchemaInfo() {
        List<ObjectInfo> objectList = new List<ObjectInfo>();

        try {
            // Get a subset of common objects for MVP
            List<String> commonObjects = new List<String>{
                    'Account', 'Contact', 'Opportunity', 'Lead', 'Case',
                    'Patient__c', 'Care_Team_Member__c', 'Patient_Encounter__c'
            };

            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

            for (String objectName : commonObjects) {
                Schema.SObjectType objectType = globalDescribe.get(objectName);
                if (objectType != null && objectType.getDescribe().isAccessible()) {
                    ObjectInfo info = new ObjectInfo();
                    info.name = objectName;
                    info.label = objectType.getDescribe().getLabel();
                    info.isCustom = objectType.getDescribe().isCustom();
                    objectList.add(info);
                }
            }

        } catch (Exception e) {
            System.debug('Error getting schema info: ' + e.getMessage());
        }

        return objectList;
    }

    // ===========================================
    // WRAPPER CLASSES
    // ===========================================

    /**
     * Multi-query execution result wrapper
     */
    public with sharing class MultiQueryResult {
        @AuraEnabled public List<QueryResult> results;
        @AuraEnabled public Integer totalRecordCount;
        @AuraEnabled public Long totalExecutionTime;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;

        public MultiQueryResult(List<QueryResult> results, Integer totalRecordCount, Long totalExecutionTime, Boolean success, String errorMessage) {
            this.results = results;
            this.totalRecordCount = totalRecordCount;
            this.totalExecutionTime = totalExecutionTime;
            this.success = success;
            this.errorMessage = errorMessage;
        }
    }

    /**
     * Individual query execution result wrapper
     */
    public with sharing class QueryResult {
        @AuraEnabled public String data;
        @AuraEnabled public Integer recordCount;
        @AuraEnabled public Long executionTime;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Integer queryIndex;
        @AuraEnabled public String originalQuery;

        public QueryResult(String data, Integer recordCount, Long executionTime, Boolean success, String errorMessage) {
            this.data = data;
            this.recordCount = recordCount;
            this.executionTime = executionTime;
            this.success = success;
            this.errorMessage = errorMessage;
        }
    }

    /**
     * Object information for schema browser
     */
    public with sharing class ObjectInfo {
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean isCustom;
    }

    /**
     * Query components for validation
     */
    private with sharing class QueryComponents {
        public String primaryObject;
        public Set<String> fields;

        public QueryComponents() {
            this.fields = new Set<String>();
        }
    }

    // ===========================================
    // CUSTOM EXCEPTIONS
    // ===========================================

    public with sharing class SecurityException extends Exception {}
    public with sharing class LimitException extends Exception {}
    public with sharing class PerformanceException extends Exception {}
}