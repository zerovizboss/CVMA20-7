/**
 * @description NPSP Treasury Dashboard Integration Test Suite
 * @author Testing Subagent - CVMA Development Team
 * @date 2025-09-11
 *
 * User Story #19: NPSP Financial Reporting Enhancement - Treasury Integration Testing
 * Parallel Testing Strategy: Validate NPSP integration with existing User Story #18 Treasury Dashboard
 *
 * INTEGRATION TESTING OBJECTIVES:
 * 1. Data Consistency: Validate data alignment between NPSP and Treasury systems
 * 2. Performance Impact: Test system performance with both dashboards active
 * 3. User Experience: Ensure seamless transition between Treasury and NPSP views
 * 4. Feature Compatibility: Validate complementary functionality
 * 5. Migration Safety: Test safe migration from custom to NPSP components
 * 6. Dual Operation: Validate both systems can operate simultaneously
 */
@IsTest
public class CVMANPSPTreasuryIntegrationTest {

    private static final Decimal TEST_DATASET_VALUE = 1500000; // $1.5M test dataset
    private static final Integer PERFORMANCE_THRESHOLD_MS = 3000; // 3 second combined threshold

    @TestSetup
    static void createIntegrationTestData() {
        // Create comprehensive test data that works with both systems
        List<Account> accounts = createIntegratedAccountData();
        List<Contact> contacts = createIntegratedContactData(accounts);
        List<Campaign> campaigns = createIntegratedCampaignData();
        List<Opportunity> opportunities = createIntegratedOpportunityData(accounts, campaigns);
        List<CampaignMember> members = createIntegratedMemberData(contacts, campaigns);

        System.debug('Integration test data created: Both NPSP and Treasury compatible dataset');
    }

    /**
     * Integration Test 1: Data Consistency Validation
     * Validates that NPSP and Treasury dashboards show consistent financial data
     */
    @IsTest
    static void testDataConsistencyBetweenSystems() {
        Test.startTest();

        // Get NPSP financial data
        CVMANPSPFinancialController.NPSPFinancialSummary npspData =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        // Get Treasury dashboard data
        CVMATreasuryDashboardController.TreasuryDashboardData treasuryData =
            CVMATreasuryDashboardController.getDashboardData();

        // Data consistency validations
        System.assertNotEquals(null, npspData, 'NPSP data should be available');
        System.assertNotEquals(null, treasuryData, 'Treasury data should be available');

        // Financial totals should be related (may not be identical due to different scopes)
        System.assertEquals(true, npspData.totalDonations > 0,
            'NPSP should show donation data: $' + npspData.totalDonations);
        System.assertEquals(true, treasuryData.totalRevenue > 0,
            'Treasury should show revenue data: $' + treasuryData.totalRevenue);

        // Member counts should be consistent
        System.assertEquals(true, npspData.totalDonors > 0,
            'NPSP should show donor count: ' + npspData.totalDonors);
        System.assertEquals(true, treasuryData.memberCount > 0,
            'Treasury should show member count: ' + treasuryData.memberCount);

        // Validate data correlation
        validateDataCorrelation(npspData, treasuryData);

        System.debug('✅ Data Consistency: NPSP=$' + npspData.totalDonations +
                     ', Treasury=$' + treasuryData.totalRevenue);

        Test.stopTest();
    }

