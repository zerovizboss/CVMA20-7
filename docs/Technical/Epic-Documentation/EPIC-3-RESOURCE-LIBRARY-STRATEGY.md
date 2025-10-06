# Epic #3: Resource Library Implementation Strategy
**Combat Veterans Motorcycle Association Chapter 20-7**

## 🎯 Strategic Overview

**Mission**: Provide 24/7 access to 300+ CVMA documents through Knowledge Articles integration

**Approach**: Standard Feature Integration (targeting 80%+ code reduction)

**Foundation**: Leverage OneDrive documentation repository (`C:\Users\zerov\OneDrive\Documents\CVMA`)

---

## 📊 User Story Prioritization

### **Phase 1: Foundation (Next Session - ~30K tokens)**

#### **User Story #69: Knowledge Article Foundation**
**Goal**: Deploy CVMA-specific Data Categories and Knowledge Article structure

**Standard Features Used**:
- Knowledge Articles (native Salesforce)
- Data Categories (organizational hierarchy)
- ArticleType: `CVMA_Document__kav`

**Components**:
1. **Data Category Group**: `CVMA_Organizational_Content`
   - Bylaws
   - Forms
   - Standard Operating Procedures (SOPs)
   - Meeting Minutes
   - Policies & Protocols
   - Financial Reports

2. **Custom Fields** on ArticleType:
   - Document_Type__c (picklist)
   - Effective_Date__c (date)
   - Revision_Number__c (text)
   - Approval_Status__c (picklist: Draft, Pending CEB Review, Approved, Archived)
   - Approved_By__c (lookup to Contact)
   - CEB_Restricted__c (checkbox - visibility control)

3. **Permission Sets**:
   - CVMA_Knowledge_Article_Publisher (Secretary role)
   - CVMA_Knowledge_Article_Viewer (all members)

**Code Reduction**: 85% (use native Knowledge vs custom document management)

**Deployment**: ~25 components

**Duration**: 3-4 hours

---

#### **User Story #70: Document Migration Pipeline**
**Goal**: Migrate priority documents from OneDrive to Knowledge Articles

**Priority Documents** (15-20 articles for Phase 1):
1. **National Bylaws** (Revision V + Appendices A-E)
2. **Chapter 20-7 Bylaws** (FL-20-7)
3. **Top 10 CVMA Forms**:
   - Form 100: Membership Application
   - Form 101: Patch Agreement
   - Form 102: Life Membership Application
   - Form 400: Investigation Decision
   - Form 404: Administrative Hold
   - Form 410: Counseling Form
   - Form 201: Chapter Relocation
   - Form 202: Benevolent Fund Request
   - Form 204: Medical Exemption
   - Form 500: Auxiliary Chapter Request

4. **Critical SOPs** (3-5 articles)

**Apex Utility Class**: CVMADocumentMigrationHelper
- readOneDrivePDF() - Access C:\Users\zerov\OneDrive\Documents\CVMA files
- createKnowledgeArticle() - Automated article generation
- assignDataCategory() - Proper categorization
- triggerCEBApproval() - Secretary review workflow

**Code Reduction**: 75% (use Data Loader + utility class vs full custom migration UI)

**Deployment**: ~10 components (Apex class, test class, Process Builder flow)

**Duration**: 2-3 hours

---

### **Phase 2: User Experience (Future Session - ~25K tokens)**

#### **User Story #71: Document Search & Discovery Component**
**Goal**: Lightning component for member document access

**Standard Features Used**:
- Lightning Knowledge component (configurable)
- Global Search integration
- Recent Articles widget

**Custom LWC**: `cvmaDocumentLibrary`
- Category filtering (Data Category navigation)
- Search bar (Knowledge search API)
- Featured documents carousel
- Recently updated articles feed

**Code Reduction**: 70% (leverage Lightning Knowledge base components)

**Deployment**: ~15 components

**Duration**: 3-4 hours

---

### **Phase 3: CEB Workflow (Future Session - ~20K tokens)**

#### **User Story #72: CEB Document Approval Workflow**
**Goal**: Secretary → Commander approval flow for CEB-restricted content

**Standard Features Used**:
- Approval Process (native Salesforce)
- Email Templates
- Knowledge Article lifecycle (Draft → Pending → Published)

**Automation**:
- Secretary creates article (Draft status)
- Auto-submit for Commander approval if CEB_Restricted__c = true
- Email notifications to CEB on new/updated documents
- Published articles auto-notify members via digest

**Code Reduction**: 90% (native Approval Process vs custom workflow)

