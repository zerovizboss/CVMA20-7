# Epic #3 Phase 1: Lightning Knowledge Implementation Task Checklist
**Combat Veterans Motorcycle Association Chapter 20-7**
**Implementation Date**: November 2, 2025
**Reference Guide**: EPIC-3-PHASE-1-CORRECTED-APPROACH-NOV-2-2025.md

---

## ✅ **COMPLETED TASKS** (Your Progress So Far)

### **Foundation Setup**
- [x] **Task 1.1**: Create Custom Object `CVMA_Document__c`
  - Status: ✅ COMPLETE
  - Location: Setup → Object Manager → CVMA_Document
  - Notes: Object created successfully

- [x] **Task 1.2**: Add 6 Custom Fields to CVMA_Document__c
  - Status: ✅ COMPLETE
  - Fields created:
    - [x] Document_Type__c (Picklist)
    - [x] Effective_Date__c (Date)
    - [x] Revision_Number__c (Text)
    - [x] CEB_Restricted__c (Checkbox)
    - [x] Source_OneDrive_Path__c (Text Area Long)
    - [x] Form_Number__c (Text)

- [x] **Task 1.3**: Create Data Category Groups (3 groups)
  - Status: ✅ COMPLETE
  - Groups created:
    - [x] CVMA Organizational Content (primary hierarchy)
    - [x] CVMA Bylaws
    - [x] Protocols
  - Notes: Excellent workaround for Developer Edition 3-group limit

- [x] **Task 1.4**: Create Page Layout for CVMA_Document__c
  - Status: ✅ PARTIAL (needs Knowledge fields after enabling)
  - Location: Setup → Object Manager → CVMA_Document → Page Layouts
  - Next: Update after enabling Knowledge (Task 3.1)

---

## 🔥 **CRITICAL NEXT TASKS** (Do These Now)

### **Enable Lightning Knowledge**

- [ ] **Task 2.1**: Verify Lightning Knowledge is Enabled in Org
  - **Action**: Setup → Quick Find → "Knowledge Settings"
  - **Expected**: "Lightning Knowledge" status shows "Enabled"
  - **If Not Enabled**: Click "Enable Lightning Knowledge" button
  - **Time**: 5 minutes
  - **Notes**: One-way migration from Classic Knowledge (if applicable)

- [ ] **Task 2.2**: Enable Knowledge for CVMA_Document__c Object 🔥 CRITICAL
  - **Action**: Setup → Object Manager → CVMA_Document
  - **Look for**: "Lightning Knowledge Setup" button (top right)
  - **Click**: Enable Lightning Knowledge for this Object
  - **Configure**:
    - Article Type Label: CVMA Document
    - Plural Label: CVMA Documents
    - Enable Article Versioning: ✅ (checked)
    - Article Number Format: CVMA-{0000000}
    - Default Article Status: Draft
    - Enable Translation: ❌ (unchecked)
  - **Expected Result**: `CVMA_Document__kav` object created automatically
  - **Time**: 10 minutes
  - **Verification**: Setup → Object Manager → Search "CVMA_Document__kav" (should exist)

---

### **Update Page Layout with Knowledge Fields**

- [ ] **Task 3.1**: Update CVMA Document Page Layout
  - **Action**: Setup → Object Manager → CVMA_Document → Page Layouts → Edit layout
  - **Section 1 - Document Information** (update):
    - [ ] Add: Title (Knowledge standard field - now available)
    - [ ] Add: UrlName (Knowledge standard field - now available)
    - [ ] Keep: Document_Type__c (your custom field)
    - [ ] Keep: Form_Number__c (your custom field)
    - [ ] Keep: Revision_Number__c (your custom field)
    - [ ] Keep: Effective_Date__c (your custom field)
  - **Section 2 - Access Control** (keep as-is):
    - [ ] CEB_Restricted__c
    - [ ] Source_OneDrive_Path__c
  - **Section 3 - Content** (update):
    - [ ] Add: Summary (Knowledge rich text field - now available)
    - [ ] Add: Detail or RichTextContent field (alternative to Body)
  - **Section 4 - System Information** (update):
    - [ ] Add: ArticleNumber (Knowledge standard field)
    - [ ] Add: VersionNumber (Knowledge standard field)
    - [ ] Add: PublishStatus (Knowledge field)
    - [ ] Keep: CreatedById, CreatedDate
    - [ ] Keep: LastModifiedById, LastModifiedDate
  - **Related Lists** (add at bottom):
    - [ ] Files (for PDF attachments)
    - [ ] Article Versions (Knowledge-specific)
  - **Time**: 15 minutes

---