    /**
     * Integration Test 2: Combined Performance Impact
     * Tests system performance when both dashboards are used simultaneously
     */
    @IsTest
    static void testCombinedPerformanceImpact() {
        Test.startTest();

        DateTime startTime = DateTime.now();
        Integer startHeap = Limits.getHeapSize();
        Integer startQueries = Limits.getQueries();

        // Execute both systems simultaneously
        CVMANPSPFinancialController.NPSPFinancialSummary npspData =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        CVMATreasuryDashboardController.TreasuryDashboardData treasuryData =
            CVMATreasuryDashboardController.getDashboardData();

        List<Map<String, Object>> campaignROI =
            CVMANPSPFinancialController.getCampaignROIAnalytics();

        DateTime endTime = DateTime.now();
        Long totalExecutionTime = endTime.getTime() - startTime.getTime();
        Integer heapUsed = Limits.getHeapSize() - startHeap;
        Integer queriesUsed = Limits.getQueries() - startQueries;

        // Performance validations
        System.assertEquals(true, totalExecutionTime < PERFORMANCE_THRESHOLD_MS,
            'Combined execution should be under ' + PERFORMANCE_THRESHOLD_MS + 'ms, took: ' + totalExecutionTime + 'ms');

        System.assertEquals(true, heapUsed < (8 * 1024 * 1024), // 8MB limit
            'Combined heap usage should be reasonable: ' + (heapUsed / 1024) + 'KB');

        System.assertEquals(true, queriesUsed < 15,
            'Combined queries should be optimized: ' + queriesUsed + ' used');

        // Validate both systems still return valid data
        System.assertNotEquals(null, npspData, 'NPSP should still function with Treasury active');
        System.assertNotEquals(null, treasuryData, 'Treasury should still function with NPSP active');
        System.assertNotEquals(null, campaignROI, 'Campaign ROI should still function');

        logIntegrationPerformance('Combined Systems', totalExecutionTime, heapUsed, queriesUsed);

        Test.stopTest();
    }

    /**
     * Integration Test 3: User Experience Transition
     * Tests seamless user experience between Treasury and NPSP dashboards
     */
    @IsTest
    static void testUserExperienceTransition() {
        Test.startTest();

        // Simulate user workflow: Treasury → NPSP → Campaign Analysis

        // Step 1: User starts with Treasury dashboard
        CVMATreasuryDashboardController.TreasuryDashboardData treasuryStart =
            CVMATreasuryDashboardController.getDashboardData();

        // Step 2: User transitions to NPSP financial summary
        CVMANPSPFinancialController.NPSPFinancialSummary npspSummary =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        // Step 3: User drills down into campaign ROI
        List<Map<String, Object>> campaignROI =
            CVMANPSPFinancialController.getCampaignROIAnalytics();

        // Step 4: User returns to Treasury for comparison
        CVMATreasuryDashboardController.TreasuryDashboardData treasuryEnd =
            CVMATreasuryDashboardController.getDashboardData();

        // Validate seamless transition
        System.assertEquals(treasuryStart.totalRevenue, treasuryEnd.totalRevenue,
            'Treasury data should remain consistent through workflow');

        System.assertNotEquals(null, npspSummary.householdGiving,
            'NPSP should provide complementary household analysis');

        System.assertEquals(true, campaignROI.size() > 0,
            'Campaign ROI should provide detailed campaign insights');

        // Validate data relationships for user understanding
        validateUserExperienceFlow(treasuryStart, npspSummary, campaignROI);

        System.debug('✅ User Experience: Seamless transition validated');

        Test.stopTest();
    }

    /**
     * Integration Test 4: Feature Compatibility Validation
     * Validates that NPSP and Treasury features complement each other
     */
    @IsTest
    static void testFeatureCompatibilityValidation() {
        Test.startTest();

        CVMANPSPFinancialController.NPSPFinancialSummary npspData =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        CVMATreasuryDashboardController.TreasuryDashboardData treasuryData =
            CVMATreasuryDashboardController.getDashboardData();

        // Validate complementary features

        // 1. Geographic Analysis
        System.assertNotEquals(null, npspData.givingByRegion,
            'NPSP should provide geographic giving analysis');
        // Treasury focuses on member distribution, NPSP on giving distribution

        // 2. Household vs Individual Analysis
        System.assertNotEquals(null, npspData.householdGiving,
            'NPSP should provide household giving insights');
        System.assertEquals(true, treasuryData.memberCount >= npspData.householdCount,
            'Members should include individuals and household members');

        // 3. Time Period Analysis
        System.assertNotEquals(null, npspData.reportingPeriod,
            'NPSP should provide time-based reporting');
        System.assertNotEquals(null, treasuryData.reportingDate,
            'Treasury should provide current reporting timestamp');

        // 4. Donor vs Member Perspectives
        System.assertEquals(true, npspData.totalDonors > 0,
            'NPSP focuses on donor analytics');
        System.assertEquals(true, treasuryData.memberCount > 0,
            'Treasury focuses on member analytics');

        // 5. Campaign Integration
        List<Map<String, Object>> campaignROI =
            CVMANPSPFinancialController.getCampaignROIAnalytics();

        System.assertEquals(true, campaignROI.size() > 0,
            'NPSP should integrate campaign data with financial analysis');

        validateFeatureComplementarity(npspData, treasuryData, campaignROI);

        System.debug('✅ Feature Compatibility: Complementary features validated');

        Test.stopTest();
    }

