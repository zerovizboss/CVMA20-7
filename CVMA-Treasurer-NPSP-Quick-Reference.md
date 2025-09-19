# CVMA Treasurer NPSP Reports & Dashboards Quick Reference Guide

## 🎯 Overview
This quick reference guide helps CVMA treasurers transition from custom financial dashboards to enterprise-grade NPSP Reports & Dashboards, providing the same financial insights with enhanced functionality.

## 📊 Your New Financial Dashboards

### 1. CVMA Financial Overview Dashboard
**Purpose**: Real-time financial health monitoring
**Access**: Apps → Reports → Dashboards → "CVMA Financial Analytics" folder

**Key Metrics Available**:
- 💰 **Total Revenue (Current Year)**: Live revenue tracking
- ⚠️ **Outstanding Dues**: Members with unpaid dues
- 📈 **Collection Rate**: Percentage of successful payments
- 👥 **Dues by Member Level**: $120 Full / $60 Associate / $30 Prospect
- 💳 **Payment Methods**: Cash, Check, Credit Card, Bank Transfer, PayPal, Venmo
- 📅 **Monthly Trends**: 12-month revenue pattern

**Mobile Access**: Fully responsive on phone/tablet

### 2. CVMA Campaign Performance Dashboard
**Purpose**: Event financial performance with RSVP integration
**Access**: Apps → Reports → Dashboards → "CVMA Campaign Performance"

