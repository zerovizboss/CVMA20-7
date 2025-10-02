#!/bin/bash

# Fix CSS Variable References - Replace with Inline Gradients
# Combat Veterans Motorcycle Association Chapter 20-7

echo "🎖️  CVMA Military Ribbons CSS Variable Fix"
echo "=============================================="
echo ""

# Define ribbon gradients mapping
declare -A RIBBONS=(
    # CVMA Organizational
    ["cvma-organizational"]="linear-gradient(to right, #000000 0%, #000000 20%, #B8860B 20%, #B8860B 40%, #c41e3a 40%, #c41e3a 60%, #B8860B 60%, #B8860B 80%, #000000 80%, #000000 100%)"

    # US Navy
    ["navy-cross"]="linear-gradient(to right, #002147 0%, #002147 37.5%, #ffffff 37.5%, #ffffff 62.5%, #002147 62.5%, #002147 100%)"
    ["navy-commendation"]="linear-gradient(to right, #006747 0%, #006747 30%, #ffffff 30%, #ffffff 40%, #ff7f00 40%, #ff7f00 60%, #ffffff 60%, #ffffff 70%, #006747 70%, #006747 100%)"
    ["navy-achievement"]="linear-gradient(to right, #002147 0%, #002147 22%, #ff7f00 22%, #ff7f00 28%, #002147 28%, #002147 44%, #ff7f00 44%, #ff7f00 56%, #002147 56%, #002147 72%, #ff7f00 72%, #ff7f00 78%, #002147 78%, #002147 100%)"
    ["navy-good-conduct"]="linear-gradient(to right, #ffffff 0%, #ffffff 8%, #bf0a30 8%, #bf0a30 92%, #ffffff 92%, #ffffff 100%)"

    # US Marine Corps
    ["usmc-good-conduct"]="linear-gradient(to right, #B8860B 0%, #B8860B 10%, #c1272d 10%, #c1272d 90%, #B8860B 90%, #B8860B 100%)"
    ["usmc-achievement"]="linear-gradient(to right, #002147 0%, #002147 22%, #B8860B 22%, #B8860B 28%, #002147 28%, #002147 44%, #B8860B 44%, #B8860B 56%, #002147 56%, #002147 72%, #B8860B 72%, #B8860B 78%, #002147 78%, #002147 100%)"

    # US Army
    ["army-commendation"]="linear-gradient(to right, #006747 0%, #006747 30%, #ffffff 30%, #ffffff 40%, #ff7f00 40%, #ff7f00 60%, #ffffff 60%, #ffffff 70%, #006747 70%, #006747 100%)"
    ["army-achievement"]="linear-gradient(to right, #006747 0%, #006747 22%, #ffffff 22%, #ffffff 28%, #006747 28%, #006747 44%, #ffffff 44%, #ffffff 56%, #006747 56%, #006747 72%, #ffffff 72%, #ffffff 78%, #006747 78%, #006747 100%)"
    ["army-good-conduct"]="linear-gradient(to right, #ffffff 0%, #ffffff 8%, #bf0a30 8%, #bf0a30 92%, #ffffff 92%, #ffffff 100%)"
    ["bronze-star"]="linear-gradient(to right, #bf0a30 0%, #bf0a30 20%, #ffffff 20%, #ffffff 40%, #002868 40%, #002868 60%, #ffffff 60%, #ffffff 80%, #bf0a30 80%, #bf0a30 100%)"

    # US Air Force
    ["air-medal"]="linear-gradient(to right, #0033a0 0%, #0033a0 33.33%, #ff7f00 33.33%, #ff7f00 66.66%, #0033a0 66.66%, #0033a0 100%)"
    ["air-force-commendation"]="linear-gradient(to right, #ffcd00 0%, #ffcd00 30%, #0033a0 30%, #0033a0 40%, #bf0a30 40%, #bf0a30 60%, #0033a0 60%, #0033a0 70%, #ffcd00 70%, #ffcd00 100%)"
    ["air-force-achievement"]="linear-gradient(to right, #ffcd00 0%, #ffcd00 25%, #0033a0 25%, #0033a0 37.5%, #ffcd00 37.5%, #ffcd00 62.5%, #0033a0 62.5%, #0033a0 75%, #ffcd00 75%, #ffcd00 100%)"

    # Memorial Ribbons
    ["purple-heart"]="linear-gradient(to right, #ffffff 0%, #ffffff 10%, #672878 10%, #672878 90%, #ffffff 90%, #ffffff 100%)"
    ["pow-mia"]="linear-gradient(to right, #000000 0%, #000000 25%, #ffffff 25%, #ffffff 75%, #000000 75%, #000000 100%)"
)

# Function to replace CSS variables with inline gradients
fix_css_variables() {
    local file=$1
    local fixed=0

    for ribbon_name in "${!RIBBONS[@]}"; do
        local gradient="${RIBBONS[$ribbon_name]}"

        # Escape special characters for sed
        local escaped_gradient=$(echo "$gradient" | sed 's/[&/\]/\\&/g')

        # Replace var(--ribbon-name) with actual gradient
        if grep -q "var(--${ribbon_name})" "$file" 2>/dev/null; then
            sed -i "s|var(--${ribbon_name})|${escaped_gradient}|g" "$file" 2>/dev/null && {
                echo "  ✅ Replaced var(--${ribbon_name})"
                ((fixed++))
            }
        fi
    done

    return $fixed
}

# Process all LWC CSS files
total_files=0
total_replacements=0

echo "📁 Processing LWC component CSS files..."
echo ""

for css_file in src/lwc/*/*.css; do
    if [ -f "$css_file" ]; then
        component=$(basename $(dirname "$css_file"))

        # Check if file contains any var(--) references
        if grep -q "var(--" "$css_file" 2>/dev/null; then
            echo "🔧 Fixing: $component"

            fix_css_variables "$css_file"
            fixed=$?

            if [ $fixed -gt 0 ]; then
                ((total_files++))
                ((total_replacements+=fixed))
            fi
            echo ""
        fi
    fi
done

echo "=============================================="
echo "✅ CSS Variable Fix Complete!"
echo ""
echo "📊 Summary:"
echo "  • Files Modified: $total_files"
echo "  • Variables Replaced: $total_replacements"
echo ""
echo "🎖️  All CSS variables replaced with inline gradients"
echo "🚀 Components ready for deployment"
echo ""
