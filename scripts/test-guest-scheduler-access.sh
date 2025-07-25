#!/bin/bash

# CVMA Guest User Scheduler Access - Complete Testing Script
# This script runs comprehensive tests to verify guest user access configuration

echo "🚀 Starting CVMA Guest User Scheduler Access Testing..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
    esac
}

# Step 1: Deploy all changes
print_status "INFO" "Step 1: Deploying metadata changes..."

print_status "INFO" "Deploying profiles..."
sf project deploy start --source-dir src/profiles --wait 10 --json > deploy_profiles.json
if [ $? -eq 0 ]; then
    print_status "SUCCESS" "Profiles deployed successfully"
else
    print_status "ERROR" "Profile deployment failed"
    cat deploy_profiles.json
    exit 1
fi

print_status "INFO" "Deploying sharing rules..."
sf project deploy start --source-dir src/sharingRules --wait 10 --json > deploy_sharing.json
if [ $? -eq 0 ]; then
    print_status "SUCCESS" "Sharing rules deployed successfully"
else
    print_status "ERROR" "Sharing rules deployment failed"
    cat deploy_sharing.json
    exit 1
fi

print_status "INFO" "Deploying network configuration..."
sf project deploy start --source-dir src/networks --wait 10 --json > deploy_networks.json
if [ $? -eq 0 ]; then
    print_status "SUCCESS" "Network configuration deployed successfully"
else
    print_status "ERROR" "Network deployment failed"
    cat deploy_networks.json
    exit 1
fi

print_status "INFO" "Deploying site configuration..."
sf project deploy start --source-dir src/sites --wait 10 --json > deploy_sites.json
if [ $? -eq 0 ]; then
    print_status "SUCCESS" "Site configuration deployed successfully"
else
    print_status "ERROR" "Site deployment failed"
    cat deploy_sites.json
    exit 1
fi

print_status "INFO" "Deploying permission sets..."
sf project deploy start --source-dir src/permissionsets --wait 10 --json > deploy_permsets.json
if [ $? -eq 0 ]; then
    print_status "SUCCESS" "Permission sets deployed successfully"
else
    print_status "ERROR" "Permission set deployment failed"
    cat deploy_permsets.json
    exit 1
fi

print_status "INFO" "Deploying test classes..."
sf project deploy start --source-dir src/classes --wait 10 --json > deploy_classes.json
if [ $? -eq 0 ]; then
    print_status "SUCCESS" "Test classes deployed successfully"
else
    print_status "ERROR" "Test class deployment failed"
    cat deploy_classes.json
    exit 1
fi

# Step 2: Run Apex tests
print_status "INFO" "Step 2: Running Apex test suite..."

print_status "INFO" "Running CVMAGuestUserSchedulerAccessTest..."
sf apex run test --class-names CVMAGuestUserSchedulerAccessTest --result-format json --code-coverage --wait 10 > test_results_main.json

if [ $? -eq 0 ]; then
    # Parse test results
    PASSED_TESTS=$(cat test_results_main.json | jq -r '.result.summary.passing // 0')
    FAILED_TESTS=$(cat test_results_main.json | jq -r '.result.summary.failing // 0')
    TOTAL_TESTS=$(cat test_results_main.json | jq -r '.result.summary.testsRan // 0')
    COVERAGE=$(cat test_results_main.json | jq -r '.result.summary.testRunCoverage // "N/A"')
    
    print_status "SUCCESS" "Main test suite completed"
    print_status "INFO" "Tests Run: $TOTAL_TESTS | Passed: $PASSED_TESTS | Failed: $FAILED_TESTS"
    print_status "INFO" "Code Coverage: $COVERAGE%"
    
    if [ "$FAILED_TESTS" != "0" ]; then
        print_status "ERROR" "Some tests failed. Check detailed results:"
        cat test_results_main.json | jq '.result.tests[] | select(.Outcome == "Fail") | {MethodName, Message}'
        exit 1
    fi
else
    print_status "ERROR" "Main test suite failed to execute"
    cat test_results_main.json
    exit 1
fi

print_status "INFO" "Running CVMAExperienceBuilderIntegrationTest..."
sf apex run test --class-names CVMAExperienceBuilderIntegrationTest --result-format json --code-coverage --wait 10 > test_results_integration.json

if [ $? -eq 0 ]; then
    PASSED_TESTS_INT=$(cat test_results_integration.json | jq -r '.result.summary.passing // 0')
    FAILED_TESTS_INT=$(cat test_results_integration.json | jq -r '.result.summary.failing // 0')
    TOTAL_TESTS_INT=$(cat test_results_integration.json | jq -r '.result.summary.testsRan // 0')
    
    print_status "SUCCESS" "Integration test suite completed"
    print_status "INFO" "Tests Run: $TOTAL_TESTS_INT | Passed: $PASSED_TESTS_INT | Failed: $FAILED_TESTS_INT"
    
    if [ "$FAILED_TESTS_INT" != "0" ]; then
        print_status "ERROR" "Some integration tests failed. Check detailed results:"
        cat test_results_integration.json | jq '.result.tests[] | select(.Outcome == "Fail") | {MethodName, Message}'
        exit 1
    fi
