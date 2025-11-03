# Next Session Priorities: November 4, 2025+
**Combat Veterans Motorcycle Association Chapter 20-7**
**Session Status**: Epic #3 Phase 1 - 60% Complete (Ready for Permission Sets + Article Creation)

---

## 🚨 **QUICK START: What You Need to Know**

### **Session Context (November 3, 2025)**:
✅ **Knowledge Object**: 7 fields configured (6 custom + 1 standard "Content" relabeled)
✅ **Lightning Record Page**: Created with Dynamic Forms
✅ **Data Categories**: 3 groups assigned (Admin Content, Bylaws & Forms, Policy/Protocols/SOP)
✅ **CVMA Branding**: Accordion hover CSS deployed (CVMA Red)
✅ **Architecture**: Option C Hybrid confirmed (Knowledge + Google Drive)
✅ **CSS Deployed**: cvmaKnowledgeRecordPageCSS (Deployment ID: 0Afbm00000NNB5ZCAX)

### **What's Left** (Estimated 2 hours):
- [ ] Configure 3 Permission Sets (30 min)
- [ ] Create test Knowledge article (15 min)
- [ ] Create remaining 17 articles (85 min)
- [ ] Publish and test access (10 min)

---

## 🎯 **PRIMARY TASK: Complete Epic #3 Phase 1**

### **Step 7: Configure 3 Permission Sets** (30 minutes)

#### **Permission Set 1: CVMA_Knowledge_Article_Publisher**

**Purpose**: Secretary role - full Knowledge article management

**Configuration**:
1. **Setup → Permission Sets → New**
2. **Label**: CVMA Knowledge Article Publisher
3. **API Name**: CVMA_Knowledge_Article_Publisher
4. **Description**: Grants full access to create, edit, publish, and manage Knowledge articles (Secretary role)

**Object Settings → Knowledge**:
- ✅ Read
- ✅ Create
- ✅ Edit
- ✅ Delete
- ✅ View All
- ✅ Modify All

**Field Permissions** (All fields - Visible + Editable):
- Title ✅
- UrlName ✅
- Summary ✅
- Content (Article Content) ✅
- Document_Type__c ✅
- Effective_Date__c ✅
- Revision_Number__c ✅
- CEB_Restricted__c ✅
- Source_GoogleDrive_URL__c ✅
- Form_Number__c ✅
- ArticleNumber (Read-only system field)
- VersionNumber (Read-only system field)
- PublishStatus ✅

**Tab Settings**:
- Knowledge: Default On

**Assign To**: Secretary profile/user

---

#### **Permission Set 2: CVMA_Knowledge_Article_Viewer**

**Purpose**: All CVMA members - read-only access to published articles

**Configuration**:
1. **Setup → Permission Sets → New**
2. **Label**: CVMA Knowledge Article Viewer
3. **API Name**: CVMA_Knowledge_Article_Viewer
4. **Description**: Grants read-only access to published Knowledge articles (all CVMA members)

**Object Settings → Knowledge**:
- ✅ Read
- ❌ Create
- ❌ Edit
- ❌ Delete
- ❌ View All (only published articles)
- ❌ Modify All

**Field Permissions** (All fields - Visible only):
- All fields: **Read-only** ✅
- Excludes: CEB_Restricted__c = true articles (use Data Category visibility)

**Tab Settings**:
- Knowledge: Default On

**Assign To**: All member profiles (Full Member, Associate Member, Auxiliary Member)

---

#### **Permission Set 3: CVMA_CEB_Restricted_Viewer**

**Purpose**: CEB officers - access to restricted content

**Configuration**:
1. **Setup → Permission Sets → New**
2. **Label**: CVMA CEB Restricted Content Viewer
3. **API Name**: CVMA_CEB_Restricted_Viewer
4. **Description**: Grants access to CEB-restricted Knowledge articles (CEB officers only)

**Object Settings → Knowledge**:
- ✅ Read
- ❌ Create (unless also Publisher)
- ❌ Edit (unless also Publisher)
- ❌ Delete
- ✅ View All (includes CEB_Restricted__c = true)
- ❌ Modify All

**Field Permissions**:
- All fields: **Read-only** ✅
- CEB_Restricted__c: **Visible** ✅

**Tab Settings**:
- Knowledge: Default On

**Assign To**: All CEB officer profiles (Commander, XO, Secretary, Treasurer, Road Captain, Chaplain, Sergeant at Arms, PRO, Quartermaster)

---

### **Step 8: Create Test Knowledge Article** (15 minutes)

#### **Article 1: CVMA National Bylaws - Revision V** (Test Article)

**Purpose**: Validate all fields, test Google Drive integration, verify publishing workflow

**Steps**:
1. **Navigate to Knowledge Tab**
2. **Click New**
3. **Select Record Type**: CVMA Bylaws
4. **Fill Fields**:

```
Title: CVMA National Bylaws - Revision V
UrlName: (auto-generated: cvma-national-bylaws-revision-v)
Summary: National CVMA Bylaws governing all chapters, effective August 10, 2025

Content (Article Content - Rich Text):
  The Combat Veterans Motorcycle Association (CVMA) National Bylaws, Revision V,
  establish the governance structure, membership requirements, and operational
  procedures for all CVMA chapters nationwide.

  Key Sections:
  - Article I: Organization and Purpose
  - Article II: Membership Requirements and Classifications
  - Article III: Chapter Organization and Operations
  - Article VII: Regional and State Representatives
  - Article XIV: Chapter Executive Board (CEB) Roles and Responsibilities
  - Appendix C: Disciplinary Procedures

  This revision supersedes all previous versions and becomes effective August 10, 2025.

Document_Type__c: Bylaws
Effective_Date__c: 08/10/2025
Revision_Number__c: Revision V
CEB_Restricted__c: ☐ (No - public document)
Source_GoogleDrive_URL__c: [Paste Google Drive URL after upload]
Form_Number__c: (blank - not a form)
```

5. **Before Publishing**:
   - Upload PDF to Google Drive: `CVMA 20-7 Documents/Bylaws/National/CVMA-National-Bylaws-Revision-V-Signed.pdf`
   - Get shareable link: "Anyone with the link can view"
   - Copy URL to Source_GoogleDrive_URL__c field

6. **Assign Data Category**:
   - Primary: **CVMA Bylaws & Forms** > Bylaws > National Bylaws
   - Secondary: **CVMA Admin Content** > Governance

7. **Publish Article**:
   - Click **Publish** button
   - Confirm publication

8. **Test**:
   - ✅ Article appears in Knowledge search
   - ✅ Google Drive URL clickable and opens PDF
   - ✅ All custom fields visible
   - ✅ Accordion sections organized correctly
   - ✅ Hover state shows CVMA Red (not Gold)
   - ✅ (Optional) Test cvmaGoogleDriveFileViewer component if added to Lightning Record Page

---

### **Step 9: Create Remaining 17 Articles** (85 minutes - 5 min each)

**Priority Documents for Phase 1** (18 total):

#### **Bylaws Articles (5 articles)**:
1. ✅ CVMA National Bylaws - Revision V (test article created)
2. CVMA National Bylaws - Appendix C (Discipline)
3. CVMA National Bylaws - Appendix D (Election Procedures)
4. CVMA Chapter Bylaws Template
5. FL 20-7 Chapter Bylaws

#### **Forms Articles (8 articles)**:
6. CVMA Form 100 - Membership Application (01OCT25 Revision)
7. CVMA Form 101 - Patch Agreement (01OCT25 Revision)
8. CVMA Form 102 - Life Membership Application (01OCT25 Revision)
9. CVMA Form 400 - Investigation Decision Form
10. CVMA Form 401 - Chapter Request for State Investigation
11. CVMA Form 402 - State Investigative Committee Outline
12. CVMA Form 403 - Sworn Statement (Blank)
13. CVMA Form 410 - Counseling Form

#### **SOP Articles (3 articles)**:
14. CVMA SOP - Auxiliary State Representative Voting Procedures
15. CVMA SOP - Chapter Meeting Procedures
16. CVMA Protocol - License Use and Apparel Guidelines

#### **Financial Articles (2 articles)**:
17. CVMA Treasurer Report Template
18. CVMA Life Membership Calculator Guide

---

### **Article Creation Template** (Use for all 17):

