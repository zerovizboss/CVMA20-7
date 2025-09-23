# 🚀 Experience Cloud Site Configuration Guide
## CVMA Site-Specific Training Components Setup

### **Combat Veterans Motorcycle Association Chapter 20-7**
**Implementation Guide**: Step-by-step configuration for revolutionary training experience
**Date**: January 23, 2025

---

## 📋 **Prerequisites Completed** ✅
- All four site-specific training components deployed to Salesforce org
- Components enhanced with configurable properties for optimal flexibility
- CVMADocumentSharingController operational for PDF generation
- Site-specific training content organized and ready

---

## 🎯 **Configuration Overview**

### **Four-Site Architecture**
| Component | Site | URL | Configuration Focus |
|-----------|------|-----|-------------------|
| `CEB Training Hub` | CEB Site | `/ceb` | Officer task workflows |
| `Member Training Portal` | Member Site | `/` | Self-service learning |
| `Help Center Portal` | Help Center | `/defaulthelpcenter12Jun` | Search-driven support |
| `Technical Docs Portal` | Technical Site | `/` | Reference documentation |

---

## 🏢 **Site 1: CEB Training Hub Configuration**

### **Target Site**: https://cvma20-7-dev-ed.develop.my.site.com/ceb

#### **Step 1: Access Experience Builder**
1. Navigate to **Setup** → **Digital Experiences** → **All Sites**
2. Find "CEB" site and click **Builder**
3. Select the main dashboard/home page

#### **Step 2: Add CEB Training Hub Component**
1. In Experience Builder, click **Components** (left panel)
2. Search for "CEB Training Hub"
3. Drag component to the main content area
4. Position prominently on the page (full width recommended)

#### **Step 3: Configure Component Properties**
```
Display Mode: "dashboard" (default)
Show Quick Actions: true (enable emergency procedures & daily tasks)
Default Category: "all" (show all training modules initially)
```

#### **Step 4: Optimal Page Layout**
```
CEB Site Layout Recommendation:
┌─────────────────────────────────────┐
│ Site Header & Navigation            │
├─────────────────────────────────────┤
│ CEB Training Hub (Full Width)       │
│ ├── Quick Actions Bar               │
│ ├── Daily Operations Modules        │
│ ├── Member Services Training        │
│ ├── Financial Management            │
│ └── Event Coordination              │
├─────────────────────────────────────┤
│ Officer Dashboard Links             │
└─────────────────────────────────────┘
```

#### **Step 5: Test Officer Workflows**
- ✅ Quick Actions: Emergency procedures, Daily checklist, Member support
- ✅ Module Selection: Click each training category
- ✅ Mobile View: Test on mobile device
- ✅ PDF Generation: Verify document creation works

---

## 👥 **Site 2: Member Training Portal Configuration**

### **Target Site**: https://cvma20-7-dev-ed.develop.my.site.com

#### **Step 1: Access Experience Builder**
1. Navigate to **Setup** → **Digital Experiences** → **All Sites**
2. Find "Combat Veterans Motorcycle Association" site and click **Builder**
3. Create or select a "Training" page

#### **Step 2: Add Member Training Portal Component**
1. In Experience Builder, click **Components** (left panel)
2. Search for "Member Training Portal"
3. Drag component to the training page content area

#### **Step 3: Configure Component Properties**
```
Display Mode: "full" (complete learning experience)
Show Progress Tracking: true (enable member achievement tracking)
Enable Quick Help: true (password reset, profile updates, etc.)
Default Learning Path: "getting-started" (optimal for new members)
```

#### **Step 4: Optimal Page Layout**
```
Member Site Layout Recommendation:
┌─────────────────────────────────────┐
│ Site Header & Member Navigation     │
├─────────────────────────────────────┤
│ Member Training Portal (Full Width) │
│ ├── Learning Path Selection         │
│ ├── Getting Started (20 min)        │
│ ├── Self-Service Tools (25 min)     │
│ ├── Community Engagement (15 min)   │
│ └── Accessibility Features (10 min) │
├─────────────────────────────────────┤
│ Quick Help Topics                   │
│ Member Services Links               │
└─────────────────────────────────────┘
```

#### **Step 5: Test Member Workflows**
- ✅ Learning Paths: Complete getting started flow
- ✅ Progress Tracking: Verify step progression works
- ✅ Quick Help: Test password reset and profile update links
- ✅ Mobile Learning: Validate mobile learning experience

---

## ❓ **Site 3: Help Center Portal Configuration**

### **Target Site**: https://cvma20-7-dev-ed.develop.my.site.com/defaulthelpcenter12Jun

#### **Step 1: Access Experience Builder**
1. Navigate to **Setup** → **Digital Experiences** → **All Sites**
2. Find "Default Help Center" site and click **Builder**
3. Select the main support/home page

