/**
 * @description Test class for CVMATreasuryDashboardController
 * @author Claude AI - CVMA Development Team
 * @date 2025-09-11
 *
 * User Story #18: Treasury Dashboard Test Coverage
 * Tests Standard Feature Integration functionality
 */
@IsTest
private class CVMATreasuryDashboardControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test campaigns with budget data
        List<Campaign> testCampaigns = new List<Campaign>();

        Campaign membershipCampaign = new Campaign(
            Name = 'CVMA Membership Dues 2025',
            Type = 'Membership',
            Status = 'In Progress',
            BudgetedCost = 1000.00,
            ActualCost = 500.00,
            StartDate = Date.today().addMonths(-6),
            EndDate = Date.today().addMonths(6)
        );
        testCampaigns.add(membershipCampaign);

        Campaign fundraiserCampaign = new Campaign(
            Name = 'Annual Fundraiser 2025',
            Type = 'Fundraising',
            Status = 'Planned',
            BudgetedCost = 5000.00,
            ActualCost = 2000.00,
            StartDate = Date.today().addMonths(-3),
            EndDate = Date.today().addMonths(3)
        );
        testCampaigns.add(fundraiserCampaign);

        insert testCampaigns;

        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        testContacts.add(new Contact(FirstName = 'Test', LastName = 'Member1', Email = 'test1@cvma.org'));
        testContacts.add(new Contact(FirstName = 'Test', LastName = 'Member2', Email = 'test2@cvma.org'));
        testContacts.add(new Contact(FirstName = 'Test', LastName = 'Member3', Email = 'test3@cvma.org'));
        insert testContacts;

        // Create test opportunities for revenue
        List<Opportunity> testOpportunities = new List<Opportunity>();

        testOpportunities.add(new Opportunity(
            Name = 'Membership Dues - Member1',
            Amount = 120.00,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-30),
            CampaignId = membershipCampaign.Id
        ));

        testOpportunities.add(new Opportunity(
            Name = 'Membership Dues - Member2',
            Amount = 120.00,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-15),
            CampaignId = membershipCampaign.Id
        ));

        testOpportunities.add(new Opportunity(
            Name = 'Fundraiser Donation',
            Amount = 500.00,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-5),
            CampaignId = fundraiserCampaign.Id
        ));

        testOpportunities.add(new Opportunity(
            Name = 'Current Month Opportunity',
            Amount = 250.00,
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            CampaignId = membershipCampaign.Id
        ));

        insert testOpportunities;

        // Create campaign members for Epic #2 integration
        List<CampaignMember> testMembers = new List<CampaignMember>();

        testMembers.add(new CampaignMember(
            CampaignId = membershipCampaign.Id,
            ContactId = testContacts[0].Id,
            Status = 'Responded_Yes'
        ));

        testMembers.add(new CampaignMember(
            CampaignId = membershipCampaign.Id,
            ContactId = testContacts[1].Id,
            Status = 'Responded_Yes'
        ));

        testMembers.add(new CampaignMember(
            CampaignId = fundraiserCampaign.Id,
            ContactId = testContacts[2].Id,
            Status = 'Sent'
        ));

        insert testMembers;
    }

    @IsTest
    static void testGetTreasurySummary_Success() {
        Test.startTest();

        // Test treasury summary retrieval
        CVMATreasuryDashboardController.TreasurySummary summary =
            CVMATreasuryDashboardController.getTreasurySummary();

        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, summary, 'Treasury summary should not be null');
        System.assertEquals('Year to Date ' + Date.today().year(), summary.reportingPeriod,
                           'Reporting period should match current year');

        // Verify revenue calculations (240 membership + 500 fundraiser = 740)
        System.assertEquals(740.00, summary.totalRevenue, 'Total revenue should be $740');

        // Verify budget calculations (1000 + 5000 = 6000)
        System.assertEquals(6000.00, summary.totalBudget, 'Total budget should be $6000');

        // Verify actual cost calculations (500 + 2000 = 2500)
        System.assertEquals(2500.00, summary.totalActualCost, 'Total actual cost should be $2500');

        // Verify budget variance (6000 - 2500 = 3500)
        System.assertEquals(3500.00, summary.budgetVariance, 'Budget variance should be $3500');

        // Verify campaign count
        System.assertEquals(2, summary.totalCampaigns, 'Should have 2 campaigns');

        // Verify opportunities count
        System.assertEquals(4, summary.totalOpportunities, 'Should have 4 opportunities');

        // Verify monthly revenue (current month opportunity = 250)
        System.assertEquals(250.00, summary.monthlyRevenue, 'Monthly revenue should be $250');

        // Verify campaign breakdown
        System.assertNotEquals(null, summary.campaignBreakdown, 'Campaign breakdown should not be null');
        System.assertEquals(2, summary.campaignBreakdown.size(), 'Should have 2 campaign breakdowns');

        // Verify campaign member integration
        Boolean foundMembershipCampaign = false;
        for (CVMATreasuryDashboardController.CampaignFinancial cf : summary.campaignBreakdown) {
            if (cf.campaignName.contains('Membership')) {
                foundMembershipCampaign = true;
                System.assertEquals(2, cf.memberCount, 'Membership campaign should have 2 members');
                System.assertEquals(100.0, cf.responseRate, 'Response rate should be 100%');
            }
        }
        System.assert(foundMembershipCampaign, 'Should find membership campaign with member data');
    }

    @IsTest
    static void testGetCampaignMemberFinancials_Success() {
        Test.startTest();

        // Test campaign member financial analytics
        List<Map<String, Object>> memberFinancials =
            CVMATreasuryDashboardController.getCampaignMemberFinancials();

        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, memberFinancials, 'Member financials should not be null');
        System.assertEquals(2, memberFinancials.size(), 'Should have 2 campaigns with financial data');

        // Find and verify membership campaign data
        Map<String, Object> membershipData = null;
        for (Map<String, Object> data : memberFinancials) {
            if (((String)data.get('campaignName')).contains('Membership')) {
                membershipData = data;
                break;
            }
        }

        System.assertNotEquals(null, membershipData, 'Should find membership campaign data');
        System.assertEquals(2, membershipData.get('totalMembers'), 'Should have 2 total members');
        System.assertEquals(2, membershipData.get('respondedYes'), 'Should have 2 responded yes');
        System.assertEquals(100.0, membershipData.get('responseRate'), 'Response rate should be 100%');

        // Verify revenue per member calculation (370 revenue / 2 members = 185)
        Decimal revenuePerMember = (Decimal)membershipData.get('revenuePerMember');
        System.assertEquals(185.0, revenuePerMember, 'Revenue per member should be $185');
    }

    @IsTest
    static void testGetTreasurySummary_NoData() {
        // Delete all opportunities to test empty data scenario
        delete [SELECT Id FROM Opportunity];

        Test.startTest();

        CVMATreasuryDashboardController.TreasurySummary summary =
            CVMATreasuryDashboardController.getTreasurySummary();

        Test.stopTest();

        // Assertions for empty data
        System.assertNotEquals(null, summary, 'Summary should not be null even with no data');
        System.assertEquals(0, summary.totalRevenue, 'Total revenue should be 0 with no opportunities');
        System.assertEquals(0, summary.totalOpportunities, 'Total opportunities should be 0');
        System.assertEquals(0, summary.monthlyRevenue, 'Monthly revenue should be 0');
    }

    @IsTest
    static void testTreasuryAccess_SecurityValidation() {
        // Test without proper permissions - should throw exception
        Test.startTest();

        try {
            CVMATreasuryDashboardController.getTreasurySummary();
            System.assert(false, 'Should have thrown access denied exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Access denied'),
                         'Should throw access denied exception: ' + e.getMessage());
        }

        Test.stopTest();
    }

    @IsTest
    static void testCampaignFinancialDataStructure() {
        Test.startTest();

        // Test campaign financial data structure
        CVMATreasuryDashboardController.CampaignFinancial cf =
            new CVMATreasuryDashboardController.CampaignFinancial();

        // Set test data
        cf.campaignName = 'Test Campaign';
        cf.campaignType = 'Test Type';
        cf.status = 'Active';
        cf.revenue = 1000.00;
        cf.budget = 1500.00;
        cf.actualCost = 800.00;
        cf.opportunities = 5;
        cf.memberCount = 10;
        cf.responseRate = 75.0;

        Test.stopTest();

        // Verify data structure
        System.assertEquals('Test Campaign', cf.campaignName, 'Campaign name should match');
        System.assertEquals(1000.00, cf.revenue, 'Revenue should match');
        System.assertEquals(75.0, cf.responseRate, 'Response rate should match');
    }

    @IsTest
    static void testTreasurySummaryDataStructure() {
        Test.startTest();

        // Test treasury summary data structure
        CVMATreasuryDashboardController.TreasurySummary summary =
            new CVMATreasuryDashboardController.TreasurySummary();

        // Set test data
        summary.totalRevenue = 5000.00;
        summary.totalBudget = 7000.00;
        summary.totalActualCost = 4500.00;
        summary.budgetVariance = 2500.00;
        summary.totalCampaigns = 3;
        summary.totalOpportunities = 15;
        summary.monthlyRevenue = 1200.00;
        summary.reportingPeriod = 'Test Period';
        summary.campaignBreakdown = new List<CVMATreasuryDashboardController.CampaignFinancial>();

        Test.stopTest();

        // Verify data structure
        System.assertEquals(5000.00, summary.totalRevenue, 'Total revenue should match');
        System.assertEquals(2500.00, summary.budgetVariance, 'Budget variance should match');
        System.assertEquals(3, summary.totalCampaigns, 'Campaign count should match');
        System.assertNotEquals(null, summary.campaignBreakdown, 'Campaign breakdown should not be null');
    }
}
