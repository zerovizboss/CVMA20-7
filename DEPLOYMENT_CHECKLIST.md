# CVMA Salesforce Best Practices - Deployment Checklist

## Pre-Deployment Checklist

### Environment Preparation
- [ ] Backup current org configuration
- [ ] Verify Salesforce CLI is installed and authenticated
- [ ] Confirm deployment user has System Administrator permissions
- [ ] Review current custom object and field limits
- [ ] Validate NPSP package is installed and up-to-date

### Code Review
- [ ] All Apex classes compile without errors
- [ ] Test classes have >90% code coverage
- [ ] Security review completed (WITH SECURITY_ENFORCED usage)
- [ ] Performance review completed (query optimization)
- [ ] Code follows naming conventions

## Deployment Steps

### Step 1: Deploy Custom Objects
```bash
sf project deploy start --source-dir src/objects/CVMA_Error_Log__c
```
- [ ] Custom object deployed successfully
- [ ] All custom fields created
- [ ] Object permissions configured
- [ ] Tab created and visible to appropriate profiles

**Validation:**
- [ ] Navigate to CVMA Error Log tab
- [ ] Verify all fields are accessible
- [ ] Test record creation manually

### Step 2: Deploy Custom Metadata Types
```bash
sf project deploy start --source-dir src/customMetadata
```
- [ ] CVMA_Application_Config metadata type deployed
- [ ] CVMA_Email_Template metadata type deployed
- [ ] All metadata records deployed successfully
- [ ] Values are accessible in org

**Validation:**
- [ ] Navigate to Setup > Custom Metadata Types
- [ ] Verify both types exist with all fields
- [ ] Check sample records are created with correct values

### Step 3: Deploy Apex Classes
```bash
sf project deploy start --source-dir src/classes/CVMAErrorHandler*
sf project deploy start --source-dir src/classes/CVMAConfigurationHelper*
sf project deploy start --source-dir src/classes/CVMATestDataFactory*
```
- [ ] CVMAErrorHandler and test deployed
- [ ] CVMAConfigurationHelper and test deployed
- [ ] CVMATestDataFactory and test deployed

**Validation:**
- [ ] All classes compile successfully
- [ ] No compilation errors in Developer Console
- [ ] Classes visible in Setup > Apex Classes

### Step 4: Deploy Enhanced Controllers
```bash
sf project deploy start --source-dir src/classes/CVMAMemberProfileControllerSecure*
sf project deploy start --source-dir src/classes/CVMAOfficerDashboardControllerOptimized*
```
- [ ] Secure controllers deployed successfully
- [ ] Enhanced test classes deployed

**Validation:**
- [ ] Controllers compile without errors
- [ ] Test methods execute successfully
- [ ] No security warnings in static analysis

### Step 5: Run Comprehensive Tests
```bash
sf apex run test
```
- [ ] All test classes pass
- [ ] Overall code coverage >90%
- [ ] No test failures or errors
- [ ] Performance tests complete within limits

**Test Results Documentation:**
- Total Tests Run: ___
- Passed: ___
- Failed: ___
- Code Coverage: ___%
- Execution Time: ___

### Step 6: Update Package.xml
- [ ] All new components added to package.xml
- [ ] Version number updated appropriately
- [ ] Full deployment validates successfully

```bash
sf project deploy start --check-only
```

## Post-Deployment Configuration

### Security Configuration
- [ ] Create custom permission: CVMA_Officer_Access
- [ ] Assign permission to appropriate profiles
- [ ] Configure field-level security for CVMA_Error_Log__c
- [ ] Set up sharing rules if needed

### Profile Configuration
- [ ] Grant access to CVMA Error Log object
- [ ] Enable custom metadata access
- [ ] Configure Lightning app permissions
- [ ] Test user access with different profiles

### Email Configuration
- [ ] Configure organization-wide email addresses
- [ ] Set up email deliverability settings
- [ ] Test email template rendering
- [ ] Verify SMTP settings

### Data Validation
- [ ] Test error logging functionality
- [ ] Validate configuration helper methods
- [ ] Verify membership ID generation
- [ ] Test email template merge fields