#### **Step 2: Add Help Center Portal Component**
1. In Experience Builder, click **Components** (left panel)
2. Search for "Help Center Portal"
3. Drag component to the main content area (full width)

#### **Step 3: Configure Component Properties**
```
Display Mode: "search-first" (prioritize search interface)
Enable Advanced Search: true (enhanced search capabilities)
Show Quick Solutions: true (password reset, contact support, etc.)
Prioritize Accessibility: true (accessibility support prominent)
```

#### **Step 4: Optimal Page Layout**
```
Help Center Layout Recommendation:
┌─────────────────────────────────────┐
│ Help Center Header & Search         │
├─────────────────────────────────────┤
│ Help Center Portal (Full Width)     │
│ ├── Primary Search Interface        │
│ ├── Quick Solutions (4 buttons)     │
│ ├── Help Categories                 │
│ └── Popular Articles                │
├─────────────────────────────────────┤
│ Contact Support Options             │
│ Live Chat Integration               │
└─────────────────────────────────────┘
```

#### **Step 5: Test Support Workflows**
- ✅ Search Functionality: Test various search terms
- ✅ Quick Solutions: Verify password reset, contact support
- ✅ Accessibility: Test with screen reader if available
- ✅ Category Browsing: Navigate help categories

---

## ⚙️ **Site 4: Technical Documentation Portal Configuration**

### **Target Site**: https://cvma20-7-dev-ed.develop.my.site.com (Technical Section)

#### **Step 1: Access Experience Builder**
1. Navigate to **Setup** → **Digital Experiences** → **All Sites**
2. Find "Combat Veterans Motorcycle Association" site and click **Builder**
3. Create or select a "Technical Documentation" page

#### **Step 2: Add Technical Docs Portal Component**
1. In Experience Builder, click **Components** (left panel)
2. Search for "Technical Documentation Portal"
3. Drag component to the documentation page

#### **Step 3: Configure Component Properties**
```
Display Mode: "reference" (documentation browser interface)
Enable Advanced Filtering: true (document type, tags, search)
Show Code Examples: true (interactive code snippets)
Enable Document Preview: true (quick content preview)
```

#### **Step 4: Optimal Page Layout**
```
Technical Site Layout Recommendation:
┌─────────────────────────────────────┐
│ Technical Navigation & Search       │
├─────────────────────────────────────┤
│ Technical Docs Portal (Full Width)  │
│ ├── Document Type Filters           │
│ ├── Epic Documentation (43 docs)    │
│ ├── API Documentation (15 docs)     │
│ ├── Development Guides (25 docs)    │
│ └── Deployment Runbooks (18 docs)   │
├─────────────────────────────────────┤
│ Code Examples & Snippets            │
│ Recently Updated Documents          │
└─────────────────────────────────────┘
```

#### **Step 5: Test Developer Workflows**
- ✅ Advanced Filtering: Filter by document type and tags
- ✅ Code Examples: Copy code snippets to clipboard
- ✅ Document Search: Search for specific Epic or API docs
- ✅ Cross-References: Navigate between related documentation

---

## 🔗 **Cross-Site Integration Setup**

### **Navigation Links Between Sites**
Add these navigation elements to connect the training experiences:

#### **CEB Site Navigation**
```html
<!-- Add to CEB site header/navigation -->
<a href="/s/training">Member Training Portal</a>
<a href="/defaulthelpcenter12Jun/s/">Help Center</a>
<a href="/s/technical-docs">Technical Documentation</a>
```

#### **Member Site Navigation**
```html
<!-- Add to member site (for officers) -->
<a href="/ceb/s/">Officer Training</a>
<a href="/defaulthelpcenter12Jun/s/">Get Help</a>
```

#### **Help Center Navigation**
```html
<!-- Add to help center -->
<a href="/s/">Member Home</a>
<a href="/ceb/s/">Officer Resources</a>
```

### **Contextual Content Linking**
Configure each component to dispatch navigation events:
```javascript
// Example: Link from Member Portal to Help Center for specific topics
this.dispatchEvent(new CustomEvent('navigatetohelp', {
    detail: { topic: 'accessibility-support' }
}));
```

---

## 📱 **Mobile Optimization Validation**

### **Mobile Testing Checklist**
Test each site on mobile devices:

#### **All Sites Mobile Requirements**
- [ ] **Responsive Design**: Components adjust to mobile screen sizes
- [ ] **Touch Friendly**: Buttons and interactions work with touch
- [ ] **Readable Text**: Text scales appropriately
- [ ] **Fast Loading**: Pages load within 3 seconds on mobile
- [ ] **Offline Capability**: Basic functionality without internet

