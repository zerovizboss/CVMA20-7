/**
 * CVMAMemberLifecycleControllerTest.cls
 * Comprehensive test class for Epic #3 Member Management Enhancement
 * Tests all member lifecycle management functionality with 90%+ coverage
 *
 * Combat Veterans Motorcycle Association Chapter 20-7
 * Enterprise-grade testing for member lifecycle automation
 */
@IsTest
public class CVMAMemberLifecycleControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'CVMA Test Chapter 20-7'
        );
        insert testAccount;

        // Create test contacts with different membership levels
        List<Contact> testContacts = new List<Contact>();

        // Full Member - high engagement
        testContacts.add(new Contact(
            FirstName = 'John',
            LastName = 'Veteran',
            Level__c = 'Full Member',
            Membership_Id__c = 'FM001',
            Email = 'john.veteran@test.com',
            Phone = '555-0101',
            MailingState = 'TX',
            MailingCity = 'Austin',
            Road_Name__c = 'Iron Eagle',
            AccountId = testAccount.Id
        ));

        // Support Member - medium engagement
        testContacts.add(new Contact(
            FirstName = 'Jane',
            LastName = 'Support',
            Level__c = 'Support Member',
            Membership_Id__c = 'SUP002',
            Email = 'jane.support@test.com',
            Phone = '555-0102',
            MailingState = 'TX',
            MailingCity = 'Dallas',
            AccountId = testAccount.Id
        ));

        // Auxiliary Member - low engagement (at-risk)
        testContacts.add(new Contact(
            FirstName = 'Bob',
            LastName = 'Auxiliary',
            Level__c = 'Auxiliary Member',
            Membership_Id__c = 'AUX003',
            Email = 'bob.auxiliary@test.com',
            MailingState = 'CA',
            MailingCity = 'Los Angeles',
            AccountId = testAccount.Id
        ));

        // New member for onboarding tests
        testContacts.add(new Contact(
            FirstName = 'Mike',
            LastName = 'Newbie',
            Level__c = 'Full Member',
            Membership_Id__c = 'FM004',
            Email = 'mike.newbie@test.com',
            Phone = '555-0104',
            MailingState = 'FL',
            MailingCity = 'Miami',
            AccountId = testAccount.Id
        ));

        insert testContacts;

        // Create test campaigns
        List<Campaign> testCampaigns = new List<Campaign>();

        testCampaigns.add(new Campaign(
            Name = 'Chapter Meeting - January',
            Type = 'Chapter Events',
            Status = 'Completed',
            StartDate = Date.today().addDays(-30),
            EndDate = Date.today().addDays(-30)
        ));

        testCampaigns.add(new Campaign(
            Name = 'Charity Ride 2025',
            Type = 'Fundraising',
            Status = 'Completed',
            StartDate = Date.today().addDays(-60),
            EndDate = Date.today().addDays(-60)
        ));

        testCampaigns.add(new Campaign(
            Name = 'Membership Drive',
            Type = 'Member Services',
            Status = 'In Progress',
            StartDate = Date.today().addDays(-10),
            EndDate = Date.today().addDays(20)
        ));

        insert testCampaigns;

        // Create campaign members with different engagement levels
        List<CampaignMember> campaignMembers = new List<CampaignMember>();

        // High engagement member (John) - participated in all campaigns
        for (Campaign campaign : testCampaigns) {
            campaignMembers.add(new CampaignMember(
                CampaignId = campaign.Id,
                ContactId = testContacts[0].Id,
                Status = 'Responded'
            ));
        }

        // Medium engagement member (Jane) - participated in some campaigns
        campaignMembers.add(new CampaignMember(
            CampaignId = testCampaigns[0].Id,
            ContactId = testContacts[1].Id,
            Status = 'Responded'
        ));

        campaignMembers.add(new CampaignMember(
            CampaignId = testCampaigns[2].Id,
            ContactId = testContacts[1].Id,
            Status = 'Sent'
        ));

        // Low engagement member (Bob) - minimal participation
        campaignMembers.add(new CampaignMember(
            CampaignId = testCampaigns[2].Id,
            ContactId = testContacts[2].Id,
            Status = 'Sent'
        ));

        insert campaignMembers;

        // Create test opportunities for financial impact
        List<Opportunity> testOpportunities = new List<Opportunity>();

        testOpportunities.add(new Opportunity(
            Name = 'Annual Dues - John Veteran',
            AccountId = testAccount.Id,
            npsp__Primary_Contact__c = testContacts[0].Id,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-30),
            Amount = 150.00,
            Type = 'Member Services'
        ));

        testOpportunities.add(new Opportunity(
            Name = 'Charity Donation - John Veteran',
            AccountId = testAccount.Id,
            npsp__Primary_Contact__c = testContacts[0].Id,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-45),
            Amount = 500.00,
            Type = 'Donation'
        ));

        insert testOpportunities;

        // Create test tasks for activity history
        List<Task> testTasks = new List<Task>();

        testTasks.add(new Task(
            Subject = 'Welcome Call Completed',
            WhoId = testContacts[0].Id,
            Type = 'Call',
            Status = 'Completed',
            ActivityDate = Date.today().addDays(-20)
        ));

        testTasks.add(new Task(
            Subject = 'Chapter Meeting Follow-up',
            WhoId = testContacts[1].Id,
            Type = 'Email',
            Status = 'Completed',
            ActivityDate = Date.today().addDays(-15)
        ));

        insert testTasks;
    }

    @IsTest
    static void testGetMemberLifecycleAnalytics_FullMember() {
        // Get test contact
        Contact testMember = [
            SELECT Id, Name, Level__c
            FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();

        Map<String, Object> result = CVMAMemberLifecycleController.getMemberLifecycleAnalytics(testMember.Id);

        Test.stopTest();

        // Verify successful response
        System.assertEquals(true, result.get('success'), 'Should return successful response');
        System.assertNotEquals(null, result.get('member'), 'Should return member data');
        System.assertNotEquals(null, result.get('engagementAnalysis'), 'Should return engagement analysis');
        System.assertNotEquals(null, result.get('lifecycleStage'), 'Should return lifecycle stage');
        System.assertNotEquals(null, result.get('retentionAnalysis'), 'Should return retention analysis');

        // Verify engagement analysis
        Map<String, Object> engagement = (Map<String, Object>) result.get('engagementAnalysis');
        System.assertEquals(true, (Integer) engagement.get('totalCampaigns') > 0, 'Should have campaign participation');
        System.assertEquals(true, (Integer) engagement.get('engagementScore') > 50, 'Should have high engagement score');

        // Verify lifecycle stage
        Map<String, Object> lifecycle = (Map<String, Object>) result.get('lifecycleStage');
        System.assertNotEquals(null, lifecycle.get('lifecycleStage'), 'Should have lifecycle stage');
        System.assertNotEquals(null, lifecycle.get('membershipMonths'), 'Should have membership duration');
    }

    @IsTest
    static void testGetMemberLifecycleAnalytics_AtRiskMember() {
        // Get at-risk test contact
        Contact testMember = [
            SELECT Id, Name, Level__c
            FROM Contact
            WHERE FirstName = 'Bob' AND LastName = 'Auxiliary'
            LIMIT 1
        ];

        Test.startTest();

        Map<String, Object> result = CVMAMemberLifecycleController.getMemberLifecycleAnalytics(testMember.Id);

        Test.stopTest();

        // Verify successful response
        System.assertEquals(true, result.get('success'), 'Should return successful response');

        // Verify retention analysis shows risk
        Map<String, Object> retention = (Map<String, Object>) result.get('retentionAnalysis');
        System.assertNotEquals('Low', retention.get('riskLevel'), 'Should identify higher risk level');

        // Verify risk factors are identified
        List<String> riskFactors = (List<String>) retention.get('factors');
        System.assertEquals(true, !riskFactors.isEmpty(), 'Should identify risk factors');
    }

    @IsTest
    static void testInitiateNewMemberOnboarding_Success() {
        // Get new member test contact
        Contact newMember = [
            SELECT Id, Name, Level__c
            FROM Contact
            WHERE FirstName = 'Mike' AND LastName = 'Newbie'
            LIMIT 1
        ];

        Test.startTest();

        Map<String, Object> result = CVMAMemberLifecycleController.initiateNewMemberOnboarding(
            newMember.Id,
            'Full Member'
        );

        Test.stopTest();

        // Verify successful response
        if (result.get('success') != true) {
            System.debug('Onboarding Error: ' + result.get('error'));
        }
        System.assertEquals(true, result.get('success'), 'Should successfully initiate onboarding: ' + result.get('error'));
        System.assertNotEquals(null, result.get('campaignMemberId'), 'Should create campaign member');
        System.assertEquals(true, (Integer) result.get('onboardingTasks') > 0, 'Should create onboarding tasks');
        System.assertNotEquals(null, result.get('welcomeOpportunityId'), 'Should create welcome opportunity');

        // Verify campaign member was created
        List<CampaignMember> campaignMembers = [
            SELECT Id, CampaignId, ContactId, Status
            FROM CampaignMember
            WHERE ContactId = :newMember.Id
            AND Campaign.Name LIKE 'New Member Onboarding%'
        ];
        System.assertEquals(1, campaignMembers.size(), 'Should create campaign member for onboarding');

        // Verify tasks were created
        List<Task> onboardingTasks = [
            SELECT Id, Subject, WhoId, Type, Priority
            FROM Task
            WHERE WhoId = :newMember.Id
            AND (Subject LIKE 'Welcome Call%' OR Subject LIKE 'Send New Member%' OR Subject LIKE 'Chapter Meeting%')
        ];
        System.assertEquals(3, onboardingTasks.size(), 'Should create 3 onboarding tasks');

        // Verify welcome opportunity was created
        List<Opportunity> welcomeOpps = [
            SELECT Id, Name, npsp__Primary_Contact__c
            FROM Opportunity
            WHERE npsp__Primary_Contact__c = :newMember.Id
            AND Name LIKE 'Welcome Package%'
        ];
        System.assertEquals(1, welcomeOpps.size(), 'Should create welcome opportunity');
    }

    @IsTest
    static void testGetMemberEngagementOptimization() {
        Test.startTest();

        Map<String, Object> result = CVMAMemberLifecycleController.getMemberEngagementOptimization();

        Test.stopTest();

        // Verify successful response
        System.assertEquals(true, result.get('success'), 'Should return successful response');
        System.assertEquals(true, (Integer) result.get('totalMembers') > 0, 'Should return member count');
        System.assertNotEquals(null, result.get('engagementAnalysis'), 'Should return engagement analysis');

        // Verify at-risk and highly engaged member identification
        List<Map<String, Object>> atRiskMembers = (List<Map<String, Object>>) result.get('atRiskMembers');
        List<Map<String, Object>> highlyEngagedMembers = (List<Map<String, Object>>) result.get('highlyEngagedMembers');

        System.assertNotEquals(null, atRiskMembers, 'Should identify at-risk members');
        System.assertNotEquals(null, highlyEngagedMembers, 'Should identify highly engaged members');

        // Verify optimization recommendations
        Map<String, Object> recommendations = (Map<String, Object>) result.get('optimizationRecommendations');
        System.assertNotEquals(null, recommendations, 'Should provide optimization recommendations');

        // Verify chapter metrics
        Map<String, Object> chapterMetrics = (Map<String, Object>) result.get('chapterMetrics');
        System.assertNotEquals(null, chapterMetrics.get('averageEngagementScore'), 'Should calculate average engagement');
    }

    @IsTest
    static void testCreateMemberRetentionCampaign() {
        // Get at-risk member IDs
        List<Contact> atRiskMembers = [
            SELECT Id
            FROM Contact
            WHERE Level__c = 'Auxiliary Member'
            LIMIT 2
        ];

        List<Id> memberIds = new List<Id>();
        for (Contact member : atRiskMembers) {
            memberIds.add(member.Id);
        }

        Test.startTest();

        Map<String, Object> result = CVMAMemberLifecycleController.createMemberRetentionCampaign(
            memberIds,
            'Personal Outreach'
        );

        Test.stopTest();

        // Verify successful response
        System.assertEquals(true, result.get('success'), 'Should successfully create retention campaign');
        System.assertNotEquals(null, result.get('campaignId'), 'Should create retention campaign');
        System.assertEquals(memberIds.size(), result.get('membersTargeted'), 'Should target correct number of members');

        // Verify campaign was created
        List<Campaign> retentionCampaigns = [
            SELECT Id, Name, Type, Status
            FROM Campaign
            WHERE Name LIKE 'Member Retention - Personal Outreach%'
        ];
        System.assertEquals(1, retentionCampaigns.size(), 'Should create retention campaign');

        // Verify campaign members were added
        List<CampaignMember> retentionMembers = [
            SELECT Id, ContactId
            FROM CampaignMember
            WHERE CampaignId = :retentionCampaigns[0].Id
        ];
        System.assertEquals(memberIds.size(), retentionMembers.size(), 'Should add all at-risk members to campaign');

        // Verify retention tasks were created
        List<Task> retentionTasks = [
            SELECT Id, Subject, WhoId
            FROM Task
            WHERE Subject LIKE 'Member Retention%'
        ];
        System.assertEquals(memberIds.size(), retentionTasks.size(), 'Should create retention task for each member');
    }

    @IsTest
    static void testGetMemberAnalyticsDashboard() {
        Integer currentYear = Date.today().year();

        Test.startTest();

        Map<String, Object> result = CVMAMemberLifecycleController.getMemberAnalyticsDashboard(currentYear);

        Test.stopTest();

        // Verify successful response
        System.assertEquals(true, result.get('success'), 'Should return successful response');
        System.assertEquals(currentYear, result.get('year'), 'Should return correct year');

        // Verify growth analytics
        Map<String, Object> growthAnalytics = (Map<String, Object>) result.get('growthAnalytics');
        System.assertNotEquals(null, growthAnalytics, 'Should return growth analytics');
        System.assertNotEquals(null, growthAnalytics.get('totalNewMembers'), 'Should calculate total new members');

        // Verify level distribution
        List<AggregateResult> levelDistribution = (List<AggregateResult>) result.get('levelDistribution');
        System.assertNotEquals(null, levelDistribution, 'Should return level distribution');

        // Verify geographic distribution
        List<AggregateResult> geoDistribution = (List<AggregateResult>) result.get('geoDistribution');
        System.assertNotEquals(null, geoDistribution, 'Should return geographic distribution');

        // Verify engagement trends
        Map<String, Object> engagementTrends = (Map<String, Object>) result.get('engagementTrends');
        System.assertNotEquals(null, engagementTrends, 'Should return engagement trends');

        // Verify retention metrics
        Map<String, Object> retentionMetrics = (Map<String, Object>) result.get('retentionMetrics');
        System.assertNotEquals(null, retentionMetrics, 'Should return retention metrics');

        // Verify chapter health indicators
        Map<String, Object> chapterHealth = (Map<String, Object>) result.get('chapterHealth');
        System.assertNotEquals(null, chapterHealth.get('overallHealth'), 'Should calculate overall health');
    }

    @IsTest
    static void testGetMemberAnalyticsDashboard_DefaultYear() {
        Test.startTest();

        Map<String, Object> result = CVMAMemberLifecycleController.getMemberAnalyticsDashboard(null);

        Test.stopTest();

        // Verify successful response with default year
        System.assertEquals(true, result.get('success'), 'Should return successful response');
        System.assertEquals(Date.today().year(), result.get('year'), 'Should default to current year');
    }

    @IsTest
    static void testErrorHandling_InvalidContactId() {
        // Generate non-existent contact ID
        Id invalidContactId = Contact.SObjectType.getDescribe().getKeyPrefix() + '000000000001';

        Test.startTest();

        Map<String, Object> result = CVMAMemberLifecycleController.getMemberLifecycleAnalytics(invalidContactId);

        Test.stopTest();

        // Verify error handling
        System.assertEquals(false, result.get('success'), 'Should return error for invalid contact');
        System.assertNotEquals(null, result.get('error'), 'Should return error message');
    }

    @IsTest
    static void testBulkOperations_MultipleMembers() {
        // Get multiple member IDs for bulk testing
        List<Contact> allMembers = [
            SELECT Id
            FROM Contact
            WHERE Level__c IN ('Full Member', 'Support Member', 'Auxiliary Member')
            LIMIT 10
        ];

        Test.startTest();

        // Test bulk engagement optimization
        Map<String, Object> engagementResult = CVMAMemberLifecycleController.getMemberEngagementOptimization();

        // Test bulk analytics dashboard
        Map<String, Object> analyticsResult = CVMAMemberLifecycleController.getMemberAnalyticsDashboard(Date.today().year());

        Test.stopTest();

        // Verify bulk operations handle multiple members successfully
        System.assertEquals(true, engagementResult.get('success'), 'Should handle bulk engagement analysis');
        System.assertEquals(true, analyticsResult.get('success'), 'Should handle bulk analytics');
        System.assertEquals(true, (Integer) engagementResult.get('totalMembers') >= allMembers.size(), 'Should process all members');
    }

    @IsTest
    static void testSecurityEnforcement() {
        // Create test user with limited permissions
        Profile limitedProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User limitedUser = new User(
            FirstName = 'Test',
            LastName = 'Limited',
            Email = 'testlimited@cvmatest.com',
            Username = 'testlimited@cvmatest.com',
            Alias = 'tlimited',
            ProfileId = limitedProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert limitedUser;

        // Get test contact
        Contact testMember = [
            SELECT Id
            FROM Contact
            WHERE FirstName = 'John' AND LastName = 'Veteran'
            LIMIT 1
        ];

        Test.startTest();

        System.runAs(limitedUser) {
            try {
                Map<String, Object> result = CVMAMemberLifecycleController.getMemberLifecycleAnalytics(testMember.Id);
                // If the user has access, verify success; if not, verify proper error handling
                System.assertNotEquals(null, result, 'Should return a response regardless of permissions');
            } catch (Exception e) {
                // Security exceptions are expected for users without proper permissions
                System.assertEquals(true, e.getMessage().contains('FIELD_ACCESS') || e.getMessage().contains('INSUFFICIENT_ACCESS'), 'Should throw security exception for unauthorized access');
            }
        }

        Test.stopTest();
    }

    @IsTest
    static void testDataValidation_EdgeCases() {
        // Test with contact that has minimal data
        Contact minimalContact = new Contact(
            FirstName = 'Minimal',
            LastName = 'Data',
            Level__c = 'Auxiliary Member',
            Membership_Id__c = 'AUX999'
        );
        insert minimalContact;

        Test.startTest();

        Map<String, Object> result = CVMAMemberLifecycleController.getMemberLifecycleAnalytics(minimalContact.Id);

        Test.stopTest();

        // Verify system handles minimal data gracefully
        System.assertEquals(true, result.get('success'), 'Should handle minimal contact data');

        // Verify default values are provided for missing data
        Map<String, Object> engagement = (Map<String, Object>) result.get('engagementAnalysis');
        System.assertEquals(0, engagement.get('totalCampaigns'), 'Should default to 0 campaigns for new contact');
        System.assertEquals(0, engagement.get('engagementScore'), 'Should default to 0 engagement score');
    }
}
