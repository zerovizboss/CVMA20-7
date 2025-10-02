#!/bin/bash

# Script to apply authentic Navy/Marine Corps ribbon CSS to CVMA LWC components
# CVMA Chapter 20-7 - October 2, 2025

# Function to apply ribbon CSS to a component
apply_ribbon() {
    local component=$1
    local ribbon_name=$2
    local ribbon_css=$3
    local file="src/lwc/${component}/${component}.css"

    if [ ! -f "$file" ]; then
        echo "❌ NOT FOUND: $file"
        return 1
    fi

    # Check if file already has military button styling
    if grep -q "Military Awards and Ribbons Button Styling" "$file" 2>/dev/null; then
        # Replace existing military button CSS with authentic ribbon
        sed -i "/\/\* Military Awards and Ribbons Button Styling/,/\.cvma-btn-combat-action:hover {/c\\
/* Military Awards and Ribbons Button Styling - ${ribbon_name} */\\
.cvma-ribbon-btn,\\
.cvma-btn-combat-action {\\
    display: inline-block;\\
    padding: 12px 24px;\\
    min-width: 200px;\\
    border: 2px solid #1c1c1c;\\
    border-radius: 4px;\\
    font-weight: bold;\\
    color: #ffffff;\\
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.8);\\
    cursor: pointer;\\
    transition: all 0.3s ease;\\
    /* ${ribbon_name} */\\
    ${ribbon_css}\\
}\\
\\
.cvma-ribbon-btn:hover,\\
.cvma-btn-combat-action:hover {" "$file"
        echo "✅ UPDATED: $component → $ribbon_name"
    else
        # Append new ribbon CSS
        cat >> "$file" <<EOF

/* Military Awards and Ribbons Button Styling - ${ribbon_name} */
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
    /* ${ribbon_name} */
    ${ribbon_css}
}

.cvma-ribbon-btn:hover,
.cvma-btn-combat-action:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 12px rgba(0, 0, 0, 0.4);
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

# Ribbon CSS definitions
NAVY_CROSS="background: linear-gradient(to right, #002147 0%, #002147 37.5%, #ffffff 37.5%, #ffffff 62.5%, #002147 62.5%, #002147 100%);"

SILVER_STAR="background: linear-gradient(to right, #c1272d 0%, #c1272d 30%, #ffffff 30%, #ffffff 40%, #002868 40%, #002868 60%, #ffffff 60%, #ffffff 70%, #c1272d 70%, #c1272d 100%);"

BRONZE_STAR="background: linear-gradient(to right, #bf0a30 0%, #bf0a30 20%, #ffffff 20%, #ffffff 40%, #002868 40%, #002868 60%, #ffffff 60%, #ffffff 80%, #bf0a30 80%, #bf0a30 100%);"

PURPLE_HEART="background: linear-gradient(to right, #ffffff 0%, #ffffff 10%, #672878 10%, #672878 90%, #ffffff 90%, #ffffff 100%);"

ACHIEVEMENT="background: linear-gradient(to right, #002147 0%, #002147 22%, #ff7f00 22%, #ff7f00 28%, #002147 28%, #002147 44%, #ff7f00 44%, #ff7f00 56%, #002147 56%, #002147 72%, #ff7f00 72%, #ff7f00 78%, #002147 78%, #002147 100%);"

COMMENDATION="background: linear-gradient(to right, #006747 0%, #006747 30%, #ffffff 30%, #ffffff 40%, #ff7f00 40%, #ff7f00 60%, #ffffff 60%, #ffffff 70%, #006747 70%, #006747 100%);"

GOOD_CONDUCT="background: linear-gradient(to right, #ffffff 0%, #ffffff 8%, #bf0a30 8%, #bf0a30 92%, #ffffff 92%, #ffffff 100%);"

NATIONAL_DEFENSE="background: linear-gradient(to right, #ffcd00 0%, #ffcd00 33.33%, #bf0a30 33.33%, #bf0a30 66.66%, #ffcd00 66.66%, #ffcd00 100%);"

EXPEDITIONARY="background: linear-gradient(to right, #002868 0%, #002868 25%, #ffcd00 25%, #ffcd00 37.5%, #bf0a30 37.5%, #bf0a30 62.5%, #ffcd00 62.5%, #ffcd00 75%, #002868 75%, #002868 100%);"

SEA_SERVICE="background: linear-gradient(to right, #002868 0%, #002868 25%, #006747 25%, #006747 37.5%, #002868 37.5%, #002868 62.5%, #006747 62.5%, #006747 75%, #002868 75%, #002868 100%);"