### **Configure Permission Sets**

- [ ] **Task 4.1**: Create CVMA_Knowledge_Article_Publisher Permission Set
  - **Action**: Setup → Permission Sets → New
  - **Configuration**:
    - Label: CVMA Knowledge Article Publisher
    - API Name: CVMA_Knowledge_Article_Publisher
  - **Object Settings** → Search: `CVMA_Document__kav` (not __c)
  - **Permissions**:
    - [ ] Read: ✅
    - [ ] Create: ✅
    - [ ] Edit: ✅
    - [ ] Delete: ✅
    - [ ] View All: ✅
    - [ ] Modify All: ✅
  - **Field Permissions**: Select All
  - **Assign To**: Secretary user
  - **Time**: 8 minutes

- [ ] **Task 4.2**: Create CVMA_Knowledge_Article_Viewer Permission Set
  - **Action**: Setup → Permission Sets → New
  - **Configuration**:
    - Label: CVMA Knowledge Article Viewer
    - API Name: CVMA_Knowledge_Article_Viewer
  - **Object Settings** → Search: `CVMA_Document__kav`
  - **Permissions**:
    - [ ] Read: ✅
    - [ ] Create: ❌
    - [ ] Edit: ❌
    - [ ] Delete: ❌
  - **Field Permissions**: All fields Read Only
  - **Assign To**: All CVMA members
  - **Time**: 8 minutes

- [ ] **Task 4.3**: Create CVMA_CEB_Restricted_Viewer Permission Set
  - **Action**: Setup → Permission Sets → New
  - **Configuration**:
    - Label: CVMA CEB Restricted Viewer
    - API Name: CVMA_CEB_Restricted_Viewer
  - **Object Settings** → Search: `CVMA_Document__kav`
  - **Permissions**:
    - [ ] Read: ✅ (including CEB_Restricted__c = true)
    - [ ] View All: ✅
  - **Sharing Rule** (if needed):
    - [ ] Setup → Sharing Settings → CVMA_Document__kav → New
    - [ ] Rule: CEB_Restricted__c = true → Share with CEB Officers
  - **Assign To**: All CEB officers
  - **Time**: 9 minutes

---

## 🧪 **TEST PHASE** (Before Creating All 18 Articles)

### **Create Test Article**

- [ ] **Task 5.1**: Create First Test Article (National Bylaws)
  - **Action**: Knowledge tab → New → CVMA Document
  - **Fields to Fill**:
    - [ ] Title: CVMA National Bylaws - Revision V
    - [ ] UrlName: (auto-populated, can edit)
    - [ ] Document_Type__c: Bylaws
    - [ ] Revision_Number__c: Revision V
    - [ ] Effective_Date__c: 08/10/2025
    - [ ] CEB_Restricted__c: ❌ (unchecked)
    - [ ] Source_OneDrive_Path__c: `C:\Users\zerov\OneDrive\Documents\CVMA\Documentation\Bylaws\CVMA-National-Bylaws---Revision-V---Signed.pdf`
    - [ ] Summary: National CVMA Bylaws governing all chapters, effective August 10, 2025
  - **Attach PDF**:
    - [ ] Click Files related list → Upload Files
    - [ ] Select: CVMA-National-Bylaws---Revision-V---Signed.pdf
  - **Assign Data Category**:
    - [ ] Click Data Categories button
    - [ ] Navigate: CVMA Organizational Content > All > Bylaws > National Bylaws
    - [ ] Select and Save
  - **Publish**:
    - [ ] Click Publish button → Publish Now
  - **Time**: 10 minutes

---

### **Test Article Access**

- [ ] **Task 5.2**: Test Article Visibility (Current User)
  - [ ] Can view article in Knowledge tab
  - [ ] Can edit article
  - [ ] Can see all fields
  - [ ] Can download PDF attachment
  - [ ] Search "bylaws" returns article
  - **Time**: 5 minutes

- [ ] **Task 5.3**: Test Article Visibility (Member User - if available)
  - [ ] Can view article
  - [ ] Can download PDF
  - [ ] Cannot edit or delete
  - [ ] Cannot see Source_OneDrive_Path__c field
  - **Time**: 5 minutes (optional if no test user)

- [ ] **Task 5.4**: Test Search Functionality
  - [ ] Global search: "National Bylaws" → Returns article
  - [ ] Knowledge search: "Revision V" → Returns article
  - [ ] Category filter: Bylaws > National Bylaws → Shows article
  - **Time**: 5 minutes

**🚨 STOP HERE IF TESTS FAIL - Report errors before continuing**

---

## 📄 **BULK ARTICLE CREATION** (After Test Succeeds)