```
Title: [Document Name]
UrlName: (auto-generated)
Summary: [1-2 sentence description]

Content (Rich Text):
  [Comprehensive summary with key sections, purpose, and usage notes]

  Key Sections:
  - [Section 1]
  - [Section 2]
  - [etc.]

  [Effective date, supersedes information, or revision notes]

Document_Type__c: [Bylaws | Form | Standard Operating Procedure | Financial Report]
Effective_Date__c: [MM/DD/YYYY or blank]
Revision_Number__c: [e.g., "Revision V", "01OCT25", or blank]
CEB_Restricted__c: [☐ No (public) or ☑ Yes (CEB-only)]
Source_GoogleDrive_URL__c: [Google Drive URL]
Form_Number__c: [e.g., "100" for forms, or blank]

Data Category: [Select appropriate categories]

Publish: ✅
```

---

## 📋 **Pre-Session Checklist**

### **Before Starting Article Creation**:
- [ ] Google Drive folder structure ready:
  ```
  CVMA 20-7 Documents/
  ├── Bylaws/
  │   ├── National/
  │   └── Chapter/
  ├── Forms/
  │   ├── Membership/
  │   ├── Disciplinary/
  │   └── Administrative/
  ├── SOPs/
  └── Financial Reports/
  ```
- [ ] PDFs uploaded to Google Drive (18 documents)
- [ ] Shareable links created ("Anyone with the link can view")
- [ ] Lightning Record Page includes HTML component with CSS link:
  ```html
  <link rel="stylesheet" href="{!$Resource.cvmaKnowledgeRecordPageCSS}">
  ```
- [ ] Browser cache cleared (test accordion hover - should be CVMA Red)

---

## 🚀 **Session Options**

### **Option A: Complete Epic #3 Phase 1** ⭐ RECOMMENDED (2 hours)
**Goal**: Finish all 18 Knowledge articles, test publishing workflow, validate member access

**Tasks**:
1. Configure 3 Permission Sets (30 min)
2. Create test article (15 min)
3. Upload PDFs to Google Drive (30 min if not done)
4. Create remaining 17 articles (85 min)
5. Test member access and search (10 min)

**Outcome**: Epic #3 Phase 1 100% complete ✅

---

### **Option B: Permission Sets + Testing Only** (1 hour)
**Goal**: Configure permissions and thoroughly test one article

**Tasks**:
1. Configure 3 Permission Sets (30 min)
2. Create test article (15 min)
3. Test all functionality:
   - Publishing workflow
   - Search and discoverability
   - Google Drive link functionality
   - cvmaGoogleDriveFileViewer component (if added)
   - Member access with different profiles
   - CEB-restricted content gating
   - Accordion styling (CVMA Red hover)

**Outcome**: Validation complete, bulk article creation next session

---

### **Option C: Automated Markdown → Knowledge Pipeline** (Research)
**Goal**: Explore automation for session documentation → Knowledge articles

**Tasks**:
1. Research MCP server for Google Drive
2. Design workflow: Markdown → PDF → Google Drive → Knowledge article
3. Evaluate options:
   - MCP server integration
   - Apex automation via Epic #12
   - Manual process template
4. Create proof-of-concept

**Outcome**: Automation plan for future implementation

---

## 📚 **Reference Documents for Next Session**

### **Essential Reading** (Quick refresh - 5 min):
1. `EPIC-3-PHASE-1-LIGHTNING-KNOWLEDGE-CORRECT-APPROACH.md` - Implementation guide (Steps 7-9)
2. `SESSION-NOVEMBER-03-2025-EPIC-3-ACHIEVEMENTS.md` - Today's achievements summary
3. `CVMA-CONTENT-ARCHITECTURE-COMPARISON.md` - Option C Hybrid architecture reference

### **Optional Deep Dive**:
4. `KNOWLEDGE-RECORD-PAGE-IMPLEMENTATION-GUIDE.md` - Lightning Record Page troubleshooting
5. `CVMA-RESOURCE-REGISTRY.md` - OneDrive document locations (if needed)

