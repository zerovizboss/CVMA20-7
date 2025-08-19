#!/bin/bash
# CVMA Pre-commit PMD Analysis Script
# Runs PMD analysis on changed Apex files

set -e

echo "🔍 Running PMD Analysis on Apex files..."

# Check if PMD is available
if ! command -v pmd &> /dev/null; then
    echo "⚠️  PMD not found. Installing PMD..."
    
    # Create temp directory for PMD
    PMD_DIR="${HOME}/.cvma/pmd"
    mkdir -p "${PMD_DIR}"
    
    # Download and setup PMD if not exists
    if [ ! -f "${PMD_DIR}/bin/pmd" ]; then
        echo "📥 Downloading PMD..."
        cd "${PMD_DIR}"
        curl -L -o pmd-dist-7.8.0-bin.zip https://github.com/pmd/pmd/releases/download/pmd_releases%2F7.8.0/pmd-dist-7.8.0-bin.zip
        unzip -q pmd-dist-7.8.0-bin.zip
        mv pmd-bin-7.8.0/* .
        chmod +x bin/pmd
        rm -rf pmd-bin-7.8.0 pmd-dist-7.8.0-bin.zip
        echo "✅ PMD installed successfully"
    fi
    
    # Add PMD to PATH for this session
    export PATH="${PMD_DIR}/bin:${PATH}"
fi

# Get list of changed Apex files
APEX_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(cls|trigger)$' || true)

if [ -z "$APEX_FILES" ]; then
    echo "ℹ️  No Apex files changed. Skipping PMD analysis."
    exit 0
fi

echo "📄 Analyzing files:"
echo "$APEX_FILES"

# Create PMD ruleset if it doesn't exist
if [ ! -f "pmd-ruleset.xml" ]; then
    echo "📝 Creating PMD ruleset..."
    cat > pmd-ruleset.xml << 'EOF'
<?xml version="1.0"?>
<ruleset name="CVMA Apex Rules"
         xmlns="http://pmd.sourceforge.net/ruleset/2.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 http://pmd.sourceforge.net/ruleset_2_0_0.xsd">
    <description>CVMA Salesforce Apex PMD Rules - Pre-commit</description>
    
    <!-- Critical Security Rules -->
    <rule ref="category/apex/security.xml/ApexCRUDViolation" />
    <rule ref="category/apex/security.xml/ApexSharingViolations" />
    <rule ref="category/apex/security.xml/ApexSOQLInjection" />
    <rule ref="category/apex/security.xml/ApexXSSFromEscapeFalse" />
    <rule ref="category/apex/security.xml/ApexXSSFromURLParam" />
    
    <!-- Critical Best Practices -->
    <rule ref="category/apex/bestpractices.xml/ApexUnitTestClassShouldHaveAsserts" />
    <rule ref="category/apex/bestpractices.xml/ApexUnitTestShouldNotUseSeeAllDataTrue" />
    <rule ref="category/apex/bestpractices.xml/AvoidGlobalModifier" />
    
    <!-- Critical Error Prone -->
    <rule ref="category/apex/errorprone.xml/AvoidHardcodingId" />
    <rule ref="category/apex/errorprone.xml/EmptyIfStmt" />
    <rule ref="category/apex/errorprone.xml/EmptyStatementBlock" />
    
    <!-- Performance -->
    <rule ref="category/apex/performance.xml/OperationWithLimitsInLoop" />
</ruleset>
EOF
fi

# Create temp file for results
TEMP_RESULT=$(mktemp)

# Run PMD on changed files
echo "🔄 Running PMD analysis..."
pmd check \
    --dir src/classes,src/triggers \
    --rulesets pmd-ruleset.xml \
    --format text \
    --report-file "$TEMP_RESULT" \
    --fail-on-violation false \
    --minimum-priority 2 || true

# Check results
if [ -s "$TEMP_RESULT" ]; then
    echo "❌ PMD found violations in your code:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "$TEMP_RESULT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🛠️  Please fix the violations above before committing."
    echo "🔍 For detailed guidance, check: https://pmd.github.io/latest/pmd_rules_apex.html"
    rm "$TEMP_RESULT"
    exit 1
else
    echo "✅ PMD analysis passed! No critical violations found."
fi

# Cleanup
rm "$TEMP_RESULT"
echo "🎉 Pre-commit PMD check completed successfully!"