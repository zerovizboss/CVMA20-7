/**
 * @description Controller for CEB Internal Documentation Management System
 * Handles secure access to internal documentation for Combat Executive Board
 * Integrates with Knowledge Articles and provides role-based access control
 *
 * Epic #11 User Story #36: CEB Internal Documentation Management System
 *
 * @author Claude Code
 * @version 1.0
 * @since 2025-09-22
 */
public with sharing class CVMACEBDocumentationController {

    /**
     * @description Get CEB internal documents by category
     * Restricted to CEB roles only
     * @param category Document category to filter by
     * @return List of internal Knowledge Articles for CEB
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCEBDocuments(String category) {
        try {
            // Validate CEB access first
            if (!validateCEBAccess()) {
                throw new System.SecurityException('Access denied: CEB role required');
            }

            List<Map<String, Object>> cebDocuments = new List<Map<String, Object>>();

            // For initial deployment, use Document objects instead of Knowledge Articles
            List<Document> documents = [
                SELECT Id, Name, Description, LastModifiedDate, LastModifiedBy.Name, Type
                FROM Document
                WHERE FolderId IN (SELECT Id FROM Folder WHERE Name = 'CEB Internal Documents' WITH SECURITY_ENFORCED)
                WITH SECURITY_ENFORCED
                ORDER BY LastModifiedDate DESC
                LIMIT 100
            ];

            // Apply category filter if needed (using Type field for now)
            List<Document> filteredDocuments = documents;
            if (String.isNotBlank(category)) {
                filteredDocuments = new List<Document>();
                for (Document doc : documents) {
                    if (doc.Type != null && doc.Type.contains(category)) {
                        filteredDocuments.add(doc);
                    }
                }
            }

            for (Document doc : filteredDocuments) {
                Map<String, Object> docInfo = new Map<String, Object>();
                docInfo.put('id', doc.Id);
                docInfo.put('title', doc.Name);
                docInfo.put('summary', doc.Description);
                docInfo.put('lastModified', doc.LastModifiedDate);
                docInfo.put('lastModifiedBy', doc.LastModifiedBy?.Name);
                cebDocuments.add(docInfo);
            }

            return cebDocuments;

        } catch (Exception e) {
            System.debug('Error retrieving CEB documents: ' + e.getMessage());
            throw new AuraHandledException('Unable to retrieve CEB documents: ' + e.getMessage());
        }
    }

    /**
     * @description Get CEB document categories for filtering
     * @return List of available document categories
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCEBDocumentCategories() {
        try {
            // Validate CEB access
            if (!validateCEBAccess()) {
                throw new System.SecurityException('Access denied: CEB role required');
            }

            List<Map<String, Object>> categories = new List<Map<String, Object>>();

            // Get distinct categories from Knowledge Articles
            List<AggregateResult> categoryResults = [
                SELECT Category__c
                FROM Knowledge__kav
                WHERE PublishStatus = 'Online'
                AND IsInternal__c = true
                AND Category__c != null
                GROUP BY Category__c
                ORDER BY Category__c ASC
                WITH SECURITY_ENFORCED
            ];

            for (AggregateResult result : categoryResults) {
                Map<String, Object> categoryInfo = new Map<String, Object>();
                categoryInfo.put('value', result.get('Category__c'));
                categoryInfo.put('label', result.get('Category__c'));
                categories.add(categoryInfo);
            }

            return categories;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACEBDocumentationController.getCEBDocumentCategories');
            throw new AuraHandledException('Unable to retrieve categories: ' + e.getMessage());
        }
    }

    /**
     * @description Create new CEB internal document
     * @param title Document title
     * @param summary Document summary
     * @param content Document content
     * @param category Document category
     * @return Success message with article ID
     */
    @AuraEnabled
    public static String createCEBDocument(String title, String summary, String content, String category) {
        try {
            // Validate CEB access and creation permissions
            if (!validateCEBAccess()) {
                throw new System.SecurityException('Access denied: CEB role required');
            }

            // Input validation and sanitization
            if (String.isBlank(title) || String.isBlank(content)) {
                throw new IllegalArgumentException('Title and content are required');
            }

            String sanitizedTitle = CVMAErrorHandler.sanitizeInput(title);
            String sanitizedSummary = CVMAErrorHandler.sanitizeInput(summary);
            String sanitizedContent = CVMAErrorHandler.sanitizeInput(content);
            String sanitizedCategory = CVMAErrorHandler.sanitizeInput(category);

            // Create Knowledge Article
            Knowledge__kav newArticle = new Knowledge__kav();
            newArticle.Title = sanitizedTitle;
            newArticle.Summary = sanitizedSummary;
            newArticle.Content__c = sanitizedContent;
            newArticle.Category__c = sanitizedCategory;
            newArticle.IsInternal__c = true;
            newArticle.Language = 'en_US';

            insert newArticle;

            return 'CEB document created successfully with ID: ' + newArticle.Id;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACEBDocumentationController.createCEBDocument');
            throw new AuraHandledException('Failed to create CEB document: ' + e.getMessage());
        }
    }

    /**
     * @description Get CEB documentation usage analytics
     * @return Analytics data for CEB dashboard
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCEBDocumentationAnalytics() {
        try {
            // Validate CEB access
            if (!validateCEBAccess()) {
                throw new System.SecurityException('Access denied: CEB role required');
            }

            Map<String, Object> analytics = new Map<String, Object>();

            // Total internal documents
            Integer totalDocs = [
                SELECT COUNT()
                FROM Knowledge__kav
                WHERE PublishStatus = 'Online'
                AND IsInternal__c = true
                WITH SECURITY_ENFORCED
            ];

            // Documents by category
            List<AggregateResult> categoryStats = [
                SELECT Category__c, COUNT(Id) docCount
                FROM Knowledge__kav
                WHERE PublishStatus = 'Online'
                AND IsInternal__c = true
                GROUP BY Category__c
                ORDER BY COUNT(Id) DESC
                WITH SECURITY_ENFORCED
                LIMIT 10
            ];

            // Recent document activity
            List<Knowledge__kav> recentDocs = [
                SELECT Title, LastModifiedDate, LastModifiedBy.Name
                FROM Knowledge__kav
                WHERE PublishStatus = 'Online'
                AND IsInternal__c = true
                ORDER BY LastModifiedDate DESC
                WITH SECURITY_ENFORCED
                LIMIT 5
            ];

            analytics.put('totalDocuments', totalDocs);
            analytics.put('categoryStatistics', categoryStats);
            analytics.put('recentActivity', recentDocs);

            return analytics;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACEBDocumentationController.getCEBDocumentationAnalytics');
            throw new AuraHandledException('Unable to retrieve analytics: ' + e.getMessage());
        }
    }

    /**
     * @description Validate user has CEB (Combat Executive Board) access
     * Checks user roles and profiles for CEB permissions
     * @return Boolean indicating CEB access
     */
    private static Boolean validateCEBAccess() {
        try {
            // Get current user information
            User currentUser = [
                SELECT Id, Profile.Name, UserRole.Name, UserRole.DeveloperName
                FROM User
                WHERE Id = :UserInfo.getUserId()
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            // Check for CEB roles (CO, XO, Secretary, Treasurer, Road Captain)
            Set<String> cebRoles = new Set<String>{
                'CO', 'XO', 'COMMANDING_OFFICER', 'EXECUTIVE_OFFICER',
                'SECRETARY', 'TREASURER', 'ROAD_CAPTAIN', 'CHAPLAIN',
                'SERGEANT_AT_ARMS', 'WEBMASTER'
            };

            // Check UserRole
            if (currentUser.UserRole?.DeveloperName != null &&
                cebRoles.contains(currentUser.UserRole.DeveloperName.toUpperCase())) {
                return true;
            }

            // Check Profile for System Administrator or CEB specific profiles
            if (currentUser.Profile?.Name != null &&
                (currentUser.Profile.Name.contains('System Administrator') ||
                 currentUser.Profile.Name.contains('CEB') ||
                 currentUser.Profile.Name.contains('Combat Executive Board'))) {
                return true;
            }

            return false;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMACEBDocumentationController.validateCEBAccess');
            return false;
        }
    }
}
