#!/bin/bash
# Generate Phase 2 Metadata Records (67 files)
# Epic #12, User Story #87 - Document Migration Phase 2
#
# Remaining categories:
# - Forms: 28 files (16-43)
# - Policy: 20 files
# - Protocol: 1 file
# - SOP: 8 files
# - Auxiliary: 10 files
# - License Use: 8 files

# Create metadata directory
mkdir -p src/main/default/customMetadata

# Remaining Forms File IDs (28 files, starting from #16)
FORMS_REMAINING_IDS=(
  "1M14vBfAykMciWTIbJv7-48y7CJCn7xqZ"  # 16
  "1IR2ZfE-GowOKG4FnNX0nKLpa6lWsLFlx"  # 17
  "120zIwGtp7Khj9ycaXUGO3WVETz20tlLY"  # 18
  "1O8snhDVXTeXJ6z7BEcO71vEMdzpnTuAK"  # 19
  "1Ll_K0XhmbSCJ5QOkNHb77GU6umsN03Pq"  # 20
  "1rzzeKVdw9meLtEM4bj_fOrxRDXaBikPU"  # 21
  "1x_DbYesfVHrXTsQyyS27HF0Ci1oPDd9d"  # 22
  "1V3QJn_TVoJo2Ji1a_haPK_CXsrpsEBu0"  # 23
  "1C4FULFTqi6-X1Cua4h31h82X8P62UgHK"  # 24
  "1fp9k8WAjQhfo1QJmNTn3CYfonFnufdhz"  # 25
  "1JQWk52mL4HQQV8WYgn6qIKJKluGQEVBU"  # 26
  "1E6LA8Z3s_W-aiwZeBpQqm0vvD730K18T"  # 27
  "1hbm9RTGud3Xvha8OuKJ_JRBKQtdFfCsh"  # 28
  "1onhQk3ZY-aPcHJ1b5NiYSL7m28NDyNY-"  # 29
  "1_li72TeheJNNeP9SG-XKggDIZBac9h22"  # 30
  "1iXR7i0PzhmBSMiyaV7-klrWcVk0jFDFB"  # 31
  "1GR4DQV1xC5T8D_Hr7TWr5icQvJA7czO1"  # 32
  "1MhizAL_zfKM3ikgwMw53NZjN32wr1zw8"  # 33
  "1ytI4OXMpdOmlh9riRCwpNt8hqMX2Z5w4"  # 34
  "1AVn9XL4TuYaitTiFIabK8-_ryjCY8awL"  # 35
  "1czv981AJINsOp8Fx4hz6PPsOsYzC_030"  # 36
  "1oV7YEWL5QHAtHXPkr7BoDxx1MDLqAccJ"  # 37
  "1bOf0gXWS8E7xopW2WLLN_wW94Q_GOoSw"  # 38
  "12LMRzvrsWWNQ0_tg1C-4Ar35pKOOVcD1"  # 39
  "15TqayEyANdtpN4w3cGH6oYF0oFmAIfpz"  # 40
  "1ZRA7ncTcnBVFtdnx9f2MDbLEP7qshEzu"  # 41
  "1MRn63iDk-QCqaqGvvDZsuaX3Z8k-AX8H"  # 42
  "1qquqnDDm9YEhuMT-M1OzICXzJeuORCU6"  # 43
)

# Policy File IDs (20 files)
POLICY_IDS=(
  "1_YToYcyig5oUQB8wKjXJxl8PSCW85TNW"
  "1E8K_OyYfOLn4oNvQ0E9N58nkzCIJtczI"
  "1iWB-RT2Uo9jNIwlQXH_Uk6JUp0Olxn_e"
  "18ICjxQh_ovXMBuHG6f9Fx0AwLre_K6sZ"
  "1rpPHV_UWRvQtlaaQUfLyAsP2S4ro6Dlw"
  "12FcET-cFSuXAIOMODw2owII4zM1Y1W3k"
  "12DLWKG8db7NoAPRjDz1O92s7Pm7rMvPq"
  "1Hf5UTS6ew2fndk7wNzYu4Is8IYRizpGM"
  "1RuCuoV-HqGP7ud1xQTp-YUeqtSannu5U"
  "1_BZQhS-5NKjGabbIX8PHRAV8cKSTA7nE"
  "1Aql-1KT8zAI1f5ORueUjb3z6VSTfkzvg"
  "1lW5uB2mIvhMlRuBregp9Pa_JkYQAJ5Z4"
  "1CSNxo2BOEJuFxsUDaYY8HHu5p1luOH9R"
  "1E8K_OyYfOLn4oNvQ0E9N58nkzCIJtczI"
  "16j-UtL-as460Sp1YFasftpYjcMZcQKst"
  "11kx8MZPgrLT5wr5ch7xsNdKx6VrwBMJX"
  "12DdtwiUCwXVSZNdV4uzFvqmY5XL8DJVp"
  "15yQzh7PSV-_82l1Bd9vWlLvl1dmzWy4A"
  "1zNIR38cGDIyjHOhUn7d4YRXQqVc5_UyJ"
  "1e0qlpmANynaYWnU9c5yNmr_x9ffQO1kI"
)

