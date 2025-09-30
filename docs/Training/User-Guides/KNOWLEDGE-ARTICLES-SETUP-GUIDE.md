# Knowledge Articles Setup Guide
## CVMA Organizational Content Integration

### **Combat Veterans Motorcycle Association Chapter 20-7**
**Implementation Date**: September 23, 2025
**Purpose**: Structure Knowledge Articles for CVMA bylaws, SOPs, forms, and protocols
**Integration**: OneDrive documentation (`C:\Users\zerov\OneDrive\Documents\CVMA`)

---

## 🏗️ **KNOWLEDGE ARTICLES FOUNDATION SETUP**

### **Step 1: Enable Lightning Knowledge**
1. **Setup** → **Knowledge Settings** → **Lightning Knowledge**
2. **Enable Knowledge** if not already active
3. **Configure Settings**:
   - ✅ Enable Lightning Knowledge
   - ✅ Enable Article Creation
   - ✅ Enable Public Knowledge Base
   - ✅ Enable Article Auto-Complete
   - ✅ Enable External Media Content

### **Step 2: Create Data Categories**
1. **Setup** → **Data Category Setup**
2. **Create Category Group**: "CVMA Organizational Content"
3. **Create Categories**:

```
CVMA Organizational Content
├── Bylaws and Governance
│   ├── Chapter Bylaws
│   ├── National CVMA Constitution
│   ├── Amendment Procedures
│   └── Governance Protocols
├── Standard Operating Procedures
│   ├── Officer Procedures
│   │   ├── Commander Duties
│   │   ├── Vice Commander Duties
│   │   ├── Secretary Duties
│   │   └── Treasurer Duties
│   ├── Member Procedures
│   │   ├── Meeting Protocols
│   │   ├── Event Participation
│   │   └── Communication Standards
│   └── Chapter Operations
│       ├── Event Management
│       ├── Financial Procedures
│       └── Safety Protocols
├── Forms and Documentation
│   ├── Membership Forms
│   │   ├── Application Forms
│   │   ├── Renewal Forms
│   │   └── Transfer Forms
│   ├── Event Forms
│   │   ├── RSVP Forms
│   │   ├── Planning Forms
│   │   └── After Action Reports
│   └── Administrative Forms
│       ├── Officer Nomination
│       ├── Budget Requests
│       └── Incident Reports
├── Emergency Protocols
│   ├── Crisis Response
│   ├── Medical Emergencies
│   ├── Chapter Emergency Contacts
│   └── Escalation Procedures
└── Training Materials
    ├── New Member Orientation
    ├── Officer Training
    ├── Safety Training
    └── CVMA History and Values
```

### **Step 3: Configure Article Types**
1. **Setup** → **Knowledge Article Types**
2. **Create Article Types**:
   - **CVMA_Bylaw**: For official bylaws and governance
   - **CVMA_SOP**: For standard operating procedures
   - **CVMA_Form**: For forms and templates
   - **CVMA_Protocol**: For emergency and operational protocols
   - **CVMA_Training**: For training and educational content

---

## 📋 **ARTICLE TEMPLATE STRUCTURES**

### **CVMA Bylaw Template**
```html
<article class="cvma-bylaw-article">
    <header class="cvma-military-themed">
        <h1>{{Article Title}}</h1>
        <div class="cvma-article-meta">
            <span class="cvma-effective-date">Effective Date: {{Date}}</span>
            <span class="cvma-revision">Revision: {{Version}}</span>
            <span class="cvma-authority">Authority: {{Approving Body}}</span>
        </div>
    </header>

    <section class="cvma-article-summary">
        <h2>Summary</h2>
        <p class="cvma-summary-text">{{Brief description for quick reference}}</p>
    </section>

    <section class="cvma-article-content">
        <div class="cvma-content-body">
            {{Structured bylaw content with military-themed styling}}
        </div>
    </section>

    <section class="cvma-related-content">
        <h2>Related Documents</h2>
        <ul class="cvma-related-links">
            {{Links to related bylaws, SOPs, and forms}}
        </ul>
    </section>

    <footer class="cvma-article-footer">
        <div class="cvma-crisis-support">
            <p><strong>Need Help?</strong> Contact Chapter Support: {{Emergency Contact}}</p>
        </div>
    </footer>
</article>
```

### **CVMA SOP Template**
```html
<article class="cvma-sop-article">
    <header class="cvma-military-themed">
        <h1>{{SOP Title}}</h1>
        <div class="cvma-sop-meta">
            <span class="cvma-sop-number">SOP Number: {{Number}}</span>
            <span class="cvma-effective-date">Effective: {{Date}}</span>
            <span class="cvma-review-date">Next Review: {{Review Date}}</span>
        </div>
    </header>

    <section class="cvma-purpose">
        <h2>Purpose</h2>
        <p>{{Clear statement of SOP purpose and scope}}</p>
    </section>

    <section class="cvma-responsibilities">
        <h2>Responsibilities</h2>
        <div class="cvma-roles">
            {{Role-based responsibilities with military hierarchy respect}}
        </div>
    </section>

    <section class="cvma-procedures">
        <h2>Procedures</h2>
        <div class="cvma-step-by-step">
            {{Numbered steps with clear action items}}
        </div>
    </section>

    <section class="cvma-forms-references">
        <h2>Required Forms</h2>
        <ul class="cvma-form-links">
            {{Links to related forms and templates}}
        </ul>
    </section>
</article>
```

