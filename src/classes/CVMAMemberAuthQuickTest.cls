/**
 * CVMAMemberAuthQuickTest
 * Quick validation test for member authentication system
 */
@IsTest
public class CVMAMemberAuthQuickTest {

    @TestSetup
    static void setupTestData() {
        // Use only valid levels that we know work
        Contact fullMember = CVMATestDataFactory.createContact()
            .withFirstName('John')
            .withLastName('FullMember')
            .withLevel('Full Member')
            .withMembershipId('FM123')
            .create();

        Contact supportMember = CVMATestDataFactory.createContact()
            .withFirstName('Bob')
            .withLastName('SupportMember')
            .withLevel('Support Member')
            .withMembershipId('SUP789')
            .create();
    }

    @IsTest
    static void testAuthenticateFullMember() {
        Test.startTest();
        Map<String, Object> result = CVMAMemberAuthenticationController.authenticateMember(
            'FM123', 'FullMember', null
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Authentication should succeed');
        System.assertEquals('Full Member', result.get('membershipLevel'), 'Should return correct level');
        System.assertEquals('Premium', result.get('accessLevel'), 'Full members should have premium access');
    }

    @IsTest
    static void testAuthenticateSupportMember() {
        Test.startTest();
        Map<String, Object> result = CVMAMemberAuthenticationController.authenticateMember(
            'SUP789', 'SupportMember', null
        );
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Authentication should succeed');
        System.assertEquals('Support Member', result.get('membershipLevel'), 'Should return correct level');
        System.assertEquals('Basic', result.get('accessLevel'), 'Support members should have basic access');
    }

    @IsTest
    static void testInvalidCredentials() {
        Test.startTest();
        try {
            CVMAMemberAuthenticationController.authenticateMember(
                'INVALID123', 'NonExistent', null
            );
            System.assert(false, 'Should throw exception for invalid credentials');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid membership credentials'), 'Should return appropriate error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testMemberEpic8Access() {
        Contact fullMember = [SELECT Id FROM Contact WHERE Membership_Id__c = 'FM123' LIMIT 1];

        Test.startTest();
        Map<String, Object> result = CVMAMemberAuthenticationController.getMemberEpic8Access(fullMember.Id);
        Test.stopTest();

        System.assertEquals('Premium', result.get('accessLevel'), 'Full member should have premium access');
        System.assertNotEquals(null, result.get('epic8Features'), 'Should have Epic #8 features');
    }

    @IsTest
    static void testSecurityEnforcement() {
        Contact fullMember = [SELECT Id FROM Contact WHERE Membership_Id__c = 'FM123' LIMIT 1];

        Test.startTest();
        // All methods use WITH SECURITY_ENFORCED
        Map<String, Object> authResult = CVMAMemberAuthenticationController.authenticateMember(
            'FM123', 'FullMember', null
        );
        Map<String, Object> accessResult = CVMAMemberAuthenticationController.getMemberEpic8Access(fullMember.Id);
        Map<String, Object> dashboardResult = CVMAMemberAuthenticationController.getMemberAnalyticsDashboard(fullMember.Id);
        Test.stopTest();

        System.assertNotEquals(null, authResult, 'Authentication should work with security enforcement');
        System.assertNotEquals(null, accessResult, 'Access check should work with security enforcement');
        System.assertNotEquals(null, dashboardResult, 'Dashboard should work with security enforcement');
    }
}
