/**
 * CVMARealVAFormsController
 * Production-ready VA Forms API integration for CVMA Chapter 20-7
 *
 * Integrates with VA Forms API (https://api.va.gov/services/va_forms/docs/v0)
 * to provide comprehensive form search, filtering, and submission assistance
 * for CVMA members.
 *
 * Features:
 * - VA Form search and filtering capabilities
 * - Direct links to VA.gov form submission
 * - Form completion assistance for CVMA members
 * - Performance optimization with caching
 * - Comprehensive error handling and logging
 * - Member-specific form recommendations
 *
 * @author CVMA Development Team
 * @since Epic #8 VA Lighthouse API Integration
 * @version 1.0.0
 */
public with sharing class CVMARealVAFormsController {

    // API Configuration
    private static final String API_NAME = 'VA_Forms_API';
    private static final String CACHE_KEY_PREFIX = 'VA_FORMS_';
    private static final Integer DEFAULT_CACHE_TTL_MINUTES = 60;

    // Form categories for better organization
    private static final Map<String, String> FORM_CATEGORIES = new Map<String, String>{
        'DISABILITY' => 'Disability Compensation',
        'HEALTHCARE' => 'Healthcare Benefits',
        'EDUCATION' => 'Education Benefits',
        'HOME_LOAN' => 'Home Loan Benefits',
        'BURIAL' => 'Burial and Memorial',
        'VOCATIONAL' => 'Vocational Rehabilitation',
        'PENSION' => 'Pension Benefits',
        'INSURANCE' => 'Life Insurance'
    };

    /**
     * VA Form Data Structure
     */
    public class VAForm {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String formNumber { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public String submissionUrl { get; set; }
        @AuraEnabled public String pdfUrl { get; set; }
        @AuraEnabled public Boolean isAvailableOnline { get; set; }
        @AuraEnabled public String lastRevisionDate { get; set; }
        @AuraEnabled public List<String> relatedForms { get; set; }
        @AuraEnabled public String instructions { get; set; }
        @AuraEnabled public Integer estimatedCompletionTime { get; set; }
        @AuraEnabled public List<String> requiredDocuments { get; set; }
        @AuraEnabled public String benefitType { get; set; }

        public VAForm() {
            this.relatedForms = new List<String>();
            this.requiredDocuments = new List<String>();
            this.isAvailableOnline = false;
        }
    }

    /**
     * Form Search Response Structure
     */
    public class VAFormSearchResponse {
        @AuraEnabled public List<VAForm> forms { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public Integer currentPage { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer totalPages { get; set; }
        @AuraEnabled public String searchQuery { get; set; }
        @AuraEnabled public List<String> appliedFilters { get; set; }
        @AuraEnabled public Boolean isSuccess { get; set; }
        @AuraEnabled public String errorMessage { get; set; }

        public VAFormSearchResponse() {
            this.forms = new List<VAForm>();
            this.appliedFilters = new List<String>();
            this.isSuccess = false;
            this.currentPage = 1;
            this.pageSize = 20;
        }
    }

    /**
     * Member Form Recommendations
     */
    public class MemberFormRecommendations {
        @AuraEnabled public List<VAForm> recommendedForms { get; set; }
        @AuraEnabled public List<VAForm> completedForms { get; set; }
        @AuraEnabled public List<VAForm> inProgressForms { get; set; }
        @AuraEnabled public List<String> recommendationReasons { get; set; }
        @AuraEnabled public String memberProfile { get; set; }
        @AuraEnabled public DateTime lastUpdated { get; set; }

        public MemberFormRecommendations() {
            this.recommendedForms = new List<VAForm>();
            this.completedForms = new List<VAForm>();
            this.inProgressForms = new List<VAForm>();
            this.recommendationReasons = new List<String>();
            this.lastUpdated = DateTime.now();
        }
    }

    /**
     * Search VA forms with comprehensive filtering options
     *
     * @param searchQuery Text search query
     * @param category Form category filter
     * @param benefitType Benefit type filter
     * @param onlineOnly Filter for online-available forms only
     * @param pageNumber Page number for pagination
     * @param pageSize Number of results per page
     * @return VAFormSearchResponse Search results with metadata
     */
    @AuraEnabled(cacheable=true)
    public static VAFormSearchResponse searchVAForms(String searchQuery, String category,
                                                     String benefitType, Boolean onlineOnly,
                                                     Integer pageNumber, Integer pageSize) {
        try {
            // Input validation and sanitization
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'READ');
            searchQuery = CVMAErrorHandler.sanitizeInput(searchQuery);
            category = CVMAErrorHandler.sanitizeInput(category);
            benefitType = CVMAErrorHandler.sanitizeInput(benefitType);

            if (pageNumber == null || pageNumber < 1) pageNumber = 1;
            if (pageSize == null || pageSize < 1 || pageSize > 100) pageSize = 20;

            // Check cache first
            String cacheKey = buildSearchCacheKey(searchQuery, category, benefitType, onlineOnly, pageNumber, pageSize);
            VAFormSearchResponse cachedResponse = (VAFormSearchResponse) Cache.Org.get(cacheKey);
            if (cachedResponse != null) {
                return cachedResponse;
            }

            // Build query parameters
            Map<String, String> queryParams = new Map<String, String>();
            if (String.isNotBlank(searchQuery)) {
                queryParams.put('query', searchQuery);
            }
            if (String.isNotBlank(category)) {
                queryParams.put('category', category);
            }
            if (String.isNotBlank(benefitType)) {
                queryParams.put('benefit_type', benefitType);
            }
            if (onlineOnly == true) {
                queryParams.put('online_only', 'true');
            }
            queryParams.put('page', String.valueOf(pageNumber));
            queryParams.put('per_page', String.valueOf(pageSize));

            // Make API request
            CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse = CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                API_NAME, 'forms', 'GET', null, queryParams
            );

            VAFormSearchResponse searchResponse = new VAFormSearchResponse();
            searchResponse.searchQuery = searchQuery;
            searchResponse.currentPage = pageNumber;
            searchResponse.pageSize = pageSize;

            if (apiResponse.isSuccess) {
                searchResponse = parseFormSearchResponse(apiResponse.body, searchResponse);
                searchResponse.isSuccess = true;

                // Apply additional filters if needed
                if (String.isNotBlank(category)) {
                    searchResponse.appliedFilters.add('Category: ' + category);
                }
                if (String.isNotBlank(benefitType)) {
                    searchResponse.appliedFilters.add('Benefit Type: ' + benefitType);
                }
                if (onlineOnly == true) {
                    searchResponse.appliedFilters.add('Online Forms Only');
                }

                // Cache successful response
                Cache.Org.put(cacheKey, searchResponse, DEFAULT_CACHE_TTL_MINUTES * 60);
            } else {
                searchResponse.isSuccess = false;
                searchResponse.errorMessage = apiResponse.errorMessage;
            }

            return searchResponse;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAFormsController', 'searchVAForms',
                'HIGH', 'INTEGRATION', new Map<String, Object>{
                    'searchQuery' => searchQuery,
                    'category' => category,
                    'benefitType' => benefitType
                });

            VAFormSearchResponse errorResponse = new VAFormSearchResponse();
            errorResponse.isSuccess = false;
            errorResponse.errorMessage = 'Failed to search VA forms: ' + e.getMessage();
            return errorResponse;
        }
    }

    /**
     * Get specific VA form by form number
     *
     * @param formNumber VA form number (e.g., "21-526EZ")
     * @return VAForm Complete form details
     */
    @AuraEnabled(cacheable=true)
    public static VAForm getVAFormByNumber(String formNumber) {
        try {
            // Input validation
            formNumber = CVMAErrorHandler.sanitizeInput(formNumber);
            if (String.isBlank(formNumber)) {
                throw new CVMAVAFormsException('Form number is required');
            }

            // Check cache first
            String cacheKey = CACHE_KEY_PREFIX + 'FORM_' + formNumber;
            VAForm cachedForm = (VAForm) Cache.Org.get(cacheKey);
            if (cachedForm != null) {
                return cachedForm;
            }

            // Make API request
            CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse = CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                API_NAME, 'forms/' + EncodingUtil.urlEncode(formNumber, 'UTF-8'), 'GET', null, null
            );

            if (apiResponse.isSuccess) {
                VAForm form = parseFormDetails(apiResponse.body);

                // Cache successful response
                Cache.Org.put(cacheKey, form, DEFAULT_CACHE_TTL_MINUTES * 60);

                return form;
            } else {
                throw new CVMAVAFormsException('Failed to retrieve form details: ' + apiResponse.errorMessage);
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAFormsController', 'getVAFormByNumber',
                'MEDIUM', 'INTEGRATION', new Map<String, Object>{'formNumber' => formNumber});
            throw new AuraHandledException('Failed to retrieve VA form: ' + e.getMessage());
        }
    }

    /**
     * Get personalized form recommendations for a CVMA member
     *
     * @param memberId Contact ID of the CVMA member
     * @return MemberFormRecommendations Personalized recommendations
     */
    @AuraEnabled
    public static MemberFormRecommendations getMemberFormRecommendations(Id memberId) {
        try {
            // Input validation
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'READ');
            if (memberId == null) {
                throw new CVMAVAFormsException('Member ID is required');
            }

            // Get member profile information
            Contact member = [
                SELECT Id, FirstName, LastName, Level__c, Military_Service_Branch__c,
                       Service_Start_Date__c, Service_End_Date__c, MailingState
                FROM Contact
                WHERE Id = :memberId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            MemberFormRecommendations recommendations = new MemberFormRecommendations();
            recommendations.memberProfile = member.FirstName + ' ' + member.LastName + ' (' + member.Level__c + ')';

            // Generate recommendations based on member profile
            recommendations.recommendedForms = generateFormRecommendations(member);
            recommendations.recommendationReasons = generateRecommendationReasons(member);

            // Get forms the member may have already completed or started
            // This would integrate with form tracking in a full implementation
            recommendations.completedForms = getCompletedForms(member);
            recommendations.inProgressForms = getInProgressForms(member);

            return recommendations;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAFormsController', 'getMemberFormRecommendations',
                'MEDIUM', 'INTEGRATION', new Map<String, Object>{'memberId' => String.valueOf(memberId)});
            throw new AuraHandledException('Failed to generate form recommendations: ' + e.getMessage());
        }
    }

    /**
     * Get all available form categories
     *
     * @return Map<String, String> Available categories with descriptions
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getFormCategories() {
        return FORM_CATEGORIES;
    }

    /**
     * Get popular forms for quick access
     *
     * @return List<VAForm> Most commonly used forms
     */
    @AuraEnabled(cacheable=true)
    public static List<VAForm> getPopularForms() {
        try {
            // Cache key for popular forms
            String cacheKey = CACHE_KEY_PREFIX + 'POPULAR_FORMS';
            List<VAForm> cachedForms = (List<VAForm>) Cache.Org.get(cacheKey);
            if (cachedForms != null) {
                return cachedForms;
            }

            // List of popular form numbers
            List<String> popularFormNumbers = new List<String>{
                '21-526EZ', // Disability Compensation
                '22-1990',  // Education Benefits
                '26-1880',  // Home Loan Certificate
                '10-10EZ',  // Healthcare Application
                '21P-527EZ' // Pension Application
            };

            List<VAForm> popularForms = new List<VAForm>();
            for (String formNumber : popularFormNumbers) {
                try {
                    VAForm form = getVAFormByNumber(formNumber);
                    if (form != null) {
                        popularForms.add(form);
                    }
                } catch (Exception e) {
                    // Continue with other forms if one fails
                    System.debug('Failed to retrieve popular form ' + formNumber + ': ' + e.getMessage());
                }
            }

            // Cache for longer period since popular forms don't change often
            Cache.Org.put(cacheKey, popularForms, 240 * 60); // 4 hours

            return popularForms;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAFormsController', 'getPopularForms',
                'LOW', 'INTEGRATION', new Map<String, Object>());
            return new List<VAForm>();
        }
    }

    // Private helper methods

    /**
     * Build cache key for search queries
     */
    private static String buildSearchCacheKey(String searchQuery, String category, String benefitType,
                                            Boolean onlineOnly, Integer pageNumber, Integer pageSize) {
        List<String> keyParts = new List<String>{
            CACHE_KEY_PREFIX + 'SEARCH',
            String.isNotBlank(searchQuery) ? searchQuery.replaceAll('[^a-zA-Z0-9]', '') : 'ALL',
            String.isNotBlank(category) ? category : 'ANY',
            String.isNotBlank(benefitType) ? benefitType : 'ANY',
            onlineOnly == true ? 'ONLINE' : 'ALL',
            String.valueOf(pageNumber),
            String.valueOf(pageSize)
        };

        return String.join(keyParts, '_').left(250); // Salesforce cache key limit
    }

    /**
     * Parse VA Forms API search response
     */
    private static VAFormSearchResponse parseFormSearchResponse(String responseBody, VAFormSearchResponse searchResponse) {
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            // Handle API response structure
            List<Object> formsData = (List<Object>) responseMap.get('data');
            Map<String, Object> metaData = (Map<String, Object>) responseMap.get('meta');

            if (formsData != null) {
                for (Object formObj : formsData) {
                    Map<String, Object> formMap = (Map<String, Object>) formObj;
                    VAForm form = parseFormFromAPI(formMap);
                    if (form != null) {
                        searchResponse.forms.add(form);
                    }
                }
            }

            // Parse metadata if available
            if (metaData != null) {
                Object totalCount = metaData.get('total_count');
                if (totalCount != null) {
                    searchResponse.totalCount = (Integer) totalCount;
                    searchResponse.totalPages = (Integer) Math.ceil((Decimal) searchResponse.totalCount / searchResponse.pageSize);
                }
            } else {
                searchResponse.totalCount = searchResponse.forms.size();
                searchResponse.totalPages = 1;
            }

        } catch (Exception e) {
            throw new CVMAVAFormsException('Failed to parse API response: ' + e.getMessage());
        }

        return searchResponse;
    }

    /**
     * Parse individual form details from API response
     */
    private static VAForm parseFormDetails(String responseBody) {
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            Map<String, Object> formData = (Map<String, Object>) responseMap.get('data');

            return parseFormFromAPI(formData);

        } catch (Exception e) {
            throw new CVMAVAFormsException('Failed to parse form details: ' + e.getMessage());
        }
    }

    /**
     * Parse form data from API response map
     */
    private static VAForm parseFormFromAPI(Map<String, Object> formMap) {
        if (formMap == null) return null;

        VAForm form = new VAForm();

        // Extract attributes map
        Map<String, Object> attributes = (Map<String, Object>) formMap.get('attributes');
        if (attributes == null) return null;

        form.id = (String) formMap.get('id');
        form.formNumber = (String) attributes.get('form_name');
        form.title = (String) attributes.get('title');
        form.description = (String) attributes.get('description');
        form.submissionUrl = (String) attributes.get('form_tool_url');
        form.pdfUrl = (String) attributes.get('url');
        form.lastRevisionDate = (String) attributes.get('last_revision_on');

        // Determine category based on form number pattern
        form.category = categorizeForm(form.formNumber);

        // Check if form is available online
        form.isAvailableOnline = String.isNotBlank(form.submissionUrl);

        // Set estimated completion time based on form type
        form.estimatedCompletionTime = estimateCompletionTime(form.formNumber);

        // Add common required documents
        form.requiredDocuments = getRequiredDocuments(form.formNumber);

        return form;
    }

    /**
     * Categorize form based on form number patterns
     */
    private static String categorizeForm(String formNumber) {
        if (String.isBlank(formNumber)) return 'OTHER';

        formNumber = formNumber.toUpperCase();

        if (formNumber.startsWith('21-526') || formNumber.startsWith('21-4138')) {
            return 'DISABILITY';
        } else if (formNumber.startsWith('22-')) {
            return 'EDUCATION';
        } else if (formNumber.startsWith('26-')) {
            return 'HOME_LOAN';
        } else if (formNumber.startsWith('10-10')) {
            return 'HEALTHCARE';
        } else if (formNumber.startsWith('21P-')) {
            return 'PENSION';
        } else if (formNumber.startsWith('40-')) {
            return 'BURIAL';
        } else if (formNumber.startsWith('28-')) {
            return 'VOCATIONAL';
        } else if (formNumber.startsWith('29-')) {
            return 'INSURANCE';
        }

        return 'OTHER';
    }

    /**
     * Estimate completion time based on form complexity
     */
    private static Integer estimateCompletionTime(String formNumber) {
        if (String.isBlank(formNumber)) return 30;

        // Complex forms
        if (formNumber.contains('21-526') || formNumber.contains('22-1990')) {
            return 60; // 60 minutes
        }

        // Medium complexity forms
        if (formNumber.contains('10-10EZ') || formNumber.contains('26-1880')) {
            return 30; // 30 minutes
        }

        // Simple forms
        return 15; // 15 minutes
    }

    /**
     * Get required documents based on form type
     */
    private static List<String> getRequiredDocuments(String formNumber) {
        List<String> documents = new List<String>();

        if (String.isBlank(formNumber)) return documents;

        // Common documents for all forms
        documents.add('Valid photo ID');
        documents.add('DD-214 (Certificate of Release or Discharge from Active Duty)');

        // Form-specific documents
        if (formNumber.contains('21-526')) {
            documents.add('Medical records supporting claimed conditions');
            documents.add('Buddy statements (if applicable)');
        } else if (formNumber.contains('22-1990')) {
            documents.add('High school diploma or equivalency certificate');
            documents.add('College transcripts (if applicable)');
        } else if (formNumber.contains('10-10EZ')) {
            documents.add('Income verification documents');
            documents.add('Insurance information');
        }

        return documents;
    }

    /**
     * Generate form recommendations based on member profile
     */
    private static List<VAForm> generateFormRecommendations(Contact member) {
        List<VAForm> recommendations = new List<VAForm>();

        try {
            // Basic recommendations for all veterans
            List<String> recommendedFormNumbers = new List<String>{'21-526EZ', '10-10EZ'};

            // Add education benefits if member is younger or recently separated
            Date serviceEndDate = member.Service_End_Date__c;
            if (serviceEndDate != null && serviceEndDate > Date.today().addYears(-15)) {
                recommendedFormNumbers.add('22-1990');
            }

            // Add home loan benefits for eligible members
            recommendedFormNumbers.add('26-1880');

            // Get form details for recommendations
            for (String formNumber : recommendedFormNumbers) {
                try {
                    VAForm form = getVAFormByNumber(formNumber);
                    if (form != null) {
                        recommendations.add(form);
                    }
                } catch (Exception e) {
                    // Continue with other recommendations if one fails
                    System.debug('Failed to get recommended form ' + formNumber + ': ' + e.getMessage());
                }
            }

        } catch (Exception e) {
            System.debug('Error generating form recommendations: ' + e.getMessage());
        }

        return recommendations;
    }

    /**
     * Generate recommendation reasons for member
     */
    private static List<String> generateRecommendationReasons(Contact member) {
        List<String> reasons = new List<String>();

        reasons.add('Disability compensation may be available for service-connected conditions');
        reasons.add('Healthcare enrollment provides access to VA medical services');

        if (member.Service_End_Date__c != null && member.Service_End_Date__c > Date.today().addYears(-15)) {
            reasons.add('Education benefits are available for recent veterans');
        }

        if (member.Level__c == 'Full Member') {
            reasons.add('Full CVMA members are encouraged to maximize their VA benefits');
        }

        return reasons;
    }

    /**
     * Get completed forms for member (placeholder implementation)
     */
    private static List<VAForm> getCompletedForms(Contact member) {
        // In a full implementation, this would query form submission tracking
        return new List<VAForm>();
    }

    /**
     * Get in-progress forms for member (placeholder implementation)
     */
    private static List<VAForm> getInProgressForms(Contact member) {
        // In a full implementation, this would query form progress tracking
        return new List<VAForm>();
    }

    /**
     * Custom exception for VA Forms API errors
     */
    public class CVMAVAFormsException extends Exception {}
}
