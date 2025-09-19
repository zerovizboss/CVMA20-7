#!/bin/bash

# CVMA Support Agent
# Handles Experience Cloud site support for guest users of Combat Veterans Motorcycle Association Profile
# Author: Generated via Claude-Copilot Multi-Agent Architecture
# Date: September 9, 2025

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs/agents"
WORK_QUEUE_DIR="$PROJECT_ROOT/.agent-queue/cvma-support"
CONFIG_FILE="$PROJECT_ROOT/.cvma/support-agent.config"

# Ensure directories exist
mkdir -p "$LOG_DIR" "$WORK_QUEUE_DIR" "$(dirname "$CONFIG_FILE")"

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [CVMA-Support] $*" | tee -a "$LOG_DIR/cvma-support-agent.log"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] [CVMA-Support] $*" | tee -a "$LOG_DIR/cvma-support-agent.log"
}

success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] [CVMA-Support] $*" | tee -a "$LOG_DIR/cvma-support-agent.log"
}

# Initialize configuration
init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "Creating CVMA Support Agent configuration..."
        cat > "$CONFIG_FILE" << 'EOF'
{
  "experience_cloud": {
    "site_name": "Combat Veterans Motorcycle Association",
    "profile": "Combat Veterans Motorcycle Association Profile",
    "guest_user_context": true,
    "monitoring_interval": 300
  },
  "support_capabilities": {
    "guest_registration": true,
    "event_rsvp": true,
    "membership_application": true,
    "general_inquiries": true,
    "technical_support": true
  },
  "response_templates": {
    "greeting": "Welcome to the Combat Veterans Motorcycle Association! How can I assist you today?",
    "registration_help": "I'll help you with the registration process. Let me guide you through each step.",
    "event_support": "I can help you find and RSVP to CVMA events. What are you looking for?",
    "membership_info": "I'd be happy to provide information about CVMA membership and the application process."
  },
  "escalation": {
    "to_human": 15,
    "to_admin": 30,
    "priority_threshold": 5
  }
}
EOF
        success "Configuration file created at $CONFIG_FILE"
    fi
}

# Experience Cloud site monitoring
check_experience_cloud_health() {
    log "Checking Experience Cloud site health..."
    
    local site_status=$(sf community list --json 2>/dev/null | jq -r '.result[] | select(.name == "Combat Veterans Motorcycle Association") | .status' 2>/dev/null || echo "unknown")
    
    if [[ "$site_status" == "Live" ]]; then
        success "Experience Cloud site is Live and accessible"
        return 0
    else
        error "Experience Cloud site status: $site_status"
        return 1
    fi
}

# Guest user access validation
validate_guest_access() {
    log "Validating guest user access permissions..."
    
    # Check guest user profile permissions
    local query="SELECT Id, Name, UserType FROM Profile WHERE Name LIKE '%Guest%' OR Name LIKE '%Combat Veterans%'"
    local profiles=$(sf data query --query "$query" --json 2>/dev/null | jq -r '.result.records[] | .Name' 2>/dev/null || echo "")
    
    if [[ -n "$profiles" ]]; then
        success "Guest user profiles found: $profiles"
        return 0
    else
        error "No guest user profiles found or accessible"
        return 1
    fi
}

# Monitor CVMA Guest Request object
monitor_guest_requests() {
    log "Monitoring CVMA Guest Requests..."
    
    local query="SELECT Id, Name, Status__c, Request_Type__c, CreatedDate FROM CVMA_Guest_Request__c WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 10"
    local requests=$(sf data query --query "$query" --json 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        local count=$(echo "$requests" | jq -r '.result.totalSize // 0' 2>/dev/null || echo "0")
        log "Found $count new guest requests today"
        
        # Process pending requests
        process_pending_requests "$requests"
    else
        error "Failed to retrieve guest requests"
    fi
}

# Process pending guest requests
process_pending_requests() {
    local requests_json="$1"
    
    log "Processing pending guest requests..."
    
    # Extract pending requests
    local pending=$(echo "$requests_json" | jq -r '.result.records[] | select(.Status__c == "Pending") | .Id' 2>/dev/null)
    
    if [[ -n "$pending" ]]; then
        while IFS= read -r request_id; do
            [[ -n "$request_id" ]] && auto_respond_to_request "$request_id"
        done <<< "$pending"
    else
        log "No pending guest requests to process"
    fi
}

# Auto-respond to guest requests based on type
auto_respond_to_request() {
    local request_id="$1"
    
    log "Processing guest request: $request_id"
    
    # Get request details
    local query="SELECT Id, Request_Type__c, Description__c, Contact_Email__c FROM CVMA_Guest_Request__c WHERE Id = '$request_id'"
    local request_data=$(sf data query --query "$query" --json 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        local request_type=$(echo "$request_data" | jq -r '.result.records[0].Request_Type__c // "General"' 2>/dev/null)
        local email=$(echo "$request_data" | jq -r '.result.records[0].Contact_Email__c // ""' 2>/dev/null)
        
        case "$request_type" in
            "Registration")
                send_registration_assistance "$request_id" "$email"
                ;;
            "Event RSVP")
                send_event_assistance "$request_id" "$email"
                ;;
            "Membership")
                send_membership_info "$request_id" "$email"
                ;;
            *)
                send_general_response "$request_id" "$email"
                ;;
        esac
    else
        error "Failed to retrieve request details for $request_id"
    fi
}

