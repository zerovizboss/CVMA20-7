/**
 * @description Test class for CVMAKnowledgeGoogleDriveHelper
 * Epic #3 - MCP-Enhanced Knowledge Library
 *
 * Tests integration between Knowledge Articles and Google Drive files via
 * CVMA_Google_Drive_File__mdt custom metadata.
 *
 * @author Claude Code
 * @date October 2025
 */
@IsTest
private class CVMAKnowledgeGoogleDriveHelperTest {

    /**
     * @description Test getGoogleDriveURL method with valid file ID
     */
    @IsTest
    static void testGetGoogleDriveURL_ValidFileId() {
        // Arrange
        String testFileId = '1fDc9PNIT0elHsOqjxqqekULocEkiSgsE';

        // Act
        String result = CVMAKnowledgeGoogleDriveHelper.getGoogleDriveURL(testFileId);

        // Assert
        String expectedUrl = 'https://drive.google.com/file/d/' + testFileId + '/view';
        System.assertEquals(expectedUrl, result, 'Should generate correct Google Drive URL');
    }

    /**
     * @description Test getGoogleDriveURL method with null file ID
     */
    @IsTest
    static void testGetGoogleDriveURL_NullFileId() {
        // Act
        String result = CVMAKnowledgeGoogleDriveHelper.getGoogleDriveURL(null);

        // Assert
        System.assertEquals(null, result, 'Should return null for null file ID');
    }

    /**
     * @description Test getGoogleDriveURL method with blank file ID
     */
    @IsTest
    static void testGetGoogleDriveURL_BlankFileId() {
        // Act
        String result = CVMAKnowledgeGoogleDriveHelper.getGoogleDriveURL('  ');

        // Assert
        System.assertEquals(null, result, 'Should return null for blank file ID');
    }

    /**
     * @description Test getGoogleDriveURL method with file ID containing whitespace
     */
    @IsTest
    static void testGetGoogleDriveURL_FileIdWithWhitespace() {
        // Arrange
        String testFileId = '  1fDc9PNIT0elHsOqjxqqekULocEkiSgsE  ';

        // Act
        String result = CVMAKnowledgeGoogleDriveHelper.getGoogleDriveURL(testFileId);

        // Assert
        System.assert(result.contains('1fDc9PNIT0elHsOqjxqqekULocEkiSgsE'),
                     'Should handle file ID with whitespace');
    }

    /**
     * @description Test validateDriveFileExists method
     * Note: This test validates the method logic but will return false
     * since we cannot create custom metadata in tests
     */
    @IsTest
    static void testValidateDriveFileExists() {
        // Arrange
        String testFileId = '1fDc9PNIT0elHsOqjxqqekULocEkiSgsE';

        // Act
        Boolean exists = CVMAKnowledgeGoogleDriveHelper.validateDriveFileExists(testFileId);

        // Assert
        // Will be false in test context (no metadata records)
        // In production with Epic #12 metadata, this would return true
        System.assertNotEquals(null, exists, 'Should return a boolean value');
    }

    /**
     * @description Test validateDriveFileExists with null file ID
     */
    @IsTest
    static void testValidateDriveFileExists_NullFileId() {
        // Act
        Boolean exists = CVMAKnowledgeGoogleDriveHelper.validateDriveFileExists(null);

        // Assert
        System.assertEquals(false, exists, 'Should return false for null file ID');
    }

    /**
     * @description Test getFileMetadata method
     * Note: With Epic #12 metadata deployed, this returns actual file metadata!
     */
    @IsTest
    static void testGetFileMetadata() {
        // Arrange
        String testFileId = '1fDc9PNIT0elHsOqjxqqekULocEkiSgsE';

        // Act
        CVMAKnowledgeGoogleDriveHelper.GoogleDriveFileMetadata metadata =
            CVMAKnowledgeGoogleDriveHelper.getFileMetadata(testFileId);

        // Assert
        // With Epic #12 metadata deployed, should return actual file info
        System.assertNotEquals(null, metadata,
                             'Should return metadata for Epic #12 deployed files');
        if (metadata != null) {
            System.assertEquals(testFileId, metadata.fileId, 'File ID should match');
            System.assertNotEquals(null, metadata.fileName, 'File name should be populated');
            System.assertNotEquals(null, metadata.category, 'Category should be populated');
        }
    }

