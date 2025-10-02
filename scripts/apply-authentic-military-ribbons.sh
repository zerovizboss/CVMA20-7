#!/bin/bash

# Script to apply authentic military ribbons to CVMA LWC components
# CVMA Chapter 20-7 - October 2, 2025
# Based on branch-specific process mapping

# Function to apply ribbon CSS to component
apply_ribbon() {
    local component=$1
    local ribbon_name=$2
    local ribbon_class=$3
    local file="src/lwc/${component}/${component}.css"

    if [ ! -f "$file" ]; then
        echo "❌ NOT FOUND: $file"
        return 1
    fi

    # Check if file has existing military button styling
    if grep -q "Military Awards and Ribbons" "$file" 2>/dev/null; then
        # Update existing ribbon reference
        sed -i "s/\/\* Military Awards and Ribbons.*\*\//\/* Military Awards and Ribbons - ${ribbon_name} *\//g" "$file"
        sed -i "s/background: linear-gradient.*;/background: var(--${ribbon_class});/g" "$file"
        echo "✅ UPDATED: $component → $ribbon_name"
    else
        # Append new ribbon CSS
        cat >> "$file" <<EOF

/* Military Awards and Ribbons - ${ribbon_name} */
.cvma-ribbon-btn,
.cvma-btn-combat-action {
    display: inline-block;
    padding: 12px 24px;
    min-width: 200px;
    border: 2px solid #1c1c1c;
    border-radius: 4px;
    font-weight: bold;
    color: #ffffff;
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.8);
    cursor: pointer;
    transition: all 0.3s ease;
    text-align: center;
}

.cvma-ribbon-btn:hover,
.cvma-btn-combat-action:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 12px rgba(0, 0, 0, 0.4);
}

/* Apply ${ribbon_name} ribbon pattern */
.cvma-ribbon-btn,
.cvma-btn-combat-action {
EOF
        # Append the specific ribbon gradient
        get_ribbon_css "$ribbon_class" >> "$file"
        cat >> "$file" <<EOF
}

/* Accessibility Enhancements */
@media (prefers-reduced-motion: reduce) {
    .cvma-ribbon-btn,
    .cvma-btn-combat-action {
        transition: none;
    }

    .cvma-ribbon-btn:hover,
    .cvma-btn-combat-action:hover {
        transform: none;
    }
}

@media (prefers-contrast: high) {
    .cvma-ribbon-btn,
    .cvma-btn-combat-action {
        border-width: 3px;
        border-color: #000;
    }
}
EOF
        echo "✅ ADDED: $component → $ribbon_name"
    fi
}

