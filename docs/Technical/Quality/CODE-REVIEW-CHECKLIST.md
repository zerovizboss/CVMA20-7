# Code Review Checklist - CVMA Chapter 20-7
**Combat Veterans Motorcycle Association**
**Salesforce Development Quality Standards**

## 📋 **Checklist Purpose**

This checklist ensures consistent code quality, security compliance, and maintainability across all CVMA Salesforce development. Use this for:
- Pre-commit self-review (developer validates own code)
- Peer code review (another developer reviews pull request)
- Deployment readiness validation (before production deployment)

**Target Audience:** Salesforce Developers, Technical Leads, DevOps Engineers

---

## ✅ **1. Security & Permissions**

### **SOQL Security:**
- [ ] All custom SOQL queries include `WITH SECURITY_ENFORCED`
- [ ] No dynamic SOQL with string concatenation (use bind variables)
- [ ] CRUD/FLS validation via `CVMAErrorHandler.validateCRUDPermissions()` before data operations
- [ ] No hardcoded SOQL queries bypassing security (all queries respect user permissions)

**Example:**
```apex
// ✅ GOOD
List<Contact> contacts = [
    SELECT Id, Name, Email
    FROM Contact
    WHERE Status__c = 'Active'
    WITH SECURITY_ENFORCED
    LIMIT 10
];

// ❌ BAD
String query = 'SELECT Id FROM Contact WHERE Name = \'' + userName + '\'';
List<Contact> contacts = Database.query(query);
```

---

### **Input Sanitization:**
- [ ] All user inputs sanitized via `CVMAErrorHandler.sanitizeInput()`
- [ ] No direct string concatenation of user input into queries
- [ ] XSS prevention in Lightning Web Components (use `{!expression}` or `@api`)
- [ ] File upload validation (file type, size limits)

**Example:**
```apex
// ✅ GOOD
String sanitizedSearch = CVMAErrorHandler.sanitizeInput(searchTerm);
List<Contact> results = [
    SELECT Id, Name
    FROM Contact
    WHERE Name LIKE :('%' + sanitizedSearch + '%')
    WITH SECURITY_ENFORCED
];

// ❌ BAD
List<Contact> results = [
    SELECT Id, Name
    FROM Contact
    WHERE Name LIKE :('%' + searchTerm + '%')
];
```

---

### **Sharing & Visibility:**
- [ ] Controllers use `with sharing` keyword (unless explicit business requirement for `without sharing`)
- [ ] Guest user profile permissions validated (no sensitive data exposure)
- [ ] Permission set assignments follow least-privilege principle
- [ ] Object-level and field-level security configured correctly

---

## 🧪 **2. Test Coverage & Quality**

### **Test Class Standards:**
- [ ] Test class exists for every Apex class (1:1 ratio)
- [ ] Test class name follows convention: `[ClassName]Test.cls`
- [ ] `@IsTest` annotation present on test class
- [ ] All test methods use `@IsTest` annotation (not `testMethod`)
- [ ] Test coverage >90% for all classes (target: 95%+)

**Example:**
```apex
// ✅ GOOD
@IsTest
public class CVMAMemberProfileControllerTest {
    @IsTest
    static void testGetMemberProfile() {
        // Test implementation
    }
}

// ❌ BAD
public class TestCVMAMemberProfile { // Missing @IsTest
    static testMethod void testProfile() { // Old testMethod syntax
        // Test implementation
    }
}
```

---

### **Test Data Management:**
- [ ] All test data created via `CVMATestDataFactory` (no hardcoded data)
- [ ] `Test.startTest()` and `Test.stopTest()` used to reset governor limits
- [ ] `System.runAs()` used to test different user contexts
- [ ] Negative test cases included (test error handling)
- [ ] Bulk operation tests (test with 200+ records)

**Example:**
```apex
// ✅ GOOD
@IsTest
static void testBulkInsert() {
    List<Contact> contacts = CVMATestDataFactory.createContacts(200);

    Test.startTest();
    insert contacts;
    Test.stopTest();

    List<Contact> inserted = [SELECT Id FROM Contact];
    System.assertEquals(200, inserted.size(), 'Should insert 200 contacts');
}

// ❌ BAD
@IsTest
static void testInsert() {
    Contact c = new Contact(FirstName='Test', LastName='User'); // Hardcoded
    insert c; // No governor limit reset
    // No assertions
}
```

---

### **Assertions & Validation:**
- [ ] Every test method includes `System.assert*()` statements
- [ ] Assertions validate expected behavior (not just code execution)
- [ ] Exception handling tested (try/catch with expected exceptions)
- [ ] Edge cases tested (null values, empty lists, boundary conditions)

---