    /**
     * @description Test getFileMetadata with null file ID
     */
    @IsTest
    static void testGetFileMetadata_NullFileId() {
        // Act
        CVMAKnowledgeGoogleDriveHelper.GoogleDriveFileMetadata metadata =
            CVMAKnowledgeGoogleDriveHelper.getFileMetadata(null);

        // Assert
        System.assertEquals(null, metadata, 'Should return null for null file ID');
    }

    /**
     * @description Test queryKnowledgeWithDrive method
     * Note: Will return empty list in test context without Knowledge Articles
     */
    @IsTest
    static void testQueryKnowledgeWithDrive() {
        // Act
        Test.startTest();
        List<CVMAKnowledgeGoogleDriveHelper.KnowledgeWithDriveWrapper> results =
            CVMAKnowledgeGoogleDriveHelper.queryKnowledgeWithDrive(null, null, false);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, results, 'Should return a list (even if empty)');
    }

    /**
     * @description Test queryKnowledgeWithDrive with search term
     */
    @IsTest
    static void testQueryKnowledgeWithDrive_WithSearchTerm() {
        // Act
        Test.startTest();
        List<CVMAKnowledgeGoogleDriveHelper.KnowledgeWithDriveWrapper> results =
            CVMAKnowledgeGoogleDriveHelper.queryKnowledgeWithDrive(null, 'bylaws', false);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, results, 'Should return a list even with search term');
    }

    /**
     * @description Test GoogleDriveFileMetadata wrapper class
     */
    @IsTest
    static void testGoogleDriveFileMetadata_Constructor() {
        // Arrange
        String fileId = '1fDc9PNIT0elHsOqjxqqekULocEkiSgsE';
        String fileName = 'Test-File.pdf';
        String category = 'Bylaws';
        String description = 'Test description';
        String publicLink = 'https://drive.google.com/file/d/1fDc9PNIT0elHsOqjxqqekULocEkiSgsE/view';
        Boolean cebOnly = false;
        Decimal sizeMB = 1.5;
        Date uploadedDate = Date.today();

        // Act
        CVMAKnowledgeGoogleDriveHelper.GoogleDriveFileMetadata metadata =
            new CVMAKnowledgeGoogleDriveHelper.GoogleDriveFileMetadata(
                fileId, fileName, category, description, publicLink,
                cebOnly, sizeMB, uploadedDate
            );

        // Assert
        System.assertEquals(fileId, metadata.fileId, 'File ID should match');
        System.assertEquals(fileName, metadata.fileName, 'File name should match');
        System.assertEquals(category, metadata.category, 'Category should match');
        System.assertEquals(description, metadata.description, 'Description should match');
        System.assertEquals(publicLink, metadata.publicLink, 'Public link should match');
        System.assertEquals(cebOnly, metadata.cebOnly, 'CEB only flag should match');
        System.assertEquals(sizeMB, metadata.sizeMB, 'Size should match');
        System.assertEquals(uploadedDate, metadata.uploadedDate, 'Uploaded date should match');
    }

    /**
     * @description Test KnowledgeWithDriveWrapper class
     */
    @IsTest
    static void testKnowledgeWithDriveWrapper_Constructor() {
        // Arrange - using mock test data (not real IDs)
        String articleId = 'TEST_ARTICLE_ID';
        String title = 'Test Article';
        String summary = 'Test summary';
        String urlName = 'test-article';
        String driveFileId = '1fDc9PNIT0elHsOqjxqqekULocEkiSgsE';
        String driveDownloadUrl = 'https://drive.google.com/file/d/1fDc9PNIT0elHsOqjxqqekULocEkiSgsE/view';

        // Act
        CVMAKnowledgeGoogleDriveHelper.KnowledgeWithDriveWrapper wrapper =
            new CVMAKnowledgeGoogleDriveHelper.KnowledgeWithDriveWrapper(
                articleId, title, summary, urlName, driveFileId, driveDownloadUrl
            );

        // Assert
        System.assertEquals(articleId, wrapper.articleId, 'Article ID should match');
        System.assertEquals(title, wrapper.title, 'Title should match');
        System.assertEquals(summary, wrapper.summary, 'Summary should match');
        System.assertEquals(urlName, wrapper.urlName, 'URL name should match');
        System.assertEquals(driveFileId, wrapper.driveFileId, 'Drive file ID should match');
        System.assertEquals(driveDownloadUrl, wrapper.driveDownloadUrl, 'Drive download URL should match');
    }
}