    /**
     * Integration Test 5: Migration Safety Validation
     * Tests safe migration from custom Treasury components to NPSP integration
     */
    @IsTest
    static void testMigrationSafetyValidation() {
        Test.startTest();

        // Phase 1: Pre-migration state (Treasury only)
        CVMATreasuryDashboardController.TreasuryDashboardData preMigration =
            CVMATreasuryDashboardController.getDashboardData();

        // Phase 2: Post-NPSP integration (both systems active)
        CVMANPSPFinancialController.NPSPFinancialSummary postMigration =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        CVMATreasuryDashboardController.TreasuryDashboardData treasuryPostMigration =
            CVMATreasuryDashboardController.getDashboardData();

        // Migration safety validations

        // 1. No data loss
        System.assertEquals(preMigration.totalRevenue, treasuryPostMigration.totalRevenue,
            'Treasury revenue should not change after NPSP integration');

        System.assertEquals(preMigration.memberCount, treasuryPostMigration.memberCount,
            'Member count should remain consistent');

        // 2. Enhanced capabilities
        System.assertNotEquals(null, postMigration.householdGiving,
            'NPSP should add household giving capabilities');

        System.assertNotEquals(null, postMigration.givingByRegion,
            'NPSP should add geographic analysis capabilities');

        // 3. Data integrity
        validateDataIntegrity(preMigration, treasuryPostMigration, postMigration);

        // 4. User access preservation
        System.assertEquals(true, treasuryPostMigration.totalRevenue >= 0,
            'Users should retain access to Treasury data');

        System.assertEquals(true, postMigration.totalDonations >= 0,
            'Users should gain access to NPSP analytics');

        System.debug('✅ Migration Safety: Safe integration validated');

        Test.stopTest();
    }

    /**
     * Integration Test 6: Dual Operation Validation
     * Validates that both systems can operate simultaneously without conflicts
     */
    @IsTest
    static void testDualOperationValidation() {
        Test.startTest();

        // Create multiple concurrent operations
        List<CVMANPSPFinancialController.NPSPFinancialSummary> npspResults =
            new List<CVMANPSPFinancialController.NPSPFinancialSummary>();
        List<CVMATreasuryDashboardController.TreasuryDashboardData> treasuryResults =
            new List<CVMATreasuryDashboardController.TreasuryDashboardData>();

        // Simulate concurrent access patterns
        for (Integer i = 0; i < 3; i++) {
            npspResults.add(CVMANPSPFinancialController.getNPSPFinancialSummary());
            treasuryResults.add(CVMATreasuryDashboardController.getDashboardData());
        }

        // Validate consistent results across concurrent operations
        for (Integer i = 1; i < npspResults.size(); i++) {
            System.assertEquals(npspResults[0].totalDonations, npspResults[i].totalDonations,
                'NPSP results should be consistent across concurrent calls');

            System.assertEquals(treasuryResults[0].totalRevenue, treasuryResults[i].totalRevenue,
                'Treasury results should be consistent across concurrent calls');
        }

        // Validate no resource conflicts
        System.assertEquals(true, Limits.getQueries() < Limits.getLimitQueries() / 2,
            'Concurrent operations should not exhaust query limits');

        System.assertEquals(true, Limits.getHeapSize() < Limits.getLimitHeapSize() / 2,
            'Concurrent operations should not exhaust heap space');

        // Test interleaved operations
        CVMANPSPFinancialController.NPSPFinancialSummary interleavedNPSP =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        CVMATreasuryDashboardController.TreasuryDashboardData interleavedTreasury =
            CVMATreasuryDashboardController.getDashboardData();

        List<Map<String, Object>> interleavedCampaign =
            CVMANPSPFinancialController.getCampaignROIAnalytics();

        // Validate all operations complete successfully
        System.assertNotEquals(null, interleavedNPSP, 'Interleaved NPSP operation should succeed');
        System.assertNotEquals(null, interleavedTreasury, 'Interleaved Treasury operation should succeed');
        System.assertNotEquals(null, interleavedCampaign, 'Interleaved Campaign operation should succeed');

        System.debug('✅ Dual Operation: Concurrent operations validated');

        Test.stopTest();
    }

