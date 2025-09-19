#!/bin/bash
# CVMA Real-time User Story Status Updates
# Automated GitHub integration for traditional SDLC workflow tracking

set -e

# Configuration
REPORTS_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TRACKER_DIR="${REPORTS_DIR}/${TIMESTAMP}/tracker"
REPO_URL="https://github.com/zerovizboss/CVMA20-7.git"
PROJECT_BOARD="CVMA20-7"

echo "📊 CVMA Real-time User Story Status Tracker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create tracker reports directory
mkdir -p "${TRACKER_DIR}"

# Check GitHub CLI availability
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) not found"
    echo "Please install GitHub CLI: https://cli.github.com/"
    exit 1
fi

# Verify GitHub authentication
echo "🔍 Verifying GitHub authentication..."
if ! gh auth status > "${TRACKER_DIR}/gh-auth-status.txt" 2>&1; then
    echo "❌ GitHub authentication failed"
    echo "Please authenticate with: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI authenticated successfully"

# Get current project status
echo "📋 Retrieving current project status..."
gh project list --owner zerovizboss --format json > "${TRACKER_DIR}/projects.json" 2>/dev/null || echo "[]" > "${TRACKER_DIR}/projects.json"

# Get all issues with user story labels
echo "🔍 Analyzing user story issues..."
gh issue list --repo zerovizboss/CVMA20-7 --label "user-story" --state all --json number,title,state,labels,assignees,milestone,createdAt,updatedAt,url > "${TRACKER_DIR}/user-stories.json"

# Get current epics
gh issue list --repo zerovizboss/CVMA20-7 --label "epic" --state all --json number,title,state,labels,createdAt,updatedAt,url > "${TRACKER_DIR}/epics.json"

# Parse and categorize user stories by status
cat "${TRACKER_DIR}/user-stories.json" | jq -r '.[] | [.number, .title, .state, (.labels | map(.name) | join(",")), (.milestone.title // "No Milestone"), .updatedAt] | @csv' > "${TRACKER_DIR}/user-stories.csv"

# Count stories by status
TOTAL_STORIES=$(cat "${TRACKER_DIR}/user-stories.json" | jq 'length')
OPEN_STORIES=$(cat "${TRACKER_DIR}/user-stories.json" | jq '[.[] | select(.state == "open")] | length')
CLOSED_STORIES=$(cat "${TRACKER_DIR}/user-stories.json" | jq '[.[] | select(.state == "closed")] | length')

# Count by workflow status
READY_STORIES=$(cat "${TRACKER_DIR}/user-stories.json" | jq '[.[] | select(.labels | map(.name) | contains(["story:ready"]))] | length')
IN_PROGRESS_STORIES=$(cat "${TRACKER_DIR}/user-stories.json" | jq '[.[] | select(.labels | map(.name) | contains(["story:in-progress"]))] | length')
REVIEW_STORIES=$(cat "${TRACKER_DIR}/user-stories.json" | jq '[.[] | select(.labels | map(.name) | contains(["story:review"]))] | length')
TESTING_STORIES=$(cat "${TRACKER_DIR}/user-stories.json" | jq '[.[] | select(.labels | map(.name) | contains(["story:testing"]))] | length')
DONE_STORIES=$(cat "${TRACKER_DIR}/user-stories.json" | jq '[.[] | select(.labels | map(.name) | contains(["story:done"]))] | length')

# Count epics by status
TOTAL_EPICS=$(cat "${TRACKER_DIR}/epics.json" | jq 'length')
OPEN_EPICS=$(cat "${TRACKER_DIR}/epics.json" | jq '[.[] | select(.state == "open")] | length')
COMPLETED_EPICS=$(cat "${TRACKER_DIR}/epics.json" | jq '[.[] | select(.state == "closed")] | length')

