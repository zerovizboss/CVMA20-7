#!/bin/bash

# Agent Capabilities Monitor
# Monitors performance, health, and capabilities of all agents in the multi-agent system
# Author: Generated via Claude-Copilot Multi-Agent Architecture
# Date: September 9, 2025

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs/agents"
METRICS_DIR="$PROJECT_ROOT/logs/metrics"
AGENT_STATE_DIR="$SCRIPT_DIR/agent-state"
WORK_QUEUE_DIR="$SCRIPT_DIR/work-queue"

# Ensure directories exist
mkdir -p "$LOG_DIR" "$METRICS_DIR" "$AGENT_STATE_DIR" "$WORK_QUEUE_DIR"

# Agent definitions
AGENTS=("claude" "copilot" "salesforce-monitor" "cvma-support")

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [CAPABILITIES-MONITOR] $*" | tee -a "$LOG_DIR/capabilities-monitor.log"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] [CAPABILITIES-MONITOR] $*" | tee -a "$LOG_DIR/capabilities-monitor.log"
}

success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] [CAPABILITIES-MONITOR] $*" | tee -a "$LOG_DIR/capabilities-monitor.log"
}

# Monitor individual agent health
monitor_agent_health() {
    local agent_name="$1"
    local agent_file="$AGENT_STATE_DIR/${agent_name}.json"
    
    if [[ ! -f "$agent_file" ]]; then
        error "Agent state file not found for $agent_name"
        return 1
    fi
    
    local status=$(jq -r '.status' "$agent_file" 2>/dev/null || echo "unknown")
    local last_updated=$(jq -r '.last_updated' "$agent_file" 2>/dev/null || echo "never")
    local current_task=$(jq -r '.current_task' "$agent_file" 2>/dev/null || echo "none")
    
    log "Agent $agent_name status: $status, task: $current_task, updated: $last_updated"
    
    # Check if agent is responsive (last update within 10 minutes)
    if [[ "$last_updated" != "never" ]]; then
        local current_time=$(date -u +%s)
        local update_time=$(date -d "$last_updated" +%s 2>/dev/null || echo "0")
        local time_diff=$((current_time - update_time))
        
        if [[ $time_diff -gt 600 ]]; then  # 10 minutes
            error "Agent $agent_name appears unresponsive (last update: ${time_diff}s ago)"
            return 1
        else
            success "Agent $agent_name is responsive (last update: ${time_diff}s ago)"
        fi
    else
        error "Agent $agent_name has never been updated"
        return 1
    fi
    
    return 0
}

