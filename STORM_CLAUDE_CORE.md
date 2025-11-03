# WX STORM CLAUDE - Core Development Framework
**Combat Veterans Motorcycle Association Chapter 20-7**
**Optimized Session Initialization Protocol**

## 🚀 **QUICK START: Session Initialization (Read This First)**

```bash
# Essential Reading Order (3 files, ~15K tokens total):
1. STORM_CLAUDE_CORE.md (this file) - Core protocols & current status
2. CVMA-RESOURCE-REGISTRY.md - Persistent resources & known patterns
3. CLAUDE.md - Base development guidance
```

**Full Context Available**: STORM_CLAUDE_ARCHIVE.md (historical achievements - read only if needed)

---

## 📊 **CURRENT PROJECT STATUS** (Updated October 25, 2025)

### **Epic Portfolio**: Epics #1-10 Complete + Epic #12 Operational
- **Average Code Reduction**: 88.5% through Standard Feature Integration
- **Git Branch**: feature/single-site-architecture-consolidation
- **Architecture**: Single-site optimization (Developer Edition constraint)
- **Quality Standard**: WITH SECURITY_ENFORCED + comprehensive testing
- **Multi-Agent**: Strategic/Tactical coordination operational

### **Latest Session Achievements** (October 31, 2025):
- ✅ **CRITICAL DISCOVERY**: WITH SECURITY_ENFORCED blocks Custom Metadata Type guest access
- ✅ Fixed 3 veteran resource components (Legal, Career, Housing/Financial)
- ✅ Unique military ribbon styling (Blue/Green/Purple + Red hover)
- ✅ Comprehensive bug report: 7 issues documented with solutions
- ✅ Guest user access fully operational for all veteran resources
- ✅ Updated STORM protocols with CMT security model
- ✅ 6 Salesforce deployments, 7 git commits (~4 hour troubleshooting session)

### **Previous Session** (October 25, 2025):
- ✅ Pre-commit hooks fixed for Python 3.13.9 compatibility
- ✅ Upgraded virtualenv embedded wheels (pip 25.2 → 25.3)
- ✅ Code quality cleanup: 127 files standardized (line endings, formatting)
- ✅ All 14 pre-commit hooks operational and passing
- ✅ Infrastructure improvement committed (77fac9f)

