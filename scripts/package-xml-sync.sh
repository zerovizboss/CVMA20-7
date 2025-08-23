#!/bin/bash
# CVMA Package.xml Synchronization Automation with Target Org
# Automated metadata synchronization and package.xml management

set -e

# Configuration
REPORTS_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SYNC_DIR="${REPORTS_DIR}/${TIMESTAMP}/sync"

echo "📦 CVMA Package.xml Synchronization with Target Org"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create sync reports directory
mkdir -p "${SYNC_DIR}"

# Check Salesforce CLI availability
if ! command -v sf &> /dev/null; then
    echo "❌ Error: Salesforce CLI (sf) not found"
    echo "Please install Salesforce CLI: https://developer.salesforce.com/tools/sfdxcli"
    exit 1
fi

# Verify org connection
echo "🔍 Verifying org connection..."
if ! sf org display --json > "${SYNC_DIR}/org-info.json" 2>/dev/null; then
    echo "❌ Error: No default org found or org connection failed"
    echo "Please authenticate with: sf org login web"
    exit 1
fi

ORG_USERNAME=$(cat "${SYNC_DIR}/org-info.json" | jq -r '.result.username')
ORG_TYPE=$(cat "${SYNC_DIR}/org-info.json" | jq -r '.result.connectedStatus // "Unknown"')
echo "✅ Connected to org: ${ORG_USERNAME} (${ORG_TYPE})"

# Backup current package.xml
if [ -f "src/package.xml" ]; then
    cp "src/package.xml" "${SYNC_DIR}/package-backup.xml"
    echo "💾 Current package.xml backed up to: ${SYNC_DIR}/package-backup.xml"
fi

# Get org metadata inventory
echo "📋 Retrieving metadata inventory from target org..."
sf project list metadata --json > "${SYNC_DIR}/org-metadata.json" || {
    echo "❌ Failed to retrieve metadata inventory"
    exit 1
}

# Parse metadata types and components
echo "🔄 Analyzing metadata components..."

# Extract metadata types from org
cat "${SYNC_DIR}/org-metadata.json" | jq -r '.result[] | .type' | sort -u > "${SYNC_DIR}/available-types.txt"

# Count metadata by type
cat > "${SYNC_DIR}/metadata-summary.txt" << EOF
CVMA Metadata Inventory Summary
Generated: $(date)
Target Org: ${ORG_USERNAME}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

METADATA TYPE SUMMARY:
EOF

TOTAL_COMPONENTS=0
while read -r type; do
    COUNT=$(cat "${SYNC_DIR}/org-metadata.json" | jq -r --arg type "$type" '.result[] | select(.type == $type) | .fullName' | wc -l)
    echo "  ${type}: ${COUNT} components" >> "${SYNC_DIR}/metadata-summary.txt"
    TOTAL_COMPONENTS=$((TOTAL_COMPONENTS + COUNT))
done < "${SYNC_DIR}/available-types.txt"

echo "  TOTAL: ${TOTAL_COMPONENTS} components" >> "${SYNC_DIR}/metadata-summary.txt"

# Generate optimized package.xml based on org content
echo "🔧 Generating synchronized package.xml..."

# Define core metadata types for CVMA project
cat > "${SYNC_DIR}/core-metadata-types.txt" << EOF
ApexClass
ApexTrigger
CustomObject
CustomField
Layout
ListView
WebLink
CustomTab
CustomApplication
Profile
PermissionSet
Flow
WorkflowRule
ValidationRule
CustomMetadata
LightningComponentBundle
AuraDefinitionBundle
StaticResource
EmailTemplate
Report
Dashboard
Queue
QuickAction
CompactLayout
RecordType
BusinessProcess
CustomSettings
Community
Network
ExperienceBundle
Site
CommunityTemplateDefinition
CommunityThemeDefinition
Settings
RemoteSiteSetting
NamedCredential
ExternalDataSource
EOF

# Start building new package.xml
cat > "${SYNC_DIR}/package-generated.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
EOF

# Process each core metadata type
while read -r metadata_type; do
    # Check if this type exists in the org
    TYPE_COUNT=$(cat "${SYNC_DIR}/org-metadata.json" | jq -r --arg type "$metadata_type" '.result[] | select(.type == $type) | .fullName' | wc -l 2>/dev/null || echo 0)
    
    if [ "$TYPE_COUNT" -gt 0 ]; then
        echo "    <types>" >> "${SYNC_DIR}/package-generated.xml"
        
        # Add all members of this type
        cat "${SYNC_DIR}/org-metadata.json" | jq -r --arg type "$metadata_type" '.result[] | select(.type == $type) | .fullName' | sort | while read -r member; do
            if [ -n "$member" ] && [ "$member" != "null" ]; then
                echo "        <members>${member}</members>" >> "${SYNC_DIR}/package-generated.xml"
            fi
        done
        
        echo "        <name>${metadata_type}</name>" >> "${SYNC_DIR}/package-generated.xml"
        echo "    </types>" >> "${SYNC_DIR}/package-generated.xml"
        
        echo "✅ Added ${metadata_type}: ${TYPE_COUNT} components"
    fi
done < "${SYNC_DIR}/core-metadata-types.txt"

