#!/bin/bash

# CVMA Copilot Agent - Bash Operations Specialist
# Handles all bash execution, file operations, and system tasks for Claude
# Created: September 9, 2025

# Agent configuration
AGENT_NAME="copilot"
ORCHESTRATOR_DIR="/c/Users/zerov/IdeaProjects/cvma/scripts/agent-orchestration"
WORK_QUEUE_DIR="$ORCHESTRATOR_DIR/work-queue" 
AGENT_LOG="$ORCHESTRATOR_DIR/../logs/agents/copilot-agent.log"

# Ensure directories exist
mkdir -p "$(dirname "$AGENT_LOG")"

# Logging function
log_message() {
    echo "[$(date)] [COPILOT] $1" | tee -a "$AGENT_LOG"
}

# Copilot-specific bash execution capabilities
execute_bash_command() {
    local command="$1"
    local context="$2"
    local work_unit_id="$3"
    
    log_message "Executing bash command: $command"
    
    local start_time=$(date +%s)
    local output=""
    local exit_code=0
    
    # Execute command with error handling
    if output=$(eval "$command" 2>&1); then
        exit_code=0
        log_message "Command succeeded: $command"
    else
        exit_code=$?
        log_message "Command failed (exit $exit_code): $command"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Return structured result
    cat << EOF
{
    "command": "$command",
    "exit_code": $exit_code,
    "output": "$(echo "$output" | jq -R . | jq -s . | jq -r 'join("\\n")')",
    "duration_seconds": $duration,
    "context": "$context",
    "work_unit_id": "$work_unit_id",
    "executed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# Advanced git operations
perform_git_operation() {
    local operation="$1"
    local parameters="$2"
    local work_unit_id="$3"
    
    log_message "Git operation: $operation with params: $parameters"
    
    cd /c/Users/zerov/IdeaProjects/cvma || {
        log_message "Failed to change to CVMA directory"
        return 1
    }
    
    local result=""
    local success=true
    
    case "$operation" in
        "status")
            result=$(git status --porcelain 2>&1) || success=false
            ;;
        "add")
            result=$(git add "$parameters" 2>&1) || success=false
            ;;
        "commit")
            result=$(git commit -m "$parameters" 2>&1) || success=false
            ;;
        "push")
            result=$(git push 2>&1) || success=false
            ;;
        "pull")
            result=$(git pull 2>&1) || success=false
            ;;
        "branch")
            if [ "$parameters" = "list" ]; then
                result=$(git branch 2>&1) || success=false
            else
                result=$(git checkout -b "$parameters" 2>&1) || success=false
            fi
            ;;
        "log")
            local count="${parameters:-10}"
            result=$(git log --oneline -n "$count" 2>&1) || success=false
            ;;
        "diff")
            result=$(git diff "$parameters" 2>&1) || success=false
            ;;
        *)
            result="Unknown git operation: $operation"
            success=false
            ;;
    esac
    
    if [ "$success" = true ]; then
        log_message "Git operation '$operation' completed successfully"
    else
        log_message "Git operation '$operation' failed"
    fi
    
    cat << EOF
{
    "operation": "$operation",
    "parameters": "$parameters",
    "success": $success,
    "output": "$(echo "$result" | jq -R . | jq -s . | jq -r 'join("\\n")')",
    "work_unit_id": "$work_unit_id",
    "executed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# File system operations
perform_file_operation() {
    local operation="$1"
    local file_path="$2"
    local additional_params="$3"
    local work_unit_id="$4"
    
    log_message "File operation: $operation on $file_path"
    
    local result=""
    local success=true
    
    case "$operation" in
        "exists")
            if [ -e "$file_path" ]; then
                result="File exists: $file_path"
            else
                result="File does not exist: $file_path"
            fi
            ;;
        "create_dir")
            result=$(mkdir -p "$file_path" 2>&1) || success=false
            [ "$success" = true ] && result="Directory created: $file_path"
            ;;
        "list_dir")
            result=$(ls -la "$file_path" 2>&1) || success=false
            ;;
        "get_size")
            result=$(du -sh "$file_path" 2>&1) || success=false
            ;;
        "permissions")
            result=$(stat -c "%A %U:%G" "$file_path" 2>/dev/null || stat -f "%Sp %Su:%Sg" "$file_path" 2>&1) || success=false
            ;;
        "find_files")
            local pattern="$additional_params"
            result=$(find "$file_path" -name "$pattern" 2>&1) || success=false
            ;;
        "count_lines")
            result=$(wc -l < "$file_path" 2>&1) || success=false
            ;;
        "tail")
            local lines="${additional_params:-10}"
            result=$(tail -n "$lines" "$file_path" 2>&1) || success=false
            ;;
        *)
            result="Unknown file operation: $operation"
            success=false
            ;;
    esac
    
    if [ "$success" = true ]; then
        log_message "File operation '$operation' completed successfully"
    else
        log_message "File operation '$operation' failed"
    fi
    
    cat << EOF
{
    "operation": "$operation",
    "file_path": "$file_path",
    "additional_params": "$additional_params",
    "success": $success,
    "output": "$(echo "$result" | jq -R . | jq -s . | jq -r 'join("\\n")')",
    "work_unit_id": "$work_unit_id",
    "executed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# System monitoring and health checks
perform_system_monitoring() {
    local metric="$1"
    local parameters="$2"
    local work_unit_id="$3"
    
    log_message "System monitoring: $metric"
    
    local result=""
    local success=true
    
    case "$metric" in
        "disk_usage")
            result=$(df -h "$parameters" 2>&1) || success=false
            ;;
        "process_list")
            result=$(ps aux | grep "$parameters" | grep -v grep 2>&1) || {
                result="No processes found matching: $parameters"
            }
            ;;
        "memory_usage")
            # Windows-compatible memory check
            result=$(wmic OS get TotalVisibleMemorySize,FreePhysicalMemory /value 2>/dev/null || echo "Memory info unavailable")
            ;;
        "uptime")
            result=$(uptime 2>/dev/null || echo "Uptime info unavailable on Windows")
            ;;
        "network_test")
            result=$(ping -c 4 "$parameters" 2>&1) || success=false
            ;;
        "port_check")
            result=$(netstat -an | grep "$parameters" 2>&1) || {
                result="Port $parameters not found in netstat output"
            }
            ;;
        *)
            result="Unknown system metric: $metric"
            success=false
            ;;
    esac
    
    if [ "$success" = true ]; then
        log_message "System monitoring '$metric' completed successfully"
    else
        log_message "System monitoring '$metric' failed"
    fi
    
    cat << EOF
{
    "metric": "$metric",
    "parameters": "$parameters", 
    "success": $success,
    "output": "$(echo "$result" | jq -R . | jq -s . | jq -r 'join("\\n")')",
    "work_unit_id": "$work_unit_id",
    "executed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# Deployment and build operations
perform_deployment_task() {
    local task_type="$1"
    local parameters="$2"
    local work_unit_id="$3"
    
    log_message "Deployment task: $task_type"
    
    cd /c/Users/zerov/IdeaProjects/cvma || {
        log_message "Failed to change to CVMA directory"
        return 1
    }
    
    local result=""
    local success=true
    
    case "$task_type" in
        "sf_deploy")
            result=$(sf project deploy start --source-dir src/ 2>&1) || success=false
            ;;
        "sf_retrieve")
            result=$(sf project retrieve start --source-dir src/ 2>&1) || success=false
            ;;
        "run_tests")
            result=$(sf apex run test 2>&1) || success=false
            ;;
        "package_xml_sync")
            result=$(./scripts/package-xml-sync.sh 2>&1) || success=false
            ;;
        "pmd_analysis")
            result=$(./scripts/enhanced-pmd-analysis.sh 2>&1) || success=false
            ;;
        "build_static_resources")
            # Build JavaScript libraries or other static resources
            result="Static resource build not implemented yet"
            ;;
        *)
            result="Unknown deployment task: $task_type"
            success=false
            ;;
    esac
    
    if [ "$success" = true ]; then
        log_message "Deployment task '$task_type' completed successfully"
    else
        log_message "Deployment task '$task_type' failed"
    fi
    
    cat << EOF
{
    "task_type": "$task_type",
    "parameters": "$parameters",
    "success": $success,
    "output": "$(echo "$result" | jq -R . | jq -s . | jq -r 'join("\\n")')",
    "work_unit_id": "$work_unit_id",
    "executed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# Main task dispatcher
dispatch_task() {
    local work_unit_file="$1"
    
    if [ ! -f "$work_unit_file" ]; then
        log_message "Work unit file not found: $work_unit_file"
        return 1
    fi
    
    local unit_id=$(jq -r '.unit_id' "$work_unit_file")
    local task_type=$(jq -r '.task_type' "$work_unit_file")
    local description=$(jq -r '.description' "$work_unit_file")
    
    log_message "Dispatching task: $unit_id [$task_type] - $description"
    
    # Update work unit status
    jq '.status = "in_progress" | .started_at = now | .started_at |= todateiso8601' \
       "$work_unit_file" > "${work_unit_file}.tmp" && mv "${work_unit_file}.tmp" "$work_unit_file"
    
    local task_result=""
    local task_success=true
    
    case "$task_type" in
        "bash_execution")
            local command=$(jq -r '.context.command // ""' "$work_unit_file")
            local context=$(jq -r '.context.description // ""' "$work_unit_file")
            task_result=$(execute_bash_command "$command" "$context" "$unit_id")
            ;;
        "git_operations") 
            local git_op=$(jq -r '.context.operation // ""' "$work_unit_file")
            local git_params=$(jq -r '.context.parameters // ""' "$work_unit_file")
            task_result=$(perform_git_operation "$git_op" "$git_params" "$unit_id")
            ;;
        "file_operations")
            local file_op=$(jq -r '.context.operation // ""' "$work_unit_file")
            local file_path=$(jq -r '.context.file_path // ""' "$work_unit_file")
            local additional=$(jq -r '.context.additional_params // ""' "$work_unit_file")
            task_result=$(perform_file_operation "$file_op" "$file_path" "$additional" "$unit_id")
            ;;
        "system_monitoring")
            local metric=$(jq -r '.context.metric // ""' "$work_unit_file")
            local params=$(jq -r '.context.parameters // ""' "$work_unit_file")
            task_result=$(perform_system_monitoring "$metric" "$params" "$unit_id")
            ;;
        "deployment_tasks")
            local deploy_type=$(jq -r '.context.task_type // ""' "$work_unit_file")
            local deploy_params=$(jq -r '.context.parameters // ""' "$work_unit_file")
            task_result=$(perform_deployment_task "$deploy_type" "$deploy_params" "$unit_id")
            ;;
        *)
            log_message "Unknown task type: $task_type"
            task_result='{"success": false, "error": "Unknown task type"}'
            task_success=false
            ;;
    esac
    
    # Extract success status from task result
    if echo "$task_result" | jq -e '.success == false' > /dev/null; then
        task_success=false
    fi
    
    # Update work unit with results
    local completion_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    if [ "$task_success" = true ]; then
        jq --argjson result "$task_result" --arg completed_at "$completion_time" \
           '.status = "completed" | .results = $result | .completed_at = $completed_at' \
           "$work_unit_file" > "${work_unit_file}.tmp" && mv "${work_unit_file}.tmp" "$work_unit_file"
        
        log_message "Task $unit_id completed successfully"
    else
        jq --argjson result "$task_result" --arg completed_at "$completion_time" \
           '.status = "failed" | .results = $result | .completed_at = $completed_at' \
           "$work_unit_file" > "${work_unit_file}.tmp" && mv "${work_unit_file}.tmp" "$work_unit_file"
        
        log_message "Task $unit_id failed"
    fi
    
    return 0
}

