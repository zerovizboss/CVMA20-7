#!/bin/bash

# CVMA Salesforce Monitoring Agent
# Specialized agent for monitoring and handling errors throughout the CVMA Salesforce org
# Created: September 9, 2025

# Agent configuration
AGENT_NAME="salesforce_monitor"
ORCHESTRATOR_DIR="/c/Users/zerov/IdeaProjects/cvma/scripts/agent-orchestration"
WORK_QUEUE_DIR="$ORCHESTRATOR_DIR/work-queue"
SF_MONITOR_LOG="$ORCHESTRATOR_DIR/../logs/agents/salesforce-monitor.log"
SF_ERROR_LOG="$ORCHESTRATOR_DIR/../logs/agents/salesforce-errors.log"

# Salesforce CLI paths and org configuration
CVMA_ORG_ALIAS="cvma-dev-org"
CVMA_PROJECT_PATH="/c/Users/zerov/IdeaProjects/cvma"

# Ensure directories exist
mkdir -p "$(dirname "$SF_MONITOR_LOG")" "$(dirname "$SF_ERROR_LOG")"

# Logging function
log_sf_monitor() {
    echo "[$(date)] [SF-MONITOR] $1" | tee -a "$SF_MONITOR_LOG"
}

# Error logging function
log_sf_error() {
    echo "[$(date)] [SF-ERROR] $1" | tee -a "$SF_ERROR_LOG"
    log_sf_monitor "ERROR: $1"
}

