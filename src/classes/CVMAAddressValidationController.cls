/**
 * CVMAAddressValidationController
 * Production-ready VA Address Validation API integration for CVMA Chapter 20-7
 *
 * Integrates with VA Address Validation API to provide comprehensive address
 * validation, standardization, and optimization for member profiles and
 * VA correspondence accuracy.
 *
 * Features:
 * - Member profile address validation and standardization
 * - Mailing address optimization for VA correspondence
 * - Batch address validation for data cleanup
 * - Real-time address suggestions and corrections
 * - Performance optimization with intelligent caching
 * - Geographic coordinate enrichment
 *
 * @author CVMA Development Team
 * @since Epic #8 VA Lighthouse API Integration
 * @version 1.0.0
 */
public with sharing class CVMAAddressValidationController {

    // API Configuration
    private static final String API_NAME = 'VA_Address_Validation';
    private static final String CACHE_KEY_PREFIX = 'VA_ADDRESS_';
    private static final Integer DEFAULT_CACHE_TTL_MINUTES = 240; // 4 hours for address data

    // Validation confidence thresholds
    private static final Decimal HIGH_CONFIDENCE_THRESHOLD = 80.0;
    private static final Decimal MEDIUM_CONFIDENCE_THRESHOLD = 60.0;

    /**
     * Address Validation Request Structure
     */
    public class AddressValidationRequest {
        @AuraEnabled public String street { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String zipCode { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public String addressType { get; set; } // 'mailing', 'physical', 'billing'
        @AuraEnabled public Boolean requireHighConfidence { get; set; }

        public AddressValidationRequest() {
            this.country = 'United States';
            this.addressType = 'mailing';
            this.requireHighConfidence = false;
        }
    }

    /**
     * Validated Address Response Structure
     */
    public class ValidatedAddress {
        @AuraEnabled public String street { get; set; }
        @AuraEnabled public String city { get; set; }
        @AuraEnabled public String state { get; set; }
        @AuraEnabled public String zipCode { get; set; }
        @AuraEnabled public String zipCodeExtended { get; set; }
        @AuraEnabled public String county { get; set; }
        @AuraEnabled public String country { get; set; }
        @AuraEnabled public String formattedAddress { get; set; }
        @AuraEnabled public Decimal latitude { get; set; }
        @AuraEnabled public Decimal longitude { get; set; }
        @AuraEnabled public String addressType { get; set; }
        @AuraEnabled public Boolean isDeliverable { get; set; }
        @AuraEnabled public String deliverabilityAnalysis { get; set; }

        public ValidatedAddress() {
            this.country = 'United States';
            this.isDeliverable = false;
        }
    }

    /**
     * Address Validation Response Structure
     */
    public class AddressValidationResponse {
        @AuraEnabled public ValidatedAddress validatedAddress { get; set; }
        @AuraEnabled public ValidatedAddress originalAddress { get; set; }
        @AuraEnabled public List<ValidatedAddress> suggestions { get; set; }
        @AuraEnabled public Decimal confidenceScore { get; set; }
        @AuraEnabled public String validationLevel { get; set; } // 'HIGH', 'MEDIUM', 'LOW'
        @AuraEnabled public Boolean isValid { get; set; }
        @AuraEnabled public Boolean requiresCorrection { get; set; }
        @AuraEnabled public List<String> validationMessages { get; set; }
        @AuraEnabled public String validationStatus { get; set; }
        @AuraEnabled public Boolean isSuccess { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public DateTime validatedAt { get; set; }

        public AddressValidationResponse() {
            this.suggestions = new List<ValidatedAddress>();
            this.validationMessages = new List<String>();
            this.isValid = false;
            this.requiresCorrection = false;
            this.isSuccess = false;
            this.validatedAt = DateTime.now();
        }
    }

    /**
     * Batch Address Validation Result
     */
    public class BatchValidationResult {
        @AuraEnabled public List<AddressValidationResponse> validationResults { get; set; }
        @AuraEnabled public Integer totalProcessed { get; set; }
        @AuraEnabled public Integer validAddresses { get; set; }
        @AuraEnabled public Integer invalidAddresses { get; set; }
        @AuraEnabled public Integer correctedAddresses { get; set; }
        @AuraEnabled public Boolean isSuccess { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public DateTime processingTime { get; set; }

        public BatchValidationResult() {
            this.validationResults = new List<AddressValidationResponse>();
            this.isSuccess = false;
            this.processingTime = DateTime.now();
        }
    }

    /**
     * Member Address Context
     */
    public class MemberAddressContext {
        @AuraEnabled public String memberId { get; set; }
        @AuraEnabled public String memberName { get; set; }
        @AuraEnabled public AddressValidationResponse mailingAddressValidation { get; set; }
        @AuraEnabled public AddressValidationResponse shippingAddressValidation { get; set; }
        @AuraEnabled public List<String> addressRecommendations { get; set; }
        @AuraEnabled public Boolean needsAddressUpdate { get; set; }
        @AuraEnabled public String addressQualityScore { get; set; }

        public MemberAddressContext() {
            this.addressRecommendations = new List<String>();
            this.needsAddressUpdate = false;
        }
    }

    /**
     * Validate single address with comprehensive analysis
     *
     * @param request Address validation request with all components
     * @return AddressValidationResponse Validation results with suggestions
     */
    @AuraEnabled
    public static AddressValidationResponse validateAddress(AddressValidationRequest request) {
        try {
            // Input validation and sanitization
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'READ');
            if (request == null) {
                throw new CVMAAddressValidationException('Address validation request is required');
            }

            request.street = CVMAErrorHandler.sanitizeInput(request.street);
            request.city = CVMAErrorHandler.sanitizeInput(request.city);
            request.state = CVMAErrorHandler.sanitizeInput(request.state);
            request.zipCode = CVMAErrorHandler.sanitizeInput(request.zipCode);

            if (String.isBlank(request.street) || String.isBlank(request.city) || String.isBlank(request.state)) {
                throw new CVMAAddressValidationException('Street, city, and state are required for address validation');
            }

            // Check cache first
            String cacheKey = buildAddressCacheKey(request);
            AddressValidationResponse cachedResponse = (AddressValidationResponse) Cache.Org.get(cacheKey);
            if (cachedResponse != null) {
                return cachedResponse;
            }

            // Build API request
            String requestBody = buildValidationRequestBody(request);

            // Make API request
            CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse = CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                API_NAME, 'validate', 'POST', requestBody, null
            );

            AddressValidationResponse validationResponse = new AddressValidationResponse();

            if (apiResponse.isSuccess) {
                validationResponse = parseValidationResponse(apiResponse.body, request);
                validationResponse.isSuccess = true;

                // Enhance with additional analysis
                enrichValidationResponse(validationResponse, request);

                // Cache successful response
                Cache.Org.put(cacheKey, validationResponse, DEFAULT_CACHE_TTL_MINUTES * 60);
            } else {
                validationResponse.isSuccess = false;
                validationResponse.errorMessage = apiResponse.errorMessage;
            }

            return validationResponse;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAAddressValidationController', 'validateAddress',
                'HIGH', 'INTEGRATION', new Map<String, Object>{
                    'street' => request?.street,
                    'city' => request?.city,
                    'state' => request?.state
                });

            AddressValidationResponse errorResponse = new AddressValidationResponse();
            errorResponse.isSuccess = false;
            errorResponse.errorMessage = 'Failed to validate address: ' + e.getMessage();
            return errorResponse;
        }
    }

    /**
     * Validate member profile addresses
     *
     * @param memberId Contact ID of the CVMA member
     * @return MemberAddressContext Complete address validation context for member
     */
    @AuraEnabled
    public static MemberAddressContext validateMemberAddresses(Id memberId) {
        try {
            // Input validation
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'READ');
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'UPDATE');

            if (memberId == null) {
                throw new CVMAAddressValidationException('Member ID is required');
            }

            // Get member address information
            Contact member = [
                SELECT Id, FirstName, LastName, MailingStreet, MailingCity, MailingState,
                       MailingPostalCode, MailingCountry, OtherStreet, OtherCity, OtherState,
                       OtherPostalCode, OtherCountry
                FROM Contact
                WHERE Id = :memberId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            MemberAddressContext context = new MemberAddressContext();
            context.memberId = String.valueOf(member.Id);
            context.memberName = member.FirstName + ' ' + member.LastName;

            // Validate mailing address
            if (String.isNotBlank(member.MailingStreet)) {
                AddressValidationRequest mailingRequest = new AddressValidationRequest();
                mailingRequest.street = member.MailingStreet;
                mailingRequest.city = member.MailingCity;
                mailingRequest.state = member.MailingState;
                mailingRequest.zipCode = member.MailingPostalCode;
                mailingRequest.country = member.MailingCountry;
                mailingRequest.addressType = 'mailing';
                mailingRequest.requireHighConfidence = true;

                context.mailingAddressValidation = validateAddress(mailingRequest);
            }

            // Validate shipping/other address if different
            if (String.isNotBlank(member.OtherStreet) && !isSameAddress(member)) {
                AddressValidationRequest shippingRequest = new AddressValidationRequest();
                shippingRequest.street = member.OtherStreet;
                shippingRequest.city = member.OtherCity;
                shippingRequest.state = member.OtherState;
                shippingRequest.zipCode = member.OtherPostalCode;
                shippingRequest.country = member.OtherCountry;
                shippingRequest.addressType = 'physical';

                context.shippingAddressValidation = validateAddress(shippingRequest);
            }

            // Generate address recommendations
            context.addressRecommendations = generateAddressRecommendations(context);
            context.needsAddressUpdate = determineAddressUpdateNeed(context);
            context.addressQualityScore = calculateAddressQualityScore(context);

            return context;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAAddressValidationController', 'validateMemberAddresses',
                'MEDIUM', 'INTEGRATION', new Map<String, Object>{'memberId' => String.valueOf(memberId)});
            throw new AuraHandledException('Failed to validate member addresses: ' + e.getMessage());
        }
    }

    /**
     * Batch validate multiple addresses for data cleanup
     *
     * @param requests List of address validation requests
     * @return BatchValidationResult Results for all address validations
     */
    @AuraEnabled
    public static BatchValidationResult validateAddressesBatch(List<AddressValidationRequest> requests) {
        try {
            // Input validation
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'READ');

            if (requests == null || requests.isEmpty()) {
                throw new CVMAAddressValidationException('Address validation requests are required');
            }

            if (requests.size() > 100) {
                throw new CVMAAddressValidationException('Batch size cannot exceed 100 addresses');
            }

            BatchValidationResult batchResult = new BatchValidationResult();
            batchResult.totalProcessed = requests.size();

            // Process each address
            for (AddressValidationRequest request : requests) {
                try {
                    AddressValidationResponse response = validateAddress(request);
                    batchResult.validationResults.add(response);

                    // Update counters
                    if (response.isValid) {
                        batchResult.validAddresses++;
                    } else {
                        batchResult.invalidAddresses++;
                    }

                    if (response.requiresCorrection) {
                        batchResult.correctedAddresses++;
                    }

                } catch (Exception e) {
                    // Create error response for failed validation
                    AddressValidationResponse errorResponse = new AddressValidationResponse();
                    errorResponse.isSuccess = false;
                    errorResponse.errorMessage = e.getMessage();
                    batchResult.validationResults.add(errorResponse);
                    batchResult.invalidAddresses++;
                }
            }

            batchResult.isSuccess = true;
            return batchResult;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAAddressValidationController', 'validateAddressesBatch',
                'HIGH', 'INTEGRATION', new Map<String, Object>{'batchSize' => requests?.size()});

            BatchValidationResult errorResult = new BatchValidationResult();
            errorResult.isSuccess = false;
            errorResult.errorMessage = 'Failed to process batch validation: ' + e.getMessage();
            return errorResult;
        }
    }

    /**
     * Apply validated address corrections to member profile
     *
     * @param memberId Contact ID of the member
     * @param validatedAddress Validated address to apply
     * @param addressType Type of address ('mailing' or 'other')
     * @return Boolean Success status of address update
     */
    @AuraEnabled
    public static Boolean applyAddressCorrection(Id memberId, ValidatedAddress validatedAddress, String addressType) {
        try {
            // Input validation
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'UPDATE');

            if (memberId == null || validatedAddress == null) {
                throw new CVMAAddressValidationException('Member ID and validated address are required');
            }

            addressType = CVMAErrorHandler.sanitizeInput(addressType);
            if (String.isBlank(addressType)) {
                addressType = 'mailing';
            }

            // Get member record
            Contact member = [
                SELECT Id
                FROM Contact
                WHERE Id = :memberId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            // Apply address correction based on type
            if (addressType.toLowerCase() == 'mailing') {
                member.MailingStreet = validatedAddress.street;
                member.MailingCity = validatedAddress.city;
                member.MailingState = validatedAddress.state;
                member.MailingPostalCode = validatedAddress.zipCodeExtended != null ?
                    validatedAddress.zipCodeExtended : validatedAddress.zipCode;
                member.MailingCountry = validatedAddress.country;
            } else {
                member.OtherStreet = validatedAddress.street;
                member.OtherCity = validatedAddress.city;
                member.OtherState = validatedAddress.state;
                member.OtherPostalCode = validatedAddress.zipCodeExtended != null ?
                    validatedAddress.zipCodeExtended : validatedAddress.zipCode;
                member.OtherCountry = validatedAddress.country;
            }

            // Update the record
            update member;

            return true;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAAddressValidationController', 'applyAddressCorrection',
                'MEDIUM', 'INTEGRATION', new Map<String, Object>{
                    'memberId' => String.valueOf(memberId),
                    'addressType' => addressType
                });
            throw new AuraHandledException('Failed to apply address correction: ' + e.getMessage());
        }
    }

    // Private helper methods

    /**
     * Build cache key for address validation
     */
    private static String buildAddressCacheKey(AddressValidationRequest request) {
        List<String> keyParts = new List<String>{
            CACHE_KEY_PREFIX + 'VALIDATE',
            request.street?.replaceAll('[^a-zA-Z0-9 ]', '').replaceAll(' ', '_').left(50),
            request.city?.replaceAll('[^a-zA-Z0-9]', ''),
            request.state?.replaceAll('[^a-zA-Z0-9]', ''),
            request.zipCode?.replaceAll('[^0-9]', '')
        };

        return String.join(keyParts, '_').left(250);
    }

    /**
     * Build API request body for address validation
     */
    private static String buildValidationRequestBody(AddressValidationRequest request) {
        Map<String, Object> requestMap = new Map<String, Object>{
            'requestAddress' => new Map<String, Object>{
                'addressLine1' => request.street,
                'city' => request.city,
                'stateProvince' => request.state,
                'zipCode5' => request.zipCode?.left(5),
                'country' => request.country
            },
            'addressType' => request.addressType
        };

        return JSON.serialize(requestMap);
    }

    /**
     * Parse address validation API response
     */
    private static AddressValidationResponse parseValidationResponse(String responseBody, AddressValidationRequest originalRequest) {
        AddressValidationResponse response = new AddressValidationResponse();

        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            // Parse validated address
            Map<String, Object> addressMap = (Map<String, Object>) responseMap.get('address');
            if (addressMap != null) {
                response.validatedAddress = parseValidatedAddressFromAPI(addressMap);
            }

            // Parse validation metadata
            Map<String, Object> validationMap = (Map<String, Object>) responseMap.get('validation');
            if (validationMap != null) {
                response.confidenceScore = (Decimal) validationMap.get('confidence');
                response.validationStatus = (String) validationMap.get('status');
                response.isValid = 'CONFIRMED'.equals(response.validationStatus);

                // Parse validation messages
                List<Object> messages = (List<Object>) validationMap.get('messages');
                if (messages != null) {
                    for (Object msg : messages) {
                        response.validationMessages.add(String.valueOf(msg));
                    }
                }
            }

            // Parse suggestions if available
            List<Object> suggestions = (List<Object>) responseMap.get('suggestions');
            if (suggestions != null) {
                for (Object suggestionObj : suggestions) {
                    Map<String, Object> suggestionMap = (Map<String, Object>) suggestionObj;
                    ValidatedAddress suggestion = parseValidatedAddressFromAPI(suggestionMap);
                    if (suggestion != null) {
                        response.suggestions.add(suggestion);
                    }
                }
            }

            // Store original address for comparison
            response.originalAddress = buildOriginalAddress(originalRequest);

        } catch (Exception e) {
            throw new CVMAAddressValidationException('Failed to parse validation response: ' + e.getMessage());
        }

        return response;
    }

    /**
     * Parse validated address from API response
     */
    private static ValidatedAddress parseValidatedAddressFromAPI(Map<String, Object> addressMap) {
        if (addressMap == null) return null;

        ValidatedAddress address = new ValidatedAddress();

        address.street = (String) addressMap.get('addressLine1');
        address.city = (String) addressMap.get('city');
        address.state = (String) addressMap.get('stateProvince');
        address.zipCode = (String) addressMap.get('zipCode5');
        address.zipCodeExtended = (String) addressMap.get('zipCode4');
        address.county = (String) addressMap.get('county');
        address.country = (String) addressMap.get('country');

        // Build formatted address
        List<String> addressParts = new List<String>();
        if (String.isNotBlank(address.street)) addressParts.add(address.street);
        if (String.isNotBlank(address.city)) addressParts.add(address.city);
        if (String.isNotBlank(address.state)) addressParts.add(address.state);
        String zipDisplay = address.zipCode;
        if (String.isNotBlank(address.zipCodeExtended)) {
            zipDisplay += '-' + address.zipCodeExtended;
        }
        if (String.isNotBlank(zipDisplay)) addressParts.add(zipDisplay);

        address.formattedAddress = String.join(addressParts, ', ');

        // Parse coordinates if available
        Map<String, Object> coordsMap = (Map<String, Object>) addressMap.get('coordinates');
        if (coordsMap != null) {
            address.latitude = (Decimal) coordsMap.get('latitude');
            address.longitude = (Decimal) coordsMap.get('longitude');
        }

        // Parse deliverability
        Map<String, Object> deliveryMap = (Map<String, Object>) addressMap.get('deliverability');
        if (deliveryMap != null) {
            address.isDeliverable = 'DELIVERABLE'.equals(deliveryMap.get('status'));
            address.deliverabilityAnalysis = (String) deliveryMap.get('analysis');
        }

        return address;
    }

    /**
     * Build original address from request for comparison
     */
    private static ValidatedAddress buildOriginalAddress(AddressValidationRequest request) {
        ValidatedAddress original = new ValidatedAddress();

        original.street = request.street;
        original.city = request.city;
        original.state = request.state;
        original.zipCode = request.zipCode;
        original.country = request.country;
        original.addressType = request.addressType;

        // Build formatted address
        List<String> addressParts = new List<String>();
        if (String.isNotBlank(original.street)) addressParts.add(original.street);
        if (String.isNotBlank(original.city)) addressParts.add(original.city);
        if (String.isNotBlank(original.state)) addressParts.add(original.state);
        if (String.isNotBlank(original.zipCode)) addressParts.add(original.zipCode);

        original.formattedAddress = String.join(addressParts, ', ');

        return original;
    }

    /**
     * Enhance validation response with additional analysis
     */
    private static void enrichValidationResponse(AddressValidationResponse response, AddressValidationRequest request) {
        // Determine validation level based on confidence score
        if (response.confidenceScore != null) {
            if (response.confidenceScore >= HIGH_CONFIDENCE_THRESHOLD) {
                response.validationLevel = 'HIGH';
            } else if (response.confidenceScore >= MEDIUM_CONFIDENCE_THRESHOLD) {
                response.validationLevel = 'MEDIUM';
            } else {
                response.validationLevel = 'LOW';
            }
        }

        // Determine if correction is required
        if (response.validatedAddress != null && response.originalAddress != null) {
            response.requiresCorrection = !addressesMatch(response.validatedAddress, response.originalAddress);
        }

        // Add specific validation messages based on analysis
        if (response.requiresCorrection) {
            response.validationMessages.add('Address standardization recommended for optimal mail delivery');
        }

        if (response.validatedAddress?.isDeliverable == false) {
            response.validationMessages.add('Address may not be deliverable - please verify accuracy');
        }

        if (request.requireHighConfidence && response.confidenceScore < HIGH_CONFIDENCE_THRESHOLD) {
            response.validationMessages.add('Address validation confidence below required threshold');
        }
    }

    /**
     * Check if two addresses match
     */
    private static Boolean addressesMatch(ValidatedAddress addr1, ValidatedAddress addr2) {
        return normalizeForComparison(addr1.street) == normalizeForComparison(addr2.street) &&
               normalizeForComparison(addr1.city) == normalizeForComparison(addr2.city) &&
               normalizeForComparison(addr1.state) == normalizeForComparison(addr2.state) &&
               normalizeForComparison(addr1.zipCode) == normalizeForComparison(addr2.zipCode);
    }

    /**
     * Normalize address component for comparison
     */
    private static String normalizeForComparison(String addressComponent) {
        if (String.isBlank(addressComponent)) return '';
        return addressComponent.toLowerCase().replaceAll('[^a-z0-9]', '');
    }

    /**
     * Check if mailing and other addresses are the same
     */
    private static Boolean isSameAddress(Contact member) {
        return normalizeForComparison(member.MailingStreet) == normalizeForComparison(member.OtherStreet) &&
               normalizeForComparison(member.MailingCity) == normalizeForComparison(member.OtherCity) &&
               normalizeForComparison(member.MailingState) == normalizeForComparison(member.OtherState);
    }

    /**
     * Generate address recommendations for member
     */
    private static List<String> generateAddressRecommendations(MemberAddressContext context) {
        List<String> recommendations = new List<String>();

        if (context.mailingAddressValidation?.requiresCorrection == true) {
            recommendations.add('Update mailing address with standardized format for reliable VA mail delivery');
        }

        if (context.mailingAddressValidation?.validatedAddress?.isDeliverable == false) {
            recommendations.add('Verify mailing address accuracy - current address may not be deliverable');
        }

        if (context.shippingAddressValidation?.requiresCorrection == true) {
            recommendations.add('Consider updating shipping address for accurate deliveries');
        }

        if (context.mailingAddressValidation?.confidenceScore < MEDIUM_CONFIDENCE_THRESHOLD) {
            recommendations.add('Address verification recommended - low confidence in current address format');
        }

        if (recommendations.isEmpty()) {
            recommendations.add('Address information appears accurate and up-to-date');
        }

        return recommendations;
    }

    /**
     * Determine if member needs address update
     */
    private static Boolean determineAddressUpdateNeed(MemberAddressContext context) {
        return (context.mailingAddressValidation?.requiresCorrection == true) ||
               (context.mailingAddressValidation?.validatedAddress?.isDeliverable == false) ||
               (context.mailingAddressValidation?.confidenceScore < MEDIUM_CONFIDENCE_THRESHOLD);
    }

    /**
     * Calculate overall address quality score
     */
    private static String calculateAddressQualityScore(MemberAddressContext context) {
        if (context.mailingAddressValidation?.confidenceScore == null) {
            return 'UNKNOWN';
        }

        Decimal score = context.mailingAddressValidation.confidenceScore;

        if (score >= HIGH_CONFIDENCE_THRESHOLD) {
            return 'EXCELLENT';
        } else if (score >= MEDIUM_CONFIDENCE_THRESHOLD) {
            return 'GOOD';
        } else if (score >= 40) {
            return 'NEEDS_IMPROVEMENT';
        } else {
            return 'POOR';
        }
    }

    /**
     * Custom exception for Address Validation API errors
     */
    public class CVMAAddressValidationException extends Exception {}
}
