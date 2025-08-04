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
            errorLog.Timestamp__c = DateTime.now();
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
    
    /**
     * Log error with additional context data
     */
    public static void logError(Exception ex, String className, String methodName, Severity severity, Category category, Map<String, Object> contextData) {
        try {
            // Log basic error first
            logError(ex, className, methodName, severity, category);
            
            // Add context data if provided
            if (contextData != null && !contextData.isEmpty()) {
                String contextJson = JSON.serialize(contextData);
                
                // Update the most recent error log with context
                List<CVMA_Error_Log__c> recentLogs = [
                    SELECT Id 
                    FROM CVMA_Error_Log__c 
                    WHERE User__c = :UserInfo.getUserId() 
                    AND Class_Name__c = :className 
                    AND Method_Name__c = :methodName
                    ORDER BY CreatedDate DESC 
                    LIMIT 1
                ];
                
                if (!recentLogs.isEmpty()) {
                    recentLogs[0].Context_Data__c = contextJson.length() > 32768 ? 
                        contextJson.substring(0, 32768) : contextJson;
                    update recentLogs[0];
                }
            }
            
        } catch (Exception logException) {
            System.debug(LoggingLevel.ERROR, 'Error adding context to error log: ' + logException.getMessage());
        }
    }
    
    /**
     * Create user-friendly error message for display
     */
    public static String createUserMessage(Exception ex, Category category) {
        String baseMessage;
        
        switch on category {
            when SECURITY {
                baseMessage = 'You do not have sufficient permissions to perform this action.';
            }
            when DATA_VALIDATION {
                baseMessage = 'The information provided is invalid. Please check your entries and try again.';
            }
            when INTEGRATION {
                baseMessage = 'We are experiencing connectivity issues. Please try again later.';
            }
            when PERFORMANCE {
                baseMessage = 'The system is currently busy. Please try again in a few moments.';
            }
            when BUSINESS_LOGIC {
                baseMessage = 'This action cannot be completed due to business rules.';
            }
            when else {
                baseMessage = 'An unexpected error occurred. Please contact your administrator.';
            }
        }
        
        // Add specific details for certain exception types
        if (ex instanceof DmlException) {
            DmlException dmlEx = (DmlException) ex;
            if (dmlEx.getDmlType(0) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
                return dmlEx.getDmlMessage(0);
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
        String missingPermissions = '';
        
        // Check object-level permissions
        switch on operation.toLowerCase() {
            when 'create' {
                if (!objectType.getDescribe().isCreateable()) {
                    missingPermissions += 'Create access to ' + objectType.getDescribe().getLabel() + '. ';
                }
            }
            when 'read' {
                if (!objectType.getDescribe().isAccessible()) {
                    missingPermissions += 'Read access to ' + objectType.getDescribe().getLabel() + '. ';
                }
            }
            when 'update' {
                if (!objectType.getDescribe().isUpdateable()) {
                    missingPermissions += 'Update access to ' + objectType.getDescribe().getLabel() + '. ';
                }
            }
            when 'delete' {
                if (!objectType.getDescribe().isDeletable()) {
                    missingPermissions += 'Delete access to ' + objectType.getDescribe().getLabel() + '. ';
                }
            }
        }
        
        // Check field-level permissions
        if (fields != null && !fields.isEmpty()) {
            Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
            
            for (String fieldName : fields) {
                if (fieldMap.containsKey(fieldName)) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                    
                    switch on operation.toLowerCase() {
                        when 'create', 'update' {
                            if (!fieldDescribe.isUpdateable()) {
                                missingPermissions += 'Update access to field ' + fieldDescribe.getLabel() + '. ';
                            }
                        }
                        when 'read' {
                            if (!fieldDescribe.isAccessible()) {
                                missingPermissions += 'Read access to field ' + fieldDescribe.getLabel() + '. ';
                            }
                        }
                    }
                }
            }
        }
        
        if (!String.isBlank(missingPermissions)) {
            throw new SecurityException('Insufficient permissions: ' + missingPermissions.trim());
        }
    }
    
    /**
     * Sanitize user input to prevent injection attacks
     */
    public static String sanitizeInput(String input) {
        if (String.isBlank(input)) {
            return input;
        }
        
        // Remove potentially dangerous characters
        String sanitized = input.replaceAll('[<>\"\'&]', '');
        
        // Trim whitespace
        sanitized = sanitized.trim();
        
        return sanitized;
    }
    
    /**
     * Validate email format
     */
    public static Boolean isValidEmail(String email) {
        if (String.isBlank(email)) {
            return false;
        }
        
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        Pattern emailPattern = Pattern.compile(emailRegex);
        return emailPattern.matcher(email).matches();
    }
    
    /**
     * Private helper methods
     */
    private static void logToSystemDebug(Exception ex, String className, String methodName, Severity severity, Category category) {
        String logMessage = String.format(
            'ERROR [{0}] {1}.{2}: {3} - {4}',
            new List<String>{
                severity.name(),
                className,
                methodName,
                category.name(),
                ex.getMessage()
            }
        );
        
        System.debug(LoggingLevel.ERROR, logMessage);
        System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
    }
    
    private static String getUserProfile() {
        try {
            User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            return currentUser.Profile.Name;
        } catch (Exception ex) {
            return 'Unknown Profile';
        }
    }
    
    // Custom exception classes
    public class SecurityException extends Exception {}
    public class ValidationException extends Exception {}
    public class IntegrationException extends Exception {}
}