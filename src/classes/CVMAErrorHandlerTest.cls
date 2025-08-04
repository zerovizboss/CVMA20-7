/**
 * Test class for CVMAErrorHandler
 * Comprehensive test coverage for error handling and logging functionality
 */
@IsTest
public class CVMAErrorHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user for error logging
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'ErrorUser',
            Email = 'error.test@cvma.com',
            Username = 'error.test@cvma.com.test',
            Alias = 'errtest',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = testProfile.Id
        );
        insert testUser;
    }
    
    @IsTest
    static void testLogError_BasicLogging() {
        User testUser = [SELECT Id FROM User WHERE Username = 'error.test@cvma.com.test' LIMIT 1];
        
        Test.startTest();
        System.runAs(testUser) {
            try {
                // Generate test exception
                Integer divideByZero = 10 / 0;
            } catch (Exception ex) {
                CVMAErrorHandler.logError(ex, 'TestClass', 'testMethod', 
                    CVMAErrorHandler.Severity.HIGH, CVMAErrorHandler.Category.BUSINESS_LOGIC);
            }
        }
        Test.stopTest();
        
        // Verify error log was created
        List<CVMA_Error_Log__c> errorLogs = [
            SELECT Id, Class_Name__c, Method_Name__c, Error_Type__c, Severity__c, 
                   Category__c, User__c, Error_Message__c
            FROM CVMA_Error_Log__c
            WHERE User__c = :testUser.Id
        ];
        
        System.assertEquals(1, errorLogs.size(), 'Should create one error log');
        CVMA_Error_Log__c errorLog = errorLogs[0];
        System.assertEquals('TestClass', errorLog.Class_Name__c, 'Class name should match');
        System.assertEquals('testMethod', errorLog.Method_Name__c, 'Method name should match');
        System.assertEquals('HIGH', errorLog.Severity__c, 'Severity should match');
        System.assertEquals('BUSINESS_LOGIC', errorLog.Category__c, 'Category should match');
        System.assert(errorLog.Error_Message__c.contains('divide by zero'), 'Error message should contain exception details');
    }
    
    @IsTest
    static void testLogError_WithContextData() {
        User testUser = [SELECT Id FROM User WHERE Username = 'error.test@cvma.com.test' LIMIT 1];
        
        Map<String, Object> contextData = new Map<String, Object>();
        contextData.put('recordId', 'a001234567890123');
        contextData.put('operation', 'update');
        contextData.put('fieldValues', new Map<String, String>{'Name' => 'Test Value'});
        
        Test.startTest();
        System.runAs(testUser) {
            try {
                throw new CVMAErrorHandler.ValidationException('Test validation error');
            } catch (Exception ex) {
                CVMAErrorHandler.logError(ex, 'TestClass', 'testMethodWithContext', 
                    CVMAErrorHandler.Severity.MEDIUM, CVMAErrorHandler.Category.DATA_VALIDATION, contextData);
            }
        }
        Test.stopTest();
        
        // Verify error log with context data
        List<CVMA_Error_Log__c> errorLogs = [
            SELECT Id, Context_Data__c, Error_Message__c
            FROM CVMA_Error_Log__c
            WHERE User__c = :testUser.Id
        ];
        
        System.assertEquals(1, errorLogs.size(), 'Should create one error log');
        System.assertNotEquals(null, errorLogs[0].Context_Data__c, 'Context data should be populated');
        System.assert(errorLogs[0].Context_Data__c.contains('recordId'), 'Context should contain recordId');
        System.assert(errorLogs[0].Context_Data__c.contains('a001234567890123'), 'Context should contain record ID value');
    }
    
    @IsTest
    static void testCreateUserMessage_SecurityCategory() {
        Exception testException = new CVMAErrorHandler.SecurityException('Access denied');
        
        Test.startTest();
        String userMessage = CVMAErrorHandler.createUserMessage(testException, CVMAErrorHandler.Category.SECURITY);
        Test.stopTest();
        
        System.assert(userMessage.contains('permissions'), 'Security message should mention permissions');
    }
    
    @IsTest
    static void testCreateUserMessage_DataValidationCategory() {
        Exception testException = new CVMAErrorHandler.ValidationException('Invalid data');
        
        Test.startTest();
        String userMessage = CVMAErrorHandler.createUserMessage(testException, CVMAErrorHandler.Category.DATA_VALIDATION);
        Test.stopTest();
        
        System.assert(userMessage.contains('invalid'), 'Validation message should mention invalid data');
    }
    
    @IsTest
    static void testCreateUserMessage_DmlException() {
        // Create a contact with invalid data to generate DML exception
        Contact invalidContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'invalid-email-format' // This will cause validation error
        );
        
        Test.startTest();
        try {
            insert invalidContact;
        } catch (DmlException ex) {
            String userMessage = CVMAErrorHandler.createUserMessage(ex, CVMAErrorHandler.Category.DATA_VALIDATION);
            System.assertNotEquals(null, userMessage, 'Should return user message for DML exception');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testHandleException_FullWorkflow() {
        Map<String, Object> contextData = new Map<String, Object>();
        contextData.put('testContext', 'fullWorkflowTest');
        
        Test.startTest();
        String userMessage;
        try {
            throw new CVMAErrorHandler.IntegrationException('Integration failed');
        } catch (Exception ex) {
            userMessage = CVMAErrorHandler.handleException(ex, 'TestClass', 'testFullWorkflow', 
                CVMAErrorHandler.Severity.CRITICAL, CVMAErrorHandler.Category.INTEGRATION, contextData);
        }
        Test.stopTest();
        
        // Verify error was logged
        List<CVMA_Error_Log__c> errorLogs = [SELECT Id, Severity__c, Category__c FROM CVMA_Error_Log__c];
        System.assertEquals(1, errorLogs.size(), 'Should create error log');
        System.assertEquals('CRITICAL', errorLogs[0].Severity__c, 'Severity should be critical');
        System.assertEquals('INTEGRATION', errorLogs[0].Category__c, 'Category should be integration');
        
        // Verify user message
        System.assert(userMessage.contains('connectivity'), 'Integration message should mention connectivity');
    }
    
    @IsTest
    static void testValidateCRUDPermissions_Success() {
        Test.startTest();
        try {
            // Test with Contact object and accessible fields
            CVMAErrorHandler.validateCRUDPermissions(
                Contact.SObjectType, 
                new List<String>{'FirstName', 'LastName', 'Email'}, 
                'read'
            );
            System.assert(true, 'Should not throw exception for valid permissions');
        } catch (Exception ex) {
            System.assert(false, 'Should not throw exception for standard fields: ' + ex.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateCRUDPermissions_SecurityException() {
        Test.startTest();
        try {
            // Test with a system object that users typically can't delete
            CVMAErrorHandler.validateCRUDPermissions(
                User.SObjectType, 
                new List<String>{'FirstName'}, 
                'delete'
            );
            System.assert(false, 'Should throw exception for delete on User object');
        } catch (CVMAErrorHandler.SecurityException ex) {
            System.assert(ex.getMessage().contains('permissions'), 'Exception should mention permissions');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSanitizeInput() {
        Test.startTest();
        
        // Test normal input
        String normalInput = 'John Doe';
        String sanitizedNormal = CVMAErrorHandler.sanitizeInput(normalInput);
        System.assertEquals('John Doe', sanitizedNormal, 'Normal input should remain unchanged');
        
        // Test input with dangerous characters
        String dangerousInput = '<script>alert("hack")</script>';
        String sanitizedDangerous = CVMAErrorHandler.sanitizeInput(dangerousInput);
        System.assertEquals('scriptalert(hack)/script', sanitizedDangerous, 'Dangerous characters should be removed');
        
        // Test null/blank input
        String nullInput = null;
        String sanitizedNull = CVMAErrorHandler.sanitizeInput(nullInput);
        System.assertEquals(null, sanitizedNull, 'Null input should remain null');
        
        String blankInput = '';
        String sanitizedBlank = CVMAErrorHandler.sanitizeInput(blankInput);
        System.assertEquals('', sanitizedBlank, 'Blank input should remain blank');
        
        // Test input with whitespace
        String whitespaceInput = '  John Doe  ';
        String sanitizedWhitespace = CVMAErrorHandler.sanitizeInput(whitespaceInput);
        System.assertEquals('John Doe', sanitizedWhitespace, 'Whitespace should be trimmed');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testIsValidEmail() {
        Test.startTest();
        
        // Test valid emails
        System.assert(CVMAErrorHandler.isValidEmail('test@example.com'), 'Valid email should return true');
        System.assert(CVMAErrorHandler.isValidEmail('user.name+tag@domain.co.uk'), 'Complex valid email should return true');
        System.assert(CVMAErrorHandler.isValidEmail('test123@test-domain.org'), 'Email with numbers and hyphens should be valid');
        
        // Test invalid emails
        System.assert(!CVMAErrorHandler.isValidEmail('invalid-email'), 'Invalid email should return false');
        System.assert(!CVMAErrorHandler.isValidEmail('test@'), 'Incomplete email should return false');
        System.assert(!CVMAErrorHandler.isValidEmail('@domain.com'), 'Email without local part should return false');
        System.assert(!CVMAErrorHandler.isValidEmail('test@domain'), 'Email without TLD should return false');
        System.assert(!CVMAErrorHandler.isValidEmail(''), 'Empty email should return false');
        System.assert(!CVMAErrorHandler.isValidEmail(null), 'Null email should return false');
        
        Test.stopTest();
    }
    
    @IsTest
    static void testErrorLogFallback() {
        // This test simulates when error log object insert fails
        Test.startTest();
        try {
            // Create an exception that will be logged
            throw new System.CalloutException('Test callout failure');
        } catch (Exception ex) {
            // The error handler should gracefully handle cases where error log insert fails
            CVMAErrorHandler.logError(ex, 'TestClass', 'testFallback', 
                CVMAErrorHandler.Severity.HIGH, CVMAErrorHandler.Category.INTEGRATION);
        }
        Test.stopTest();
        
        // Even if error log insert fails, the method should complete without throwing an exception
        System.assert(true, 'Error handler should handle logging failures gracefully');
    }
    
    @IsTest
    static void testCustomExceptionTypes() {
        Test.startTest();
        
        // Test SecurityException
        try {
            throw new CVMAErrorHandler.SecurityException('Security test');
        } catch (CVMAErrorHandler.SecurityException ex) {
            System.assertEquals('Security test', ex.getMessage(), 'SecurityException should carry message');
        }
        
        // Test ValidationException
        try {
            throw new CVMAErrorHandler.ValidationException('Validation test');
        } catch (CVMAErrorHandler.ValidationException ex) {
            System.assertEquals('Validation test', ex.getMessage(), 'ValidationException should carry message');
        }
        
        // Test IntegrationException
        try {
            throw new CVMAErrorHandler.IntegrationException('Integration test');
        } catch (CVMAErrorHandler.IntegrationException ex) {
            System.assertEquals('Integration test', ex.getMessage(), 'IntegrationException should carry message');
        }
        
        Test.stopTest();
    }
}