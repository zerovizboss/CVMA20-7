# VA Lighthouse API Activation Guide
## Combat Veterans Motorcycle Association Chapter 20-7

**Document Version**: 1.0.0
**Created**: September 19, 2025
**Status**: Ready for Production Activation

---

## 📋 **OVERVIEW**

This guide provides step-by-step instructions for activating real VA Lighthouse API integration once you receive your production credentials from the VA. The entire infrastructure is already deployed and ready - you just need to provide the actual API keys.

**Current Status**: ✅ Mock APIs Active, Real API Infrastructure Ready
**Activation Time**: 5-10 minutes once credentials are received
**Rollback Time**: Instant (toggle feature flags)

---

## 🔐 **STEP 1: OBTAIN VA LIGHTHOUSE API CREDENTIALS**

### Manual Registration Required
1. **Visit**: https://developer.va.gov/apply
2. **Organization Details**:
   - **Organization Name**: Combat Veterans Motorcycle Association Chapter 20-7
   - **Organization Type**: Non-profit veterans service organization
   - **Contact Information**: Your name, email, and phone
   - **Use Case**: "Veteran benefits optimization and member services enhancement for CVMA Chapter 20-7"

### APIs to Request Access For:
- ✅ **VA Forms API** - Access to VA form catalog and submission assistance
- ✅ **VA Facilities API** - Facility finder with geolocation services
- ✅ **VA Address Validation API** - Address verification and standardization
- ⭐ **VA Veterans Verification API** (Optional) - Veteran status verification

### Expected Credentials You'll Receive:
```
Client ID: [Your unique client identifier]
Client Secret: [Your secure client secret]
API Key: [Your API access key]
Environment: Sandbox or Production
```

---

## ⚙️ **STEP 2: CONFIGURE CREDENTIALS IN SALESFORCE**

### Option A: Protected Custom Settings (Recommended for Production)

1. **Navigate to**: Setup → Custom Settings → CVMA VA API Keys → Manage

2. **Create New Records**:
   ```
   Name: VA_OAuth_Client_ID
   Key Type: Client ID
   Environment: Production
   API Key Value: [Your Client ID from VA]
   Is Active: ✅

   Name: VA_OAuth_Client_Secret
   Key Type: Client Secret
   Environment: Production
   API Key Value: [Your Client Secret from VA]
   Is Active: ✅
   ```

### Option B: Enhanced Security (Enterprise Only)
If you have Shield Platform Encryption:
1. Enable encryption on the `API_Key_Value__c` field
2. Follow Option A steps with encryption active

---

## 🎛️ **STEP 3: ACTIVATE REAL API ACCESS**

### Enable Feature Flags
1. **Navigate to**: Setup → Custom Metadata Types → CVMA Application Config → Manage

2. **Update or Create These Records**:
   ```
   Label: ENABLE_REAL_VA_FORMS_API
   Boolean Value: ✅ True

   Label: ENABLE_REAL_VA_FACILITIES_API
   Boolean Value: ✅ True

   Label: ENABLE_REAL_VA_ADDRESS_API
   Boolean Value: ✅ True
   ```

### Update API Configurations
1. **Navigate to**: Setup → Custom Metadata Types → CVMA VA API Config → Manage

2. **For Each API (VA_Forms_API, VA_Facilities_API, VA_Address_Validation)**:
   - **Set `Use_Mock_API__c`**: ❌ False
   - **Set `Environment__c`**: Production (or Sandbox if testing)
   - **Verify `Is_Active__c`**: ✅ True

---

## 📊 **STEP 4: VALIDATE INTEGRATION**

### Test Dashboard Access
1. **Navigate to**: Lightning App → CVMA → Epic 8 Dashboard
2. **Check**: VA API Integration Status section
3. **Verify**: All APIs show "Connected" status

### Test Member Services
1. **Open any member record**
2. **Access**: Epic 8 Enhanced Member Services
3. **Verify**: Real VA forms, facilities, and address validation are working

### Monitor Performance
1. **Check**: VA API Integration Dashboard for response times
2. **Review**: Error logs in Setup → Debug Logs
3. **Validate**: Circuit breaker status remains "Closed"

---

## 🔄 **STEP 5: PRODUCTION DEPLOYMENT CHECKLIST**

### Pre-Deployment Validation
- [ ] VA Lighthouse credentials tested in Sandbox environment
- [ ] All test classes passing (>90% coverage achieved)
- [ ] Feature flags configured correctly
- [ ] Circuit breaker thresholds appropriate for production
- [ ] Rate limiting configured per VA API guidelines
- [ ] Monitoring alerts configured

