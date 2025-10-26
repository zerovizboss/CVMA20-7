# Epic #3: CEB Decision Request - Knowledge Article Publication Strategy

**Created**: October 25, 2025
**Epic**: #3 - Knowledge Article Foundation
**Status**: Awaiting CEB Decision
**Decision Deadline**: Before Phase 2 Implementation

---

## 🎯 Decision Required

**Where should CEB members publish completed documents for Member access?**

The technical foundation is complete (107 Google Drive files, helper classes, POC validated). Before building the publication workflow, we need to decide on the **Member-facing publication page strategy**.

---

## 📋 Three Options

### **Option 1: Dedicated "Member Documents" Page** ⭐ RECOMMENDED

**What It Is**:
- Single centralized page called "Member Documents" or "Chapter Documents"
- All published documents appear here (Meeting Minutes, Treasury Reports, etc.)
- Organized by tabs or filters (by category, CEB role, date)
- Added to Member navigation menu

**User Experience**:
```
Member clicks "Documents" → Sees all published content organized by type
- Tab: Meeting Minutes (Secretary publications)
- Tab: Financial Reports (Treasurer publications)
- Tab: Event Plans (Road Captain publications)
- Search bar + filters (date range, category, keyword)
```

**Pros**:
- ✅ Single source of truth (members know exactly where to look)
- ✅ Easy to find (one click from navigation)
- ✅ Supports powerful search and filtering
- ✅ Professional presentation (looks like a corporate knowledge base)
- ✅ Scales well (add new categories without structural changes)

**Cons**:
- ⚠️ Requires creating a new Experience Cloud page
- ⚠️ Less obvious which CEB role published what (solved with filters)

**Development Effort**: ~4-6 hours (create page, configure components, add to navigation)

---

### **Option 2: Role-Specific Publication Pages**

**What It Is**:
- Each CEB role has their own "Resources" or "Publications" page
- Secretary page shows Secretary's meeting minutes
- Treasurer page shows Treasurer's reports
- Road Captain page shows Road Captain's ride plans

**User Experience**:
```
Member clicks "Secretary" → Sees Secretary Resources page
- Recent Meeting Minutes (last 6 months)
- Historical archives link
- Secretary contact info

Member clicks "Treasurer" → Sees Treasurer Resources page
- Monthly Financial Reports
- Annual summaries
- Treasurer contact info
```

**Pros**:
- ✅ Clear ownership (know who published what)
- ✅ Natural fit for org structure (mirrors CVMA roles)
- ✅ Can include role-specific context and instructions
- ✅ Easy for CEB to manage their own publications

**Cons**:
- ⚠️ Members must know which role publishes what (learning curve)
- ⚠️ Harder to search across all documents
- ⚠️ More navigation clicks to find content
- ⚠️ Requires creating 7 separate pages (one per CEB role)

**Development Effort**: ~10-14 hours (7 pages × 1.5 hours each, plus shared components)

---

### **Option 3: Hybrid Approach** ⭐ MOST FLEXIBLE

**What It Is**:
- **Primary hub**: "Member Documents" page (all documents in one place)
- **Secondary access**: Each CEB role page has "Recent Publications" section
- **Tertiary access**: Dashboard and SAA Corner show relevant documents

**User Experience**:
```
Journey 1 (Document-focused user):
Member clicks "Documents" → Sees everything organized by category

Journey 2 (Role-focused user):
Member clicks "Treasurer" → Sees Treasurer page with "Recent Reports" section

Journey 3 (Dashboard user):
Member visits home dashboard → Sees widget "Latest Financial Report"
```

**Pros**:
- ✅ Best of both worlds (hub + role pages)
- ✅ Documents accessible from multiple entry points
- ✅ Supports different user mental models
- ✅ Highly discoverable (find content multiple ways)
- ✅ Professional and user-friendly

**Cons**:
- ⚠️ Most development effort upfront
- ⚠️ More components to maintain
- ⚠️ Potential for duplication if not designed carefully

**Development Effort**: ~8-12 hours (hub page + role page enhancements + widgets)

---

## 🎯 Our Recommendation: **Option 3 (Hybrid)**

### **Why We Recommend Hybrid**:

1. **Different users think differently**:
   - Some members want "all meeting minutes" (hub serves them)
   - Some members want "what did the Treasurer publish?" (role page serves them)
   - Hybrid supports both mental models

