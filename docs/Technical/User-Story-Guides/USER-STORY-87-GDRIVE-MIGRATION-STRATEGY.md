# User Story #87: Google Drive Document Migration Strategy

**Epic**: #12 Google Drive MCP Integration
**Story Points**: 3
**Status**: In Progress
**Date**: October 22, 2025

---

## 📊 **Migration Scope**

### **Google Drive Folder Structure**

**Root**: CVMA Chapter 20-7 (`1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej`)

**Main Folders** (6 total):
1. **CEB/** - Chapter Executive Board materials
2. **docs/** - Documentation (Bylaws, Forms, SOPs, Policies)
3. **Events/** - Event planning and documentation
4. **Media/** - Photos, videos, promotional materials
5. **Secretary/** - Meeting minutes, correspondence
6. **Treasurer/** - Financial reports, budget documents

### **docs/ Subfolder Breakdown** (92 files confirmed)

| Subfolder | File Count | Category |
|-----------|------------|----------|
| Bylaws | 12 | Governance documents |
| Forms | 43 | CVMA administrative forms |
| License Use | 8 | License compliance documents |
| Policy | 20 | Chapter and national policies |
| Protocol | 1 | Operational protocols |
| SOP | 8 | Standard Operating Procedures |
| Auxiliary | TBD | Auxiliary member materials |
| Technical | TBD | Technical documentation |
| Training | TBD | Training materials |

**docs/ Total**: 92+ files
**Estimated Grand Total**: 150-250+ files across all folders

---

## 🎯 **Phased Migration Approach**

### **Why Phased?**

**Challenges**:
- Large file count (potentially 100+ files)
- Need Google Drive file IDs for each file
- Custom metadata records must be created for each
- Token budget: ~105K remaining (need to reserve capacity)

**Solution**: 3-Phase Migration
- **Phase 1**: High-priority, high-visibility files (TODAY)
- **Phase 2**: Remaining documentation files (Next session)
- **Phase 3**: Media and archive files (Future session)

---

## 📋 **Phase 1: Priority Files (Current Session)**

### **Target Folders**: `docs/Bylaws/` and `docs/Forms/` (25 files)

**Priority Files** (25 files total):

**CSV Template Created**: `data/phase1-gdrive-files-template.csv`

#### **Bylaws** (8 files - HIGHEST PRIORITY)
- CVMA-National-Bylaws---Revision-V---Signed.pdf
- FL-20-7-Bylaws-221227.pdf
- Appendix-A.pdf
- CVMA-Bylaws-Appendix-B-Regional-Rotation-2024.pdf
- CVMA-Bylaws-Appendix-C-Discipline-2023.pdf
- CVMABylaws-AppendixDConflictofInterest.pdf
- CVMA-Bylaws-Appendix-E-BLCP-Form-and-Instructions-2023.pdf
- CVMA-National-Bylaws---Change-Revision-Summary--10August2025-.pdf

**Why These First?**:
- Referenced in Epic #4 Bylaws Compliance implementation
- Required for CEB dashboard functionality
- Frequently accessed by members
- Support existing Salesforce features (CEB term tracking, disciplinary system)

#### **Critical Forms** (5-7 files)
- CVMA Form 100: Membership Application (October 2025 revision)
- CVMA Form 101: Patch Agreement (October 2025 revision)
- CVMA Form 102: Life Membership Application (October 2025 revision)
- CVMA Form 400: Investigation Decision Form
- CVMA Form 404: Administrative Hold Memorandum
- CVMA Form 410: Counseling Form

**Why These Forms?**:
- October 2025 revisions (most current)
- Support Epic #4 disciplinary workflows
- High-frequency usage by CEB

---

## 📋 **Phase 2: Documentation Library (Next Session)**

### **Target Folders**: `docs/`, `CEB/`, `Events/`

**Remaining Documentation** (30-50 files):
- Additional Forms (CVMA Forms 200-500 series)
- SOPs (Standard Operating Procedures)
- Policies (Auxiliary, License Use, etc.)
- CEB meeting materials
- Event planning templates

**Estimated Effort**: 40-50K tokens, 1-2 hours

---

## 📋 **Phase 3: Media & Archives (Future Session)**

### **Target Folders**: `Media/`, `Secretary/`, `Treasurer/`

**Media Assets** (50-100+ files):
- Event photos (baseball games, escort services, rides)
- Historical chapter photography
- Promotional materials

**Administrative Archives**:
- Secretary meeting minutes (historical)
- Treasurer monthly reports (2025 archive)
- Correspondence and records

**Estimated Effort**: 60-80K tokens, 2-3 hours

---

## 🔧 **Phase 1 Implementation Plan**

### **Step 1: Collect Google Drive File IDs** (USER ACTION - 10 min)

**Process**:
1. Open Google Drive CVMA folder: https://drive.google.com/drive/folders/1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej
2. Navigate to `docs/Bylaws/` subfolder
3. For each of the 8 priority Bylaws files:
   - Right-click file → **Get link**
   - Copy the file ID from the URL
   - Format: `https://drive.google.com/file/d/[FILE_ID_HERE]/view`

**Data Collection Template**:

```
BYLAWS FILE IDs:
1. CVMA-National-Bylaws---Revision-V---Signed.pdf: [FILE_ID]
2. FL-20-7-Bylaws-221227.pdf: [FILE_ID]
3. Appendix-A.pdf: [FILE_ID]
4. CVMA-Bylaws-Appendix-B-Regional-Rotation-2024.pdf: [FILE_ID]
5. CVMA-Bylaws-Appendix-C-Discipline-2023.pdf: [FILE_ID]
6. CVMABylaws-AppendixDConflictofInterest.pdf: [FILE_ID]
7. CVMA-Bylaws-Appendix-E-BLCP-Form-and-Instructions-2023.pdf: [FILE_ID]
8. CVMA-National-Bylaws---Change-Revision-Summary--10August2025-.pdf: [FILE_ID]

FORMS FILE IDs:
9. CVMA Form 100 (October 2025): [FILE_ID]
10. CVMA Form 101 (October 2025): [FILE_ID]
11. CVMA Form 102 (October 2025): [FILE_ID]
12. CVMA Form 400: [FILE_ID]
13. CVMA Form 404: [FILE_ID]
14. CVMA Form 410: [FILE_ID]
```

---

### **Step 2: Create Custom Metadata Records** (CLAUDE ACTION - 20-25K tokens)

**Process**:
1. Receive file IDs from user
2. Generate 15-20 custom metadata XML files
3. Use naming convention: `CVMA_Google_Drive_File.[RecordName].md-meta.xml`
4. Set appropriate fields:
   - `File_Name__c`: Original filename
   - `Google_Drive_ID__c`: File ID from user
   - `File_Type__c`: PDF (all Phase 1 files)
   - `Category__c`: Bylaws or Forms
   - `Public_Link__c`: Full Google Drive shareable link
   - `Size_MB__c`: File sizes from local OneDrive copy
   - `Uploaded_Date__c`: 2025-10-22
   - `Description__c`: Descriptive text
   - `CEB_Only__c`: false (Bylaws), varies (Forms)
   - `Display_Order__c`: 10-110 (Bylaws), 200-300 (Forms)
   - `Is_Active__c`: true

---

### **Step 3: Deploy Metadata to Salesforce** (CLAUDE ACTION - 5-10K tokens)

**Deployment Command**:
```bash
sf project deploy start \
  --metadata-dir src/main/default/customMetadata \
  --target-org cvma
```

**Validation Query**:
```bash
sf data query \
  --query "SELECT QualifiedApiName, MasterLabel, File_Name__c, Category__c, Google_Drive_ID__c, Public_Link__c FROM CVMA_Google_Drive_File__mdt ORDER BY Display_Order__c" \
  --target-org cvma
```

---

### **Step 4: Test and Validate** (CLAUDE ACTION - 5K tokens)

**Validation Checklist**:
- [ ] All 15-20 metadata records deployed successfully
- [ ] Google Drive file IDs correct
- [ ] Public links accessible (test 3-5 random files)
- [ ] Categories properly set (Bylaws vs Forms)
- [ ] Display_Order creates logical sorting
- [ ] CEB_Only flag appropriate for each file

---

## 📊 **Metadata Record Schema**

### **Custom Metadata Type**: `CVMA_Google_Drive_File__mdt`

**Already Deployed** (User Story #86):
- Deployment ID: `0Afbm00000N02RBCAZ`
- Components: 12 (1 object + 11 fields)
- Storage per record: ~500 bytes

**Field Definitions**:

| Field API Name | Type | Length | Purpose |
|----------------|------|--------|---------|
| File_Name__c | Text | 255 | Original filename for display |
| Google_Drive_ID__c | Text | 100 | Unique Google Drive file identifier |
| File_Type__c | Text | 50 | PDF, DOCX, XLSX, JPG, PNG |
| Category__c | Text | 50 | Bylaws, Forms, Documentation, Photos, Training, Meeting Materials |
| Public_Link__c | URL | 255 | Full Google Drive shareable link |
| Size_MB__c | Number | 6,2 | File size in megabytes |
| Uploaded_Date__c | Date | - | Upload/migration date |
| Description__c | Long Text | 1000 | File description and context |
| CEB_Only__c | Checkbox | - | Restrict to CEB officers only |
| Display_Order__c | Number | 3,0 | Sort order in UI (10, 20, 30...) |
| Is_Active__c | Checkbox | - | Active/inactive flag (default: true) |

---

## 🎯 **Phase 1 Success Criteria**

### **Technical Validation**
- [ ] 15-20 custom metadata records created
- [ ] All records deployed to Salesforce without errors
- [ ] Google Drive file IDs validated (links work)
- [ ] Shareable links publicly accessible
- [ ] Query returns expected results

### **Business Validation**
- [ ] Bylaws accessible via metadata (supports Epic #4 features)
- [ ] Critical forms available (supports CEB workflows)
- [ ] File categorization supports future LWC filtering
- [ ] CEB permission model enforced

### **Documentation**
- [ ] MEMORY_CONTINUED.md updated with Phase 1 completion
- [ ] Phase 2-3 migration plan documented
- [ ] Git commit with metadata records pushed
- [ ] User Story #87 progress tracked (Phase 1 complete)

---

## 📈 **Storage Optimization Metrics**

### **Phase 1 Files**

**Bylaws Total**: ~2.6 MB (8 files)
**Forms Total**: ~1.5 MB (6 files)
**Phase 1 Total**: ~4.1 MB

**Salesforce Storage Impact**:
- **Without Google Drive**: 4.1 MB consumed (20% of 20 MB limit)
- **With Google Drive + Metadata**: ~7 KB (15 records × 500 bytes)
- **Storage Savings**: 99.8%

**Developer Edition Capacity**:
- **Before**: 75% used (15 MB / 20 MB)
- **After Phase 1**: ~76% used (15.007 MB / 20 MB - minimal increase)
- **Future**: Phase 2-3 adds ~500 bytes per file (not 1-5 MB each)

---

## 🚀 **Next Steps After Phase 1**

### **Immediate (This Session)**
1. User provides Google Drive file IDs for 15 priority files
2. Claude creates custom metadata records
3. Deploy metadata to Salesforce
4. Validate deployment and test links
5. Git commit and push

### **Short-term (Next Session)**
1. Phase 2: Remaining documentation files (30-50 files)
2. Create LWC component for file browsing (User Story #88)
3. Test member access to Bylaws/Forms via Experience Cloud

### **Long-term (Future Sessions)**
1. Phase 3: Media and archive files (50-100+ files)
2. File upload component (User Story #89)
3. AI-powered search integration (User Story #92)

---

## 📋 **User Action Required**

**To Continue Phase 1 Implementation**:

Please provide Google Drive file IDs for the **15 priority files** listed above. You can:

**Option A**: Copy file IDs directly from Google Drive
1. Navigate to each file in Google Drive
2. Right-click → "Get link"
3. Extract file ID from URL: `https://drive.google.com/file/d/[FILE_ID]/view`
4. Paste file IDs in chat

**Option B**: Share folder link structure
1. Provide the direct link to the `docs/Bylaws/` subfolder
2. Provide the direct link to the `docs/Forms/` subfolder
3. I'll guide you through getting the file IDs

**Option C**: Create shareable links for all files
1. Select all 15 files in Google Drive
2. Right-click → "Get link" → "Anyone with the link can view"
3. Copy the links and paste in chat

Once file IDs are provided, I'll create the metadata records and deploy within **20-30 minutes**.

---

## 🏍️ **Epic #12 Progress Update**

**User Story #86**: ✅ COMPLETE (MCP Server Setup - 5 pts)
**User Story #87**: 🔄 IN PROGRESS - Phase 1 (Document Migration - 3 pts)

**Epic Progress**: 5 of 23 story points (21.7% → ~30% after Phase 1)

**Next User Stories**:
- **#88**: File Viewer LWC (5 pts) - Ready after Phase 1 metadata
- **#89**: Upload Component (5 pts) - Requires #88
- **#92**: AI Search (5 pts) - Requires #87 complete

---

**Created**: October 22, 2025
**Last Updated**: October 22, 2025
**Status**: Awaiting file IDs for Phase 1 implementation

🏍️ **Combat Veterans Motorcycle Association Chapter 20-7**
**Vets Serving Vets - Data Storage Excellence**
