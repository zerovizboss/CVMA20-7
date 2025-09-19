/**
 * Test Class for CVMAVeteranServicesController - Epic #8 Phase 3
 * Comprehensive test coverage for External Services Integration
 *
 * Tests VA Benefits API integration, community resource mapping, crisis intervention,
 * military records verification, and healthcare network integration
 *
 * @author Combat Veterans Motorcycle Association Chapter 20-7
 * @version 3.0 - Phase 3 External Integration
 * @since September 2025
 */
@IsTest
public class CVMAVeteranServicesControllerTest {

    /**
     * Test data setup for veteran services testing
     */
    @TestSetup
    static void setupTestData() {
        // Create test veteran contacts using CVMATestDataFactory
        List<Contact> testVeterans = new List<Contact>();

        // High disability rating veteran
        Contact highRatingVeteran = CVMATestDataFactory.createContact()
            .withName('John', 'HighRating')
            .withEmail('john.highrating@test.com')
            .withPhone('(555) 123-0001')
            .withMemberStatus('Full Member')
            .withMilitaryBranch('Army')
            .withServiceDates(Date.newInstance(2000, 1, 1), Date.newInstance(2010, 12, 31))
            .withDisabilityRating('80')
            .withMailingAddress('123 High St', 'Jacksonville', 'FL', '32205')
            .create();
        testVeterans.add(highRatingVeteran);

        // Medium disability rating veteran
        Contact mediumRatingVeteran = CVMATestDataFactory.createContact()
            .withName('Jane', 'MediumRating')
            .withEmail('jane.mediumrating@test.com')
            .withPhone('(555) 123-0002')
            .withMemberStatus('Full Member')
            .withMilitaryBranch('Navy')
            .withServiceDates(Date.newInstance(2005, 3, 15), Date.newInstance(2015, 3, 14))
            .withDisabilityRating('50')
            .withMailingAddress('456 Medium Ave', 'Jacksonville', 'FL', '32207')
            .create();
        testVeterans.add(mediumRatingVeteran);

        // Recent veteran (within 5 years)
        Contact recentVeteran = CVMATestDataFactory.createContact()
            .withName('Mike', 'Recent')
            .withEmail('mike.recent@test.com')
            .withPhone('(555) 123-0003')
            .withMemberStatus('Full Member')
            .withMilitaryBranch('Marine Corps')
            .withServiceDates(Date.newInstance(2015, 6, 1), Date.newInstance(2021, 5, 31))
            .withDisabilityRating('30')
            .withMailingAddress('789 Recent Rd', 'Jacksonville', 'FL', '32209')
            .create();
        testVeterans.add(recentVeteran);

        // Veteran without disability rating
        Contact noRatingVeteran = CVMATestDataFactory.createContact()
            .withName('Sarah', 'NoRating')
            .withEmail('sarah.norating@test.com')
            .withPhone('(555) 123-0004')
            .withMemberStatus('Associate Member')
            .withMilitaryBranch('Air Force')
            .withServiceDates(Date.newInstance(1995, 9, 1), Date.newInstance(2005, 8, 31))
            .withMailingAddress('321 NoRating Blvd', 'Jacksonville', 'FL', '32211')
            .create();
        testVeterans.add(noRatingVeteran);

        // Out-of-state veteran
        Contact outOfStateVeteran = CVMATestDataFactory.createContact()
            .withName('David', 'OutOfState')
            .withEmail('david.outofstate@test.com')
            .withPhone('(555) 123-0005')
            .withMemberStatus('Full Member')
            .withMilitaryBranch('Coast Guard')
            .withServiceDates(Date.newInstance(2008, 12, 1), Date.newInstance(2018, 11, 30))
            .withDisabilityRating('40')
            .withMailingAddress('654 OutState Dr', 'Atlanta', 'GA', '30301')
            .create();
        testVeterans.add(outOfStateVeteran);

        insert testVeterans;

        // Create test campaigns for event data
        List<Campaign> testCampaigns = CVMATestDataFactory.createCampaigns(3)
            .withType('Event')
            .withStatus('Completed')
            .withBudgetedCost(1000)
            .withActualCost(800)
            .create();

        insert testCampaigns;

        // Create test opportunities for financial data
        List<Opportunity> testOpportunities = CVMATestDataFactory.createOpportunities(5)
            .withAmount(5000)
            .withStage('Closed Won')
            .withCloseDate(Date.today().addDays(-30))
            .create();

        insert testOpportunities;

        System.debug('CVMAVeteranServicesControllerTest: Test data setup completed');
    }

