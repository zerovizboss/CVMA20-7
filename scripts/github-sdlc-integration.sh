#!/bin/bash
# CVMA GitHub Project Integration with Traditional SDLC Workflow
# Automated project management, issue tracking, and workflow automation

set -e

# Configuration
REPORTS_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SDLC_DIR="${REPORTS_DIR}/${TIMESTAMP}/sdlc"
PROJECT_NAME="CVMA Development Project"
REPO_OWNER="zerov"  # Update with actual GitHub username/organization
REPO_NAME="cvma"    # Update with actual repository name

echo "🚀 CVMA GitHub SDLC Integration Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create SDLC reports directory
mkdir -p "${SDLC_DIR}"

# Check GitHub CLI availability
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) not found"
    echo "Please install GitHub CLI: https://cli.github.com/"
    echo "Windows: winget install --id GitHub.cli"
    exit 1
fi

# Verify GitHub authentication
echo "🔍 Verifying GitHub authentication..."
if ! gh auth status > "${SDLC_DIR}/gh-auth-status.txt" 2>&1; then
    echo "❌ GitHub authentication failed"
    echo "Please authenticate with: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI authenticated successfully"

# Get repository information
echo "📋 Getting repository information..."
gh repo view --json name,owner,defaultBranchRef,url > "${SDLC_DIR}/repo-info.json" || {
    echo "❌ Failed to get repository information"
    echo "Please ensure you're in a GitHub repository directory"
    exit 1
}

REPO_URL=$(cat "${SDLC_DIR}/repo-info.json" | jq -r '.url')
DEFAULT_BRANCH=$(cat "${SDLC_DIR}/repo-info.json" | jq -r '.defaultBranchRef.name')
echo "📦 Repository: ${REPO_URL}"
echo "🌿 Default Branch: ${DEFAULT_BRANCH}"

# Create GitHub Project if it doesn't exist
echo "🏗️  Setting up GitHub Project..."
gh project list --owner "${REPO_OWNER}" --format json > "${SDLC_DIR}/existing-projects.json" 2>/dev/null || echo "[]" > "${SDLC_DIR}/existing-projects.json"

PROJECT_EXISTS=$(cat "${SDLC_DIR}/existing-projects.json" | jq -r --arg name "${PROJECT_NAME}" '.[] | select(.title == $name) | .number')

if [ -z "$PROJECT_EXISTS" ] || [ "$PROJECT_EXISTS" = "null" ]; then
    echo "🆕 Creating new GitHub Project: ${PROJECT_NAME}"
    gh project create --owner "${REPO_OWNER}" --title "${PROJECT_NAME}" --body "CVMA Traditional SDLC Project Management" > "${SDLC_DIR}/project-creation.json" || {
        echo "⚠️  Project creation failed, continuing with existing setup"
    }
else
    echo "✅ Using existing project: ${PROJECT_NAME} (#${PROJECT_EXISTS})"
fi

# Define SDLC workflow templates
echo "📝 Creating SDLC workflow templates..."

# Epic template
cat > "${SDLC_DIR}/epic-template.md" << 'EOF'
# Epic: [Epic Title]

## Description
Brief description of the epic and its business value.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## User Stories
- [ ] #[User Story 1]
- [ ] #[User Story 2]
- [ ] #[User Story 3]

## Definition of Done
- [ ] All user stories completed
- [ ] Code coverage ≥90%
- [ ] PMD SCA compliance ≥90%
- [ ] UAT testing completed
- [ ] Documentation updated
- [ ] Deployed to target org

## Priority
- **Business Value**: [High/Medium/Low]
- **Technical Complexity**: [High/Medium/Low]
- **Risk Level**: [High/Medium/Low]
EOF

# User Story template
cat > "${SDLC_DIR}/user-story-template.md" << 'EOF'
# User Story: [Story Title]

## Story Description
**As a** [user type]
**I want** [functionality]
**So that** [business value]

## Acceptance Criteria
- [ ] Given [context], when [action], then [result]
- [ ] Given [context], when [action], then [result]
- [ ] Given [context], when [action], then [result]

## Technical Requirements
- [ ] Apex classes created/modified
- [ ] Lightning components created/modified
- [ ] Test coverage ≥90%
- [ ] PMD compliance ≥90%
- [ ] Security review completed

## Definition of Done
- [ ] Code implemented and reviewed
- [ ] Unit tests written and passing
- [ ] Integration tests passing
- [ ] Code deployed to target org
- [ ] UAT testing completed
- [ ] Documentation updated

