/**
 * Test Class for CVMACrossChapterAnalyticsController - Epic #8 Phase 3
 * Comprehensive test coverage for Multi-Chapter Intelligence Platform
 *
 * Tests cross-chapter analytics, performance comparison, best practices sharing,
 * national intelligence, and industry benchmarking integration
 *
 * @author Combat Veterans Motorcycle Association Chapter 20-7
 * @version 3.0 - Phase 3 Cross-Chapter Intelligence
 * @since September 2025
 */
@IsTest
public class CVMACrossChapterAnalyticsControllerTest {

    /**
     * Test data setup for cross-chapter analytics testing
     */
    @TestSetup
    static void setupTestData() {
        // Create comprehensive test data for cross-chapter analytics
        List<Contact> testMembers = new List<Contact>();

        // High performing members
        for (Integer i = 0; i < 10; i++) {
            Contact highPerformer = CVMATestDataFactory.createContact()
                .withName('HighPerformer' + i, 'Test')
                .withEmail('highperformer' + i + '@test.com')
                .withMemberStatus('Full Member')
                .withMilitaryBranch('Army')
                .withServiceDates(Date.newInstance(2010, 1, 1), Date.newInstance(2020, 12, 31))
                .withDisabilityRating(String.valueOf(80 + i))
                .withMailingAddress('123 High St', 'Jacksonville', 'FL', '32205')
                .create();
            testMembers.add(highPerformer);
        }

        // Medium performing members
        for (Integer i = 0; i < 15; i++) {
            Contact mediumPerformer = CVMATestDataFactory.createContact()
                .withName('MediumPerformer' + i, 'Test')
                .withEmail('mediumperformer' + i + '@test.com')
                .withMemberStatus('Associate Member')
                .withMilitaryBranch('Navy')
                .withServiceDates(Date.newInstance(2005, 1, 1), Date.newInstance(2015, 12, 31))
                .withDisabilityRating(String.valueOf(50 + i))
                .withMailingAddress('456 Medium Ave', 'Jacksonville', 'FL', '32207')
                .create();
            testMembers.add(mediumPerformer);
        }

        // Diverse geographic representation
        for (Integer i = 0; i < 5; i++) {
            Contact geoMember = CVMATestDataFactory.createContact()
                .withName('GeoMember' + i, 'Test')
                .withEmail('geomember' + i + '@test.com')
                .withMemberStatus('Full Member')
                .withMilitaryBranch('Marine Corps')
                .withServiceDates(Date.newInstance(2015, 1, 1), Date.newInstance(2022, 12, 31))
                .withDisabilityRating('60')
                .withMailingAddress('789 Geo Rd', i % 2 == 0 ? 'Atlanta' : 'Miami', i % 2 == 0 ? 'GA' : 'FL', '30301')
                .create();
            testMembers.add(geoMember);
        }

        insert testMembers;

        // Create test campaigns for cross-chapter event analysis
        List<Campaign> testCampaigns = new List<Campaign>();

        for (Integer i = 0; i < 8; i++) {
            Campaign campaign = CVMATestDataFactory.createCampaign()
                .withName('Cross Chapter Event ' + i)
                .withType('Event')
                .withStatus('Completed')
                .withStartDate(Date.today().addDays(-30 * (i + 1)))
                .withEndDate(Date.today().addDays(-30 * (i + 1) + 1))
                .withBudgetedCost(2000 + (i * 500))
                .withActualCost(1800 + (i * 400))
                .create();
            campaign.NumberSent = 100 + (i * 10);
            campaign.NumberOfResponses = 60 + (i * 8);
            testCampaigns.add(campaign);
        }

        insert testCampaigns;

        // Create test opportunities for cross-chapter financial analysis
        List<Opportunity> testOpportunities = new List<Opportunity>();

        for (Integer i = 0; i < 12; i++) {
            Opportunity opp = CVMATestDataFactory.createOpportunity()
                .withName('Chapter Fundraising ' + i)
                .withAmount(5000 + (i * 1000))
                .withStage('Closed Won')
                .withCloseDate(Date.today().addDays(-15 * (i + 1)))
                .withType('Fundraising')
                .create();
            testOpportunities.add(opp);
        }

        insert testOpportunities;

        System.debug('CVMACrossChapterAnalyticsControllerTest: Test data setup completed');
    }

