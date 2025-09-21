@IsTest
private class CVMARealVAFacilitiesControllerTest {

    @IsTest
    static void testGetNearbyFacilities() {
        Test.startTest();
        String result = CVMARealVAFacilitiesController.getNearbyFacilities(
            '38.9072', '-77.0369', '10'
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Facilities search should return result');
    }
}