## Estimate
**Story Points**: [1/2/3/5/8]
**Development Hours**: [Estimate]

## Dependencies
- Depends on: #[Issue number]
- Blocks: #[Issue number]

## Sprint
**Target Sprint**: [Sprint number/name]
**Priority**: [P0/P1/P2/P3]
EOF

# Bug template
cat > "${SDLC_DIR}/bug-template.md" << 'EOF'
# Bug Report: [Bug Title]

## Bug Description
Brief description of the issue.

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
Description of what should happen.

## Actual Behavior
Description of what actually happens.

## Environment
- **Org**: [Sandbox/Production]
- **User Profile**: [Profile name]
- **Browser**: [Browser and version]
- **Device**: [Desktop/Mobile/Tablet]

## Severity
- [ ] P0 - Critical (System down)
- [ ] P1 - High (Core functionality broken)
- [ ] P2 - Medium (Feature partially working)
- [ ] P3 - Low (Minor issue)

## Acceptance Criteria
- [ ] Bug is reproduced and root cause identified
- [ ] Fix is implemented and tested
- [ ] Regression testing completed
- [ ] Code coverage maintained ≥90%
EOF

# Create issue label setup script
cat > "${SDLC_DIR}/setup-labels.sh" << 'EOF'
#!/bin/bash
# Setup SDLC labels for GitHub repository

echo "🏷️  Setting up SDLC labels..."

# Epic labels
gh label create "epic" --description "Epic work item" --color "8B5CF6" --force
gh label create "epic:in-progress" --description "Epic in progress" --color "F59E0B" --force
gh label create "epic:completed" --description "Epic completed" --color "10B981" --force

# User Story labels
gh label create "user-story" --description "User story work item" --color "3B82F6" --force
gh label create "story:ready" --description "Story ready for development" --color "06B6D4" --force
gh label create "story:in-progress" --description "Story in development" --color "F59E0B" --force
gh label create "story:review" --description "Story in code review" --color "A855F7" --force
gh label create "story:testing" --description "Story in testing" --color "EC4899" --force
gh label create "story:done" --description "Story completed" --color "10B981" --force

# Priority labels
gh label create "priority:p0" --description "Critical priority" --color "DC2626" --force
gh label create "priority:p1" --description "High priority" --color "EA580C" --force
gh label create "priority:p2" --description "Medium priority" --color "F59E0B" --force
gh label create "priority:p3" --description "Low priority" --color "65A30D" --force

# Component labels
gh label create "component:apex" --description "Apex development" --color "1E40AF" --force
gh label create "component:lwc" --description "Lightning Web Components" --color "0EA5E9" --force
gh label create "component:aura" --description "Aura Components" --color "0284C7" --force
gh label create "component:flow" --description "Flow development" --color "059669" --force
gh label create "component:config" --description "Configuration changes" --color "7C3AED" --force

# Quality labels
gh label create "quality:code-review" --description "Needs code review" --color "F97316" --force
gh label create "quality:testing" --description "Needs testing" --color "EF4444" --force
gh label create "quality:documentation" --description "Needs documentation" --color "84CC16" --force

# Bug labels
gh label create "bug" --description "Something isn't working" --color "DC2626" --force
gh label create "bug:critical" --description "Critical bug" --color "7F1D1D" --force
gh label create "bug:regression" --description "Regression bug" --color "B91C1C" --force

echo "✅ SDLC labels created successfully!"
EOF

chmod +x "${SDLC_DIR}/setup-labels.sh"

# Create milestone management script
cat > "${SDLC_DIR}/manage-milestones.sh" << 'EOF'
#!/bin/bash
# Manage SDLC milestones

CURRENT_DATE=$(date +"%Y-%m-%d")
SPRINT_LENGTH=14  # 2 weeks

echo "📅 Managing SDLC milestones..."

# Calculate sprint dates
SPRINT_1_END=$(date -d "${CURRENT_DATE} + ${SPRINT_LENGTH} days" +"%Y-%m-%d")
SPRINT_2_END=$(date -d "${CURRENT_DATE} + $((SPRINT_LENGTH * 2)) days" +"%Y-%m-%d")
SPRINT_3_END=$(date -d "${CURRENT_DATE} + $((SPRINT_LENGTH * 3)) days" +"%Y-%m-%d")