### **OneDrive Source Documents**:
- **Bylaws**: `C:\Users\zerov\OneDrive\Documents\CVMA\Documentation\Bylaws\`
- **Forms**: `C:\Users\zerov\OneDrive\Documents\CVMA\Documentation\Forms\`
- **SOPs**: `C:\Users\zerov\OneDrive\Documents\CVMA\Documentation\SOP\`
- **Financial**: `C:\Users\zerov\OneDrive\Documents\CVMA\Tressurer\`

---

## 💡 **Tips for Efficient Article Creation**

### **Batch Processing Strategy**:
1. **Upload all PDFs to Google Drive first** (30 min)
   - Organize in folder structure
   - Create shareable links for all
   - Copy URLs to spreadsheet/notepad for easy access

2. **Create articles in batches by type** (5 min each):
   - Bylaws batch (5 articles)
   - Forms batch (8 articles)
   - SOP batch (3 articles)
   - Financial batch (2 articles)

3. **Use copy/paste for similar articles**:
   - Copy previous article
   - Update title, summary, content, fields
   - Update Google Drive URL
   - Publish

### **Quality Checklist Per Article**:
- [ ] Title clear and searchable
- [ ] Summary concise (1-2 sentences)
- [ ] Content comprehensive with key sections
- [ ] All metadata fields filled
- [ ] Google Drive URL tested (clickable, opens PDF)
- [ ] Data Category assigned
- [ ] Published successfully
- [ ] Appears in Knowledge search

---

## 🔧 **Troubleshooting Quick Reference**

### **Issue: Accordion Still Shows Gold on Hover**
- **Solution**: Hard refresh (Ctrl+Shift+R)
- **Verify**: HTML component added to Lightning Record Page
- **Check**: Static resource deployed (Setup → Static Resources → cvmaKnowledgeRecordPageCSS)

### **Issue: Google Drive URL Not Clickable**
- **Solution**: Ensure field type is URL (not Text)
- **Check**: Source_GoogleDrive_URL__c field data type = URL

### **Issue: Article Not Appearing in Search**
- **Solution**: Verify article published (not Draft)
- **Check**: Data Category assigned
- **Verify**: User has Knowledge tab visible and Read permission

### **Issue: CEB-Restricted Content Visible to All Members**
- **Solution**: Configure Data Category visibility rules
- **Alternative**: Use sharing rules or profile-based security

---

## ✅ **Success Criteria for Next Session**

Epic #3 Phase 1 is complete when:
- [ ] 3 Permission Sets configured and assigned
- [ ] 18 Knowledge articles created and published
- [ ] All articles have Google Drive URLs
- [ ] All articles assigned to Data Categories
- [ ] Test article validated (all fields working)
- [ ] Member access tested (Full Member can view)
- [ ] CEB-restricted content gated correctly
- [ ] Search and discoverability working
- [ ] Accordion hover shows CVMA Red (not Gold)

---

## 📊 **Estimated Timeline**

| Task | Time | Cumulative |
|------|------|------------|
| Permission Set 1 (Publisher) | 10 min | 10 min |
| Permission Set 2 (Viewer) | 10 min | 20 min |
| Permission Set 3 (CEB Restricted) | 10 min | 30 min |
| Upload PDFs to Google Drive | 30 min | 60 min |
| Create test article + validation | 15 min | 75 min |
| Create 17 remaining articles | 85 min | 160 min (2h 40m) |
| Test member access and search | 10 min | 170 min (2h 50m) |

**Total Estimated Time**: ~3 hours (with PDF upload) or ~2 hours (if PDFs pre-uploaded)

---

## 🎯 **Key Reminders**

1. **Option C Hybrid Architecture**: Knowledge articles link to Google Drive PDFs (no Salesforce file storage)
2. **7 Fields Total**: 6 custom + 1 standard "Content" (relabeled "Article Content")
3. **CVMA Red Hover**: Accordion sections should show #c41e3a on hover (deployed CSS)
4. **Data Categories**: 3 groups assigned (Admin Content, Bylaws & Forms, Policy/Protocols/SOP)
5. **Source Documentation**: All GitHub issues must include source attribution (new protocol)

---

## 🏍️ **Ready to Complete Phase 1!**

Everything is prepared for Epic #3 Phase 1 completion:
- ✅ Knowledge object configured
- ✅ Lightning Record Page created
- ✅ Data Categories assigned
- ✅ CVMA branding applied
- ✅ Architecture decided (Option C)

**Remaining**: Permission Sets + 18 Knowledge articles = ~2-3 hours

**Result**: Searchable, organized, scalable CVMA document library for 300+ future documents

---

🏍️ **Vets Serving Vets - Chapter 20-7**

🎖️ Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>

**Created**: November 3, 2025
**Ready For**: November 4, 2025+ session
