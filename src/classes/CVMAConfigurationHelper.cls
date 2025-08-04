/**
 * Configuration Helper class for accessing CVMA custom metadata settings
 * Provides cached access to application configuration and email templates
 * Implements Salesforce best practices for metadata access and caching
 */
public with sharing class CVMAConfigurationHelper {
    
    // Class constants
    private static final String CLASS_NAME = 'CVMAConfigurationHelper';
    
    // Cache maps for performance
    private static Map<String, CVMA_Application_Config__mdt> configCache = new Map<String, CVMA_Application_Config__mdt>();
    private static Map<String, CVMA_Email_Template__mdt> emailTemplateCache = new Map<String, CVMA_Email_Template__mdt>();
    
    // Cache initialization flags
    private static Boolean configCacheInitialized = false;
    private static Boolean emailTemplateCacheInitialized = false;
    
    /**
     * Get application configuration value by developer name
     */
    public static String getConfigTextValue(String developerName) {
        CVMA_Application_Config__mdt config = getApplicationConfig(developerName);
        return config != null ? config.Text_Value__c : null;
    }
    
    /**
     * Get application configuration numeric value by developer name
     */
    public static Decimal getConfigNumericValue(String developerName) {
        CVMA_Application_Config__mdt config = getApplicationConfig(developerName);
        return config != null ? config.Numeric_Value__c : null;
    }
    
    /**
     * Get application configuration boolean value by developer name
     */
    public static Boolean getConfigBooleanValue(String developerName) {
        CVMA_Application_Config__mdt config = getApplicationConfig(developerName);
        return config != null ? config.Is_Active__c : false;
    }
    
    /**
     * Get email template by developer name
     */
    public static CVMA_Email_Template__mdt getEmailTemplate(String developerName) {
        initializeEmailTemplateCache();
        return emailTemplateCache.get(developerName);
    }
    
    /**
     * Get email template subject with merge field substitution
     */
    public static String getEmailSubject(String templateName, Map<String, String> mergeFields) {
        CVMA_Email_Template__mdt template = getEmailTemplate(templateName);
        if (template == null || !template.Is_Active__c) {
            return null;
        }
        
        String subject = template.Email_Subject__c;
        if (mergeFields != null && !mergeFields.isEmpty()) {
            subject = replaceMergeFields(subject, mergeFields);
        }
        
        return subject;
    }
    
    /**
     * Get email template body with merge field substitution
     */
    public static String getEmailBody(String templateName, Map<String, String> mergeFields) {
        CVMA_Email_Template__mdt template = getEmailTemplate(templateName);
        if (template == null || !template.Is_Active__c) {
            return null;
        }
        
        String body = template.Email_Body__c;
        if (mergeFields != null && !mergeFields.isEmpty()) {
            body = replaceMergeFields(body, mergeFields);
        }
        
        return body;
    }
    
    /**
     * Get commonly used configuration values with defaults
     */
    public static Integer getDashboardPageSize() {
        Decimal pageSize = getConfigNumericValue('Dashboard_Page_Size');
        return pageSize != null ? pageSize.intValue() : 50;
    }
    
    public static Integer getEmailBatchSize() {
        Decimal batchSize = getConfigNumericValue('Email_Batch_Size');
        return batchSize != null ? batchSize.intValue() : 10;
    }
    
    public static String getMembershipIdFormat() {
        String format = getConfigTextValue('Membership_ID_Format');
        return String.isNotBlank(format) ? format : 'FM{NNN}'; // Validation rule: FM+1-5 digits
    }
    
    /**
     * Generate new membership ID based on configured format
     */
    public static String generateMembershipId(Integer sequence) {
        final String METHOD_NAME = 'generateMembershipId';
        
        try {
            String format = getMembershipIdFormat();
            
            // Replace year placeholder
            String currentYear = String.valueOf(Date.today().year());
            format = format.replace('{YYYY}', currentYear);
            format = format.replace('{YY}', currentYear.substring(2));
            
            // Replace sequence number placeholder with zero-padded number (max 5 digits per validation rule)
            format = format.replace('{NNNNN}', String.valueOf(sequence).leftPad(5, '0'));
            format = format.replace('{NNNN}', String.valueOf(sequence).leftPad(4, '0'));
            format = format.replace('{NNN}', String.valueOf(sequence).leftPad(3, '0'));
            format = format.replace('{NN}', String.valueOf(sequence).leftPad(2, '0'));
            format = format.replace('{N}', String.valueOf(sequence));
            
            return format;
            
        } catch (Exception ex) {
            CVMAErrorHandler.logError(ex, CLASS_NAME, METHOD_NAME, 
                CVMAErrorHandler.Severity.MEDIUM, CVMAErrorHandler.Category.BUSINESS_LOGIC);
            
            // Return default format on error per validation rule
            return 'FM' + String.valueOf(sequence).leftPad(3, '0');
        }
    }
    
    /**
     * Validate configuration integrity
     */
    public static List<String> validateConfiguration() {
        List<String> issues = new List<String>();
        
        try {
            // Check required configurations
            if (getConfigNumericValue('Dashboard_Page_Size') == null) {
                issues.add('Dashboard_Page_Size configuration is missing');
            }
            
            if (getConfigNumericValue('Email_Batch_Size') == null) {
                issues.add('Email_Batch_Size configuration is missing');
            }
            
            if (String.isBlank(getConfigTextValue('Membership_ID_Format'))) {
                issues.add('Membership_ID_Format configuration is missing');
            }
            
            // Check email templates
            if (getEmailTemplate('Renewal_Reminder') == null) {
                issues.add('Renewal_Reminder email template is missing');
            }
            
            if (getEmailTemplate('Welcome_New_Member') == null) {
                issues.add('Welcome_New_Member email template is missing');
            }
            
        } catch (Exception ex) {
            CVMAErrorHandler.logError(ex, CLASS_NAME, 'validateConfiguration', 
                CVMAErrorHandler.Severity.HIGH, CVMAErrorHandler.Category.SYSTEM_ERROR);
            issues.add('Error validating configuration: ' + ex.getMessage());
        }
        
        return issues;
    }
    
    /**
     * Private helper methods
     */
    private static CVMA_Application_Config__mdt getApplicationConfig(String developerName) {
        initializeConfigCache();
        return configCache.get(developerName);
    }
    
    private static void initializeConfigCache() {
        if (configCacheInitialized) {
            return;
        }
        
        try {
            List<CVMA_Application_Config__mdt> configs = [
                SELECT DeveloperName, Category__c, Description__c, Is_Active__c, 
                       Numeric_Value__c, Text_Value__c
                FROM CVMA_Application_Config__mdt
                WHERE Is_Active__c = true
                WITH SECURITY_ENFORCED
            ];
            
            for (CVMA_Application_Config__mdt config : configs) {
                configCache.put(config.DeveloperName, config);
            }
            
            configCacheInitialized = true;
            
        } catch (Exception ex) {
            CVMAErrorHandler.logError(ex, CLASS_NAME, 'initializeConfigCache', 
                CVMAErrorHandler.Severity.HIGH, CVMAErrorHandler.Category.SYSTEM_ERROR);
        }
    }
    
    private static void initializeEmailTemplateCache() {
        if (emailTemplateCacheInitialized) {
            return;
        }
        
        try {
            List<CVMA_Email_Template__mdt> templates = [
                SELECT DeveloperName, Email_Body__c, Email_Subject__c, From_Address__c,
                       From_Name__c, Is_Active__c, Template_Type__c
                FROM CVMA_Email_Template__mdt
                WHERE Is_Active__c = true
                WITH SECURITY_ENFORCED
            ];
            
            for (CVMA_Email_Template__mdt template : templates) {
                emailTemplateCache.put(template.DeveloperName, template);
            }
            
            emailTemplateCacheInitialized = true;
            
        } catch (Exception ex) {
            CVMAErrorHandler.logError(ex, CLASS_NAME, 'initializeEmailTemplateCache', 
                CVMAErrorHandler.Severity.HIGH, CVMAErrorHandler.Category.SYSTEM_ERROR);
        }
    }
    
    private static String replaceMergeFields(String text, Map<String, String> mergeFields) {
        if (String.isBlank(text) || mergeFields == null || mergeFields.isEmpty()) {
            return text;
        }
        
        String result = text;
        for (String fieldName : mergeFields.keySet()) {
            String fieldValue = mergeFields.get(fieldName);
            if (fieldValue == null) {
                fieldValue = '';
            }
            
            // Replace {!FieldName} format merge fields
            result = result.replace('{!' + fieldName + '}', fieldValue);
            
            // Replace {FieldName} format merge fields as well
            result = result.replace('{' + fieldName + '}', fieldValue);
        }
        
        return result;
    }
    
    /**
     * Clear cache (useful for testing)
     */
    @TestVisible
    private static void clearCache() {
        configCache.clear();
        emailTemplateCache.clear();
        configCacheInitialized = false;
        emailTemplateCacheInitialized = false;
    }
}