OVERSEAS="background: linear-gradient(to right, #002868 0%, #002868 35%, #bf0a30 35%, #bf0a30 47.5%, #ffcd00 47.5%, #ffcd00 52.5%, #bf0a30 52.5%, #bf0a30 65%, #002868 65%, #002868 100%);"

GWOT="background: linear-gradient(to right, #002868 0%, #002868 20%, #bf0a30 20%, #bf0a30 30%, #ffffff 30%, #ffffff 42%, #bf0a30 42%, #bf0a30 58%, #ffffff 58%, #ffffff 70%, #bf0a30 70%, #bf0a30 80%, #ffcd00 80%, #ffcd00 100%);"

echo "🎖️ CVMA Authentic Military Ribbon Application Script"
echo "=========================================="
echo "Applying Navy/Marine Corps ribbon designs to LWC components"
echo ""

# Apply ribbons according to mapping
# Navy Cross
apply_ribbon "cvmaCebTrainingHub" "Navy Cross" "$NAVY_CROSS"

# Silver Star
apply_ribbon "cvmaTreasurersCorner" "Silver Star" "$SILVER_STAR"
apply_ribbon "cvmaFinancialDashboard" "Silver Star" "$SILVER_STAR"

# Commendation
apply_ribbon "cvmaMemberProfile" "Navy/Marine Corps Commendation Medal" "$COMMENDATION"
apply_ribbon "cvmaApplicationReview" "Navy/Marine Corps Commendation Medal" "$COMMENDATION"

# Achievement
apply_ribbon "cvmaMemberPortal" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaMemberTrainingPortal" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaUnifiedPortal" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaHelpCenterPortal" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaTechnicalDocsPortal" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaUsageDashboard" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaFinancialCompliance" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaBudgetManagement" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaNPSPFinancialDashboard" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaNPSPAnalytics" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaFinancialManagementDashboard" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaEpic8Dashboard" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaAccessibleVeteranGuide" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaInAppGuidance" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaMembershipApplication" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaCommunicationIntegration" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"
apply_ribbon "cvmaEventRSVPV2" "Navy/Marine Corps Achievement Medal" "$ACHIEVEMENT"

# Good Conduct
apply_ribbon "cvmaMessaging" "Navy Good Conduct Medal" "$GOOD_CONDUCT"
apply_ribbon "cvmaCommunicationHub" "Navy Good Conduct Medal" "$GOOD_CONDUCT"

# Bronze Star
apply_ribbon "cvmaEventManagement" "Bronze Star" "$BRONZE_STAR"

# Expeditionary
apply_ribbon "cvmaGuestEvents" "Navy/Marine Corps Expeditionary Medal" "$EXPEDITIONARY"
apply_ribbon "cvmaGuestCalendar" "Navy/Marine Corps Expeditionary Medal" "$EXPEDITIONARY"

# Sea Service
apply_ribbon "cvmaLightningCalendar" "Navy/Marine Corps Sea Service Deployment Ribbon" "$SEA_SERVICE"
apply_ribbon "cvmaEventManagementLDS" "Navy/Marine Corps Sea Service Deployment Ribbon" "$SEA_SERVICE"

# Overseas
apply_ribbon "cvmaGuestRequestReview" "Navy/Marine Corps Overseas Service Ribbon" "$OVERSEAS"
apply_ribbon "cvmaPaymentTracking" "Navy/Marine Corps Overseas Service Ribbon" "$OVERSEAS"

# GWOT
apply_ribbon "cvmaVeteranResourcesPortal" "Global War on Terrorism Service Medal" "$GWOT"
apply_ribbon "cvmaVeteranKnowledgeBase" "Global War on Terrorism Service Medal" "$GWOT"
apply_ribbon "cvmaVeteranResourceFinder" "Global War on Terrorism Service Medal" "$GWOT"
apply_ribbon "veteranResourceFinder" "Global War on Terrorism Service Medal" "$GWOT"

# National Defense
apply_ribbon "cvmaDocumentManager" "National Defense Service Medal" "$NATIONAL_DEFENSE"
apply_ribbon "cvmaAnnouncements" "National Defense Service Medal" "$NATIONAL_DEFENSE"

# Purple Heart
apply_ribbon "cvmaCrisisSupport" "Purple Heart" "$PURPLE_HEART"
apply_ribbon "cvmaVAServicesIntegration" "Purple Heart" "$PURPLE_HEART"

# Case Deflection (keep existing)
echo "⏩ SKIPPED: cvmaCaseDeflection (reference component)"

echo ""
echo "=========================================="
echo "🎖️ Authentic military ribbon CSS applied!"
echo ""