**Event Analytics**:
- 🎪 **Campaign ROI**: Revenue vs expenses for each event
- 📋 **RSVP Integration**: Attendance vs revenue analysis (from User Story #15)
- 💵 **Event Revenue**: Breakdown by event type
- 📊 **Success Metrics**: Events performance summary with KPIs

### 3. CVMA Member Payment Analytics Dashboard
**Purpose**: Member dues compliance and payment tracking
**Access**: Apps → Reports → Dashboards → "CVMA Payment Analytics"

**Payment Insights**:
- ✅ **Dues Compliance**: Payment status by member level
- 🔴 **Overdue Alerts**: Members 30+ days past due
- 💸 **Processing Fees**: Cost analysis by payment method
- 📈 **Payment Patterns**: Seasonal trends and timing

## 📋 Essential Reports for Treasurers

### Daily Reports (Check These Every Morning)

#### 1. "Outstanding Dues Alert Report"
**Location**: Reports → CVMA Financial Analytics → 01 - Executive Summary
**Purpose**: See which members have unpaid dues
**Filters**: Opportunity.StageName = 'Pledged', Amount > 0
**Columns**: Member Name, Level, Amount Due, Days Overdue
**Action**: Follow up with overdue members

#### 2. "New Payments Received (Yesterday)"
**Location**: Reports → CVMA Financial Analytics → 02 - Member Dues & Payments
**Purpose**: Track payments received in last 24 hours
**Filters**: Payment Date = YESTERDAY
**Columns**: Member Name, Amount, Payment Method, Time Received
**Action**: Verify deposits and update records

### Weekly Reports (Check Every Monday)

#### 3. "Weekly Financial Summary"
**Location**: Reports → CVMA Financial Analytics → 05 - Monthly & Annual Reporting
**Purpose**: Week-over-week revenue comparison
**Metrics**: Total Revenue, Payment Count, Average Payment, Collection Rate
**Format**: Trend chart with weekly breakdown
**Action**: Prepare weekly update for officers

#### 4. "Campaign Performance Update"
**Location**: Reports → CVMA Financial Analytics → 03 - Campaign & Event Analytics
**Purpose**: Event revenue and attendance tracking
**Integration**: Shows RSVP data from Campaign Members (User Story #15)
**Metrics**: Revenue per event, Cost per RSVP, ROI percentage
**Action**: Plan future events based on performance data

### Monthly Reports (1st of Each Month)

#### 5. "Monthly Financial Dashboard (PDF Export)"
**Location**: Any dashboard → Actions → Subscribe
**Purpose**: Comprehensive monthly summary for board meetings
**Format**: PDF automatically emailed on 1st of month at 9:00 AM
**Contents**: All dashboard components, charts, and key metrics
**Action**: Review before board meeting and prepare financial report

#### 6. "Member Payment Compliance Status"
**Location**: Reports → CVMA Financial Analytics → 02 - Member Dues & Payments
**Purpose**: Overall dues compliance by member level
**Format**: Funnel chart showing compliance stages
**Metrics**: % paid on time, % 30+ days late, % 60+ days late
**Action**: Identify members needing payment reminders

## 🔍 How to Find Specific Information

### "Where is my old custom dashboard data?"

#### **Old Custom Tab: "Financial Summary"** → **New Location:**
- **Revenue Totals**: Development Analysis Dashboard → Total Revenue component
- **Payment Breakdown**: Payment Analytics Dashboard → Payment Method component
- **Member Analysis**: Financial Overview Dashboard → Dues by Level component

#### **Old Custom Tab: "Payment Records"** → **New Location:**
- **Payment List**: Reports → "NPSP Payment History by Contact"
- **Payment Status**: Payment Analytics Dashboard → Dues Compliance component
- **Method Analysis**: Payment Analytics Dashboard → Processing Fee component

#### **Old Custom Tab: "Transactions"** → **New Location:**
- **Event Revenue**: Campaign Performance Dashboard → Event Revenue component
- **Campaign ROI**: Campaign Performance Dashboard → ROI Analysis component
- **Monthly Trends**: Financial Overview Dashboard → Monthly Trends component

### Common Tasks & Where to Do Them

#### **Task**: "Check if John Smith paid his dues"
**Solution**: Reports → "NPSP Payment History by Contact" → Filter by Contact Name
**Alternative**: Contacts tab → Find John Smith → Related → Payments

#### **Task**: "See which payment methods are most popular"
**Solution**: Payment Analytics Dashboard → Payment Method Performance component
**Alternative**: Reports → "Payment Method Analysis" → View pie chart

#### **Task**: "Get event revenue for last motorcycle ride"
**Solution**: Campaign Performance Dashboard → Event Revenue component
**Filter**: Campaign Name contains "Ride"
**Alternative**: Campaigns tab → Find specific ride → Related → Opportunities

#### **Task**: "Find members who haven't paid 2025 dues"
**Solution**: Reports → "Outstanding Dues Alert Report"
**Filter**: Campaign = "Annual Dues 2025", Stage = "Pledged"
**Action**: Export list for follow-up calls

## 📱 Mobile Access Guide

### Accessing Dashboards on Phone/Tablet

1. **Salesforce Mobile App**: Download from App Store/Google Play
2. **Login**: Use same CVMA org credentials
3. **Navigation**: Menu → Reports → Dashboards
4. **Mobile Dashboard**: "CVMA Treasurer Mobile Dashboard" (simplified view)

**Mobile Dashboard Components**:
- 💰 Revenue (Current Month)
- ⚠️ Outstanding Dues Count
- ✅ Collection Rate %
- 📋 Recent Payments (Last 7 days)

### Mobile Quick Actions
- 👆 **Tap any chart**: Drill down to underlying report
- 📧 **Share Dashboard**: Email snapshot to officers
- 🔄 **Pull to Refresh**: Update data instantly
- 🔍 **Search Reports**: Find specific report quickly

## ⚙️ Automated Features (No Action Required)

### Email Subscriptions (Already Configured)

**Daily (7:00 AM)**:
- ✉️ Outstanding Dues Alert Report
- ✉️ New Payments Received (Previous Day)
- ✉️ Payment Processing Errors (if any)

**Weekly (Monday 8:00 AM)**:
- ✉️ Weekly Financial Summary
- ✉️ Campaign Performance Update
- ✉️ Member Payment Compliance Status

**Monthly (1st @ 9:00 AM)**:
- ✉️ Monthly Dashboard PDF Export
- ✉️ CVMA Board Financial Summary
- ✉️ Year-to-Date Performance vs Goals

### Auto-Refresh Settings

**Real-time (Every 15 minutes)**:
- Payment processing status updates
- Outstanding dues alerts
- Campaign RSVP updates

**Daily (6:00 AM)**:
- Member compliance reports
- Monthly trend analysis
- Payment method performance

## 🆚 Old vs New Comparison

### What's Better with NPSP Reports?

| **Capability** | **Old Custom Dashboard** | **New NPSP Reports** |
|---|---|---|
| **Reports Available** | 8 custom reports | 67 enterprise reports |
| **Real-time Data** | Manual refresh only | Auto-refresh every 15 min |
| **Mobile Access** | Desktop only | Full mobile responsive |
| **Export Options** | CSV only | PDF, Excel, CSV |
| **Scheduling** | Manual only | Automated email delivery |
| **Drill-down** | Limited | Full drill-down capability |
| **Charts/Visuals** | Basic charts | Professional dashboards |
| **Integration** | Custom code | Standard Salesforce |
| **Maintenance** | Requires developer | Self-maintaining |
| **Upgrades** | Manual updates | Automatic Salesforce updates |

### What Stays the Same?

- ✅ All your financial data (no data migration needed)
- ✅ CVMA-specific dues amounts ($120/$60/$30)
- ✅ Payment methods (Cash, Check, Credit Card, etc.)
- ✅ Member levels (Full Member, Associate, Prospect)
- ✅ Campaign/Event tracking with RSVP integration
- ✅ Treasurer role permissions and access

## 🚨 Important Notes

### Data Accuracy
- **All reports use the same NPSP data** that was implemented in User Story #14
- **Campaign integration** connects with User Stories #15 (RSVP) and #16 (Calendar)
- **No data loss** - everything from custom dashboards is preserved

### Getting Help
- **Salesforce Help**: Click "Help" in upper right corner of any page
- **CVMA Support**: Contact system administrator for CVMA-specific questions
- **Report Issues**: Use "Feedback" link in any report that doesn't look right

### Backup Access
- **Custom dashboards remain available** during transition period (30 days)
- **Reports can be compared** side-by-side for validation
- **Rollback plan exists** if any issues are discovered

## 🎯 Quick Start Checklist

**Week 1: Get Familiar**
- [ ] Login and explore "CVMA Financial Analytics" folder
- [ ] Open each of the 3 main dashboards
- [ ] Compare data with old custom dashboard
- [ ] Test mobile access on your phone

**Week 2: Daily Use**
- [ ] Check daily email reports (Outstanding Dues, New Payments)
- [ ] Use Financial Overview Dashboard for daily monitoring
- [ ] Try drilling down from charts to detailed reports
- [ ] Export a report to PDF/Excel

**Week 3: Advanced Features**
- [ ] Customize dashboard components (add/remove charts)
- [ ] Create personal report views with custom filters
- [ ] Set up additional email subscriptions if needed
- [ ] Share dashboard snapshots with other officers

**Week 4: Full Transition**
- [ ] Stop checking old custom dashboard
- [ ] Use NPSP dashboards for all financial analysis
- [ ] Prepare monthly board report using new PDF export
- [ ] Provide feedback on any missing functionality

## 📞 Support & Resources

**Need Help?**
- 📧 Email: CVMA system administrator
- 📱 Phone: [Contact information]
- 💬 Slack: #cvma-salesforce-support

**Training Resources**:
- 🎥 NPSP Dashboard Training Video: [Link]
- 📚 Salesforce Trailhead: "Reports and Dashboards for Nonprofits"
- 📖 Complete Configuration Guide: `CVMA-NPSP-Treasurer-Dashboard-Configuration.md`

## 🏆 Success Metrics

**You'll know the migration is successful when:**
- ✅ Daily financial monitoring takes less time than before
- ✅ Monthly board reports are more comprehensive and professional
- ✅ Mobile access lets you check finances anywhere
- ✅ Automated emails keep you informed without manual checking
- ✅ Officers comment on improved financial reporting quality
- ✅ You discover new insights from the 67 available reports

**Questions? We're here to help make this transition smooth for all CVMA treasurers!** 🎖️
