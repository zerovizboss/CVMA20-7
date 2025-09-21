/**
 * CVMARealVAFacilitiesController
 * Production-ready VA Facilities API integration for CVMA Chapter 20-7
 *
 * Integrates with VA Facilities API (https://api.va.gov/services/va_facilities/docs/v1)
 * to provide comprehensive facility location, services, and scheduling assistance
 * for CVMA members.
 *
 * Features:
 * - Geolocation-based facility search with distance calculations
 * - Facility services and hours information
 * - Appointment scheduling assistance
 * - Performance optimization with intelligent caching
 * - Member location-aware recommendations
 * - Emergency facility lookup capabilities
 *
 * @author CVMA Development Team
 * @since Epic #8 VA Lighthouse API Integration
 * @version 1.0.0
 */
public with sharing class CVMARealVAFacilitiesController {

    // API Configuration
    private static final String API_NAME = 'VA_Facilities_API';
    private static final String CACHE_KEY_PREFIX = 'VA_FACILITIES_';
    private static final Integer DEFAULT_CACHE_TTL_MINUTES = 120;

    // Search defaults
    private static final Integer DEFAULT_SEARCH_RADIUS_MILES = 50;
    private static final Integer MAX_SEARCH_RADIUS_MILES = 200;
    private static final Integer DEFAULT_RESULTS_LIMIT = 20;

    // Facility types
    private static final Map<String, String> FACILITY_TYPES = new Map<String, String>{
        'health' => 'VA Medical Centers',
        'benefits' => 'VA Regional Offices',
        'cemetery' => 'VA National Cemeteries',
        'vet_center' => 'Vet Centers'
    };

    /**
     * VA Facility Data Structure
     */
    public class VAFacility {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String facilityType { get; set; }
        @AuraEnabled public String classification { get; set; }
        @AuraEnabled public VAAddress address { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String website { get; set; }
        @AuraEnabled public List<String> services { get; set; }
        @AuraEnabled public Map<String, String> hours { get; set; }
        @AuraEnabled public Decimal latitude { get; set; }
        @AuraEnabled public Decimal longitude { get; set; }
        @AuraEnabled public Decimal distanceFromMember { get; set; }
        @AuraEnabled public String operatingStatus { get; set; }
        @AuraEnabled public List<String> specialties { get; set; }
        @AuraEnabled public Boolean hasEmergencyServices { get; set; }
        @AuraEnabled public String appointmentPhone { get; set; }
        @AuraEnabled public String lastUpdated { get; set; }

        public VAFacility() {
            this.services = new List<String>();
            this.hours = new Map<String, String>();
            this.specialties = new List<String>();
            this.hasEmergencyServices = false;
        }
    }

    /**
     * VA Address Structure
     */
    public class VAAddress {
        @AuraEnabled public String street { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String zipCode { get; set; }
        @AuraEnabled public String fullAddress { get; set; }

        public VAAddress() {}
    }

    /**
     * Facility Search Response
     */
    public class VAFacilitySearchResponse {
        @AuraEnabled public List<VAFacility> facilities { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public String searchLocation { get; set; }
        @AuraEnabled public Integer searchRadius { get; set; }
        @AuraEnabled public List<String> facilityTypes { get; set; }
        @AuraEnabled public List<String> services { get; set; }
        @AuraEnabled public Boolean isSuccess { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public DateTime searchTime { get; set; }

        public VAFacilitySearchResponse() {
            this.facilities = new List<VAFacility>();
            this.facilityTypes = new List<String>();
            this.services = new List<String>();
            this.isSuccess = false;
            this.searchTime = DateTime.now();
        }
    }

    /**
     * Member Location Context
     */
    public class MemberLocationContext {
        @AuraEnabled public String memberName { get; set; }
        @AuraEnabled public String memberLocation { get; set; }
        @AuraEnabled public Decimal memberLatitude { get; set; }
        @AuraEnabled public Decimal memberLongitude { get; set; }
        @AuraEnabled public List<VAFacility> nearbyFacilities { get; set; }
        @AuraEnabled public List<VAFacility> recommendedFacilities { get; set; }
        @AuraEnabled public String emergencyFacilityId { get; set; }
        @AuraEnabled public Integer totalNearbyFacilities { get; set; }

        public MemberLocationContext() {
            this.nearbyFacilities = new List<VAFacility>();
            this.recommendedFacilities = new List<VAFacility>();
        }
    }

    /**
     * Search VA facilities by location with comprehensive filtering
     *
     * @param zipCode Search zip code
     * @param state Search state
     * @param city Search city
     * @param latitude Search latitude
     * @param longitude Search longitude
     * @param radiusMiles Search radius in miles
     * @param facilityTypes List of facility types to include
     * @param services List of required services
     * @param resultsLimit Maximum number of results
     * @return VAFacilitySearchResponse Search results with facilities
     */
    @AuraEnabled(cacheable=true)
    public static VAFacilitySearchResponse searchFacilities(String zipCode, String state, String city,
                                                            Decimal latitude, Decimal longitude,
                                                            Integer radiusMiles, List<String> facilityTypes,
                                                            List<String> services, Integer resultsLimit) {
        try {
            // Input validation and sanitization
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'READ');
            zipCode = CVMAErrorHandler.sanitizeInput(zipCode);
            state = CVMAErrorHandler.sanitizeInput(state);
            city = CVMAErrorHandler.sanitizeInput(city);

            // Set defaults
            if (radiusMiles == null || radiusMiles < 1) radiusMiles = DEFAULT_SEARCH_RADIUS_MILES;
            if (radiusMiles > MAX_SEARCH_RADIUS_MILES) radiusMiles = MAX_SEARCH_RADIUS_MILES;
            if (resultsLimit == null || resultsLimit < 1) resultsLimit = DEFAULT_RESULTS_LIMIT;
            if (resultsLimit > 100) resultsLimit = 100;

            // Build search location string
            String searchLocation = buildSearchLocationString(zipCode, state, city, latitude, longitude);
            if (String.isBlank(searchLocation)) {
                throw new CVMAVAFacilitiesException('Search location is required (zip code, city/state, or coordinates)');
            }

            // Check cache first
            String cacheKey = buildFacilityCacheKey(searchLocation, radiusMiles, facilityTypes, services, resultsLimit);
            VAFacilitySearchResponse cachedResponse = (VAFacilitySearchResponse) Cache.Org.get(cacheKey);
            if (cachedResponse != null) {
                return cachedResponse;
            }

            // Build query parameters
            Map<String, String> queryParams = buildFacilityQueryParams(zipCode, state, city, latitude, longitude,
                                                                      radiusMiles, facilityTypes, services, resultsLimit);

            // Make API request
            CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse = CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                API_NAME, 'facilities', 'GET', null, queryParams
            );

            VAFacilitySearchResponse searchResponse = new VAFacilitySearchResponse();
            searchResponse.searchLocation = searchLocation;
            searchResponse.searchRadius = radiusMiles;
            searchResponse.facilityTypes = facilityTypes != null ? facilityTypes : new List<String>();
            searchResponse.services = services != null ? services : new List<String>();

            if (apiResponse.isSuccess) {
                searchResponse = parseFacilitySearchResponse(apiResponse.body, searchResponse);
                searchResponse.isSuccess = true;

                // Calculate distances if coordinates provided
                if (latitude != null && longitude != null) {
                    calculateDistances(searchResponse.facilities, latitude, longitude);
                    sortFacilitiesByDistance(searchResponse.facilities);
                }

                // Cache successful response
                Cache.Org.put(cacheKey, searchResponse, DEFAULT_CACHE_TTL_MINUTES * 60);
            } else {
                searchResponse.isSuccess = false;
                searchResponse.errorMessage = apiResponse.errorMessage;
            }

            return searchResponse;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAFacilitiesController', 'searchFacilities',
                'HIGH', 'INTEGRATION', new Map<String, Object>{
                    'searchLocation' => buildSearchLocationString(zipCode, state, city, latitude, longitude),
                    'radiusMiles' => radiusMiles
                });

            VAFacilitySearchResponse errorResponse = new VAFacilitySearchResponse();
            errorResponse.isSuccess = false;
            errorResponse.errorMessage = 'Failed to search VA facilities: ' + e.getMessage();
            return errorResponse;
        }
    }

    /**
     * Get specific VA facility by ID
     *
     * @param facilityId VA facility ID
     * @return VAFacility Complete facility details
     */
    @AuraEnabled(cacheable=true)
    public static VAFacility getFacilityById(String facilityId) {
        try {
            // Input validation
            facilityId = CVMAErrorHandler.sanitizeInput(facilityId);
            if (String.isBlank(facilityId)) {
                throw new CVMAVAFacilitiesException('Facility ID is required');
            }

            // Check cache first
            String cacheKey = CACHE_KEY_PREFIX + 'FACILITY_' + facilityId;
            VAFacility cachedFacility = (VAFacility) Cache.Org.get(cacheKey);
            if (cachedFacility != null) {
                return cachedFacility;
            }

            // Make API request
            CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse = CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                API_NAME, 'facilities/' + EncodingUtil.urlEncode(facilityId, 'UTF-8'), 'GET', null, null
            );

            if (apiResponse.isSuccess) {
                VAFacility facility = parseFacilityDetails(apiResponse.body);

                // Cache successful response
                Cache.Org.put(cacheKey, facility, DEFAULT_CACHE_TTL_MINUTES * 60);

                return facility;
            } else {
                throw new CVMAVAFacilitiesException('Failed to retrieve facility details: ' + apiResponse.errorMessage);
            }

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAFacilitiesController', 'getFacilityById',
                'MEDIUM', 'INTEGRATION', new Map<String, Object>{'facilityId' => facilityId});
            throw new AuraHandledException('Failed to retrieve VA facility: ' + e.getMessage());
        }
    }

    /**
     * Get member-specific facility recommendations based on location and needs
     *
     * @param memberId Contact ID of the CVMA member
     * @param serviceNeeds List of needed services
     * @return MemberLocationContext Personalized facility recommendations
     */
    @AuraEnabled
    public static MemberLocationContext getMemberFacilityContext(Id memberId, List<String> serviceNeeds) {
        try {
            // Input validation
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'READ');
            if (memberId == null) {
                throw new CVMAVAFacilitiesException('Member ID is required');
            }

            // Get member location information
            Contact member = [
                SELECT Id, FirstName, LastName, MailingStreet, MailingCity,
                       MailingState, MailingPostalCode, MailingLatitude, MailingLongitude
                FROM Contact
                WHERE Id = :memberId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            MemberLocationContext context = new MemberLocationContext();
            context.memberName = member.FirstName + ' ' + member.LastName;
            context.memberLocation = member.MailingCity + ', ' + member.MailingState;
            context.memberLatitude = member.MailingLatitude;
            context.memberLongitude = member.MailingLongitude;

            // Search for nearby facilities
            if (String.isNotBlank(member.MailingPostalCode) || (member.MailingLatitude != null && member.MailingLongitude != null)) {
                VAFacilitySearchResponse nearbySearch = searchFacilities(
                    member.MailingPostalCode, member.MailingState, member.MailingCity,
                    member.MailingLatitude, member.MailingLongitude,
                    DEFAULT_SEARCH_RADIUS_MILES, null, serviceNeeds, 10
                );

                if (nearbySearch.isSuccess) {
                    context.nearbyFacilities = nearbySearch.facilities;
                    context.totalNearbyFacilities = nearbySearch.totalCount;

                    // Identify recommended facilities based on services and distance
                    context.recommendedFacilities = filterRecommendedFacilities(nearbySearch.facilities, serviceNeeds);

                    // Find nearest emergency facility
                    context.emergencyFacilityId = findNearestEmergencyFacility(nearbySearch.facilities);
                }
            }

            return context;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAFacilitiesController', 'getMemberFacilityContext',
                'MEDIUM', 'INTEGRATION', new Map<String, Object>{
                    'memberId' => String.valueOf(memberId),
                    'serviceNeeds' => serviceNeeds
                });
            throw new AuraHandledException('Failed to get member facility context: ' + e.getMessage());
        }
    }

    /**
     * Get available facility types
     *
     * @return Map<String, String> Available facility types with descriptions
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getFacilityTypes() {
        return FACILITY_TYPES;
    }

    /**
     * Get emergency facilities near a location
     *
     * @param zipCode Search zip code
     * @param latitude Search latitude
     * @param longitude Search longitude
     * @return List<VAFacility> Emergency facilities sorted by distance
     */
    @AuraEnabled(cacheable=true)
    public static List<VAFacility> getEmergencyFacilities(String zipCode, Decimal latitude, Decimal longitude) {
        try {
            // Search for health facilities with emergency services
            VAFacilitySearchResponse searchResponse = searchFacilities(
                zipCode, null, null, latitude, longitude,
                100, // Larger radius for emergencies
                new List<String>{'health'},
                new List<String>{'Emergency'},
                5
            );

            if (searchResponse.isSuccess) {
                // Filter for facilities with emergency services
                List<VAFacility> emergencyFacilities = new List<VAFacility>();
                for (VAFacility facility : searchResponse.facilities) {
                    if (facility.hasEmergencyServices) {
                        emergencyFacilities.add(facility);
                    }
                }
                return emergencyFacilities;
            }

            return new List<VAFacility>();

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMARealVAFacilitiesController', 'getEmergencyFacilities',
                'HIGH', 'INTEGRATION', new Map<String, Object>{
                    'zipCode' => zipCode,
                    'latitude' => latitude,
                    'longitude' => longitude
                });
            return new List<VAFacility>();
        }
    }

    // Private helper methods

    /**
     * Build search location string for caching and display
     */
    private static String buildSearchLocationString(String zipCode, String state, String city, Decimal latitude, Decimal longitude) {
        if (String.isNotBlank(zipCode)) {
            return zipCode;
        } else if (String.isNotBlank(city) && String.isNotBlank(state)) {
            return city + ', ' + state;
        } else if (latitude != null && longitude != null) {
            return latitude.setScale(4) + ',' + longitude.setScale(4);
        }
        return null;
    }

    /**
     * Build cache key for facility searches
     */
    private static String buildFacilityCacheKey(String searchLocation, Integer radiusMiles,
                                               List<String> facilityTypes, List<String> services, Integer resultsLimit) {
        List<String> keyParts = new List<String>{
            CACHE_KEY_PREFIX + 'SEARCH',
            searchLocation.replaceAll('[^a-zA-Z0-9,.]', ''),
            String.valueOf(radiusMiles),
            facilityTypes != null ? String.join(facilityTypes, '-') : 'ALL',
            services != null ? String.join(services, '-') : 'ANY',
            String.valueOf(resultsLimit)
        };

        return String.join(keyParts, '_').left(250);
    }

    /**
     * Build query parameters for facility API request
     */
    private static Map<String, String> buildFacilityQueryParams(String zipCode, String state, String city,
                                                               Decimal latitude, Decimal longitude, Integer radiusMiles,
                                                               List<String> facilityTypes, List<String> services,
                                                               Integer resultsLimit) {
        Map<String, String> queryParams = new Map<String, String>();

        // Location parameters
        if (String.isNotBlank(zipCode)) {
            queryParams.put('zip', zipCode);
        } else if (String.isNotBlank(city) && String.isNotBlank(state)) {
            queryParams.put('state', state);
            queryParams.put('city', city);
        } else if (latitude != null && longitude != null) {
            queryParams.put('lat', String.valueOf(latitude));
            queryParams.put('long', String.valueOf(longitude));
        }

        // Search parameters
        queryParams.put('radius', String.valueOf(radiusMiles));
        queryParams.put('per_page', String.valueOf(resultsLimit));

        // Facility type filters
        if (facilityTypes != null && !facilityTypes.isEmpty()) {
            queryParams.put('type', String.join(facilityTypes, ','));
        }

        // Service filters
        if (services != null && !services.isEmpty()) {
            queryParams.put('services', String.join(services, ','));
        }

        return queryParams;
    }

    /**
     * Parse VA Facilities API search response
     */
    private static VAFacilitySearchResponse parseFacilitySearchResponse(String responseBody, VAFacilitySearchResponse searchResponse) {
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            // Handle API response structure
            List<Object> facilitiesData = (List<Object>) responseMap.get('data');
            Map<String, Object> metaData = (Map<String, Object>) responseMap.get('meta');

            if (facilitiesData != null) {
                for (Object facilityObj : facilitiesData) {
                    Map<String, Object> facilityMap = (Map<String, Object>) facilityObj;
                    VAFacility facility = parseFacilityFromAPI(facilityMap);
                    if (facility != null) {
                        searchResponse.facilities.add(facility);
                    }
                }
            }

            // Parse metadata
            if (metaData != null) {
                Object totalCount = metaData.get('total_count');
                if (totalCount != null) {
                    searchResponse.totalCount = (Integer) totalCount;
                }
            } else {
                searchResponse.totalCount = searchResponse.facilities.size();
            }

        } catch (Exception e) {
            throw new CVMAVAFacilitiesException('Failed to parse facilities API response: ' + e.getMessage());
        }

        return searchResponse;
    }

    /**
     * Parse individual facility details from API response
     */
    private static VAFacility parseFacilityDetails(String responseBody) {
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            Map<String, Object> facilityData = (Map<String, Object>) responseMap.get('data');

            return parseFacilityFromAPI(facilityData);

        } catch (Exception e) {
            throw new CVMAVAFacilitiesException('Failed to parse facility details: ' + e.getMessage());
        }
    }

    /**
     * Parse facility data from API response map
     */
    private static VAFacility parseFacilityFromAPI(Map<String, Object> facilityMap) {
        if (facilityMap == null) return null;

        VAFacility facility = new VAFacility();

        // Extract attributes map
        Map<String, Object> attributes = (Map<String, Object>) facilityMap.get('attributes');
        if (attributes == null) return null;

        facility.id = (String) facilityMap.get('id');
        facility.name = (String) attributes.get('name');
        facility.facilityType = (String) attributes.get('facility_type');
        facility.classification = (String) attributes.get('classification');
        facility.phone = (String) attributes.get('phone_number');
        facility.website = (String) attributes.get('website');
        facility.operatingStatus = (String) attributes.get('operating_status');

        // Parse address
        Map<String, Object> addressMap = (Map<String, Object>) attributes.get('address');
        if (addressMap != null) {
            facility.address = parseAddress(addressMap);
        }

        // Parse coordinates
        Map<String, Object> coordsMap = (Map<String, Object>) attributes.get('lat_long');
        if (coordsMap != null) {
            facility.latitude = (Decimal) coordsMap.get('lat');
            facility.longitude = (Decimal) coordsMap.get('long');
        }

        // Parse services
        List<Object> servicesData = (List<Object>) attributes.get('services');
        if (servicesData != null) {
            for (Object serviceObj : servicesData) {
                if (serviceObj instanceof String) {
                    facility.services.add((String) serviceObj);
                }
            }
        }

        // Parse hours
        Map<String, Object> hoursMap = (Map<String, Object>) attributes.get('hours');
        if (hoursMap != null) {
            for (String day : hoursMap.keySet()) {
                facility.hours.put(day, String.valueOf(hoursMap.get(day)));
            }
        }

        // Check for emergency services
        facility.hasEmergencyServices = facility.services.contains('Emergency') ||
                                       facility.services.contains('Emergency Care') ||
                                       facility.classification?.contains('Medical Center') == true;

        // Set appointment phone (often same as main phone)
        facility.appointmentPhone = facility.phone;

        facility.lastUpdated = String.valueOf(Date.today());

        return facility;
    }

    /**
     * Parse address from API response
     */
    private static VAAddress parseAddress(Map<String, Object> addressMap) {
        VAAddress address = new VAAddress();

        Map<String, Object> physicalMap = (Map<String, Object>) addressMap.get('physical');
        if (physicalMap != null) {
            address.street = (String) physicalMap.get('address_1');
            address.city = (String) physicalMap.get('city');
            address.state = (String) physicalMap.get('state');
            address.zipCode = (String) physicalMap.get('zip');

            // Build full address
            List<String> addressParts = new List<String>();
            if (String.isNotBlank(address.street)) addressParts.add(address.street);
            if (String.isNotBlank(address.city)) addressParts.add(address.city);
            if (String.isNotBlank(address.state)) addressParts.add(address.state);
            if (String.isNotBlank(address.zipCode)) addressParts.add(address.zipCode);

            address.fullAddress = String.join(addressParts, ', ');
        }

        return address;
    }

    /**
     * Calculate distances from member location to facilities
     */
    private static void calculateDistances(List<VAFacility> facilities, Decimal memberLat, Decimal memberLng) {
        for (VAFacility facility : facilities) {
            if (facility.latitude != null && facility.longitude != null) {
                facility.distanceFromMember = calculateDistance(memberLat, memberLng, facility.latitude, facility.longitude);
            }
        }
    }

    /**
     * Calculate distance between two points using Haversine formula
     */
    private static Decimal calculateDistance(Decimal lat1, Decimal lng1, Decimal lat2, Decimal lng2) {
        if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
            return null;
        }

        // Convert to radians
        Decimal dLat = Math.toRadians(lat2 - lat1);
        Decimal dLng = Math.toRadians(lng2 - lng1);
        Decimal a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                   Math.sin(dLng / 2) * Math.sin(dLng / 2);
        Decimal c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        // Earth's radius in miles
        Decimal earthRadiusMiles = 3959;
        return earthRadiusMiles * c;
    }

    /**
     * Sort facilities by distance from member
     */
    private static void sortFacilitiesByDistance(List<VAFacility> facilities) {
        // Simple bubble sort implementation (for small lists)
        for (Integer i = 0; i < facilities.size() - 1; i++) {
            for (Integer j = 0; j < facilities.size() - i - 1; j++) {
                Decimal dist1 = facilities[j].distanceFromMember;
                Decimal dist2 = facilities[j + 1].distanceFromMember;

                if (dist1 != null && dist2 != null && dist1 > dist2) {
                    VAFacility temp = facilities[j];
                    facilities[j] = facilities[j + 1];
                    facilities[j + 1] = temp;
                } else if (dist1 == null && dist2 != null) {
                    VAFacility temp = facilities[j];
                    facilities[j] = facilities[j + 1];
                    facilities[j + 1] = temp;
                }
            }
        }
    }

    /**
     * Filter recommended facilities based on services and proximity
     */
    private static List<VAFacility> filterRecommendedFacilities(List<VAFacility> facilities, List<String> serviceNeeds) {
        List<VAFacility> recommended = new List<VAFacility>();

        for (VAFacility facility : facilities) {
            // Recommend medical centers within 25 miles
            if (facility.facilityType == 'health' && facility.distanceFromMember != null && facility.distanceFromMember <= 25) {
                recommended.add(facility);
            }

            // Recommend facilities that match needed services
            if (serviceNeeds != null) {
                for (String neededService : serviceNeeds) {
                    if (facility.services.contains(neededService)) {
                        recommended.add(facility);
                        break;
                    }
                }
            }

            // Limit recommendations
            if (recommended.size() >= 5) break;
        }

        return recommended;
    }

    /**
     * Find nearest facility with emergency services
     */
    private static String findNearestEmergencyFacility(List<VAFacility> facilities) {
        for (VAFacility facility : facilities) {
            if (facility.hasEmergencyServices) {
                return facility.id;
            }
        }
        return null;
    }

    /**
     * Custom exception for VA Facilities API errors
     */
    public class CVMAVAFacilitiesException extends Exception {}
}
