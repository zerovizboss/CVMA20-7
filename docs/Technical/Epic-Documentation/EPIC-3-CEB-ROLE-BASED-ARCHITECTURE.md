# Epic #3: CEB Role-Based Architecture & Knowledge Publishing Workflow

**Created**: October 25, 2025
**Epic**: #3 - Knowledge Article Foundation (MCP-Enhanced)
**Status**: Architecture Planning

---

## 🏍️ Overview

This document defines the **CEB Role-Based Architecture** that governs how CEB (Central Executive Board) members create, manage, and publish content for the broader CVMA membership. The architecture follows both **Chapter and National CVMA Bylaws** and implements a sophisticated **Role Hierarchy** with controlled access patterns.

---

## 🎯 Core Architectural Principles

### 1. **Three-Tier Access Model**

| Tier | User Type | Access Level | Example |
|------|-----------|--------------|---------|
| **Tier 1** | Guest Users | Public content only (no file access) | Bylaws, public forms |
| **Tier 2** | Members (Non-CEB) | Published Knowledge Articles + shared files | Meeting minutes, Treasury reports |
| **Tier 3** | CEB Members | Role-specific pages + creation tools + all member access | Secretary page, Treasurer dashboards |

### 2. **Member Identification**
- **Member Number**: Stored in Contact record (`Member_Number__c` field)
- **Access Control**: Only users with valid Member Number can access shared files
- **Guest Restriction**: No Member Number = No file access (public content only)

### 3. **CEB Navigation Structure**
```
Navigation Menu
├── Public Menu Items (All Users)
├── Member Menu Items (Authenticated Members)
└── CEB Menu (CEB Members Only) ✅ IMPLEMENTED
    ├── Commander Page
    ├── Vice Commander Page
    ├── Secretary Page (create Meeting Minutes)
    ├── Treasurer Page (Reports & Dashboards)
    ├── Sergeant at Arms Page (SAA Corner - currently implemented)
    ├── Road Captain Page
    └── Chaplain Page
```

---

## 🔐 Role Hierarchy & Permissions

### Salesforce Role Hierarchy
Based on CVMA Bylaws organizational structure:

```
Chapter Commander (Top)
├── Vice Commander
├── Secretary
├── Treasurer
├── Sergeant at Arms
├── Road Captain
└── Chaplain
```

**Permission Model**:
- Each CEB role has **dedicated site page** (navigation link)
- Role-specific **objects, records, flows, and reports**
- Create/edit capabilities within their domain
- **Publish** completed work to Members via Knowledge Articles

---

## 📋 CEB Role Workflows

### **Secretary Workflow** (Example)

#### **Creation Phase** (CEB-Only Access)
1. Secretary accesses **Secretary Page** via CEB navigation menu
2. Creates **Meeting Minutes** using Salesforce form/flow
3. Drafts document in Salesforce (or integrates with Google Drive via MCP)
4. Reviews and finalizes document

#### **Publication Phase** (Member Access)
5. Secretary clicks **"Publish to Members"** button/action
6. System creates **Knowledge Article** linking to the meeting minutes
7. Knowledge Article tagged with:
   - Category: `Meeting Minutes`
   - Data Category: `CEB Documents`
   - Visibility: `Members Only` (requires Member Number)
8. Members see new article on **TBD site page** (recommendation below)

#### **Google Drive Integration**
- Meeting Minutes stored in: `Google Drive/CVMA/Documentation/Secretary/`
- File added to `CVMA_Google_Drive_File__mdt` registry
- `CEB_Only__c = false` (visible to all members after publication)
- Link generated via `CVMAKnowledgeGoogleDriveHelper.getGoogleDriveURL()`

---

### **Treasurer Workflow** (Example)

#### **Creation Phase** (CEB-Only Access)
1. Treasurer accesses **Treasurer Page** via CEB navigation menu
2. Uses **Reports & Dashboards** to compile monthly data
3. Generates **Monthly Treasury Report** (Salesforce Report or Google Doc)
4. Reviews financial data and finalizes report

#### **Publication Phase** (Member Access)
5. Treasurer clicks **"Publish Monthly Report"** action
6. System creates **Knowledge Article** with report attachment/link
7. Knowledge Article tagged with:
   - Category: `Financial Reports`
   - Data Category: `Treasury`
   - Visibility: `Members Only`
8. Members see report on **TBD site page** (Financial Dashboard or Documents page)

#### **Google Drive Integration**
- Treasury Reports stored in: `Google Drive/CVMA/Documentation/Treasurer/`
- File added to `CVMA_Google_Drive_File__mdt` registry
- `CEB_Only__c = false` (published for members)
- Already have 5 files deployed (Jan, Mar, May, Jun, Aug 2025)

---

## 🗂️ Google Drive Folder Architecture

