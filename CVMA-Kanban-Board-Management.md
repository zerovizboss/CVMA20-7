# CVMA Kanban Board Management Process

## Overview
This document outlines the process for maintaining the GitHub project kanban board for the CVMA Salesforce project. It ensures that project status accurately reflects actual development progress and testing completion.

## GitHub Project Details
- **Project Name**: "CVMA 20-7 Experience Builder Enhancements" 
- **Project URL**: https://github.com/users/zerovizboss/projects/5
- **Repository**: https://github.com/zerovizboss/CVMA20-7
- **Timeline**: Aug 04, 2025 - Jan 05, 2026

## Kanban Board Structure

### Columns and Usage

#### 1. No Value (Backlog)
- **Purpose**: Epic-level issues awaiting assignment to specific sprints
- **Criteria**: High-level initiatives not yet broken down into actionable tasks
- **Actions**: Move to "Dev Ready" when sprint planning is complete

#### 2. Backlog
- **Purpose**: Planned user stories ready for prioritization
- **Criteria**: Well-defined user stories with acceptance criteria
- **Actions**: Move to "Dev Ready" when sprint assignment occurs

#### 3. Dev Ready
- **Purpose**: User stories ready for active development
- **Criteria**: 
  - Sprint assigned
  - Acceptance criteria defined
  - Dependencies resolved
  - Team member assigned
- **Actions**: Move to "In Progress" when development begins

#### 4. In Progress
- **Purpose**: Active development work
- **Criteria**: 
  - Developer actively working on implementation
  - Feature branch created from appropriate epic branch
  - Regular commits being made
- **Actions**: Move to "Review" when implementation complete and PR created

#### 5. Review
- **Purpose**: Code review and testing phase
- **Criteria**: 
  - Pull request created to epic branch
  - Apex tests passing
  - Code review completed
  - Deployment to sandbox successful
- **Actions**: Move to "Done" when merged to epic branch

#### 6. Done
- **Purpose**: Completed and verified user stories
- **Criteria**: 
  - Code merged to epic branch
  - Tests passing with adequate coverage
  - Feature validated in Salesforce org
  - Documentation updated

## User Story Lifecycle Management

### Epic Workflow Integration
Following the CVMA Git Branching Strategy:

1. **Epic Creation**: Create epic branch from `main`
2. **User Story Development**: Create feature branches from epic branch
3. **Kanban Updates**: Move cards as work progresses
4. **Epic Completion**: Close epic issue when all user stories complete

### Status Update Triggers

#### Move to "In Progress"
- **Trigger**: Developer starts work on user story
- **Git Action**: Feature branch created
- **Command**: 
```bash
gh issue edit {issue-number} --add-label "in-progress" --repo zerovizboss/CVMA20-7
```

#### Move to "Review"
- **Trigger**: Pull request created
- **Git Action**: PR submitted to epic branch
- **Command**:
```bash
gh issue edit {issue-number} --add-label "review" --remove-label "in-progress" --repo zerovizboss/CVMA20-7
```

#### Move to "Done"
- **Trigger**: Feature merged to epic branch
- **Git Action**: PR merged and feature branch deleted
- **Command**:
```bash
gh issue close {issue-number} --comment "User Story completed and merged to epic branch" --repo zerovizboss/CVMA20-7
```

## GitHub CLI Commands for Board Management

### Setup Requirements
```bash
# Install GitHub CLI
curl -L https://github.com/cli/cli/releases/download/v2.63.2/gh_2.63.2_windows_amd64.zip -o gh.zip
unzip -o gh.zip

# Authenticate (requires project permissions)
./bin/gh.exe auth refresh -s read:project -h github.com
```

### Issue Management Commands

#### List Issues by Status
```bash
# View all open issues
./bin/gh.exe issue list --repo zerovizboss/CVMA20-7

# View issues in specific state
./bin/gh.exe issue list --state open --repo zerovizboss/CVMA20-7
```

