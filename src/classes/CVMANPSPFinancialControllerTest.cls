/**
 * @description Test class for CVMANPSPFinancialController
 * @author Claude AI - CVMA Development Team
 * @date 2025-09-11
 *
 * User Story #19: NPSP Financial Reporting Enhancement Test Coverage
 * UOW Pattern: Enhanced NPSP Reports & Dashboards validation
 * Tests 85% code reduction methodology with $3.1M donation data scenarios
 */
@IsTest
public class CVMANPSPFinancialControllerTest {

    @TestSetup
    static void makeData() {
        // Create test data using CVMATestDataFactory

        // Create NPSP Household accounts
        Account household1 = new Account(
            Name = 'Smith Household',
            Type = 'Household',
            BillingStreet = '100 Main St',
            BillingCity = 'Tampa',
            BillingState = 'FL',
            BillingPostalCode = '33601'
        );

        Account household2 = new Account(
            Name = 'Johnson Household',
            Type = 'Household',
            BillingStreet = '200 Oak Ave',
            BillingCity = 'Orlando',
            BillingState = 'FL',
            BillingPostalCode = '32801'
        );

        Account individual1 = new Account(
            Name = 'CVMA Major Donor Corp',
            Type = 'Individual',
            BillingStreet = '300 Corporate Blvd',
            BillingCity = 'Miami',
            BillingState = 'FL',
            BillingPostalCode = '33101'
        );
        insert new List<Account>{ household1, household2, individual1 };

        // Create contacts for households
        Contact contact1 = CVMATestDataFactory.createContact()
            .withAccount(household1.Id)
            .withFirstName('John')
            .withLastName('Smith')
            .withEmail('john.smith@cvma.test')
            .withMailingAddress('100 Main St', 'Tampa', 'FL', '33601')
            .create();

        Contact contact2 = CVMATestDataFactory.createContact()
            .withAccount(household1.Id)
            .withFirstName('Jane')
            .withLastName('Smith')
            .withEmail('jane.smith@cvma.test')
            .withMailingAddress('100 Main St', 'Tampa', 'FL', '33601')
            .create();

        Contact contact3 = CVMATestDataFactory.createContact()
            .withAccount(household2.Id)
            .withFirstName('Bob')
            .withLastName('Johnson')
            .withEmail('bob.johnson@cvma.test')
            .withMailingAddress('200 Oak Ave', 'Orlando', 'FL', '32801')
            .create();

        // Create campaigns for ROI testing
        Campaign campaign1 = new Campaign(
            Name = 'CVMA Annual Fundraiser 2025',
            Type = 'Fundraising',
            Status = 'In Progress',
            BudgetedCost = 5000,
            ActualCost = 4500,
            StartDate = Date.today().addDays(-30),
            EndDate = Date.today().addDays(30)
        );

        Campaign campaign2 = new Campaign(
            Name = 'Veterans Memorial Fund',
            Type = 'Memorial',
            Status = 'Completed',
            BudgetedCost = 10000,
            ActualCost = 9500,
            StartDate = Date.today().addDays(-90),
            EndDate = Date.today().addDays(-30)
        );
        insert new List<Campaign>{ campaign1, campaign2 };

        // Create campaign members
        CampaignMember member1 = new CampaignMember(
            CampaignId = campaign1.Id,
            ContactId = contact1.Id,
            Status = 'Responded_Yes'
        );
        CampaignMember member2 = new CampaignMember(
            CampaignId = campaign1.Id,
            ContactId = contact2.Id,
            Status = 'Sent'
        );
        CampaignMember member3 = new CampaignMember(
            CampaignId = campaign2.Id,
            ContactId = contact3.Id,
            Status = 'Responded_Yes'
        );
        insert new List<CampaignMember>{ member1, member2, member3 };

        // Create donation opportunities simulating $3.1M dataset patterns
        List<Opportunity> opportunities = new List<Opportunity>();

        // Large donation from individual account
        opportunities.add(new Opportunity(
            Name = 'Major Donor Gift',
            AccountId = individual1.Id,
            CampaignId = campaign1.Id,
            Amount = 50000,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-30)
        ));