# Create milestones
gh api repos/:owner/:repo/milestones \
  --method POST \
  --field title="Sprint 1" \
  --field description="First development sprint" \
  --field due_on="${SPRINT_1_END}T23:59:59Z" \
  --field state="open" || echo "Sprint 1 milestone may already exist"

gh api repos/:owner/:repo/milestones \
  --method POST \
  --field title="Sprint 2" \
  --field description="Second development sprint" \
  --field due_on="${SPRINT_2_END}T23:59:59Z" \
  --field state="open" || echo "Sprint 2 milestone may already exist"

gh api repos/:owner/:repo/milestones \
  --method POST \
  --field title="Sprint 3" \
  --field description="Third development sprint" \
  --field due_on="${SPRINT_3_END}T23:59:59Z" \
  --field state="open" || echo "Sprint 3 milestone may already exist"

# Release milestone
RELEASE_DATE=$(date -d "${CURRENT_DATE} + 90 days" +"%Y-%m-%d")
gh api repos/:owner/:repo/milestones \
  --method POST \
  --field title="v1.0 Release" \
  --field description="First major release" \
  --field due_on="${RELEASE_DATE}T23:59:59Z" \
  --field state="open" || echo "Release milestone may already exist"

echo "✅ Milestones created successfully!"
EOF

chmod +x "${SDLC_DIR}/manage-milestones.sh"

# Create workflow automation script
cat > "${SDLC_DIR}/workflow-automation.sh" << 'EOF'
#!/bin/bash
# SDLC Workflow Automation

set -e

echo "⚡ SDLC Workflow Automation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Function to create epic
create_epic() {
    local title="$1"
    local description="$2"
    
    echo "🎯 Creating Epic: ${title}"
    gh issue create \
        --title "Epic: ${title}" \
        --body "${description}" \
        --label "epic" \
        --assignee "@me"
}

# Function to create user story
create_user_story() {
    local title="$1"
    local description="$2"
    local epic_number="$3"
    
    echo "📝 Creating User Story: ${title}"
    gh issue create \
        --title "User Story: ${title}" \
        --body "${description}" \
        --label "user-story,story:ready" \
        --assignee "@me" \
        --milestone "Sprint 1"
    
    if [ ! -z "$epic_number" ]; then
        echo "🔗 Linking to Epic #${epic_number}"
    fi
}

# Function to transition story status
transition_story() {
    local issue_number="$1"
    local status="$2"
    
    case $status in
        "in-progress")
            gh issue edit "$issue_number" --remove-label "story:ready" --add-label "story:in-progress"
            ;;
        "review")
            gh issue edit "$issue_number" --remove-label "story:in-progress" --add-label "story:review,quality:code-review"
            ;;
        "testing")
            gh issue edit "$issue_number" --remove-label "story:review" --add-label "story:testing,quality:testing"
            ;;
        "done")
            gh issue edit "$issue_number" --remove-label "story:testing" --add-label "story:done"
            gh issue close "$issue_number"
            ;;
    esac
    
    echo "✅ Story #${issue_number} transitioned to ${status}"
}

# Function to create branch for user story
create_story_branch() {
    local issue_number="$1"
    local branch_name="feature/user-story-${issue_number}"
    
    echo "🌿 Creating branch: ${branch_name}"
    git checkout -b "$branch_name"
    git push -u origin "$branch_name"
    
    # Link branch to issue
    gh issue comment "$issue_number" --body "🌿 Development branch created: \`${branch_name}\`"
}

