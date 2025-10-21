# Custom Metadata Types (CMT) - Developer Guide
**Combat Veterans Motorcycle Association Chapter 20-7**

## 🎯 **What Are Custom Metadata Types?**

Custom Metadata Types (CMT) are **application configuration data** that you can deploy like code, rather than **business data** that lives in Custom Objects.

Think of CMT as **"configurable constants"** - data that defines how your application behaves, not data that users create during daily operations.

---

## 📊 **CMT vs Custom Objects: The Core Difference**

### **Custom Metadata Types = Configuration**
- Defines how your app works
- Managed by developers/admins
- Deployed via metadata API (like Apex classes)
- Changes infrequently
- Version controlled in git

### **Custom Objects = Business Data**
- Stores what your app does
- Created by end users
- Managed via Data Loader/SOQL DML
- Changes constantly
- Lives in the database

### **Real-World Analogy**
- **CMT**: Like a restaurant's menu (configuration - changes occasionally)
- **Custom Object**: Like restaurant orders (transactions - changes constantly)

---

## 🏗️ **CVMA Project Examples**

### **User Stories #73-75: Veteran Resources (CMT) ✅**

**Why CMT?**
```apex
// Reference data that configures what resources are available
CVMA_Legal_Resource__mdt (CMT)
├── DAV_Disabled_American_Veterans (metadata record)
├── VFW_Service_Officers (metadata record)
└── American_Legion_Veterans_Advocacy (metadata record)

// Query CMT - No CRUD/FLS checks needed
List<CVMA_Legal_Resource__mdt> resources = [
    SELECT Resource_Name__c, Contact_Phone__c, Website_URL__c
    FROM CVMA_Legal_Resource__mdt
    WHERE Is_Active__c = true
];
// Cacheable, fast, no security complexity
```

**Characteristics**:
- ✅ Reference data (not transactions)
- ✅ Admin updates via Setup UI
- ✅ Deployed like code (git-tracked)
- ✅ Read-only for end users
- ✅ No record ownership needed

### **User Story #76: Veteran Assistance Requests (Custom Object) ✅**

**Why Custom Object?**
```apex
// Transactional data created by users
Veteran_Assistance_Request__c (Custom Object)
├── John Smith's housing request (record owned by John)
├── Jane Doe's financial assistance (record owned by Jane)
└── Bob Jones's emergency request (record owned by Bob)

// Query Custom Object - Requires WITH SECURITY_ENFORCED
List<Veteran_Assistance_Request__c> requests = [
    SELECT Name, Member__c, Request_Type__c, Status__c
    FROM Veteran_Assistance_Request__c
    WHERE Status__c = 'Pending'
    WITH SECURITY_ENFORCED
];
// User ownership, sharing rules, approval workflows
```

**Characteristics**:
- ✅ User-generated transactions
- ✅ Record ownership (each request belongs to someone)
- ✅ Approval workflows needed
- ✅ Sharing rules (CEB sees all, members see own)
- ✅ Reporting on trends over time

---

## 🔍 **Common CMT Use Cases**

### **1. External System Configurations**

**Example: API Endpoint Configuration**
```apex
// CMT: API_Configuration__mdt
public class APICalloutService {
    public static HttpResponse callExternalAPI(String endpointName) {
        API_Configuration__mdt config = [
            SELECT Endpoint_URL__c, API_Key__c, Timeout__c, Retry_Count__c
            FROM API_Configuration__mdt
            WHERE DeveloperName = :endpointName
            LIMIT 1
        ];

        HttpRequest req = new HttpRequest();
        req.setEndpoint(config.Endpoint_URL__c);
        req.setHeader('Authorization', 'Bearer ' + config.API_Key__c);
        req.setTimeout(Integer.valueOf(config.Timeout__c));
        // No hardcoded values - all configurable via CMT
    }
}
```

**Why CMT?**
- Different endpoints per sandbox/production (no code changes)
- Admins can update timeout values without deploying code
- API keys stored in protected custom metadata
- Version controlled (track config changes in git)

