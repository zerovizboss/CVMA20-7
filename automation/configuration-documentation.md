# CVMA Experience Cloud Training Platform - Configuration Documentation

## Overview
This document provides comprehensive guidance for configuring the CVMA Chapter 20-7 Experience Cloud training platform across four sites using the deployed components.

## Automated vs Manual Configuration

### ✅ Automated Components (Already Deployed)

#### Lightning Web Components
1. **cvmaCebTrainingHub**
   - **Location:** `/src/lwc/cvmaCebTrainingHub/`
   - **Purpose:** Officer-focused training interface for CEB site
   - **Features:**
     - Task-oriented dashboard
     - Quick action buttons
     - Training modules by category
     - PDF generation integration
   - **Status:** ✅ Deployed and ready for configuration

2. **cvmaVeteranKnowledgeBase**
   - **Location:** `/src/lwc/cvmaVeteranKnowledgeBase/`
   - **Purpose:** Enhanced knowledge system with accessibility features
   - **Features:**
     - Multiple display modes (search, article, category)
     - WCAG 2.1 AA compliance
     - Survey integration
     - PDF generation
     - Mobile optimization
   - **Status:** ✅ Deployed and ready for configuration

#### Apex Controllers
3. **CVMADocumentSharingController**
   - **Location:** `/src/classes/CVMADocumentSharingController.cls`
   - **Purpose:** PDF generation from markdown content
   - **Features:**
     - Training document PDF generation
     - Content formatting
     - Document delivery
   - **Status:** ✅ Deployed with some compilation warnings (functional)

### ⚠️ Manual Configuration Required

#### Experience Builder Page Creation
The following pages must be created manually in Experience Builder:

#### Site 1: CEB Officer Training
**Access:** Experience Builder → CEB Site

1. **Officer Dashboard Page**
   ```
   Page Name: Officer Dashboard
   Route: /
   Template: Standard Page

   Component Configuration:
   - Add cvmaCebTrainingHub to main region
   - Properties:
     * displayMode: "dashboard"
     * showQuickActions: true
     * defaultCategory: "all"
   ```

2. **Training Modules Page**
   ```
   Page Name: Training Modules
   Route: /training
   Template: Standard Page

   Component Configuration:
   - Add cvmaCebTrainingHub to main region
   - Properties:
     * displayMode: "compact"
     * showQuickActions: false
     * defaultCategory: "Daily Operations"
   ```

#### Site 2: Member Training Portal
**Access:** Experience Builder → Combat Veterans Motorcycle Association Site

1. **Member Home Page**
   ```
   Page Name: Member Home
   Route: /
   Template: Home Page

   Component Configuration:
   - Add cvmaVeteranKnowledgeBase to main region
   - Properties:
     * displayMode: "article"
     * enableSearch: true
     * showCategories: true
     * showFeaturedArticles: true
     * maxSearchResults: 10
   ```

2. **Member Training Page**
   ```
   Page Name: Member Training
   Route: /training
   Template: Standard Page

   Component Configuration:
   - Add cvmaVeteranKnowledgeBase to main region
   - Properties:
     * displayMode: "category"
     * enableSearch: true
     * showCategories: true
     * showFeaturedArticles: false
     * maxSearchResults: 15
   ```

#### Site 3: Help Center
**Access:** Experience Builder → Default Help Center Site

1. **Help Search Page**
   ```
   Page Name: Help Search
   Route: /
   Template: Search Page

   Component Configuration:
   - Add cvmaVeteranKnowledgeBase to main region
   - Properties:
     * displayMode: "search"
     * enableSearch: true
     * showCategories: false
     * showFeaturedArticles: true
     * maxSearchResults: 15
   ```

#### Site 4: Technical Documentation
**Status:** ❌ Requires new site creation

1. **Create New Experience Cloud Site**
   ```
   Site Name: Technical Documentation
   Template: Build Your Own (LWR)
   URL Path: technical
   ```

2. **Documentation Home Page**
   ```
   Page Name: Documentation Home
   Route: /
   Template: Standard Page

   Component Configuration:
   - Add cvmaVeteranKnowledgeBase to main region
   - Properties:
     * displayMode: "category"
     * enableSearch: true
     * showCategories: true
     * showFeaturedArticles: false
     * maxSearchResults: 20
   ```

