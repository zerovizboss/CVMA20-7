# Epic #4: CVMA Bylaws Compliance - Technical Troubleshooting Guide
**Combat Veterans Motorcycle Association Chapter 20-7**

## 📋 **Epic Overview**

**Epic Status:** ✅ 100% COMPLETE (4/4 User Stories Deployed)
**Deployment Dates:** September 30 - October 2, 2025
**National Bylaws Coverage:** Article VII (Chain of Command), Article XIV.03 (CEB Responsibilities), Appendix C (Discipline)

---

## 🎯 **Deployed User Stories**

1. **User Story #66** - Chain of Command Data Model (Region/State hierarchy)
2. **User Story #67** - CEB Term Tracking & Election Deadline Alerts
3. **User Story #68 Phase 2** - Disciplinary System Integration (Administrative Hold automation)
4. **User Story #60** - CEB Dashboard Implementation (Role-specific analytics)

---

## 🚨 **Common Issues Across Epic #4**

### **Category 1: Permission and Access Issues**

#### **Issue: CEB Officer Cannot See Dashboard/Reports**
**Symptoms:**
- Dashboard widgets show "Insufficient Privileges" error
- Reports return no data despite records existing
- CEB officer cannot edit Contact records

**Root Causes:**
1. Permission set not assigned to user
2. Dashboard folder sharing not configured
3. Report folder permissions insufficient
4. User profile lacks base access to objects

**Resolution Steps:**
1. Verify permission set assignment:
   - **Setup** → Search user name
   - Click user → **Permission Set Assignments**
   - Confirm appropriate permission set assigned:
     - Commander: `CVMA_Commander_Access`
     - Treasurer: `CVMA_Treasurer_Access`
     - Secretary: `CVMA_Secretary_Access`
     - State Rep: `CVMA_StateRepresentative_Access`
     - Regional Rep: `CVMA_RegionRepresentative_Access`

2. Verify dashboard folder sharing:
   - **Dashboards** tab → Find dashboard folder
   - Click **Share** → Verify user/group has Viewer or Manager access
   - If missing, add user with appropriate access level

3. Check report folder permissions:
   - **Reports** tab → Find report folder (e.g., "CEB Reports")
   - Click **Share** → Add user with Viewer access

4. Validate user license:
   - User must have Customer Community Plus or Salesforce Platform license
   - Guest users cannot access CEB dashboards (intentional restriction)

**Prevention:**
- Create onboarding checklist for new CEB officers
- Document permission set assignment process
- Automate permission set assignment via Flow when `CEB_Position__c` populated

---

#### **Issue: Guest User Can Access CEB-Restricted Content**
**Symptoms:**
- Guest user sees financial data on public pages
- Guest user can view CEB officer information
- Security policy violation

**Root Causes:**
1. Guest user profile has excessive object permissions
2. Sharing rules too permissive
3. Component-level security not enforced
4. Lightning Web Component missing security checks

**Resolution Steps:**
1. Audit guest user profile:
   - **Setup** → **Profiles** → **[Site Name] Profile**
   - **Object Settings** → Verify Contact, Opportunity, Campaign permissions = Read ONLY (or none)
   - Remove Create, Edit, Delete permissions

2. Review sharing rules:
   - **Setup** → **Sharing Settings** → Verify Organization-Wide Defaults:
     - Contact: Private (or Public Read Only with criteria-based restrictions)
     - Opportunity: Private
     - Campaign: Public Read Only (safe for events)

3. Check component visibility rules:
   - **Experience Builder** → Select site → Edit page with sensitive component
   - Click component → **Properties** → **Visibility**
   - Set **Audience:** CEB Officers (permission set-based audience)

4. Validate LWC security:
   - Review Lightning Web Component Apex controllers
   - Ensure all SOQL queries use `WITH SECURITY_ENFORCED`
   - Example from `CVMAMemberProfileControllerSecure.cls`:
     ```apex
     List<Contact> contacts = [
         SELECT Id, FirstName, LastName, Email, CEB_Position__c
         FROM Contact
         WHERE Id = :contactId
         WITH SECURITY_ENFORCED
         LIMIT 1
     ];
     ```