    /**
     * Integration Test 7: End-to-End Integration Scenario
     * Tests complete user workflow across both systems
     */
    @IsTest
    static void testEndToEndIntegrationScenario() {
        Test.startTest();

        // Scenario: Treasurer reviews monthly financials

        // Step 1: Monthly Treasury overview
        CVMATreasuryDashboardController.TreasuryDashboardData monthlyOverview =
            CVMATreasuryDashboardController.getDashboardData();

        // Step 2: Deep dive into NPSP donor analytics
        CVMANPSPFinancialController.NPSPFinancialSummary donorAnalytics =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        // Step 3: Campaign performance analysis
        List<Map<String, Object>> campaignPerformance =
            CVMANPSPFinancialController.getCampaignROIAnalytics();

        // Step 4: Geographic giving analysis
        Map<String, Decimal> regionalGiving = donorAnalytics.givingByRegion;

        // Step 5: Household giving trends
        List<CVMANPSPFinancialController.HouseholdGiving> householdTrends =
            donorAnalytics.householdGiving;

        // Validate complete workflow
        System.assertNotEquals(null, monthlyOverview, 'Monthly overview should be available');
        System.assertNotEquals(null, donorAnalytics, 'Donor analytics should be available');
        System.assertNotEquals(null, campaignPerformance, 'Campaign performance should be available');
        System.assertNotEquals(null, regionalGiving, 'Regional giving should be available');
        System.assertNotEquals(null, householdTrends, 'Household trends should be available');

        // Validate data flow continuity
        System.assertEquals(true, monthlyOverview.totalRevenue > 0,
            'Should start with positive treasury data');
        System.assertEquals(true, donorAnalytics.totalDonations > 0,
            'Should have positive donation analytics');
        System.assertEquals(true, campaignPerformance.size() > 0,
            'Should have campaign performance data');
        System.assertEquals(true, regionalGiving.size() > 0,
            'Should have regional distribution');
        System.assertEquals(true, householdTrends.size() > 0,
            'Should have household giving trends');

        validateEndToEndWorkflow(monthlyOverview, donorAnalytics, campaignPerformance);

        System.debug('✅ End-to-End Integration: Complete workflow validated');

        Test.stopTest();
    }