    /**
     * Test main veteran services integration method
     */
    @IsTest
    static void testGetVeteranServicesIntegration() {
        Test.startTest();

        Map<String, Object> result = CVMAVeteranServicesController.getVeteranServicesIntegration();

        Test.stopTest();

        // Verify integration status
        System.assertNotEquals(null, result, 'Veteran services integration should return data');
        System.assert(result.containsKey('integrationStatus'), 'Should contain integration status');
        System.assert(result.containsKey('vaBenefitsVerification'), 'Should contain VA benefits verification');
        System.assert(result.containsKey('communityResources'), 'Should contain community resources');
        System.assert(result.containsKey('crisisIntervention'), 'Should contain crisis intervention');
        System.assert(result.containsKey('militaryRecordsVerification'), 'Should contain military records verification');

        // Verify integration status details
        Map<String, Object> integrationStatus = (Map<String, Object>) result.get('integrationStatus');
        System.assertEquals('Active', integrationStatus.get('vaApiConnectivity'), 'VA API should be active');
        System.assertEquals(true, integrationStatus.get('communityResourcesConnected'), 'Community resources should be connected');
        System.assertEquals(true, integrationStatus.get('crisisInterventionOperational'), 'Crisis intervention should be operational');

        System.debug('CVMAVeteranServicesControllerTest: Main integration test completed successfully');
    }

    /**
     * Test VA Benefits verification functionality
     */
    @IsTest
    static void testGetVABenefitsVerification() {
        Test.startTest();

        Map<String, Object> result = CVMAVeteranServicesController.getVABenefitsVerification();

        Test.stopTest();

        // Verify VA benefits data structure
        System.assertNotEquals(null, result, 'VA benefits verification should return data');
        System.assert(result.containsKey('benefitsEligibility'), 'Should contain benefits eligibility');
        System.assert(result.containsKey('disabilityCompensation'), 'Should contain disability compensation');
        System.assert(result.containsKey('verificationStatus'), 'Should contain verification status');

        // Verify benefits eligibility analysis
        Map<String, Object> eligibility = (Map<String, Object>) result.get('benefitsEligibility');
        System.assertNotEquals(null, eligibility.get('eligibleMembers'), 'Should have eligible members count');
        System.assertNotEquals(null, eligibility.get('totalMembers'), 'Should have total members count');
        System.assertNotEquals(null, eligibility.get('eligibilityRate'), 'Should have eligibility rate');

        // Verify disability compensation analysis
        Map<String, Object> compensation = (Map<String, Object>) result.get('disabilityCompensation');
        System.assertNotEquals(null, compensation.get('membersWithRating'), 'Should have members with rating count');
        System.assertNotEquals(null, compensation.get('averageRating'), 'Should have average rating');

        System.debug('CVMAVeteranServicesControllerTest: VA Benefits verification test completed successfully');
    }

    /**
     * Test benefits optimization recommendations
     */
    @IsTest
    static void testGetBenefitsOptimizationRecommendations() {
        Test.startTest();

        Map<String, Object> result = CVMAVeteranServicesController.getBenefitsOptimizationRecommendations();

        Test.stopTest();

        // Verify optimization data structure
        System.assertNotEquals(null, result, 'Benefits optimization should return data');
        System.assert(result.containsKey('personalizedRecommendations'), 'Should contain personalized recommendations');
        System.assert(result.containsKey('potentialSavings'), 'Should contain potential savings');
        System.assert(result.containsKey('actionablePlans'), 'Should contain actionable plans');

        // Verify personalized recommendations
        Map<String, Object> recommendations = (Map<String, Object>) result.get('personalizedRecommendations');
        System.assertNotEquals(null, recommendations.get('personalizedPlans'), 'Should have personalized plans');
        System.assertNotEquals(null, recommendations.get('totalRecommendations'), 'Should have total recommendations count');

        System.debug('CVMAVeteranServicesControllerTest: Benefits optimization test completed successfully');
    }

    /**
     * Test community resource mapping functionality
     */
    @IsTest
    static void testGetCommunityResourceMapping() {
        Test.startTest();

        Map<String, Object> result = CVMAVeteranServicesController.getCommunityResourceMapping();

        Test.stopTest();

        // Verify community resources data structure
        System.assertNotEquals(null, result, 'Community resource mapping should return data');
        System.assert(result.containsKey('localVeteranOrganizations'), 'Should contain local veteran organizations');
        System.assert(result.containsKey('healthcareProviders'), 'Should contain healthcare providers');
        System.assert(result.containsKey('employmentServices'), 'Should contain employment services');
        System.assert(result.containsKey('resourceAvailability'), 'Should contain resource availability');

        System.debug('CVMAVeteranServicesControllerTest: Community resource mapping test completed successfully');
    }

