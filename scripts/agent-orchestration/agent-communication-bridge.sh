#!/bin/bash

# CVMA Agent Communication Bridge
# Real-time message passing and coordination between Claude and Copilot agents
# Created: September 9, 2025

# Configuration
BRIDGE_DIR="/c/Users/zerov/IdeaProjects/cvma/scripts/agent-orchestration"
COMMUNICATION_DIR="$BRIDGE_DIR/communication"
MESSAGE_QUEUE_DIR="$COMMUNICATION_DIR/message-queue"
BRIDGE_LOG="$BRIDGE_DIR/../logs/agents/communication-bridge.log"

# Create required directories
mkdir -p "$MESSAGE_QUEUE_DIR" "$COMMUNICATION_DIR"
mkdir -p "$(dirname "$BRIDGE_LOG")"

# Message types and priorities
declare -A MESSAGE_PRIORITIES=(
    ["urgent"]=1
    ["high"]=2
    ["normal"]=3
    ["low"]=4
    ["info"]=5
)

# Logging function
log_bridge() {
    echo "[$(date)] [BRIDGE] $1" | tee -a "$BRIDGE_LOG"
}

# Create structured message
create_message() {
    local from_agent="$1"
    local to_agent="$2"
    local message_type="$3"
    local priority="$4"
    local content="$5"
    local correlation_id="$6"
    
    local message_id="msg_$(date +%s)_$$"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Validate agents
    if [[ "$from_agent" != "claude" && "$from_agent" != "copilot" ]] || \
       [[ "$to_agent" != "claude" && "$to_agent" != "copilot" ]]; then
        log_bridge "Invalid agent names: $from_agent -> $to_agent"
        return 1
    fi
    
    # Create message file
    local message_file="$MESSAGE_QUEUE_DIR/${to_agent}_${message_id}.json"
    
    cat > "$message_file" << EOF
{
    "message_id": "$message_id",
    "from_agent": "$from_agent",
    "to_agent": "$to_agent",
    "message_type": "$message_type",
    "priority": ${MESSAGE_PRIORITIES[$priority]:-3},
    "priority_label": "$priority",
    "content": $(echo "$content" | jq -R .),
    "correlation_id": "$correlation_id",
    "timestamp": "$timestamp",
    "status": "pending",
    "delivery_attempts": 0,
    "max_delivery_attempts": 3,
    "expires_at": "$(date -u -d '+1 hour' +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    log_bridge "Message created: $message_id [$from_agent -> $to_agent] [$message_type] Priority: $priority"
    echo "$message_id"
}

# Deliver messages to agent
deliver_messages() {
    local target_agent="$1"
    local delivered_count=0
    
    # Get all pending messages for target agent, sorted by priority
    for message_file in "$MESSAGE_QUEUE_DIR/${target_agent}_msg_"*.json; do
        [ -f "$message_file" ] || continue
        
        local status=$(jq -r '.status' "$message_file" 2>/dev/null)
        local expires_at=$(jq -r '.expires_at' "$message_file" 2>/dev/null)
        local current_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        
        # Skip delivered or expired messages
        if [ "$status" != "pending" ] || [[ "$expires_at" < "$current_time" ]]; then
            # Clean up expired messages
            if [[ "$expires_at" < "$current_time" ]]; then
                log_bridge "Removing expired message: $(basename "$message_file")"
                rm -f "$message_file"
            fi
            continue
        fi
        
        # Attempt delivery
        local message_id=$(jq -r '.message_id' "$message_file")
        local from_agent=$(jq -r '.from_agent' "$message_file")
        local message_type=$(jq -r '.message_type' "$message_file")
        local content=$(jq -r '.content' "$message_file")
        local correlation_id=$(jq -r '.correlation_id' "$message_file")
        local attempts=$(jq -r '.delivery_attempts' "$message_file")
        local max_attempts=$(jq -r '.max_delivery_attempts' "$message_file")
        
        # Increment delivery attempts
        attempts=$((attempts + 1))
        
        if [ $attempts -le $max_attempts ]; then
            # Deliver message (this would interface with actual agent processes)
            if deliver_to_agent "$target_agent" "$message_id" "$from_agent" "$message_type" "$content" "$correlation_id"; then
                # Mark as delivered
                jq --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
                   '.status = "delivered" | .delivered_at = $timestamp' \
                   "$message_file" > "${message_file}.tmp" && mv "${message_file}.tmp" "$message_file"
                
                log_bridge "Message delivered: $message_id to $target_agent"
                ((delivered_count++))
            else
                # Update delivery attempts
                jq --arg attempts "$attempts" '.delivery_attempts = ($attempts | tonumber)' \
                   "$message_file" > "${message_file}.tmp" && mv "${message_file}.tmp" "$message_file"
                
                log_bridge "Message delivery failed (attempt $attempts/$max_attempts): $message_id"
            fi
        else
            # Mark as failed after max attempts
            jq --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
               '.status = "failed" | .failed_at = $timestamp' \
               "$message_file" > "${message_file}.tmp" && mv "${message_file}.tmp" "$message_file"
            
            log_bridge "Message delivery failed permanently: $message_id"
        fi
    done
    
    if [ $delivered_count -gt 0 ]; then
        log_bridge "Delivered $delivered_count messages to $target_agent"
    fi
}

# Deliver message to specific agent
deliver_to_agent() {
    local agent="$1"
    local message_id="$2"
    local from_agent="$3"
    local message_type="$4"
    local content="$5"
    local correlation_id="$6"
    
    case "$agent" in
        "claude")
            # Deliver to Claude (this could be a webhook, file, or process signal)
            deliver_to_claude "$message_id" "$from_agent" "$message_type" "$content" "$correlation_id"
            ;;
        "copilot")
            # Deliver to Copilot (this could be a webhook, file, or process signal)
            deliver_to_copilot "$message_id" "$from_agent" "$message_type" "$content" "$correlation_id"
            ;;
        *)
            log_bridge "Unknown agent: $agent"
            return 1
            ;;
    esac
}

