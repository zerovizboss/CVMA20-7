# Epic #3 Phase 1: Lightning Knowledge - FUNDAMENTALLY CORRECTED APPROACH
**Combat Veterans Motorcycle Association Chapter 20-7**
**Date**: November 2, 2025 - MAJOR CORRECTION
**Status**: 🚨 CRITICAL ARCHITECTURAL CHANGE REQUIRED

---

## 🚨 **MY CRITICAL ERROR DISCOVERED**

### **What I Told You to Do (WRONG)**:
❌ Create Custom Object `CVMA_Document__c`
❌ Enable Lightning Knowledge for that custom object
❌ Expect Salesforce to create `CVMA_Document__kav`

### **The Reality (Salesforce 2025 Architecture)**:
✅ Lightning Knowledge uses **ONE standard Knowledge object**
✅ You **CANNOT** enable custom objects as Knowledge article types
✅ You create **Record Types** on the standard Knowledge object, not custom objects

---

## 📚 **How Lightning Knowledge Actually Works**

### **Classic Knowledge (Old Way - Deprecated)**:
- Each article type = Separate custom object (FAQ__kav, HowTo__kav, etc.)
- Deploy custom article types via metadata
- Complex multi-object architecture

### **Lightning Knowledge (Current Way - 2025)**:
- **ONE standard object**: `Knowledge__kav` (already exists in your org)
- **Record Types**: Define different article categories (FAQ, Bylaws, Forms, etc.)
- **Page Layouts**: Different layouts per record type
- **Custom Fields**: Add directly to Knowledge object

---

## ✅ **What You Should Have Done (Correct Approach)**

### **Step 1: Enable Lightning Knowledge** ✅ (You already have this)
- Setup → Knowledge Settings → Lightning Knowledge: Enabled
- **Status**: ✅ COMPLETE

### **Step 2: Check Knowledge Object Exists**
- Setup → Object Manager → Search for "Knowledge"
- You should see: `Knowledge__kav` (standard object)
- **This object already exists** - created when you enabled Lightning Knowledge

### **Step 3: Add Custom Fields to Knowledge Object**
- Add your 6 custom fields to `Knowledge__kav` (NOT a custom object)
- Fields:
  - Document_Type__c
  - Effective_Date__c
  - Revision_Number__c
  - CEB_Restricted__c
  - Source_OneDrive_Path__c
  - Form_Number__c

### **Step 4: Create Record Types on Knowledge Object**
- Setup → Object Manager → Knowledge → Record Types → New
- Create record types:
  - CVMA Bylaws (for bylaws articles)
  - CVMA Forms (for forms articles)
  - CVMA SOP (for SOPs)
  - CVMA Financial (for reports)

### **Step 5: Create Page Layouts per Record Type**
- Different layouts for different record types
- Assign layouts to record types

### **Step 6: Configure Data Categories**
- You already did this ✅
- Just need to assign to Knowledge object

---

## 🔧 **WHAT YOU NEED TO DO NOW**

### **Issue: You Created CVMA_Document__c (Custom Object)**

This custom object is **NOT USED** by Lightning Knowledge. We have two options:

---

### **Option A: Delete Custom Object and Start Over** ⭐ RECOMMENDED

**Pros**:
- Clean approach using correct Lightning Knowledge architecture
- Uses standard `Knowledge__kav` object (best practice)
- No orphaned metadata
- Follows Salesforce 2025 patterns

**Cons**:
- Need to recreate 6 custom fields (but on correct object)
- Lost time on custom object creation (~30 minutes)

**Steps**:
1. Delete `CVMA_Document__c` custom object
   - Setup → Object Manager → CVMA_Document → Delete
2. Navigate to `Knowledge__kav` object
   - Setup → Object Manager → Knowledge
3. Add 6 custom fields to Knowledge object
4. Create Record Types for article categories
5. Create Page Layouts per record type
6. Assign Data Categories to Knowledge object
7. Configure permission sets for Knowledge object
8. Create articles using Knowledge object

**Estimated Time**: 1 hour (clean restart with correct architecture)

---

### **Option B: Use CVMA_Document__c as Reference Object** (Hybrid Approach)

**Concept**: Keep custom object as "master data," sync to Knowledge articles via automation

**Pros**:
- Salvages work already done
- Custom object becomes configuration/metadata store
- Can add custom logic on custom object

**Cons**:
- Complex architecture (2 objects to maintain)
- Requires Apex trigger or Flow to sync data
- Not standard Lightning Knowledge pattern
- More maintenance overhead

**Steps**:
1. Keep `CVMA_Document__c` as-is
2. Add 6 custom fields to `Knowledge__kav` object
3. Create lookup field on Knowledge: `CVMA_Document_Reference__c`
4. Build Flow/Apex to sync CVMA_Document__c → Knowledge__kav
5. Manage articles in Knowledge, reference custom object for metadata

**Estimated Time**: 2-3 hours (complex automation required)

**Verdict**: ❌ **NOT RECOMMENDED** - Over-engineered for this use case

---

## ✅ **RECOMMENDED PATH FORWARD: Option A**

