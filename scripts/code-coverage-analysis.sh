#!/bin/bash
# CVMA Automated Code Coverage Analysis with 90% Target
# Salesforce Apex Test Coverage Validation

set -e

# Configuration
TARGET_COVERAGE=90
MIN_CLASS_COVERAGE=75
REPORTS_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
COVERAGE_DIR="${REPORTS_DIR}/${TIMESTAMP}/coverage"

echo "📊 CVMA Code Coverage Analysis - Target: ${TARGET_COVERAGE}%"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create coverage reports directory
mkdir -p "${COVERAGE_DIR}"

# Check Salesforce CLI availability
if ! command -v sf &> /dev/null; then
    echo "❌ Error: Salesforce CLI (sf) not found"
    echo "Please install Salesforce CLI: https://developer.salesforce.com/tools/sfdxcli"
    exit 1
fi

# Verify org connection
echo "🔍 Verifying org connection..."
if ! sf org display --json > "${COVERAGE_DIR}/org-info.json" 2>/dev/null; then
    echo "❌ Error: No default org found or org connection failed"
    echo "Please authenticate with: sf org login web"
    exit 1
fi

ORG_USERNAME=$(cat "${COVERAGE_DIR}/org-info.json" | jq -r '.result.username')
echo "✅ Connected to org: ${ORG_USERNAME}"

# Run all Apex tests and collect coverage data
echo "🧪 Running all Apex tests with code coverage..."
echo "⏳ This may take several minutes for comprehensive test execution..."

# Execute tests with detailed code coverage
sf apex run test \
    --code-coverage \
    --result-format json \
    --output-dir "${COVERAGE_DIR}" \
    --wait 30 > "${COVERAGE_DIR}/test-run-summary.json" || {
    echo "❌ Test execution failed"
    cat "${COVERAGE_DIR}/test-run-summary.json" 2>/dev/null || echo "No test summary available"
    exit 1
}

# Parse test results
if [ ! -f "${COVERAGE_DIR}/test-run-summary.json" ]; then
    echo "❌ Error: Test results not found"
    exit 1
fi

TEST_RUN_ID=$(cat "${COVERAGE_DIR}/test-run-summary.json" | jq -r '.result.testRunId // empty')

if [ -z "$TEST_RUN_ID" ]; then
    echo "❌ Error: Could not extract test run ID"
    exit 1
fi

echo "📋 Test Run ID: ${TEST_RUN_ID}"

# Get detailed code coverage results
sf apex get test --test-run-id "$TEST_RUN_ID" --code-coverage --result-format json > "${COVERAGE_DIR}/detailed-coverage.json"

# Parse coverage data
TOTAL_LINES=$(cat "${COVERAGE_DIR}/detailed-coverage.json" | jq '.result.coverage.totalLines // 0')
COVERED_LINES=$(cat "${COVERAGE_DIR}/detailed-coverage.json" | jq '.result.coverage.coveredLines // 0')

if [ "$TOTAL_LINES" -gt 0 ]; then
    OVERALL_COVERAGE=$((COVERED_LINES * 100 / TOTAL_LINES))
else
    OVERALL_COVERAGE=0
fi

# Extract individual class coverage
cat "${COVERAGE_DIR}/detailed-coverage.json" | jq -r '.result.coverage.coverage[] | select(.name | test(".*Test.*") | not) | "\(.name),\(.totalLines),\(.coveredLines),\(if .totalLines > 0 then (.coveredLines * 100 / .totalLines | floor) else 0 end)"' > "${COVERAGE_DIR}/class-coverage.csv"

# Count classes below minimum coverage
LOW_COVERAGE_CLASSES=0
TOTAL_CLASSES=0
ZERO_COVERAGE_CLASSES=0

while IFS=',' read -r class_name total_lines covered_lines coverage_pct; do
    if [ -n "$class_name" ]; then
        TOTAL_CLASSES=$((TOTAL_CLASSES + 1))
        if [ "$coverage_pct" -lt "$MIN_CLASS_COVERAGE" ]; then
            LOW_COVERAGE_CLASSES=$((LOW_COVERAGE_CLASSES + 1))
        fi
        if [ "$coverage_pct" -eq 0 ]; then
            ZERO_COVERAGE_CLASSES=$((ZERO_COVERAGE_CLASSES + 1))
        fi
    fi
done < "${COVERAGE_DIR}/class-coverage.csv"