#### Update Issue Status
```bash
# Add labels
./bin/gh.exe issue edit {issue-number} --add-label "in-progress" --repo zerovizboss/CVMA20-7

# Remove labels  
./bin/gh.exe issue edit {issue-number} --remove-label "dev-ready" --repo zerovizboss/CVMA20-7

# Close with comment
./bin/gh.exe issue close {issue-number} --comment "Completed with all acceptance criteria met" --repo zerovizboss/CVMA20-7
```

#### Epic Management
```bash
# Close epic with detailed summary
./bin/gh.exe issue close {epic-number} --comment "Epic completed with all user stories implemented:
✅ User Story #X: Description
✅ User Story #Y: Description
✅ User Story #Z: Description

Technical achievements:
- Component details
- Test coverage
- Deployment status" --repo zerovizboss/CVMA20-7
```

## Testing Verification Process

### Before Moving to "Review"
1. **Run Apex Tests**: `sf apex run test`
2. **Check Code Coverage**: Ensure >75% coverage for new classes
3. **Validate Deployment**: `sf project deploy start --check-only`
4. **Security Review**: Verify CRUD/FLS permissions implemented

### Before Moving to "Done"
1. **Integration Testing**: Test in Salesforce org
2. **User Acceptance**: Validate against acceptance criteria
3. **Documentation**: Update MEMORY.md with completion status
4. **Git Cleanup**: Delete feature branch after merge

## Automated Processes

### GitHub Actions Integration (Future)
```yaml
name: Update Kanban Board
on:
  pull_request:
    types: [opened, closed]
  
jobs:
  update-board:
    runs-on: ubuntu-latest
    steps:
      - name: Move to Review on PR Open
        if: github.event.action == 'opened'
        run: gh issue edit ${{ github.event.pull_request.number }} --add-label "review"
        
      - name: Move to Done on PR Merge
        if: github.event.pull_request.merged == true
        run: gh issue close ${{ github.event.pull_request.number }} --comment "Merged to epic branch"
```

## Project Metrics Tracking

### Weekly Review Process
1. **Velocity Tracking**: Count user stories completed per sprint
2. **Cycle Time**: Measure time from "Dev Ready" to "Done"
3. **Quality Metrics**: Track test coverage and bug reports
4. **Board Health**: Ensure no stale issues in "In Progress"

### Epic Completion Metrics
- **Total User Stories**: Count per epic
- **Completion Rate**: Percentage of acceptance criteria met
- **Test Coverage**: Code coverage percentage
- **Deployment Success**: Successful vs failed deployments

## Communication Protocols

### Daily Updates
- Comment on issues with progress updates
- Use @mentions for blocking issues
- Update time estimates when scope changes

### Sprint Reviews
- Close completed user stories with detailed comments
- Update epic progress in main issue comments
- Move remaining work to next sprint columns

### Stakeholder Reporting
- Generate weekly progress reports from board status
- Include completion metrics and upcoming milestones
- Highlight any blockers or scope changes

## Troubleshooting Common Issues

### Stale Issues in "In Progress"
**Problem**: Issues stuck in progress column
**Solution**: 
1. Check last commit date on feature branch
2. Contact assigned developer for status update
3. Move back to "Dev Ready" if work paused

### Missing Test Coverage
**Problem**: User story complete but tests failing
**Solution**:
1. Keep in "Review" status until tests pass
2. Create separate issue for test coverage improvement
3. Block epic merge until coverage requirements met

### Deployment Failures
**Problem**: Code works locally but fails in org
**Solution**:
1. Move back to "In Progress" status
2. Create hotfix branch if blocking
3. Update issue with deployment logs and error details

## Board Maintenance Schedule

### Daily (Development Days)
- Update issues moved between columns
- Add progress comments to active issues
- Close completed user stories

### Weekly (Sprint Boundaries)
- Review board health and stale issues
- Update epic progress percentages
- Plan next sprint assignments

### Monthly (Epic Completion)
- Close completed epics with full summaries
- Archive completed user story branches
- Update project timeline and milestones

---

*This process document should be updated as team workflows evolve. Last updated: January 2025*