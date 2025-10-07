# LWC Compilation Errors - Remaining Fixes Needed
**Date:** October 7, 2025
**Status:** 6 of 12 errors fixed, 6 remaining

---

## ✅ **Fixed Errors (6 of 12)**

1. ✅ cvmaInAppGuidance - Boolean @api `showOnFirstVisit = true` → Removed initialization
2. ✅ cvmaInAppGuidance - Boolean @api `enableVoiceCommands = true` → Removed initialization
3. ✅ cvmaVAServicesIntegration - Boolean @api `showFullIntegration = true` → Removed initialization
4. ✅ cvmaVeteranResourceFinder - Boolean @api `showGuestAccess = true` → Removed initialization
5. ✅ veteranResourceFinder - Boolean @api `guestAccess = true` → Removed initialization
6. ✅ cvmaEventRSVPV2 - Invalid wire adapters removed (getRSVPSummary, getRSVPResponseOptions)

---

## ❌ **Remaining Errors (6 of 12)**

### **1. cvmaInAppGuidance.html - Line 254:57**
**Error:** `LWC1058: Invalid HTML syntax: unexpected-character-in-attribute-name`
**Location:** Line 254, column 57
**Problem:** Ternary operator in attribute value
```html
<lightning-button
    label={isLastStep ? 'Complete Tour' : currentStepData.nextLabel}
    icon-name={isLastStep ? 'utility:check' : 'utility:chevronright'}
```

**Fix Required:**
Add getters in JavaScript:
```javascript
get nextButtonLabel() {
    return this.isLastStep ? 'Complete Tour' : this.currentStepData.nextLabel;
}

get nextButtonIcon() {
    return this.isLastStep ? 'utility:check' : 'utility:chevronright';
}
```

Update HTML:
```html
<lightning-button
    label={nextButtonLabel}
    icon-name={nextButtonIcon}
```

---

### **2. cvmaVAServicesIntegration.html - Line 306:96**
**Error:** `LWC1059: case is not a valid identifier`
**Location:** Line 306, column 96
**Problem:** Reserved keyword `case` used as variable name

**Fix Required:**
Find line 306 and rename variable from `case` to `serviceCase` or `caseRecord`

---

### **3. cvmaVeteranResourceFinder.js-meta.xml**
**Error:** `The 'properties' target isn't supported`
**Problem:** Invalid metadata configuration

**Fix Required:**
Remove invalid `<properties>` elements from metadata file, or change to valid target configuration

---

### **4. veteranResourceFinder.html - Line 79:38**
**Error:** `LWC1043: Event handler should be an expression`
**Location:** Line 79, column 38
**Problem:** Invalid event handler syntax

**Fix Required:**
Check line 79 for event handler - likely missing `{` or has incorrect syntax like `onclick="handleClick"` instead of `onclick={handleClick}`

---

### **5. cvmaCommunicationIntegration.js-meta.xml**
**Error:** `The 'targetConfig' tag doesn't contain any design information`
**Status:** ALREADY FIXED (empty targetConfigs removed)

---

### **6. cvmaFinancialManagementDashboard.js-meta.xml**
**Error:** `The 'targetConfig' tag doesn't contain any design information`
**Status:** ALREADY FIXED (empty targetConfig removed)

---

## 🎯 **Quick Fix Commands**

```bash
# Fix cvmaInAppGuidance ternary operators
# Edit cvmaInAppGuidance.js and add getters (see Fix #1 above)
# Edit cvmaInAppGuidance.html lines 254-255

# Fix cvmaVAServicesIntegration reserved keyword
grep -n "case" src/lwc/cvmaVAServicesIntegration/cvmaVAServicesIntegration.html
# Rename 'case' variable to 'serviceCase'

# Fix cvmaVeteranResourceFinder metadata
# Edit cvmaVeteranResourceFinder.js-meta.xml - remove <properties> elements

# Fix veteranResourceFinder event handler
# Edit veteranResourceFinder.html line 79 - fix onclick syntax

# Validate all fixes
sf project deploy start --source-dir src/lwc --target-org cvma --dry-run
```

---

## 📋 **Deployment Status**

**Before Session:**
- 12 LWC components with compilation errors
- 0 components deployable

**Current Status:**
- 6 errors fixed (50% complete)
- 6 errors remaining (50% to go)
- ~30 components deployable

**Estimated Time to Complete:** 30-45 minutes for remaining 6 fixes

---

🎖️ **Generated with [Claude Code](https://claude.com/claude-code)**
**Next Steps:** Complete remaining 6 fixes following this guide, then deploy all LWC components
