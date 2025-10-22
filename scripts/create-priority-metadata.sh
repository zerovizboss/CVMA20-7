#!/bin/bash
# Generate Phase 1 Priority Metadata Records
# Epic #12, User Story #87 - 25 files (10 Bylaws + 15 Forms)

# Create metadata directory
mkdir -p src/main/default/customMetadata

# Bylaws File IDs (alphabetical order)
BYLAWS_IDS=(
  "1d1hqjeys8Vy2pHe9qcESTEuuH2WhzJzi"  # Appendix-A.pdf
  "1235ByskFK3eRFwvNoYzjFbAfIv9oik4S"  # ChapterBylawTemplate-8-2-2024.docx
  "1Qc88GlfInYqCkMA-0_jtl5XW99qKqTad"  # CVMA-Bylaws-Appendix-B-Regional-Rotation-2024.pdf
  "1CFCz4PNsfVehMmXiloo4wcVOyTGYZ8Py"  # CVMA-Bylaws-Appendix-C-Discipline-2023.pdf
  "1bnEX7Q72G77BI0b3lYEJRsGrCMFYCC0p"  # CVMABylaws-AppendixDConflictofInterest.pdf
  "12Dmof8zfBbfxrXIVA1Et2u0U6xwSjU05"  # CVMA-Bylaws-Appendix-E-BLCP-Form-and-Instructions-2023.pdf
  "1Y-Sy8HG4n8GghN_6jy8q-BEewt7WoFUn"  # CVMA-National-Bylaws---Change-Revision-Summary--10August2025-.pdf
  "1hYPxJRfcWe2tOCYbhPgR-y7vynGZqqjI"  # CVMA-National-Bylaws---Revision-V---Signed.pdf
  "1F5P-BAzdqRs8L7eplVx8hBuYR4py9jDi"  # FL-20-7-Bylaws-221227.pdf
  "14Rf9ARoD4Ky-aRZIMIrsSfBHknZia4cz"  # STATEBYLAWSDraftTemplate-8-5-2024.docx (10th file)
)

# Forms File IDs (first 15 alphabetically)
FORMS_IDS=(
  "1lGlXSQWDSmkR-5no-8eH2-Rfg6N-_RJh"  # 2024-LRRP-Packet
  "1HKPfqLDjISFhYGRq0iWoFS1zLSoB3Jv9"  # Appendix-A
  "1MtE1wmrYdboFbK3v3LWoz1hdadICvF6M"  # Application-Forms-Checklists
  "1aaQuYvpCC1Ga8pfVswaAsulX6OsoUD7f"  # Army AIE PS_Form
  "1Qw6AvAlrTOK-qxoPhN1pUNx7ZACmZSeC"  # AUXChapterSOP
  "1wNucwkiLLQ7mSgnF-LLwt2XbTNfC0o4S"  # Auxiliary-Bylaws
  "1Ul26pJqXolWEuSThEvjc7IXJJJucfqqR"  # AuxiliaryChapterLiaisonSOP
  "1LiRx15icXvv8GtDbroxpQOc75ANucaV6"  # Auxiliary-Chapter-Policy
  "1Z3iDArUGGbWSip86H-BmVMtmgArPvwox"  # Auxiliary-Summary
  "1pI_g8dA4y4r2akmj9jOhXOdE8IdBf5WK"  # Blank-CVMAForm308
  "16PcjDqmFdZ4mZagAuaONfni-Gqi7lIWL"  # ChapterBylawTemplate
  "1-dxq1C8A_yCzlBih7tqmRWuSIlQJzTwG"  # CVMA-2024-App-form
  "1QPez_4an9jdK7dj2p7_OnF2NmIcxuC7d"  # CVMAActiveStandingRules
  "1ylrv95y48VEuHIUnlvNNPCSTBDApL3hT"  # CVMAAuxiliaryPolicy
  "1lEq78AvGIhx8uLmx7h6G06NTjiALTtQu"  # CVMA-Bylaws-Appendix-B
)