# Function to get ribbon CSS gradient
get_ribbon_css() {
    local ribbon_class=$1
    case "$ribbon_class" in
        "cvma-organizational")
            echo "    background: linear-gradient(to right, #000000 0%, #000000 20%, #B8860B 20%, #B8860B 40%, #c41e3a 40%, #c41e3a 60%, #B8860B 60%, #B8860B 80%, #000000 80%, #000000 100%);"
            ;;
        "navy-commendation")
            echo "    background: linear-gradient(to right, #006747 0%, #006747 30%, #ffffff 30%, #ffffff 40%, #ff7f00 40%, #ff7f00 60%, #ffffff 60%, #ffffff 70%, #006747 70%, #006747 100%);"
            ;;
        "navy-achievement")
            echo "    background: linear-gradient(to right, #002147 0%, #002147 22%, #ff7f00 22%, #ff7f00 28%, #002147 28%, #002147 44%, #ff7f00 44%, #ff7f00 56%, #002147 56%, #002147 72%, #ff7f00 72%, #ff7f00 78%, #002147 78%, #002147 100%);"
            ;;
        "navy-good-conduct")
            echo "    background: linear-gradient(to right, #ffffff 0%, #ffffff 8%, #bf0a30 8%, #bf0a30 92%, #ffffff 92%, #ffffff 100%);"
            ;;
        "navy-cross")
            echo "    background: linear-gradient(to right, #002147 0%, #002147 37.5%, #ffffff 37.5%, #ffffff 62.5%, #002147 62.5%, #002147 100%);"
            ;;
        "usmc-good-conduct")
            echo "    background: linear-gradient(to right, #B8860B 0%, #B8860B 10%, #c1272d 10%, #c1272d 90%, #B8860B 90%, #B8860B 100%);"
            ;;
        "usmc-achievement")
            echo "    background: linear-gradient(to right, #002147 0%, #002147 22%, #B8860B 22%, #B8860B 28%, #002147 28%, #002147 44%, #B8860B 44%, #B8860B 56%, #002147 56%, #002147 72%, #B8860B 72%, #B8860B 78%, #002147 78%, #002147 100%);"
            ;;
        "army-commendation")
            echo "    background: linear-gradient(to right, #006747 0%, #006747 30%, #ffffff 30%, #ffffff 40%, #ff7f00 40%, #ff7f00 60%, #ffffff 60%, #ffffff 70%, #006747 70%, #006747 100%);"
            ;;
        "army-achievement")
            echo "    background: linear-gradient(to right, #006747 0%, #006747 22%, #ffffff 22%, #ffffff 28%, #006747 28%, #006747 44%, #ffffff 44%, #ffffff 56%, #006747 56%, #006747 72%, #ffffff 72%, #ffffff 78%, #006747 78%, #006747 100%);"
            ;;
        "army-good-conduct")
            echo "    background: linear-gradient(to right, #ffffff 0%, #ffffff 8%, #bf0a30 8%, #bf0a30 92%, #ffffff 92%, #ffffff 100%);"
            ;;
        "bronze-star")
            echo "    background: linear-gradient(to right, #bf0a30 0%, #bf0a30 20%, #ffffff 20%, #ffffff 40%, #002868 40%, #002868 60%, #ffffff 60%, #ffffff 80%, #bf0a30 80%, #bf0a30 100%);"
            ;;
        "air-medal")
            echo "    background: linear-gradient(to right, #0033a0 0%, #0033a0 33.33%, #ff7f00 33.33%, #ff7f00 66.66%, #0033a0 66.66%, #0033a0 100%);"
            ;;
        "air-force-commendation")
            echo "    background: linear-gradient(to right, #ffcd00 0%, #ffcd00 30%, #0033a0 30%, #0033a0 40%, #bf0a30 40%, #bf0a30 60%, #0033a0 60%, #0033a0 70%, #ffcd00 70%, #ffcd00 100%);"
            ;;
        "air-force-achievement")
            echo "    background: linear-gradient(to right, #ffcd00 0%, #ffcd00 25%, #0033a0 25%, #0033a0 37.5%, #ffcd00 37.5%, #ffcd00 62.5%, #0033a0 62.5%, #0033a0 75%, #ffcd00 75%, #ffcd00 100%);"
            ;;
        "purple-heart")
            echo "    background: linear-gradient(to right, #ffffff 0%, #ffffff 10%, #672878 10%, #672878 90%, #ffffff 90%, #ffffff 100%);"
            ;;
        "pow-mia")
            echo "    background: linear-gradient(to right, #000000 0%, #000000 25%, #ffffff 25%, #ffffff 75%, #000000 75%, #000000 100%);"
            ;;
        "silver-star")
            echo "    background: linear-gradient(to right, #c1272d 0%, #c1272d 30%, #ffffff 30%, #ffffff 40%, #002868 40%, #002868 60%, #ffffff 60%, #ffffff 70%, #c1272d 70%, #c1272d 100%);"
            ;;
        "national-defense")
            echo "    background: linear-gradient(to right, #ffcd00 0%, #ffcd00 33.33%, #bf0a30 33.33%, #bf0a30 66.66%, #ffcd00 66.66%, #ffcd00 100%);"
            ;;
        *)
            echo "    background: linear-gradient(to right, #000000 0%, #000000 20%, #B8860B 20%, #B8860B 40%, #c41e3a 40%, #c41e3a 60%, #B8860B 60%, #B8860B 80%, #000000 80%, #000000 100%);"
            ;;
    esac
}

echo "🎖️ CVMA Authentic Military Ribbon Application"
echo "============================================="
echo "Applying branch-specific ribbons to components"
echo ""

# CVMA ORGANIZATIONAL (Red/Gold/Black)
echo "📋 CVMA Organizational Ribbon..."
apply_ribbon "cvmaAnnouncements" "CVMA Organizational" "cvma-organizational"
apply_ribbon "cvmaUnifiedPortal" "CVMA Organizational" "cvma-organizational"
apply_ribbon "cvmaDocumentManager" "CVMA Organizational" "cvma-organizational"

