#!/bin/bash

# CVMA Multi-Agent Control Panel
# Central management system for Claude-Copilot agent orchestration
# Created: September 9, 2025

# Configuration
ORCHESTRATION_DIR="/c/Users/zerov/IdeaProjects/cvma/scripts/agent-orchestration"
CONTROL_LOG="$ORCHESTRATION_DIR/../logs/agents/control-panel.log"

# Script paths
ORCHESTRATOR_SCRIPT="$ORCHESTRATION_DIR/claude-copilot-orchestrator.sh"
COPILOT_AGENT_SCRIPT="$ORCHESTRATION_DIR/copilot-agent.sh"
CLAUDE_INTERFACE_SCRIPT="$ORCHESTRATION_DIR/claude-agent-interface.sh"
COMMUNICATION_BRIDGE_SCRIPT="$ORCHESTRATION_DIR/agent-communication-bridge.sh"

# Ensure directories exist
mkdir -p "$(dirname "$CONTROL_LOG")"

# Logging function
log_control() {
    echo "[$(date)] [CONTROL] $1" | tee -a "$CONTROL_LOG"
}

# Check if all components exist
check_system_components() {
    local all_good=true
    
    echo "🔍 Checking Multi-Agent System Components..."
    echo
    
    # Check script files
    local components=(
        "$ORCHESTRATOR_SCRIPT:Main Orchestrator"
        "$COPILOT_AGENT_SCRIPT:Copilot Agent"
        "$CLAUDE_INTERFACE_SCRIPT:Claude Interface"
        "$COMMUNICATION_BRIDGE_SCRIPT:Communication Bridge"
    )
    
    for component in "${components[@]}"; do
        local script_path=$(echo "$component" | cut -d':' -f1)
        local script_name=$(echo "$component" | cut -d':' -f2)
        
        if [ -x "$script_path" ]; then
            echo "✅ $script_name: Found and executable"
        elif [ -f "$script_path" ]; then
            echo "⚠️  $script_name: Found but not executable (fixing...)"
            chmod +x "$script_path"
            echo "✅ $script_name: Now executable"
        else
            echo "❌ $script_name: Missing ($script_path)"
            all_good=false
        fi
    done
    
    echo
    
    # Check required directories
    local directories=(
        "$ORCHESTRATION_DIR/work-queue:Work Queue"
        "$ORCHESTRATION_DIR/agent-state:Agent State"
        "$ORCHESTRATION_DIR/communication:Communication"
        "$(dirname "$CONTROL_LOG"):Logs"
    )
    
    for dir_info in "${directories[@]}"; do
        local dir_path=$(echo "$dir_info" | cut -d':' -f1)
        local dir_name=$(echo "$dir_info" | cut -d':' -f2)
        
        if [ -d "$dir_path" ]; then
            echo "✅ $dir_name Directory: $dir_path"
        else
            echo "⚠️  $dir_name Directory: Missing (creating...)"
            mkdir -p "$dir_path"
            echo "✅ $dir_name Directory: Created"
        fi
    done
    
    echo
    
    if [ "$all_good" = true ]; then
        echo "🎉 All system components are ready!"
        log_control "System components check passed"
        return 0
    else
        echo "⚠️  Some components need attention"
        log_control "System components check failed"
        return 1
    fi
}

# Start all agents
start_all_agents() {
    log_control "Starting all agents..."
    
    echo "🚀 Starting Multi-Agent System..."
    echo
    
    # Start communication bridge first
    echo "📡 Starting Communication Bridge..."
    "$COMMUNICATION_BRIDGE_SCRIPT" start &
    local bridge_pid=$!
    echo "Communication Bridge PID: $bridge_pid"
    echo $bridge_pid > "$ORCHESTRATION_DIR/bridge.pid"
    
    sleep 2
    
    # Start Copilot agent
    echo "🤖 Starting Copilot Agent..."
    "$COPILOT_AGENT_SCRIPT" start &
    local copilot_pid=$!
    echo "Copilot Agent PID: $copilot_pid"
    echo $copilot_pid > "$ORCHESTRATION_DIR/copilot.pid"
    
    sleep 2
    
    # Start main orchestrator
    echo "🎯 Starting Main Orchestrator..."
    "$ORCHESTRATOR_SCRIPT" start &
    local orchestrator_pid=$!
    echo "Orchestrator PID: $orchestrator_pid"
    echo $orchestrator_pid > "$ORCHESTRATION_DIR/orchestrator.pid"
    
    echo
    echo "✅ All agents started successfully!"
    echo
    echo "Process IDs saved in $ORCHESTRATION_DIR/"
    echo "  - bridge.pid: $bridge_pid"
    echo "  - copilot.pid: $copilot_pid"
    echo "  - orchestrator.pid: $orchestrator_pid"
    echo
    echo "Use '$0 status' to monitor agents"
    echo "Use '$0 stop' to stop all agents"
    
    log_control "All agents started - Bridge:$bridge_pid, Copilot:$copilot_pid, Orchestrator:$orchestrator_pid"
}

