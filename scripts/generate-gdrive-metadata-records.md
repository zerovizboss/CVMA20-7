# Generate Google Drive Metadata Records

**Purpose**: Create custom metadata records for files uploaded to Google Drive CVMA folder

**Epic**: #12 Google Drive MCP Integration
**User Story**: #87 Document Migration

---

## 📋 **Process Overview**

### **Step 1: Get File List from Google Drive**

**Via Google Drive Web UI**:
1. Open: https://drive.google.com/drive/folders/1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej
2. Navigate to each subfolder
3. For each file, collect:
   - File name
   - Google Drive file ID (from URL or "Get link")
   - File type (PDF, DOCX, XLSX, JPG, PNG)
   - Folder/category (Bylaws, Forms, Training, etc.)
   - File size

**File ID Example**:
- Shareable link: `https://drive.google.com/file/d/1ABC123xyz/view?usp=sharing`
- File ID: `1ABC123xyz`

---

## 📋 **Step 2: Create Metadata Records**

### **Metadata Type: CVMA_Google_Drive_File__mdt**

**Fields**:
- `File_Name__c`: Original filename
- `Google_Drive_ID__c`: Google Drive file ID
- `File_Type__c`: PDF, DOCX, XLSX, JPG, PNG
- `Category__c`: Bylaws, Forms, Documentation, Photos, Training, Meeting Materials
- `Public_Link__c`: Full Google Drive shareable link
- `Size_MB__c`: File size in megabytes
- `Uploaded_Date__c`: Upload date (YYYY-MM-DD)
- `Description__c`: File description
- `CEB_Only__c`: Restrict to CEB officers only (checkbox)
- `Display_Order__c`: Sort order in UI
- `Is_Active__c`: Active/inactive flag (default: true)

---

## 📋 **Step 3: Metadata Record Template**

### **XML Format** (for each file):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>[Display Name]</label>
    <protected>false</protected>
    <values>
        <field>File_Name__c</field>
        <value xsi:type="xsd:string">CVMA-National-Bylaws-Revision-V-Signed.pdf</value>
    </values>
    <values>
        <field>Google_Drive_ID__c</field>
        <value xsi:type="xsd:string">[GOOGLE_DRIVE_FILE_ID]</value>
    </values>
    <values>
        <field>File_Type__c</field>
        <value xsi:type="xsd:string">PDF</value>
    </values>
    <values>
        <field>Category__c</field>
        <value xsi:type="xsd:string">Bylaws</value>
    </values>
    <values>
        <field>Public_Link__c</field>
        <value xsi:type="xsd:string">https://drive.google.com/file/d/[FILE_ID]/view</value>
    </values>
    <values>
        <field>Size_MB__c</field>
        <value xsi:type="xsd:double">1.5</value>
    </values>
    <values>
        <field>Uploaded_Date__c</field>
        <value xsi:type="xsd:date">2025-10-22</value>
    </values>
    <values>
        <field>Description__c</field>
        <value xsi:type="xsd:string">CVMA National Bylaws - Revision V (Signed, August 2025)</value>
    </values>
    <values>
        <field>CEB_Only__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
    <values>
        <field>Display_Order__c</field>
        <value xsi:type="xsd:double">10</value>
    </values>
    <values>
        <field>Is_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
</CustomMetadata>
```

**File Location**: `src/main/default/customMetadata/CVMA_Google_Drive_File.[RecordName].md-meta.xml`

---

## 📋 **Step 4: Batch Creation Strategy**

### **Priority Categories** (Phase 1):

1. **Bylaws** (8-12 files)
   - National Bylaws Revision V
   - Chapter 20-7 Bylaws
   - Appendices A-E
   - CEB_Only: false (all members)
   - Display_Order: 10-110

2. **Forms** (Top 10 most-used)
   - CVMA Form 100, 101, 102 (October 2025 revisions)
   - CVMA Form 400-404 (Disciplinary)
   - CEB_Only: varies by form
   - Display_Order: 200-300

3. **Training Materials** (5-10 files)
   - CEB officer training guides
   - Member orientation materials
   - CEB_Only: true (restricted)
   - Display_Order: 400-500

### **Deferred Categories** (Phase 2):

- Meeting Materials (minutes, agendas)
- Photos (event documentation)
- Administrative documents
- Media assets

---

## 📋 **Step 5: Deployment Process**

### **Deploy Metadata Records**:

```bash
# Deploy all Google Drive file metadata records
sf project deploy start \
  --metadata-dir src/main/default/customMetadata \
  --target-org cvma
```

### **Validate Deployment**:

```bash
# Query metadata records
sf data query \
  --query "SELECT QualifiedApiName, File_Name__c, Category__c, Google_Drive_ID__c FROM CVMA_Google_Drive_File__mdt" \
  --target-org cvma