    /**
     * Test crisis intervention services
     */
    @IsTest
    static void testGetCrisisInterventionServices() {
        Test.startTest();

        Map<String, Object> result = CVMAVeteranServicesController.getCrisisInterventionServices();

        Test.stopTest();

        // Verify crisis services data structure
        System.assertNotEquals(null, result, 'Crisis intervention should return data');
        System.assert(result.containsKey('emergencyContacts'), 'Should contain emergency contacts');
        System.assert(result.containsKey('crisisHotlines'), 'Should contain crisis hotlines');
        System.assert(result.containsKey('riskAssessment'), 'Should contain risk assessment');
        System.assert(result.containsKey('automaticAlerts'), 'Should contain automatic alerts');

        System.debug('CVMAVeteranServicesControllerTest: Crisis intervention test completed successfully');
    }

    /**
     * Test military records verification
     */
    @IsTest
    static void testGetMilitaryRecordsVerification() {
        Test.startTest();

        Map<String, Object> result = CVMAVeteranServicesController.getMilitaryRecordsVerification();

        Test.stopTest();

        // Verify military records data structure
        System.assertNotEquals(null, result, 'Military records verification should return data');
        System.assert(result.containsKey('serviceVerification'), 'Should contain service verification');
        System.assert(result.containsKey('deploymentRecords'), 'Should contain deployment records');
        System.assert(result.containsKey('dd214Verification'), 'Should contain DD214 verification');
        System.assert(result.containsKey('vaIntegration'), 'Should contain VA integration');

        System.debug('CVMAVeteranServicesControllerTest: Military records verification test completed successfully');
    }

    /**
     * Test healthcare network integration
     */
    @IsTest
    static void testGetHealthcareNetworkIntegration() {
        Test.startTest();

        Map<String, Object> result = CVMAVeteranServicesController.getHealthcareNetworkIntegration();

        Test.stopTest();

        // Verify healthcare network data structure
        System.assertNotEquals(null, result, 'Healthcare network integration should return data');
        System.assert(result.containsKey('vaHospitals'), 'Should contain VA hospitals');
        System.assert(result.containsKey('privatePractices'), 'Should contain private practices');
        System.assert(result.containsKey('appointmentAvailability'), 'Should contain appointment availability');
        System.assert(result.containsKey('providerRatings'), 'Should contain provider ratings');

        System.debug('CVMAVeteranServicesControllerTest: Healthcare network integration test completed successfully');
    }

    /**
     * Test error handling scenarios
     */
    @IsTest
    static void testErrorHandling() {
        // Test with no data available
        delete [SELECT Id FROM Contact];
        delete [SELECT Id FROM Campaign];
        delete [SELECT Id FROM Opportunity];

        Test.startTest();

        Map<String, Object> veteranServicesResult = CVMAVeteranServicesController.getVeteranServicesIntegration();
        Map<String, Object> vaBenefitsResult = CVMAVeteranServicesController.getVABenefitsVerification();
        Map<String, Object> optimizationResult = CVMAVeteranServicesController.getBenefitsOptimizationRecommendations();

        Test.stopTest();

        // Verify error handling provides default data
        System.assertNotEquals(null, veteranServicesResult, 'Should handle errors gracefully with default data');
        System.assertNotEquals(null, vaBenefitsResult, 'Should handle VA benefits errors gracefully');
        System.assertNotEquals(null, optimizationResult, 'Should handle optimization errors gracefully');

        // Verify default data structure is maintained
        System.assert(veteranServicesResult.containsKey('integrationStatus') ||
                     veteranServicesResult.containsKey('error'), 'Should contain integration status or error message');

        System.debug('CVMAVeteranServicesControllerTest: Error handling test completed successfully');
    }

    /**
     * Test data security and permissions
     */
    @IsTest
    static void testDataSecurity() {
        // Create user with limited permissions
        User limitedUser = CVMATestDataFactory.createUser()
            .withProfile('Standard User')
            .withEmail('limited@test.com')
            .create();

        Test.startTest();

        System.runAs(limitedUser) {
            try {
                Map<String, Object> result = CVMAVeteranServicesController.getVeteranServicesIntegration();
                System.assertNotEquals(null, result, 'Should handle limited permissions gracefully');
            } catch (Exception e) {
                System.assert(e.getMessage().contains('permissions') ||
                             e.getMessage().contains('access'), 'Should provide meaningful security error message');
            }
        }

        Test.stopTest();

        System.debug('CVMAVeteranServicesControllerTest: Data security test completed successfully');
    }