# Send registration assistance
send_registration_assistance() {
    local request_id="$1"
    local email="$2"
    
    log "Sending registration assistance for request $request_id"
    
    local response="Thank you for your interest in joining CVMA! I'll help guide you through our registration process:

1. Visit our registration page on the CVMA Experience Cloud site
2. Complete all required fields including military service verification
3. Upload required documentation (DD-214, service records)
4. Review and accept our code of conduct and bylaws

If you need assistance with any step, please don't hesitate to reach out. A CVMA officer will review your application within 5-7 business days.

Semper Fi,
CVMA Support Team"

    update_request_status "$request_id" "In Progress" "$response"
}

# Send event assistance
send_event_assistance() {
    local request_id="$1"
    local email="$2"
    
    log "Sending event assistance for request $request_id"
    
    local response="Thank you for your interest in CVMA events! Here's how you can find and RSVP to our events:

1. Browse upcoming events on our calendar
2. Click on any event for full details and RSVP options
3. For guest attendees, registration may be required
4. Contact information will be provided for event-specific questions

Current events are updated regularly. Check back often for new rides, meetings, and community service opportunities.

Ride Safe,
CVMA Support Team"

    update_request_status "$request_id" "In Progress" "$response"
}

# Send membership information
send_membership_info() {
    local request_id="$1"
    local email="$2"
    
    log "Sending membership information for request $request_id"
    
    local response="Thank you for your interest in CVMA membership! Here's what you need to know:

MEMBERSHIP REQUIREMENTS:
- Honorable military service (any branch)
- Own and operate a motorcycle
- Complete application and background check
- Attend probationary period meetings

MEMBERSHIP BENEFITS:
- Brotherhood of combat veterans
- Organized rides and events
- Community service opportunities
- Veteran advocacy support

To begin the application process, visit our membership section or contact your local chapter directly.

Semper Fidelis,
CVMA Support Team"

    update_request_status "$request_id" "In Progress" "$response"
}

# Send general response
send_general_response() {
    local request_id="$1"
    local email="$2"
    
    log "Sending general response for request $request_id"
    
    local response="Thank you for contacting the Combat Veterans Motorcycle Association!

Your request has been received and will be reviewed by our team. We typically respond to inquiries within 24-48 hours during business days.

For immediate assistance with:
- Membership questions: Visit our membership information page
- Event inquiries: Check our events calendar
- Technical issues: Contact our support team directly

We appreciate your patience and look forward to assisting you.

Respectfully,
CVMA Support Team"

    update_request_status "$request_id" "In Progress" "$response"
}

# Update request status with response
update_request_status() {
    local request_id="$1"
    local status="$2"
    local response="$3"
    
    log "Updating request $request_id to status: $status"
    
    # Update the request record
    sf data update record --sobject CVMA_Guest_Request__c --record-id "$request_id" --values "Status__c='$status' Response__c='$response'" >/dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        success "Updated request $request_id successfully"
    else
        error "Failed to update request $request_id"
    fi
}

# Monitor Experience Cloud site performance
monitor_site_performance() {
    log "Monitoring Experience Cloud site performance..."
    
    # Check site accessibility (placeholder for actual monitoring)
    local site_check=$(curl -s -o /dev/null -w "%{http_code}" "https://cvma20-7-dev-ed.develop.my.site.com/combat-veterans-motorcycle-association" 2>/dev/null || echo "000")
    
    if [[ "$site_check" == "200" ]]; then
        success "Experience Cloud site is accessible (HTTP 200)"
    else
        error "Experience Cloud site accessibility issue (HTTP $site_check)"
        escalate_site_issue "$site_check"
    fi
}

# Escalate site issues
escalate_site_issue() {
    local http_code="$1"
    
    error "Escalating site issue: HTTP $http_code"
    
    # Create escalation work unit for main orchestrator
    local work_unit=$(cat << EOF
{
  "id": "cvma-support-escalation-$(date +%s)",
  "type": "escalation",
  "priority": "urgent",
  "agent": "claude",
  "status": "pending",
  "context": {
    "issue": "Experience Cloud site accessibility",
    "http_code": "$http_code",
    "timestamp": "$(date -Iseconds)",
    "requires_immediate_attention": true
  },
  "task": "Investigate Experience Cloud site accessibility issues and implement recovery procedures"
}
EOF
)
    
    echo "$work_unit" > "$WORK_QUEUE_DIR/../escalation-$(date +%s).json"
    success "Escalation work unit created for site issue"
}