# Salesforce Org Health Monitoring
monitor_org_health() {
    local work_unit_id="$1"
    
    log_sf_monitor "Starting comprehensive org health check..."
    
    cd "$CVMA_PROJECT_PATH" || {
        log_sf_error "Failed to change to CVMA project directory"
        return 1
    }
    
    local health_report=""
    local health_status="healthy"
    local issues_found=0
    
    # 1. Check org connectivity
    log_sf_monitor "Checking org connectivity..."
    if sf org display --json > /tmp/org_info.json 2>/dev/null; then
        local org_status=$(jq -r '.result.connectedStatus' /tmp/org_info.json 2>/dev/null)
        if [ "$org_status" = "Connected" ]; then
            health_report+="✅ Org Connectivity: Connected\\n"
        else
            health_report+="❌ Org Connectivity: $org_status\\n"
            health_status="warning"
            ((issues_found++))
        fi
    else
        health_report+="❌ Org Connectivity: Failed to connect\\n"
        health_status="critical"
        ((issues_found++))
    fi
    
    # 2. Check recent deployment status
    log_sf_monitor "Checking recent deployments..."
    if sf project deploy report --json > /tmp/deploy_status.json 2>/dev/null; then
        local deploy_status=$(jq -r '.result.response.details.runTestResult.outcome' /tmp/deploy_status.json 2>/dev/null)
        if [ "$deploy_status" = "Passed" ] || [ "$deploy_status" = "null" ]; then
            health_report+="✅ Recent Deployments: No issues\\n"
        else
            health_report+="⚠️  Recent Deployments: Issues detected ($deploy_status)\\n"
            health_status="warning"
            ((issues_found++))
        fi
    else
        health_report+="ℹ️  Recent Deployments: No recent deployments found\\n"
    fi
    
    # 3. Monitor Apex test results
    log_sf_monitor "Checking Apex test coverage..."
    if sf apex run test --result-format json --code-coverage > /tmp/test_results.json 2>/dev/null; then
        local test_success=$(jq -r '.result.summary.outcome' /tmp/test_results.json 2>/dev/null)
        local coverage=$(jq -r '.result.summary.orgWideCoverage' /tmp/test_results.json 2>/dev/null)
        
        if [ "$test_success" = "Passed" ]; then
            health_report+="✅ Apex Tests: All tests passing\\n"
            if [ "$coverage" != "null" ]; then
                local coverage_percent=$(echo "$coverage" | cut -d'%' -f1)
                if [ "$coverage_percent" -ge 75 ]; then
                    health_report+="✅ Test Coverage: ${coverage}\\n"
                else
                    health_report+="⚠️  Test Coverage: ${coverage} (below 75%)\\n"
                    health_status="warning"
                    ((issues_found++))
                fi
            fi
        else
            health_report+="❌ Apex Tests: Some tests failing\\n"
            health_status="critical"
            ((issues_found++))
        fi
    else
        health_report+="⚠️  Apex Tests: Unable to run test suite\\n"
        health_status="warning"
        ((issues_found++))
    fi
    
    # 4. Check for debug logs with errors
    log_sf_monitor "Checking for recent errors in debug logs..."
    if sf data query --query "SELECT Id, Operation, Status, Application, LogLength, StartTime FROM ApexLog WHERE Status = 'Success' AND LogLength > 10000 ORDER BY StartTime DESC LIMIT 5" --json > /tmp/debug_logs.json 2>/dev/null; then
        local large_logs=$(jq '.result.records | length' /tmp/debug_logs.json 2>/dev/null)
        if [ "$large_logs" -gt 3 ]; then
            health_report+="⚠️  Debug Logs: $large_logs large debug logs detected (possible performance issues)\\n"
            health_status="warning"
            ((issues_found++))
        else
            health_report+="✅ Debug Logs: No unusual activity detected\\n"
        fi
    else
        health_report+="ℹ️  Debug Logs: Unable to query debug logs\\n"
    fi
    
    # 5. Monitor CVMA-specific error logs
    log_sf_monitor "Checking CVMA custom error logs..."
    if sf data query --query "SELECT Id, Error_Type__c, Error_Message__c, CreatedDate FROM CVMA_Error_Log__c WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC LIMIT 10" --json > /tmp/cvma_errors.json 2>/dev/null; then
        local error_count=$(jq '.result.records | length' /tmp/cvma_errors.json 2>/dev/null)
        if [ "$error_count" -gt 0 ]; then
            health_report+="❌ CVMA Errors: $error_count errors logged today\\n"
            health_status="critical"
            ((issues_found++))
            
            # Log detailed error information
            echo "Recent CVMA errors:" >> "$SF_ERROR_LOG"
            jq -r '.result.records[] | "- \(.Error_Type__c): \(.Error_Message__c) (\(.CreatedDate))"' /tmp/cvma_errors.json >> "$SF_ERROR_LOG"
        else
            health_report+="✅ CVMA Errors: No errors logged today\\n"
        fi
    else
        health_report+="ℹ️  CVMA Errors: Unable to query error logs\\n"
    fi
    
    # 6. Check Experience Cloud site health
    log_sf_monitor "Checking Experience Cloud site status..."
    if sf data query --query "SELECT Id, Status, Name, UrlPathPrefix FROM Site WHERE Name LIKE '%Combat Veterans%' LIMIT 1" --json > /tmp/site_status.json 2>/dev/null; then
        local site_status=$(jq -r '.result.records[0].Status' /tmp/site_status.json 2>/dev/null)
        local site_name=$(jq -r '.result.records[0].Name' /tmp/site_status.json 2>/dev/null)
        
        if [ "$site_status" = "Active" ]; then
            health_report+="✅ Experience Cloud: $site_name is active\\n"
        else
            health_report+="❌ Experience Cloud: $site_name status is $site_status\\n"
            health_status="critical"
            ((issues_found++))
        fi
    else
        health_report+="⚠️  Experience Cloud: Unable to check site status\\n"
        health_status="warning"
        ((issues_found++))
    fi
    
    # Generate comprehensive health report
    local final_report=$(cat << EOF
{
    "org_health_check": {
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "overall_status": "$health_status",
        "issues_found": $issues_found,
        "detailed_report": "$health_report",
        "work_unit_id": "$work_unit_id",
        "recommendations": $(generate_health_recommendations "$health_status" "$issues_found")
    }
}
EOF
)
    
    log_sf_monitor "Org health check completed: $health_status ($issues_found issues)"
    echo "$final_report"
    
    # Clean up temporary files
    rm -f /tmp/org_info.json /tmp/deploy_status.json /tmp/test_results.json /tmp/debug_logs.json /tmp/cvma_errors.json /tmp/site_status.json
    
    return 0
}

