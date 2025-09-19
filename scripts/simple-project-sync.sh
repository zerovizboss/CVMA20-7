#!/bin/bash
# Simple CVMA GitHub Project Automation (no external dependencies)
# Works with current GitHub CLI authentication

ACTION=${1:-help}
REPO="zerovizboss/CVMA20-7"
PROJECT_NUMBER=5
OWNER="zerovizboss"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

sync_project() {
    log_message "🔄 Syncing CVMA project board..."
    echo
    echo "=== CURRENT PROJECT BOARD ==="
    gh project item-list "$PROJECT_NUMBER" --owner "$OWNER"
    echo
    echo "=== OPEN ISSUES ==="
    gh issue list --repo "$REPO" --state open
    echo
    log_message "✅ Project sync completed"
}

generate_simple_report() {
    local report_date=$(date '+%Y-%m-%d')
    local report_file="reports/cvma-status-$report_date.md"
    
    log_message "📊 Generating simple project report..."
    mkdir -p reports
    
    cat > "$report_file" << EOF
# CVMA Project Status - $report_date

## Current Development Status

### Active Branch: $(git branch --show-current)

### Recent Commits (Last 5)
$(git log --oneline -5 | sed 's/^/- /')

### Open Issues
$(gh issue list --repo "$REPO" --state open | sed 's/^/- /')

### Recently Closed Issues (Last 5)  
$(gh issue list --repo "$REPO" --state closed --limit 5 | sed 's/^/- /')

### Epic Status
$(gh issue list --repo "$REPO" --search "EPIC" --state all | sed 's/^/- /')

---
*Generated*: $report_date  
*Repository*: https://github.com/$REPO  
*Project*: https://github.com/users/$OWNER/projects/$PROJECT_NUMBER
EOF
    
    log_message "📄 Report saved: $report_file"
    echo "✅ Report generated: $report_file"
}

update_deployment() {
    local issue_number="$1"
    local success_message="${2:-Deployment completed successfully}"
    
    if [ -z "$issue_number" ]; then
        log_message "❌ Issue number required"
        echo "Usage: $0 deploy <issue_number> [message]"
        return 1
    fi
    
    local deploy_comment="## 🚀 Deployment Completed

**Status**: Successfully deployed  
**Date**: $(date '+%Y-%m-%d %H:%M:%S')  
**Branch**: $(git branch --show-current)

### Details
$success_message

### Recent Commits
$(git log --oneline -3 | sed 's/^/- /')

🤖 Automated deployment notification"
    
    log_message "🚀 Updating deployment status for issue #$issue_number"
    
    # Add deployment comment
    if gh issue comment "$issue_number" --repo "$REPO" --body "$deploy_comment"; then
        log_message "✅ Deployment comment added to issue #$issue_number"
        
        # Close issue as completed
        if gh issue close "$issue_number" --repo "$REPO" --reason completed; then
            log_message "✅ Issue #$issue_number closed as completed"
        else
            log_message "⚠️ Could not close issue #$issue_number"
        fi
    else
        log_message "❌ Failed to comment on issue #$issue_number"
    fi
}

show_quick_status() {
    log_message "📊 CVMA Quick Status"
    echo
    echo "🔄 Current Branch: $(git branch --show-current)"
    echo "📝 Last Commit: $(git log -1 --format='%h - %s (%cr)')"
    echo
    echo "📋 Project Board Summary:"
    local board_count=$(gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" | wc -l)
    echo "   Total items on board: $((board_count - 1))"
    echo
    echo "🎯 Open Issues:"
    gh issue list --repo "$REPO" --state open --limit 3
    echo
    echo "✅ Recent Completions:"
    gh issue list --repo "$REPO" --state closed --limit 3
}

commit_and_notify() {
    local message="$1"
    local issue_number="$2"
    
    if [ -z "$message" ]; then
        log_message "❌ Commit message required"
        return 1
    fi
    
    log_message "💾 Creating commit and notification..."
    
    # Add all changes and commit
    git add .
    git commit -m "$message

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    if [ $? -eq 0 ]; then
        log_message "✅ Commit created: $message"
        
        # If issue number provided, update it
        if [ -n "$issue_number" ]; then
            local commit_hash=$(git rev-parse --short HEAD)
            update_deployment "$issue_number" "Code committed and ready for deployment (commit: $commit_hash)"
        fi
    else
        log_message "❌ Commit failed"
    fi
}

show_help() {
    cat << EOF
🤖 CVMA GitHub Project Automation Tool

Usage: $0 [action] [parameters]

Actions:
  sync                          - Show project board and issue status
  report                       - Generate project status report  
  status                       - Show quick project status
  deploy <issue#> [message]    - Mark issue as deployed and close it
  commit <message> [issue#]    - Commit changes and optionally notify issue
  help                         - Show this help

Examples:
  $0 sync                      - Sync and show project status
  $0 report                    - Generate daily status report
  $0 deploy 17 "RSVP system deployed"
  $0 commit "feat: Event RSVP system" 17
  
Current Setup:
  Repository: $REPO
  Project: https://github.com/users/$OWNER/projects/$PROJECT_NUMBER
  Branch: $(git branch --show-current 2>/dev/null || echo "unknown")
  
🚀 Ready to automate your CVMA project management!
EOF
}

# Main execution
case "$ACTION" in
    "sync")
        sync_project
        ;;
    "report")
        generate_simple_report
        ;;
    "status")
        show_quick_status
        ;;
    "deploy")
        update_deployment "$2" "$3"
        ;;
    "commit")
        commit_and_notify "$2" "$3"
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        echo "❌ Unknown action: $ACTION"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac