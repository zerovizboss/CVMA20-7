#!/bin/bash

# CVMA Training Deployment Validation Script
# Purpose: Comprehensive testing of site-specific training components

echo "🏍️ CVMA Training Deployment Validation - Chapter 20-7"
echo "Testing revolutionary site-specific training experience..."
echo ""

# Check if Salesforce CLI is available
if ! command -v sf &> /dev/null; then
    echo "❌ Salesforce CLI not found. Please install sf CLI."
    exit 1
fi

echo "✅ Salesforce CLI available"

# Check org connection
echo "🔗 Checking Salesforce org connection..."
if sf org display --target-org cvma &> /dev/null; then
    echo "✅ Connected to CVMA org"
else
    echo "❌ Cannot connect to CVMA org. Please check authentication."
    exit 1
fi

echo ""
echo "📋 Component Validation Checklist"
echo "=================================="

# Function to check if component exists
check_component() {
    local component_name=$1
    local component_type=$2

    echo -n "Checking $component_name... "

    if sf data query --query "SELECT Id, DeveloperName FROM $component_type WHERE DeveloperName = '$component_name'" --target-org cvma | grep -q "$component_name"; then
        echo "✅ Found"
        return 0
    else
        echo "❌ Not found"
        return 1
    fi
}

# Check LWC components
echo ""
echo "🔧 Lightning Web Components:"
echo "----------------------------"

components_found=0
total_components=4

# Note: LWC metadata is stored differently, so we'll check for the source files
lwc_components=("cvmaCebTrainingHub" "cvmaMemberTrainingPortal" "cvmaHelpCenterPortal" "cvmaTechnicalDocsPortal")

for component in "${lwc_components[@]}"; do
    echo -n "Checking LWC $component... "
    if [ -f "src/lwc/$component/$component.js" ]; then
        echo "✅ Source file exists"
        ((components_found++))
    else
        echo "❌ Source file missing"
    fi
done

echo ""
echo "📊 Component Status: $components_found/$total_components components ready"

# Check Apex controllers
echo ""
echo "⚡ Apex Controllers:"
echo "-------------------"

apex_controllers=("CVMADocumentSharingController" "CVMADocumentSharingControllerTest")
controllers_found=0
total_controllers=2

for controller in "${apex_controllers[@]}"; do
    echo -n "Checking Apex $controller... "
    if [ -f "src/classes/$controller.cls" ]; then
        echo "✅ Source file exists"
        ((controllers_found++))
    else
        echo "❌ Source file missing"
    fi
done

echo ""
echo "📊 Controller Status: $controllers_found/$total_controllers controllers ready"

# Check Experience Cloud sites
echo ""
echo "🌐 Experience Cloud Sites:"
echo "-------------------------"

sites=("CEB1" "Combat_Veterams_Motorcycle_Association1" "Default_Help_Center1")
sites_found=0
total_sites=3

for site in "${sites[@]}"; do
    echo -n "Checking site $site... "
    if [ -f "src/experiences/$site.site-meta.xml" ]; then
        echo "✅ Configuration exists"
        ((sites_found++))
    else
        echo "❌ Configuration missing"
    fi
done

echo ""
echo "📊 Site Status: $sites_found/$total_sites sites configured"

# Check training content organization
echo ""
echo "📚 Training Content Organization:"
echo "--------------------------------"

content_areas=("sites/ceb-site/training-content" "sites/member-site/training-content" "sites/help-center-site/training-content" "sites/main-technical-site/training-content")
content_found=0
total_content_areas=4

for area in "${content_areas[@]}"; do
    echo -n "Checking $area... "
    if [ -d "$area" ] && [ "$(find "$area" -name "*.md" | wc -l)" -gt 0 ]; then
        doc_count=$(find "$area" -name "*.md" | wc -l)
        echo "✅ $doc_count documents"
        ((content_found++))
    else
        echo "❌ No documents found"
    fi
done

echo ""
echo "📊 Content Status: $content_found/$total_content_areas content areas populated"

# Check shared components
echo ""
echo "🔄 Shared Components:"
echo "--------------------"

shared_components=("shared/components/training")
shared_found=0
total_shared=1

for shared in "${shared_components[@]}"; do
    echo -n "Checking $shared... "
    if [ -d "$shared" ] && [ "$(find "$shared" -name "*.js" | wc -l)" -gt 0 ]; then
        echo "✅ Components available"
        ((shared_found++))
    else
        echo "❌ Components missing"
    fi