# Extract test results summary
TOTAL_TESTS=$(cat "${COVERAGE_DIR}/detailed-coverage.json" | jq '.result.tests | length')
PASSED_TESTS=$(cat "${COVERAGE_DIR}/detailed-coverage.json" | jq '[.result.tests[] | select(.outcome == "Pass")] | length')
FAILED_TESTS=$(cat "${COVERAGE_DIR}/detailed-coverage.json" | jq '[.result.tests[] | select(.outcome != "Pass")] | length')

# Generate detailed coverage report
cat > "${COVERAGE_DIR}/coverage-report.txt" << EOF
CVMA Salesforce Code Coverage Analysis Report
Generated: $(date)
Target Coverage: ${TARGET_COVERAGE}%
Minimum Class Coverage: ${MIN_CLASS_COVERAGE}%
Org: ${ORG_USERNAME}
Test Run ID: ${TEST_RUN_ID}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

OVERALL COVERAGE: ${OVERALL_COVERAGE}% $([ $OVERALL_COVERAGE -ge $TARGET_COVERAGE ] && echo "✅ PASS" || echo "❌ FAIL")

COVERAGE DETAILS:
  Total Lines of Code: ${TOTAL_LINES}
  Covered Lines: ${COVERED_LINES}
  Uncovered Lines: $((TOTAL_LINES - COVERED_LINES))

CLASS COVERAGE ANALYSIS:
  Total Classes Analyzed: ${TOTAL_CLASSES}
  Classes Below ${MIN_CLASS_COVERAGE}% Coverage: ${LOW_COVERAGE_CLASSES}
  Classes with Zero Coverage: ${ZERO_COVERAGE_CLASSES}

TEST EXECUTION SUMMARY:
  Total Tests: ${TOTAL_TESTS}
  Passed Tests: ${PASSED_TESTS}
  Failed Tests: ${FAILED_TESTS}
  Success Rate: $([ $TOTAL_TESTS -gt 0 ] && echo "$((PASSED_TESTS * 100 / TOTAL_TESTS))%" || echo "N/A")

QUALITY GATES:
  $([ $OVERALL_COVERAGE -ge $TARGET_COVERAGE ] && echo "✅" || echo "❌") Overall coverage ≥${TARGET_COVERAGE}%: ${OVERALL_COVERAGE}%
  $([ $FAILED_TESTS -eq 0 ] && echo "✅" || echo "❌") All tests passing: ${FAILED_TESTS} failed
  $([ $ZERO_COVERAGE_CLASSES -eq 0 ] && echo "✅" || echo "⚠️") No zero coverage classes: ${ZERO_COVERAGE_CLASSES} found
  $([ $LOW_COVERAGE_CLASSES -eq 0 ] && echo "✅" || echo "⚠️") All classes ≥${MIN_CLASS_COVERAGE}% coverage: ${LOW_COVERAGE_CLASSES} below threshold

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RECOMMENDATIONS:
$([ $OVERALL_COVERAGE -lt $TARGET_COVERAGE ] && echo "🔴 CRITICAL: Increase overall test coverage to ≥${TARGET_COVERAGE}%")
$([ $FAILED_TESTS -gt 0 ] && echo "🔴 CRITICAL: Fix ${FAILED_TESTS} failing test(s)")
$([ $ZERO_COVERAGE_CLASSES -gt 0 ] && echo "🟠 HIGH: Add test coverage for ${ZERO_COVERAGE_CLASSES} untested class(es)")
$([ $LOW_COVERAGE_CLASSES -gt 0 ] && echo "🟡 MEDIUM: Improve coverage for ${LOW_COVERAGE_CLASSES} class(es) below ${MIN_CLASS_COVERAGE}%")
$([ $OVERALL_COVERAGE -ge $TARGET_COVERAGE ] && [ $FAILED_TESTS -eq 0 ] && echo "🟢 EXCELLENT: Code meets coverage and quality standards")

LOW COVERAGE CLASSES (Below ${MIN_CLASS_COVERAGE}%):
EOF

# Add low coverage classes to report
if [ "$LOW_COVERAGE_CLASSES" -gt 0 ]; then
    echo "" >> "${COVERAGE_DIR}/coverage-report.txt"
    while IFS=',' read -r class_name total_lines covered_lines coverage_pct; do
        if [ -n "$class_name" ] && [ "$coverage_pct" -lt "$MIN_CLASS_COVERAGE" ]; then
            echo "  - ${class_name}: ${coverage_pct}% (${covered_lines}/${total_lines} lines)" >> "${COVERAGE_DIR}/coverage-report.txt"
        fi
    done < "${COVERAGE_DIR}/class-coverage.csv"
fi

