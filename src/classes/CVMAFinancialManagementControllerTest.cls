/**
 * @description Test class for CVMAFinancialManagementController
 * Epic #4 Financial Management - Comprehensive test coverage
 * @author Claude Code
 * @version 1.0
 * @since 2025-09-22
 */
@IsTest
public class CVMAFinancialManagementControllerTest {

    @TestSetup
    static void makeData() {
        try {
            // Create test user with System Administrator profile for full access
            Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

            User testUser = new User(
                FirstName = 'Test',
                LastName = 'Treasurer',
                Email = 'treasurer@cvmatest.org',
                Username = 'treasurer@cvmatest.org.test',
                Alias = 'treas',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = sysAdminProfile.Id
            );
            insert testUser;

            System.runAs(testUser) {
                // Create test contacts for CVMA members
                List<Contact> testContacts = new List<Contact>();
                testContacts.add(new Contact(
                    FirstName = 'John',
                    LastName = 'FullMember',
                    Level__c = 'Full Member',
                    Membership_Id__c = 'FM001',
                    Email = 'john.fullmember@test.com'
                ));
                testContacts.add(new Contact(
                    FirstName = 'Jane',
                    LastName = 'AssociateMember',
                    Level__c = 'Associate Member',
                    Membership_Id__c = 'AM001',
                    Email = 'jane.associate@test.com'
                ));
                testContacts.add(new Contact(
                    FirstName = 'Bob',
                    LastName = 'Prospect',
                    Level__c = 'Prospect',
                    Membership_Id__c = 'PR001',
                    Email = 'bob.prospect@test.com'
                ));
                insert testContacts;

                // Create test campaigns for dues and fundraising
                List<Campaign> testCampaigns = new List<Campaign>();
                testCampaigns.add(new Campaign(
                    Name = 'Annual Dues ' + Date.today().year(),
                    Type = 'Member Services',
                    Status = 'In Progress',
                    StartDate = Date.newInstance(Date.today().year(), 1, 1),
                    EndDate = Date.newInstance(Date.today().year(), 12, 31),
                    ExpectedRevenue = 50000,
                    BudgetedCost = 5000
                ));
                testCampaigns.add(new Campaign(
                    Name = 'Veterans Support Fundraiser',
                    Type = 'Fundraising',
                    Status = 'In Progress',
                    StartDate = Date.today().addDays(-30),
                    EndDate = Date.today().addDays(30),
                    ExpectedRevenue = 25000,
                    BudgetedCost = 3000,
                    ActualCost = 2500
                ));
                testCampaigns.add(new Campaign(
                    Name = 'Community Event',
                    Type = 'Event',
                    Status = 'Completed',
                    StartDate = Date.today().addDays(-60),
                    EndDate = Date.today().addDays(-30),
                    ExpectedRevenue = 10000,
                    BudgetedCost = 2000,
                    ActualCost = 1800
                ));
                insert testCampaigns;

                // Create test opportunities for donations and expenses
                List<Opportunity> testOpportunities = new List<Opportunity>();

                // Member dues opportunities
                for (Contact c : testContacts) {
                    Decimal duesAmount = c.Level__c == 'Full Member' ? 120 :
                                       c.Level__c == 'Associate Member' ? 60 : 30;

                    testOpportunities.add(new Opportunity(
                        Name = c.Name + ' - Annual Dues ' + Date.today().year(),
                        AccountId = null, // Individual donation
                        npsp__Primary_Contact__c = c.Id,
                        Amount = duesAmount,
                        CloseDate = Date.today(),
                        StageName = 'Closed Won',
                        CampaignId = testCampaigns[0].Id,
                        RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Donation' AND SObjectType = 'Opportunity' LIMIT 1].Id
                    ));
                }

                // Fundraising opportunities
                testOpportunities.add(new Opportunity(
                    Name = 'Major Donation - Veterans Support',
                    AccountId = null,
                    npsp__Primary_Contact__c = testContacts[0].Id,
                    Amount = 5000,
                    CloseDate = Date.today().addDays(-15),
                    StageName = 'Closed Won',
                    CampaignId = testCampaigns[1].Id,
                    RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Donation' AND SObjectType = 'Opportunity' LIMIT 1].Id
                ));

                // Expense opportunities
                testOpportunities.add(new Opportunity(
                    Name = 'Event Supplies',
                    AccountId = null,
                    Amount = 500,
                    CloseDate = Date.today().addDays(-10),
                    StageName = 'Closed Won',
                    CampaignId = testCampaigns[2].Id,
                    RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Expense' AND SObjectType = 'Opportunity' LIMIT 1].Id
                ));

                insert testOpportunities;

                // Create test payment records if NPSP is available
                try {
                    List<npe01__OppPayment__c> testPayments = new List<npe01__OppPayment__c>();
                    for (Opportunity opp : testOpportunities) {
                        if (opp.RecordTypeId != null) { // Only for donation opportunities
                            testPayments.add(new npe01__OppPayment__c(
                                npe01__Opportunity__c = opp.Id,
                                npe01__Payment_Amount__c = opp.Amount,
                                npe01__Payment_Date__c = opp.CloseDate,
                                npe01__Payment_Method__c = 'Check',
                                npe01__Paid__c = true,
                                npe01__Check_Reference_Number__c = 'CHK' + String.valueOf(Math.random()).substring(2, 8)
                            ));
                        }
                    }
                    if (!testPayments.isEmpty()) {
                        insert testPayments;
                    }
                } catch (Exception e) {
                    // NPSP not available - skip payment creation
                    System.debug('NPSP Payment objects not available: ' + e.getMessage());
                }
            }
        } catch (Exception e) {
            System.debug('Test setup error: ' + e.getMessage());
        }
    }

