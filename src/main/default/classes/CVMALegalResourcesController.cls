/**
 * @description Controller for CVMA Legal Resources LWC component
 * Provides legal clinic and advocacy service information for veterans
 * User Story #75: Legal & Advocacy Services Resources
 *
 * @author CVMA Chapter 20-7
 * @date 2025-10-20
 */
public without sharing class CVMALegalResourcesController {

    /**
     * @description Retrieves legal resources from custom metadata, optionally filtered by type
     * @param resourceType Filter by resource type (Legal Clinic, Advocacy, etc.) - null returns all
     * @return List of legal resource wrapper objects
     */
    @AuraEnabled(cacheable=true)
    public static List<LegalResourceWrapper> getLegalResources(String resourceType) {
        try {
            List<CVMA_Legal_Resource__mdt> resources;

            if (String.isNotBlank(resourceType)) {
                resources = [
                    SELECT Resource_Name__c, Resource_Type__c, Description__c,
                           Contact_Phone__c, Contact_Email__c, Website_URL__c,
                           Address__c, Service_Area__c, Eligibility_Requirements__c,
                           Appointment_Required__c, Pro_Bono_Available__c, Display_Order__c
                    FROM CVMA_Legal_Resource__mdt
                    WHERE Is_Active__c = true
                    AND Resource_Type__c = :resourceType
                    ORDER BY Display_Order__c ASC NULLS LAST, Resource_Name__c ASC
                ];
            } else {
                resources = [
                    SELECT Resource_Name__c, Resource_Type__c, Description__c,
                           Contact_Phone__c, Contact_Email__c, Website_URL__c,
                           Address__c, Service_Area__c, Eligibility_Requirements__c,
                           Appointment_Required__c, Pro_Bono_Available__c, Display_Order__c
                    FROM CVMA_Legal_Resource__mdt
                    WHERE Is_Active__c = true
                    ORDER BY Display_Order__c ASC NULLS LAST, Resource_Name__c ASC
                ];
            }

            List<LegalResourceWrapper> wrappedResources = new List<LegalResourceWrapper>();
            for (CVMA_Legal_Resource__mdt resource : resources) {
                wrappedResources.add(new LegalResourceWrapper(resource));
            }

            return wrappedResources;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving legal resources: ' + e.getMessage());
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

            for (CVMA_Legal_Resource__mdt resource : [
                SELECT Resource_Type__c
                FROM CVMA_Legal_Resource__mdt
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
     * @description Wrapper class for legal resource data transfer
     */
    public class LegalResourceWrapper {
        @AuraEnabled public String resourceName;
        @AuraEnabled public String resourceType;
        @AuraEnabled public String description;
        @AuraEnabled public String contactPhone;
        @AuraEnabled public String contactEmail;
        @AuraEnabled public String websiteUrl;
        @AuraEnabled public String address;
        @AuraEnabled public String serviceArea;
        @AuraEnabled public String eligibilityRequirements;
        @AuraEnabled public Boolean appointmentRequired;
        @AuraEnabled public Boolean proBonoAvailable;

        /**
         * @description Constructor to create wrapper from custom metadata record
         * @param resource Custom metadata record
         */
        public LegalResourceWrapper(CVMA_Legal_Resource__mdt resource) {
            this.resourceName = resource.Resource_Name__c;
            this.resourceType = resource.Resource_Type__c;
            this.description = resource.Description__c;
            this.contactPhone = resource.Contact_Phone__c;
            this.contactEmail = resource.Contact_Email__c;
            this.websiteUrl = resource.Website_URL__c;
            this.address = resource.Address__c;
            this.serviceArea = resource.Service_Area__c;
            this.eligibilityRequirements = resource.Eligibility_Requirements__c;
            this.appointmentRequired = resource.Appointment_Required__c;
            this.proBonoAvailable = resource.Pro_Bono_Available__c;
        }
    }
}