### **CVMA Emergency Protocol Template**
```html
<article class="cvma-emergency-protocol">
    <header class="cvma-critical-header">
        <h1>🚨 {{Emergency Protocol Title}}</h1>
        <div class="cvma-emergency-meta">
            <span class="cvma-urgency-level">{{Critical/High/Medium}}</span>
            <span class="cvma-contact-info">Emergency: {{Phone Number}}</span>
        </div>
    </header>

    <section class="cvma-immediate-actions">
        <h2>Immediate Actions</h2>
        <ol class="cvma-critical-steps">
            {{Step-by-step emergency response}}
        </ol>
    </section>

    <section class="cvma-contact-escalation">
        <h2>Emergency Contacts</h2>
        <div class="cvma-contact-grid">
            <div class="cvma-contact-card">
                <h3>Veterans Crisis Line</h3>
                <p class="cvma-contact-phone">📞 1-800-273-8255</p>
                <p class="cvma-contact-text">📱 Text: 838255</p>
                <p class="cvma-contact-chat">💬 veteranscrisisline.net</p>
            </div>
            <div class="cvma-contact-card">
                <h3>Chapter Emergency</h3>
                <p class="cvma-contact-info">{{Chapter Emergency Contact}}</p>
            </div>
        </div>
    </section>
</article>
```

---

## 🎖️ **MILITARY BRANDING IN ARTICLES**

### **CSS for Knowledge Articles**
Add to article templates:
```css
/* Military-themed article styling */
.cvma-bylaw-article,
.cvma-sop-article,
.cvma-emergency-protocol {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}

.cvma-military-themed {
    background: linear-gradient(90deg, #c41e3a 0%, #ffffff 50%, #0033a0 100%);
    background-size: 100% 5px;
    background-repeat: repeat-y;
    border-bottom: 3px solid #1c1c1c;
    padding: 20px;
    margin-bottom: 20px;
}

.cvma-critical-header {
    background: linear-gradient(135deg, #663399 0%, #ffffff 25%, #663399 50%, #ffffff 75%, #663399 100%);
    background-size: 20px 20px;
    border: 3px solid #4a1a4a;
    padding: 20px;
    margin-bottom: 20px;
    border-radius: 6px;
}

.cvma-article-meta,
.cvma-sop-meta,
.cvma-emergency-meta {
    display: flex;
    gap: 20px;
    margin-top: 10px;
    font-weight: bold;
    color: #1c1c1c;
}

.cvma-contact-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 20px;
    margin-top: 15px;
}

.cvma-contact-card {
    background: #f8f9fa;
    border: 2px solid #1c1c1c;
    padding: 15px;
    border-radius: 6px;
    text-align: center;
}

.cvma-contact-phone,
.cvma-contact-text,
.cvma-contact-chat {
    font-size: 18px;
    font-weight: bold;
    margin: 5px 0;
}

/* Responsive design for mobile */
@media (max-width: 768px) {
    .cvma-article-meta,
    .cvma-sop-meta,
    .cvma-emergency-meta {
        flex-direction: column;
        gap: 10px;
    }

    .cvma-contact-grid {
        grid-template-columns: 1fr;
    }
}
```

---

## 📄 **CONTENT MIGRATION FROM ONEDRIVE**

### **Step 1: Document Assessment**
From your OneDrive location: `C:\Users\zerov\OneDrive\Documents\CVMA`

**Suggested Migration Priority**:
1. **High Priority**: Emergency contacts, crisis protocols, basic bylaws
2. **Medium Priority**: Officer procedures, member guidelines, common forms
3. **Low Priority**: Historical documents, detailed procedures, reference materials

### **Step 2: Content Conversion Workflow**
```
OneDrive Document → Knowledge Article Conversion:
1. Review source document structure
2. Select appropriate article template (Bylaw/SOP/Protocol/Training)
3. Apply CVMA military styling
4. Add proper categorization
5. Include emergency contact information
6. Test mobile responsiveness
7. Validate accessibility compliance
```

### **Step 3: Batch Import Process**
1. **Create Article Template Library** with military styling
2. **Use CVMADocumentSharingController** for PDF generation
3. **Link Knowledge Articles** to ContentDocument for file attachments
4. **Configure Search** with military-themed faceting
5. **Test Integration** with cvmaUnifiedPortal component

