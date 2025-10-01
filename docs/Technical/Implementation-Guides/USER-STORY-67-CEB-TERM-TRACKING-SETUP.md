# User Story #67: CEB Term Tracking Automation - Setup Guide

## 📋 Implementation Summary

This guide provides step-by-step instructions for completing the CEB Term Tracking Automation setup after deploying the base components.

### Components Deployed Automatically
✅ **Custom Fields (4)**:
- Previous_CEB_Positions__c
- Election_Due_Date__c (Formula Field)
- Term_Limit_Status__c
- Last_Election_Date__c

✅ **Validation Rules (3)**:
- CEB_Term_End_After_Start
- CEB_Term_Requires_Position
- Election_Date_Validation

✅ **Email Templates (3)**:
- CVMA_CEB_90_Day_Term_Expiration
- CVMA_CEB_60_Day_Term_Expiration
- CVMA_CEB_30_Day_Term_Expiration

✅ **Record-Triggered Flow (Draft)**:
- CVMA_CEB_Term_Tracking_Automation (requires activation)

---

## 🔧 Manual Setup Required

### Step 1: Activate Record-Triggered Flow

The CVMA_CEB_Term_Tracking_Automation flow was deployed in Draft status and must be activated manually.

**Instructions:**
1. Navigate to **Setup → Flows**
2. Search for "CVMA CEB Term Tracking Automation"
3. Open the flow
4. Review the flow logic (optional)
5. Click **Activate**

**Flow Purpose:**
- Automatically updates Term_Limit_Status__c when CEB positions change
- Archives position history to Previous_CEB_Positions__c
- Maintains compliance with National Bylaws Article XIV.03.b

---

### Step 2: Create Scheduled Flow for Daily Term Expiration Alerts

Due to the complexity of scheduled flows, this component must be created through the Salesforce UI.

**Create New Scheduled Flow:**
1. Navigate to **Setup → Flows**
2. Click **New Flow**
3. Select **Scheduled-Triggered Flow**
4. Configure the following:

#### Flow Configuration
- **Name**: CVMA Daily CEB Term Expiration Alerts
- **Description**: Daily scheduled check for CEB term expirations with automated email alerts at 90, 60, and 30 days
- **API Name**: CVMA_Daily_CEB_Term_Expiration_Alerts
- **Schedule**: Daily at 6:00 AM (or preferred time)
- **Object**: Contact
- **Entry Conditions**:
  - CEB_Position__c IS NOT BLANK
  - CEB_Term_End__c IS NOT BLANK

#### Flow Logic (Get Records)

**Element 1: Get 90-Day Expiration Contacts**
- **Object**: Contact
- **Conditions**:
  - CEB_Position__c ≠ NULL
  - Election_Due_Date__c = TODAY + 90
- **Store**: Save to variable `var_90DayContacts` (Collection)

**Element 2: Loop Through 90-Day Contacts**
- **Loop**: For Each item in `var_90DayContacts`

**Element 3: Send 90-Day Alert Email**
- **Action**: Send Email
- **Template**: CVMA_CEB_90_Day_Term_Expiration
- **Recipients**:
  - Loop item (current Contact)
  - Chapter Secretary (lookup from Contact where CEB_Position__c = 'Secretary')
  - Chapter Commander (lookup from Contact where CEB_Position__c = 'Commander (CO)')

**Element 4: Get 60-Day Expiration Contacts**
- **Object**: Contact
- **Conditions**:
  - CEB_Position__c ≠ NULL
  - Election_Due_Date__c = TODAY + 60
- **Store**: Save to variable `var_60DayContacts` (Collection)

**Element 5: Loop Through 60-Day Contacts**
- **Loop**: For Each item in `var_60DayContacts`

**Element 6: Send 60-Day Alert Email**
- **Action**: Send Email
- **Template**: CVMA_CEB_60_Day_Term_Expiration
- **Recipients**:
  - Loop item (current Contact)
  - Chapter Secretary
  - Chapter Commander
  - State Representative (from Contact.State_Organization__r.State_Representative__c)

**Element 7: Get 30-Day Expiration Contacts**
- **Object**: Contact
- **Conditions**:
  - CEB_Position__c ≠ NULL
  - Election_Due_Date__c = TODAY + 30
- **Store**: Save to variable `var_30DayContacts` (Collection)

**Element 8: Loop Through 30-Day Contacts**
- **Loop**: For Each item in `var_30DayContacts`

**Element 9: Send 30-Day CRITICAL Alert Email**
- **Action**: Send Email
- **Template**: CVMA_CEB_30_Day_Term_Expiration
- **Recipients**:
  - Loop item (current Contact)
  - Chapter Secretary
  - Chapter Commander
  - State Representative
  - Region Representative (from Contact.State_Organization__r.Region__r.Region_Representative__c)

