#!/bin/bash
# =============================================================================
# CVMA Adaptive Session Token Optimization
# User Story #22: 75% efficiency improvement through intelligent session management
# =============================================================================

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="CVMA Adaptive Session Scheduler"
readonly VERSION="1.0.0"
readonly BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${BASE_DIR}/session-optimization.log"
readonly ANALYTICS_FILE="${BASE_DIR}/token-analytics.json"
readonly STATE_FILE="${BASE_DIR}/session-state.json"

# Token Management Constants
readonly MAX_TOKENS=200000
readonly EMERGENCY_THRESHOLD_PCT=98
readonly HIGH_COMPLEXITY_PCT=95
readonly MEDIUM_COMPLEXITY_PCT=85
readonly LOW_COMPLEXITY_PCT=75

# Session Scheduling Constants (in seconds)
readonly HIGH_UTILIZATION_INTERVAL=10800  # 3 hours
readonly MEDIUM_UTILIZATION_INTERVAL=18000 # 5 hours
readonly LOW_UTILIZATION_INTERVAL=25200    # 7 hours

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# =============================================================================
# Logging and Utility Functions
# =============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    echo -e "${BLUE}[$timestamp]${NC} ${GREEN}[$level]${NC} $message"
}

error() {
    local message="$*"
    log "ERROR" "$message"
    echo -e "${RED}Error: $message${NC}" >&2
}

warning() {
    local message="$*"
    log "WARN" "$message"
    echo -e "${YELLOW}Warning: $message${NC}"
}

info() {
    local message="$*"
    log "INFO" "$message"
}

# =============================================================================
# Token Management Functions  
# =============================================================================

estimate_current_tokens() {
    # Estimate current token usage based on conversation length
    # This is a fallback estimation since we can't directly access Claude's token count
    local estimated_tokens=0
    
    # Check recent git activity as proxy for development work
    local recent_commits=$(git log --oneline --since="1 hour ago" 2>/dev/null | wc -l || echo 0)
    local modified_files=$(git status --porcelain 2>/dev/null | wc -l || echo 0)
    
    # Base estimation algorithm
    estimated_tokens=$((50000 + (recent_commits * 5000) + (modified_files * 2000)))
    
    # Cap at reasonable maximum
    if [ $estimated_tokens -gt $MAX_TOKENS ]; then
        estimated_tokens=$MAX_TOKENS
    fi
    
    echo "$estimated_tokens"
}

calculate_utilization_percentage() {
    local current_tokens="$1"
    local utilization=$(echo "scale=1; ($current_tokens * 100) / $MAX_TOKENS" | bc -l)
    echo "$utilization"
}

get_dynamic_threshold() {
    local task_complexity="$1"
    local threshold_pct
    
    case "$task_complexity" in
        "high")
            threshold_pct=$HIGH_COMPLEXITY_PCT
            ;;
        "medium")
            threshold_pct=$MEDIUM_COMPLEXITY_PCT
            ;;
        "low")
            threshold_pct=$LOW_COMPLEXITY_PCT
            ;;
        "emergency")
            threshold_pct=$EMERGENCY_THRESHOLD_PCT
            ;;
        *)
            threshold_pct=$MEDIUM_COMPLEXITY_PCT
            ;;
    esac
    
    local threshold=$(echo "($MAX_TOKENS * $threshold_pct) / 100" | bc)
    echo "$threshold"
}

# =============================================================================
# Task Complexity Analysis
# =============================================================================

analyze_task_complexity() {
    local task_description="$1"
    local complexity="medium"  # default
    
    # High complexity indicators
    if [[ "$task_description" =~ (User Story|Epic|deployment|integration|NPSP|Lightning|Apex) ]]; then
        complexity="high"
    # Low complexity indicators  
    elif [[ "$task_description" =~ (documentation|analysis|review|planning|README) ]]; then
        complexity="low"
    # Emergency indicators
    elif [[ "$task_description" =~ (critical|emergency|hotfix|urgent|production) ]]; then
        complexity="emergency"
    fi
    
    echo "$complexity"
}

get_current_task_context() {
    local task_context=""
    
    # Check todo list for current work
    if [ -f "${BASE_DIR}/../.claude/todos.json" ]; then
        task_context=$(jq -r '.[] | select(.status == "in_progress") | .content' "${BASE_DIR}/../.claude/todos.json" 2>/dev/null | head -1 || echo "")
    fi
    
    # Check git commit messages as fallback
    if [ -z "$task_context" ]; then
        task_context=$(git log --oneline -1 2>/dev/null | cut -d' ' -f2- || echo "general development")
    fi
    
    echo "$task_context"
}