## 🏗️ **3. Code Structure & Maintainability**

### **Naming Conventions:**
- [ ] Apex classes start with `CVMA` prefix (e.g., `CVMAMemberController`)
- [ ] Lightning Web Components start with `cvma` prefix (e.g., `cvmaMemberProfile`)
- [ ] Variables use camelCase (e.g., `memberCount`, `totalRevenue`)
- [ ] Constants use UPPER_SNAKE_CASE (e.g., `MAX_QUERY_LIMIT`, `DEFAULT_STATUS`)
- [ ] Methods use descriptive names (verb + noun: `getMemberProfile`, `validatePermissions`)

**Example:**
```apex
// ✅ GOOD
public class CVMAEventController {
    private static final Integer MAX_EVENTS = 50;

    public static List<Campaign> getUpcomingEvents() {
        // Implementation
    }
}

// ❌ BAD
public class EventCtrl { // Missing CVMA prefix
    private static final integer maxevents = 50; // Wrong casing

    public static List<Campaign> getEvents() { // Vague method name
        // Implementation
    }
}
```

---

### **Code Organization:**
- [ ] Classes have single responsibility (one purpose per class)
- [ ] Methods are concise (<50 lines each)
- [ ] No duplicate code (use helper methods for repeated logic)
- [ ] Constants defined at class level (not scattered in methods)
- [ ] Utility classes marked `public class` with private constructor

**Example:**
```apex
// ✅ GOOD - Utility class pattern
public class CVMAStringUtils {
    private CVMAStringUtils() {
        // Private constructor prevents instantiation
    }

    public static String capitalizeFirstLetter(String input) {
        return String.isBlank(input) ? '' : input.capitalize();
    }
}

// ❌ BAD - Instantiable utility class
public class StringUtils {
    public String capitalize(String input) { // Should be static
        return input.capitalize();
    }
}
```

---

### **Comments & Documentation:**
- [ ] Class-level Javadoc comment (purpose, author, version)
- [ ] Public method Javadoc comments (`@param`, `@return`, `@throws`)
- [ ] Complex logic explained with inline comments
- [ ] TODO/FIXME comments include ticket reference (e.g., `// TODO: GitHub #123`)
- [ ] No commented-out code (delete or use version control)

**Example:**
```apex
/**
 * Controller for CVMA Member Profile management
 * Handles member data retrieval and updates with security enforcement
 * @author CVMA Development Team
 * @version 2.0
 */
public with sharing class CVMAMemberProfileController {

    /**
     * Retrieve member profile data for current user
     * @return MemberProfileData Wrapper with user and contact information
     * @throws SecurityException if user lacks read permissions
     */
    @AuraEnabled(cacheable=true)
    public static MemberProfileData getMemberProfile() {
        // Implementation
    }
}
```

---

## ⚡ **4. Performance & Governor Limits**

### **Query Optimization:**
- [ ] SOQL queries outside loops (no queries in for-each loops)
- [ ] Selective queries (use indexed fields in WHERE clause when possible)
- [ ] LIMIT clause on all queries (prevent full table scans)
- [ ] Aggregate queries used instead of iterating collections
- [ ] Parent-child queries minimize query count (1 query vs N+1)

**Example:**
```apex
// ✅ GOOD
List<Contact> contacts = [
    SELECT Id, Name, (SELECT Id FROM Opportunities)
    FROM Contact
    WHERE LastModifiedDate = LAST_N_DAYS:30
    LIMIT 200
];

for (Contact c : contacts) {
    // Process contact and related opportunities
}

// ❌ BAD
List<Contact> contacts = [SELECT Id FROM Contact]; // No LIMIT

for (Contact c : contacts) {
    List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE ContactId = :c.Id]; // Query in loop
}
```

---

### **Bulk Operations:**
- [ ] Collections used for DML (no single-record DML in loops)
- [ ] Batch size considerations (max 200 records per DML statement)
- [ ] Exception handling for partial failures (`Database.insert(records, false)`)
- [ ] Trigger bulkification (no SOQL/DML in trigger loops)

**Example:**
```apex
// ✅ GOOD
List<Contact> contactsToUpdate = new List<Contact>();

for (Contact c : contacts) {
    c.Status__c = 'Active';
    contactsToUpdate.add(c);
}

update contactsToUpdate; // Bulk DML outside loop

// ❌ BAD
for (Contact c : contacts) {
    c.Status__c = 'Active';
    update c; // DML in loop - hits governor limits
}
```

---

### **Governor Limit Protection:**
- [ ] No infinite loops or recursion (use static variables to prevent)
- [ ] Large data sets processed via Batch Apex or Queueable
- [ ] Email sending respects daily limits (single email per method)
- [ ] CPU time monitored for complex calculations