```

---

## 📋 **Step 6: Testing Checklist**

- [ ] Metadata records deployed successfully
- [ ] Google Drive file IDs correct (test links)
- [ ] Shareable links publicly accessible (no "Access Denied")
- [ ] Categories align with LWC component filters
- [ ] CEB_Only flag properly restricts sensitive files
- [ ] Display_Order produces logical file sorting

---

## 🔧 **Helper Script: Generate Metadata XML**

### **Python Script** (optional automation):

```python
#!/usr/bin/env python3
"""
Generate CVMA Google Drive metadata XML files from CSV input

Input CSV format:
File_Name,Google_Drive_ID,File_Type,Category,Size_MB,Description,CEB_Only,Display_Order

Example:
CVMA-National-Bylaws.pdf,1ABC123xyz,PDF,Bylaws,1.5,"National Bylaws Revision V",false,10
"""

import csv
import sys
from datetime import date

TEMPLATE = '''<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>{label}</label>
    <protected>false</protected>
    <values>
        <field>File_Name__c</field>
        <value xsi:type="xsd:string">{file_name}</value>
    </values>
    <values>
        <field>Google_Drive_ID__c</field>
        <value xsi:type="xsd:string">{drive_id}</value>
    </values>
    <values>
        <field>File_Type__c</field>
        <value xsi:type="xsd:string">{file_type}</value>
    </values>
    <values>
        <field>Category__c</field>
        <value xsi:type="xsd:string">{category}</value>
    </values>
    <values>
        <field>Public_Link__c</field>
        <value xsi:type="xsd:string">https://drive.google.com/file/d/{drive_id}/view</value>
    </values>
    <values>
        <field>Size_MB__c</field>
        <value xsi:type="xsd:double">{size_mb}</value>
    </values>
    <values>
        <field>Uploaded_Date__c</field>
        <value xsi:type="xsd:date">{upload_date}</value>
    </values>
    <values>
        <field>Description__c</field>
        <value xsi:type="xsd:string">{description}</value>
    </values>
    <values>
        <field>CEB_Only__c</field>
        <value xsi:type="xsd:boolean">{ceb_only}</value>
    </values>
    <values>
        <field>Display_Order__c</field>
        <value xsi:type="xsd:double">{display_order}</value>
    </values>
    <values>
        <field>Is_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
</CustomMetadata>
'''

def generate_metadata(csv_file):
    """Generate metadata XML files from CSV input"""
    today = date.today().isoformat()

    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Generate record name (alphanumeric only)
            record_name = row['File_Name'].replace('.', '_').replace('-', '_').replace(' ', '_')
            record_name = ''.join(c for c in record_name if c.isalnum() or c == '_')

            # Generate XML
            xml_content = TEMPLATE.format(
                label=row['File_Name'].replace('.pdf', '').replace('.docx', ''),
                file_name=row['File_Name'],
                drive_id=row['Google_Drive_ID'],
                file_type=row['File_Type'],
                category=row['Category'],
                size_mb=row['Size_MB'],
                upload_date=today,
                description=row['Description'],
                ceb_only=row['CEB_Only'].lower(),
                display_order=row['Display_Order']
            )

            # Write file
            output_file = f"src/main/default/customMetadata/CVMA_Google_Drive_File.{record_name}.md-meta.xml"
            with open(output_file, 'w') as out:
                out.write(xml_content)

            print(f"Created: {output_file}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 generate-gdrive-metadata.py files.csv")
        sys.exit(1)

    generate_metadata(sys.argv[1])
    print("\nMetadata generation complete!")
```

**Usage**:
```bash
$ python3 scripts/generate-gdrive-metadata.py data/cvma-gdrive-files.csv
```

---

## 📊 **Metadata Record Naming Convention**

**Format**: `CVMA_Google_Drive_File.[RecordName].md-meta.xml`

**Record Name Rules**:
- Alphanumeric characters only (A-Z, 0-9, underscore)
- No spaces, dots, or special characters
- Max 40 characters
- Descriptive but concise

**Examples**:
- `CVMA_Google_Drive_File.National_Bylaws_Revision_V.md-meta.xml`
- `CVMA_Google_Drive_File.Chapter_20_7_Bylaws.md-meta.xml`
- `CVMA_Google_Drive_File.Form_100_Membership_App.md-meta.xml`
- `CVMA_Google_Drive_File.Appendix_C_Discipline.md-meta.xml`

---

## 🎯 **Success Criteria**

- [ ] All priority files have metadata records created
- [ ] Google Drive IDs validated (links work)
- [ ] Categories match LWC component design
- [ ] CEB_Only restrictions properly applied
- [ ] Display_Order creates logical grouping
- [ ] Metadata deployed successfully to Salesforce
- [ ] Test query returns expected results

---

**Created**: October 22, 2025
**Epic**: #12 Google Drive MCP Integration
**User Story**: #87 Document Migration

🏍️ **CVMA Chapter 20-7 - Vets Serving Vets**