# Create comprehensive status report
cat > "${TRACKER_DIR}/status-report.txt" << EOF
CVMA Real-time User Story Status Report
Generated: $(date)
Repository: ${REPO_URL}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EPIC SUMMARY:
  Total Epics: ${TOTAL_EPICS}
  Active Epics: ${OPEN_EPICS}
  Completed Epics: ${COMPLETED_EPICS}
  Epic Completion Rate: $([ ${TOTAL_EPICS} -gt 0 ] && echo "$((COMPLETED_EPICS * 100 / TOTAL_EPICS))%" || echo "N/A")

USER STORY SUMMARY:
  Total Stories: ${TOTAL_STORIES}
  Open Stories: ${OPEN_STORIES}
  Completed Stories: ${CLOSED_STORIES}
  Story Completion Rate: $([ ${TOTAL_STORIES} -gt 0 ] && echo "$((CLOSED_STORIES * 100 / TOTAL_STORIES))%" || echo "N/A")

WORKFLOW STATUS DISTRIBUTION:
  📋 Ready for Development: ${READY_STORIES}
  🔨 In Progress: ${IN_PROGRESS_STORIES}
  👀 In Code Review: ${REVIEW_STORIES}
  🧪 In Testing: ${TESTING_STORIES}
  ✅ Done: ${DONE_STORIES}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

DETAILED EPIC STATUS:
EOF

# Add epic details
cat "${TRACKER_DIR}/epics.json" | jq -r '.[] | "  Epic #\(.number): \(.title) - \(.state | ascii_upcase)"' >> "${TRACKER_DIR}/status-report.txt"

cat >> "${TRACKER_DIR}/status-report.txt" << EOF

DETAILED USER STORY STATUS:
EOF

# Add user story details grouped by status
echo "" >> "${TRACKER_DIR}/status-report.txt"
echo "📋 READY FOR DEVELOPMENT:" >> "${TRACKER_DIR}/status-report.txt"
cat "${TRACKER_DIR}/user-stories.json" | jq -r '.[] | select(.labels | map(.name) | contains(["story:ready"])) | "  - User Story #\(.number): \(.title)"' >> "${TRACKER_DIR}/status-report.txt"

echo "" >> "${TRACKER_DIR}/status-report.txt"
echo "🔨 IN PROGRESS:" >> "${TRACKER_DIR}/status-report.txt"
cat "${TRACKER_DIR}/user-stories.json" | jq -r '.[] | select(.labels | map(.name) | contains(["story:in-progress"])) | "  - User Story #\(.number): \(.title)"' >> "${TRACKER_DIR}/status-report.txt"

echo "" >> "${TRACKER_DIR}/status-report.txt"
echo "👀 IN CODE REVIEW:" >> "${TRACKER_DIR}/status-report.txt"
cat "${TRACKER_DIR}/user-stories.json" | jq -r '.[] | select(.labels | map(.name) | contains(["story:review"])) | "  - User Story #\(.number): \(.title)"' >> "${TRACKER_DIR}/status-report.txt"

echo "" >> "${TRACKER_DIR}/status-report.txt"
echo "🧪 IN TESTING:" >> "${TRACKER_DIR}/status-report.txt"
cat "${TRACKER_DIR}/user-stories.json" | jq -r '.[] | select(.labels | map(.name) | contains(["story:testing"])) | "  - User Story #\(.number): \(.title)"' >> "${TRACKER_DIR}/status-report.txt"

echo "" >> "${TRACKER_DIR}/status-report.txt"
echo "✅ COMPLETED:" >> "${TRACKER_DIR}/status-report.txt"
cat "${TRACKER_DIR}/user-stories.json" | jq -r '.[] | select(.labels | map(.name) | contains(["story:done"]) or .state == "closed") | "  - User Story #\(.number): \(.title)"' >> "${TRACKER_DIR}/status-report.txt"

# Create automated status update functions
cat > "${TRACKER_DIR}/status-updater.sh" << 'EOF'
#!/bin/bash
# Real-time User Story Status Update Functions

set -e

REPO="zerovizboss/CVMA20-7"