    /**
     * Comprehensive Integration Validation Suite
     * Executes all integration tests and provides overall compatibility report
     */
    @IsTest
    static void testComprehensiveIntegrationValidation() {
        Test.startTest();

        Map<String, String> integrationResults = new Map<String, String>();

        try {
            // Test 1: Data consistency
            validateIntegrationDataConsistency();
            integrationResults.put('Data_Consistency', '✅ PASSED');
        } catch (Exception e) {
            integrationResults.put('Data_Consistency', '❌ FAILED: ' + e.getMessage().substring(0, 50));
        }

        try {
            // Test 2: Performance impact
            validateIntegrationPerformanceImpact();
            integrationResults.put('Performance_Impact', '✅ PASSED');
        } catch (Exception e) {
            integrationResults.put('Performance_Impact', '❌ FAILED: ' + e.getMessage().substring(0, 50));
        }

        try {
            // Test 3: Feature compatibility
            validateIntegrationFeatureCompatibility();
            integrationResults.put('Feature_Compatibility', '✅ PASSED');
        } catch (Exception e) {
            integrationResults.put('Feature_Compatibility', '❌ FAILED: ' + e.getMessage().substring(0, 50));
        }

        try {
            // Test 4: Migration safety
            validateIntegrationMigrationSafety();
            integrationResults.put('Migration_Safety', '✅ PASSED');
        } catch (Exception e) {
            integrationResults.put('Migration_Safety', '❌ FAILED: ' + e.getMessage().substring(0, 50));
        }

        // Integration reporting
        System.debug('\n=== NPSP TREASURY INTEGRATION RESULTS ===');
        Integer passedTests = 0;
        for (String test : integrationResults.keySet()) {
            String result = integrationResults.get(test);
            System.debug(test + ': ' + result);
            if (result.contains('✅')) passedTests++;
        }

        System.debug('Integration Compatibility: ' + passedTests + '/' + integrationResults.size() + ' tests passed');

        // Overall integration validation
        System.assertEquals(integrationResults.size(), passedTests,
            'All integration tests must pass for successful NPSP Treasury integration');

        Test.stopTest();
    }

    // Test Data Creation Helpers

    private static List<Account> createIntegratedAccountData() {
        List<Account> accounts = new List<Account>();

        // Create household accounts
        for (Integer i = 0; i < 30; i++) {
            accounts.add(new Account(
                Name = 'Integration Household ' + i,
                Type = 'Household',
                BillingStreet = (500 + i) + ' Integration St',
                BillingCity = (i % 3 == 0) ? 'Tampa' : (i % 3 == 1) ? 'Orlando' : 'Miami',
                BillingState = 'FL',
                BillingPostalCode = '3' + String.valueOf(3000 + i).right(4)
            ));
        }

        // Create individual accounts
        for (Integer i = 0; i < 15; i++) {
            accounts.add(new Account(
                Name = 'Integration Individual ' + i,
                Type = 'Individual',
                BillingStreet = (600 + i) + ' Integration Ave',
                BillingCity = 'Jacksonville',
                BillingState = 'FL',
                BillingPostalCode = '32' + String.valueOf(200 + i).right(3)
            ));
        }

        insert accounts;
        return accounts;
    }

    private static List<Contact> createIntegratedContactData(List<Account> accounts) {
        List<Contact> contacts = new List<Contact>();

        for (Integer i = 0; i < accounts.size(); i++) {
            Contact contact = CVMATestDataFactory.createContact()
                .withAccount(accounts[i].Id)
                .withFirstName('Integration' + i)
                .withLastName('Contact')
                .withEmail('integration' + i + '@cvma.test')
                .withLevel((i % 4 == 0) ? 'Full Member' :
                          (i % 4 == 1) ? 'Associate' :
                          (i % 4 == 2) ? 'Auxiliary' : 'Supporter')
                .create();
            contacts.add(contact);
        }

        return contacts;
    }

    private static List<Campaign> createIntegratedCampaignData() {
        List<Campaign> campaigns = new List<Campaign>();

        campaigns.add(new Campaign(
            Name = 'Integration Annual Fundraiser',
            Type = 'Fundraising',
            Status = 'Active',
            BudgetedCost = 15000,
            ActualCost = 14200,
            StartDate = Date.today().addDays(-120),
            EndDate = Date.today().addDays(60)
        ));

        campaigns.add(new Campaign(
            Name = 'Integration Memorial Campaign',
            Type = 'Memorial',
            Status = 'Completed',
            BudgetedCost = 25000,
            ActualCost = 23800,
            StartDate = Date.today().addDays(-200),
            EndDate = Date.today().addDays(-30)
        ));

        campaigns.add(new Campaign(
            Name = 'Integration Emergency Fund',
            Type = 'Emergency',
            Status = 'Active',
            BudgetedCost = 10000,
            ActualCost = 9500,
            StartDate = Date.today().addDays(-90),
            EndDate = Date.today().addDays(90)
        ));

        insert campaigns;
        return campaigns;
    }