# US NAVY - Financial Processes
echo ""
echo "⚓ US Navy Ribbons..."
apply_ribbon "cvmaTreasurersCorner" "Navy Commendation Medal" "navy-commendation"
apply_ribbon "cvmaFinancialDashboard" "Navy Achievement Medal" "navy-achievement"
apply_ribbon "cvmaFinancialCompliance" "Navy Good Conduct Medal" "navy-good-conduct"
apply_ribbon "cvmaFinancialManagementDashboard" "Navy Commendation Medal" "navy-commendation"
apply_ribbon "cvmaNPSPFinancialDashboard" "Navy Achievement Medal" "navy-achievement"
apply_ribbon "cvmaNPSPAnalytics" "Navy Achievement Medal" "navy-achievement"
apply_ribbon "cvmaBudgetManagement" "Navy Good Conduct Medal" "navy-good-conduct"
apply_ribbon "cvmaPaymentTracking" "Navy Achievement Medal" "navy-achievement"

# US MARINE CORPS - Leadership
echo ""
echo "🦅 US Marine Corps Ribbons..."
apply_ribbon "cvmaOfficerDashboard" "Navy Cross" "navy-cross"
apply_ribbon "cvmaCebTrainingHub" "USMC Good Conduct Medal" "usmc-good-conduct"
apply_ribbon "cvmaApplicationReview" "USMC Achievement Medal" "usmc-achievement"
apply_ribbon "cvmaMembershipApplication" "USMC Achievement Medal" "usmc-achievement"

# US ARMY - Member Services
echo ""
echo "🪖 US Army Ribbons..."
apply_ribbon "cvmaMemberPortal" "Army Commendation Medal" "army-commendation"
apply_ribbon "cvmaMemberProfile" "Army Achievement Medal" "army-achievement"
apply_ribbon "cvmaEventManagement" "Bronze Star Medal" "bronze-star"
apply_ribbon "cvmaEventRSVP" "Army Achievement Medal" "army-achievement"
apply_ribbon "cvmaEventManagementLDS" "Army Good Conduct Medal" "army-good-conduct"
apply_ribbon "cvmaEventRSVPV2" "Army Achievement Medal" "army-achievement"
apply_ribbon "cvmaGuestEvents" "Army Commendation Medal" "army-commendation"
apply_ribbon "cvmaGuestCalendar" "Army Achievement Medal" "army-achievement"
apply_ribbon "cvmaGuestRequestReview" "Army Good Conduct Medal" "army-good-conduct"
apply_ribbon "cvmaLightningCalendar" "Army Achievement Medal" "army-achievement"
apply_ribbon "cvmaMessaging" "Army Good Conduct Medal" "army-good-conduct"
apply_ribbon "cvmaCommunicationHub" "Army Achievement Medal" "army-achievement"
apply_ribbon "cvmaCommunicationIntegration" "Army Achievement Medal" "army-achievement"

# US AIR FORCE - Training/Technical
echo ""
echo "✈️ US Air Force Ribbons..."
apply_ribbon "cvmaMemberTrainingPortal" "Air Force Commendation Medal" "air-force-commendation"
apply_ribbon "cvmaTechnicalDocsPortal" "Air Medal" "air-medal"
apply_ribbon "cvmaHelpCenterPortal" "Air Force Achievement Medal" "air-force-achievement"
apply_ribbon "cvmaUsageDashboard" "Air Force Achievement Medal" "air-force-achievement"
apply_ribbon "cvmaEpic8Dashboard" "Air Force Achievement Medal" "air-force-achievement"
apply_ribbon "cvmaInAppGuidance" "Air Force Achievement Medal" "air-force-achievement"
apply_ribbon "cvmaAccessibleVeteranGuide" "Air Force Commendation Medal" "air-force-commendation"

# MEMORIAL RIBBONS
echo ""
echo "💜 Universal Memorial Ribbons..."
apply_ribbon "cvmaCrisisSupport" "Purple Heart" "purple-heart"
apply_ribbon "cvmaVAServicesIntegration" "Purple Heart" "purple-heart"
apply_ribbon "cvmaVeteranResourcesPortal" "POW/MIA" "pow-mia"
apply_ribbon "cvmaVeteranKnowledgeBase" "POW/MIA" "pow-mia"
apply_ribbon "cvmaVeteranResourceFinder" "POW/MIA" "pow-mia"
apply_ribbon "veteranResourceFinder" "POW/MIA" "pow-mia"

# Skip reference component
echo ""
echo "⏩ SKIPPED: cvmaCaseDeflection (reference component)"

echo ""
echo "============================================="
echo "🎖️ Authentic military ribbons applied!"
echo "   - CVMA: Red/Gold/Black organizational"
echo "   - Navy: Financial processes"
echo "   - Marines: Leadership functions"
echo "   - Army: Member services"
echo "   - Air Force: Training/Technical"
echo "   - Memorial: Purple Heart & POW/MIA"
echo ""