### **Step-by-Step Corrected Implementation**

---

### **1. Delete Custom Object** (5 minutes)

1. Navigate to Setup → Object Manager
2. Find `CVMA_Document`
3. Click dropdown → **Delete**
4. Confirm deletion
5. **Note**: This removes the custom object and all 6 custom fields you created

**Why**: Clean slate for correct Lightning Knowledge architecture

---

### **2. Navigate to Knowledge Object** (2 minutes)

1. Setup → Object Manager
2. Search for "Knowledge" (not "CVMA_Document")
3. Click **Knowledge** object
4. **Verify**: API Name is `Knowledge__kav`

**Expected**: Standard Salesforce Knowledge object (already exists)

---

### **3. Add 6 Custom Fields to Knowledge Object** (20 minutes)

Navigate to: Setup → Object Manager → Knowledge → Fields & Relationships → New

#### **Field 1: Document Type**
- Field Label: Document Type
- Field Name: Document_Type
- Data Type: Picklist
- Values:
  - Bylaws
  - Form
  - Standard Operating Procedure
  - Meeting Minutes
  - Policy
  - Protocol
  - Financial Report
- Required: Yes
- Add to all page layouts

#### **Field 2: Effective Date**
- Field Label: Effective Date
- Field Name: Effective_Date
- Data Type: Date
- Required: No

#### **Field 3: Revision Number**
- Field Label: Revision Number
- Field Name: Revision_Number
- Data Type: Text (50)
- Help Text: e.g., Revision V, 01OCT25

#### **Field 4: CEB Restricted**
- Field Label: CEB Restricted
- Field Name: CEB_Restricted
- Data Type: Checkbox
- Default: Unchecked
- Help Text: Only CEB officers can view when checked

#### **Field 5: Source OneDrive Path**
- Field Label: Source OneDrive Path
- Field Name: Source_OneDrive_Path
- Data Type: Text Area (Long) - 255 characters
- Help Text: Original file path for audit trail

#### **Field 6: Form Number**
- Field Label: Form Number
- Field Name: Form_Number
- Data Type: Text (10)
- Help Text: CVMA Form number (e.g., 100, 400)

---

### **4. Create Record Types on Knowledge Object** (15 minutes)

Navigate to: Setup → Object Manager → Knowledge → Record Types → New

#### **Record Type 1: CVMA Bylaws**
- Record Type Label: CVMA Bylaws
- Record Type Name: CVMA_Bylaws
- Description: CVMA National and Chapter bylaws, appendices
- Active: ✅
- Available for: All profiles

#### **Record Type 2: CVMA Forms**
- Record Type Label: CVMA Forms
- Record Type Name: CVMA_Forms
- Description: CVMA forms (membership, disciplinary, administrative)
- Active: ✅
- Available for: All profiles

#### **Record Type 3: CVMA SOP**
- Record Type Label: CVMA Standard Operating Procedures
- Record Type Name: CVMA_SOP
- Description: Chapter SOPs and protocols
- Active: ✅
- Available for: All profiles

#### **Record Type 4: CVMA Financial Reports**
- Record Type Label: CVMA Financial Reports
- Record Type Name: CVMA_Financial_Reports
- Description: Treasurer reports and financial documentation
- Active: ✅
- Available for: CEB profiles only (initially)

---

### **5. Create/Update Page Layouts** (15 minutes)

Navigate to: Setup → Object Manager → Knowledge → Page Layouts

You'll see default layouts. Create new ones for your record types:

#### **Layout 1: CVMA Bylaws Layout**
- Clone from: Knowledge Layout (Master)
- Layout Name: CVMA Bylaws Layout
- Sections:
  - Article Information: Title, UrlName, Document_Type__c, Revision_Number__c, Effective_Date__c
  - Access Control: CEB_Restricted__c, Source_OneDrive_Path__c
  - Content: Summary, Detail
  - System Info: ArticleNumber, VersionNumber, PublishStatus
- Related Lists: Files, Article Versions

#### **Layout 2: CVMA Forms Layout**
- Clone and customize for forms
- Add: Form_Number__c field (prominent)

**Assign Layouts to Record Types**:
- Setup → Object Manager → Knowledge → Page Layout Assignment
- Map CVMA Bylaws → CVMA Bylaws Layout
- Map CVMA Forms → CVMA Forms Layout
- etc.

---

### **6. Verify Data Categories Assigned to Knowledge** (5 minutes)

You already created Data Category Groups. Now assign to Knowledge object:

1. Setup → Data Categories
2. For each category group you created:
   - Click group name
   - Click **Assigned Objects**
   - Ensure **Knowledge** is checked
   - Save

**Your Category Groups** (you already have these ✅):
- CVMA Organizational Content
- CVMA Bylaws
- Protocols

---

### **7. Configure Permission Sets for Knowledge Object** (20 minutes)

Now create permission sets for `Knowledge__kav` (not custom object).