---

## 🎨 **5. Lightning Web Components**

### **LWC Structure:**
- [ ] Component name starts with `cvma` (e.g., `cvmaMemberProfile`)
- [ ] Component folder contains: `.js`, `.html`, `.js-meta.xml`, `.css` (if needed)
- [ ] `@api` properties documented in JS file
- [ ] `@wire` used for cacheable data (not imperative calls)
- [ ] Error handling in all `@wire` and imperative Apex calls

**Example:**
```javascript
// ✅ GOOD - cvmaMemberProfile.js
import { LightningElement, api, wire } from 'lwc';
import getMemberProfile from '@salesforce/apex/CVMAMemberProfileController.getMemberProfile';

export default class CvmaMemberProfile extends LightningElement {
    @api recordId;
    memberData;
    error;

    @wire(getMemberProfile)
    wiredProfile({ error, data }) {
        if (data) {
            this.memberData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.memberData = undefined;
        }
    }
}
```

---

### **LWC Best Practices:**
- [ ] Accessibility attributes included (`aria-label`, `role`, etc.)
- [ ] CSS scoped to component (no global CSS pollution)
- [ ] Lightning Design System (SLDS) used for styling
- [ ] `if:true` and `for:each` used correctly in templates
- [ ] Component documented in `.js-meta.xml` (description, targets)

---

## 📦 **6. Deployment Readiness**

### **Pre-Deployment Validation:**
- [ ] All tests pass locally (run `sf apex run test --test-level RunLocalTests`)
- [ ] Pre-commit hooks pass (ggshield secret scan, linters, etc.)
- [ ] Code review completed (peer approval on pull request)
- [ ] Deployment runbook created (for manual steps if applicable)
- [ ] User guide/documentation updated (if new feature)

---

### **Metadata Quality:**
- [ ] All metadata files have corresponding `-meta.xml` files
- [ ] `package.xml` updated (includes all new components)
- [ ] No hardcoded org-specific values (use custom metadata or settings)
- [ ] API version consistent across components (current: 60.0)
- [ ] Managed package dependencies declared (NPSP, etc.)

**Example:**
```xml
<!-- ✅ GOOD - CVMAMemberController.cls-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>60.0</apiVersion>
    <status>Active</status>
</ApexClass>

<!-- ❌ BAD - Missing -meta.xml file or wrong API version -->
```

---

### **Documentation Requirements:**
- [ ] Implementation guide created (for new features)
- [ ] User guide created (for member-facing features)
- [ ] Troubleshooting section included (common issues + resolutions)
- [ ] GitHub issue updated (deployment status, validation notes)
- [ ] NEXT-SESSION priorities updated (if blockers or follow-up needed)

---

## 🚨 **7. Error Handling**

### **Exception Management:**
- [ ] All exceptions caught and handled (no silent failures)
- [ ] `CVMAErrorHandler.handleException()` used for logging
- [ ] User-friendly error messages displayed (not technical stack traces)
- [ ] Critical errors logged to `CVMA_Error_Log__c` object
- [ ] Email alerts sent for critical failures (if applicable)

**Example:**
```apex
// ✅ GOOD
try {
    List<Contact> contacts = [SELECT Id FROM Contact WITH SECURITY_ENFORCED];
    update contacts;
} catch (DmlException e) {
    CVMAErrorHandler.handleException(
        e,
        'CVMAMemberController',
        'updateMembers',
        CVMAErrorHandler.ErrorSeverity.HIGH
    );
    throw new AuraHandledException('Unable to update members. Please contact support.');
}

// ❌ BAD
try {
    List<Contact> contacts = [SELECT Id FROM Contact];
    update contacts;
} catch (Exception e) {
    // Silent failure - error not logged
}
```

---

### **Validation & User Feedback:**
- [ ] Input validation before processing (null checks, type validation)
- [ ] Business logic validation (dues paid before renewal, etc.)
- [ ] Success messages displayed to users (`AuraHandledException` for LWC)
- [ ] Partial success handling (some records succeeded, some failed)

---

## 📊 **8. Standard Feature Integration Validation**

### **Pre-Development Check:**
- [ ] Native Salesforce feature evaluated before custom code
- [ ] NPSP functionality leveraged (for financial features)
- [ ] Campaign Member used (for event RSVP tracking)
- [ ] Lightning Calendar used (for event displays)
- [ ] Knowledge Articles used (for document management)

**Standard Feature Integration Checklist:**
- [ ] Code reduction target: 80%+ (vs full custom implementation)
- [ ] Business requirements met with standard features
- [ ] Custom code only for CVMA-specific logic (not generic functionality)
- [ ] Configuration-driven (custom metadata, settings) where possible

---