2. **Discoverability**:
   - New members can explore via hub (see everything)
   - Experienced members can go directly to role pages (faster)
   - Dashboard promotes latest content (engagement)

3. **CEB flexibility**:
   - CEB can decide later which pages to emphasize
   - Can promote hub OR role pages in announcements
   - Not locked into one approach

4. **Future-proof**:
   - Easy to add new publication types (Commander updates, Chaplain messages)
   - Easy to add new access points (mobile app, email digests)
   - Supports evolving CEB needs

### **Implementation Plan** (If Option 3 Chosen):

**Phase 2A: Member Documents Hub** (4-6 hours)
- Create "Member Documents" page
- Add Lightning Knowledge component with category filters
- Configure search and sorting
- Add to Member navigation menu

**Phase 2B: Role Page Enhancements** (3-4 hours)
- Add "Recent Publications" section to Secretary page
- Add "Recent Publications" section to Treasurer page
- Add "Recent Publications" section to other CEB role pages (as needed)
- Use shared Lightning Web Component (reusable)

**Phase 2C: Dashboard Widgets** (2-3 hours)
- Add "Latest Meeting Minutes" widget to member dashboard
- Add "Latest Financial Report" widget to member dashboard
- Add "Upcoming Events" widget (Road Captain content)

**Total Effort**: 9-13 hours (spread across multiple sessions)

---

## 📊 Comparison Matrix

| Criteria | Option 1 (Hub Only) | Option 2 (Role Pages) | Option 3 (Hybrid) |
|----------|---------------------|----------------------|-------------------|
| **Ease of Finding Documents** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Search & Filter Power** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Clear Role Ownership** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Development Effort** | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **Maintenance Effort** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **User Flexibility** | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Scalability** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Professional Look** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## ❓ Questions for CEB to Consider

### **User Behavior Questions**:
1. How do members currently ask for documents?
   - "Where is the latest meeting minutes?" (suggests hub approach)
   - "Can the Secretary send me the agenda?" (suggests role page approach)

2. Do members know which CEB role publishes what?
   - If YES → Role pages might work well
   - If NO → Hub with clear categories is better

3. How often do members need historical documents?
   - Often → Strong search/filter is critical (favors hub)
   - Rarely → Recent publications are enough (favors role pages)

### **CEB Workflow Questions**:
1. Should documents require approval before publication?
   - YES → Add approval step to workflow
   - NO → Secretary/Treasurer publish directly (faster)

2. Who should be notified when new documents are published?
   - All members → Email digest
   - Just CEB → In-app notification
   - Configurable by member → Preference settings

3. How should archived documents be handled?
   - Keep visible indefinitely → Archive filter/view
   - Auto-archive after X months → Scheduled job
   - Manual archival → CEB action

---

## 🗳️ Decision Template

**CEB Commander**: Please select one of the following and provide any additional context:

```
☐ Option 1: Member Documents Hub Only
  Reason: _________________________________________________

☐ Option 2: Role-Specific Publication Pages
  Reason: _________________________________________________

☐ Option 3: Hybrid Approach (Hub + Role Pages + Widgets)
  Reason: _________________________________________________

☐ Other (Please Describe):
  _________________________________________________________
```

**Additional Requirements**:
- Approval workflow needed? ☐ Yes ☐ No
- Email notifications? ☐ Yes ☐ No
- Preferred page name: _____________________________________
- Other considerations: ____________________________________

---

## 🚀 What Happens After Decision

Once CEB decides on publication strategy:

1. **User zerov updates this document** with decision
2. **Phase 2 implementation begins**:
   - Create selected page(s)
   - Build publication workflow
   - Configure Knowledge Article integration
   - Test with CEB members
3. **CEB testing period** (1-2 weeks)
4. **Feedback and refinement**
5. **Production deployment** to all members
6. **Training/announcement** to membership

**Estimated Timeline**: 2-3 weeks from decision to production (depending on option chosen)

---

## 📝 Notes

- This decision affects **Member experience only** (CEB creation workflows are independent)
- Can change publication strategy later (but involves rework)
- Starting with Option 1 and adding Option 3 features later is possible
- Starting with Option 3 and removing features is easier than adding later

**Recommendation**: Choose Option 3 for maximum flexibility, or Option 1 if development time is a constraint.

---

**Decision Maker**: Chapter Commander (with input from CEB)
**Decision Status**: ⏳ PENDING
**Decision Date**: _____________
**Decided Option**: _____________
**Notes**: _________________________________________________