# Copilot agent main loop
run_agent() {
    log_message "Copilot agent starting..."
    
    while true; do
        # Look for pending work assigned to copilot
        for work_file in "$WORK_QUEUE_DIR"/*.json; do
            [ -f "$work_file" ] || continue
            
            local assigned_agent=$(jq -r '.assigned_agent' "$work_file" 2>/dev/null)
            local status=$(jq -r '.status' "$work_file" 2>/dev/null)
            
            if [ "$assigned_agent" = "copilot" ] && [ "$status" = "pending" ]; then
                dispatch_task "$work_file"
            fi
        done
        
        # Brief pause between cycles
        sleep 2
    done
}

# Command interface
case "$1" in
    "start")
        run_agent
        ;;
    "test_bash")
        echo "Testing bash execution..."
        result=$(execute_bash_command "echo 'Hello from Copilot Agent'" "test" "test_unit")
        echo "$result" | jq .
        ;;
    "test_git")
        echo "Testing git operations..."
        result=$(perform_git_operation "status" "" "test_unit")
        echo "$result" | jq .
        ;;
    "test_file")
        echo "Testing file operations..."
        result=$(perform_file_operation "exists" "/c/Users/zerov/IdeaProjects/cvma/README.md" "" "test_unit")
        echo "$result" | jq .
        ;;
    "status")
        echo "🤖 Copilot Agent Status"
        echo "======================"
        echo "Agent Name: $AGENT_NAME"
        echo "Log File: $AGENT_LOG"
        echo "Work Queue: $WORK_QUEUE_DIR"
        echo
        echo "Capabilities:"
        echo "  ⚙️  Bash command execution"
        echo "  📁 File system operations"
        echo "  🔀 Git operations"
        echo "  📊 System monitoring"
        echo "  🚀 Deployment tasks"
        echo
        if [ -f "$AGENT_LOG" ]; then
            echo "Recent activity:"
            tail -5 "$AGENT_LOG"
        fi
        ;;
    *)
        echo "🤖 CVMA Copilot Agent - Bash Operations Specialist"
        echo "================================================="
        echo
        echo "Commands:"
        echo "  start      - Start agent daemon"
        echo "  test_bash  - Test bash execution"
        echo "  test_git   - Test git operations"
        echo "  test_file  - Test file operations"
        echo "  status     - Show agent status"
        echo
        echo "This agent handles all bash operations for Claude, implementing"
        echo "the Separation of Concerns pattern in the multi-agent system."
        ;;
esac