# =============================================================================
# Session Analytics and Tracking
# =============================================================================

update_analytics() {
    local session_data="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Create analytics entry
    local analytics_entry=$(cat <<EOF
{
    "timestamp": "$timestamp",
    "sessionData": $session_data
}
EOF
)
    
    # Update analytics file (keep last 50 entries)
    if [ -f "$ANALYTICS_FILE" ]; then
        local temp_file=$(mktemp)
        jq ". += [$analytics_entry] | if length > 50 then .[1:] else . end" "$ANALYTICS_FILE" > "$temp_file"
        mv "$temp_file" "$ANALYTICS_FILE"
    else
        echo "[$analytics_entry]" > "$ANALYTICS_FILE"
    fi
}

calculate_average_utilization() {
    if [ ! -f "$ANALYTICS_FILE" ]; then
        echo "75.0"  # Default assumption
        return
    fi
    
    local avg_utilization=$(jq -r '[.[] | .sessionData.utilizationPct] | add / length' "$ANALYTICS_FILE" 2>/dev/null || echo "75.0")
    echo "$avg_utilization"
}

generate_optimization_report() {
    local current_tokens="$1"
    local utilization_pct="$2"
    local task_complexity="$3"
    local next_interval="$4"
    
    info "=== Session Optimization Report ==="
    info "Current Token Usage: $current_tokens / $MAX_TOKENS"
    info "Utilization: ${utilization_pct}%"
    info "Task Complexity: $task_complexity"
    info "Next Session Interval: $(($next_interval / 3600)) hours"
    
    # Historical analysis
    local avg_utilization=$(calculate_average_utilization)
    info "Average Utilization: ${avg_utilization}%"
    
    # Recommendations
    if (( $(echo "$utilization_pct > 90" | bc -l) )); then
        info "✅ Excellent token utilization - maintaining aggressive schedule"
    elif (( $(echo "$utilization_pct > 75" | bc -l) )); then
        info "✅ Good token utilization - standard scheduling"
    else
        info "⚠️  Low token utilization - consider extending next session"
    fi
}

# =============================================================================
# Adaptive Session Scheduling
# =============================================================================

calculate_next_session_interval() {
    local utilization_pct="$1"
    local task_complexity="$2"
    local interval
    
    # Base interval on utilization
    if (( $(echo "$utilization_pct > 90" | bc -l) )); then
        interval=$HIGH_UTILIZATION_INTERVAL
    elif (( $(echo "$utilization_pct > 75" | bc -l) )); then
        interval=$MEDIUM_UTILIZATION_INTERVAL
    else
        interval=$LOW_UTILIZATION_INTERVAL
    fi
    
    # Adjust for task complexity
    case "$task_complexity" in
        "high"|"emergency")
            # Reduce interval for complex tasks
            interval=$(echo "$interval * 0.8" | bc | cut -d. -f1)
            ;;
        "low")
            # Increase interval for simple tasks  
            interval=$(echo "$interval * 1.2" | bc | cut -d. -f1)
            ;;
    esac
    
    echo "$interval"
}

should_extend_session() {
    local current_tokens="$1"
    local task_complexity="$2"
    local current_task="$3"
    
    local threshold=$(get_dynamic_threshold "$task_complexity")
    
    # Check if approaching threshold
    if [ "$current_tokens" -ge "$threshold" ]; then
        # Check if we're in middle of important work
        if [[ "$current_task" =~ (User Story|Epic|deployment|critical) ]]; then
            echo "true"
            return
        fi
    fi
    
    echo "false"
}

save_session_state() {
    local session_data="$1"
    echo "$session_data" > "$STATE_FILE"
}

load_session_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "{}"
    fi
}

# =============================================================================
# Main Session Optimization Logic
# =============================================================================