## Validation Testing

### Functional Testing
- [ ] Create test error log entry
- [ ] Test configuration value retrieval
- [ ] Validate membership ID generation
- [ ] Test email template functionality

### Security Testing
- [ ] Verify WITH SECURITY_ENFORCED works correctly
- [ ] Test CRUD/FLS validation
- [ ] Validate input sanitization
- [ ] Test guest user restrictions

### Performance Testing
- [ ] Test dashboard with large datasets
- [ ] Verify pagination functionality
- [ ] Test bulk operations
- [ ] Monitor governor limit usage

### Integration Testing
- [ ] Test with existing CVMA components
- [ ] Verify NPSP field integration
- [ ] Test community user access
- [ ] Validate email delivery

## Rollback Plan

### Immediate Rollback Steps
If critical issues are discovered:

1. **Disable New Components:**
   ```bash
   # Deactivate new classes
   sf apex update --name CVMAErrorHandler --status Inactive
   sf apex update --name CVMAConfigurationHelper --status Inactive
   ```

2. **Revert to Previous Controllers:**
   - Restore original controller versions
   - Update Lightning components to use original controllers

3. **Remove Custom Metadata:**
   - Delete custom metadata records if causing issues
   - Deactivate metadata types if necessary

### Full Rollback Steps
If complete rollback is needed:

1. **Export Current Data:**
   ```bash
   sf data export --query "SELECT * FROM CVMA_Error_Log__c"
   ```

2. **Remove Components:**
   ```bash
   sf project delete --metadata ApexClass:CVMAErrorHandler
   sf project delete --metadata ApexClass:CVMAConfigurationHelper
   sf project delete --metadata CustomObject:CVMA_Error_Log__c
   ```

3. **Restore Previous Version:**
   - Deploy from previous backup
   - Restore original configurations

## Monitoring Setup

### Error Monitoring
- [ ] Create CVMA Error Log report
- [ ] Set up critical error alerts
- [ ] Configure dashboard widgets
- [ ] Schedule weekly error summary

### Performance Monitoring
- [ ] Set up query performance tracking
- [ ] Monitor governor limit usage
- [ ] Track email send rates
- [ ] Monitor user adoption metrics

### Configuration Monitoring
- [ ] Set up metadata change tracking
- [ ] Monitor configuration value usage
- [ ] Track email template performance
- [ ] Monitor membership ID generation

## Documentation Updates

### Update CLAUDE.md
- [ ] Add new command references
- [ ] Update architecture notes
- [ ] Document new testing patterns
- [ ] Add maintenance procedures

### Update Team Documentation
- [ ] Train administrators on new features
- [ ] Update user guides
- [ ] Document troubleshooting procedures
- [ ] Create maintenance schedules

## Sign-off Checklist

### Technical Sign-off
- [ ] System Administrator: _________________ Date: _______
- [ ] Lead Developer: ______________________ Date: _______
- [ ] Security Reviewer: ___________________ Date: _______

### Business Sign-off  
- [ ] CVMA Chapter President: ______________ Date: _______
- [ ] IT Manager: ________________________ Date: _______
- [ ] End User Representative: ____________ Date: _______

## Contact Information

### Deployment Team
- **System Administrator:** [Name] - [Email] - [Phone]
- **Lead Developer:** [Name] - [Email] - [Phone]  
- **Project Manager:** [Name] - [Email] - [Phone]

### Support Contacts
- **Salesforce Support:** 1-800-NO-SOFTWARE
- **Internal IT Help Desk:** [Internal Number]
- **Emergency Contact:** [24/7 Contact Info]

## Deployment Log

### Deployment Attempt 1
- **Date:** _______________
- **Time:** _______________
- **Deployed By:** _________
- **Result:** _____________
- **Notes:** ______________

### Deployment Attempt 2 (if needed)
- **Date:** _______________
- **Time:** _______________
- **Deployed By:** _________
- **Result:** _____________
- **Notes:** ______________

---

**Deployment Guide Version:** 2.0  
**Last Updated:** January 2025  
**Next Review Date:** _______________