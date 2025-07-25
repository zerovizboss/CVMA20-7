# CVMA Guest User Scheduler Access - Testing Guide

## Overview
This guide provides comprehensive testing procedures to verify that guest users can access Service Appointments, Cases, and Events through the Combat Veterans Motorcycle Association Experience Builder site.

## Pre-Test Setup

### 1. Deploy All Changes
```bash
# Deploy all modified metadata
sf project deploy start --source-dir src/profiles
sf project deploy start --source-dir src/sharingRules
sf project deploy start --source-dir src/networks
sf project deploy start --source-dir src/sites
sf project deploy start --source-dir src/permissionsets
sf project deploy start --source-dir src/classes
```

### 2. Verify Deployment
```bash
# Run the test class
sf apex run test --class-names CVMAGuestUserSchedulerAccessTest --result-format human

# Check for any deployment errors
sf project deploy report
```

## Automated Testing

### Run Apex Test Class
```bash
# Execute the comprehensive test suite
sf apex run test --class-names CVMAGuestUserSchedulerAccessTest --code-coverage --result-format json

# Expected Results:
# - All 6 test methods should pass
# - Code coverage should be adequate
# - No DML or SOQL limit exceptions
```

### Test Coverage Validation
The test class validates:
- ✅ Service Appointment CRUD operations for guest users
- ✅ Case read-only access with proper filtering
- ✅ Event read-only access with privacy filtering  
- ✅ Sharing rules effectiveness
- ✅ Profile permissions verification
- ✅ Guest user creation and authentication

## Manual Testing Procedures

### Phase 1: Community Setup Verification

#### 1.1 Verify Community Configuration
1. **Navigate to Setup > All Communities**
2. **Select "Combat Veterans Motorcycle Association"**
3. **Verify Settings:**
   - Status: Published ✓
   - Guest User Profile: Guest License User ✓
   - URL is accessible ✓

#### 1.2 Check Guest User Profile
1. **Go to Setup > Profiles > Guest License User**
2. **Verify Object Permissions:**
   ```
   ServiceAppointment: Create ✓, Read ✓, Edit ✓, Delete ✗
   Case: Create ✗, Read ✓, Edit ✗, Delete ✗
   Event: Create ✗, Read ✓, Edit ✗, Delete ✗
   ServiceResource: Read ✓
   ServiceTerritory: Read ✓
   ```
3. **Verify Application Access:**
   - Lightning Scheduler: Visible ✓
4. **Verify Tab Settings:**
   - ServiceAppointment: Available ✓

### Phase 2: Experience Builder Site Testing

#### 2.1 Access Community as Guest
1. **Open Incognito/Private Browser Window**
2. **Navigate to Community URL:**
   ```
   https://[your-org].lightning.force.com/lightning/r/[community-name]/home
   ```
3. **Verify Guest Access:**
   - No login required ✓
   - Community loads successfully ✓
   - Guest user session established ✓

#### 2.2 Scheduler Component Access
1. **Look for Scheduler Components in Experience Builder:**
   - Navigate to Experience Builder
   - Check available components for Scheduler
   - Verify Service Appointment components are available

2. **Add Scheduler Components to Pages:**
   ```
   Recommended Components:
   - Service Appointment List
   - Service Appointment Calendar
   - Appointment Booking Flow
   ```

### Phase 3: Functional Testing

#### 3.1 Service Appointment Testing

**Test Data Setup (as Admin):**
```sql
-- Create test Service Appointments
INSERT ServiceAppointment (
    Subject = 'Public CVMA Meeting',
    Status = 'Scheduled',
    SchedStartTime = TOMORROW 10:00 AM,
    SchedEndTime = TOMORROW 11:00 AM,
    Description = 'Public meeting for all members'
);

INSERT ServiceAppointment (
    Subject = 'Canceled Meeting',
    Status = 'Canceled',
    SchedStartTime = TOMORROW 2:00 PM,
    SchedEndTime = TOMORROW 3:00 PM,
    Description = 'This should not be visible to guests'
);
```

**Guest User Testing:**
1. **View Service Appointments:**
   - Should see "Public CVMA Meeting" ✓
   - Should NOT see "Canceled Meeting" ✓
   - Verify appointment details are readable ✓

2. **Create Service Appointment:**
   - Click "New Appointment" or similar button ✓
   - Fill required fields ✓
   - Successfully save appointment ✓
   - Verify appointment appears in list ✓

3. **Edit Service Appointment:**
   - Select existing appointment ✓
   - Modify description or other editable fields ✓
   - Save changes successfully ✓
   - Verify changes are reflected ✓

#### 3.2 Case Visibility Testing

**Test Data Setup (as Admin):**
```sql
-- Create test Cases
INSERT Case (
    Subject = 'Public Inquiry',
    Type = 'Question',
    Status = 'New',
    Description = 'Public case visible to guests'
);

INSERT Case (
    Subject = 'Internal Issue',
    Type = 'Internal',
    Status = 'New',
    Description = 'Internal case not visible to guests'
);
```

