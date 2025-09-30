# 🌐 Experience Builder Calendar Implementation Guide
## Standard Lightning Calendar + Campaign Events for Combat Veterans Site

**Date**: September 10, 2025
**Objective**: Implement standard Lightning Calendar component in Experience Builder for guest user and member access to Campaign events

---

## 🎯 IMPLEMENTATION STRATEGY

### **Target Site**: Combat_Veterans_Motorcycle_Association
- **Site Type**: ChatterNetworkPicasso (Experience Builder)
- **URL**: /s (primary community site)
- **Guest Profile**: Combat Veterams Motorcycle Association Profile
- **Target Page**: "Vets for Vets Rides" page

### **Component Approach**: Standard Lightning Calendar
- **Replace**: Custom LWC calendar components
- **Use**: Native Lightning Calendar component
- **Integration**: Campaign events via WhatId field
- **Access**: Guest user read-only, member full access

---

## 📊 VALIDATED INFRASTRUCTURE

### **✅ Campaign Events Ready**: **10 Events Available**
- **Testing Events** (Feb 23, 2025)
- **First Coast Honor Flight** (Apr 5, 2025)
- **Chapter Meetings** (Apr 6, May 10, 2025)
- **CVMA Nationals** (Jun 27-29, 2025)
- **CloudQnect Tech Call** (Jul 23, 2025)
- **Additional Events** (May 21, Jun 19, 2025)

### **✅ Guest User Configuration Confirmed**:
- **Active Guest User**: CVMA 20-7 Guest User
- **Profile**: Combat Veterams Motorcycle Association Profile
- **Campaign Access**: Read permissions confirmed
- **Event Access**: Non-private events accessible

### **✅ Security Framework Ready**:
- **Guest Access**: Campaigns and Events accessible with appropriate restrictions
- **Field-Level Security**: Financial data restricted, event details available
- **Sharing Sets**: Ready for Campaign guest access configuration

---

## 🔧 EXPERIENCE BUILDER IMPLEMENTATION

### **Step 1: Access Experience Builder**

#### **Navigate to Site Setup**:
1. **Setup → Digital Experiences → All Sites**
2. **Select**: Combat_Veterans_Motorcycle_Association
3. **Click**: Builder (Experience Builder interface)
4. **Navigate**: To "Vets for Vets Rides" page

#### **Page Configuration Access**:
- **Page Manager**: Access existing pages or create new calendar page
- **Component Library**: Standard Lightning components available
- **Template Options**: Lightning Community templates

### **Step 2: Add Standard Lightning Calendar Component**

#### **Component Selection**:
1. **Component Library → Standard Components**
2. **Find**: Lightning Calendar (standard component)
3. **Alternative**: Activity Timeline with Calendar view
4. **Drag & Drop**: To target page area

#### **Component Configuration Properties**:
```javascript
Component: Lightning Calendar
Properties:
  - Data Source: Events
  - Filter: WhatId != null (Campaign-linked events only)
  - Guest Access: Read-only
  - Default View: Month
  - Event Details: Show subject, date/time, description
  - Privacy Filter: IsPrivate = false (public events only)
```

### **Step 3: Campaign Event Filtering Configuration**

#### **Data Source Configuration**:
```apex
// Campaign Events Query for Calendar Component
Event Filter Criteria:
1. IsPrivate = false (public events)
2. WhatId != null (linked to Campaigns)
3. StartDateTime >= TODAY-30 (recent and future events)
4. WITH SECURITY_ENFORCED (guest user security)

Display Fields:
- Subject (event title)
- StartDateTime/EndDateTime (timing)
- Description (event details)
- Location (if available)
- WhatId (Campaign reference)
```

#### **Guest User Restrictions**:
```apex
Guest User Event Access:
✅ Event Subject and Description
✅ Date, Time, and Location
✅ Public Campaign information
❌ Private events (IsPrivate = true)
❌ Financial data (Campaign costs/revenue)
❌ Member-specific information
❌ Internal communications
```

### **Step 4: Page Layout and Design**

#### **Layout Configuration**:
1. **Page Template**: Choose Community template with calendar focus
2. **Header**: CVMA Chapter 20-7 branding
3. **Navigation**: Include calendar in main navigation menu
4. **Footer**: Contact information and chapter details