    /**
     * Test main cross-chapter analytics method
     */
    @IsTest
    static void testGetCrossChapterAnalytics() {
        Test.startTest();

        Map<String, Object> result = CVMACrossChapterAnalyticsController.getCrossChapterAnalytics();

        Test.stopTest();

        // Verify analytics data structure
        System.assertNotEquals(null, result, 'Cross-chapter analytics should return data');
        System.assert(result.containsKey('intelligenceStatus'), 'Should contain intelligence status');
        System.assert(result.containsKey('chapterPerformanceComparison'), 'Should contain performance comparison');
        System.assert(result.containsKey('bestPracticesSharing'), 'Should contain best practices');
        System.assert(result.containsKey('nationalIntelligence'), 'Should contain national intelligence');
        System.assert(result.containsKey('industryBenchmarking'), 'Should contain industry benchmarking');
        System.assert(result.containsKey('collaborationOpportunities'), 'Should contain collaboration opportunities');

        // Verify intelligence status
        Map<String, Object> intelligenceStatus = (Map<String, Object>) result.get('intelligenceStatus');
        System.assertEquals(true, intelligenceStatus.get('multiChapterConnectivity'), 'Multi-chapter connectivity should be active');
        System.assertEquals(true, intelligenceStatus.get('nationalAnalyticsOperational'), 'National analytics should be operational');
        System.assertEquals(true, intelligenceStatus.get('benchmarkingPlatformActive'), 'Benchmarking platform should be active');

        System.debug('CVMACrossChapterAnalyticsControllerTest: Main analytics test completed successfully');
    }

    /**
     * Test chapter performance comparison functionality
     */
    @IsTest
    static void testGetChapterPerformanceComparison() {
        Test.startTest();

        Map<String, Object> result = CVMACrossChapterAnalyticsController.getChapterPerformanceComparison();

        Test.stopTest();

        // Verify performance comparison data structure
        System.assertNotEquals(null, result, 'Chapter performance comparison should return data');
        System.assert(result.containsKey('currentChapterRanking'), 'Should contain current chapter ranking');
        System.assert(result.containsKey('membershipGrowthComparison'), 'Should contain membership growth comparison');
        System.assert(result.containsKey('eventParticipationComparison'), 'Should contain event participation comparison');
        System.assert(result.containsKey('digitalAdoptionComparison'), 'Should contain digital adoption comparison');
        System.assert(result.containsKey('topPerformingChapters'), 'Should contain top performing chapters');

        // Verify ranking data
        Map<String, Object> ranking = (Map<String, Object>) result.get('currentChapterRanking');
        System.assertNotEquals(null, ranking.get('overallRanking'), 'Should have overall ranking');
        System.assertNotEquals(null, ranking.get('percentile'), 'Should have percentile ranking');

        System.debug('CVMACrossChapterAnalyticsControllerTest: Performance comparison test completed successfully');
    }

    /**
     * Test best practices sharing functionality
     */
    @IsTest
    static void testGetBestPracticesSharing() {
        Test.startTest();

        Map<String, Object> result = CVMACrossChapterAnalyticsController.getBestPracticesSharing();

        Test.stopTest();

        // Verify best practices data structure
        System.assertNotEquals(null, result, 'Best practices sharing should return data');
        System.assert(result.containsKey('memberEngagementPractices'), 'Should contain member engagement practices');
        System.assert(result.containsKey('eventManagementPractices'), 'Should contain event management practices');
        System.assert(result.containsKey('technologyAdoptionPractices'), 'Should contain technology adoption practices');
        System.assert(result.containsKey('successStories'), 'Should contain success stories');
        System.assert(result.containsKey('implementationGuides'), 'Should contain implementation guides');

        System.debug('CVMACrossChapterAnalyticsControllerTest: Best practices test completed successfully');
    }

