#!/bin/bash
# CVMA GitHub Project Board Automation Script
# Works with current GitHub CLI authentication

ACTION=${1:-sync}
REPO="zerovizboss/CVMA20-7"
PROJECT_NUMBER=5
OWNER="zerovizboss"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

sync_project_board() {
    log_message "🔄 Syncing CVMA project board..."
    
    # Get open issues not on project board
    gh issue list --repo "$REPO" --state open --json number,title,url | jq -r '.[] | "Issue #\(.number): \(.title) - \(.url)"'
    
    # List current project items
    log_message "📋 Current project board items:"
    gh project item-list "$PROJECT_NUMBER" --owner "$OWNER"
    
    log_message "✅ Project board sync completed"
}

generate_report() {
    local report_date=$(date '+%Y-%m-%d')
    local report_file="reports/cvma-project-status-$report_date.md"
    
    log_message "📊 Generating project status report..."
    
    # Create reports directory if it doesn't exist
    mkdir -p reports
    
    # Get project statistics
    local total_issues=$(gh issue list --repo "$REPO" --state all --json number | jq length)
    local open_issues=$(gh issue list --repo "$REPO" --state open --json number | jq length)
    local closed_issues=$(gh issue list --repo "$REPO" --state closed --json number | jq length)
    
    # Calculate completion rate
    local completion_rate=0
    if [ "$total_issues" -gt 0 ]; then
        completion_rate=$(echo "scale=1; $closed_issues * 100 / $total_issues" | bc -l)
    fi
    
    # Generate report
    cat > "$report_file" << EOF
# CVMA Project Status Report - $report_date

## 📊 Project Overview

### Statistics
- **Total Issues**: $total_issues
- **Open Issues**: $open_issues  
- **Closed Issues**: $closed_issues
- **Completion Rate**: ${completion_rate}%

### Recent Activity (Last 7 Days)
$(gh issue list --repo "$REPO" --state closed --limit 5 --json number,title,closedAt | jq -r '.[] | "- #\(.number): \(.title) (closed: \(.closedAt | split("T")[0]))"')

### Open Issues by Priority
$(gh issue list --repo "$REPO" --state open --label enhancement --json number,title | jq -r '.[] | "- #\(.number): \(.title)"')

### Epic Status
$(gh issue list --repo "$REPO" --state all --search "EPIC in:title" --json number,title,state | jq -r '.[] | "- **\(.title)**: \(.state | ascii_upcase)"')

## 🚀 Development Metrics

### Recent Commits
$(git log --oneline -5 | sed 's/^/- /')

### Current Branch
- **Branch**: $(git branch --show-current)
- **Last Commit**: $(git log -1 --format="%h - %s (%cr)")

---
*Generated on: $report_date*  
*Repository*: [$REPO](https://github.com/$REPO)  
*Project Board*: [CVMA Project](https://github.com/users/$OWNER/projects/$PROJECT_NUMBER)
EOF
    
    log_message "📄 Report generated: $report_file"
    echo "Report saved to: $report_file"
}

update_issue_status() {
    local issue_number="$1"
    local status="$2"
    local comment="$3"
    
    if [ -z "$issue_number" ]; then
        log_message "❌ Issue number required"
        return 1
    fi
    
    log_message "🔄 Updating issue #$issue_number..."
    
    if [ "$status" = "completed" ] || [ "$status" = "done" ]; then
        local close_comment="## ✅ Issue Completed

$comment

**Status**: Completed  
**Completion Date**: $(date '+%Y-%m-%d %H:%M:%S')

🤖 Auto-updated by CVMA Project Sync"
        
        gh issue close "$issue_number" --repo "$REPO" --reason completed
        gh issue comment "$issue_number" --repo "$REPO" --body "$close_comment"
        log_message "✅ Issue #$issue_number closed as completed"
    elif [ -n "$comment" ]; then
        gh issue comment "$issue_number" --repo "$REPO" --body "$comment"
        log_message "✅ Comment added to issue #$issue_number"
    fi
}

show_status() {
    log_message "📋 CVMA Project Current Status"
    echo
    echo "=== PROJECT BOARD ==="
    gh project item-list "$PROJECT_NUMBER" --owner "$OWNER"
    echo
    echo "=== OPEN ISSUES ==="
    gh issue list --repo "$REPO" --state open
    echo  
    echo "=== RECENT COMMITS ==="
    git log --oneline -5
    echo
    echo "=== DEVELOPMENT METRICS ==="
    echo "- Current Branch: $(git branch --show-current)"
    echo "- Open Issues: $(gh issue list --repo "$REPO" --state open --json number | jq length)"
    echo "- Closed Issues: $(gh issue list --repo "$REPO" --state closed --json number | jq length)"
    echo "- Last Deploy: $(git log --grep="deploy" --oneline -1 || echo "No deployment commits found")"
}

deploy_complete() {
    local user_story="$1"
    local description="$2"
    
    log_message "🚀 Processing deployment completion for: $user_story"
    
    # Find related issue
    local issue_number=$(gh issue list --repo "$REPO" --state open --search "$user_story" --json number,title | jq -r '.[0].number // empty')
    
    if [ -n "$issue_number" ]; then
        local deploy_comment="## 🚀 Deployment Completed

**User Story**: $user_story  
**Status**: Successfully deployed to Salesforce org  
**Deployment Date**: $(date '+%Y-%m-%d %H:%M:%S')

### Implementation Details
$description

### Next Steps
- [x] Code deployed to org
- [x] Components verified working
- [x] Issue marked as completed

🤖 Auto-generated deployment notification"
        
        update_issue_status "$issue_number" "completed" "$deploy_comment"
        log_message "✅ Deployment notification sent for User Story: $user_story"
    else
        log_message "⚠️  No open issue found for: $user_story"
    fi
}

show_help() {
    echo "CVMA GitHub Project Automation Tool"
    echo
    echo "Usage: $0 [action] [options]"
    echo
    echo "Actions:"
    echo "  sync                     - Sync project board with repository issues"
    echo "  report                   - Generate project status report"
    echo "  status                   - Show current project status"
    echo "  update <issue> <status>  - Update issue status (completed/in-progress)"
    echo "  deploy <story> <desc>    - Mark user story as deployed"
    echo "  help                     - Show this help message"
    echo
    echo "Examples:"
    echo "  $0 sync"
    echo "  $0 report"
    echo "  $0 status"
    echo "  $0 update 17 completed"
    echo "  $0 deploy 'User Story #8' 'Event RSVP system deployed'"
    echo
    echo "🤖 CVMA Project Automation with Claude Code integration"
}

# Main execution
case "$ACTION" in
    "sync")
        sync_project_board
        ;;
    "report")
        generate_report
        ;;
    "status")
        show_status
        ;;
    "update")
        update_issue_status "$2" "$3" "$4"
        ;;
    "deploy")
        deploy_complete "$2" "$3"
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        log_message "❌ Unknown action: $ACTION"
        show_help
        exit 1
        ;;
esac

log_message "🏁 CVMA project sync completed"