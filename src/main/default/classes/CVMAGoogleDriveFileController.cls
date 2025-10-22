/**
 * @description Controller for CVMA Google Drive File Viewer LWC
 * Epic #12, User Story #88 - File Viewer Component
 *
 * Provides secure access to CVMA_Google_Drive_File__mdt records with:
 * - Category filtering
 * - Search functionality
 * - CEB permission enforcement
 * - Guest user access restrictions
 *
 * @author Claude Code
 * @date October 2025
 */
public with sharing class CVMAGoogleDriveFileController {

    /**
     * @description Retrieves Google Drive files with optional filtering
     * @param category Filter by category (Bylaws, Forms, Policy, etc.) - null returns all
     * @param searchTerm Search in file name and description - null returns all
     * @return List of file metadata wrapped in display-friendly format
     */
    @AuraEnabled(cacheable=true)
    public static List<GoogleDriveFileWrapper> getFiles(String category, String searchTerm) {
        try {
            // Security: Block guest user access
            if (isGuestUser()) {
                throw new AuraHandledException('Guest users do not have access to this resource.');
            }

            // Get current user's CEB status
            Boolean isCEBOfficer = checkCEBAccess();

            // Build dynamic SOQL query
            String query = 'SELECT QualifiedApiName, MasterLabel, File_Name__c, Google_Drive_ID__c, ' +
                          'File_Type__c, Category__c, Public_Link__c, Size_MB__c, ' +
                          'Uploaded_Date__c, Description__c, CEB_Only__c, Display_Order__c, Is_Active__c ' +
                          'FROM CVMA_Google_Drive_File__mdt ' +
                          'WHERE Is_Active__c = true';

            // Apply category filter
            if (String.isNotBlank(category) && category != 'All') {
                query += ' AND Category__c = :category';
            }

            // Apply CEB permission filter
            if (!isCEBOfficer) {
                query += ' AND CEB_Only__c = false';
            }

            query += ' ORDER BY Display_Order__c ASC';

            // Execute query with security enforced
            List<CVMA_Google_Drive_File__mdt> files = Database.query(String.escapeSingleQuotes(query));

            // Wrap results and apply search filter (client-side search would be better for UX)
            List<GoogleDriveFileWrapper> results = new List<GoogleDriveFileWrapper>();

            for (CVMA_Google_Drive_File__mdt file : files) {
                // Apply search term filter if provided
                if (String.isNotBlank(searchTerm)) {
                    String lowerSearch = searchTerm.toLowerCase();
                    String fileName = file.File_Name__c != null ? file.File_Name__c.toLowerCase() : '';
                    String description = file.Description__c != null ? file.Description__c.toLowerCase() : '';

                    if (!fileName.contains(lowerSearch) && !description.contains(lowerSearch)) {
                        continue; // Skip this file
                    }
                }

                results.add(new GoogleDriveFileWrapper(file));
            }

            return results;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving files: ' + e.getMessage());
        }
    }

    /**
     * @description Gets list of unique categories for filter dropdown
     * @return List of category values
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getCategories() {
        try {
            // Security: Block guest user access
            if (isGuestUser()) {
                throw new AuraHandledException('Guest users do not have access to this resource.');
            }

            Set<String> categorySet = new Set<String>();

            // Query all active files to get unique categories
            for (CVMA_Google_Drive_File__mdt file : [
                SELECT Category__c
                FROM CVMA_Google_Drive_File__mdt
                WHERE Is_Active__c = true
            ]) {
                if (String.isNotBlank(file.Category__c)) {
                    categorySet.add(file.Category__c);
                }
            }

            // Convert to sorted list
            List<String> categories = new List<String>(categorySet);
            categories.sort();

            return categories;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving categories: ' + e.getMessage());
        }
    }

    /**
     * @description Checks if current user is a CEB officer
     * Uses permission set membership or profile checks
     * @return true if user has CEB access
     */
    @AuraEnabled(cacheable=true)
    public static Boolean checkCEBAccess() {
        try {
            // Security: Block guest user access
            if (isGuestUser()) {
                return false;
            }

            Id userId = UserInfo.getUserId();

            // Option 1: Check for CEB Permission Set
            List<PermissionSetAssignment> cebPermSets = [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
                AND PermissionSet.Name LIKE '%CEB%'
                LIMIT 1
            ];

            if (!cebPermSets.isEmpty()) {
                return true;
            }

            // Option 2: Check if user profile is System Administrator (always has access)
            String profileName = [SELECT Profile.Name FROM User WHERE Id = :userId LIMIT 1].Profile.Name;
            if (profileName == 'System Administrator') {
                return true;
            }

            // Default: no CEB access
            return false;

        } catch (Exception e) {
            // If there's an error checking CEB access, default to non-CEB
            System.debug('Error checking CEB access: ' + e.getMessage());
            return false;
        }
    }

    /**
     * @description Checks if current user is a guest user
     * @return true if guest user
     */
    private static Boolean isGuestUser() {
        return UserInfo.getUserType() == 'Guest';
    }

    /**
     * @description Wrapper class for Google Drive file metadata
     * Provides client-friendly format with computed properties
     */
    public class GoogleDriveFileWrapper {
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
        @AuraEnabled public String fileIcon { get; set; }
        @AuraEnabled public String fileSizeDisplay { get; set; }

        public GoogleDriveFileWrapper(CVMA_Google_Drive_File__mdt file) {
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

            // Set file icon based on type
            this.fileIcon = getFileIcon(file.File_Type__c);

            // Format file size for display
            this.fileSizeDisplay = formatFileSize(file.Size_MB__c);
        }

        /**
         * @description Returns SLDS icon name based on file type
         */
        private String getFileIcon(String fileType) {
            if (fileType == null) return 'doctype:attachment';

            switch on fileType.toUpperCase() {
                when 'PDF' {
                    return 'doctype:pdf';
                }
                when 'DOC', 'DOCX' {
                    return 'doctype:word';
                }
                when 'XLS', 'XLSX' {
                    return 'doctype:excel';
                }
                when 'PPT', 'PPTX' {
                    return 'doctype:ppt';
                }
                when 'ZIP', 'RAR' {
                    return 'doctype:zip';
                }
                when 'TXT' {
                    return 'doctype:txt';
                }
                when 'JPG', 'JPEG', 'PNG', 'GIF' {
                    return 'doctype:image';
                }
                when else {
                    return 'doctype:attachment';
                }
            }
        }

        /**
         * @description Formats file size for display
         */
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
