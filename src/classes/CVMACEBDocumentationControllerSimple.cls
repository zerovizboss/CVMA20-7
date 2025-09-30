/**
 * @description Simplified CEB Internal Documentation Controller for initial deployment
 * Uses standard Document objects for CEB internal documentation
 *
 * Epic #11 User Story #36: CEB Internal Documentation Management System
 *
 * @author Claude Code
 * @version 1.0 - Simplified for initial deployment
 * @since 2025-09-22
 */
public with sharing class CVMACEBDocumentationControllerSimple {

    /**
     * @description Get available document categories for CEB
     * @return List of categories
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCEBDocumentCategories() {
        try {
            if (!validateCEBAccess()) {
                throw new AuraHandledException('Access denied: CEB role required');
            }

            List<Map<String, Object>> categories = new List<Map<String, Object>>();

            // Hardcoded categories for initial deployment
            categories.add(new Map<String, Object>{'value' => 'Technical', 'label' => 'Technical Documentation'});
            categories.add(new Map<String, Object>{'value' => 'Administrative', 'label' => 'Administrative Procedures'});
            categories.add(new Map<String, Object>{'value' => 'Training', 'label' => 'Training Materials'});
            categories.add(new Map<String, Object>{'value' => 'Financial', 'label' => 'Financial Reports'});

            return categories;

        } catch (Exception e) {
            System.debug('Error retrieving CEB categories: ' + e.getMessage());
            throw new AuraHandledException('Unable to retrieve categories: ' + e.getMessage());
        }
    }

    /**
     * @description Get CEB analytics dashboard data
     * @return Analytics data
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCEBDocumentationAnalytics() {
        try {
            if (!validateCEBAccess()) {
                throw new AuraHandledException('Access denied: CEB role required');
            }

            Map<String, Object> analytics = new Map<String, Object>();

            // Basic analytics using Document object
            Integer totalDocs = [SELECT COUNT() FROM Document WITH SECURITY_ENFORCED];

            analytics.put('totalDocuments', totalDocs);
            analytics.put('lastUpdated', System.now());
            analytics.put('status', 'Active');

            return analytics;

        } catch (Exception e) {
            System.debug('Error retrieving CEB analytics: ' + e.getMessage());
            throw new AuraHandledException('Unable to retrieve analytics: ' + e.getMessage());
        }
    }

    /**
     * @description Validate user has CEB access
     * @return Boolean indicating CEB access
     */
    private static Boolean validateCEBAccess() {
        try {
            User currentUser = [
                SELECT Id, Profile.Name, UserRole.Name
                FROM User
                WHERE Id = :UserInfo.getUserId()
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            // Check for System Administrator or CEB profiles
            if (currentUser.Profile?.Name != null &&
                (currentUser.Profile.Name.contains('System Administrator') ||
                 currentUser.Profile.Name.contains('CEB'))) {
                return true;
            }

            return false;

        } catch (Exception e) {
            System.debug('CEB access validation failed: ' + e.getMessage());
            return false;
        }
    }
}
