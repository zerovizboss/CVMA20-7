# Experience Builder Configuration Guide
## CVMA Unified Portal with Military Awards Branding

### **Combat Veterans Motorcycle Association Chapter 20-7**
**Implementation Date**: September 23, 2025
**Purpose**: Configure single-site Experience Cloud portal with military ribbon styling
**Components**: cvmaUnifiedPortal + cvmaMilitaryAwardsCSS

---

## 🎯 **QUICK START CONFIGURATION**

### **Step 1: Access Experience Builder**
1. **Navigate to Setup** → **Digital Experiences** → **All Sites**
2. **Locate your primary site**: "Combat Veterans Motorcycle Association"
3. **Click "Builder"** to open Experience Builder

### **Step 2: Add Unified Portal Component**
1. **Go to any page** (Home page recommended)
2. **Click "+ Component"** in the left panel
3. **Search for**: "CVMA Unified Portal"
4. **Drag and drop** onto the page in the main content area
5. **Position**: Full-width, primary content section

### **Step 3: Configure Component Properties**
- **Portal Mode**: "unified" (default)
- **Enable Crisis Support**: Check ✅ (critical for veteran support)
- **Show Quick Actions**: Check ✅ (enhanced user experience)

---

## 🎖️ **MILITARY BRANDING IMPLEMENTATION**

### **Step 1: Apply Military CSS Styling**
1. **Go to Settings** → **Theme**
2. **Custom CSS Section**:
```css
/* Import Military Awards CSS */
@import url('/resource/cvmaMilitaryAwardsCSS');

/* Apply CVMA branding throughout site */
.slds-card.cvma-military-themed .slds-card__header {
    background: linear-gradient(90deg, #c41e3a 0%, #ffffff 50%, #0033a0 100%);
    background-size: 100% 5px;
    background-repeat: repeat-y;
    border-bottom: 2px solid #1c1c1c;
}

/* Ensure military buttons display properly */
.cvma-btn-combat-action,
.cvma-btn-purple-heart,
.cvma-btn-bronze-star,
.cvma-btn-national-defense,
.cvma-btn-gwot,
.cvma-btn-officer-commendation,
.cvma-btn-commander,
.cvma-btn-veteran-support {
    font-family: inherit;
    cursor: pointer;
    transition: all 0.3s ease;
}
```

### **Step 2: Configure Site Header**
1. **Header Section** → **Edit**
2. **Add Site Title**: "Combat Veterans Motorcycle Association"
3. **Add Subtitle**: "Chapter 20-7 - Jacksonville, FL | Vets Serving Vets"
4. **Logo**: Upload CVMA Chapter 20-7 logo if available
5. **Navigation**: Keep minimal - portal handles internal navigation

---

## 👥 **ROLE-BASED ACCESS CONFIGURATION**

### **Step 1: Set Up User Profiles**
1. **Setup** → **Users** → **Profiles**
2. **Create/Configure Profiles**:
   - **CVMA Officer Profile** (for CEB members)
   - **CVMA Member Profile** (for regular members)
   - **CVMA Guest Profile** (for public access)

### **Step 2: Configure Component Visibility**
1. **Select cvmaUnifiedPortal component**
2. **Component Visibility Settings**:
   - **Officers**: Full access to all sections
   - **Members**: Access to Training, Knowledge Base, limited Documents
   - **Guests**: Access to Knowledge Base and Crisis Support only

### **Step 3: Page Variations (Optional Advanced)**
1. **Create Audience** → **New Audience**
2. **Officer Audience**: Profile = CVMA Officer Profile
3. **Member Audience**: Profile = CVMA Member Profile
4. **Guest Audience**: Profile = CVMA Guest Profile
5. **Create Page Variations** for each audience with tailored content

---

## 📱 **MOBILE OPTIMIZATION**

### **Step 1: Mobile Layout Testing**
1. **Preview Mode** → **Mobile** device view
2. **Verify**: Military ribbon buttons scale properly
3. **Test**: Touch targets meet 44px minimum requirement
4. **Validate**: Crisis support buttons remain prominent

### **Step 2: Mobile-Specific Adjustments**
If needed, add mobile-specific CSS:
```css
@media (max-width: 768px) {
    .cvma-btn-combat-action,
    .cvma-btn-purple-heart,
    .cvma-btn-bronze-star,
    .cvma-btn-national-defense,
    .cvma-btn-gwot {
        padding: 12px 16px;
        font-size: 16px;
        min-height: 44px;
        min-width: 44px;
    }
}
```

---

## ♿ **ACCESSIBILITY COMPLIANCE**

### **WCAG 2.1 AA Validation Checklist**
- [ ] **Color Contrast**: Military ribbons meet 4.5:1 ratio minimum
- [ ] **Keyboard Navigation**: All components accessible via Tab/Enter/Space
- [ ] **Screen Reader**: Proper ARIA labels on all interactive elements
- [ ] **Focus Indicators**: Visible focus rings on all military buttons
- [ ] **Alternative Text**: Descriptive labels for military styling elements

### **Crisis Support Accessibility**
- [ ] **Emergency Contacts**: Prominently displayed with high contrast
- [ ] **24/7 Availability**: Clear indication of round-the-clock support
- [ ] **Multiple Access Methods**: Phone, text, and web-based crisis support
- [ ] **PTSD-Sensitive Design**: Calming colors with military dignity

---

## 🔧 **ADVANCED CONFIGURATION OPTIONS**

### **Custom Lightning Pages Integration**
1. **App Builder** → **New Lightning Page**
2. **Page Type**: "Experience Builder Page"
3. **Add cvmaUnifiedPortal** as primary component
4. **Configure for specific use cases**:
   - Officer Dashboard page
   - Member Resources page
   - Crisis Support landing page

