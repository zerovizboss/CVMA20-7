#!/bin/bash
# CVMA PMD Analysis Script for Current Codebase
# Runs PMD analysis on all Apex files

set -e

echo "🔍 Running PMD Analysis on CVMA codebase..."

# Check if PMD is available
PMD_DIR="${HOME}/.cvma/pmd"
if [ ! -f "${PMD_DIR}/bin/pmd" ]; then
    echo "⚠️  PMD not found. Installing PMD..."
    mkdir -p "${PMD_DIR}"
    cd "${PMD_DIR}"
    echo "📥 Downloading PMD..."
    curl -L -o pmd-dist-7.8.0-bin.zip https://github.com/pmd/pmd/releases/download/pmd_releases%2F7.8.0/pmd-dist-7.8.0-bin.zip
    unzip -q pmd-dist-7.8.0-bin.zip
    mv pmd-bin-7.8.0/* .
    chmod +x bin/pmd
    rm -rf pmd-bin-7.8.0 pmd-dist-7.8.0-bin.zip
    echo "✅ PMD installed successfully"
    cd -
fi

# Add PMD to PATH for this session
export PATH="${PMD_DIR}/bin:${PATH}"

# Check if src/classes directory exists
if [ ! -d "src/classes" ]; then
    echo "❌ src/classes directory not found. Are you in the project root?"
    exit 1
fi

# Create PMD ruleset if it doesn't exist
if [ ! -f "pmd-ruleset.xml" ]; then
    echo "📝 Creating PMD ruleset..."
    cat > pmd-ruleset.xml << 'EOF'
<?xml version="1.0"?>
<ruleset name="CVMA Apex Rules"
         xmlns="http://pmd.sourceforge.net/ruleset/2.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 http://pmd.sourceforge.net/ruleset_2_0_0.xsd">
    <description>CVMA Salesforce Apex PMD Rules</description>
    
    <!-- Security Rules -->
    <rule ref="category/apex/security.xml/ApexCRUDViolation" />
    <rule ref="category/apex/security.xml/ApexSharingViolations" />
    <rule ref="category/apex/security.xml/ApexSOQLInjection" />
    <rule ref="category/apex/security.xml/ApexXSSFromEscapeFalse" />
    
    <!-- Best Practices -->
    <rule ref="category/apex/bestpractices.xml/ApexUnitTestClassShouldHaveAsserts" />
    <rule ref="category/apex/bestpractices.xml/ApexUnitTestShouldNotUseSeeAllDataTrue" />
    <rule ref="category/apex/bestpractices.xml/AvoidGlobalModifier" />
    <rule ref="category/apex/bestpractices.xml/UnusedLocalVariable" />
    
    <!-- Error Prone -->
    <rule ref="category/apex/errorprone.xml/AvoidHardcodingId" />
    <rule ref="category/apex/errorprone.xml/EmptyIfStmt" />
    <rule ref="category/apex/errorprone.xml/EmptyStatementBlock" />
    
    <!-- Performance -->
    <rule ref="category/apex/performance.xml/OperationWithLimitsInLoop" />
    
    <!-- Design -->
    <rule ref="category/apex/design.xml/ExcessiveClassLength">
        <properties>
            <property name="minimum" value="1000" />
        </properties>
    </rule>
    <rule ref="category/apex/design.xml/CyclomaticComplexity">
        <properties>
            <property name="methodReportLevel" value="10" />
        </properties>
    </rule>
</ruleset>
EOF
fi

# Create reports directory
mkdir -p reports

echo "🔄 Running PMD analysis on all Apex classes..."

# Run PMD analysis
pmd check \
    --dir src/classes \
    --rulesets pmd-ruleset.xml \
    --format text \
    --report-file reports/pmd-report.txt \
    --fail-on-violation false \
    --minimum-priority 3 || true

# Generate HTML report
echo "📊 Generating HTML report..."
pmd check \
    --dir src/classes \
    --rulesets pmd-ruleset.xml \
    --format html \
    --report-file reports/pmd-report.html \
    --fail-on-violation false \
    --minimum-priority 3 || true

# Generate JSON report for processing
pmd check \
    --dir src/classes \
    --rulesets pmd-ruleset.xml \
    --format json \
    --report-file reports/pmd-report.json \
    --fail-on-violation false \
    --minimum-priority 3 || true

# Display results
echo ""
echo "📋 PMD Analysis Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -s "reports/pmd-report.txt" ]; then
    echo "❌ Violations found:"
    cat reports/pmd-report.txt
    echo ""
    echo "📊 Summary of violations by priority:"
    echo "High Priority: $(grep -c "Priority.*[12]" reports/pmd-report.txt || echo 0)"
    echo "Medium Priority: $(grep -c "Priority.*3" reports/pmd-report.txt || echo 0)"
    echo "Low Priority: $(grep -c "Priority.*[45]" reports/pmd-report.txt || echo 0)"
else
    echo "✅ No PMD violations found! Excellent code quality!"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Reports generated:"
echo "  - Text Report: reports/pmd-report.txt"
echo "  - HTML Report: reports/pmd-report.html"
echo "  - JSON Report: reports/pmd-report.json"
echo ""
echo "🎉 PMD analysis completed successfully!"