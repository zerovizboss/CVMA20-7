# NPSP Reports Configuration for CVMA

## Required Report Configurations

### 1. Member Dues Tracking Report
- **Base Report**: NPSP Opportunities by Contact
- **Filters**:
  - RecordType = 'Donation'
  - Campaign Name contains 'Annual Dues'
  - Contact Level__c IN ('Full Member', 'Associate', 'Prospect')
- **Grouping**: By Contact Level__c
- **Summary Fields**: Amount (Sum), Payment Count

### 2. Payment History Dashboard
- **Base Report**: NPSP Payment History
- **Filters**:
  - Payment Date = CURRENT_FISCAL_YEAR
  - Amount >= 30 (minimum dues)
- **Chart Type**: Bar Chart by Month
- **Dashboard Component**: Financial Summary

### 3. Outstanding Dues Report
- **Base Report**: NPSP Outstanding Pledges
- **Filters**:
  - Stage = 'Pledged'
  - Campaign Type = 'CVMA Event' OR Name contains 'Dues'
- **Sorting**: By Days Overdue (DESC)

### 4. Treasurer Dashboard Components
1. Total Revenue YTD (from NPSP Revenue Dashboard)
2. Outstanding Dues (custom component)
3. Payment Methods Breakdown (NPSP Payment Analysis)
4. Member Payment Status (NPSP Donor Analysis)

## Implementation Steps
1. Navigate to Reports tab in Salesforce
2. Create new folder: 'CVMA Financial Analytics'
3. Clone NPSP reports and apply CVMA filters
4. Create dashboard from configured reports
5. Share with CVMA Treasurer users
