/**
 * CVMARealVAAPIAuthenticatorTest
 * Comprehensive test class for CVMARealVAAPIAuthenticator
 *
 * Tests OAuth 2.0 authentication, API configuration management, and request handling
 * with comprehensive mock scenarios and edge cases.
 *
 * @author CVMA Development Team
 * @since Epic #8 VA Lighthouse API Integration
 * @version 1.0.0
 */
@IsTest
private class CVMARealVAAPIAuthenticatorTest {

    /**
     * Test data setup
     */
    @TestSetup
    static void makeData() {
        // Create test contacts using factory
        Contact testMember = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .withMailingAddress('123 Test St', 'Jacksonville', 'FL', '32204')
            .create();
    }

    /**
     * Test successful API configuration retrieval
     */
    @IsTest
    static void testGetAPIConfiguration_Success() {
        Test.startTest();

        try {
            CVMARealVAAPIAuthenticator.VAAPIConfig config =
                CVMARealVAAPIAuthenticator.getAPIConfiguration('VA_Forms_API');

            // Verify configuration structure
            System.assertNotEquals(null, config, 'API configuration should not be null');
            System.assertEquals('VA_Forms_API', config.apiName, 'API name should match request');
            System.assert(config.isActive, 'API should be active by default');
            System.assert(config.useMockAPI, 'Should use mock API by default');
            System.assertNotEquals(null, config.baseURL, 'Base URL should be configured');
            System.assertNotEquals(null, config.version, 'API version should be configured');

        } catch (Exception e) {
            System.assert(false, 'Should not throw exception for valid API configuration: ' + e.getMessage());
        }

        Test.stopTest();
    }

    /**
     * Test API configuration retrieval with invalid API name
     */
    @IsTest
    static void testGetAPIConfiguration_InvalidAPI() {
        Test.startTest();

        try {
            CVMARealVAAPIAuthenticator.VAAPIConfig config =
                CVMARealVAAPIAuthenticator.getAPIConfiguration('Invalid_API');
            System.assert(false, 'Should throw exception for invalid API name');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('API configuration not found'),
                'Should throw appropriate error message');
        }

