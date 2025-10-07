# Deployment Runbook: User Story #67 - CEB Term Tracking Automation
**CVMA Chapter 20-7 - Combat Veterans Motorcycle Association**

## 📋 **Deployment Overview**

**Epic:** #4 - CVMA Bylaws Compliance
**User Story:** #67 - CEB Term Tracking & Election Deadline Alerts
**Deployment Date:** October 1, 2025
**Deployment ID:** 0Afbm00000MNDwtCAH (14 components - 100% success)
**Status:** ✅ Metadata Deployed - ⚠️ Manual Flow Activation Required

---

## 🎯 **What Was Deployed (Automatic)**

### **Custom Fields (Contact Object)**
✅ `CEB_Position__c` (Picklist) - CEB officer role assignment
✅ `CEB_Term_Start__c` (Date) - Term start date
✅ `CEB_Term_End__c` (Date) - Term end date (auto-calculated as Start + 365 days)
✅ `Election_Due_Date__c` (Formula) - 90 days before term end
✅ `Days_Until_Election__c` (Formula) - Countdown to election deadline

### **Permission Sets**
✅ `CVMA_Commander_Access` - Full CEB management permissions
✅ `CVMA_Treasurer_Access` - Financial data and CEB read access
✅ `CVMA_Secretary_Access` - Meeting minutes and documentation permissions

### **Email Templates (Folder: CVMA_CEB_Alerts)**
✅ `CVMA_CEB_Term_90_Day_Notice` - 90-day advance election notice
✅ `CVMA_CEB_Term_60_Day_Notice` - 60-day election preparation reminder
✅ `CVMA_CEB_Term_30_Day_Notice` - 30-day urgent election alert

### **Record-Triggered Flow**
✅ `CVMA_CEB_Term_Tracking_Automation` (Deployed but INACTIVE)

---

## ⚠️ **What Requires Manual Setup (This Runbook)**

### **Required Manual Tasks:**
1. ✅ Activate `CVMA_CEB_Term_Tracking_Automation` flow
2. ✅ Create scheduled flow for election deadline alerts (90/60/30-day)
3. ✅ Assign permission sets to CEB officers
4. ✅ Populate CEB term dates for active officers
5. ✅ Test alert workflow with sample data
6. ✅ Validate email delivery and notification content

**Estimated Time:** 45-60 minutes
**Prerequisites:** System Administrator access, CEB officer Contact records exist

---

## 🚀 **Step 1: Activate Record-Triggered Flow**

### **Why This Is Required:**
Salesforce deploys flows in INACTIVE state for safety. You must manually activate after validating configuration.

### **Activation Steps:**

1. Navigate to **Setup** → **Flows**
2. Search for: **CVMA CEB Term Tracking Automation**
3. Click the flow name to open
4. Review flow logic:
   - **Trigger:** When Contact record is created or updated
   - **Entry Criteria:** `CEB_Position__c` is not blank AND (`CEB_Term_Start__c` changed OR `CEB_Term_End__c` changed)
   - **Actions:** Update `Election_Due_Date__c` and `Days_Until_Election__c` formulas

5. Click **Activate** button (top-right)
6. Confirm activation warning: "This flow will now run automatically"
7. Click **Activate**

### **Validation:**
✅ Flow status shows "Active" badge
✅ Last Modified Date = Today's date
✅ Version number incremented (if previously activated)

---

## 🚀 **Step 2: Create Scheduled Flow for Election Deadline Alerts**

### **Why This Is Required:**
Email alerts for 90/60/30-day election deadlines require scheduled flow (daily check). This cannot be fully deployed via metadata - requires manual creation.

### **Create New Scheduled Flow:**

1. Navigate to **Setup** → **Flows**
2. Click **New Flow**
3. Select **Scheduled-Triggered Flow**
4. Configure flow properties:

---

### **Flow Configuration:**

**Flow Label:** CVMA Daily CEB Election Alerts
**API Name:** CVMA_Daily_CEB_Election_Alerts
**Description:** Daily monitoring of CEB term expiration with automated 90/60/30-day election deadline alerts

