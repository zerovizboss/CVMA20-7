#!/bin/bash
# CVMA Security Pattern Validation Script
# Ensures all Apex code follows CVMA security best practices

set -e

echo "🔒 Running security pattern validation..."

# Get changed Apex files
APEX_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(cls|trigger)$' || true)

if [ -z "$APEX_FILES" ]; then
    echo "ℹ️  No Apex files changed. Skipping security validation."
    exit 0
fi

SECURITY_VIOLATIONS=""

echo "🔍 Checking security patterns in:"
for file in $APEX_FILES; do
    echo "  - $file"
    
    # Skip test files for some checks
    IS_TEST_FILE=$(echo "$file" | grep -E 'Test\.cls$' || true)
    
    # Check for WITH SECURITY_ENFORCED in SOQL queries (skip test files)
    if [ -z "$IS_TEST_FILE" ]; then
        # Find SOQL queries and check if WITH SECURITY_ENFORCED exists in the same context
        # Use awk to check for WITH SECURITY_ENFORCED within 10 lines after SELECT
        if grep -n "SELECT.*FROM" "$file" | grep -v "//" | grep -v "\*" > /dev/null; then
            # For each SELECT found, check if WITH SECURITY_ENFORCED follows within reasonable range
            QUERY_LINES=$(grep -n "SELECT.*FROM" "$file" | grep -v "//" | grep -v "\*" | cut -d: -f1)
            for line_num in $QUERY_LINES; do
                # Check 10 lines after the SELECT for WITH SECURITY_ENFORCED
                END_LINE=$((line_num + 10))
                if ! sed -n "${line_num},${END_LINE}p" "$file" | grep -q "WITH SECURITY_ENFORCED"; then
                    SECURITY_VIOLATIONS+="$file: SOQL query at line $line_num without WITH SECURITY_ENFORCED\n"
                fi
            done
        fi
    fi
    
    # Check for hardcoded IDs
    if grep -nE "Id.*=.*'[a-zA-Z0-9]{15,18}'" "$file" > /dev/null; then
        SECURITY_VIOLATIONS+="$file: Contains hardcoded Salesforce IDs\n"
    fi
    
    # Check for potential SOQL injection
    if grep -n "String.*query.*=.*'.*SELECT" "$file" | grep -v "WITH SECURITY_ENFORCED" > /dev/null; then
        SECURITY_VIOLATIONS+="$file: Potential SOQL injection vulnerability\n"
    fi
    
    # Check for missing sharing keywords (skip test files)
    if [ -z "$IS_TEST_FILE" ] && grep -q "public class" "$file"; then
        if ! grep -qE "(with sharing|without sharing|inherited sharing)" "$file"; then
            SECURITY_VIOLATIONS+="$file: Missing sharing declaration (with/without/inherited sharing)\n"
        fi
    fi
    
    # Check for CVMAErrorHandler usage in non-test files
    if [ -z "$IS_TEST_FILE" ] && grep -q "public class" "$file"; then
        # Look for exception handling without CVMAErrorHandler
        if grep -q "catch.*Exception" "$file" && ! grep -q "CVMAErrorHandler" "$file"; then
            echo "    ⚠️  Consider using CVMAErrorHandler for exception handling"
        fi
    fi
    
    # Check for input sanitization in controllers
    if [[ "$file" == *"Controller"* ]] && [ -z "$IS_TEST_FILE" ]; then
        if grep -q "String.*=.*ApexPages\.currentPage()" "$file" && ! grep -q "sanitize" "$file"; then
            SECURITY_VIOLATIONS+="$file: Missing input sanitization for user parameters\n"
        fi
    fi
    
    # Check for proper test data usage in test files
    if [ -n "$IS_TEST_FILE" ]; then
        if grep -q "seeAllData.*=.*true" "$file"; then
            SECURITY_VIOLATIONS+="$file: Test class uses seeAllData=true (security risk)\n"
        fi
    fi
    
    # Check for debug statements with sensitive data
    if grep -nE "System\.debug.*password|System\.debug.*token|System\.debug.*key" "$file" > /dev/null; then
        SECURITY_VIOLATIONS+="$file: Debug statements may contain sensitive information\n"
    fi
    
    # Positive checks
    if grep -q "WITH SECURITY_ENFORCED" "$file"; then
        echo "    ✅ Uses WITH SECURITY_ENFORCED"
    fi
    
    if grep -q "CVMAErrorHandler" "$file"; then
        echo "    ✅ Uses CVMAErrorHandler framework"
    fi
    
    if grep -qE "(with sharing|inherited sharing)" "$file"; then
        echo "    ✅ Proper sharing declaration"
    fi
done

# Report violations
if [ -n "$SECURITY_VIOLATIONS" ]; then
    echo ""
    echo "❌ Security violations found:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "$SECURITY_VIOLATIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🔧 Security Remediation Guide:"
    echo "1. Add 'WITH SECURITY_ENFORCED' to all SOQL queries"
    echo "2. Use CVMAErrorHandler.validateCRUDPermissions() before data operations"
    echo "3. Sanitize user input with CVMAErrorHandler.sanitizeInput()"
    echo "4. Declare proper sharing keywords: 'with sharing', 'without sharing', or 'inherited sharing'"
    echo "5. Remove hardcoded IDs - use custom metadata or settings instead"
    echo "6. Implement proper exception handling using CVMAErrorHandler framework"
    echo ""
    echo "📚 See CLAUDE.md for CVMA security best practices."
    exit 1
fi

echo "✅ All security patterns validated successfully!"
echo "🛡️  Code follows CVMA security best practices!"
echo "🎉 Security scan completed!"