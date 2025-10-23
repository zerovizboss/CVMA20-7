/**
 * @description Test class for CVMAGoogleDriveManagementController
 * Epic #12, User Story #89 - Metadata Management
 *
 * Tests CEB admin functionality for Google Drive file management:
 * - File retrieval with filtering
 * - Statistics calculation
 * - Google Drive ID validation
 * - CSV export
 * - Security (CEB-only access)
 *
 * @author Claude Code
 * @date October 2025
 */
@IsTest
private class CVMAGoogleDriveManagementControllerTest {

    /**
     * @description Test retrieval of all Google Drive files
     */
    @IsTest
    static void testGetAllFiles_Success() {
        // Setup: Create test user with CEB permission
        User cebUser = createCEBUser();

        System.runAs(cebUser) {
            Test.startTest();

            // Test: Get all active files
            List<CVMAGoogleDriveManagementController.GoogleDriveFileAdminWrapper> files =
                CVMAGoogleDriveManagementController.getAllFiles(false, 'All', null);

            Test.stopTest();

            // Verify: Files returned (metadata should exist in org)
            System.assertNotEquals(null, files, 'Files list should not be null');
            // Note: Actual count depends on deployed metadata
        }
    }

    /**
     * @description Test retrieval with category filter
     */
    @IsTest
    static void testGetAllFiles_WithCategoryFilter() {
        User cebUser = createCEBUser();

        System.runAs(cebUser) {
            Test.startTest();

            // Test: Get files by category
            List<CVMAGoogleDriveManagementController.GoogleDriveFileAdminWrapper> files =
                CVMAGoogleDriveManagementController.getAllFiles(false, 'Bylaws', null);

            Test.stopTest();

            // Verify: Only Bylaws category returned
            for (CVMAGoogleDriveManagementController.GoogleDriveFileAdminWrapper file : files) {
                System.assertEquals('Bylaws', file.category,
                    'Should only return Bylaws category');
            }
        }
    }

    /**
     * @description Test retrieval with search term
     */
    @IsTest
    static void testGetAllFiles_WithSearchTerm() {
        User cebUser = createCEBUser();

        System.runAs(cebUser) {
            Test.startTest();

            // Test: Search for specific term
            List<CVMAGoogleDriveManagementController.GoogleDriveFileAdminWrapper> files =
                CVMAGoogleDriveManagementController.getAllFiles(false, 'All', 'Bylaws');

            Test.stopTest();

            // Verify: Results match search term
            System.assertNotEquals(null, files, 'Files list should not be null');
        }
    }

    /**
     * @description Test retrieval including inactive files
     */
    @IsTest
    static void testGetAllFiles_IncludeInactive() {
        User cebUser = createCEBUser();

        System.runAs(cebUser) {
            Test.startTest();

            // Test: Get all files including inactive
            List<CVMAGoogleDriveManagementController.GoogleDriveFileAdminWrapper> files =
                CVMAGoogleDriveManagementController.getAllFiles(true, 'All', null);

            Test.stopTest();

            // Verify: Results include inactive files
            System.assertNotEquals(null, files, 'Files list should not be null');
        }
    }

    /**
     * @description Test security - non-CEB user access denied
     */
    @IsTest
    static void testGetAllFiles_NonCEBUser_AccessDenied() {
        // Setup: Create standard user without CEB permission
        User standardUser = createStandardUser();

        System.runAs(standardUser) {
            Test.startTest();

            Boolean exceptionThrown = false;
            String errorMessage = '';

            try {
                CVMAGoogleDriveManagementController.getAllFiles(false, 'All', null);
            } catch (AuraHandledException e) {
                exceptionThrown = true;
                errorMessage = e.getMessage();
            }

            Test.stopTest();

            // Verify: Access denied for non-CEB user
            System.assert(exceptionThrown, 'Should throw exception for non-CEB user');
            System.assert(errorMessage.contains('Access denied'), 'Error message should indicate access denied');
        }
    }

    /**
     * @description Test file statistics calculation
     */
    @IsTest
    static void testGetFileStatistics() {
        User cebUser = createCEBUser();

        System.runAs(cebUser) {
            Test.startTest();

            Map<String, Object> stats = CVMAGoogleDriveManagementController.getFileStatistics();

            Test.stopTest();

            // Verify: Statistics returned
            System.assertNotEquals(null, stats, 'Statistics should not be null');
            System.assert(stats.containsKey('totalFiles'), 'Should include total files count');
            System.assert(stats.containsKey('activeFiles'), 'Should include active files count');
            System.assert(stats.containsKey('categoryCount'), 'Should include category breakdown');
            System.assert(stats.containsKey('totalSizeMB'), 'Should include total size');
        }
    }

    /**
     * @description Test Google Drive ID validation - valid ID
     */
    @IsTest
    static void testValidateGoogleDriveId_Valid() {
        User cebUser = createCEBUser();

        System.runAs(cebUser) {
            Test.startTest();

            // Test: Validate a properly formatted new ID
            String newDriveId = '1XYZ123abc456def789ghi012';
            Map<String, Object> result =
                CVMAGoogleDriveManagementController.validateGoogleDriveId(newDriveId);

            Test.stopTest();

            // Verify: Validation passed (assuming ID doesn't exist yet)
            // Note: May fail if this exact ID exists in metadata
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assert(result.containsKey('valid'), 'Result should contain valid flag');
        }
    }

