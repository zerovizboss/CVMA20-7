# CVMA Military Branch & Ribbon Component Mapping

## Design Philosophy
Combat Veterans Motorcycle Association honors all branches of military service through authentic ribbon designs aligned with component functionality and military heritage.

---

## 🏍️ CVMA Primary Theme (Red/Yellow/Black)
**Represents**: Combat Action Engagement Levels

### Components:
- General navigation elements
- cvmaAnnouncements
- cvmaUnifiedPortal (general portal)
- cvmaDocumentManager

### Ribbon Design - CVMA Combat Action:
```css
background: linear-gradient(to right,
    #000000 0%, #000000 20%,
    #FFD700 20%, #FFD700 40%,
    #C41E3A 40%, #C41E3A 60%,
    #FFD700 60%, #FFD700 80%,
    #000000 80%, #000000 100%
);
```

---

## ⚓ US NAVY - Financial & Logistics Processes
**Why Navy**: Strong naval tradition in financial management, logistics, and supply chain

### Components:
- cvmaTreasurersCorner
- cvmaFinancialDashboard
- cvmaFinancialCompliance
- cvmaFinancialManagementDashboard
- cvmaNPSPFinancialDashboard
- cvmaNPSPAnalytics
- cvmaBudgetManagement
- cvmaPaymentTracking

### Ribbon Examples:
- **Navy Commendation Medal** (Green/White/Orange)
- **Navy Achievement Medal** (Navy Blue/Orange)
- **Navy Good Conduct Medal** (Red with White edges)

---

## 🦅 US MARINE CORPS - Leadership & Officer Functions
**Why Marines**: Tradition of leadership, officer development, elite training

### Components:
- cvmaOfficerDashboard
- cvmaCebTrainingHub
- cvmaApplicationReview (vetting process)
- cvmaMembershipApplication

### Ribbon Examples:
- **Navy Cross** (Navy Blue/White - highest Marine valor award)
- **Marine Corps Good Conduct Medal**
- **Marine Corps Achievement Medal**

---

## 🪖 US ARMY - Member Services & Operations
**Why Army**: Ground operations, member support, community engagement

### Components:
- cvmaMemberPortal
- cvmaMemberProfile
- cvmaEventManagement
- cvmaEventRSVP
- cvmaEventManagementLDS
- cvmaEventRSVPV2
- cvmaGuestEvents
- cvmaGuestCalendar
- cvmaGuestRequestReview
- cvmaLightningCalendar
- cvmaMessaging
- cvmaCommunicationHub
- cvmaCommunicationIntegration

### Ribbon Examples:
- **Army Commendation Medal** (Green with White/Orange)
- **Army Achievement Medal** (Green with White stripes)
- **Army Good Conduct Medal** (Red with White)
- **Bronze Star** (Red/White/Blue stripes)

---

## ✈️ US AIR FORCE - Training & Technical Services
**Why Air Force**: Technology, education, precision, advanced systems

### Components:
- cvmaMemberTrainingPortal
- cvmaTechnicalDocsPortal
- cvmaHelpCenterPortal
- cvmaUsageDashboard
- cvmaEpic8Dashboard
- cvmaInAppGuidance
- cvmaAccessibleVeteranGuide

### Ribbon Examples:
- **Air Medal** (Blue/Orange vertical stripes)
- **Aerial Achievement Medal** (Blue/Orange)
- **Air Force Commendation Medal** (Yellow/Blue/Red)
- **Air Force Achievement Medal** (Yellow/Blue)

---

## 💜 UNIVERSAL MEMORIAL - Purple Heart
**Honors**: Wounded warriors - physical and mental wounds

### Components:
- cvmaCrisisSupport
- cvmaVAServicesIntegration

### Ribbon Design - Purple Heart:
```css
background: linear-gradient(to right,
    #FFFFFF 0%, #FFFFFF 10%,
    #672878 10%, #672878 90%,
    #FFFFFF 90%, #FFFFFF 100%
);
```

---

## 🕊️ UNIVERSAL MEMORIAL - POW/MIA
**Honors**: Prisoners of War and Missing in Action

### Components:
- cvmaVeteranResourcesPortal
- cvmaVeteranKnowledgeBase
- cvmaVeteranResourceFinder
- veteranResourceFinder

### Ribbon Design - POW/MIA:
```css
background: linear-gradient(to right,
    #000000 0%, #000000 25%,
    #FFFFFF 25%, #FFFFFF 75%,
    #000000 75%, #000000 100%
);
```

---

## 🎖️ Implementation Notes

### Color Accuracy
All ribbon colors based on official military uniform regulations:
- Navy: Navy Blue (#002147), Orange (#FF7F00)
- Marine Corps: Scarlet (#C1272D), Gold (#FFD700)
- Army: Green (#006747), White (#FFFFFF), Orange (#FF7F00)
- Air Force: Blue (#0033A0), Yellow (#FFD700)

### Consistency Rules
1. **Each process area maintains ONE branch** throughout all related components
2. **CVMA colors** (Red/Yellow/Black) used for general/universal functions
3. **Memorial ribbons** (Purple Heart, POW/MIA) transcend branch boundaries

### Accessibility
- All ribbons include high-contrast text
- Text shadows for readability
- Reduced motion support
- High contrast mode support

---

**Generated**: October 2, 2025
**CVMA Chapter 20-7** - "Vets Serving Vets"
