# Google Drive MCP Server Setup Guide

**Epic**: #12 Google Drive MCP Integration
**User Story**: #86 MCP Server Setup & Configuration
**Date**: October 21, 2025
**Target Org**: cvma (Developer Edition)

---

## 🎯 **Setup Overview**

This guide walks through configuring the Google Drive MCP server for CVMA Chapter 20-7 document storage.

### **What We're Setting Up**
1. Google Drive API OAuth credentials
2. Claude Code MCP configuration
3. CVMA Google Drive folder access
4. Test file operations

### **Prerequisites**
- ✅ Google Account: `detonator@cvma20-7.org` (existing Gmail integration)
- ✅ CVMA Google Drive Folder: `1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej`
- ✅ MCP Package Installed: `@modelcontextprotocol/server-gdrive@2025.1.14`
- ✅ Claude Code MCP Config: `.claude/mcp.json` created

---

## 📋 **Step 1: Google Cloud Console Setup**

### **1.1 Create Google Cloud Project**

1. Navigate to: https://console.cloud.google.com/
2. Sign in with `detonator@cvma20-7.org`
3. Click **Select a project** → **NEW PROJECT**
   - **Project name**: `CVMA-MCP-Integration`
   - **Organization**: (Leave blank for personal account)
   - Click **CREATE**

### **1.2 Enable Google Drive API**

1. In the new project, go to **APIs & Services** → **Library**
2. Search for **"Google Drive API"**
3. Click **Google Drive API** → **ENABLE**
4. Wait for API to activate (~30 seconds)

### **1.3 Create OAuth 2.0 Credentials**

1. Go to **APIs & Services** → **Credentials**
2. Click **CREATE CREDENTIALS** → **OAuth client ID**
3. Configure OAuth consent screen (if prompted):
   - **User Type**: External
   - **App name**: `CVMA MCP Integration`
   - **User support email**: `detonator@cvma20-7.org`
   - **Developer contact**: `detonator@cvma20-7.org`
   - **Scopes**: Add `https://www.googleapis.com/auth/drive.file`
   - Click **SAVE AND CONTINUE**
4. Create OAuth Client ID:
   - **Application type**: Desktop app
   - **Name**: `CVMA MCP Client`
   - Click **CREATE**
5. **Download JSON** (save as `google-oauth-credentials.json`)
   - Store in: `C:\Users\zerov\.config\claude-code\gdrive\credentials.json`

---

## 📋 **Step 2: Claude Code MCP Configuration**

### **2.1 Verify MCP Config File**

File already created at: `.claude/mcp.json`

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
        "GDRIVE_FOLDER_ID": "1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej"
      }
    }
  }
}
```

### **2.2 Set OAuth Credentials Path**

Create directory structure:
```bash
mkdir -p "C:\Users\zerov\.config\claude-code\gdrive"
```

Move downloaded JSON file:
```bash
mv ~/Downloads/google-oauth-credentials.json "C:\Users\zerov\.config\claude-code\gdrive\credentials.json"
```

---

## 📋 **Step 3: First-Time Authentication**

### **3.1 Restart Claude Code**

Close and reopen Claude Code to load the new MCP configuration.

### **3.2 Authenticate with Google**

When you first use an MCP Google Drive command, you'll be prompted to authenticate:

1. **Browser window opens** → Sign in with `detonator@cvma20-7.org`
2. **Grant permissions**:
   - ✅ View and manage Google Drive files
   - ✅ View and manage metadata
3. **Copy authorization code** → Paste into Claude Code terminal
4. **Token saved** → Authentication complete

### **3.3 Verify Folder Access**

Test that Claude Code can access CVMA Google Drive folder:

```bash
# This command should list contents of CVMA folder
# (Execute via Claude Code after authentication)
```

---

## 📋 **Step 4: Test MCP Operations**

### **4.1 Test File Upload**

Create a test file and upload to Google Drive:

```bash
# Create test file
echo "CVMA MCP Integration Test - $(date)" > /tmp/mcp-test.txt

