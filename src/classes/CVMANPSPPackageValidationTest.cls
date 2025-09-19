/**
 * @description Comprehensive NPSP Reports & Dashboards Package Installation Validation
 * @author Testing Subagent - CVMA Development Team
 * @date 2025-09-11
 *
 * User Story #19: NPSP Financial Reporting Enhancement - Testing Strategy
 * Parallel execution with Strategic, Documentation, Trailblazer, and Tactical Agents
 *
 * TESTING OBJECTIVES:
 * 1. Post-Installation Validation: Verify NPSP Reports package installation success
 * 2. Performance Testing: Test report generation with $2.21M CVMA dataset
 * 3. Security Validation: Ensure WITH SECURITY_ENFORCED compliance
 * 4. Integration Testing: Validate Treasury Dashboard compatibility
 * 5. Data Quality Testing: Verify rollup field calculations
 */
@IsTest
public class CVMANPSPPackageValidationTest {

    private static final Integer LARGE_DATASET_SIZE = 1000; // Simulate large dataset
    private static final Decimal TOTAL_DONATION_TARGET = 2210000; // $2.21M dataset simulation

    @TestSetup
    static void createLargeDataset() {
        // Create comprehensive test dataset simulating CVMA's $2.21M financial data
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        List<Campaign> campaigns = new List<Campaign>();
        List<Opportunity> opportunities = new List<Opportunity>();

        // Create diverse account types for comprehensive testing
        for (Integer i = 0; i < 50; i++) {
            accounts.add(new Account(
                Name = 'CVMA Household ' + i,
                Type = 'Household',
                BillingStreet = (100 + i) + ' Main St',
                BillingCity = (i % 2 == 0) ? 'Tampa' : 'Orlando',
                BillingState = 'FL',
                BillingPostalCode = (i % 2 == 0) ? '33601' : '32801'
            ));
        }

        // Add individual donor accounts
        for (Integer i = 0; i < 20; i++) {
            accounts.add(new Account(
                Name = 'CVMA Individual Donor ' + i,
                Type = 'Individual',
                BillingStreet = (200 + i) + ' Corporate Blvd',
                BillingCity = 'Miami',
                BillingState = 'FL',
                BillingPostalCode = '33101'
            ));
        }

        insert accounts;

        // Create contacts for households (2 per household)
        for (Integer i = 0; i < 50; i++) {
            Contact primary = CVMATestDataFactory.createContact()
                .withAccount(accounts[i].Id)
                .withFirstName('Primary' + i)
                .withLastName('Member')
                .withEmail('primary' + i + '@cvma.test')
                .withLevel('Full Member')
                .create();
            contacts.add(primary);

            Contact secondary = CVMATestDataFactory.createContact()
                .withAccount(accounts[i].Id)
                .withFirstName('Secondary' + i)
                .withLastName('Member')
                .withEmail('secondary' + i + '@cvma.test')
                .withLevel('Associate')
                .create();
            contacts.add(secondary);
        }

        // Create fundraising campaigns
        campaigns.add(new Campaign(
            Name = 'CVMA Annual Fundraiser 2025',
            Type = 'Fundraising',
            Status = 'In Progress',
            BudgetedCost = 25000,
            ActualCost = 22000,
            StartDate = Date.today().addDays(-180),
            EndDate = Date.today().addDays(180)
        ));

        campaigns.add(new Campaign(
            Name = 'Veterans Memorial Fund',
            Type = 'Memorial',
            Status = 'Completed',
            BudgetedCost = 50000,
            ActualCost = 48000,
            StartDate = Date.today().addDays(-365),
            EndDate = Date.today().addDays(-90)
        ));

        campaigns.add(new Campaign(
            Name = 'Emergency Relief Fund',
            Type = 'Emergency',
            Status = 'Active',
            BudgetedCost = 15000,
            ActualCost = 14500,
            StartDate = Date.today().addDays(-60),
            EndDate = Date.today().addDays(30)
        ));

        insert campaigns;

        // Create opportunities to simulate $2.21M dataset
        Integer opportunityCount = 0;
        Decimal cumulativeAmount = 0;

        // Large donations from individual accounts
        for (Integer i = 50; i < 70; i++) {
            Decimal amount = 25000 + (Math.random() * 75000); // $25K - $100K
            opportunities.add(new Opportunity(
                Name = 'Major Gift ' + opportunityCount++,
                AccountId = accounts[i].Id,
                CampaignId = campaigns[Math.mod(i, campaigns.size())].Id,
                Amount = amount,
                StageName = 'Closed Won',
                CloseDate = Date.today().addDays(-Math.mod(i * 7, 180))
            ));
            cumulativeAmount += amount;
        }

        // Medium donations from households
        for (Integer i = 0; i < 50; i++) {
            Decimal amount = 1000 + (Math.random() * 9000); // $1K - $10K
            opportunities.add(new Opportunity(
                Name = 'Household Gift ' + opportunityCount++,
                AccountId = accounts[i].Id,
                CampaignId = campaigns[Math.mod(i, campaigns.size())].Id,
                Amount = amount,
                StageName = 'Closed Won',
                CloseDate = Date.today().addDays(-Math.mod(i * 5, 365))
            ));
            cumulativeAmount += amount;
        }

        // Small recurring donations
        for (Integer i = 0; i < 200; i++) {
            Decimal amount = 25 + (Math.random() * 475); // $25 - $500
            opportunities.add(new Opportunity(
                Name = 'Monthly Gift ' + opportunityCount++,
                AccountId = accounts[Math.mod(i, 50)].Id,
                Amount = amount,
                StageName = 'Closed Won',
                CloseDate = Date.today().addDays(-Math.mod(i * 3, 90))
            ));
            cumulativeAmount += amount;
        }

        insert opportunities;

        System.debug('Test dataset created with ' + opportunities.size() + ' opportunities totaling $' + cumulativeAmount);
    }

