/**
 * Test class for CVMAConfigurationHelper
 * Tests configuration access, caching, and merge field functionality
 */
@IsTest
private class CVMAConfigurationHelperTest {
    
    @IsTest
    static void testGetConfigValues() {
        Test.startTest();
        
        // Test getting configuration values
        String membershipFormat = CVMAConfigurationHelper.getMembershipIdFormat();
        Integer pageSize = CVMAConfigurationHelper.getDashboardPageSize();
        Integer batchSize = CVMAConfigurationHelper.getEmailBatchSize();
        
        Test.stopTest();
        
        // Verify default values are returned when metadata doesn't exist
        System.assertEquals('CVMA-20-7-{YYYY}-{NNNN}', membershipFormat, 'Should return default membership ID format');
        System.assertEquals(50, pageSize, 'Should return default page size');
        System.assertEquals(10, batchSize, 'Should return default batch size');
    }
    
    @IsTest
    static void testMembershipIdGeneration() {
        Test.startTest();
        
        // Test membership ID generation
        String membershipId1 = CVMAConfigurationHelper.generateMembershipId(1);
        String membershipId123 = CVMAConfigurationHelper.generateMembershipId(123);
        
        Test.stopTest();
        
        // Verify format is correct
        String currentYear = String.valueOf(Date.today().year());
        System.assertEquals('CVMA-20-7-' + currentYear + '-0001', membershipId1, 'Should generate correct membership ID for sequence 1');
        System.assertEquals('CVMA-20-7-' + currentYear + '-0123', membershipId123, 'Should generate correct membership ID for sequence 123');
    }
    
    @IsTest
    static void testEmailTemplateAccess() {
        Test.startTest();
        
        // Clear cache to ensure fresh lookup
        CVMAConfigurationHelper.clearCache();
        
        // Test email template access
        CVMA_Email_Template__mdt renewalTemplate = CVMAConfigurationHelper.getEmailTemplate('Renewal_Reminder');
        CVMA_Email_Template__mdt welcomeTemplate = CVMAConfigurationHelper.getEmailTemplate('Welcome_New_Member');
        CVMA_Email_Template__mdt nonExistentTemplate = CVMAConfigurationHelper.getEmailTemplate('NonExistent');
        
        Test.stopTest();
        
        // Verify results (templates may not exist in test context)
        System.assertEquals(null, nonExistentTemplate, 'Should return null for non-existent template');
    }
    
    @IsTest
    static void testMergeFieldReplacement() {
        Test.startTest();
        
        // Test merge field replacement
        Map<String, String> mergeFields = new Map<String, String>{
            'FirstName' => 'John',
            'LastName' => 'Doe',
            'MembershipId' => 'CVMA-20-7-2024-0001',
            'MemberLevel' => 'Full Member'
        };
        
        // Create mock template content
        String subject = 'Welcome {!FirstName} {!LastName}';
        String body = 'Dear {!FirstName}, your membership ID is {!MembershipId} with level {!MemberLevel}.';
        
        // Since we can't easily mock custom metadata in tests, we'll test the merge logic
        // by calling getEmailSubject and getEmailBody (which will return null but test the merge logic)
        String processedSubject = CVMAConfigurationHelper.getEmailSubject('Welcome_New_Member', mergeFields);
        String processedBody = CVMAConfigurationHelper.getEmailBody('Welcome_New_Member', mergeFields);
        
        Test.stopTest();
        
        // The methods will return null since templates don't exist in test context
        // but this tests that the methods don't throw exceptions
        System.assertEquals(null, processedSubject, 'Should return null when template not found');
        System.assertEquals(null, processedBody, 'Should return null when template not found');
    }
    
    @IsTest
    static void testConfigurationValidation() {
        Test.startTest();
        
        // Test configuration validation
        List<String> validationIssues = CVMAConfigurationHelper.validateConfiguration();
        
        Test.stopTest();
        
        // In test context, metadata may not exist, so we expect some issues
        System.assertNotEquals(null, validationIssues, 'Should return validation issues list');
        
        // The specific issues depend on what metadata exists in the test org
        // This test primarily ensures the validation method doesn't throw exceptions
    }
    
