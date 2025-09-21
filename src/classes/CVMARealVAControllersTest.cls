/**
 * CVMARealVAControllersTest
 * Comprehensive test class for remaining VA API controllers:
 * - CVMARealVAFacilitiesController
 * - CVMAAddressValidationController
 * - Updated CVMAEpic8Phase3Controller
 *
 * @author CVMA Development Team
 * @since Epic #8 VA Lighthouse API Integration
 * @version 1.0.0
 */
@IsTest
private class CVMARealVAControllersTest {

    /**
     * Test data setup
     */
    @TestSetup
    static void makeData() {
        // Create test contacts using factory
        Contact testMember = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .withMilitary('Army', Date.today().addYears(-10), Date.today().addYears(-2))
            .withMailingAddress('123 Test St', 'Jacksonville', 'FL', '32204')
            .create();

        // Set coordinates for testing
        testMember.MailingLatitude = 30.3322;
        testMember.MailingLongitude = -81.6557;
        update testMember;
    }

    // ==================== VA Facilities Controller Tests ====================

    /**
     * Test VA facilities search success
     */
    @IsTest
    static void testSearchFacilities_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAFacilitiesSuccessMock());

        CVMARealVAFacilitiesController.VAFacilitySearchResponse searchResponse =
            CVMARealVAFacilitiesController.searchFacilities(
                '32204', 'FL', 'Jacksonville', 30.3322, -81.6557, 50,
                new List<String>{'health'}, new List<String>{'Healthcare'}, 20
            );

        System.assertEquals(true, searchResponse.isSuccess, 'Facilities search should be successful');
        System.assertNotEquals(null, searchResponse.facilities, 'Facilities list should not be null');
        System.assertEquals('32204', searchResponse.searchLocation, 'Search location should match');

        Test.stopTest();
    }

    /**
     * Test get facility by ID
     */
    @IsTest
    static void testGetFacilityById_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAFacilityDetailMock());

        CVMARealVAFacilitiesController.VAFacility facility =
            CVMARealVAFacilitiesController.getFacilityById('vha_12345');

        System.assertNotEquals(null, facility, 'Facility should not be null');
        System.assertEquals('vha_12345', facility.id, 'Facility ID should match');
        System.assertNotEquals(null, facility.name, 'Facility name should be set');

        Test.stopTest();
    }

    /**
     * Test member facility context
     */
    @IsTest
    static void testGetMemberFacilityContext_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAFacilitiesSuccessMock());

        Contact testMember = [SELECT Id FROM Contact LIMIT 1];

        CVMARealVAFacilitiesController.MemberLocationContext context =
            CVMARealVAFacilitiesController.getMemberFacilityContext(
                testMember.Id, new List<String>{'Healthcare'}
            );

        System.assertNotEquals(null, context, 'Context should not be null');
        System.assertNotEquals(null, context.memberName, 'Member name should be set');
        System.assertNotEquals(null, context.nearbyFacilities, 'Nearby facilities should be set');

        Test.stopTest();
    }

    /**
     * Test get facility types
     */
    @IsTest
    static void testGetFacilityTypes() {
        Test.startTest();

        Map<String, String> types = CVMARealVAFacilitiesController.getFacilityTypes();

        System.assertNotEquals(null, types, 'Facility types should not be null');
        System.assert(types.size() > 0, 'Should have facility types defined');

        Test.stopTest();
    }

    /**
     * Test emergency facilities
     */
    @IsTest
    static void testGetEmergencyFacilities_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAEmergencyFacilitiesMock());

        List<CVMARealVAFacilitiesController.VAFacility> emergencyFacilities =
            CVMARealVAFacilitiesController.getEmergencyFacilities('32204', 30.3322, -81.6557);

        System.assertNotEquals(null, emergencyFacilities, 'Emergency facilities should not be null');

        Test.stopTest();
    }

    // ==================== Address Validation Controller Tests ====================

    /**
     * Test address validation success
     */
    @IsTest
    static void testValidateAddress_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAAddressValidationSuccessMock());

        CVMAAddressValidationController.AddressValidationRequest request =
            new CVMAAddressValidationController.AddressValidationRequest();
        request.street = '123 Test Street';
        request.city = 'Jacksonville';
        request.state = 'FL';
        request.zipCode = '32204';

        CVMAAddressValidationController.AddressValidationResponse response =
            CVMAAddressValidationController.validateAddress(request);

        System.assertEquals(true, response.isSuccess, 'Address validation should be successful');
        System.assertNotEquals(null, response.validatedAddress, 'Validated address should not be null');
        System.assert(response.confidenceScore >= 0, 'Confidence score should be set');

        Test.stopTest();
    }

    /**
     * Test member address validation
     */
    @IsTest
    static void testValidateMemberAddresses_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAAddressValidationSuccessMock());

        Contact testMember = [SELECT Id FROM Contact LIMIT 1];

        CVMAAddressValidationController.MemberAddressContext context =
            CVMAAddressValidationController.validateMemberAddresses(testMember.Id);

        System.assertNotEquals(null, context, 'Address context should not be null');
        System.assertNotEquals(null, context.memberName, 'Member name should be set');
        System.assertNotEquals(null, context.addressRecommendations, 'Recommendations should be set');

        Test.stopTest();
    }

    /**
     * Test batch address validation
     */
    @IsTest
    static void testValidateAddressesBatch_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAAddressValidationSuccessMock());

        List<CVMAAddressValidationController.AddressValidationRequest> requests =
            new List<CVMAAddressValidationController.AddressValidationRequest>();

        CVMAAddressValidationController.AddressValidationRequest request =
            new CVMAAddressValidationController.AddressValidationRequest();
        request.street = '123 Test Street';
        request.city = 'Jacksonville';
        request.state = 'FL';
        request.zipCode = '32204';
        requests.add(request);

        CVMAAddressValidationController.BatchValidationResult result =
            CVMAAddressValidationController.validateAddressesBatch(requests);

        System.assertEquals(true, result.isSuccess, 'Batch validation should be successful');
        System.assertEquals(1, result.totalProcessed, 'Should process one address');

        Test.stopTest();
    }

    /**
     * Test apply address correction
     */
    @IsTest
    static void testApplyAddressCorrection_Success() {
        Test.startTest();

        Contact testMember = [SELECT Id FROM Contact LIMIT 1];

        CVMAAddressValidationController.ValidatedAddress validatedAddress =
            new CVMAAddressValidationController.ValidatedAddress();
        validatedAddress.street = '123 Corrected Street';
        validatedAddress.city = 'Jacksonville';
        validatedAddress.state = 'FL';
        validatedAddress.zipCode = '32204';
        validatedAddress.country = 'United States';

        Boolean result = CVMAAddressValidationController.applyAddressCorrection(
            testMember.Id, validatedAddress, 'mailing'
        );

        System.assertEquals(true, result, 'Address correction should be successful');

        Test.stopTest();
    }

    // ==================== Epic 8 Phase 3 Controller Tests ====================

    /**
     * Test Epic 8 Phase 3 dashboard
     */
    @IsTest
    static void testGetEpic8Phase3Dashboard_Success() {
        Test.startTest();

        Map<String, Object> dashboard = CVMAEpic8Phase3Controller.getEpic8Phase3Dashboard();

        System.assertNotEquals(null, dashboard, 'Dashboard should not be null');
        System.assertEquals('Active', dashboard.get('phase3_status'), 'Phase 3 should be active');

        Test.stopTest();
    }

    /**
     * Test enhanced member services with VA API integration
     */
    @IsTest
    static void testGetEnhancedMemberServices_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAIntegratedServicesMock());

        Contact testMember = [SELECT Id FROM Contact LIMIT 1];

        Map<String, Object> services = CVMAEpic8Phase3Controller.getEnhancedMemberServices(testMember.Id);

        System.assertNotEquals(null, services, 'Services should not be null');
        System.assertNotEquals(null, services.get('member_profile'), 'Member profile should be set');
        System.assertNotEquals(null, services.get('api_integration_status'), 'API status should be set');

        Test.stopTest();
    }

    /**
     * Test VA API integration dashboard
     */
    @IsTest
    static void testGetVAAPIIntegrationDashboard_Success() {
        Test.startTest();

        Map<String, Object> dashboard = CVMAEpic8Phase3Controller.getVAAPIIntegrationDashboard();

        System.assertNotEquals(null, dashboard, 'Dashboard should not be null');
        System.assertNotEquals(null, dashboard.get('api_status'), 'API status should be set');
        System.assertNotEquals(null, dashboard.get('integration_health'), 'Integration health should be set');

        Test.stopTest();
    }

    /**
     * Test member VA forms integration
     */
    @IsTest
    static void testGetMemberVAFormsIntegration_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAIntegratedServicesMock());

        Contact testMember = [SELECT Id FROM Contact LIMIT 1];

        Map<String, Object> formsIntegration =
            CVMAEpic8Phase3Controller.getMemberVAFormsIntegration(testMember.Id);

        System.assertNotEquals(null, formsIntegration, 'Forms integration should not be null');
        System.assertEquals('Connected', formsIntegration.get('integration_status'), 'Should be connected');

        Test.stopTest();
    }

    /**
     * Test member VA facilities integration
     */
    @IsTest
    static void testGetMemberVAFacilitiesIntegration_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAIntegratedServicesMock());

        Contact testMember = [SELECT Id FROM Contact LIMIT 1];

        Map<String, Object> facilitiesIntegration =
            CVMAEpic8Phase3Controller.getMemberVAFacilitiesIntegration(testMember.Id);

        System.assertNotEquals(null, facilitiesIntegration, 'Facilities integration should not be null');
        System.assertEquals('Connected', facilitiesIntegration.get('integration_status'), 'Should be connected');

        Test.stopTest();
    }

    /**
     * Test member address validation integration
     */
    @IsTest
    static void testGetMemberAddressValidationIntegration_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAIntegratedServicesMock());

        Contact testMember = [SELECT Id FROM Contact LIMIT 1];

        Map<String, Object> addressIntegration =
            CVMAEpic8Phase3Controller.getMemberAddressValidationIntegration(testMember.Id);

        System.assertNotEquals(null, addressIntegration, 'Address integration should not be null');
        System.assertEquals('Connected', addressIntegration.get('integration_status'), 'Should be connected');

        Test.stopTest();
    }

    // ==================== Error Handling Tests ====================

    /**
     * Test error handling across all controllers
     */
    @IsTest
    static void testErrorHandling() {
        Test.startTest();

        // Test invalid member ID
        try {
            CVMARealVAFacilitiesController.getMemberFacilityContext(null, null);
            System.assert(false, 'Should throw exception for null member ID');
        } catch (Exception e) {
            System.assert(true, 'Exception handling is working');
        }

        // Test invalid address validation
        try {
            CVMAAddressValidationController.AddressValidationRequest request =
                new CVMAAddressValidationController.AddressValidationRequest();
            CVMAAddressValidationController.validateAddress(request);
            System.assert(false, 'Should throw exception for incomplete address');
        } catch (Exception e) {
            System.assert(true, 'Exception handling is working');
        }

        Test.stopTest();
    }

    /**
     * Test input sanitization across controllers
     */
    @IsTest
    static void testInputSanitization() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAIntegratedServicesMock());

        String maliciousInput = '<script>alert("xss")</script>';

        // Test facilities search with malicious input
        CVMARealVAFacilitiesController.VAFacilitySearchResponse facilityResponse =
            CVMARealVAFacilitiesController.searchFacilities(
                maliciousInput, null, null, null, null, null, null, null, null
            );

        System.assertNotEquals(null, facilityResponse, 'Should handle malicious input gracefully');

        Test.stopTest();
    }

    // ==================== Mock Classes ====================

    /**
     * Mock for VA Facilities API success response
     */
    public class VAFacilitiesSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('oauth2/token')) {
                res.setBody('{"access_token":"mock_token","token_type":"Bearer","expires_in":3600}');
            } else {
                String responseBody = '{"data":[{' +
                    '"id":"vha_12345",' +
                    '"attributes":{' +
                        '"name":"Test VA Medical Center",' +
                        '"facility_type":"health",' +
                        '"classification":"VA Medical Center",' +
                        '"phone_number":"(904) 555-0000",' +
                        '"website":"https://www.va.gov/test",' +
                        '"address":{"physical":{"address_1":"123 VA Street","city":"Jacksonville","state":"FL","zip":"32204"}},' +
                        '"lat_long":{"lat":30.3322,"long":-81.6557},' +
                        '"services":["Healthcare","Emergency"],' +
                        '"hours":{"monday":"8:00-17:00","tuesday":"8:00-17:00"}' +
                    '}}],' +
                    '"meta":{"total_count":1}}';
                res.setBody(responseBody);
            }

            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * Mock for VA Facility detail response
     */
    public class VAFacilityDetailMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            String responseBody = '{"data":{' +
                '"id":"vha_12345",' +
                '"attributes":{' +
                    '"name":"Test VA Medical Center",' +
                    '"facility_type":"health",' +
                    '"classification":"VA Medical Center",' +
                    '"phone_number":"(904) 555-0000",' +
                    '"website":"https://www.va.gov/test",' +
                    '"address":{"physical":{"address_1":"123 VA Street","city":"Jacksonville","state":"FL","zip":"32204"}},' +
                    '"lat_long":{"lat":30.3322,"long":-81.6557},' +
                    '"services":["Healthcare","Emergency"]' +
                '}}}';

            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * Mock for emergency facilities response
     */
    public class VAEmergencyFacilitiesMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            String responseBody = '{"data":[{' +
                '"id":"vha_emergency",' +
                '"attributes":{' +
                    '"name":"Emergency VA Center",' +
                    '"facility_type":"health",' +
                    '"services":["Emergency"],' +
                    '"lat_long":{"lat":30.3322,"long":-81.6557}' +
                '}}]}';

            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * Mock for address validation success response
     */
    public class VAAddressValidationSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('oauth2/token')) {
                res.setBody('{"access_token":"mock_token","token_type":"Bearer","expires_in":3600}');
            } else {
                String responseBody = '{' +
                    '"address":{' +
                        '"addressLine1":"123 Test Street",' +
                        '"city":"Jacksonville",' +
                        '"stateProvince":"FL",' +
                        '"zipCode5":"32204",' +
                        '"zipCode4":"1234",' +
                        '"county":"Duval",' +
                        '"country":"United States",' +
                        '"coordinates":{"latitude":30.3322,"longitude":-81.6557},' +
                        '"deliverability":{"status":"DELIVERABLE","analysis":"Address is deliverable"}' +
                    '},' +
                    '"validation":{' +
                        '"confidence":95.5,' +
                        '"status":"CONFIRMED",' +
                        '"messages":["Address validated successfully"]' +
                    '}}';
                res.setBody(responseBody);
            }

            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * Mock for integrated VA services response
     */
    public class VAIntegratedServicesMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (req.getEndpoint().contains('oauth2/token')) {
                res.setBody('{"access_token":"mock_token","token_type":"Bearer","expires_in":3600}');
            } else if (req.getEndpoint().contains('forms')) {
                res.setBody('{"data":[{"id":"21-526EZ","attributes":{"form_name":"21-526EZ","title":"Disability Form"}}]}');
            } else if (req.getEndpoint().contains('facilities')) {
                res.setBody('{"data":[{"id":"vha_123","attributes":{"name":"Test Facility","facility_type":"health"}}]}');
            } else if (req.getEndpoint().contains('validate')) {
                res.setBody('{"address":{"addressLine1":"123 Test St"},"validation":{"confidence":90,"status":"CONFIRMED"}}');
            } else {
                res.setBody('{"mock":true,"status":"success"}');
            }

            res.setStatusCode(200);
            return res;
        }
    }

    /**
     * Test bulk operations across all controllers
     */
    @IsTest
    static void testBulkOperations() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAIntegratedServicesMock());

        Contact testMember = [SELECT Id FROM Contact LIMIT 1];

        // Test multiple concurrent operations
        List<Map<String, Object>> results = new List<Map<String, Object>>();

        for (Integer i = 0; i < 3; i++) {
            Map<String, Object> services = CVMAEpic8Phase3Controller.getEnhancedMemberServices(testMember.Id);
            results.add(services);
        }

        System.assertEquals(3, results.size(), 'Should handle bulk operations');

        Test.stopTest();
    }

    /**
     * Test caching across controllers
     */
    @IsTest
    static void testCaching() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new VAIntegratedServicesMock());

        // Test API configuration caching
        CVMARealVAAPIAuthenticator.VAAPIConfig config1 =
            CVMARealVAAPIAuthenticator.getAPIConfiguration('VA_Forms_API');
        CVMARealVAAPIAuthenticator.VAAPIConfig config2 =
            CVMARealVAAPIAuthenticator.getAPIConfiguration('VA_Forms_API');

        System.assertEquals(config1.apiName, config2.apiName, 'Cached config should match');

        Test.stopTest();
    }
}
