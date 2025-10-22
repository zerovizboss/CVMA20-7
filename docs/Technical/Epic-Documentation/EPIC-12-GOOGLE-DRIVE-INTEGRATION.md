# Epic #12: Google Drive Data Storage Integration & Migration

**Priority**: HIGH
**Status**: Planning
**Epic Owner**: CVMA Development Team
**Target Completion**: Q1 2026
**GitHub Issue**: TBD (to be created)

---

## 🎯 **Business Problem**

### **Developer Edition Storage Constraint**

Salesforce Developer Edition has severe storage limitations:
- **File Storage**: 20 MB total (shared across all files)
- **Data Storage**: 5 MB total (all records)
- **Current Usage**: Approaching limits with CVMA documents, member photos, event files

### **Impact**
- Cannot store chapter documents (bylaws, forms, SOPs)
- Cannot upload member photos or event images
- Cannot attach files to assistance requests (upcoming User Story #76)
- Risk of deployment failures due to storage limits

### **Solution**
Migrate all Salesforce file storage to Google Drive, leveraging existing Gmail integration.

---

## 📊 **Current State Assessment**

### **Existing Infrastructure**
- ✅ Google Drive connector package installed (`V2_Gdrive__` namespace)
- ✅ Gmail integration active for email
- ✅ Google Drive folder created: https://drive.google.com/drive/folders/1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej
- ❌ V2_Gdrive package may need reinstallation/reconfiguration

### **Data to Migrate**
1. CVMA Documents (bylaws, forms, SOPs) - currently in OneDrive
2. Member photos and event images (future)
3. Assistance request attachments (User Story #76)
4. CEB meeting materials (User Story #70)
5. Training materials and resources

---

## 🏗️ **Proposed Solution Architecture**

### **Integration Approach**
1. **Google Drive as Primary Storage**: All files stored in Google Drive
2. **Salesforce as Index**: ContentDocument records point to Google Drive file IDs
3. **Seamless User Experience**: LWC components display Drive files inline
4. **Automatic Sync**: Files uploaded to Salesforce auto-sync to Google Drive
5. **Permission Mapping**: Salesforce sharing rules mirror to Google Drive permissions

### **Developer Edition Optimization**
- Files stored in Google Drive (unlimited storage with Google Workspace)
- Salesforce stores only file metadata (~1 KB per file vs full file size)
- Reduce Salesforce storage usage by 95%+

---

## 📋 **User Stories Breakdown**

### **User Story #86: Google Drive Package Installation & Configuration**
**Story Points**: 3
**Priority**: CRITICAL (Blocker for all other stories)

**Acceptance Criteria**:
- V2_Gdrive package reinstalled/configured in CVMA org
- Google Drive OAuth connected to `detonator@cvma20-7.org`
- CVMA folder (`1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej`) set as default root
- Permission sets assigned to CEB officers
- Test file upload/retrieval working

**Technical Tasks**:
- Install/upgrade V2_Gdrive from AppExchange
- Configure Google OAuth connection
- Map Salesforce profiles to Google Drive permissions
- Create test LWC component for file upload

---

### **User Story #87: Document Migration from OneDrive to Google Drive**
**Story Points**: 5
**Priority**: HIGH

**Acceptance Criteria**:
- All CVMA documents migrated from OneDrive to Google Drive CVMA folder
- Folder structure preserved: `/Bylaws`, `/Forms`, `/Documentation`, etc.
- File metadata maintained (creation dates, descriptions)
- Salesforce ContentDocument records created with Google Drive file IDs
- Verify all links in existing LWC components work

**Files to Migrate**:
- Bylaws (5 PDFs)
- Forms (20+ CVMA forms)
- Documentation (SOPs, protocols, policies)
- Event materials
- Training guides

**OneDrive Source**: `C:\Users\zerov\OneDrive\Documents\CVMA\Documentation`

---

### **User Story #88: Google Drive File Browser LWC Component**
**Story Points**: 8
**Priority**: HIGH

**Acceptance Criteria**:
- LWC component displays Google Drive folder contents
- Support for folder navigation (breadcrumbs)
- File preview for PDFs, images, documents
- Download button for all file types
- Search/filter capabilities
- Guest user restrictions (members only)
- Mobile-responsive design

**Integration**:
- Use V2_Gdrive API for file retrieval
- Display in Experience Cloud pages
- Replace existing cvmaMemberDocumentPortal with Google Drive browser

---

### **User Story #89: Google Drive Upload Component**
**Story Points**: 8
**Priority**: MEDIUM

**Acceptance Criteria**:
- LWC component for file uploads to Google Drive
- Drag-and-drop file upload
- Progress bar during upload
- Automatic folder organization (by document type)
- Create Salesforce ContentDocument record after upload
- CEB-only access (members cannot upload)
- File type validation (PDF, DOCX, XLSX, images)

**Use Cases**:
- CEB uploads meeting minutes
- Officers upload event photos
- Treasurer uploads financial reports

---

### **User Story #90: Automatic Salesforce-to-Drive Sync**
**Story Points**: 13
**Priority**: MEDIUM

**Acceptance Criteria**:
- Apex trigger on ContentDocument insert
- Automatically upload file to Google Drive
- Store Google Drive file ID in custom field
- Delete Salesforce file after successful upload (free storage)
- Error handling and retry logic
- Scheduled batch job to clean up orphaned files

**Technical Implementation**:
- ContentDocument trigger
- V2_Gdrive API callout
- Custom field: `Google_Drive_File_ID__c`
- Batch class for cleanup

---

### **User Story #91: Google Drive Permission Sync**
**Story Points**: 8
**Priority**: LOW

**Acceptance Criteria**:
- Salesforce record sharing mirrors to Google Drive file permissions
- CEB officers have edit access
- Members have view access
- Guests have no access
- Permission changes in Salesforce update Google Drive

**Implementation**:
- Apex sharing rules → Google Drive API permissions
- Scheduled job to sync permissions (hourly)

---

### **User Story #92: Google Drive Search Integration**
**Story Points**: 5
**Priority**: LOW

**Acceptance Criteria**:
- Global search component for Google Drive files
- Search by filename, content, metadata
- Filter by file type, date range, folder
- Results display with preview
- Deep linking to files in Experience Cloud

---

## 📊 **Epic Metrics & Success Criteria**

### **Storage Savings**
- Target: Reduce Salesforce file storage by 95%+
- Current: ~15 MB used (approaching 20 MB limit)
- Post-Migration: <1 MB (metadata only)

### **Performance**
- File retrieval: <2 seconds
- Upload processing: <5 seconds per file
- Search results: <1 second

### **User Adoption**
- CEB officers trained on upload component (100%)
- Members access documents via Google Drive browser (90%+ usage)
- Zero file access complaints

---

## 🔧 **Developer Edition Constraints & Mitigations**

### **Storage Limits**
- ✅ Files stored in Google Drive (unlimited)
- ✅ Salesforce stores metadata only (~1 KB/file)
- ✅ Reduces storage usage by 95%+

### **API Limits**
- ⚠️ Google Drive API: 1,000 requests/100 seconds/user
- ✅ Mitigation: Batch API calls, cache file metadata
- ✅ Use scheduled jobs for sync (avoid real-time limits)

### **Package Limits**
- ✅ V2_Gdrive package available for Developer Edition
- ⚠️ Some features may be limited (check package documentation)

### **Deployment Limits**
- ✅ Google Drive metadata doesn't count against deployment size
- ✅ No impact on Apex code limits

---

## 📋 **Dependencies**

### **Blockers**
- User Story #86 must complete first (package installation)
- Google OAuth authorization required

### **Integrations**
- User Story #22 (Member Document Portal) - will be replaced/enhanced
- User Story #76 (Assistance Requests) - file attachment integration
- User Story #70 (CEB Document Management) - meeting materials storage

### **External**
- Google Workspace account (`detonator@cvma20-7.org`)
- V2_Gdrive AppExchange package
- Google Drive API access

---

## 🗓️ **Implementation Timeline**

**Sprint 1 (Week 1-2)**: Foundation
- User Story #86: Package installation & configuration

**Sprint 2 (Week 3-4)**: Migration
- User Story #87: Document migration from OneDrive

**Sprint 3 (Week 5-6)**: Core Components
- User Story #88: File browser component

**Sprint 4 (Week 7-8)**: Upload & Sync
- User Story #89: Upload component
- User Story #90: Auto-sync (Phase 1)

**Sprint 5 (Week 9-10)**: Polish & Features
- User Story #91: Permission sync
- User Story #92: Search integration

---

## 🎯 **Business Value**

### **Storage Optimization**
- Eliminate Salesforce storage constraints
- Enable unlimited document storage via Google Drive
- Future-proof for growth (member photos, event files)

### **Cost Savings**
- Avoid Salesforce storage upgrade costs
- Leverage existing Google Workspace subscription
- No additional AppExchange costs (V2_Gdrive free tier)

### **User Experience**
- Seamless file access in Experience Cloud
- Familiar Google Drive interface
- Mobile-responsive document viewing

### **Vets Serving Vets Mission**
- Enable comprehensive document library for members
- Support assistance requests with file attachments
- Professional document management for chapter operations

---

## 📚 **Documentation Requirements**

- Installation guide for V2_Gdrive package
- Google OAuth setup instructions
- File migration runbook
- CEB training materials for upload component
- Member user guide for document access
- Troubleshooting guide for common issues

---

## ⚠️ **Risks & Mitigations**

### **Risk**: V2_Gdrive package no longer maintained
**Mitigation**: Evaluate alternative packages or custom integration using Google Drive API directly

### **Risk**: Google Drive API rate limits
**Mitigation**: Implement caching, batch processing, exponential backoff

### **Risk**: Permission sync complexity
**Mitigation**: Start with simple CEB/Member/Guest model, iterate

### **Risk**: File migration data loss
**Mitigation**: Keep OneDrive files until migration validated, checksum verification

---

## 📊 **Epic Summary**

**Total User Stories**: 7
**Total Story Points**: 50
**Estimated Duration**: 10 weeks (5 sprints)
**Dependencies**: 1 critical (User Story #86)
**Integrations**: 3 existing user stories

**Epic Owner**: CVMA Development Team
**Stakeholders**: CEB Officers, CVMA Members
**Target Org**: cvma (Developer Edition)
**Google Drive Folder**: https://drive.google.com/drive/folders/1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej

---

🎖️ Combat Veterans Motorcycle Association Chapter 20-7
🏍️ Vets Serving Vets - Data Storage Excellence
**Created**: October 21, 2025
