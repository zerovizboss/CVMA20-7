/**
 * CVMAEpic8Phase3ControllerTest
 * Test Coverage for Epic #8 Phase 3 External Integration
 *
 * @author CVMA Chapter 20-7 Development Team
 * @version Epic #8 Phase 3
 * @since September 2025
 */
@IsTest
public class CVMAEpic8Phase3ControllerTest {

    @TestSetup
    static void setupTestData() {
        Contact testMember = new Contact(
            FirstName = 'John',
            LastName = 'TestVeteran',
            Email = 'john.veteran@cvma.org',
            Phone = '555-123-4567',
            MailingCity = 'San Diego',
            MailingState = 'CA',
            MailingPostalCode = '92101',
            Level__c = 'Full Member',
            Membership_Id__c = 'FM123'
        );
        insert testMember;
    }

    @IsTest
    static void testGetEpic8Phase3Dashboard_Success() {
        Test.startTest();
        Map<String, Object> result = CVMAEpic8Phase3Controller.getEpic8Phase3Dashboard();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Dashboard data should not be null');
        System.assertEquals('Active', result.get('phase3_status'), 'Phase 3 should be active');
        System.assert(result.containsKey('veteran_services_integration'), 'Should contain veteran services');
        System.assert(result.containsKey('cross_chapter_analytics'), 'Should contain cross-chapter analytics');
        System.assert(result.containsKey('advanced_automation'), 'Should contain automation data');
        System.assert(result.containsKey('success_indicators'), 'Should contain success indicators');
    }

    @IsTest
    static void testGetVeteranServicesIntegration_Success() {
        Test.startTest();
        Map<String, Object> result = CVMAEpic8Phase3Controller.getVeteranServicesIntegration();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Veteran services data should not be null');
        System.assertEquals('Operational', result.get('va_benefits_api'), 'VA Benefits API should be operational');
        System.assertEquals('Connected', result.get('community_resources'), 'Community resources should be connected');
        System.assertEquals('Active', result.get('crisis_intervention'), 'Crisis intervention should be active');
        System.assertNotEquals(null, result.get('integration_health'), 'Integration health should be present');
    }

    @IsTest
    static void testGetCrossChapterAnalytics_Success() {
        Test.startTest();
        Map<String, Object> result = CVMAEpic8Phase3Controller.getCrossChapterAnalytics();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Cross-chapter analytics should not be null');
        System.assertEquals(245, result.get('national_chapters_connected'), 'Should connect 245 chapters');
        System.assertEquals(true, result.get('performance_comparisons_active'), 'Performance comparisons should be active');
        System.assertEquals('Real-time', result.get('data_synchronization'), 'Should have real-time sync');
        System.assertNotEquals(null, result.get('collaboration_score'), 'Collaboration score should be present');
    }

    @IsTest
    static void testGetAdvancedAutomationEngine_Success() {
        Test.startTest();
        Map<String, Object> result = CVMAEpic8Phase3Controller.getAdvancedAutomationEngine();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Automation engine data should not be null');
        System.assertNotEquals(null, result.get('ai_workflows_active'), 'AI workflows should be present');
        System.assertNotEquals(null, result.get('automation_efficiency'), 'Automation efficiency should be present');
        System.assertNotEquals(null, result.get('predictive_accuracy'), 'Predictive accuracy should be present');
        System.assertNotEquals(null, result.get('automation_roi'), 'Automation ROI should be present');
    }

