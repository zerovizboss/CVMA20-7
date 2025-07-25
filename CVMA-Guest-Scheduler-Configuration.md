# Combat Veterans Motorcycle Association - Guest User Scheduler Access Configuration

## Overview
This configuration enables guest users in the Combat Veterans Motorcycle Association community to access Service Appointments on the Salesforce Scheduler calendar, allowing them to view Cases, Events, and Appointments.

## Files Modified/Created

### 1. Profile Configuration
**File:** `src/profiles/Guest License User.profile`
- **Added ServiceAppointment object permissions** with read, create, and edit access
- **Added Event object permissions** with read access
- **Added Case object permissions** with read access  
- **Enabled Salesforce Scheduler application** (`standard__LightningScheduler`)
- **Made ServiceAppointment tab available** (changed from Hidden to Available)

### 2. Sharing Rules
Created sharing rules to grant guest users appropriate access:

**File:** `src/sharingRules/ServiceAppointment.sharingRules`
- Grants Edit access to Combat Veterans guest users for non-canceled Service Appointments

**File:** `src/sharingRules/Case.sharingRules`
- Grants Read access to Combat Veterans guest users for non-internal Cases

**File:** `src/sharingRules/Event.sharingRules`
- Grants Read access to Combat Veterans guest users for public Events

### 3. Community Configuration
**File:** `src/networks/Combat Veterams Motorcycle Association.network`
- **Added Guest License User profile** to network member groups
- **Added CVMA_Guest_Scheduler_Access permission set** to network

**File:** `src/sites/Combat_Veterams_Motorcycle_Association.site`
- **Enabled standard lookups** for better functionality
- **Enabled standard search** for improved user experience

### 4. Permission Set
**File:** `src/permissionsets/CVMA_Guest_Scheduler_Access.permissionset`
- **Service Appointment access**: Create, Read, Edit permissions
- **Event access**: Read permission
- **Case access**: Read permission  
- **Service Resource access**: Read permission
- **Service Territory access**: Read permission
- **ServiceAppointment tab**: Available
- **Lightning Scheduler app**: Visible

## Deployment Instructions

1. **Deploy to Salesforce org:**
   ```bash
   sf project deploy start --source-dir src/profiles
   sf project deploy start --source-dir src/sharingRules
   sf project deploy start --source-dir src/networks
   sf project deploy start --source-dir src/sites
   sf project deploy start --source-dir src/permissionsets
   ```

2. **Verify deployment:**
   ```bash
   sf project deploy start --check-only
   ```

## Testing Steps

### 1. Verify Guest User Profile Access
1. Navigate to **Setup > Profiles > Guest License User**
2. Confirm object permissions:
   - ServiceAppointment: Create, Read, Edit ✓
   - Event: Read ✓
   - Case: Read ✓
3. Verify tab visibility:
   - ServiceAppointment tab: Available ✓
4. Check application access:
   - Lightning Scheduler: Visible ✓

### 2. Test Community Access
1. Go to **Setup > All Communities**
2. Open **Combat Veterans Motorcycle Association** community
3. Verify **Guest License User** profile is associated
4. Confirm **CVMA_Guest_Scheduler_Access** permission set is enabled

### 3. Test Guest User Experience
1. **Access community as guest user**:
   - Navigate to community URL without authentication
   - Should be able to access as guest

2. **Verify Scheduler Calendar Access**:
   - Guest user should see Service Appointments
   - Should be able to view appointment details
   - Should be able to create new appointments
   - Should be able to modify existing appointments

3. **Verify Related Object Access**:
   - Cases should be visible in related lists/calendar
   - Events should display on calendar
   - Service Resources should be selectable

### 4. Validate Sharing Rules
1. **Check ServiceAppointment sharing**:
   - Guest users should see non-canceled appointments
   - Should have edit access for creating/modifying

2. **Verify Case and Event sharing**:
   - Public cases should be visible
   - Non-private events should appear on calendar

## Security Considerations

### Data Access Controls
- **Service Appointments**: Guest users can create/edit appointments but cannot delete
- **Cases**: Read-only access, excludes internal cases
- **Events**: Read-only access, excludes private events
- **Service Resources/Territories**: Read-only for appointment booking context

### Community Safeguards
- Guest users are restricted to community context only
- Standard Salesforce security model applies
- Sharing rules provide additional access controls
- Profile permissions limit scope of data access

## Troubleshooting

### Common Issues
1. **Guest user cannot see Scheduler**:
   - Verify Lightning Scheduler app is visible in profile
   - Check ServiceAppointment tab visibility
   - Confirm permission set assignment

2. **Limited appointment visibility**:
   - Review sharing rules configuration
   - Verify guest user profile in community
   - Check Service Appointment record-level security

3. **Cannot create appointments**:
   - Confirm Create permission on ServiceAppointment object
   - Verify required field permissions are granted
   - Check page layout assignments

### Validation Commands
```bash
# Check deployment status
sf project deploy report

# Validate metadata
sf project retrieve start --metadata Profile:Guest_License_User
sf project retrieve start --metadata PermissionSet:CVMA_Guest_Scheduler_Access
```

## Additional Notes
- This configuration follows Salesforce best practices for guest user security
- Regular review of sharing rules and permissions is recommended
- Consider implementing additional validation rules if needed for data quality
- Monitor guest user activity through setup audit trail