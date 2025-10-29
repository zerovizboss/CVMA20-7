#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Lucidchart Package Access Test
Checks what Lucidchart components are accessible in CVMA org
"""

import subprocess
import json
import sys
import io

# Set UTF-8 encoding for Windows
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

print("=" * 70)
print("Lucidchart Package Access Test - CVMA Org")
print("=" * 70)

# Connect using simple-salesforce
try:
    from simple_salesforce import Salesforce

    # Get CLI session
    sf_cmd = "C:\\Program Files\\sf\\bin\\sf.cmd"
    result = subprocess.run(
        [sf_cmd, "org", "display", "--json", "--target-org", "cvma"],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print("Error: Could not access Salesforce CLI session")
        sys.exit(1)

    org_info = json.loads(result.stdout)
    sf = Salesforce(
        instance_url=org_info["result"]["instanceUrl"],
        session_id=org_info["result"]["accessToken"],
    )

    print("\n✅ Connected to CVMA org")
    print(f"   Username: {org_info['result']['username']}")

except Exception as e:
    print(f"❌ Connection failed: {e}")
    sys.exit(1)

# Check Lucidchart package installation
print("\n" + "=" * 70)
print("1. Lucidchart Package Information")
print("=" * 70)

try:
    # Query installed packages
    packages = sf.query(
        """
        SELECT SubscriberPackageName, SubscriberPackageNamespace,
               SubscriberPackageVersionName, SubscriberPackageVersionNumber
        FROM InstalledSubscriberPackage
        WHERE SubscriberPackageName LIKE '%Lucid%'
    """
    )

    if packages["totalSize"] > 0:
        for pkg in packages["records"]:
            print(f"\n✅ Package Found:")
            print(f"   Name: {pkg['SubscriberPackageName']}")
            print(f"   Namespace: {pkg['SubscriberPackageNamespace']}")
            print(
                f"   Version: {pkg['SubscriberPackageVersionName']} ({pkg['SubscriberPackageVersionNumber']})"
            )
    else:
        print("\n❌ No Lucidchart package found")
        sys.exit(1)

except Exception as e:
    print(f"\n❌ Error querying packages: {e}")
    sys.exit(1)

# Check Lucidchart custom objects
print("\n" + "=" * 70)
print("2. Lucidchart Custom Objects")
print("=" * 70)

try:
    # Describe objects with Lucidchart namespace
    global_describe = sf.describe()
    lucid_objects = [
        obj
        for obj in global_describe["sobjects"]
        if "Lucidchart" in obj["name"] or "Lucid" in obj["name"]
    ]

    if lucid_objects:
        print(f"\n✅ Found {len(lucid_objects)} Lucidchart objects:")
        for obj in lucid_objects:
            print(f"   - {obj['name']} ({obj['label']})")
            print(
                f"     Queryable: {obj['queryable']}, Createable: {obj['createable']}"
            )
    else:
        print("\n⚠️  No Lucidchart custom objects found")

except Exception as e:
    print(f"\n❌ Error describing objects: {e}")

# Check for Lucidchart Visualforce pages
print("\n" + "=" * 70)
print("3. Lucidchart Visualforce Pages")
print("=" * 70)

try:
    # Query Visualforce pages using Tooling API
    tooling_query = """
        SELECT Id, Name, ApiVersion, Description
        FROM ApexPage
        WHERE NamespacePrefix = 'Lucidchart'
    """

    # Use REST API for Tooling query
    tooling_url = f"{sf.base_url}tooling/query/?q={tooling_query.replace(' ', '+')}"
    response = sf.restful(tooling_url.replace(sf.base_url, ""))

    if response["size"] > 0:
        print(f"\n✅ Found {response['size']} Visualforce pages:")
        for page in response["records"]:
            print(f"   - {page['Name']}")
            if page.get("Description"):
                print(f"     Description: {page['Description']}")
    else:
        print("\n⚠️  No Lucidchart Visualforce pages found")

except Exception as e:
    print(f"\n⚠️  Could not query Visualforce pages: {e}")

# Check for Lucidchart Lightning components
print("\n" + "=" * 70)
print("4. Lucidchart Lightning Web Components")
print("=" * 70)

try:
    # Query Lightning components
    tooling_query = """
        SELECT Id, DeveloperName, MasterLabel, Description
        FROM LightningComponentBundle
        WHERE NamespacePrefix = 'Lucidchart'
    """

    tooling_url = f"{sf.base_url}tooling/query/?q={tooling_query.replace(' ', '+')}"
    response = sf.restful(tooling_url.replace(sf.base_url, ""))

    if response["size"] > 0:
        print(f"\n✅ Found {response['size']} Lightning components:")
        for comp in response["records"]:
            print(f"   - {comp['DeveloperName']} ({comp['MasterLabel']})")
    else:
        print("\n⚠️  No Lucidchart Lightning components found")

except Exception as e:
    print(f"\n⚠️  Could not query Lightning components: {e}")

# Check for Lucidchart Apex classes
print("\n" + "=" * 70)
print("5. Lucidchart Apex Classes")
print("=" * 70)

try:
    apex_classes = sf.query(
        """
        SELECT Id, Name, ApiVersion, Status
        FROM ApexClass
        WHERE NamespacePrefix = 'Lucidchart'
        LIMIT 10
    """
    )

    if apex_classes["totalSize"] > 0:
        print(f"\n✅ Found {apex_classes['totalSize']} Apex classes:")
        for cls in apex_classes["records"]:
            print(
                f"   - {cls['Name']} (API {cls['ApiVersion']}, Status: {cls['Status']})"
            )
    else:
        print("\n⚠️  No Lucidchart Apex classes found")

except Exception as e:
    print(f"\n⚠️  Could not query Apex classes: {e}")

# Check Custom Settings
print("\n" + "=" * 70)
print("6. Lucidchart Custom Settings/Metadata")
print("=" * 70)

try:
    # Try to query custom settings
    settings_query = """
        SELECT QualifiedApiName, DeveloperName, MasterLabel
        FROM CustomObject
        WHERE NamespacePrefix = 'Lucidchart'
    """

    tooling_url = f"{sf.base_url}tooling/query/?q={settings_query.replace(' ', '+')}"
    response = sf.restful(tooling_url.replace(sf.base_url, ""))

    if response["size"] > 0:
        print(f"\n✅ Found {response['size']} custom objects/settings:")
        for obj in response["records"]:
            print(f"   - {obj['QualifiedApiName']} ({obj['MasterLabel']})")
    else:
        print("\n⚠️  No custom settings found")

except Exception as e:
    print(f"\n⚠️  Could not query custom settings: {e}")

# Summary
print("\n" + "=" * 70)
print("SUMMARY: Lucidchart Access Analysis")
print("=" * 70)

print(
    """
