#!/bin/bash

# CVMA Claude-Copilot Agent Orchestrator
# Multi-agent coordination system with Unit of Work pattern
# Created: September 9, 2025

# Configuration
ORCHESTRATOR_DIR="/c/Users/zerov/IdeaProjects/cvma/scripts/agent-orchestration"
WORK_QUEUE_DIR="$ORCHESTRATOR_DIR/work-queue"
AGENT_STATE_DIR="$ORCHESTRATOR_DIR/agent-state"
COMMUNICATION_DIR="$ORCHESTRATOR_DIR/communication"
LOG_DIR="/c/Users/zerov/IdeaProjects/cvma/logs/agents"

# Create required directories
mkdir -p "$WORK_QUEUE_DIR" "$AGENT_STATE_DIR" "$COMMUNICATION_DIR" "$LOG_DIR"

# Agent responsibility definitions
CLAUDE_RESPONSIBILITIES=(
    "high_level_planning"
    "architecture_decisions" 
    "user_story_management"
    "code_review"
    "documentation"
    "error_analysis"
    "strategic_refactoring"
)

COPILOT_RESPONSIBILITIES=(
    "bash_execution"
    "file_operations"
    "git_operations"
    "deployment_tasks"
    "testing_automation"
    "build_processes"
    "system_monitoring"
)

# Unit of Work structure
create_work_unit() {
    local unit_id="$1"
    local agent_type="$2"
    local task_type="$3"
    local description="$4"
    local priority="$5"
    
    local work_unit_file="$WORK_QUEUE_DIR/${unit_id}.json"
    
    cat > "$work_unit_file" << EOF
{
    "unit_id": "$unit_id",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "assigned_agent": "$agent_type",
    "task_type": "$task_type",
    "description": "$description",
    "priority": $priority,
    "status": "pending",
    "dependencies": [],
    "context": {},
    "results": {},
    "started_at": null,
    "completed_at": null,
    "error_info": null
}
EOF
    
    echo "Work unit created: $unit_id for $agent_type"
}

# Agent state management
update_agent_state() {
    local agent_name="$1"
    local status="$2"
    local current_task="$3"
    
    cat > "$AGENT_STATE_DIR/${agent_name}.json" << EOF
{
    "agent_name": "$agent_name",
    "status": "$status",
    "current_task": "$current_task",
    "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "capabilities": $(printf '%s\n' "${agent_name^^}_RESPONSIBILITIES[@]" | jq -R . | jq -s .),
    "performance_metrics": {
        "tasks_completed": 0,
        "success_rate": 1.0,
        "average_completion_time": 0
    }
}
EOF
}

# Inter-agent communication
send_message() {
    local from_agent="$1"
    local to_agent="$2"
    local message_type="$3"
    local content="$4"
    
    local message_id="msg_$(date +%s)_$$"
    local message_file="$COMMUNICATION_DIR/${to_agent}_inbox.json"
    
    # Create message
    local message=$(cat << EOF
{
    "message_id": "$message_id",
    "from": "$from_agent",
    "to": "$to_agent",
    "type": "$message_type",
    "content": "$content",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "unread"
}
EOF
)
    
    # Append to inbox (create if doesn't exist)
    if [ -f "$message_file" ]; then
        jq --argjson msg "$message" '. += [$msg]' "$message_file" > "${message_file}.tmp" && mv "${message_file}.tmp" "$message_file"
    else
        echo "[$message]" > "$message_file"
    fi
    
    echo "Message sent: $from_agent -> $to_agent [$message_type]"
}