    /**
     * Test national CVMA intelligence functionality
     */
    @IsTest
    static void testGetNationalCVMAIntelligence() {
        Test.startTest();

        Map<String, Object> result = CVMACrossChapterAnalyticsController.getNationalCVMAIntelligence();

        Test.stopTest();

        // Verify national intelligence data structure
        System.assertNotEquals(null, result, 'National intelligence should return data');
        System.assert(result.containsKey('nationalMembershipTrends'), 'Should contain national membership trends');
        System.assert(result.containsKey('organizationalHealth'), 'Should contain organizational health');
        System.assert(result.containsKey('strategicOpportunities'), 'Should contain strategic opportunities');
        System.assert(result.containsKey('veteranServicesImpact'), 'Should contain veteran services impact');

        System.debug('CVMACrossChapterAnalyticsControllerTest: National intelligence test completed successfully');
    }

    /**
     * Test industry benchmarking functionality
     */
    @IsTest
    static void testGetIndustryBenchmarking() {
        Test.startTest();

        Map<String, Object> result = CVMACrossChapterAnalyticsController.getIndustryBenchmarking();

        Test.stopTest();

        // Verify industry benchmarking data structure
        System.assertNotEquals(null, result, 'Industry benchmarking should return data');
        System.assert(result.containsKey('veteranOrganizationComparison'), 'Should contain veteran organization comparison');
        System.assert(result.containsKey('technologyLeadership'), 'Should contain technology leadership');
        System.assert(result.containsKey('competitiveAdvantages'), 'Should contain competitive advantages');

        System.debug('CVMACrossChapterAnalyticsControllerTest: Industry benchmarking test completed successfully');
    }

    /**
     * Test cross-chapter resource optimization
     */
    @IsTest
    static void testGetCrossChapterResourceOptimization() {
        Test.startTest();

        Map<String, Object> result = CVMACrossChapterAnalyticsController.getCrossChapterResourceOptimization();

        Test.stopTest();

        // Verify resource optimization data structure
        System.assertNotEquals(null, result, 'Resource optimization should return data');
        System.assert(result.containsKey('resourceSharingOpportunities'), 'Should contain resource sharing opportunities');
        System.assert(result.containsKey('costSavings'), 'Should contain cost savings');
        System.assert(result.containsKey('efficiencyGains'), 'Should contain efficiency gains');

        System.debug('CVMACrossChapterAnalyticsControllerTest: Resource optimization test completed successfully');
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

        Map<String, Object> analyticsResult = CVMACrossChapterAnalyticsController.getCrossChapterAnalytics();
        Map<String, Object> performanceResult = CVMACrossChapterAnalyticsController.getChapterPerformanceComparison();
        Map<String, Object> practicesResult = CVMACrossChapterAnalyticsController.getBestPracticesSharing();

        Test.stopTest();

        // Verify error handling provides default data
        System.assertNotEquals(null, analyticsResult, 'Should handle errors gracefully with default data');
        System.assertNotEquals(null, performanceResult, 'Should handle performance errors gracefully');
        System.assertNotEquals(null, practicesResult, 'Should handle practices errors gracefully');

        System.debug('CVMACrossChapterAnalyticsControllerTest: Error handling test completed successfully');
    }

    /**
     * Test data security and permissions
     */
    @IsTest
    static void testDataSecurity() {
        // Create user with limited permissions
        User limitedUser = CVMATestDataFactory.createUser()
            .withProfile('Standard User')
            .withEmail('limited@crosschapter.test')
            .create();

        Test.startTest();

        System.runAs(limitedUser) {
            try {
                Map<String, Object> result = CVMACrossChapterAnalyticsController.getCrossChapterAnalytics();
                System.assertNotEquals(null, result, 'Should handle limited permissions gracefully');
            } catch (Exception e) {
                System.assert(e.getMessage().contains('permissions') ||
                             e.getMessage().contains('access'), 'Should provide meaningful security error message');
            }
        }

        Test.stopTest();

        System.debug('CVMACrossChapterAnalyticsControllerTest: Data security test completed successfully');
    }

