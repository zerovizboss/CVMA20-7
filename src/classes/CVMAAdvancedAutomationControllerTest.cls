/**
 * Test Class for CVMAAdvancedAutomationController - Epic #8 Phase 3
 * Comprehensive test coverage for AI-Powered Workflow Optimization
 *
 * Tests advanced automation capabilities, workflow optimization, member services automation,
 * operational excellence, cross-epic integration, and adaptive learning systems
 *
 * @author Combat Veterans Motorcycle Association Chapter 20-7
 * @version 3.0 - Phase 3 Advanced Automation
 * @since September 2025
 */
@IsTest
public class CVMAAdvancedAutomationControllerTest {

    /**
     * Test data setup for advanced automation testing
     */
    @TestSetup
    static void setupTestData() {
        // Create diverse member dataset for automation testing
        List<Contact> testMembers = new List<Contact>();

        // High-risk members for intervention testing
        for (Integer i = 0; i < 5; i++) {
            Contact highRiskMember = CVMATestDataFactory.createContact()
                .withName('HighRisk' + i, 'Member')
                .withEmail('highrisk' + i + '@automation.test')
                .withMemberStatus('Inactive')
                .withMilitaryBranch('Army')
                .withDisabilityRating('90')
                .create();
            // Set last activity to over 180 days ago to trigger high risk
            highRiskMember.LastActivityDate = Date.today().addDays(-200);
            testMembers.add(highRiskMember);
        }

        // Medium-risk members
        for (Integer i = 0; i < 8; i++) {
            Contact mediumRiskMember = CVMATestDataFactory.createContact()
                .withName('MediumRisk' + i, 'Member')
                .withEmail('mediumrisk' + i + '@automation.test')
                .withMemberStatus('Associate Member')
                .withMilitaryBranch('Navy')
                .withDisabilityRating('60')
                .create();
            // Set last activity to 90-180 days ago
            mediumRiskMember.LastActivityDate = Date.today().addDays(-120);
            testMembers.add(mediumRiskMember);
        }

        // Active, engaged members
        for (Integer i = 0; i < 12; i++) {
            Contact activeMember = CVMATestDataFactory.createContact()
                .withName('Active' + i, 'Member')
                .withEmail('active' + i + '@automation.test')
                .withMemberStatus('Full Member')
                .withMilitaryBranch('Marine Corps')
                .withDisabilityRating('40')
                .create();
            // Set recent activity
            activeMember.LastActivityDate = Date.today().addDays(-Math.mod(i, 30));
            testMembers.add(activeMember);
        }

        insert testMembers;

        System.debug('CVMAAdvancedAutomationControllerTest: Test data setup completed');
    }

    /**
     * Test main advanced automation method
     */
    @IsTest
    static void testGetAdvancedAutomation() {
        Test.startTest();

        Map<String, Object> result = CVMAAdvancedAutomationController.getAdvancedAutomation();

        Test.stopTest();

        // Verify automation data structure
        System.assertNotEquals(null, result, 'Advanced automation should return data');
        System.assert(result.containsKey('automationStatus'), 'Should contain automation status');
        System.assert(result.containsKey('workflowOptimization'), 'Should contain workflow optimization');
        System.assert(result.containsKey('memberServicesAutomation'), 'Should contain member services automation');
        System.assert(result.containsKey('operationalAutomation'), 'Should contain operational automation');
        System.assert(result.containsKey('crossEpicAutomation'), 'Should contain cross-epic automation');
        System.assert(result.containsKey('adaptiveLearning'), 'Should contain adaptive learning');

        // Verify automation status
        Map<String, Object> automationStatus = (Map<String, Object>) result.get('automationStatus');
        System.assertEquals(true, automationStatus.get('aiWorkflowOptimization'), 'AI workflow optimization should be active');
        System.assertEquals(true, automationStatus.get('adaptiveLearningOperational'), 'Adaptive learning should be operational');
        System.assertEquals(true, automationStatus.get('processAutomationDeployed'), 'Process automation should be deployed');

        System.debug('CVMAAdvancedAutomationControllerTest: Main automation test completed successfully');
    }

    /**
     * Test workflow optimization functionality
     */
    @IsTest
    static void testGetWorkflowOptimization() {
        Test.startTest();

        Map<String, Object> result = CVMAAdvancedAutomationController.getWorkflowOptimization();

        Test.stopTest();

        // Verify workflow optimization data structure
        System.assertNotEquals(null, result, 'Workflow optimization should return data');
        System.assert(result.containsKey('workflowAnalysis'), 'Should contain workflow analysis');
        System.assert(result.containsKey('bottleneckIdentification'), 'Should contain bottleneck identification');
        System.assert(result.containsKey('efficiencyOptimization'), 'Should contain efficiency optimization');
        System.assert(result.containsKey('automationOpportunities'), 'Should contain automation opportunities');

        System.debug('CVMAAdvancedAutomationControllerTest: Workflow optimization test completed successfully');
    }