optimize_session() {
    local mode="${1:-analyze}"
    
    info "🚀 Starting CVMA Session Token Optimization"
    info "Mode: $mode"
    
    # Get current session data
    local current_tokens=$(estimate_current_tokens)
    local utilization_pct=$(calculate_utilization_percentage "$current_tokens")
    local current_task=$(get_current_task_context)
    local task_complexity=$(analyze_task_complexity "$current_task")
    
    info "Current Task: $current_task"
    info "Task Complexity: $task_complexity"
    
    # Calculate optimal scheduling
    local next_interval=$(calculate_next_session_interval "$utilization_pct" "$task_complexity")
    local should_extend=$(should_extend_session "$current_tokens" "$task_complexity" "$current_task")
    
    # Create session data object
    local session_data=$(cat <<EOF
{
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "currentTokens": $current_tokens,
    "maxTokens": $MAX_TOKENS,
    "utilizationPct": $utilization_pct,
    "taskComplexity": "$task_complexity",
    "currentTask": "$current_task",
    "nextInterval": $next_interval,
    "shouldExtend": $should_extend,
    "mode": "$mode"
}
EOF
)
    
    # Save state and update analytics
    save_session_state "$session_data"
    update_analytics "$session_data"
    
    # Generate optimization report
    generate_optimization_report "$current_tokens" "$utilization_pct" "$task_complexity" "$next_interval"
    
    # Take action based on mode
    case "$mode" in
        "schedule")
            schedule_next_session "$next_interval"
            ;;
        "extend")
            if [ "$should_extend" = "true" ]; then
                info "🔄 Session extension recommended - continuing work on: $current_task"
                return 0
            else
                info "⏰ Session ready for completion"
                return 1
            fi
            ;;
        "analyze")
            info "📊 Analysis complete - no action taken"
            ;;
    esac
}

schedule_next_session() {
    local interval="$1"
    local next_time=$(date -d "+${interval} seconds" +"%Y-%m-%d %H:%M:%S")
    local hours=$(echo "$interval / 3600" | bc)
    
    info "⏰ Next session scheduled for: $next_time (in ${hours}h)"
    
    # Update MEMORY.md with next session time
    if [ -f "${BASE_DIR}/../MEMORY.md" ]; then
        local temp_file=$(mktemp)
        sed "s/Next Session: .*/Next Session: $next_time (${hours}h interval)/" "${BASE_DIR}/../MEMORY.md" > "$temp_file"
        mv "$temp_file" "${BASE_DIR}/../MEMORY.md"
    fi
}

# =============================================================================
# CLI Interface
# =============================================================================

show_help() {
    cat <<EOF
$SCRIPT_NAME v$VERSION

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    optimize [analyze|schedule|extend]  Run session optimization (default: analyze)
    status                             Show current session status
    analytics                          Display usage analytics
    reset                              Reset analytics and state
    help                               Show this help

EXAMPLES:
    $0 optimize analyze        # Analyze current session without taking action
    $0 optimize schedule       # Optimize and schedule next session  
    $0 optimize extend         # Check if session should be extended
    $0 status                  # Show current optimization status
    $0 analytics               # Display token usage analytics

Vets Serving Vets through Intelligent Development Optimization ⚡🏍️
EOF
}

show_status() {
    info "📊 Current Session Status:"
    
    if [ -f "$STATE_FILE" ]; then
        local state=$(cat "$STATE_FILE")
        local tokens=$(echo "$state" | jq -r '.currentTokens')
        local utilization=$(echo "$state" | jq -r '.utilizationPct')
        local complexity=$(echo "$state" | jq -r '.taskComplexity')
        local task=$(echo "$state" | jq -r '.currentTask')
        
        info "Token Usage: $tokens / $MAX_TOKENS (${utilization}%)"
        info "Current Task: $task"
        info "Complexity: $complexity"
    else
        warning "No session state found - run 'optimize' first"
    fi
}

show_analytics() {
    info "📈 Token Usage Analytics:"
    
    if [ -f "$ANALYTICS_FILE" ]; then
        local avg_utilization=$(calculate_average_utilization)
        local session_count=$(jq '. | length' "$ANALYTICS_FILE")
        
        info "Sessions Tracked: $session_count"
        info "Average Utilization: ${avg_utilization}%"
        info "Recent Sessions:"
        
        jq -r '.[-5:] | .[] | "  \(.timestamp): \(.sessionData.utilizationPct)% - \(.sessionData.currentTask)"' "$ANALYTICS_FILE" 2>/dev/null || info "  No recent sessions"
    else
        warning "No analytics data found"
    fi
}

reset_state() {
    info "🔄 Resetting session state and analytics..."
    [ -f "$STATE_FILE" ] && rm "$STATE_FILE"
    [ -f "$ANALYTICS_FILE" ] && rm "$ANALYTICS_FILE"
    [ -f "$LOG_FILE" ] && rm "$LOG_FILE"
    info "✅ State reset complete"
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
    # Ensure required tools are available
    command -v jq >/dev/null 2>&1 || { error "jq is required but not installed"; exit 1; }
    command -v bc >/dev/null 2>&1 || { error "bc is required but not installed"; exit 1; }
    
    # Create log file if it doesn't exist
    touch "$LOG_FILE"
    
    case "${1:-help}" in
        "optimize")
            optimize_session "${2:-analyze}"
            ;;
        "status")
            show_status
            ;;
        "analytics")
            show_analytics  
            ;;
        "reset")
            reset_state
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"