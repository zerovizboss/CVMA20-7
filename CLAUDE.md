# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🏍️ **ENHANCED DEVELOPMENT PROTOCOLS**

**CRITICAL**: For advanced multi-agent development protocols, revolutionary architecture patterns, and Strategic→TodoWrite→Tactical methodology, see **STORM_CLAUDE.md** - our enhanced development framework that extends beyond base CLAUDE.md capabilities.

**DEVOPS TEAM PROTOCOL**: For persistent resource references, established patterns, and context preservation, see **CVMA-RESOURCE-REGISTRY.md** - prevents "chasing our tail in the Storm" by maintaining known resources across sessions.

### **Required Session Initialization Files**:
1. **STORM_CLAUDE.md**: Epic status, multi-agent protocols, development methodology
2. **CVMA-RESOURCE-REGISTRY.md**: Persistent resources, known patterns, cultural context
3. **CLAUDE.md** (this file): Base development guidance and project overview

STORM_CLAUDE.md contains:
- Multi-agent coordination protocols (Strategic Agent + Tactical Agent)
- Standard Feature Integration methodology (88.5%+ average code reduction)
- Epic/User Story management patterns
- Session memory and continuity protocols
- Advanced Salesforce development patterns

CVMA-RESOURCE-REGISTRY.md contains:
- OneDrive documentation resources (`C:\Users\zerov\OneDrive\Documents\CVMA\Documentation`)
- GitHub repository and project management patterns
- Established development protocols and resource integration
- Cultural context (STORM/WX humor references)
- DevSecOps "known knowns" that should never require re-explanation

**Always reference both STORM_CLAUDE.md AND CVMA-RESOURCE-REGISTRY.md for autonomous development continuity.**

## Project Overview

This is a Salesforce project for the Combat Veterans Motorcycle Association (CVMA). The codebase includes:

- **Salesforce Communities**: Multiple community sites including CEB, Combat Veterans Motorcycle Association, and Default Help Center
- **Apex Classes**: Custom business logic including authentication controllers, iterables, and test classes
- **Lightning Components**: Custom Aura components for site functionality
- **Third-party Packages**: Includes NPSP (Nonprofit Success Pack), Google Drive connector, map plotting tools, and Trailhead integration
- **Custom Objects**: Various custom objects with DNBI__, Extentia_SIM__, npsp__, and trailheadapp__ namespaces

## Development Commands

### Salesforce CLI Commands
The project uses Salesforce CLI (`sf` command) for development:

```bash
# Deploy metadata to org
sf project deploy start

# Retrieve metadata from org
sf project retrieve start

# Run Apex tests
sf apex run test

# Execute anonymous Apex
sf apex run

# Open default org
sf org open

# Check CLI status and configuration
sf doctor

# View org information
sf org display
```

### Testing
- Apex test classes follow the pattern `*Test.cls` (e.g., `MyIterableTest.cls`)
- Run tests using: `sf apex run test`
- Test classes use `@IsTest` annotation and standard Apex testing patterns

## Architecture Notes