### **Bylaws Category (5 more articles)**

- [ ] **Task 6.1**: Create Article - Chapter 20-7 Bylaws
  - File: FL-20-7-Bylaws-221227.pdf
  - Category: Bylaws > Chapter Bylaws
  - CEB_Restricted: ❌

- [ ] **Task 6.2**: Create Article - Appendix A
  - File: Appendix-A.pdf
  - Category: Bylaws > National Bylaws
  - CEB_Restricted: ❌

- [ ] **Task 6.3**: Create Article - Appendix B (Regional Rotation)
  - File: CVMA-Bylaws-Appendix-B-Regional-Rotation-2024.pdf
  - Category: Bylaws > National Bylaws
  - CEB_Restricted: ❌

- [ ] **Task 6.4**: Create Article - Appendix C (Discipline) 🔒 CEB ONLY
  - File: CVMA-Bylaws-Appendix-C-Discipline-2023.pdf
  - Category: Bylaws > National Bylaws
  - CEB_Restricted: ✅ (CHECKED)

- [ ] **Task 6.5**: Create Article - Revision Summary
  - File: CVMA-National-Bylaws---Change-Revision-Summary--10August2025-.pdf
  - Category: Bylaws > National Bylaws
  - CEB_Restricted: ❌

---

### **Membership Forms (3 articles)**

- [ ] **Task 7.1**: Create Article - Form 100 (Membership Application)
  - File: CVMA-Form-100-MembershipApplication-01OCT25.pdf
  - Category: Forms > Membership Forms
  - Form_Number__c: 100
  - Revision_Number__c: 01OCT25
  - CEB_Restricted: ❌

- [ ] **Task 7.2**: Create Article - Form 101 (Patch Agreement)
  - File: CVMA-Form-101-PatchAgreement-01OCT25.pdf
  - Category: Forms > Membership Forms
  - Form_Number__c: 101
  - Revision_Number__c: 01OCT25
  - CEB_Restricted: ❌

- [ ] **Task 7.3**: Create Article - Form 102 (Life Membership)
  - File: CVMA-Form-102-LifeMembershipApplication-01OCT25.pdf
  - Category: Forms > Membership Forms
  - Form_Number__c: 102
  - Revision_Number__c: 01OCT25
  - CEB_Restricted: ❌

---

### **Disciplinary Forms (5 articles - ALL CEB RESTRICTED)**

- [ ] **Task 8.1**: Create Article - Form 400 (Investigation Decision) 🔒
  - File: CVMAForm400-InvestigationDecisionForm.pdf
  - Category: Forms > Disciplinary Forms
  - Form_Number__c: 400
  - CEB_Restricted: ✅ (CHECKED)

- [ ] **Task 8.2**: Create Article - Form 401 (State Investigation) 🔒
  - File: CVMAForm401-ChapterRequest-For-StateLevel-Investigation.pdf
  - Category: Forms > Disciplinary Forms
  - Form_Number__c: 401
  - CEB_Restricted: ✅ (CHECKED)

- [ ] **Task 8.3**: Create Article - Form 404 (Administrative Hold) 🔒
  - File: CVMAForm404-AdministrationHold-26JUL2024.docx
  - Category: Forms > Disciplinary Forms
  - Form_Number__c: 404
  - CEB_Restricted: ✅ (CHECKED)

- [ ] **Task 8.4**: Create Article - Form 410 (Counseling) 🔒
  - File: CVMAForm410-CounselingForm-12-3-2024.pdf
  - Category: Forms > Disciplinary Forms
  - Form_Number__c: 410
  - CEB_Restricted: ✅ (CHECKED)

- [ ] **Task 8.5**: Create Article - Form 400 Instructions 🔒
  - File: Instructions-CVMAForm400-CSR-InvestigationDecisionForm.pdf
  - Category: Forms > Disciplinary Forms
  - CEB_Restricted: ✅ (CHECKED)

---

### **Administrative Forms (4 articles)**

- [ ] **Task 9.1**: Create Article - Form 201 (Chapter Relocation)
  - File: CVMAForm201-ChapterRelocationtRequest-Jan21.pdf
  - Category: Forms > Administrative Forms
  - Form_Number__c: 201
  - CEB_Restricted: ❌

- [ ] **Task 9.2**: Create Article - Form 202 (Benevolent Fund)
  - File: CVMAForm202-Benevolent-Fund-Request-Form-NOV-24.pdf
  - Category: Forms > Administrative Forms
  - Form_Number__c: 202
  - CEB_Restricted: ❌

