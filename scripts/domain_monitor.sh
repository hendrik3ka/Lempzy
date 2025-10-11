#!/bin/bash

# Enable debug output
set -x

# Include the Telegram notification function script
DIR="$(cd "$(dirname "${BASH_SOURCE}")" >/dev/null 2>&1 && pwd)"
TELEGRAM_NOTIFY_SCRIPT="$DIR/telegram_notify.sh"
if ! source "$TELEGRAM_NOTIFY_SCRIPT"; then
    echo "Error: Failed to source $TELEGRAM_NOTIFY_SCRIPT" >&2
    exit 1
fi

# Parent directory for domains
WWW_DIR="/home/mindforest.top/"

# Events to monitor for files and folders
MONITOR_EVENTS="create,delete,modify,move"

# List of sensitive files/subdirectories relative to each domain root
SENSITIVE_ITEMS=(
    "wp-admin"
    "wp-includes"
    "index.php"
    "wp-cron.php"
)

# File to log inotifywait errors
INOTIFY_ERROR_LOG="/tmp/inotifywait_errors.log"

# Function to kill all inotifywait processes
kill_existing_monitors() {
    echo "Killing all inotifywait processes at $(date)..."
    if pkill -f "^/usr/bin/inotifywait" 2>/dev/null; then
        echo "Successfully killed inotifywait processes"
    else
        echo "No inotifywait processes found to kill"
    fi
    sleep 2  # Ensure processes are fully terminated
}

# Function to start monitoring a list of paths
start_watch() {
    local watch_paths=("$@")
    local process_info="Monitoring: ${watch_paths[*]}"

    echo "Starting monitor for $process_info at $(date)"
    
    # Start inotifywait in background
    /usr/bin/inotifywait -m -r -e "$MONITOR_EVENTS" "${watch_paths[@]}" 2>>"$INOTIFY_ERROR_LOG" |
    while read path event file; do
        # Log raw event
        echo "Event: path='$path', event='$event', file='$file'"
        
        # Deduplicate notifications using a lock file
        EVENT_KEY="$path$file:$event"
        LOCK_FILE="/tmp/inotify_event_$(echo -n "$EVENT_KEY" | md5sum | awk '{print $1}').lock"
        
        # Only process if lock file doesn't exist
        if ! [ -f "$LOCK_FILE" ]; then
            touch "$LOCK_FILE"
            
            # Notify for directory creation in wp-admin or wp-includes
            if [[ "$event" =~ ISDIR && ( "$path" =~ wp-admin/ || "$path" =~ wp-includes/ ) ]]; then
                MESSAGE="*ALERT*: New directory detected in '$path$file'. Event: '$event'"
                echo "Sending notification for new directory in $path$file"
                send_telegram_notification "$MESSAGE"
            elif [[ ! "$event" =~ ISDIR ]]; then
                # Notify for file changes
                MESSAGE="*ALERT*: Change detected in '$path$file'. Event: '$event'"
                echo "Sending notification for change in $path$file"
                send_telegram_notification "$MESSAGE"
            fi
            
            # Remove lock file after 1 second to allow new events
            (sleep 1; rm -f "$LOCK_FILE") &
        else
            echo "Duplicate event ignored: $EVENT_KEY"
        fi
    done &
    
    # Log the PID of the inotifywait process
    local inotify_pid=$!
    echo "Started inotifywait with PID $inotify_pid"
}

# Function to scan and monitor existing domains
scan_domains() {
    echo "=== Scanning domains at $(date) ==="
    
    # Kill existing monitors
    kill_existing_monitors
    
    # Scan domains
    local total_paths=0
    for domain_dir in "$WWW_DIR"/*/; do
        if [ -d "$domain_dir" ]; then
            domain_name=$(basename "$domain_dir")
            echo "Processing domain: $domain_name"
            
            # Build the list of specific paths for this domain
            declare -a domain_paths=()
            for item in "${SENSITIVE_ITEMS[@]}"; do
                full_path="$domain_dir$item"
                if [ -e "$full_path" ]; then
                    domain_paths+=("$full_path")
                    ((total_paths++))
                else
                    echo "Path $full_path does not exist; will be picked up in next scan"
                fi
            done
            
            if [ ${#domain_paths[@]} -gt 0 ]; then
                echo "Monitoring ${#domain_paths[@]} paths for $domain_name"
                start_watch "${domain_paths[@]}"
            else
                echo "No SENSITIVE_ITEMS found for $domain_name"
            fi
        fi
    done
    
    echo "Scan complete. Monitoring $total_paths paths at $(date)."
}

# Trap to clean up on exit
trap 'kill_existing_monitors; echo "Service terminated gracefully at $(date)"; exit 0' EXIT

# 1. Initial scan and monitoring
echo "Starting domain monitor service at $(date)..."
scan_domains

# 2. Periodically re-scan domains every 60 seconds
(
    while true; do
        sleep 60
        echo "=== Periodic rescan triggered at $(date) ==="
        scan_domains
    done
) &

# Store the rescan loop PID
RESCAN_PID=$!
echo "Rescan loop started with PID $RESCAN_PID"

# 3. Monitor for new domain directories
echo "Starting new domain detection monitor at $(date)..."
/usr/bin/inotifywait -m -e create,moved_to "$WWW_DIR" 2>>"$INOTIFY_ERROR_LOG" |
while read path event file; do
    NEW_DOMAIN_PATH="$WWW_DIR/$file"
    if [ -d "$NEW_DOMAIN_PATH" ]; then
        echo "New domain folder detected: $NEW_DOMAIN_PATH at $(date)"
        # Next scan will pick up its SENSITIVE_ITEMS
    fi
done &

# Log the new domain monitor PID
NEW_DOMAIN_PID=$!
echo "New domain monitor started with PID $NEW_DOMAIN_PID"

# Log service status
echo "Domain monitor service running at $(date)."

# Keep the script running
wait