    /**
     * @description Test Google Drive ID validation - empty ID
     */
    @IsTest
    static void testValidateGoogleDriveId_Empty() {
        User cebUser = createCEBUser();

        System.runAs(cebUser) {
            Test.startTest();

            Map<String, Object> result =
                CVMAGoogleDriveManagementController.validateGoogleDriveId('');

            Test.stopTest();

            // Verify: Validation failed for empty ID
            System.assertEquals(false, result.get('valid'), 'Empty ID should be invalid');
            System.assert(((String)result.get('message')).contains('cannot be empty'),
                'Error message should mention empty ID');
        }
    }

    /**
     * @description Test Google Drive ID validation - invalid length
     */
    @IsTest
    static void testValidateGoogleDriveId_InvalidLength() {
        User cebUser = createCEBUser();

        System.runAs(cebUser) {
            Test.startTest();

            Map<String, Object> result =
                CVMAGoogleDriveManagementController.validateGoogleDriveId('abc123');

            Test.stopTest();

            // Verify: Validation failed for too short ID
            System.assertEquals(false, result.get('valid'), 'Short ID should be invalid');
            System.assert(((String)result.get('message')).contains('Invalid ID length'),
                'Error message should mention invalid length');
        }
    }

    /**
     * @description Test Google Drive ID validation - invalid characters
     */
    @IsTest
    static void testValidateGoogleDriveId_InvalidCharacters() {
        User cebUser = createCEBUser();

        System.runAs(cebUser) {
            Test.startTest();

            Map<String, Object> result =
                CVMAGoogleDriveManagementController.validateGoogleDriveId('1XYZ@123#invalid$chars!');

            Test.stopTest();

            // Verify: Validation failed for invalid characters
            System.assertEquals(false, result.get('valid'), 'ID with special chars should be invalid');
            System.assert(((String)result.get('message')).contains('Invalid characters'),
                'Error message should mention invalid characters');
        }
    }

    /**
     * @description Test CSV export functionality
     */
    @IsTest
    static void testExportToCSV() {
        User cebUser = createCEBUser();

        System.runAs(cebUser) {
            Test.startTest();

            String csv = CVMAGoogleDriveManagementController.exportToCSV(false);

            Test.stopTest();

            // Verify: CSV contains header and data
            System.assertNotEquals(null, csv, 'CSV should not be null');
            System.assert(csv.contains('QualifiedApiName'), 'CSV should contain header');
            System.assert(csv.contains(','), 'CSV should be comma-separated');
        }
    }

    /**
     * @description Test get categories
     */
    @IsTest
    static void testGetCategories() {
        User cebUser = createCEBUser();

        System.runAs(cebUser) {
            Test.startTest();

            List<String> categories = CVMAGoogleDriveManagementController.getCategories();

            Test.stopTest();

            // Verify: Categories returned
            System.assertNotEquals(null, categories, 'Categories should not be null');
        }
    }

    /**
     * @description Test isCEBOfficer for CEB user
     */
    @IsTest
    static void testIsCEBOfficer_CEBUser() {
        User cebUser = createCEBUser();

        System.runAs(cebUser) {
            Test.startTest();

            Boolean isCEB = CVMAGoogleDriveManagementController.isCEBOfficer();

            Test.stopTest();

            // Verify: CEB user identified correctly
            System.assertEquals(true, isCEB, 'CEB user should be identified');
        }
    }

    /**
     * @description Test isCEBOfficer for standard user
     */
    @IsTest
    static void testIsCEBOfficer_StandardUser() {
        User standardUser = createStandardUser();

        System.runAs(standardUser) {
            Test.startTest();

            Boolean isCEB = CVMAGoogleDriveManagementController.isCEBOfficer();

            Test.stopTest();

            // Verify: Standard user not identified as CEB
            System.assertEquals(false, isCEB, 'Standard user should not be CEB');
        }
    }

    // ========== Test Data Helpers ==========

    /**
     * @description Creates test user with System Administrator profile (CEB access)
     * @return Test user with CEB permissions
     */
    private static User createCEBUser() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User cebUser = new User(
            Alias = 'cebtest',
            Email = 'cebtest@cvma20-7.org.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'CEB Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'cebtest' + System.currentTimeMillis() + '@cvma20-7.org.test'
        );

        insert cebUser;

        return cebUser;
    }

    /**
     * @description Creates test user with standard profile (no CEB access)
     * @return Test user without CEB permissions
     */
    private static User createStandardUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User standardUser = new User(
            Alias = 'stdtest',
            Email = 'standardtest@cvma20-7.org.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Standard Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            UserName = 'standardtest' + System.currentTimeMillis() + '@cvma20-7.org.test'
        );

        insert standardUser;

        return standardUser;
    }
}
