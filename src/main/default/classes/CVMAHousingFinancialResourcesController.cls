/**
 * @description Controller for CVMA Housing & Financial Resources LWC component
 * Provides housing assistance and financial aid information for veterans in crisis
 * User Story #74: Housing & Financial Assistance Resources
 *
 * @author CVMA Chapter 20-7
 * @date 2025-10-31
 */
public with sharing class CVMAHousingFinancialResourcesController {

    /**
     * @description Retrieves housing/financial resources from custom metadata, optionally filtered by type
     * @param resourceType Filter by resource type (Housing, Financial Aid, etc.) - null returns all
     * @return List of housing/financial resource wrapper objects
     */
    @AuraEnabled(cacheable=true)
    public static List<HousingFinancialResourceWrapper> getHousingFinancialResources(String resourceType) {
        try {
            List<CVMA_Housing_Financial_Resource__mdt> resources;

            if (String.isNotBlank(resourceType)) {
                resources = [
                    SELECT Resource_Name__c, Resource_Type__c, Description__c,
                           Contact_Phone__c, Contact_Email__c, Website_URL__c,
                           Address__c, Service_Area__c, Eligibility_Requirements__c,
                           Emergency_Service__c, CEB_Approval_Required__c, Display_Order__c
                    FROM CVMA_Housing_Financial_Resource__mdt
                    WHERE Is_Active__c = true
                    AND Resource_Type__c = :resourceType
                    ORDER BY Display_Order__c ASC NULLS LAST, Resource_Name__c ASC
                ];
            } else {
                resources = [
                    SELECT Resource_Name__c, Resource_Type__c, Description__c,
                           Contact_Phone__c, Contact_Email__c, Website_URL__c,
                           Address__c, Service_Area__c, Eligibility_Requirements__c,
                           Emergency_Service__c, CEB_Approval_Required__c, Display_Order__c
                    FROM CVMA_Housing_Financial_Resource__mdt
                    WHERE Is_Active__c = true
                    ORDER BY Display_Order__c ASC NULLS LAST, Resource_Name__c ASC
                ];
            }

            List<HousingFinancialResourceWrapper> wrappedResources = new List<HousingFinancialResourceWrapper>();
            for (CVMA_Housing_Financial_Resource__mdt resource : resources) {
                wrappedResources.add(new HousingFinancialResourceWrapper(resource));
            }

            return wrappedResources;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving housing/financial resources: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves only emergency resources (Emergency_Service__c = true)
     * @return List of emergency resource wrapper objects
     */
    @AuraEnabled(cacheable=true)
    public static List<HousingFinancialResourceWrapper> getEmergencyResources() {
        try {
            List<CVMA_Housing_Financial_Resource__mdt> resources = [
                SELECT Resource_Name__c, Resource_Type__c, Description__c,
                       Contact_Phone__c, Contact_Email__c, Website_URL__c,
                       Address__c, Service_Area__c, Eligibility_Requirements__c,
                       Emergency_Service__c, CEB_Approval_Required__c, Display_Order__c
                FROM CVMA_Housing_Financial_Resource__mdt
                WHERE Is_Active__c = true
                AND Emergency_Service__c = true
                ORDER BY Display_Order__c ASC NULLS LAST, Resource_Name__c ASC
            ];

            List<HousingFinancialResourceWrapper> wrappedResources = new List<HousingFinancialResourceWrapper>();
            for (CVMA_Housing_Financial_Resource__mdt resource : resources) {
                wrappedResources.add(new HousingFinancialResourceWrapper(resource));
            }

            return wrappedResources;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving emergency resources: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves distinct resource types for filtering
     * @return List of resource type strings
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getResourceTypes() {
        try {
            Set<String> typeSet = new Set<String>();

            for (CVMA_Housing_Financial_Resource__mdt resource : [
                SELECT Resource_Type__c
                FROM CVMA_Housing_Financial_Resource__mdt
                WHERE Is_Active__c = true
            ]) {
                if (String.isNotBlank(resource.Resource_Type__c)) {
                    typeSet.add(resource.Resource_Type__c);
                }
            }

            List<String> types = new List<String>(typeSet);
            types.sort();
            return types;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving resource types: ' + e.getMessage());
        }
    }

    /**
     * @description Wrapper class for housing/financial resource data transfer
     */
    public class HousingFinancialResourceWrapper {
        @AuraEnabled public String resourceName;
        @AuraEnabled public String resourceType;
        @AuraEnabled public String description;
        @AuraEnabled public String contactPhone;
        @AuraEnabled public String contactEmail;
        @AuraEnabled public String websiteUrl;
        @AuraEnabled public String address;
        @AuraEnabled public String serviceArea;
        @AuraEnabled public String eligibilityRequirements;
        @AuraEnabled public Boolean emergencyService;
        @AuraEnabled public Boolean cebApprovalRequired;

        /**
         * @description Constructor to create wrapper from custom metadata record
         * @param resource Custom metadata record
         */
        public HousingFinancialResourceWrapper(CVMA_Housing_Financial_Resource__mdt resource) {
            this.resourceName = resource.Resource_Name__c;
            this.resourceType = resource.Resource_Type__c;
            this.description = resource.Description__c;
            this.contactPhone = resource.Contact_Phone__c;
            this.contactEmail = resource.Contact_Email__c;
            this.websiteUrl = resource.Website_URL__c;
            this.address = resource.Address__c;
            this.serviceArea = resource.Service_Area__c;
            this.eligibilityRequirements = resource.Eligibility_Requirements__c;
            this.emergencyService = resource.Emergency_Service__c;
            this.cebApprovalRequired = resource.CEB_Approval_Required__c;
        }
    }
}
