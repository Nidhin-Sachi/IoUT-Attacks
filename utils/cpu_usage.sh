#!/bin/bash

# File to store the CPU usage log
LOG_FILE="/home/rps/Documents/nidhin/cpu_usage.log"

# Function to calculate CPU usage
get_cpu_usage() {
    # Read CPU stats from /proc/stat
    CPU=($(head -n1 /proc/stat))
    IDLE=${CPU[4]}
    TOTAL=0

    # Sum all CPU values
    for VALUE in "${CPU[@]:1}"; do
        TOTAL=$((TOTAL + VALUE))
    done

    # Calculate the difference in idle and total values
    DIFF_IDLE=$((IDLE - PREV_IDLE))
    DIFF_TOTAL=$((TOTAL - PREV_TOTAL))
    DIFF_USAGE=$((100 * (DIFF_TOTAL - DIFF_IDLE) / DIFF_TOTAL))

    # Save the current CPU stats for the next calculation
    PREV_IDLE=$IDLE
    PREV_TOTAL=$TOTAL

    echo "$DIFF_USAGE"
}

# Initialize CPU stats
PREV_STATS=($(head -n1 /proc/stat))
PREV_IDLE=${PREV_STATS[4]}
PREV_TOTAL=0
for VALUE in "${PREV_STATS[@]:1}"; do
    PREV_TOTAL=$((PREV_TOTAL + VALUE))
done

# Infinite loop to log CPU usage every 5 minutes
while true; do
    # Get current date and time
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    # Calculate CPU usage
    CPU_USAGE=$(get_cpu_usage)

    # Log the timestamp and CPU usage into the file
    echo "$TIMESTAMP CPU Usage: $CPU_USAGE%" >> "$LOG_FILE"

    # Wait for 5 minutes
    sleep 300 
done
