/**
 * @description Test class for CVMAUsageTrackingController - Usage analytics testing
 * @author Claude AI - CVMA Development Team
 * @date January 2025
 */
@IsTest
public class CVMAUsageTrackingControllerTest {

    @IsTest
    static void testGetUsageMetrics_Success() {
        Test.startTest();

        // Test getting usage metrics
        CVMAUsageTrackingController.DevelopmentMetrics metrics = CVMAUsageTrackingController.getUsageMetrics();

        Test.stopTest();

        // Verify metrics structure
        System.assertNotEquals(null, metrics, 'Should return development metrics');
        System.assertNotEquals(null, metrics.totalUserStories, 'Should have total user stories');
        System.assertNotEquals(null, metrics.completedUserStories, 'Should have completed user stories');
        System.assertNotEquals(null, metrics.linesOfCodeGenerated, 'Should have lines of code generated');
        System.assertNotEquals(null, metrics.componentsCreated, 'Should have components created');
        System.assertNotEquals(null, metrics.codeReductionPercentage, 'Should have code reduction percentage');
        System.assertNotEquals(null, metrics.testClassesCreated, 'Should have test classes created');
        System.assertNotEquals(null, metrics.epicProgress, 'Should have epic progress list');
        System.assertNotEquals(null, metrics.recentSessions, 'Should have recent sessions list');

        // Verify expected values based on documentation
        System.assertEquals(17, metrics.totalUserStories, 'Should have 17 total user stories');
        System.assertEquals(9, metrics.completedUserStories, 'Should have 9 completed user stories');
        System.assert(metrics.linesOfCodeGenerated > 10000, 'Should have generated significant lines of code');
        System.assert(metrics.componentsCreated > 20, 'Should have created multiple components');
        System.assertEquals(87.0, metrics.codeReductionPercentage, 'Should show 87% code reduction average');
        System.assertEquals(8, metrics.testClassesCreated, 'Should have 8 test classes');

        // Verify epic progress structure
        System.assert(metrics.epicProgress.size() >= 3, 'Should have at least 3 epics');
        for (CVMAUsageTrackingController.EpicProgress epic : metrics.epicProgress) {
            System.assertNotEquals(null, epic.epicName, 'Epic should have name');
            System.assertNotEquals(null, epic.status, 'Epic should have status');
            System.assertNotEquals(null, epic.completionPercentage, 'Epic should have completion percentage');
        }

        // Verify recent sessions structure
        System.assert(metrics.recentSessions.size() >= 3, 'Should have recent sessions');
        for (CVMAUsageTrackingController.SessionMetrics session : metrics.recentSessions) {
            System.assertNotEquals(null, session.sessionDate, 'Session should have date');
            System.assertNotEquals(null, session.userStory, 'Session should have user story');
            System.assertNotEquals(null, session.status, 'Session should have status');
        }
    }

    @IsTest
    static void testGetClaudeCodeUsage_Success() {
        Test.startTest();

        // Test getting Claude Code usage metrics
        Map<String, Object> usage = CVMAUsageTrackingController.getClaudeCodeUsage();

        Test.stopTest();

        // Verify usage structure
        System.assertNotEquals(null, usage, 'Should return Claude Code usage metrics');
        System.assert(usage.containsKey('totalSessions'), 'Should include total sessions');
        System.assert(usage.containsKey('successfulDeployments'), 'Should include successful deployments');
        System.assert(usage.containsKey('componentsGenerated'), 'Should include components generated');
        System.assert(usage.containsKey('testCoverage'), 'Should include test coverage');
        System.assert(usage.containsKey('developmentVelocityIncrease'), 'Should include development velocity');
        System.assert(usage.containsKey('maintenanceReduction'), 'Should include maintenance reduction');
        System.assert(usage.containsKey('qualityImprovementScore'), 'Should include quality score');
        System.assert(usage.containsKey('recentAchievements'), 'Should include recent achievements');

        // Verify expected ranges
        Integer totalSessions = (Integer) usage.get('totalSessions');
        System.assert(totalSessions > 0, 'Should have positive session count');

        Integer successfulDeployments = (Integer) usage.get('successfulDeployments');
        System.assert(successfulDeployments > 0, 'Should have successful deployments');

        Decimal testCoverage = (Decimal) usage.get('testCoverage');
        System.assert(testCoverage > 90.0, 'Should have high test coverage');

        Integer velocityIncrease = (Integer) usage.get('developmentVelocityIncrease');
        System.assert(velocityIncrease > 100, 'Should show significant velocity increase');

        List<String> achievements = (List<String>) usage.get('recentAchievements');
        System.assert(achievements.size() > 0, 'Should have recent achievements');
    }

