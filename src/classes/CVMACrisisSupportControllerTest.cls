/**
 * CVMACrisisSupportControllerTest
 * Epic #8 Phase 3 - Crisis Support Services Testing
 *
 * @author CVMA Chapter 20-7 Development Team
 * @version 1.0 - Epic #8 Phase 3 Implementation
 * @since September 2025
 */
@IsTest
public class CVMACrisisSupportControllerTest {

    @TestSetup
    static void setupTestData() {
        Contact testMember = CVMATestDataFactory.createContact()
            .withLevel('Full Member')
            .withMembershipId('FM12345')
            .create();
    }

    @IsTest
    static void testGetCrisisSupport() {
        Contact testMember = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        Map<String, Object> result = CVMACrisisSupportController.getCrisisSupport(testMember.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Crisis support should return data');
        System.assert(result.containsKey('crisisResources'), 'Should contain crisis resources');
        System.assert(result.containsKey('emergencyContacts'), 'Should contain emergency contacts');
        System.assert(result.containsKey('mentalHealthSupport'), 'Should contain mental health support');
    }

    @IsTest
    static void testGetEmergencyResources() {
        Test.startTest();
        Map<String, Object> result = CVMACrisisSupportController.getEmergencyResources();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Emergency resources should return data');
        System.assert(result.containsKey('nationalHotlines'), 'Should contain national hotlines');
        System.assert(result.containsKey('localResources'), 'Should contain local resources');
        System.assert(result.containsKey('onlineSupport'), 'Should contain online support');
    }

    @IsTest
    static void testGetMentalHealthSupport() {
        Contact testMember = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        Map<String, Object> result = CVMACrisisSupportController.getMentalHealthSupport(testMember.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Mental health support should return data');
        System.assert(result.containsKey('counselingResources'), 'Should contain counseling resources');
        System.assert(result.containsKey('therapyProviders'), 'Should contain therapy providers');
        System.assert(result.containsKey('supportGroups'), 'Should contain support groups');
    }

    @IsTest
    static void testGetCrisisInterventionProtocols() {
        Test.startTest();
        Map<String, Object> result = CVMACrisisSupportController.getCrisisInterventionProtocols();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Crisis intervention protocols should return data');
        System.assert(result.containsKey('immediateResponse'), 'Should contain immediate response protocols');
        System.assert(result.containsKey('followUpProcedures'), 'Should contain follow-up procedures');
        System.assert(result.containsKey('professionalReferrals'), 'Should contain professional referrals');
    }
}