    /**
     * Test member services automation functionality
     */
    @IsTest
    static void testGetMemberServicesAutomation() {
        Test.startTest();

        Map<String, Object> result = CVMAAdvancedAutomationController.getMemberServicesAutomation();

        Test.stopTest();

        // Verify member services automation data structure
        System.assertNotEquals(null, result, 'Member services automation should return data');
        System.assert(result.containsKey('automatedOutreach'), 'Should contain automated outreach');
        System.assert(result.containsKey('riskIdentification'), 'Should contain risk identification');
        System.assert(result.containsKey('personalizedCommunications'), 'Should contain personalized communications');
        System.assert(result.containsKey('retentionAutomation'), 'Should contain retention automation');

        // Verify risk identification includes member analysis
        Map<String, Object> riskIdentification = (Map<String, Object>) result.get('riskIdentification');
        System.assertNotEquals(null, riskIdentification.get('totalMembers'), 'Should analyze total members');
        System.assertNotEquals(null, riskIdentification.get('overallRiskLevel'), 'Should calculate overall risk level');

        System.debug('CVMAAdvancedAutomationControllerTest: Member services automation test completed successfully');
    }

    /**
     * Test operational automation functionality
     */
    @IsTest
    static void testGetOperationalAutomation() {
        Test.startTest();

        Map<String, Object> result = CVMAAdvancedAutomationController.getOperationalAutomation();

        Test.stopTest();

        // Verify operational automation data structure
        System.assertNotEquals(null, result, 'Operational automation should return data');
        System.assert(result.containsKey('performanceMonitoring'), 'Should contain performance monitoring');
        System.assert(result.containsKey('qualityMetrics'), 'Should contain quality metrics');
        System.assert(result.containsKey('processEfficiency'), 'Should contain process efficiency');
        System.assert(result.containsKey('continuousImprovement'), 'Should contain continuous improvement');

        System.debug('CVMAAdvancedAutomationControllerTest: Operational automation test completed successfully');
    }

    /**
     * Test cross-epic automation functionality
     */
    @IsTest
    static void testGetCrossEpicAutomation() {
        Test.startTest();

        Map<String, Object> result = CVMAAdvancedAutomationController.getCrossEpicAutomation();

        Test.stopTest();

        // Verify cross-epic automation data structure
        System.assertNotEquals(null, result, 'Cross-epic automation should return data');
        System.assert(result.containsKey('epicIntegrationStatus'), 'Should contain epic integration status');
        System.assert(result.containsKey('dataFlowOptimization'), 'Should contain data flow optimization');
        System.assert(result.containsKey('performanceOptimization'), 'Should contain performance optimization');

        System.debug('CVMAAdvancedAutomationControllerTest: Cross-epic automation test completed successfully');
    }

    /**
     * Test adaptive learning functionality
     */
    @IsTest
    static void testGetAdaptiveLearning() {
        Test.startTest();

        Map<String, Object> result = CVMAAdvancedAutomationController.getAdaptiveLearning();

        Test.stopTest();

        // Verify adaptive learning data structure
        System.assertNotEquals(null, result, 'Adaptive learning should return data');
        System.assert(result.containsKey('learningModels'), 'Should contain learning models');
        System.assert(result.containsKey('patternRecognition'), 'Should contain pattern recognition');
        System.assert(result.containsKey('predictiveModeling'), 'Should contain predictive modeling');
        System.assert(result.containsKey('selfOptimization'), 'Should contain self optimization');

        System.debug('CVMAAdvancedAutomationControllerTest: Adaptive learning test completed successfully');
    }

    /**
     * Test member risk scoring calculations
     */
    @IsTest
    static void testMemberRiskScoring() {
        Test.startTest();

        Map<String, Object> result = CVMAAdvancedAutomationController.getMemberServicesAutomation();

        Test.stopTest();

        // Verify risk identification includes proper analysis
        Map<String, Object> riskIdentification = (Map<String, Object>) result.get('riskIdentification');

        Integer highRiskCount = (Integer) riskIdentification.get('highRiskCount');
        Integer mediumRiskCount = (Integer) riskIdentification.get('mediumRiskCount');
        Integer lowRiskCount = (Integer) riskIdentification.get('lowRiskCount');
        Integer totalMembers = (Integer) riskIdentification.get('totalMembers');

        // Verify risk counts are logical
        System.assert(highRiskCount >= 0, 'High risk count should be non-negative');
        System.assert(mediumRiskCount >= 0, 'Medium risk count should be non-negative');
        System.assert(lowRiskCount >= 0, 'Low risk count should be non-negative');
        System.assertEquals(totalMembers, highRiskCount + mediumRiskCount + lowRiskCount, 'Risk counts should sum to total');

        // Verify we have some high-risk members from our test data setup
        System.assert(highRiskCount > 0, 'Should identify high-risk members from test data');

        System.debug('CVMAAdvancedAutomationControllerTest: Member risk scoring test completed successfully');
    }

