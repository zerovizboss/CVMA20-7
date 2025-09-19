#!/bin/bash
# CVMA Naming Convention Validation Script
# Ensures all components follow CVMA naming standards

set -e

echo "📝 Validating CVMA naming conventions..."

# Get changed Apex files
APEX_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(cls|trigger)$' || true)

if [ -z "$APEX_FILES" ]; then
    echo "ℹ️  No Apex files changed. Skipping naming validation."
    exit 0
fi

NAMING_VIOLATIONS=""

echo "🔍 Checking naming conventions in:"
for file in $APEX_FILES; do
    filename=$(basename "$file" .cls)
    filename=$(basename "$filename" .trigger)
    echo "  - $filename"
    
    # Check if it's a test file
    IS_TEST_FILE=$(echo "$filename" | grep -E 'Test$' || true)
    
    # CVMA prefix validation for non-test, non-standard classes
    if [ -z "$IS_TEST_FILE" ]; then
        # Skip standard patterns and utility classes
        if [[ ! "$filename" =~ ^(MyIterable|OperatingHours|ServiceTerritory|WorkType|WorkOrder|ServiceAppointment|Case|Event|Contact|Account|User|Profile)$ ]]; then
            if [[ ! "$filename" =~ ^CVMA ]]; then
                NAMING_VIOLATIONS+="$filename: Should start with 'CVMA' prefix\n"
            fi
        fi
    else
        # Test class validation
        base_class=$(echo "$filename" | sed 's/Test$//')
        if [[ "$base_class" =~ ^CVMA ]] && [[ ! "$filename" =~ ^CVMATest ]] && [[ ! "$filename" =~ ^CVMA.*Test$ ]]; then
            NAMING_VIOLATIONS+="$filename: Test class should follow CVMAClassNameTest pattern\n"
        fi
    fi
    
    # Check class name conventions inside the file
    if [[ "$file" == *.cls ]]; then
        # Extract class declaration
        CLASS_DECLARATION=$(grep -E "^(public|global|private).*class" "$file" | head -1 || true)
        
        if [ -n "$CLASS_DECLARATION" ]; then
            # Extract class name from declaration
            CLASS_NAME=$(echo "$CLASS_DECLARATION" | sed -E 's/.*class\s+([A-Za-z0-9_]+).*/\1/')
            
            if [ "$CLASS_NAME" != "$filename" ]; then
                NAMING_VIOLATIONS+="$filename: Class name '$CLASS_NAME' doesn't match filename\n"
            fi
            
            # Check for proper PascalCase
            if [[ ! "$CLASS_NAME" =~ ^[A-Z][a-zA-Z0-9]*$ ]]; then
                NAMING_VIOLATIONS+="$filename: Class name should be in PascalCase\n"
            fi
        fi
        
        # Check method naming conventions
        METHOD_VIOLATIONS=$(grep -nE "^\s*(public|private|global)\s+(static\s+)?\w+\s+[a-z][a-zA-Z0-9_]*\s*\(" "$file" | grep -v "get\|set\|is" || true)
        if [ -n "$METHOD_VIOLATIONS" ]; then
            # Check if methods follow camelCase (starting with lowercase)
            while IFS= read -r line; do
                METHOD_NAME=$(echo "$line" | sed -E 's/.*\s([a-zA-Z_][a-zA-Z0-9_]*)\s*\(.*/\1/')
                if [[ ! "$METHOD_NAME" =~ ^[a-z][a-zA-Z0-9]*$ ]] && [[ ! "$METHOD_NAME" =~ ^(get|set|is)[A-Z] ]]; then
                    NAMING_VIOLATIONS+="$filename: Method '$METHOD_NAME' should be in camelCase\n"
                fi
            done <<< "$METHOD_VIOLATIONS"
        fi
        
        # Check variable naming conventions
        VARIABLE_VIOLATIONS=$(grep -nE "^\s+\w+\s+[A-Z][a-zA-Z0-9_]*\s*=" "$file" || true)
        if [ -n "$VARIABLE_VIOLATIONS" ]; then
            echo "    ⚠️  Variables should start with lowercase (camelCase)"
        fi
    fi
    
    # Check trigger naming conventions
    if [[ "$file" == *.trigger ]]; then
        if [[ ! "$filename" =~ ^CVMA.*Trigger$ ]]; then
            NAMING_VIOLATIONS+="$filename: Trigger should follow CVMAObjectNameTrigger pattern\n"
        fi
    fi
    
    # Positive feedback
    if [[ "$filename" =~ ^CVMA ]]; then
        echo "    ✅ Follows CVMA naming prefix"
    fi
    
    if [ -n "$IS_TEST_FILE" ] && [[ "$filename" =~ ^CVMA.*Test$ ]]; then
        echo "    ✅ Test class follows naming convention"
    fi
done

# Report violations
if [ -n "$NAMING_VIOLATIONS" ]; then
    echo ""
    echo "❌ Naming convention violations found:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "$NAMING_VIOLATIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 CVMA Naming Convention Guide:"
    echo ""
    echo "🏗️  Classes:"
    echo "   - Custom classes: CVMAClassName (PascalCase)"
    echo "   - Test classes: CVMAClassNameTest"
    echo "   - Controllers: CVMAModuleController"
    echo "   - Utilities: CVMAModuleHelper/Utility"
    echo ""
    echo "🔧 Methods & Variables:"
    echo "   - Methods: methodName (camelCase)"
    echo "   - Variables: variableName (camelCase)" 
    echo "   - Constants: CONSTANT_NAME (UPPER_SNAKE_CASE)"
    echo ""
    echo "⚡ Triggers:"
    echo "   - Triggers: CVMAObjectNameTrigger"
    echo ""
    echo "📚 See CLAUDE.md for complete naming standards."
    exit 1
fi

echo "✅ All naming conventions validated successfully!"
echo "📝 Code follows CVMA naming standards!"
echo "🎉 Naming validation completed!"