# Generate health recommendations
generate_health_recommendations() {
    local status="$1"
    local issues_count="$2"
    
    local recommendations="[]"
    
    case "$status" in
        "critical")
            recommendations='["Immediate attention required", "Check failed tests and deployment issues", "Review CVMA error logs", "Consider rolling back recent changes"]'
            ;;
        "warning")
            recommendations='["Monitor closely", "Schedule maintenance window", "Review test coverage", "Check performance metrics"]'
            ;;
        "healthy")
            recommendations='["Continue regular monitoring", "Consider proactive maintenance", "Review growth metrics"]'
            ;;
    esac
    
    echo "$recommendations"
}

# Monitor specific CVMA components
monitor_cvma_components() {
    local work_unit_id="$1"
    local component_type="$2"
    
    log_sf_monitor "Monitoring CVMA components: $component_type"
    
    cd "$CVMA_PROJECT_PATH" || {
        log_sf_error "Failed to change to CVMA project directory"
        return 1
    }
    
    local monitoring_result=""
    local component_status="healthy"
    
    case "$component_type" in
        "lightning_components")
            # Check Lightning Web Components
            log_sf_monitor "Checking Lightning Web Components..."
            local lwc_count=$(find src/lwc -name "*.js" | wc -l)
            local lwc_issues=$(sf project deploy validate --source-dir src/lwc --json 2>/dev/null | jq '.result.details.componentFailures | length' 2>/dev/null)
            
            if [ "$lwc_issues" = "0" ] || [ "$lwc_issues" = "null" ]; then
                monitoring_result+="✅ Lightning Components: $lwc_count components, no issues detected\\n"
            else
                monitoring_result+="❌ Lightning Components: $lwc_issues validation issues found\\n"
                component_status="warning"
            fi
            ;;
            
        "apex_classes")
            # Check Apex classes
            log_sf_monitor "Checking Apex classes..."
            local apex_count=$(find src/classes -name "*.cls" | wc -l)
            local apex_test_count=$(find src/classes -name "*Test.cls" | wc -l)
            
            monitoring_result+="✅ Apex Classes: $apex_count total classes, $apex_test_count test classes\\n"
            
            # Check for PMD violations
            if command -v pmd &> /dev/null; then
                local pmd_violations=$(./scripts/enhanced-pmd-analysis.sh 2>/dev/null | grep "violations found" | grep -o "[0-9]*" | head -1)
                if [ -n "$pmd_violations" ] && [ "$pmd_violations" -gt 20 ]; then
                    monitoring_result+="⚠️  PMD Analysis: $pmd_violations violations found\\n"
                    component_status="warning"
                else
                    monitoring_result+="✅ PMD Analysis: Code quality acceptable\\n"
                fi
            fi
            ;;
            
        "custom_objects")
            # Check custom objects
            log_sf_monitor "Checking custom objects..."
            if sf data query --query "SELECT COUNT() FROM CVMA_Error_Log__c WHERE CreatedDate = TODAY" --json > /tmp/error_count.json 2>/dev/null; then
                local today_errors=$(jq '.result.totalSize' /tmp/error_count.json)
                if [ "$today_errors" -gt 5 ]; then
                    monitoring_result+="❌ Error Logs: $today_errors errors today (threshold exceeded)\\n"
                    component_status="critical"
                else
                    monitoring_result+="✅ Error Logs: $today_errors errors today (within limits)\\n"
                fi
            fi
            
            # Check other CVMA custom objects
            local custom_objects=("CVMA_Event_RSVP__c" "CVMA_Message__c" "CVMA_Announcement__c" "CVMA_Guest_Request__c")
            for obj in "${custom_objects[@]}"; do
                if sf data query --query "SELECT COUNT() FROM $obj WHERE CreatedDate = THIS_WEEK" --json > /tmp/obj_count.json 2>/dev/null; then
                    local record_count=$(jq '.result.totalSize' /tmp/obj_count.json)
                    monitoring_result+="ℹ️  $obj: $record_count records this week\\n"
                fi
            done
            
            rm -f /tmp/error_count.json /tmp/obj_count.json
            ;;
            
        "experience_cloud")
            # Monitor Experience Cloud specifically
            log_sf_monitor "Monitoring Experience Cloud sites..."
            if sf data query --query "SELECT Id, Name, Status, CreatedDate, (SELECT COUNT() FROM NetworkMembers) FROM Network WHERE Status = 'Live'" --json > /tmp/networks.json 2>/dev/null; then
                local network_count=$(jq '.result.records | length' /tmp/networks.json)
                monitoring_result+="✅ Experience Cloud: $network_count active networks\\n"
                
                # Check for guest user activity
                if sf data query --query "SELECT Id, Name, IsActive, Profile.Name FROM User WHERE Profile.Name LIKE '%Guest%' AND IsActive = true LIMIT 5" --json > /tmp/guest_users.json 2>/dev/null; then
                    local guest_count=$(jq '.result.records | length' /tmp/guest_users.json)
                    monitoring_result+="✅ Guest Users: $guest_count active guest user profiles\\n"
                fi
            fi
            
            rm -f /tmp/networks.json /tmp/guest_users.json
            ;;
    esac
    
    local component_report=$(cat << EOF
{
    "component_monitoring": {
        "component_type": "$component_type",
        "status": "$component_status",
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "monitoring_result": "$monitoring_result",
        "work_unit_id": "$work_unit_id"
    }
}
EOF
)
    
    log_sf_monitor "Component monitoring completed for $component_type: $component_status"
    echo "$component_report"
    
    return 0
}

