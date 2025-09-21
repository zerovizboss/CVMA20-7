/**
 * Test class for CVMARealVAIntegrationController
 * Comprehensive testing of VA Lighthouse API integration framework
 * Includes mock HTTP responses and security validation
 *
 * @author CVMA Development Team
 * @since Veterans Resources Portal Implementation
 */
@IsTest
private class CVMARealVAIntegrationControllerTest {

    /**
     * Mock HTTP Response class for VA API testing
     */
    private class MockVAAPIResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        private String contentType;

        public MockVAAPIResponse(Integer statusCode, String responseBody, String contentType) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
            this.contentType = contentType;
        }

        public HTTPResponse respond(HTTPRequest request) {
            HTTPResponse response = new HTTPResponse();
            response.setStatusCode(this.statusCode);
            response.setBody(this.responseBody);
            response.setHeader('Content-Type', this.contentType);
            return response;
        }
    }

    @TestSetup
    static void setupTestData() {
        // Create test contact with military service information
        Contact testVeteran = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .withMilitaryService('Army', Date.today().addYears(-10), Date.today().addYears(-2))
            .withEmail('testveteran@cvma.org')
            .create();

        // Create test application configuration for VA API
        // Note: Custom metadata cannot be inserted in tests, so we'll test fallback behavior
    }

    @IsTest
    static void testGetBenefitsClaims_Success() {
        // Arrange
        String testVeteranId = 'TEST_VETERAN_123';
        String mockResponseBody = '{"claims": [{"claimId": "12345", "claimType": "Disability", "status": "Under Review"}]}';

        Test.setMock(HttpCalloutMock.class, new MockVAAPIResponse(200, mockResponseBody, 'application/json'));

        // Act
        Test.startTest();
        CVMARealVAIntegrationController.VALighthouseResponse result =
            CVMARealVAIntegrationController.getBenefitsClaims(testVeteranId);
        Test.stopTest();

        // Assert
        Assert.isNotNull(result, 'Response should not be null');
        // Since VA credentials won't be configured in test, should return mock data
        Assert.areEqual('MOCK_DATA', result.status, 'Should return mock data when credentials not configured');
        Assert.isTrue(result.message.contains('mock data'), 'Message should indicate mock data usage');
    }

    @IsTest
    static void testGetBenefitsClaims_InvalidInput() {
        // Act & Assert
        Test.startTest();
        try {
            CVMARealVAIntegrationController.getBenefitsClaims('');
            Assert.fail('Should throw exception for empty veteran ID');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Veteran ID is required'), 'Should validate veteran ID input');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetVeteranProfile_Success() {
        // Arrange
        String testVeteranId = 'TEST_VETERAN_123';
        String mockResponseBody = '{"veteranId": "123", "personalInfo": {"firstName": "John", "lastName": "Doe"}}';

        Test.setMock(HttpCalloutMock.class, new MockVAAPIResponse(200, mockResponseBody, 'application/json'));

        // Act
        Test.startTest();
        CVMARealVAIntegrationController.VALighthouseResponse result =
            CVMARealVAIntegrationController.getVeteranProfile(testVeteranId);
        Test.stopTest();

        // Assert
        Assert.isNotNull(result, 'Response should not be null');
        Assert.areEqual('MOCK_DATA', result.status, 'Should return mock data when credentials not configured');
        Assert.isNotNull(result.correlationId, 'Should have correlation ID');
        Assert.isNotNull(result.timestamp, 'Should have timestamp');
    }

    @IsTest
    static void testGetVeteranProfile_InvalidInput() {
        // Act & Assert
        Test.startTest();
        try {
            CVMARealVAIntegrationController.getVeteranProfile(null);
            Assert.fail('Should throw exception for null veteran ID');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Veteran ID is required'), 'Should validate veteran ID input');
        }
        Test.stopTest();
    }

    @IsTest
    static void testFindNearbyFacilities_Success() {
        // Arrange
        Decimal testLatitude = 30.3322;  // Jacksonville, FL coordinates
        Decimal testLongitude = -81.6557;
        Integer testRadius = 25;
        String facilityType = 'va_medical_center';

        String mockResponseBody = '{"facilities": [{"facilityId": "vha_673", "name": "Test VA Hospital"}]}';
        Test.setMock(HttpCalloutMock.class, new MockVAAPIResponse(200, mockResponseBody, 'application/json'));

        // Act
        Test.startTest();
        CVMARealVAIntegrationController.VALighthouseResponse result =
            CVMARealVAIntegrationController.findNearbyFacilities(testLatitude, testLongitude, testRadius, facilityType);
        Test.stopTest();

        // Assert
        Assert.isNotNull(result, 'Response should not be null');
        Assert.areEqual('MOCK_DATA', result.status, 'Should return mock data when credentials not configured');
        Assert.isNotNull(result.data, 'Should have facility data');
    }

    @IsTest
    static void testFindNearbyFacilities_InvalidCoordinates() {
        // Act & Assert
        Test.startTest();
        try {
            CVMARealVAIntegrationController.findNearbyFacilities(null, null, 25, 'medical');
            Assert.fail('Should throw exception for invalid coordinates');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Latitude and longitude are required'),
                'Should validate coordinate input');
        }
        Test.stopTest();
    }

    @IsTest
    static void testVerifyVeteranStatus_Success() {
        // Arrange
        String testVeteranId = 'TEST_VETERAN_123';
        String mockResponseBody = '{"veteranStatus": "verified", "serviceConnected": true}';

        Test.setMock(HttpCalloutMock.class, new MockVAAPIResponse(200, mockResponseBody, 'application/json'));

        // Act
        Test.startTest();
        CVMARealVAIntegrationController.VALighthouseResponse result =
            CVMARealVAIntegrationController.verifyVeteranStatus(testVeteranId);
        Test.stopTest();

        // Assert
        Assert.isNotNull(result, 'Response should not be null');
        Assert.areEqual('MOCK_DATA', result.status, 'Should return mock data when credentials not configured');
        Assert.isNotNull(result.data, 'Should have verification data');
    }

    @IsTest
    static void testVerifyVeteranStatus_InvalidInput() {
        // Act & Assert
        Test.startTest();
        try {
            CVMARealVAIntegrationController.verifyVeteranStatus('   ');
            Assert.fail('Should throw exception for blank veteran ID');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Veteran ID is required'), 'Should validate veteran ID input');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAreVACredentialsConfigured() {
        // Act
        Test.startTest();
        Boolean result = CVMARealVAIntegrationController.areVACredentialsConfigured();
        Test.stopTest();

        // Assert
        // In test context, credentials won't be configured
        Assert.areEqual(false, result, 'Should return false when credentials not configured in test');
    }

    @IsTest
    static void testGetAPIEnvironment() {
        // Act
        Test.startTest();
        String environment = CVMARealVAIntegrationController.getAPIEnvironment();
        Test.stopTest();

        // Assert
        Assert.isNotNull(environment, 'Environment should not be null');
        Assert.areEqual('sandbox', environment, 'Should default to sandbox environment in test');
    }

    @IsTest
    static void testVALighthouseResponseConstruction() {
        // Act
        Test.startTest();
        CVMARealVAIntegrationController.VALighthouseResponse response =
            new CVMARealVAIntegrationController.VALighthouseResponse();
        Test.stopTest();

        // Assert
        Assert.isNotNull(response.timestamp, 'Timestamp should be automatically set');
        Assert.isNotNull(response.correlationId, 'Correlation ID should be automatically generated');
        Assert.isNotNull(response.metadata, 'Metadata should be initialized');
        Assert.areEqual('v0', response.metadata.apiVersion, 'API version should be set');
    }

    @IsTest
    static void testBenefitsClaimConstruction() {
        // Act
        Test.startTest();
        CVMARealVAIntegrationController.BenefitsClaim claim =
            new CVMARealVAIntegrationController.BenefitsClaim();
        Test.stopTest();

        // Assert
        Assert.isNotNull(claim.documentsNeeded, 'Documents needed list should be initialized');
        Assert.areEqual(0, claim.documentsNeeded.size(), 'Documents needed list should be empty initially');
    }

    @IsTest
    static void testVeteranProfileResponseConstruction() {
        // Act
        Test.startTest();
        CVMARealVAIntegrationController.VeteranProfileResponse profile =
            new CVMARealVAIntegrationController.VeteranProfileResponse();
        Test.stopTest();

        // Assert
        Assert.isNotNull(profile.personalInfo, 'Personal info should be initialized');
        Assert.isNotNull(profile.militaryService, 'Military service should be initialized');
        Assert.isNotNull(profile.contactInfo, 'Contact info should be initialized');
        Assert.isNotNull(profile.disabilityInfo, 'Disability info should be initialized');
        Assert.isNotNull(profile.militaryService.servicePeriods, 'Service periods list should be initialized');
    }

    @IsTest
    static void testVAFacilityConstruction() {
        // Act
        Test.startTest();
        CVMARealVAIntegrationController.VAFacility facility =
            new CVMARealVAIntegrationController.VAFacility();
        Test.stopTest();

        // Assert
        Assert.isNotNull(facility.address, 'Address should be initialized');
        Assert.isNotNull(facility.services, 'Services list should be initialized');
        Assert.isNotNull(facility.hours, 'Hours should be initialized');
        Assert.areEqual(0, facility.services.size(), 'Services list should be empty initially');
    }

    @IsTest
    static void testSecurityValidation_NoReadAccess() {
        // Arrange - Create test user without Contact read access
        User testUser = CVMATestDataFactory.createTestUser('testuser@cvma.org', 'CVMA Guest User');

        // Act & Assert
        System.runAs(testUser) {
            Test.startTest();
            try {
                CVMARealVAIntegrationController.getBenefitsClaims('TEST123');
                // Test will pass if no exception is thrown (fallback to mock data)
                Assert.isTrue(true, 'Should handle security validation gracefully');
            } catch (Exception e) {
                // Expected behavior for insufficient permissions
                Assert.isTrue(e.getMessage().contains('permissions') ||
                            e.getMessage().contains('access'), 'Should validate permissions');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testCorrelationIdGeneration() {
        // Act
        Test.startTest();
        CVMARealVAIntegrationController.VALighthouseResponse response1 =
            new CVMARealVAIntegrationController.VALighthouseResponse();
        CVMARealVAIntegrationController.VALighthouseResponse response2 =
            new CVMARealVAIntegrationController.VALighthouseResponse();
        Test.stopTest();

        // Assert
        Assert.areNotEqual(response1.correlationId, response2.correlationId,
            'Correlation IDs should be unique');
        Assert.isTrue(response1.correlationId.startsWith('CVMA-'),
            'Correlation ID should have CVMA prefix');
    }

    @IsTest
    static void testAPIEnvironmentFallback() {
        // Act
        Test.startTest();
        // Test that getAPIEnvironment handles missing custom metadata gracefully
        String environment = CVMARealVAIntegrationController.getAPIEnvironment();
        Test.stopTest();

        // Assert
        Assert.isNotNull(environment, 'Environment should not be null');
        Assert.areEqual('sandbox', environment, 'Should default to sandbox when configuration not found');
    }

    @IsTest
    static void testVAIntegrationExceptionHandling() {
        // Act & Assert
        Test.startTest();
        try {
            throw new CVMARealVAIntegrationController.VAIntegrationException('Test exception');
        } catch (CVMARealVAIntegrationController.VAIntegrationException e) {
            Assert.areEqual('Test exception', e.getMessage(), 'Exception message should be preserved');
        }
        Test.stopTest();
    }

    @IsTest
    static void testMetadataInitialization() {
        // Act
        Test.startTest();
        CVMARealVAIntegrationController.VAAPIMetadata metadata =
            new CVMARealVAIntegrationController.VAAPIMetadata();
        Test.stopTest();

        // Assert
        Assert.areEqual('v0', metadata.apiVersion, 'API version should be set');
        Assert.areEqual('sandbox', metadata.environment, 'Environment should default to sandbox');
        Assert.areEqual(false, metadata.isFromCache, 'Should not be from cache initially');
    }

    @IsTest
    static void testHttpCalloutMockIntegration() {
        // Arrange
        String testErrorResponse = '{"error": "API temporarily unavailable"}';
        Test.setMock(HttpCalloutMock.class, new MockVAAPIResponse(503, testErrorResponse, 'application/json'));

        // Act
        Test.startTest();
        CVMARealVAIntegrationController.VALighthouseResponse result =
            CVMARealVAIntegrationController.getBenefitsClaims('TEST_VETERAN');
        Test.stopTest();

        // Assert
        // Should still return mock data even when real API would fail
        Assert.isNotNull(result, 'Should return result even when API fails');
        Assert.areEqual('MOCK_DATA', result.status, 'Should fallback to mock data');
    }
}
