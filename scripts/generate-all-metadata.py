#!/usr/bin/env python3
"""
Generate ALL CVMA Google Drive metadata XML files
Epic #12, User Story #87 - Complete docs/ Folder Migration (92 files)
"""

import os
import re
from datetime import date

# XML Template
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

# File ID mappings (alphabetical order per folder)
BYLAWS_IDS = [
    "1d1hqjeys8Vy2pHe9qcESTEuuH2WhzJzi",
    "14Rf9ARoD4Ky-aRZIMIrsSfBHknZia4cz",
    "1235ByskFK3eRFwvNoYzjFbAfIv9oik4S",
    "1Qc88GlfInYqCkMA-0_jtl5XW99qKqTad",
    "1CFCz4PNsfVehMmXiloo4wcVOyTGYZ8Py",
    "1bnEX7Q72G77BI0b3lYEJRsGrCMFYCC0p",
    "12Dmof8zfBbfxrXIVA1Et2u0U6xwSjU05",
    "1Y-Sy8HG4n8GghN_6jy8q-BEewt7WoFUn",
    "1hYPxJRfcWe2tOCYbhPgR-y7vynGZqqjI",
    "1F5P-BAzdqRs8L7eplVx8hBuYR4py9jDi",
]

FORMS_IDS = [
    "1lGlXSQWDSmkR-5no-8eH2-Rfg6N-_RJh", "1HKPfqLDjISFhYGRq0iWoFS1zLSoB3Jv9",
    "1MtE1wmrYdboFbK3v3LWoz1hdadICvF6M", "1aaQuYvpCC1Ga8pfVswaAsulX6OsoUD7f",
    "1Qw6AvAlrTOK-qxoPhN1pUNx7ZACmZSeC", "1wNucwkiLLQ7mSgnF-LLwt2XbTNfC0o4S",
    "1Ul26pJqXolWEuSThEvjc7IXJJJucfqqR", "1LiRx15icXvv8GtDbroxpQOc75ANucaV6",
    "1Z3iDArUGGbWSip86H-BmVMtmgArPvwox", "1pI_g8dA4y4r2akmj9jOhXOdE8IdBf5WK",
    "16PcjDqmFdZ4mZagAuaONfni-Gqi7lIWL", "1-dxq1C8A_yCzlBih7tqmRWuSIlQJzTwG",
    "1QPez_4an9jdK7dj2p7_OnF2NmIcxuC7d", "1ylrv95y48VEuHIUnlvNNPCSTBDApL3hT",
    "1lEq78AvGIhx8uLmx7h6G06NTjiALTtQu", "1M14vBfAykMciWTIbJv7-48y7CJCn7xqZ",
    "1IR2ZfE-GowOKG4FnNX0nKLpa6lWsLFlx", "120zIwGtp7Khj9ycaXUGO3WVETz20tlLY",
    "1O8snhDVXTeXJ6z7BEcO71vEMdzpnTuAK", "1Ll_K0XhmbSCJ5QOkNHb77GU6umsN03Pq",
    "1rzzeKVdw9meLtEM4bj_fOrxRDXaBikPU", "1x_DbYesfVHrXTsQyyS27HF0Ci1oPDd9d",
    "1V3QJn_TVoJo2Ji1a_haPK_CXsrpsEBu0", "1C4FULFTqi6-X1Cua4h31h82X8P62UgHK",
    "1fp9k8WAjQhfo1QJmNTn3CYfonFnufdhz", "1JQWk52mL4HQQV8WYgn6qIKJKluGQEVBU",
    "1E6LA8Z3s_W-aiwZeBpQqm0vvD730K18T", "1hbm9RTGud3Xvha8OuKJ_JRBKQtdFfCsh",
    "1onhQk3ZY-aPcHJ1b5NiYSL7m28NDyNY-", "1_li72TeheJNNeP9SG-XKggDIZBac9h22",
    "1iXR7i0PzhmBSMiyaV7-klrWcVk0jFDFB", "1GR4DQV1xC5T8D_Hr7TWr5icQvJA7czO1",
    "1MhizAL_zfKM3ikgwMw53NZjN32wr1zw8", "1ytI4OXMpdOmlh9riRCwpNt8hqMX2Z5w4",
    "1AVn9XL4TuYaitTiFIabK8-_ryjCY8awL", "1czv981AJINsOp8Fx4hz6PPsOsYzC_030",
    "1oV7YEWL5QHAtHXPkr7BoDxx1MDLqAccJ", "1bOf0gXWS8E7xopW2WLLN_wW94Q_GOoSw",
    "12LMRzvrsWWNQ0_tg1C-4Ar35pKOOVcD1", "15TqayEyANdtpN4w3cGH6oYF0oFmAIfpz",
    "1ZRA7ncTcnBVFtdnx9f2MDbLEP7qshEzu", "1MRn63iDk-QCqaqGvvDZsuaX3Z8k-AX8H",
    "1qquqnDDm9YEhuMT-M1OzICXzJeuORCU6"
]