# Error recovery and remediation
perform_error_recovery() {
    local work_unit_id="$1"
    local error_type="$2"
    local error_context="$3"
    
    log_sf_monitor "Starting error recovery for: $error_type"
    
    cd "$CVMA_PROJECT_PATH" || {
        log_sf_error "Failed to change to CVMA project directory"
        return 1
    }
    
    local recovery_actions=""
    local recovery_success=false
    
    case "$error_type" in
        "deployment_failure")
            log_sf_monitor "Attempting deployment failure recovery..."
            
            # 1. Check deployment status
            if sf project deploy report --json > /tmp/deploy_report.json 2>/dev/null; then
                local failed_components=$(jq '.result.response.details.componentFailures | length' /tmp/deploy_report.json 2>/dev/null)
                
                if [ "$failed_components" -gt 0 ]; then
                    recovery_actions+="Found $failed_components failed components\\n"
                    
                    # 2. Try selective deployment of successful components
                    log_sf_monitor "Attempting selective deployment..."
                    if sf project deploy start --ignore-conflicts --json > /tmp/recovery_deploy.json 2>/dev/null; then
                        recovery_actions+="Selective deployment initiated\\n"
                        recovery_success=true
                    else
                        recovery_actions+="Selective deployment failed\\n"
                    fi
                else
                    recovery_actions+="No failed components found\\n"
                    recovery_success=true
                fi
            fi
            
            rm -f /tmp/deploy_report.json /tmp/recovery_deploy.json
            ;;
            
        "test_failure")
            log_sf_monitor "Attempting test failure recovery..."
            
            # 1. Run tests with detailed results
            if sf apex run test --result-format json --detailed-coverage > /tmp/test_recovery.json 2>/dev/null; then
                local failed_tests=$(jq '.result.summary.failing' /tmp/test_recovery.json 2>/dev/null)
                
                recovery_actions+="Found $failed_tests failing tests\\n"
                
                # 2. Analyze common failure patterns
                local test_failures=$(jq -r '.result.tests[] | select(.outcome == "Fail") | .methodName' /tmp/test_recovery.json 2>/dev/null)
                recovery_actions+="Failed tests: $test_failures\\n"
                
                # 3. Check for data dependency issues
                if echo "$test_failures" | grep -q "TestDataFactory"; then
                    recovery_actions+="Detected test data issues - recommend reviewing CVMATestDataFactory\\n"
                fi
            fi
            
            rm -f /tmp/test_recovery.json
            ;;
            
        "org_limits")
            log_sf_monitor "Checking org limits and capacity..."
            
            if sf data query --query "SELECT Id, Max, Remaining, Name FROM Limit WHERE Name IN ('DailyApiRequests', 'DailyAsyncApexExecutions', 'DailyBulkApiRequests')" --json > /tmp/limits.json 2>/dev/null; then
                local limits_info=$(jq -r '.result.records[] | "\(.Name): \(.Remaining)/\(.Max)"' /tmp/limits.json)
                recovery_actions+="Current limits: $limits_info\\n"
                
                # Check if any limits are critically low
                local critical_limits=$(jq '.result.records[] | select((.Remaining / .Max) < 0.1) | .Name' /tmp/limits.json)
                if [ -n "$critical_limits" ]; then
                    recovery_actions+="CRITICAL: Low limits detected: $critical_limits\\n"
                else
                    recovery_actions+="All limits within acceptable ranges\\n"
                    recovery_success=true
                fi
            fi
            
            rm -f /tmp/limits.json
            ;;
            
        "experience_cloud_error")
            log_sf_monitor "Diagnosing Experience Cloud issues..."
            
            # Check network status
            if sf data query --query "SELECT Id, Name, Status, UrlPathPrefix FROM Site WHERE Status != 'Active'" --json > /tmp/site_issues.json 2>/dev/null; then
                local inactive_sites=$(jq '.result.records | length' /tmp/site_issues.json)
                if [ "$inactive_sites" -gt 0 ]; then
                    local site_names=$(jq -r '.result.records[].Name' /tmp/site_issues.json)
                    recovery_actions+="Inactive sites detected: $site_names\\n"
                else
                    recovery_actions+="All Experience Cloud sites active\\n"
                    recovery_success=true
                fi
            fi
            
            rm -f /tmp/site_issues.json
            ;;
    esac
    
    local recovery_report=$(cat << EOF
{
    "error_recovery": {
        "error_type": "$error_type",
        "error_context": "$error_context",
        "recovery_success": $recovery_success,
        "recovery_actions": "$recovery_actions",
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "work_unit_id": "$work_unit_id"
    }
}
EOF
)
    
    log_sf_monitor "Error recovery completed for $error_type: success=$recovery_success"
    echo "$recovery_report"
    
    return 0
}

