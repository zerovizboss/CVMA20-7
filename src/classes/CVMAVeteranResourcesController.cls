public with sharing class CVMAVeteranResourcesController {

    @AuraEnabled(cacheable=true)
    public static List<VeteranOrganization> getVeteranOrganizations() {
        try {
            List<VeteranOrganization> organizations = new List<VeteranOrganization>();

            // Service Dog Organizations
            organizations.add(new VeteranOrganization(
                'k9-warriors',
                'K9s For Warriors',
                'Service Dogs',
                'Provides highly-trained Service Dogs to military veterans suffering from PTSD, traumatic brain injury and/or military sexual trauma.',
                'Combat veterans with PTSD, TBI, or MST, Honorable discharge, Able to care for service dog',
                'National',
                '904-686-1956',
                'https://k9sforwarriors.org',
                true,
                true,
                'https://k9sforwarriors.org/apply/',
                10
            ));

            organizations.add(new VeteranOrganization(
                'canine-companions',
                'Canine Companions for Independence',
                'Service Dogs',
                'Provides expertly trained service dogs to adults, children and veterans with disabilities.',
                'Physical disability requiring mobility assistance, Veteran status, Able to handle service dog',
                'National',
                '800-572-2275',
                'https://canine.org',
                false,
                true,
                'https://canine.org/apply/',
                8
            ));

            // Housing & Financial Organizations
            organizations.add(new VeteranOrganization(
                'homes-for-heroes',
                'Homes for Heroes',
                'Housing',
                'Real estate rewards program for heroes including military, veterans, firefighters, EMS, law enforcement, healthcare workers and teachers.',
                'Active military, Veteran, First responder, Healthcare worker, Teacher',
                'National',
                '800-294-7304',
                'https://homesforheroes.com',
                true,
                false,
                'https://homesforheroes.com/register/',
                9
            ));

            organizations.add(new VeteranOrganization(
                'tunnel-to-towers',
                'Tunnel to Towers Foundation',
                'Housing',
                'Provides mortgage-free homes to catastrophically injured veterans and fallen first responder families.',
                'Catastrophically injured post-9/11 veteran, Gold Star family, Fallen first responder family',
                'National',
                '718-987-1931',
                'https://tunnel2towers.org',
                true,
                true,
                'https://tunnel2towers.org/programs/smart-home-program/',
                9
            ));

            // Wounded Warrior Support
            organizations.add(new VeteranOrganization(
                'wounded-warrior-project',
                'Wounded Warrior Project',
                'Wounded Warrior',
                'Honors and empowers wounded warriors through various programs and services.',
                'Post-9/11 injured veteran, Physical or mental injury from military service',
                'National',
                '904-296-7350',
                'https://woundedwarriorproject.org',
                true,
                true,
                'https://woundedwarriorproject.org/programs/',
                10
            ));

            organizations.add(new VeteranOrganization(
                'iava',
                'Iraq and Afghanistan Veterans of America',
                'Wounded Warrior',
                'Leading advocacy organization for Iraq and Afghanistan veterans and their families.',
                'Iraq or Afghanistan veteran, Honorable discharge',
                'National',
                '212-982-9699',
                'https://iava.org',
                true,
                false,
                'https://iava.org/membership/',
                7
            ));

            // Employment Organizations
            organizations.add(new VeteranOrganization(
                'corporate-gray',
                'Corporate Gray',
                'Employment',
                'Connects military veterans with career opportunities in corporate America.',
                'Military veteran, Seeking civilian career transition',
                'National',
                '843-225-7223',
                'https://corporategray.com',
                false,
                false,
                'https://corporategray.com/join/',
                6
            ));

            organizations.add(new VeteranOrganization(
                'recruit-military',
                'RecruitMilitary',
                'Employment',
                'Career opportunities for veterans through virtual career fairs and job matching.',
                'Military veteran, Active job seeker',
                'National',
                '513-791-4300',
                'https://recruitmilitary.com',
                false,
                false,
                'https://recruitmilitary.com/veterans',
                7
            ));

            // Emergency Response Organizations
            organizations.add(new VeteranOrganization(
                'team-rubicon',
                'Team Rubicon',
                'Emergency',
                'Veteran-led disaster response organization providing emergency services and continued purpose for veterans.',
                'Military veteran, Pass background check, Complete training',
                'National',
                '310-640-8787',
                'https://teamrubicon.org',
                true,
                false,
                'https://teamrubicon.org/join/',
                8
            ));

            organizations.add(new VeteranOrganization(
                'team-red-white-blue',
                'Team Red White & Blue',
                'Emergency',
                'Veterans organization focused on enriching veterans\' lives through physical and social activity.',
                'Military veteran, Commitment to physical fitness',
                'National',
                '512-524-2703',
                'https://teamrwb.org',
                false,
                false,
                'https://teamrwb.org/membership/',
                6
            ));

            // Mental Health Organizations
            organizations.add(new VeteranOrganization(
                'give-an-hour',
                'Give an Hour',
                'Mental Health',
                'Provides free mental health services to military members, veterans, and their families.',
                'Military member, Veteran, Military family member',
                'National',
                '202-416-7896',
                'https://giveanhour.org',
                false,
                true,
                'https://giveanhour.org/get-help/',
                8
            ));

            return organizations;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAVeteranResourcesController.getVeteranOrganizations');
            throw new AuraHandledException('Failed to retrieve veteran organizations: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<EligibilityResult> checkEligibility(String organizationId, Map<String, Object> veteranData) {
        try {
            List<EligibilityResult> results = new List<EligibilityResult>();

            // Get organization details
            VeteranOrganization org = getOrganizationById(organizationId);
            if (org == null) {
                throw new AuraHandledException('Organization not found');
            }

            // Extract veteran data
            Boolean serviceConnectedDisability = (Boolean) veteranData.get('serviceConnectedDisability');
            Integer disabilityRating = (Integer) veteranData.get('disabilityRating');
            String branch = (String) veteranData.get('branch');
            Boolean combatVeteran = (Boolean) veteranData.get('combatVeteran');
            String state = (String) veteranData.get('state');

            // Check eligibility based on organization requirements
            if (organizationId == 'k9-warriors') {
                results.add(checkK9WarriorsEligibility(serviceConnectedDisability, combatVeteran, disabilityRating));
            } else if (organizationId == 'wounded-warrior-project') {
                results.add(checkWWPEligibility(serviceConnectedDisability, combatVeteran));
            } else if (organizationId == 'homes-for-heroes') {
                results.add(checkHomesForHeroesEligibility(true)); // All veterans eligible
            } else if (organizationId == 'tunnel-to-towers') {
                results.add(checkTunnelToTowersEligibility(serviceConnectedDisability, disabilityRating));
            } else {
                // Default eligibility check for other organizations
                results.add(new EligibilityResult(
                    'General Program',
                    org.organizationName + ' General Program',
                    'Likely Eligible',
                    'success',
                    'Based on your veteran status, you appear to meet basic eligibility requirements. Contact the organization for detailed requirements.'
                ));
            }

            return results;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAVeteranResourcesController.checkEligibility');
            throw new AuraHandledException('Failed to check eligibility: ' + e.getMessage());
        }
    }

    private static VeteranOrganization getOrganizationById(String organizationId) {
        List<VeteranOrganization> orgs = getVeteranOrganizations();
        for (VeteranOrganization org : orgs) {
            if (org.id == organizationId) {
                return org;
            }
        }
        return null;
    }

    private static EligibilityResult checkK9WarriorsEligibility(Boolean serviceConnected, Boolean combatVet, Integer rating) {
        if (combatVet && serviceConnected && rating != null && rating >= 30) {
            return new EligibilityResult(
                'Service Dog Program',
                'K9s For Warriors Service Dog Program',
                'Highly Eligible',
                'success',
                'Combat veteran with PTSD/TBI rating of 30% or higher - excellent candidate for service dog program.'
            );
        } else if (serviceConnected) {
            return new EligibilityResult(
                'Service Dog Program',
                'K9s For Warriors Service Dog Program',
                'Potentially Eligible',
                'warning',
                'Service-connected disability present. Combat veteran status and higher disability rating preferred.'
            );
        } else {
            return new EligibilityResult(
                'Service Dog Program',
                'K9s For Warriors Service Dog Program',
                'Additional Review Needed',
                'error',
                'Requires service-connected PTSD, TBI, or MST diagnosis. Contact organization for detailed requirements.'
            );
        }
    }

    private static EligibilityResult checkWWPEligibility(Boolean serviceConnected, Boolean combatVet) {
        if (serviceConnected || combatVet) {
            return new EligibilityResult(
                'WWP Programs',
                'Wounded Warrior Project Programs',
                'Eligible',
                'success',
                'Post-9/11 injured veteran - eligible for full range of WWP programs and services.'
            );
        } else {
            return new EligibilityResult(
                'WWP Programs',
                'Wounded Warrior Project Programs',
                'Review Required',
                'warning',
                'WWP serves post-9/11 wounded veterans. Contact organization to verify service dates and eligibility.'
            );
        }
    }

    private static EligibilityResult checkHomesForHeroesEligibility(Boolean isVeteran) {
        if (isVeteran) {
            return new EligibilityResult(
                'Real Estate Rewards',
                'Homes for Heroes Rewards Program',
                'Eligible',
                'success',
                'All veterans eligible for real estate rewards program. Savings available on home purchases and sales.'
            );
        } else {
            return new EligibilityResult(
                'Real Estate Rewards',
                'Homes for Heroes Rewards Program',
                'Not Eligible',
                'error',
                'Program requires veteran, active military, or first responder status.'
            );
        }
    }

    private static EligibilityResult checkTunnelToTowersEligibility(Boolean serviceConnected, Integer rating) {
        if (serviceConnected && rating != null && rating >= 95) {
            return new EligibilityResult(
                'Smart Home Program',
                'Tunnel to Towers Smart Home Program',
                'Highly Eligible',
                'success',
                'Catastrophically injured veteran with 95%+ rating - excellent candidate for mortgage-free smart home.'
            );
        } else if (serviceConnected && rating != null && rating >= 70) {
            return new EligibilityResult(
                'Smart Home Program',
                'Tunnel to Towers Smart Home Program',
                'Potentially Eligible',
                'warning',
                'Significant service-connected disability. Program prioritizes catastrophically injured veterans.'
            );
        } else {
            return new EligibilityResult(
                'Smart Home Program',
                'Tunnel to Towers Smart Home Program',
                'Unlikely Eligible',
                'error',
                'Program serves catastrophically injured post-9/11 veterans. Consider other housing assistance programs.'
            );
        }
    }

    // Inner Classes
    public class VeteranOrganization {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String organizationName { get; set; }
        @AuraEnabled public String serviceCategory { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String eligibilityCriteria { get; set; }
        @AuraEnabled public String statesCovered { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String website { get; set; }
        @AuraEnabled public Boolean combatVeteranFocus { get; set; }
        @AuraEnabled public Boolean disabilityFocus { get; set; }
        @AuraEnabled public String applicationUrl { get; set; }
        @AuraEnabled public Integer priorityScore { get; set; }
        @AuraEnabled public String phoneLink { get; set; }

        public VeteranOrganization(String id, String name, String category, String desc, String eligibility,
                                 String states, String phone, String website, Boolean combatFocus,
                                 Boolean disabilityFocus, String appUrl, Integer priority) {
            this.id = id;
            this.organizationName = name;
            this.serviceCategory = category;
            this.description = desc;
            this.eligibilityCriteria = eligibility;
            this.statesCovered = states;
            this.phone = phone;
            this.website = website;
            this.combatVeteranFocus = combatFocus;
            this.disabilityFocus = disabilityFocus;
            this.applicationUrl = appUrl;
            this.priorityScore = priority;
            this.phoneLink = 'tel:' + phone;
        }
    }

    public class EligibilityResult {
        @AuraEnabled public String program { get; set; }
        @AuraEnabled public String programName { get; set; }
        @AuraEnabled public String eligibilityStatus { get; set; }
        @AuraEnabled public String statusVariant { get; set; }
        @AuraEnabled public String requirements { get; set; }

        public EligibilityResult(String program, String programName, String status, String variant, String requirements) {
            this.program = program;
            this.programName = programName;
            this.eligibilityStatus = status;
            this.statusVariant = variant;
            this.requirements = requirements;
        }
    }
}