POLICY_IDS = [
    "1_YToYcyig5oUQB8wKjXJxl8PSCW85TNW", "1E8K_OyYfOLn4oNvQ0E9N58nkzCIJtczI",
    "1iWB-RT2Uo9jNIwlQXH_Uk6JUp0Olxn_e", "18ICjxQh_ovXMBuHG6f9Fx0AwLre_K6sZ",
    "1rpPHV_UWRvQtlaaQUfLyAsP2S4ro6Dlw", "12FcET-cFSuXAIOMODw2owII4zM1Y1W3k",
    "12DLWKG8db7NoAPRjDz1O92s7Pm7rMvPq", "1Hf5UTS6ew2fndk7wNzYu4Is8IYRizpGM",
    "1RuCuoV-HqGP7ud1xQTp-YUeqtSannu5U", "1_BZQhS-5NKjGabbIX8PHRAV8cKSTA7nE",
    "1Aql-1KT8zAI1f5ORueUjb3z6VSTfkzvg", "1lW5uB2mIvhMlRuBregp9Pa_JkYQAJ5Z4",
    "1CSNxo2BOEJuFxsUDaYY8HHu5p1luOH9R", "1E8K_OyYfOLn4oNvQ0E9N58nkzCIJtczI",
    "16j-UtL-as460Sp1YFasftpYjcMZcQKst", "11kx8MZPgrLT5wr5ch7xsNdKx6VrwBMJX",
    "12DdtwiUCwXVSZNdV4uzFvqmY5XL8DJVp", "15yQzh7PSV-_82l1Bd9vWlLvl1dmzWy4A",
    "1zNIR38cGDIyjHOhUn7d4YRXQqVc5_UyJ", "1e0qlpmANynaYWnU9c5yNmr_x9ffQO1kI"
]

PROTOCOL_IDS = ["1B3fqf8AchpyTEia0_H4i9loRKN5AfSy7"]

SOP_IDS = [
    "1rUyYqiidyXOugQnpt5tVUN-xPP4s6nA8", "1938j5CpmSSDJiRGRWKvVzjWFe5obR8Jl",
    "1kSseyMV3hXk_Hr33BUcN_zvR-0ZFqG9Y", "1fsPprMN7ccRtWBTDhcXbBF60WzPjnU0K",
    "11aVDN9bLkUVJKJuPYqjcw0JfkwilC8sV", "1ZycMy9j5lIzGWC-WumgKut2xu0RmZl_k",
    "1---Jgv937D2NED0ZVDWVNtOwMb0fK94m", "1h20zDODjxT6CjJVOcZL8mqQFTNTe42Ac"
]

AUXILIARY_IDS = [
    "1fDc9PNIT0elHsOqjxqqekULocEkiSgsE", "1AokTZzMuQltslX-BoFx47pNMkrq_t-8e",
    "1IQf6alYfxgM1_5e2FK3kqQ6DTnzFN1u7", "1tTknTRa7RPpz2rA2wmgldxWO2ocvheH7",
    "1O8ijM7rTEWcRJyIxpPZFeIkaCb_1v7QO", "1onEvt_X4CjBtUnrXtEnY-yDrGL2Cn6bm",
    "1qsb3Zrf1QYcfkCUlH4D7j9oSIVnhTlvt", "1KbJ1wNktLEU8FKonMF8K5W9waTbFgMR4",
    "11v1G9XKMRU-pq0jptODl1e8TqG7fyAR1", "1EYmeUyUz7A-3jwKiWpHS1vvu8VciDwvI"
]