# Function to transition user story status
update_story_status() {
    local issue_number="$1"
    local new_status="$2"
    local comment="$3"
    
    echo "🔄 Transitioning User Story #${issue_number} to ${new_status}..."
    
    case $new_status in
        "ready")
            gh issue edit "$issue_number" --repo "$REPO" \
                --remove-label "story:in-progress,story:review,story:testing" \
                --add-label "story:ready"
            ;;
        "in-progress")
            gh issue edit "$issue_number" --repo "$REPO" \
                --remove-label "story:ready,story:review,story:testing,story:done" \
                --add-label "story:in-progress"
            ;;
        "review")
            gh issue edit "$issue_number" --repo "$REPO" \
                --remove-label "story:in-progress,story:testing" \
                --add-label "story:review,quality:code-review"
            ;;
        "testing")
            gh issue edit "$issue_number" --repo "$REPO" \
                --remove-label "story:review,quality:code-review" \
                --add-label "story:testing,quality:testing"
            ;;
        "done")
            gh issue edit "$issue_number" --repo "$REPO" \
                --remove-label "story:testing,quality:testing" \
                --add-label "story:done"
            # Optionally close the issue
            # gh issue close "$issue_number" --repo "$REPO"
            ;;
    esac
    
    # Add status comment if provided
    if [ ! -z "$comment" ]; then
        gh issue comment "$issue_number" --repo "$REPO" --body "🔄 **Status Update**: $comment

Updated to: **${new_status}**
Timestamp: $(date)
Automated by: CVMA SDLC Status Tracker"
    fi
    
    echo "✅ User Story #${issue_number} transitioned to ${new_status}"
}

# Function to create deployment comment
add_deployment_comment() {
    local issue_number="$1"
    local deployment_status="$2"
    local coverage_info="$3"
    local pmd_info="$4"
    
    gh issue comment "$issue_number" --repo "$REPO" --body "🚀 **Deployment Update**

Status: **${deployment_status}**
$([ ! -z "$coverage_info" ] && echo "Code Coverage: $coverage_info")
$([ ! -z "$pmd_info" ] && echo "PMD Compliance: $pmd_info")

Deployment Time: $(date)
Automated by: CVMA SDLC Status Tracker"
}