# Work unit processor
process_work_queue() {
    local agent_name="$1"
    
    echo "[$(date)] Processing work queue for $agent_name..."
    
    # Find pending work units for this agent
    for work_file in "$WORK_QUEUE_DIR"/*.json; do
        [ -f "$work_file" ] || continue
        
        local assigned_agent=$(jq -r '.assigned_agent' "$work_file")
        local status=$(jq -r '.status' "$work_file")
        
        if [ "$assigned_agent" = "$agent_name" ] && [ "$status" = "pending" ]; then
            local unit_id=$(jq -r '.unit_id' "$work_file")
            local task_type=$(jq -r '.task_type' "$work_file")
            local description=$(jq -r '.description' "$work_file")
            
            echo "Processing work unit: $unit_id [$task_type]"
            
            # Update work unit status
            jq '.status = "in_progress" | .started_at = now | .started_at |= todateiso8601' "$work_file" > "${work_file}.tmp" && mv "${work_file}.tmp" "$work_file"
            
            # Execute work based on agent type
            if [ "$agent_name" = "copilot" ]; then
                execute_copilot_work "$unit_id" "$task_type" "$description" "$work_file"
            elif [ "$agent_name" = "claude" ]; then
                execute_claude_work "$unit_id" "$task_type" "$description" "$work_file"
            fi
        fi
    done
}

# Copilot work execution (bash operations)
execute_copilot_work() {
    local unit_id="$1"
    local task_type="$2"
    local description="$3"
    local work_file="$4"
    
    echo "[COPILOT] Executing: $task_type - $description"
    
    local result_file="/tmp/copilot_result_${unit_id}.json"
    local success=true
    local output=""
    local error_info=""
    
    case "$task_type" in
        "bash_execution")
            local command=$(jq -r '.context.command' "$work_file")
            echo "[COPILOT] Running: $command"
            
            if output=$(eval "$command" 2>&1); then
                echo "[COPILOT] Command succeeded"
            else
                success=false
                error_info="Command failed: $command"
                echo "[COPILOT] Command failed: $error_info"
            fi
            ;;
            
        "git_operations")
            local git_command=$(jq -r '.context.git_command' "$work_file")
            echo "[COPILOT] Git operation: $git_command"
            
            cd /c/Users/zerov/IdeaProjects/cvma
            if output=$(git $git_command 2>&1); then
                echo "[COPILOT] Git operation succeeded"
            else
                success=false
                error_info="Git operation failed: $git_command"
                echo "[COPILOT] Git operation failed: $error_info"
            fi
            ;;
            
        "file_operations")
            local operation=$(jq -r '.context.operation' "$work_file")
            local file_path=$(jq -r '.context.file_path' "$work_file")
            echo "[COPILOT] File operation: $operation on $file_path"
            
            case "$operation" in
                "create_directory")
                    mkdir -p "$file_path" && output="Directory created: $file_path" || {
                        success=false
                        error_info="Failed to create directory: $file_path"
                    }
                    ;;
                "check_exists")
                    [ -e "$file_path" ] && output="File exists: $file_path" || output="File does not exist: $file_path"
                    ;;
                "get_permissions")
                    output=$(ls -la "$file_path" 2>&1) || {
                        success=false
                        error_info="Failed to get permissions for: $file_path"
                    }
                    ;;
            esac
            ;;
            
        "system_monitoring")
            local metric=$(jq -r '.context.metric' "$work_file")
            case "$metric" in
                "disk_usage")
                    output=$(df -h /c/Users/zerov/IdeaProjects/cvma 2>&1)
                    ;;
                "memory_usage")
                    output=$(free -h 2>&1 || echo "Memory info unavailable on Windows")
                    ;;
                "process_status")
                    local process_name=$(jq -r '.context.process_name' "$work_file")
                    output=$(pgrep -f "$process_name" 2>&1 || echo "Process not found: $process_name")
                    ;;
            esac
            ;;
            
        *)
            success=false
            error_info="Unknown task type: $task_type"
            ;;
    esac
    
    # Update work unit with results
    local completion_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    if [ "$success" = true ]; then
        jq --arg output "$output" --arg completed_at "$completion_time" \
           '.status = "completed" | .results.output = $output | .completed_at = $completed_at' \
           "$work_file" > "${work_file}.tmp" && mv "${work_file}.tmp" "$work_file"
        
        # Notify Claude of completion
        send_message "copilot" "claude" "task_completed" "Work unit $unit_id completed successfully"
    else
        jq --arg error "$error_info" --arg completed_at "$completion_time" \
           '.status = "failed" | .error_info = $error | .completed_at = $completed_at' \
           "$work_file" > "${work_file}.tmp" && mv "${work_file}.tmp" "$work_file"
        
        # Notify Claude of failure
        send_message "copilot" "claude" "task_failed" "Work unit $unit_id failed: $error_info"
    fi
    
    echo "[COPILOT] Work unit $unit_id completed with status: $([ "$success" = true ] && echo "SUCCESS" || echo "FAILED")"
}

# Claude work execution (strategic tasks)
execute_claude_work() {
    local unit_id="$1"
    local task_type="$2"
    local description="$3"
    local work_file="$4"
    
    echo "[CLAUDE] Executing: $task_type - $description"
    
    # Claude work is typically handled by the main Claude process
    # This function serves as a placeholder for Claude work coordination
    
    case "$task_type" in
        "high_level_planning")
            echo "[CLAUDE] Planning task delegated to main Claude process"
            # Signal to main Claude process that planning is needed
            ;;
            
        "architecture_decisions")
            echo "[CLAUDE] Architecture decision delegated to main Claude process"
            # Signal to main Claude process for architecture work
            ;;
            
        "code_review")
            local file_to_review=$(jq -r '.context.file_path' "$work_file")
            echo "[CLAUDE] Code review needed for: $file_to_review"
            # Create copilot work unit to fetch file content
            create_work_unit "fetch_${unit_id}" "copilot" "file_operations" "Get file content for review" 3
            ;;
            
        *)
            echo "[CLAUDE] Task type $task_type handled by main Claude process"
            ;;
    esac
    
    # Mark as delegated to main process
    local completion_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    jq --arg completed_at "$completion_time" \
       '.status = "delegated_to_main" | .completed_at = $completed_at' \
       "$work_file" > "${work_file}.tmp" && mv "${work_file}.tmp" "$work_file"
}

# Orchestrator main loop
run_orchestrator() {
    echo "🤖 CVMA Agent Orchestrator Starting..."
    echo "📋 Claude responsibilities: ${CLAUDE_RESPONSIBILITIES[*]}"
    echo "⚙️  Copilot responsibilities: ${COPILOT_RESPONSIBILITIES[*]}"
    
    # Initialize agent states
    update_agent_state "claude" "ready" "none"
    update_agent_state "copilot" "ready" "none"
    
    # Main orchestration loop
    while true; do
        echo "[$(date)] Orchestrator cycle..."
        
        # Process work queues for both agents
        process_work_queue "copilot"
        process_work_queue "claude"
        
        # Check for inter-agent messages
        process_agent_messages
        
        # Sleep for a short interval
        sleep 5
    done
}

# Process inter-agent messages
process_agent_messages() {
    for inbox in "$COMMUNICATION_DIR"/*_inbox.json; do
        [ -f "$inbox" ] || continue
        
        local agent_name=$(basename "$inbox" _inbox.json)
        
        # Process unread messages
        if [ -f "$inbox" ]; then
            local unread_count=$(jq '[.[] | select(.status == "unread")] | length' "$inbox")
            
            if [ "$unread_count" -gt 0 ]; then
                echo "[$agent_name] Processing $unread_count unread messages"
                
                # Mark messages as read (simplified)
                jq 'map(if .status == "unread" then .status = "read" else . end)' "$inbox" > "${inbox}.tmp" && mv "${inbox}.tmp" "$inbox"
            fi
        fi
    done
}

# Command interface
case "$1" in
    "start")
        run_orchestrator
        ;;
        
    "create_work")
        if [ $# -lt 5 ]; then
            echo "Usage: $0 create_work <unit_id> <agent> <task_type> <description> <priority>"
            exit 1
        fi
        create_work_unit "$2" "$3" "$4" "$5" "$6"
        ;;
        
    "status")
        echo "🤖 CVMA Agent Orchestrator Status"
        echo "================================="
        echo
        
        echo "📊 Agent States:"
        for state_file in "$AGENT_STATE_DIR"/*.json; do
            [ -f "$state_file" ] || continue
            local agent_name=$(basename "$state_file" .json)
            local status=$(jq -r '.status' "$state_file")
            local current_task=$(jq -r '.current_task' "$state_file")
            echo "  $agent_name: $status (current: $current_task)"
        done
        
        echo
        echo "📋 Work Queue:"
        local pending_count=0
        local in_progress_count=0
        local completed_count=0
        
        for work_file in "$WORK_QUEUE_DIR"/*.json; do
            [ -f "$work_file" ] || continue
            local status=$(jq -r '.status' "$work_file")
            case "$status" in
                "pending") ((pending_count++)) ;;
                "in_progress") ((in_progress_count++)) ;;
                "completed") ((completed_count++)) ;;
            esac
        done
        
        echo "  Pending: $pending_count"
        echo "  In Progress: $in_progress_count" 
        echo "  Completed: $completed_count"
        ;;
        
    "send_message")
        if [ $# -lt 4 ]; then
            echo "Usage: $0 send_message <from> <to> <type> <content>"
            exit 1
        fi
        send_message "$2" "$3" "$4" "$5"
        ;;
        
    "demo")
        echo "🎭 Creating demo work units..."
        
        # Create sample work units
        create_work_unit "demo_git_status" "copilot" "git_operations" "Check git status" 1
        create_work_unit "demo_file_check" "copilot" "file_operations" "Check if README exists" 2
        create_work_unit "demo_planning" "claude" "high_level_planning" "Plan next user story" 1
        
        echo "✅ Demo work units created. Run '$0 status' to see them."
        ;;
        
    *)
        echo "🤖 CVMA Claude-Copilot Agent Orchestrator"
        echo "========================================"
        echo
        echo "Commands:"
        echo "  start                           - Start orchestrator daemon"
        echo "  create_work <id> <agent> <type> <desc> <priority> - Create work unit"
        echo "  status                          - Show orchestrator status"  
        echo "  send_message <from> <to> <type> <content> - Send inter-agent message"
        echo "  demo                           - Create demo work units"
        echo
        echo "Agent Types: claude, copilot"
        echo "Task Types:"
        echo "  Claude: high_level_planning, architecture_decisions, code_review"
        echo "  Copilot: bash_execution, git_operations, file_operations, system_monitoring"
        ;;
esac
