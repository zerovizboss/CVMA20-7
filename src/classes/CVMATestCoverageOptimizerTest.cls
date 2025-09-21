@IsTest
private class CVMATestCoverageOptimizerTest {

    @IsTest
    static void testRunCoverageAnalysis() {
        Test.startTest();
        CVMATestCoverageOptimizer.CoverageAnalysis analysis =
            CVMATestCoverageOptimizer.runCoverageAnalysis();
        Test.stopTest();

        System.assertNotEquals(null, analysis, 'Analysis should not be null');
        System.assertNotEquals(null, analysis.qualityScore, 'Quality score should be calculated');
        System.assertNotEquals(null, analysis.performance, 'Performance metrics should be included');
    }

    @IsTest
    static void testGenerateCoverageReport() {
        Test.startTest();
        String report = CVMATestCoverageOptimizer.generateCoverageReport();
        Test.stopTest();

        System.assertNotEquals(null, report, 'Report should be generated');
        System.assert(report.contains('Coverage Report'), 'Report should contain title');
    }
}