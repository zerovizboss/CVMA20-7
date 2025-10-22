# Epic #12: Google Drive MCP Integration (REVISED)

**Priority**: HIGH
**Status**: Planning - MCP Server Approach
**Epic Owner**: CVMA Development Team
**Target Completion**: Q1 2026
**GitHub Issue**: #86
**Strategy**: Google MCP Server (NOT V2_Gdrive Package)

---

## 🎯 **Business Problem**

### **Developer Edition Storage Crisis**

**Salesforce Developer Edition Limits**:
- **File Storage**: 20 MB total (all files across org)
- **Data Storage**: 5 MB total (all records)
- **Current Usage**: ~15 MB (75% capacity)

**Impact**:
- Cannot store CVMA documents (bylaws, forms, SOPs)
- Cannot upload member photos or event images
- Cannot attach files to assistance requests (User Story #76)
- Risk of deployment failures when limits exceeded

---

## 💡 **Solution: Google MCP Server Integration**

### **Why MCP Server > AppExchange Package**

**Traditional V2_Gdrive Package Approach**:
❌ Adds 50-100 custom components to Salesforce
❌ Consumes Developer Edition custom object/field limits
❌ Requires managed package installation
❌ 10,000+ lines of vendor-controlled code
❌ Limited customization options
❌ Vendor dependency for updates/fixes

**Google MCP Server Approach**:
✅ **ZERO Salesforce package overhead**
✅ Only custom metadata records (1 KB per file)
✅ No custom objects or Apex classes required
✅ ~100 lines of LWC code (you control everything)
✅ Native Claude Code integration
✅ AI-powered features included
✅ Direct Google Drive API access
✅ Unlimited storage (Google Drive = 15 GB free or unlimited with Workspace)

**Storage Savings**: 95%+ reduction in Salesforce storage usage

---

## 🏗️ **MCP Server Architecture**

### **System Design**

```
┌─────────────────────────────────────────────────┐
│         CVMA Member (Browser)                   │
│     Experience Cloud Community                  │
└──────────────┬──────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────┐
│    Salesforce LWC Component                     │
│    cvmaGoogleDriveViewer                        │
│  - Query custom metadata for file list          │
│  - Display file cards with previews             │
│  - "View" button → Google Drive link            │
│  - Military ribbon styling (CVMA branding)      │
└──────────────┬──────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────┐
│  Custom Metadata Type (Salesforce)              │
│  CVMA_Google_Drive_File__mdt                    │
│                                                  │
│  Fields:                                         │
│  - File_Name__c: "CVMA Bylaws 2025.pdf"        │
│  - Google_Drive_ID__c: "1VblBnqH..."           │
│  - File_Type__c: "PDF"                          │
│  - Category__c: "Bylaws"                        │
│  - Public_Link__c: "https://drive.google.com"  │
│  - Size_MB__c: 2.5                              │
│  - Uploaded_Date__c: 2025-01-15                 │
│  - Description__c: "National bylaws revision"   │
│  - CEB_Only__c: false                           │
│  - Display_Order__c: 10                         │
│                                                  │
│  Storage: ~500 bytes per file record            │
└──────────────┬──────────────────────────────────┘
               │
               │ (Managed via Claude Code + MCP)
               ▼
┌─────────────────────────────────────────────────┐
│     Claude Code + MCP Integration Agent         │
│  (Running on developer machine)                 │
│                                                  │
│  Operations:                                     │
│  - Upload files from OneDrive → Google Drive    │
│  - Generate public/private links                │
│  - Create custom metadata records               │
│  - Deploy metadata to Salesforce                │
│  - Sync folder structures                       │
│  - AI-powered search and summarization          │
└──────────────┬──────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────┐
│     Google MCP Server                           │
│  (@modelcontextprotocol/server-gdrive)          │
│                                                  │
│  Capabilities:                                   │
│  - gdrive_list_files                            │
│  - gdrive_upload_file                           │
│  - gdrive_download_file                         │
│  - gdrive_search                                │
│  - gdrive_create_folder                         │
│  - gdrive_get_file_metadata                     │
│  - gdrive_set_permissions                       │
└──────────────┬──────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────┐
│          Google Drive API                       │
│  CVMA Folder: 1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej│
│                                                  │
│  /Bylaws (5 PDFs - 10 MB)                       │
│  /Forms (25 PDFs/DOCX - 15 MB)                  │
│  /Photos (50 images - 20 MB)                    │
│  /Meeting Materials (10 PPTX - 8 MB)            │
│  /Training (15 videos/PDFs - 50 MB)             │
│                                                  │
│  Total: 103 MB in Google Drive                  │
│  Salesforce Storage: <50 KB (metadata only)     │
└─────────────────────────────────────────────────┘
```

---

## 📋 **Revised User Stories (MCP Approach)**

### **Total Story Points: 23 (was 50 with package approach - 54% reduction!)**

---

### **User Story #86: Google MCP Server Setup & Configuration**

**Story Points**: 5
**Priority**: CRITICAL (Blocker)
**Epic**: #12 Google Drive Integration

**Acceptance Criteria**:
- Google MCP Server installed on development machine
- OAuth credentials configured via Google Cloud Console
- Claude Code can communicate with MCP server
- Test file upload/download working to CVMA folder (1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej)
- Custom metadata type CVMA_Google_Drive_File__mdt created
- MCP Integration Agent created and operational

**Technical Implementation**:

1. **Install Google MCP Server**:
```bash
npm install -g @modelcontextprotocol/server-gdrive
```

2. **Configure Claude Code MCP** (.claude/mcp.json):
```json
{
  "mcpServers": {
    "gdrive": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-gdrive"
      ],
      "env": {
        "GDRIVE_ROOT_FOLDER_ID": "1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej",
        "GOOGLE_API_KEY": "<from Google Cloud Console>"
      }
    }
  }
}
```

3. **Create Custom Metadata Type**:
```xml
<!-- CVMA_Google_Drive_File__mdt -->
<CustomObject>
    <label>CVMA Google Drive File</label>
    <fields>
        <fullName>File_Name__c</fullName>
        <type>Text</type>
        <length>255</length>
    </fields>
    <fields>
        <fullName>Google_Drive_ID__c</fullName>
        <type>Text</type>
        <length>100</length>
    </fields>
    <!-- Additional fields: File_Type__c, Category__c, Public_Link__c, etc. -->
</CustomObject>
```

4. **Create MCP Integration Agent** (see Agent Specification section)

**Testing Checklist**:
- [ ] MCP server responds to Claude Code commands
- [ ] Can list files in CVMA Google Drive folder
- [ ] Can upload test file to Google Drive
- [ ] Can generate shareable link
- [ ] Can create metadata record in Salesforce
- [ ] MCP Integration Agent operational

**Dependencies**: None (foundation story)

**Estimated Tokens**: 40-50K

---

### **User Story #87: Document Migration via MCP**

**Story Points**: 3
**Priority**: HIGH
**Epic**: #12 Google Drive Integration

**Acceptance Criteria**:
- All files from OneDrive migrated to Google Drive
- Folder structure preserved (/Bylaws, /Forms, /Documentation, etc.)
- Salesforce custom metadata records created for each file
- Public/private links generated appropriately
- Metadata deployed to Salesforce org
- Migration validation report generated

**OneDrive Source**: `C:\Users\zerov\OneDrive\Documents\CVMA\Documentation`

**Files to Migrate**:
- Bylaws: 5 PDFs (~10 MB)
- Forms: 25+ PDFs/DOCX (~15 MB)
- Documentation: 20+ PDFs/DOCX (~8 MB)
- Total: ~50 files, ~33 MB

**Implementation via Claude Code + MCP**:

```javascript
// User command to Claude Code:
"Migrate all files from C:\Users\zerov\OneDrive\Documents\CVMA\Documentation
to Google Drive folder 1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej.
Preserve folder structure.
Create Salesforce custom metadata records for each file.
Deploy metadata to cvma org."

// MCP Integration Agent executes:
1. Scan OneDrive folder recursively
2. For each file:
   a. Upload to Google Drive (via MCP)
   b. Get Google Drive file ID
   c. Generate public link
   d. Create CVMA_Google_Drive_File__mdt record
3. Deploy all metadata to Salesforce
4. Generate migration report
5. Validate all files accessible
```

**Post-Migration Validation**:
- All OneDrive files have corresponding Google Drive files
- All Google Drive files have metadata records in Salesforce
- File sizes match (checksum validation)
- Links are accessible
- Folder hierarchy preserved

**Salesforce Storage Impact**:
- 50 files × 500 bytes/file = 25 KB total
- **Storage savings**: 33 MB → 25 KB = **99.9% reduction**

**Dependencies**: User Story #86 (MCP Server Setup)

**Estimated Tokens**: 30-40K

---

### **User Story #88: Google Drive File Viewer LWC**

**Story Points**: 5
**Priority**: HIGH
**Epic**: #12 Google Drive Integration

**Acceptance Criteria**:
- LWC component displays Google Drive files from custom metadata
- Filter by category (Bylaws, Forms, Documentation, etc.)
- File type badges (PDF, DOCX, XLSX, etc.)
- CEB-only file visibility restrictions
- Click to open Google Drive preview
- Download button for offline access
- Search/filter functionality
- Mobile-responsive design
- Military ribbon styling (CVMA branding)
- Guest user restrictions (members only)

**Architecture**: Reuse proven pattern from User Stories #73-75!

```javascript
// cvmaGoogleDriveViewer.js (similar to CVMALegalResourcesController)
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import IS_GUEST from '@salesforce/user/isGuest';

export default class CvmaGoogleDriveViewer extends LightningElement {
    @track selectedCategory = '';
    @track files = [];
    @track categories = [];

    // Query custom metadata (NO Apex controller needed!)
    @wire(getRecord, { /* query CVMA_Google_Drive_File__mdt */ })
    wiredFiles({ data, error }) {
        if (data) {
            this.files = this.transformMetadata(data);
        }
    }

    handleView(event) {
        const fileLink = event.target.dataset.link;
        window.open(fileLink, '_blank'); // Open Google Drive preview
    }
}
```

**Component Features**:
- Category dropdown (same as Legal/Career resources)
- File cards with preview thumbnails
- Military ribbon styling (red/gold border)
- Badge for file type (PDF, DOCX, etc.)
- Badge for CEB-only files
- Search bar for file name filtering

**Integration**:
- Experience Cloud: Combat Veterans Motorcycle Association site
- Page: Resources or new "Documents" page
- Visibility: Members only (Guest restriction via IS_GUEST)

**Code Estimate**: ~150 lines (4 files: .js, .html, .css, .js-meta.xml)

**Dependencies**: User Story #87 (Migration complete)

**Estimated Tokens**: 35-45K

---

### **User Story #89: Document Upload via MCP (CEB Only)**

**Story Points**: 5
**Priority**: MEDIUM
**Epic**: #12 Google Drive Integration

**Acceptance Criteria**:
- CEB officers can upload files via Claude Code
- Files automatically organized by category
- Custom metadata record created automatically
- Public link generated and stored
- File appears in LWC viewer immediately after deployment
- Upload validation (file type, size limits)
- Error handling and retry logic

**Implementation via MCP Integration Agent**:

```javascript
// CEB Officer command to Claude Code:
"Upload the file C:\Users\zerov\Downloads\meeting-minutes-jan-2025.pdf
to CVMA Google Drive under /Meeting Materials.
Create metadata record and deploy to Salesforce."

// MCP Integration Agent executes:
1. Validate file type (PDF, DOCX, XLSX, images only)
2. Validate file size (<10 MB)
3. Upload to Google Drive /Meeting Materials folder
4. Generate public link
5. Create CVMA_Google_Drive_File__mdt record
6. Deploy metadata to Salesforce
7. Confirm file visible in LWC viewer
```

**Upload Process**:
1. CEB officer uses Claude Code (no Salesforce UI needed)
2. MCP Integration Agent handles all operations
3. File appears in Google Drive
4. Metadata appears in Salesforce after deployment
5. Members see file in Experience Cloud viewer

**Security**:
- Only CEB officers can execute upload commands
- File type whitelist: PDF, DOCX, XLSX, JPG, PNG
- Size limit: 10 MB per file
- Category validation (must match existing categories)

**No Salesforce UI Component Needed**:
- Uploads happen via Claude Code + MCP
- CEB officers already using Claude Code for development
- Simpler than building drag-and-drop UI

**Dependencies**: User Story #88 (Viewer component)

**Estimated Tokens**: 35-45K

---

### **User Story #92: AI-Powered Document Search (MCP Native)**

**Story Points**: 5
**Priority**: MEDIUM
**Epic**: #12 Google Drive Integration

**Acceptance Criteria**:
- Semantic search over Google Drive files via Claude Code
- Search by content (not just filename)
- AI-generated file summaries
- Results ranked by relevance
- Can search across PDF content
- Integration with Experience Cloud (optional LWC search component)

**AI Features (Native with MCP)**:

```javascript
// Example 1: Semantic Search
User: "Find all documents related to CEB term limits"
Claude Code (via MCP):
- Searches Google Drive files
- Reads PDF content
- Finds relevant sections
- Returns: "CVMA Bylaws 2025.pdf (Section 4.2), FL-20-7-Bylaws.pdf (Article III)"

// Example 2: Document Summarization
User: "Summarize the key changes in the 2025 bylaws revision"
Claude Code (via MCP):
- Fetches CVMA Bylaws 2025.pdf from Google Drive
- Analyzes content
- Generates summary:
  "1. CEB term limits changed from 2 to 3 years
   2. New treasurer position added
   3. Meeting quorum reduced from 10 to 7 members"

// Example 3: Document Comparison
User: "What are the differences between national and chapter bylaws?"
Claude Code (via MCP):
- Fetches both PDFs
- Compares content
- Highlights differences in table format
```

**LWC Search Component** (Optional):
- Search bar in Experience Cloud
- Calls Claude Code API endpoint (future enhancement)
- Displays AI-generated results
- Links to Google Drive files

**Implementation**:
- Primary: Claude Code commands (immediate - no development)
- Future: LWC component for member search (8 story points - separate user story)

**Dependencies**: User Story #88 (File viewer)

**Estimated Tokens**: 30-40K

---

## 🤖 **MCP Integration Agent Specification**

### **Agent Name**: `mcp-integration-manager`

**Purpose**: Specialized agent for MCP server operations, Google Drive integration, and external API management.

**Capabilities**:
1. **Google Drive Operations** (via MCP)
   - Upload/download files
   - List folder contents
   - Create folders
   - Set file permissions
   - Generate shareable links

2. **Salesforce Metadata Management**
   - Create custom metadata records
   - Deploy metadata to org
   - Validate deployments
   - Query existing metadata

3. **File Migration**
   - Batch upload from local filesystem
   - Preserve folder structures
   - Generate migration reports
   - Validate file integrity (checksums)

4. **AI-Powered Features**
   - Semantic search over documents
   - Document summarization
   - Content extraction from PDFs
   - File categorization suggestions

**Tools Available**:
- `*` (all tools for maximum flexibility)
- Specialized for: Bash, Read, Write, Edit, Task (sub-agents)
- MCP server communication (native)

**Example Usage**:

```javascript
// Upload and index files
Task (mcp-integration-manager):
  "Upload all files from C:\Users\zerov\OneDrive\Documents\CVMA\Documentation\Bylaws
   to Google Drive folder 1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej/Bylaws.
   Create Salesforce custom metadata records.
   Deploy to cvma org."

// Search and analyze
Task (mcp-integration-manager):
  "Search Google Drive for all references to 'CEB term limits' in bylaws documents.
   Summarize findings and provide section references."

// Batch migration
Task (mcp-integration-manager):
  "Migrate all CVMA documents from OneDrive to Google Drive.
   Create folder structure: Bylaws, Forms, Documentation, Photos, Training.
   Generate metadata for each file.
   Deploy to Salesforce.
   Provide migration report with file counts and storage savings."
```

**Agent Configuration** (.claude/agents/mcp-integration-manager.md):

```markdown
# MCP Integration Manager Agent

You are the MCP Integration Manager, specialized in Google Drive integration and external API operations for the CVMA Salesforce project.

## Your Responsibilities

1. **Google Drive Operations**
   - Use MCP server (@modelcontextprotocol/server-gdrive) for all Google Drive operations
   - Upload/download files to CVMA folder (1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej)
   - Generate public/private shareable links
   - Maintain folder organization

2. **Salesforce Custom Metadata**
   - Create CVMA_Google_Drive_File__mdt records for each uploaded file
   - Include: File_Name__c, Google_Drive_ID__c, File_Type__c, Category__c, Public_Link__c
   - Deploy metadata to Salesforce using deployment tools
   - Validate deployments successful

3. **File Migration**
   - Batch process OneDrive → Google Drive migrations
   - Preserve folder hierarchies
   - Generate checksums for validation
   - Create migration reports (file counts, sizes, storage savings)

4. **AI Features**
   - Use MCP to read file contents
   - Provide semantic search over documents
   - Generate document summaries
   - Suggest file categorizations

## Key Constraints

- Developer Edition: Minimize Salesforce storage (use custom metadata only)
- File size limit: 10 MB per file (warn if exceeded)
- Allowed file types: PDF, DOCX, XLSX, JPG, PNG (reject others)
- CVMA folder root: 1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej
- Target org: cvma

## Success Criteria

- 95%+ Salesforce storage reduction
- All files accessible via public links
- Metadata records match Google Drive files 1:1
- Migration reports show 100% success rate
- AI search returns relevant results
```

---

## 📊 **Epic Success Metrics**

### **Storage Optimization**

**Target**: 95%+ Salesforce storage reduction

**Before Migration**:
- Salesforce file storage: ~15 MB (75% of 20 MB limit)
- Risk of hitting storage limit
- Cannot upload new files

**After Migration**:
- Salesforce storage: <500 KB (2.5% of 20 MB limit)
- Google Drive storage: 100+ MB (unlimited capacity)
- **Storage reduction**: 96.7%

**Capacity Unlocked**:
- Can store 1,000+ files in Google Drive
- Salesforce storage freed for critical data
- No risk of deployment failures

### **Performance Targets**

- File retrieval: <2 seconds (Google Drive link)
- Upload processing: <5 seconds per file (via MCP)
- Search results: <1 second (AI-powered)
- Metadata deployment: <30 seconds per batch

### **User Adoption**

- CEB officers trained on MCP upload process (100%)
- Members access documents via LWC viewer (90%+ usage)
- Zero file access complaints
- AI search usage: 50+ queries/month

---

## 🔧 **Developer Edition Optimization**

### **Zero Package Overhead**

**No Salesforce Components Added**:
- Custom objects: 0
- Custom fields: 0 (except metadata type fields)
- Apex classes: 0 (optional 1-2 for enhanced LWC)
- Managed packages: 0

**Only Metadata**:
- 1 custom metadata type (CVMA_Google_Drive_File__mdt)
- 100+ metadata records (~50 KB total)
- 1 LWC component (~10 KB)

**Total Salesforce Overhead**: <100 KB (vs 10+ MB with package)

### **API Limit Avoidance**

**Traditional Approach** (V2_Gdrive Package):
- Every file operation = Salesforce API call
- 5,000 API calls/day limit in Developer Edition
- Risk of hitting limit with heavy usage

**MCP Approach**:
- File operations happen externally (MCP server)
- Only metadata deployments use Salesforce API
- Typical usage: <50 API calls/day
- **99% API call reduction**

---

## 🗓️ **Revised Implementation Timeline**

**Sprint 1 (Week 1)**: Foundation
- User Story #86: MCP Server setup & testing (5 story points)
- Create MCP Integration Agent
- Test file upload/download

**Sprint 2 (Week 2)**: Migration
- User Story #87: OneDrive → Google Drive migration (3 story points)
- Validate all files accessible
- Generate migration report

**Sprint 3 (Week 3-4)**: User Interface
- User Story #88: File viewer LWC (5 story points)
- Deploy to Experience Cloud
- User acceptance testing

**Sprint 4 (Week 5)**: Enhancement
- User Story #89: CEB upload via MCP (5 story points)
- User Story #92: AI-powered search (5 story points)

**Total Duration**: 5 weeks
**Total Story Points**: 23 (vs 50 with package approach)

---

## 📋 **Dependencies & Prerequisites**

### **External Services**

**Google Drive**:
- Google account: detonator@cvma20-7.org
- Folder created: 1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej
- API access enabled (Google Cloud Console)

**Claude Code**:
- MCP support enabled
- Google MCP server installed
- OAuth credentials configured

**Salesforce**:
- Developer Edition org: cvma
- Custom metadata deployment enabled
- Experience Cloud sites active

### **Technical Prerequisites**

**Development Machine**:
- Node.js 18+ installed
- npm installed
- Git bash environment
- OneDrive sync active

**Knowledge**:
- Custom metadata types (User Stories #73-75 pattern)
- LWC development (proven in previous user stories)
- MCP server configuration (new - documented in User Story #86)

---

## 🎯 **Business Value**

### **Immediate Benefits**

1. **Storage Crisis Resolved**
   - 96.7% Salesforce storage reduction
   - Unlimited file capacity via Google Drive
   - Future-proof for growth

2. **Cost Avoidance**
   - No Salesforce storage upgrades needed ($$$)
   - No AppExchange package costs
   - Leverage existing Google Workspace

3. **User Experience**
   - Seamless file access in Experience Cloud
   - Familiar Google Drive interface
   - Mobile-responsive viewing

### **Long-Term Value**

1. **AI-Powered Features**
   - Semantic search over documents
   - Automatic summarization
   - Smart categorization
   - Content analysis

2. **Scalability**
   - Support 1,000+ files easily
   - No Salesforce governor limit concerns
   - Unlimited storage growth

3. **Flexibility**
   - Full control over integration
   - Custom features as needed
   - No vendor lock-in

### **Vets Serving Vets Mission**

- Enable comprehensive document library for members
- Support assistance requests with file attachments (User Story #76)
- Professional CEB document management
- Training materials and resources accessible 24/7
- Event photos and member engagement

---

## ⚠️ **Risks & Mitigations**

### **Risk**: MCP server learning curve
**Mitigation**: User Story #86 includes comprehensive testing and documentation. MCP Integration Agent handles complexity.

### **Risk**: Google Drive API rate limits
**Mitigation**: MCP server handles rate limiting automatically. Batch operations for efficiency.

### **Risk**: OAuth token expiration
**Mitigation**: MCP server manages token refresh. Document troubleshooting steps.

### **Risk**: File migration data loss
**Mitigation**:
- Keep OneDrive files until validation complete
- Checksum verification for all uploads
- Migration report with 100% accuracy requirement
- Rollback plan documented

---

## 📚 **Documentation Deliverables**

1. **MCP Server Setup Guide**
   - Installation instructions
   - OAuth configuration steps
   - Troubleshooting common issues

2. **MCP Integration Agent Guide**
   - Agent capabilities
   - Example commands
   - Best practices

3. **File Migration Runbook**
   - Step-by-step migration process
   - Validation procedures
   - Rollback instructions

4. **CEB Training Materials**
   - Upload process via Claude Code
   - File organization guidelines
   - Best practices

5. **Member User Guide**
   - Accessing documents in Experience Cloud
   - Search functionality
   - Mobile access instructions

6. **Technical Architecture Diagram**
   - System components
   - Data flow
   - Integration points

---

## 📊 **Success Criteria Summary**

**Technical Success**:
- ✅ 95%+ Salesforce storage reduction achieved
- ✅ All files migrated without data loss
- ✅ LWC viewer deployed and functional
- ✅ MCP Integration Agent operational
- ✅ Zero Salesforce package overhead

**User Success**:
- ✅ CEB officers can upload files via Claude Code
- ✅ Members can view documents in Experience Cloud
- ✅ AI search returns relevant results
- ✅ No file access complaints

**Business Success**:
- ✅ Storage crisis resolved
- ✅ Cost avoidance achieved (no Salesforce upgrades)
- ✅ Future-proof architecture established
- ✅ Vets Serving Vets mission supported

---

**Epic Owner**: CVMA Development Team
**GitHub Issue**: #86
**Status**: Ready for implementation
**Approach**: Google MCP Server (RECOMMENDED)
**Alternative**: V2_Gdrive Package (documented in EPIC-12-GOOGLE-DRIVE-INTEGRATION.md for reference)

🎖️ Combat Veterans Motorcycle Association Chapter 20-7
🏍️ Vets Serving Vets - Data Storage Excellence via MCP Integration
**Created**: October 21, 2025
**Revised**: October 21, 2025 (MCP approach)