**Guest User Testing:**
1. **View Cases in Related Lists:**
   - Should see "Public Inquiry" ✓
   - Should NOT see "Internal Issue" ✓
   - Verify case details are readable ✓

2. **Attempt Case Creation (Should Fail):**
   - Try to create new case ✓
   - Should receive permission error ✓
   - Verify no case is created ✓

#### 3.3 Event Visibility Testing

**Test Data Setup (as Admin):**
```sql
-- Create test Events
INSERT Event (
    Subject = 'Public CVMA Event',
    IsPrivate = false,
    StartDateTime = TOMORROW 6:00 PM,
    EndDateTime = TOMORROW 8:00 PM,
    Description = 'Public event for community'
);

INSERT Event (
    Subject = 'Private Meeting',
    IsPrivate = true,
    StartDateTime = TOMORROW 3:00 PM,
    EndDateTime = TOMORROW 4:00 PM,
    Description = 'Private event not visible to guests'
);
```

**Guest User Testing:**
1. **View Events in Calendar:**
   - Should see "Public CVMA Event" ✓
   - Should NOT see "Private Meeting" ✓
   - Verify event details are readable ✓

2. **Calendar Integration:**
   - Events should appear on scheduler calendar ✓
   - Time slots should be accurate ✓
   - Event descriptions should be visible ✓

### Phase 4: Security Testing

#### 4.1 Data Access Validation
1. **Test Record Level Security:**
   - Guest user sees only permitted records ✓
   - Sharing rules are enforced ✓
   - No unauthorized data access ✓

2. **Test Field Level Security:**
   - Sensitive fields are hidden ✓
   - Required fields are accessible ✓
   - Field permissions are enforced ✓

#### 4.2 Operation Restrictions
1. **Delete Operations (Should Fail):**
   - Try to delete Service Appointment ✗
   - Try to delete Case ✗
   - Try to delete Event ✗

2. **Bulk Operations (Should be Limited):**
   - Mass update attempts should be restricted ✓
   - Bulk delete should be prevented ✓

### Phase 5: User Experience Testing

#### 5.1 Navigation Testing
1. **Menu Access:**
   - Scheduler links are visible ✓
   - Navigation is intuitive ✓
   - No broken links ✓

2. **Mobile Responsiveness:**
   - Test on mobile device ✓
   - Scheduler components work on mobile ✓
   - Forms are mobile-friendly ✓

#### 5.2 Performance Testing
1. **Page Load Times:**
   - Community loads within 3 seconds ✓
   - Scheduler components load quickly ✓
   - No timeout errors ✓

2. **Data Loading:**
   - Appointment lists load efficiently ✓
   - Calendar views render properly ✓
   - Search functionality works ✓

## Troubleshooting Common Issues

### Issue 1: Guest User Cannot Access Scheduler
**Symptoms:** Scheduler not visible or accessible
**Solutions:**
1. Verify Lightning Scheduler app visibility in profile
2. Check ServiceAppointment tab settings
3. Confirm permission set assignment
4. Review community member groups

### Issue 2: Limited Data Visibility
**Symptoms:** Expected records not showing
**Solutions:**
1. Review sharing rule criteria
2. Check record ownership
3. Verify guest user profile in community
4. Test sharing rule activation

### Issue 3: Permission Errors
**Symptoms:** "Insufficient privileges" errors
**Solutions:**
1. Verify object permissions in profile
2. Check field-level security
3. Review custom permission set
4. Confirm community settings

### Issue 4: Calendar Not Loading
**Symptoms:** Calendar component blank or error
**Solutions:**
1. Check OperatingHours configuration
2. Verify ServiceTerritory setup
3. Review WorkType permissions
4. Test with different browsers

## Test Results Documentation

### Test Execution Checklist
- [ ] Automated tests pass (6/6 methods)
- [ ] Community accessible to guest users
- [ ] Service Appointments CRUD operations work
- [ ] Case visibility filtering works
- [ ] Event privacy filtering works
- [ ] Sharing rules are effective
- [ ] Security restrictions are enforced
- [ ] Mobile experience is functional
- [ ] Performance is acceptable

### Sign-off Criteria
| Test Category | Status | Notes |
|---------------|--------|-------|
| Automated Tests | ✅/❌ | All test methods passing |
| Guest Access | ✅/❌ | Community accessible without login |
| Service Appointment CRUD | ✅/❌ | Create, Read, Edit working |
| Data Filtering | ✅/❌ | Sharing rules effective |
| Security | ✅/❌ | Proper restrictions in place |
| User Experience | ✅/❌ | Intuitive and responsive |

### Final Validation Commands
```bash
# Run comprehensive validation
sf apex run test --class-names CVMAGuestUserSchedulerAccessTest

# Check community status
sf community list

# Verify metadata deployment
sf project deploy validate --source-dir src

# Generate test report
sf apex get test --test-run-id [TEST_RUN_ID] --output-dir test-results
```

## Conclusion
This testing guide ensures comprehensive validation of guest user access to the Salesforce Scheduler functionality in the Combat Veterans Motorcycle Association community. Follow all phases systematically to confirm proper implementation and security compliance.