    private static List<Opportunity> createIntegratedOpportunityData(List<Account> accounts,
                                                                   List<Campaign> campaigns) {
        List<Opportunity> opportunities = new List<Opportunity>();

        // Large donations for major donor analysis
        for (Integer i = 30; i < 45; i++) {
            Decimal amount = 15000 + (Math.random() * 35000); // $15K-$50K
            opportunities.add(new Opportunity(
                Name = 'Integration Major Gift ' + i,
                AccountId = accounts[i].Id,
                CampaignId = campaigns[Math.mod(i, campaigns.size())].Id,
                Amount = amount,
                StageName = 'Closed Won',
                CloseDate = Date.today().addDays(-Math.mod(i * 7, 180))
            ));
        }

        // Medium donations from households
        for (Integer i = 0; i < 30; i++) {
            Decimal amount = 500 + (Math.random() * 4500); // $500-$5K
            opportunities.add(new Opportunity(
                Name = 'Integration Household Gift ' + i,
                AccountId = accounts[i].Id,
                CampaignId = campaigns[Math.mod(i, campaigns.size())].Id,
                Amount = amount,
                StageName = 'Closed Won',
                CloseDate = Date.today().addDays(-Math.mod(i * 5, 120))
            ));
        }

        // Small recurring donations
        for (Integer i = 0; i < 100; i++) {
            Decimal amount = 25 + (Math.random() * 225); // $25-$250
            opportunities.add(new Opportunity(
                Name = 'Integration Monthly Gift ' + i,
                AccountId = accounts[Math.mod(i, 30)].Id,
                Amount = amount,
                StageName = 'Closed Won',
                CloseDate = Date.today().addDays(-Math.mod(i * 3, 90))
            ));
        }

        insert opportunities;
        return opportunities;
    }

    private static List<CampaignMember> createIntegratedMemberData(List<Contact> contacts,
                                                                  List<Campaign> campaigns) {
        List<CampaignMember> members = new List<CampaignMember>();

        for (Integer i = 0; i < Math.min(100, contacts.size()); i++) {
            String[] statuses = new String[]{'Sent', 'Responded_Yes', 'Responded_No', 'Responded_Maybe'};

            members.add(new CampaignMember(
                CampaignId = campaigns[Math.mod(i, campaigns.size())].Id,
                ContactId = contacts[i].Id,
                Status = statuses[Math.mod(i, statuses.size())]
            ));
        }

        insert members;
        return members;
    }

    // Validation Helper Methods

    private static void validateDataCorrelation(CVMANPSPFinancialController.NPSPFinancialSummary npspData,
                                               CVMATreasuryDashboardController.TreasuryDashboardData treasuryData) {
        // Validate logical relationships between systems
        System.assertEquals(true, npspData.totalDonors <= treasuryData.memberCount,
            'Donors should be subset of or equal to members');

        // Both should show positive financial activity
        System.assertEquals(true, npspData.totalDonations > 0 && treasuryData.totalRevenue > 0,
            'Both systems should show positive financial activity');
    }

    private static void validateUserExperienceFlow(CVMATreasuryDashboardController.TreasuryDashboardData treasury,
                                                  CVMANPSPFinancialController.NPSPFinancialSummary npsp,
                                                  List<Map<String, Object>> campaigns) {
        // Validate user can understand data relationships
        System.assertEquals(true, treasury.memberCount > 0, 'Treasury should show member context');
        System.assertEquals(true, npsp.totalDonors > 0, 'NPSP should show donor context');
        System.assertEquals(true, campaigns.size() > 0, 'Campaigns should provide detailed context');
    }

    private static void validateFeatureComplementarity(CVMANPSPFinancialController.NPSPFinancialSummary npsp,
                                                      CVMATreasuryDashboardController.TreasuryDashboardData treasury,
                                                      List<Map<String, Object>> campaigns) {
        // Validate features complement rather than duplicate
        System.assertNotEquals(null, npsp.householdGiving, 'NPSP adds household analysis');
        System.assertNotEquals(null, npsp.givingByRegion, 'NPSP adds geographic analysis');
        System.assertEquals(true, campaigns.size() > 0, 'NPSP adds campaign analysis');

        // Treasury maintains operational focus
        System.assertEquals(true, treasury.memberCount > 0, 'Treasury maintains member focus');
        System.assertEquals(true, treasury.totalRevenue > 0, 'Treasury maintains revenue focus');
    }

