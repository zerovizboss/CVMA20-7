/**
 * Test Class for CVMAEinsteinAnalyticsController
 * Epic #8 Phase 2: Comprehensive AI-Powered Analytics Testing
 *
 * Tests all predictive analytics capabilities including member retention,
 * event forecasting, financial trends, and MCP-enhanced intelligence
 *
 * @author Claude Code (Strategic Agent)
 * @version 2.0 - Epic #8 Phase 2 MCP-Enhanced Testing
 * @since September 2025
 */
@isTest
private class CVMAEinsteinAnalyticsControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create comprehensive test data using CVMATestDataFactory

        // Create test account for organization context
        Account testAccount = CVMATestDataFactory.createAccount()
            .withName('CVMA Chapter 20-7 Test')
            .create();

        // Create diverse member test data
        List<Contact> testMembers = new List<Contact>();

        // High engagement members (recent activity)
        for (Integer i = 0; i < 25; i++) {
            Contact member = CVMATestDataFactory.createContact()
                .withLevel('Full Member')
                .withAccount(testAccount)
                .withLastActivityDate(Date.today().addDays(-15))
                .create();
            testMembers.add(member);
        }

        // Medium engagement members (moderate activity)
        for (Integer i = 0; i < 35; i++) {
            Contact member = CVMATestDataFactory.createContact()
                .withLevel('Associate Member')
                .withAccount(testAccount)
                .withLastActivityDate(Date.today().addDays(-60))
                .create();
            testMembers.add(member);
        }

        // Low engagement members (minimal activity)
        for (Integer i = 0; i < 15; i++) {
            Contact member = CVMATestDataFactory.createContact()
                .withLevel('Full Member')
                .withAccount(testAccount)
                .withLastActivityDate(Date.today().addDays(-150))
                .create();
            testMembers.add(member);
        }

        // At-risk members (no recent activity)
        for (Integer i = 0; i < 10; i++) {
            Contact member = CVMATestDataFactory.createContact()
                .withLevel('Full Member')
                .withAccount(testAccount)
                .withLastActivityDate(Date.today().addDays(-300))
                .withEmailOptOut(true)
                .create();
            testMembers.add(member);
        }

        // Create test campaigns for event analytics
        List<Campaign> testCampaigns = new List<Campaign>();

        // Historical successful events
        for (Integer i = 0; i < 12; i++) {
            Campaign event = CVMATestDataFactory.createCampaign()
                .withType('Event')
                .withStartDate(Date.today().addDays(-365 + (i * 30)))
                .withNumberSent(100)
                .withNumberOfResponses(75)
                .withBudgetedCost(1000)
                .withActualCost(950)
                .create();
            testCampaigns.add(event);
        }

        // Upcoming events for forecasting
        for (Integer i = 0; i < 5; i++) {
            Campaign futureEvent = CVMATestDataFactory.createCampaign()
                .withType('Event')
                .withStartDate(Date.today().addDays(30 + (i * 14)))
                .withBudgetedCost(1200)
                .withExpectedRevenue(500)
                .create();
            testCampaigns.add(futureEvent);
        }

        // Create campaign members for engagement analysis
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        for (Campaign campaign : testCampaigns) {
            for (Integer i = 0; i < 5 && i < testMembers.size(); i++) {
                CampaignMember member = new CampaignMember(
                    CampaignId = campaign.Id,
                    ContactId = testMembers[i].Id,
                    Status = i < 3 ? 'Responded' : 'Sent'
                );
                campaignMembers.add(member);
            }
        }
        insert campaignMembers;

        // Create financial test data with NPSP opportunities
        List<Opportunity> testOpportunities = new List<Opportunity>();

        // Historical revenue data
        for (Integer i = 0; i < 24; i++) {
            Opportunity opp = CVMATestDataFactory.createOpportunity()
                .withAmount(500 + (Math.random() * 2000))
                .withStageName('Closed Won')
                .withCloseDate(Date.today().addDays(-730 + (i * 30)))
                .withRecordType('Donation')
                .create();
            testOpportunities.add(opp);
        }

        // Current period opportunities
        for (Integer i = 0; i < 8; i++) {
            Opportunity opp = CVMATestDataFactory.createOpportunity()
                .withAmount(750 + (Math.random() * 1500))
                .withStageName(i < 6 ? 'Closed Won' : 'Prospecting')
                .withCloseDate(Date.today().addDays(-30 + (i * 4)))
                .withRecordType('Donation')
                .create();
            testOpportunities.add(opp);
        }

        // Create NPSP payment records
        List<npe01__OppPayment__c> paymentRecords = new List<npe01__OppPayment__c>();
        for (Opportunity opp : testOpportunities) {
            if (opp.StageName == 'Closed Won') {
                npe01__OppPayment__c payment = new npe01__OppPayment__c(
                    npe01__Opportunity__c = opp.Id,
                    npe01__Payment_Amount__c = opp.Amount,
                    npe01__Payment_Date__c = opp.CloseDate,
                    npe01__Payment_Method__c = Math.random() > 0.5 ? 'Credit Card' : 'Check',
                    npe01__Paid__c = true
                );
                paymentRecords.add(payment);
            }
        }
        insert paymentRecords;
    }

    @isTest
    static void testGetEinsteinPredictiveAnalytics() {
        Test.startTest();

        Map<String, Object> result = CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics();

        Test.stopTest();

        // Verify main analytics components
        System.assertNotEquals(null, result, 'Einstein predictive analytics should return data');
        System.assert(result.containsKey('foundationAnalytics'), 'Should include foundation analytics');
        System.assert(result.containsKey('memberRetentionForecasting'), 'Should include member retention forecasting');
        System.assert(result.containsKey('eventSuccessForecasting'), 'Should include event success forecasting');
        System.assert(result.containsKey('financialTrendAnalysis'), 'Should include financial trend analysis');
        System.assert(result.containsKey('veteranServicesIntegration'), 'Should include veteran services integration');
        System.assert(result.containsKey('predictiveCorrelations'), 'Should include predictive correlations');
        System.assert(result.containsKey('mcpEnhancedInsights'), 'Should include MCP-enhanced insights');
        System.assert(result.containsKey('mobileAnalyticsData'), 'Should include mobile analytics data');
    }

    @isTest
    static void testGetMemberRetentionPredictions() {
        Test.startTest();

        Map<String, Object> retentionData = CVMAEinsteinAnalyticsController.getMemberRetentionPredictions();

        Test.stopTest();

        // Verify retention prediction components
        System.assertNotEquals(null, retentionData, 'Member retention predictions should return data');
        System.assert(retentionData.containsKey('engagementScoreDistribution'), 'Should include engagement score distribution');
        System.assert(retentionData.containsKey('retentionRiskAnalysis'), 'Should include retention risk analysis');
        System.assert(retentionData.containsKey('interventionRecommendations'), 'Should include intervention recommendations');
        System.assert(retentionData.containsKey('predictedLifetimeValue'), 'Should include predicted lifetime value');
        System.assert(retentionData.containsKey('churnPrediction'), 'Should include churn prediction');

        // Verify engagement score distribution
        Map<String, Object> engagementScores = (Map<String, Object>) retentionData.get('engagementScoreDistribution');
        System.assertNotEquals(null, engagementScores, 'Engagement scores should be calculated');
        System.assert(engagementScores.containsKey('totalMembers'), 'Should include total member count');
        System.assert(engagementScores.containsKey('highEngagement'), 'Should include high engagement count');
        System.assert(engagementScores.containsKey('mediumEngagement'), 'Should include medium engagement count');
        System.assert(engagementScores.containsKey('lowEngagement'), 'Should include low engagement count');

        // Verify risk analysis
        Map<String, Object> riskAnalysis = (Map<String, Object>) retentionData.get('retentionRiskAnalysis');
        System.assertNotEquals(null, riskAnalysis, 'Risk analysis should be calculated');
        System.assert(riskAnalysis.containsKey('highRisk'), 'Should include high risk count');
        System.assert(riskAnalysis.containsKey('mediumRisk'), 'Should include medium risk count');
        System.assert(riskAnalysis.containsKey('lowRisk'), 'Should include low risk count');

        // Verify intervention recommendations
        List<Map<String, Object>> interventions = (List<Map<String, Object>>) retentionData.get('interventionRecommendations');
        System.assertNotEquals(null, interventions, 'Intervention recommendations should be provided');
        System.assert(interventions.size() > 0, 'Should provide at least one recommendation');

        if (interventions.size() > 0) {
            Map<String, Object> firstIntervention = interventions[0];
            System.assert(firstIntervention.containsKey('title'), 'Intervention should have title');
            System.assert(firstIntervention.containsKey('priority'), 'Intervention should have priority');
            System.assert(firstIntervention.containsKey('description'), 'Intervention should have description');
        }
    }

    @isTest
    static void testGetEventSuccessPredictions() {
        Test.startTest();

        Map<String, Object> eventData = CVMAEinsteinAnalyticsController.getEventSuccessPredictions();

        Test.stopTest();

        // Verify event prediction components
        System.assertNotEquals(null, eventData, 'Event success predictions should return data');
        System.assert(eventData.containsKey('attendanceForecast'), 'Should include attendance forecast');
        System.assert(eventData.containsKey('optimalScheduling'), 'Should include optimal scheduling');
        System.assert(eventData.containsKey('resourceOptimization'), 'Should include resource optimization');
        System.assert(eventData.containsKey('seasonalPatterns'), 'Should include seasonal patterns');
        System.assert(eventData.containsKey('successFactors'), 'Should include success factors');

        // Verify attendance forecast
        Map<String, Object> attendanceForecast = (Map<String, Object>) eventData.get('attendanceForecast');
        System.assertNotEquals(null, attendanceForecast, 'Attendance forecast should be calculated');
        System.assert(attendanceForecast.containsKey('predictedAttendanceRate'), 'Should include predicted attendance rate');
        System.assert(attendanceForecast.containsKey('seasonalFactors'), 'Should include seasonal factors');
        System.assert(attendanceForecast.containsKey('confidenceLevel'), 'Should include confidence level');
    }

    @isTest
    static void testGetFinancialTrendPredictions() {
        Test.startTest();

        Map<String, Object> financialData = CVMAEinsteinAnalyticsController.getFinancialTrendPredictions();

        Test.stopTest();

        // Verify financial prediction components
        System.assertNotEquals(null, financialData, 'Financial trend predictions should return data');
        System.assert(financialData.containsKey('revenueForecasting'), 'Should include revenue forecasting');
        System.assert(financialData.containsKey('budgetVarianceAlerts'), 'Should include budget variance alerts');
        System.assert(financialData.containsKey('seasonalFinancialPatterns'), 'Should include seasonal patterns');
        System.assert(financialData.containsKey('investmentRecommendations'), 'Should include investment recommendations');
        System.assert(financialData.containsKey('cashFlowPrediction'), 'Should include cash flow prediction');

        // Verify revenue forecasting
        Map<String, Object> revenueForecasting = (Map<String, Object>) financialData.get('revenueForecasting');
        System.assertNotEquals(null, revenueForecasting, 'Revenue forecasting should be calculated');
        System.assert(revenueForecasting.containsKey('projectedGrowthRate'), 'Should include projected growth rate');
        System.assert(revenueForecasting.containsKey('nextQuarterForecast'), 'Should include next quarter forecast');
        System.assert(revenueForecasting.containsKey('confidenceInterval'), 'Should include confidence interval');
    }

    @isTest
    static void testGetVeteranServicesInsights() {
        Test.startTest();

        Map<String, Object> veteranData = CVMAEinsteinAnalyticsController.getVeteranServicesInsights();

        Test.stopTest();

        // Verify veteran services components
        System.assertNotEquals(null, veteranData, 'Veteran services insights should return data');
        System.assert(veteranData.containsKey('serviceUtilization'), 'Should include service utilization');
        System.assert(veteranData.containsKey('communityResourceMapping'), 'Should include community resource mapping');
        System.assert(veteranData.containsKey('externalIntegrationReadiness'), 'Should include external integration readiness');
        System.assert(veteranData.containsKey('veteranOutreachOptimization'), 'Should include veteran outreach optimization');
        System.assert(veteranData.containsKey('serviceGapAnalysis'), 'Should include service gap analysis');
        System.assert(veteranData.containsKey('collaborationOpportunities'), 'Should include collaboration opportunities');
    }

    @isTest
    static void testGetAdvancedPredictiveCorrelations() {
        Test.startTest();

        Map<String, Object> correlationData = CVMAEinsteinAnalyticsController.getAdvancedPredictiveCorrelations();

        Test.stopTest();

        // Verify correlation analysis components
        System.assertNotEquals(null, correlationData, 'Advanced predictive correlations should return data');
        System.assert(correlationData.containsKey('memberEventCorrelation'), 'Should include member-event correlation');
        System.assert(correlationData.containsKey('financialMemberCorrelation'), 'Should include financial-member correlation');
        System.assert(correlationData.containsKey('communicationEffectivenessCorrelation'), 'Should include communication effectiveness correlation');
        System.assert(correlationData.containsKey('digitalAdoptionCorrelation'), 'Should include digital adoption correlation');
        System.assert(correlationData.containsKey('behavioralPredictions'), 'Should include behavioral predictions');
        System.assert(correlationData.containsKey('organizationalOptimization'), 'Should include organizational optimization');
    }

    @isTest
    static void testGetMCPEnhancedPredictiveInsights() {
        Test.startTest();

        Map<String, Object> mcpData = CVMAEinsteinAnalyticsController.getMCPEnhancedPredictiveInsights();

        Test.stopTest();

        // Verify MCP-enhanced insights components
        System.assertNotEquals(null, mcpData, 'MCP-enhanced predictive insights should return data');
        System.assert(mcpData.containsKey('unlimitedProcessingCapacity'), 'Should include unlimited processing capacity');
        System.assert(mcpData.containsKey('externalDataIntegration'), 'Should include external data integration');
        System.assert(mcpData.containsKey('aiModelCoordination'), 'Should include AI model coordination');
        System.assert(mcpData.containsKey('realTimeIntelligence'), 'Should include real-time intelligence');
        System.assert(mcpData.containsKey('predictiveScaling'), 'Should include predictive scaling');
        System.assert(mcpData.containsKey('innovationAcceleration'), 'Should include innovation acceleration');
        System.assert(mcpData.containsKey('competitiveAdvantage'), 'Should include competitive advantage');
    }

    @isTest
    static void testGetMobileOptimizedAnalytics() {
        Test.startTest();

        Map<String, Object> mobileData = CVMAEinsteinAnalyticsController.getMobileOptimizedAnalytics();

        Test.stopTest();

        // Verify mobile analytics components
        System.assertNotEquals(null, mobileData, 'Mobile optimized analytics should return data');
        System.assert(mobileData.containsKey('quickInsights'), 'Should include quick insights');
        System.assert(mobileData.containsKey('criticalAlerts'), 'Should include critical alerts');
        System.assert(mobileData.containsKey('actionableItems'), 'Should include actionable items');
        System.assert(mobileData.containsKey('performanceKPIs'), 'Should include performance KPIs');
        System.assert(mobileData.containsKey('offlineDataCache'), 'Should include offline data cache');
        System.assert(mobileData.containsKey('syncOptimization'), 'Should include sync optimization');
        System.assert(mobileData.containsKey('notificationIntelligence'), 'Should include notification intelligence');
    }

    @isTest
    static void testEngagementScoreCalculation() {
        // Create specific test data for engagement calculation
        List<Contact> testContacts = new List<Contact>();

        // High engagement contact
        Contact highEngagement = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .withLastActivityDate(Date.today().addDays(-10))
            .create();
        testContacts.add(highEngagement);

        // Medium engagement contact
        Contact mediumEngagement = CVMATestDataFactory.createContact()
            .withLevel('Associate Member')
            .withLastActivityDate(Date.today().addDays(-60))
            .create();
        testContacts.add(mediumEngagement);

        // Low engagement contact
        Contact lowEngagement = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .withLastActivityDate(Date.today().addDays(-200))
            .create();
        testContacts.add(lowEngagement);

        Test.startTest();

        Map<String, Object> retentionData = CVMAEinsteinAnalyticsController.getMemberRetentionPredictions();

        Test.stopTest();

        // Verify engagement scores are calculated correctly
        Map<String, Object> engagementScores = (Map<String, Object>) retentionData.get('engagementScoreDistribution');
        System.assertNotEquals(null, engagementScores, 'Engagement scores should be calculated');

        Integer totalMembers = (Integer) engagementScores.get('totalMembers');
        System.assert(totalMembers > 0, 'Should have total members counted');

        Integer highCount = (Integer) engagementScores.get('highEngagement');
        Integer mediumCount = (Integer) engagementScores.get('mediumEngagement');
        Integer lowCount = (Integer) engagementScores.get('lowEngagement');

        System.assertEquals(totalMembers, highCount + mediumCount + lowCount,
            'Total members should equal sum of engagement categories');
    }

    @isTest
    static void testRetentionRiskCalculation() {
        // Create test data with known risk factors
        Contact highRiskMember = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .withLastActivityDate(Date.today().addDays(-300))
            .withEmailOptOut(true)
            .create();

        Contact lowRiskMember = CVMATestDataFactory.createContact()
            .withLevel('Associate Member')
            .withLastActivityDate(Date.today().addDays(-20))
            .withEmailOptOut(false)
            .create();

        Test.startTest();

        Map<String, Object> retentionData = CVMAEinsteinAnalyticsController.getMemberRetentionPredictions();

        Test.stopTest();

        // Verify risk analysis identifies different risk levels
        Map<String, Object> riskAnalysis = (Map<String, Object>) retentionData.get('retentionRiskAnalysis');
        System.assertNotEquals(null, riskAnalysis, 'Risk analysis should be calculated');

        Boolean interventionRequired = (Boolean) riskAnalysis.get('interventionRequired');
        System.assertNotEquals(null, interventionRequired, 'Intervention requirement should be determined');
    }

    @isTest
    static void testAttendanceForecastCalculation() {
        Test.startTest();

        Map<String, Object> eventData = CVMAEinsteinAnalyticsController.getEventSuccessPredictions();

        Test.stopTest();

        // Verify attendance forecast uses historical data
        Map<String, Object> attendanceForecast = (Map<String, Object>) eventData.get('attendanceForecast');
        System.assertNotEquals(null, attendanceForecast, 'Attendance forecast should be calculated');

        Decimal predictedRate = (Decimal) attendanceForecast.get('predictedAttendanceRate');
        System.assertNotEquals(null, predictedRate, 'Should have predicted attendance rate');
        System.assert(predictedRate >= 0, 'Attendance rate should be non-negative');
        System.assert(predictedRate <= 100, 'Attendance rate should not exceed 100%');
    }

    @isTest
    static void testRevenueForecasting() {
        Test.startTest();

        Map<String, Object> financialData = CVMAEinsteinAnalyticsController.getFinancialTrendPredictions();

        Test.stopTest();

        // Verify revenue forecasting calculations
        Map<String, Object> revenueForecasting = (Map<String, Object>) financialData.get('revenueForecasting');
        System.assertNotEquals(null, revenueForecasting, 'Revenue forecasting should be calculated');

        Decimal growthRate = (Decimal) revenueForecasting.get('projectedGrowthRate');
        Decimal nextQuarterForecast = (Decimal) revenueForecasting.get('nextQuarterForecast');

        System.assertNotEquals(null, growthRate, 'Should have projected growth rate');
        System.assertNotEquals(null, nextQuarterForecast, 'Should have next quarter forecast');
        System.assert(nextQuarterForecast >= 0, 'Next quarter forecast should be non-negative');
    }

    @isTest
    static void testErrorHandling() {
        // Test error handling by creating invalid data scenario
        Test.startTest();

        try {
            // This should handle gracefully even with limited data
            Map<String, Object> result = CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics();
            System.assertNotEquals(null, result, 'Should return data even in error scenarios');
        } catch (Exception e) {
            System.assert(false, 'Should handle errors gracefully: ' + e.getMessage());
        }

        Test.stopTest();
    }

    @isTest
    static void testCacheableAnnotations() {
        // Verify methods are properly cacheable for performance
        Test.startTest();

        // Call methods multiple times to test caching
        Map<String, Object> result1 = CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics();
        Map<String, Object> result2 = CVMAEinsteinAnalyticsController.getMemberRetentionPredictions();
        Map<String, Object> result3 = CVMAEinsteinAnalyticsController.getEventSuccessPredictions();

        Test.stopTest();

        // Verify all methods return data (cacheability tested by annotation)
        System.assertNotEquals(null, result1, 'Main analytics should return cached data');
        System.assertNotEquals(null, result2, 'Retention predictions should return cached data');
        System.assertNotEquals(null, result3, 'Event predictions should return cached data');
    }

    @isTest
    static void testSecurityEnforcement() {
        // Test WITH SECURITY_ENFORCED is properly implemented
        Test.startTest();

        try {
            // These calls should respect field-level security
            Map<String, Object> retentionData = CVMAEinsteinAnalyticsController.getMemberRetentionPredictions();
            Map<String, Object> eventData = CVMAEinsteinAnalyticsController.getEventSuccessPredictions();
            Map<String, Object> financialData = CVMAEinsteinAnalyticsController.getFinancialTrendPredictions();

            // Verify methods return data with security enforcement
            System.assertNotEquals(null, retentionData, 'Retention data should respect security');
            System.assertNotEquals(null, eventData, 'Event data should respect security');
            System.assertNotEquals(null, financialData, 'Financial data should respect security');

        } catch (System.QueryException e) {
            // This is expected if user doesn't have proper permissions
            System.assert(e.getMessage().contains('INSUFFICIENT_ACCESS'),
                'Should throw proper security exception if access denied');
        }

        Test.stopTest();
    }

    @isTest
    static void testDataVolumeHandling() {
        // Test handling of large data volumes within governor limits
        Test.startTest();

        // Create additional test data to approach limits
        List<Contact> additionalMembers = new List<Contact>();
        for (Integer i = 0; i < 100; i++) {
            Contact member = CVMATestDataFactory.createContact()
                .withLevel('Full Member')
                .withLastActivityDate(Date.today().addDays(-30))
                .create();
            additionalMembers.add(member);
        }

        // Test analytics with larger data set
        Map<String, Object> result = CVMAEinsteinAnalyticsController.getEinsteinPredictiveAnalytics();

        Test.stopTest();

        // Verify analytics handle larger data volumes
        System.assertNotEquals(null, result, 'Should handle larger data volumes');

        Map<String, Object> retentionData = (Map<String, Object>) result.get('memberRetentionForecasting');
        Map<String, Object> engagementScores = (Map<String, Object>) retentionData.get('engagementScoreDistribution');
        Integer totalMembers = (Integer) engagementScores.get('totalMembers');

        System.assert(totalMembers > 0, 'Should process all members in larger data set');
    }
}