# Claude-specific message delivery
deliver_to_claude() {
    local message_id="$1"
    local from_agent="$2"
    local message_type="$3"
    local content="$4"
    local correlation_id="$5"
    
    # Create Claude inbox entry
    local claude_inbox="$COMMUNICATION_DIR/claude_inbox.json"
    
    local message_entry=$(cat << EOF
{
    "message_id": "$message_id",
    "from": "$from_agent",
    "type": "$message_type",
    "content": "$content",
    "correlation_id": "$correlation_id",
    "received_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "unread"
}
EOF
)
    
    # Add to inbox
    if [ -f "$claude_inbox" ]; then
        jq --argjson entry "$message_entry" '. += [$entry]' "$claude_inbox" > "${claude_inbox}.tmp" && mv "${claude_inbox}.tmp" "$claude_inbox"
    else
        echo "[$message_entry]" > "$claude_inbox"
    fi
    
    # Create notification file for Claude
    echo "$message_id" > "$COMMUNICATION_DIR/claude_notification_$(date +%s).flag"
    
    return 0
}

# Copilot-specific message delivery
deliver_to_copilot() {
    local message_id="$1"
    local from_agent="$2"
    local message_type="$3"
    local content="$4"
    local correlation_id="$5"
    
    # Create Copilot inbox entry
    local copilot_inbox="$COMMUNICATION_DIR/copilot_inbox.json"
    
    local message_entry=$(cat << EOF
{
    "message_id": "$message_id",
    "from": "$from_agent", 
    "type": "$message_type",
    "content": "$content",
    "correlation_id": "$correlation_id",
    "received_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "status": "unread"
}
EOF
)
    
    # Add to inbox
    if [ -f "$copilot_inbox" ]; then
        jq --argjson entry "$message_entry" '. += [$entry]' "$copilot_inbox" > "${copilot_inbox}.tmp" && mv "${copilot_inbox}.tmp" "$copilot_inbox"
    else
        echo "[$message_entry]" > "$copilot_inbox"
    fi
    
    # Create notification file for Copilot
    echo "$message_id" > "$COMMUNICATION_DIR/copilot_notification_$(date +%s).flag"
    
    return 0
}