**Common Fields**:
- Endpoint_URL__c
- API_Key__c
- Timeout__c
- Retry_Count__c
- Is_Active__c

---

### **2. Business Rules & Constants**

**Example: Tax Rate Configuration**
```apex
// CMT: Tax_Rate_Configuration__mdt
public class OrderCalculator {
    private static Map<String, Tax_Rate_Configuration__mdt> taxRates;

    static {
        taxRates = new Map<String, Tax_Rate_Configuration__mdt>();
        for (Tax_Rate_Configuration__mdt rate : [
            SELECT State_Code__c, Tax_Rate__c, Special_Tax__c
            FROM Tax_Rate_Configuration__mdt
            WHERE Is_Active__c = true
        ]) {
            taxRates.put(rate.State_Code__c, rate);
        }
    }

    public static Decimal calculateTax(Decimal amount, String stateCode) {
        Tax_Rate_Configuration__mdt config = taxRates.get(stateCode);
        return amount * (config.Tax_Rate__c / 100);
    }
}
```

**Why CMT?**
- Tax rates change per state/jurisdiction
- Business users can update rates without code
- Audit trail of rate changes via deployments
- Cache tax rates in static block (performance)

**Common Fields**:
- State_Code__c
- Tax_Rate__c
- Special_Tax__c
- Effective_Date__c
- Is_Active__c

---

### **3. Feature Flags / Feature Toggles**

**Example: Feature Enablement**
```apex
// CMT: Feature_Flag__mdt
public class FeatureManager {
    public static Boolean isFeatureEnabled(String featureName) {
        try {
            Feature_Flag__mdt flag = [
                SELECT Is_Enabled__c, Start_Date__c, End_Date__c
                FROM Feature_Flag__mdt
                WHERE DeveloperName = :featureName
                LIMIT 1
            ];

            Date today = Date.today();
            return flag.Is_Enabled__c
                && (flag.Start_Date__c == null || today >= flag.Start_Date__c)
                && (flag.End_Date__c == null || today <= flag.End_Date__c);
        } catch (Exception e) {
            return false; // Default to disabled if not found
        }
    }
}

// Usage in LWC or Apex
if (FeatureManager.isFeatureEnabled('Beta_Dashboard')) {
    // Show new beta dashboard
} else {
    // Show classic dashboard
}
```

**Why CMT?**
- Enable/disable features without code deployment
- Gradual rollouts (enable for sandbox, disable in production)
- Time-based feature enablement (holiday promotions)
- A/B testing capabilities

**Common Fields**:
- Feature_Name__c
- Is_Enabled__c
- Start_Date__c
- End_Date__c
- Target_Profiles__c (text area - comma-separated)
- Description__c

---

### **4. Email Template Configuration**

**Example: Dynamic Email Templates**
```apex
// CMT: Email_Template_Config__mdt
public class EmailService {
    public static void sendNotificationEmail(String templateName, Map<String, String> mergeFields) {
        Email_Template_Config__mdt template = [
            SELECT Subject__c, Body__c, From_Address__c, CC_Addresses__c
            FROM Email_Template_Config__mdt
            WHERE DeveloperName = :templateName
            LIMIT 1
        ];

        String subject = template.Subject__c;
        String body = template.Body__c;

        // Merge field replacement
        for (String fieldName : mergeFields.keySet()) {
            String token = '{!' + fieldName + '}';
            subject = subject.replace(token, mergeFields.get(fieldName));
            body = body.replace(token, mergeFields.get(fieldName));
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setToAddresses(new List<String>{ /* recipients */ });
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}
```

**Why CMT?**
- Business users update email content without code
- Different templates per org (sandbox vs production)
- Version controlled email template changes
- No VF email template governor limit issues

**Common Fields**:
- Subject__c
- Body__c (Long Text Area)
- From_Address__c
- CC_Addresses__c
- BCC_Addresses__c
- Is_HTML__c

**CVMA Example**: Used in User Stories #67, #68 for CEB term expiration emails