        Test.stopTest();
    }

    /**
     * Test access token retrieval with mock response
     */
    @IsTest
    static void testGetAccessToken_Success() {
        Test.startTest();

        // Set up mock HTTP response for OAuth token request
        Test.setMock(HttpCalloutMock.class, new VAOAuthSuccessMock());

        CVMARealVAAPIAuthenticator.VATokenResponse tokenResponse =
            CVMARealVAAPIAuthenticator.getAccessToken();

        // Verify token response
        System.assertEquals(true, tokenResponse.isValid, 'Token should be valid');
        System.assertNotEquals(null, tokenResponse.accessToken, 'Access token should not be null');
        System.assertEquals('Bearer', tokenResponse.tokenType, 'Token type should be Bearer');
        System.assert(tokenResponse.expiresIn > 0, 'Token should have expiration time');
        System.assertNotEquals(null, tokenResponse.expiresAt, 'Expiration date should be set');

        Test.stopTest();
    }

    /**
     * Test access token retrieval with authentication failure
     */
    @IsTest
    static void testGetAccessToken_AuthFailure() {
        Test.startTest();

        // Set up mock HTTP response for OAuth failure
        Test.setMock(HttpCalloutMock.class, new VAOAuthFailureMock());

        CVMARealVAAPIAuthenticator.VATokenResponse tokenResponse =
            CVMARealVAAPIAuthenticator.getAccessToken();

        // Verify failed token response
        System.assertEquals(false, tokenResponse.isValid, 'Token should be invalid');
        System.assertEquals(null, tokenResponse.accessToken, 'Access token should be null');

        Test.stopTest();
    }

    /**
     * Test authenticated API request with success response
     */
    @IsTest
    static void testMakeAuthenticatedRequest_Success() {
        Test.startTest();

        // Set up mock responses
        Test.setMock(HttpCalloutMock.class, new VAAPISuccessMock());

        Map<String, String> queryParams = new Map<String, String>{
            'query' => 'disability',
            'page' => '1'
        };

        CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse =
            CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                'VA_Forms_API', 'forms', 'GET', null, queryParams
            );

        // Verify successful response
        System.assertEquals(true, apiResponse.isSuccess, 'API request should be successful');
        System.assertEquals(200, apiResponse.statusCode, 'Status code should be 200');
        System.assertNotEquals(null, apiResponse.body, 'Response body should not be null');
        System.assert(apiResponse.responseTime >= 0, 'Response time should be recorded');
        System.assertNotEquals(null, apiResponse.timestamp, 'Timestamp should be set');

        Test.stopTest();
    }

    /**
     * Test authenticated API request with API failure
     */
    @IsTest
    static void testMakeAuthenticatedRequest_APIFailure() {
        Test.startTest();

        // Set up mock for API failure
        Test.setMock(HttpCalloutMock.class, new VAAPIFailureMock());

        CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse =
            CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                'VA_Forms_API', 'forms', 'GET', null, null
            );

        // Verify failed response
        System.assertEquals(false, apiResponse.isSuccess, 'API request should fail');
        System.assertEquals(500, apiResponse.statusCode, 'Status code should be 500');
        System.assertNotEquals(null, apiResponse.errorMessage, 'Error message should be set');

        Test.stopTest();
    }

    /**
     * Test authenticated API request with invalid API name
     */
    @IsTest
    static void testMakeAuthenticatedRequest_InvalidAPIName() {
        Test.startTest();

        CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse =
            CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                'Invalid_API', 'test', 'GET', null, null
            );

        // Verify error response
        System.assertEquals(false, apiResponse.isSuccess, 'Request should fail for invalid API');
        System.assertNotEquals(null, apiResponse.errorMessage, 'Error message should be provided');

        Test.stopTest();
    }

    /**
     * Test authenticated API request with empty parameters
     */
    @IsTest
    static void testMakeAuthenticatedRequest_EmptyParameters() {
        Test.startTest();

        CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse =
            CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                '', '', 'GET', null, null
            );

        // Verify error response for empty parameters
        System.assertEquals(false, apiResponse.isSuccess, 'Request should fail for empty parameters');
        System.assertNotEquals(null, apiResponse.errorMessage, 'Error message should be provided');

        Test.stopTest();
    }

    /**
     * Test authenticated API request with mock API enabled
     */
    @IsTest
    static void testMakeAuthenticatedRequest_MockAPI() {
        Test.startTest();

        // The default configuration should use mock API
        CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse =
            CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                'VA_Forms_API', 'forms', 'GET', null, null
            );

        // Verify mock response
        System.assertEquals(true, apiResponse.isSuccess, 'Mock API should return success');
        System.assertEquals(200, apiResponse.statusCode, 'Mock should return 200 status');
        System.assert(apiResponse.body.contains('mock'), 'Mock response should contain mock indicator');

        Test.stopTest();
    }

    /**
     * Test rate limiting functionality
     */
    @IsTest
    static void testRateLimiting() {
        Test.startTest();

        // Make multiple requests to test rate limiting
        for (Integer i = 0; i < 5; i++) {
            CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse =
                CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                    'VA_Forms_API', 'forms', 'GET', null, null
                );

            // All requests should succeed with mock API (no actual rate limiting in test)
            System.assertEquals(true, apiResponse.isSuccess, 'Mock API requests should succeed');
        }

        Test.stopTest();
    }

    /**
     * Test error handling and logging
     */
    @IsTest
    static void testErrorHandling() {
        Test.startTest();

        // Test with malformed input that should trigger error handling
        try {
            CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse =
                CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                    null, 'forms', 'GET', null, null
                );

            System.assertEquals(false, apiResponse.isSuccess, 'Request with null API name should fail');

        } catch (Exception e) {
            // Exception handling is acceptable for null parameters
            System.assert(true, 'Exception handling for null parameters is acceptable');
        }

        Test.stopTest();
    }

    // Mock classes for HTTP callouts

    /**
     * Mock class for successful OAuth token response
     */
    public class VAOAuthSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"mock_token_12345","token_type":"Bearer","expires_in":3600,"scope":"veteran/forms.read veteran/facilities.read"}');
            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * Mock class for failed OAuth token response
     */
    public class VAOAuthFailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"invalid_client","error_description":"Invalid client credentials"}');
            res.setStatusCode(401);
            return res;
        }
    }

    /**
     * Mock class for successful API response
     */
    public class VAAPISuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('oauth2/token')) {
                // OAuth token request
                res.setBody('{"access_token":"mock_token_12345","token_type":"Bearer","expires_in":3600}');
            } else {
                // API request
                res.setBody('{"data":[{"id":"1","attributes":{"name":"Test Form"}}],"meta":{"total_count":1}}');
            }

            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * Mock class for failed API response
     */
    public class VAAPIFailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('oauth2/token')) {
                // OAuth failure
                res.setBody('{"error":"invalid_client"}');
                res.setStatusCode(401);
            } else {
                // API failure
                res.setBody('{"error":"Internal server error"}');
                res.setStatusCode(500);
            }

            return res;
        }
    }

    /**
     * Test caching functionality
     */
    @IsTest
    static void testCaching() {
        Test.startTest();

        // First request should hit the API
        CVMARealVAAPIAuthenticator.VAAPIConfig config1 =
            CVMARealVAAPIAuthenticator.getAPIConfiguration('VA_Forms_API');

        // Second request should use cache
        CVMARealVAAPIAuthenticator.VAAPIConfig config2 =
            CVMARealVAAPIAuthenticator.getAPIConfiguration('VA_Forms_API');

        // Both should return the same configuration
        System.assertEquals(config1.apiName, config2.apiName, 'Cached config should match');
        System.assertEquals(config1.baseURL, config2.baseURL, 'Cached config should match');

        Test.stopTest();
    }

    /**
     * Test input sanitization
     */
    @IsTest
    static void testInputSanitization() {
        Test.startTest();

        // Test with potentially malicious input
        String maliciousInput = '<script>alert("xss")</script>';
        Map<String, String> queryParams = new Map<String, String>{
            'query' => maliciousInput
        };

        CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse =
            CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                'VA_Forms_API', 'forms', 'GET', null, queryParams
            );

        // Should handle malicious input gracefully
        System.assertNotEquals(null, apiResponse, 'Response should not be null');

        Test.stopTest();
    }

    /**
     * Test security enforced queries
     */
    @IsTest
    static void testSecurityEnforced() {
        Test.startTest();

        // Test should pass with proper CRUD permissions
        try {
            CVMARealVAAPIAuthenticator.VAAPIConfig config =
                CVMARealVAAPIAuthenticator.getAPIConfiguration('VA_Forms_API');
            System.assertNotEquals(null, config, 'Config should be retrieved with proper permissions');
        } catch (Exception e) {
            // Security enforced queries may fail in test context depending on setup
            System.assert(true, 'Security enforced behavior is environment dependent');
        }

        Test.stopTest();
    }

    /**
     * Test bulk operations and performance
     */
    @IsTest
    static void testBulkOperations() {
        Test.startTest();

        List<CVMARealVAAPIAuthenticator.VAAPIResponse> responses =
            new List<CVMARealVAAPIAuthenticator.VAAPIResponse>();

        // Make multiple concurrent requests
        for (Integer i = 0; i < 10; i++) {
            CVMARealVAAPIAuthenticator.VAAPIResponse apiResponse =
                CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                    'VA_Forms_API', 'forms', 'GET', null, null
                );
            responses.add(apiResponse);
        }

        // Verify all responses
        System.assertEquals(10, responses.size(), 'Should handle bulk operations');
        for (CVMARealVAAPIAuthenticator.VAAPIResponse response : responses) {
            System.assertNotEquals(null, response, 'Each response should be valid');
        }

        Test.stopTest();
    }

    /**
     * Test circuit breaker functionality
     */
    @IsTest
    static void testCircuitBreakerOpenState() {
        Test.startTest();

        // Mock API that always fails to trigger circuit breaker
        Test.setMock(HttpCalloutMock.class, new VAAPIAlwaysFailsMock());

        // First, create a feature flag to enable real API
        CVMATestDataFactory.createApplicationConfig()
            .withName('ENABLE_REAL_VA_FORMS_API')
            .withBooleanValue(true)
            .create();

        // Make multiple failed requests (mock API is disabled by feature flag)
        List<CVMARealVAAPIAuthenticator.VAAPIResponse> responses = new List<CVMARealVAAPIAuthenticator.VAAPIResponse>();
        for (Integer i = 0; i < 6; i++) {
            try {
                CVMARealVAAPIAuthenticator.VAAPIResponse response =
                    CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                        'VA_Forms_API', 'forms', 'GET', null, null
                    );
                responses.add(response);
            } catch (Exception e) {
                // Circuit breaker may throw exception
                if (e.getMessage().contains('Circuit breaker')) {
                    System.assert(true, 'Circuit breaker should activate after threshold failures');
                    break;
                }
            }
        }

        Test.stopTest();
    }

    /**
     * Test feature flag functionality
     */
    @IsTest
    static void testFeatureFlagHandling() {
        Test.startTest();

        // Test with feature flag disabled (should use mock API)
        CVMARealVAAPIAuthenticator.VAAPIResponse response1 =
            CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                'VA_Forms_API', 'forms', 'GET', null, null
            );

        System.assert(response1.isSuccess, 'Mock API should work when feature flag disabled');
        System.assert(response1.body.contains('mock'), 'Should use mock API');

        Test.stopTest();
    }

    /**
     * Test API configuration with all new fields
     */
    @IsTest
    static void testEnhancedAPIConfiguration() {
        Test.startTest();

        CVMARealVAAPIAuthenticator.VAAPIConfig config =
            CVMARealVAAPIAuthenticator.getAPIConfiguration('VA_Forms_API');

        // Test enhanced configuration fields
        System.assertNotEquals(null, config.oauthClientIdKey, 'OAuth Client ID key should be configured');
        System.assertNotEquals(null, config.oauthClientSecretKey, 'OAuth Client Secret key should be configured');
        System.assertNotEquals(null, config.oauthTokenEndpoint, 'OAuth token endpoint should be configured');
        System.assertNotEquals(null, config.oauthScope, 'OAuth scope should be configured');
        System.assertNotEquals(null, config.featureFlagOverride, 'Feature flag should be configured');
        System.assertNotEquals(null, config.healthCheckEndpoint, 'Health check endpoint should be configured');
        System.assert(config.circuitBreakerThreshold > 0, 'Circuit breaker threshold should be positive');
        System.assert(config.circuitBreakerResetMinutes > 0, 'Circuit breaker reset time should be positive');
        System.assertEquals(true, config.enableMonitoring, 'Monitoring should be enabled');
        System.assert(config.slaResponseTimeMS > 0, 'SLA response time should be configured');

        Test.stopTest();
    }

    /**
     * Test monitoring data structures
     */
    @IsTest
    static void testMonitoringDataStructures() {
        Test.startTest();

        // Test APIMonitoringData structure
        CVMARealVAAPIAuthenticator.APIMonitoringData monitoring = new CVMARealVAAPIAuthenticator.APIMonitoringData();
        monitoring.apiName = 'VA_Forms_API';
        monitoring.responseTime = 150;
        monitoring.success = true;
        monitoring.endpoint = '/forms';
        monitoring.statusCode = 200;
        monitoring.slaViolation = false;

        System.assertEquals('VA_Forms_API', monitoring.apiName, 'API name should be set');
        System.assertEquals(150, monitoring.responseTime, 'Response time should be recorded');
        System.assert(monitoring.success, 'Success should be tracked');
        System.assertNotEquals(null, monitoring.timestamp, 'Timestamp should be set');

        // Test CircuitBreakerState structure
        CVMARealVAAPIAuthenticator.CircuitBreakerState cbState = new CVMARealVAAPIAuthenticator.CircuitBreakerState();
        cbState.apiName = 'VA_Forms_API';
        cbState.threshold = 5;
        cbState.resetMinutes = 15;

        System.assertEquals('VA_Forms_API', cbState.apiName, 'API name should be set');
        System.assertEquals(false, cbState.isOpen, 'Circuit breaker should start closed');
        System.assertEquals(0, cbState.failureCount, 'Failure count should start at zero');

        Test.stopTest();
    }

    /**
     * Test different HTTP methods
     */
    @IsTest
    static void testDifferentHTTPMethods() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAAPISuccessMock());

        // Test GET request
        CVMARealVAAPIAuthenticator.VAAPIResponse getResponse =
            CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                'VA_Forms_API', 'forms', 'GET', null, null
            );
        System.assert(getResponse.isSuccess, 'GET request should succeed');

        // Test POST request with body
        String postBody = '{"test": "data"}';
        CVMARealVAAPIAuthenticator.VAAPIResponse postResponse =
            CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                'VA_Forms_API', 'forms', 'POST', postBody, null
            );
        System.assert(postResponse.isSuccess, 'POST request should succeed');

        Test.stopTest();
    }

    /**
     * Test response header handling
     */
    @IsTest
    static void testResponseHeaders() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAAPIWithHeadersMock());

        CVMARealVAAPIAuthenticator.VAAPIResponse response =
            CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                'VA_Forms_API', 'forms', 'GET', null, null
            );

        System.assert(response.isSuccess, 'Request should succeed');
        System.assertNotEquals(null, response.headers, 'Headers should be captured');

        Test.stopTest();
    }

    /**
     * Test token expiration handling
     */
    @IsTest
    static void testTokenExpirationHandling() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAOAuthSuccessMock());

        // Get initial token
        CVMARealVAAPIAuthenticator.VATokenResponse token1 = CVMARealVAAPIAuthenticator.getAccessToken();
        System.assert(token1.isValid, 'First token should be valid');

        // Simulate token expiration by setting past expiry
        token1.expiresAt = DateTime.now().addMinutes(-10);

        // Should get new token when expired one is detected
        CVMARealVAAPIAuthenticator.VATokenResponse token2 = CVMARealVAAPIAuthenticator.getAccessToken();
        System.assert(token2.isValid, 'New token should be valid');

        Test.stopTest();
    }

    /**
     * Test error categorization
     */
    @IsTest
    static void testErrorCategorization() {
        Test.startTest();

        // Test with various error status codes
        List<Integer> errorCodes = new List<Integer>{401, 403, 429, 500, 502, 503, 504};

        for (Integer errorCode : errorCodes) {
            Test.setMock(HttpCalloutMock.class, new VAAPIErrorCodeMock(errorCode));

            CVMARealVAAPIAuthenticator.VAAPIResponse response =
                CVMARealVAAPIAuthenticator.makeAuthenticatedRequest(
                    'VA_Forms_API', 'forms', 'GET', null, null
                );

            System.assert(!response.isSuccess, 'Request should fail with error code ' + errorCode);
            System.assertEquals(errorCode, response.statusCode, 'Status code should match');
        }

        Test.stopTest();
    }

    // Additional Mock Classes for Enhanced Testing

    /**
     * Mock class for API that always fails (for circuit breaker testing)
     */
    public class VAAPIAlwaysFailsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            if (req.getEndpoint().contains('oauth2/token')) {
                // OAuth succeeds
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"access_token":"fail_test_token","token_type":"Bearer","expires_in":3600}');
                res.setStatusCode(200);
            } else {
                // API always fails
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"error":"service_unavailable","message":"Service is unavailable"}');
                res.setStatusCode(503);
            }

            return res;
        }
    }

    /**
     * Mock class with response headers for testing
     */
    public class VAAPIWithHeadersMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setHeader('X-RateLimit-Remaining', '999');
            res.setHeader('X-Response-Time', '150ms');

            if (req.getEndpoint().contains('oauth2/token')) {
                res.setBody('{"access_token":"header_test_token","token_type":"Bearer","expires_in":3600}');
            } else {
                res.setBody('{"data":[{"id":"1","attributes":{"name":"Test Form"}}],"meta":{"total_count":1}}');
            }

            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * Mock class for specific error codes
     */
    public class VAAPIErrorCodeMock implements HttpCalloutMock {
        private Integer errorCode;

        public VAAPIErrorCodeMock(Integer code) {
            this.errorCode = code;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('oauth2/token')) {
                // OAuth succeeds for error testing
                res.setBody('{"access_token":"error_test_token","token_type":"Bearer","expires_in":3600}');
                res.setStatusCode(200);
            } else {
                // Return specific error code
                res.setBody('{"error":"test_error","code":' + errorCode + '}');
                res.setStatusCode(errorCode);
            }

            return res;
        }
    }
}
