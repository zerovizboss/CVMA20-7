public without sharing class CVMACareerResourcesController {

    @AuraEnabled(cacheable=true)
    public static List<CareerResourceWrapper> getCareerResources(String resourceType) {
        try {
            List<CVMA_Career_Resource__mdt> resources;

            if (String.isNotBlank(resourceType)) {
                resources = [
                    SELECT Resource_Name__c, Resource_Type__c, Description__c,
                           Contact_Phone__c, Contact_Email__c, Website_URL__c,
                           Target_Audience__c, Service_Area__c, Cost__c,
                           Certification_Available__c, CEB_Approved__c, Display_Order__c
                    FROM CVMA_Career_Resource__mdt
                    WHERE Is_Active__c = true
                    AND Resource_Type__c = :resourceType
                    WITH SECURITY_ENFORCED
                    ORDER BY Display_Order__c ASC NULLS LAST, Resource_Name__c ASC
                ];
            } else {
                resources = [
                    SELECT Resource_Name__c, Resource_Type__c, Description__c,
                           Contact_Phone__c, Contact_Email__c, Website_URL__c,
                           Target_Audience__c, Service_Area__c, Cost__c,
                           Certification_Available__c, CEB_Approved__c, Display_Order__c
                    FROM CVMA_Career_Resource__mdt
                    WHERE Is_Active__c = true
                    WITH SECURITY_ENFORCED
                    ORDER BY Display_Order__c ASC NULLS LAST, Resource_Name__c ASC
                ];
            }

            List<CareerResourceWrapper> wrappedResources = new List<CareerResourceWrapper>();
            for (CVMA_Career_Resource__mdt resource : resources) {
                wrappedResources.add(new CareerResourceWrapper(resource));
            }

            return wrappedResources;

        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving career resources: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getResourceTypes() {
        try {
            Set<String> typeSet = new Set<String>();

            for (CVMA_Career_Resource__mdt resource : [
                SELECT Resource_Type__c
                FROM CVMA_Career_Resource__mdt
                WHERE Is_Active__c = true
                WITH SECURITY_ENFORCED
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

    // Wrapper class for career resource data
    public class CareerResourceWrapper {
        @AuraEnabled public String resourceName;
        @AuraEnabled public String resourceType;
        @AuraEnabled public String description;
        @AuraEnabled public String contactPhone;
        @AuraEnabled public String contactEmail;
        @AuraEnabled public String websiteUrl;
        @AuraEnabled public String targetAudience;
        @AuraEnabled public String serviceArea;
        @AuraEnabled public String cost;
        @AuraEnabled public Boolean certificationAvailable;
        @AuraEnabled public Boolean cebApproved;

        public CareerResourceWrapper(CVMA_Career_Resource__mdt resource) {
            this.resourceName = resource.Resource_Name__c;
            this.resourceType = resource.Resource_Type__c;
            this.description = resource.Description__c;
            this.contactPhone = resource.Contact_Phone__c;
            this.contactEmail = resource.Contact_Email__c;
            this.websiteUrl = resource.Website_URL__c;
            this.targetAudience = resource.Target_Audience__c;
            this.serviceArea = resource.Service_Area__c;
            this.cost = resource.Cost__c;
            this.certificationAvailable = resource.Certification_Available__c;
            this.cebApproved = resource.CEB_Approved__c;
        }
    }
}
