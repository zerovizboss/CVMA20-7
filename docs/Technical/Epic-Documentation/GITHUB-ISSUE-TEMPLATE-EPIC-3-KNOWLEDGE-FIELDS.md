# GitHub Issue: Lightning Knowledge Missing Default Body Field + Developer Edition Limitations

**Epic**: #3 - Resource Library
**Component**: Lightning Knowledge Architecture
**Severity**: Medium
**Type**: Documentation / Configuration Issue
**Date Discovered**: November 3, 2025
**Session**: Epic #3 Phase 1 Implementation

---

## Problem Statement

During Epic #3 Phase 1 implementation, user discovered two critical issues:

1. **Missing "Details" Field**: Implementation guide referenced a "Details" or "Detail" field on Knowledge object that does not exist
2. **Page Layout Cloning Unavailable**: Developer Edition does not support page layout cloning functionality

These issues caused implementation confusion and required real-time troubleshooting.

---

## Root Cause Analysis

### Issue #1: Non-existent "Details" Field

**Incorrect Assumption**: Lightning Knowledge has a default rich text body/content field (similar to Case object's Description field)

**Reality**: Knowledge__kav object only includes these standard fields:
- Title
- UrlName
- Summary
- ArticleNumber
- VersionNumber
- PublishStatus
- Language
- IsVisibleInPkb
- IsVisibleInCsp
- IsVisibleInPrm

**NO default body/content field exists** - must be created as custom field.

### Issue #2: Page Layout Cloning Limitation

**Incorrect Assumption**: All Salesforce orgs support page layout cloning

**Reality**: Developer Edition has limitations on page layout operations, including inability to clone existing layouts in certain contexts.

---

## Resolution/Approach

### Solution #1: Create Custom Rich Text Field for Article Body

Added Field 7 to implementation guide:

**Field Name**: Article_Content__c
**Field Label**: Article Content
**Data Type**: Rich Text Area
**Length**: 32,768 characters (maximum)
**Visible Lines**: 25
**Toolbar**: Full
**Purpose**: Primary body content for Knowledge articles

### Solution #2: Use Single Master Layout for All Record Types

**Developer Edition Workaround**:
1. Edit existing "Knowledge Layout" (master layout)
2. Add all 7 custom fields to single layout
3. Assign this layout to all 4 record types (Bylaws, Forms, SOP, Financial)
4. Result: All record types share same layout (acceptable for Phase 1)

**Alternative** (if separate layouts needed later):
- Use "New" button to create custom layouts manually (not "Clone")
- Time: ~10 minutes per layout

---

## Sources

### Official Salesforce Documentation

1. **Salesforce Knowledge Developer Guide** (Winter '26, Version 65.0)
   - URL: https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/salesforce_knowledge_dev_guide.pdf
   - Confirmation: Knowledge__kav default field schema
   - Finding: No default body/content field listed

2. **Lightning Knowledge Guide** (Winter '26)
   - URL: https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/lightning_knowledge_guide.pdf
   - Confirmation: Article configuration patterns
   - Finding: Custom fields required for rich text content

3. **Rich Text Fields in Knowledge Articles** (Salesforce Help)
   - URL: https://help.salesforce.com/s/articleView?id=sf.knowledge_rich_text_considerations.htm
   - Confirmation: Rich text fields must be created as custom fields
   - Best Practices: Field length and toolbar considerations

4. **KnowledgeArticle Object Reference**
   - URL: https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_knowledgearticle.htm
   - Confirmation: Standard field schema (no body field)

### Community Resources

5. **Salesforce Stack Exchange - Knowledge Article Body Display**
   - URL: https://salesforce.stackexchange.com/questions/112469/knowledge-article-not-displaying-body
   - Context: Common issue with missing article body content
   - Resolution: Custom rich text field required

6. **GitHub - KnowledgeArticleBodyContent Component**
   - URL: https://github.com/salesforce-experiencecloud/KnowledgeArticleBodyContent
   - Context: Experience Cloud component for displaying article content
   - Confirmation: References custom article content fields (no default body)

### Web Search Results

7. **Salesforce Ben - Lightning Article Editor Guide**
   - URL: https://www.salesforceben.com/how-to-use-lightning-article-editor-in-salesforce-a-quick-guide/
   - Context: Knowledge article creation best practices
   - Finding: Custom fields needed for article structure

8. **Web Search Query Results** (November 3, 2025)
   - Query: "Salesforce Knowledge object rich text field article body content field name Lightning Knowledge"
   - Key Finding: "There is no standard 'body' field in Lightning Knowledge. If you want fields like a rich text area to hold information, you need to add it as a custom field to the article type."
   - Common Field Names: Body__c, Question__c, Answer__c (all custom)

### Internal Resources

9. **Epic #3 Implementation Guide**
   - Path: `docs/Technical/Epic-Documentation/EPIC-3-PHASE-1-LIGHTNING-KNOWLEDGE-CORRECT-APPROACH.md`
   - Status: Updated with corrections
   - Change: Added Field 7 (Article_Content__c) and Developer Edition workarounds

10. **Session Documentation** (November 3, 2025)
    - User reported: "There is no field with either name [Details/Detail] and I didn't create a custom field for it either"
    - User reported: "There is no option for me to clone this page layout"
    - Real-time validation of issues during implementation

### Error Context

11. **User Observation** (November 3, 2025 Session)
    - Issue: Could not find "Details" or "Detail" field in Knowledge object field list
    - Issue: Page layout dropdown did not include "Clone" option
    - Environment: Developer Edition org (cvma20-7-dev-ed)
    - User Level: Senior Salesforce Developer (experienced validator)

---

## Implementation

### Changes Made

1. **Updated EPIC-3-PHASE-1-LIGHTNING-KNOWLEDGE-CORRECT-APPROACH.md**:
   - Changed: "6 Custom Fields" → "7 Custom Fields"
   - Added: Field 7 (Article_Content__c) with full specifications
   - Added: Developer Edition limitation callouts
   - Added: Single master layout approach (recommended)
   - Removed: References to non-existent "Details" field
   - Updated: Page layout section with manual creation instructions

2. **Updated NEXT-SESSION-PRIORITIES-NOVEMBER-03-2025.md**:
   - Updated field count from 6 to 7
   - Added Article_Content__c to field list

3. **Updated STORM_CLAUDE_CORE.md**:
   - Added: GitHub Issue Source Documentation Protocol
   - Requirement: All future issues must include source attribution
   - Template: Markdown format for consistent documentation

### Technical Specifications

**Field 7: Article_Content__c**
```
Label: Article Content
API Name: Article_Content__c
Type: Rich Text Area
Length: 32,768 characters
Visible Lines: 25
Toolbar: Full
Help Text: Main body content of the Knowledge article
Required: No (allow flexibility)
```

**Page Layout Strategy**:
- Single Layout: "Knowledge Layout" (master)
- Assigned To: All 4 record types (CVMA Bylaws, Forms, SOP, Financial Reports)
- Benefit: Simplifies maintenance, works around Developer Edition limitations

---

## Testing Validation

**User Validation** (November 3, 2025):
- ✅ Confirmed: No "Details" or "Detail" field exists on Knowledge__kav object
- ✅ Confirmed: Page layout clone option not available in Developer Edition
- ✅ Confirmed: URL data type successfully applied to Source_GoogleDrive_URL__c field
- ✅ Confirmed: User able to proceed with corrected instructions

**Expected Outcome**:
- User will create Article_Content__c field as Field 7
- User will edit single Knowledge Layout with all 7 custom fields
- User will assign master layout to all record types
- Test article creation will validate field accessibility

---

## Lessons Learned

### Architectural Assumptions to Avoid

1. ❌ **Never assume default body/content fields exist** on objects without verification
   - Always check official object schema documentation first
   - Knowledge__kav is unique - no default rich text content field

2. ❌ **Never assume Developer Edition has full Enterprise/Unlimited features**
   - Page layout cloning may not be available
   - Always provide manual workarounds for Developer Edition users

3. ✅ **Always validate field existence** before documenting in implementation guides
   - Use Setup → Object Manager → [Object] → Fields to verify
   - Cross-reference with official Salesforce object reference documentation

### Documentation Best Practices

1. ✅ **Provide fallback approaches** for feature limitations
   - Single master layout approach works universally
   - Manual "New" layout creation available when "Clone" isn't

2. ✅ **Include org edition callouts** when features may vary
   - Developer Edition limitations should be clearly marked
   - Provide workarounds specific to constrained environments

3. ✅ **User feedback is invaluable** for catching documentation errors
   - Senior developers provide excellent validation
   - Real-world implementation reveals assumption gaps

---

## Impact Assessment

### Session Cost

**Time Lost**: ~15 minutes (troubleshooting + documentation updates)
**Token Usage**: ~3K tokens (research + updates)
**User Impact**: Minimal - caught early in implementation (Field 3/7)

### Prevention Value

**Future Sessions**: Will not repeat this error
**Other Developers**: Clear documentation of Knowledge object field requirements
**STORM Protocols**: Updated with source documentation mandate

---

## Related Issues

- **GitHub Issue #89**: Lightning Knowledge Architecture Error - $150 Cost Impact (November 2, 2025)
  - Context: Custom object vs. Knowledge object fundamental error
  - Lesson: Verify Salesforce architecture patterns before implementation

- **This Issue**: Field schema and Developer Edition limitations
  - Context: Missing default field assumption + edition-specific features
  - Lesson: Validate object schemas and test edition-specific features

---

## Recommendations

### Immediate Actions

1. ✅ User creates Article_Content__c field (Field 7)
2. ✅ User edits Knowledge Layout with all 7 fields
3. ✅ User assigns Knowledge Layout to all record types
4. ✅ User proceeds with Epic #3 Phase 1 implementation

### Future Protocol Enhancements

1. **Object Schema Validation Checklist**:
   - [ ] Verify standard fields via Object Manager
   - [ ] Cross-reference official Salesforce documentation
   - [ ] Confirm field existence before documenting
   - [ ] Test in target org edition (Developer/Enterprise/Unlimited)

2. **Edition-Specific Testing**:
   - [ ] Call out Developer Edition limitations proactively
   - [ ] Provide workarounds for all documented features
   - [ ] Test procedures in actual target org when possible

3. **Source Documentation**:
   - [ ] All GitHub issues include source URLs
   - [ ] Research findings linked to official documentation
   - [ ] Community resources cited when applicable
   - [ ] Internal resource paths documented

---

## Acceptance Criteria

This issue is resolved when:

- [x] Article_Content__c field documented in implementation guide
- [x] Field 7 specifications added to Epic #3 Phase 1 guide
- [x] Developer Edition limitations documented
- [x] Single master layout approach documented
- [x] Page layout cloning workaround provided
- [x] STORM protocols updated with source documentation requirements
- [x] User able to proceed with corrected implementation

---

**Issue Status**: ✅ RESOLVED (November 3, 2025)

**Documentation Updated**:
- EPIC-3-PHASE-1-LIGHTNING-KNOWLEDGE-CORRECT-APPROACH.md
- NEXT-SESSION-PRIORITIES-NOVEMBER-03-2025.md
- STORM_CLAUDE_CORE.md

**User Impact**: Minimal - caught early, corrected in real-time

---

🏍️ **Vets Serving Vets - Chapter 20-7**

🎖️ Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
