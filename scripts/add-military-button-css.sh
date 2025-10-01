#!/bin/bash

# Script to add Military Awards and Ribbons button styling to all LWC components
# CVMA Chapter 20-7 - October 2, 2025

CSS_SNIPPET='
/* Military Awards and Ribbons Button Styling */
.cvma-btn-combat-action {
    background: linear-gradient(135deg, #c41e3a 0%, #ffffff 50%, #0033a0 100%);
    color: #ffffff !important;
    font-weight: bold;
    text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.8);
    border: 2px solid #1c1c1c;
    border-radius: 4px;
    padding: 12px 24px;
    min-width: 200px;
    transition: all 0.3s ease;
}

.cvma-btn-combat-action:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 12px rgba(0, 0, 0, 0.4);
}

/* Accessibility Enhancements */
@media (prefers-reduced-motion: reduce) {
    .cvma-btn-combat-action {
        transition: none;
    }

    .cvma-btn-combat-action:hover {
        transform: none;
    }
}

@media (prefers-contrast: high) {
    .cvma-btn-combat-action {
        border-width: 3px;
        border-color: #000;
    }
}'

# List of CSS files to update (from previous grep -L command)
CSS_FILES=(
    "src/lwc/cvmaAccessibleVeteranGuide/cvmaAccessibleVeteranGuide.css"
    "src/lwc/cvmaAnnouncements/cvmaAnnouncements.css"
    "src/lwc/cvmaApplicationReview/cvmaApplicationReview.css"
    "src/lwc/cvmaBudgetManagement/cvmaBudgetManagement.css"
    "src/lwc/cvmaCommunicationHub/cvmaCommunicationHub.css"
    "src/lwc/cvmaCommunicationIntegration/cvmaCommunicationIntegration.css"
    "src/lwc/cvmaDocumentManager/cvmaDocumentManager.css"
    "src/lwc/cvmaEpic8Dashboard/cvmaEpic8Dashboard.css"
    "src/lwc/cvmaEventManagementLDS/cvmaEventManagementLDS.css"
    "src/lwc/cvmaEventRSVPV2/cvmaEventRSVPV2.css"
    "src/lwc/cvmaFinancialCompliance/cvmaFinancialCompliance.css"
    "src/lwc/cvmaFinancialDashboard/cvmaFinancialDashboard.css"
    "src/lwc/cvmaFinancialManagementDashboard/cvmaFinancialManagementDashboard.css"
    "src/lwc/cvmaGuestCalendar/cvmaGuestCalendar.css"
    "src/lwc/cvmaGuestEvents/cvmaGuestEvents.css"
    "src/lwc/cvmaGuestRequestReview/cvmaGuestRequestReview.css"
    "src/lwc/cvmaHelpCenterPortal/cvmaHelpCenterPortal.css"
    "src/lwc/cvmaInAppGuidance/cvmaInAppGuidance.css"
    "src/lwc/cvmaLightningCalendar/cvmaLightningCalendar.css"
    "src/lwc/cvmaMemberPortal/cvmaMemberPortal.css"
    "src/lwc/cvmaMemberProfile/cvmaMemberProfile.css"
    "src/lwc/cvmaMembershipApplication/cvmaMembershipApplication.css"
    "src/lwc/cvmaMemberTrainingPortal/cvmaMemberTrainingPortal.css"
    "src/lwc/cvmaMessaging/cvmaMessaging.css"
    "src/lwc/cvmaNPSPAnalytics/cvmaNPSPAnalytics.css"
    "src/lwc/cvmaNPSPFinancialDashboard/cvmaNPSPFinancialDashboard.css"
    "src/lwc/cvmaPaymentTracking/cvmaPaymentTracking.css"
    "src/lwc/cvmaTechnicalDocsPortal/cvmaTechnicalDocsPortal.css"
    "src/lwc/cvmaTreasurersCorner/cvmaTreasurersCorner.css"
    "src/lwc/cvmaUsageDashboard/cvmaUsageDashboard.css"
    "src/lwc/cvmaVAServicesIntegration/cvmaVAServicesIntegration.css"
    "src/lwc/cvmaVeteranKnowledgeBase/cvmaVeteranKnowledgeBase.css"
    "src/lwc/cvmaVeteranResourceFinder/cvmaVeteranResourceFinder.css"
    "src/lwc/cvmaVeteranResourcesPortal/cvmaVeteranResourcesPortal.css"
    "src/lwc/veteranResourceFinder/veteranResourceFinder.css"
)

echo "🏍️ CVMA Military Button CSS Update Script"
echo "=========================================="
echo "Adding Military Awards and Ribbons button styling to ${#CSS_FILES[@]} components"
echo ""

UPDATED=0
SKIPPED=0

for file in "${CSS_FILES[@]}"; do
    if [ -f "$file" ]; then
        # Check if the file already has the military button CSS (shouldn't happen but safety check)
        if grep -q "cvma-btn-combat-action" "$file" 2>/dev/null; then
            echo "⏩ SKIPPED: $file (already has military button CSS)"
            ((SKIPPED++))
        else
            # Append the CSS snippet to the file
            echo "$CSS_SNIPPET" >> "$file"
            echo "✅ UPDATED: $file"
            ((UPDATED++))
        fi
    else
        echo "❌ NOT FOUND: $file"
    fi
done

echo ""
echo "=========================================="
echo "✅ Updated: $UPDATED files"
echo "⏩ Skipped: $SKIPPED files"
echo "🎖️ Military Awards button styling applied!"
echo ""