### Package Structure
- **src/**: Main source directory containing all Salesforce metadata
- **classes/**: Apex classes and test classes (.cls files with .cls-meta.xml metadata)
- **aura/**: Lightning Aura components
- **objects/**: Custom and standard object configurations
- **layouts/**: Page layouts for various objects
- **communities/**: Experience Cloud site configurations
- **flows/**: Process automation flows

### Key Namespaces
- **DNBI__**: Dun & Bradstreet integration package
- **Extentia_SIM__**: Map plotting functionality
- **npsp__**: Nonprofit Success Pack for donor management
- **trailheadapp__**: Trailhead integration for learning management
- **V2_Gdrive__**: Google Drive connector
- **lightngcarousel__**: Lightning carousel components

### Testing Patterns
- All test classes are in `src/classes/` with `Test` suffix
- Use `@IsTest` annotation for test classes and methods
- **Use CVMATestDataFactory for consistent test data creation**
- Standard System.debug() for debugging in tests
- Follow Salesforce testing best practices with test data creation
- Target >90% code coverage for all classes

### Salesforce Best Practices Implementation
The codebase follows enterprise-grade Salesforce best practices:

#### Error Handling and Logging
- **CVMAErrorHandler.cls**: Centralized error handling with severity levels and categories
- **CVMA_Error_Log__c**: Custom object for comprehensive error tracking
- All exceptions should be handled through CVMAErrorHandler.handleException()
- Log security violations, data validation errors, and system issues

#### Security Framework
- All SOQL queries use `WITH SECURITY_ENFORCED`
- CRUD/FLS validation via `CVMAErrorHandler.validateCRUDPermissions()`
- Input sanitization using `CVMAErrorHandler.sanitizeInput()`
- Guest user access restrictions implemented
- XSS prevention in all user outputs

#### Configuration Management
- **CVMA_Application_Config__mdt**: Application settings via custom metadata
- **CVMA_Email_Template__mdt**: Email templates with merge field support
- **CVMAConfigurationHelper.cls**: Centralized configuration access with caching
- Use metadata for configurable values instead of hard-coding

#### Performance Optimization
- Query optimization with aggregate queries and pagination
- Caching for frequently accessed data
- Governor limit protection and bulk operation support
- Email batch processing within Salesforce limits

#### Test Data Factory
- **CVMATestDataFactory.cls**: Comprehensive test data creation using builder pattern
- Use factory methods for consistent, unique test data
- Example: `CVMATestDataFactory.createContact().withLevel('Full Member').create()`

### Enhanced Controllers
- **CVMAMemberProfileControllerSecure.cls**: Secure member profile management
- **CVMAOfficerDashboardControllerOptimized.cls**: Optimized dashboard with pagination and caching
- Use enhanced versions for new development

### Code Quality Standards
- Use `with sharing` for all controllers
- Implement comprehensive exception handling
- Follow naming conventions (CVMA prefix for custom components)
- Document all public methods
- Validate CRUD/FLS permissions before data operations

### Communities Setup
The org has multiple Experience Cloud communities configured:
- Internal Zone (internal users)
- CEB community
- Combat Veterans Motorcycle Association main community
- Default Help Center for support

Each community has its own branding, navigation menus, and moderation rules configured.

## Autonomous Session Startup Protocol

**CRITICAL**: Follow this protocol at the start of every Claude Code session to ensure autonomous operation without manual catch-up.

### Step 1: Project State Assessment (Always Execute First)
```bash
# Read current project state from docs/Technical/Epic-Documentation/MEMORY_CONTINUED.md (focus on latest session achievements)
# Check docs/Technical/Epic-Documentation/NEXT-SESSION-*.md files for immediate priorities
# Review git status for pending work
# Identify current Epic progress and active user stories
```

### Step 2: Session Context Establishment
1. **Read docs/Technical/Epic-Documentation/MEMORY_CONTINUED.md latest entries** - Current Epic status, completed user stories, next priorities
2. **Check docs/Technical/Epic-Documentation/NEXT-SESSION-PRIORITIES-*.md** - Ready-to-implement tasks with all prerequisites met
3. **Review docs/Technical/Epic-Documentation/SESSION-*-ACHIEVEMENTS.md** - Previous session outcomes and technical decisions
4. **Validate git status** - Understand pending changes and current branch context

### Step 3: Multi-Agent Coordination Protocol
- **Strategic Agent (Claude)**: Architecture analysis, business logic design, methodology planning
- **Tactical Agent (Copilot)**: Implementation execution, testing, deployment, GitHub management
- **Coordination Pattern**: Strategic analysis → TodoWrite planning → Tactical implementation → Quality validation
- **External Authentication Protocol**: Prompt user for login when agents require external resource access (GitHub, etc.)

### Step 4: Autonomous Task Planning
1. **Use TodoWrite immediately** to plan current session based on documented priorities
2. **Identify current Epic progress** (Epic #1: Complete, Epic #2: 75% complete, Epic #4: Queued)
3. **Execute ready-to-implement tasks** - All prerequisites validated in previous sessions
4. **Follow Standard Feature Integration methodology** - Target 80%+ code reduction

### Current Project Status (Updated September 10, 2025)
- **Active Epic**: Epic #2 Event Management (75% complete - 3/4 user stories deployed)
- **Ready Task**: User Story #17 NPSP Financial Dashboard (2-3 hour implementation)
- **Methodology**: Standard Feature Integration (proven 80%+ code reduction across 3 user stories)
- **Multi-Agent Status**: Strategic/Tactical coordination established and operational

### Key Success Patterns
- **Standard Feature Integration**: Replace custom components with native Salesforce features
- **Code Reduction Achievement**: Average 86.7% reduction across Epic #2 user stories
- **Security Compliance**: 100% WITH SECURITY_ENFORCED implementation
- **Documentation Excellence**: Comprehensive implementation guides created for every user story

### Session Initialization Command
```bash
# Use this command to get immediate project context
./scripts/claude-session-init.sh
```

## Memory Notes

- **Multi-Agent Architecture**: Strategic Agent (Claude) + Tactical Agent (Copilot) proven effective
- **Standard Feature Integration**: Revolutionary approach achieving 80%+ code reduction
- **Epic #2 Status**: 75% complete, User Story #17 ready for implementation (NPSP Financial Dashboard)
- "Remind me to provide feedback for future Epic and related User Stories to provide the Roles of CO and XO authorization to edit Contacts when logged into the Combat Veterans Motorcycle Association"
- 3 approach is fine, I'm a Senior Salesforce Developer and have been testing your limitations.  This has truly been enlightening for me as well as I've learned how to work with you and you with me, which is the ultimate goal.  However, I'd like to also save some token cost for you to assist me in consolidating the STORM_CLAUDE.md file or add a new continuation file to capture all if the content.  Apparently I'm over the max limit and need a resolution to allow us to grow with our pre-established protocols, methods and processes that we've acquired over the course of our development growth.  Can you consolidate the instructions without losing the valueable details that we've had to overcome along the way.  If not, can you utilize a continuation or WX STORM_CLAUDE_B.md that can be called upon during session initialization to get ramped up in future sessions without losing time and token cost to keep repeating ourselves.
- 3 approach is fine, I'm a Senior Salesforce Developer and have been testing your limitations.  This has truly been enlightening for me as well as I've learned how to work with you and you with me, which is the ultimate goal.  However, I'd like to also save some token cost for you to assist me in consolidating the STORM_CLAUDE.md file or add a new continuation file to capture all if the content.  Apparently I'm over the max limit and need a resolution to allow us to grow with our pre-established protocols, methods and processes that we've acquired over the course of our development growth.  Can you consolidate the instructions without losing the valueable details that we've had to overcome along the way.  If not, can you utilize a continuation or WX STORM_CLAUDE_B.md that can be called upon during session initialization to get ramped up in future sessions without losing time and token cost to keep repeating ourselves.
- Session Summary and Update the Board (Target CVMA20-7 Repo Project)