**Deployment**: ~12 components

**Duration**: 2-3 hours

---

## 🎯 Session-by-Session Roadmap

### **Next Session (October 6, 2025)**: Phase 1 - User Stories #69 + #70
**Token Budget**: ~35K / 200K (leaves 90K+ for cleanup and buffer)

**Deliverables**:
1. Knowledge Article data model deployed
2. Data Categories configured
3. 15-20 priority documents migrated
4. CEB permission sets assigned
5. GitHub issues closed: #69, #70

**Success Criteria**:
- Members can access bylaws and top 10 forms via Knowledge
- Secretary has article publishing permissions
- CEB-restricted content properly gated
- 80%+ code reduction through Standard Feature Integration

---

### **Future Session 2**: Phase 2 - User Story #71
**Token Budget**: ~25K

**Deliverables**:
1. cvmaDocumentLibrary LWC deployed
2. Enhanced search and discovery experience
3. Featured documents showcase

---

### **Future Session 3**: Phase 3 - User Story #72
**Token Budget**: ~20K

**Deliverables**:
1. CEB approval workflow operational
2. Email notifications configured
3. Complete Epic #3 closure

---

## 💰 Business Value

### **Operational Efficiency**:
- **70% reduction** in document sharing overhead (email attachments eliminated)
- **24/7 member access** to critical organizational documents
- **Version control** with audit trail for all document revisions

### **Governance Excellence**:
- **CEB oversight** on restricted content publication
- **Compliance tracking** with effective dates and revision numbers
- **Professional presentation** of CVMA organizational structure

### **Technology Leadership**:
- **80%+ average code reduction** through Knowledge Articles
- **Enterprise-grade** content management without custom development
- **Scalable foundation** for 300+ document library

---

## 🔧 Technical Architecture

### **Data Model**:
```
Knowledge Article (CVMA_Document__kav)
├── Data Category: CVMA_Organizational_Content
│   ├── Bylaws
│   ├── Forms
│   ├── SOPs
│   ├── Meeting Minutes
│   ├── Policies
│   └── Financial Reports
├── Custom Fields:
│   ├── Document_Type__c
│   ├── Effective_Date__c
│   ├── Revision_Number__c
│   ├── Approval_Status__c
│   ├── Approved_By__c
│   └── CEB_Restricted__c
└── Attachments: PDF files from OneDrive
```

### **Security Model**:
```
Permission Sets:
├── CVMA_Knowledge_Article_Publisher (Secretary)
├── CVMA_Knowledge_Article_Viewer (All Members)
└── CVMA_CEB_Restricted_Viewer (CEB Officers only)

Sharing Rules:
├── Public articles: All members
└── CEB-restricted: Commander, XO, Secretary, Treasurer only
```

### **Integration Points**:
```
OneDrive Repository (C:\Users\zerov\OneDrive\Documents\CVMA)
└── CVMADocumentMigrationHelper.readOneDrivePDF()
    └── Knowledge Article Creation
        └── Data Category Assignment
            └── CEB Approval (if restricted)
                └── Published & Member Accessible
```

---

## 📚 Success Metrics

### **Code Reduction Target**: 80%+
- Before: ~3,500 lines custom document management
- After: ~700 lines Knowledge configuration + utilities
- **Reduction**: 80% through Standard Feature Integration

### **Deployment Efficiency**:
- Phase 1: ~35 components (1 session)
- Phase 2: ~15 components (1 session)
- Phase 3: ~12 components (1 session)
- **Total**: ~62 components across 3 sessions

### **User Adoption**:
- 15-20 priority documents available Day 1
- 100% CEB officers trained on publishing workflow
- All members can access critical bylaws and forms 24/7

---

## 🚀 Next Steps

### **Immediate Actions (Next Session)**:
1. Deploy Knowledge Article foundation (User Story #69)
2. Migrate 15-20 priority documents (User Story #70)
3. Configure CEB permission sets
4. Test member access and search functionality
5. Close GitHub issues #69, #70

### **CEB Approval Required**:
- Secretary role assignment for Knowledge Article publishing
- CEB-restricted content categories definition
- Document approval workflow activation

---

**Epic Owner**: WX Storm Claude + Tactical Agent
**Target Completion**: 3 sessions
**Business Impact**: HIGH - Core "information accessibility" mission

🎖️ **Generated with [Claude Code](https://claude.com/claude-code)**
**Date**: October 6, 2025
**Token Budget**: Conservative (35K next session leaves 90K+ buffer)