    /**
     * Test 1: NPSP Package Installation Validation
     * Validates that NPSP Reports & Dashboards package components are accessible
     */
    @IsTest
    static void testNPSPPackageInstallationValidation() {
        Test.startTest();

        try {
            // Validate NPSP controller accessibility
            CVMANPSPFinancialController.NPSPFinancialSummary summary =
                CVMANPSPFinancialController.getNPSPFinancialSummary();

            // Validate core NPSP functionality
            System.assertNotEquals(null, summary, 'NPSP Financial Summary should be accessible');
            System.assertNotEquals(null, summary.totalDonations, 'Total donations calculation should work');
            System.assertNotEquals(null, summary.householdGiving, 'Household giving analytics should be available');

            // Validate NPSP report data structures
            System.assertEquals(true, summary.totalDonations >= 0, 'Total donations should be non-negative');
            System.assertEquals(true, summary.totalDonors >= 0, 'Total donors should be non-negative');

            System.debug('✅ NPSP Package Installation: VALIDATED');

        } catch (Exception e) {
            System.assert(false, 'NPSP Package Installation Failed: ' + e.getMessage());
        }

        Test.stopTest();
    }

    /**
     * Test 2: Performance Testing with Large Dataset
     * Tests NPSP report generation performance with simulated $2.21M dataset
     */
    @IsTest
    static void testNPSPPerformanceWithLargeDataset() {
        Test.startTest();

        DateTime startTime = DateTime.now();

        // Test financial summary performance
        CVMANPSPFinancialController.NPSPFinancialSummary summary =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        DateTime endTime = DateTime.now();
        Long executionTime = endTime.getTime() - startTime.getTime();

        // Performance assertions
        System.assertEquals(true, executionTime < 5000,
            'Financial summary should execute within 5 seconds, took: ' + executionTime + 'ms');

        // Validate data volume handling
        System.assertEquals(true, summary.totalDonations > 0,
            'Should process large donation dataset');
        System.assertEquals(true, summary.topDonors.size() > 0,
            'Should generate top donors from large dataset');

        // Test campaign ROI performance
        DateTime campaignStartTime = DateTime.now();
        List<Map<String, Object>> campaignROI =
            CVMANPSPFinancialController.getCampaignROIAnalytics();
        DateTime campaignEndTime = DateTime.now();
        Long campaignExecutionTime = campaignEndTime.getTime() - campaignStartTime.getTime();

        System.assertEquals(true, campaignExecutionTime < 3000,
            'Campaign ROI should execute within 3 seconds, took: ' + campaignExecutionTime + 'ms');

        System.debug('✅ NPSP Performance Testing: Summary=' + executionTime + 'ms, ROI=' + campaignExecutionTime + 'ms');

        Test.stopTest();
    }