LICENSE_USE_IDS = [
    "1hWFXk7dulMG4eQKlLtuQqpAfqGcIBEVB", "1gjN_Hr6ZUP8hn951SbziB4vBa-7KinOe",
    "1-A7oecqhfE1vUQo8a4HzyFJXDifOvgiH", "1049dmtowL-dYhiw4_8E55MjQNKDxu3tK",
    "1KTZqPz3cTXPKzC59rX07Ph6lWPCI9ZZX", "1VUEhEp7gwJ-KfLs1zBO_WoQdxoOOVj-v",
    "1kQob1hzAWOuYYUijxEkXZn8uA8nDdAVg", "1254dRiTcDm6Sqs0gcgJXZEVcDeEbV40Y"
]

def get_file_type(filename):
    """Extract file type from filename"""
    ext = filename.split('.')[-1].upper()
    return ext

def generate_record_name(filename, category):
    """Generate unique alphanumeric record name"""
    # Remove extension
    name = filename.rsplit('.', 1)[0]
    # Replace special characters
    name = re.sub(r'[^a-zA-Z0-9]+', '_', name)
    # Add category prefix for uniqueness
    name = f"{category}_{name}"
    # Limit to 40 characters
    if len(name) > 40:
        name = name[:40]
    return name.rstrip('_')

def generate_label(filename):
    """Generate human-readable label"""
    return filename.rsplit('.', 1)[0].replace('---', ' - ').replace('_', ' ')

def generate_metadata_file(filename, drive_id, category, display_order, ceb_only=False, size_mb=0.1):
    """Generate metadata XML file"""
    today = date.today().isoformat()
    record_name = generate_record_name(filename, category)
    label = generate_label(filename)
    file_type = get_file_type(filename)

    # Generate description based on category and filename
    description = f"CVMA {category} - {label}"

    xml_content = TEMPLATE.format(
        label=label[:80],  # Salesforce label limit
        file_name=filename,
        drive_id=drive_id,
        file_type=file_type,
        category=category,
        size_mb=size_mb,
        upload_date=today,
        description=description[:1000],  # Long text limit
        ceb_only=str(ceb_only).lower(),
        display_order=display_order
    )

    output_file = f"src/main/default/customMetadata/CVMA_Google_Drive_File.{record_name}.md-meta.xml"
    os.makedirs(os.path.dirname(output_file), exist_ok=True)

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(xml_content)

    return output_file

def get_local_filenames(folder_path):
    """Get alphabetically sorted filenames from local folder"""
    if not os.path.exists(folder_path):
        return []
    files = [f for f in os.listdir(folder_path) if os.path.isfile(os.path.join(folder_path, f))]
    return sorted(files)

def process_folder(folder_name, file_ids, category, start_order, ceb_only_default=False):
    """Process a folder and generate metadata"""
    base_path = "/c/Users/zerov/OneDrive/Documents/CVMA/Documentation"
    folder_path = os.path.join(base_path, folder_name)

    filenames = get_local_filenames(folder_path)
    created = []

    print(f"\n{category} ({len(filenames)} files):")
    print("=" * 60)

    for idx, (filename, drive_id) in enumerate(zip(filenames, file_ids)):
        display_order = start_order + (idx * 10)
        output_file = generate_metadata_file(
            filename, drive_id, category, display_order, ceb_only_default
        )
        created.append(output_file)
        print(f"  [{idx+1:2d}] {filename[:50]:<50} → {drive_id[:20]}")

    return created

def main():
    """Generate all metadata records"""
    print("CVMA Google Drive Metadata Generation")
    print("Epic #12, User Story #87 - Complete docs/ Migration")
    print("=" * 60)

    all_files = []

    # Process each folder
    all_files += process_folder("Bylaws", BYLAWS_IDS, "Bylaws", 10, False)
    all_files += process_folder("Forms", FORMS_IDS, "Forms", 200, False)
    all_files += process_folder("Policy", POLICY_IDS, "Policy", 600, True)
    all_files += process_folder("Protocol", PROTOCOL_IDS, "Protocol", 800, True)
    all_files += process_folder("SOP", SOP_IDS, "SOP", 900, True)
    all_files += process_folder("Auxiliary", AUXILIARY_IDS, "Auxiliary", 1100, False)
    all_files += process_folder("License Use", LICENSE_USE_IDS, "License Use", 1300, True)

    print("\n" + "=" * 60)
    print(f"✅ Total metadata files created: {len(all_files)}")
    print("\nNext steps:")
    print("1. Review: src/main/default/customMetadata/")
    print("2. Deploy: sf project deploy start --metadata-dir src/main/default/customMetadata --target-org cvma")
    print("3. Validate: Check deployment status")

if __name__ == '__main__':
    main()