#### **Site-Specific Mobile Features**
- **CEB Site**: Quick actions accessible for field use
- **Member Site**: Learning paths optimized for mobile consumption
- **Help Center**: Search interface works with mobile keyboards
- **Technical Site**: Code examples readable on mobile screens

---

## ♿ **Accessibility Compliance Validation**

### **WCAG 2.1 AA Compliance Checklist**
Validate each site meets accessibility requirements:

#### **All Sites Accessibility Requirements**
- [ ] **Screen Reader Compatible**: Test with NVDA, JAWS, or VoiceOver
- [ ] **Keyboard Navigation**: All functionality accessible via keyboard
- [ ] **Color Contrast**: 4.5:1 minimum contrast ratio
- [ ] **Text Scaling**: Support 200% text scaling without horizontal scroll
- [ ] **Focus Indicators**: Clear focus indicators for all interactive elements

#### **Site-Specific Accessibility Features**
- **CEB Site**: High contrast mode for field conditions
- **Member Site**: Clear learning progression indicators
- **Help Center**: Accessibility-first design with request system
- **Technical Site**: Screen reader-friendly code examples

---

## 🧪 **User Journey Testing**

### **Officer Journey (CEB Site)**
1. **Login** → CEB site dashboard
2. **Quick Action** → Access emergency procedures
3. **Training Module** → Complete financial oversight training
4. **Cross-Site** → Navigate to technical documentation for API reference
5. **PDF Generation** → Create officer training certificate

### **Member Journey (Member Site)**
1. **Login** → Member home page
2. **Training Portal** → Start "Getting Started" learning path
3. **Progress Tracking** → Complete steps and track progress
4. **Quick Help** → Use password reset feature
5. **Cross-Site** → Access help center for accessibility support

### **Support Journey (Help Center)**
1. **Access** → Visit help center (guest or authenticated)
2. **Search** → Search for "profile update"
3. **Quick Solution** → Use contact support feature
4. **Accessibility** → Request accommodation
5. **Cross-Site** → Navigate to member training for detailed guide

### **Developer Journey (Technical Site)**
1. **Access** → Technical documentation section
2. **Filter** → Filter by "Epic Documentation"
3. **Code Example** → Copy Apex code snippet
4. **API Reference** → Review integration documentation
5. **Cross-Site** → Link to help center for support escalation

---

## 📊 **Success Validation**

### **Key Performance Indicators**
Monitor these metrics after deployment:

#### **User Experience Metrics**
- **Time to Information**: <30 seconds to find relevant training
- **Mobile Usage**: >50% mobile access for member training
- **Completion Rates**: >80% learning path completion
- **Search Success**: >85% successful help center searches

#### **Technical Performance**
- **Page Load Times**: <3 seconds on all sites
- **Component Response**: <1 second interaction response
- **Mobile Performance**: Core Web Vitals "Good" rating
- **Accessibility Score**: 100% automated testing compliance

#### **Business Impact**
- **Officer Efficiency**: 50% faster training completion
- **Member Self-Service**: 75% reduction in support tickets
- **Help Center Resolution**: 85% first-contact resolution
- **Developer Satisfaction**: 90% technical documentation approval

---

## 🚀 **Go-Live Checklist**

### **Pre-Launch Validation** (Complete Before User Access)
- [ ] All four components deployed and configured
- [ ] Site-specific content organized and accessible
- [ ] Cross-site navigation functional
- [ ] Mobile responsiveness validated
- [ ] Accessibility compliance verified
- [ ] PDF generation working across all sites
- [ ] User permissions configured correctly
- [ ] Analytics tracking implemented

### **Launch Day Activities**
1. **Soft Launch**: Enable for CEB officers first
2. **Officer Training**: Train CEB officers on new interface
3. **Member Rollout**: Enable for all members
4. **Support Monitoring**: Monitor help center for issues
5. **Technical Validation**: Verify all integrations working

### **Post-Launch Monitoring** (First 30 Days)
- **Daily**: Monitor usage analytics and error reports
- **Weekly**: Review user feedback and support tickets
- **Bi-weekly**: Performance optimization and content updates
- **Monthly**: Complete success metrics review and optimization planning

---

## 🏆 **Revolutionary Training Experience Ready!**

This configuration guide enables the **most advanced veteran organization training platform** with:

- **User-Centered Design**: Optimized for specific workflows and needs
- **Cross-Site Integration**: Seamless experience across all platforms
- **Mobile Excellence**: Full functionality on all devices
- **Accessibility Leadership**: WCAG 2.1 AA compliance with veteran-specific accommodations
- **Scalable Architecture**: Foundation for multi-chapter expansion

**🏍️ Combat Veterans Motorcycle Association Chapter 20-7**
**Vets Serving Vets through Revolutionary Training Excellence**

*Follow this guide to configure the complete site-specific training experience and revolutionize how CVMA delivers training to officers, members, and technical staff.*