## Step-by-Step Configuration Guide

### Phase 1: Experience Builder Setup

#### Step 1: Access Experience Builder
1. Open Salesforce org
2. Navigate to **Setup → Digital Experiences → All Sites**
3. Select site to configure
4. Click **Builder** button

#### Step 2: Create Pages
1. In Experience Builder, click **+ New Page**
2. Select appropriate template
3. Set page properties (name, route)
4. Add components to page regions

#### Step 3: Configure Components
1. Select component on page
2. Open **Properties** panel
3. Configure properties according to specifications above
4. Test component functionality

#### Step 4: Set up Navigation
1. Access **Navigation** in Experience Builder
2. Create navigation menu items
3. Configure cross-site navigation links

### Phase 2: Site-Specific Configuration

#### CEB Officer Training Site Configuration
**Objective:** Task-oriented training interface for officers

**Navigation Setup:**
```
Dashboard (/ceb)
├── Training Modules (/ceb/training)
├── Quick Reference (/ceb/reference)
└── Member Portal (/)
```

**Component Properties:**
- **displayMode:** "dashboard" for main page, "compact" for training page
- **showQuickActions:** true for main page only
- **defaultCategory:** "all" for main, specific categories for others

#### Member Training Portal Configuration
**Objective:** Self-service learning for all members

**Navigation Setup:**
```
Home (/)
├── Training (/training)
├── Resources (/resources)
├── Help Center (/defaulthelpcenter12Jun)
└── Officer Portal (/ceb) [officers only]
```

**Component Properties:**
- **displayMode:** "article" for home, "category" for training
- **enableSearch:** true for all pages
- **showCategories:** true for most pages
- **showFeaturedArticles:** true for home page

#### Help Center Configuration
**Objective:** Search-first support interface

**Navigation Setup:**
```
Search Help (/defaulthelpcenter12Jun)
├── Common Solutions (/defaulthelpcenter12Jun/solutions)
├── Contact Support (/defaulthelpcenter12Jun/contact)
└── Back to Portal (/)
```

**Component Properties:**
- **displayMode:** "search" for all pages
- **enableSearch:** true (primary feature)
- **showCategories:** false (focus on search)
- **showFeaturedArticles:** true for quick access

### Phase 3: Survey Integration

#### Survey Builder Configuration
**Access:** Setup → Survey → Survey Builder

1. **Knowledge Article Feedback Survey**
   ```
   Survey Name: Knowledge Article Feedback
   Questions:
   - Rating: "How helpful was this article?" (1-5 scale)
   - Multiple Choice: "Experience level?" (New/Experienced/Officer/Technical)
   - Text: "How can we improve this article?" (optional)
   ```

2. **Training Module Rating Survey**
   ```
   Survey Name: Training Module Rating
   Questions:
   - Rating: "Rate training effectiveness" (1-5 scale)
   - Multiple Choice: "Most valuable aspect?" (Content/Examples/Navigation/PDFs)
   - Text: "Suggestions for improvement" (optional)
   ```

#### Survey Integration Points
- **Knowledge Articles:** Bottom of article display
- **Training Modules:** End of module completion
- **Help Center:** After solution usage
- **Site Feedback:** Global feedback option

### Phase 4: Accessibility Configuration

#### WCAG 2.1 AA Compliance Setup
**Automatic Features (in components):**
- Screen reader optimization
- Keyboard navigation
- High contrast support
- Mobile responsiveness
- Alt text for images
- ARIA labels and roles

**Manual Configuration Required:**
1. **Site-level accessibility settings**
2. **Content accessibility review**
3. **Navigation accessibility testing**
4. **Form accessibility validation**

### Phase 5: Mobile Optimization

#### Responsive Design Configuration
**Automatic Features (in components):**
- Mobile-first design
- Touch-friendly interfaces
- Responsive breakpoints
- Performance optimization

**Manual Testing Required:**
1. **Cross-device testing**
2. **Performance validation**
3. **Touch interaction testing**
4. **Content readability verification**