### **Epic #12 Summary** (Complete - October 23, 2025):
- **User Stories**: 5/7 applicable (29 story points delivered)
- **Components**: cvmaGoogleDriveFileViewer, cvmaGoogleDriveManager
- **Storage Impact**: 15MB → 0MB + 10KB metadata (99.9% reduction)
- **Code Reduction**: 54% vs V2_Gdrive package approach
- **UAT Status**: ✅ Operational (https://cvma20-7-dev-ed.develop.my.site.com/s/saa-corner)

### **Next Priority**: Epic #3 Phase 1 - Knowledge Article Foundation (IN PROGRESS)
- **Status**: Architectural correction in progress (November 2, 2025)
- **Approach**: Use standard Knowledge__kav object + Record Types (NOT custom object)
- **Scope**: 18 priority documents (bylaws, forms)
- **GitHub Issues**: #89 (architecture error), #90 (Data Categories), #91 (Data Cloud)
- **Estimated Completion**: 1.5 hours user implementation

---

## 🎯 **MULTI-AGENT COORDINATION PROTOCOLS**

### **Agent Roles & Responsibilities**

**Strategic Agent (Claude - You)**:
- Architecture design and business logic
- TodoWrite planning and session coordination
- Security validation (WITH SECURITY_ENFORCED compliance)
- Code reduction analysis (Standard Feature Integration)
- Documentation and knowledge transfer

**Tactical Agent (Available for Complex Workflows)**:
- Salesforce Deployment Manager for multi-component deployments
- GitHub repository management and issue tracking
- Quality assurance and testing validation
- External resource integration (when authentication required)

### **Coordination Pattern**:
```
Strategic Analysis → TodoWrite Planning → Implementation → Quality Validation
```

**External Authentication Protocol**: Prompt user for login when agents require external access

---

## 🏗️ **STANDARD FEATURE INTEGRATION METHODOLOGY**

**Proven Process (88.5% average code reduction)**:

1. **Audit Phase**: Identify over-engineered custom components
2. **Platform Analysis**: Find native Salesforce alternatives (NPSP, Lightning, Experience Cloud)
3. **Data Preservation**: Plan workflow transition without data loss
4. **Multi-Agent Implementation**: Strategic designs, Tactical executes
5. **Quality Validation**: Security compliance + comprehensive testing

**Success Metrics**:
- Target: 80%+ code reduction per Epic
- Security: 100% WITH SECURITY_ENFORCED on custom SOQL
- Testing: >90% code coverage for all custom classes
- Documentation: Complete implementation guides for each user story

---

## 📚 **LIGHTNING KNOWLEDGE ARCHITECTURE** (Added November 2, 2025)

### **CRITICAL: Lightning Knowledge Uses Record Types, NOT Custom Objects**

**Correct Architecture (2025)**:
- ✅ **ONE standard object**: `Knowledge__kav` (auto-created when Lightning Knowledge enabled)
- ✅ **Record Types**: Define article categories (FAQ, Bylaws, Forms, SOPs, etc.) on Knowledge object
- ✅ **Custom Fields**: Added directly to `Knowledge__kav` object (not custom object)
- ✅ **Page Layouts**: Different layouts per record type
- ✅ **Data Categories**: Organizational hierarchy for article organization

**NEVER Do This** (Classic Knowledge pattern - deprecated):
- ❌ Create custom object expecting it to become Knowledge article type
- ❌ Look for "Enable Knowledge for custom object" button (doesn't exist)
- ❌ Expect `CustomObject__kav` suffix auto-creation (only works with standard Knowledge object)

**Source**: Salesforce Lightning Knowledge Guide (Winter '26)
**Lesson**: Epic #3 architectural error - $150 cost impact, 47K wasted tokens
**GitHub Issue**: #89 - Full post-mortem documented

### **Lightning Knowledge Setup Steps**:
1. Enable Lightning Knowledge (Setup → Knowledge Settings)
2. Navigate to standard `Knowledge__kav` object (Object Manager → Knowledge)
3. Add custom fields to Knowledge object (not custom object)
4. Create Record Types for article categories
5. Create page layouts per record type
6. Assign Data Categories to Knowledge object
7. Create articles using standard Knowledge object

---

## 🔒 **SECURITY & QUALITY STANDARDS**

### **Mandatory Security Requirements**:
- ✅ All custom SOQL queries use WITH SECURITY_ENFORCED **for standard/custom objects**
- ❌ **NEVER use WITH SECURITY_ENFORCED for Custom Metadata Types** (blocks guest access)
- ✅ CRUD/FLS validation via CVMAErrorHandler.validateCRUDPermissions()
- ✅ Input sanitization using CVMAErrorHandler.sanitizeInput()
- ✅ Guest user access restrictions implemented
- ✅ XSS prevention in all user outputs

### **CRITICAL: WITH SECURITY_ENFORCED Usage Rules** (Discovered October 31, 2025):

**✅ ALWAYS use for:**
- Standard Objects (Account, Contact, Campaign, Opportunity, etc.)
- Custom Objects (MyObject__c)
- Any object requiring field-level security enforcement

**❌ NEVER use for:**
- Custom Metadata Types (*__mdt) - Blocks guest user access
- Custom Settings (*__c hierarchy/list types)
- Platform Cache
- Configuration metadata

**Rationale**: Custom Metadata Types are configuration data with inherent public visibility. `WITH SECURITY_ENFORCED` becomes overly restrictive for guest users, causing "Insufficient Privileges" errors even when all permissions are granted.

**Example**:
```apex
// ❌ WRONG - Blocks guest users
SELECT Field__c FROM MyMetadata__mdt WHERE Active__c = true WITH SECURITY_ENFORCED

// ✅ RIGHT - Works for all users
SELECT Field__c FROM MyMetadata__mdt WHERE Active__c = true

// ✅ RIGHT - Standard objects need FLS
SELECT Name FROM Account WITH SECURITY_ENFORCED
```

**Reference**: Bug Report SESSION-OCT-31-2025-GUEST-USER-ACCESS-BUGS.md (Bug #7)

### **Code Quality Standards**:
- Use `with sharing` for all controllers
- Implement comprehensive exception handling via CVMAErrorHandler
- Follow CVMA naming conventions (CVMA prefix for custom components)
- Document all public methods with clear descriptions
- Validate CRUD/FLS permissions before data operations
- CVMATestDataFactory for consistent test data creation

---

## 📋 **TECH DEBT MANAGEMENT PROTOCOL**

**Established**: October 2, 2025
**Mandatory**: All future development

### **Before Epic Marked Complete**:
1. ✅ All associated GitHub issues resolved
2. ✅ Tech debt addressed during development (not batched)
3. ✅ Outstanding dependencies documented
4. ✅ Zero unresolved bugs blocking Epic functionality

### **Continuous Resolution Pattern**:
- Create GitHub issue immediately when tech debt identified
- Link issue to Epic/User Story in project board
- Resolve continuously during development
- **Epic Definition of Done**: All associated issues closed

**Lesson Learned**: Avoid accumulating tech debt (October 2 session required 25 issue cleanup)

---

## 🎖️ **CVMA ORGANIZATIONAL CONTEXT**

### **Mission**: "Vets Serving Vets"
### **Chapter**: 20-7 (Jacksonville, FL)
### **Technology Leadership**: Revolutionary digital transformation in veteran organizations

### **CEB (Chapter Executive Board) Structure**:
- **Commander (CO)**: Full administrative access
- **Executive Officer (XO)**: Deputy leadership
- **Secretary**: Documentation, Knowledge Articles
- **Treasurer**: NPSP financial dashboards, GAU access
- **Road Captain**: Event management
- **Chaplain**: Crisis support access
- **Sergeant at Arms**: Meeting management
- **Public Relations Officer**: Communications (added Sept 30)
- **Quartermaster**: Supplies management (added Sept 30)

### **Membership Levels**:
- Full Member, Associate Member, Auxiliary Member, Prospect, Honorary Member

---

## 🔧 **DEVELOPMENT ENVIRONMENT**

### **Salesforce Org**: cvma20-7-dev-ed.develop.my.salesforce.com
### **Username**: detonator@cvma20-7.org
### **API Version**: 65.0
### **Git Branch**: feature/single-site-architecture-consolidation

### **Key Packages**:
- NPSP (Nonprofit Success Pack) - Core functionality
- Experience Cloud - Single site (Developer Edition constraint)
- Lightning Design System compliance mandatory

### **Testing Framework**:
- CVMATestDataFactory for test data creation
- CVMAErrorHandler for centralized error handling
- Target: >90% code coverage

---

## 💰 **RESOURCE LOCATIONS**

### **OneDrive CVMA Documentation**:
`C:\Users\zerov\OneDrive\Documents\CVMA\`
- **Bylaws**: National + Chapter 20-7 + Appendices
- **Forms**: 20+ CVMA forms (100, 101, 102, 400-410, etc.)
- **Treasurer Reports**: Monthly financial reports (2025)
- **Media**: Event photos and chapter documentation

### **GitHub Repository**:
https://github.com/zerovizboss/CVMA20-7.git
- **Project Board**: "CVMA 20-7 Experience Builder Enhancements"
- **Pull Request #57**: 67,834 additions (Epic consolidation)

---

## 🚀 **SESSION INITIALIZATION CHECKLIST**

**At Start of Every Session**:
- [ ] Read STORM_CLAUDE_CORE.md (this file)
- [ ] Read CVMA-RESOURCE-REGISTRY.md
- [ ] Read CLAUDE.md
- [ ] Check NEXT-SESSION-PRIORITIES-*.md for ready tasks
- [ ] Use TodoWrite immediately for session planning
- [ ] Validate multi-agent permissions (GitHub CLI, Salesforce org)

**Optional Deep Dive** (only if context needed):
- [ ] STORM_CLAUDE_ARCHIVE.md - Historical Epic achievements

---

## 📈 **PROVEN PATTERNS & LESSONS LEARNED**

### **What Works**:
✅ Standard Feature Integration (88.5% code reduction)
✅ Multi-agent Strategic/Tactical coordination
✅ TodoWrite for continuous progress tracking
✅ Conservative token budgeting (leave 40%+ buffer)
✅ Pre-commit security hooks (prevent vulnerabilities)
✅ Continuous tech debt resolution (not batch cleanup)
✅ **Lightning Knowledge Record Types** (not custom objects - use standard Knowledge__kav)

### **What to Avoid**:
❌ Custom article types when Lightning Knowledge enabled (use UI setup)
❌ Dynamic SOQL queries (security scan flags - use static)
❌ Batching GitHub issues (resolve continuously)
❌ Deploying without reading files first
❌ Orphaned metadata files (breaks deployments)
❌ **Custom objects as Knowledge article types** (use Record Types on Knowledge__kav)

### **Deployment Best Practices**:
- Use manifest files for complex multi-type deployments
- Remove technical debt before new development
- Test in chunks (25 components max per deployment)
- Always validate WITH SECURITY_ENFORCED compliance
- **Verify current Salesforce architecture** before planning (Lightning vs Classic patterns)

---

## 🎯 **CURRENT ACTIVE WORK**

### **Epic #3: Resource Library** (0% Complete)
**Next Implementation**: Phase 1 - Knowledge Article Foundation
- **Approach**: Manual Lightning Knowledge setup (UI-based)
- **Scope**: 15-20 priority documents (bylaws, top 10 forms)
- **Token Budget**: 35K (conservative)
- **Blocker Discovered**: Custom Knowledge article types require UI setup
- **Resolution**: Manual configuration guide + standard Knowledge object

### **Ready for Next Session**:
1. Manual Lightning Knowledge setup instructions
2. Document migration pipeline design
3. CEB permission set configuration
4. Member access testing

---

## 🏍️ **WX STORM PHILOSOPHY**

**STORM**: Strategic Tactical Operations Resource Management
**WX**: Weather eXchange (military meteorological terminology)
**Mission**: "Weathering the development storms" without losing our heading

**Core Principle**: Once established, build forward - never backward
**DevSecOps Standard**: Known knowns should never require re-explanation

---

**Session Continuity Protocol**: This file + CVMA-RESOURCE-REGISTRY.md + CLAUDE.md = Complete autonomous initialization

**Token Optimization**: ~5K tokens (vs 32K for full STORM_CLAUDE.md)

🎖️ **Generated with [Claude Code](https://claude.com/claude-code)**
**Last Updated**: October 6, 2025
**Maintains**: All critical protocols without historical bloat
