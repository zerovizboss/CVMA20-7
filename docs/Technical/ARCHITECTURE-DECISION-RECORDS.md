# Architecture Decision Records (ADR)

**Purpose**: Document significant technical decisions, rationale, and future review triggers for CVMA Chapter 20-7 Salesforce project.

---

## ADR-001: MCP Google Drive Package Selection (Epic #12)

**Date**: October 21, 2025
**Status**: ✅ ACCEPTED
**Decision Maker**: CVMA Development Team
**Review Date**: April 2026 (6-month review)

### **Context**

Epic #12 requires Google Drive integration to solve Developer Edition storage constraints (20 MB limit). We evaluated three approaches:
1. V2_Gdrive AppExchange package (50-100 Salesforce components)
2. Google MCP Server integration (minimal Salesforce footprint)
3. Direct Google Drive API integration in Apex

### **Decision**

**Selected**: `@modelcontextprotocol/server-gdrive` (Anthropic official MCP package)

**Despite**: Deprecation warning ("Package no longer supported")

### **Rationale**

#### **Why This Package?**
1. **Official Anthropic Package** - Created specifically for Claude Code MCP integration
2. **Zero Cost** - MIT license, Google Drive API is free
3. **Already Functional** - Deprecation ≠ broken, current version works
4. **Fast Implementation** - 5 story points vs 13+ for alternatives
5. **Minimal Salesforce Footprint** - Only custom metadata (~500 bytes/file vs MB of actual files)
6. **Simple OAuth2 Authentication** - User-friendly vs Service Account complexity

#### **Why Not Alternatives?**

**mcp-google-drive (v1.6.2, community-maintained)**
- ✅ Actively updated (Aug 2025)
- ❌ Requires Service Account credentials (more complex setup)
- ❌ Community-maintained (no official support)
- ⚠️ Migration cost: 30-60 minutes if current package fails

**@sowonai/mcp-google-drive (v0.3.2)**
- ❌ Older version (May 2025)
- ❌ Less feature-complete
- ❌ Community-maintained

**V2_Gdrive AppExchange Package**
- ❌ Adds 50-100 Salesforce components (defeats storage optimization goal)
- ❌ Consumes Developer Edition custom object/field limits
- ❌ Vendor lock-in

**Direct Google Drive API in Apex**
- ❌ 13+ story points (vs 5 for MCP)
- ❌ Complex OAuth setup in Salesforce
- ❌ More maintenance overhead

### **Risks & Mitigation**

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Package stops working | Low | Medium | Switch to `mcp-google-drive` (30-min swap) |
| Claude Code drops MCP support | Very Low | High | Migrate to V2_Gdrive or Direct API (2-3 sprints) |
| Google Drive API pricing changes | Very Low | High | Monitor Google Cloud announcements |
| OAuth token expires | Medium | Low | Refresh token flow already implemented |

### **Success Metrics**

- ✅ Salesforce storage reduction: 95%+ (target <1 MB metadata)
- ✅ File upload/download operations: <5 seconds per file
- ✅ CVMA document migration: 100% success rate
- ✅ Zero Salesforce API limit issues

### **Future Review Triggers**

**Review this decision if:**
1. ⚠️ **Package fails** - Stops working, critical bugs emerge
2. ⚠️ **Google Drive API pricing changes** - Free tier becomes paid
3. ⚠️ **Claude Code deprecates MCP** - Anthropic announces end-of-life
4. ⚠️ **Developer Edition upgraded** - If CVMA migrates to Enterprise Edition (removes storage constraints)
5. 📅 **6-Month Review** - April 2026 (scheduled re-evaluation)

**Action Items for Review:**
- Check `mcp-google-drive` package status (is it still maintained?)
- Evaluate V2_Gdrive package improvements
- Assess Direct API implementation complexity (has it decreased?)
- Review actual storage savings achieved

### **Implementation Notes**

**Installation**:
```bash
npm install -g @modelcontextprotocol/server-gdrive
# Deprecated warning acknowledged - package functional
```

**Configuration**:
- `.claude/mcp.json` - MCP server configuration
- Google OAuth credentials via existing `detonator@cvma20-7.org` account
- CVMA Google Drive folder: `1VblBnqHfQmjVDoRkO5mbgFnRGVPQv9Ej`

**Custom Metadata Type**:
- `CVMA_Google_Drive_File__mdt` - File metadata storage in Salesforce
- Fields: File_Name__c, Google_Drive_ID__c, File_Type__c, Category__c, Public_Link__c, Size_MB__c, etc.

### **References**

- Epic #12: `docs/Technical/Epic-Documentation/EPIC-12-GOOGLE-DRIVE-MCP-INTEGRATION.md`
- MCP Integration Manager Agent: `.claude/agents/mcp-integration-manager.md`
- GitHub Issue: #86
- Google Drive API Docs: https://developers.google.com/drive/api/guides/limits
- Model Context Protocol: https://modelcontextprotocol.io

### **Lessons Learned**

- **Deprecation warnings aren't blockers** - Evaluate functional status vs support status
- **Official packages preferred** - Even deprecated, Anthropic packages have better Claude Code integration
- **Storage optimization > Feature richness** - Developer Edition constraints drive architectural decisions
- **Migration paths matter** - Always have Plan B (30-min swap to `mcp-google-drive`)

---

## ADR Template (For Future Decisions)

```markdown
## ADR-XXX: [Decision Title]

**Date**: YYYY-MM-DD
**Status**: PROPOSED | ACCEPTED | DEPRECATED | SUPERSEDED
**Decision Maker**: [Team/Individual]
**Review Date**: [Future review date]

### Context
[What problem are we solving? What constraints exist?]

### Decision
[What did we decide? What package/approach/pattern?]

### Rationale
[Why this choice? What alternatives were considered?]

### Risks & Mitigation
[What could go wrong? How do we mitigate?]

### Success Metrics
[How do we measure success?]

### Future Review Triggers
[When should we revisit this decision?]

### References
[Links to docs, issues, related decisions]
```

---

**Created**: October 21, 2025
**Last Updated**: October 21, 2025
**Next Review**: April 2026

🏍️ **CVMA Chapter 20-7 - Vets Serving Vets**
📚 **Architectural Excellence Through Documented Decisions**