else
    print_status "ERROR" "Integration test suite failed to execute"
    cat test_results_integration.json
    exit 1
fi

# Step 3: Validate metadata integrity
print_status "INFO" "Step 3: Validating metadata integrity..."

print_status "INFO" "Checking Guest License User profile..."
sf data query --query "SELECT Id, Name FROM Profile WHERE Name = 'Guest License User'" --result-format json > profile_check.json
PROFILE_EXISTS=$(cat profile_check.json | jq -r '.result.totalSize')

if [ "$PROFILE_EXISTS" == "1" ]; then
    print_status "SUCCESS" "Guest License User profile exists"
else
    print_status "ERROR" "Guest License User profile not found"
    exit 1
fi

print_status "INFO" "Checking Community network..."
sf data query --query "SELECT Id, Name, Status FROM Network WHERE Name = 'Combat Veterams Motorcycle Association'" --result-format json > network_check.json
NETWORK_EXISTS=$(cat network_check.json | jq -r '.result.totalSize')

if [ "$NETWORK_EXISTS" == "1" ]; then
    NETWORK_STATUS=$(cat network_check.json | jq -r '.result.records[0].Status')
    print_status "SUCCESS" "Community network exists with status: $NETWORK_STATUS"
else
    print_status "WARNING" "Community network not found (may not exist in test org)"
fi

print_status "INFO" "Checking Permission Set..."
sf data query --query "SELECT Id, Name FROM PermissionSet WHERE Name = 'CVMA_Guest_Scheduler_Access'" --result-format json > permset_check.json
PERMSET_EXISTS=$(cat permset_check.json | jq -r '.result.totalSize')

if [ "$PERMSET_EXISTS" == "1" ]; then
    print_status "SUCCESS" "CVMA Guest Scheduler Access permission set exists"
else
    print_status "ERROR" "CVMA Guest Scheduler Access permission set not found"
    exit 1
fi

# Step 4: Generate test report
print_status "INFO" "Step 4: Generating test report..."

cat << EOF > CVMA_Test_Report.md
# CVMA Guest User Scheduler Access - Test Report

## Test Execution Summary
- **Date:** $(date)
- **Total Tests Run:** $((TOTAL_TESTS + TOTAL_TESTS_INT))
- **Tests Passed:** $((PASSED_TESTS + PASSED_TESTS_INT))
- **Tests Failed:** $((FAILED_TESTS + FAILED_TESTS_INT))
- **Overall Status:** $([ $((FAILED_TESTS + FAILED_TESTS_INT)) -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")

## Main Test Suite Results
- **Class:** CVMAGuestUserSchedulerAccessTest
- **Tests Run:** $TOTAL_TESTS
- **Passed:** $PASSED_TESTS
- **Failed:** $FAILED_TESTS
- **Code Coverage:** $COVERAGE%

## Integration Test Suite Results  
- **Class:** CVMAExperienceBuilderIntegrationTest
- **Tests Run:** $TOTAL_TESTS_INT
- **Passed:** $PASSED_TESTS_INT
- **Failed:** $FAILED_TESTS_INT

## Metadata Validation
- **Guest License User Profile:** ✅ Exists
- **Community Network:** $([ "$NETWORK_EXISTS" == "1" ] && echo "✅ Exists ($NETWORK_STATUS)" || echo "⚠️  Not Found")
- **Permission Set:** ✅ Exists

## Deployment Status
- **Profiles:** ✅ Deployed
- **Sharing Rules:** ✅ Deployed  
- **Networks:** ✅ Deployed
- **Sites:** ✅ Deployed
- **Permission Sets:** ✅ Deployed
- **Test Classes:** ✅ Deployed

## Next Steps
1. Perform manual testing using the CVMA-Guest-User-Testing-Guide.md
2. Test the Experience Builder site with actual guest user access
3. Verify Scheduler components are working in the community
4. Monitor guest user activity and permissions

EOF

print_status "SUCCESS" "Test report generated: CVMA_Test_Report.md"

# Step 5: Clean up temporary files
rm -f deploy_*.json test_results_*.json profile_check.json network_check.json permset_check.json

# Final summary
echo ""
echo "=================================================="
print_status "SUCCESS" "CVMA Guest User Scheduler Access Testing Complete!"
echo ""
print_status "INFO" "Summary:"
print_status "INFO" "• All metadata deployed successfully"
print_status "INFO" "• $((PASSED_TESTS + PASSED_TESTS_INT)) of $((TOTAL_TESTS + TOTAL_TESTS_INT)) tests passed"
print_status "INFO" "• Configuration validated"
print_status "INFO" "• Test report generated"
echo ""
print_status "INFO" "Next: Run manual tests using CVMA-Guest-User-Testing-Guide.md"
echo "=================================================="