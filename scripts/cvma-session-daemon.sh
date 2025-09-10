#!/bin/bash

# CVMA Session Daemon
# Continuous monitoring for scheduled sessions
# Created: September 9, 2025

SCHEDULER_SCRIPT="/c/Users/zerov/IdeaProjects/cvma/scripts/cvma-session-scheduler.sh"
CHECK_INTERVAL=60  # Check every minute
LOG_FILE="/c/Users/zerov/IdeaProjects/cvma/logs/sessions/daemon.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date)] CVMA Session Daemon starting..." | tee -a "$LOG_FILE"

# Function to check for session time
monitor_sessions() {
    while true; do
        current_time=$(date +'%H:%M')
        
        # Run status check (this will trigger session if it's time)
        if [ -x "$SCHEDULER_SCRIPT" ]; then
            "$SCHEDULER_SCRIPT" status >> "$LOG_FILE" 2>&1
            
            # Check if session was triggered by looking for alert output
            if "$SCHEDULER_SCRIPT" status 2>/dev/null | grep -q "CVMA Development Session Alert"; then
                echo "[$(date)] Session alert triggered at $current_time" | tee -a "$LOG_FILE"
                
                # Optional: Open Claude Code or launch development environment
                # code "C:\Users\zerov\IdeaProjects\cvma" &
            fi
        else
            echo "[$(date)] Scheduler script not found or not executable" | tee -a "$LOG_FILE"
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# Signal handlers for graceful shutdown
cleanup() {
    echo "[$(date)] CVMA Session Daemon stopping..." | tee -a "$LOG_FILE"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start monitoring
echo "[$(date)] Monitoring sessions every $CHECK_INTERVAL seconds" | tee -a "$LOG_FILE"
monitor_sessions