# Function to create metadata XML
create_metadata() {
  local record_name=$1
  local label=$2
  local filename=$3
  local drive_id=$4
  local file_type=$5
  local category=$6
  local size_mb=$7
  local description=$8
  local ceb_only=$9
  local display_order=${10}

  cat > "src/main/default/customMetadata/CVMA_Google_Drive_File.${record_name}.md-meta.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>${label}</label>
    <protected>false</protected>
    <values>
        <field>File_Name__c</field>
        <value xsi:type="xsd:string">${filename}</value>
    </values>
    <values>
        <field>Google_Drive_ID__c</field>
        <value xsi:type="xsd:string">${drive_id}</value>
    </values>
    <values>
        <field>File_Type__c</field>
        <value xsi:type="xsd:string">${file_type}</value>
    </values>
    <values>
        <field>Category__c</field>
        <value xsi:type="xsd:string">${category}</value>
    </values>
    <values>
        <field>Public_Link__c</field>
        <value xsi:type="xsd:string">https://drive.google.com/file/d/${drive_id}/view</value>
    </values>
    <values>
        <field>Size_MB__c</field>
        <value xsi:type="xsd:double">${size_mb}</value>
    </values>
    <values>
        <field>Uploaded_Date__c</field>
        <value xsi:type="xsd:date">2025-10-22</value>
    </values>
    <values>
        <field>Description__c</field>
        <value xsi:type="xsd:string">${description}</value>
    </values>
    <values>
        <field>CEB_Only__c</field>
        <value xsi:type="xsd:boolean">${ceb_only}</value>
    </values>
    <values>
        <field>Display_Order__c</field>
        <value xsi:type="xsd:double">${display_order}</value>
    </values>
    <values>
        <field>Is_Active__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
</CustomMetadata>
EOF

  echo "Created: CVMA_Google_Drive_File.${record_name}.md-meta.xml"
}

echo "Creating Phase 1 Priority Metadata Records (25 files)"
echo "=============================================="

# Create Bylaws metadata (10 files)
echo ""
echo "Bylaws (10 files):"
create_metadata "Bylaws_Appendix_A" "Appendix A" "Appendix-A.pdf" "${BYLAWS_IDS[0]}" "PDF" "Bylaws" "0.31" "CVMA Bylaws Appendix A" "false" "30"
create_metadata "Bylaws_Chapter_Template" "Chapter Bylaws Template" "ChapterBylawTemplate-8-2-2024.docx" "${BYLAWS_IDS[1]}" "DOCX" "Bylaws" "0.08" "CVMA Chapter Bylaws Template (August 2024)" "true" "90"
create_metadata "Bylaws_Appendix_B" "Appendix B Regional Rotation" "CVMA-Bylaws-Appendix-B-Regional-Rotation-2024.pdf" "${BYLAWS_IDS[2]}" "PDF" "Bylaws" "0.08" "CVMA Bylaws Appendix B - Regional Rotation 2024" "false" "40"
create_metadata "Bylaws_Appendix_C" "Appendix C Discipline" "CVMA-Bylaws-Appendix-C-Discipline-2023.pdf" "${BYLAWS_IDS[3]}" "PDF" "Bylaws" "0.17" "CVMA Bylaws Appendix C - Disciplinary Procedures 2023" "false" "50"
create_metadata "Bylaws_Appendix_D" "Appendix D Conflict of Interest" "CVMABylaws-AppendixDConflictofInterest.pdf" "${BYLAWS_IDS[4]}" "PDF" "Bylaws" "0.09" "CVMA Bylaws Appendix D - Conflict of Interest" "false" "60"
create_metadata "Bylaws_Appendix_E" "Appendix E BLCP" "CVMA-Bylaws-Appendix-E-BLCP-Form-and-Instructions-2023.pdf" "${BYLAWS_IDS[5]}" "PDF" "Bylaws" "0.17" "CVMA Bylaws Appendix E - BLCP Form and Instructions" "false" "70"
create_metadata "Bylaws_Revision_Summary" "National Bylaws Change Summary" "CVMA-National-Bylaws---Change-Revision-Summary--10August2025-.pdf" "${BYLAWS_IDS[6]}" "PDF" "Bylaws" "0.12" "CVMA National Bylaws Change Revision Summary (August 2025)" "false" "80"
create_metadata "Bylaws_National_Rev_V" "National Bylaws Revision V" "CVMA-National-Bylaws---Revision-V---Signed.pdf" "${BYLAWS_IDS[7]}" "PDF" "Bylaws" "1.5" "CVMA National Bylaws - Revision V (Signed, August 2025)" "false" "10"
create_metadata "Bylaws_FL_20_7" "FL Chapter 20-7 Bylaws" "FL-20-7-Bylaws-221227.pdf" "${BYLAWS_IDS[8]}" "PDF" "Bylaws" "0.21" "Florida Chapter 20-7 Bylaws (December 2022)" "false" "20"
create_metadata "Bylaws_State_Template" "State Bylaws Template" "STATEBYLAWSDraftTemplate-8-5-2024.docx" "${BYLAWS_IDS[9]}" "DOCX" "Bylaws" "0.07" "CVMA State Bylaws Draft Template (August 2024)" "true" "100"

