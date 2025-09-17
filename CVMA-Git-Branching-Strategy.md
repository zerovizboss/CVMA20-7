# CVMA Git Branching Strategy

## Overview
This document outlines the Git branching strategy for the Combat Veterans Motorcycle Association (CVMA) Salesforce project. The strategy is designed to support Agile development with Epic and User Story workflows while maintaining code quality and deployment readiness.

## Branching Strategy: Epic-Feature Flow

### Branch Types

#### 1. Main Branch (`main`)
- **Purpose**: Production-ready code
- **Protection**: Protected branch with required PR reviews
- **Source**: Epic branches merge here after completion
- **Deployment**: Automatically deployed to production org

#### 2. Epic Branches (`epic-{number}-{description}`)
- **Purpose**: Integration branch for related User Stories
- **Naming**: `epic-2-event-management`, `epic-3-communication-platform`
- **Lifecycle**: Created from `main`, deleted after merge to `main`
- **Source**: User Story branches merge here

#### 3. User Story Branches (`feature/user-story-{number}-{description}`)
- **Purpose**: Individual feature development
- **Naming**: `feature/user-story-8-event-scheduling`
- **Lifecycle**: Created from epic branch, deleted after merge to epic
- **Source**: Development work happens here

#### 4. Hotfix Branches (`hotfix/{description}`)
- **Purpose**: Critical production fixes
- **Naming**: `hotfix/member-profile-validation-error`
- **Lifecycle**: Created from `main`, merged directly to `main`
- **Source**: Emergency fixes only

## CVMA Project Epic Structure

Based on the CVMA-SDLC-Lifecycle.md, here are the planned epic branches:

### Epic #2: Event Management Enhancement
**Branch**: `epic-2-event-management`
**User Stories**:
- `feature/user-story-8-event-scheduling`
- `feature/user-story-9-calendar-integration`
- `feature/user-story-10-participation-tracking`

### Epic #3: Communication Platform
**Branch**: `epic-3-communication-platform`
**User Stories**:
- `feature/user-story-11-messaging-system`
- `feature/user-story-12-announcements`
- `feature/user-story-13-communication-integration`

### Epic #4: Financial Management
**Branch**: `epic-4-financial-management`
**User Stories**:
- `feature/user-story-14-dues-tracking`
- `feature/user-story-15-financial-reporting`

### Epic #5: Reporting and Analytics
**Branch**: `epic-5-reporting-analytics`
**User Stories**:
- `feature/user-story-16-engagement-analytics`
- `feature/user-story-17-performance-dashboards`

## Workflow Process

### Starting a New Epic

1. Create epic branch from `main`:
```bash
git checkout main
git pull origin main
git checkout -b epic-{number}-{description}
git push -u origin epic-{number}-{description}
```

2. Create GitHub issue for epic tracking
3. Set up project board for user stories

### Working on User Stories

1. Create user story branch from epic branch:
```bash
git checkout epic-{number}-{description}
git pull origin epic-{number}-{description}
git checkout -b feature/user-story-{number}-{description}
```

2. Develop feature with frequent commits:
```bash
git add .
git commit -m "feat: implement {specific feature} for user story #{number}"
```

3. Push and create Pull Request to epic branch:
```bash
git push -u origin feature/user-story-{number}-{description}
```

### Merging Process

#### User Story → Epic Branch
1. Create PR from user story branch to epic branch
2. Code review by team members
3. Run Salesforce tests: `sf apex run test`
4. Merge using "Squash and merge" for clean history
5. Delete user story branch

#### Epic → Main Branch
1. Ensure all user stories are merged to epic
2. Create PR from epic branch to `main`
3. Comprehensive testing and validation
4. Deploy to staging org for final validation
5. Merge using "Create a merge commit" to preserve epic history
6. Deploy to production org
7. Delete epic branch

## Branch Protection Rules

### Main Branch Protection
- Require pull request reviews (minimum 1)
- Require status checks to pass
- Require branches to be up to date before merging
- Restrict pushes that create files larger than 100MB
- Restrict force pushes

### Epic Branch Protection
- Require pull request reviews for user story merges
- Require status checks to pass
- Allow force pushes by administrators (for emergency fixes)

## Commit Message Standards

Follow Conventional Commits specification:

### Format
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples
```bash
git commit -m "feat(member-profile): add emergency contact field validation"
git commit -m "fix(dashboard): resolve member count calculation error"
git commit -m "test(application): add test coverage for document upload"
```

## Salesforce-Specific Considerations

### Before Merging
1. Run all Apex tests: `sf apex run test`
2. Validate metadata deployment: `sf project deploy start --check-only`
3. Check code coverage requirements (>75%)
4. Verify security and sharing settings

### Deployment Pipeline
1. **Feature Branch**: Sandbox deployment for development
2. **Epic Branch**: Staging org deployment for integration testing
3. **Main Branch**: Production org deployment

## Emergency Procedures

### Hotfixes
For critical production issues:

1. Create hotfix branch from `main`:
```bash
git checkout main
git pull origin main
git checkout -b hotfix/{issue-description}
```

2. Implement fix and test thoroughly
3. Create PR directly to `main`
4. After merge, cherry-pick to active epic branches if needed

### Rollback Procedures
1. Identify commit hash of last known good state
2. Create revert commit: `git revert {commit-hash}`
3. Deploy revert to production immediately
4. Create issue to address root cause

## Best Practices

### Daily Workflow
1. Start day by pulling latest changes from epic branch
2. Commit frequently with descriptive messages
3. Push to remote at least daily
4. Keep user story branches short-lived (< 1 week)

### Code Quality
- Follow CVMA coding standards in CLAUDE.md
- Use CVMAErrorHandler for all exception handling
- Implement comprehensive test coverage
- Document all public methods and classes

### Communication
- Reference GitHub issues in commit messages
- Update PR descriptions with testing notes
- Use GitHub Projects to track epic and user story progress
- Notify team of epic branch updates

## Tools and Automation

### Required Tools
- Git CLI or GitHub Desktop
- Salesforce CLI (`sf` command)
- IDE with Git integration (IntelliJ IDEA + Illuminated Cloud II)

### Recommended GitHub Actions
- Automated Apex test runs on PR creation
- Metadata validation on epic branch updates
- Deployment automation to staging org
- Code coverage reporting

## Metrics and Monitoring

### Key Metrics
- **Cycle Time**: Time from user story start to epic merge
- **Merge Rate**: Successful merges vs total attempts  
- **Review Time**: Time for PR review and approval
- **Deployment Success**: Successful vs failed deployments

### Review Cadence
- Weekly epic branch review meetings
- Sprint retrospectives on branching effectiveness
- Monthly strategy refinement based on metrics

## Support and Training

### Team Training
- Git branching workshop for new team members
- Salesforce CLI training for deployment procedures
- Code review best practices session

### Documentation
- This strategy document (living document)
- CLAUDE.md for development standards
- Salesforce deployment guides in `/scripts` directory

---

*This document is a living guide and should be updated as the team's needs evolve. Last updated: January 2025*