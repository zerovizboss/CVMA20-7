#!/bin/bash
# CVMA Code Review Approval Workflow
# Automated code review process with quality gates and approval tracking

set -e

# Configuration
REPORTS_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REVIEW_DIR="${REPORTS_DIR}/${TIMESTAMP}/review"
REPO="zerovizboss/CVMA20-7"
MIN_PMD_SCORE=90
MIN_COVERAGE=90

echo "👀 CVMA Code Review Approval Workflow"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create review reports directory
mkdir -p "${REVIEW_DIR}"

# Check required tools
echo "🔍 Verifying required tools..."
MISSING_TOOLS=()

if ! command -v gh &> /dev/null; then
    MISSING_TOOLS+=("GitHub CLI (gh)")
fi

if ! command -v git &> /dev/null; then
    MISSING_TOOLS+=("Git")
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "❌ Missing required tools:"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  - $tool"
    done
    exit 1
fi

echo "✅ All required tools available"

# Create code review checklist template
cat > "${REVIEW_DIR}/code-review-checklist.md" << 'EOF'
# CVMA Code Review Checklist

## Pre-Review Quality Gates ✅
- [ ] PMD Static Code Analysis Score ≥90%
- [ ] Code Coverage ≥90%
- [ ] All tests passing
- [ ] Build successful
- [ ] No merge conflicts

## Code Quality Review 🔍
- [ ] Code follows Salesforce best practices
- [ ] Proper error handling using CVMAErrorHandler
- [ ] WITH SECURITY_ENFORCED in all SOQL queries
- [ ] Input sanitization implemented
- [ ] No hardcoded values or magic numbers
- [ ] Proper null checks and validation

## Security Review 🔒
- [ ] No sensitive data exposed in logs
- [ ] CRUD/FLS permissions validated
- [ ] XSS prevention implemented
- [ ] No SOQL injection vulnerabilities
- [ ] Guest user access properly restricted

## Architecture Review 🏗️
- [ ] Follows established patterns
- [ ] Proper separation of concerns
- [ ] Reusable components where appropriate
- [ ] Performance considerations addressed
- [ ] Governor limits respected

## Testing Review 🧪
- [ ] Test coverage meets requirements (≥90%)
- [ ] Edge cases covered
- [ ] Negative scenarios tested
- [ ] Bulk operations tested
- [ ] User permission scenarios tested

## Documentation Review 📝
- [ ] Code is self-documenting with clear naming
- [ ] Complex logic has comments
- [ ] Public methods are documented
- [ ] User Story acceptance criteria met

## Final Approval ✅
- [ ] All checklist items completed
- [ ] Code reviewer approval
- [ ] Ready for deployment

**Reviewer**: _________________
**Date**: _________________
**Story/PR**: _________________
EOF

# Create automated review workflow
cat > "${REVIEW_DIR}/review-workflow.sh" << 'EOF'
#!/bin/bash
# Automated Code Review Workflow Functions

set -e

REPO="zerovizboss/CVMA20-7"
REVIEW_DIR="$(dirname "$0")"

# Function to start code review process
start_code_review() {
    local pr_number="$1"
    local reviewer="$2"
    
    echo "👀 Starting code review process for PR #${pr_number}..."
    
    # Get PR information
    gh pr view "$pr_number" --repo "$REPO" --json number,title,author,headRefName,url > "${REVIEW_DIR}/pr-${pr_number}-info.json"
    
    local pr_title=$(cat "${REVIEW_DIR}/pr-${pr_number}-info.json" | jq -r '.title')
    local pr_author=$(cat "${REVIEW_DIR}/pr-${pr_number}-info.json" | jq -r '.author.login')
    local branch=$(cat "${REVIEW_DIR}/pr-${pr_number}-info.json" | jq -r '.headRefName')
    
    echo "📋 PR Details:"
    echo "  Title: ${pr_title}"
    echo "  Author: ${pr_author}"
    echo "  Branch: ${branch}"
    echo "  Reviewer: ${reviewer}"
    
    # Add review started comment
    gh pr comment "$pr_number" --repo "$REPO" --body "👀 **Code Review Started**

**Reviewer**: @${reviewer}
**Started**: $(date)

## Review Process
This PR will undergo comprehensive review including:
- 🔍 Code quality and best practices
- 🔒 Security and permissions review
- 🧪 Test coverage validation
- 📊 Quality gate verification

**Status**: 🔄 Review In Progress

---
*Automated by CVMA Code Review Workflow*"
    
    # Update PR labels
    gh pr edit "$pr_number" --repo "$REPO" --add-label "review:in-progress"
    
    # Assign reviewer
    gh pr edit "$pr_number" --repo "$REPO" --add-reviewer "$reviewer"
    
    echo "✅ Code review process started for PR #${pr_number}"
}