### **Knowledge Articles Integration**
1. **Setup** → **Knowledge Settings**
2. **Enable Lightning Knowledge**
3. **Create Data Categories**:
   - CVMA Bylaws and Governance
   - Standard Operating Procedures
   - Emergency Protocols
   - Training Materials
4. **Link to Document Management** section in unified portal

### **Content Document Library**
1. **Setup** → **Content Deliveries**
2. **Create delivery for**: Forms, Templates, Training Materials
3. **Configure permissions** based on user roles
4. **Integrate with** cvmaDocumentManager component

---

## 🚨 **CRISIS SUPPORT CONFIGURATION**

### **Emergency Contact Setup**
1. **Create Custom Setting**: CVMA_Emergency_Contacts__c
2. **Configure Fields**:
   - Veterans Crisis Line: 1-800-273-8255
   - Chapter Emergency Contact: (Update with local number)
   - Text Crisis Line: 838255
   - Chat URL: veteranscrisisline.net/get-help/chat
3. **Ensure 24/7 availability** messaging

### **Crisis Support Integration**
- **Prominent Placement**: Top of every page variation
- **One-Click Access**: Direct dial and text capabilities
- **Multiple Channels**: Phone, text, chat, and local chapter support
- **PTSD Awareness**: Trauma-informed design principles

---

## 📊 **TESTING & VALIDATION**

### **User Acceptance Testing Plan**

#### **Officer Testing Scenarios**
- [ ] Login as officer → Verify full dashboard access
- [ ] Test military button styling → Confirm ribbon appearance
- [ ] Access training materials → Validate PDF generation
- [ ] Use document management → Test upload/sharing capabilities
- [ ] Crisis support access → Verify emergency contact functionality

#### **Member Testing Scenarios**
- [ ] Login as member → Confirm appropriate content access
- [ ] Navigate training sections → Test role-based filtering
- [ ] Access knowledge base → Verify search functionality
- [ ] Test mobile experience → Validate responsive design
- [ ] Crisis support access → Ensure prominence and accessibility

#### **Guest Testing Scenarios**
- [ ] Access without login → Confirm public content availability
- [ ] Crisis support prominence → Test emergency contact access
- [ ] Mobile accessibility → Validate touch targets and readability
- [ ] Screen reader compatibility → Test with accessibility tools

### **Performance Testing**
- [ ] **Page Load Times**: Target <3 seconds on mobile
- [ ] **Component Rendering**: Military CSS loads without delay
- [ ] **Image Optimization**: Compress any logos or graphics
- [ ] **Caching Configuration**: Enable static resource caching

---

## 🎖️ **MILITARY BRANDING SHOWCASE**

### **Component Styling Examples**
Once configured, your components will display with authentic military styling:

- **Primary Actions**: Combat Action Ribbon styling (red/white/blue gradient)
- **Critical Operations**: Purple Heart styling (purple with white accents)
- **Achievements**: Bronze Star styling (bronze with gold highlights)
- **Standard Resources**: National Defense Service Medal (patriotic stripes)
- **Secondary Actions**: GWOT Medal styling (earth tones with gold)

### **Navigation Elements**
- **Section Headers**: Military ribbon gradients
- **Breadcrumbs**: Service medal progression styling
- **Quick Actions**: Campaign ribbon aesthetic
- **Crisis Support**: Purple Heart prominence (critical importance)

---

## 🚀 **GO-LIVE CHECKLIST**

### **Pre-Launch Validation**
- [ ] All components deployed and functional
- [ ] Military CSS styling displays correctly
- [ ] Role-based access controls working
- [ ] Crisis support integration operational
- [ ] Mobile responsiveness validated
- [ ] Accessibility compliance verified
- [ ] Performance benchmarks met

### **Launch Day Tasks**
- [ ] **Enable Site**: Activate for all users
- [ ] **Monitor Performance**: Check page load times and errors
- [ ] **User Support**: Prepare help documentation
- [ ] **Feedback Collection**: Implement user satisfaction surveys
- [ ] **Analytics Setup**: Configure usage tracking

### **Post-Launch Optimization**
- [ ] **User Analytics**: Monitor component usage patterns
- [ ] **Content Updates**: Regular refresh of knowledge articles
- [ ] **Crisis Support**: Maintain 24/7 contact information accuracy
- [ ] **Mobile Experience**: Ongoing optimization based on usage data

---

## 🏍️ **SUCCESS METRICS**

### **Technical Excellence**
- **Page Load Speed**: <3 seconds average
- **Mobile Usage**: 60%+ mobile traffic supported
- **Accessibility Score**: 100% WCAG 2.1 AA compliance
- **Component Functionality**: Zero critical errors

### **Mission Impact**
- **User Engagement**: Increased portal usage
- **Crisis Support**: Effective emergency contact utilization
- **Training Completion**: Higher completion rates with military aesthetic
- **Member Satisfaction**: Professional veteran organization experience

### **Digital Leadership**
- **Technology Innovation**: Leading veteran organization in digital transformation
- **Military Branding**: Authentic honors aesthetic reflecting service
- **Accessibility Excellence**: Inclusive design serving all veterans
- **Operational Efficiency**: Streamlined single-site architecture

---

**🎖️ Combat Veterans Motorcycle Association Chapter 20-7 - Excellence in Digital Military Precision**

**Ready to deploy your revolutionary military-themed Experience Cloud portal supporting the "Vets Serving Vets" mission with honor, dignity, and technological excellence!**