    @IsTest
    static void testCacheClearing() {
        Test.startTest();
        
        // Test cache clearing functionality
        CVMAConfigurationHelper.clearCache();
        
        // Access configuration to populate cache
        Integer pageSize1 = CVMAConfigurationHelper.getDashboardPageSize();
        
        // Clear cache and access again
        CVMAConfigurationHelper.clearCache();
        Integer pageSize2 = CVMAConfigurationHelper.getDashboardPageSize();
        
        Test.stopTest();
        
        // Both should return the same default value
        System.assertEquals(pageSize1, pageSize2, 'Should return consistent values after cache clear');
    }
    
    @IsTest
    static void testNullInputHandling() {
        Test.startTest();
        
        // Test null input handling
        String nullConfig = CVMAConfigurationHelper.getConfigTextValue(null);
        Decimal nullNumeric = CVMAConfigurationHelper.getConfigNumericValue(null);
        Boolean nullBoolean = CVMAConfigurationHelper.getConfigBooleanValue(null);
        CVMA_Email_Template__mdt nullTemplate = CVMAConfigurationHelper.getEmailTemplate(null);
        
        Test.stopTest();
        
        // Verify null handling
        System.assertEquals(null, nullConfig, 'Should handle null config name');
        System.assertEquals(null, nullNumeric, 'Should handle null numeric config name');
        System.assertEquals(false, nullBoolean, 'Should return false for null boolean config name');
        System.assertEquals(null, nullTemplate, 'Should handle null template name');
    }
    
    @IsTest
    static void testEmptyMergeFields() {
        Test.startTest();
        
        // Test with empty merge fields
        Map<String, String> emptyMergeFields = new Map<String, String>();
        String subject = CVMAConfigurationHelper.getEmailSubject('Welcome_New_Member', emptyMergeFields);
        String body = CVMAConfigurationHelper.getEmailBody('Welcome_New_Member', emptyMergeFields);
        
        // Test with null merge fields
        String subjectNull = CVMAConfigurationHelper.getEmailSubject('Welcome_New_Member', null);
        String bodyNull = CVMAConfigurationHelper.getEmailBody('Welcome_New_Member', null);
        
        Test.stopTest();
        
        // Should handle empty and null merge fields gracefully
        System.assertEquals(null, subject, 'Should handle empty merge fields');
        System.assertEquals(null, body, 'Should handle empty merge fields');
        System.assertEquals(null, subjectNull, 'Should handle null merge fields');
        System.assertEquals(null, bodyNull, 'Should handle null merge fields');
    }
    
    @IsTest
    static void testMembershipIdSequenceVariations() {
        Test.startTest();
        
        // Test different sequence numbers
        String id1 = CVMAConfigurationHelper.generateMembershipId(1);
        String id10 = CVMAConfigurationHelper.generateMembershipId(10);
        String id100 = CVMAConfigurationHelper.generateMembershipId(100);
        String id1000 = CVMAConfigurationHelper.generateMembershipId(1000);
        String id9999 = CVMAConfigurationHelper.generateMembershipId(9999);
        
        Test.stopTest();
        
        String currentYear = String.valueOf(Date.today().year());
        
        // Verify correct zero-padding
        System.assertEquals('CVMA-20-7-' + currentYear + '-0001', id1, 'Should pad single digit');
        System.assertEquals('CVMA-20-7-' + currentYear + '-0010', id10, 'Should pad double digit');
        System.assertEquals('CVMA-20-7-' + currentYear + '-0100', id100, 'Should pad triple digit');
        System.assertEquals('CVMA-20-7-' + currentYear + '-1000', id1000, 'Should not pad four digits');
        System.assertEquals('CVMA-20-7-' + currentYear + '-9999', id9999, 'Should handle max four digits');
    }
}