# Stop all agents
stop_all_agents() {
    log_control "Stopping all agents..."
    
    echo "🛑 Stopping Multi-Agent System..."
    echo
    
    # Stop processes using saved PIDs
    local pid_files=(
        "$ORCHESTRATION_DIR/orchestrator.pid:Orchestrator"
        "$ORCHESTRATION_DIR/copilot.pid:Copilot Agent"
        "$ORCHESTRATION_DIR/bridge.pid:Communication Bridge"
    )
    
    for pid_file_info in "${pid_files[@]}"; do
        local pid_file=$(echo "$pid_file_info" | cut -d':' -f1)
        local agent_name=$(echo "$pid_file_info" | cut -d':' -f2)
        
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                echo "🔴 Stopping $agent_name (PID: $pid)..."
                kill "$pid"
                
                # Wait for graceful shutdown
                local count=0
                while kill -0 "$pid" 2>/dev/null && [ $count -lt 10 ]; do
                    sleep 1
                    ((count++))
                done
                
                if kill -0 "$pid" 2>/dev/null; then
                    echo "⚡ Force stopping $agent_name..."
                    kill -9 "$pid"
                fi
                
                echo "✅ $agent_name stopped"
            else
                echo "ℹ️  $agent_name was not running"
            fi
            
            rm -f "$pid_file"
        else
            echo "ℹ️  No PID file for $agent_name"
        fi
    done
    
    echo
    echo "✅ All agents stopped"
    log_control "All agents stopped"
}

# Show comprehensive system status
show_system_status() {
    echo "📊 CVMA Multi-Agent System Status"
    echo "================================="
    echo
    
    # Check agent processes
    echo "🤖 Agent Processes:"
    local agents_running=0
    
    local pid_files=(
        "$ORCHESTRATION_DIR/orchestrator.pid:Orchestrator"
        "$ORCHESTRATION_DIR/copilot.pid:Copilot Agent"  
        "$ORCHESTRATION_DIR/bridge.pid:Communication Bridge"
    )
    
    for pid_file_info in "${pid_files[@]}"; do
        local pid_file=$(echo "$pid_file_info" | cut -d':' -f1)
        local agent_name=$(echo "$pid_file_info" | cut -d':' -f2)
        
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            if kill -0 "$pid" 2>/dev/null; then
                echo "  ✅ $agent_name: Running (PID: $pid)"
                ((agents_running++))
            else
                echo "  ❌ $agent_name: Stopped (stale PID file)"
                rm -f "$pid_file"
            fi
        else
            echo "  ❌ $agent_name: Not running"
        fi
    done
    
    echo
    
    # Show orchestrator status
    if [ -x "$ORCHESTRATOR_SCRIPT" ]; then
        echo "🎯 Orchestrator Status:"
        "$ORCHESTRATOR_SCRIPT" status 2>/dev/null | sed 's/^/  /'
        echo
    fi
    
    # Show communication bridge status
    if [ -x "$COMMUNICATION_BRIDGE_SCRIPT" ]; then
        echo "📡 Communication Bridge Status:"
        "$COMMUNICATION_BRIDGE_SCRIPT" status 2>/dev/null | sed 's/^/  /'
        echo
    fi
    
    # Show agent capabilities
    echo "🧠 Agent Capabilities:"
    echo "  Claude Agent:"
    echo "    • High-level planning and architecture decisions"
    echo "    • User story management and strategic refactoring"
    echo "    • Code review coordination and documentation"
    echo "    • Task delegation to Copilot agent"
    echo
    echo "  Copilot Agent:"
    echo "    • Bash command execution and file operations"
    echo "    • Git operations and deployment tasks"
    echo "    • System monitoring and testing automation"
    echo "    • Build processes and resource management"
    echo
    
    # Show recent activity summary
    echo "📈 System Activity:"
    if [ -f "$CONTROL_LOG" ]; then
        echo "  Recent control panel events:"
        tail -3 "$CONTROL_LOG" | sed 's/^/    /'
    fi
    
    echo
    echo "📊 Summary: $agents_running/3 agents running"
}

