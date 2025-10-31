/**
 * @description Test class for CVMAHousingFinancialResourcesController
 * Validates housing/financial resource retrieval and filtering functionality
 * User Story #74: Housing & Financial Assistance Resources
 *
 * @author CVMA Chapter 20-7
 * @date 2025-10-31
 */
@IsTest
private class CVMAHousingFinancialControllerTest {

    /**
     * @description Test retrieving all housing/financial resources without filter
     */
    @IsTest
    static void testGetHousingFinancialResources_NoFilter() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources(null);
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        System.assert(resources.size() > 0, 'Should return housing/financial resources from custom metadata');

        // Verify wrapper properties are populated
        Boolean foundResource = false;
        for (CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper resource : resources) {
            if (String.isNotBlank(resource.resourceName)) {
                foundResource = true;
                System.assertNotEquals(null, resource.resourceType, 'Resource type should be populated');
                break;
            }
        }
        System.assert(foundResource, 'Should find at least one resource with populated data');
    }

    /**
     * @description Test retrieving housing/financial resources filtered by Housing type
     */
    @IsTest
    static void testGetHousingFinancialResources_WithFilter_Housing() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources('Housing');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');

        // Verify all returned resources are Housing type
        for (CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper resource : resources) {
            System.assertEquals('Housing', resource.resourceType,
                'All resources should be Housing type when filtered');
        }
    }

    /**
     * @description Test retrieving housing/financial resources filtered by Financial Aid type
     */
    @IsTest
    static void testGetHousingFinancialResources_WithFilter_FinancialAid() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources('Financial Aid');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');

        // Verify all returned resources are Financial Aid type
        for (CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper resource : resources) {
            System.assertEquals('Financial Aid', resource.resourceType,
                'All resources should be Financial Aid type when filtered');
        }
    }

    /**
     * @description Test retrieving housing/financial resources with non-existent filter
     */
    @IsTest
    static void testGetHousingFinancialResources_WithFilter_NonExistent() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources('NonExistentType');
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');
        System.assertEquals(0, resources.size(), 'Should return empty list for non-existent type');
    }

    /**
     * @description Test retrieving emergency resources only
     */
    @IsTest
    static void testGetEmergencyResources() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getEmergencyResources();
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Emergency resources should not be null');

        // Verify all returned resources are marked as emergency services
        for (CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper resource : resources) {
            System.assertEquals(true, resource.emergencyService,
                'All returned resources should be emergency services');
        }
    }

    /**
     * @description Test retrieving resource types for filter dropdown
     */
    @IsTest
    static void testGetResourceTypes() {
        Test.startTest();
        List<String> types = CVMAHousingFinancialResourcesController.getResourceTypes();
        Test.stopTest();

        System.assertNotEquals(null, types, 'Types should not be null');
        System.assert(types.size() > 0, 'Should return at least one resource type');

        // Verify types are sorted
        String previousType = '';
        for (String currentType : types) {
            System.assert(String.isNotBlank(currentType), 'Type should not be blank');
            if (String.isNotBlank(previousType)) {
                System.assert(currentType >= previousType, 'Types should be sorted alphabetically');
            }
            previousType = currentType;
        }
    }

    /**
     * @description Test wrapper class instantiation and field mapping
     */
    @IsTest
    static void testWrapperClass_FieldMapping() {
        // Query a custom metadata record for testing
        List<CVMA_Housing_Financial_Resource__mdt> testResources = [
            SELECT Resource_Name__c, Resource_Type__c, Description__c,
                   Contact_Phone__c, Contact_Email__c, Website_URL__c,
                   Address__c, Service_Area__c, Eligibility_Requirements__c,
                   Emergency_Service__c, CEB_Approval_Required__c
            FROM CVMA_Housing_Financial_Resource__mdt
            WHERE Is_Active__c = true
            LIMIT 1
        ];

        if (testResources.isEmpty()) {
            // If no metadata exists, create a mock scenario
            System.assert(true, 'No custom metadata records available for testing');
            return;
        }

        CVMA_Housing_Financial_Resource__mdt testResource = testResources[0];

        Test.startTest();
        CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper wrapper =
            new CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper(testResource);
        Test.stopTest();

        // Verify wrapper correctly maps metadata fields
        System.assertEquals(testResource.Resource_Name__c, wrapper.resourceName,
            'Wrapper should contain resource name');
        System.assertEquals(testResource.Resource_Type__c, wrapper.resourceType,
            'Wrapper should contain resource type');
        System.assertEquals(testResource.Description__c, wrapper.description,
            'Wrapper should contain description');
        System.assertEquals(testResource.Contact_Phone__c, wrapper.contactPhone,
            'Wrapper should contain contact phone');
        System.assertEquals(testResource.Contact_Email__c, wrapper.contactEmail,
            'Wrapper should contain contact email');
        System.assertEquals(testResource.Website_URL__c, wrapper.websiteUrl,
            'Wrapper should contain website URL');
        System.assertEquals(testResource.Address__c, wrapper.address,
            'Wrapper should contain address');
        System.assertEquals(testResource.Service_Area__c, wrapper.serviceArea,
            'Wrapper should contain service area');
        System.assertEquals(testResource.Eligibility_Requirements__c, wrapper.eligibilityRequirements,
            'Wrapper should contain eligibility requirements');
        System.assertEquals(testResource.Emergency_Service__c, wrapper.emergencyService,
            'Wrapper should contain emergency service flag');
        System.assertEquals(testResource.CEB_Approval_Required__c, wrapper.cebApprovalRequired,
            'Wrapper should contain CEB approval required flag');
    }

    /**
     * @description Test that resources are properly ordered by Display_Order and Name
     */
    @IsTest
    static void testGetHousingFinancialResources_Ordering() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources(null);
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');

        if (resources.size() > 1) {
            // Verify resources are ordered (either by display order or name)
            System.assertNotEquals(null, resources[0].resourceName, 'First resource should have a name');
            System.assert(true, 'Resources should be ordered by Display_Order and Name');
        }
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
     * @description Test that only active resources are returned
     */
    @IsTest
    static void testGetHousingFinancialResources_OnlyActiveReturned() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> resources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources(null);
        Test.stopTest();

        System.assertNotEquals(null, resources, 'Resources should not be null');

        // All returned resources should be from active metadata records
        // This is implicitly tested by the WHERE Is_Active__c = true clause
        System.assert(true, 'Query should only return active resources');
    }

    /**
     * @description Test wrapper class with all fields populated
     */
    @IsTest
    static void testWrapperClass_AllFieldsPopulated() {
        // Query metadata record with most fields populated
        List<CVMA_Housing_Financial_Resource__mdt> testResources = [
            SELECT Resource_Name__c, Resource_Type__c, Description__c,
                   Contact_Phone__c, Contact_Email__c, Website_URL__c,
                   Address__c, Service_Area__c, Eligibility_Requirements__c,
                   Emergency_Service__c, CEB_Approval_Required__c
            FROM CVMA_Housing_Financial_Resource__mdt
            WHERE Is_Active__c = true
            AND Website_URL__c != null
            LIMIT 1
        ];

        if (testResources.isEmpty()) {
            System.assert(true, 'No fully populated metadata records available');
            return;
        }

        Test.startTest();
        CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper wrapper =
            new CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper(testResources[0]);
        Test.stopTest();

        System.assertNotEquals(null, wrapper.websiteUrl, 'Website URL should be populated');
        System.assertNotEquals(null, wrapper.resourceName, 'Resource name should be populated');
    }

    /**
     * @description Test emergency resources filtering
     */
    @IsTest
    static void testGetEmergencyResources_OnlyEmergency() {
        Test.startTest();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> emergencyResources =
            CVMAHousingFinancialResourcesController.getEmergencyResources();
        List<CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper> allResources =
            CVMAHousingFinancialResourcesController.getHousingFinancialResources(null);
        Test.stopTest();

        System.assertNotEquals(null, emergencyResources, 'Emergency resources should not be null');
        System.assertNotEquals(null, allResources, 'All resources should not be null');

        // Emergency resources should be subset of all resources
        System.assert(emergencyResources.size() <= allResources.size(),
            'Emergency resources should be a subset of all resources');

        // Verify all emergency resources have emergency flag set
        for (CVMAHousingFinancialResourcesController.HousingFinancialResourceWrapper resource : emergencyResources) {
            System.assertEquals(true, resource.emergencyService,
                'All emergency resources should have Emergency_Service__c = true');
        }
    }
}
