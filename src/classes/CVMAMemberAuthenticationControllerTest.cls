/**
 * CVMAMemberAuthenticationControllerTest
 * Test Coverage for Member Authentication and Epic #8 Access
 *
 * @author CVMA Chapter 20-7 Development Team
 * @version 1.0
 * @since September 2025
 */
@IsTest
public class CVMAMemberAuthenticationControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test members using the factory
        List<Contact> testMembers = new List<Contact>();

        // Full Member
        testMembers.add(CVMATestDataFactory.createContact()
            .withFirstName('John')
            .withLastName('FullMember')
            .withEmail('john.full@cvma.org')
            .withLevel('Full Member')
            .withMembershipId('FM123')
            .withRoadName('Road Captain')
            .withCity('San Diego')
            .withState('CA')
            .create());

        // Support Member
        testMembers.add(CVMATestDataFactory.createContact()
            .withFirstName('Bob')
            .withLastName('SupportMember')
            .withEmail('bob.support@cvma.org')
            .withLevel('Support Member')
            .withMembershipId('SUP789')
            .withCity('Sacramento')
            .withState('CA')
            .create());

        // Auxiliary Member
        testMembers.add(CVMATestDataFactory.createContact()
            .withFirstName('Jane')
            .withLastName('AuxiliaryMember')
            .withEmail('jane.auxiliary@cvma.org')
            .withLevel('Auxiliary Member')
            .withMembershipId('AUX456')
            .withCity('Los Angeles')
            .withState('CA')
            .create());

        // Expired Member
        Contact expiredMember = CVMATestDataFactory.createContact()
            .withFirstName('Charlie')
            .withLastName('ExpiredMember')
            .withEmail('charlie.expired@cvma.org')
            .withLevel('Full Member')
            .withMembershipId('FM999')
            .withCity('San Francisco')
            .withState('CA')
            .create();
        expiredMember.npo02__MembershipEndDate__c = Date.today().addDays(-30);
        testMembers.add(expiredMember);
    }

    @IsTest
    static void testAuthenticateMember_FullMember_Success() {
        Test.startTest();
        Map<String, Object> result = CVMAMemberAuthenticationController.authenticateMember(
            'FM123', 'FullMember', 'john.full@cvma.org'
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Authentication should succeed');
        System.assertEquals('Full Member', result.get('membershipLevel'), 'Should return correct membership level');
        System.assertEquals('Premium', result.get('accessLevel'), 'Full members should have premium access');
        System.assertEquals('active', result.get('membershipStatus'), 'Should be active member');

        Map<String, List<String>> features = (Map<String, List<String>>) result.get('epic8Features');
        System.assert(features.containsKey('analytics'), 'Should have analytics features');
        System.assert(features.containsKey('external_integration'), 'Should have external integration features');
    }

    @IsTest
    static void testAuthenticateMember_AuxiliaryMember_Success() {
        Test.startTest();
        Map<String, Object> result = CVMAMemberAuthenticationController.authenticateMember(
            'AUX456', 'AuxiliaryMember', null
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Authentication should succeed');
        System.assertEquals('Auxiliary Member', result.get('membershipLevel'), 'Should return correct membership level');
        System.assertEquals('Basic', result.get('accessLevel'), 'Auxiliary members should have basic access');
    }

    @IsTest
    static void testAuthenticateMember_ExpiredMember_Success() {
        Test.startTest();
        Map<String, Object> result = CVMAMemberAuthenticationController.authenticateMember(
            'FM999', 'ExpiredMember', null
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Authentication should succeed');
        System.assertEquals('expired', result.get('membershipStatus'), 'Should show expired status');
        System.assertEquals('Full Member', result.get('membershipLevel'), 'Should retain membership level');
    }

    @IsTest
    static void testAuthenticateMember_InvalidCredentials() {
        Test.startTest();
        try {
            CVMAMemberAuthenticationController.authenticateMember(
                'INVALID123', 'NonExistent', 'fake@email.com'
            );
            System.assert(false, 'Should throw exception for invalid credentials');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid membership credentials'), 'Should return appropriate error message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAuthenticateMember_EmailMismatch() {
        Test.startTest();
        try {
            CVMAMemberAuthenticationController.authenticateMember(
                'FM123', 'FullMember', 'wrong@email.com'
            );
            System.assert(false, 'Should throw exception for email mismatch');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Email address does not match'), 'Should return email mismatch error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAuthenticateMember_MissingParameters() {
        Test.startTest();
        try {
            CVMAMemberAuthenticationController.authenticateMember(
                '', 'FullMember', null
            );
            System.assert(false, 'Should throw exception for missing parameters');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should return required fields error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetMemberEpic8Access_FullMember() {
        Contact fullMember = [SELECT Id FROM Contact WHERE Membership_Id__c = 'FM123' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = CVMAMemberAuthenticationController.getMemberEpic8Access(fullMember.Id);
        Test.stopTest();

        System.assertEquals('Premium', result.get('accessLevel'), 'Full member should have premium access');
        System.assertEquals('Full Member', result.get('membershipLevel'), 'Should return correct level');

        Map<String, List<String>> features = (Map<String, List<String>>) result.get('epic8Features');
        List<String> analyticsFeatures = features.get('analytics');
        System.assert(analyticsFeatures.contains('Predictive Insights'), 'Full members should have predictive insights');
    }

    @IsTest
    static void testGetMemberEpic8Access_SupportMember() {
        Contact supportMember = [SELECT Id FROM Contact WHERE Membership_Id__c = 'SUP789' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = CVMAMemberAuthenticationController.getMemberEpic8Access(supportMember.Id);
        Test.stopTest();

        System.assertEquals('Basic', result.get('accessLevel'), 'Support member should have basic access');
        System.assertEquals('Support Member', result.get('membershipLevel'), 'Should return correct level');
    }

    @IsTest
    static void testGetMemberAnalyticsDashboard_Success() {
        Contact fullMember = [SELECT Id FROM Contact WHERE Membership_Id__c = 'FM123' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = CVMAMemberAuthenticationController.getMemberAnalyticsDashboard(fullMember.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.get('memberProfile'), 'Should have member profile');
        System.assertNotEquals(null, result.get('accessibleAnalytics'), 'Should have analytics access info');
        System.assertNotEquals(null, result.get('participationHistory'), 'Should have participation history');
        System.assertNotEquals(null, result.get('chapterEngagement'), 'Should have engagement metrics');
        System.assertNotEquals(null, result.get('availableServices'), 'Should have available services');

        Map<String, Object> analyticsAccess = (Map<String, Object>) result.get('accessibleAnalytics');
        System.assertEquals(true, analyticsAccess.get('personalDashboard'), 'Should have personal dashboard access');
        System.assertEquals(true, analyticsAccess.get('predictiveAnalytics'), 'Full members should have predictive analytics');
    }

    @IsTest
    static void testGetMemberCrossChapterAccess_FullMember() {
        Contact fullMember = [SELECT Id FROM Contact WHERE Membership_Id__c = 'FM123' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = CVMAMemberAuthenticationController.getMemberCrossChapterAccess(fullMember.Id);
        Test.stopTest();

        System.assertEquals(true, result.get('canViewOtherChapters'), 'Full members should view other chapters');
        System.assertEquals(true, result.get('canParticipateInEvents'), 'Full members should participate in events');
        System.assertEquals('Leadership', result.get('collaborationLevel'), 'Full members should have leadership collaboration');

        List<Map<String, Object>> events = (List<Map<String, Object>>) result.get('availableEvents');
        System.assert(events.size() > 0, 'Should have available events');
    }

    @IsTest
    static void testGetMemberCrossChapterAccess_SupportMember() {
        Contact supportMember = [SELECT Id FROM Contact WHERE Membership_Id__c = 'SUP789' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = CVMAMemberAuthenticationController.getMemberCrossChapterAccess(supportMember.Id);
        Test.stopTest();

        System.assertEquals(false, result.get('canViewOtherChapters'), 'Support members should not view other chapters');
        System.assertEquals(true, result.get('canParticipateInEvents'), 'Support members should participate in cross-chapter events');
        System.assertEquals('Observer', result.get('collaborationLevel'), 'Support members should have observer collaboration');
    }

    @IsTest
    static void testMemberAccessLevels() {
        List<Contact> members = [
            SELECT Id, Level__c, Membership_Id__c
            FROM Contact
            WHERE Level__c != null
            ORDER BY Membership_Id__c
        ];

        Test.startTest();
        Map<String, String> expectedAccess = new Map<String, String>{
            'Full Member' => 'Premium',
            'Support Member' => 'Basic',
            'Auxiliary Member' => 'Basic'
        };

        for (Contact member : members) {
            Map<String, Object> access = CVMAMemberAuthenticationController.getMemberEpic8Access(member.Id);
            String expectedLevel = expectedAccess.get(member.Level__c);
            System.assertEquals(expectedLevel, access.get('accessLevel'),
                'Access level should match membership level: ' + member.Level__c);
        }
        Test.stopTest();
    }

    @IsTest
    static void testSecurityEnforcement() {
        Contact fullMember = [SELECT Id FROM Contact WHERE Membership_Id__c = 'FM123' LIMIT 1];

        Test.startTest();
        // All methods use WITH SECURITY_ENFORCED, so they should respect field-level security
        Map<String, Object> authResult = CVMAMemberAuthenticationController.authenticateMember(
            'FM123', 'FullMember', null
        );
        Map<String, Object> accessResult = CVMAMemberAuthenticationController.getMemberEpic8Access(fullMember.Id);
        Map<String, Object> dashboardResult = CVMAMemberAuthenticationController.getMemberAnalyticsDashboard(fullMember.Id);
        Map<String, Object> crossChapterResult = CVMAMemberAuthenticationController.getMemberCrossChapterAccess(fullMember.Id);
        Test.stopTest();

        System.assertNotEquals(null, authResult, 'Authentication should work with proper security');
        System.assertNotEquals(null, accessResult, 'Access check should work with proper security');
        System.assertNotEquals(null, dashboardResult, 'Dashboard should work with proper security');
        System.assertNotEquals(null, crossChapterResult, 'Cross-chapter access should work with proper security');
    }

    @IsTest
    static void testMembershipTenureCalculation() {
        Contact fullMember = [SELECT Id FROM Contact WHERE Membership_Id__c = 'FM123' LIMIT 1];

        Test.startTest();
        Map<String, Object> dashboard = CVMAMemberAuthenticationController.getMemberAnalyticsDashboard(fullMember.Id);
        Test.stopTest();

        Map<String, Object> memberProfile = (Map<String, Object>) dashboard.get('memberProfile');
        Integer tenureMonths = (Integer) memberProfile.get('tenureMonths');
        System.assert(tenureMonths >= 12, 'Should calculate correct membership tenure');
    }

    @IsTest
    static void testFeatureAccessByLevel() {
        Map<String, String> membershipToId = new Map<String, String>{
            'FM123' => 'Full Member',
            'AUX456' => 'Auxiliary Member',
            'SUP789' => 'Support Member'
        };

        Test.startTest();
        for (String membershipId : membershipToId.keySet()) {
            String lastName = membershipToId.get(membershipId).replace(' ', '') + 'Member';
            if (membershipId == 'AUX456') {
                lastName = 'AuxiliaryMember';
            }
            Map<String, Object> authResult = CVMAMemberAuthenticationController.authenticateMember(
                membershipId, lastName, null
            );

            Map<String, List<String>> features = (Map<String, List<String>>) authResult.get('epic8Features');
            String level = membershipToId.get(membershipId);

            // Verify appropriate features are available
            if (level == 'Full Member') {
                System.assert(features.get('analytics').contains('Predictive Insights'),
                    'Full members should have predictive insights');
                System.assert(features.get('external_integration').contains('Leadership Tools'),
                    'Full members should have leadership tools');
            } else {
                System.assert(!features.get('analytics').contains('Predictive Insights'),
                    'Non-full members should not have predictive insights');
            }
        }
        Test.stopTest();
    }
}