# Monitor work queue performance
monitor_work_queue() {
    local agent_name="$1"
    
    log "Monitoring work queue performance for $agent_name..."
    
    local pending_count=0
    local in_progress_count=0
    local completed_count=0
    local failed_count=0
    
    # Count work units by status for this agent
    for work_file in "$WORK_QUEUE_DIR"/*.json; do
        [[ -f "$work_file" ]] || continue
        
        local assigned_agent=$(jq -r '.assigned_agent' "$work_file" 2>/dev/null)
        local status=$(jq -r '.status' "$work_file" 2>/dev/null)
        
        if [[ "$assigned_agent" == "$agent_name" ]]; then
            case "$status" in
                "pending") ((pending_count++)) ;;
                "in_progress") ((in_progress_count++)) ;;
                "completed") ((completed_count++)) ;;
                "failed") ((failed_count++)) ;;
            esac
        fi
    done
    
    log "Work queue stats for $agent_name: pending=$pending_count, in_progress=$in_progress_count, completed=$completed_count, failed=$failed_count"
    
    # Calculate success rate
    local total_processed=$((completed_count + failed_count))
    local success_rate=0
    
    if [[ $total_processed -gt 0 ]]; then
        success_rate=$(echo "scale=2; $completed_count * 100 / $total_processed" | bc 2>/dev/null || echo "0")
    fi
    
    echo "$success_rate"
}

# Test agent capabilities
test_agent_capabilities() {
    local agent_name="$1"
    
    log "Testing capabilities for $agent_name..."
    
    case "$agent_name" in
        "claude")
            test_claude_capabilities
            ;;
        "copilot")
            test_copilot_capabilities
            ;;
        "salesforce-monitor")
            test_salesforce_monitor_capabilities
            ;;
        "cvma-support")
            test_cvma_support_capabilities
            ;;
        *)
            error "Unknown agent: $agent_name"
            return 1
            ;;
    esac
}

# Test Claude capabilities
test_claude_capabilities() {
    log "Testing Claude strategic capabilities..."
    
    # Test planning capability (simulated)
    local test_work_unit="test_claude_planning_$(date +%s)"
    
    cat > "$WORK_QUEUE_DIR/${test_work_unit}.json" << EOF
{
    "unit_id": "$test_work_unit",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "assigned_agent": "claude",
    "task_type": "high_level_planning",
    "description": "Test planning capability",
    "priority": 1,
    "status": "pending",
    "context": {"test": true},
    "results": {},
    "started_at": null,
    "completed_at": null,
    "error_info": null
}
EOF
    
    success "Created test work unit for Claude: $test_work_unit"
}

# Test Copilot capabilities
test_copilot_capabilities() {
    log "Testing Copilot tactical capabilities..."
    
    # Test bash execution
    local test_work_unit="test_copilot_bash_$(date +%s)"
    
    cat > "$WORK_QUEUE_DIR/${test_work_unit}.json" << EOF
{
    "unit_id": "$test_work_unit",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "assigned_agent": "copilot",
    "task_type": "bash_execution",
    "description": "Test bash execution capability",
    "priority": 1,
    "status": "pending",
    "context": {
        "command": "echo 'Copilot capability test successful'",
        "test": true
    },
    "results": {},
    "started_at": null,
    "completed_at": null,
    "error_info": null
}
EOF
    
    success "Created test work unit for Copilot: $test_work_unit"
}

# Test Salesforce Monitor capabilities
test_salesforce_monitor_capabilities() {
    log "Testing Salesforce Monitor capabilities..."
    
    # Test org health monitoring
    if command -v sf >/dev/null 2>&1; then
        local test_result=$(sf org display --json 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            success "Salesforce Monitor: org connectivity test passed"
        else
            error "Salesforce Monitor: org connectivity test failed"
        fi
    else
        error "Salesforce Monitor: sf CLI not available"
    fi
    
    # Test monitoring agent script
    if [[ -x "$SCRIPT_DIR/salesforce-monitoring-agent.sh" ]]; then
        success "Salesforce Monitor: agent script is executable"
    else
        error "Salesforce Monitor: agent script not found or not executable"
    fi
}

# Test CVMA Support capabilities
test_cvma_support_capabilities() {
    log "Testing CVMA Support capabilities..."
    
    # Test Experience Cloud connectivity (simulated)
    local site_url="https://cvma20-7-dev-ed.develop.my.site.com"
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$site_url" 2>/dev/null || echo "000")
    
    if [[ "$http_code" == "200" ]] || [[ "$http_code" == "302" ]]; then
        success "CVMA Support: Experience Cloud site accessibility test passed (HTTP $http_code)"
    else
        error "CVMA Support: Experience Cloud site accessibility test failed (HTTP $http_code)"
    fi
    
    # Test support agent script
    if [[ -x "$SCRIPT_DIR/cvma-support-agent.sh" ]]; then
        success "CVMA Support: agent script is executable"
    else
        error "CVMA Support: agent script not found or not executable"
    fi
}

# Generate performance metrics
generate_performance_metrics() {
    log "Generating performance metrics for all agents..."
    
    local timestamp=$(date -Iseconds)
    local today=$(date +%Y-%m-%d)
    local metrics_file="$METRICS_DIR/agent-performance-$today.json"
    
    local metrics='{"timestamp": "'$timestamp'", "date": "'$today'", "agents": {}}'
    
    for agent in "${AGENTS[@]}"; do
        log "Collecting metrics for $agent..."
        
        local success_rate=$(monitor_work_queue "$agent")
        local health_status="unknown"
        
        if monitor_agent_health "$agent" >/dev/null 2>&1; then
            health_status="healthy"
        else
            health_status="unhealthy"
        fi
        
        # Add agent metrics
        metrics=$(echo "$metrics" | jq --arg agent "$agent" --arg rate "$success_rate" --arg health "$health_status" '
            .agents[$agent] = {
                "success_rate": ($rate | tonumber),
                "health_status": $health,
                "last_checked": "'$timestamp'"
            }
        ')
    done
    
    echo "$metrics" > "$metrics_file"
    success "Performance metrics saved to $metrics_file"
}

# Check system dependencies
check_dependencies() {
    log "Checking system dependencies..."
    
    local dependencies=("jq" "bc" "curl")
    local missing_deps=()
    
    for dep in "${dependencies[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            success "Dependency $dep: available"
        else
            error "Dependency $dep: missing"
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing_deps[*]}"
        return 1
    else
        success "All dependencies are available"
        return 0
    fi
}

# Monitor inter-agent communication
monitor_communication() {
    log "Monitoring inter-agent communication..."
    
    local communication_dir="$SCRIPT_DIR/communication"
    local message_count=0
    local unread_count=0
    
    if [[ -d "$communication_dir" ]]; then
        for inbox in "$communication_dir"/*_inbox.json; do
            [[ -f "$inbox" ]] || continue
            
            local agent_name=$(basename "$inbox" _inbox.json)
            local total_messages=$(jq 'length' "$inbox" 2>/dev/null || echo "0")
            local unread_messages=$(jq '[.[] | select(.status == "unread")] | length' "$inbox" 2>/dev/null || echo "0")
            
            message_count=$((message_count + total_messages))
            unread_count=$((unread_count + unread_messages))
            
            log "Agent $agent_name: $total_messages total messages, $unread_messages unread"
        done
        
        log "Communication summary: $message_count total messages, $unread_count unread"
    else
        log "Communication directory not found, assuming no inter-agent messages"
    fi
}

# Generate comprehensive status report
generate_status_report() {
    log "Generating comprehensive status report..."
    
    local report_file="$METRICS_DIR/system-status-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "CVMA Multi-Agent System Status Report"
        echo "===================================="
        echo "Generated: $(date)"
        echo
        
        echo "AGENT HEALTH STATUS"
        echo "-------------------"
        for agent in "${AGENTS[@]}"; do
            echo -n "$agent: "
            if monitor_agent_health "$agent" >/dev/null 2>&1; then
                echo "HEALTHY"
            else
                echo "UNHEALTHY"
            fi
        done
        echo
        
        echo "WORK QUEUE PERFORMANCE"
        echo "----------------------"
        for agent in "${AGENTS[@]}"; do
            local success_rate=$(monitor_work_queue "$agent")
            echo "$agent: ${success_rate}% success rate"
        done
        echo
        
        echo "SYSTEM DEPENDENCIES"
        echo "-------------------"
        if check_dependencies >/dev/null 2>&1; then
            echo "All dependencies: AVAILABLE"
        else
            echo "Some dependencies: MISSING"
        fi
        echo
        
        echo "COMMUNICATION SYSTEM"
        echo "--------------------"
        monitor_communication 2>&1 | grep -E "(total messages|Communication summary)"
        
    } > "$report_file"
    
    success "Status report generated: $report_file"
    cat "$report_file"
}

# Main execution function
main() {
    case "${1:-help}" in
        "health")
            log "Running agent health checks..."
            for agent in "${AGENTS[@]}"; do
                monitor_agent_health "$agent"
            done
            ;;
        "performance")
            log "Running performance monitoring..."
            generate_performance_metrics
            ;;
        "test")
            log "Testing agent capabilities..."
            check_dependencies
            for agent in "${AGENTS[@]}"; do
                test_agent_capabilities "$agent"
            done
            ;;
        "report")
            log "Generating comprehensive status report..."
            generate_status_report
            ;;
        "monitor")
            log "Running complete monitoring cycle..."
            check_dependencies
            for agent in "${AGENTS[@]}"; do
                monitor_agent_health "$agent"
            done
            generate_performance_metrics
            monitor_communication
            success "Monitoring cycle completed"
            ;;
        "status")
            echo "Agent Capabilities Monitor Status:"
            echo "  Script Directory: $SCRIPT_DIR"
            echo "  Log Directory: $LOG_DIR"
            echo "  Metrics Directory: $METRICS_DIR"
            echo "  Monitored Agents: ${AGENTS[*]}"
            echo "  Dependencies: $(check_dependencies >/dev/null 2>&1 && echo "✓ OK" || echo "✗ Missing")"
            ;;
        "help"|*)
            echo "Agent Capabilities Monitor - Multi-Agent System Health and Performance Monitor"
            echo
            echo "Usage: $0 {health|performance|test|report|monitor|status|help}"
            echo
            echo "Commands:"
            echo "  health       - Check health status of all agents"
            echo "  performance  - Generate performance metrics"
            echo "  test         - Test agent capabilities and dependencies"
            echo "  report       - Generate comprehensive status report"
            echo "  monitor      - Run complete monitoring cycle"
            echo "  status       - Display monitor configuration"
            echo "  help         - Display this help message"
            echo
            echo "Monitored Agents: ${AGENTS[*]}"
            ;;
    esac
}

# Execute main function
main "$@"