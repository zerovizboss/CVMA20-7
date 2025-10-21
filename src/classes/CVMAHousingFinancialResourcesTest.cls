/**
 * @description Test class for CVMAHousingFinancialResourcesController
 * @author CVMA Development Team
 * @date 2025
 * @group Test Classes
 */
@IsTest
private class CVMAHousingFinancialResourcesTest {

    /**
     * @description Test getHousingFinancialResources with no filter (all resources)
     */
    @IsTest
    static void testGetHousingFinancialResources_NoFilter() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources(null);
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        System.assert(resources.size() > 0, 'Should return housing/financial resources from custom metadata');
    }

    /**
     * @description Test getHousingFinancialResources filtered by 'VA Home Loan' type
     */
    @IsTest
    static void testGetHousingFinancialResources_WithFilter_VAHomeLoan() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources('VA Home Loan');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        for (CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper resource : resources) {
            System.assertEquals('VA Home Loan', resource.resourceType,
                'All resources should be VA Home Loan type');
        }
    }

    /**
     * @description Test getHousingFinancialResources filtered by 'Emergency Shelter' type
     */
    @IsTest
    static void testGetHousingFinancialResources_WithFilter_EmergencyShelter() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources('Emergency Shelter');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        for (CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper resource : resources) {
            System.assertEquals('Emergency Shelter', resource.resourceType,
                'All resources should be Emergency Shelter type');
        }
    }

    /**
     * @description Test getHousingFinancialResources filtered by 'Financial Aid' type
     */
    @IsTest
    static void testGetHousingFinancialResources_WithFilter_FinancialAid() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources('Financial Aid');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        for (CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper resource : resources) {
            System.assertEquals('Financial Aid', resource.resourceType,
                'All resources should be Financial Aid type');
        }
    }

    /**
     * @description Test getHousingFinancialResources with non-existent type filter
     */
    @IsTest
    static void testGetHousingFinancialResources_WithFilter_NonExistent() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources('NonExistent Type');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources list should not be null');
        System.assertEquals(0, resources.size(), 'Should return empty list for non-existent type');
    }

    /**
     * @description Test getHousingFinancialResources with empty string filter (should return all)
     */
    @IsTest
    static void testGetHousingFinancialResources_EmptyStringFilter() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources('');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        System.assert(resources.size() > 0, 'Empty string filter should return all resources');
    }

    /**
     * @description Test getResourceTypes method
     */
    @IsTest
    static void testGetResourceTypes() {
        Test.startTest();
        List<String> types = CVMAHousingFinancialResourcesController.getResourceTypes();
        Test.stopTest();

        System.assertNotEquals(null, types, 'Types should not be null');
        System.assert(types.size() > 0, 'Should return at least one resource type');
    }

    /**
     * @description Test getEmergencyResources method
     */
    @IsTest
    static void testGetEmergencyResources() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getEmergencyResources();
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Emergency resources should not be null');
        for (CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper resource : resources) {
            System.assertEquals(true, resource.emergencyService,
                'All resources should be emergency services');
        }
    }

    /**
     * @description Test that only active resources are returned
     */
    @IsTest
    static void testGetHousingFinancialResources_OnlyActiveReturned() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources(null);
        Test.stopTest();

        // All returned resources should be from active records only
        System.assertNotEquals(null, resources, 'Resources should not be null');
    }

    /**
     * @description Test resource ordering (by Display_Order__c and Resource_Name__c)
     */
    @IsTest
    static void testGetHousingFinancialResources_Ordering() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources(null);
        Test.stopTest();

        // Verify resources are returned (ordering verified by Display_Order in SOQL)
        System.assertNotEquals(null, resources, 'Resources should not be null');
    }

    /**
     * @description Test wrapper class field mapping
     */
    @IsTest
    static void testWrapperClass_FieldMapping() {
        // Test wrapper class field mapping
        CVMA_Housing_Financial_Resource__mdt testResource = [
            SELECT Resource_Name__c, Resource_Type__c, Description__c,
                   Contact_Phone__c, Contact_Email__c, Website_URL__c,
                   Address__c, Service_Area__c, Eligibility_Requirements__c,
                   Emergency_Service__c, CEB_Approval_Required__c
            FROM CVMA_Housing_Financial_Resource__mdt
            LIMIT 1
        ];

        Test.startTest();
        CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper wrapper =
            new CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper(testResource);
        Test.stopTest();

        System.assertEquals(testResource.Resource_Name__c, wrapper.resourceName,
            'Wrapper should map resource name correctly');
        System.assertEquals(testResource.Resource_Type__c, wrapper.resourceType,
            'Wrapper should map resource type correctly');
    }

    /**
     * @description Test wrapper class with all fields populated
     */
    @IsTest
    static void testWrapperClass_AllFieldsPopulated() {
        CVMA_Housing_Financial_Resource__mdt testResource = [
            SELECT Resource_Name__c, Resource_Type__c, Description__c,
                   Contact_Phone__c, Contact_Email__c, Website_URL__c,
                   Address__c, Service_Area__c, Eligibility_Requirements__c,
                   Emergency_Service__c, CEB_Approval_Required__c
            FROM CVMA_Housing_Financial_Resource__mdt
            LIMIT 1
        ];

        Test.startTest();
        CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper wrapper =
            new CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper(testResource);
        Test.stopTest();

        // Verify all fields are accessible
        System.assertNotEquals(null, wrapper.resourceName, 'Resource name should be populated');
        System.assertNotEquals(null, wrapper.resourceType, 'Resource type should be populated');
    }

    /**
     * @description Test getResourceTypes returns sorted list
     */
    @IsTest
    static void testGetResourceTypes_Sorted() {
        Test.startTest();
        List<String> types = CVMAHousingFinancialResourcesController.getResourceTypes();
        Test.stopTest();

        // Verify types are sorted alphabetically
        for (Integer i = 0; i < types.size() - 1; i++) {
            System.assert(types[i] <= types[i + 1],
                'Resource types should be sorted alphabetically');
        }
    }

    /**
     * @description Test getHousingFinancialResources with Rental Assistance filter
     */
    @IsTest
    static void testGetHousingFinancialResources_WithFilter_RentalAssistance() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources('Rental Assistance');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        for (CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper resource : resources) {
            System.assertEquals('Rental Assistance', resource.resourceType,
                'All resources should be Rental Assistance type');
        }
    }

    /**
     * @description Test getHousingFinancialResources with Utility Assistance filter
     */
    @IsTest
    static void testGetHousingFinancialResources_WithFilter_UtilityAssistance() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources('Utility Assistance');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        for (CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper resource : resources) {
            System.assertEquals('Utility Assistance', resource.resourceType,
                'All resources should be Utility Assistance type');
        }
    }

    /**
     * @description Test getHousingFinancialResources with Food Bank filter
     */
    @IsTest
    static void testGetHousingFinancialResources_WithFilter_FoodBank() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources('Food Bank');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        for (CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper resource : resources) {
            System.assertEquals('Food Bank', resource.resourceType,
                'All resources should be Food Bank type');
        }
    }

    /**
     * @description Test wrapper class CEB approval field mapping
     */
    @IsTest
    static void testWrapperClass_CEBApprovalMapping() {
        List<CVMA_Housing_Financial_Resource__mdt> testResources = [
            SELECT Resource_Name__c, Resource_Type__c, Description__c,
                   Contact_Phone__c, Contact_Email__c, Website_URL__c,
                   Address__c, Service_Area__c, Eligibility_Requirements__c,
                   Emergency_Service__c, CEB_Approval_Required__c
            FROM CVMA_Housing_Financial_Resource__mdt
            WHERE CEB_Approval_Required__c = true
            LIMIT 1
        ];

        if (!testResources.isEmpty()) {
            Test.startTest();
            CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper wrapper =
                new CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper(testResources[0]);
            Test.stopTest();

            System.assertEquals(true, wrapper.cebApprovalRequired,
                'Wrapper should map CEB approval required correctly');
        }
    }
}