---

### **5. Mapping Tables / Cross-Reference Data**

**Example: Industry Code Mapping**
```apex
// CMT: Industry_Code_Mapping__mdt
public class IndustryMapper {
    private static Map<String, Industry_Code_Mapping__mdt> mappings;

    static {
        mappings = new Map<String, Industry_Code_Mapping__mdt>();
        for (Industry_Code_Mapping__mdt mapping : [
            SELECT External_Code__c, Salesforce_Value__c, Description__c
            FROM Industry_Code_Mapping__mdt
            WHERE Is_Active__c = true
        ]) {
            mappings.put(mapping.External_Code__c, mapping);
        }
    }

    public static String mapExternalToSalesforce(String externalCode) {
        Industry_Code_Mapping__mdt mapping = mappings.get(externalCode);
        return mapping != null ? mapping.Salesforce_Value__c : 'Other';
    }
}

// Integration scenario
Account acc = new Account();
acc.Industry = IndustryMapper.mapExternalToSalesforce(externalSystem.industryCode);
```

**Why CMT?**
- External system codes differ from Salesforce picklist values
- Mapping rules change over time (no code changes)
- Admin can add new mappings via Setup
- Cached in static block (performance)

**Common Fields**:
- External_Code__c
- Salesforce_Value__c
- Description__c
- Is_Active__c
- Effective_Date__c

---

### **6. Validation Rules / Business Logic**

**Example: Account Validation Configuration**
```apex
// CMT: Validation_Rule__mdt
public class AccountValidator {
    public static Boolean validateAccount(Account acc) {
        List<Validation_Rule__mdt> rules = [
            SELECT Field_Name__c, Operator__c, Value__c, Error_Message__c
            FROM Validation_Rule__mdt
            WHERE Object_Name__c = 'Account'
            AND Is_Active__c = true
        ];

        for (Validation_Rule__mdt rule : rules) {
            Object fieldValue = acc.get(rule.Field_Name__c);

            if (!evaluateRule(fieldValue, rule.Operator__c, rule.Value__c)) {
                throw new ValidationException(rule.Error_Message__c);
            }
        }
        return true;
    }

    private static Boolean evaluateRule(Object fieldValue, String operator, String expectedValue) {
        // Implement operator logic (equals, not equals, greater than, etc.)
    }
}
```

**Why CMT?**
- Validation rules configurable without code
- Different rules per org/sandbox
- Business users define validation criteria
- Complex multi-object validation

**Common Fields**:
- Object_Name__c
- Field_Name__c
- Operator__c (equals, not equals, greater than, etc.)
- Value__c
- Error_Message__c
- Is_Active__c

---

### **7. Picklist Alternatives (Dynamic Values)**

**Example: Custom Picklist Configuration**
```apex
// CMT: Custom_Picklist_Value__mdt
public class PicklistService {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValues(String picklistName) {
        List<Map<String, String>> options = new List<Map<String, String>>();

        for (Custom_Picklist_Value__mdt value : [
            SELECT Label__c, Value__c, Display_Order__c
            FROM Custom_Picklist_Value__mdt
            WHERE Picklist_Name__c = :picklistName
            AND Is_Active__c = true
            ORDER BY Display_Order__c
        ]) {
            options.add(new Map<String, String>{
                'label' => value.Label__c,
                'value' => value.Value__c
            });
        }
        return options;
    }
}
```

**Why CMT?**
- Standard picklists limited to 1000 values
- Picklist values need complex logic (date-based, user-based)
- Values depend on external systems
- Need to share picklist across multiple objects

**Common Fields**:
- Picklist_Name__c
- Label__c
- Value__c
- Display_Order__c
- Is_Active__c
- Start_Date__c
- End_Date__c

---

### **8. Scheduled Job Configuration**

