#!/usr/bin/env python3
"""
Generate CVMA Google Drive metadata XML files from file ID mappings
Epic #12, User Story #87 - Document Migration
"""

import os
from datetime import date

# XML Template
TEMPLATE = """<?xml version="1.0" encoding="UTF-8"?>
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
"""

# Bylaws files (alphabetical order from Google Drive)
bylaws_files = [
    (
        "Appendix-A.pdf",
        "1d1hqjeys8Vy2pHe9qcESTEuuH2WhzJzi",
        0.31,
        "CVMA Bylaws Appendix A",
        False,
        30,
    ),
    (
        "ChapterBylawTemplate-8-2-2024.docx",
        "1235ByskFK3eRFwvNoYzjFbAfIv9oik4S",
        0.08,
        "CVMA Chapter Bylaws Template (August 2024)",
        True,
        90,
    ),
    (
        "CVMA-Bylaws-Appendix-B-Regional-Rotation-2024.pdf",
        "1Qc88GlfInYqCkMA-0_jtl5XW99qKqTad",
        0.08,
        "CVMA Bylaws Appendix B - Regional Rotation 2024",
        False,
        40,
    ),
    (
        "CVMA-Bylaws-Appendix-C-Discipline-2023.pdf",
        "1CFCz4PNsfVehMmXiloo4wcVOyTGYZ8Py",
        0.17,
        "CVMA Bylaws Appendix C - Disciplinary Procedures 2023",
        False,
        50,
    ),
    (
        "CVMABylaws-AppendixDConflictofInterest.pdf",
        "1bnEX7Q72G77BI0b3lYEJRsGrCMFYCC0p",
        0.09,
        "CVMA Bylaws Appendix D - Conflict of Interest",
        False,
        60,
    ),
    (
        "CVMA-Bylaws-Appendix-E-BLCP-Form-and-Instructions-2023.pdf",
        "12Dmof8zfBbfxrXIVA1Et2u0U6xwSjU05",
        0.17,
        "CVMA Bylaws Appendix E - BLCP Form and Instructions",
        False,
        70,
    ),
    (
        "CVMA-National-Bylaws---Change-Revision-Summary--10August2025-.pdf",
        "1Y-Sy8HG4n8GghN_6jy8q-BEewt7WoFUn",
        0.12,
        "CVMA National Bylaws Change Revision Summary (August 2025)",
        False,
        80,
    ),
    (
        "CVMA-National-Bylaws---Revision-V---Signed.pdf",
        "1hYPxJRfcWe2tOCYbhPgR-y7vynGZqqjI",
        1.5,
        "CVMA National Bylaws - Revision V (Signed, August 2025)",
        False,
        10,
    ),
    (
        "FL-20-7-Bylaws-221227.pdf",
        "1F5P-BAzdqRs8L7eplVx8hBuYR4py9jDi",
        0.21,
        "Florida Chapter 20-7 Bylaws (December 2022)",
        False,
        20,
    ),
    (
        "STATEBYLAWSDraftTemplate-8-5-2024.docx",
        "14Rf9ARoD4Ky-aRZIMIrsSfBHknZia4cz",
        0.07,
        "CVMA State Bylaws Draft Template (August 2024)",
        True,
        100,
    ),
]


def get_file_type(filename):
    """Extract file type from filename"""
    ext = filename.split(".")[-1].upper()
    return ext


def generate_record_name(filename):
    """Generate alphanumeric record name from filename"""
    # Remove extension
    name = filename.rsplit(".", 1)[0]
    # Replace special characters with underscores
    name = name.replace("-", "_").replace(" ", "_").replace("(", "").replace(")", "")
    # Keep only alphanumeric and underscores
    name = "".join(c for c in name if c.isalnum() or c == "_")
    # Limit to 40 characters
    if len(name) > 40:
        name = name[:40]
    return name


def generate_label(filename):
    """Generate human-readable label from filename"""
    return filename.rsplit(".", 1)[0].replace("---", " - ").replace("_", " ")


def generate_metadata_file(
    filename, drive_id, size_mb, description, ceb_only, display_order, category
):
    """Generate metadata XML file"""
    today = date.today().isoformat()
    record_name = generate_record_name(filename)
    label = generate_label(filename)
    file_type = get_file_type(filename)

    xml_content = TEMPLATE.format(
        label=label,
        file_name=filename,
        drive_id=drive_id,
        file_type=file_type,
        category=category,
        size_mb=size_mb,
        upload_date=today,
        description=description,
        ceb_only=str(ceb_only).lower(),
        display_order=display_order,
    )

    output_file = f"src/main/default/customMetadata/CVMA_Google_Drive_File.{record_name}.md-meta.xml"

    # Ensure directory exists
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(xml_content)

    print(f"Created: {output_file}")
    return output_file


def main():
    """Generate all Bylaws metadata files"""
    print("Generating Bylaws metadata records...")
    print("=" * 60)

    created_files = []
    for (
        filename,
        drive_id,
        size_mb,
        description,
        ceb_only,
        display_order,
    ) in bylaws_files:
        output_file = generate_metadata_file(
            filename, drive_id, size_mb, description, ceb_only, display_order, "Bylaws"
        )
        created_files.append(output_file)

    print("=" * 60)
    print(f"\nTotal files created: {len(created_files)}")
    print("\nNext steps:")
    print("1. Review metadata files in src/main/default/customMetadata/")
    print(
        "2. Deploy to Salesforce: sf project deploy start --metadata-dir src/main/default/customMetadata"
    )
    print("3. Validate deployment")


if __name__ == "__main__":
    main()