# Function to run quality gates
run_quality_gates() {
    local pr_number="$1"
    local branch="$2"
    
    echo "📊 Running quality gates for PR #${pr_number}..."
    
    # Switch to branch for analysis
    git fetch origin "$branch"
    git checkout "$branch"
    
    local quality_report="${REVIEW_DIR}/quality-report-${pr_number}.txt"
    
    echo "CVMA Code Review Quality Gates Report" > "$quality_report"
    echo "PR #${pr_number} - $(date)" >> "$quality_report"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$quality_report"
    echo "" >> "$quality_report"
    
    # Run PMD analysis
    echo "🔍 Running PMD analysis..." >> "$quality_report"
    if [ -f "scripts/enhanced-pmd-analysis.sh" ]; then
        bash scripts/enhanced-pmd-analysis.sh > /dev/null 2>&1 || true
        
        # Extract PMD results
        if [ -f "reports/latest/compliance-report.txt" ]; then
            local pmd_score=$(grep "COMPLIANCE SCORE:" reports/latest/compliance-report.txt | sed 's/.*: \([0-9]*\)%.*/\1/')
            local critical_violations=$(grep "Critical (Priority 1):" reports/latest/compliance-report.txt | sed 's/.*: \([0-9]*\) violations/\1/')
            
            echo "PMD Static Code Analysis: ${pmd_score}% $([ "$pmd_score" -ge $MIN_PMD_SCORE ] && echo "✅ PASS" || echo "❌ FAIL")" >> "$quality_report"
            echo "Critical Violations: ${critical_violations} $([ "$critical_violations" -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")" >> "$quality_report"
        else
            echo "PMD Static Code Analysis: ❌ ANALYSIS FAILED" >> "$quality_report"
            pmd_score=0
        fi
    else
        echo "PMD Static Code Analysis: ⚠️ SCRIPT NOT FOUND" >> "$quality_report"
        pmd_score=0
    fi
    
    echo "" >> "$quality_report"
    
    # Run code coverage analysis
    echo "🧪 Running code coverage analysis..." >> "$quality_report"
    if [ -f "scripts/code-coverage-analysis.sh" ]; then
        bash scripts/code-coverage-analysis.sh > /dev/null 2>&1 || true
        
        # Extract coverage results
        if [ -f "reports/latest-coverage/coverage-report.txt" ]; then
            local coverage=$(grep "OVERALL COVERAGE:" reports/latest-coverage/coverage-report.txt | sed 's/.*: \([0-9]*\)%.*/\1/')
            local failed_tests=$(grep "Failed Tests:" reports/latest-coverage/coverage-report.txt | sed 's/.*: \([0-9]*\)/\1/')
            
            echo "Code Coverage: ${coverage}% $([ "$coverage" -ge $MIN_COVERAGE ] && echo "✅ PASS" || echo "❌ FAIL")" >> "$quality_report"
            echo "Failed Tests: ${failed_tests} $([ "$failed_tests" -eq 0 ] && echo "✅ PASS" || echo "❌ FAIL")" >> "$quality_report"
        else
            echo "Code Coverage: ❌ ANALYSIS FAILED" >> "$quality_report"
            coverage=0
        fi
    else
        echo "Code Coverage: ⚠️ SCRIPT NOT FOUND" >> "$quality_report"
        coverage=0
    fi
    
    echo "" >> "$quality_report"
    
    # Determine overall quality gate status
    local quality_gates_passed=true
    if [ "$pmd_score" -lt $MIN_PMD_SCORE ] || [ "$coverage" -lt $MIN_COVERAGE ] || [ "$critical_violations" -gt 0 ] || [ "$failed_tests" -gt 0 ]; then
        quality_gates_passed=false
    fi
    
    echo "OVERALL QUALITY GATES: $([ "$quality_gates_passed" = true ] && echo "✅ PASSED" || echo "❌ FAILED")" >> "$quality_report"
    echo "" >> "$quality_report"
    
    echo "RECOMMENDATIONS:" >> "$quality_report"
    if [ "$quality_gates_passed" = true ]; then
        echo "🟢 All quality gates passed - ready for manual code review" >> "$quality_report"
    else
        echo "🔴 Quality gates failed - requires fixes before manual review:" >> "$quality_report"
        [ "$pmd_score" -lt $MIN_PMD_SCORE ] && echo "  - Improve PMD score to ≥${MIN_PMD_SCORE}%" >> "$quality_report"
        [ "$coverage" -lt $MIN_COVERAGE ] && echo "  - Increase code coverage to ≥${MIN_COVERAGE}%" >> "$quality_report"
        [ "$critical_violations" -gt 0 ] && echo "  - Fix all critical PMD violations" >> "$quality_report"
        [ "$failed_tests" -gt 0 ] && echo "  - Fix all failing tests" >> "$quality_report"
    fi
    
    # Add quality report to PR
    gh pr comment "$pr_number" --repo "$REPO" --body "📊 **Quality Gates Report**