    @IsTest
    static void testExportUsageMetrics_Success() {
        Test.startTest();

        // Test exporting usage metrics to CSV
        String csvData = CVMAUsageTrackingController.exportUsageMetrics();

        Test.stopTest();

        // Verify CSV structure
        System.assertNotEquals(null, csvData, 'Should return CSV data');
        System.assert(csvData.contains('Metric,Value'), 'Should have CSV header');
        System.assert(csvData.contains('Total User Stories'), 'Should include user stories metric');
        System.assert(csvData.contains('Lines of Code Generated'), 'Should include lines of code metric');
        System.assert(csvData.contains('Components Created'), 'Should include components metric');
        System.assert(csvData.contains('Code Reduction Percentage'), 'Should include code reduction metric');

        // Verify epic section
        System.assert(csvData.contains('Epic,Status,Completion,Code Reduction'), 'Should have epic section header');
        System.assert(csvData.contains('Member Management'), 'Should include Epic #1');
        System.assert(csvData.contains('Event Management'), 'Should include Epic #2');
        System.assert(csvData.contains('Standard Feature Integration'), 'Should include SFI initiative');

        // Verify CSV formatting
        String[] lines = csvData.split('\n');
        System.assert(lines.size() > 10, 'Should have multiple CSV lines');
    }

    @IsTest
    static void testDevelopmentMetricsWrapperClass() {
        Test.startTest();

        // Test DevelopmentMetrics wrapper class
        CVMAUsageTrackingController.DevelopmentMetrics metrics = new CVMAUsageTrackingController.DevelopmentMetrics();
        metrics.totalUserStories = 17;
        metrics.completedUserStories = 9;
        metrics.linesOfCodeGenerated = 15000;
        metrics.componentsCreated = 28;
        metrics.codeReductionPercentage = 87.0;
        metrics.testClassesCreated = 8;

        Test.stopTest();

        // Verify wrapper properties
        System.assertEquals(17, metrics.totalUserStories, 'Total user stories should be set');
        System.assertEquals(9, metrics.completedUserStories, 'Completed user stories should be set');
        System.assertEquals(15000, metrics.linesOfCodeGenerated, 'Lines of code should be set');
        System.assertEquals(28, metrics.componentsCreated, 'Components created should be set');
        System.assertEquals(87.0, metrics.codeReductionPercentage, 'Code reduction should be set');
        System.assertEquals(8, metrics.testClassesCreated, 'Test classes should be set');
    }

    @IsTest
    static void testEpicProgressWrapperClass() {
        Test.startTest();

        // Test EpicProgress wrapper class
        CVMAUsageTrackingController.EpicProgress epic = new CVMAUsageTrackingController.EpicProgress();
        epic.epicName = 'Test Epic';
        epic.status = 'Completed';
        epic.userStoriesTotal = 3;
        epic.userStoriesCompleted = 3;
        epic.completionPercentage = 100.0;
        epic.codeReduction = 85;
        epic.lastUpdated = Date.today();

        Test.stopTest();

        // Verify wrapper properties
        System.assertEquals('Test Epic', epic.epicName, 'Epic name should be set');
        System.assertEquals('Completed', epic.status, 'Status should be set');
        System.assertEquals(3, epic.userStoriesTotal, 'Total user stories should be set');
        System.assertEquals(3, epic.userStoriesCompleted, 'Completed user stories should be set');
        System.assertEquals(100.0, epic.completionPercentage, 'Completion percentage should be set');
        System.assertEquals(85, epic.codeReduction, 'Code reduction should be set');
        System.assertEquals(Date.today(), epic.lastUpdated, 'Last updated should be set');
    }

    @IsTest
    static void testSessionMetricsWrapperClass() {
        Test.startTest();

        // Test SessionMetrics wrapper class
        CVMAUsageTrackingController.SessionMetrics session = new CVMAUsageTrackingController.SessionMetrics();
        session.sessionDate = 'January 25, 2025';
        session.userStory = 'User Story #16: Lightning Calendar';
        session.linesGenerated = 1200;
        session.componentsCreated = 4;
        session.status = 'Completed';
        session.achievements = '80% code reduction, Lightning Calendar integration';

        Test.stopTest();

        // Verify wrapper properties
        System.assertEquals('January 25, 2025', session.sessionDate, 'Session date should be set');
        System.assertEquals('User Story #16: Lightning Calendar', session.userStory, 'User story should be set');
        System.assertEquals(1200, session.linesGenerated, 'Lines generated should be set');
        System.assertEquals(4, session.componentsCreated, 'Components created should be set');
        System.assertEquals('Completed', session.status, 'Status should be set');
        System.assertEquals('80% code reduction, Lightning Calendar integration', session.achievements, 'Achievements should be set');
    }

    @IsTest
    static void testErrorHandling_GetUsageMetrics() {
        Test.startTest();

        // Test should handle errors gracefully and not throw unhandled exceptions
        try {
            CVMAUsageTrackingController.DevelopmentMetrics metrics = CVMAUsageTrackingController.getUsageMetrics();
            System.assertNotEquals(null, metrics, 'Should return metrics even with potential issues');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Unable to retrieve usage metrics'), 'Should have proper error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testErrorHandling_GetClaudeCodeUsage() {
        Test.startTest();

        // Test should handle errors gracefully
        try {
            Map<String, Object> usage = CVMAUsageTrackingController.getClaudeCodeUsage();
            System.assertNotEquals(null, usage, 'Should return usage data even with potential issues');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Unable to retrieve Claude Code usage'), 'Should have proper error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testErrorHandling_ExportUsageMetrics() {
        Test.startTest();

        // Test should handle errors gracefully
        try {
            String csvData = CVMAUsageTrackingController.exportUsageMetrics();
            System.assertNotEquals(null, csvData, 'Should return CSV data even with potential issues');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Unable to export usage metrics'), 'Should have proper error message');
        }

        Test.stopTest();
    }
}