# Create Forms metadata (15 files)
echo ""
echo "Forms (15 files):"
create_metadata "Forms_LRRP_Packet" "2024 LRRP Packet" "2024-LRRP-Packet-uploaded-01-15-2025.pdf" "${FORMS_IDS[0]}" "PDF" "Forms" "2.0" "CVMA 2024 LRRP Packet (January 2025)" "false" "200"
create_metadata "Forms_Appendix_A_Copy" "Appendix A (Forms)" "Appendix-A.pdf" "${FORMS_IDS[1]}" "PDF" "Forms" "0.31" "CVMA Bylaws Appendix A (Forms copy)" "false" "210"
create_metadata "Forms_App_Checklist" "Application Forms Checklists" "Application-Forms-Checklists-7-22-2024.pdf" "${FORMS_IDS[2]}" "PDF" "Forms" "0.19" "CVMA Application Forms Checklists (July 2024)" "false" "220"
create_metadata "Forms_Army_AIE" "Army AIE Form" "Army AIE PS_Form_190-6_G_11_JUN_25.pdf" "${FORMS_IDS[3]}" "PDF" "Forms" "0.35" "Army AIE PS Form 190-6 (June 2025)" "false" "230"
create_metadata "Forms_AUX_SOP" "Auxiliary Chapter SOP" "AUXChapterSOP.pdf" "${FORMS_IDS[4]}" "PDF" "Forms" "0.15" "CVMA Auxiliary Chapter SOP" "false" "240"
create_metadata "Forms_Aux_Bylaws" "Auxiliary Bylaws Revision A" "Auxiliary-Bylaws-REVISION-A-.pdf" "${FORMS_IDS[5]}" "PDF" "Forms" "1.0" "CVMA Auxiliary Bylaws - Revision A" "false" "250"
create_metadata "Forms_Aux_Liaison" "Auxiliary Liaison SOP" "AuxiliaryChapterLiaisonSOPREVA.pdf" "${FORMS_IDS[6]}" "PDF" "Forms" "0.19" "CVMA Auxiliary Chapter Liaison SOP Revision A" "false" "260"
create_metadata "Forms_Aux_Policy" "Auxiliary Chapter Policy" "Auxiliary-Chapter-Policy-REV-A-Approved.pdf" "${FORMS_IDS[7]}" "PDF" "Forms" "0.12" "CVMA Auxiliary Chapter Policy Revision A (Approved)" "false" "270"
create_metadata "Forms_Aux_Summary" "Auxiliary Bylaw Revisions" "Auxiliary-Summary-of-Bylaw-Revisions.pdf" "${FORMS_IDS[8]}" "PDF" "Forms" "0.13" "CVMA Auxiliary Summary of Bylaw Revisions" "false" "280"
create_metadata "Forms_308_Blank" "Form 308 License Violation" "Blank-CVMAForm308-LICENSE-USE-VIOLATION-REPORT.pdf" "${FORMS_IDS[9]}" "PDF" "Forms" "1.5" "CVMA Form 308 - License Use Violation Report (Blank)" "true" "290"
create_metadata "Forms_Chapter_Bylaws" "Chapter Bylaws Template (Forms)" "ChapterBylawTemplate-8-2-2024.docx" "${FORMS_IDS[10]}" "DOCX" "Forms" "0.08" "CVMA Chapter Bylaws Template August 2024 (Forms copy)" "true" "300"
create_metadata "Forms_2024_App" "2024 Application Form" "CVMA-2024-App-form.pdf" "${FORMS_IDS[11]}" "PDF" "Forms" "0.6" "CVMA 2024 Application Form" "false" "310"
create_metadata "Forms_Standing_Rules" "Active Standing Rules" "CVMAActiveStandingRules-19JAN2021.pdf" "${FORMS_IDS[12]}" "PDF" "Forms" "0.13" "CVMA Active Standing Rules (January 2021)" "true" "320"
create_metadata "Forms_Aux_Apparel" "Auxiliary Apparel Policy" "CVMAAuxiliaryPolicy-Apparel-1-20-2025.pdf" "${FORMS_IDS[13]}" "PDF" "Forms" "0.12" "CVMA Auxiliary Policy - Apparel (January 2025)" "false" "330"
create_metadata "Forms_Bylaws_AppB" "Bylaws Appendix B (Forms)" "CVMA-Bylaws-Appendix-B-Regional-Rotation-2024.pdf" "${FORMS_IDS[14]}" "PDF" "Forms" "0.08" "CVMA Bylaws Appendix B Regional Rotation (Forms copy)" "false" "340"

echo ""
echo "=============================================="
echo "✅ Created 25 metadata XML files"
echo ""
echo "Next: Deploy to Salesforce"
echo "  sf project deploy start --metadata-dir src/main/default/customMetadata --target-org cvma"