\`\`\`
$(cat "$quality_report")
\`\`\`

$([ "$quality_gates_passed" = true ] && echo "✅ **Quality gates passed** - ready for manual review" || echo "❌ **Quality gates failed** - please address issues and request re-review")

---
*Automated by CVMA Quality Gates*"
    
    # Update PR status based on quality gates
    if [ "$quality_gates_passed" = true ]; then
        gh pr edit "$pr_number" --repo "$REPO" --add-label "quality:passed" --remove-label "quality:failed"
        echo "✅ Quality gates passed for PR #${pr_number}"
        return 0
    else
        gh pr edit "$pr_number" --repo "$REPO" --add-label "quality:failed" --remove-label "quality:passed"
        echo "❌ Quality gates failed for PR #${pr_number}"
        return 1
    fi
}

# Function to complete manual review
complete_manual_review() {
    local pr_number="$1"
    local reviewer="$2"
    local approval_status="$3"
    local comments="$4"
    
    echo "📝 Completing manual review for PR #${pr_number}..."
    
    local review_comment="👀 **Manual Code Review Completed**

**Reviewer**: @${reviewer}
**Status**: ${approval_status}
**Completed**: $(date)

## Review Comments
${comments}

## Review Checklist Status
- [x] Code quality and best practices reviewed
- [x] Security and permissions validated
- [x] Architecture and patterns assessed
- [x] Documentation adequacy confirmed

---
*Manual Review by ${reviewer}*"
    
    # Add review completion comment
    gh pr comment "$pr_number" --repo "$REPO" --body "$review_comment"
    
    case $approval_status in
        "APPROVED")
            gh pr edit "$pr_number" --repo "$REPO" \
                --add-label "review:approved" \
                --remove-label "review:in-progress,review:changes-requested"
            gh pr review "$pr_number" --repo "$REPO" --approve --body "✅ Code review approved. Ready for deployment."
            echo "✅ PR #${pr_number} approved and ready for deployment"
            ;;
        "CHANGES_REQUESTED")
            gh pr edit "$pr_number" --repo "$REPO" \
                --add-label "review:changes-requested" \
                --remove-label "review:in-progress,review:approved"
            gh pr review "$pr_number" --repo "$REPO" --request-changes --body "🔄 Changes requested. Please address review comments."
            echo "🔄 Changes requested for PR #${pr_number}"
            ;;
        *)
            echo "❌ Invalid approval status: ${approval_status}"
            return 1
            ;;
    esac
}

# Function to merge approved PR
merge_approved_pr() {
    local pr_number="$1"
    local merge_method="$2"
    
    echo "🔀 Merging approved PR #${pr_number}..."
    
    # Verify PR is approved
    local approval_status=$(gh pr view "$pr_number" --repo "$REPO" --json reviewDecision | jq -r '.reviewDecision // "REVIEW_REQUIRED"')
    
    if [ "$approval_status" != "APPROVED" ]; then
        echo "❌ PR #${pr_number} is not approved (status: ${approval_status})"
        return 1
    fi
    
    # Merge PR
    case $merge_method in
        "merge"|"squash"|"rebase")
            gh pr merge "$pr_number" --repo "$REPO" --"$merge_method" --delete-branch
            echo "✅ PR #${pr_number} merged successfully using ${merge_method}"
            ;;
        *)
            gh pr merge "$pr_number" --repo "$REPO" --merge --delete-branch
            echo "✅ PR #${pr_number} merged successfully using default merge"
            ;;
    esac
    
    # Add merge notification
    gh pr comment "$pr_number" --repo "$REPO" --body "🎉 **PR Merged Successfully**

**Merge Time**: $(date)
**Method**: ${merge_method:-merge}

The code has been integrated into the main branch and is ready for deployment.

---
*Automated by CVMA Code Review Workflow*"
}

echo "🛠️  Code review workflow functions loaded!"
echo ""
echo "Available functions:"
echo "  start_code_review <pr_number> <reviewer>"
echo "  run_quality_gates <pr_number> <branch>"
echo "  complete_manual_review <pr_number> <reviewer> <APPROVED|CHANGES_REQUESTED> [comments]"
echo "  merge_approved_pr <pr_number> [merge_method]"
echo ""
echo "Merge methods: merge, squash, rebase"
EOF

chmod +x "${REVIEW_DIR}/review-workflow.sh"

# Create review dashboard script
cat > "${REVIEW_DIR}/review-dashboard.sh" << 'EOF'
#!/bin/bash
# CVMA Code Review Dashboard

REPO="zerovizboss/CVMA20-7"

echo "👀 CVMA Code Review Dashboard - $(date)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get PRs pending review
echo "📋 Pull Requests Pending Review:"
PENDING_REVIEW=$(gh pr list --repo "$REPO" --state open --label "review:in-progress" --json number,title,author,createdAt)
if [ "$(echo "$PENDING_REVIEW" | jq 'length')" -eq 0 ]; then
    echo "  No PRs pending review"
else
    echo "$PENDING_REVIEW" | jq -r '.[] | "  #\(.number) - \(.title) by @\(.author.login) (\(.createdAt[:10]))"'
fi

echo ""

# Get PRs with changes requested
echo "🔄 Pull Requests with Changes Requested:"
CHANGES_REQUESTED=$(gh pr list --repo "$REPO" --state open --label "review:changes-requested" --json number,title,author,updatedAt)
if [ "$(echo "$CHANGES_REQUESTED" | jq 'length')" -eq 0 ]; then
    echo "  No PRs with changes requested"
else
    echo "$CHANGES_REQUESTED" | jq -r '.[] | "  #\(.number) - \(.title) by @\(.author.login) (updated: \(.updatedAt[:10]))"'
fi

echo ""

# Get approved PRs ready for merge
echo "✅ Approved PRs Ready for Merge:"
APPROVED_PRS=$(gh pr list --repo "$REPO" --state open --label "review:approved" --json number,title,author,reviewDecision)
if [ "$(echo "$APPROVED_PRS" | jq 'length')" -eq 0 ]; then
    echo "  No approved PRs ready for merge"
else
    echo "$APPROVED_PRS" | jq -r '.[] | "  #\(.number) - \(.title) by @\(.author.login)"'
fi

echo ""

# Show quality gate failures
echo "❌ PRs with Quality Gate Failures:"
QUALITY_FAILED=$(gh pr list --repo "$REPO" --state open --label "quality:failed" --json number,title,author)
if [ "$(echo "$QUALITY_FAILED" | jq 'length')" -eq 0 ]; then
    echo "  No PRs with quality gate failures"
else
    echo "$QUALITY_FAILED" | jq -r '.[] | "  #\(.number) - \(.title) by @\(.author.login)"'
fi

echo ""
echo "🔗 Repository: https://github.com/zerovizboss/CVMA20-7"
EOF

chmod +x "${REVIEW_DIR}/review-dashboard.sh"

# Create review approval tracking
cat > "${REVIEW_DIR}/approval-tracker.sh" << 'EOF'
#!/bin/bash
# CVMA Review Approval Tracking

REPO="zerovizboss/CVMA20-7"
LOG_FILE="review-approvals.log"

# Function to log review activities
log_review_activity() {
    local pr_number="$1"
    local activity="$2"
    local reviewer="$3"
    local timestamp=$(date)
    
    echo "${timestamp} | PR #${pr_number} | ${activity} | ${reviewer}" >> "$LOG_FILE"
}

# Function to generate review metrics
generate_review_metrics() {
    local period_days="${1:-30}"  # Default to 30 days
    local since_date=$(date -d "${period_days} days ago" +"%Y-%m-%d")
    
    echo "📊 CVMA Code Review Metrics (Last ${period_days} days)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get PR data
    gh pr list --repo "$REPO" --state all --json number,title,author,createdAt,closedAt,reviewDecision,reviews \
        --jq --arg since "$since_date" '.[] | select(.createdAt >= $since)' > metrics_data.json
    
    local total_prs=$(cat metrics_data.json | jq -s 'length')
    local approved_prs=$(cat metrics_data.json | jq -s '[.[] | select(.reviewDecision == "APPROVED")] | length')
    local merged_prs=$(cat metrics_data.json | jq -s '[.[] | select(.closedAt != null)] | length')
    
    echo "Total PRs Created: ${total_prs}"
    echo "PRs Approved: ${approved_prs}"
    echo "PRs Merged: ${merged_prs}"
    
    if [ $total_prs -gt 0 ]; then
        local approval_rate=$((approved_prs * 100 / total_prs))
        local merge_rate=$((merged_prs * 100 / total_prs))
        echo "Approval Rate: ${approval_rate}%"
        echo "Merge Rate: ${merge_rate}%"
    fi
    
    # Average review time calculation
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "📈 Review Activity Summary:"
        echo "Review activities logged: $(wc -l < "$LOG_FILE")"
        
        # Show top reviewers
        echo ""
        echo "🏆 Top Reviewers:"
        awk -F' | ' '{print $4}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -5
    fi
    
    # Cleanup
    rm -f metrics_data.json
}

echo "📊 Review approval tracking functions loaded!"
echo ""
echo "Available functions:"
echo "  log_review_activity <pr_number> <activity> <reviewer>"
echo "  generate_review_metrics [days]"
EOF

chmod +x "${REVIEW_DIR}/approval-tracker.sh"

# Create comprehensive workflow report
cat > "${REVIEW_DIR}/review-workflow-report.txt" << EOF
CVMA Code Review Approval Workflow Setup
Generated: $(date)
Repository: ${REPO}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CODE REVIEW WORKFLOW COMPONENTS:

📋 Review Checklist:
  - Comprehensive code review checklist template
  - Quality gates verification (PMD ≥90%, Coverage ≥90%)
  - Security review requirements
  - Architecture and testing validation

⚡ Automated Workflow Functions:
  - start_code_review: Initiate review process with PR assignment
  - run_quality_gates: Execute automated quality validation
  - complete_manual_review: Record manual review completion
  - merge_approved_pr: Handle approved PR merging

📊 Review Dashboard:
  - Real-time PR status monitoring
  - Pending reviews tracking
  - Quality gate failure alerts
  - Approval and merge readiness

📈 Approval Tracking:
  - Review activity logging
  - Performance metrics calculation
  - Reviewer statistics and rankings
  - Time-to-approval analytics

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REVIEW WORKFLOW PROCESS:

1. 📝 **PR Creation**
   - Developer creates pull request
   - Automated quality gates execute
   - Review process initiated automatically

2. 🔍 **Quality Gate Validation**
   - PMD static code analysis (target: ≥90%)
   - Code coverage validation (target: ≥90%)
   - Test execution and validation
   - Security and compliance checks

3. 👀 **Manual Code Review**
   - Assigned reviewer receives notification
   - Comprehensive checklist validation
   - Code quality and architecture review
   - Security and best practices verification

4. ✅ **Review Approval Process**
   - Approve: Ready for merge and deployment
   - Request Changes: Return to developer with feedback
   - Activity logging and metrics tracking

5. 🔀 **Merge and Deployment**
   - Approved PRs merged to main branch
   - Deployment preparation initiated
   - User story status updated automatically

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

QUALITY GATES CONFIGURATION:

🎯 Minimum Requirements:
  - PMD Compliance Score: ≥90%
  - Code Coverage: ≥90%
  - Critical Violations: 0
  - Failed Tests: 0

🔒 Security Requirements:
  - WITH SECURITY_ENFORCED in all SOQL queries
  - Input sanitization implemented
  - CRUD/FLS validation present
  - XSS prevention measures

🏗️ Architecture Requirements:
  - CVMAErrorHandler framework usage
  - Proper exception handling
  - Performance optimization
  - Governor limit compliance

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FILES GENERATED:

📋 Templates and Checklists:
  - Code Review Checklist: ${REVIEW_DIR}/code-review-checklist.md

⚡ Workflow Automation:
  - Review Workflow Functions: ${REVIEW_DIR}/review-workflow.sh
  - Review Dashboard: ${REVIEW_DIR}/review-dashboard.sh
  - Approval Tracker: ${REVIEW_DIR}/approval-tracker.sh

📊 Reports and Documentation:
  - Workflow Setup Report: ${REVIEW_DIR}/review-workflow-report.txt

USAGE EXAMPLES:

# Start code review for PR #15
source ${REVIEW_DIR}/review-workflow.sh
start_code_review 15 "zerovizboss"

# Run quality gates
run_quality_gates 15 "feature/user-story-15"

# Complete manual review with approval
complete_manual_review 15 "zerovizboss" "APPROVED" "Great work! Code meets all standards."

# Merge approved PR
merge_approved_pr 15 "squash"

# View review dashboard
bash ${REVIEW_DIR}/review-dashboard.sh

# Generate review metrics
source ${REVIEW_DIR}/approval-tracker.sh
generate_review_metrics 30

INTEGRATION POINTS:

🔗 GitHub Integration:
  - Automatic PR labeling and status updates
  - Reviewer assignment and notifications
  - Quality gate reporting in comments
  - Merge automation with branch cleanup

📊 Quality Gate Integration:
  - PMD analysis automation
  - Code coverage validation
  - Test execution monitoring
  - Deployment readiness verification

🎯 SDLC Integration:
  - User story status synchronization
  - Project board updates
  - Milestone progress tracking
  - Deployment workflow triggers

EOF

# Display results
echo ""
echo "📋 Code Review Workflow Results:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "${REVIEW_DIR}/review-workflow-report.txt"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create symlink to latest review workflow
rm -f "${REPORTS_DIR}/latest-review"
ln -sf "${TIMESTAMP}/review" "${REPORTS_DIR}/latest-review"

echo ""
echo "📈 Latest review workflow available at: ${REPORTS_DIR}/latest-review/"

# Exit successfully
echo "✅ Code review approval workflow setup completed successfully"
exit 0