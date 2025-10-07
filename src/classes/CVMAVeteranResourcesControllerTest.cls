@IsTest
private class CVMAVeteranResourcesControllerTest {

    @IsTest
    static void testGetVeteranOrganizations() {
        Test.startTest();
        List<CVMAVeteranResourcesController.VeteranOrganization> organizations =
            CVMAVeteranResourcesController.getVeteranOrganizations();
        Test.stopTest();

        System.assertNotEquals(null, organizations, 'Organizations list should not be null');
        System.assert(organizations.size() > 0, 'Should return at least one organization');

        // Verify organization structure
        CVMAVeteranResourcesController.VeteranOrganization org = organizations[0];
        System.assertNotEquals(null, org.id, 'Organization should have ID');
        System.assertNotEquals(null, org.organizationName, 'Organization should have name');
        System.assertNotEquals(null, org.serviceCategory, 'Organization should have category');
    }

    @IsTest
    static void testCheckEligibilityK9Warriors() {
        Map<String, Object> veteranData = new Map<String, Object>{
            'serviceConnectedDisability' => true,
            'disabilityRating' => 70,
            'branch' => 'Army',
            'combatVeteran' => true,
            'state' => 'FL'
        };

        Test.startTest();
        List<CVMAVeteranResourcesController.EligibilityResult> results =
            CVMAVeteranResourcesController.checkEligibility('k9-warriors', veteranData);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Eligibility results should not be null');
        System.assertEquals(1, results.size(), 'Should return one eligibility result');

        CVMAVeteranResourcesController.EligibilityResult result = results[0];
        System.assertEquals('Service Dog Program', result.program, 'Should be Service Dog Program');
        System.assertEquals('Highly Eligible', result.eligibilityStatus, 'Combat veteran with 70% should be highly eligible');
        System.assertEquals('success', result.statusVariant, 'Variant should be success');
    }

    @IsTest
    static void testCheckEligibilityWWP() {
        Map<String, Object> veteranData = new Map<String, Object>{
            'serviceConnectedDisability' => true,
            'disabilityRating' => 50,
            'branch' => 'Marines',
            'combatVeteran' => true,
            'state' => 'TX'
        };

        Test.startTest();
        List<CVMAVeteranResourcesController.EligibilityResult> results =
            CVMAVeteranResourcesController.checkEligibility('wounded-warrior-project', veteranData);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Eligibility results should not be null');
        System.assertEquals(1, results.size(), 'Should return one eligibility result');

        CVMAVeteranResourcesController.EligibilityResult result = results[0];
        System.assertEquals('WWP Programs', result.program, 'Should be WWP Programs');
        System.assertEquals('Eligible', result.eligibilityStatus, 'Service-connected veteran should be eligible');
    }

    @IsTest
    static void testCheckEligibilityHomesForHeroes() {
        Map<String, Object> veteranData = new Map<String, Object>{
            'serviceConnectedDisability' => false,
            'disabilityRating' => 0,
            'branch' => 'Navy',
            'combatVeteran' => false,
            'state' => 'CA'
        };

        Test.startTest();
        List<CVMAVeteranResourcesController.EligibilityResult> results =
            CVMAVeteranResourcesController.checkEligibility('homes-for-heroes', veteranData);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Eligibility results should not be null');
        System.assertEquals(1, results.size(), 'Should return one eligibility result');

        CVMAVeteranResourcesController.EligibilityResult result = results[0];
        System.assertEquals('Real Estate Rewards', result.program, 'Should be Real Estate Rewards');
        System.assertEquals('Eligible', result.eligibilityStatus, 'All veterans eligible for Homes for Heroes');
    }

    @IsTest
    static void testCheckEligibilityTunnelToTowers() {
        Map<String, Object> veteranData = new Map<String, Object>{
            'serviceConnectedDisability' => true,
            'disabilityRating' => 100,
            'branch' => 'Army',
            'combatVeteran' => true,
            'state' => 'NY'
        };

        Test.startTest();
        List<CVMAVeteranResourcesController.EligibilityResult> results =
            CVMAVeteranResourcesController.checkEligibility('tunnel-to-towers', veteranData);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Eligibility results should not be null');
        System.assertEquals(1, results.size(), 'Should return one eligibility result');

        CVMAVeteranResourcesController.EligibilityResult result = results[0];
        System.assertEquals('Smart Home Program', result.program, 'Should be Smart Home Program');
        System.assertEquals('Highly Eligible', result.eligibilityStatus, '100% disabled veteran should be highly eligible');
    }

    @IsTest
    static void testCheckEligibilityDefaultOrganization() {
        Map<String, Object> veteranData = new Map<String, Object>{
            'serviceConnectedDisability' => false,
            'disabilityRating' => 0,
            'branch' => 'Air Force',
            'combatVeteran' => false,
            'state' => 'FL'
        };

        Test.startTest();
        List<CVMAVeteranResourcesController.EligibilityResult> results =
            CVMAVeteranResourcesController.checkEligibility('corporate-gray', veteranData);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Eligibility results should not be null');
        System.assertEquals(1, results.size(), 'Should return one eligibility result');

        CVMAVeteranResourcesController.EligibilityResult result = results[0];
        System.assertEquals('General Program', result.program, 'Should be General Program');
        System.assertEquals('Likely Eligible', result.eligibilityStatus, 'Default should be likely eligible');
    }

    @IsTest
    static void testCheckEligibilityInvalidOrganization() {
        Map<String, Object> veteranData = new Map<String, Object>{
            'serviceConnectedDisability' => false,
            'disabilityRating' => 0,
            'branch' => 'Army',
            'combatVeteran' => false,
            'state' => 'FL'
        };

        Test.startTest();
        try {
            CVMAVeteranResourcesController.checkEligibility('invalid-org-id', veteranData);
            System.assert(false, 'Should have thrown exception for invalid organization');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Organization not found') ||
                         e.getMessage().contains('Failed to check eligibility'),
                'Exception message should indicate error: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testVeteranOrganizationInnerClass() {
        Test.startTest();
        CVMAVeteranResourcesController.VeteranOrganization org =
            new CVMAVeteranResourcesController.VeteranOrganization(
                'test-org',
                'Test Organization',
                'Test Category',
                'Test Description',
                'Test Eligibility',
                'National',
                '555-1234',
                'https://test.org',
                true,
                true,
                'https://test.org/apply',
                10
            );
        Test.stopTest();

        System.assertEquals('test-org', org.id, 'ID should match');
        System.assertEquals('Test Organization', org.organizationName, 'Name should match');
        System.assertEquals('Test Category', org.serviceCategory, 'Category should match');
        System.assertEquals('tel:555-1234', org.phoneLink, 'Phone link should be formatted correctly');
    }

    @IsTest
    static void testEligibilityResultInnerClass() {
        Test.startTest();
        CVMAVeteranResourcesController.EligibilityResult result =
            new CVMAVeteranResourcesController.EligibilityResult(
                'Test Program',
                'Test Program Name',
                'Eligible',
                'success',
                'Test Requirements'
            );
        Test.stopTest();

        System.assertEquals('Test Program', result.program, 'Program should match');
        System.assertEquals('Test Program Name', result.programName, 'Program name should match');
        System.assertEquals('Eligible', result.eligibilityStatus, 'Status should match');
        System.assertEquals('success', result.statusVariant, 'Variant should match');
        System.assertEquals('Test Requirements', result.requirements, 'Requirements should match');
    }
}
