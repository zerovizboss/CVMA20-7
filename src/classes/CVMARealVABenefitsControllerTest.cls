@IsTest
private class CVMARealVABenefitsControllerTest {

    @TestSetup
    static void setupTestData() {
        CVMATestDataFactory.TestDataBundle testBundle = CVMATestDataFactory.setupBasicTestData();

        Contact veteranContact = CVMATestDataFactory.createContact()
            .withFirstName('John')
            .withLastName('Veteran')
            .withEmail('john.veteran@cvma-test.org')
            .withAccount(testBundle.testAccount.Id)
            .create();

        veteranContact.VA_File_Number__c = 'C123456789';
        veteranContact.SSN__c = '123-45-6789';
        update veteranContact;
    }

    @IsTest
    static void testGetVABenefitsSuccess() {
        Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new CVMARealVAAPIMock(200, 'success'));

        Test.startTest();
        CVMARealVABenefitsController.VABenefitsResponse response =
            CVMARealVABenefitsController.getVABenefits(testContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertNotEquals(null, response.apiStatus, 'API status should be included');
    }

    @IsTest
    static void testGetVABenefitsWithInvalidContact() {
        Test.startTest();
        try {
            CVMARealVABenefitsController.getVABenefits('invalid-id');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Failed to retrieve VA benefits'));
        }
        Test.stopTest();
    }

    // Mock class for HTTP callouts
    private class CVMARealVAAPIMock implements HttpCalloutMock {
        private Integer statusCode;
        private String status;

        public CVMARealVAAPIMock(Integer statusCode, String status) {
            this.statusCode = statusCode;
            this.status = status;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);

            if (statusCode == 200) {
                Map<String, Object> mockData = new Map<String, Object>{
                    'data' => new Map<String, Object>{
                        'attributes' => new Map<String, Object>{
                            'combined_disability_rating' => 70,
                            'monthly_compensation_amount' => 1500,
                            'payment_status' => 'Current'
                        }
                    }
                };
                response.setBody(JSON.serialize(mockData));
            }

            return response;
        }
    }
}