**Schedule Configuration:**
- **Frequency:** Daily
- **Time:** 6:00 AM (adjust to your chapter's timezone)
- **Start Date:** Today's date
- **End Date:** (Leave blank - runs indefinitely)

**Object:** Contact
**Entry Conditions:** ALL conditions must be true (AND)
- `CEB_Position__c` IS NOT BLANK
- `CEB_Term_End__c` IS NOT BLANK

---

### **Flow Elements to Create:**

#### **Element 1: Get 90-Day Contacts**
- **Element Type:** Get Records
- **Label:** Get CEB Officers with 90-Day Election Deadline
- **Object:** Contact
- **Conditions:**
  - `CEB_Position__c` ≠ null
  - `Election_Due_Date__c` = TODAY (90 days before term end)
- **How Many Records:** All records
- **How to Store:** Automatically store all fields
- **Variable Name:** `var_90DayContacts`

---

#### **Element 2: Decision - Check 90-Day Contacts**
- **Element Type:** Decision
- **Label:** 90-Day Contacts Exist?
- **Outcome 1:** Yes (90-Day Contacts Found)
  - **Condition:** `{!var_90DayContacts}` IS NULL = False
- **Outcome 2:** No (Default Outcome)

---

#### **Element 3: Loop Through 90-Day Contacts**
- **Element Type:** Loop
- **Label:** Loop 90-Day Contacts
- **Collection Variable:** `{!var_90DayContacts}`
- **Direction:** First item to last item

---

#### **Element 4: Send 90-Day Email**
- **Element Type:** Action - Send Email
- **Label:** Send 90-Day Election Notice
- **Email Template:** CVMA CEB Term 90 Day Notice
- **Recipient:** `{!$Record.Email}` (current loop item)
- **Additional Recipients:**
  - Commander Email
  - Secretary Email
  - Chapter XO Email (if applicable)

**Merge Field Configuration:**
- `{!Contact.FirstName}`
- `{!Contact.CEB_Position__c}`
- `{!Contact.CEB_Term_End__c}`
- `{!Contact.Election_Due_Date__c}`

---

#### **Element 5: Get 60-Day Contacts**
- **Element Type:** Get Records
- **Label:** Get CEB Officers with 60-Day Election Deadline
- **Object:** Contact
- **Conditions:**
  - `CEB_Position__c` ≠ null
  - `Days_Until_Election__c` = 60
- **How Many Records:** All records
- **Variable Name:** `var_60DayContacts`

---

#### **Element 6: Decision - Check 60-Day Contacts**
- **Element Type:** Decision
- **Label:** 60-Day Contacts Exist?
- **Outcome 1:** Yes (60-Day Contacts Found)
  - **Condition:** `{!var_60DayContacts}` IS NULL = False
- **Outcome 2:** No (Default Outcome)

---

#### **Element 7: Loop Through 60-Day Contacts**
- **Element Type:** Loop
- **Label:** Loop 60-Day Contacts
- **Collection Variable:** `{!var_60DayContacts}`
- **Direction:** First item to last item

---

#### **Element 8: Send 60-Day Email**
- **Element Type:** Action - Send Email
- **Label:** Send 60-Day Election Reminder
- **Email Template:** CVMA CEB Term 60 Day Notice
- **Recipient:** `{!$Record.Email}` (current loop item)
- **Additional Recipients:**
  - Commander Email
  - Secretary Email

---

#### **Element 9: Get 30-Day Contacts**
- **Element Type:** Get Records
- **Label:** Get CEB Officers with 30-Day Election URGENT Deadline
- **Object:** Contact
- **Conditions:**
  - `CEB_Position__c` ≠ null
  - `Days_Until_Election__c` = 30
- **How Many Records:** All records
- **Variable Name:** `var_30DayContacts`

---

#### **Element 10: Decision - Check 30-Day Contacts**
- **Element Type:** Decision
- **Label:** 30-Day Contacts Exist?
- **Outcome 1:** Yes (30-Day Contacts Found - URGENT)
  - **Condition:** `{!var_30DayContacts}` IS NULL = False
- **Outcome 2:** No (Default Outcome)

---

#### **Element 11: Loop Through 30-Day Contacts**
- **Element Type:** Loop
- **Label:** Loop 30-Day Contacts
- **Collection Variable:** `{!var_30DayContacts}`
- **Direction:** First item to last item

---

#### **Element 12: Send 30-Day URGENT Email**
- **Element Type:** Action - Send Email
- **Label:** Send 30-Day URGENT Election Alert
- **Email Template:** CVMA CEB Term 30 Day Notice
- **Recipient:** `{!$Record.Email}` (current loop item)
- **Additional Recipients:**
  - Commander Email
  - Secretary Email
  - State Representative Email (escalation)

---

### **Flow Diagram (Logical Flow):**

```
START (Daily at 6 AM)
  ↓
Get 90-Day Contacts → Decision (Exist?) → YES → Loop → Send Email
  ↓                                      → NO → Skip
Get 60-Day Contacts → Decision (Exist?) → YES → Loop → Send Email
  ↓                                      → NO → Skip
Get 30-Day Contacts → Decision (Exist?) → YES → Loop → Send Email (+ State Rep)
  ↓                                      → NO → Skip
END
```

---

### **Save and Activate Flow:**

1. Click **Save**
2. Review all flow elements
3. Run **Debug** with test data:
   - Create test Contact with `CEB_Term_End__c` = TODAY + 90
   - Verify 90-day email triggers
4. Click **Activate**
5. Confirm activation

---

## 🚀 **Step 3: Assign Permission Sets to CEB Officers**

### **Required Permission Set Assignments:**

**Commander:**
- `CVMA_Commander_Access` ✅

**Treasurer:**
- `CVMA_Treasurer_Access` ✅

**Secretary:**
- `CVMA_Secretary_Access` ✅

**Other CEB Officers (XO, Road Captain, Chaplain, Sergeant at Arms):**
- `CVMA_Commander_Access` (read-only for most CEB functions) ✅

---

### **Assignment Steps:**

1. Navigate to Contact record for CEB officer
2. Click **Permission Set Assignments** related list
3. Click **Edit Assignments**
4. Select appropriate permission set from Available list
5. Move to Enabled list
6. Click **Save**

**Repeat for all CEB officers (typically 7-10 officers per chapter)**

---

### **Bulk Assignment (Optional - Data Loader):**

If you have many CEB officers:

1. Export Contact records with `CEB_Position__c` ≠ null
2. Create Permission Set Assignment CSV:
   - `PermissionSetId` = ID of permission set
   - `AssigneeId` = Contact User ID
3. Use Data Loader to insert Permission Set Assignments

---

## 🚀 **Step 4: Populate CEB Term Dates**

### **Required Data Entry for Active CEB Officers:**

For each CEB officer Contact record:

1. Navigate to Contact record
2. Edit → Scroll to CEB Information section
3. Fill in:
   - **CEB Position:** (e.g., Commander, Treasurer, Secretary)
   - **CEB Term Start:** Date officer term began
   - **CEB Term End:** Auto-calculated (Start + 365 days) - verify correct

4. Save

**Expected Formula Calculations:**
- `Election_Due_Date__c` = CEB_Term_End__c - 90 days
- `Days_Until_Election__c` = Days between TODAY and Election_Due_Date__c

---

### **Example Data Entry:**

**Contact:** John Smith
**CEB Position:** Commander
**CEB Term Start:** 2025-01-01
**CEB Term End:** 2026-01-01 (auto-calculated)
**Election Due Date:** 2025-10-03 (90 days before term end)
**Days Until Election:** (calculated daily)

---

## 🚀 **Step 5: Test Alert Workflow**

### **Test Scenario 1: 90-Day Alert**

1. Create test Contact: "Test Commander 90 Day"
2. Set `CEB_Position__c` = Commander
3. Set `CEB_Term_Start__c` = TODAY
4. Set `CEB_Term_End__c` = TODAY + 90
5. **Expected:** `Election_Due_Date__c` = TODAY
6. Wait for scheduled flow to run (next 6 AM) OR run flow manually via Debug
7. **Verify:** 90-day email sent to test Contact + Commander + Secretary

---

### **Test Scenario 2: 60-Day Alert**

1. Create test Contact: "Test Treasurer 60 Day"
2. Set `CEB_Position__c` = Treasurer
3. Set `CEB_Term_End__c` = TODAY + 60
4. **Expected:** `Days_Until_Election__c` = 60 (since Election_Due_Date = TODAY + 60 - 90 = TODAY - 30, wait until TODAY - 30 days from now)
5. Manually adjust `Days_Until_Election__c` formula to test (or wait for actual 60-day milestone)
6. Run flow via Debug
7. **Verify:** 60-day email sent

---

### **Test Scenario 3: 30-Day URGENT Alert**

1. Create test Contact: "Test Secretary 30 Day"
2. Set `CEB_Position__c` = Secretary
3. Set `CEB_Term_End__c` = TODAY + 30
4. Run scheduled flow via Debug
5. **Verify:** 30-day URGENT email sent + State Representative copied

---

### **Manual Flow Debug (Immediate Testing):**

1. Navigate to flow: **CVMA Daily CEB Election Alerts**
2. Click **Debug**
3. Select test Contact record with term end date matching alert threshold
4. Click **Run**
5. Review **Debug Details** → Email Actions
6. Confirm email sent successfully

---

## 🚀 **Step 6: Validate Email Delivery**

### **Email Template Validation:**

1. Navigate to **Setup** → **Email Templates**
2. Search folder: **CVMA CEB Alerts**
3. Open each template:
   - CVMA CEB Term 90 Day Notice
   - CVMA CEB Term 60 Day Notice
   - CVMA CEB Term 30 Day Notice

4. Review merge fields:
   - `{!Contact.FirstName}`
   - `{!Contact.CEB_Position__c}`
   - `{!Contact.CEB_Term_End__c}`
   - `{!Contact.Election_Due_Date__c}`

5. Click **Preview** → Select test Contact → Verify merge field population

---

### **Deliverability Check:**

1. Send test email (via flow debug)
2. Check recipient inbox (Commander, Secretary)
3. Verify:
   - ✅ Email received
   - ✅ Subject line correct
   - ✅ Merge fields populated correctly
   - ✅ Links/formatting display properly
   - ✅ No spam folder delivery

---

## ✅ **Post-Deployment Validation Checklist**

Run through this checklist to confirm successful deployment:

- [ ] **Flow Activation:** CVMA_CEB_Term_Tracking_Automation status = Active
- [ ] **Scheduled Flow Created:** CVMA_Daily_CEB_Election_Alerts exists and active
- [ ] **Scheduled Flow Configured:** Daily at 6 AM, no end date
- [ ] **Permission Sets Assigned:** All CEB officers have appropriate permission sets
- [ ] **CEB Term Data Populated:** All active officers have Term Start/End dates
- [ ] **Formula Fields Calculating:** Election_Due_Date__c and Days_Until_Election__c display correct values
- [ ] **Email Templates Validated:** All 3 templates preview correctly with merge fields
- [ ] **90-Day Alert Test:** Test email sent and received successfully
- [ ] **60-Day Alert Test:** Test email sent and received successfully
- [ ] **30-Day Alert Test:** Test email sent and received successfully (with State Rep copy)
- [ ] **Email Deliverability:** No spam folder issues, formatting displays correctly
- [ ] **Documentation Updated:** NEXT-SESSION priorities updated with completion status
- [ ] **GitHub Issue Closed:** User Story #67 marked complete with deployment notes

---

## 🚨 **Troubleshooting Common Issues**

### **Issue 1: Flow Not Triggering**
**Symptom:** CEB term dates updated, but no email alerts sent
**Cause:** Scheduled flow not running or inactive
**Resolution:**
1. Verify scheduled flow status: **Setup** → **Flows** → **CVMA Daily CEB Election Alerts** → Status = Active
2. Check scheduled flow run history: **Setup** → **Flows** → Flow name → **Run History**
3. Verify entry conditions match test data (Days_Until_Election__c = 90, 60, or 30)

---

### **Issue 2: Email Not Received**
**Symptom:** Flow runs successfully but email not delivered
**Cause:** Email deliverability settings or spam filtering
**Resolution:**
1. Check **Setup** → **Email Administration** → **Deliverability** → Access = All Email
2. Verify recipient email address valid on Contact record
3. Check spam/junk folder
4. Review **Setup** → **Email Log Files** for delivery errors
5. Verify org daily email limit not exceeded (typically 5,000 emails/day)

---

### **Issue 3: Formula Fields Showing Blank**
**Symptom:** Election_Due_Date__c or Days_Until_Election__c blank
**Cause:** CEB_Term_End__c not populated
**Resolution:**
1. Edit Contact → Verify `CEB_Term_Start__c` and `CEB_Term_End__c` have valid dates
2. Save record to recalculate formulas
3. If still blank, check formula syntax: **Setup** → **Object Manager** → **Contact** → **Fields** → Field name → View formula

---

### **Issue 4: Permission Set Assignment Failed**
**Symptom:** Cannot assign permission set to CEB officer
**Cause:** User profile restrictions or licensing
**Resolution:**
1. Verify Contact has associated User record
2. Verify User has appropriate license (Customer Community Plus or higher)
3. Check User is Active
4. Verify no conflicting permission sets assigned

---

### **Issue 5: Scheduled Flow Runs Too Frequently**
**Symptom:** Multiple email alerts sent in same day
**Cause:** Scheduled flow frequency set to hourly instead of daily
**Resolution:**
1. Edit scheduled flow: **Setup** → **Flows** → Flow name → **Edit**
2. Click **Configure Start**
3. Change **Frequency** to Daily
4. Set **Time** to 6:00 AM (or preferred time)
5. Save and reactivate

---

## 📊 **Success Metrics**

After deployment, monitor these metrics:

**Week 1:**
- ✅ CEB officers receive timely election alerts (90/60/30-day)
- ✅ Zero missed election deadlines
- ✅ Commander has full visibility into term expirations

**Month 1:**
- ✅ 100% of CEB officer transitions planned in advance
- ✅ No emergency elections due to missed deadlines
- ✅ Secretary reports reduced manual tracking overhead

**Quarter 1:**
- ✅ National Bylaws Article XIV.03 compliance maintained
- ✅ CEB election calendar published and accurate
- ✅ Member confidence in CEB governance increased

---

## 📞 **Support Resources**

**Technical Questions:** detonator@cvma20-7.org
**Flow Troubleshooting:** Salesforce Flow documentation (help.salesforce.com)
**National Bylaws Reference:** Article XIV.03 (CEB Term Limits)
**GitHub Issue:** #67 (User Story - CEB Term Tracking)
**Deployment Record:** 0Afbm00000MNDwtCAH

---

## 📚 **Related Documentation**

- **USER-STORY-67-CEB-TERM-TRACKING-GUIDE.md** - Business requirements and field definitions
- **EPIC-4-CVMA-BYLAWS-COMPLIANCE.md** - Epic overview and compliance roadmap
- **CVMA-RESOURCE-REGISTRY.md** - Known resources and patterns
- **STORM_CLAUDE_CORE.md** - Development protocols and methodology

---

🎖️ **Generated with [Claude Code](https://claude.com/claude-code)**
**Date:** October 6, 2025
**For:** Senior Salesforce Developer - CVMA Chapter 20-7
**Deployment Status:** ✅ Metadata Complete - ⚠️ Manual Activation Required
**Estimated Activation Time:** 45-60 minutes
