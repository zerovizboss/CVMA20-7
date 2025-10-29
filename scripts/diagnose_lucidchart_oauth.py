#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Lucidchart OAuth Diagnostic Script
Checks Connected Apps and OAuth configuration
"""

import subprocess
import json
import sys
import io

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

print("=" * 70)
print("Lucidchart OAuth Configuration Diagnostic")
print("=" * 70)

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

    print("\nConnected to CVMA org")
    print(f"Instance: {org_info['result']['instanceUrl']}")

except Exception as e:
    print(f"Connection failed: {e}")
    sys.exit(1)

# Check Connected Apps
print("\n" + "=" * 70)
print("1. Connected Apps Analysis")
print("=" * 70)

try:
    # Use Tooling API to query Connected Apps
    query = "SELECT Id, Name, Status, CreatedDate FROM ConnectedApplication"
    tooling_url = f"tooling/query/?q={query.replace(' ', '+')}"
    response = sf.restful(tooling_url)

    if response["size"] > 0:
        print(f"\nFound {response['size']} Connected Apps:")
        for app in response["records"]:
            print(f"\n  Name: {app['Name']}")
            print(f"  Status: {app['Status']}")
            print(f"  Created: {app['CreatedDate']}")
            print(f"  ID: {app['Id']}")
    else:
        print("\nNo Connected Apps found")
        print("This is the PROBLEM - Lucidchart package should have created one")

except Exception as e:
    print(f"\nCould not query Connected Apps: {e}")

# Check OAuth settings
print("\n" + "=" * 70)
print("2. OAuth Configuration Check")
print("=" * 70)

try:
    # Check if we can access OAuth tokens (would show active connections)
    query = "SELECT Id, UserId, AppName, CreatedDate, LastUsedDate FROM OauthToken WHERE AppName LIKE '%Lucid%'"
    tokens = sf.query(query)

    if tokens["totalSize"] > 0:
        print(f"\nFound {tokens['totalSize']} OAuth tokens:")
        for token in tokens["records"]:
            print(f"\n  App: {token['AppName']}")
            print(f"  Created: {token['CreatedDate']}")
            print(f"  Last Used: {token.get('LastUsedDate', 'Never')}")
    else:
        print("\nNo OAuth tokens found for Lucidchart")
        print("Expected - this means no successful connection yet")

except Exception as e:
    print(f"\nCannot query OAuth tokens (normal restriction): {e}")

# Check package installation
print("\n" + "=" * 70)
print("3. Package Installation Status")
print("=" * 70)

try:
    # Check for Lucidchart namespace
    describe = sf.describe()
    lucid_objects = [
        obj["name"]
        for obj in describe["sobjects"]
        if "Lucidchart" in obj["name"] or "Lucid" in obj["name"]
    ]

    if lucid_objects:
        print(f"\nLucidchart package objects found: {len(lucid_objects)}")
        for obj in lucid_objects[:5]:
            print(f"  - {obj}")
    else:
        print("\nNo Lucidchart objects found")

except Exception as e:
    print(f"\nError checking package: {e}")

# Recommendations
print("\n" + "=" * 70)
print("DIAGNOSIS & RECOMMENDATIONS")
print("=" * 70)

print(
    """
ISSUE IDENTIFIED:
The Lucidchart package is installed, but OAuth connection is failing.

MOST LIKELY CAUSES:

1. MISSING CONNECTED APP
   - Old Lucidchart package version (Q3 2020)
   - May not have proper OAuth configuration
   - SOLUTION: Upgrade or reinstall package

2. DEVELOPER EDITION OAUTH LIMITATIONS
   - Some OAuth flows restricted in Developer Edition
   - Connected App limits (max 5 apps)
   - SOLUTION: Check connected apps count

3. PACKAGE CONFIGURATION INCOMPLETE
   - Package installed but not fully configured
   - Missing OAuth consumer keys
   - SOLUTION: Complete setup wizard

RECOMMENDED ACTIONS:

ACTION #1: Check Connected Apps Count
------------------------------------------
1. Setup > Apps > Connected Apps > Manage Connected Apps
2. Count how many apps are listed
3. If 5 apps exist, remove one (least used)
4. Developer Edition limit is 5 connected apps max

ACTION #2: Reinstall Lucidchart Package (Latest Version)
------------------------------------------
Your version: Q3 2020 v2.0 (OLD - 5 years old!)
Latest version: Check AppExchange

Steps:
1. Setup > Installed Packages > Lucidchart
2. Export any data (if you have diagrams linked)
3. Click "Uninstall"
4. Wait for uninstall to complete
5. Go to AppExchange: https://appexchange.salesforce.com/
6. Search "Lucidchart"
7. Click "Get It Now"
8. Install latest version
9. Follow new setup wizard

ACTION #3: Use Lucidchart Without Salesforce Integration
------------------------------------------
If OAuth continues to fail:
1. Create diagrams in lucid.app independently
2. Store diagram URLs in Salesforce custom fields
3. Not ideal but functional workaround
4. Can build custom LWC components to embed diagrams

ACTION #4: Contact Lucidchart Support
------------------------------------------
Email: support@lucidchart.com
Include:
- Salesforce Org ID: 00Dbm000007w9muEAA
- Package Version: 2.0.0.1 (Q3 2020)
- Issue: OAuth authentication failing
- Request: Help with Developer Edition org connection
"""
)

print("\n" + "=" * 70)
print("Next Step: Try ACTION #1 (Check Connected Apps count)")
print("=" * 70)
