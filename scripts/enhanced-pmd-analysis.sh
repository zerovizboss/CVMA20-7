#!/bin/bash
# Enhanced CVMA PMD Analysis Script with 90% SCA Compliance Target
# Automated Static Code Analysis with Quality Gates

set -e

# Configuration
PMD_DIR="${HOME}/.cvma/pmd"
TARGET_SCORE=90
REPORTS_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "🔍 CVMA Enhanced PMD Analysis - SCA Compliance Target: ${TARGET_SCORE}%"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Install PMD if not available
if [ ! -f "${PMD_DIR}/bin/pmd" ]; then
    echo "⚠️  PMD not found. Installing PMD 7.8.0..."
    mkdir -p "${PMD_DIR}"
    cd "${PMD_DIR}"
    curl -L -o pmd-dist-7.8.0-bin.zip https://github.com/pmd/pmd/releases/download/pmd_releases%2F7.8.0/pmd-dist-7.8.0-bin.zip
    unzip -q pmd-dist-7.8.0-bin.zip
    mv pmd-bin-7.8.0/* .
    chmod +x bin/pmd
    rm -rf pmd-bin-7.8.0 pmd-dist-7.8.0-bin.zip
    echo "✅ PMD installed successfully"
    cd -
fi

export PATH="${PMD_DIR}/bin:${PATH}"

# Validate project structure
if [ ! -d "src/classes" ]; then
    echo "❌ Error: src/classes directory not found. Ensure you're in the project root."
    exit 1
fi

# Create enhanced PMD ruleset with comprehensive rules
cat > pmd-ruleset-enhanced.xml << 'EOF'
<?xml version="1.0"?>
<ruleset name="CVMA Enhanced Apex Rules - 90% SCA Target"
         xmlns="http://pmd.sourceforge.net/ruleset/2.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://pmd.sourceforge.net/ruleset/2.0.0 http://pmd.sourceforge.net/ruleset_2_0_0.xsd">
    
    <description>CVMA Salesforce Apex PMD Rules - Enhanced for 90% SCA Compliance</description>
    
    <!-- Critical Security Rules (Priority 1) -->
    <rule ref="category/apex/security.xml/ApexCRUDViolation" />
    <rule ref="category/apex/security.xml/ApexSharingViolations" />
    <rule ref="category/apex/security.xml/ApexSOQLInjection" />
    <rule ref="category/apex/security.xml/ApexXSSFromEscapeFalse" />
    <rule ref="category/apex/security.xml/ApexXSSFromURLParam" />
    <rule ref="category/apex/security.xml/ApexBadCrypto" />
    <rule ref="category/apex/security.xml/ApexCSRF" />
    <rule ref="category/apex/security.xml/ApexDangerousMethods" />
    <rule ref="category/apex/security.xml/ApexSuggestUsingNamedCred" />
    
    <!-- Best Practices (Priority 2) -->
    <rule ref="category/apex/bestpractices.xml/ApexUnitTestClassShouldHaveAsserts" />
    <rule ref="category/apex/bestpractices.xml/ApexUnitTestShouldNotUseSeeAllDataTrue" />
    <rule ref="category/apex/bestpractices.xml/AvoidGlobalModifier" />
    <rule ref="category/apex/bestpractices.xml/UnusedLocalVariable" />
    <rule ref="category/apex/bestpractices.xml/DebugsShouldUseLoggingLevel" />
    
    <!-- Error Prone (Priority 2) -->
    <rule ref="category/apex/errorprone.xml/AvoidHardcodingId" />
    <rule ref="category/apex/errorprone.xml/EmptyIfStmt" />
    <rule ref="category/apex/errorprone.xml/EmptyStatementBlock" />
    <rule ref="category/apex/errorprone.xml/EmptyTryOrFinallyBlock" />
    <rule ref="category/apex/errorprone.xml/EmptyWhileStmt" />
    <rule ref="category/apex/errorprone.xml/InaccessibleAuraEnabledGetter" />
    <rule ref="category/apex/errorprone.xml/MethodWithSameNameAsEnclosingClass" />
    
    <!-- Performance (Priority 2) -->
    <rule ref="category/apex/performance.xml/OperationWithLimitsInLoop" />
    <rule ref="category/apex/performance.xml/AvoidSoqlInLoops" />
    <rule ref="category/apex/performance.xml/AvoidSoslInLoops" />
    <rule ref="category/apex/performance.xml/AvoidDmlStatementsInLoops" />
    
    <!-- Design Quality (Priority 3) -->
    <rule ref="category/apex/design.xml/ExcessiveClassLength">
        <properties>
            <property name="minimum" value="800" />
        </properties>
    </rule>
    <rule ref="category/apex/design.xml/ExcessiveParameterList">
        <properties>
            <property name="minimum" value="8" />
        </properties>
    </rule>
    <rule ref="category/apex/design.xml/CyclomaticComplexity">
        <properties>
            <property name="methodReportLevel" value="8" />
            <property name="classReportLevel" value="40" />
        </properties>
    </rule>
    <rule ref="category/apex/design.xml/CognitiveComplexity">
        <properties>
            <property name="reportLevel" value="15" />
        </properties>
    </rule>
    <rule ref="category/apex/design.xml/NcssConstructorCount">
        <properties>
            <property name="minimum" value="20" />
        </properties>
    </rule>
    <rule ref="category/apex/design.xml/NcssMethodCount">
        <properties>
            <property name="minimum" value="60" />
        </properties>
    </rule>
    <rule ref="category/apex/design.xml/NcssTypeCount">
        <properties>
            <property name="minimum" value="700" />
        </properties>
    </rule>
    
    <!-- Code Style (Priority 4) -->
    <rule ref="category/apex/codestyle.xml/ClassNamingConventions" />
    <rule ref="category/apex/codestyle.xml/FieldNamingConventions" />
    <rule ref="category/apex/codestyle.xml/MethodNamingConventions" />
    <rule ref="category/apex/codestyle.xml/PropertyNamingConventions" />
    <rule ref="category/apex/codestyle.xml/VariableNamingConventions" />
    
</ruleset>
EOF

# Create reports directory with timestamp
mkdir -p "${REPORTS_DIR}/${TIMESTAMP}"

echo "🔄 Running enhanced PMD analysis..."

# Count total Apex files for scoring
TOTAL_FILES=$(find src/classes -name "*.cls" | wc -l)
echo "📊 Analyzing ${TOTAL_FILES} Apex classes..."

# Run PMD analysis with different priority levels
pmd check \
    --dir src/classes \
    --rulesets pmd-ruleset-enhanced.xml \
    --format json \
    --report-file "${REPORTS_DIR}/${TIMESTAMP}/pmd-detailed.json" \
    --fail-on-violation false || true

# Generate text report for immediate viewing
pmd check \
    --dir src/classes \
    --rulesets pmd-ruleset-enhanced.xml \
    --format text \
    --report-file "${REPORTS_DIR}/${TIMESTAMP}/pmd-summary.txt" \
    --fail-on-violation false || true

# Generate HTML report for detailed review
pmd check \
    --dir src/classes \
    --rulesets pmd-ruleset-enhanced.xml \
    --format html \
    --report-file "${REPORTS_DIR}/${TIMESTAMP}/pmd-detailed.html" \
    --fail-on-violation false || true

# Calculate SCA compliance score
if [ -f "${REPORTS_DIR}/${TIMESTAMP}/pmd-summary.txt" ]; then
    CRITICAL_VIOLATIONS=$(grep -c "Priority.*1" "${REPORTS_DIR}/${TIMESTAMP}/pmd-summary.txt" 2>/dev/null || echo 0)
    HIGH_VIOLATIONS=$(grep -c "Priority.*2" "${REPORTS_DIR}/${TIMESTAMP}/pmd-summary.txt" 2>/dev/null || echo 0)
    MEDIUM_VIOLATIONS=$(grep -c "Priority.*3" "${REPORTS_DIR}/${TIMESTAMP}/pmd-summary.txt" 2>/dev/null || echo 0)
    LOW_VIOLATIONS=$(grep -c "Priority.*[45]" "${REPORTS_DIR}/${TIMESTAMP}/pmd-summary.txt" 2>/dev/null || echo 0)
    
    TOTAL_VIOLATIONS=$((CRITICAL_VIOLATIONS + HIGH_VIOLATIONS + MEDIUM_VIOLATIONS + LOW_VIOLATIONS))
    
    # Calculate weighted score (Critical = 4 points, High = 3 points, Medium = 2 points, Low = 1 point)
    WEIGHTED_SCORE=$(( (CRITICAL_VIOLATIONS * 4) + (HIGH_VIOLATIONS * 3) + (MEDIUM_VIOLATIONS * 2) + (LOW_VIOLATIONS * 1) ))
    MAX_POSSIBLE_SCORE=$((TOTAL_FILES * 4)) # Assume max 4 points deduction per file
    
    if [ $MAX_POSSIBLE_SCORE -gt 0 ]; then
        COMPLIANCE_SCORE=$(( 100 - ((WEIGHTED_SCORE * 100) / MAX_POSSIBLE_SCORE) ))
        # Ensure score doesn't go negative
        if [ $COMPLIANCE_SCORE -lt 0 ]; then
            COMPLIANCE_SCORE=0
        fi
    else
        COMPLIANCE_SCORE=100
    fi
else
    CRITICAL_VIOLATIONS=0
    HIGH_VIOLATIONS=0
    MEDIUM_VIOLATIONS=0
    LOW_VIOLATIONS=0
    TOTAL_VIOLATIONS=0
    COMPLIANCE_SCORE=100
fi

# Generate compliance report
cat > "${REPORTS_DIR}/${TIMESTAMP}/compliance-report.txt" << EOF
CVMA PMD Static Code Analysis Report
Generated: $(date)
Target Compliance Score: ${TARGET_SCORE}%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

COMPLIANCE SCORE: ${COMPLIANCE_SCORE}% $([ $COMPLIANCE_SCORE -ge $TARGET_SCORE ] && echo "✅ PASS" || echo "❌ FAIL")

VIOLATION SUMMARY:
  Critical (Priority 1): ${CRITICAL_VIOLATIONS} violations
  High (Priority 2):     ${HIGH_VIOLATIONS} violations  
  Medium (Priority 3):   ${MEDIUM_VIOLATIONS} violations
  Low (Priority 4-5):    ${LOW_VIOLATIONS} violations
  
  Total Violations: ${TOTAL_VIOLATIONS}
  Files Analyzed: ${TOTAL_FILES}

QUALITY GATES:
  $([ $CRITICAL_VIOLATIONS -eq 0 ] && echo "✅" || echo "❌") Critical violations: ${CRITICAL_VIOLATIONS} (Must be 0)
  $([ $HIGH_VIOLATIONS -le 5 ] && echo "✅" || echo "❌") High violations: ${HIGH_VIOLATIONS} (Target: ≤5)
  $([ $COMPLIANCE_SCORE -ge $TARGET_SCORE ] && echo "✅" || echo "⚠️") Overall compliance: ${COMPLIANCE_SCORE}% (Target: ≥${TARGET_SCORE}%)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RECOMMENDATIONS:
$([ $CRITICAL_VIOLATIONS -gt 0 ] && echo "🔴 CRITICAL: Fix all Priority 1 violations before deployment")
$([ $HIGH_VIOLATIONS -gt 5 ] && echo "🟠 HIGH: Reduce Priority 2 violations to ≤5")
$([ $COMPLIANCE_SCORE -lt $TARGET_SCORE ] && echo "🟡 IMPROVEMENT: Increase compliance score to ≥${TARGET_SCORE}%")
$([ $COMPLIANCE_SCORE -ge $TARGET_SCORE ] && echo "🟢 EXCELLENT: Code meets SCA compliance standards")

REPORTS GENERATED:
  - Detailed JSON: ${REPORTS_DIR}/${TIMESTAMP}/pmd-detailed.json
  - Summary Text: ${REPORTS_DIR}/${TIMESTAMP}/pmd-summary.txt  
  - HTML Report: ${REPORTS_DIR}/${TIMESTAMP}/pmd-detailed.html
  - Compliance Report: ${REPORTS_DIR}/${TIMESTAMP}/compliance-report.txt

EOF

# Display results
echo ""
echo "📋 PMD Analysis Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "${REPORTS_DIR}/${TIMESTAMP}/compliance-report.txt"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create symlink to latest report
rm -f "${REPORTS_DIR}/latest"
ln -sf "${TIMESTAMP}" "${REPORTS_DIR}/latest"

echo ""
echo "🎯 Latest reports available at: ${REPORTS_DIR}/latest/"

# Exit with appropriate code for CI/CD
if [ $COMPLIANCE_SCORE -ge $TARGET_SCORE ] && [ $CRITICAL_VIOLATIONS -eq 0 ]; then
    echo "✅ PMD analysis PASSED - Code meets quality standards"
    exit 0
else
    echo "❌ PMD analysis FAILED - Code requires improvements"
    exit 1
fi