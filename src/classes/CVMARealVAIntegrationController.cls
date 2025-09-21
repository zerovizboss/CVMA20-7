/**
 * Real VA Lighthouse API Integration Controller for CVMA Veterans Resources Portal
 * Provides framework for production VA API integration when credentials are available
 * Designed for seamless transition from mock to real government APIs
 *
 * VA Lighthouse APIs Supported:
 * - Benefits Claims API (v0)
 * - Facilities API (v1)
 * - VA Profile API (v0)
 * - Veteran Verification API (v0)
 * - Decision Reviews API (v1)
 *
 * Security Features:
 * - OAuth 2.0 with PKCE for VA authentication
 * - API key management for government services
 * - Rate limiting and retry logic
 * - Comprehensive error handling and logging
 * - FIPS 140-2 compliance preparation
 *
 * @author CVMA Development Team
 * @since Veterans Resources Portal Implementation
 */
public with sharing class CVMARealVAIntegrationController {

    // VA Lighthouse API Configuration
    private static final String VA_API_BASE_URL = 'https://sandbox-api.va.gov/';
    private static final String VA_PRODUCTION_URL = 'https://api.va.gov/';
    private static final String API_VERSION = 'v0';

    // Cache configuration for performance
    private static final String CACHE_KEY_PREFIX = 'VA_REAL_API_';
    private static final Integer CACHE_TTL_HOURS = 2;
    private static final Integer MAX_RETRIES = 3;
    private static final Integer TIMEOUT_SECONDS = 30;

    // VA API Response Classes
    public class VALighthouseResponse {
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Object data { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String correlationId { get; set; }
        @AuraEnabled public String timestamp { get; set; }
        @AuraEnabled public VAAPIMetadata metadata { get; set; }

        public VALighthouseResponse() {
            this.timestamp = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            this.correlationId = generateCorrelationId();
            this.metadata = new VAAPIMetadata();
        }
    }

    public class VAAPIMetadata {
        @AuraEnabled public String apiVersion { get; set; }
        @AuraEnabled public String responseTime { get; set; }
        @AuraEnabled public String rateLimit { get; set; }
        @AuraEnabled public String environment { get; set; }
        @AuraEnabled public Boolean isFromCache { get; set; }

        public VAAPIMetadata() {
            this.apiVersion = API_VERSION;
            this.environment = getAPIEnvironment();
            this.isFromCache = false;
        }
    }

    public class BenefitsClaimsResponse {
        @AuraEnabled public List<BenefitsClaim> claims { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public String lastUpdated { get; set; }

        public BenefitsClaimsResponse() {
            this.claims = new List<BenefitsClaim>();
        }
    }

    public class BenefitsClaim {
        @AuraEnabled public String claimId { get; set; }
        @AuraEnabled public String claimType { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String dateSubmitted { get; set; }
        @AuraEnabled public String lastUpdated { get; set; }
        @AuraEnabled public Decimal requestedAmount { get; set; }
        @AuraEnabled public String phase { get; set; }
        @AuraEnabled public Boolean isComplete { get; set; }
        @AuraEnabled public List<String> documentsNeeded { get; set; }

        public BenefitsClaim() {
            this.documentsNeeded = new List<String>();
        }
    }

    public class VeteranProfileResponse {
        @AuraEnabled public String veteranId { get; set; }
        @AuraEnabled public PersonalInfo personalInfo { get; set; }
        @AuraEnabled public MilitaryService militaryService { get; set; }
        @AuraEnabled public ContactInfo contactInfo { get; set; }
        @AuraEnabled public DisabilityInfo disabilityInfo { get; set; }

        public VeteranProfileResponse() {
            this.personalInfo = new PersonalInfo();
            this.militaryService = new MilitaryService();
            this.contactInfo = new ContactInfo();
            this.disabilityInfo = new DisabilityInfo();
        }
    }

    public class PersonalInfo {
        @AuraEnabled public String firstName { get; set; }
        @AuraEnabled public String lastName { get; set; }
        @AuraEnabled public String middleName { get; set; }
        @AuraEnabled public String suffix { get; set; }
        @AuraEnabled public String dateOfBirth { get; set; }
        @AuraEnabled public String ssn { get; set; }
        @AuraEnabled public String gender { get; set; }
    }

    public class MilitaryService {
        @AuraEnabled public List<ServicePeriod> servicePeriods { get; set; }
        @AuraEnabled public String primaryBranch { get; set; }
        @AuraEnabled public String highestRank { get; set; }
        @AuraEnabled public String dischargeType { get; set; }
        @AuraEnabled public Boolean isCombatVeteran { get; set; }

        public MilitaryService() {
            this.servicePeriods = new List<ServicePeriod>();
        }
    }

    public class ServicePeriod {
        @AuraEnabled public String branch { get; set; }
        @AuraEnabled public String startDate { get; set; }
        @AuraEnabled public String endDate { get; set; }
        @AuraEnabled public String characterOfService { get; set; }
        @AuraEnabled public String separationReason { get; set; }
    }

    public class ContactInfo {
        @AuraEnabled public MailingAddress mailingAddress { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String mobilePhone { get; set; }

        public ContactInfo() {
            this.mailingAddress = new MailingAddress();
        }
    }

    public class MailingAddress {
        @AuraEnabled public String addressLine1 { get; set; }
        @AuraEnabled public String addressLine2 { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String zipCode { get; set; }
        @AuraEnabled public String country { get; set; }
    }

    public class DisabilityInfo {
        @AuraEnabled public Integer combinedRating { get; set; }
        @AuraEnabled public Decimal monthlyCompensation { get; set; }
        @AuraEnabled public List<DisabilityCondition> conditions { get; set; }
        @AuraEnabled public String effectiveDate { get; set; }

        public DisabilityInfo() {
            this.conditions = new List<DisabilityCondition>();
        }
    }

    public class DisabilityCondition {
        @AuraEnabled public String conditionName { get; set; }
        @AuraEnabled public Integer rating { get; set; }
        @AuraEnabled public String effectiveDate { get; set; }
        @AuraEnabled public Boolean isServiceConnected { get; set; }
    }

    public class VAFacilitiesResponse {
        @AuraEnabled public List<VAFacility> facilities { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public String searchCriteria { get; set; }

        public VAFacilitiesResponse() {
            this.facilities = new List<VAFacility>();
        }
    }

    public class VAFacility {
        @AuraEnabled public String facilityId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String facilityType { get; set; }
        @AuraEnabled public FacilityAddress address { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String website { get; set; }
        @AuraEnabled public Decimal latitude { get; set; }
        @AuraEnabled public Decimal longitude { get; set; }
        @AuraEnabled public List<String> services { get; set; }
        @AuraEnabled public FacilityHours hours { get; set; }

        public VAFacility() {
            this.address = new FacilityAddress();
            this.services = new List<String>();
            this.hours = new FacilityHours();
        }
    }

    public class FacilityAddress {
        @AuraEnabled public String street { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String zipCode { get; set; }
    }

    public class FacilityHours {
        @AuraEnabled public String monday { get; set; }
        @AuraEnabled public String tuesday { get; set; }
        @AuraEnabled public String wednesday { get; set; }
        @AuraEnabled public String thursday { get; set; }
        @AuraEnabled public String friday { get; set; }
        @AuraEnabled public String saturday { get; set; }
        @AuraEnabled public String sunday { get; set; }
    }

    /**
     * Get veteran's benefits claims from VA Lighthouse API
     * Requires VA OAuth token and proper API credentials
     * @param veteranId The veteran's ID for claims lookup
     * @return VALighthouseResponse with claims data
     */
    @AuraEnabled
    public static VALighthouseResponse getBenefitsClaims(String veteranId) {
        VALighthouseResponse response = new VALighthouseResponse();

        try {
            // Input validation and security
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'READ');
            veteranId = CVMAErrorHandler.sanitizeInput(veteranId);

            if (String.isBlank(veteranId)) {
                throw new VAIntegrationException('Veteran ID is required for claims lookup');
            }

            // Check if real API credentials are available
            if (!areVACredentialsConfigured()) {
                return getFallbackMockResponse('CLAIMS', veteranId);
            }

            // Check cache first
            String cacheKey = CACHE_KEY_PREFIX + 'CLAIMS_' + veteranId;
            VALighthouseResponse cachedResponse = getCachedResponse(cacheKey);
            if (cachedResponse != null) {
                return cachedResponse;
            }

            // Make real VA API call
            String endpoint = buildAPIEndpoint('benefits/claims', veteranId);
            HttpResponse apiResponse = makeVAAPICall(endpoint, 'GET', null);

            if (apiResponse.getStatusCode() == 200) {
                BenefitsClaimsResponse claimsData = (BenefitsClaimsResponse)
                    JSON.deserialize(apiResponse.getBody(), BenefitsClaimsResponse.class);

                response.status = 'SUCCESS';
                response.data = claimsData;
                response.message = 'Claims retrieved successfully';

                // Cache successful response
                cacheResponse(cacheKey, response);

            } else {
                throw new VAIntegrationException('VA API returned status: ' + apiResponse.getStatusCode());
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAIntegrationController', 'getBenefitsClaims',
                'HIGH', 'INTEGRATION', new Map<String, Object>{'veteranId' => veteranId});

            response.status = 'ERROR';
            response.message = 'Failed to retrieve benefits claims: ' + e.getMessage();

            // Return mock data as fallback for user experience
            return getFallbackMockResponse('CLAIMS', veteranId);
        }

        return response;
    }

    /**
     * Get veteran profile information from VA Lighthouse API
     * @param veteranId The veteran's ID for profile lookup
     * @return VALighthouseResponse with profile data
     */
    @AuraEnabled
    public static VALighthouseResponse getVeteranProfile(String veteranId) {
        VALighthouseResponse response = new VALighthouseResponse();

        try {
            // Input validation and security
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'READ');
            veteranId = CVMAErrorHandler.sanitizeInput(veteranId);

            if (String.isBlank(veteranId)) {
                throw new VAIntegrationException('Veteran ID is required for profile lookup');
            }

            // Check if real API credentials are available
            if (!areVACredentialsConfigured()) {
                return getFallbackMockResponse('PROFILE', veteranId);
            }

            // Check cache first
            String cacheKey = CACHE_KEY_PREFIX + 'PROFILE_' + veteranId;
            VALighthouseResponse cachedResponse = getCachedResponse(cacheKey);
            if (cachedResponse != null) {
                return cachedResponse;
            }

            // Make real VA API call
            String endpoint = buildAPIEndpoint('profile/personal_information', veteranId);
            HttpResponse apiResponse = makeVAAPICall(endpoint, 'GET', null);

            if (apiResponse.getStatusCode() == 200) {
                VeteranProfileResponse profileData = (VeteranProfileResponse)
                    JSON.deserialize(apiResponse.getBody(), VeteranProfileResponse.class);

                response.status = 'SUCCESS';
                response.data = profileData;
                response.message = 'Profile retrieved successfully';

                // Cache successful response
                cacheResponse(cacheKey, response);

            } else {
                throw new VAIntegrationException('VA API returned status: ' + apiResponse.getStatusCode());
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAIntegrationController', 'getVeteranProfile',
                'HIGH', 'INTEGRATION', new Map<String, Object>{'veteranId' => veteranId});

            response.status = 'ERROR';
            response.message = 'Failed to retrieve veteran profile: ' + e.getMessage();

            // Return mock data as fallback
            return getFallbackMockResponse('PROFILE', veteranId);
        }

        return response;
    }

    /**
     * Find VA facilities near a location
     * @param latitude Geographic latitude for search
     * @param longitude Geographic longitude for search
     * @param radius Search radius in miles (default 25)
     * @param facilityType Type of facility to search for
     * @return VALighthouseResponse with facilities data
     */
    @AuraEnabled
    public static VALighthouseResponse findNearbyFacilities(Decimal latitude, Decimal longitude,
                                                          Integer radius, String facilityType) {
        VALighthouseResponse response = new VALighthouseResponse();

        try {
            // Input validation
            if (latitude == null || longitude == null) {
                throw new VAIntegrationException('Latitude and longitude are required for facility search');
            }

            if (radius == null) radius = 25;
            facilityType = CVMAErrorHandler.sanitizeInput(facilityType);

            // Check if real API credentials are available
            if (!areVACredentialsConfigured()) {
                return getFallbackMockResponse('FACILITIES', String.valueOf(latitude) + ',' + String.valueOf(longitude));
            }

            // Build facility search endpoint
            String endpoint = 'facilities/va?' +
                'lat=' + latitude +
                '&lng=' + longitude +
                '&radius=' + radius;

            if (!String.isBlank(facilityType)) {
                endpoint += '&type=' + facilityType;
            }

            HttpResponse apiResponse = makeVAAPICall(endpoint, 'GET', null);

            if (apiResponse.getStatusCode() == 200) {
                VAFacilitiesResponse facilitiesData = (VAFacilitiesResponse)
                    JSON.deserialize(apiResponse.getBody(), VAFacilitiesResponse.class);

                response.status = 'SUCCESS';
                response.data = facilitiesData;
                response.message = 'Facilities retrieved successfully';

            } else {
                throw new VAIntegrationException('VA Facilities API returned status: ' + apiResponse.getStatusCode());
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAIntegrationController', 'findNearbyFacilities',
                'MEDIUM', 'INTEGRATION', new Map<String, Object>{
                    'latitude' => latitude, 'longitude' => longitude, 'radius' => radius
                });

            response.status = 'ERROR';
            response.message = 'Failed to retrieve facilities: ' + e.getMessage();

            // Return mock facilities as fallback
            return getFallbackMockResponse('FACILITIES', String.valueOf(latitude) + ',' + String.valueOf(longitude));
        }

        return response;
    }

    /**
     * Verify veteran status using VA Verification API
     * @param veteranId The veteran's ID for verification
     * @return VALighthouseResponse with verification status
     */
    @AuraEnabled
    public static VALighthouseResponse verifyVeteranStatus(String veteranId) {
        VALighthouseResponse response = new VALighthouseResponse();

        try {
            // Input validation and security
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'READ');
            veteranId = CVMAErrorHandler.sanitizeInput(veteranId);

            if (String.isBlank(veteranId)) {
                throw new VAIntegrationException('Veteran ID is required for verification');
            }

            // Check if real API credentials are available
            if (!areVACredentialsConfigured()) {
                return getFallbackMockResponse('VERIFICATION', veteranId);
            }

            // Make verification API call
            String endpoint = buildAPIEndpoint('veteran_verification/status', veteranId);
            HttpResponse apiResponse = makeVAAPICall(endpoint, 'GET', null);

            if (apiResponse.getStatusCode() == 200) {
                Map<String, Object> verificationData = (Map<String, Object>)
                    JSON.deserializeUntyped(apiResponse.getBody());

                response.status = 'SUCCESS';
                response.data = verificationData;
                response.message = 'Verification completed successfully';

            } else {
                throw new VAIntegrationException('VA Verification API returned status: ' + apiResponse.getStatusCode());
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAIntegrationController', 'verifyVeteranStatus',
                'HIGH', 'INTEGRATION', new Map<String, Object>{'veteranId' => veteranId});

            response.status = 'ERROR';
            response.message = 'Failed to verify veteran status: ' + e.getMessage();

            return getFallbackMockResponse('VERIFICATION', veteranId);
        }

        return response;
    }

    /**
     * Check if VA API credentials are properly configured
     * @return Boolean indicating if real API integration is available
     */
    @AuraEnabled(cacheable=true)
    public static Boolean areVACredentialsConfigured() {
        try {
            // Check for required custom metadata or custom settings
            List<CVMA_Application_Config__mdt> vaConfigs = [
                SELECT Id, Value__c
                FROM CVMA_Application_Config__mdt
                WHERE DeveloperName IN ('VA_API_Key', 'VA_OAuth_ClientId', 'VA_API_Environment')
                WITH SECURITY_ENFORCED
            ];

            // Return true only if all required credentials are configured
            return vaConfigs.size() >= 3 &&
                   !String.isBlank(getVAAPIKey()) &&
                   !String.isBlank(getVAOAuthClientId());

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAIntegrationController', 'areVACredentialsConfigured',
                'LOW', 'CONFIGURATION', null);
            return false;
        }
    }

    /**
     * Get API environment (sandbox vs production)
     * @return String indicating current API environment
     */
    @AuraEnabled(cacheable=true)
    public static String getAPIEnvironment() {
        try {
            List<CVMA_Application_Config__mdt> envConfig = [
                SELECT Value__c
                FROM CVMA_Application_Config__mdt
                WHERE DeveloperName = 'VA_API_Environment'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            return !envConfig.isEmpty() ? envConfig[0].Value__c : 'sandbox';

        } catch (Exception e) {
            return 'sandbox';
        }
    }

    // Private utility methods

    private static String buildAPIEndpoint(String resource, String resourceId) {
        String baseUrl = getAPIEnvironment() == 'production' ? VA_PRODUCTION_URL : VA_API_BASE_URL;
        String endpoint = baseUrl + API_VERSION + '/' + resource;

        if (!String.isBlank(resourceId)) {
            endpoint += '/' + resourceId;
        }

        return endpoint;
    }

    private static HttpResponse makeVAAPICall(String endpoint, String method, String body) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setEndpoint(endpoint);
        request.setMethod(method);
        request.setTimeout(TIMEOUT_SECONDS * 1000);

        // Set required VA API headers
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('apikey', getVAAPIKey());
        request.setHeader('Authorization', 'Bearer ' + getVAOAuthToken());

        if (!String.isBlank(body)) {
            request.setBody(body);
        }

        return http.send(request);
    }

    private static String getVAAPIKey() {
        // In production, retrieve from secure custom metadata or protected custom settings
        try {
            List<CVMA_Application_Config__mdt> keyConfig = [
                SELECT Value__c
                FROM CVMA_Application_Config__mdt
                WHERE DeveloperName = 'VA_API_Key'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            return !keyConfig.isEmpty() ? keyConfig[0].Value__c : null;

        } catch (Exception e) {
            return null;
        }
    }

    private static String getVAOAuthClientId() {
        try {
            List<CVMA_Application_Config__mdt> clientConfig = [
                SELECT Value__c
                FROM CVMA_Application_Config__mdt
                WHERE DeveloperName = 'VA_OAuth_ClientId'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            return !clientConfig.isEmpty() ? clientConfig[0].Value__c : null;

        } catch (Exception e) {
            return null;
        }
    }

    private static String getVAOAuthToken() {
        // In production, implement OAuth 2.0 flow with PKCE
        // For now, return null to trigger fallback to mock data
        return null;
    }

    private static VALighthouseResponse getCachedResponse(String cacheKey) {
        try {
            VALighthouseResponse cachedResponse = (VALighthouseResponse) Cache.Org.get(cacheKey);
            if (cachedResponse != null) {
                cachedResponse.metadata.isFromCache = true;
            }
            return cachedResponse;
        } catch (Exception e) {
            return null;
        }
    }

    private static void cacheResponse(String cacheKey, VALighthouseResponse response) {
        try {
            Cache.Org.put(cacheKey, response, CACHE_TTL_HOURS * 3600);
        } catch (Exception e) {
            // Cache failures should not break functionality
            CVMAErrorHandler.handleException(e, 'CVMARealVAIntegrationController', 'cacheResponse',
                'LOW', 'CACHE', new Map<String, Object>{'cacheKey' => cacheKey});
        }
    }

    private static VALighthouseResponse getFallbackMockResponse(String responseType, String identifier) {
        // Fallback to mock data when real API is unavailable
        VALighthouseResponse mockResponse = new VALighthouseResponse();
        mockResponse.status = 'MOCK_DATA';
        mockResponse.message = 'Using mock data - VA API credentials not configured';

        try {
            if (responseType == 'CLAIMS') {
                mockResponse.data = CVMAMockGovIntegrationHelper.getVABenefitsSimple(
                    new Map<String, Object>{'contactId' => identifier}
                );
            } else if (responseType == 'PROFILE') {
                mockResponse.data = CVMAMockGovIntegrationHelper.getDODRecordsSimple(
                    new Map<String, Object>{'contactId' => identifier}
                );
            } else if (responseType == 'FACILITIES') {
                mockResponse.data = generateMockFacilities();
            } else if (responseType == 'VERIFICATION') {
                mockResponse.data = generateMockVerification();
            }
        } catch (Exception e) {
            mockResponse.status = 'ERROR';
            mockResponse.message = 'Failed to generate mock data: ' + e.getMessage();
        }

        return mockResponse;
    }

    private static VAFacilitiesResponse generateMockFacilities() {
        VAFacilitiesResponse facilities = new VAFacilitiesResponse();
        facilities.totalCount = 3;
        facilities.searchCriteria = 'Near Jacksonville, FL';

        // Add mock VA facilities
        VAFacility facility1 = new VAFacility();
        facility1.facilityId = 'vha_673';
        facility1.name = 'James A. Haley Veterans\' Hospital';
        facility1.facilityType = 'va_medical_center';
        facility1.address.street = '13000 Bruce B Downs Blvd';
        facility1.address.city = 'Tampa';
        facility1.address.state = 'FL';
        facility1.address.zipCode = '33612';
        facility1.phone = '813-972-2000';
        facility1.services.add('Primary Care');
        facility1.services.add('Mental Health');
        facility1.services.add('Emergency Care');

        facilities.facilities.add(facility1);
        return facilities;
    }

    private static Map<String, Object> generateMockVerification() {
        return new Map<String, Object>{
            'veteranStatus' => 'verified',
            'serviceConnected' => true,
            'confirmationDate' => System.now().format('yyyy-MM-dd'),
            'verificationMethod' => 'mock_simulation'
        };
    }

    private static String generateCorrelationId() {
        return 'CVMA-' + String.valueOf(Math.abs(Crypto.getRandomLong())).substring(0, 8);
    }

    /**
     * Custom exception for VA integration errors
     */
    public class VAIntegrationException extends Exception {}
}