# Function to link commit to issue
link_commit_to_story() {
    local issue_number="$1"
    local commit_hash="$2"
    local commit_message="$3"
    
    gh issue comment "$issue_number" --repo "$REPO" --body "💻 **Code Commit Linked**

Commit: \`${commit_hash}\`
Message: ${commit_message}

[View Commit](https://github.com/zerovizboss/CVMA20-7/commit/${commit_hash})
Timestamp: $(date)"
}

# Function to create quality gate report
add_quality_report() {
    local issue_number="$1"
    local pmd_score="$2"
    local coverage_percent="$3"
    local test_results="$4"
    
    local pmd_status="❌ FAIL"
    local coverage_status="❌ FAIL"
    
    [ "$pmd_score" -ge 90 ] && pmd_status="✅ PASS"
    [ "$coverage_percent" -ge 90 ] && coverage_status="✅ PASS"
    
    gh issue comment "$issue_number" --repo "$REPO" --body "📊 **Quality Gate Report**

## PMD Static Code Analysis
Score: **${pmd_score}%** ${pmd_status}
Target: ≥90%

## Code Coverage
Coverage: **${coverage_percent}%** ${coverage_status}
Target: ≥90%

## Test Results
${test_results}

Generated: $(date)
Automated by: CVMA Quality Gates"
}

# Function to check current story status
check_story_status() {
    local issue_number="$1"
    
    gh issue view "$issue_number" --repo "$REPO" --json labels,state | jq -r '
        .labels | map(.name) | 
        if contains(["story:ready"]) then "ready"
        elif contains(["story:in-progress"]) then "in-progress" 
        elif contains(["story:review"]) then "review"
        elif contains(["story:testing"]) then "testing"
        elif contains(["story:done"]) then "done"
        elif .state == "closed" then "closed"
        else "unknown"
        end'
}

echo "🛠️  User Story status update functions loaded!"
echo ""
echo "Available functions:"
echo "  update_story_status <issue_number> <status> [comment]"
echo "  add_deployment_comment <issue_number> <status> [coverage] [pmd]"
echo "  link_commit_to_story <issue_number> <commit_hash> <message>"
echo "  add_quality_report <issue_number> <pmd_score> <coverage> <test_results>"
echo "  check_story_status <issue_number>"
echo ""
echo "Status options: ready, in-progress, review, testing, done"
EOF

chmod +x "${TRACKER_DIR}/status-updater.sh"

# Create real-time monitoring script
cat > "${TRACKER_DIR}/monitor-stories.sh" << 'EOF'
#!/bin/bash
# Real-time User Story Monitoring

REPO="zerovizboss/CVMA20-7"
MONITOR_INTERVAL=30  # seconds

echo "📊 Starting real-time user story monitoring..."
echo "Press Ctrl+C to stop monitoring"
echo ""

while true; do
    clear
    echo "🔍 CVMA User Story Monitor - $(date)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get current status
    READY=$(gh issue list --repo "$REPO" --label "story:ready" --state open --json number | jq 'length')
    IN_PROGRESS=$(gh issue list --repo "$REPO" --label "story:in-progress" --state open --json number | jq 'length')
    REVIEW=$(gh issue list --repo "$REPO" --label "story:review" --state open --json number | jq 'length')
    TESTING=$(gh issue list --repo "$REPO" --label "story:testing" --state open --json number | jq 'length')
    DONE=$(gh issue list --repo "$REPO" --label "story:done" --state all --json number | jq 'length')
    
    echo "📋 Ready for Dev: $READY"
    echo "🔨 In Progress: $IN_PROGRESS"
    echo "👀 Code Review: $REVIEW"
    echo "🧪 Testing: $TESTING"
    echo "✅ Completed: $DONE"
    echo ""
    
    # Show active stories
    if [ "$IN_PROGRESS" -gt 0 ]; then
        echo "🔨 ACTIVE STORIES:"
        gh issue list --repo "$REPO" --label "story:in-progress" --state open --format table
        echo ""
    fi
    
    if [ "$REVIEW" -gt 0 ]; then
        echo "👀 IN REVIEW:"
        gh issue list --repo "$REPO" --label "story:review" --state open --format table
        echo ""
    fi
    
    echo "Next update in ${MONITOR_INTERVAL} seconds..."
    sleep $MONITOR_INTERVAL
done
EOF

chmod +x "${TRACKER_DIR}/monitor-stories.sh"

# Create integration with existing project automation
cat > "${TRACKER_DIR}/integrate-project-sync.sh" << 'EOF'
#!/bin/bash
# Integration with existing CVMA project automation

# Source the existing simple-project-sync.sh if available
if [ -f "./scripts/simple-project-sync.sh" ]; then
    echo "🔗 Integrating with existing project sync..."
    
    # Add status tracking to deployment notifications
    update_deployment_status() {
        local story_number="$1"
        local status="$2"
        
        if [ ! -z "$story_number" ]; then
            # Update GitHub issue status
            source scripts/user-story-status-tracker.sh
            update_story_status "$story_number" "$status" "Deployment completed successfully"
            
            # Run existing project sync
            bash ./scripts/simple-project-sync.sh status
        fi
    }
    
    echo "✅ Integration functions created"
    echo "Usage: update_deployment_status <story_number> <status>"
else
    echo "⚠️  simple-project-sync.sh not found, standalone mode"
fi
EOF

chmod +x "${TRACKER_DIR}/integrate-project-sync.sh"

# Add real-time webhook simulation for continuous monitoring
cat > "${TRACKER_DIR}/webhook-simulator.sh" << 'EOF'
#!/bin/bash
# Webhook Event Simulator for Real-time Updates

REPO="zerovizboss/CVMA20-7"

simulate_deployment_event() {
    local story_number="$1"
    local branch="$2"
    local commit_hash=$(git rev-parse HEAD 2>/dev/null || echo "local-dev")
    local timestamp=$(date)
    
    echo "🚀 Deployment Event Detected"
    echo "Story: #${story_number}"
    echo "Branch: ${branch}"
    echo "Commit: ${commit_hash}"
    echo "Time: ${timestamp}"
    
    # Update story status to testing
    source "${REPORTS_DIR}/latest-tracker/status-updater.sh"
    update_story_status "$story_number" "testing" "Deployed to Salesforce org for testing"
    
    # Add deployment comment
    add_deployment_comment "$story_number" "Deployed Successfully" "Coverage: TBD" "PMD: TBD"
    
    echo "✅ Story status updated to testing"
}

simulate_quality_gate_event() {
    local story_number="$1"
    local pmd_score="$2"
    local coverage="$3"
    local test_results="$4"
    
    echo "📊 Quality Gate Event"
    echo "Story: #${story_number}"
    echo "PMD Score: ${pmd_score}%"
    echo "Coverage: ${coverage}%"
    
    # Add quality report
    source "${REPORTS_DIR}/latest-tracker/status-updater.sh"
    add_quality_report "$story_number" "$pmd_score" "$coverage" "$test_results"
    
    # Update status based on quality gates
    if [ "$pmd_score" -ge 90 ] && [ "$coverage" -ge 90 ]; then
        update_story_status "$story_number" "done" "Quality gates passed - story completed"
        echo "✅ Story marked as complete - quality gates passed"
    else
        update_story_status "$story_number" "in-progress" "Quality gates failed - returning to development"
        echo "❌ Story returned to development - quality gates failed"
    fi
}

echo "🎣 Webhook simulation functions loaded!"
echo "Available functions:"
echo "  simulate_deployment_event <story_number> <branch>"
echo "  simulate_quality_gate_event <story_number> <pmd_score> <coverage> <test_results>"
EOF

chmod +x "${TRACKER_DIR}/webhook-simulator.sh"

# Complete status report
cat >> "${TRACKER_DIR}/status-report.txt" << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REAL-TIME TRACKING FEATURES:

📊 Status Monitoring:
  - Automated story status transitions
  - Real-time progress tracking
  - Quality gate reporting
  - Deployment status updates

🔄 SDLC Integration:
  - GitHub issue label automation
  - Comment-based status updates
  - Commit linking to stories
  - Milestone progress tracking

⚡ Automation Scripts:
  - Status updater functions
  - Real-time monitoring dashboard
  - Webhook event simulation
  - Integration with existing project sync

FILES GENERATED:
  - Status Report: ${TRACKER_DIR}/status-report.txt
  - User Stories Data: ${TRACKER_DIR}/user-stories.json
  - Epics Data: ${TRACKER_DIR}/epics.json
  - Status Updater: ${TRACKER_DIR}/status-updater.sh
  - Monitor Dashboard: ${TRACKER_DIR}/monitor-stories.sh
  - Project Integration: ${TRACKER_DIR}/integrate-project-sync.sh
  - Webhook Simulator: ${TRACKER_DIR}/webhook-simulator.sh

NEXT STEPS:
1. Load status update functions: source ${TRACKER_DIR}/status-updater.sh
2. Start real-time monitoring: bash ${TRACKER_DIR}/monitor-stories.sh
3. Integrate with deployments: bash ${TRACKER_DIR}/integrate-project-sync.sh
4. Test webhook events: source ${TRACKER_DIR}/webhook-simulator.sh

EOF

# Display results
echo ""
echo "📋 Real-time User Story Status Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "${TRACKER_DIR}/status-report.txt"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create symlink to latest tracker
rm -f "${REPORTS_DIR}/latest-tracker"
ln -sf "${TIMESTAMP}/tracker" "${REPORTS_DIR}/latest-tracker"

echo ""
echo "📈 Latest tracking reports available at: ${REPORTS_DIR}/latest-tracker/"

# Exit successfully
echo "✅ Real-time User Story tracking setup completed successfully"
exit 0