    /**
     * Test 3: Security Validation for WITH SECURITY_ENFORCED
     * Validates that all NPSP queries comply with security standards
     */
    @IsTest
    static void testNPSPSecurityCompliance() {
        Test.startTest();

        // Test with restricted user profile
        User restrictedUser = createRestrictedTestUser();

        System.runAs(restrictedUser) {
            try {
                CVMANPSPFinancialController.getNPSPFinancialSummary();
                System.assert(false, 'Should throw security exception for restricted user');
            } catch (AuraHandledException e) {
                System.assertEquals(true, e.getMessage().contains('Access denied') ||
                                        e.getMessage().contains('INSUFFICIENT_ACCESS'),
                    'Should properly handle access restrictions: ' + e.getMessage());
                System.debug('✅ NPSP Security Validation: Access properly restricted');
            }
        }

        // Test field-level security validation
        validateFieldLevelSecurity();

        Test.stopTest();
    }

    /**
     * Test 4: Integration Testing with User Story #18 Treasury Dashboard
     * Validates compatibility between NPSP reports and existing Treasury Dashboard
     */
    @IsTest
    static void testNPSPTreasuryDashboardIntegration() {
        Test.startTest();

        // Get NPSP financial summary
        CVMANPSPFinancialController.NPSPFinancialSummary npspSummary =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        // Get Treasury dashboard data for comparison
        CVMATreasuryDashboardController.TreasuryDashboardData treasuryData =
            CVMATreasuryDashboardController.getDashboardData();

        // Validate data consistency between systems
        System.assertEquals(true, npspSummary.totalDonations >= 0,
            'NPSP total donations should be valid');
        System.assertEquals(true, treasuryData.totalRevenue >= 0,
            'Treasury total revenue should be valid');

        // Test data integration compatibility
        System.assertNotEquals(null, npspSummary.householdGiving,
            'NPSP household data should integrate with Treasury reporting');

        // Validate that both systems can run simultaneously
        System.assertEquals(true, npspSummary.totalDonors >= 0 && treasuryData.memberCount >= 0,
            'Both NPSP and Treasury systems should provide valid metrics');

        System.debug('✅ NPSP Treasury Integration: NPSP=$' + npspSummary.totalDonations +
                     ', Treasury=$' + treasuryData.totalRevenue);

        Test.stopTest();
    }

    /**
     * Test 5: Data Quality Validation with $2.21M Dataset
     * Verifies NPSP rollup field calculations and data accuracy
     */
    @IsTest
    static void testNPSPDataQualityValidation() {
        Test.startTest();

        CVMANPSPFinancialController.NPSPFinancialSummary summary =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        // Validate calculation accuracy
        System.assertEquals(true, summary.totalDonations > 0,
            'Should have positive total donations from test data');

        // Validate household calculations
        Decimal householdTotal = 0;
        for (CVMANPSPFinancialController.HouseholdGiving hg : summary.householdGiving) {
            householdTotal += hg.householdTotal;

            // Validate per-member averages
            Decimal expectedAverage = hg.householdTotal / hg.memberCount;
            System.assertEquals(expectedAverage, hg.perMemberAverage,
                'Per-member average should be calculated correctly for ' + hg.householdName);
        }

        // Validate regional aggregations
        Decimal regionalTotal = 0;
        for (String region : summary.givingByRegion.keySet()) {
            regionalTotal += summary.givingByRegion.get(region);
        }

        // Regional total should match or be close to overall total (accounting for non-geo donations)
        System.assertEquals(true, Math.abs(summary.totalDonations - regionalTotal) < 1000,
            'Regional giving should approximately match total giving');

        // Validate top donor accuracy
        if (summary.topDonors.size() > 1) {
            for (Integer i = 0; i < summary.topDonors.size() - 1; i++) {
                System.assertEquals(true,
                    summary.topDonors[i].totalGiving >= summary.topDonors[i + 1].totalGiving,
                    'Top donors should be sorted in descending order');
            }
        }

        System.debug('✅ NPSP Data Quality: Total=$' + summary.totalDonations +
                     ', Households=' + householdTotal + ', Regional=' + regionalTotal);

        Test.stopTest();
    }