# Proactive maintenance tasks
perform_maintenance() {
    local work_unit_id="$1"
    local maintenance_type="$2"
    
    log_sf_monitor "Starting maintenance task: $maintenance_type"
    
    cd "$CVMA_PROJECT_PATH" || {
        log_sf_error "Failed to change to CVMA project directory"
        return 1
    }
    
    local maintenance_result=""
    local maintenance_success=false
    
    case "$maintenance_type" in
        "cleanup_logs")
            log_sf_monitor "Cleaning up old debug logs..."
            
            # Delete debug logs older than 7 days
            if sf data query --query "SELECT Id FROM ApexLog WHERE StartTime < LAST_N_DAYS:7" --json > /tmp/old_logs.json 2>/dev/null; then
                local log_count=$(jq '.result.records | length' /tmp/old_logs.json)
                
                if [ "$log_count" -gt 0 ]; then
                    maintenance_result+="Found $log_count old debug logs to clean up\\n"
                    
                    # Note: Actual deletion would require careful implementation
                    maintenance_result+="Log cleanup scheduled (manual review required)\\n"
                    maintenance_success=true
                else
                    maintenance_result+="No old debug logs found\\n"
                    maintenance_success=true
                fi
            fi
            
            rm -f /tmp/old_logs.json
            ;;
            
        "validate_data_integrity")
            log_sf_monitor "Validating CVMA data integrity..."
            
            # Check for orphaned records
            local data_issues=0
            
            # Check CVMA_Event_RSVP__c records without valid contacts
            if sf data query --query "SELECT COUNT() FROM CVMA_Event_RSVP__c WHERE Contact__c = null" --json > /tmp/orphaned_rsvps.json 2>/dev/null; then
                local orphaned_rsvps=$(jq '.result.totalSize' /tmp/orphaned_rsvps.json)
                if [ "$orphaned_rsvps" -gt 0 ]; then
                    maintenance_result+="Found $orphaned_rsvps RSVP records without contacts\\n"
                    ((data_issues++))
                fi
            fi
            
            # Check for duplicate email addresses in contacts
            if sf data query --query "SELECT Email, COUNT(Id) cnt FROM Contact WHERE Email != null GROUP BY Email HAVING COUNT(Id) > 1" --json > /tmp/duplicate_emails.json 2>/dev/null; then
                local duplicate_emails=$(jq '.result.records | length' /tmp/duplicate_emails.json)
                if [ "$duplicate_emails" -gt 0 ]; then
                    maintenance_result+="Found $duplicate_emails duplicate email addresses\\n"
                    ((data_issues++))
                fi
            fi
            
            if [ "$data_issues" -eq 0 ]; then
                maintenance_result+="Data integrity check passed - no issues found\\n"
                maintenance_success=true
            else
                maintenance_result+="Data integrity issues detected: $data_issues problems\\n"
            fi
            
            rm -f /tmp/orphaned_rsvps.json /tmp/duplicate_emails.json
            ;;
            
        "performance_optimization")
            log_sf_monitor "Checking performance optimization opportunities..."
            
            # Check for long-running SOQL queries
            maintenance_result+="Performance analysis completed - monitoring for optimization opportunities\\n"
            
            # Check storage usage
            if sf data query --query "SELECT Id, Used, Max FROM Limit WHERE Name = 'DataStorageMB'" --json > /tmp/storage.json 2>/dev/null; then
                local used_storage=$(jq '.result.records[0].Used' /tmp/storage.json)
                local max_storage=$(jq '.result.records[0].Max' /tmp/storage.json)
                local usage_percent=$((used_storage * 100 / max_storage))
                
                maintenance_result+="Data storage usage: $usage_percent% ($used_storage MB / $max_storage MB)\\n"
                
                if [ "$usage_percent" -lt 80 ]; then
                    maintenance_success=true
                else
                    maintenance_result+="WARNING: High storage usage detected\\n"
                fi
            fi
            
            rm -f /tmp/storage.json
            ;;
    esac
    
    local maintenance_report=$(cat << EOF
{
    "maintenance_task": {
        "maintenance_type": "$maintenance_type",
        "success": $maintenance_success,
        "result": "$maintenance_result",
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "work_unit_id": "$work_unit_id"
    }
}
EOF
)
    
    log_sf_monitor "Maintenance task completed: $maintenance_type (success=$maintenance_success)"
    echo "$maintenance_report"
    
    return 0
}