- [ ] **Task 9.3**: Create Article - Form 204 (Medical Exemption)
  - File: CVMAForm204-MedicalExemptiontRequest-AUG-2025.pdf
  - Category: Forms > Administrative Forms
  - Form_Number__c: 204
  - CEB_Restricted: ❌

- [ ] **Task 9.4**: Create Article - Form 500 (Auxiliary Chapter)
  - File: CVMAForm500-AUXChapterRequestFormFINAL.pdf
  - Category: Forms > Administrative Forms
  - Form_Number__c: 500
  - CEB_Restricted: ❌

---

## 🎯 **FINAL VALIDATION**

### **Complete Testing**

- [ ] **Task 10.1**: Verify All 18 Articles Published
  - [ ] Navigate to Knowledge tab
  - [ ] Confirm 18 articles visible
  - [ ] All articles show "Published" status

- [ ] **Task 10.2**: Test Search Across All Articles
  - [ ] Search "Form" → Returns all 12 forms
  - [ ] Search "Bylaws" → Returns 6 bylaws articles
  - [ ] Search "CEB" → Returns disciplinary forms (if CEB user)

- [ ] **Task 10.3**: Test Data Category Filtering
  - [ ] Filter: Bylaws → Shows 6 articles
  - [ ] Filter: Forms > Membership → Shows 3 articles
  - [ ] Filter: Forms > Disciplinary → Shows 5 articles (CEB only)
  - [ ] Filter: Forms > Administrative → Shows 4 articles

- [ ] **Task 10.4**: Test CEB Restricted Access
  - [ ] As CEB user: Can see Appendix C and Forms 400-410
  - [ ] As Member user: Cannot see CEB-restricted content
  - [ ] As Guest user: Cannot access any Knowledge Articles

- [ ] **Task 10.5**: Test Mobile Responsiveness
  - [ ] Open Knowledge on mobile device
  - [ ] Articles display correctly
  - [ ] PDF attachments downloadable
  - [ ] Search and filtering work

---

## 📊 **PROGRESS TRACKING**

### **Current Status**
- **Phase**: Setup & Testing
- **Completed Tasks**: 4 (foundation setup)
- **Remaining Tasks**: ~30 tasks
- **Estimated Time**: 1.5-2 hours

### **Task Count Summary**
- ✅ Foundation Setup: 4/4 tasks complete
- 🔥 Critical Next: 2 tasks (enable Knowledge, update layout)
- 🔧 Configuration: 3 tasks (permission sets)
- 🧪 Testing: 4 tasks (test article + validation)
- 📄 Bulk Creation: 17 tasks (17 remaining articles)
- 🎯 Final Validation: 5 tasks

**Total**: 35 tasks (4 complete, 31 remaining)

---

## 🚨 **BLOCKERS & ISSUES**

### **If You Encounter Problems**

**Issue**: Cannot find "Enable Lightning Knowledge" button
- **Solution**: Setup → Knowledge Settings → Enable Lightning Knowledge first

**Issue**: CVMA_Document__kav not created after enabling
- **Solution**: Refresh page, check Object Manager for __kav suffix

**Issue**: Cannot upload PDF files
- **Solution**: Check Files related list field-level security

**Issue**: Articles not visible after publishing
- **Solution**: Check permission sets, verify publication status

**Issue**: CEB-restricted articles visible to all users
- **Solution**: Verify CEB_Restricted__c checkbox, check sharing rules

---

## 📚 **REFERENCE DOCUMENTS**

- **Corrected Implementation Guide**: EPIC-3-PHASE-1-CORRECTED-APPROACH-NOV-2-2025.md
- **Original Implementation Plan**: EPIC-3-PHASE-1-IMPLEMENTATION-PLAN-NOV-2-2025.md (deprecated)
- **Session Planning Notes**: SESSION-NOVEMBER-02-2025-EPIC-3-PLANNING.md
- **OneDrive Source**: C:\Users\zerov\OneDrive\Documents\CVMA\Documentation\

---

## ✅ **SUCCESS CRITERIA**

Epic #3 Phase 1 is complete when:
- [ ] Lightning Knowledge enabled for CVMA_Document__c
- [ ] CVMA_Document__kav object exists
- [ ] 6 custom fields functioning on Knowledge articles
- [ ] 3 Data Category Groups configured
- [ ] 3 Permission Sets created and assigned
- [ ] 18 Knowledge Articles published
- [ ] All articles searchable and categorized
- [ ] CEB-restricted content properly gated
- [ ] PDF attachments downloadable
- [ ] Mobile-responsive article access

---

**Use this checklist to track your progress through the corrected implementation!**

🏍️ **Vets Serving Vets - Chapter 20-7**

🎖️ Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
