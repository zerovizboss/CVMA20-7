@IsTest
private class CVMAPerformanceMonitorTest {

    @IsTest
    static void testStartMonitoringSession() {
        Test.startTest();
        CVMAPerformanceMonitor.PerformanceSession session =
            CVMAPerformanceMonitor.startMonitoringSession();
        Test.stopTest();

        System.assertNotEquals(null, session, 'Session should be created');
        System.assertNotEquals(null, session.sessionId, 'Session should have ID');
        System.assert(session.metrics.size() > 0, 'Should capture initial metrics');
    }

    @IsTest
    static void testCaptureSystemMetrics() {
        Test.startTest();
        CVMAPerformanceMonitor.PerformanceMetric metric =
            CVMAPerformanceMonitor.captureSystemMetrics('Test_Operation');
        Test.stopTest();

        System.assertNotEquals(null, metric, 'Metric should be captured');
        System.assertEquals('Test_Operation', metric.operation, 'Operation should match');
        System.assertNotEquals(null, metric.status, 'Status should be determined');
    }

    @IsTest
    static void testMonitorAPICall() {
        Test.startTest();
        CVMAPerformanceMonitor.PerformanceMetric metric =
            CVMAPerformanceMonitor.monitorAPICall('VA_Forms_API', 'search');
        Test.stopTest();

        System.assertNotEquals(null, metric, 'API metric should be captured');
        System.assert(metric.operation.contains('VA_Forms_API'), 'Should track API name');
    }
}