    /**
     * Test error handling scenarios
     */
    @IsTest
    static void testErrorHandling() {
        // Test with no data available
        delete [SELECT Id FROM Contact];

        Test.startTest();

        Map<String, Object> automationResult = CVMAAdvancedAutomationController.getAdvancedAutomation();
        Map<String, Object> workflowResult = CVMAAdvancedAutomationController.getWorkflowOptimization();
        Map<String, Object> memberServicesResult = CVMAAdvancedAutomationController.getMemberServicesAutomation();

        Test.stopTest();

        // Verify error handling provides default data
        System.assertNotEquals(null, automationResult, 'Should handle errors gracefully with default data');
        System.assertNotEquals(null, workflowResult, 'Should handle workflow errors gracefully');
        System.assertNotEquals(null, memberServicesResult, 'Should handle member services errors gracefully');

        System.debug('CVMAAdvancedAutomationControllerTest: Error handling test completed successfully');
    }

    /**
     * Test data security and permissions
     */
    @IsTest
    static void testDataSecurity() {
        // Create user with limited permissions
        User limitedUser = CVMATestDataFactory.createUser()
            .withProfile('Standard User')
            .withEmail('limited@automation.test')
            .create();

        Test.startTest();

        System.runAs(limitedUser) {
            try {
                Map<String, Object> result = CVMAAdvancedAutomationController.getAdvancedAutomation();
                System.assertNotEquals(null, result, 'Should handle limited permissions gracefully');
            } catch (Exception e) {
                System.assert(e.getMessage().contains('permissions') ||
                             e.getMessage().contains('access'), 'Should provide meaningful security error message');
            }
        }

        Test.stopTest();

        System.debug('CVMAAdvancedAutomationControllerTest: Data security test completed successfully');
    }

    /**
     * Test workflow efficiency calculations
     */
    @IsTest
    static void testWorkflowEfficiencyCalculations() {
        Test.startTest();

        Map<String, Object> result = CVMAAdvancedAutomationController.getWorkflowOptimization();

        Test.stopTest();

        // Verify workflow analysis includes efficiency metrics
        Map<String, Object> workflowAnalysis = (Map<String, Object>) result.get('workflowAnalysis');
        if (workflowAnalysis != null) {
            System.assertNotEquals(null, workflowAnalysis.get('overallEfficiency'), 'Should calculate overall efficiency');
            System.assertNotEquals(null, workflowAnalysis.get('bottleneckCount'), 'Should identify bottleneck count');
            System.assertNotEquals(null, workflowAnalysis.get('automationLevel'), 'Should measure automation level');
        }

        System.debug('CVMAAdvancedAutomationControllerTest: Workflow efficiency test completed successfully');
    }

    /**
     * Test integration with Epic #8 components
     */
    @IsTest
    static void testEpic8Integration() {
        Test.startTest();

        // Test integration with other Epic #8 Phase 3 components
        Map<String, Object> advancedAutomation = CVMAAdvancedAutomationController.getAdvancedAutomation();

        Test.stopTest();

        // Verify integration status includes phase information
        System.assert(advancedAutomation.containsKey('automationStatus'), 'Should indicate automation status');

        Map<String, Object> automationStatus = (Map<String, Object>) advancedAutomation.get('automationStatus');
        System.assertNotEquals(null, automationStatus.get('automationMCPCapacity'), 'Should show MCP capacity');

        System.debug('CVMAAdvancedAutomationControllerTest: Epic #8 integration test completed successfully');
    }

    /**
     * Test performance with large datasets
     */
    @IsTest
    static void testPerformanceWithLargeDataset() {
        // Create additional test data to simulate larger dataset
        List<Contact> largeDataSet = new List<Contact>();

        for (Integer i = 0; i < 100; i++) {
            Contact member = CVMATestDataFactory.createContact()
                .withName('LargeSet' + i, 'Member')
                .withEmail('largeset' + i + '@automation.test')
                .withMemberStatus('Full Member')
                .withMilitaryBranch('Air Force')
                .create();
            largeDataSet.add(member);
        }

        insert largeDataSet;

        Test.startTest();

        Map<String, Object> result = CVMAAdvancedAutomationController.getAdvancedAutomation();

        Test.stopTest();

        // Verify performance with larger dataset
        System.assertNotEquals(null, result, 'Should handle large datasets efficiently');
        System.assert(result.containsKey('automationStatus'), 'Should maintain functionality with large datasets');

        System.debug('CVMAAdvancedAutomationControllerTest: Performance test with large dataset completed successfully');
    }

    /**
     * Test automation opportunity identification
     */
    @IsTest
    static void testAutomationOpportunityIdentification() {
        Test.startTest();

        Map<String, Object> result = CVMAAdvancedAutomationController.getWorkflowOptimization();

        Test.stopTest();

        // Verify automation opportunities are identified
        System.assert(result.containsKey('automationOpportunities'), 'Should identify automation opportunities');
        System.assert(result.containsKey('processImprovements'), 'Should suggest process improvements');
        System.assert(result.containsKey('workflowRedesign'), 'Should recommend workflow redesign');

        System.debug('CVMAAdvancedAutomationControllerTest: Automation opportunity identification test completed successfully');
    }
}
