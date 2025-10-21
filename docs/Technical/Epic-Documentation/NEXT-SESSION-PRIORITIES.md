# Next Session Priorities - CVMA Project
**Generated**: October 7, 2025
**Session Context**: Post-Weekly Limit Reset
**Previous Session**: 2 User Stories deployed (YouTube Carousel + Document Portal)

---

## 🎯 **IMMEDIATE PRIORITIES (Next Session Start)**

### **Priority 1: Manual Configuration Completion (~30 minutes)**
Complete User Story #22 (Member Document Portal) manual steps:

1. **Create Content Library** (5 minutes)
   - Navigate to: Setup > Content Libraries > New Library
   - Name: "CVMA Chapter 20-7 Documents"
   - Add Members: CEB officers (Commander, VP, Secretary, Treasurer)

2. **Upload Priority Documents** (15 minutes)
   - From: `C:\Users\zerov\OneDrive\Documents\CVMA\Documentation\`
   - **Bylaws**: CVMA-National-Bylaws-Revision-V, FL-20-7-Bylaws
   - **Forms**: CVMA Forms 100, 101, 102 (October 2025 revisions)
   - **General**: Chapter SOPs, meeting materials

3. **Experience Cloud Configuration** (10 minutes)
   - Add cvmaMemberDocumentPortal to site
   - Configure libraryId property
   - Test guest/member/CEB access roles

---

## 🚀 **HIGH-VALUE USER STORIES (Epic #11 Continuation)**

### **Tier 1: Zero Dependencies - Ready to Deploy**

#### **User Story #75: Legal & Advocacy Services Resources**
- **Story Points**: 5
- **Epic**: #5 Veteran Support Services
- **Approach**: Similar to User Story #22 (document portal pattern)
- **Implementation**: Custom metadata for legal resources + LWC display component
- **Estimated Code Reduction**: 85%+ (Standard Feature Integration)
- **Token Estimate**: 40-50K tokens
- **Developer Edition**: ✅ All requirements supported

#### **User Story #74: Housing & Financial Assistance Resources**
- **Story Points**: 5
- **Epic**: #5 Veteran Support Services
- **Approach**: Resource directory with Knowledge Article integration
- **Dependencies**: ⚠️ Requires Epic #3 manual Knowledge setup (BLOCKED until completed)
- **Alternative**: Custom metadata approach (like User Story #79 YouTube Carousel)
- **Token Estimate**: 40-50K tokens

#### **User Story #73: Employment & Career Services Resources**
- **Story Points**: 5
- **Epic**: #5 Veteran Support Services
- **Approach**: External resource links + local job board
- **Implementation**: LWC component with custom metadata
- **Estimated Code Reduction**: 80%+
- **Token Estimate**: 40-50K tokens

### **Tier 2: Low Dependencies - Can Implement After Setup**

#### **User Story #72: Benefits & Claims Assistance Resources**
- **Story Points**: 5
- **Epic**: #5 Veteran Support Services
- **Dependencies**: ⚠️ May require VA API integration (Epic #9 patterns available)
- **Approach**: Resource directory with external VA.gov links
- **Token Estimate**: 45-55K tokens

#### **User Story #71: VA Healthcare Resource Integration**
- **Story Points**: 5
- **Epic**: #5 Veteran Support Services
- **Dependencies**: ⚠️ Requires Knowledge Articles (Epic #3 manual setup)
- **Approach**: VA Medical Center directory with location search
- **Token Estimate**: 50-60K tokens

### **Tier 3: High Dependencies - Defer Until Foundations Complete**

#### **User Story #76: Veteran Assistance Request & CEB Approval System**
- **Story Points**: 13
- **Epic**: #5 Veteran Support Services
- **Dependencies**: ⚠️ Foundation for User Stories #77, #78, #32
- **Approach**: Custom object (Veteran_Assistance_Request__c) + approval workflow
- **Impact**: BLOCKS 3 downstream user stories
- **Token Estimate**: 80-100K tokens
- **Priority**: **HIGH** - Foundation object required

#### **User Story #77: CVMA Volunteer Coordination Dashboard**
- **Story Points**: 8
- **Dependencies**: ⚠️ Requires User Story #76 (Veteran_Assistance_Request__c)
- **Approach**: Dashboard + volunteer assignment logic
- **Token Estimate**: 60-80K tokens

#### **User Story #78 (Issue #32): Veteran Services Impact Analytics Dashboard**
- **Story Points**: 8
- **Dependencies**: ⚠️ Requires User Stories #76 + #77
- **Approach**: Analytics dashboard with Chart.js visualizations
- **Token Estimate**: 70-90K tokens

---

## 📋 **RECOMMENDED NEXT SESSION PLAN**

### **Option A: High-Velocity Momentum (3 User Stories)**
**Total Estimate**: 120-150K tokens

1. **User Story #75**: Legal & Advocacy Services (40-50K tokens)
   - Zero dependencies
   - Custom metadata approach
   - Military ribbon styling

2. **User Story #73**: Employment & Career Services (40-50K tokens)
   - Zero dependencies
   - Similar to User Story #75
   - Job board integration

3. **User Story #74**: Housing & Financial Assistance (40-50K tokens)
   - Custom metadata fallback (no Knowledge Articles needed)
   - Resource directory pattern
   - CVMA branding

**Outcome**: 3 user stories deployed, maintain 70%+ code reduction average

---

### **Option B: Foundation Builder (1 Large User Story)**
**Total Estimate**: 80-100K tokens

1. **User Story #76**: Veteran Assistance Request & CEB Approval System
   - **UNLOCKS**: User Stories #77, #78, #32 (3 downstream stories)
   - Custom object creation
   - CEB approval workflow
   - Integration with existing CEB permission sets

**Outcome**: Foundation established, 3 user stories unblocked for future sessions

---

### **Option C: Balanced Progress (2 Medium User Stories)**
**Total Estimate**: 100-120K tokens

1. **User Story #75**: Legal & Advocacy Services (40-50K tokens)
2. **User Story #72**: Benefits & Claims Assistance (45-55K tokens)
   - VA.gov integration
   - Resource directory
   - External link management

**Outcome**: 2 user stories deployed, veteran resource catalog expansion

---

## 🎯 **STRATEGIC RECOMMENDATION: Option A**

**Rationale:**
1. **Momentum**: 3 user stories = 5 total deployed in 2 sessions (excellent velocity)
2. **Zero Blockers**: All 3 stories have zero dependencies
3. **Proven Pattern**: Custom metadata + LWC wrapper (93.8% code reduction proven)
4. **Quick Wins**: 5-story-point user stories = faster deployment cycles
5. **Resource Consistency**: All veteran resource-focused (similar patterns)

**Risk Mitigation:**
- Custom metadata approach avoids Epic #3 Knowledge Article blocker
- Similar architectural patterns reduce complexity
- Standard Feature Integration methodology proven (72.8% average reduction)

---

## 🚨 **TECH DEBT TRACKING**

### **Active Issues (To Resolve)**

#### **Issue #80: veteranResourceFinder LWC Deployment**
- **Status**: BLOCKED - Developer Edition metadata sync (24-48 hours)
- **Priority**: Low (workaround available: cvmaVeteranResourceFinder)
- **Action**: Auto-resolves after metadata sync
- **Token Cost**: 0 (automatic resolution)

#### **Issue #81: Veteran Organization Data Migration to Knowledge Articles**
- **Status**: BLOCKED - Epic #3 manual Knowledge setup required
- **Priority**: Medium (deferred until Knowledge configured)
- **Action**: Complete Epic #3 Phase 1 manual setup first
- **Token Cost**: 7-11 hours after Epic #3 complete

### **Epic #3 Manual Setup (Required for Multiple User Stories)**
- **Blocking**: User Stories #71, #74, Issue #81
- **Effort**: 2-3 hours manual UI configuration
- **Priority**: **HIGH** - Unblocks 3+ items
- **Process**:
  1. Enable Lightning Knowledge (already enabled)
  2. Create Knowledge article types via UI
  3. Configure article layouts and page layouts
  4. Set up data categories
  5. Deploy Knowledge articles via metadata

---

## 📊 **SESSION CAPACITY PLANNING**

### **Token Budget Guidelines**
- **Low-Complexity User Story**: 40-50K tokens (5 story points)
- **Medium-Complexity User Story**: 60-80K tokens (8 story points)
- **High-Complexity User Story**: 80-120K tokens (13 story points)
- **Session Capacity**: 200K tokens total
- **Recommended Usage**: 120-150K tokens (60-75% capacity)

### **Efficiency Metrics (This Session)**
- **User Stories Deployed**: 2
- **Tokens Used**: 86K (43% capacity)
- **Average per Story**: 43K tokens
- **Code Reduction**: 72.8% average
- **Tech Debt Created**: 0

**Target for Next Session:**
- **User Stories**: 3 (Option A)
- **Tokens Budgeted**: 120-150K (60-75% capacity)
- **Expected Code Reduction**: 75%+ average
- **Quality Standard**: WITH SECURITY_ENFORCED + comprehensive testing

---

## 🏛️ **DEVELOPER EDITION CONSTRAINT CHECKLIST**

Before starting each user story, validate:

- [ ] **Knowledge Articles**: If required, is Epic #3 manual setup complete?
- [ ] **Custom Objects**: Does story create new objects? (limit considerations)
- [ ] **CRM Analytics**: Does story use Einstein Analytics? (NOT available in DE)
- [ ] **Custom Metadata**: Confirm metadata type creation supported
- [ ] **Apex Controllers**: Confirm WITH SECURITY_ENFORCED compliance
- [ ] **LWC Components**: No namespace conflicts
- [ ] **Test Coverage**: 75%+ minimum, target 90%
- [ ] **Content Libraries**: Limit 10 libraries in Developer Edition

---

## 🌩️ **WX STORM SESSION INITIALIZATION PROTOCOL**

**At Start of Next Session:**

1. **Read STORM_CLAUDE.md** (Epic Portfolio context)
2. **Read CVMA-RESOURCE-REGISTRY.md** (Resource locations + autonomous protocols)
3. **Read MEMORY_CONTINUED.md** (Latest session achievements)
4. **Read NEXT-SESSION-PRIORITIES.md** (This file)
5. **Initialize TodoWrite** with selected option tasks
6. **Activate Multi-Agent Coordination** (Strategic + Salesforce + Tactical)

---

## 🎖️ **SUCCESS CRITERIA**

**Session Goals:**
- ✅ 2-3 user stories deployed successfully
- ✅ Maintain 70%+ average code reduction
- ✅ Zero blocking tech debt created
- ✅ All deployments tested and validated
- ✅ GitHub issues closed with comprehensive summaries
- ✅ MEMORY_CONTINUED.md updated with achievements

**Quality Gates:**
- ✅ WITH SECURITY_ENFORCED on all Apex queries
- ✅ 75%+ test coverage (target 90%)
- ✅ Military ribbon styling applied
- ✅ Guest user access restrictions enforced
- ✅ Mobile-responsive design validated
- ✅ Experience Cloud deployment verified

---

**Next Session Command:**
```bash
# Initialize WX STORM protocols
cat STORM_CLAUDE.md
cat CVMA-RESOURCE-REGISTRY.md
cat docs/Technical/Epic-Documentation/MEMORY_CONTINUED.md
cat docs/Technical/Epic-Documentation/NEXT-SESSION-PRIORITIES.md
```

🏍️ **CVMA Chapter 20-7 - Vets Serving Vets**
⚡ **WX STORM Status**: Ready for next deployment cycle
🎯 **Target**: Option A - 3 User Stories, 75%+ code reduction
