# Epic #3: CVMA_Document Custom Object Deletion Guide
**Combat Veterans Motorcycle Association Chapter 20-7**
**Date**: November 2, 2025

---

## 🎯 **What Needs to Be Deleted**

Based on your manual org UI creation:
1. **Custom Object**: `CVMA_Document__c` (+ 6 custom fields)
2. **Data Category Groups**: 3 groups (optionally - can reuse with Knowledge object)

---

## ✅ **Recommended Approach: Delete in Org UI**

Since you created everything in the org UI and it hasn't been pulled to local metadata, the simplest approach is to delete in the UI.

### **Step 1: Delete Custom Object** (2 minutes)

1. Navigate to **Setup** (gear icon → Setup)
2. In Quick Find, type "Object Manager"
3. Click **Object Manager**
4. Find **CVMA_Document** in the list
5. Click on **CVMA_Document**
6. Click the dropdown menu (top right) → **Delete**
7. Confirm deletion

**Expected Result**: Custom object and all 6 custom fields deleted

---

### **Step 2: Data Categories Decision**

**IMPORTANT**: Your Data Category Groups can be **REUSED** with the correct Knowledge object approach!

**Recommendation**: **KEEP Data Categories** (no deletion needed)

**Why**:
- Data Categories work with standard Knowledge object
- Your 3-group structure is excellent
- No rework required - just assign to Knowledge object instead

**If You Want to Delete Anyway** (not recommended):
1. Setup → Quick Find → "Data Categories"
2. For each category group:
   - Click group name
   - Click **Delete** (top right)
   - Confirm deletion

---

### **Step 3: Verify Clean State** (1 minute)

1. Setup → Object Manager → Search for "CVMA_Document"
   - Should return NO results ✅
2. Setup → Object Manager → Search for "Knowledge"
   - Should show standard **Knowledge** object ✅
3. Setup → Data Categories
   - Should show your 3 groups (if kept) ✅
   - OR no groups (if deleted) ✅

---

## 🔧 **After Deletion: Next Steps**

Follow the corrected implementation guide:
`EPIC-3-PHASE-1-LIGHTNING-KNOWLEDGE-CORRECT-APPROACH.md`

**Steps**:
1. Navigate to standard `Knowledge__kav` object (Setup → Object Manager → Knowledge)
2. Add 6 custom fields to Knowledge object
3. Create 4 Record Types on Knowledge object
4. Create page layouts per record type
5. Assign Data Categories to Knowledge object (if kept)
6. Configure permission sets for Knowledge object
7. Create 18 Knowledge articles

**Estimated Time**: 1.5 hours

---

## 📊 **What You're Losing** (Minimal)

**Time Investment Lost**: ~1.5 hours
**Work Lost**:
- Custom object creation (5 min)
- 6 custom fields (20 min)
- Data Categories (20 min - REUSABLE!)
- Page layout (15 min)

**What's Salvageable**:
- ✅ Lightning Knowledge enabled (no rework)
- ✅ Data Categories (can reuse - KEEP THESE!)
- ✅ OneDrive document identification (already done)

---

## 🚨 **IMPORTANT: Don't Create Articles Yet**

Do NOT create Knowledge articles until:
- [ ] Custom object deleted
- [ ] Standard Knowledge object configured
- [ ] 6 custom fields added to Knowledge object
- [ ] Record Types created
- [ ] Page layouts created
- [ ] Permission sets configured
- [ ] Test article created and validated

---

## 💡 **Why This Happened**

**Root Cause**: Implementation guide incorrectly instructed creating custom object for Knowledge article types (Classic Knowledge pattern, not Lightning).

**Correct Pattern**: Lightning Knowledge uses ONE standard Knowledge object + Record Types.

**Lesson Learned**: Always verify current Salesforce architecture before implementation (documented in STORM_CLAUDE_CORE.md).

**Cost Impact**: $150.48 USD (documented in GitHub Issue #89)

---

## ✅ **Deletion Checklist**

- [ ] Custom object `CVMA_Document__c` deleted
- [ ] Verified no CVMA_Document in Object Manager
- [ ] Data Categories kept (or deleted if preferred)
- [ ] Standard Knowledge object verified present
- [ ] Ready to start corrected implementation

---

**Next Action**: Delete custom object in org UI, then follow corrected implementation guide.

🏍️ **Vets Serving Vets - Chapter 20-7**