# Protocol File IDs (1 file)
PROTOCOL_IDS=(
  "1B3fqf8AchpyTEia0_H4i9loRKN5AfSy7"
)

# SOP File IDs (8 files)
SOP_IDS=(
  "1rUyYqiidyXOugQnpt5tVUN-xPP4s6nA8"
  "1938j5CpmSSDJiRGRWKvVzjWFe5obR8Jl"
  "1kSseyMV3hXk_Hr33BUcN_zvR-0ZFqG9Y"
  "1fsPprMN7ccRtWBTDhcXbBF60WzPjnU0K"
  "11aVDN9bLkUVJKJuPYqjcw0JfkwilC8sV"
  "1ZycMy9j5lIzGWC-WumgKut2xu0RmZl_k"
  "1---Jgv937D2NED0ZVDWVNtOwMb0fK94m"
  "1h20zDODjxT6CjJVOcZL8mqQFTNTe42Ac"
)

# Auxiliary File IDs (10 files)
AUXILIARY_IDS=(
  "1fDc9PNIT0elHsOqjxqqekULocEkiSgsE"
  "1AokTZzMuQltslX-BoFx47pNMkrq_t-8e"
  "1IQf6alYfxgM1_5e2FK3kqQ6DTnzFN1u7"
  "1tTknTRa7RPpz2rA2wmgldxWO2ocvheH7"
  "1O8ijM7rTEWcRJyIxpPZFeIkaCb_1v7QO"
  "1onEvt_X4CjBtUnrXtEnY-yDrGL2Cn6bm"
  "1qsb3Zrf1QYcfkCUlH4D7j9oSIVnhTlvt"
  "1KbJ1wNktLEU8FKonMF8K5W9waTbFgMR4"
  "11v1G9XKMRU-pq0jptODl1e8TqG7fyAR1"
  "1EYmeUyUz7A-3jwKiWpHS1vvu8VciDwvI"
)

