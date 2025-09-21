@IsTest
private class CVMAVeteranResourcesControllerTest {

    @IsTest
    static void testGetVeteranResources() {
        Test.startTest();
        String result = CVMAVeteranResourcesController.getVeteranResources('all');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Veteran resources should return result');
    }
}