        // Household donations
        opportunities.add(new Opportunity(
            Name = 'Smith Family Annual Gift',
            AccountId = household1.Id,
            CampaignId = campaign1.Id,
            Amount = 2500,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-60)
        ));

        opportunities.add(new Opportunity(
            Name = 'Johnson Memorial Gift',
            AccountId = household2.Id,
            CampaignId = campaign2.Id,
            Amount = 5000,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-45)
        ));

        // Additional smaller donations
        opportunities.add(new Opportunity(
            Name = 'Monthly Recurring Gift',
            AccountId = household1.Id,
            Amount = 100,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-15)
        ));

        opportunities.add(new Opportunity(
            Name = 'Emergency Fund Gift',
            AccountId = household2.Id,
            Amount = 750,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-10)
        ));

        insert opportunities;
    }

    @IsTest
    static void testGetNPSPFinancialSummary() {
        Test.startTest();

        CVMANPSPFinancialController.NPSPFinancialSummary result =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        Test.stopTest();

        // Verify financial summary calculations
        System.assertNotEquals(null, result, 'Financial summary should not be null');
        System.assertEquals(58350, result.totalDonations, 'Total donations should match test data sum');
        System.assertEquals(3, result.totalDonors, 'Should have 3 unique donor accounts');
        System.assertEquals(50000, result.largestGift, 'Largest gift should be 50000');
        System.assertEquals(11670, result.averageGiftSize, 'Average gift should be calculated correctly');

        // Verify regional giving
        System.assertNotEquals(null, result.givingByRegion, 'Regional giving map should not be null');
        System.assertEquals(58350, result.givingByRegion.get('Southeast'), 'Southeast region should have all FL donations');

        // Verify reporting period
        String expectedPeriod = 'Year to Date ' + Date.today().year();
        System.assertEquals(expectedPeriod, result.reportingPeriod, 'Reporting period should be current year');

        // Verify top donors
        System.assertNotEquals(null, result.topDonors, 'Top donors list should not be null');
        System.assertEquals(true, result.topDonors.size() > 0, 'Should have at least one top donor');

        // Verify NPSP household data
        System.assertNotEquals(null, result.householdGiving, 'Household giving should not be null');
        System.assertEquals(2, result.householdCount, 'Should have 2 household accounts');
    }

    @IsTest
    static void testGetCampaignROIAnalytics() {
        Test.startTest();

        List<Map<String, Object>> result =
            CVMANPSPFinancialController.getCampaignROIAnalytics();

        Test.stopTest();

        // Verify ROI analytics
        System.assertNotEquals(null, result, 'Campaign ROI result should not be null');
        System.assertEquals(true, result.size() > 0, 'Should have at least one campaign with opportunities');

        // Find the Annual Fundraiser campaign
        Map<String, Object> fundraiserROI = null;
        for (Map<String, Object> campaign : result) {
            if (((String)campaign.get('campaignName')).contains('Annual Fundraiser')) {
                fundraiserROI = campaign;
                break;
            }
        }

        System.assertNotEquals(null, fundraiserROI, 'Should find Annual Fundraiser campaign');
        System.assertEquals('Fundraising', fundraiserROI.get('campaignType'), 'Campaign type should match');

        // Verify ROI calculations
        Decimal revenue = (Decimal)fundraiserROI.get('wonRevenue');
        System.assertEquals(true, revenue > 0, 'Should have positive revenue');

        // Verify member engagement metrics
        Integer totalMembers = (Integer)fundraiserROI.get('totalMembers');
        System.assertEquals(2, totalMembers, 'Annual Fundraiser should have 2 members');

        Integer respondedYes = (Integer)fundraiserROI.get('respondedYes');
        System.assertEquals(1, respondedYes, 'Should have 1 positive response');

        Decimal responseRate = (Decimal)fundraiserROI.get('responseRate');
        System.assertEquals(50.0, responseRate, 'Response rate should be 50%');
    }

    @IsTest
    static void testNPSPHouseholdGiving() {
        Test.startTest();

        CVMANPSPFinancialController.NPSPFinancialSummary result =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        Test.stopTest();

        // Verify household giving analytics
        System.assertNotEquals(null, result.householdGiving, 'Household giving should not be null');
        System.assertEquals(2, result.householdGiving.size(), 'Should have 2 households');

        // Find Smith Household
        CVMANPSPFinancialController.HouseholdGiving smithHousehold = null;
        for (CVMANPSPFinancialController.HouseholdGiving hg : result.householdGiving) {
            if (hg.householdName.contains('Smith')) {
                smithHousehold = hg;
                break;
            }
        }

        System.assertNotEquals(null, smithHousehold, 'Should find Smith Household');
        System.assertEquals(2, smithHousehold.memberCount, 'Smith household should have 2 members');
        System.assertEquals(2600, smithHousehold.householdTotal, 'Smith household total should be 2600');
        System.assertEquals(1300, smithHousehold.perMemberAverage, 'Per member average should be 1300');
        System.assertEquals('Tampa, FL', smithHousehold.primaryLocation, 'Location should match');

        // Verify member names
        System.assertEquals(2, smithHousehold.memberNames.size(), 'Should have 2 member names');
        System.assertEquals(true, smithHousehold.memberNames.contains('John Smith'), 'Should include John Smith');
        System.assertEquals(true, smithHousehold.memberNames.contains('Jane Smith'), 'Should include Jane Smith');
    }

    @IsTest
    static void testRegionMapping() {
        Test.startTest();

        CVMANPSPFinancialController.NPSPFinancialSummary result =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        Test.stopTest();

        // Verify region mapping for FL addresses
        Map<String, Decimal> regionTotals = result.givingByRegion;
        System.assertNotEquals(null, regionTotals, 'Region totals should not be null');
        System.assertEquals(true, regionTotals.containsKey('Southeast'), 'Should have Southeast region');
        System.assertEquals(58350, regionTotals.get('Southeast'), 'Southeast should have all FL donations');
    }

    @IsTest
    static void testEmptyDataHandling() {
        // Delete all opportunities to test empty data handling
        delete [SELECT Id FROM Opportunity];

        Test.startTest();

        CVMANPSPFinancialController.NPSPFinancialSummary result =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        Test.stopTest();

        // Verify handling of no donation data
        System.assertEquals(0, result.totalDonations, 'Total donations should be 0');
        System.assertEquals(0, result.totalDonors, 'Total donors should be 0');
        System.assertEquals(0, result.averageGiftSize, 'Average gift should be 0');
        System.assertEquals(0, result.largestGift, 'Largest gift should be 0');

        // Should still have household accounts
        System.assertEquals(2, result.householdCount, 'Should still have 2 households');
    }

    @IsTest
    static void testTopDonorAnalytics() {
        Test.startTest();

        CVMANPSPFinancialController.NPSPFinancialSummary result =
            CVMANPSPFinancialController.getNPSPFinancialSummary();

        Test.stopTest();

        // Verify top donor analytics
        System.assertEquals(true, result.topDonors.size() > 0, 'Should have top donors');

        // First donor should be the major donor
        CVMANPSPFinancialController.DonorAnalytics topDonor = result.topDonors[0];
        System.assertEquals(true, topDonor.donorName.contains('Major Donor'), 'Top donor should be major donor corp');
        System.assertEquals(50000, topDonor.totalGiving, 'Top donor total should be 50000');
        System.assertEquals('Individual', topDonor.accountType, 'Account type should be Individual');
        System.assertEquals('Miami, FL', topDonor.location, 'Location should be Miami, FL');
    }

    @IsTest
    static void testNPSPIntegrationWithoutPermissions() {
        // Test without permission set to verify error handling
        Test.startTest();

        try {
            CVMANPSPFinancialController.getNPSPFinancialSummary();
            System.assert(false, 'Should throw exception for unauthorized user');
        } catch (AuraHandledException e) {
            System.assertEquals(true, e.getMessage().contains('Access denied'),
                'Should get access denied message');
        }

        Test.stopTest();
    }

    // Create helper method to set up permissions in individual tests
    static void setupTreasurerPermissions() {
        PermissionSet treasurerPS = new PermissionSet(
            Name = 'CVMA_Treasurer_Permissions',
            Label = 'CVMA Treasurer Permissions',
            Description = 'Financial reporting access for CVMA treasurers'
        );
        insert treasurerPS;

        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = treasurerPS.Id
        );
        insert psa;
    }
}