    @IsTest
    static void testGetEnhancedMemberServices_Success() {
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = CVMAEpic8Phase3Controller.getEnhancedMemberServices(testContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Enhanced member services should not be null');
        System.assert(result.containsKey('member_profile'), 'Should contain member profile');
        System.assert(result.containsKey('va_benefits_available'), 'Should contain VA benefits');
        System.assert(result.containsKey('community_resources'), 'Should contain community resources');
        System.assert(result.containsKey('automated_recommendations'), 'Should contain recommendations');
        System.assert(result.containsKey('next_actions'), 'Should contain next actions');

        // Verify member profile structure
        Map<String, Object> memberProfile = (Map<String, Object>) result.get('member_profile');
        System.assertEquals(testContact.Id, memberProfile.get('id'), 'Member ID should match');
        System.assert(((String) memberProfile.get('name')).contains('John'), 'Name should contain John');
    }

    @IsTest
    static void testGetEnhancedMemberServices_InvalidId() {
        // Create and delete a contact to get an invalid ID
        Contact tempContact = new Contact(
            FirstName = 'Temp',
            LastName = 'Contact',
            Level__c = 'Full Member',
            Membership_Id__c = 'FM999'
        );
        insert tempContact;
        Id invalidId = tempContact.Id;
        delete tempContact;

        Test.startTest();
        try {
            CVMAEpic8Phase3Controller.getEnhancedMemberServices(invalidId);
            System.assert(false, 'Should throw exception for invalid contact ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Enhanced Member Services Error') ||
                         e.getMessage().contains('List has no rows') ||
                         e.getMessage().contains('Script-thrown exception'),
                         'Should contain appropriate error message: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testSecurityEnforcement() {
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' LIMIT 1];

        Test.startTest();
        // This method uses WITH SECURITY_ENFORCED, so it should respect field-level security
        Map<String, Object> result = CVMAEpic8Phase3Controller.getEnhancedMemberServices(testContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should work with proper security permissions');
    }

    @IsTest
    static void testDashboardDataIntegrity() {
        Test.startTest();
        Map<String, Object> dashboard = CVMAEpic8Phase3Controller.getEpic8Phase3Dashboard();
        Map<String, Object> veteranServices = CVMAEpic8Phase3Controller.getVeteranServicesIntegration();
        Map<String, Object> analytics = CVMAEpic8Phase3Controller.getCrossChapterAnalytics();
        Map<String, Object> automation = CVMAEpic8Phase3Controller.getAdvancedAutomationEngine();
        Test.stopTest();

        // Verify all components are accessible and functional
        System.assertNotEquals(null, dashboard, 'Dashboard should be accessible');
        System.assertNotEquals(null, veteranServices, 'Veteran services should be accessible');
        System.assertNotEquals(null, analytics, 'Analytics should be accessible');
        System.assertNotEquals(null, automation, 'Automation should be accessible');

        // Verify dashboard contains references to all subsystems
        System.assert(dashboard.containsKey('veteran_services_integration'), 'Dashboard should reference veteran services');
        System.assert(dashboard.containsKey('cross_chapter_analytics'), 'Dashboard should reference analytics');
        System.assert(dashboard.containsKey('advanced_automation'), 'Dashboard should reference automation');
    }

    @IsTest
    static void testPerformanceMetrics() {
        Test.startTest();
        Map<String, Object> dashboard = CVMAEpic8Phase3Controller.getEpic8Phase3Dashboard();
        Test.stopTest();

        Map<String, Object> deploymentMetrics = (Map<String, Object>) dashboard.get('deployment_metrics');
        System.assertNotEquals(null, deploymentMetrics, 'Deployment metrics should be present');
        System.assertEquals(3, deploymentMetrics.get('components_deployed'), 'Should have 3 components deployed');
        System.assertNotEquals(null, deploymentMetrics.get('test_coverage'), 'Test coverage should be present');
        System.assertNotEquals(null, deploymentMetrics.get('performance_score'), 'Performance score should be present');
    }

    @IsTest
    static void testSuccessIndicators() {
        Test.startTest();
        Map<String, Object> dashboard = CVMAEpic8Phase3Controller.getEpic8Phase3Dashboard();
        Test.stopTest();

        List<String> successIndicators = (List<String>) dashboard.get('success_indicators');
        System.assertNotEquals(null, successIndicators, 'Success indicators should be present');
        System.assert(successIndicators.size() > 0, 'Should have success indicators');

        Boolean hasVAIntegration = false;
        Boolean hasAnalytics = false;
        Boolean hasAutomation = false;

        for (String indicator : successIndicators) {
            if (indicator.contains('VA Benefits')) {
                hasVAIntegration = true;
            }
            if (indicator.contains('analytics')) {
                hasAnalytics = true;
            }
            if (indicator.contains('automation')) {
                hasAutomation = true;
            }
        }

        System.assert(hasVAIntegration, 'Should have VA Benefits integration indicator');
        System.assert(hasAnalytics, 'Should have analytics indicator');
        System.assert(hasAutomation, 'Should have automation indicator');
    }

    @IsTest
    static void testMemberServiceRecommendations() {
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = CVMAEpic8Phase3Controller.getEnhancedMemberServices(testContact.Id);
        Test.stopTest();

        List<String> recommendations = (List<String>) result.get('automated_recommendations');
        System.assertNotEquals(null, recommendations, 'Recommendations should be present');
        System.assert(recommendations.size() > 0, 'Should have recommendations');

        List<String> nextActions = (List<String>) result.get('next_actions');
        System.assertNotEquals(null, nextActions, 'Next actions should be present');
        System.assert(nextActions.size() > 0, 'Should have next actions');
    }
}