### **Current Structure** (Mirrors CEB Roles)
```
Google Drive/CVMA/
├── Documentation/
│   ├── Bylaws/ ✅ DEPLOYED (Epic #12 - 101 files)
│   ├── Forms/ ✅ DEPLOYED
│   ├── Secretary/ ✅ DEPLOYED (1 file - Feb 2025 Agenda)
│   ├── Treasurer/ ✅ DEPLOYED (5 files - Monthly Reports)
│   ├── Commander/ ⏳ PENDING
│   ├── Vice_Commander/ ⏳ PENDING
│   ├── Sergeant_at_Arms/ ⏳ PENDING
│   ├── Road_Captain/ ⏳ PENDING
│   └── Chaplain/ ⏳ PENDING
├── Events/ ⏳ PENDING
├── CEB/ ⏳ PENDING
└── Media/ ⏳ PENDING
```

### **Access Control Mapping**
| Folder | CEB Role Access | Member Access | Guest Access |
|--------|----------------|---------------|--------------|
| Bylaws | Read/Write (CO/VCO) | Read | Read (public) |
| Forms | Read/Write (Secretary) | Read | Read (some forms) |
| Secretary | Read/Write (Secretary) | Read (published) | None |
| Treasurer | Read/Write (Treasurer) | Read (published) | None |
| Events | Read/Write (RC) | Read | None |
| CEB | Read/Write (All CEB) | None | None |

---

## 🎨 Recommended Knowledge Article Publication Strategy

### **Option 1: Dedicated "Member Documents" Page** ⭐ RECOMMENDED

**Benefits**:
- Single source of truth for all published documents
- Easy to find (consistent location)
- Can organize by category tabs or filters
- Supports search and filtering by CEB role, date, category

**Page Structure**:
```
Member Documents Hub
├── Tab: Meeting Minutes (Secretary publications)
├── Tab: Financial Reports (Treasurer publications)
├── Tab: Event Plans (Road Captain publications)
├── Tab: Commander Updates (Commander announcements)
└── Search/Filter (by date, category, CEB role)
```

**Implementation**:
- Create new Experience Cloud page: `Member_Documents`
- Add Lightning Knowledge component with filters
- Configure Data Category visibility (Members Only)
- Add to Member navigation menu

---

### **Option 2: Role-Specific Publication Pages**

