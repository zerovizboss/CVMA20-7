/**
 * Mock DOD Records API Controller for Epic #8 Phase 3
 * Provides comprehensive simulation of military service verification and DOD records
 * Designed for Developer Org compliance while maintaining realistic functionality
 *
 * Features:
 * - Military service verification (branch, rank, dates, discharge status)
 * - SCRA (Servicemembers Civil Relief Act) status verification
 * - Security clearance history (unclassified simulation only)
 * - Awards and decorations tracking
 * - Deployment history (sanitized for security)
 * - DD-214 simulation core elements
 *
 * @author CVMA Development Team
 * @since Epic #8 Phase 3
 */
public with sharing class CVMAMockDODRecordsController {

    // Cache keys for performance optimization
    private static final String CACHE_KEY_PREFIX = 'DOD_RECORDS_';
    private static final Integer CACHE_TTL_MINUTES = 60; // Longer cache for military records

    // Military service data constants
    private static final Map<String, List<String>> BRANCH_RANKS = new Map<String, List<String>>{
        'Army' => new List<String>{'PVT', 'PFC', 'SPC', 'CPL', 'SGT', 'SSG', 'SFC', 'MSG', '1SG', 'SGM', 'CSM',
                                   '2LT', '1LT', 'CPT', 'MAJ', 'LTC', 'COL', 'BG', 'MG', 'LTG', 'GEN'},
        'Navy' => new List<String>{'SR', 'SA', 'SN', 'PO3', 'PO2', 'PO1', 'CPO', 'SCPO', 'MCPO',
                                   'ENS', 'LTJG', 'LT', 'LCDR', 'CDR', 'CAPT', 'RADM(LH)', 'RADM', 'VADM', 'ADM'},
        'Air Force' => new List<String>{'AB', 'AMN', 'A1C', 'SRA', 'SSG', 'TSG', 'MSG', 'SMS', 'CMS',
                                        '2LT', '1LT', 'CAPT', 'MAJ', 'LT COL', 'COL', 'BG', 'MG', 'LT GEN', 'GEN'},
        'Marines' => new List<String>{'PVT', 'PFC', 'LCPL', 'CPL', 'SGT', 'SSGT', 'GSGT', 'MSGT', 'MGYSGT',
                                      '2NDLT', '1STLT', 'CAPT', 'MAJ', 'LTCOL', 'COL', 'BGEN', 'MAJGEN', 'LTGEN', 'GEN'},
        'Coast Guard' => new List<String>{'SR', 'SA', 'SN', 'PO3', 'PO2', 'PO1', 'CPO', 'SCPO', 'MCPO',
                                          'ENS', 'LTJG', 'LT', 'LCDR', 'CDR', 'CAPT', 'RADM', 'VADM', 'ADM'},
        'Space Force' => new List<String>{'SPC1', 'SPC2', 'SPC3', 'SPC4', 'SGT', 'TSG', 'MSG', 'SMS', 'CMS',
                                          '2LT', '1LT', 'CAPT', 'MAJ', 'LT COL', 'COL', 'BG', 'MG', 'LT GEN', 'GEN'}
    };

    /**
     * Comprehensive DOD Records Data Structure
     */
    public class DODRecordsResponse {
        @AuraEnabled public Boolean isVerified { get; set; }
        @AuraEnabled public String serviceNumber { get; set; }
        @AuraEnabled public ServiceRecord serviceRecord { get; set; }
        @AuraEnabled public SCRAStatus scraStatus { get; set; }
        @AuraEnabled public SecurityClearance securityClearance { get; set; }
        @AuraEnabled public List<AwardDecoration> awards { get; set; }
        @AuraEnabled public List<DeploymentRecord> deployments { get; set; }
        @AuraEnabled public DD214Summary dd214Summary { get; set; }
        @AuraEnabled public String lastVerified { get; set; }
        @AuraEnabled public List<String> verificationAlerts { get; set; }
        @AuraEnabled public APIStatus apiStatus { get; set; }

        public DODRecordsResponse() {
            this.isVerified = false;
            this.awards = new List<AwardDecoration>();
            this.deployments = new List<DeploymentRecord>();
            this.verificationAlerts = new List<String>();
            this.apiStatus = new APIStatus();
        }
    }

    public class ServiceRecord {
        @AuraEnabled public String serviceBranch { get; set; }
        @AuraEnabled public String entryDate { get; set; }
        @AuraEnabled public String separationDate { get; set; }
        @AuraEnabled public String highestRank { get; set; }
        @AuraEnabled public String dischargeType { get; set; }
        @AuraEnabled public String dischargeReason { get; set; }
        @AuraEnabled public String primaryMOS { get; set; }
        @AuraEnabled public String unitAssignment { get; set; }
        @AuraEnabled public Integer totalServiceDays { get; set; }
        @AuraEnabled public Integer activeServiceDays { get; set; }
        @AuraEnabled public Boolean isCombatVeteran { get; set; }
    }

    public class SCRAStatus {
        @AuraEnabled public Boolean isActiveDuty { get; set; }
        @AuraEnabled public String statusDate { get; set; }
        @AuraEnabled public String currentUnit { get; set; }
        @AuraEnabled public String dutyLocation { get; set; }
        @AuraEnabled public Boolean isDeployed { get; set; }
        @AuraEnabled public String expectedReturnDate { get; set; }
        @AuraEnabled public List<String> activeProtections { get; set; }

        public SCRAStatus() {
            this.activeProtections = new List<String>();
        }
    }

    public class SecurityClearance {
        @AuraEnabled public String currentLevel { get; set; }
        @AuraEnabled public String highestLevel { get; set; }
        @AuraEnabled public String lastInvestigation { get; set; }
        @AuraEnabled public String expirationDate { get; set; }
        @AuraEnabled public Boolean isEligibleForReinstatement { get; set; }
        @AuraEnabled public String status { get; set; }
    }

    public class AwardDecoration {
        @AuraEnabled public String awardName { get; set; }
        @AuraEnabled public String awardDate { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public Integer oakLeafClusters { get; set; }
    }

    public class DeploymentRecord {
        @AuraEnabled public String operation { get; set; }
        @AuraEnabled public String theater { get; set; }
        @AuraEnabled public String startDate { get; set; }
        @AuraEnabled public String endDate { get; set; }
        @AuraEnabled public String unit { get; set; }
        @AuraEnabled public Boolean isCombatDeployment { get; set; }
    }

    public class DD214Summary {
        @AuraEnabled public String entryDate { get; set; }
        @AuraEnabled public String releaseDate { get; set; }
        @AuraEnabled public String lastDutyAssignment { get; set; }
        @AuraEnabled public String militaryOccupation { get; set; }
        @AuraEnabled public String reasonForSeparation { get; set; }
        @AuraEnabled public String narrativeReasonForSeparation { get; set; }
        @AuraEnabled public String separationCode { get; set; }
        @AuraEnabled public String reentryCode { get; set; }
        @AuraEnabled public List<String> awards { get; set; }

        public DD214Summary() {
            this.awards = new List<String>();
        }
    }

    public class APIStatus {
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String responseTime { get; set; }
        @AuraEnabled public String lastUpdated { get; set; }
        @AuraEnabled public String version { get; set; }
        @AuraEnabled public String securityLevel { get; set; }

        public APIStatus() {
            this.status = 'Available';
            this.responseTime = generateResponseTime();
            this.lastUpdated = System.now().format('yyyy-MM-dd HH:mm:ss');
            this.version = 'v3.2.1';
            this.securityLevel = 'UNCLASSIFIED';
        }
    }

    /**
     * Main method to retrieve comprehensive DOD military records
     * @param contactId The Contact ID of the veteran/service member
     * @return DODRecordsResponse Complete military service verification
     */
    @AuraEnabled(cacheable=true)
    public static DODRecordsResponse getDODRecords(String contactId) {
        try {
            // Input validation and security
            CVMAErrorHandler.validateCRUDPermissions('Contact', 'READ');
            contactId = CVMAErrorHandler.sanitizeInput(contactId);

            if (String.isBlank(contactId)) {
                throw new CVMAMockAPIException('Contact ID is required for DOD records lookup');
            }

            // Check cache first for performance
            String cacheKey = CACHE_KEY_PREFIX + contactId;
            DODRecordsResponse cachedResponse = (DODRecordsResponse) Cache.Org.get(cacheKey);
            if (cachedResponse != null) {
                return cachedResponse;
            }

            // Retrieve contact military service information
            Contact serviceContact = getServiceMemberContactInfo(contactId);

            // Generate comprehensive mock DOD records
            DODRecordsResponse response = generateMockDODRecords(serviceContact);

            // Cache the response for performance (longer cache for military records)
            Cache.Org.put(cacheKey, response, CACHE_TTL_MINUTES * 60);

            return response;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAMockDODRecordsController', 'getDODRecords',
                'HIGH', 'INTEGRATION', new Map<String, Object>{'contactId' => contactId});
            throw new AuraHandledException('Failed to retrieve DOD records: ' + e.getMessage());
        }
    }

    /**
     * Get service verification specifically for membership applications
     * @param contactId The Contact ID of the service member
     * @return ServiceRecord Basic service verification information
     */
    @AuraEnabled(cacheable=true)
    public static ServiceRecord getServiceVerification(String contactId) {
        try {
            DODRecordsResponse fullResponse = getDODRecords(contactId);
            return fullResponse.serviceRecord;
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAMockDODRecordsController', 'getServiceVerification',
                'MEDIUM', 'INTEGRATION', new Map<String, Object>{'contactId' => contactId});
            throw new AuraHandledException('Failed to retrieve service verification: ' + e.getMessage());
        }
    }

    /**
     * Get SCRA status for legal protections verification
     * @param contactId The Contact ID of the service member
     * @return SCRAStatus Current active duty and deployment status
     */
    @AuraEnabled(cacheable=true)
    public static SCRAStatus getSCRAStatus(String contactId) {
        try {
            DODRecordsResponse fullResponse = getDODRecords(contactId);
            return fullResponse.scraStatus;
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAMockDODRecordsController', 'getSCRAStatus',
                'MEDIUM', 'INTEGRATION', new Map<String, Object>{'contactId' => contactId});
            throw new AuraHandledException('Failed to retrieve SCRA status: ' + e.getMessage());
        }
    }

    /**
     * Get military awards and decorations
     * @param contactId The Contact ID of the service member
     * @return List<AwardDecoration> Military honors and commendations
     */
    @AuraEnabled(cacheable=true)
    public static List<AwardDecoration> getMilitaryAwards(String contactId) {
        try {
            DODRecordsResponse fullResponse = getDODRecords(contactId);
            return fullResponse.awards;
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAMockDODRecordsController', 'getMilitaryAwards',
                'LOW', 'INTEGRATION', new Map<String, Object>{'contactId' => contactId});
            throw new AuraHandledException('Failed to retrieve military awards: ' + e.getMessage());
        }
    }

    /**
     * Get deployment history (sanitized for security)
     * @param contactId The Contact ID of the service member
     * @return List<DeploymentRecord> Deployment and operational history
     */
    @AuraEnabled(cacheable=true)
    public static List<DeploymentRecord> getDeploymentHistory(String contactId) {
        try {
            DODRecordsResponse fullResponse = getDODRecords(contactId);
            return fullResponse.deployments;
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAMockDODRecordsController', 'getDeploymentHistory',
                'LOW', 'INTEGRATION', new Map<String, Object>{'contactId' => contactId});
            throw new AuraHandledException('Failed to retrieve deployment history: ' + e.getMessage());
        }
    }

    /**
     * Get DD-214 summary information
     * @param contactId The Contact ID of the veteran
     * @return DD214Summary Core discharge document elements
     */
    @AuraEnabled(cacheable=true)
    public static DD214Summary getDD214Summary(String contactId) {
        try {
            DODRecordsResponse fullResponse = getDODRecords(contactId);
            return fullResponse.dd214Summary;
        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAMockDODRecordsController', 'getDD214Summary',
                'MEDIUM', 'INTEGRATION', new Map<String, Object>{'contactId' => contactId});
            throw new AuraHandledException('Failed to retrieve DD-214 summary: ' + e.getMessage());
        }
    }

    /**
     * Validate combat veteran status for CVMA membership eligibility
     * @param contactId The Contact ID of the applicant
     * @return Boolean True if verified combat veteran, false otherwise
     */
    @AuraEnabled
    public static Boolean validateCombatVeteranStatus(String contactId) {
        try {
            ServiceRecord serviceRecord = getServiceVerification(contactId);
            List<DeploymentRecord> deployments = getDeploymentHistory(contactId);

            // Verify combat veteran status through service record and deployments
            Boolean hasCombatDeployment = false;
            for (DeploymentRecord deployment : deployments) {
                if (deployment.isCombatDeployment) {
                    hasCombatDeployment = true;
                    break;
                }
            }

            return serviceRecord.isCombatVeteran && hasCombatDeployment;

        } catch (Exception e) {
            CVMAErrorHandler.handleException(e, 'CVMAMockDODRecordsController', 'validateCombatVeteranStatus',
                'HIGH', 'SECURITY', new Map<String, Object>{'contactId' => contactId});
            return false; // Fail secure - deny if cannot verify
        }
    }

    /**
     * Get service member contact information securely
     * @param contactId The Contact ID to retrieve
     * @return Contact The service member's contact record with military service info
     */
    private static Contact getServiceMemberContactInfo(String contactId) {
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Email, Military_Service_Branch__c,
                   Service_Start_Date__c, Service_End_Date__c, Level__c,
                   Membership_Id__c, npo02__MembershipJoinDate__c
            FROM Contact
            WHERE Id = :contactId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (contacts.isEmpty()) {
            throw new CVMAMockAPIException('Service member contact not found with ID: ' + contactId);
        }

        return contacts[0];
    }

    /**
     * Generate comprehensive mock DOD records based on contact information
     * @param serviceContact The service member's contact record
     * @return DODRecordsResponse Simulated DOD records package
     */
    private static DODRecordsResponse generateMockDODRecords(Contact serviceContact) {
        DODRecordsResponse response = new DODRecordsResponse();

        // Base verification on military service branch
        response.isVerified = !String.isBlank(serviceContact.Military_Service_Branch__c);

        if (response.isVerified) {
            response.serviceNumber = generateServiceNumber(serviceContact);
            response.serviceRecord = generateMockServiceRecord(serviceContact);
            response.scraStatus = generateMockSCRAStatus(serviceContact);
            response.securityClearance = generateMockSecurityClearance(serviceContact);
            response.awards = generateMockAwards(serviceContact);
            response.deployments = generateMockDeployments(serviceContact);
            response.dd214Summary = generateMockDD214Summary(serviceContact);
            response.lastVerified = System.now().format('yyyy-MM-dd HH:mm:ss');
            response.verificationAlerts = generateVerificationAlerts(response);
        } else {
            response.verificationAlerts.add('Military service branch required for DOD records verification.');
        }

        return response;
    }

    /**
     * Generate mock service record with realistic military data
     */
    private static ServiceRecord generateMockServiceRecord(Contact serviceContact) {
        ServiceRecord record = new ServiceRecord();

        record.serviceBranch = serviceContact.Military_Service_Branch__c;
        record.entryDate = serviceContact.Service_Start_Date__c?.format() ?:
            Date.today().addYears(-8).format();
        record.separationDate = serviceContact.Service_End_Date__c?.format() ?:
            Date.today().addYears(-2).format();

        // Generate realistic rank based on service length
        Integer serviceYears = calculateServiceYears(serviceContact);
        record.highestRank = generateRank(record.serviceBranch, serviceYears);

        record.dischargeType = generateDischargeType();
        record.dischargeReason = generateDischargeReason(record.dischargeType);
        record.primaryMOS = generateMOS(record.serviceBranch);
        record.unitAssignment = generateUnitAssignment(record.serviceBranch);

        Date entryDate = Date.valueOf(record.entryDate);
        Date sepDate = Date.valueOf(record.separationDate);
        record.totalServiceDays = entryDate.daysBetween(sepDate);
        record.activeServiceDays = record.totalServiceDays; // Simplification for mock

        // Combat veteran determination based on service branch and years
        record.isCombatVeteran = determineCombatVeteranStatus(record.serviceBranch, serviceYears);

        return record;
    }

    /**
     * Generate mock SCRA status (mostly inactive for veterans)
     */
    private static SCRAStatus generateMockSCRAStatus(Contact serviceContact) {
        SCRAStatus scra = new SCRAStatus();

        // Most CVMA members are veterans, not active duty
        Boolean isActive = Math.random() < 0.05; // 5% chance of being active

        scra.isActiveDuty = isActive;
        scra.statusDate = System.now().format('yyyy-MM-dd');

        if (isActive) {
            scra.currentUnit = generateActiveUnit(serviceContact.Military_Service_Branch__c);
            scra.dutyLocation = generateDutyLocation();
            scra.isDeployed = Math.random() < 0.3; // 30% chance if active
            scra.expectedReturnDate = scra.isDeployed ?
                Date.today().addMonths(6).format() : null;
            scra.activeProtections.addAll(generateActiveProtections());
        }

        return scra;
    }

    /**
     * Generate mock security clearance (unclassified simulation only)
     */
    private static SecurityClearance generateMockSecurityClearance(Contact serviceContact) {
        SecurityClearance clearance = new SecurityClearance();

        // Generate realistic clearance based on service branch
        Boolean hadClearance = Math.random() < 0.4; // 40% had some clearance

        if (hadClearance) {
            List<String> clearanceLevels = new List<String>{'Confidential', 'Secret', 'Top Secret'};
            String level = clearanceLevels[(Integer)(Math.random() * clearanceLevels.size())];

            clearance.highestLevel = level;
            clearance.currentLevel = Math.random() < 0.7 ? level : 'Expired';
            clearance.lastInvestigation = Date.today().addYears(-3).format();
            clearance.expirationDate = Date.today().addYears(2).format();
            clearance.isEligibleForReinstatement = clearance.currentLevel == 'Expired';
            clearance.status = clearance.currentLevel == 'Expired' ? 'Inactive' : 'Active';
        } else {
            clearance.currentLevel = 'None';
            clearance.highestLevel = 'None';
            clearance.status = 'Not Required';
        }

        return clearance;
    }

    /**
     * Generate mock military awards based on service
     */
    private static List<AwardDecoration> generateMockAwards(Contact serviceContact) {
        List<AwardDecoration> awards = new List<AwardDecoration>();

        // Common awards that most service members receive
        String serviceBranch = serviceContact.Military_Service_Branch__c;
        Integer serviceYears = calculateServiceYears(serviceContact);

        // Add basic service awards
        awards.add(createAward('National Defense Service Medal', 'Service Award', 'Awarded for honorable active military service'));
        awards.add(createAward(getServiceRibbon(serviceBranch), 'Service Award', 'Completion of military training'));

        // Add deployment awards if applicable
        if (serviceYears >= 2) {
            awards.add(createAward('Global War on Terrorism Service Medal', 'Campaign Award', 'Service during GWOT operations'));
        }

        // Add achievement awards based on service length
        if (serviceYears >= 4) {
            awards.add(createAward('Army Commendation Medal', 'Achievement Award', 'Meritorious service achievement'));
        }

        if (serviceYears >= 6) {
            awards.add(createAward('Meritorious Service Medal', 'Achievement Award', 'Outstanding meritorious service'));
        }

        // Combat awards for combat veterans
        ServiceRecord serviceRecord = generateMockServiceRecord(serviceContact);
        if (serviceRecord.isCombatVeteran) {
            awards.add(createAward('Combat Action Badge', 'Combat Award', 'Active participation in ground combat'));
            if (Math.random() < 0.3) { // 30% chance
                awards.add(createAward('Bronze Star Medal', 'Valor Award', 'Heroic or meritorious achievement in combat'));
            }
        }

        return awards;
    }

    /**
     * Generate mock deployment history (sanitized)
     */
    private static List<DeploymentRecord> generateMockDeployments(Contact serviceContact) {
        List<DeploymentRecord> deployments = new List<DeploymentRecord>();

        Integer serviceYears = calculateServiceYears(serviceContact);
        String serviceBranch = serviceContact.Military_Service_Branch__c;

        // Number of deployments based on service years and branch
        Integer deploymentCount = 0;
        if (serviceYears >= 4) {
            deploymentCount = (Integer)(Math.random() * 3) + 1; // 1-3 deployments
        }

        for (Integer i = 0; i < deploymentCount; i++) {
            DeploymentRecord deployment = new DeploymentRecord();
            deployment.operation = generateOperationName();
            deployment.theater = generateTheater();
            deployment.startDate = generateDeploymentDate(serviceContact.Service_Start_Date__c, i);
            deployment.endDate = Date.valueOf(deployment.startDate).addMonths(12).format();
            deployment.unit = generateDeploymentUnit(serviceBranch);
            deployment.isCombatDeployment = isOperationCombat(deployment.operation);

            deployments.add(deployment);
        }

        return deployments;
    }

    /**
     * Generate mock DD-214 summary
     */
    private static DD214Summary generateMockDD214Summary(Contact serviceContact) {
        DD214Summary dd214 = new DD214Summary();
        ServiceRecord serviceRecord = generateMockServiceRecord(serviceContact);

        dd214.entryDate = serviceRecord.entryDate;
        dd214.releaseDate = serviceRecord.separationDate;
        dd214.lastDutyAssignment = serviceRecord.unitAssignment;
        dd214.militaryOccupation = serviceRecord.primaryMOS;
        dd214.reasonForSeparation = serviceRecord.dischargeReason;
        dd214.narrativeReasonForSeparation = generateNarrativeReason(serviceRecord.dischargeType);
        dd214.separationCode = generateSeparationCode(serviceRecord.dischargeType);
        dd214.reentryCode = generateReentryCode(serviceRecord.dischargeType);

        // Add key awards to DD-214 summary
        List<AwardDecoration> awards = generateMockAwards(serviceContact);
        for (AwardDecoration award : awards) {
            if (awards.size() <= 5) { // Limit to primary awards
                dd214.awards.add(award.awardName);
            }
        }

        return dd214;
    }

    // Utility methods for realistic data generation

    private static String generateServiceNumber(Contact serviceContact) {
        String branchCode = getBranchCode(serviceContact.Military_Service_Branch__c);
        return branchCode + String.valueOf(Math.random() * 100000000).substring(0, 8);
    }

    private static Integer calculateServiceYears(Contact serviceContact) {
        if (serviceContact.Service_Start_Date__c == null || serviceContact.Service_End_Date__c == null) {
            return (Integer)(Math.random() * 20) + 2; // 2-22 years
        }
        return serviceContact.Service_Start_Date__c.daysBetween(serviceContact.Service_End_Date__c) / 365;
    }

    private static String generateRank(String serviceBranch, Integer serviceYears) {
        List<String> ranks = BRANCH_RANKS.get(serviceBranch);
        if (ranks == null) return 'E-5';

        // Rank progression based on service years
        Integer rankIndex;
        if (serviceYears < 2) rankIndex = 0; // Entry level
        else if (serviceYears < 4) rankIndex = (Integer)(Math.random() * 3) + 1; // E-2 to E-4
        else if (serviceYears < 8) rankIndex = (Integer)(Math.random() * 3) + 4; // E-5 to E-7
        else if (serviceYears < 15) rankIndex = (Integer)(Math.random() * 4) + 6; // E-6 to E-9 or O-1 to O-3
        else rankIndex = (Integer)(Math.random() * 6) + 10; // Senior NCO/Officer

        return rankIndex < ranks.size() ? ranks[rankIndex] : ranks[ranks.size() - 1];
    }

    private static String generateDischargeType() {
        List<String> dischargeTypes = new List<String>{'Honorable', 'General Under Honorable Conditions', 'Other Than Honorable'};
        Double random = Math.random();
        if (random < 0.85) return 'Honorable'; // 85% honorable
        if (random < 0.95) return 'General Under Honorable Conditions'; // 10% general
        return 'Other Than Honorable'; // 5% other
    }

    private static String generateDischargeReason(String dischargeType) {
        if (dischargeType == 'Honorable') {
            List<String> reasons = new List<String>{'Completion of Required Active Service', 'Expiration of Service Obligation', 'Retirement'};
            return reasons[(Integer)(Math.random() * reasons.size())];
        }
        return 'End of Active Service Obligation';
    }

    private static String generateMOS(String serviceBranch) {
        Map<String, List<String>> branchMOS = new Map<String, List<String>>{
            'Army' => new List<String>{'11B - Infantry', '13B - Cannon Crewmember', '25B - Information Technology', '31B - Military Police'},
            'Navy' => new List<String>{'IT - Information Systems', 'CS - Culinary Specialist', 'BM - Boatswain\'s Mate', 'FC - Fire Controlman'},
            'Air Force' => new List<String>{'3D1X2 - Cyber Transport Systems', '2A3X3 - Tactical Aircraft Maintenance', '1N0X1 - Operations Intelligence'},
            'Marines' => new List<String>{'0311 - Rifleman', '0651 - Cyber Network Systems', '6842 - Nuclear Biological Chemical', '8411 - Food Service'},
            'Coast Guard' => new List<String>{'BM - Boatswain\'s Mate', 'IT - Information Systems', 'ME - Maritime Enforcement', 'SK - Storekeeper'},
            'Space Force' => new List<String>{'1D7X1R - Cyber Defense Operations', '13SX - Space Systems Operations', '1N0X1 - Operations Intelligence'}
        };

        List<String> mosList = branchMOS.get(serviceBranch);
        return mosList != null ? mosList[(Integer)(Math.random() * mosList.size())] : '99Z - Unknown';
    }

    private static String generateUnitAssignment(String serviceBranch) {
        Map<String, List<String>> branchUnits = new Map<String, List<String>>{
            'Army' => new List<String>{'1st Infantry Division', '82nd Airborne Division', '101st Airborne Division', '3rd Armored Division'},
            'Navy' => new List<String>{'USS Enterprise', 'Naval Station Norfolk', 'USS Gerald R. Ford', 'Naval Air Station Pensacola'},
            'Air Force' => new List<String>{'1st Fighter Wing', 'Air Combat Command', 'Air Force Materiel Command', '22nd Air Refueling Wing'},
            'Marines' => new List<String>{'1st Marine Division', '2nd Marine Expeditionary Force', '3rd Marine Aircraft Wing', 'Marine Corps Base Quantico'},
            'Coast Guard' => new List<String>{'Coast Guard Cutter Bertholf', 'Coast Guard Station Miami', 'Coast Guard Air Station Cape Cod'},
            'Space Force' => new List<String>{'Space Operations Command', '45th Launch Delta', 'Space Training and Readiness Command'}
        };

        List<String> units = branchUnits.get(serviceBranch);
        return units != null ? units[(Integer)(Math.random() * units.size())] : 'Unknown Unit';
    }

    private static Boolean determineCombatVeteranStatus(String serviceBranch, Integer serviceYears) {
        // Combat rates vary by branch and era
        List<String> combatBranches = new List<String>{'Army', 'Marines'};
        Double combatChance = combatBranches.contains(serviceBranch) ? 0.6 : 0.3;

        // Increase chance with longer service
        if (serviceYears >= 6) combatChance += 0.2;

        return Math.random() < combatChance;
    }

    private static String generateActiveUnit(String serviceBranch) {
        return generateUnitAssignment(serviceBranch);
    }

    private static String generateDutyLocation() {
        List<String> locations = new List<String>{
            'Fort Liberty, NC', 'Norfolk Naval Station, VA', 'Lackland AFB, TX',
            'Camp Pendleton, CA', 'Coast Guard Base Alameda, CA', 'Peterson SFB, CO'
        };
        return locations[(Integer)(Math.random() * locations.size())];
    }

    private static List<String> generateActiveProtections() {
        return new List<String>{
            'Stay of Proceedings', 'Reduced Interest Rates', 'Protection from Eviction',
            'Postponement of Civil Court Proceedings'
        };
    }

    private static AwardDecoration createAward(String name, String category, String description) {
        AwardDecoration award = new AwardDecoration();
        award.awardName = name;
        award.category = category;
        award.description = description;
        award.awardDate = Date.today().addYears(-3).format();
        award.oakLeafClusters = (Integer)(Math.random() * 3); // 0-2 clusters
        return award;
    }

    private static String getServiceRibbon(String serviceBranch) {
        Map<String, String> serviceRibbons = new Map<String, String>{
            'Army' => 'Army Service Ribbon',
            'Navy' => 'Navy and Marine Corps Overseas Service Ribbon',
            'Air Force' => 'Air Force Training Ribbon',
            'Marines' => 'Marine Corps Good Conduct Medal',
            'Coast Guard' => 'Coast Guard Good Conduct Medal',
            'Space Force' => 'Space Force Training Ribbon'
        };
        return serviceRibbons.get(serviceBranch);
    }

    private static String generateOperationName() {
        List<String> operations = new List<String>{
            'Operation Iraqi Freedom', 'Operation Enduring Freedom', 'Operation New Dawn',
            'Operation Inherent Resolve', 'Operation Freedom\'s Sentinel'
        };
        return operations[(Integer)(Math.random() * operations.size())];
    }

    private static String generateTheater() {
        List<String> theaters = new List<String>{'Iraq', 'Afghanistan', 'Kuwait', 'Germany', 'Korea', 'Japan'};
        return theaters[(Integer)(Math.random() * theaters.size())];
    }

    private static String generateDeploymentDate(Date serviceStart, Integer deploymentNumber) {
        Date baseDate = serviceStart != null ? serviceStart : Date.today().addYears(-6);
        return baseDate.addYears(deploymentNumber + 1).format();
    }

    private static String generateDeploymentUnit(String serviceBranch) {
        return generateUnitAssignment(serviceBranch);
    }

    private static Boolean isOperationCombat(String operation) {
        List<String> combatOps = new List<String>{'Operation Iraqi Freedom', 'Operation Enduring Freedom', 'Operation Inherent Resolve'};
        return combatOps.contains(operation);
    }

    private static String generateNarrativeReason(String dischargeType) {
        if (dischargeType == 'Honorable') return 'Satisfactory completion of required active service';
        return 'Completion of required active service';
    }

    private static String generateSeparationCode(String dischargeType) {
        if (dischargeType == 'Honorable') return 'JFF';
        return 'JFV';
    }

    private static String generateReentryCode(String dischargeType) {
        if (dischargeType == 'Honorable') return 'RE-1';
        return 'RE-2';
    }

    private static String getBranchCode(String serviceBranch) {
        Map<String, String> branchCodes = new Map<String, String>{
            'Army' => 'A', 'Navy' => 'N', 'Air Force' => 'F',
            'Marines' => 'M', 'Coast Guard' => 'C', 'Space Force' => 'S'
        };
        return branchCodes.get(serviceBranch) ?: 'U';
    }

    private static List<String> generateVerificationAlerts(DODRecordsResponse response) {
        List<String> alerts = new List<String>();

        if (response.serviceRecord.isCombatVeteran) {
            alerts.add('Combat veteran status verified - eligible for CVMA membership');
        }

        if (response.scraStatus.isActiveDuty) {
            alerts.add('Active duty status confirmed - SCRA protections available');
        }

        if (response.securityClearance.currentLevel != 'None' && response.securityClearance.status == 'Active') {
            alerts.add('Security clearance active - ' + response.securityClearance.currentLevel + ' level');
        }

        return alerts;
    }

    private static String generateResponseTime() {
        Integer responseTime = (Integer)(Math.random() * 200) + 100; // 100-300ms
        return responseTime + 'ms';
    }

    /**
     * Custom exception for mock API errors
     */
    public class CVMAMockAPIException extends Exception {}
}
