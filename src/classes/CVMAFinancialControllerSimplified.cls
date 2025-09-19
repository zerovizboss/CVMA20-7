/**
 * @description Simplified CVMA Financial Controller for NPSP Integration
 * @author Claude AI - CVMA Development Team
 * @date 2025-09-10
 *
 * Handles CVMA-specific financial logic while leveraging NPSP standard reports
 * Reduced from 935 lines to ~200 lines (78% reduction)
 */
public with sharing class CVMAFinancialControllerSimplified {

    // CVMA-specific dues constants
    private static final Decimal ANNUAL_DUES_FULL = 120.00;
    private static final Decimal ANNUAL_DUES_ASSOCIATE = 60.00;
    private static final Decimal ANNUAL_DUES_PROSPECT = 30.00;

    /**
     * @description Calculate dues amount based on CVMA membership level
     * @param memberLevel Contact.Level__c value
     * @return Decimal dues amount
     */
    @AuraEnabled(cacheable=true)
    public static Decimal calculateMemberDues(String memberLevel) {
        try {
            CVMAErrorHandler.validateInputs(new List<String>{memberLevel}, 'Member level is required');

            switch on CVMAErrorHandler.sanitizeInput(memberLevel) {
                when 'Full Member' {
                    return ANNUAL_DUES_FULL;
                }
                when 'Associate' {
                    return ANNUAL_DUES_ASSOCIATE;
                }
                when 'Prospect' {
                    return ANNUAL_DUES_PROSPECT;
                }
                when else {
                    throw new CVMAErrorHandler.ValidationException('Invalid membership level: ' + memberLevel);
                }
            }
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAFinancialControllerSimplified.calculateMemberDues');
            throw e;
        }
    }

    /**
     * @description Process CVMA-specific payment validation and business rules
     * @param paymentData Payment information wrapper
     * @return PaymentResponse result
     */
    @AuraEnabled
    public static PaymentResponse processCVMAPayment(PaymentWrapper paymentData) {
        try {
            // Validate treasurer permissions
            validateTreasurerPermissions();

            // CVMA-specific payment validation
            validateCVMAPaymentRules(paymentData);

            // Use NPSP standard payment processing
            npe01__OppPayment__c payment = new npe01__OppPayment__c(
                npe01__Opportunity__c = paymentData.opportunityId,
                npe01__Payment_Amount__c = paymentData.amount,
                npe01__Payment_Date__c = paymentData.paymentDate,
                npe01__Payment_Method__c = paymentData.paymentMethod,
                npe01__Paid__c = true
            );

            insert payment;

            return new PaymentResponse(true, 'Payment processed successfully', payment.Id);

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAFinancialControllerSimplified.processCVMAPayment');
            return new PaymentResponse(false, e.getMessage(), null);
        }
    }

    /**
     * @description Get CVMA-specific financial configuration
     * @return CVMAFinancialConfig configuration settings
     */
    @AuraEnabled(cacheable=true)
    public static CVMAFinancialConfig getCVMAFinancialConfig() {
        return new CVMAFinancialConfig(
            ANNUAL_DUES_FULL,
            ANNUAL_DUES_ASSOCIATE,
            ANNUAL_DUES_PROSPECT,
            'Use NPSP Reports for detailed analytics'
        );
    }

    // Private helper methods
    private static void validateTreasurerPermissions() {
        // Check if user has CVMA Treasurer permission set
        List<PermissionSetAssignment> assignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :UserInfo.getUserId()
            AND PermissionSet.Name = 'CVMA_Treasurer'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (assignments.isEmpty()) {
            throw new CVMAErrorHandler.SecurityException('Insufficient permissions for financial operations');
        }
    }

    private static void validateCVMAPaymentRules(PaymentWrapper payment) {
        // CVMA-specific validation logic
        if (payment.amount <= 0) {
            throw new CVMAErrorHandler.ValidationException('Payment amount must be positive');
        }

        if (payment.amount > 500) {
            // Large payment validation
            throw new CVMAErrorHandler.ValidationException('Payments over $500 require additional approval');
        }
    }

    // Data transfer objects (minimal set)
    public class PaymentWrapper {
        @AuraEnabled public String opportunityId;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Date paymentDate;
        @AuraEnabled public String paymentMethod;
    }

    public class PaymentResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String paymentId;

        public PaymentResponse(Boolean success, String message, String paymentId) {
            this.success = success;
            this.message = message;
            this.paymentId = paymentId;
        }
    }

    public class CVMAFinancialConfig {
        @AuraEnabled public Decimal fullMemberDues;
        @AuraEnabled public Decimal associateDues;
        @AuraEnabled public Decimal prospectDues;
        @AuraEnabled public String reportingNote;

        public CVMAFinancialConfig(Decimal full, Decimal associate, Decimal prospect, String note) {
            this.fullMemberDues = full;
            this.associateDues = associate;
            this.prospectDues = prospect;
            this.reportingNote = note;
        }
    }
}