done

echo ""
echo "📊 Shared Status: $shared_found/$total_shared shared components ready"

# Test org accessibility
echo ""
echo "🌐 Org Access Validation:"
echo "-------------------------"

echo -n "Testing org accessibility... "
if sf org open --target-org cvma --url-only &> /dev/null; then
    echo "✅ Org accessible"

    # Get org URL for reference
    org_url=$(sf org open --target-org cvma --url-only 2>/dev/null | grep -o 'https://[^/]*' | head -1)
    if [ ! -z "$org_url" ]; then
        echo "🔗 Org URL: $org_url"
    fi
else
    echo "❌ Org access issues"
fi

# Calculate overall readiness score
echo ""
echo "🏆 DEPLOYMENT READINESS ASSESSMENT"
echo "=================================="

total_score=$((components_found + controllers_found + sites_found + content_found + shared_found))
max_score=$((total_components + total_controllers + total_sites + total_content_areas + total_shared))
percentage=$((total_score * 100 / max_score))

echo "📊 Overall Readiness: $total_score/$max_score ($percentage%)"

if [ $percentage -ge 90 ]; then
    echo "🎯 Status: ✅ READY FOR DEPLOYMENT"
    echo ""
    echo "🚀 Next Steps:"
    echo "1. Open Salesforce org: sf org open --target-org cvma"
    echo "2. Navigate to Setup → Digital Experiences → All Sites"
    echo "3. Configure components following EXPERIENCE-CLOUD-CONFIGURATION-GUIDE.md"
    echo "4. Test user journeys on each site"
    echo "5. Enable for production use"
elif [ $percentage -ge 75 ]; then
    echo "⚠️ Status: 🔶 MOSTLY READY (minor issues to address)"
    echo ""
    echo "🔧 Recommended Actions:"
    echo "1. Review missing components above"
    echo "2. Deploy any missing elements"
    echo "3. Re-run validation script"
elif [ $percentage -ge 50 ]; then
    echo "⚠️ Status: 🔶 PARTIAL DEPLOYMENT (significant issues to address)"
    echo ""
    echo "🔧 Required Actions:"
    echo "1. Deploy missing critical components"
    echo "2. Organize missing training content"
    echo "3. Re-run validation script"
else
    echo "❌ Status: 🔴 NOT READY (major issues to resolve)"
    echo ""
    echo "🔧 Critical Actions Required:"
    echo "1. Review deployment process"
    echo "2. Deploy all missing components"
    echo "3. Organize all training content"
    echo "4. Re-run validation script"
fi

echo ""
echo "📋 Site Configuration URLs:"
echo "============================="

if [ ! -z "$org_url" ]; then
    echo "🏢 CEB Site Builder: $org_url/lightning/setup/NetworkBuilder/home"
    echo "👥 Member Site Builder: $org_url/lightning/setup/NetworkBuilder/home"
    echo "❓ Help Center Builder: $org_url/lightning/setup/NetworkBuilder/home"
    echo "⚙️ All Sites Management: $org_url/lightning/setup/SetupNetworks/home"
else
    echo "🔗 Access sites via Setup → Digital Experiences → All Sites"
fi

echo ""
echo "📖 Documentation References:"
echo "============================="
echo "📋 Configuration Guide: EXPERIENCE-CLOUD-CONFIGURATION-GUIDE.md"
echo "🚀 Deployment Guide: COMPREHENSIVE-SITE-DEPLOYMENT-GUIDE.md"
echo "📊 Site Mapping: SITE-DEPLOYMENT-MAPPING.md"

echo ""
echo "🎯 Component Testing Checklist:"
echo "==============================="
echo "□ CEB Training Hub - Task-oriented officer interface"
echo "□ Member Training Portal - Progressive learning paths"
echo "□ Help Center Portal - Search-driven support"
echo "□ Technical Docs Portal - Reference documentation"
echo "□ Cross-site navigation working"
echo "□ PDF generation functional"
echo "□ Mobile responsiveness validated"
echo "□ Accessibility compliance verified"

echo ""
echo "🏍️ CVMA Training Deployment Validation Complete!"
echo "Chapter 20-7 - Vets Serving Vets through Revolutionary Training Excellence"

# Open org if deployment is ready
if [ $percentage -ge 90 ]; then
    echo ""
    read -p "🚀 Ready for configuration! Open Salesforce org now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🌐 Opening Salesforce org..."
        sf org open --target-org cvma
    fi
fi