**Example: Batch Job Configuration**
```apex
// CMT: Batch_Job_Config__mdt
public class ConfigurableBatchJob implements Database.Batchable<SObject> {
    private Batch_Job_Config__mdt config;

    public ConfigurableBatchJob(String jobName) {
        this.config = [
            SELECT Batch_Size__c, SOQL_Query__c, Error_Email__c
            FROM Batch_Job_Config__mdt
            WHERE DeveloperName = :jobName
            LIMIT 1
        ];
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(config.SOQL_Query__c);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Process records
    }

    public void finish(Database.BatchableContext bc) {
        // Send completion email to config.Error_Email__c
    }
}

// Schedule with configurable batch size
Batch_Job_Config__mdt config = [SELECT Batch_Size__c FROM Batch_Job_Config__mdt WHERE DeveloperName = 'DailyAccountUpdate' LIMIT 1];
Database.executeBatch(new ConfigurableBatchJob('DailyAccountUpdate'), Integer.valueOf(config.Batch_Size__c));
```

**Why CMT?**
- Batch size tunable without code deployment
- SOQL query adjustable by admins
- Different configs per sandbox/production
- Error notification emails configurable

**Common Fields**:
- Job_Name__c
- Batch_Size__c
- SOQL_Query__c (Long Text Area)
- Error_Email__c
- Schedule_Cron__c
- Is_Active__c

---

## ⚠️ **When NOT to Use CMT**

### **Anti-Pattern Examples**

#### **❌ User-Generated Content**
```apex
// BAD: Using CMT for user transactions
Contact_Form_Submission__mdt // Should be Custom Object
Blog_Post__mdt              // Should be Custom Object
Customer_Feedback__mdt      // Should be Custom Object
```
**Why?** Users create these records dynamically - they need ownership, sharing rules, and real-time creation.

#### **❌ Large Data Volumes**
```apex
// BAD: Using CMT for high-volume data
Product_Inventory__mdt // 10,000+ products - use Custom Object
Historical_Sales__mdt  // Millions of records - use Custom Object
```
**Why?** CMT has practical limits (~10MB per org, ~200 fields per type). Use Custom Objects for large datasets.

#### **❌ Frequently Changing Data**
```apex
// BAD: Using CMT for real-time updates
Current_Stock_Price__mdt    // Changes every second - use Custom Object
User_Session__mdt           // Active user sessions - use Custom Object
Real_Time_Sensor_Data__mdt  // IoT data - use Platform Events or Custom Object
```
**Why?** CMT requires metadata deployment to change. Use Custom Objects for data that changes constantly.

#### **❌ Record-Level Permissions**
```apex
// BAD: Using CMT when you need row-level security
Employee_Salary__mdt        // Sensitive per-person data - use Custom Object with sharing
Customer_Contract__mdt      // Each rep sees own contracts - use Custom Object
```
**Why?** CMT is org-wide accessible (no record-level sharing). Use Custom Objects when you need OWD/sharing rules.

---

## 🎓 **CMT Best Practices**

### **1. Naming Conventions**
```apex
// Good naming
CVMA_Legal_Resource__mdt
API_Configuration__mdt
Feature_Flag__mdt

// Bad naming
Legal__mdt                  // Not specific enough
Data__mdt                   // Too generic
Config123__mdt              // Not descriptive
```

### **2. Field Design**
```apex
// Always include these fields
Is_Active__c               // Checkbox (enable/disable without deleting)
Display_Order__c           // Number (control sort order)
Description__c             // Text Area (document purpose)

// Optional but useful
Effective_Start_Date__c    // Date (when config becomes active)
Effective_End_Date__c      // Date (when config expires)
Created_By__c              // Text (track who created - manual field)
```

### **3. Query Optimization**
```apex
// Good: Cache CMT in static context
public class ConfigService {
    private static Map<String, API_Configuration__mdt> apiConfigs;

    static {
        apiConfigs = new Map<String, API_Configuration__mdt>();
        for (API_Configuration__mdt config : [SELECT ...]) {
            apiConfigs.put(config.DeveloperName, config);
        }
    }

    public static API_Configuration__mdt getConfig(String name) {
        return apiConfigs.get(name); // No SOQL in loop
    }
}

// Bad: Query CMT repeatedly
public static void processRecords(List<Account> accounts) {
    for (Account acc : accounts) {
        API_Configuration__mdt config = [SELECT ... WHERE DeveloperName = 'MyAPI'];
        // Query in loop - bad performance
    }
}
```