**Benefits**:
- Clear ownership (Secretary page shows Secretary's publications)
- Natural fit for users familiar with org structure
- Can include role context and instructions

**Page Structure**:
```
├── Secretary Resources (Meeting Minutes)
├── Treasurer Resources (Financial Reports)
├── Road Captain Resources (Ride Plans)
└── etc.
```

**Implementation**:
- Enhance existing CEB role pages with "Published Documents" section
- Create separate "Publications" section below creation tools
- Use Lightning Knowledge component filtered by role

---

### **Option 3: Hybrid Approach** ⭐ MOST FLEXIBLE

**Benefits**:
- Best of both worlds
- Documents accessible from multiple entry points
- Supports different user mental models

**Implementation**:
1. **Primary Hub**: "Member Documents" page (all documents)
2. **Secondary Access**: Each CEB role page has "Recent Publications" section
3. **Tertiary Access**: SAA Corner or Dashboard pages show relevant documents

**Example User Journeys**:
- **Journey 1**: Member clicks "Documents" → Sees all published content
- **Journey 2**: Member clicks "Treasurer" → Sees Treasurer's recent reports
- **Journey 3**: Member visits Dashboard → Sees "Latest Financial Report" widget

---

## 🔧 Technical Implementation Requirements

### **Custom Fields** (Already Implemented)
From Epic #12 and current deployment:

| Field | Type | Purpose |
|-------|------|---------|
| `Google_Drive_ID__c` | Text | Unique file identifier |
| `Category__c` | Text | Document category (Meeting Minutes, Financial Reports) |
| `CEB_Only__c` | Checkbox | Access restriction flag |
| `Display_Order__c` | Number | Sort order for display |
| `Is_Active__c` | Checkbox | Publication status |
| `Uploaded_Date__c` | Date | Publication date |
| `Description__c` | Text Area | Document description |

### **New Custom Fields** (Recommended)
| Field | Type | Purpose |
|-------|------|---------|
| `Published_By_Role__c` | Picklist | CEB role that published (Secretary, Treasurer, etc.) |
| `Publication_Status__c` | Picklist | Draft, Under Review, Published, Archived |
| `Member_Only__c` | Checkbox | Requires Member Number to access |
| `Publish_Date__c` | DateTime | When document was published to members |

### **Knowledge Article Custom Fields** (Recommended)
| Field | Type | Purpose |
|-------|------|---------|
| `Google_Drive_File_ID__c` | Lookup/Text | Link to CVMA_Google_Drive_File__mdt record |
| `CEB_Role__c` | Picklist | Publishing CEB role |
| `Requires_Member_Number__c` | Checkbox | Access control flag |

---

## 📊 Publication Flow (Technical)

### **Secretary Publishing Meeting Minutes**

```apex
// Pseudo-code for publication flow
public class CVMADocumentPublisher {

    @AuraEnabled
    public static void publishMeetingMinutes(String googleDriveFileId) {
        // 1. Validate CEB role permissions
        if (!hasRole('Secretary')) {
            throw new AuraHandledException('Only Secretary can publish meeting minutes');
        }

        // 2. Get file metadata
        CVMA_Google_Drive_File__mdt fileMetadata =
            [SELECT Label, Description__c, Google_Drive_ID__c, Category__c
             FROM CVMA_Google_Drive_File__mdt
             WHERE Google_Drive_ID__c = :googleDriveFileId
             WITH SECURITY_ENFORCED LIMIT 1];

        // 3. Create Knowledge Article
        Knowledge__kav article = new Knowledge__kav(
            Title = fileMetadata.Label,
            Summary = fileMetadata.Description__c,
            Google_Drive_File_ID__c = googleDriveFileId,
            CEB_Role__c = 'Secretary',
            Requires_Member_Number__c = true,
            UrlName = generateUrlName(fileMetadata.Label)
        );
        insert article;

        // 4. Publish article (moves to Published status)
        KbManagement.PublishingService.publishArticle(
            article.KnowledgeArticleId, true
        );

        // 5. Update metadata record
        // (Custom metadata can't be updated via Apex - handle via deployment)

        // 6. Send notification to members (optional)
        notifyMembers('New meeting minutes published: ' + article.Title);
    }
}
```

---

## 🎯 Recommended Next Steps

### **Phase 1: Foundation** (Current)
- ✅ Google Drive file registry (107 files deployed)
- ✅ CVMAKnowledgeGoogleDriveHelper utility class
- ✅ POC validation complete

### **Phase 2: Knowledge Article Integration** (Next)
1. Create custom fields on Knowledge object
2. Create "Member Documents" hub page
3. Build CVMADocumentPublisher utility class
4. Create Lightning Web Component for publication workflow
5. Configure Data Categories for role-based filtering

### **Phase 3: CEB Role Page Enhancement** (Subsequent)
1. Add "Publish" buttons to Secretary/Treasurer pages
2. Integrate publication flow with existing creation workflows
3. Add "Recent Publications" sections to CEB role pages
4. Create notification system for new publications

### **Phase 4: Member Experience** (Final)
1. Deploy "Member Documents" page to Member navigation
2. Configure search and filtering by category/role/date
3. Add dashboard widgets for latest publications
4. Create email notifications for new Knowledge Articles

---

## 🏆 Success Metrics

### **User Adoption**
- CEB members publishing documents via Salesforce (vs. email/manual)
- Members accessing documents via Knowledge Articles (vs. asking CEB)
- Reduction in "Where is the latest [document]?" questions

### **Technical Performance**
- Page load time < 2 seconds for Member Documents hub
- Search results accuracy > 95%
- Zero guest users accessing member-only content (security validation)

### **Content Growth**
- Number of Knowledge Articles published per month
- Number of Google Drive files integrated
- Categories and CEB roles represented

---

## 📝 Decision Log

### **Open Decisions** (Awaiting CEB Input)
1. **Publication Page Location**: Option 1, 2, or 3?
2. **Approval Workflow**: Should documents require CO/VCO approval before publication?
3. **Notification Preference**: Email, in-app, or both?
4. **Archival Policy**: How long to keep old meeting minutes/reports active?

### **Proposed Recommendations**
- **Publication Strategy**: Option 3 (Hybrid Approach) for maximum flexibility
- **Approval Workflow**: Start without approval (Secretary/Treasurer trusted), add later if needed
- **Notification**: Both email (digest) and in-app (bell icon)
- **Archival**: Keep all documents active, use "Archive" view filter for old content

---

## 🔗 Related Documentation

- **STORM_CLAUDE_CORE.md**: Current project status and protocols
- **CVMA-RESOURCE-REGISTRY.md**: OneDrive and Google Drive resource references
- **EPIC-3-MCP-KNOWLEDGE-INTEGRATION-DEV-GUIDE.md**: Technical implementation details
- **EPIC-3-POC-SUCCESS-VALIDATION.md**: Proof-of-concept validation results
- **EPIC-3-EXISTING-GDRIVE-STATUS.md**: Current Google Drive deployment status

---

## 💡 Architecture Notes

### **Why This Approach Works**

1. **Follows CVMA Bylaws**: Role hierarchy mirrors organizational structure
2. **Scalable**: Add new CEB roles/pages without architectural changes
3. **Secure**: Three-tier access model with Member Number validation
4. **User-Friendly**: CEB creates in familiar role context, Members consume in central hub
5. **MCP-Enhanced**: Unlimited document storage via Google Drive integration
6. **Future-Proof**: Knowledge Articles support versioning, search, analytics

### **Key Design Decisions**

- **Custom Metadata Registry**: Separates file metadata from Knowledge Articles (reusability)
- **Helper Class Pattern**: CVMAKnowledgeGoogleDriveHelper provides consistent access
- **Publication Workflow**: Explicit "publish" action (draft vs. published states)
- **Member Number Validation**: Contact record as source of truth for access control
- **Hybrid Publication Strategy**: Multiple access paths support different user needs

---

**Next Session TODO**: Get CEB feedback on publication page strategy (Option 1, 2, or 3) and proceed with Phase 2 implementation.
