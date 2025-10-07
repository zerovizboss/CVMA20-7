# Treasurer's Corner - User Guide for CEB Officers
**CVMA Chapter 20-7 - Combat Veterans Motorcycle Association**
**NPSP Financial Dashboard for Non-Technical Users**

## 💰 **Welcome, Treasurer!**

This guide helps you use the Treasurer's Corner dashboard to manage chapter finances, even if you're not a "computer person." Everything is explained in plain English with step-by-step instructions and screenshots references.

**What You'll Learn:**
- How to access and navigate the Treasurer's Corner
- Understanding financial reports and dashboards
- Tracking donations and membership dues
- Monthly treasurer reporting requirements
- Budget vs actual monitoring
- Common tasks and troubleshooting

**No Financial Software Experience Required!**

---

## 🎯 **What is Treasurer's Corner?**

**Treasurer's Corner** is your one-stop financial management hub powered by Salesforce's **Nonprofit Success Pack (NPSP)**. Think of it as your chapter's financial control center.

**What It Does:**
- Tracks all chapter income (donations, dues, fundraiser proceeds)
- Monitors expenses (event costs, supplies, veteran assistance)
- Shows real-time financial health (how much money we have)
- Generates monthly treasurer reports automatically
- Compares actual spending to budget
- Alerts you to financial issues before they become problems

**Why It's Better Than Spreadsheets:**
- ✅ Real-time data (always current, never outdated)
- ✅ Automatic calculations (no manual math errors)
- ✅ Built-in audit trail (every transaction tracked)
- ✅ Mobile access (check finances from anywhere)
- ✅ CEB transparency (Commander can view anytime)

---

## 🔐 **Step 1: Access Treasurer's Corner**

### **Login to Member Portal:**

1. Open your browser (Chrome, Firefox, Safari, Edge)
2. Navigate to: https://cvma20-7.force.com (or your portal URL)
3. Enter your credentials:
   - **Username:** your-email@example.com
   - **Password:** Your password
4. Click **Log In**

### **Navigate to Treasurer's Corner:**

**Method 1: Home Page Tile**
- Click **Treasurer's Corner** tile on home page
- (Tile only visible if you have Treasurer permission)

**Method 2: Navigation Menu**
- Click **Finance** in top navigation bar
- Select **Treasurer's Corner** from dropdown

**Method 3: Quick Link**
- Click **Apps** launcher (waffle icon, top-left)
- Search: "Treasurer"
- Click **Treasurer's Corner** app

---

### **Troubleshooting Access:**

**Problem: Don't see Treasurer's Corner tile/menu**
- **Cause:** Missing Treasurer permission set
- **Solution:** Contact Chapter Secretary or Commander
- They need to assign "CVMA_Treasurer_Access" permission to your user account

**Problem: "Insufficient Privileges" error**
- **Cause:** Permission set not activated yet
- **Solution:** Log out, wait 5 minutes, log back in
- If still blocked, contact Secretary

---

## 📊 **Step 2: Understanding Your Dashboard**

When you open Treasurer's Corner, you see your **Financial Dashboard** - a visual summary of chapter finances.

### **Dashboard Layout (Top to Bottom):**

#### **Section 1: Financial Health Snapshot** (Top Row)

**Metric 1: Total Cash Balance**
- **What It Shows:** How much money the chapter has RIGHT NOW
- **Color Coding:**
  - 🟢 Green: Healthy balance (above $5,000 recommended)
  - 🟡 Yellow: Caution (between $2,000-$5,000)
  - 🔴 Red: Low balance (below $2,000 - action needed)
- **What to Do:** If red, discuss fundraising at next CEB meeting

**Metric 2: Monthly Revenue**
- **What It Shows:** Total income THIS MONTH (donations + dues + fundraisers)
- **Example:** $2,450 (September 2025)
- **What to Do:** Compare to last month - is income steady or dropping?

**Metric 3: Monthly Expenses**
- **What It Shows:** Total spending THIS MONTH (events + supplies + assistance)
- **Example:** $1,750 (September 2025)
- **What to Do:** Compare to budget - are we overspending?

