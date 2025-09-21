/**
 * Helper class for Mock Government Integration
 * Provides simplified government services simulation for Epic #8 Phase 3
 * Addresses deployment dependencies and field validation issues
 *
 * @author CVMA Development Team
 * @since Epic #8 Phase 3
 */
public with sharing class CVMAMockGovIntegrationHelper {

    /**
     * Simplified VA Benefits Response for demonstration
     */
    public class VABenefitsBasic {
        @AuraEnabled public Boolean isEligible { get; set; }
        @AuraEnabled public Integer disabilityRating { get; set; }
        @AuraEnabled public Decimal monthlyCompensation { get; set; }
        @AuraEnabled public String healthcareStatus { get; set; }
        @AuraEnabled public String lastVerified { get; set; }
        @AuraEnabled public List<String> activeAlerts { get; set; }

        public VABenefitsBasic() {
            this.isEligible = false;
            this.activeAlerts = new List<String>();
            this.lastVerified = System.now().format('yyyy-MM-dd HH:mm:ss');
        }
    }

    /**
     * Simplified DOD Records Response for demonstration
     */
    public class DODRecordsBasic {
        @AuraEnabled public Boolean isVerified { get; set; }
        @AuraEnabled public String serviceBranch { get; set; }
        @AuraEnabled public String highestRank { get; set; }
        @AuraEnabled public String dischargeType { get; set; }
        @AuraEnabled public Boolean isCombatVeteran { get; set; }
        @AuraEnabled public String lastVerified { get; set; }
        @AuraEnabled public List<String> verificationAlerts { get; set; }

        public DODRecordsBasic() {
            this.isVerified = false;
            this.verificationAlerts = new List<String>();
            this.lastVerified = System.now().format('yyyy-MM-dd HH:mm:ss');
        }
    }

    /**
     * Get simplified VA benefits for a contact
     * @param contactId The Contact ID of the veteran member
     * @return VABenefitsBasic Simplified benefits information
     */
    @AuraEnabled(cacheable=true)
    public static VABenefitsBasic getVABenefitsSimple(String contactId) {
        try {
            if (String.isBlank(contactId)) {
                throw new AuraHandledException('Contact ID is required for VA benefits lookup');
            }

            // Get contact information using standard fields only
            Contact veteranContact = getContactInfo(contactId);

            // Generate mock VA benefits
            VABenefitsBasic benefits = new VABenefitsBasic();

            // Simple eligibility check - any contact is eligible for demo
            benefits.isEligible = true;
            benefits.disabilityRating = generateDisabilityRating();
            benefits.monthlyCompensation = calculateCompensation(benefits.disabilityRating);
            benefits.healthcareStatus = 'Enrolled';

            if (benefits.disabilityRating > 0) {
                benefits.activeAlerts.add('Disability compensation: $' + benefits.monthlyCompensation.setScale(0));
            }
            benefits.activeAlerts.add('Healthcare enrollment active');

            return benefits;

        } catch (Exception e) {
            System.debug('Error in getVABenefitsSimple: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve VA benefits: ' + e.getMessage());
        }
    }

    /**
     * Get simplified DOD records for a contact
     * @param contactId The Contact ID of the service member
     * @return DODRecordsBasic Simplified service verification
     */
    @AuraEnabled(cacheable=true)
    public static DODRecordsBasic getDODRecordsSimple(String contactId) {
        try {
            if (String.isBlank(contactId)) {
                throw new AuraHandledException('Contact ID is required for DOD records lookup');
            }

            // Get contact information using standard fields only
            Contact serviceContact = getContactInfo(contactId);

            // Generate mock DOD records
            DODRecordsBasic records = new DODRecordsBasic();

            // Simple verification - any contact is verified for demo
            records.isVerified = true;
            records.serviceBranch = generateServiceBranch();
            records.highestRank = generateRank(records.serviceBranch);
            records.dischargeType = 'Honorable';
            records.isCombatVeteran = Math.random() < 0.6; // 60% chance

            records.verificationAlerts.add('Service verified: ' + records.serviceBranch);
            if (records.isCombatVeteran) {
                records.verificationAlerts.add('Combat veteran status confirmed');
            }

            return records;

        } catch (Exception e) {
            System.debug('Error in getDODRecordsSimple: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve DOD records: ' + e.getMessage());
        }
    }

    /**
     * Get benefit optimization recommendations
     * @param contactId The Contact ID of the veteran member
     * @return List<String> Benefit recommendations
     */
    @AuraEnabled
    public static List<String> getBenefitRecommendations(String contactId) {
        try {
            List<String> recommendations = new List<String>();

            // Generate sample recommendations
            recommendations.add('Consider using remaining education benefits');
            recommendations.add('VA home loan benefit available');
            recommendations.add('Healthcare enrollment optimization available');

            return recommendations;

        } catch (Exception e) {
            System.debug('Error in getBenefitRecommendations: ' + e.getMessage());
            return new List<String>{'Unable to generate recommendations at this time'};
        }
    }

    /**
     * Get contact information securely using only standard fields
     * @param contactId The Contact ID to retrieve
     * @return Contact The contact record
     */
    private static Contact getContactInfo(String contactId) {
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Email, Level__c
            FROM Contact
            WHERE Id = :contactId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (contacts.isEmpty()) {
            throw new AuraHandledException('Contact not found with ID: ' + contactId);
        }

        return contacts[0];
    }

    /**
     * Generate realistic disability rating
     */
    private static Integer generateDisabilityRating() {
        Double random = Math.random();
        if (random < 0.1) return 100;
        if (random < 0.2) return (Integer)(Math.random() * 30) + 70;
        if (random < 0.4) return (Integer)(Math.random() * 40) + 30;
        if (random < 0.7) return (Integer)(Math.random() * 30);
        return 0;
    }

    /**
     * Calculate monthly compensation based on disability rating
     */
    private static Decimal calculateCompensation(Integer rating) {
        if (rating >= 100) return 3737.85;
        if (rating >= 90) return 2898.63;
        if (rating >= 80) return 2527.33;
        if (rating >= 70) return 2161.34;
        if (rating >= 60) return 1686.81;
        if (rating >= 50) return 1204.73;
        if (rating >= 40) return 868.74;
        if (rating >= 30) return 524.31;
        if (rating >= 20) return 269.30;
        if (rating >= 10) return 171.23;
        return 0;
    }

    /**
     * Generate random service branch
     */
    private static String generateServiceBranch() {
        List<String> branches = new List<String>{'Army', 'Navy', 'Air Force', 'Marines', 'Coast Guard'};
        return branches[(Integer)(Math.random() * branches.size())];
    }

    /**
     * Generate realistic rank for service branch
     */
    private static String generateRank(String serviceBranch) {
        Map<String, List<String>> branchRanks = new Map<String, List<String>>{
            'Army' => new List<String>{'PVT', 'PFC', 'SPC', 'CPL', 'SGT', 'SSG', 'SFC'},
            'Navy' => new List<String>{'SR', 'SA', 'SN', 'PO3', 'PO2', 'PO1', 'CPO'},
            'Air Force' => new List<String>{'AB', 'AMN', 'A1C', 'SRA', 'SSG', 'TSG'},
            'Marines' => new List<String>{'PVT', 'PFC', 'LCPL', 'CPL', 'SGT', 'SSGT'},
            'Coast Guard' => new List<String>{'SR', 'SA', 'SN', 'PO3', 'PO2', 'PO1'}
        };

        List<String> ranks = branchRanks.get(serviceBranch);
        if (ranks == null) return 'E-5';

        return ranks[(Integer)(Math.random() * ranks.size())];
    }
}