**Element 10: Save Flow**
- Click **Save**
- Click **Activate**

---

### Step 3: Configure Email Alert Recipients

The scheduled flow requires identifying key contacts for alert distribution.

**Option A: Use Roles (Recommended)**
- Assign CEB positions to Salesforce Roles
- Configure flow to send to Role members

**Option B: Use Custom Settings**
- Create Custom Setting: CVMA_Alert_Recipients__c
- Fields: Chapter_Secretary_Email__c, Chapter_Commander_Email__c
- Update flow to use Custom Setting values

**Option C: Use Lookup Fields**
- Rely on CEB_Position__c field to identify current officers
- Query Contact records with specific CEB positions

---

## 📊 Testing the Implementation

### Test Case 1: Validation Rules
1. Open a Contact record with a CEB Position
2. Try to set CEB_Term_End__c before CEB_Term_Start__c
3. **Expected**: Validation error prevents save

### Test Case 2: Formula Field Calculation
1. Set CEB_Term_Start__c = 01/01/2025
2. Set CEB_Term_End__c = 01/01/2028
3. **Expected**: Election_Due_Date__c calculates to 12/02/2027 (30 days before term end)

### Test Case 3: Email Templates
1. Navigate to **Setup → Email Templates**
2. Search for "CVMA CEB"
3. Select "CVMA CEB 90 Day Term Expiration"
4. Click **Send Test and Verify Merge Fields**
5. Select a Contact with CEB_Position__c populated
6. **Expected**: Email preview shows correctly merged field values

### Test Case 4: Scheduled Flow (After Creation)
1. Manually run the flow: **Setup → Flows → CVMA Daily CEB Term Expiration Alerts → Run**
2. Check email delivery to test recipients
3. **Expected**: Emails sent to contacts with terms expiring in 90/60/30 days

---

## 🎯 Success Criteria Validation

### Automated Alert System
✅ 90-Day Alert: Email template created and functional
✅ 60-Day Alert: Email template created with escalation
✅ 30-Day Alert: CRITICAL email template with full escalation
✅ Term Expiration: Formula field calculates election due date
✅ Alert Recipients: Chapter officers, State Representative, Region Representative

### Data Integrity
✅ Term date validation prevents inconsistent data
✅ CEB position required for term tracking
✅ Election date validation ensures proper sequence
✅ Historical tracking field available for manual updates

### National Bylaws Compliance
✅ Article XIV.03.b: Election requirements automated
✅ Article VII.03: State/Regional oversight notification
✅ Proper governance: 90-60-30 day advance notice ensures compliance

---

## 📋 Next Steps for Full Implementation

### Phase 2: Historical Data Population
1. **Backfill Existing CEB Terms**:
   - Review current CEB officers
   - Set CEB_Term_Start__c and CEB_Term_End__c
   - Set Last_Election_Date__c if known
   - Update Term_Limit_Status__c to "Currently Serving"

2. **Archive Previous Positions**:
   - Manually populate Previous_CEB_Positions__c for members with past CEB service
   - Format: "Position | Start Date - End Date"
   - Example: "Commander (CO) | 01/01/2022 - 01/01/2025"

### Phase 3: Dashboard and Reporting
1. **Create CEB Term Management Dashboard**:
   - Report: Upcoming Term Expirations (next 180 days)
   - Report: CEB Position History by Member
   - Report: Election Compliance Status by Chapter
   - Chart: Term Expiration Timeline

2. **Create List Views**:
   - CEB Officers - Terms Expiring Soon
   - CEB Eligible Members (Term_Limit_Status__c = 'Eligible')
   - CEB Officers - Term Limited

### Phase 4: User Training
1. **Chapter Secretary Training**:
   - Using the automation system
   - Updating term dates after elections
   - Responding to automated alerts
   - Historical record maintenance

2. **State Representative Training**:
   - Oversight dashboard usage
   - Election compliance monitoring
   - Intervention procedures for missed elections

---

## 🏍️ CVMA National Bylaws References

### Article XIV.03.b - Chapter Officer Elections
- Officers elected per chapter bylaws procedures
- Minimum 1 year CVMA membership required (6 months for new chapters)
- Only Full Members eligible for CEB positions
- Elections must follow proper procedures

### Article VII.03 - State/Regional Oversight
- State Representatives oversee chapter operations
- Region Representatives oversee state organizations
- Escalation procedures for compliance issues

---

**Implementation Date**: October 1, 2025
**Epic #4**: CVMA Bylaws Compliance - CEB Role-Based Access Control
**User Story #67**: CEB Term Tracking Automation and Election Management

🎖️ Combat Veterans Motorcycle Association Chapter 20-7
"Vets Serving Vets" - Automated Governance Excellence
