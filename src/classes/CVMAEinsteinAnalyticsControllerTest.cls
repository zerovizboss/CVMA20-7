/**
 * CVMAEinsteinAnalyticsControllerTest
 *
 * Test class for CVMAEinsteinAnalyticsController
 * Ensures comprehensive test coverage for Einstein Analytics functionality
 *
 * @author CVMA Development Team
 * @version 1.0
 * @since Epic #8 Phase 3
 */
@IsTest
private class CVMAEinsteinAnalyticsControllerTest {

    /**
     * Setup test data for Einstein Analytics tests
     */
    @TestSetup
    static void setupTestData() {
        // Create test contacts with various engagement levels
        List<Contact> testContacts = new List<Contact>();

        // High engagement members
        for (Integer i = 0; i < 5; i++) {
            Contact highEngagement = CVMATestDataFactory.createContact()
                .withFirstName('HighEngagement')
                .withLastName('Member' + i)
                .withLevel('Full Member')
                .withEmail('highengagement' + i + '@cvma.test')
                .create();
            testContacts.add(highEngagement);
        }

        // Medium engagement members
        for (Integer i = 0; i < 3; i++) {
            Contact mediumEngagement = CVMATestDataFactory.createContact()
                .withFirstName('MediumEngagement')
                .withLastName('Member' + i)
                .withLevel('Support Member')
                .withEmail('mediumengagement' + i + '@cvma.test')
                .create();
            testContacts.add(mediumEngagement);
        }

        // Low engagement / at-risk members
        for (Integer i = 0; i < 2; i++) {
            Contact lowEngagement = CVMATestDataFactory.createContact()
                .withFirstName('LowEngagement')
                .withLastName('Member' + i)
                .withLevel('Auxiliary Member')
                .withEmail('lowengagement' + i + '@cvma.test')
                .create();
            testContacts.add(lowEngagement);
        }

        // Create some test events for event success prediction
        List<Event> testEvents = new List<Event>();
        for (Integer i = 0; i < 3; i++) {
            Event testEvent = new Event(
                Subject = 'Test Chapter Meeting ' + i,
                StartDateTime = DateTime.now().addDays(-30 + (i * 10)),
                EndDateTime = DateTime.now().addDays(-30 + (i * 10)).addHours(2),
                WhoId = testContacts[i].Id
            );
            testEvents.add(testEvent);
        }
        insert testEvents;

        // Create some donation opportunities for engagement tracking
        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            Opportunity testOpp = new Opportunity(
                Name = 'Test Donation ' + i,
                StageName = 'Closed Won',
                CloseDate = Date.today().addDays(-15 + (i * 5)),
                Amount = 50.00,
                npe01__Contact_Id_for_Role__c = testContacts[i].Id
            );
            testOpportunities.add(testOpp);
        }
        insert testOpportunities;
    }

    /**
     * Test the main Einstein Analytics method
     */
    @IsTest
    static void testGetEinsteinPredictiveAnalytics() {
        Test.startTest();

        Map<String, Object> analyticsData = CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics();

        Test.stopTest();

        // Verify core metrics are present
        System.assertNotEquals(null, analyticsData, 'Analytics data should not be null');
        System.assert(analyticsData.containsKey('predictive_accuracy'), 'Should contain predictive accuracy');
        System.assert(analyticsData.containsKey('member_retention_forecast'), 'Should contain retention forecast');
        System.assert(analyticsData.containsKey('event_success_prediction'), 'Should contain event prediction');

        // Verify accuracy is within expected range
        Decimal accuracy = (Decimal) analyticsData.get('predictive_accuracy');
        System.assert(accuracy >= 75.0 && accuracy <= 98.0, 'Accuracy should be between 75-98%');

        // Verify retention forecast is reasonable
        Decimal retention = (Decimal) analyticsData.get('member_retention_forecast');
        System.assert(retention >= 75.0 && retention <= 95.0, 'Retention forecast should be between 75-95%');

        // Verify event success prediction
        Decimal eventSuccess = (Decimal) analyticsData.get('event_success_prediction');
        System.assert(eventSuccess >= 65.0 && eventSuccess <= 92.0, 'Event success should be between 65-92%');
    }

    /**
     * Test analytics with no data scenario
     */
    @IsTest
    static void testAnalyticsWithNoData() {
        // Delete all test data to simulate empty org
        delete [SELECT Id FROM Contact WHERE Email LIKE '%@cvma.test'];
        delete [SELECT Id FROM Event WHERE Subject LIKE 'Test Chapter Meeting%'];
        delete [SELECT Id FROM Opportunity WHERE Name LIKE 'Test Donation%'];

        Test.startTest();

        Map<String, Object> analyticsData = CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics();

        Test.stopTest();

        // Verify defaults are returned
        System.assertNotEquals(null, analyticsData, 'Analytics data should not be null even with no data');

        Decimal accuracy = (Decimal) analyticsData.get('predictive_accuracy');
        System.assertEquals(85.0, accuracy, 'Should return default accuracy of 85%');

        Decimal retention = (Decimal) analyticsData.get('member_retention_forecast');
        System.assertEquals(88.5, retention, 'Should return default retention forecast');
    }

    /**
     * Test engagement trend analysis
     */
    @IsTest
    static void testEngagementTrendAnalysis() {
        Test.startTest();

        Map<String, Object> analyticsData = CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics();

        Test.stopTest();

        // Verify engagement trend data is present
        System.assert(analyticsData.containsKey('engagement_trend_analysis'), 'Should contain engagement trends');

        Map<String, Object> trendData = (Map<String, Object>) analyticsData.get('engagement_trend_analysis');
        System.assert(trendData.containsKey('trend_direction'), 'Should contain trend direction');
        System.assert(trendData.containsKey('current_month_engagement'), 'Should contain current month data');
    }

    /**
     * Test churn risk member identification
     */
    @IsTest
    static void testChurnRiskMembers() {
        Test.startTest();

        Map<String, Object> analyticsData = CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics();

        Test.stopTest();

        // Verify churn risk data is present
        System.assert(analyticsData.containsKey('churn_risk_members'), 'Should contain churn risk analysis');

        List<Object> riskMembers = (List<Object>) analyticsData.get('churn_risk_members');
        System.assertNotEquals(null, riskMembers, 'Risk members list should not be null');

        // If we have risk members, verify structure
        if (!riskMembers.isEmpty()) {
            Map<String, Object> riskMember = (Map<String, Object>) riskMembers[0];
            System.assert(riskMember.containsKey('memberId'), 'Risk member should have ID');
            System.assert(riskMember.containsKey('riskScore'), 'Risk member should have risk score');
            System.assert(riskMember.containsKey('recommendedAction'), 'Risk member should have recommended action');
        }
    }

    /**
     * Test model performance metrics
     */
    @IsTest
    static void testModelPerformanceMetrics() {
        Test.startTest();

        Map<String, Object> analyticsData = CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics();

        Test.stopTest();

        // Verify model performance data
        System.assert(analyticsData.containsKey('model_performance'), 'Should contain model performance');

        Map<String, Object> modelPerf = (Map<String, Object>) analyticsData.get('model_performance');
        System.assert(modelPerf.containsKey('retention_model_accuracy'), 'Should have retention model accuracy');
        System.assert(modelPerf.containsKey('engagement_model_accuracy'), 'Should have engagement model accuracy');
        System.assert(modelPerf.containsKey('event_prediction_accuracy'), 'Should have event prediction accuracy');
    }

    /**
     * Test error handling
     */
    @IsTest
    static void testErrorHandling() {
        Test.startTest();

        try {
            Map<String, Object> analyticsData = CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics();
            // Should still return some data even with limited access
            System.assertNotEquals(null, analyticsData, 'Should handle errors gracefully');
        } catch (AuraHandledException e) {
            // Expected behavior for permission errors
            System.assert(e.getMessage().contains('Failed to load Einstein Analytics'), 'Should throw descriptive error');
        }

        Test.stopTest();
    }

    /**
     * Test caching functionality
     */
    @IsTest
    static void testCaching() {
        Test.startTest();

        // First call should populate cache
        Map<String, Object> firstCall = CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics();

        // Second call should use cache (would be faster in real scenario)
        Map<String, Object> secondCall = CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics();

        Test.stopTest();

        // Verify both calls return data
        System.assertNotEquals(null, firstCall, 'First call should return data');
        System.assertNotEquals(null, secondCall, 'Second call should return cached data');

        // Verify cache consistency (should be same data)
        System.assertEquals(
            firstCall.get('predictive_accuracy'),
            secondCall.get('predictive_accuracy'),
            'Cached data should match original'
        );
    }
}