# Upload via MCP (Claude Code command)
# Expected: File uploaded to CVMA Google Drive folder
```

### **4.2 Test File List**

List files in CVMA Google Drive folder:

```bash
# Claude Code MCP command to list files
# Expected: See "mcp-test.txt" in results
```

### **4.3 Test File Download**

Download the test file:

```bash
# Claude Code MCP command to download
# Expected: File downloaded to local system
```

### **4.4 Test File Delete**

Clean up test file:

```bash
# Claude Code MCP command to delete
# Expected: "mcp-test.txt" removed from Google Drive
```

---

## 📋 **Step 5: Salesforce Metadata Type Creation**

### **5.1 Create Custom Metadata Type**

Create `CVMA_Google_Drive_File__mdt` with these fields:

| Field API Name | Type | Length | Description |
|----------------|------|--------|-------------|
| File_Name__c | Text | 255 | Original filename |
| Google_Drive_ID__c | Text | 100 | Google Drive file ID |
| File_Type__c | Text | 50 | PDF, DOCX, XLSX, JPG, PNG |
| Category__c | Text | 50 | Bylaws, Forms, Documentation, Photos, Training, Meeting Materials |
| Public_Link__c | URL | 255 | Google Drive shareable link |
| Size_MB__c | Number | 6,2 | File size in megabytes |
| Uploaded_Date__c | Date | - | Upload date |
| Description__c | Long Text Area | 1000 | File description |
| CEB_Only__c | Checkbox | - | Restrict to CEB officers only |
| Display_Order__c | Number | 3,0 | Sort order in UI |
| Is_Active__c | Checkbox | - | Active/inactive flag (default: true) |

### **5.2 Deploy to Salesforce**

```bash
sf project deploy start --metadata-dir src/main/default/objects/CVMA_Google_Drive_File__mdt --target-org cvma
```

---

## 📋 **Step 6: MCP Integration Manager Agent Validation**

### **6.1 Test Agent Invocation**

Use the MCP Integration Manager agent:

```
Task (mcp-integration-manager):
"List all files in the CVMA Google Drive folder"
```

**Expected Output**: List of files with names, IDs, sizes

### **6.2 Test File Migration**

Upload a CVMA document:

```
Task (mcp-integration-manager):
"Upload C:\Users\zerov\OneDrive\Documents\CVMA\Documentation\Bylaws\CVMA-National-Bylaws-Revision-V.pdf
 to CVMA Google Drive Bylaws folder.
 Create Salesforce metadata record.
 Category: Bylaws, CEB Only: false"
```

**Expected Outcome**:
- ✅ File uploaded to Google Drive
- ✅ Shareable link generated
- ✅ Custom metadata record created
- ✅ Metadata deployed to Salesforce

---

## ⚠️ **Troubleshooting**

### **Error: "OAuth token not found"**
**Solution**: Run authentication flow (Step 3.2)

### **Error: "Insufficient permissions"**
**Solution**: Re-authenticate with full Drive scope:
- Delete `~/.config/claude-code/gdrive/token.json`
- Restart authentication flow
- Ensure you grant "View and manage files" permission

### **Error: "Folder not found"**
**Solution**: Verify CVMA folder ID in `.claude/mcp.json`:
```bash
GDRIVE_FOLDER_ID=1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej
```

### **Error: "API quota exceeded"**
**Solution**: Google Drive API free tier limits:
- 12,000 queries per 60 seconds
- If exceeded, wait 60 seconds and retry

### **Error: "Package deprecated warning"**
**Solution**: This is expected (see ADR-001). Package is functional despite deprecation.

---

## ✅ **Success Checklist**

Mark complete when validated:

- [ ] Google Cloud project created (`CVMA-MCP-Integration`)
- [ ] Google Drive API enabled
- [ ] OAuth credentials created and downloaded
- [ ] `.claude/mcp.json` configured
- [ ] First-time authentication completed
- [ ] Test file upload successful
- [ ] Test file download successful
- [ ] CVMA_Google_Drive_File__mdt created
- [ ] Metadata type deployed to Salesforce
- [ ] MCP Integration Manager agent operational

---

## 📚 **References**

- **Google Cloud Console**: https://console.cloud.google.com/
- **Google Drive API Docs**: https://developers.google.com/drive/api
- **MCP Package**: `@modelcontextprotocol/server-gdrive@2025.1.14`
- **Epic #12 Documentation**: `docs/Technical/Epic-Documentation/EPIC-12-GOOGLE-DRIVE-MCP-INTEGRATION.md`
- **ADR-001**: `docs/Technical/ARCHITECTURE-DECISION-RECORDS.md`
- **MCP Integration Manager Agent**: `.claude/agents/mcp-integration-manager.md`

---

## 🔐 **Security Notes**

**Credentials Storage**:
- OAuth credentials: `C:\Users\zerov\.config\claude-code\gdrive\credentials.json`
- **DO NOT commit to git** (already in .gitignore)
- Tokens auto-refresh (valid for 7 days, then re-authenticate)

**Permission Scopes**:
- `https://www.googleapis.com/auth/drive.file` - Minimum required scope
- Files created by this app only (not full Drive access)

**Salesforce Metadata**:
- Custom metadata = configuration data (safe to commit)
- Contains file IDs and public links (not sensitive)
- CEB_Only__c flag controls member access

---

**Created**: October 21, 2025
**Last Updated**: October 21, 2025
**Status**: Ready for implementation

🏍️ **CVMA Chapter 20-7 - Vets Serving Vets**
⚡ **MCP Integration Excellence**