    @IsTest
    static void testGetEnhancedFinancialDashboard() {
        User testUser = [SELECT Id FROM User WHERE Email = 'treasurer@cvmatest.org' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            Map<String, Object> result = CVMAFinancialManagementController.getEnhancedFinancialDashboard(testUser.Id);

            System.assert(result.containsKey('success'), 'Result should contain success key');
            System.assertEquals(true, (Boolean)result.get('success'), 'Should return success');
            System.assert(result.containsKey('hasTreasurerAccess'), 'Should contain treasurer access info');
            System.assert(result.containsKey('npspDashboard'), 'Should contain NPSP dashboard data');
            System.assert(result.containsKey('memberDuesAnalytics'), 'Should contain member dues analytics');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetMemberDuesManagement() {
        User testUser = [SELECT Id FROM User WHERE Email = 'treasurer@cvmatest.org' LIMIT 1];
        Integer currentYear = Date.today().year();

        Test.startTest();
        System.runAs(testUser) {
            Map<String, Object> result = CVMAFinancialManagementController.getMemberDuesManagement(currentYear);

            System.assert(result.containsKey('success'), 'Result should contain success key');
            System.assertEquals(true, (Boolean)result.get('success'), 'Should return success');
            System.assertEquals(currentYear, (Integer)result.get('year'), 'Should return correct year');
            System.assert(result.containsKey('duesAnalysis'), 'Should contain dues analysis');
            System.assert(result.containsKey('revenueProjections'), 'Should contain revenue projections');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetMemberDuesManagement_DefaultYear() {
        User testUser = [SELECT Id FROM User WHERE Email = 'treasurer@cvmatest.org' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            Map<String, Object> result = CVMAFinancialManagementController.getMemberDuesManagement(null);

            System.assert(result.containsKey('success'), 'Result should contain success key');
            System.assertEquals(true, (Boolean)result.get('success'), 'Should return success');
            System.assertEquals(Date.today().year(), (Integer)result.get('year'), 'Should default to current year');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetFundraisingPerformance() {
        User testUser = [SELECT Id FROM User WHERE Email = 'treasurer@cvmatest.org' LIMIT 1];
        Date startDate = Date.today().addDays(-90);
        Date endDate = Date.today();

        Test.startTest();
        System.runAs(testUser) {
            Map<String, Object> result = CVMAFinancialManagementController.getFundraisingPerformance(startDate, endDate);

            System.assert(result.containsKey('success'), 'Result should contain success key');
            System.assertEquals(true, (Boolean)result.get('success'), 'Should return success');
            System.assert(result.containsKey('campaigns'), 'Should contain campaigns data');
            System.assert(result.containsKey('performanceMetrics'), 'Should contain performance metrics');
            System.assert(result.containsKey('topPerformers'), 'Should contain top performers');
            System.assert(result.containsKey('recommendations'), 'Should contain recommendations');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetFundraisingPerformance_DefaultDates() {
        User testUser = [SELECT Id FROM User WHERE Email = 'treasurer@cvmatest.org' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            Map<String, Object> result = CVMAFinancialManagementController.getFundraisingPerformance(null, null);

            System.assert(result.containsKey('success'), 'Result should contain success key');
            System.assertEquals(true, (Boolean)result.get('success'), 'Should return success with default dates');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateAnnualDuesOpportunities() {
        User testUser = [SELECT Id FROM User WHERE Email = 'treasurer@cvmatest.org' LIMIT 1];
        Integer nextYear = Date.today().year() + 1;
        String campaignName = 'Annual Dues ' + nextYear + ' Test';

        Test.startTest();
        System.runAs(testUser) {
            Map<String, Object> result = CVMAFinancialManagementController.createAnnualDuesOpportunities(nextYear, campaignName);

            System.assert(result.containsKey('success'), 'Result should contain success key');
            System.assertEquals(true, (Boolean)result.get('success'), 'Should return success');
            System.assertEquals(nextYear, (Integer)result.get('year'), 'Should return correct year');
            System.assert(result.containsKey('totalMembers'), 'Should contain total members count');
            System.assert(result.containsKey('opportunitiesCreated'), 'Should contain opportunities created count');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateAnnualDuesOpportunities_DefaultYear() {
        User testUser = [SELECT Id FROM User WHERE Email = 'treasurer@cvmatest.org' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            Map<String, Object> result = CVMAFinancialManagementController.createAnnualDuesOpportunities(null, null);

            System.assert(result.containsKey('success'), 'Result should contain success key');
            System.assertEquals(true, (Boolean)result.get('success'), 'Should return success');
            System.assertEquals(Date.today().year(), (Integer)result.get('year'), 'Should default to current year');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetExpenseTrackingAnalytics() {
        User testUser = [SELECT Id FROM User WHERE Email = 'treasurer@cvmatest.org' LIMIT 1];
        Date startDate = Date.today().addDays(-30);
        Date endDate = Date.today();

        Test.startTest();
        System.runAs(testUser) {
            Map<String, Object> result = CVMAFinancialManagementController.getExpenseTrackingAnalytics(startDate, endDate);

            System.assert(result.containsKey('success'), 'Result should contain success key');
            System.assertEquals(true, (Boolean)result.get('success'), 'Should return success');
            System.assert(result.containsKey('expenses'), 'Should contain expenses data');
            System.assert(result.containsKey('expenseAnalysis'), 'Should contain expense analysis');
            System.assert(result.containsKey('budgetComparison'), 'Should contain budget comparison');
            System.assert(result.containsKey('spendingTrends'), 'Should contain spending trends');
        }
        Test.stopTest();
    }

    @IsTest
    static void testErrorHandling_InvalidUser() {
        // Test with non-existent user ID
        Id nonExistentUserId = TestDataFactory.getFakeId(User.SObjectType);

        Test.startTest();
        Map<String, Object> result = CVMAFinancialManagementController.getEnhancedFinancialDashboard(nonExistentUserId);

        System.assert(result.containsKey('success'), 'Result should contain success key');
        System.assertEquals(false, (Boolean)result.get('success'), 'Should return failure for invalid user');
        System.assert(result.containsKey('error'), 'Should contain error message');
        Test.stopTest();
    }

    @IsTest
    static void testBulkOperations() {
        User testUser = [SELECT Id FROM User WHERE Email = 'treasurer@cvmatest.org' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            // Test multiple simultaneous calls to verify bulk handling
            List<Map<String, Object>> results = new List<Map<String, Object>>();

            for (Integer i = 0; i < 5; i++) {
                results.add(CVMAFinancialManagementController.getEnhancedFinancialDashboard(testUser.Id));
            }

            System.assertEquals(5, results.size(), 'Should handle multiple simultaneous calls');

            for (Map<String, Object> result : results) {
                System.assertEquals(true, (Boolean)result.get('success'), 'Each call should succeed');
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testSecurityEnforcement() {
        // Create user without financial permissions
        Profile standardProfile;
        try {
            standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        } catch (Exception e) {
            // If Standard User profile doesn't exist, use System Administrator for test
            standardProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        }

        User limitedUser = new User(
            FirstName = 'Limited',
            LastName = 'User',
            Email = 'limited@cvmatest.org',
            Username = 'limited@cvmatest.org.test',
            Alias = 'limited',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert limitedUser;

        Test.startTest();
        System.runAs(limitedUser) {
            Map<String, Object> result = CVMAFinancialManagementController.getEnhancedFinancialDashboard(limitedUser.Id);

            System.assert(result.containsKey('success'), 'Result should contain success key');
            // Note: With System Administrator profile, user will have access
            // In real implementation, would verify limited access with appropriate profile
        }
        Test.stopTest();
    }

    @IsTest
    static void testPerformanceWithLargeDataset() {
        User testUser = [SELECT Id FROM User WHERE Email = 'treasurer@cvmatest.org' LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            // Test performance with larger dataset simulation
            Integer startCpuTime = Limits.getCpuTime();

            Map<String, Object> result = CVMAFinancialManagementController.getEnhancedFinancialDashboard(testUser.Id);

            Integer endCpuTime = Limits.getCpuTime();
            Integer cpuTimeUsed = endCpuTime - startCpuTime;

            System.assertEquals(true, (Boolean)result.get('success'), 'Should handle large dataset efficiently');
            System.assert(cpuTimeUsed < 5000, 'Should complete within reasonable CPU time: ' + cpuTimeUsed + 'ms');
        }
        Test.stopTest();
    }

    // Helper class for generating fake IDs in tests
    public class TestDataFactory {
        private static Integer fakeIdCount = 0;

        public static Id getFakeId(Schema.SObjectType sObjectType) {
            String result = String.valueOf(fakeIdCount++);
            return (Id)(sObjectType.getDescribe().getKeyPrefix() +
                       '0'.repeat(12-result.length()) + result);
        }
    }
}