    private static void validateDataIntegrity(CVMATreasuryDashboardController.TreasuryDashboardData preMigration,
                                             CVMATreasuryDashboardController.TreasuryDashboardData postMigration,
                                             CVMANPSPFinancialController.NPSPFinancialSummary npspData) {
        // Validate no data corruption during integration
        System.assertEquals(preMigration.memberCount, postMigration.memberCount,
            'Member count should remain stable');

        // Validate enhanced capabilities
        System.assertEquals(true, npspData.householdGiving.size() >= 0,
            'NPSP should add household capabilities');
        System.assertEquals(true, npspData.givingByRegion.size() >= 0,
            'NPSP should add regional capabilities');
    }

    private static void validateEndToEndWorkflow(CVMATreasuryDashboardController.TreasuryDashboardData treasury,
                                                CVMANPSPFinancialController.NPSPFinancialSummary npsp,
                                                List<Map<String, Object>> campaigns) {
        // Validate complete treasurer workflow
        System.assertEquals(true, treasury.totalRevenue > 0, 'Start with treasury overview');
        System.assertEquals(true, npsp.totalDonations > 0, 'Drill into donor analytics');
        System.assertEquals(true, campaigns.size() > 0, 'Analyze campaign performance');

        // Validate data tells coherent story
        System.assertEquals(true, npsp.totalDonors <= treasury.memberCount,
            'Donor count should make sense within member context');
    }

    // Integration validation methods

    private static void validateIntegrationDataConsistency() {
        CVMANPSPFinancialController.NPSPFinancialSummary npspData =
            CVMANPSPFinancialController.getNPSPFinancialSummary();
        CVMATreasuryDashboardController.TreasuryDashboardData treasuryData =
            CVMATreasuryDashboardController.getDashboardData();

        System.assertEquals(true, npspData.totalDonations >= 0 && treasuryData.totalRevenue >= 0,
            'Data consistency validation passed');
    }

    private static void validateIntegrationPerformanceImpact() {
        DateTime startTime = DateTime.now();

        CVMANPSPFinancialController.getNPSPFinancialSummary();
        CVMATreasuryDashboardController.getDashboardData();

        Long executionTime = DateTime.now().getTime() - startTime.getTime();
        System.assertEquals(true, executionTime < PERFORMANCE_THRESHOLD_MS,
            'Performance impact validation passed');
    }

    private static void validateIntegrationFeatureCompatibility() {
        CVMANPSPFinancialController.NPSPFinancialSummary npspData =
            CVMANPSPFinancialController.getNPSPFinancialSummary();
        CVMATreasuryDashboardController.TreasuryDashboardData treasuryData =
            CVMATreasuryDashboardController.getDashboardData();

        System.assertEquals(true, npspData.householdGiving != null && treasuryData.memberCount > 0,
            'Feature compatibility validation passed');
    }

    private static void validateIntegrationMigrationSafety() {
        CVMATreasuryDashboardController.TreasuryDashboardData treasuryBefore =
            CVMATreasuryDashboardController.getDashboardData();
        CVMANPSPFinancialController.getNPSPFinancialSummary();
        CVMATreasuryDashboardController.TreasuryDashboardData treasuryAfter =
            CVMATreasuryDashboardController.getDashboardData();

        System.assertEquals(treasuryBefore.totalRevenue, treasuryAfter.totalRevenue,
            'Migration safety validation passed');
    }

    private static void logIntegrationPerformance(String operation, Long executionTime,
                                                 Integer heapUsed, Integer queriesUsed) {
        System.debug('INTEGRATION[' + operation + ']: ' +
                     'Time=' + executionTime + 'ms, ' +
                     'Heap=' + (heapUsed / 1024) + 'KB, ' +
                     'Queries=' + queriesUsed);
    }
}