### Deployment Process
1. **Deploy to Production**: Use same configuration as Sandbox
2. **Update Endpoints**: Change from `sandbox-api.va.gov` to `api.va.gov`
3. **Test Immediately**: Verify all three APIs respond correctly
4. **Monitor Closely**: Watch for any authentication or rate limiting issues

### Post-Deployment Monitoring
- [ ] API response times under 2 seconds
- [ ] Success rate >95% for all APIs
- [ ] Circuit breaker functioning correctly
- [ ] Member services accessing real VA data
- [ ] No security violations or unauthorized access attempts

---

## 🚨 **ROLLBACK PROCEDURES**

### Instant Rollback (If Issues Arise)
1. **Quick Fix**: Set feature flags to False
   ```
   ENABLE_REAL_VA_FORMS_API: False
   ENABLE_REAL_VA_FACILITIES_API: False
   ENABLE_REAL_VA_ADDRESS_API: False
   ```

2. **Alternative**: Set `Use_Mock_API__c` to True in API configurations

### System Automatically Falls Back To:
- ✅ Mock API responses
- ✅ Cached data where available
- ✅ Error handling with user-friendly messages
- ✅ Full functionality maintained

---

## 📞 **SUPPORT AND TROUBLESHOOTING**

### Common Issues and Solutions

**Issue**: Authentication Failed
**Solution**:
- Verify Client ID/Secret are exactly as provided by VA
- Check environment endpoints (sandbox vs production)
- Ensure credentials are marked as Active

**Issue**: Rate Limit Exceeded
**Solution**:
- Check current usage in API Integration Dashboard
- Review rate limiting configuration
- Contact VA to request limit increase if needed

**Issue**: Circuit Breaker Open
**Solution**:
- Check VA API status at https://developer.va.gov/support
- Wait for automatic reset (15 minutes default)
- Manually reset by clearing platform cache

### Error Log Monitoring
- **Location**: Setup → Debug Logs
- **Filter by**: CVMARealVAAPIAuthenticator
- **Monitor for**: Authentication failures, rate limiting, API errors

### Performance Monitoring
- **Dashboard**: Epic 8 → VA API Integration Dashboard
- **Key Metrics**: Response time, success rate, daily usage
- **Alerts**: SLA violations, circuit breaker activations

---

## ✅ **ACTIVATION VERIFICATION CHECKLIST**

After completing all steps, verify these success indicators:

### VA Forms API Integration ✅
- [ ] Form search returns real VA forms
- [ ] Member recommendations show actual VA forms
- [ ] Popular forms display correctly
- [ ] Form submission links work

### VA Facilities API Integration ✅
- [ ] Facility search returns real VA locations
- [ ] Member location context shows nearby facilities
- [ ] Emergency facility lookup functions
- [ ] Geolocation accuracy verified

### VA Address Validation API Integration ✅
- [ ] Address validation returns standardized addresses
- [ ] Member profile addresses get quality scores
- [ ] Recommendations for address corrections appear
- [ ] Validation accuracy meets expectations

### System Health ✅
- [ ] Overall integration health >95%
- [ ] Response times under SLA thresholds
- [ ] Circuit breakers remain closed
- [ ] No authentication errors in logs
- [ ] Member services fully functional

---

## 🎯 **SUCCESS CONFIRMATION**

**You'll Know It's Working When**:
1. **Epic 8 Dashboard** shows "Real APIs Connected"
2. **Member Services** display actual VA data instead of mock data
3. **Form searches** return hundreds of real VA forms
4. **Facility finder** shows actual VA locations with real addresses
5. **Address validation** provides USPS-standardized addresses

**Expected Performance**:
- Response times: 150-500ms average
- Success rate: >98% for all APIs
- Daily API usage: Tracking real member interactions
- Member satisfaction: Enhanced with real government data

---

## 📈 **NEXT STEPS AFTER ACTIVATION**

### Phase 1: Monitor and Optimize (Week 1-2)
- Watch performance metrics daily
- Fine-tune circuit breaker thresholds
- Optimize caching for frequently accessed data
- Gather member feedback on new services

### Phase 2: Enhanced Features (Month 1-2)
- Add VA Veterans Verification API (if approved)
- Implement advanced form tracking
- Create custom VA benefit calculators
- Add automated benefit eligibility checking

### Phase 3: Cross-Chapter Integration (Month 2-3)
- Share VA integration with other CVMA chapters
- Create national VA service analytics
- Implement best practices sharing
- Scale infrastructure for multi-chapter support

---

**🏍️ Combat Veterans Motorcycle Association Chapter 20-7**
**Vets Serving Vets Through Revolutionary Government Integration**
**Ready for Real VA Lighthouse API Activation** ⚡🚀

*This infrastructure represents the most advanced veteran services integration platform ever deployed by a non-profit organization, ready to deliver unprecedented value to CVMA members through direct government API access.*
