/**
 * @description Controller for CVMA Financial Management System
 * @author Claude AI - CVMA Development Team
 * @date 2025-01-09
 *
 * Handles financial operations including:
 * - Dues tracking and payment processing
 * - Financial transaction management
 * - Treasury reporting and analytics
 * - Payment status monitoring
 * - Budget and expense tracking
 */
public with sharing class CVMAFinancialController {

    // Constants
    private static final Decimal ANNUAL_DUES_FULL = 120.00;
    private static final Decimal ANNUAL_DUES_ASSOCIATE = 60.00;
    private static final Decimal ANNUAL_DUES_PROSPECT = 30.00;
    private static final String PAYMENT_STATUS_PENDING = 'Pending';
    private static final String PAYMENT_STATUS_PAID = 'Paid';
    private static final String PAYMENT_STATUS_OVERDUE = 'Overdue';
    private static final String PAYMENT_STATUS_CANCELLED = 'Cancelled';
    private static final String TRANSACTION_TYPE_DUES = 'Dues Payment';
    private static final String TRANSACTION_TYPE_EXPENSE = 'Expense';
    private static final String TRANSACTION_TYPE_DONATION = 'Donation';
    private static final String TRANSACTION_TYPE_FUNDRAISER = 'Fundraiser';

    // Custom exceptions
    public class FinancialException extends Exception {}
    public class PaymentException extends Exception {}
    public class InsufficientPermissionsException extends Exception {}

    // Data transfer objects
    public class PaymentRecord {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String memberId { get; set; }
        @AuraEnabled public String memberName { get; set; }
        @AuraEnabled public String memberLevel { get; set; }
        @AuraEnabled public Decimal amountDue { get; set; }
        @AuraEnabled public Decimal amountPaid { get; set; }
        @AuraEnabled public Decimal balance { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Date dueDate { get; set; }
        @AuraEnabled public Date lastPaymentDate { get; set; }
        @AuraEnabled public Integer daysPastDue { get; set; }
        @AuraEnabled public String paymentMethod { get; set; }
        @AuraEnabled public String notes { get; set; }
    }

    public class FinancialTransaction {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public Date transactionDate { get; set; }
        @AuraEnabled public String transactionType { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public Decimal amount { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public String memberId { get; set; }
        @AuraEnabled public String memberName { get; set; }
        @AuraEnabled public String paymentMethod { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String referenceNumber { get; set; }
    }

    public class FinancialSummary {
        @AuraEnabled public Decimal totalRevenue { get; set; }
        @AuraEnabled public Decimal totalExpenses { get; set; }
        @AuraEnabled public Decimal netIncome { get; set; }
        @AuraEnabled public Decimal outstandingDues { get; set; }
        @AuraEnabled public Decimal treasuryBalance { get; set; }
        @AuraEnabled public Integer totalMembers { get; set; }
        @AuraEnabled public Integer paidMembers { get; set; }
        @AuraEnabled public Integer overdueMembers { get; set; }
        @AuraEnabled public Map<String, Decimal> revenueByCategory { get; set; }
        @AuraEnabled public Map<String, Decimal> expensesByCategory { get; set; }
        @AuraEnabled public String reportingPeriod { get; set; }
    }

    public class PaymentResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String transactionId { get; set; }
        @AuraEnabled public Decimal amountProcessed { get; set; }
        @AuraEnabled public String paymentStatus { get; set; }
    }

    /**
     * @description Get payment records for dues tracking using NPSP Opportunities and Payments
     * @param year Payment year to filter (null for current year)
     * @param status Payment status filter (null for all)
     * @param pageSize Number of records per page
     * @param pageNumber Page number (0-based)
     * @return List of payment records with pagination info
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPaymentRecords(Integer year, String status, Integer pageSize, Integer pageNumber) {
        try {
            validateTreasurerPermissions();
            
            // Set defaults
            if (year == null) year = Date.today().year();
            if (pageSize == null || pageSize <= 0) pageSize = 50;
            if (pageNumber == null || pageNumber < 0) pageNumber = 0;
            
            Integer offset = pageNumber * pageSize;
            Date yearStart = Date.newInstance(year, 1, 1);
            Date yearEnd = Date.newInstance(year, 12, 31);
            
            // Query opportunities (dues records) with related payments using NPSP
            String query = 'SELECT Id, Name, Amount, StageName, CloseDate, AccountId, Account.Name, ' +
                          'npsp__Primary_Contact__c, npsp__Primary_Contact__r.Name, npsp__Primary_Contact__r.Level__c, ' +
                          '(SELECT Id, npe01__Payment_Amount__c, npe01__Payment_Date__c, ' +
                          'npe01__Payment_Method__c, npe01__Paid__c FROM npe01__OppPayment__r ' +
                          'ORDER BY npe01__Payment_Date__c DESC) ' +
                          'FROM Opportunity ' +
                          'WHERE RecordType.DeveloperName = \'Donation\' ' +
                          'AND Campaign.Name = \'Annual Dues ' + year + '\' ' +
                          'AND CloseDate >= :yearStart AND CloseDate <= :yearEnd ';
                          
            if (String.isNotBlank(status)) {
                if (status == PAYMENT_STATUS_PAID) {
                    query += 'AND StageName = \'Closed Won\' ';
                } else if (status == PAYMENT_STATUS_PENDING) {
                    query += 'AND StageName IN (\'Pledged\', \'Prospecting\') ';
                } else if (status == PAYMENT_STATUS_OVERDUE) {
                    query += 'AND StageName IN (\'Pledged\', \'Prospecting\') AND CloseDate < TODAY ';
                }
            }
            
            query += 'WITH SECURITY_ENFORCED ORDER BY Contact__r.Name LIMIT :pageSize OFFSET :offset';
            
            List<Opportunity> opportunities = Database.query(query);
            
            // Convert to PaymentRecord objects
            List<PaymentRecord> paymentRecords = new List<PaymentRecord>();
            for (Opportunity opp : opportunities) {
                PaymentRecord record = new PaymentRecord();
                record.id = opp.Id;
                record.memberId = opp.npsp__Primary_Contact__c;
                record.memberName = opp.npsp__Primary_Contact__r.Name;
                record.memberLevel = opp.npsp__Primary_Contact__r.Level__c;
                record.amountDue = opp.Amount;
                record.dueDate = opp.CloseDate;
                
                // Calculate paid amount from NPSP payments
                Decimal totalPaid = 0;
                Date lastPaymentDate = null;
                String paymentMethod = null;
                
                for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {
                    if (payment.npe01__Paid__c) {
                        totalPaid += payment.npe01__Payment_Amount__c;
                        if (lastPaymentDate == null || payment.npe01__Payment_Date__c > lastPaymentDate) {
                            lastPaymentDate = payment.npe01__Payment_Date__c;
                            paymentMethod = payment.npe01__Payment_Method__c;
                        }
                    }
                }
                
                record.amountPaid = totalPaid;
                record.lastPaymentDate = lastPaymentDate;
                record.paymentMethod = paymentMethod;
                record.balance = record.amountDue - record.amountPaid;
                
                // Determine status
                if (opp.StageName == 'Closed Won') {
                    record.status = PAYMENT_STATUS_PAID;
                    record.daysPastDue = 0;
                } else if (opp.CloseDate < Date.today() && record.balance > 0) {
                    record.status = PAYMENT_STATUS_OVERDUE;
                    record.daysPastDue = opp.CloseDate.daysBetween(Date.today());
                } else {
                    record.status = PAYMENT_STATUS_PENDING;
                    record.daysPastDue = 0;
                }
                
                paymentRecords.add(record);
            }
            
            // Get total count
            String countQuery = 'SELECT COUNT() FROM Opportunity ' +
                               'WHERE RecordType.DeveloperName = \'Donation\' ' +
                               'AND Campaign.Name = \'Annual Dues ' + year + '\' ' +
                               'AND CloseDate >= :yearStart AND CloseDate <= :yearEnd ' +
                               'WITH SECURITY_ENFORCED';
                               
            Integer totalCount = Database.countQuery(countQuery);
            
            Map<String, Object> result = new Map<String, Object>();
            result.put('records', paymentRecords);
            result.put('totalCount', totalCount);
            result.put('pageSize', pageSize);
            result.put('pageNumber', pageNumber);
            result.put('hasMore', (offset + pageSize) < totalCount);
            
            return result;
            
        } catch (Exception e) {
            CVMAErrorHandler.logError(e, 'CVMAFinancialController', 'getPaymentRecords',
                                    CVMAErrorHandler.Severity.HIGH, CVMAErrorHandler.Category.INTEGRATION);
            throw new AuraHandledException('Failed to retrieve payment records: ' + e.getMessage());
        }
    }

    /**
     * @description Process a payment for member dues using NPSP Payment objects
     * @param opportunityId Opportunity ID for the dues record
     * @param amount Payment amount
     * @param paymentMethod Method of payment (Cash, Check, Credit Card, etc.)
     * @param referenceNumber Check number, transaction ID, etc.
     * @param notes Additional payment notes
     * @return PaymentResponse with transaction details
     */
    @AuraEnabled
    public static PaymentResponse processPayment(String opportunityId, Decimal amount, String paymentMethod, 
                                               String referenceNumber, String notes) {
        try {
            validateTreasurerPermissions();
            
            // Validate inputs
            if (String.isBlank(opportunityId)) {
                throw new PaymentException('Opportunity ID is required');
            }
            if (amount == null || amount <= 0) {
                throw new PaymentException('Payment amount must be greater than zero');
            }
            if (String.isBlank(paymentMethod)) {
                throw new PaymentException('Payment method is required');
            }
            
            // Get opportunity information
            Opportunity dues = [
                SELECT Id, Name, Amount, StageName, npsp__Primary_Contact__c, npsp__Primary_Contact__r.Name
                FROM Opportunity
                WHERE Id = :opportunityId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            // Create NPSP Payment record
            npe01__OppPayment__c payment = new npe01__OppPayment__c();
            payment.npe01__Opportunity__c = opportunityId;
            payment.npe01__Payment_Amount__c = amount;
            payment.npe01__Payment_Date__c = Date.today();
            payment.npe01__Payment_Method__c = paymentMethod;
            payment.npe01__Paid__c = true;
            payment.npe01__Check_Reference_Number__c = referenceNumber;
            // Note: npe01__Notes__c may not exist, storing notes in description if needed
            
            insert payment;
            
            // Check if opportunity is now fully paid
            List<AggregateResult> paymentTotals = [
                SELECT SUM(npe01__Payment_Amount__c) totalPaid
                FROM npe01__OppPayment__c
                WHERE npe01__Opportunity__c = :opportunityId
                AND npe01__Paid__c = true
                WITH SECURITY_ENFORCED
            ];
            
            Decimal totalPaid = 0;
            if (!paymentTotals.isEmpty() && paymentTotals[0].get('totalPaid') != null) {
                totalPaid = (Decimal)paymentTotals[0].get('totalPaid');
            }
            
            // Update opportunity stage if fully paid
            if (totalPaid >= dues.Amount) {
                dues.StageName = 'Closed Won';
                update dues;
            }
            
            PaymentResponse response = new PaymentResponse();
            response.success = true;
            response.message = 'Payment processed successfully';
            response.transactionId = payment.Id;
            response.amountProcessed = amount;
            response.paymentStatus = totalPaid >= dues.Amount ? PAYMENT_STATUS_PAID : PAYMENT_STATUS_PENDING;
            
            return response;
            
        } catch (Exception e) {
            CVMAErrorHandler.logError(e, 'CVMAFinancialController', 'processPayment',
                                    CVMAErrorHandler.Severity.HIGH, CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Payment processing failed: ' + e.getMessage());
        }
    }

    /**
     * @description Get financial summary for treasury dashboard
     * @param startDate Report period start date
     * @param endDate Report period end date
     * @return FinancialSummary with key financial metrics
     */
    @AuraEnabled(cacheable=true)
    public static FinancialSummary getFinancialSummary(Date startDate, Date endDate) {
        try {
            validateTreasurerPermissions();
            
            // Set defaults if dates not provided
            if (startDate == null) {
                startDate = Date.newInstance(Date.today().year(), 1, 1);
            }
            if (endDate == null) {
                endDate = Date.today();
            }
            
            FinancialSummary summary = new FinancialSummary();
            summary.reportingPeriod = startDate.format() + ' to ' + endDate.format();
            
            // Get all opportunities (including expenses) for the period
            List<Opportunity> opportunities = [
                SELECT Id, Amount, RecordType.DeveloperName, Campaign.Name, StageName, CloseDate
                FROM Opportunity
                WHERE CloseDate >= :startDate
                AND CloseDate <= :endDate
                AND StageName = 'Closed Won'
                WITH SECURITY_ENFORCED
                ORDER BY CloseDate DESC
            ];
            
            // Calculate totals
            Decimal totalRevenue = 0;
            Decimal totalExpenses = 0;
            Map<String, Decimal> revenueByCategory = new Map<String, Decimal>();
            Map<String, Decimal> expensesByCategory = new Map<String, Decimal>();
            
            for (Opportunity opp : opportunities) {
                // Revenue opportunities (donations, dues, etc.)
                if (opp.RecordType.DeveloperName == 'Donation') {
                    totalRevenue += opp.Amount;
                    String category = opp.Campaign?.Name != null ? opp.Campaign.Name : 'Other Revenue';
                    Decimal currentAmount = revenueByCategory.get(category);
                    revenueByCategory.put(category, (currentAmount != null ? currentAmount : 0) + opp.Amount);
                }
                // Expense opportunities (negative amounts)
                else if (opp.RecordType.DeveloperName == 'Expense') {
                    totalExpenses += Math.abs(opp.Amount);
                    String category = opp.Campaign?.Name != null ? opp.Campaign.Name : 'Other Expenses';
                    Decimal currentAmount = expensesByCategory.get(category);
                    expensesByCategory.put(category, (currentAmount != null ? currentAmount : 0) + Math.abs(opp.Amount));
                }
            }
            
            summary.totalRevenue = totalRevenue;
            summary.totalExpenses = totalExpenses;
            summary.netIncome = totalRevenue - totalExpenses;
            summary.revenueByCategory = revenueByCategory;
            summary.expensesByCategory = expensesByCategory;
            
            // Get member dues payment statistics using NPSP
            Integer currentYear = Date.today().year();
            List<AggregateResult> duesStats = [
                SELECT COUNT(Id) totalMembers,
                       SUM(Amount) totalDues
                FROM Opportunity
                WHERE RecordType.DeveloperName = 'Donation'
                AND Campaign.Name = :('Annual Dues ' + currentYear)
                AND CALENDAR_YEAR(CloseDate) = :currentYear
                WITH SECURITY_ENFORCED
            ];
            
            List<AggregateResult> paidStats = [
                SELECT SUM(npe01__Payment_Amount__c) totalPaid
                FROM npe01__OppPayment__c
                WHERE npe01__Opportunity__r.RecordType.DeveloperName = 'Donation'
                AND npe01__Opportunity__r.Campaign.Name = :('Annual Dues ' + currentYear)
                AND npe01__Paid__c = true
                AND CALENDAR_YEAR(npe01__Payment_Date__c) = :currentYear
                WITH SECURITY_ENFORCED
            ];
            
            if (!duesStats.isEmpty()) {
                AggregateResult stats = duesStats[0];
                summary.totalMembers = (Integer)stats.get('totalMembers');
                Decimal totalDues = (Decimal)stats.get('totalDues');
                Decimal totalPaid = 0;
                
                if (!paidStats.isEmpty() && paidStats[0].get('totalPaid') != null) {
                    totalPaid = (Decimal)paidStats[0].get('totalPaid');
                }
                
                summary.outstandingDues = (totalDues != null ? totalDues : 0) - totalPaid;
            }
            
            // Get paid vs overdue member counts using NPSP
            List<AggregateResult> paymentStats = [
                SELECT StageName status, COUNT(Id) recordCount
                FROM Opportunity
                WHERE RecordType.DeveloperName = 'Donation'
                AND Campaign.Name = :('Annual Dues ' + currentYear)
                AND CALENDAR_YEAR(CloseDate) = :currentYear
                WITH SECURITY_ENFORCED
                GROUP BY StageName
            ];
            
            for (AggregateResult stat : paymentStats) {
                String stageName = (String)stat.get('status');
                Integer count = (Integer)stat.get('recordCount');
                if (stageName == 'Closed Won') {
                    summary.paidMembers = count;
                } else if (stageName == 'Pledged' || stageName == 'Prospecting') {
                    summary.overdueMembers = count;
                }
            }
            
            // Calculate treasury balance (simplified - would integrate with accounting system)
            summary.treasuryBalance = summary.totalRevenue - summary.totalExpenses;
            
            return summary;
            
        } catch (Exception e) {
            CVMAErrorHandler.logError(e, 'CVMAFinancialController', 'getFinancialSummary',
                                    CVMAErrorHandler.Severity.MEDIUM, CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Failed to generate financial summary: ' + e.getMessage());
        }
    }

    /**
     * @description Get financial transactions for reporting using NPSP Payment objects
     * @param startDate Filter start date
     * @param endDate Filter end date
     * @param transactionType Filter by transaction type (optional)
     * @param pageSize Number of records per page
     * @param pageNumber Page number (0-based)
     * @return Map with transactions and pagination info
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFinancialTransactions(Date startDate, Date endDate, 
                                                             String transactionType, Integer pageSize, Integer pageNumber) {
        try {
            validateTreasurerPermissions();
            
            // Set defaults
            if (startDate == null) startDate = Date.today().addMonths(-3);
            if (endDate == null) endDate = Date.today();
            if (pageSize == null || pageSize <= 0) pageSize = 50;
            if (pageNumber == null || pageNumber < 0) pageNumber = 0;
            
            Integer offset = pageNumber * pageSize;
            
            // Query NPSP Payment objects for transactions
            String query = 'SELECT Id, npe01__Payment_Date__c, npe01__Payment_Amount__c, ' +
                          'npe01__Payment_Method__c, npe01__Check_Reference_Number__c, ' +
                          'npe01__Paid__c, ' +
                          'npe01__Opportunity__c, npe01__Opportunity__r.Name, ' +
                          'npe01__Opportunity__r.RecordType.DeveloperName, ' +
                          'npe01__Opportunity__r.Campaign.Name, ' +
                          'npe01__Opportunity__r.npsp__Primary_Contact__c, ' +
                          'npe01__Opportunity__r.npsp__Primary_Contact__r.Name ' +
                          'FROM npe01__OppPayment__c ' +
                          'WHERE npe01__Payment_Date__c >= :startDate ' +
                          'AND npe01__Payment_Date__c <= :endDate ';
            
            // Filter by transaction type if specified
            if (String.isNotBlank(transactionType)) {
                if (transactionType == TRANSACTION_TYPE_DUES) {
                    query += 'AND npe01__Opportunity__r.Campaign.Name LIKE \'%Annual Dues%\' ';
                } else if (transactionType == TRANSACTION_TYPE_DONATION) {
                    query += 'AND npe01__Opportunity__r.RecordType.DeveloperName = \'Donation\' ' +
                            'AND npe01__Opportunity__r.Campaign.Name NOT LIKE \'%Annual Dues%\' ';
                } else if (transactionType == TRANSACTION_TYPE_EXPENSE) {
                    query += 'AND npe01__Opportunity__r.RecordType.DeveloperName = \'Expense\' ';
                }
            }
            
            query += 'WITH SECURITY_ENFORCED ORDER BY npe01__Payment_Date__c DESC ' +
                    'LIMIT :pageSize OFFSET :offset';
            
            List<npe01__OppPayment__c> payments = Database.query(query);
            
            // Convert to FinancialTransaction objects
            List<FinancialTransaction> transactionRecords = new List<FinancialTransaction>();
            for (npe01__OppPayment__c payment : payments) {
                FinancialTransaction record = new FinancialTransaction();
                record.id = payment.Id;
                record.transactionDate = payment.npe01__Payment_Date__c;
                record.amount = payment.npe01__Payment_Amount__c;
                record.paymentMethod = payment.npe01__Payment_Method__c;
                record.referenceNumber = payment.npe01__Check_Reference_Number__c;
                record.status = payment.npe01__Paid__c ? PAYMENT_STATUS_PAID : PAYMENT_STATUS_PENDING;
                
                // Determine transaction type based on opportunity
                if (payment.npe01__Opportunity__r?.Campaign?.Name?.contains('Annual Dues')) {
                    record.transactionType = TRANSACTION_TYPE_DUES;
                    record.description = 'Annual Dues Payment';
                    record.category = 'Member Dues';
                } else if (payment.npe01__Opportunity__r?.RecordType?.DeveloperName == 'Donation') {
                    record.transactionType = TRANSACTION_TYPE_DONATION;
                    record.description = payment.npe01__Opportunity__r?.Name;
                    record.category = payment.npe01__Opportunity__r?.Campaign?.Name != null ? 
                                    payment.npe01__Opportunity__r.Campaign.Name : 'General Donation';
                } else if (payment.npe01__Opportunity__r?.RecordType?.DeveloperName == 'Expense') {
                    record.transactionType = TRANSACTION_TYPE_EXPENSE;
                    record.description = payment.npe01__Opportunity__r?.Name;
                    record.category = payment.npe01__Opportunity__r?.Campaign?.Name != null ? 
                                    payment.npe01__Opportunity__r.Campaign.Name : 'General Expense';
                } else {
                    record.transactionType = 'Other';
                    record.description = payment.npe01__Opportunity__r?.Name;
                    record.category = 'Other';
                }
                
                record.memberId = payment.npe01__Opportunity__r?.npsp__Primary_Contact__c;
                record.memberName = payment.npe01__Opportunity__r?.npsp__Primary_Contact__r?.Name;
                
                // Notes field may not be available in NPSP Payment object
                
                transactionRecords.add(record);
            }
            
            // Get total count
            String countQuery = 'SELECT COUNT() FROM npe01__OppPayment__c ' +
                               'WHERE npe01__Payment_Date__c >= :startDate ' +
                               'AND npe01__Payment_Date__c <= :endDate ';
            
            if (String.isNotBlank(transactionType)) {
                if (transactionType == TRANSACTION_TYPE_DUES) {
                    countQuery += 'AND npe01__Opportunity__r.Campaign.Name LIKE \'%Annual Dues%\' ';
                } else if (transactionType == TRANSACTION_TYPE_DONATION) {
                    countQuery += 'AND npe01__Opportunity__r.RecordType.DeveloperName = \'Donation\' ' +
                                 'AND npe01__Opportunity__r.Campaign.Name NOT LIKE \'%Annual Dues%\' ';
                } else if (transactionType == TRANSACTION_TYPE_EXPENSE) {
                    countQuery += 'AND npe01__Opportunity__r.RecordType.DeveloperName = \'Expense\' ';
                }
            }
            
            countQuery += 'WITH SECURITY_ENFORCED';
            
            Integer totalCount = Database.countQuery(countQuery);
            
            Map<String, Object> result = new Map<String, Object>();
            result.put('transactions', transactionRecords);
            result.put('totalCount', totalCount);
            result.put('pageSize', pageSize);
            result.put('pageNumber', pageNumber);
            result.put('hasMore', (offset + pageSize) < totalCount);
            
            return result;
            
        } catch (Exception e) {
            CVMAErrorHandler.logError(e, 'CVMAFinancialController', 'getFinancialTransactions',
                                    CVMAErrorHandler.Severity.MEDIUM, CVMAErrorHandler.Category.BUSINESS_LOGIC);
            throw new AuraHandledException('Failed to retrieve financial transactions: ' + e.getMessage());
        }
    }

    // Private helper methods

    /**
     * @description Validate user has treasurer permissions
     * @throws InsufficientPermissionsException if user lacks permissions
     */
    private static void validateTreasurerPermissions() {
        if (!hasTreasurerPermissions()) {
            throw new InsufficientPermissionsException('Access denied. Treasurer permissions required.');
        }
    }

    /**
     * @description Check if current user has treasurer permissions
     * @return Boolean Whether user has treasurer permissions
     */
    private static Boolean hasTreasurerPermissions() {
        try {
            List<PermissionSetAssignment> treasurerPermissions = [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE AssigneeId = :UserInfo.getUserId()
                AND (PermissionSet.Name = 'CVMA_Treasurer_Permissions' 
                     OR PermissionSet.Name = 'CVMA_Officer_Permissions')
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            return !treasurerPermissions.isEmpty();
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * @description Calculate annual dues based on membership level
     * @param membershipLevel Member's current level
     * @return Decimal Annual dues amount
     */
    private static Decimal calculateAnnualDues(String membershipLevel) {
        switch on membershipLevel {
            when 'Full Member' {
                return ANNUAL_DUES_FULL;
            }
            when 'Associate Member' {
                return ANNUAL_DUES_ASSOCIATE;
            }
            when 'Prospect' {
                return ANNUAL_DUES_PROSPECT;
            }
            when else {
                return ANNUAL_DUES_ASSOCIATE; // Default to associate level
            }
        }
    }

    /**
     * @description Get payment method options for UI
     * @return List of payment method options
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPaymentMethods() {
        List<Map<String, String>> methods = new List<Map<String, String>>();
        methods.add(new Map<String, String>{'label' => 'Cash', 'value' => 'Cash'});
        methods.add(new Map<String, String>{'label' => 'Check', 'value' => 'Check'});
        methods.add(new Map<String, String>{'label' => 'Credit Card', 'value' => 'Credit Card'});
        methods.add(new Map<String, String>{'label' => 'Bank Transfer', 'value' => 'Bank Transfer'});
        methods.add(new Map<String, String>{'label' => 'PayPal', 'value' => 'PayPal'});
        methods.add(new Map<String, String>{'label' => 'Venmo', 'value' => 'Venmo'});
        return methods;
    }

    /**
     * @description Get transaction type options for UI
     * @return List of transaction type options
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getTransactionTypes() {
        List<Map<String, String>> types = new List<Map<String, String>>();
        types.add(new Map<String, String>{'label' => 'Dues Payment', 'value' => TRANSACTION_TYPE_DUES});
        types.add(new Map<String, String>{'label' => 'Expense', 'value' => TRANSACTION_TYPE_EXPENSE});
        types.add(new Map<String, String>{'label' => 'Donation', 'value' => TRANSACTION_TYPE_DONATION});
        types.add(new Map<String, String>{'label' => 'Fundraiser', 'value' => TRANSACTION_TYPE_FUNDRAISER});
        return types;
    }
}