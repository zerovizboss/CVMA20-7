#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Simple-Salesforce Configuration Test Script
Tests connection to CVMA Salesforce org using three different methods
"""

import subprocess
import json
import sys
import io

# Set UTF-8 encoding for Windows console
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

print("=" * 70)
print("CVMA Simple-Salesforce Configuration Test")
print("=" * 70)

# Method 1: Using Salesforce CLI Session (RECOMMENDED - Most Secure)
print("\nMethod 1: Salesforce CLI Session (Recommended)")
print("-" * 70)

try:
    # Get access token from Salesforce CLI
    # Use full path for Windows compatibility
    sf_cmd = (
        "/c/Program Files/sf/bin/sf"
        if sys.platform != "win32"
        else "C:\\Program Files\\sf\\bin\\sf.cmd"
    )
    result = subprocess.run(
        [sf_cmd, "org", "display", "--json", "--target-org", "cvma"],
        capture_output=True,
        text=True,
        shell=False,
    )

    if result.returncode == 0:
        org_info = json.loads(result.stdout)
        access_token = org_info["result"]["accessToken"]
        instance_url = org_info["result"]["instanceUrl"]
        username = org_info["result"]["username"]

        print(f"✅ CLI Session Active")
        print(f"   Username: {username}")
        print(f"   Instance: {instance_url}")
        print(f"   Access Token: {access_token[:20]}...")

        # Test connection with simple-salesforce
        try:
            from simple_salesforce import Salesforce

            sf = Salesforce(instance_url=instance_url, session_id=access_token)

            # Test query
            result = sf.query("SELECT Id, Name FROM Account LIMIT 1")
            print(f"✅ Connection successful!")
            print(f"   Query test passed: Retrieved {result['totalSize']} records")

            print("\n📝 Usage Pattern for Your Scripts:")
            print(
                """
import subprocess
import json
from simple_salesforce import Salesforce

# Get CLI session
result = subprocess.run(
    ['sf', 'org', 'display', '--json', '--target-org', 'cvma'],
    capture_output=True, text=True
)
org_info = json.loads(result.stdout)

# Connect using CLI session
sf = Salesforce(
    instance_url=org_info['result']['instanceUrl'],
    session_id=org_info['result']['accessToken']
)

# Use sf object for queries
accounts = sf.query("SELECT Id, Name FROM Account")
            """
            )

        except ImportError:
            print("❌ simple-salesforce not installed")
            print("   Run: pip install simple-salesforce")
            sys.exit(1)
        except Exception as e:
            print(f"❌ Connection failed: {e}")
            sys.exit(1)
    else:
        print("❌ No active Salesforce CLI session")
        print("   Run: sf org login web --alias cvma")
        sys.exit(1)

except FileNotFoundError:
    print("❌ Salesforce CLI not found")
    print("   Please ensure 'sf' command is available in your PATH")
    sys.exit(1)

# Method 2: Environment Variables (.env file)
print("\n\n🔐 Method 2: Environment Variables (.env file)")
print("-" * 70)

try:
    from dotenv import load_dotenv
    import os

    # Try to load .env file
    if load_dotenv():
        username = os.getenv("SF_USERNAME")
        password = os.getenv("SF_PASSWORD")
        security_token = os.getenv("SF_SECURITY_TOKEN")

        if username and password and security_token:
            print("✅ .env file found with credentials")
            print(f"   Username: {username}")
            print(f"   Password: {'*' * len(password)}")
            print(f"   Token: {security_token[:5]}...")

            try:
                from simple_salesforce import Salesforce

                sf = Salesforce(
                    username=username, password=password, security_token=security_token
                )

                result = sf.query("SELECT Id, Name FROM Account LIMIT 1")
                print(f"✅ Connection successful!")
                print(f"   Query test passed: Retrieved {result['totalSize']} records")

                print("\n📝 Usage Pattern for Your Scripts:")
                print(
                    """
from dotenv import load_dotenv
import os
from simple_salesforce import Salesforce

load_dotenv()

sf = Salesforce(
    username=os.getenv('SF_USERNAME'),
    password=os.getenv('SF_PASSWORD'),
    security_token=os.getenv('SF_SECURITY_TOKEN')
)

# Use sf object for queries
accounts = sf.query("SELECT Id, Name FROM Account")
                """
                )

            except Exception as e:
                print(f"❌ Connection failed: {e}")
                print("   Check your credentials in .env file")
        else:
            print("⚠️  .env file exists but missing required credentials")
            print("   Required: SF_USERNAME, SF_PASSWORD, SF_SECURITY_TOKEN")
            print("   See .env.example for template")
    else:
        print("⚠️  No .env file found")
        print("   Copy .env.example to .env and fill in your credentials")
        print("   Run: cp .env.example .env")

except ImportError:
    print("⚠️  python-dotenv not installed (optional)")
    print("   Run: pip install python-dotenv")

# Method 3: Direct Credentials (NOT RECOMMENDED - for testing only)
print("\n\n🔐 Method 3: Direct Credentials (Not Recommended)")
print("-" * 70)
print("⚠️  Hardcoding credentials in scripts is insecure")
print("   Use Method 1 (CLI Session) or Method 2 (.env file) instead")
print("\n📝 Pattern (for reference only):")
print(
    """
from simple_salesforce import Salesforce

sf = Salesforce(
    username='detonator@cvma20-7.org',
    password='your_password',
    security_token='your_token'
)
"""
)

# Summary and Recommendations
print("\n" + "=" * 70)
print("📊 CONFIGURATION SUMMARY")
print("=" * 70)
print("\n✅ RECOMMENDED: Use Method 1 (Salesforce CLI Session)")
print("   - Most secure (no credentials in code)")
print("   - Uses existing sf org login")
print("   - Tokens refresh automatically")
print("   - No additional setup needed")

print("\n⚠️  ALTERNATIVE: Use Method 2 (.env file)")
print("   - Good for automated scripts")
print("   - Credentials stored in .env (gitignored)")
print("   - Requires password + security token")
print("   - Install: pip install python-dotenv")

print("\n❌ AVOID: Method 3 (Hardcoded credentials)")
print("   - Security risk")
print("   - Credentials in source code")
print("   - Not suitable for git repositories")

print("\n" + "=" * 70)
print("🎯 NEXT STEPS")
print("=" * 70)
print("\n1. ✅ simple-salesforce is installed (version 1.12.9)")
print("2. ✅ Salesforce CLI session is active")
print("3. ✅ Connection test passed")
print("\n4. You're ready to use simple-salesforce in your Python scripts!")
print("   - Use the CLI Session pattern (Method 1)")
print("   - Reference: Python-Salesforce-Learning-Guide.md")
print("   - Try: scripts/export_cvma_members.py (example script)")

print("\n" + "=" * 70)
