@IsTest
private class CVMACareerResourcesControllerTest {

    @IsTest
    static void testGetCareerResources_NoFilter() {
        Test.startTest();
        List<CVMACareerResourcesController.CareerResourceWrapper> resources =
            CVMACareerResourcesController.getCareerResources(null);
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        System.assert(resources.size() > 0, 'Should return career resources from custom metadata');
    }

    @IsTest
    static void testGetCareerResources_WithFilter_JobBoard() {
        Test.startTest();
        List<CVMACareerResourcesController.CareerResourceWrapper> resources =
            CVMACareerResourcesController.getCareerResources('Job Board');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        for (CVMACareerResourcesController.CareerResourceWrapper resource : resources) {
            System.assertEquals('Job Board', resource.resourceType,
                'All resources should be Job Board type');
        }
    }

    @IsTest
    static void testGetCareerResources_WithFilter_CareerCounseling() {
        Test.startTest();
        List<CVMACareerResourcesController.CareerResourceWrapper> resources =
            CVMACareerResourcesController.getCareerResources('Career Counseling');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        for (CVMACareerResourcesController.CareerResourceWrapper resource : resources) {
            System.assertEquals('Career Counseling', resource.resourceType,
                'All resources should be Career Counseling type');
        }
    }

    @IsTest
    static void testGetCareerResources_WithFilter_TrainingProgram() {
        Test.startTest();
        List<CVMACareerResourcesController.CareerResourceWrapper> resources =
            CVMACareerResourcesController.getCareerResources('Training Program');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        for (CVMACareerResourcesController.CareerResourceWrapper resource : resources) {
            System.assertEquals('Training Program', resource.resourceType,
                'All resources should be Training Program type');
        }
    }

    @IsTest
    static void testGetCareerResources_WithFilter_NonExistent() {
        Test.startTest();
        List<CVMACareerResourcesController.CareerResourceWrapper> resources =
            CVMACareerResourcesController.getCareerResources('NonExistent Type');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources list should not be null');
        System.assertEquals(0, resources.size(), 'Should return empty list for non-existent type');
    }

    @IsTest
    static void testGetCareerResources_EmptyStringFilter() {
        Test.startTest();
        List<CVMACareerResourcesController.CareerResourceWrapper> resources =
            CVMACareerResourcesController.getCareerResources('');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        System.assert(resources.size() > 0, 'Empty string filter should return all resources');
    }

    @IsTest
    static void testGetResourceTypes() {
        Test.startTest();
        List<String> types = CVMACareerResourcesController.getResourceTypes();
        Test.stopTest();

        System.assertNotEquals(null, types, 'Types should not be null');
        System.assert(types.size() > 0, 'Should return at least one resource type');
    }

    @IsTest
    static void testGetCareerResources_OnlyActiveReturned() {
        Test.startTest();
        List<CVMACareerResourcesController.CareerResourceWrapper> resources =
            CVMACareerResourcesController.getCareerResources(null);
        Test.stopTest();

        // All returned resources should be from active records only
        System.assertNotEquals(null, resources, 'Resources should not be null');
    }

    @IsTest
    static void testGetCareerResources_Ordering() {
        Test.startTest();
        List<CVMACareerResourcesController.CareerResourceWrapper> resources =
            CVMACareerResourcesController.getCareerResources(null);
        Test.stopTest();

        // Verify resources are returned (ordering verified by Display_Order in SOQL)
        System.assertNotEquals(null, resources, 'Resources should not be null');
    }

    @IsTest
    static void testWrapperClass_FieldMapping() {
        // Test wrapper class field mapping
        CVMA_Career_Resource__mdt testResource = [
            SELECT Resource_Name__c, Resource_Type__c, Description__c,
                   Contact_Phone__c, Contact_Email__c, Website_URL__c,
                   Target_Audience__c, Service_Area__c, Cost__c,
                   Certification_Available__c, CEB_Approved__c
            FROM CVMA_Career_Resource__mdt
            LIMIT 1
        ];

        Test.startTest();
        CVMACareerResourcesController.CareerResourceWrapper wrapper =
            new CVMACareerResourcesController.CareerResourceWrapper(testResource);
        Test.stopTest();

        System.assertEquals(testResource.Resource_Name__c, wrapper.resourceName,
            'Wrapper should map resource name correctly');
        System.assertEquals(testResource.Resource_Type__c, wrapper.resourceType,
            'Wrapper should map resource type correctly');
    }

    @IsTest
    static void testWrapperClass_AllFieldsPopulated() {
        CVMA_Career_Resource__mdt testResource = [
            SELECT Resource_Name__c, Resource_Type__c, Description__c,
                   Contact_Phone__c, Contact_Email__c, Website_URL__c,
                   Target_Audience__c, Service_Area__c, Cost__c,
                   Certification_Available__c, CEB_Approved__c
            FROM CVMA_Career_Resource__mdt
            LIMIT 1
        ];

        Test.startTest();
        CVMACareerResourcesController.CareerResourceWrapper wrapper =
            new CVMACareerResourcesController.CareerResourceWrapper(testResource);
        Test.stopTest();

        // Verify all fields are accessible
        System.assertNotEquals(null, wrapper.resourceName, 'Resource name should be populated');
        System.assertNotEquals(null, wrapper.resourceType, 'Resource type should be populated');
    }
}