### **4. Error Handling**
```apex
// Good: Graceful fallback
public static String getConfigValue(String configName, String defaultValue) {
    try {
        My_Config__mdt config = [
            SELECT Value__c
            FROM My_Config__mdt
            WHERE DeveloperName = :configName
            LIMIT 1
        ];
        return config.Value__c;
    } catch (Exception e) {
        System.debug('Config not found: ' + configName + ', using default: ' + defaultValue);
        return defaultValue;
    }
}

// Bad: No error handling
public static String getConfigValue(String configName) {
    My_Config__mdt config = [SELECT Value__c FROM My_Config__mdt WHERE DeveloperName = :configName LIMIT 1];
    return config.Value__c; // Crashes if not found
}
```

### **5. Testing**
```apex
// Good: Test with actual CMT records (no mocking needed)
@IsTest
static void testAPIConfiguration() {
    // CMT records exist in all environments
    API_Configuration__mdt config = [
        SELECT Endpoint_URL__c, Timeout__c
        FROM API_Configuration__mdt
        WHERE DeveloperName = 'Test_API'
        LIMIT 1
    ];

    System.assertNotEquals(null, config, 'Test API config should exist');
    System.assert(config.Timeout__c > 0, 'Timeout should be positive');
}

// Note: You can't INSERT/UPDATE/DELETE CMT in tests - deploy test records as metadata
```

---

## 📚 **CMT Decision Tree**

```
Is this data created by end users during normal operations?
├─ YES → Use Custom Object
└─ NO → Continue
    │
    Does this data change frequently (daily/hourly)?
    ├─ YES → Use Custom Object
    └─ NO → Continue
        │
        Do you need record-level security (sharing rules)?
        ├─ YES → Use Custom Object
        └─ NO → Continue
            │
            Is this configuration data that defines app behavior?
            ├─ YES → Use Custom Metadata Type ✅
            └─ NO → Consider Custom Settings or Custom Objects
```

---

## 🔧 **CVMA Project Summary**

### **Custom Metadata Types in Use**
1. **CVMA_Legal_Resource__mdt** - User Story #75 (5 records)
2. **CVMA_Career_Resource__mdt** - User Story #73 (8 records)
3. **CVMA_Housing_Financial_Resource__mdt** - User Story #74 (9 records)
4. **CVMA_Email_Template__mdt** - User Stories #67, #68 (CEB term tracking emails)
5. **CVMA_Application_Config__mdt** - General app settings (existing)

**Total**: 22 veteran resource records + email templates + app config

### **Custom Objects in Use**
1. **Contact** - Extended with CEB fields (User Stories #66-68)
2. **Region__c** - CVMA regional structure (User Story #66)
3. **State_Organization__c** - State-level governance (User Story #66)
4. **Veteran_Assistance_Request__c** - Coming in User Story #76 (transactional)

### **Architecture Pattern**
- **CMT for Reference Data**: Veteran resources, email templates, app settings
- **Custom Objects for Transactions**: Assistance requests, member records, organizational hierarchy

---

## 🎯 **Key Takeaways**

1. **CMT = Configuration** (how your app works)
2. **Custom Objects = Business Data** (what your app does)
3. **CMT Benefits**: Deployable, cacheable, no security checks, admin-friendly
4. **Custom Objects Benefits**: User ownership, sharing rules, reporting, workflows
5. **Use Both**: CMT for reference data, Custom Objects for transactions

---

**Document Created**: October 21, 2025
**Author**: CVMA Development Team
**Purpose**: Developer education on Custom Metadata Types
**Related User Stories**: #73, #74, #75, #76

🎖️ Combat Veterans Motorcycle Association Chapter 20-7