# Create demo workflow
run_demo_workflow() {
    echo "🎭 Running Multi-Agent Demo Workflow"
    echo "===================================="
    echo
    
    log_control "Starting demo workflow"
    
    # Check if system is running
    local running_count=0
    for pid_file in "$ORCHESTRATION_DIR"/*.pid; do
        [ -f "$pid_file" ] || continue
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            ((running_count++))
        fi
    done
    
    if [ $running_count -lt 3 ]; then
        echo "⚠️  Not all agents are running. Starting system first..."
        start_all_agents
        echo
        echo "Waiting for agents to initialize..."
        sleep 5
        echo
    fi
    
    echo "🎯 Demo: Claude Planning User Story #17"
    echo "======================================="
    
    # Claude plans User Story #17
    echo "1. Claude initiates planning for NPSP Financial Dashboard migration..."
    if [ -x "$CLAUDE_INTERFACE_SCRIPT" ]; then
        "$CLAUDE_INTERFACE_SCRIPT" plan_user_story "User Story #17: NPSP Financial Dashboard Migration" "Epic #4: Financial Management"
    fi
    
    echo
    sleep 3
    
    echo "2. Checking work queue for delegated tasks..."
    if [ -x "$ORCHESTRATOR_SCRIPT" ]; then
        "$ORCHESTRATOR_SCRIPT" status
    fi
    
    echo
    sleep 3
    
    echo "3. Testing communication bridge..."
    if [ -x "$COMMUNICATION_BRIDGE_SCRIPT" ]; then
        "$COMMUNICATION_BRIDGE_SCRIPT" send "claude" "copilot" "task_delegation" "high" "Demo: Analyze NPSP integration readiness" "demo_correlation_$(date +%s)"
    fi
    
    echo
    sleep 2
    
    echo "4. Communication bridge status..."
    if [ -x "$COMMUNICATION_BRIDGE_SCRIPT" ]; then
        "$COMMUNICATION_BRIDGE_SCRIPT" status
    fi
    
    echo
    echo "🎉 Demo workflow completed!"
    echo
    echo "The demo showed:"
    echo "  ✅ Claude strategic planning and task delegation"
    echo "  ✅ Work unit creation with Unit of Work pattern"
    echo "  ✅ Inter-agent communication with message queuing"
    echo "  ✅ Copilot task assignment and processing queue"
    echo
    echo "This demonstrates Separation of Concerns:"
    echo "  🧠 Claude: Strategic, high-level decisions"
    echo "  🤖 Copilot: Tactical, execution-focused operations"
    echo "  📡 Bridge: Reliable communication and coordination"
    
    log_control "Demo workflow completed successfully"
}

# Interactive mode
interactive_mode() {
    echo "🎮 Multi-Agent Interactive Control Panel"
    echo "========================================"
    echo
    
    while true; do
        echo
        echo "Available commands:"
        echo "  1. Check system components"
        echo "  2. Start all agents"
        echo "  3. Stop all agents"
        echo "  4. Show system status"
        echo "  5. Run demo workflow"
        echo "  6. Open orchestrator shell"
        echo "  7. Open communication shell"
        echo "  8. View logs"
        echo "  9. Exit"
        echo
        read -p "Enter choice (1-9): " choice
        echo
        
        case "$choice" in
            1) check_system_components ;;
            2) start_all_agents ;;
            3) stop_all_agents ;;
            4) show_system_status ;;
            5) run_demo_workflow ;;
            6) 
                echo "Opening orchestrator shell..."
                echo "Type 'exit' to return to control panel"
                bash -c "cd '$ORCHESTRATION_DIR' && exec bash"
                ;;
            7)
                echo "Opening communication shell..."
                echo "Available: $COMMUNICATION_BRIDGE_SCRIPT <command>"
                bash -c "cd '$ORCHESTRATION_DIR' && exec bash"
                ;;
            8)
                echo "📜 Recent control panel logs:"
                tail -20 "$CONTROL_LOG" 2>/dev/null || echo "No logs found"
                ;;
            9)
                echo "👋 Exiting Multi-Agent Control Panel"
                break
                ;;
            *)
                echo "❌ Invalid choice: $choice"
                ;;
        esac
    done
}

# Command interface
case "$1" in
    "check")
        check_system_components
        ;;
        
    "start")
        start_all_agents
        ;;
        
    "stop")
        stop_all_agents
        ;;
        
    "restart")
        stop_all_agents
        sleep 3
        start_all_agents
        ;;
        
    "status")
        show_system_status
        ;;
        
    "demo")
        run_demo_workflow
        ;;
        
    "interactive"|"i")
        interactive_mode
        ;;
        
    *)
        echo "🎯 CVMA Multi-Agent Control Panel"
        echo "================================="
        echo
        echo "Commands:"
        echo "  check       - Check system components"
        echo "  start       - Start all agents"
        echo "  stop        - Stop all agents"
        echo "  restart     - Restart all agents"
        echo "  status      - Show comprehensive system status"
        echo "  demo        - Run demonstration workflow"
        echo "  interactive - Enter interactive mode"
        echo
        echo "Architecture Overview:"
        echo "  🧠 Claude Agent: Strategic planning, architecture decisions, delegation"
        echo "  🤖 Copilot Agent: Bash execution, file operations, system tasks"
        echo "  📡 Communication Bridge: Message queuing and inter-agent coordination"
        echo "  🎯 Orchestrator: Work unit management and task distribution"
        echo
        echo "This system implements:"
        echo "  📋 Unit of Work pattern for task management"
        echo "  🔄 Separation of Concerns between strategic and tactical operations"
        echo "  💬 Reliable inter-agent communication with message queuing"
        echo "  📊 Comprehensive monitoring and status tracking"
        echo
        echo "Example Usage:"
        echo "  $0 check      # Verify all components"
        echo "  $0 start      # Start the multi-agent system"
        echo "  $0 demo       # See the agents in action"
        echo "  $0 status     # Monitor system health"
        ;;
esac