# Add API version
echo "    <version>61.0</version>" >> "${SYNC_DIR}/package-generated.xml"
echo "</Package>" >> "${SYNC_DIR}/package-generated.xml"

# Compare with existing package.xml if it exists
if [ -f "src/package.xml" ]; then
    echo "🔍 Comparing with existing package.xml..."
    
    # Extract components from current package.xml
    if command -v xmlstarlet &> /dev/null; then
        xmlstarlet sel -t -m "//members" -v "." -n src/package.xml | sort > "${SYNC_DIR}/current-members.txt" 2>/dev/null || echo "Could not parse current package.xml"
        xmlstarlet sel -t -m "//members" -v "." -n "${SYNC_DIR}/package-generated.xml" | sort > "${SYNC_DIR}/new-members.txt" 2>/dev/null || echo "Could not parse new package.xml"
        
        if [ -f "${SYNC_DIR}/current-members.txt" ] && [ -f "${SYNC_DIR}/new-members.txt" ]; then
            # Find differences
            comm -23 "${SYNC_DIR}/current-members.txt" "${SYNC_DIR}/new-members.txt" > "${SYNC_DIR}/removed-components.txt"
            comm -13 "${SYNC_DIR}/current-members.txt" "${SYNC_DIR}/new-members.txt" > "${SYNC_DIR}/added-components.txt"
            
            REMOVED_COUNT=$(wc -l < "${SYNC_DIR}/removed-components.txt")
            ADDED_COUNT=$(wc -l < "${SYNC_DIR}/added-components.txt")
            
            echo "📊 Package.xml Changes:" >> "${SYNC_DIR}/metadata-summary.txt"
            echo "  Components Added: ${ADDED_COUNT}" >> "${SYNC_DIR}/metadata-summary.txt"
            echo "  Components Removed: ${REMOVED_COUNT}" >> "${SYNC_DIR}/metadata-summary.txt"
        fi
    fi
fi

# Validate generated package.xml
echo "✅ Validating generated package.xml..."
if ! xmllint --noout "${SYNC_DIR}/package-generated.xml" 2>/dev/null; then
    echo "❌ Generated package.xml is invalid"
    exit 1
fi

# Create comprehensive sync report
cat >> "${SYNC_DIR}/metadata-summary.txt" << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SYNCHRONIZATION RESULTS:
  ✅ Package.xml generated successfully
  📦 Total Components: ${TOTAL_COMPONENTS}
  🎯 Core Types Processed: $(wc -l < "${SYNC_DIR}/core-metadata-types.txt")
  📄 Backup Created: ${SYNC_DIR}/package-backup.xml
  🆕 New Package.xml: ${SYNC_DIR}/package-generated.xml

DEPLOYMENT READINESS:
$([ -f "src/package.xml" ] && echo "  📋 Backup of current package.xml created" || echo "  🆕 No existing package.xml found")
  🔍 Generated package.xml validated
  🎯 Ready for deployment to target org

NEXT STEPS:
  1. Review the generated package.xml: ${SYNC_DIR}/package-generated.xml
  2. Compare with backup if needed: ${SYNC_DIR}/package-backup.xml
  3. Replace src/package.xml with generated version
  4. Run deployment validation: sf project deploy validate --source-dir src
  5. Deploy to target org: sf project deploy start --source-dir src

FILES GENERATED:
  - Metadata Summary: ${SYNC_DIR}/metadata-summary.txt
  - Org Inventory: ${SYNC_DIR}/org-metadata.json
  - Generated Package: ${SYNC_DIR}/package-generated.xml
  - Package Backup: ${SYNC_DIR}/package-backup.xml
  - Available Types: ${SYNC_DIR}/available-types.txt

EOF

# Display results
echo ""
echo "📋 Package.xml Synchronization Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "${SYNC_DIR}/metadata-summary.txt"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create symlink to latest sync
rm -f "${REPORTS_DIR}/latest-sync"
ln -sf "${TIMESTAMP}/sync" "${REPORTS_DIR}/latest-sync"

echo ""
echo "📈 Latest sync reports available at: ${REPORTS_DIR}/latest-sync/"

# Prompt for package.xml replacement
echo ""
echo "🤔 Would you like to replace the current package.xml with the synchronized version?"
echo "   Current: src/package.xml"
echo "   Generated: ${SYNC_DIR}/package-generated.xml"
echo ""
echo "Manual replacement command:"
echo "   cp ${SYNC_DIR}/package-generated.xml src/package.xml"

# Create automated replacement script
cat > "${SYNC_DIR}/apply-sync.sh" << EOF
#!/bin/bash
# Apply synchronized package.xml to project

echo "🔄 Applying synchronized package.xml..."
cp "${SYNC_DIR}/package-generated.xml" src/package.xml
echo "✅ Package.xml updated successfully!"

echo "🔍 Validating deployment..."
sf project deploy validate --source-dir src --wait 10
EOF

chmod +x "${SYNC_DIR}/apply-sync.sh"

echo ""
echo "🚀 Auto-apply script created: ${SYNC_DIR}/apply-sync.sh"
echo "   Run this script to apply the synchronized package.xml and validate deployment"

# Exit successfully
echo "✅ Package.xml synchronization completed successfully"
exit 0