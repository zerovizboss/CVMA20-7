/**
 * CVMA Error Handler - Centralized error handling and logging framework
 * Provides consistent error handling, logging, and user feedback across the CVMA application
 */
public with sharing class CVMAErrorHandler {

    // Error severity levels
    public enum Severity {
        LOW,
        MEDIUM,
        HIGH,
        CRITICAL
    }

    // Error categories for better classification
    public enum Category {
        SECURITY,
        DATA_VALIDATION,
        INTEGRATION,
        PERFORMANCE,
        BUSINESS_LOGIC,
        SYSTEM_ERROR
    }

    /**
     * Log error with full context information
     */
    public static void logError(Exception ex, String className, String methodName, Severity severity, Category category) {
        try {
            // Create error log record
            CVMA_Error_Log__c errorLog = new CVMA_Error_Log__c();
            errorLog.Class_Name__c = className;
            errorLog.Method_Name__c = methodName;
            errorLog.Error_Message__c = ex.getMessage();
            errorLog.Stack_Trace__c = ex.getStackTraceString();
            errorLog.Error_Type__c = ex.getTypeName();
            errorLog.Severity__c = severity.name();
            errorLog.Category__c = category.name();
            errorLog.User__c = UserInfo.getUserId();
            errorLog.Timestamp__c = Datetime.now();
            errorLog.Org_Id__c = UserInfo.getOrganizationId();

            // Add context information
            errorLog.User_Profile__c = getUserProfile();
            errorLog.Session_Id__c = UserInfo.getSessionId();

            // Insert log record (using Database.insert to handle potential failures)
            Database.SaveResult result = Database.insert(errorLog, false);

            if (!result.isSuccess()) {
                // Fallback to System.debug if custom object insert fails
                System.debug(LoggingLevel.ERROR, 'Failed to insert error log: ' + result.getErrors());
                logToSystemDebug(ex, className, methodName, severity, category);
            }

        } catch (Exception logException) {
            // Ultimate fallback - log to system debug
            System.debug(LoggingLevel.ERROR, 'Error in error logging: ' + logException.getMessage());
            logToSystemDebug(ex, className, methodName, severity, category);
        }
    }

    // Constants for error handling
    private static final Integer CONTEXT_DATA_MAX_LENGTH = 32768;
    private static final String UNKNOWN_PROFILE = 'Unknown Profile';

    // Cache for user profile to avoid repeated SOQL queries
    private static Map<Id, String> userProfileCache = new Map<Id, String>();

    /**
     * Log error with additional context data
     */
    public static void logError(Exception ex, String className, String methodName, Severity severity, Category category, Map<String, Object> contextData) {
        try {
            // Create error log record with context data included
            CVMA_Error_Log__c errorLog = new CVMA_Error_Log__c();
            errorLog.Class_Name__c = className;
            errorLog.Method_Name__c = methodName;
            errorLog.Error_Message__c = ex.getMessage();
            errorLog.Stack_Trace__c = ex.getStackTraceString();
            errorLog.Error_Type__c = ex.getTypeName();
            errorLog.Severity__c = severity.name();
            errorLog.Category__c = category.name();
            errorLog.User__c = UserInfo.getUserId();
            errorLog.Timestamp__c = Datetime.now();
            errorLog.Org_Id__c = UserInfo.getOrganizationId();

            // Add context information
            errorLog.User_Profile__c = getUserProfileCached();
            errorLog.Session_Id__c = UserInfo.getSessionId();

            // Add context data if provided
            if (contextData != null && !contextData.isEmpty()) {
                String contextJson = JSON.serialize(contextData);
                errorLog.Context_Data__c = contextJson.length() > CONTEXT_DATA_MAX_LENGTH ?
                    contextJson.substring(0, CONTEXT_DATA_MAX_LENGTH) : contextJson;
            }

            // Insert log record (using Database.insert to handle potential failures)
            Database.SaveResult result = Database.insert(errorLog, false);

            if (!result.isSuccess()) {
                // Fallback to System.debug if custom object insert fails
                System.debug(LoggingLevel.ERROR, 'Failed to insert error log: ' + result.getErrors());
                logToSystemDebug(ex, className, methodName, severity, category);
            }

        } catch (Exception logException) {
            // Ultimate fallback - log to system debug
            System.debug(LoggingLevel.ERROR, 'Error in error logging: ' + logException.getMessage());
            logToSystemDebug(ex, className, methodName, severity, category);
        }
    }

    // Constants for user messages
    private static final String SECURITY_MESSAGE = 'You do not have sufficient permissions to perform this action.';
    private static final String DATA_VALIDATION_MESSAGE = 'The information provided is invalid. Please check your entries and try again.';
    private static final String INTEGRATION_MESSAGE = 'We are experiencing connectivity issues. Please try again later.';
    private static final String PERFORMANCE_MESSAGE = 'The system is currently busy. Please try again in a few moments.';
    private static final String BUSINESS_LOGIC_MESSAGE = 'This action cannot be completed due to business rules.';
    private static final String DEFAULT_ERROR_MESSAGE = 'An unexpected error occurred. Please contact your administrator.';

    /**
     * Create user-friendly error message for display
     */
    public static String createUserMessage(Exception ex, Category category) {
        if (ex == null) {
            return DEFAULT_ERROR_MESSAGE;
        }

        String baseMessage;
        if (category == null) {
            baseMessage = DEFAULT_ERROR_MESSAGE;
        } else {
            switch on category {
                when SECURITY {
                    baseMessage = SECURITY_MESSAGE;
                }
                when DATA_VALIDATION {
                    baseMessage = DATA_VALIDATION_MESSAGE;
                }
                when INTEGRATION {
                    baseMessage = INTEGRATION_MESSAGE;
                }
                when PERFORMANCE {
                    baseMessage = PERFORMANCE_MESSAGE;
                }
                when BUSINESS_LOGIC {
                    baseMessage = BUSINESS_LOGIC_MESSAGE;
                }
                when else {
                    baseMessage = DEFAULT_ERROR_MESSAGE;
                }
            }
        }

        // Add specific details for certain exception types
        if (ex instanceof DmlException) {
            DmlException dmlEx = (DmlException) ex;
            try {
                if (dmlEx.getNumDml() > 0 && dmlEx.getDmlType(0) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
                    String customMessage = dmlEx.getDmlMessage(0);
                    return String.isNotBlank(customMessage) ? customMessage : baseMessage;
                }
            } catch (Exception dmlProcessingEx) {
                System.debug(LoggingLevel.WARN, 'Error processing DML exception details: ' + dmlProcessingEx.getMessage());
            }
        }

        return baseMessage;
    }

    /**
     * Handle and log exception, return user-friendly message
     */
    public static String handleException(Exception ex, String className, String methodName, Category category) {
        return handleException(ex, className, methodName, Severity.MEDIUM, category, null);
    }

    /**
     * Handle and log exception with full parameters
     */
    public static String handleException(Exception ex, String className, String methodName,
                                       Severity severity, Category category, Map<String, Object> contextData) {
        // Log the error
        if (contextData != null) {
            logError(ex, className, methodName, severity, category, contextData);
        } else {
            logError(ex, className, methodName, severity, category);
        }

        // Return user-friendly message
        return createUserMessage(ex, category);
    }

    /**
     * Validate CRUD permissions before DML operations
     */
    public static void validateCRUDPermissions(SObjectType objectType, List<String> fields, String operation) {
        if (objectType == null || String.isBlank(operation)) {
            throw new ValidationException('Object type and operation are required for permission validation');
        }

        List<String> missingPermissions = new List<String>();
        String normalizedOperation = operation.toLowerCase().trim();

        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();

        // Check object-level permissions
        switch on normalizedOperation {
            when 'create' {
                if (!objectDescribe.isCreateable()) {
                    missingPermissions.add('Create access to ' + objectDescribe.getLabel());
                }
            }
            when 'read' {
                if (!objectDescribe.isAccessible()) {
                    missingPermissions.add('Read access to ' + objectDescribe.getLabel());
                }
            }
            when 'update' {
                if (!objectDescribe.isUpdateable()) {
                    missingPermissions.add('Update access to ' + objectDescribe.getLabel());
                }
            }
            when 'delete' {
                if (!objectDescribe.isDeletable()) {
                    missingPermissions.add('Delete access to ' + objectDescribe.getLabel());
                }
            }
            when else {
                throw new ValidationException('Invalid operation: ' + operation);
            }
        }

        // Check field-level permissions
        if (fields != null && !fields.isEmpty()) {
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();

            for (String fieldName : fields) {
                if (String.isNotBlank(fieldName) && fieldMap.containsKey(fieldName.toLowerCase())) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName.toLowerCase()).getDescribe();

                    switch on normalizedOperation {
                        when 'create', 'update' {
                            if (!fieldDescribe.isUpdateable()) {
                                missingPermissions.add('Update access to field ' + fieldDescribe.getLabel());
                            }
                        }
                        when 'read' {
                            if (!fieldDescribe.isAccessible()) {
                                missingPermissions.add('Read access to field ' + fieldDescribe.getLabel());
                            }
                        }
                    }
                }
            }
        }

        if (!missingPermissions.isEmpty()) {
            throw new SecurityException('Insufficient permissions: ' + String.join(missingPermissions, ', '));
        }
    }

    /**
     * Sanitize user input to prevent injection attacks
     */
    public static String sanitizeInput(String input) {
        if (String.isBlank(input)) {
            return input;
        }

        // Remove potentially dangerous characters and limit length
        String sanitized = input.replaceAll('[<>\"\'&]', '');
        sanitized = sanitized.trim();

        // Prevent excessively long input
        final Integer MAX_INPUT_LENGTH = 1000;
        if (sanitized.length() > MAX_INPUT_LENGTH) {
            sanitized = sanitized.substring(0, MAX_INPUT_LENGTH);
        }

        return sanitized;
    }

    /**
     * Validate email format
     */
    public static Boolean isValidEmail(String email) {
        if (String.isBlank(email)) {
            return false;
        }

        // Basic length validation
        if (email.length() > 254) {
            return false;
        }

        final String EMAIL_REGEX = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\\\.[a-zA-Z]{2,}$';
        try {
            Pattern emailPattern = Pattern.compile(EMAIL_REGEX);
            return emailPattern.matcher(email).matches();
        } catch (Exception patternException) {
            System.debug(LoggingLevel.WARN, 'Email pattern validation failed: ' + patternException.getMessage());
            return false;
        }
    }

    /**
     * Private helper methods
     */
    private static void logToSystemDebug(Exception ex, String className, String methodName, Severity severity, Category category) {
        if (ex == null || String.isBlank(className) || String.isBlank(methodName)) {
            System.debug(LoggingLevel.ERROR, 'Invalid parameters passed to logToSystemDebug');
            return;
        }

        String logMessage = String.format(
            'ERROR [{0}] {1}.{2}: {3} - {4}',
            new List<String>{
                severity != null ? severity.name() : 'UNKNOWN',
                className,
                methodName,
                category != null ? category.name() : 'UNKNOWN',
                ex.getMessage() != null ? ex.getMessage() : 'No message available'
            }
        );

        System.debug(LoggingLevel.ERROR, logMessage);

        String stackTrace = ex.getStackTraceString();
        if (String.isNotBlank(stackTrace)) {
            System.debug(LoggingLevel.ERROR, stackTrace);
        }
    }

    private static String getUserProfileCached() {
        Id userId = UserInfo.getUserId();
        if (userProfileCache.containsKey(userId)) {
            return userProfileCache.get(userId);
        }

        try {
            List<User> users = [SELECT Profile.Name FROM User WHERE Id = :userId WITH SECURITY_ENFORCED LIMIT 1];
            String profileName = !users.isEmpty() ? users[0].Profile.Name : UNKNOWN_PROFILE;
            userProfileCache.put(userId, profileName);
            return profileName;
        } catch (Exception ex) {
            userProfileCache.put(userId, UNKNOWN_PROFILE);
            return UNKNOWN_PROFILE;
        }
    }

    // Custom exception classes
    public class SecurityException extends Exception {}
    public class ValidationException extends Exception {}
    public class IntegrationException extends Exception {}
}