## Testing Configuration

### User Persona Setup
Create test users for each persona:

1. **New CVMA Member**
   ```
   Profile: Customer Community Plus User
   Permission Sets: Member Access
   Site Access: Member Portal, Help Center
   ```

2. **CEB Officer**
   ```
   Profile: CEB Profile
   Permission Sets: Officer Access
   Site Access: All sites
   ```

3. **Technical Staff**
   ```
   Profile: Customer Community Plus User
   Permission Sets: Technical Access
   Site Access: All sites including Technical Documentation
   ```

4. **Guest User**
   ```
   Profile: Guest License User
   Site Access: Help Center only
   ```

### Test Data Setup
1. **Knowledge Articles:** Create 20+ articles across categories
2. **Training Content:** 4 officer training modules minimum
3. **Survey Templates:** Configure 2 survey types
4. **Sample PDFs:** Test training materials

## Performance Optimization

### Recommended Settings
1. **Experience Cloud Settings**
   - Enable caching
   - Optimize image delivery
   - Minimize HTTP requests

2. **Component Optimization**
   - Lazy loading for heavy content
   - Pagination for search results
   - Efficient data queries

3. **Mobile Performance**
   - Compressed images
   - Minimal CSS/JS
   - Fast loading fonts

## Security Configuration

### Site Security Settings
1. **Guest User Access**
   - Help Center: Read-only access
   - Other sites: Authentication required

2. **Member Access Control**
   - Role-based site access
   - Content visibility rules
   - Cross-site navigation permissions

3. **Data Protection**
   - Survey response privacy
   - PDF access controls
   - User data encryption

## Monitoring and Analytics

### Experience Cloud Analytics
1. **Site Usage Tracking**
2. **Component Performance Metrics**
3. **User Journey Analysis**
4. **Mobile Usage Statistics**

### Custom Dashboards
1. **Training Completion Rates**
2. **Survey Response Analytics**
3. **Help Center Usage**
4. **Cross-site Navigation Patterns**

## Troubleshooting Common Issues

### Component Loading Issues
**Problem:** Components not displaying
**Solution:**
1. Verify component deployment
2. Check component permissions
3. Validate site configuration
4. Review browser console errors

### PDF Generation Issues
**Problem:** PDF generation failing
**Solution:**
1. Check CVMADocumentSharingController deployment
2. Verify content format
3. Test with sample content
4. Review Apex debug logs

### Navigation Issues
**Problem:** Cross-site navigation not working
**Solution:**
1. Verify URL configurations
2. Check user permissions
3. Validate navigation menu setup
4. Test with different user profiles

### Mobile Responsiveness Issues
**Problem:** Poor mobile experience
**Solution:**
1. Test on multiple devices
2. Check responsive breakpoints
3. Validate touch target sizes
4. Review mobile-specific CSS

## Maintenance Procedures

### Regular Maintenance Tasks
1. **Monthly:** Accessibility compliance audit
2. **Quarterly:** Performance review and optimization
3. **Bi-annually:** User satisfaction survey
4. **Annually:** Comprehensive security audit

### Update Procedures
1. **Component Updates:** Test in sandbox first
2. **Content Updates:** Follow approval workflow
3. **Site Updates:** Scheduled maintenance windows
4. **User Training:** Update training materials accordingly

## Support Resources

### Documentation Links
- [Experience Builder User Guide](https://help.salesforce.com/s/articleView?id=sf.community_designer_overview.htm)
- [Lightning Web Components Developer Guide](https://lwc.dev/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Salesforce Accessibility Guide](https://help.salesforce.com/s/articleView?id=sf.accessibility_overview.htm)

### Contact Information
- **Technical Support:** [Technical contact information]
- **Content Management:** [Content team contact]
- **User Training:** [Training team contact]
- **Accessibility Coordinator:** [Accessibility contact]

---

**Document Version:** 1.0
**Created:** September 23, 2025
**Last Updated:** September 23, 2025
**Next Review:** October 23, 2025
**Maintained by:** CVMA Chapter 20-7 Technical Team