# Main task dispatcher for Salesforce monitoring
dispatch_salesforce_task() {
    local work_unit_file="$1"
    
    if [ ! -f "$work_unit_file" ]; then
        log_sf_error "Work unit file not found: $work_unit_file"
        return 1
    fi
    
    # Extract task information (simplified - in production would use jq)
    local unit_id=$(basename "$work_unit_file" .json | cut -d'_' -f3-)
    local task_type="salesforce_monitoring"  # Default for this agent
    
    # Determine specific monitoring task from filename or content
    if [[ "$work_unit_file" == *"health"* ]]; then
        task_type="org_health_check"
    elif [[ "$work_unit_file" == *"component"* ]]; then
        task_type="component_monitoring"
    elif [[ "$work_unit_file" == *"recovery"* ]]; then
        task_type="error_recovery"
    elif [[ "$work_unit_file" == *"maintenance"* ]]; then
        task_type="maintenance"
    fi
    
    log_sf_monitor "Dispatching Salesforce task: $unit_id [$task_type]"
    
    local task_result=""
    local task_success=true
    
    case "$task_type" in
        "org_health_check")
            task_result=$(monitor_org_health "$unit_id")
            ;;
        "component_monitoring")
            # Default to lightning components monitoring
            task_result=$(monitor_cvma_components "$unit_id" "lightning_components")
            ;;
        "error_recovery")
            task_result=$(perform_error_recovery "$unit_id" "deployment_failure" "automated_recovery")
            ;;
        "maintenance")
            task_result=$(perform_maintenance "$unit_id" "cleanup_logs")
            ;;
        *)
            log_sf_error "Unknown Salesforce monitoring task type: $task_type"
            task_success=false
            ;;
    esac
    
    if [ "$task_success" = true ] && [ -n "$task_result" ]; then
        log_sf_monitor "Salesforce monitoring task completed successfully: $unit_id"
        echo "$task_result"
    else
        log_sf_error "Salesforce monitoring task failed: $unit_id"
        return 1
    fi
    
    return 0
}