    /**
     * Test performance metrics calculations
     */
    @IsTest
    static void testPerformanceMetricsCalculations() {
        Test.startTest();

        Map<String, Object> result = CVMACrossChapterAnalyticsController.getChapterPerformanceComparison();

        Test.stopTest();

        // Verify performance metrics calculations
        Map<String, Object> ranking = (Map<String, Object>) result.get('currentChapterRanking');

        System.assertNotEquals(null, ranking.get('overallRanking'), 'Should calculate overall ranking');
        System.assertNotEquals(null, ranking.get('percentile'), 'Should calculate percentile');

        Object categoryRankings = ranking.get('categoryRankings');
        if (categoryRankings != null) {
            Map<String, Object> categories = (Map<String, Object>) categoryRankings;
            System.assert(categories.containsKey('memberEngagement'), 'Should include member engagement ranking');
            System.assert(categories.containsKey('digitalAdoption'), 'Should include digital adoption ranking');
        }

        System.debug('CVMACrossChapterAnalyticsControllerTest: Performance metrics test completed successfully');
    }

    /**
     * Test integration with Epic #8 components
     */
    @IsTest
    static void testEpic8Integration() {
        Test.startTest();

        // Test integration with other Epic #8 Phase 3 components
        Map<String, Object> crossChapterAnalytics = CVMACrossChapterAnalyticsController.getCrossChapterAnalytics();

        // This would typically call other Epic #8 controllers as well
        // to verify cross-component integration

        Test.stopTest();

        // Verify integration status includes phase information
        System.assert(crossChapterAnalytics.containsKey('intelligenceStatus'), 'Should indicate intelligence status');

        Map<String, Object> intelligenceStatus = (Map<String, Object>) crossChapterAnalytics.get('intelligenceStatus');
        System.assertNotEquals(null, intelligenceStatus.get('crossChapterMCPCapacity'), 'Should show MCP capacity');

        System.debug('CVMACrossChapterAnalyticsControllerTest: Epic #8 integration test completed successfully');
    }

    /**
     * Test national membership trends analysis
     */
    @IsTest
    static void testNationalMembershipTrendsAnalysis() {
        Test.startTest();

        Map<String, Object> result = CVMACrossChapterAnalyticsController.getNationalCVMAIntelligence();

        Test.stopTest();

        // Verify national intelligence includes comprehensive analysis
        System.assert(result.containsKey('nationalMembershipTrends'), 'Should contain national membership trends');
        System.assert(result.containsKey('demographicAnalysis'), 'Should contain demographic analysis');
        System.assert(result.containsKey('geographicDistribution'), 'Should contain geographic distribution');
        System.assert(result.containsKey('organizationalHealth'), 'Should contain organizational health assessment');

        System.debug('CVMACrossChapterAnalyticsControllerTest: National trends analysis test completed successfully');
    }

    /**
     * Test competitive advantage identification
     */
    @IsTest
    static void testCompetitiveAdvantageIdentification() {
        Test.startTest();

        Map<String, Object> result = CVMACrossChapterAnalyticsController.getIndustryBenchmarking();

        Test.stopTest();

        // Verify competitive advantage analysis
        System.assert(result.containsKey('competitiveAdvantages'), 'Should identify competitive advantages');
        System.assert(result.containsKey('differentiationFactors'), 'Should identify differentiation factors');
        System.assert(result.containsKey('technologyLeadership'), 'Should assess technology leadership');

        System.debug('CVMACrossChapterAnalyticsControllerTest: Competitive advantage test completed successfully');
    }
}