## ✅ **9. Pre-Commit Checklist (Developer Self-Review)**

**Before committing code, verify:**
- [ ] **Security:** All SOQL with `WITH SECURITY_ENFORCED`, input sanitized
- [ ] **Tests:** Test class exists, >90% coverage, all tests pass
- [ ] **Naming:** Classes/methods follow CVMA naming conventions
- [ ] **Comments:** Class and public methods documented
- [ ] **Performance:** No queries in loops, bulk DML used
- [ ] **Error Handling:** Exceptions caught and logged via CVMAErrorHandler
- [ ] **Linting:** No compiler warnings, code formatted consistently
- [ ] **Pre-Commit Hooks:** ggshield secret scan passes

**Command to run all tests:**
```bash
sf apex run test --test-level RunLocalTests --result-format human
```

---

## 🔍 **10. Peer Code Review Checklist**

**Reviewer validates:**
- [ ] **Business Logic:** Code meets acceptance criteria from user story
- [ ] **Security:** WITH SECURITY_ENFORCED, CRUD/FLS validation, input sanitization
- [ ] **Test Quality:** Tests cover edge cases, assertions validate behavior
- [ ] **Code Clarity:** Readable, well-commented, follows conventions
- [ ] **Performance:** No obvious governor limit violations
- [ ] **Error Handling:** Exceptions properly caught and logged
- [ ] **Documentation:** Implementation guide or user guide created

**Reviewer approval required before merge to main branch.**

---

## 📋 **11. Deployment Validation Checklist**

**Before deploying to production:**
- [ ] **All tests pass** in sandbox (Run all tests, verify >75% org coverage)
- [ ] **Code review approved** by peer developer
- [ ] **Security scan passed** (ggshield, Salesforce security scanner)
- [ ] **Deployment runbook created** (if manual steps required)
- [ ] **User guides created** (for member-facing features)
- [ ] **CEB approval obtained** (if feature requires business decision)
- [ ] **Backup created** (metadata backup before deployment)
- [ ] **Rollback plan documented** (how to revert if deployment fails)

**Deployment Command:**
```bash
sf project deploy start --source-dir src/ --test-level RunLocalTests --target-org cvma
```

---

## 🎯 **12. Epic Completion Checklist (Zero Tech Debt)**

**Before closing Epic:**
- [ ] **All user stories deployed** (100% Epic completion)
- [ ] **All GitHub issues closed** (no open issues for Epic)
- [ ] **Implementation guides created** (for each user story)
- [ ] **Deployment runbooks created** (for manual setup tasks)
- [ ] **Technical troubleshooting guide created** (Epic-wide common issues)
- [ ] **Business impact metrics documented** (code reduction, time savings)
- [ ] **Tech debt addressed** (zero outstanding tech debt items)
- [ ] **Epic completion summary created** (GitHub issue documenting 100% status)

**Epic Closure Protocol:**
Per user requirement: "Ensure all Epic Issues generated during development are not only recorded and tracked on the board, but are also addressed before we close out the Epic. This ensures maximum cleanliness and reduces the Tech Debt load from getting out of control."

---

## 💡 **13. Quick Reference: Common Violations**

### **Security:**
❌ Missing `WITH SECURITY_ENFORCED` in SOQL
❌ Hardcoded credentials or API keys
❌ User input not sanitized before use
❌ Controller using `without sharing` without justification

### **Testing:**
❌ Test class missing for Apex class
❌ Test coverage <90%
❌ No assertions in test method
❌ Hardcoded test data (not using CVMATestDataFactory)

### **Performance:**
❌ SOQL query inside for-loop
❌ DML operation inside for-loop
❌ No LIMIT clause on SOQL query
❌ Full table scan (WHERE clause on non-indexed field)

### **Code Quality:**
❌ Class name doesn't start with `CVMA`
❌ No Javadoc comment on public method
❌ Method >100 lines long
❌ Duplicate code (copy/paste instead of helper method)

---

## 📞 **Support & Questions**

**Code Review Questions:**
- Technical Lead: detonator@cvma20-7.org
- Peer Developers: (internal Slack/Chatter)

**Quality Standards:**
- Salesforce Apex Style Guide: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta
- Lightning Web Components Best Practices: https://developer.salesforce.com/docs/component-library/documentation/lwc

**Pre-Commit Hooks:**
- Hook configuration: `.pre-commit-config.yaml`
- GitGuardian docs: https://docs.gitguardian.com

---

🎖️ **Generated with [Claude Code](https://claude.com/claude-code)**
**Date:** October 6, 2025
**Version:** 1.0
**For:** CVMA Chapter 20-7 Salesforce Development Team
**Next Review:** January 2026 (quarterly review recommended)