#### **Calendar Component Placement**:
```html
Page Structure:
├── Header (CVMA branding)
├── Navigation (Calendar link)
├── Main Content Area
│   ├── Calendar Component (primary)
│   ├── Event Filter Options (guest-appropriate)
│   └── Event Details Panel (expandable)
├── Sidebar (optional)
│   ├── Upcoming Events List
│   └── RSVP Information (members only)
└── Footer (chapter contact info)
```

### **Step 5: Member vs Guest User Experience**

#### **Guest User Experience**:
- **Calendar View**: Read-only month/week/day views
- **Event Details**: Basic information (subject, date, location, description)
- **No RSVP**: View-only access to public events
- **No Creation**: Cannot create or edit events
- **Campaign Links**: Can view Campaign summary information

#### **Member User Experience** (if authenticated):
- **Full Calendar Access**: All calendar views and navigation
- **RSVP Capability**: Can respond to Campaign events
- **Event Details**: Complete Campaign and event information
- **Personal Calendar**: Option to sync with personal calendar
- **Mobile Access**: Responsive design for mobile devices

---

## 🎨 DESIGN AND USER EXPERIENCE

### **Visual Design Guidelines**:

#### **CVMA Branding Integration**:
- **Colors**: CVMA red, black, and white color scheme
- **Logo**: CVMA Chapter 20-7 logo prominently displayed
- **Typography**: Professional, veteran-friendly fonts
- **Imagery**: Appropriate motorcycle and veteran imagery

#### **Accessibility Standards**:
- **WCAG 2.1 AA Compliance**: Standard Lightning Design System compliance
- **Screen Reader Support**: Proper ARIA labels and navigation
- **Keyboard Navigation**: Full keyboard accessibility
- **Color Contrast**: High contrast for veteran accessibility needs

#### **Mobile Responsiveness**:
- **Lightning Design System**: Native mobile responsiveness
- **Touch Navigation**: Optimized for mobile calendar navigation
- **Performance**: Fast loading on mobile devices
- **Offline Access**: Basic calendar caching where possible

### **User Interface Components**:

#### **Calendar Navigation**:
```html
Calendar Controls:
- Previous/Next Month navigation
- Today button (return to current date)
- View selector (Month/Week/Day)
- Event filter dropdown (Campaign type)
- Search functionality (event titles)
```

#### **Event Display**:
```html
Event Information:
- Event title (Campaign name + Event subject)
- Date and time (formatted for readability)
- Location (if provided)
- Description (truncated with "read more" option)
- Campaign link (for additional context)
```

---

## 🔐 SECURITY IMPLEMENTATION

### **Guest User Security Configuration**:

#### **Sharing Sets for Campaign Access**:
```
Setup → Sharing Settings → Sharing Sets
Name: CVMA_Guest_Campaign_Calendar
Object: Campaign
Access Level: Read Only
Users: Combat Veterams Motorcycle Association Profile
Criteria: IsActive = true AND Type IN ('Event', 'Public', 'Community')
```

#### **Event Object Security**:
```
Guest User Event Access:
- Object Permission: Read (via sharing sets)
- Field Access: Subject, StartDateTime, EndDateTime, Description, Location
- Record Access: IsPrivate = false only
- Create/Edit: Disabled for guest users
```

### **Data Privacy Controls**:
- **Member Information**: No personal member data exposed to guests
- **Financial Data**: Campaign financial information restricted
- **Internal Communications**: Private notes and internal details hidden
- **RSVP Data**: Member RSVP information protected

---

## 📱 MOBILE AND EXTERNAL INTEGRATION

### **Mobile Experience Builder**:
- **Responsive Design**: Automatic mobile optimization
- **Touch Interface**: Mobile-friendly calendar navigation
- **Performance**: Optimized for mobile data usage
- **App Integration**: Works within Salesforce mobile app

### **External Calendar Integration Preparation**:
- **Google Calendar Sync**: Framework ready for member calendar sync
- **iCal Export**: Standard calendar export functionality
- **RSS Feed**: Event feed for external consumption
- **Embed Options**: Calendar widget for external websites

---

## 🚀 DEPLOYMENT AND TESTING

### **Pre-Deployment Testing**:

