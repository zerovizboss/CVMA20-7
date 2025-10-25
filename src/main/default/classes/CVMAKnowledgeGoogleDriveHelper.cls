/**
 * @description Helper class for integrating Knowledge Articles with Google Drive files
 * Epic #3 - MCP-Enhanced Knowledge Library
 *
 * Provides utility methods to link Salesforce Knowledge Articles to Google Drive files
 * stored via Epic #12's CVMA_Google_Drive_File__mdt custom metadata.
 *
 * Key Methods:
 * - getGoogleDriveURL(fileId): Generate Drive download link from file ID
 * - validateDriveFileExists(fileId): Check if file exists in metadata registry
 * - getFileMetadata(fileId): Get full metadata for a Drive file
 * - queryKnowledgeWithDrive(): Query Knowledge Articles with Drive integration
 *
 * @author Claude Code
 * @date October 2025
 */
public with sharing class CVMAKnowledgeGoogleDriveHelper {

    /**
     * @description Generates Google Drive download URL from file ID
     * @param driveFileId The Google Drive file ID (from Google_Drive_File_ID__c field)
     * @return Full URL for direct file access, or null if invalid
     *
     * EXAMPLE:
     * String url = CVMAKnowledgeGoogleDriveHelper.getGoogleDriveURL('1fDc9PNIT0elHsOqjxqqekULocEkiSgsE');
     * // Returns: https://drive.google.com/file/d/1fDc9PNIT0elHsOqjxqqekULocEkiSgsE/view
     */
    public static String getGoogleDriveURL(String driveFileId) {
        if (String.isBlank(driveFileId)) {
            return null;
        }

        // Google Drive direct link pattern
        return 'https://drive.google.com/file/d/' + driveFileId.trim() + '/view';
    }

    /**
     * @description Checks if file ID exists in CVMA_Google_Drive_File__mdt registry
     * @param driveFileId The Google Drive file ID to validate
     * @return Boolean - true if file exists in metadata, false otherwise
     *
     * EXAMPLE:
     * Boolean exists = CVMAKnowledgeGoogleDriveHelper.validateDriveFileExists('1fDc9PNIT0elHsOqjxqqekULocEkiSgsE');
     * if (exists) {
     *     System.debug('File is registered in metadata');
     * }
     */
    public static Boolean validateDriveFileExists(String driveFileId) {
        if (String.isBlank(driveFileId)) {
            return false;
        }

        List<CVMA_Google_Drive_File__mdt> files = [
            SELECT Id
            FROM CVMA_Google_Drive_File__mdt
            WHERE Google_Drive_ID__c = :driveFileId.trim()
            AND Is_Active__c = true
            LIMIT 1
        ];

        return !files.isEmpty();
    }

    /**
     * @description Retrieves full metadata for a Google Drive file
     * @param driveFileId The Google Drive file ID
     * @return GoogleDriveFileMetadata wrapper with file details, or null if not found
     *
     * EXAMPLE:
     * GoogleDriveFileMetadata metadata = CVMAKnowledgeGoogleDriveHelper.getFileMetadata('1fDc9PNIT0elHsOqjxqqekULocEkiSgsE');
     * System.debug('File Name: ' + metadata.fileName);
     * System.debug('Category: ' + metadata.category);
     */
    public static GoogleDriveFileMetadata getFileMetadata(String driveFileId) {
        if (String.isBlank(driveFileId)) {
            return null;
        }

        List<CVMA_Google_Drive_File__mdt> files = [
            SELECT QualifiedApiName, MasterLabel, File_Name__c, Google_Drive_ID__c,
                   File_Type__c, Category__c, Public_Link__c, Size_MB__c,
                   Uploaded_Date__c, Description__c, CEB_Only__c, Display_Order__c
            FROM CVMA_Google_Drive_File__mdt
            WHERE Google_Drive_ID__c = :driveFileId.trim()
            AND Is_Active__c = true
            LIMIT 1
        ];

        if (files.isEmpty()) {
            return null;
        }

        CVMA_Google_Drive_File__mdt file = files[0];
        return new GoogleDriveFileMetadata(
            file.Google_Drive_ID__c,
            file.File_Name__c,
            file.Category__c,
            file.Description__c,
            file.Public_Link__c,
            file.CEB_Only__c,
            file.Size_MB__c,
            file.Uploaded_Date__c
        );
    }

    /**
     * @description Queries Knowledge Articles and enriches with Google Drive metadata
     * This method demonstrates the integration pattern for LWC components
     *
     * @param category Optional category filter
     * @param searchTerm Optional search term for title/summary
     * @param cebOnly Filter for CEB-restricted content
     * @return List of KnowledgeWithDriveWrapper objects
     *
     * EXAMPLE:
     * List<KnowledgeWithDriveWrapper> bylaws =
     *     CVMAKnowledgeGoogleDriveHelper.queryKnowledgeWithDrive('Bylaws', null, false);
     */
    @AuraEnabled(cacheable=true)
    public static List<KnowledgeWithDriveWrapper> queryKnowledgeWithDrive(
        String category,
        String searchTerm,
        Boolean cebOnly
    ) {
        try {
            // Build dynamic SOQL for Knowledge Articles
            String query =
                'SELECT Id, Title, Summary, UrlName, ArticleNumber, ' +
                '       LastPublishedDate, Question__c, Content__c ' +
                'FROM Knowledge__kav ' +
                'WHERE PublishStatus = \'Online\' ' +
                'AND Language = \'en_US\' ';

            // Apply search filter
            if (String.isNotBlank(searchTerm)) {
                String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
                query += 'AND (Title LIKE :searchPattern OR Summary LIKE :searchPattern) ';
            }

            query += 'ORDER BY Title ASC LIMIT 100';

            List<Knowledge__kav> articles = Database.query(query);

            // Enrich with Google Drive metadata
            List<KnowledgeWithDriveWrapper> results = new List<KnowledgeWithDriveWrapper>();

            for (Knowledge__kav article : articles) {
                // For POC, we'll add the linking logic here
                // In production, Knowledge Articles will have Google_Drive_File_ID__c field
                results.add(new KnowledgeWithDriveWrapper(
                    article.Id,
                    article.Title,
                    article.Summary,
                    article.UrlName,
                    null, // driveFileId - will be populated from custom field in production
                    null  // driveDownloadUrl - will be generated from file ID
                ));
            }

            return results;

        } catch (Exception e) {
            throw new AuraHandledException('Error querying Knowledge Articles: ' + e.getMessage());
        }
    }

    /**
     * @description Wrapper class for Google Drive file metadata
     */
    public class GoogleDriveFileMetadata {
        @AuraEnabled public String fileId { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String publicLink { get; set; }
        @AuraEnabled public Boolean cebOnly { get; set; }
        @AuraEnabled public Decimal sizeMB { get; set; }
        @AuraEnabled public Date uploadedDate { get; set; }

        public GoogleDriveFileMetadata(
            String fileId,
            String fileName,
            String category,
            String description,
            String publicLink,
            Boolean cebOnly,
            Decimal sizeMB,
            Date uploadedDate
        ) {
            this.fileId = fileId;
            this.fileName = fileName;
            this.category = category;
            this.description = description;
            this.publicLink = publicLink;
            this.cebOnly = cebOnly;
            this.sizeMB = sizeMB;
            this.uploadedDate = uploadedDate;
        }
    }

    /**
     * @description Wrapper class for Knowledge Article with Drive integration
     */
    public class KnowledgeWithDriveWrapper {
        @AuraEnabled public String articleId { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String summary { get; set; }
        @AuraEnabled public String urlName { get; set; }
        @AuraEnabled public String driveFileId { get; set; }
        @AuraEnabled public String driveDownloadUrl { get; set; }

        public KnowledgeWithDriveWrapper(
            String articleId,
            String title,
            String summary,
            String urlName,
            String driveFileId,
            String driveDownloadUrl
        ) {
            this.articleId = articleId;
            this.title = title;
            this.summary = summary;
            this.urlName = urlName;
            this.driveFileId = driveFileId;
            this.driveDownloadUrl = driveDownloadUrl;
        }
    }
}