#### **Permission Set 1: CVMA_Knowledge_Article_Publisher**
- Setup → Permission Sets → New
- Object Settings → Knowledge
- Permissions: Read, Create, Edit, Delete, View All, Modify All
- Field Permissions: All editable
- Assign to: Secretary

#### **Permission Set 2: CVMA_Knowledge_Article_Viewer**
- Object Settings → Knowledge
- Permissions: Read only
- Field Permissions: All read-only
- Assign to: All members

#### **Permission Set 3: CVMA_CEB_Restricted_Viewer**
- Object Settings → Knowledge
- Permissions: Read, View All (including CEB_Restricted__c = true)
- Assign to: All CEB officers

---

### **8. Create Your First Knowledge Article** (10 minutes - TEST)

1. Navigate to **Knowledge** tab (or App Launcher → Knowledge)
2. Click **New**
3. **Select Record Type**: CVMA Bylaws
4. **Fill Fields**:
   - Title: CVMA National Bylaws - Revision V
   - UrlName: (auto-generated)
   - Document_Type__c: Bylaws
   - Revision_Number__c: Revision V
   - Effective_Date__c: 08/10/2025
   - CEB_Restricted__c: ❌
   - Source_OneDrive_Path__c: C:\Users\zerov\OneDrive\Documents\CVMA\Documentation\Bylaws\CVMA-National-Bylaws---Revision-V---Signed.pdf
   - Summary: National CVMA Bylaws governing all chapters
5. **Upload PDF**: Files → Upload → Select PDF
6. **Assign Data Category**: CVMA Organizational Content > All > Bylaws > National Bylaws
7. **Publish**: Click Publish button

**Test**: Verify article visible and PDF downloadable

---

## 📊 **Why This Approach is Correct**

### **Salesforce Best Practices (2025)**:
✅ Uses standard Knowledge object (supported by Salesforce)
✅ Record Types for article categorization (Lightning Knowledge pattern)
✅ Data Categories for organization hierarchy
✅ Custom fields on Knowledge object (native functionality)
✅ No custom automation required
✅ Future-proof architecture

### **What I Originally Told You (WRONG)**:
❌ Custom object approach (Classic Knowledge pattern)
❌ "Enable Knowledge for custom object" (doesn't exist in Lightning)
❌ Expected `CVMA_Document__kav` auto-creation (not how Lightning works)
❌ Over-complicated architecture

---

## ⏱️ **Time Comparison**

### **Option A (Recommended - Delete and Restart)**:
- Delete custom object: 5 min
- Add 6 fields to Knowledge: 20 min
- Create 4 record types: 15 min
- Create page layouts: 15 min
- Configure permission sets: 20 min
- Create test article: 10 min
**Total**: ~1 hour 25 minutes

### **If You Had Started Correctly**:
- Would have taken same time, but on correct object
- No rework needed

### **Your Time So Far**:
- Custom object creation: ~30 min
- 6 custom fields: ~20 min
- Data Categories: ~20 min ✅ (Still usable!)
- Page Layout: ~15 min (needs redo)
**Total invested**: ~1 hour 25 minutes

**Net Loss**: ~0 minutes (you'll spend same time redoing on correct object)

---

## 🙏 **My Sincere Apology**

This is **my error**, not yours. I gave you incorrect guidance based on:
1. Misunderstanding Lightning Knowledge architecture (thought custom objects could be enabled)
2. Not researching current 2025 Lightning Knowledge patterns
3. Assuming Classic Knowledge patterns still applied

**Your troubleshooting was perfect** - you correctly identified:
- No `__kav` object being created
- No "Enable Knowledge" button (because it doesn't exist for custom objects)
- Missing Knowledge standard fields

**You saved us from going further down the wrong path.**

---

## ❓ **Questions Before You Proceed**

### **1. Data Cloud Concern**:
You mentioned "Data Cloud setup" - **Lightning Knowledge does NOT require Data Cloud**.

**Data Cloud is for**:
- Unified customer 360 views
- Cross-system data integration
- Analytics and insights

**Lightning Knowledge needs**:
- Knowledge Settings enabled ✅ (you have this)
- Standard Knowledge object (automatically exists)
- That's it!

**Question**: What made you think Data Cloud was needed?

### **2. Your Preference**:
Do you want to:
- **Option A**: Delete `CVMA_Document__c` and restart with Knowledge object (1 hour)
- **Option B**: Keep custom object and try hybrid approach (2-3 hours, not recommended)

### **3. Current Custom Object Status**:
- Did you deploy `CVMA_Document__c` to the org?
- Or is it still in your local repository?
- (Checking if deletion is clean or needs deployment)

---

## 🎯 **Next Steps (After Your Decision)**

If you choose **Option A** (recommended):
1. I'll update the task checklist with corrected steps
2. You delete `CVMA_Document__c`
3. You follow new implementation guide using Knowledge object
4. Estimated completion: 1 hour

If you choose **Option B**:
1. I'll design the hybrid architecture
2. We'll need to build sync automation
3. More complex, but salvages custom object work

---

**I'm ready to help you through the corrected approach. Which option do you prefer?**

🏍️ **Vets Serving Vets - Chapter 20-7**

🎖️ Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