---

## 🔍 **SEARCH OPTIMIZATION**

### **Article Search Configuration**
1. **Setup** → **Knowledge Settings** → **Search**
2. **Enable Features**:
   - ✅ Auto-complete suggestions
   - ✅ Category-based filtering
   - ✅ Content-based search
   - ✅ Mobile-optimized results

### **Search Categories**
Configure search filters matching military styling:
- 🎖️ **Bylaws & Governance** (Bronze Star styling)
- 🏅 **Officer Procedures** (Purple Heart styling)
- 🏆 **Member Guidelines** (GWOT Medal styling)
- 🚨 **Emergency Protocols** (Combat Action Ribbon styling)
- 📚 **Training Materials** (National Defense Medal styling)

---

## 🚨 **CRISIS SUPPORT INTEGRATION**

### **Emergency Article Requirements**
Every Knowledge Article must include:
```html
<div class="cvma-crisis-support-footer">
    <div class="cvma-emergency-banner">
        <h3>🚨 Crisis Support Available 24/7</h3>
        <div class="cvma-emergency-contacts">
            <a href="tel:1-800-273-8255" class="cvma-btn-purple-heart">
                📞 Veterans Crisis Line: 1-800-273-8255
            </a>
            <a href="sms:838255" class="cvma-btn-combat-action">
                📱 Text Crisis Line: 838255
            </a>
        </div>
        <p class="cvma-support-message">
            <strong>You are not alone.</strong> Professional support available immediately.
        </p>
    </div>
</div>
```

---

## 📱 **MOBILE OPTIMIZATION**

### **Mobile Article Design**
- **Touch-Friendly**: All crisis support buttons meet 44px minimum
- **Readable Text**: Minimum 16px font size on mobile
- **Simplified Navigation**: Collapsible sections for mobile reading
- **Fast Loading**: Optimize images and reduce unnecessary styling

### **Accessibility Features**
- **Screen Reader**: Proper heading hierarchy and ARIA labels
- **High Contrast**: Military styling maintains 4.5:1 contrast ratio
- **Keyboard Navigation**: Full functionality without mouse/touch
- **Focus Indicators**: Clear focus rings on all interactive elements

---

## 📊 **CONTENT GOVERNANCE**

### **Article Lifecycle Management**
1. **Creation**: Military-themed templates with crisis support
2. **Review**: Regular updates ensuring accuracy and relevance
3. **Approval**: Officer-level review for official documents
4. **Publication**: Audience-appropriate visibility settings
5. **Maintenance**: Scheduled reviews and updates

### **Quality Standards**
- **Military Branding**: Consistent ribbon styling throughout
- **Crisis Support**: Emergency contacts in every article
- **Accessibility**: WCAG 2.1 AA compliance validated
- **Mobile Responsive**: Tested across all device types
- **Content Accuracy**: Regular reviews by subject matter experts

---

## 🏍️ **INTEGRATION WITH UNIFIED PORTAL**

### **Component Integration Points**
The cvmaUnifiedPortal component will automatically:
1. **Display Articles** in the Knowledge Base section
2. **Apply Military Styling** using cvmaMilitaryAwardsCSS
3. **Filter by Role**: Show appropriate content based on user profile
4. **Enable Search**: Unified search across all organizational content
5. **Highlight Crisis Support**: Prominent emergency contact display

### **PDF Generation Integration**
Articles can be converted to PDF using:
```javascript
// Integration with CVMADocumentSharingController
const generateArticlePDF = async (articleId) => {
    const pdfId = await generateTrainingPDF({
        documentName: articleTitle,
        markdownContent: articleContent,
        targetAudience: userRole
    });
    // PDF includes military branding and crisis support information
};
```

---

## 🎖️ **SUCCESS CRITERIA**

### **Content Excellence**
- **Comprehensive Coverage**: All essential CVMA content available
- **Military Aesthetic**: Professional veteran organization appearance
- **Crisis Integration**: 24/7 support prominently featured
- **Role-Based Access**: Appropriate content for each user type

### **Technical Performance**
- **Fast Search**: <2 second response time
- **Mobile Optimized**: 100% functionality on mobile devices
- **Accessible**: WCAG 2.1 AA compliance achieved
- **Integration**: Seamless with cvmaUnifiedPortal component

### **Mission Impact**
- **Member Self-Service**: Reduced administrative burden
- **Officer Efficiency**: Streamlined access to procedures and forms
- **Crisis Support**: Immediate veteran assistance availability
- **Professional Standards**: Technology leadership in veteran organizations

---

**🎖️ Ready to transform your OneDrive CVMA documentation into a professional, military-themed Knowledge Articles system that honors veteran service while providing exceptional functionality and crisis support integration!**

**Next Step**: Begin migrating high-priority documents from `C:\Users\zerov\OneDrive\Documents\CVMA` using the templates and guidelines above.