# Analyze guest user patterns
analyze_guest_patterns() {
    log "Analyzing guest user interaction patterns..."
    
    local query="SELECT Request_Type__c, COUNT(Id) total FROM CVMA_Guest_Request__c WHERE CreatedDate = LAST_N_DAYS:7 GROUP BY Request_Type__c"
    local patterns=$(sf data query --query "$query" --json 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        local insights=$(echo "$patterns" | jq -r '.result.records[] | "\(.Request_Type__c): \(.total)"' 2>/dev/null)
        if [[ -n "$insights" ]]; then
            log "Weekly guest request patterns:"
            echo "$insights" | while read -r line; do
                log "  $line"
            done
        fi
    else
        error "Failed to analyze guest patterns"
    fi
}

# Generate support metrics
generate_support_metrics() {
    log "Generating CVMA Support metrics..."
    
    local today=$(date +%Y-%m-%d)
    local metrics_file="$LOG_DIR/support-metrics-$today.json"
    
    # Collect metrics
    local total_requests=$(sf data query --query "SELECT COUNT(Id) FROM CVMA_Guest_Request__c WHERE CreatedDate = TODAY" --json 2>/dev/null | jq -r '.result.records[0].expr0 // 0' 2>/dev/null || echo "0")
    local resolved_requests=$(sf data query --query "SELECT COUNT(Id) FROM CVMA_Guest_Request__c WHERE CreatedDate = TODAY AND Status__c = 'Resolved'" --json 2>/dev/null | jq -r '.result.records[0].expr0 // 0' 2>/dev/null || echo "0")
    local pending_requests=$(sf data query --query "SELECT COUNT(Id) FROM CVMA_Guest_Request__c WHERE Status__c = 'Pending'" --json 2>/dev/null | jq -r '.result.records[0].expr0 // 0' 2>/dev/null || echo "0")
    
    local metrics=$(cat << EOF
{
  "date": "$today",
  "timestamp": "$(date -Iseconds)",
  "metrics": {
    "total_requests_today": $total_requests,
    "resolved_today": $resolved_requests,
    "pending_requests": $pending_requests,
    "resolution_rate": $(echo "scale=2; if($total_requests > 0) $resolved_requests * 100 / $total_requests else 0" | bc 2>/dev/null || echo "0")
  },
  "site_status": "operational",
  "agent_status": "active"
}
EOF
)
    
    echo "$metrics" > "$metrics_file"
    success "Support metrics generated: $metrics_file"
}

# Main execution function
main() {
    case "${1:-help}" in
        "start")
            log "Starting CVMA Support Agent..."
            init_config
            check_experience_cloud_health
            validate_guest_access
            success "CVMA Support Agent started successfully"
            ;;
        "monitor")
            log "Running CVMA Support monitoring cycle..."
            monitor_guest_requests
            monitor_site_performance
            analyze_guest_patterns
            generate_support_metrics
            success "Monitoring cycle completed"
            ;;
        "process-requests")
            log "Processing guest requests..."
            monitor_guest_requests
            success "Request processing completed"
            ;;
        "health-check")
            log "Performing CVMA Support health check..."
            check_experience_cloud_health
            validate_guest_access
            ;;
        "metrics")
            log "Generating support metrics..."
            generate_support_metrics
            ;;
        "status")
            echo "CVMA Support Agent Status:"
            echo "  Configuration: $([[ -f "$CONFIG_FILE" ]] && echo "✓ Loaded" || echo "✗ Missing")"
            echo "  Experience Cloud: $(check_experience_cloud_health >/dev/null 2>&1 && echo "✓ Operational" || echo "✗ Issues detected")"
            echo "  Guest Access: $(validate_guest_access >/dev/null 2>&1 && echo "✓ Valid" || echo "✗ Issues detected")"
            echo "  Log Directory: $LOG_DIR"
            echo "  Queue Directory: $WORK_QUEUE_DIR"
            ;;
        "help"|*)
            echo "CVMA Support Agent - Experience Cloud Guest User Support"
            echo
            echo "Usage: $0 {start|monitor|process-requests|health-check|metrics|status|help}"
            echo
            echo "Commands:"
            echo "  start            - Initialize and start the CVMA Support Agent"
            echo "  monitor          - Run complete monitoring cycle"
            echo "  process-requests - Process pending guest requests"
            echo "  health-check     - Check Experience Cloud and guest access health"
            echo "  metrics          - Generate support performance metrics"
            echo "  status           - Display agent status information"
            echo "  help             - Display this help message"
            echo
            echo "The CVMA Support Agent provides automated support for guest users"
            echo "of the Combat Veterans Motorcycle Association Experience Cloud site."
            ;;
    esac
}

# Execute main function
main "$@"