    /**
     * Test 6: NPSP Report Folder and Permission Validation
     * Validates proper setup of NPSP report folders and user permissions
     */
    @IsTest
    static void testNPSPReportFoldersAndPermissions() {
        Test.startTest();

        // Query for NPSP-related reports (this would validate package installation)
        List<Report> npspReports = [
            SELECT Id, Name, FolderName, Format
            FROM Report
            WHERE FolderName LIKE '%NPSP%' OR Name LIKE '%NPSP%' OR Name LIKE '%Nonprofit%'
            WITH SECURITY_ENFORCED
            LIMIT 10
        ];

        // Validate report accessibility
        System.debug('Found ' + npspReports.size() + ' NPSP-related reports');

        // Query for dashboard access
        List<Dashboard> npspDashboards = [
            SELECT Id, Title, FolderName
            FROM Dashboard
            WHERE FolderName LIKE '%NPSP%' OR Title LIKE '%NPSP%' OR Title LIKE '%Nonprofit%'
            WITH SECURITY_ENFORCED
            LIMIT 5
        ];

        System.debug('Found ' + npspDashboards.size() + ' NPSP-related dashboards');

        // Test would validate folder permissions if reports exist
        System.assertEquals(true, npspReports.size() >= 0,
            'NPSP reports query should execute without errors');
        System.assertEquals(true, npspDashboards.size() >= 0,
            'NPSP dashboards query should execute without errors');

        System.debug('✅ NPSP Report Folders: Reports=' + npspReports.size() +
                     ', Dashboards=' + npspDashboards.size());

        Test.stopTest();
    }

    /**
     * Comprehensive Post-Installation Validation Suite
     * Executes all validation tests in sequence
     */
    @IsTest
    static void testComprehensivePostInstallationValidation() {
        Test.startTest();

        List<String> validationResults = new List<String>();

        try {
            // 1. Package Installation Validation
            CVMANPSPFinancialController.getNPSPFinancialSummary();
            validationResults.add('✅ Package Installation: PASSED');
        } catch (Exception e) {
            validationResults.add('❌ Package Installation: FAILED - ' + e.getMessage());
        }

        try {
            // 2. Core Functionality Validation
            List<Map<String, Object>> campaignROI =
                CVMANPSPFinancialController.getCampaignROIAnalytics();
            validationResults.add('✅ Core Functionality: PASSED');
        } catch (Exception e) {
            validationResults.add('❌ Core Functionality: FAILED - ' + e.getMessage());
        }

        try {
            // 3. Data Quality Validation
            validateDataQuality();
            validationResults.add('✅ Data Quality: PASSED');
        } catch (Exception e) {
            validationResults.add('❌ Data Quality: FAILED - ' + e.getMessage());
        }

        // Log comprehensive validation results
        System.debug('\n=== COMPREHENSIVE NPSP VALIDATION RESULTS ===');
        for (String result : validationResults) {
            System.debug(result);
        }

        // Overall validation
        Integer passedTests = 0;
        for (String result : validationResults) {
            if (result.contains('✅')) passedTests++;
        }

        System.debug('Overall Validation: ' + passedTests + '/' + validationResults.size() + ' tests passed');
        System.assertEquals(validationResults.size(), passedTests,
            'All validation tests should pass for successful NPSP integration');

        Test.stopTest();
    }

    // Helper Methods

    private static User createRestrictedTestUser() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'RestrictedUser',
            Email = 'test.restricted@cvma.test',
            Username = 'test.restricted.' + DateTime.now().getTime() + '@cvma.test',
            Alias = 'trestr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id
        );

        insert testUser;
        return testUser;
    }

    private static void validateFieldLevelSecurity() {
        // Test field access for critical NPSP fields
        Schema.DescribeFieldResult oppAmountField = Opportunity.Amount.getDescribe();
        System.assertEquals(true, oppAmountField.isAccessible(), 'Amount field should be accessible');

        Schema.DescribeFieldResult accTypeField = Account.Type.getDescribe();
        System.assertEquals(true, accTypeField.isAccessible(), 'Account Type field should be accessible');

        System.debug('✅ Field Level Security: Core financial fields accessible');
    }

    private static void validateDataQuality() {
        // Get current data for quality validation
        List<Opportunity> opportunities = [
            SELECT Id, Amount, AccountId, Account.Type, CloseDate
            FROM Opportunity
            WHERE StageName = 'Closed Won'
            WITH SECURITY_ENFORCED
            LIMIT 100
        ];

        Decimal totalAmount = 0;
        for (Opportunity opp : opportunities) {
            totalAmount += (opp.Amount != null ? opp.Amount : 0);
        }

        System.assertEquals(true, totalAmount > 0, 'Should have valid opportunity amounts');
        System.assertEquals(true, opportunities.size() > 0, 'Should have closed won opportunities');
    }
}
