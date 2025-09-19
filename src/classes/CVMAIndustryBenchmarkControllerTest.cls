/**
 * CVMAIndustryBenchmarkControllerTest
 * Epic #8 Phase 3 - Industry Benchmarking Testing
 *
 * @author CVMA Chapter 20-7 Development Team
 * @version 1.0 - Epic #8 Phase 3 Implementation
 * @since September 2025
 */
@IsTest
public class CVMAIndustryBenchmarkControllerTest {

    @TestSetup
    static void setupTestData() {
        Contact testMember = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .withMembershipId('FM12345')
            .create();
    }

    @IsTest
    static void testGetIndustryBenchmarks() {
        Test.startTest();
        Map<String, Object> result = CVMAIndustryBenchmarkController.getIndustryBenchmarks();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Industry benchmarks should return data');
        System.assert(result.containsKey('militaryOrganizations'), 'Should contain military organizations data');
        System.assert(result.containsKey('veteranServices'), 'Should contain veteran services data');
        System.assert(result.containsKey('performanceMetrics'), 'Should contain performance metrics');
    }

    @IsTest
    static void testGetCompetitiveAnalysis() {
        Test.startTest();
        Map<String, Object> result = CVMAIndustryBenchmarkController.getCompetitiveAnalysis();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Competitive analysis should return data');
        System.assert(result.containsKey('competitorAssessment'), 'Should contain competitor assessment');
        System.assert(result.containsKey('marketPosition'), 'Should contain market position');
        System.assert(result.containsKey('strategicAdvantages'), 'Should contain strategic advantages');
    }

    @IsTest
    static void testGetBestPracticesAnalysis() {
        Test.startTest();
        Map<String, Object> result = CVMAIndustryBenchmarkController.getBestPracticesAnalysis();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Best practices analysis should return data');
        System.assert(result.containsKey('industryBestPractices'), 'Should contain industry best practices');
        System.assert(result.containsKey('implementationRecommendations'), 'Should contain implementation recommendations');
        System.assert(result.containsKey('performanceGaps'), 'Should contain performance gaps');
    }

    @IsTest
    static void testGetTechnologyInnovationAnalysis() {
        Test.startTest();
        Map<String, Object> result = CVMAIndustryBenchmarkController.getTechnologyInnovationAnalysis();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Technology innovation analysis should return data');
        System.assert(result.containsKey('technologyAdoption'), 'Should contain technology adoption data');
        System.assert(result.containsKey('innovationOpportunities'), 'Should contain innovation opportunities');
        System.assert(result.containsKey('digitalTransformation'), 'Should contain digital transformation data');
    }
}
