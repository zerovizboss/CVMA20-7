@IsTest
private class CVMAAddressValidationControllerTest {

    @IsTest
    static void testValidateAddress() {
        Test.startTest();
        String result = CVMAAddressValidationController.validateAddress(
            '1600 Pennsylvania Avenue NW', 'Washington', 'DC', '20500'
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Address validation should return result');
    }
}