**Prevention:**
- Annual guest user profile audit
- Security scan pre-commit hooks (ggshield)
- Code review checklist for WITH SECURITY_ENFORCED

---

### **Category 2: Flow and Automation Issues**

#### **Issue: Scheduled Flow Not Sending Alerts**
**Symptoms:**
- No email alerts received at 90/60/30-day deadlines (User Story #67)
- No 75-day or 90-day Administrative Hold alerts (User Story #68)
- Flow run history shows 0 records processed

**Root Causes:**
1. Flow inactive (not activated after deployment)
2. Schedule configuration incorrect
3. Entry conditions too restrictive (no records match)
4. Email deliverability disabled

**Resolution Steps:**
1. Verify flow active status:
   - **Setup** → **Flows** → Search flow name
   - Check status badge = **Active** (green)
   - If inactive, click **Activate**

2. Check scheduled flow configuration:
   - Open flow → Click **Configure Start**
   - Verify **Frequency:** Daily
   - Verify **Time:** 6:00 AM (or preferred time)
   - Verify **Start Date:** Past or today
   - Verify **End Date:** Blank (runs indefinitely)

3. Review entry conditions:
   - Flow entry conditions must match real data
   - Example for CEB Term Tracking:
     - `CEB_Position__c` IS NOT BLANK
     - `CEB_Term_End__c` IS NOT BLANK
   - Create test Contact record matching exact conditions
   - Run flow debug to verify record selected

4. Check email deliverability:
   - **Setup** → **Email Administration** → **Deliverability**
   - Access Level = **All Email** (not "System email only")
   - If "No access", change to "All Email" and save

5. Review run history for errors:
   - **Setup** → **Flows** → Flow name → **Run History** tab
   - Check **Status** column: Success, Failed, or No Records Processed
   - Click failed run → Review error message
   - Common error: "FIELD_CUSTOM_VALIDATION_EXCEPTION" - validation rule blocking update

**Debug Test Procedure:**
1. Create test Contact with exact entry condition values:
   - User Story #67: `CEB_Term_End__c` = TODAY + 90, `Election_Due_Date__c` = TODAY
   - User Story #68: `Administrative_Hold_Start_Date__c` = TODAY - 75, `Administrative_Hold_End_Date__c` = TODAY + 15

2. Navigate to flow → Click **Debug**
3. Select test Contact record
4. Click **Run**
5. Review **Debug Details** → Verify email action executed
6. Check recipient inbox (including spam folder)

**Prevention:**
- Monthly flow health check (review run history)
- Test data creation script for CEB officers
- Monitoring dashboard for flow failures

---

#### **Issue: Email Sent But Merge Fields Blank**
**Symptoms:**
- Email received but {!Contact.FirstName} shows as blank
- Email template renders incorrectly
- Recipient receives generic message instead of personalized

**Root Causes:**
1. Merge field references incorrect object
2. Contact record missing required field values
3. Email template not saved correctly
4. Flow passing wrong variable to email action

**Resolution Steps:**
1. Verify email template merge fields:
   - **Setup** → **Email Templates** → Search template name
   - Click **Edit**
   - Review merge field syntax: `{!Contact.FieldName}` (exact API name required)
   - Click **Preview** → Select test Contact → Verify fields populate

2. Check Contact record data:
   - Open test Contact record
   - Verify all fields referenced in email template have values
   - Example: If email uses `{!Contact.CEB_Position__c}`, verify field populated

3. Review flow email action:
   - Open flow → Find "Send Email" action element
   - Check **Recipient** field: Should use `{!$Record.Email}` or specific Contact email field
   - Check **Record ID for Merge Fields**: Should pass Contact record ID
   - Verify email template selected correctly

4. Test with debug:
   - Run flow debug with test Contact
   - Review email action output in debug log
   - If merge fields still blank, recreate email action element in flow

**Prevention:**
- Email template validation checklist
- Merge field testing before activation
- Standard naming convention for email templates (CVMA_[Feature]_[Type])

---

### **Category 3: Formula Field and Validation Issues**

#### **Issue: Formula Field Showing #ERROR! or Blank**
**Symptoms:**
- `Administrative_Hold_End_Date__c` shows #ERROR!
- `Election_Due_Date__c` displays blank despite term dates populated
- `Days_Until_Election__c` returns incorrect calculation

**Root Causes:**
1. Referenced field blank (formula source data missing)
2. Formula syntax error
3. Data type mismatch
4. Circular reference

**Resolution Steps:**
1. Identify formula field with error:
   - Open Contact record
   - Hover over #ERROR! field → Click details icon
   - Note error message (e.g., "Field Administrative_Hold_Start_Date__c is blank")

2. Check formula source fields:
   - Edit Contact → Verify all fields referenced in formula have values
   - Example for `Administrative_Hold_End_Date__c`:
     - Formula: `Administrative_Hold_Start_Date__c + 90`
     - Required: `Administrative_Hold_Start_Date__c` must have date value

3. Validate formula syntax:
   - **Setup** → **Object Manager** → **Contact** → **Fields & Relationships**
   - Click formula field name → Click **Edit**
   - Review **Formula** editor for syntax errors
   - Common errors:
     - Missing closing parenthesis
     - Incorrect field API name (case-sensitive)
     - Data type mismatch (adding Text to Number)

4. Test formula with sample data:
   - Click **Check Syntax** in formula editor
   - Save formula
   - Create test Contact with valid source field values
   - Verify formula calculates correctly

5. Check for circular references:
   - Formula field cannot reference itself or create dependency loop
   - Example: Field A references Field B, Field B references Field A = circular
   - Review all formula fields in dependency chain

**Prevention:**
- Always populate source fields before expecting formula results
- Validation rules to enforce required source fields
- Unit tests for formula calculations

---

#### **Issue: Validation Rule Blocking Legitimate Data Entry**
**Symptoms:**
- Error: "Administrative Hold Start Date is required when Disciplinary Action Status is 'Administrative Hold'"
- Cannot save Contact record despite fields correctly filled
- Validation rule prevents legitimate use case

**Root Causes:**
1. Required field not populated
2. Validation rule logic too restrictive
3. Bulk data load missing required fields
4. User confusion about validation rule requirements

**Resolution Steps:**
1. Read validation rule error message carefully:
   - Error message provides exact requirement
   - Example: "Administrative Hold Start Date is required"
   - Action: Populate `Administrative_Hold_Start_Date__c` field before saving

2. Review validation rule logic:
   - **Setup** → **Object Manager** → **Contact** → **Validation Rules**
   - Find validation rule by error message
   - Click **Edit** → Review **Error Condition Formula**
   - Example for `Administrative_Hold_Requires_Start_Date`:
     ```
     AND(
       ISPICKVAL(Disciplinary_Action_Status__c, "Administrative Hold"),
       ISBLANK(Administrative_Hold_Start_Date__c)
     )
     ```
   - **Translation:** If status = "Administrative Hold" AND start date is blank, show error

3. Populate required fields:
   - Edit Contact → Fill in all required fields per validation rule
   - Save record → Validation rule should pass

4. If validation rule incorrect:
   - Deactivate validation rule temporarily
   - Create test data
   - Update validation rule logic
   - Reactivate with corrected formula

**Prevention:**
- Clear field labels with help text explaining requirements
- User training on validation rule requirements
- Data import templates with required field columns highlighted

---

### **Category 4: Data Model and Lookup Issues**

#### **Issue: Cannot Select Lookup Value (Committee Chair, POC, Region, etc.)**
**Symptoms:**
- Lookup search returns no results
- Correct Contact/Region exists but not selectable
- "No records found" message in lookup dialog

**Root Causes:**
1. Lookup filter too restrictive
2. Required fields missing on target record
3. Record sharing/visibility issue
4. Lookup search not indexing correctly

**Resolution Steps:**
1. Verify lookup filter configuration:
   - **Setup** → **Object Manager** → **Contact** → **Fields & Relationships**
   - Click lookup field (e.g., `Committee_Chair__c`)
   - Scroll to **Lookup Filter** section
   - Check filter criteria:
     - Example: "CEB Position IS NOT BLANK" - target Contact must have CEB_Position__c value
   - If filter too restrictive, edit or remove

2. Check target record visibility:
   - Search for target Contact/Region record directly
   - Verify record exists and accessible to user
   - Check sharing rules: **Setup** → **Sharing Settings**
   - If user cannot see record, lookup won't show it

3. Validate target record required fields:
   - Open target Contact record
   - Verify record has name/title field populated
   - Verify record meets lookup filter criteria

4. Re-index lookup search (if recently created):
   - Wait 15 minutes for new records to appear in lookup search
   - Refresh browser cache
   - Try lookup search again

5. Test lookup as different user:
   - Login as System Administrator
   - Attempt lookup → If visible, issue is permission-based
   - Review user profile and permission sets

**Prevention:**
- Document lookup filter requirements
- Validation rules to enforce lookup filter criteria
- Sharing rule audit for CEB officer visibility

---

#### **Issue: Region/State Organization Hierarchy Broken**
**Symptoms:**
- Contact record shows Region but not State Organization
- State Organization record missing Region assignment
- Reports show incorrect hierarchy rollups

**Root Causes:**
1. Master-detail relationship broken (State_Organization__c → Region__c)
2. Region lookup on Contact not populated
3. Data migration incomplete
4. Cascading delete removed parent records

**Resolution Steps:**
1. Verify State Organization → Region relationship:
   - Open State Organization record (e.g., "Florida")
   - Check **Region** field = Southeast Region (or appropriate region)
   - If blank, edit and assign correct Region

2. Verify Contact → State Organization relationship:
   - Open Contact record
   - Check **State Organization** field = Florida (or appropriate state)
   - Check **Region** field = Southeast Region (should match State Organization's Region)
   - If mismatched, update Contact to correct State Organization

3. Validate master-detail relationship:
   - **Setup** → **Object Manager** → **State_Organization__c** → **Fields & Relationships**
   - Click **Region__c** field
   - Verify **Field Type** = Master-Detail Relationship
   - Verify **Related To** = Region__c
   - If incorrect, cannot edit (master-detail cannot be changed) - data migration required

4. Bulk data fix (if many records):
   - Export all Contact records with Region and State Organization
   - Export all State Organization records
   - Use VLOOKUP to match State Organization → Region
   - Update Contact.State_Organization__c to match Contact.Region__c
   - Use Data Loader to update

**Prevention:**
- Validation rules to enforce Region/State alignment
- Data import templates with hierarchy validation
- Quarterly data audit reports

---

### **Category 5: Dashboard and Reporting Issues**

#### **Issue: Dashboard Widget Shows "No Data" Despite Records Existing**
**Symptoms:**
- Dashboard widget displays "No data to display"
- Records exist when searched manually
- Report shows data but dashboard widget blank

**Root Causes:**
1. Report filter too restrictive
2. Dashboard filter applied
3. Report folder permission insufficient
4. Dashboard not refreshed after data change

**Resolution Steps:**
1. Verify underlying report:
   - Click dashboard widget → View report
   - Check report results → If blank, report filter issue
   - If report shows data, issue is dashboard configuration

2. Check report filters:
   - Edit report → Review **Filters** panel
   - Common issues:
     - Date range too narrow (e.g., "Last 7 Days" but data older)
     - Status filter excluding active records (e.g., "Status = Closed" when looking for active)
     - Owner filter excluding current user
   - Broaden filters to test (e.g., "All Time" date range)

3. Review dashboard filters:
   - Open dashboard → Check top filter bar
   - Clear all dashboard-level filters
   - Refresh dashboard → If data appears, filter was too restrictive

4. Validate report folder permissions:
   - **Reports** tab → Find report
   - Click **Share** → Verify dashboard viewer has access
   - If missing, add user/group with Viewer permission

5. Refresh dashboard:
   - Open dashboard → Click **Refresh** button (circular arrow)
   - Wait for all widgets to reload
   - Data should update to reflect recent changes

**Prevention:**
- Document report filter logic
- Dashboard refresh schedule (auto-refresh if available)
- User training on dashboard filter usage

---

#### **Issue: NPSP Financial Data Not Showing in Treasurer Dashboard**
**Symptoms:**
- Treasurer Dashboard shows $0 for all financial metrics
- NPSP Opportunity data exists but not displayed
- Budget vs Actual widgets blank

**Root Causes:**
1. NPSP rollup jobs not running
2. Report using wrong Opportunity record types
3. GAU (General Accounting Unit) allocations missing
4. WITH SECURITY_ENFORCED blocking NPSP namespace fields

**Resolution Steps:**
1. Check NPSP rollup status:
   - **NPSP Settings** → **System Tools** → **Rollup Recalculation**
   - Click **Recalculate Rollups**
   - Select **All Rollups** → **Recalculate**
   - Wait for completion → Refresh Treasurer Dashboard

2. Verify Opportunity record types:
   - **Setup** → **Object Manager** → **Opportunity** → **Record Types**
   - Identify NPSP record types: Donation, Membership Dues, Grant, etc.
   - Edit Treasurer Dashboard report → **Filters**
   - Add filter: **Record Type** = Donation, Membership Dues (all NPSP types)

3. Check GAU allocations:
   - Navigate to **General Accounting Units** tab (NPSP)
   - Verify GAUs exist for expense categories (e.g., "Events", "Operations", "Fundraising")
   - Open Opportunity records → Related **GAU Allocations**
   - If missing, create GAU allocations manually or via bulk update

4. Validate NPSP field access:
   - Edit report → Add NPSP fields (e.g., `npsp__Amount__c`)
   - Run report → If "Insufficient Privileges" error, permission issue
   - Grant Treasurer permission set access to NPSP fields:
     - **Setup** → **Permission Sets** → **CVMA_Treasurer_Access**
     - **Object Settings** → **Opportunity** → **Field Permissions**
     - Enable Read access to all `npsp__*` fields

**Prevention:**
- Schedule NPSP rollup jobs (nightly via Apex batch)
- NPSP field access documentation
- Monthly NPSP data audit

---

### **Category 6: Experience Cloud and Site Access Issues**

#### **Issue: Website Access Suspension Not Working**
**Symptoms:**
- Member with `Website_Access_Suspended__c` = TRUE can still log into site
- Access restriction message not displayed
- Security policy not enforced

**Root Causes:**
1. Site member restriction rule not activated
2. Restriction rule incorrect field configuration
3. User accessing site via Salesforce login (not Experience Cloud)
4. Browser cache showing old session

**Resolution Steps:**
1. Verify restriction rule exists:
   - **Setup** → **All Sites** → **Combat Veterans Motorcycle Association**
   - Click **Administration** → **Members**
   - Scroll to **Member Restriction Rules**
   - Confirm rule exists: "Administrative Hold Website Access Restriction"
   - Status = **Active**

2. Check restriction rule configuration:
   - Click rule name → **Edit**
   - Verify **Field:** `Website_Access_Suspended__c`
   - Verify **Operator:** Equals
   - Verify **Value:** TRUE
   - Verify **Action:** Deny Access
   - Custom message should display when access denied

3. Test with incognito/private browser:
   - Log out of all Salesforce sessions
   - Open incognito/private browser window
   - Navigate to Experience Cloud site URL
   - Attempt login as user with `Website_Access_Suspended__c` = TRUE
   - Expected: Access denied with custom message

4. Verify user Contact record:
   - Check user's Contact record has `Website_Access_Suspended__c` = TRUE
   - Check Contact.Email matches user login email
   - If mismatch, user may have multiple Contact records

5. Validate user account:
   - **Setup** → Search user name → Click User record
   - Check **Contact** field = correct Contact record
   - If wrong Contact associated, update user record

**Prevention:**
- Quarterly audit of suspended access members
- Automated notification when Website_Access_Suspended__c changed
- Member restriction rule validation in deployment checklist

---

## 📊 **Epic-Wide Health Check Procedures**

### **Monthly CEB Data Audit (15 minutes)**

**Purpose:** Ensure data integrity across all Epic #4 features

**Checklist:**
1. [ ] **CEB Officers Current:**
   - Run report: "Active CEB Officers"
   - Verify all positions filled
   - Check term end dates within reasonable range (not expired)

2. [ ] **Permission Set Assignments:**
   - Run report: "CEB Officers Missing Permission Sets"
   - Assign missing permission sets to officers

3. [ ] **Flow Health:**
   - **Setup** → **Flows** → Search "CVMA"
   - Verify all flows Status = Active
   - Review **Run History** for failures (red status)
   - Investigate and resolve failures

4. [ ] **Email Deliverability:**
   - Check spam reports from CEB officers
   - Review **Email Log Files** for bounces
   - Update Contact email addresses if bounced

5. [ ] **Dashboard Data Accuracy:**
   - Open Commander Dashboard
   - Spot-check metrics against manual queries
   - Refresh dashboards if stale data detected

6. [ ] **Validation Rule Exemptions:**
   - Review validation rule error logs (if tracked)
   - Identify patterns of legitimate blocks
   - Adjust validation rules if too restrictive

---

### **Quarterly Epic #4 Compliance Review (45 minutes)**

**Purpose:** Validate National Bylaws compliance and system effectiveness

**Checklist:**
1. [ ] **National Bylaws Article VII (Chain of Command):**
   - Verify Region and State Organization records current
   - Validate Regional and State Representative assignments
   - Check Contact hierarchy (Region → State → Chapter)

2. [ ] **National Bylaws Article XIV.03 (CEB Responsibilities):**
   - Review CEB term expiration timeline
   - Confirm elections scheduled 90 days in advance
   - Validate CEB officer role assignments

3. [ ] **National Bylaws Appendix C (Discipline):**
   - Run report: "Active Administrative Hold Investigations"
   - Confirm no overdue 90-day deadlines
   - Verify all investigations have Committee Chair assigned
   - Check Investigation Forms Status completion

4. [ ] **Security Audit:**
   - Review guest user profile permissions (no CEB access)
   - Validate WITH SECURITY_ENFORCED in all custom Apex
   - Test site access restrictions (Website_Access_Suspended__c)

5. [ ] **Documentation Current:**
   - Update user guides with new procedures
   - Document lessons learned from support tickets
   - Revise troubleshooting guide with new issues

6. [ ] **User Feedback:**
   - Survey CEB officers on dashboard usability
   - Collect feature requests for next Epic
   - Identify pain points and workarounds

---

## 📞 **Escalation Procedures**

### **Level 1: User Self-Service**
- Read relevant user guide (USER-STORY-*-GUIDE.md)
- Check this troubleshooting guide
- Search Salesforce Help documentation

### **Level 2: CEB Officer Peer Support**
- Contact Secretary (system super user)
- Ask Commander for permission-related issues
- Consult Treasurer for NPSP financial questions

### **Level 3: System Administrator**
- Email: detonator@cvma20-7.org
- Provide:
  - User Story number (e.g., #67)
  - Error message (exact text or screenshot)
  - Steps to reproduce
  - User name and Contact record ID

### **Level 4: Salesforce Support**
- Login to Salesforce Help portal
- Create case with severity level
- Attach debug logs and error screenshots
- Reference CVMA deployment IDs

---

## 📚 **Reference Documentation**

### **User Guides:**
- USER-STORY-66-CHAIN-OF-COMMAND-GUIDE.md
- USER-STORY-67-CEB-TERM-TRACKING-GUIDE.md (if exists)
- USER-STORY-68-DISCIPLINARY-SYSTEM-GUIDE.md
- USER-STORY-60-CEB-DASHBOARD-GUIDE.md

### **Deployment Runbooks:**
- RUNBOOK-USER-STORY-67-CEB-TERM-TRACKING.md
- RUNBOOK-USER-STORY-68-ADMINISTRATIVE-HOLD.md

### **National Bylaws:**
- Article VII: Chain of Command
- Article XIV.03: CEB Responsibilities and Term Limits
- Appendix C: Discipline (Sections 6, 8.e, 9, 11, 12)

### **Development Resources:**
- CVMA-RESOURCE-REGISTRY.md - Known resources and patterns
- STORM_CLAUDE_CORE.md - Development protocols and methodology
- CLAUDE.md - Base development guidance

---

🎖️ **Generated with [Claude Code](https://claude.com/claude-code)**
**Date:** October 6, 2025
**For:** CEB Officers & System Administrators - CVMA Chapter 20-7
**Epic Status:** ✅ 100% COMPLETE (4/4 User Stories Deployed)
**Last Updated:** October 6, 2025