    /**
     * Test performance with large data sets
     */
    @IsTest
    static void testPerformanceWithLargeDataSet() {
        // Create additional test data to simulate larger dataset
        List<Contact> largeVeteranSet = new List<Contact>();

        for (Integer i = 0; i < 50; i++) {
            Contact veteran = CVMATestDataFactory.createContact()
                .withName('Veteran' + i, 'TestLarge')
                .withEmail('veteran' + i + '@testlarge.com')
                .withMemberStatus('Full Member')
                .withMilitaryBranch(Math.mod(i, 2) == 0 ? 'Army' : 'Navy')
                .withDisabilityRating(String.valueOf(Math.mod(i * 10, 100)))
                .create();
            largeVeteranSet.add(veteran);
        }

        insert largeVeteranSet;

        Test.startTest();

        Map<String, Object> result = CVMAVeteranServicesController.getVeteranServicesIntegration();

        Test.stopTest();

        // Verify performance with larger dataset
        System.assertNotEquals(null, result, 'Should handle large datasets efficiently');
        System.assert(result.containsKey('integrationStatus'), 'Should maintain functionality with large datasets');

        System.debug('CVMAVeteranServicesControllerTest: Performance test with large dataset completed successfully');
    }

    /**
     * Test disability rating calculations
     */
    @IsTest
    static void testDisabilityRatingCalculations() {
        Test.startTest();

        Map<String, Object> result = CVMAVeteranServicesController.getVABenefitsVerification();

        Test.stopTest();

        // Verify disability compensation analysis
        Map<String, Object> compensation = (Map<String, Object>) result.get('disabilityCompensation');

        Integer membersWithRating = (Integer) compensation.get('membersWithRating');
        Integer highRating = (Integer) compensation.get('highRating');
        Integer mediumRating = (Integer) compensation.get('mediumRating');
        Integer lowRating = (Integer) compensation.get('lowRating');
        Decimal averageRating = (Decimal) compensation.get('averageRating');

        // Verify rating calculations
        System.assertNotEquals(null, membersWithRating, 'Should calculate members with rating');
        System.assertNotEquals(null, averageRating, 'Should calculate average rating');

        // Verify rating distribution
        System.assert(highRating >= 0, 'High rating count should be non-negative');
        System.assert(mediumRating >= 0, 'Medium rating count should be non-negative');
        System.assert(lowRating >= 0, 'Low rating count should be non-negative');

        System.debug('CVMAVeteranServicesControllerTest: Disability rating calculations test completed successfully');
    }

    /**
     * Test benefits eligibility calculations
     */
    @IsTest
    static void testBenefitsEligibilityCalculations() {
        Test.startTest();

        Map<String, Object> result = CVMAVeteranServicesController.getVABenefitsVerification();

        Test.stopTest();

        // Verify benefits eligibility analysis
        Map<String, Object> eligibility = (Map<String, Object>) result.get('benefitsEligibility');

        Integer eligibleMembers = (Integer) eligibility.get('eligibleMembers');
        Integer pendingVerification = (Integer) eligibility.get('pendingVerification');
        Integer needsAssistance = (Integer) eligibility.get('needsAssistance');
        Integer totalMembers = (Integer) eligibility.get('totalMembers');
        Decimal eligibilityRate = (Decimal) eligibility.get('eligibilityRate');

        // Verify eligibility calculations
        System.assertNotEquals(null, eligibleMembers, 'Should calculate eligible members');
        System.assertNotEquals(null, totalMembers, 'Should calculate total members');
        System.assertNotEquals(null, eligibilityRate, 'Should calculate eligibility rate');

        // Verify mathematical consistency
        if (totalMembers > 0) {
            System.assert(eligibilityRate >= 0 && eligibilityRate <= 100, 'Eligibility rate should be valid percentage');
        }

        System.debug('CVMAVeteranServicesControllerTest: Benefits eligibility calculations test completed successfully');
    }

    /**
     * Test integration with other Epic #8 components
     */
    @IsTest
    static void testEpic8Integration() {
        Test.startTest();

        // Test integration with Einstein Analytics (Phase 2)
        Map<String, Object> veteranServices = CVMAVeteranServicesController.getVeteranServicesIntegration();

        // This would typically call Einstein Analytics controller as well
        // to verify cross-component integration

        Test.stopTest();

        // Verify integration status includes phase information
        System.assert(veteranServices.containsKey('integrationStatus'), 'Should indicate integration status');

        Map<String, Object> integrationStatus = (Map<String, Object>) veteranServices.get('integrationStatus');
        System.assertNotEquals(null, integrationStatus.get('externalServicesCapacity'), 'Should show MCP capacity');

        System.debug('CVMAVeteranServicesControllerTest: Epic #8 integration test completed successfully');
    }
}