**Metric 4: Net Cash Flow**
- **What It Shows:** Revenue minus expenses (profit or loss)
- **Color Coding:**
  - 🟢 Green: Positive (making money)
  - 🔴 Red: Negative (spending more than earning)
- **Example:** +$700 (September 2025 = $2,450 revenue - $1,750 expenses)
- **What to Do:** If consistently red, need to cut expenses or raise more funds

---

#### **Section 2: Revenue Breakdown** (Middle Left)

**Donut Chart: "Where Money Comes From"**

- **Membership Dues:** Annual $80 dues from members
- **Donations:** One-time gifts from members or community
- **Fundraiser Revenue:** BBQ sales, poker run entry fees, raffles
- **Event Revenue:** Ride fees, party tickets, etc.
- **Other Income:** Merchandise sales, interest, grants

**How to Read It:**
- Larger slice = bigger portion of income
- Hover mouse over slice to see exact dollar amount
- Click slice to see list of transactions in that category

**Example Interpretation:**
- If "Membership Dues" is 60% of income, chapter is financially healthy
- If "Fundraisers" is 80%, we're too dependent on events (risky)

---

#### **Section 3: Expense Breakdown** (Middle Right)

**Donut Chart: "Where Money Goes"**

- **Event Costs:** Food, venue, supplies for chapter events
- **Veteran Assistance:** Financial help for members in need
- **Operations:** Meeting hall rent, insurance, website hosting
- **Merchandise:** Patches, shirts, chapter gear
- **Donations Out:** Gifts to veteran charities, Wreaths Across America, etc.
- **Other Expenses:** Miscellaneous

**How to Read It:**
- Larger slice = biggest expense category
- Hover mouse over slice to see exact dollar amount
- Click slice to see detailed transaction list

**Example Interpretation:**
- If "Veteran Assistance" is 30%, chapter is fulfilling mission well
- If "Operations" is 70%, too much overhead (need to cut costs)

---

#### **Section 4: Membership Dues Status** (Bottom Left)

**Bar Chart: "Dues Collection Rate"**

- **Green Bar:** Members with current dues (paid through this year)
- **Yellow Bar:** Members with dues expiring in next 60 days
- **Red Bar:** Members past due (owe dues)

**What to Do:**
1. Click red bar to see list of members past due
2. Send friendly reminder emails (template available)
3. Report past-due members to CEB if > 90 days late
4. CEB may vote to suspend membership if > 120 days late

**Target:** 90%+ members current (green bar highest)

---

#### **Section 5: Budget vs Actual** (Bottom Right)

**Line Chart: "Are We On Track?"**

- **Blue Line:** Budgeted spending (what we PLANNED to spend)
- **Orange Line:** Actual spending (what we ACTUALLY spent)
- **Green Shaded Area:** Under budget (good!)
- **Red Shaded Area:** Over budget (bad!)

**How to Read It:**
- If orange line below blue = UNDER BUDGET ✅
- If orange line above blue = OVER BUDGET ❌
- Hovering mouse shows exact dollar amounts

**Example:**
- September budget: $2,000
- September actual: $1,750
- Result: $250 under budget ✅ (well done!)

---

## 💳 **Step 3: Recording Income (Money Coming In)**

### **Scenario 1: Member Pays Annual Dues**

Most dues are paid online automatically, but sometimes members pay cash/check at meetings.

**Steps to Record Cash/Check Dues:**

1. **Access Opportunities Tab**
   - Click **Opportunities** in navigation menu
   - (Opportunities = financial transactions in Salesforce)

2. **Create New Opportunity**
   - Click **New** button (top-right)
   - Select **Membership Dues** record type
   - Click **Next**

3. **Fill in Dues Information**
   - **Opportunity Name:** Auto-fills as "[Member Name] - 2025 Dues"
   - **Account Name:** Search for member name, select from dropdown
   - **Amount:** $80 (or prorated amount if mid-year)
   - **Close Date:** Today's date (date you received payment)
   - **Stage:** Closed Won (dues received)
   - **Payment Method:** Cash or Check
   - **Check Number:** (if check payment, enter check number)