#### **Guest User Testing Checklist**:
- [ ] Guest user can access calendar page without authentication
- [ ] Only public events (IsPrivate = false) are visible
- [ ] Campaign information displays appropriately
- [ ] No sensitive financial or member data exposed
- [ ] Mobile responsiveness works correctly
- [ ] Calendar navigation functions properly

#### **Member User Testing** (if applicable):
- [ ] Authenticated members see appropriate events
- [ ] RSVP functionality works (if implemented)
- [ ] Campaign details accessible
- [ ] Personal calendar sync options available

### **Performance Testing**:
- **Load Time**: Calendar page loads within 3 seconds
- **Event Count**: Handles 100+ events without performance issues
- **Mobile Performance**: Smooth navigation on mobile devices
- **Concurrent Users**: Supports multiple guest users simultaneously

### **Security Testing**:
- **Access Controls**: Guest users cannot access restricted events
- **Data Exposure**: No sensitive information visible to guests
- **Authentication**: Proper guest/member access separation
- **Error Handling**: Graceful handling of permission errors

---

## 📈 SUCCESS METRICS AND MONITORING

### **User Engagement Metrics**:
- **Page Views**: Calendar page traffic and engagement
- **Event Clicks**: Guest user interaction with event details
- **Time on Page**: Calendar browsing duration
- **Mobile Usage**: Percentage of mobile calendar access

### **Technical Performance Metrics**:
- **Load Times**: Calendar component loading performance
- **Error Rates**: Failed calendar loads or data access errors
- **Uptime**: Calendar availability and reliability
- **Security Events**: Any unauthorized access attempts

### **Business Impact Metrics**:
- **Event Awareness**: Increased visibility of CVMA events
- **Community Engagement**: Guest user interest in chapter activities
- **Member Recruitment**: Calendar visibility impact on membership
- **Event Attendance**: Correlation between calendar access and participation

---

## 🏍️ VETS SERVING VETS MISSION IMPACT

### **Community Outreach Enhancement**:
- **Public Event Visibility**: Veterans can easily discover CVMA activities
- **Accessibility**: Web-based calendar accessible to all veterans
- **Information Transparency**: Clear event information builds trust
- **Community Integration**: Events visible to broader veteran community

### **Member Experience Improvement**:
- **Convenience**: Easy calendar access improves member engagement
- **Mobile Access**: Calendar available anywhere, anytime
- **Event Coordination**: Better visibility into chapter activities
- **Professional Image**: Modern calendar reflects chapter innovation

### **Operational Benefits**:
- **Reduced Administration**: Automatic calendar updates reduce manual work
- **Improved Communication**: Real-time event information for all users
- **Enhanced Planning**: Better visibility into chapter event schedule
- **Technology Leadership**: Positions chapter as technology-forward organization

---

## ✅ IMPLEMENTATION READINESS STATUS

### **✅ Prerequisites Confirmed**:
- **Combat_Veterans_Motorcycle_Association site**: Active and accessible
- **Guest User Profile**: Combat Veterams Motorcycle Association Profile operational
- **Campaign Events**: 10 events ready for calendar display
- **Event-Campaign Links**: WhatId relationships established
- **Security Framework**: Guest access permissions validated

### **✅ Ready for Implementation**:
- **Experience Builder Access**: Site builder available for configuration
- **Standard Components**: Lightning Calendar component available
- **Data Source**: Campaign events ready for display
- **Security Model**: Guest and member access controls defined
- **Mobile Support**: Responsive design framework ready

### **⚡ Next Steps for Implementation**:
1. **Access Experience Builder** for Combat_Veterans_Motorcycle_Association site
2. **Navigate to "Vets for Vets Rides" page** or create dedicated calendar page
3. **Add Lightning Calendar component** from standard component library
4. **Configure event filtering** for Campaign-linked, non-private events
5. **Test guest user access** and verify appropriate event visibility
6. **Deploy and announce** calendar availability to community

**Status**: ✅ **IMPLEMENTATION READY** - Experience Builder calendar setup guide complete

---

*Generated for Enhanced Campaign-Calendar Integration*
*Combat Veterans Motorcycle Association Chapter 20-7*
*Vets Serving Vets through Experience Builder Calendar Excellence*