# Add failed tests to report if any
if [ "$FAILED_TESTS" -gt 0 ]; then
    echo "" >> "${COVERAGE_DIR}/coverage-report.txt"
    echo "FAILED TESTS:" >> "${COVERAGE_DIR}/coverage-report.txt"
    cat "${COVERAGE_DIR}/detailed-coverage.json" | jq -r '.result.tests[] | select(.outcome != "Pass") | "  - \(.name): \(.outcome) - \(.message // "No message")"' >> "${COVERAGE_DIR}/coverage-report.txt"
fi

cat >> "${COVERAGE_DIR}/coverage-report.txt" << EOF

REPORTS GENERATED:
  - Coverage Summary: ${COVERAGE_DIR}/coverage-report.txt
  - Detailed JSON: ${COVERAGE_DIR}/detailed-coverage.json
  - Class Coverage CSV: ${COVERAGE_DIR}/class-coverage.csv
  - Test Run Summary: ${COVERAGE_DIR}/test-run-summary.json

EOF

# Generate HTML coverage report
cat > "${COVERAGE_DIR}/coverage-report.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>CVMA Code Coverage Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 15px; border-radius: 5px; }
        .pass { color: #28a745; font-weight: bold; }
        .fail { color: #dc3545; font-weight: bold; }
        .warn { color: #ffc107; font-weight: bold; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .coverage-bar { background: #e9ecef; width: 200px; height: 20px; border-radius: 10px; display: inline-block; }
        .coverage-fill { height: 100%; border-radius: 10px; }
        .high-coverage { background: #28a745; }
        .medium-coverage { background: #ffc107; }
        .low-coverage { background: #dc3545; }
    </style>
</head>
<body>
    <div class="header">
        <h1>CVMA Code Coverage Analysis Report</h1>
        <p><strong>Generated:</strong> $(date)</p>
        <p><strong>Overall Coverage:</strong> <span class="$([ $OVERALL_COVERAGE -ge $TARGET_COVERAGE ] && echo "pass" || echo "fail")">${OVERALL_COVERAGE}%</span></p>
        <p><strong>Target:</strong> ${TARGET_COVERAGE}%</p>
    </div>
    
    <h2>Coverage Summary</h2>
    <div class="coverage-bar">
        <div class="coverage-fill $([ $OVERALL_COVERAGE -ge 80 ] && echo "high-coverage" || ([ $OVERALL_COVERAGE -ge 60 ] && echo "medium-coverage" || echo "low-coverage"))" style="width: ${OVERALL_COVERAGE}%"></div>
    </div>
    <p>${OVERALL_COVERAGE}% (${COVERED_LINES}/${TOTAL_LINES} lines)</p>
    
    <h2>Quality Gates</h2>
    <ul>
        <li>Overall Coverage ≥${TARGET_COVERAGE}%: <span class="$([ $OVERALL_COVERAGE -ge $TARGET_COVERAGE ] && echo "pass" || echo "fail")">$([ $OVERALL_COVERAGE -ge $TARGET_COVERAGE ] && echo "PASS" || echo "FAIL")</span></li>
        <li>All Tests Passing: <span class="$([ $FAILED_TESTS -eq 0 ] && echo "pass" || echo "fail")">$([ $FAILED_TESTS -eq 0 ] && echo "PASS" || echo "FAIL")</span></li>
        <li>No Zero Coverage Classes: <span class="$([ $ZERO_COVERAGE_CLASSES -eq 0 ] && echo "pass" || echo "warn")">$([ $ZERO_COVERAGE_CLASSES -eq 0 ] && echo "PASS" || echo "WARNING")</span></li>
    </ul>
    
    <h2>Test Results</h2>
    <p><strong>Total Tests:</strong> ${TOTAL_TESTS}</p>
    <p><strong>Passed:</strong> <span class="pass">${PASSED_TESTS}</span></p>
    <p><strong>Failed:</strong> <span class="fail">${FAILED_TESTS}</span></p>
    
</body>
</html>
EOF

# Display results
echo ""
echo "📊 Code Coverage Analysis Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "${COVERAGE_DIR}/coverage-report.txt"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create symlink to latest report
rm -f "${REPORTS_DIR}/latest-coverage"
ln -sf "${TIMESTAMP}/coverage" "${REPORTS_DIR}/latest-coverage"

echo ""
echo "📈 Latest coverage reports available at: ${REPORTS_DIR}/latest-coverage/"

# Exit with appropriate code for CI/CD
if [ $OVERALL_COVERAGE -ge $TARGET_COVERAGE ] && [ $FAILED_TESTS -eq 0 ]; then
    echo "✅ Code coverage analysis PASSED - Meets quality standards"
    exit 0
else
    echo "❌ Code coverage analysis FAILED - Requires improvements"
    exit 1
fi