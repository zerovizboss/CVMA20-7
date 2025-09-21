#!/bin/bash
# CVMA Apex Test Validation Script
# Ensures all Apex classes have corresponding test classes

set -e

echo "🧪 Validating Apex test classes..."

# Get all changed Apex class files (not test classes, triggers, or certain patterns)
APEX_CLASSES=$(git diff --cached --name-only --diff-filter=ACM | grep -E 'src/classes/.*\.cls$' | grep -v -E '(Test\.cls$|Mock\.cls$|Helper\.cls$|Util\.cls$)' || true)

if [ -z "$APEX_CLASSES" ]; then
    echo "ℹ️  No non-test Apex classes changed. Skipping test validation."
    exit 0
fi

MISSING_TESTS=""
INVALID_TESTS=""

echo "📄 Checking test coverage for:"
for class_file in $APEX_CLASSES; do
    # Extract class name from file path
    class_name=$(basename "$class_file" .cls)

    # Skip certain controller patterns that might not need tests (like pure data classes)
    if [[ "$class_name" =~ ^CVMA.*Controller$ ]]; then
        echo "  - $class_name (Controller - requires test)"
    elif [[ "$class_name" =~ ^CVMA.*Authenticator$ ]]; then
        echo "  - $class_name (Authenticator - requires test)"
    else
        echo "  - $class_name"
    fi

    # Check if corresponding test class exists
    test_file="src/classes/${class_name}Test.cls"

    if [ ! -f "$test_file" ]; then
        MISSING_TESTS+="$class_name "
        continue
    fi
    
    # Validate test class structure
    if ! grep -q "@IsTest" "$test_file"; then
        INVALID_TESTS+="$class_name (missing @IsTest annotation) "
        continue
    fi
    
    # Check if test class has at least one test method (comprehensive patterns)
    if ! grep -qE "(@IsTest\s+(static\s+)?void|static\s+void\s+test|testMethod|@TestSetup)" "$test_file"; then
        # Additional check for common test patterns
        if ! grep -qE "(void\s+test\w+|@IsTest\s*$)" "$test_file"; then
            INVALID_TESTS+="$class_name (no test methods found) "
            continue
        fi
    fi
    
    # Check for CVMATestDataFactory usage in new tests
    if grep -q "CVMATestDataFactory" "$test_file"; then
        echo "    ✅ Uses CVMATestDataFactory"
    else
        echo "    ⚠️  Consider using CVMATestDataFactory for consistent test data"
    fi
done

# Report results
if [ -n "$MISSING_TESTS" ]; then
    echo ""
    echo "❌ Missing test classes for:"
    for class in $MISSING_TESTS; do
        echo "  - ${class}Test.cls"
    done
    echo ""
    echo "📝 Please create test classes following this pattern:"
    echo "   @IsTest"
    echo "   public class ${class}Test {"
    echo "       @IsTest"
    echo "       static void testMethodName() {"
    echo "           // Test implementation using CVMATestDataFactory"
    echo "       }"
    echo "   }"
fi

if [ -n "$INVALID_TESTS" ]; then
    echo ""
    echo "❌ Invalid test classes:"
    for issue in $INVALID_TESTS; do
        echo "  - $issue"
    done
fi

# Check for proper test data patterns in changed test files
CHANGED_TESTS=$(git diff --cached --name-only --diff-filter=ACM | grep -E 'Test\.cls$' || true)
if [ -n "$CHANGED_TESTS" ]; then
    echo ""
    echo "🔍 Checking test data patterns in changed test files..."
    
    for test_file in $CHANGED_TESTS; do
        test_name=$(basename "$test_file" .cls)
        echo "  - $test_name"
        
        # Check for seeAllData usage
        if grep -q "seeAllData.*=.*true" "$test_file"; then
            echo "    ❌ Uses seeAllData=true (not recommended)"
            INVALID_TESTS+="$test_name (uses seeAllData=true) "
        fi
        
        # Check for System.runAs usage
        if grep -q "System.runAs" "$test_file"; then
            echo "    ✅ Uses System.runAs for context testing"
        fi
        
        # Check for proper assertions
        if ! grep -qE "(System\.assert|Assert\.|System\.assertEquals|System\.assertNotEquals)" "$test_file"; then
            echo "    ⚠️  No assertions found - tests should verify results"
        fi
    done
fi

# Fail if there are issues
if [ -n "$MISSING_TESTS" ] || [ -n "$INVALID_TESTS" ]; then
    echo ""
    echo "🛠️  Please address the test issues above before committing."
    echo "📚 See CLAUDE.md for CVMA testing patterns and best practices."
    exit 1
fi

echo "✅ All Apex classes have valid test coverage!"
echo "🎉 Test validation completed successfully!"