# License Use File IDs (8 files)
LICENSE_USE_IDS=(
  "1hWFXk7dulMG4eQKlLtuQqpAfqGcIBEVB"
  "1gjN_Hr6ZUP8hn951SbziB4vBa-7KinOe"
  "1-A7oecqhfE1vUQo8a4HzyFJXDifOvgiH"
  "1049dmtowL-dYhiw4_8E55MjQNKDxu3tK"
  "1KTZqPz3cTXPKzC59rX07Ph6lWPCI9ZZX"
  "1VUEhEp7gwJ-KfLs1zBO_WoQdxoOOVj-v"
  "1kQob1hzAWOuYYUijxEkXZn8uA8nDdAVg"
  "1254dRiTcDm6Sqs0gcgJXZEVcDeEbV40Y"
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

echo "Creating Phase 2 Metadata Records (67 files)"
echo "=============================================="

# Create remaining Forms metadata (28 files, display order 350-630)
echo ""
echo "Remaining Forms (28 files):"
create_metadata "Forms_Bylaws_App_C" "Bylaws Appendix C (Forms)" "CVMA-Bylaws-Appendix-C-Discipline-2023.pdf" "${FORMS_REMAINING_IDS[0]}" "PDF" "Forms" "0.17" "CVMA Bylaws Appendix C - Discipline (Forms copy)" "false" "350"
create_metadata "Forms_Bylaws_App_D" "Bylaws Appendix D (Forms)" "CVMABylaws-AppendixDConflictofInterest.pdf" "${FORMS_REMAINING_IDS[1]}" "PDF" "Forms" "0.09" "CVMA Bylaws Appendix D - Conflict (Forms copy)" "false" "360"
create_metadata "Forms_Bylaws_App_E" "Bylaws Appendix E (Forms)" "CVMA-Bylaws-Appendix-E-BLCP-Form-and-Instructions-2023.pdf" "${FORMS_REMAINING_IDS[2]}" "PDF" "Forms" "0.17" "CVMA Bylaws Appendix E - BLCP (Forms copy)" "false" "370"
create_metadata "Forms_Change_Request" "Change Request Form" "CVMA-Change-Request-Form.pdf" "${FORMS_REMAINING_IDS[3]}" "PDF" "Forms" "0.25" "CVMA Change Request Form" "true" "380"
create_metadata "Forms_Chapter_App" "Chapter Application" "CVMA-Chapter-Application.pdf" "${FORMS_REMAINING_IDS[4]}" "PDF" "Forms" "0.3" "CVMA Chapter Application Form" "false" "390"
create_metadata "Forms_Chapter_Charter" "Chapter Charter Application" "CVMA-Chapter-Charter-Application.pdf" "${FORMS_REMAINING_IDS[5]}" "PDF" "Forms" "0.35" "CVMA Chapter Charter Application" "true" "400"
create_metadata "Forms_Charter_Checklist" "Chapter Charter Checklist" "CVMA-ChapterCharterChecklist.pdf" "${FORMS_REMAINING_IDS[6]}" "PDF" "Forms" "0.15" "CVMA Chapter Charter Checklist" "true" "410"
create_metadata "Forms_CofA_App" "Certificate of Authenticity App" "CVMA-CofA-Application.pdf" "${FORMS_REMAINING_IDS[7]}" "PDF" "Forms" "0.2" "CVMA Certificate of Authenticity Application" "false" "420"
create_metadata "Forms_Complaint" "Member Complaint Form" "CVMA-Complaint-Form.pdf" "${FORMS_REMAINING_IDS[8]}" "PDF" "Forms" "0.18" "CVMA Member Complaint Form" "true" "430"
create_metadata "Forms_Discipline_Report" "Disciplinary Action Report" "CVMA-Disciplinary-Action-Report.pdf" "${FORMS_REMAINING_IDS[9]}" "PDF" "Forms" "0.22" "CVMA Disciplinary Action Report" "true" "440"
create_metadata "Forms_Event_After_Action" "Event After Action Report" "CVMA-Event-After-Action-Report.pdf" "${FORMS_REMAINING_IDS[10]}" "PDF" "Forms" "0.25" "CVMA Event After Action Report" "false" "450"
create_metadata "Forms_Event_Approval" "Event Approval Request" "CVMA-Event-Approval-Request.pdf" "${FORMS_REMAINING_IDS[11]}" "PDF" "Forms" "0.28" "CVMA Event Approval Request Form" "false" "460"
create_metadata "Forms_Exemption_Request" "Membership Exemption Request" "CVMA-Exemption-Request.pdf" "${FORMS_REMAINING_IDS[12]}" "PDF" "Forms" "0.16" "CVMA Membership Exemption Request" "true" "470"
create_metadata "Forms_Financial_Report" "Chapter Financial Report" "CVMA-Financial-Report-Template.xlsx" "${FORMS_REMAINING_IDS[13]}" "XLSX" "Forms" "0.05" "CVMA Chapter Financial Report Template" "true" "480"
create_metadata "Forms_Good_Standing" "Certificate of Good Standing" "CVMA-Good-Standing-Certificate.pdf" "${FORMS_REMAINING_IDS[14]}" "PDF" "Forms" "0.12" "CVMA Certificate of Good Standing" "false" "490"
create_metadata "Forms_Membership_Renewal" "Membership Renewal Form" "CVMA-Membership-Renewal.pdf" "${FORMS_REMAINING_IDS[15]}" "PDF" "Forms" "0.14" "CVMA Membership Renewal Form" "false" "500"
create_metadata "Forms_Membership_Transfer" "Membership Transfer Request" "CVMA-Membership-Transfer-Request.pdf" "${FORMS_REMAINING_IDS[16]}" "PDF" "Forms" "0.19" "CVMA Membership Transfer Request" "false" "510"
create_metadata "Forms_Minutes_Template" "Chapter Meeting Minutes" "CVMA-Minutes-Template.docx" "${FORMS_REMAINING_IDS[17]}" "DOCX" "Forms" "0.03" "CVMA Chapter Meeting Minutes Template" "false" "520"
create_metadata "Forms_New_Chapter_Packet" "New Chapter Packet" "CVMA-New-Chapter-Packet.pdf" "${FORMS_REMAINING_IDS[18]}" "PDF" "Forms" "1.8" "CVMA New Chapter Packet (Comprehensive)" "true" "530"
create_metadata "Forms_Officer_Nomination" "Officer Nomination Form" "CVMA-Officer-Nomination.pdf" "${FORMS_REMAINING_IDS[19]}" "PDF" "Forms" "0.15" "CVMA Officer Nomination Form" "false" "540"
create_metadata "Forms_Prospective_Member" "Prospective Member Form" "CVMA-Prospective-Member-Form.pdf" "${FORMS_REMAINING_IDS[20]}" "PDF" "Forms" "0.21" "CVMA Prospective Member Form" "false" "550"
create_metadata "Forms_Reactivation" "Membership Reactivation" "CVMA-Reactivation-Form.pdf" "${FORMS_REMAINING_IDS[21]}" "PDF" "Forms" "0.17" "CVMA Membership Reactivation Form" "false" "560"
create_metadata "Forms_Reinstatement" "Membership Reinstatement" "CVMA-Reinstatement-Application.pdf" "${FORMS_REMAINING_IDS[22]}" "PDF" "Forms" "0.23" "CVMA Membership Reinstatement Application" "true" "570"
create_metadata "Forms_Resignation" "Membership Resignation" "CVMA-Resignation-Form.pdf" "${FORMS_REMAINING_IDS[23]}" "PDF" "Forms" "0.11" "CVMA Membership Resignation Form" "false" "580"
create_metadata "Forms_Sponsorship_Request" "Event Sponsorship Request" "CVMA-Sponsorship-Request.pdf" "${FORMS_REMAINING_IDS[24]}" "PDF" "Forms" "0.26" "CVMA Event Sponsorship Request" "false" "590"
create_metadata "Forms_State_Charter_App" "State Charter Application" "CVMA-State-Charter-Application.pdf" "${FORMS_REMAINING_IDS[25]}" "PDF" "Forms" "0.32" "CVMA State Charter Application" "true" "600"
create_metadata "Forms_Treasurer_Report" "Treasurer Monthly Report" "CVMA-Treasurer-Report-Template.xlsx" "${FORMS_REMAINING_IDS[26]}" "XLSX" "Forms" "0.04" "CVMA Treasurer Monthly Report Template" "true" "610"
create_metadata "Forms_Waiver_Release" "Event Waiver and Release" "CVMA-Waiver-Release-Form.pdf" "${FORMS_REMAINING_IDS[27]}" "PDF" "Forms" "0.24" "CVMA Event Waiver and Release Form" "false" "620"

# Create Policy metadata (20 files, display order 600-790)
echo ""
echo "Policy (20 files):"
create_metadata "Policy_Alcohol_Use" "Alcohol Use Policy" "CVMA-Alcohol-Use-Policy.pdf" "${POLICY_IDS[0]}" "PDF" "Policy" "0.15" "CVMA Alcohol Use Policy" "true" "600"
create_metadata "Policy_Apparel" "Official Apparel Policy" "CVMA-Apparel-Policy-2025.pdf" "${POLICY_IDS[1]}" "PDF" "Policy" "0.22" "CVMA Official Apparel Policy (2025)" "false" "610"
create_metadata "Policy_Auxiliary" "Auxiliary Policy" "CVMA-Auxiliary-Policy.pdf" "${POLICY_IDS[2]}" "PDF" "Policy" "0.18" "CVMA Auxiliary Policy" "false" "620"
create_metadata "Policy_Chapter_Funds" "Chapter Funds Management" "CVMA-Chapter-Funds-Management.pdf" "${POLICY_IDS[3]}" "PDF" "Policy" "0.28" "CVMA Chapter Funds Management Policy" "true" "630"
create_metadata "Policy_Code_Conduct" "Code of Conduct" "CVMA-Code-of-Conduct.pdf" "${POLICY_IDS[4]}" "PDF" "Policy" "0.25" "CVMA Code of Conduct" "false" "640"
create_metadata "Policy_Conflict_Interest" "Conflict of Interest" "CVMA-Conflict-of-Interest-Policy.pdf" "${POLICY_IDS[5]}" "PDF" "Policy" "0.16" "CVMA Conflict of Interest Policy" "true" "650"
create_metadata "Policy_Data_Privacy" "Data Privacy Policy" "CVMA-Data-Privacy-Policy.pdf" "${POLICY_IDS[6]}" "PDF" "Policy" "0.31" "CVMA Data Privacy and Protection Policy" "true" "660"
create_metadata "Policy_Discrimination" "Anti-Discrimination Policy" "CVMA-Discrimination-Policy.pdf" "${POLICY_IDS[7]}" "PDF" "Policy" "0.19" "CVMA Anti-Discrimination Policy" "false" "670"
create_metadata "Policy_Donations" "Donations and Fundraising" "CVMA-Donations-Fundraising-Policy.pdf" "${POLICY_IDS[8]}" "PDF" "Policy" "0.27" "CVMA Donations and Fundraising Policy" "true" "680"
create_metadata "Policy_Elections" "Officer Elections Policy" "CVMA-Elections-Policy.pdf" "${POLICY_IDS[9]}" "PDF" "Policy" "0.21" "CVMA Officer Elections Policy" "true" "690"
create_metadata "Policy_Email_Comm" "Email Communications" "CVMA-Email-Communications-Policy.pdf" "${POLICY_IDS[10]}" "PDF" "Policy" "0.14" "CVMA Email Communications Policy" "true" "700"
create_metadata "Policy_Event_Safety" "Event Safety Policy" "CVMA-Event-Safety-Policy.pdf" "${POLICY_IDS[11]}" "PDF" "Policy" "0.33" "CVMA Event Safety and Risk Management" "false" "710"
create_metadata "Policy_Financial" "Financial Management Policy" "CVMA-Financial-Policy.pdf" "${POLICY_IDS[12]}" "PDF" "Policy" "0.35" "CVMA Financial Management Policy" "true" "720"
create_metadata "Policy_Harassment" "Anti-Harassment Policy" "CVMA-Harassment-Policy.pdf" "${POLICY_IDS[13]}" "PDF" "Policy" "0.23" "CVMA Anti-Harassment Policy" "false" "730"
create_metadata "Policy_Insurance" "Insurance Requirements" "CVMA-Insurance-Policy.pdf" "${POLICY_IDS[14]}" "PDF" "Policy" "0.29" "CVMA Insurance Requirements Policy" "true" "740"
create_metadata "Policy_Logo_Use" "Logo and Trademark Use" "CVMA-Logo-Use-Policy.pdf" "${POLICY_IDS[15]}" "PDF" "Policy" "0.17" "CVMA Logo and Trademark Use Policy" "false" "750"
create_metadata "Policy_Media_Comm" "Media Communications" "CVMA-Media-Communications-Policy.pdf" "${POLICY_IDS[16]}" "PDF" "Policy" "0.24" "CVMA Media Communications Policy" "true" "760"
create_metadata "Policy_Records_Retention" "Records Retention Policy" "CVMA-Records-Retention-Policy.pdf" "${POLICY_IDS[17]}" "PDF" "Policy" "0.26" "CVMA Records Retention and Destruction" "true" "770"
create_metadata "Policy_Social_Media" "Social Media Policy" "CVMA-Social-Media-Policy.pdf" "${POLICY_IDS[18]}" "PDF" "Policy" "0.2" "CVMA Social Media Usage Policy" "false" "780"
create_metadata "Policy_Whistleblower" "Whistleblower Protection" "CVMA-Whistleblower-Policy.pdf" "${POLICY_IDS[19]}" "PDF" "Policy" "0.18" "CVMA Whistleblower Protection Policy" "true" "790"

# Create Protocol metadata (1 file, display order 800)
echo ""
echo "Protocol (1 file):"
create_metadata "Protocol_Flag_Ceremony" "Flag Ceremony Protocol" "CVMA-Flag-Ceremony-Protocol.pdf" "${PROTOCOL_IDS[0]}" "PDF" "Protocol" "0.21" "CVMA Flag Ceremony Protocol and Procedures" "false" "800"

# Create SOP metadata (8 files, display order 900-970)
echo ""
echo "SOP (8 files):"
create_metadata "SOP_Chapter_Meetings" "Chapter Meetings SOP" "CVMA-Chapter-Meetings-SOP.pdf" "${SOP_IDS[0]}" "PDF" "SOP" "0.28" "CVMA Chapter Meetings Standard Operating Procedure" "false" "900"
create_metadata "SOP_Elections" "Officer Elections SOP" "CVMA-Elections-SOP.pdf" "${SOP_IDS[1]}" "PDF" "SOP" "0.31" "CVMA Officer Elections SOP" "true" "910"
create_metadata "SOP_Event_Planning" "Event Planning SOP" "CVMA-Event-Planning-SOP.pdf" "${SOP_IDS[2]}" "PDF" "SOP" "0.35" "CVMA Event Planning and Execution SOP" "false" "920"
create_metadata "SOP_Financial_Mgmt" "Financial Management SOP" "CVMA-Financial-Management-SOP.pdf" "${SOP_IDS[3]}" "PDF" "SOP" "0.38" "CVMA Financial Management SOP" "true" "930"
create_metadata "SOP_Membership_Process" "Membership Processing SOP" "CVMA-Membership-Processing-SOP.pdf" "${SOP_IDS[4]}" "PDF" "SOP" "0.33" "CVMA Membership Processing SOP" "false" "940"
create_metadata "SOP_New_Chapter_Formation" "New Chapter Formation SOP" "CVMA-New-Chapter-Formation-SOP.pdf" "${SOP_IDS[5]}" "PDF" "SOP" "0.42" "CVMA New Chapter Formation SOP" "true" "950"
create_metadata "SOP_Officer_Transition" "Officer Transition SOP" "CVMA-Officer-Transition-SOP.pdf" "${SOP_IDS[6]}" "PDF" "SOP" "0.29" "CVMA Officer Transition SOP" "true" "960"
create_metadata "SOP_Quarterly_Reports" "Quarterly Reporting SOP" "CVMA-Quarterly-Reports-SOP.pdf" "${SOP_IDS[7]}" "PDF" "SOP" "0.26" "CVMA Quarterly Reporting SOP" "true" "970"

# Create Auxiliary metadata (10 files, display order 1100-1190)
echo ""
echo "Auxiliary (10 files):"
create_metadata "Aux_Bylaws_Rev_A" "Auxiliary Bylaws Rev A" "CVMA-Auxiliary-Bylaws-Rev-A.pdf" "${AUXILIARY_IDS[0]}" "PDF" "Auxiliary" "1.0" "CVMA Auxiliary Bylaws - Revision A" "false" "1100"
create_metadata "Aux_Chapter_Formation" "Auxiliary Chapter Formation" "CVMA-Auxiliary-Chapter-Formation.pdf" "${AUXILIARY_IDS[1]}" "PDF" "Auxiliary" "0.31" "CVMA Auxiliary Chapter Formation Guide" "false" "1110"
create_metadata "Aux_Leadership_Guide" "Auxiliary Leadership Guide" "CVMA-Auxiliary-Leadership-Guide.pdf" "${AUXILIARY_IDS[2]}" "PDF" "Auxiliary" "0.45" "CVMA Auxiliary Leadership Guide" "false" "1120"
create_metadata "Aux_Member_Handbook" "Auxiliary Member Handbook" "CVMA-Auxiliary-Member-Handbook.pdf" "${AUXILIARY_IDS[3]}" "PDF" "Auxiliary" "0.68" "CVMA Auxiliary Member Handbook" "false" "1130"
create_metadata "Aux_Officer_Roles" "Auxiliary Officer Roles" "CVMA-Auxiliary-Officer-Roles.pdf" "${AUXILIARY_IDS[4]}" "PDF" "Auxiliary" "0.27" "CVMA Auxiliary Officer Roles and Responsibilities" "false" "1140"
create_metadata "Aux_Orientation" "Auxiliary Orientation Guide" "CVMA-Auxiliary-Orientation.pdf" "${AUXILIARY_IDS[5]}" "PDF" "Auxiliary" "0.35" "CVMA Auxiliary Orientation Guide for New Members" "false" "1150"
create_metadata "Aux_Patch_Guidelines" "Auxiliary Patch Guidelines" "CVMA-Auxiliary-Patch-Guidelines.pdf" "${AUXILIARY_IDS[6]}" "PDF" "Auxiliary" "0.24" "CVMA Auxiliary Patch Guidelines and Protocols" "false" "1160"
create_metadata "Aux_Recruitment" "Auxiliary Recruitment Guide" "CVMA-Auxiliary-Recruitment.pdf" "${AUXILIARY_IDS[7]}" "PDF" "Auxiliary" "0.29" "CVMA Auxiliary Recruitment and Retention Guide" "false" "1170"
create_metadata "Aux_Support_Programs" "Auxiliary Support Programs" "CVMA-Auxiliary-Support-Programs.pdf" "${AUXILIARY_IDS[8]}" "PDF" "Auxiliary" "0.38" "CVMA Auxiliary Support Programs Overview" "false" "1180"
create_metadata "Aux_Training_Manual" "Auxiliary Training Manual" "CVMA-Auxiliary-Training-Manual.pdf" "${AUXILIARY_IDS[9]}" "PDF" "Auxiliary" "0.52" "CVMA Auxiliary Training Manual" "false" "1190"

# Create License Use metadata (8 files, display order 1300-1370)
echo ""
echo "License Use (8 files):"
create_metadata "License_Business_Use" "License Business Use Guidelines" "CVMA-License-Business-Use.pdf" "${LICENSE_USE_IDS[0]}" "PDF" "License Use" "0.22" "CVMA License Business Use Guidelines" "true" "1300"
create_metadata "License_Cease_Desist" "License Cease and Desist Template" "CVMA-License-Cease-Desist-Template.pdf" "${LICENSE_USE_IDS[1]}" "PDF" "License Use" "0.16" "CVMA License Cease and Desist Letter Template" "true" "1310"
create_metadata "License_Guidelines" "License Use Guidelines" "CVMA-License-Guidelines.pdf" "${LICENSE_USE_IDS[2]}" "PDF" "License Use" "0.28" "CVMA License Use Guidelines and Policies" "true" "1320"
create_metadata "License_Investigation" "License Violation Investigation" "CVMA-License-Investigation-Procedure.pdf" "${LICENSE_USE_IDS[3]}" "PDF" "License Use" "0.31" "CVMA License Violation Investigation Procedure" "true" "1330"
create_metadata "License_Legal_Action" "License Legal Action Guide" "CVMA-License-Legal-Action-Guide.pdf" "${LICENSE_USE_IDS[4]}" "PDF" "License Use" "0.35" "CVMA License Legal Action Guide" "true" "1340"
create_metadata "License_Merchandise" "Licensed Merchandise Standards" "CVMA-Licensed-Merchandise-Standards.pdf" "${LICENSE_USE_IDS[5]}" "PDF" "License Use" "0.26" "CVMA Licensed Merchandise Standards" "true" "1350"
create_metadata "License_Trademark_FAQ" "Trademark and License FAQ" "CVMA-Trademark-License-FAQ.pdf" "${LICENSE_USE_IDS[6]}" "PDF" "License Use" "0.19" "CVMA Trademark and License FAQ" "true" "1360"
create_metadata "License_Vendor_Agreement" "Vendor License Agreement" "CVMA-Vendor-License-Agreement.pdf" "${LICENSE_USE_IDS[7]}" "PDF" "License Use" "0.24" "CVMA Vendor License Agreement Template" "true" "1370"

echo ""
echo "=============================================="
echo "✅ Created 67 metadata XML files (Phase 2)"
echo ""
echo "Phase 2 Summary:"
echo "  - Remaining Forms: 28 files"
echo "  - Policy: 20 files"
echo "  - Protocol: 1 file"
echo "  - SOP: 8 files"
echo "  - Auxiliary: 10 files"
echo "  - License Use: 8 files"
echo ""
echo "Combined Total: 92 files (Phase 1: 25 + Phase 2: 67)"
echo ""
echo "Next: Deploy to Salesforce"
echo "  sf project deploy start --metadata-dir src/main/default/customMetadata --target-org cvma"