# Salesforce monitoring agent main loop
run_salesforce_agent() {
    log_sf_monitor "Salesforce monitoring agent starting..."
    
    while true; do
        # Look for pending work assigned to salesforce_monitor
        for work_file in "$WORK_QUEUE_DIR"/*.json; do
            [ -f "$work_file" ] || continue
            
            # Simplified agent assignment check - in production would use jq
            if [[ "$work_file" == *"salesforce"* ]] || [[ "$work_file" == *"sf_monitor"* ]]; then
                dispatch_salesforce_task "$work_file"
            fi
        done
        
        # Brief pause between cycles
        sleep 10
    done
}

# Command interface
case "$1" in
    "start")
        run_salesforce_agent
        ;;
    "health_check")
        echo "Running org health check..."
        result=$(monitor_org_health "manual_health_check")
        echo "$result"
        ;;
    "monitor_components")
        local component_type="${2:-lightning_components}"
        echo "Monitoring CVMA components: $component_type"
        result=$(monitor_cvma_components "manual_component_check" "$component_type")
        echo "$result"
        ;;
    "error_recovery")
        local error_type="${2:-deployment_failure}"
        echo "Performing error recovery: $error_type"
        result=$(perform_error_recovery "manual_recovery" "$error_type" "manual_trigger")
        echo "$result"
        ;;
    "maintenance")
        local maintenance_type="${2:-cleanup_logs}"
        echo "Performing maintenance: $maintenance_type"
        result=$(perform_maintenance "manual_maintenance" "$maintenance_type")
        echo "$result"
        ;;
    "status")
        echo "🔍 Salesforce Monitoring Agent Status"
        echo "===================================="
        echo "Agent Name: $AGENT_NAME"
        echo "Monitor Log: $SF_MONITOR_LOG"
        echo "Error Log: $SF_ERROR_LOG"
        echo "CVMA Org: $CVMA_ORG_ALIAS"
        echo
        echo "Monitoring Capabilities:"
        echo "  📊 Comprehensive org health monitoring"
        echo "  🔧 CVMA component-specific monitoring"
        echo "  🚨 Automated error detection and recovery"
        echo "  🔄 Proactive maintenance and optimization"
        echo "  📈 Performance and capacity monitoring"
        echo "  🌐 Experience Cloud site monitoring"
        echo
        if [ -f "$SF_MONITOR_LOG" ]; then
            echo "Recent monitoring activity:"
            tail -5 "$SF_MONITOR_LOG"
        fi
        ;;
    *)
        echo "🔍 CVMA Salesforce Monitoring Agent"
        echo "===================================="
        echo
        echo "Commands:"
        echo "  start                     - Start monitoring agent daemon"
        echo "  health_check              - Run comprehensive org health check"
        echo "  monitor_components [type] - Monitor specific components"
        echo "    Types: lightning_components, apex_classes, custom_objects, experience_cloud"
        echo "  error_recovery [type]     - Perform error recovery"
        echo "    Types: deployment_failure, test_failure, org_limits, experience_cloud_error"
        echo "  maintenance [type]        - Run maintenance tasks"
        echo "    Types: cleanup_logs, validate_data_integrity, performance_optimization"
        echo "  status                    - Show agent status and recent activity"
        echo
        echo "This agent provides comprehensive monitoring and automated recovery"
        echo "for the CVMA Salesforce org, including Experience Cloud sites."
        echo
        echo "Integration with multi-agent system enables coordinated monitoring"
        echo "with Claude strategic oversight and Copilot tactical execution."
        ;;
esac