4. **Save Opportunity**
   - Click **Save** button
   - Confirmation message appears: "Opportunity created"
   - Member's dues status automatically updates to "Current"

5. **Create Receipt** (Optional but Recommended)
   - Click **Print Receipt** button
   - PDF receipt generates
   - Give receipt to member or email

---

### **Scenario 2: Chapter Receives Donation**

**Steps to Record Donation:**

1. **Create New Opportunity**
   - Click **Opportunities** tab → **New** button
   - Select **Donation** record type

2. **Fill in Donation Information**
   - **Donor Name (Account):** Search for member or create new contact
   - **Amount:** Dollar amount of donation
   - **Close Date:** Date donation received
   - **Stage:** Closed Won
   - **Donation Type:** One-time or Recurring (monthly pledge)
   - **Purpose:** Select category (General Fund, Veteran Assistance, Event Fund)
   - **Payment Method:** Cash, Check, Credit Card
   - **Check Number:** (if applicable)

3. **Save and Send Receipt**
   - Click **Save**
   - Click **Email Receipt** button
   - Donor receives automatic thank-you email with tax receipt

**Tax Receipt Note:** Donations to CVMA are NOT tax-deductible (we're a 501(c)(19) veteran organization, not 501(c)(3) charity). DO NOT claim donations are tax-deductible.

---

### **Scenario 3: Fundraiser Revenue**

**Example:** Chapter BBQ raised $1,500 in sales

**Steps to Record Fundraiser Income:**

1. **Find Fundraiser Campaign**
   - Click **Campaigns** tab
   - Search for fundraiser event (e.g., "2025 Fall BBQ Fundraiser")
   - Click campaign name

2. **Record Revenue**
   - Scroll to **Related** section
   - Click **New Opportunity** button
   - **Opportunity Name:** "2025 Fall BBQ - Revenue"
   - **Campaign:** Auto-filled (2025 Fall BBQ Fundraiser)
   - **Amount:** $1,500
   - **Close Date:** Event date
   - **Stage:** Closed Won
   - **Record Type:** Donation (fundraiser proceeds count as donations)

3. **Allocate to Budget Category** (Optional)
   - Scroll to **General Accounting Unit (GAU) Allocations**
   - Click **New GAU Allocation**
   - **GAU:** Select "Fundraising Revenue"
   - **Amount:** $1,500
   - Click **Save**

4. **Update Campaign Status**
   - Return to campaign record
   - Update **Status:** Completed
   - Campaign dashboard shows total revenue automatically

---

## 💸 **Step 4: Recording Expenses (Money Going Out)**

### **Scenario 1: Event Expenses**

**Example:** Purchased $250 in food/supplies for chapter picnic

**Steps to Record Expense:**

1. **Find Event Campaign**
   - Click **Campaigns** tab
   - Search for event (e.g., "2025 September Picnic")
   - Click campaign name

2. **Record Expense**
   - Scroll to **Campaign Expenses** section
   - Click **New Expense** button
   - **Expense Name:** "Picnic Food and Supplies"
   - **Campaign:** Auto-filled
   - **Amount:** $250
   - **Expense Date:** Purchase date
   - **Expense Category:** Food/Beverages
   - **Payment Method:** Chapter debit card, personal reimbursement, or check
   - **Receipt Attached:** Upload photo of receipt (click paperclip icon)

3. **Save Expense**
   - Click **Save**
   - Expense deducted from campaign budget automatically
   - Cash balance updated

4. **Reimburse Member (if applicable)**
   - If member paid out-of-pocket, create reimbursement check
   - Document: "Reimbursement to [Member Name] for Picnic Supplies - $250"
   - Get Commander approval signature
   - Update expense record: **Reimbursement Paid:** Yes

---

### **Scenario 2: Veteran Assistance Payment**

**Example:** Chapter approved $500 assistance for member's rent emergency

**Steps to Record Assistance:**

1. **Find Assistance Request** (if Epic #5 deployed)
   - Click **Veteran Assistance Requests** tab
   - Find approved request for member
   - Click request name

2. **Record Payment**
   - Click **Record Payment** button
   - **Amount:** $500
   - **Payment Date:** Today
   - **Payment Method:** Check (made payable to landlord)
   - **Check Number:** [enter check number]
   - **Paid To:** Landlord name
   - **Purpose:** Rent Assistance - [Month]

3. **Update Request Status**
   - **Status:** Assistance Provided
   - **Notes:** "Check #[number] issued on [date], delivered to member [date]"
   - Click **Save**

4. **Create Expense Record**
   - Click **Opportunities** tab → **New**
   - **Record Type:** Expense
   - **Opportunity Name:** "Veteran Assistance - [Member Name] - Rent"
   - **Amount:** -$500 (negative for expense)
   - **Close Date:** Payment date
   - **Stage:** Closed Won
   - **Expense Category:** Veteran Assistance
   - **GAU Allocation:** Veteran Support Fund

**CEB Approval Required:** All assistance >$500 requires CEB vote (per Bylaws). Document vote in meeting minutes.

---

### **Scenario 3: Operational Expenses**

**Example:** Monthly meeting hall rent ($200)

**Steps to Record Recurring Expense:**

1. **Create Expense Opportunity**
   - **Opportunities** tab → **New**
   - **Record Type:** Expense
   - **Opportunity Name:** "September 2025 Meeting Hall Rent"
   - **Amount:** -$200
   - **Close Date:** First of month (or payment date)
   - **Stage:** Closed Won
   - **Expense Category:** Operations - Rent
   - **Payment Method:** Auto-pay from chapter checking account

2. **Set Up Recurring Expense** (Optional Time-Saver)
   - After creating first month's expense, click **Clone** button
   - Change **Close Date** to next month
   - Change **Opportunity Name** to "October 2025 Meeting Hall Rent"
   - Click **Save**
   - Repeat for all 12 months

3. **Allocate to Budget**
   - **GAU Allocation:** Operations
   - Amount auto-deducted from Operations budget line

---

## 📅 **Step 5: Monthly Treasurer Reporting**

### **What's Required:**

Per CVMA Bylaws Appendix D, Treasurer must provide monthly financial report to CEB at chapter meetings.

**Monthly Report Must Include:**
1. ✅ Beginning balance (start of month)
2. ✅ Total revenue (all income sources)
3. ✅ Total expenses (all spending)
4. ✅ Ending balance (end of month)
5. ✅ Outstanding dues count (members owing dues)
6. ✅ Budget variance (over/under budget categories)

---

### **Generate Automated Monthly Report:**

**Method 1: One-Click Report (Recommended)**

1. **Navigate to Reports Tab**
   - Click **Reports** in navigation menu
   - Search folder: "CEB Reports"
   - Find report: "Monthly Treasurer Summary"

2. **Run Report for Current Month**
   - Click report name
   - Report generates automatically
   - Shows all required data points

3. **Export Report**
   - Click **Export** button (top-right)
   - Select **Excel Format** or **PDF**
   - Save file: "Treasurer Report - [Month] [Year].pdf"

4. **Present at CEB Meeting**
   - Print report or display on screen
   - Review each section with CEB officers
   - Answer questions
   - File report with Secretary for meeting minutes

---

**Method 2: Custom Dashboard Screenshot**

1. **Open Treasurer's Corner Dashboard**
2. **Take Screenshot** (or use Salesforce screenshot feature)
3. **Annotate Screenshot:**
   - Circle key metrics (beginning/ending balance)
   - Add notes for unusual expenses or revenue
4. **Email to CEB Officers** before meeting
5. **Present at Meeting** with printed copy

---

### **Common CEB Questions & How to Answer:**

**Q: "Why did expenses increase this month?"**
**A:** Click **Expense Breakdown** donut chart → Show which category increased (e.g., "Event Costs up $500 due to Fall BBQ")

**Q: "How many members owe dues?"**
**A:** Click **Membership Dues Status** red bar → Show list of past-due members (typically 5-10 members at any time)

**Q: "Are we on track with the budget?"**
**A:** Point to **Budget vs Actual** chart → If orange line below blue, "Yes, we're $[amount] under budget"

**Q: "How much money do we have for veteran assistance?"**
**A:** Click **GAU Allocations** section → Show "Veteran Support Fund" balance (e.g., "$2,500 available")

**Q: "What was our biggest fundraiser this year?"**
**A:** Click **Revenue Breakdown** → Click "Fundraiser Revenue" slice → Sort by amount descending → Show top fundraiser

---

## 💰 **Step 6: Budget Management**

### **Understanding Your Chapter Budget:**

Chapter budget is typically approved by CEB vote at beginning of fiscal year (January).

**Example Annual Budget:**
```
REVENUE:
- Membership Dues: $4,000 (50 members x $80)
- Donations: $2,000
- Fundraisers: $6,000
- Event Revenue: $1,000
TOTAL REVENUE: $13,000

EXPENSES:
- Operations (rent, insurance): $3,000
- Events (food, supplies): $4,000
- Veteran Assistance: $3,000
- Donations Out (charities): $1,000
- Merchandise: $1,000
- Miscellaneous: $1,000
TOTAL EXPENSES: $13,000

NET: $0 (break even)
```

---

### **Monitor Budget in Treasurer's Corner:**

1. **View Budget Dashboard**
   - Click **Budgets** tab in Treasurer's Corner
   - Select **2025 Annual Budget** (or current year)

2. **Check Budget Utilization**
   - **Green Progress Bars:** On track (used <75% of budget mid-year)
   - **Yellow Progress Bars:** Caution (used 75-90% of budget)
   - **Red Progress Bars:** Over budget (used >100%)

3. **Drill Down on Categories**
   - Click category name (e.g., "Veteran Assistance")
   - See all transactions in that budget category
   - Identify largest expenses

4. **Adjust Budget (if CEB approves)**
   - If over budget in one category, propose moving funds from another
   - Example: Move $500 from Merchandise (underspent) to Events (overspent)
   - Requires CEB vote
   - Update budget allocations after vote

---

### **Quarterly Budget Review (Recommended):**

**March 31 (Q1 Review):**
- Are we on track to hit revenue targets? (Should be at 25% of annual goal)
- Any budget categories already over 25% spent? (May need adjustment)

**June 30 (Q2 Review):**
- Should be at 50% of annual revenue and expenses
- Forecast year-end position: surplus or deficit?

**September 30 (Q3 Review):**
- Should be at 75% mark
- Plan year-end fundraisers if revenue lagging

**December 31 (Year-End Close):**
- Final actuals vs budget
- Surplus rolls into next year's beginning balance
- Prepare annual report for CEB

---

## 🔍 **Step 7: Common Tasks**

### **Task 1: Send Dues Reminder to Member**

1. **Find Member's Contact Record**
   - Click **Contacts** tab
   - Search member name
   - Click name to open record

2. **Check Dues Status**
   - View **Membership Dues Status** field
   - See **Dues Expiration Date**

3. **Send Email Reminder**
   - Click **Send Email** button (top-right)
   - Select template: "Dues Renewal Reminder"
   - Email auto-populates with member name, amount due, payment link
   - Click **Send**

4. **Log Follow-Up Activity**
   - Click **New Task** button
   - **Subject:** "Follow up on dues payment"
   - **Due Date:** 2 weeks from today
   - **Assigned To:** Yourself
   - **Save**

---

### **Task 2: Reconcile Bank Statement**

**Frequency:** Monthly (after bank statement arrives)

**Steps:**

1. **Download Bank Transactions**
   - Log into chapter checking account
   - Download transactions for month (CSV format)
   - Save file: "Bank Statement - September 2025.csv"

2. **Compare to Salesforce**
   - Open **Cash Balance** report in Treasurer's Corner
   - Filter dates: September 1 - September 30
   - Export Salesforce transactions to Excel

3. **Match Transactions**
   - Open both files side-by-side
   - Check off matching transactions:
     - Dues payments
     - Donation deposits
     - Expense checks cleared
   - **Identify Discrepancies:**
     - Bank shows transaction not in Salesforce? → Record missing income/expense
     - Salesforce shows transaction not in bank? → May still be pending

4. **Verify Ending Balance Match**
   - Bank statement ending balance: $[amount]
   - Salesforce cash balance: $[amount]
   - **If match:** Reconciliation complete ✅
   - **If don't match:** Investigate discrepancy, update Salesforce

5. **Document Reconciliation**
   - Click **Files** tab in Treasurer's Corner
   - Upload bank statement PDF
   - Add note: "September 2025 reconciliation complete - balances match"

---

### **Task 3: Process Reimbursement Request**

**Example:** Road Captain spent $75 on ride safety supplies, needs reimbursement

**Steps:**

1. **Verify Expense Approved**
   - Check meeting minutes or email from Commander
   - Pre-approval required for >$50 expenses

2. **Review Receipt**
   - Request itemized receipt from member
   - Verify purchase matches approved expense
   - Check date (must be within 90 days)

3. **Create Expense Opportunity**
   - **Opportunities** → **New**
   - **Record Type:** Expense
   - **Opportunity Name:** "Ride Safety Supplies - Reimbursement to [Name]"
   - **Amount:** -$75
   - **Expense Category:** Events - Supplies
   - **Payment Method:** Reimbursement
   - **Attach Receipt:** Upload photo of receipt

4. **Issue Reimbursement Check**
   - Write check from chapter account
   - Check payable to: Member name
   - Amount: $75
   - Memo: "Ride Safety Supplies - Sept Ride"
   - Get Commander signature (two signatures required for checks >$50)

5. **Record Check Number**
   - Return to expense opportunity
   - **Check Number:** [enter check number]
   - **Reimbursement Paid:** Checked (Yes)
   - **Payment Date:** Today
   - **Save**

6. **Give Check to Member**
   - Hand-deliver at next meeting OR
   - Mail to member's address
   - Get signed receipt (optional but recommended)

---

### **Task 4: Run Year-End Financial Report**

**Timing:** December 31 or early January

**Purpose:** Annual summary for CEB, National CVMA reporting, tax filing

**Steps:**

1. **Run Annual Summary Report**
   - **Reports** → "Annual Financial Summary"
   - Date range: January 1 - December 31, [year]
   - Click **Run Report**

2. **Export to Excel**
   - Click **Export** → **Excel Format**
   - Save file: "CVMA 20-7 Annual Report [Year].xlsx"

3. **Review Key Sections:**
   - **Total Revenue:** All income sources for year
   - **Total Expenses:** All spending for year
   - **Net Income:** Surplus or deficit
   - **Ending Cash Balance:** December 31 balance
   - **Top Donors:** Members who gave most (thank personally)
   - **Top Expenses:** Largest spending categories

4. **Present to CEB**
   - January CEB meeting
   - Review financial health
   - Discuss budget adjustments for new year

5. **Submit to National CVMA** (if required)
   - Check National Bylaws for reporting requirements
   - Some regions require annual financial report
   - Submit via email or online portal

6. **File for Tax Return** (if chapter files taxes)
   - Provide annual report to chapter accountant
   - 501(c)(19) organizations may need to file Form 990
   - Consult accountant or tax advisor

---

## 🚨 **Troubleshooting Common Issues**

### **Issue 1: Cash Balance Doesn't Match Bank Statement**

**Cause:** Missing transactions or timing differences

**Resolution:**
1. Run **Cash Balance Report** for month
2. Compare to bank statement line-by-line
3. Look for:
   - Deposits in bank not in Salesforce (missing income)
   - Checks cleared in bank not in Salesforce (missing expense)
   - Pending transactions (check written but not cashed yet)
4. Record missing transactions
5. Verify balances now match

---

### **Issue 2: Member's Dues Status Shows "Past Due" but They Paid**

**Cause:** Payment not recorded correctly

**Resolution:**
1. Find member's Contact record
2. Click **Related** → **Opportunities**
3. Look for dues payment opportunity
4. Check:
   - **Amount:** $80 (correct amount?)
   - **Close Date:** Within current year?
   - **Stage:** Closed Won (not "Pledged" or "Prospecting")
   - **Record Type:** Membership Dues (not Donation)
5. If opportunity missing, create new dues opportunity
6. If opportunity exists but wrong stage, edit and change to "Closed Won"
7. Dues status updates automatically within 15 minutes

---

### **Issue 3: Budget vs Actual Chart Not Updating**

**Cause:** GAU allocations missing on opportunities

**Resolution:**
1. **Reports** → **Opportunities Without GAU Allocations**
2. Open each opportunity missing allocation
3. Add GAU allocation:
   - **GAU:** Select budget category (Events, Operations, etc.)
   - **Amount:** Same as opportunity amount
   - **Save**
4. Repeat for all opportunities
5. Return to dashboard, click **Refresh**
6. Budget chart now shows correct data

---

### **Issue 4: Can't Find Specific Transaction**

**Cause:** Search filters too restrictive or transaction in wrong object

**Resolution:**
1. **Use Global Search:**
   - Click search box (top of page)
   - Enter: Amount, member name, or check number
   - Example: "$500" or "John Smith" or "Check 1234"
   - Results show all matching records

2. **Check Multiple Objects:**
   - Opportunities (most income/expenses)
   - Campaigns (event-specific transactions)
   - Payments (NPSP payment records)

3. **Adjust Date Filters:**
   - Remove date filters ("All Time")
   - Look for transaction in previous year

4. **Contact Support:**
   - If still can't find, contact Secretary or Commander
   - Provide: Date, amount, member name, description
   - They can help search or recover deleted records

---

## 📞 **Getting Help**

### **Treasurer Support Resources:**

**Quick Questions:**
- Contact previous Treasurer (transition mentor)
- Contact Commander for policy questions
- Contact Secretary for Salesforce technical issues

**Monthly Treasurer Call:** (Optional)
- State or regional treasurers meet monthly via Zoom
- Share best practices, troubleshoot issues
- Contact State Representative for details

**CVMA National Resources:**
- National Bylaws Appendix D (Financial Management)
- CVMA National Treasurer's Manual (if available)
- Email: national-treasurer@combatvet.org

**Salesforce NPSP Support:**
- NPSP Help Documentation: help.salesforce.com/npsp
- Trailhead Learning: NPSP Basics (free online course)
- Salesforce Community Forums

---

## ✅ **Treasurer Onboarding Checklist**

Use this checklist during your first month as Treasurer:

- [ ] **Access Treasurer's Corner** - Verify permission set assigned
- [ ] **Review Bylaws Appendix D** - Understand treasurer responsibilities
- [ ] **Meet with Previous Treasurer** - 1-2 hour transition meeting
- [ ] **Learn Dashboard** - Explore all sections and reports
- [ ] **Record Test Transaction** - Create sample income/expense (then delete)
- [ ] **Reconcile Last Month** - Practice bank reconciliation
- [ ] **Generate Monthly Report** - Run report for current month
- [ ] **Present at CEB Meeting** - Deliver first monthly treasurer report
- [ ] **Set Up Email Alerts** - Configure low balance warnings
- [ ] **Review Budget** - Understand annual budget allocations
- [ ] **Get Check Signing Authority** - Add name to chapter bank account
- [ ] **Secure Financial Records** - Set up password manager for bank login
- [ ] **Schedule Recurring Tasks** - Monthly reconciliation, quarterly budget review

---

## 🎖️ **Treasurer's Oath**

As CVMA Treasurer, you are entrusted with the chapter's financial health and members' hard-earned dues. This is a position of honor and responsibility.

**Your Commitment:**
- ✅ **Transparency:** Provide accurate monthly reports to CEB
- ✅ **Integrity:** Handle all funds honestly and ethically
- ✅ **Accountability:** Maintain complete financial records
- ✅ **Stewardship:** Protect chapter assets as if your own
- ✅ **Service:** Support the CVMA mission - "Vets Serving Vets"

**Remember:** Every dollar you manage goes toward serving combat veterans. Whether it's funding a chapter ride, helping a member in crisis, or donating to veteran charities, you're making a difference.

**Thank you for your service to CVMA Chapter 20-7.**

---

🎖️ **Generated with [Claude Code](https://claude.com/claude-code)**
**Date:** October 6, 2025
**For:** CVMA Chapter 20-7 Treasurer & CEB Financial Officers
**Questions:** treasurer@cvma20-7.org
**Technical Support:** secretary@cvma20-7.org