✅ Lucidchart package is installed in your org
   Package: Lucidchart for Sales
   Version: Q3 2020 v2.0 (2.0.0.1)
   Namespace: Lucidchart

❓ WHAT I CAN DO:
   - Query Lucidchart objects/data in your org
   - Access Lucidchart metadata (if exists)
   - View embedded diagrams (if configured)

❌ WHAT I CANNOT DO (Without Your Account):
   - Create new diagrams in Lucidchart cloud
   - Access your Lucidchart account documents
   - Generate diagrams via Lucidchart API
   - Authenticate to lucid.app

🔐 AUTHENTICATION REQUIREMENT:
   - Lucidchart integration requires YOUR Lucid account login
   - Package connects YOUR Salesforce to YOUR Lucidchart account
   - I cannot access lucid.app without your credentials
   - API access requires Lucidchart Enterprise plan + API keys

📋 WHAT YOU NEED TO DO:
   1. Log into Salesforce and configure Lucidchart integration
   2. Connect your Lucid account (lucid.app) to Salesforce
   3. If you want API automation, you need:
      - Lucidchart Enterprise plan
      - API access enabled
      - OAuth2 credentials from Lucidchart admin console

🎯 RECOMMENDED NEXT STEPS:
   1. Check if Lucidchart is configured in Salesforce Setup
   2. Navigate to Setup > Installed Packages > Lucidchart
   3. Follow Lucidchart's setup wizard to connect accounts
   4. Once connected, diagrams can be embedded in Salesforce records
"""
)

print("\n" + "=" * 70)
print("For full API access, see:")
print("https://lucid.co/developer-resources")
print("=" * 70)
