/**
 * @description Controller for CVMA Google Drive Management Component
 * Epic #12, User Story #89 - Metadata Management (CEB Admin)
 *
 * Provides CEB officers with comprehensive metadata management:
 * - View all Google Drive files (including inactive)
 * - Advanced filtering and search
 * - Export metadata to CSV
 * - Validation of Google Drive IDs
 *
 * Note: Custom metadata records are read-only at runtime.
 * Updates require deployment via Salesforce CLI or Metadata API.
 * This component provides visibility and export capabilities.
 *
 * @author Claude Code
 * @date October 2025
 */
public with sharing class CVMAGoogleDriveManagementController {

    /**
     * @description Retrieves all Google Drive files for admin management
     * @param includeInactive Include inactive files in results
     * @param category Filter by category
     * @param searchTerm Search in file name and description
     * @return List of file metadata with enhanced admin details
     */
    @AuraEnabled(cacheable=true)
    public static List<GoogleDriveFileAdminWrapper> getAllFiles(
        Boolean includeInactive,
        String category,
        String searchTerm
    ) {
        try {
            // Security: CEB officers only
            if (!isCEBOfficer()) {
                throw new AuraHandledException('Access denied. CEB officers only.');
            }

            // Build dynamic SOQL query
            String query = 'SELECT QualifiedApiName, MasterLabel, File_Name__c, Google_Drive_ID__c, ' +
                          'File_Type__c, Category__c, Public_Link__c, Size_MB__c, ' +
                          'Uploaded_Date__c, Description__c, CEB_Only__c, Display_Order__c, Is_Active__c ' +
                          'FROM CVMA_Google_Drive_File__mdt';

            // Apply active filter
            if (!includeInactive) {
                query += ' WHERE Is_Active__c = true';
            } else {
                query += ' WHERE Is_Active__c IN (true, false)';
            }

            // Apply category filter
            if (String.isNotBlank(category) && category != 'All') {
                query += ' AND Category__c = :category';
            }

            query += ' ORDER BY Category__c, Display_Order__c ASC';

            // Execute query
            List<CVMA_Google_Drive_File__mdt> files = Database.query(String.escapeSingleQuotes(query));

            // Wrap results and apply search filter
            List<GoogleDriveFileAdminWrapper> results = new List<GoogleDriveFileAdminWrapper>();

            for (CVMA_Google_Drive_File__mdt file : files) {
                // Apply search term filter if provided
                if (String.isNotBlank(searchTerm)) {
                    String lowerSearch = searchTerm.toLowerCase();
                    String fileName = file.File_Name__c != null ? file.File_Name__c.toLowerCase() : '';
                    String description = file.Description__c != null ? file.Description__c.toLowerCase() : '';
                    String apiName = file.QualifiedApiName != null ? file.QualifiedApiName.toLowerCase() : '';

                    if (!fileName.contains(lowerSearch) &&
                        !description.contains(lowerSearch) &&
                        !apiName.contains(lowerSearch)) {
                        continue; // Skip this file
                    }
                }

                results.add(new GoogleDriveFileAdminWrapper(file));
            }

            return results;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving files: ' + e.getMessage());
        }
    }

    /**
     * @description Gets statistics about Google Drive files
     * @return Map of statistics (total files, categories, storage, etc.)
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFileStatistics() {
        try {
            // Security: CEB officers only
            if (!isCEBOfficer()) {
                throw new AuraHandledException('Access denied. CEB officers only.');
            }

            Map<String, Object> stats = new Map<String, Object>();

            // Get all files
            List<CVMA_Google_Drive_File__mdt> allFiles = [
                SELECT Category__c, Size_MB__c, Is_Active__c, CEB_Only__c, File_Type__c
                FROM CVMA_Google_Drive_File__mdt
            ];

            // Calculate statistics
            Integer totalFiles = allFiles.size();
            Integer activeFiles = 0;
            Integer cebOnlyFiles = 0;
            Decimal totalSizeMB = 0;
            Map<String, Integer> categoryCount = new Map<String, Integer>();
            Map<String, Integer> fileTypeCount = new Map<String, Integer>();

            for (CVMA_Google_Drive_File__mdt file : allFiles) {
                // Count active files
                if (file.Is_Active__c) {
                    activeFiles++;
                }

                // Count CEB-only files
                if (file.CEB_Only__c) {
                    cebOnlyFiles++;
                }

                // Sum total size
                if (file.Size_MB__c != null) {
                    totalSizeMB += file.Size_MB__c;
                }

                // Count by category
                String cat = file.Category__c != null ? file.Category__c : 'Uncategorized';
                if (!categoryCount.containsKey(cat)) {
                    categoryCount.put(cat, 0);
                }
                categoryCount.put(cat, categoryCount.get(cat) + 1);

                // Count by file type
                String type = file.File_Type__c != null ? file.File_Type__c : 'Unknown';
                if (!fileTypeCount.containsKey(type)) {
                    fileTypeCount.put(type, 0);
                }
                fileTypeCount.put(type, fileTypeCount.get(type) + 1);
            }

            stats.put('totalFiles', totalFiles);
            stats.put('activeFiles', activeFiles);
            stats.put('inactiveFiles', totalFiles - activeFiles);
            stats.put('cebOnlyFiles', cebOnlyFiles);
            stats.put('totalSizeMB', totalSizeMB.setScale(2));
            stats.put('categoryCount', categoryCount);
            stats.put('fileTypeCount', fileTypeCount);

            return stats;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving statistics: ' + e.getMessage());
        }
    }

    /**
     * @description Validates a Google Drive file ID by checking URL format
     * @param driveId Google Drive file ID to validate
     * @return Validation result with details
     */
    @AuraEnabled
    public static Map<String, Object> validateGoogleDriveId(String driveId) {
        try {
            // Security: CEB officers only
            if (!isCEBOfficer()) {
                throw new AuraHandledException('Access denied. CEB officers only.');
            }

            Map<String, Object> result = new Map<String, Object>();

            // Basic validation
            if (String.isBlank(driveId)) {
                result.put('valid', false);
                result.put('message', 'Google Drive ID cannot be empty');
                return result;
            }

            // Trim whitespace
            driveId = driveId.trim();

            // Check length (Google Drive IDs are typically 28-33 characters)
            if (driveId.length() < 20 || driveId.length() > 50) {
                result.put('valid', false);
                result.put('message', 'Invalid ID length. Expected 20-50 characters, got: ' + driveId.length());
                return result;
            }

            // Check for special characters (Drive IDs are alphanumeric with - and _)
            Pattern p = Pattern.compile('[^a-zA-Z0-9_-]');
            Matcher m = p.matcher(driveId);
            if (m.find()) {
                result.put('valid', false);
                result.put('message', 'Invalid characters detected. Use alphanumeric, dash, and underscore only.');
                return result;
            }

            // Check if ID already exists
            List<CVMA_Google_Drive_File__mdt> existing = [
                SELECT QualifiedApiName, File_Name__c
                FROM CVMA_Google_Drive_File__mdt
                WHERE Google_Drive_ID__c = :driveId
                LIMIT 1
            ];

            if (!existing.isEmpty()) {
                result.put('valid', false);
                result.put('message', 'Duplicate: This Google Drive ID is already registered for file: ' +
                          existing[0].File_Name__c);
                result.put('existingFile', existing[0].QualifiedApiName);
                return result;
            }

            // All validations passed
            result.put('valid', true);
            result.put('message', 'Valid Google Drive ID');
            result.put('publicLink', 'https://drive.google.com/file/d/' + driveId + '/view');

            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Error validating Google Drive ID: ' + e.getMessage());
        }
    }

    /**
     * @description Gets list of unique categories for filter dropdown
     * @return List of category values
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getCategories() {
        try {
            // Security: CEB officers only
            if (!isCEBOfficer()) {
                throw new AuraHandledException('Access denied. CEB officers only.');
            }

            Set<String> categorySet = new Set<String>();

            for (CVMA_Google_Drive_File__mdt file : [
                SELECT Category__c
                FROM CVMA_Google_Drive_File__mdt
            ]) {
                if (String.isNotBlank(file.Category__c)) {
                    categorySet.add(file.Category__c);
                }
            }

            List<String> categories = new List<String>(categorySet);
            categories.sort();

            return categories;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving categories: ' + e.getMessage());
        }
    }

    /**
     * @description Exports file metadata to CSV format
     * @param includeInactive Include inactive files in export
     * @return CSV string with all metadata
     */
    @AuraEnabled
    public static String exportToCSV(Boolean includeInactive) {
        try {
            // Security: CEB officers only
            if (!isCEBOfficer()) {
                throw new AuraHandledException('Access denied. CEB officers only.');
            }

            // Build CSV header
            String csv = 'QualifiedApiName,Label,File_Name,Google_Drive_ID,File_Type,Category,' +
                        'Size_MB,Uploaded_Date,Description,CEB_Only,Display_Order,Is_Active,Public_Link\n';

            // Get all files
            String query = 'SELECT QualifiedApiName, MasterLabel, File_Name__c, Google_Drive_ID__c, ' +
                          'File_Type__c, Category__c, Size_MB__c, Uploaded_Date__c, Description__c, ' +
                          'CEB_Only__c, Display_Order__c, Is_Active__c, Public_Link__c ' +
                          'FROM CVMA_Google_Drive_File__mdt';

            if (!includeInactive) {
                query += ' WHERE Is_Active__c = true';
            }

            query += ' ORDER BY Category__c, Display_Order__c';

            List<CVMA_Google_Drive_File__mdt> files = Database.query(String.escapeSingleQuotes(query));

            // Build CSV rows
            for (CVMA_Google_Drive_File__mdt file : files) {
                csv += escapeCsvField(file.QualifiedApiName) + ',';
                csv += escapeCsvField(file.MasterLabel) + ',';
                csv += escapeCsvField(file.File_Name__c) + ',';
                csv += escapeCsvField(file.Google_Drive_ID__c) + ',';
                csv += escapeCsvField(file.File_Type__c) + ',';
                csv += escapeCsvField(file.Category__c) + ',';
                csv += (file.Size_MB__c != null ? String.valueOf(file.Size_MB__c) : '') + ',';
                csv += (file.Uploaded_Date__c != null ? String.valueOf(file.Uploaded_Date__c) : '') + ',';
                csv += escapeCsvField(file.Description__c) + ',';
                csv += (file.CEB_Only__c ? 'true' : 'false') + ',';
                csv += (file.Display_Order__c != null ? String.valueOf(file.Display_Order__c) : '') + ',';
                csv += (file.Is_Active__c ? 'true' : 'false') + ',';
                csv += escapeCsvField(file.Public_Link__c) + '\n';
            }

            return csv;

        } catch (Exception e) {
            throw new AuraHandledException('Error exporting to CSV: ' + e.getMessage());
        }
    }

    /**
     * @description Escapes CSV field values (handles commas, quotes, newlines)
     * @param value Field value to escape
     * @return Escaped value safe for CSV
     */
    private static String escapeCsvField(String value) {
        if (value == null) {
            return '';
        }

        // If field contains comma, quote, or newline, wrap in quotes
        if (value.contains(',') || value.contains('"') || value.contains('\n')) {
            // Escape existing quotes by doubling them
            value = value.replace('"', '""');
            return '"' + value + '"';
        }

        return value;
    }

    /**
     * @description Checks if current user is a CEB officer
     * @return true if user has CEB access
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isCEBOfficer() {
        try {
            // Block guest users
            if (UserInfo.getUserType() == 'Guest') {
                return false;
            }

            Id userId = UserInfo.getUserId();

            // Check for CEB Permission Set
            List<PermissionSetAssignment> cebPermSets = [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
                AND (PermissionSet.Name LIKE 'CVMA%CEB%'
                     OR PermissionSet.Name LIKE 'CVMA%Commander%'
                     OR PermissionSet.Name LIKE 'CVMA%Treasurer%'
                     OR PermissionSet.Name LIKE 'CVMA%Secretary%'
                     OR PermissionSet.Name LIKE 'CVMA%RoadCaptain%')
                LIMIT 1
            ];

            if (!cebPermSets.isEmpty()) {
                return true;
            }

            // Check if System Administrator
            String profileName = [SELECT Profile.Name FROM User WHERE Id = :userId LIMIT 1].Profile.Name;
            if (profileName == 'System Administrator') {
                return true;
            }

            return false;

        } catch (Exception e) {
            System.debug('Error checking CEB access: ' + e.getMessage());
            return false;
        }
    }

    /**
     * @description Wrapper class for Google Drive file metadata (admin view)
     * Includes additional computed properties for management
     */
    public class GoogleDriveFileAdminWrapper {
        @AuraEnabled public String qualifiedApiName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String driveId { get; set; }
        @AuraEnabled public String fileType { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public String publicLink { get; set; }
        @AuraEnabled public Decimal sizeMB { get; set; }
        @AuraEnabled public String uploadedDate { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public Boolean cebOnly { get; set; }
        @AuraEnabled public Decimal displayOrder { get; set; }
        @AuraEnabled public Boolean isActive { get; set; }
        @AuraEnabled public String fileIcon { get; set; }
        @AuraEnabled public String fileSizeDisplay { get; set; }
        @AuraEnabled public String statusBadge { get; set; }

        public GoogleDriveFileAdminWrapper(CVMA_Google_Drive_File__mdt file) {
            this.qualifiedApiName = file.QualifiedApiName;
            this.label = file.MasterLabel;
            this.fileName = file.File_Name__c;
            this.driveId = file.Google_Drive_ID__c;
            this.fileType = file.File_Type__c;
            this.category = file.Category__c;
            this.publicLink = file.Public_Link__c;
            this.sizeMB = file.Size_MB__c;
            this.uploadedDate = file.Uploaded_Date__c != null ?
                String.valueOf(file.Uploaded_Date__c) : '';
            this.description = file.Description__c;
            this.cebOnly = file.CEB_Only__c;
            this.displayOrder = file.Display_Order__c;
            this.isActive = file.Is_Active__c;

            // Computed properties
            this.fileIcon = getFileIcon(file.File_Type__c);
            this.fileSizeDisplay = formatFileSize(file.Size_MB__c);
            this.statusBadge = file.Is_Active__c ? 'Active' : 'Inactive';
        }

        private String getFileIcon(String fileType) {
            if (fileType == null) return 'doctype:attachment';

            switch on fileType.toUpperCase() {
                when 'PDF' { return 'doctype:pdf'; }
                when 'DOC', 'DOCX' { return 'doctype:word'; }
                when 'XLS', 'XLSX' { return 'doctype:excel'; }
                when 'PPT', 'PPTX' { return 'doctype:ppt'; }
                when 'ZIP', 'RAR' { return 'doctype:zip'; }
                when 'TXT' { return 'doctype:txt'; }
                when 'JPG', 'JPEG', 'PNG', 'GIF' { return 'doctype:image'; }
                when else { return 'doctype:attachment'; }
            }
        }

        private String formatFileSize(Decimal sizeMB) {
            if (sizeMB == null) return '';

            if (sizeMB < 0.01) {
                return String.valueOf((sizeMB * 1024).setScale(0)) + ' KB';
            } else if (sizeMB < 1.0) {
                return sizeMB.setScale(2) + ' MB';
            } else {
                return sizeMB.setScale(1) + ' MB';
            }
        }
    }
}