# Function to create pull request
create_pull_request() {
    local issue_number="$1"
    local title="$2"
    local branch_name="feature/user-story-${issue_number}"
    
    echo "🔄 Creating pull request for User Story #${issue_number}"
    gh pr create \
        --title "User Story #${issue_number}: ${title}" \
        --body "Closes #${issue_number}

## Summary
Implementation of User Story #${issue_number}

## Changes Made
- [ ] Apex classes created/modified
- [ ] Lightning components created/modified
- [ ] Tests added/updated

## Quality Checklist
- [ ] Code coverage ≥90%
- [ ] PMD compliance ≥90%
- [ ] All tests passing
- [ ] Security review completed

## Testing
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Manual testing completed

Generated with [Claude Code](https://claude.ai/code)" \
        --head "$branch_name" \
        --base "main" \
        --label "quality:code-review" \
        --assignee "@me"
}

echo "🛠️  SDLC workflow automation functions loaded successfully!"
echo "Available functions:"
echo "  - create_epic 'title' 'description'"
echo "  - create_user_story 'title' 'description' [epic_number]"
echo "  - transition_story issue_number status"
echo "  - create_story_branch issue_number"
echo "  - create_pull_request issue_number 'title'"
EOF

chmod +x "${SDLC_DIR}/workflow-automation.sh"

# Create comprehensive SDLC report
cat > "${SDLC_DIR}/sdlc-setup-report.txt" << EOF
CVMA GitHub SDLC Integration Setup Report
Generated: $(date)
Repository: ${REPO_URL}
Default Branch: ${DEFAULT_BRANCH}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SDLC COMPONENTS CREATED:

📋 Issue Templates:
  - Epic Template: ${SDLC_DIR}/epic-template.md
  - User Story Template: ${SDLC_DIR}/user-story-template.md  
  - Bug Template: ${SDLC_DIR}/bug-template.md

🏷️  Label Management:
  - Setup Script: ${SDLC_DIR}/setup-labels.sh
  - Epic labels (epic, epic:in-progress, epic:completed)
  - Story labels (user-story, story:ready, story:in-progress, story:review, story:testing, story:done)
  - Priority labels (priority:p0, priority:p1, priority:p2, priority:p3)
  - Component labels (component:apex, component:lwc, component:aura, component:flow, component:config)
  - Quality labels (quality:code-review, quality:testing, quality:documentation)
  - Bug labels (bug, bug:critical, bug:regression)

📅 Milestone Management:
  - Management Script: ${SDLC_DIR}/manage-milestones.sh
  - Automatic sprint planning (2-week sprints)
  - Release milestone planning

⚡ Workflow Automation:
  - Automation Script: ${SDLC_DIR}/workflow-automation.sh
  - Epic creation functions
  - User story lifecycle management
  - Branch and PR automation
  - Status transition automation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TRADITIONAL SDLC WORKFLOW:

1. 📋 PLANNING PHASE
   - Create Epics with business requirements
   - Break down Epics into User Stories
   - Assign story points and priorities
   - Plan sprints with milestones

2. 🔨 DEVELOPMENT PHASE
   - Transition stories to "In Progress"
   - Create feature branches
   - Implement code with quality gates
   - Ensure PMD compliance ≥90%
   - Maintain code coverage ≥90%

3. 👀 REVIEW PHASE
   - Create pull requests
   - Conduct code reviews
   - Run automated quality checks
   - Validate deployment readiness

4. 🧪 TESTING PHASE
   - Execute unit and integration tests
   - Perform manual UAT testing
   - Validate acceptance criteria
   - Document test results

5. 🚀 DEPLOYMENT PHASE
   - Deploy to target org
   - Monitor deployment success
   - Update story status to "Done"
   - Close completed issues

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NEXT STEPS:

1. 🏷️  Run label setup:
   bash ${SDLC_DIR}/setup-labels.sh

2. 📅 Create milestones:
   bash ${SDLC_DIR}/manage-milestones.sh

3. 📋 Copy templates to .github/ISSUE_TEMPLATE/:
   mkdir -p .github/ISSUE_TEMPLATE
   cp ${SDLC_DIR}/*-template.md .github/ISSUE_TEMPLATE/

4. ⚡ Load workflow automation:
   source ${SDLC_DIR}/workflow-automation.sh

5. 🎯 Create your first Epic and User Stories using the functions

FILES GENERATED:
  - SDLC Setup Report: ${SDLC_DIR}/sdlc-setup-report.txt
  - Epic Template: ${SDLC_DIR}/epic-template.md
  - User Story Template: ${SDLC_DIR}/user-story-template.md
  - Bug Template: ${SDLC_DIR}/bug-template.md
  - Label Setup Script: ${SDLC_DIR}/setup-labels.sh
  - Milestone Manager: ${SDLC_DIR}/manage-milestones.sh
  - Workflow Automation: ${SDLC_DIR}/workflow-automation.sh
  - Repository Info: ${SDLC_DIR}/repo-info.json

EOF

# Display results
echo ""
echo "📋 GitHub SDLC Integration Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "${SDLC_DIR}/sdlc-setup-report.txt"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create symlink to latest SDLC setup
rm -f "${REPORTS_DIR}/latest-sdlc"
ln -sf "${TIMESTAMP}/sdlc" "${REPORTS_DIR}/latest-sdlc"

echo ""
echo "📈 Latest SDLC setup available at: ${REPORTS_DIR}/latest-sdlc/"

# Exit successfully
echo "✅ GitHub SDLC integration setup completed successfully"
exit 0