# Message status tracking
get_message_status() {
    local message_id="$1"
    
    # Search for message in queue
    for message_file in "$MESSAGE_QUEUE_DIR"/*"${message_id}"*.json; do
        if [ -f "$message_file" ]; then
            jq . "$message_file"
            return 0
        fi
    done
    
    echo '{"error": "Message not found", "message_id": "'$message_id'"}'
    return 1
}

# Clean up old messages
cleanup_messages() {
    local retention_hours="${1:-24}"  # Default 24 hour retention
    local cutoff_time=$(date -u -d "-${retention_hours} hours" +%Y-%m-%dT%H:%M:%SZ)
    
    local cleaned_count=0
    
    for message_file in "$MESSAGE_QUEUE_DIR"/*.json; do
        [ -f "$message_file" ] || continue
        
        local timestamp=$(jq -r '.timestamp' "$message_file" 2>/dev/null)
        local status=$(jq -r '.status' "$message_file" 2>/dev/null)
        
        # Remove old completed/failed messages
        if [[ "$timestamp" < "$cutoff_time" ]] && [[ "$status" =~ ^(delivered|failed)$ ]]; then
            rm -f "$message_file"
            ((cleaned_count++))
        fi
    done
    
    # Clean up old notification flags
    find "$COMMUNICATION_DIR" -name "*_notification_*.flag" -mmin +60 -delete 2>/dev/null
    
    log_bridge "Cleaned up $cleaned_count old messages"
}

# Bridge status monitoring
show_bridge_status() {
    echo "🌉 Agent Communication Bridge Status"
    echo "===================================="
    echo
    
    # Count messages by status
    local pending_count=0
    local delivered_count=0
    local failed_count=0
    
    for message_file in "$MESSAGE_QUEUE_DIR"/*.json; do
        [ -f "$message_file" ] || continue
        local status=$(jq -r '.status' "$message_file" 2>/dev/null)
        case "$status" in
            "pending") ((pending_count++)) ;;
            "delivered") ((delivered_count++)) ;;
            "failed") ((failed_count++)) ;;
        esac
    done
    
    echo "📊 Message Queue:"
    echo "  Pending: $pending_count"
    echo "  Delivered: $delivered_count"
    echo "  Failed: $failed_count"
    echo
    
    # Show agent inboxes
    local claude_unread=0
    local copilot_unread=0
    
    if [ -f "$COMMUNICATION_DIR/claude_inbox.json" ]; then
        claude_unread=$(jq '[.[] | select(.status == "unread")] | length' "$COMMUNICATION_DIR/claude_inbox.json" 2>/dev/null || echo 0)
    fi
    
    if [ -f "$COMMUNICATION_DIR/copilot_inbox.json" ]; then
        copilot_unread=$(jq '[.[] | select(.status == "unread")] | length' "$COMMUNICATION_DIR/copilot_inbox.json" 2>/dev/null || echo 0)
    fi
    
    echo "📬 Agent Inboxes:"
    echo "  Claude unread: $claude_unread"
    echo "  Copilot unread: $copilot_unread"
    echo
    
    echo "📁 Bridge Directories:"
    echo "  Message Queue: $MESSAGE_QUEUE_DIR"
    echo "  Communication: $COMMUNICATION_DIR"
    echo "  Bridge Log: $BRIDGE_LOG"
}

# Bridge main loop
run_bridge() {
    log_bridge "Communication bridge starting..."
    
    while true; do
        # Deliver pending messages
        deliver_messages "claude"
        deliver_messages "copilot"
        
        # Cleanup old messages every 100 cycles (roughly 10 minutes)
        if [ $((RANDOM % 100)) -eq 0 ]; then
            cleanup_messages
        fi
        
        sleep 3
    done
}

# Command interface
case "$1" in
    "start")
        run_bridge
        ;;
        
    "send")
        if [ $# -lt 5 ]; then
            echo "Usage: $0 send <from_agent> <to_agent> <message_type> <priority> <content> [correlation_id]"
            echo "Priorities: urgent, high, normal, low, info"
            exit 1
        fi
        message_id=$(create_message "$2" "$3" "$4" "$5" "$6" "$7")
        echo "Message queued: $message_id"
        ;;
        
    "status")
        show_bridge_status
        ;;
        
    "get_message")
        if [ $# -lt 2 ]; then
            echo "Usage: $0 get_message <message_id>"
            exit 1
        fi
        get_message_status "$2"
        ;;
        
    "cleanup")
        local hours="${2:-24}"
        cleanup_messages "$hours"
        ;;
        
    "test")
        echo "🧪 Testing communication bridge..."
        
        # Create test messages
        test_msg1=$(create_message "claude" "copilot" "task_delegation" "high" "Test bash execution" "test_correlation_1")
        test_msg2=$(create_message "copilot" "claude" "task_completed" "normal" "Bash command executed successfully" "test_correlation_1")
        
        echo "Created test messages: $test_msg1, $test_msg2"
        
        # Attempt delivery
        echo "Attempting message delivery..."
        deliver_messages "copilot"
        deliver_messages "claude"
        
        echo "Bridge test completed. Check status with: $0 status"
        ;;
        
    *)
        echo "🌉 CVMA Agent Communication Bridge"
        echo "================================="
        echo
        echo "Commands:"
        echo "  start                                    - Start bridge daemon"
        echo "  send <from> <to> <type> <priority> <content> [correlation_id] - Send message"
        echo "  status                                   - Show bridge status"
        echo "  get_message <message_id>                 - Get message details"
        echo "  cleanup [retention_hours]                - Clean up old messages"
        echo "  test                                     - Run bridge test"
        echo
        echo "Agents: claude, copilot"
        echo "Priorities: urgent, high, normal, low, info"
        echo "Message Types: task_delegation, task_completed, task_failed, status_update, etc."
        echo
        echo "This bridge enables real-time communication between Claude and Copilot agents"
        echo "with message queuing, delivery guarantees, and status tracking."
        ;;
esac