#!/bin/bash

# GPIO pin for SCL (BCM pin 3)
SCL_PIN=3
LOG_FILE="scl_data.csv"
MANIPULATION_MODE="toggle"  # Options: "stretch" or "toggle"
MANIPULATION_DURATION=2      # Duration in seconds for manipulation
MONITOR_DURATION=5           # Duration in seconds for monitoring
POLLING_INTERVAL=0.0001      # Polling interval in seconds

# Function to configure GPIO for output
configure_gpio_output() {
    echo "$SCL_PIN" > /sys/class/gpio/export 2>/dev/null
    echo "out" > /sys/class/gpio/gpio$SCL_PIN/direction
    echo "1" > /sys/class/gpio/gpio$SCL_PIN/value
    echo "[INFO] Configured GPIO $SCL_PIN as output."
}

# Function to configure GPIO for input
configure_gpio_input() {
    echo "in" > /sys/class/gpio/gpio$SCL_PIN/direction
    echo "[INFO] Configured GPIO $SCL_PIN as input."
}

# Function to manipulate the SCL line
manipulate_scl() {
    echo "[INFO] Starting SCL $MANIPULATION_MODE manipulation for $MANIPULATION_DURATION seconds..."
    local start_time=$(date +%s.%N)
    if [ "$MANIPULATION_MODE" = "stretch" ]; then
        echo "0" > /sys/class/gpio/gpio$SCL_PIN/value  # Hold SCL low
        sleep $MANIPULATION_DURATION
    elif [ "$MANIPULATION_MODE" = "toggle" ]; then
        while (( $(echo "$(date +%s.%N) - $start_time < $MANIPULATION_DURATION" | bc -l) )); do
            echo "1" > /sys/class/gpio/gpio$SCL_PIN/value
            sleep 0.001  # 1 ms HIGH
            echo "0" > /sys/class/gpio/gpio$SCL_PIN/value
            sleep 0.001  # 1 ms LOW
        done
    fi
    echo "1" > /sys/class/gpio/gpio$SCL_PIN/value  # Restore SCL to HIGH
    echo "[INFO] SCL $MANIPULATION_MODE manipulation complete."
}

# Function to monitor the SCL line
monitor_scl() {
    echo "[INFO] Monitoring SCL line for $MONITOR_DURATION seconds..."
    configure_gpio_input
    echo "Timestamp,SCL_State" > "$LOG_FILE"
    local start_time=$(date +%s.%N)
    while (( $(echo "$(date +%s.%N) - $start_time < $MONITOR_DURATION" | bc -l) )); do
        local state=$(cat /sys/class/gpio/gpio$SCL_PIN/value)
        local timestamp=$(date +%s.%N)
        echo "$timestamp,$state" >> "$LOG_FILE"
        sleep $POLLING_INTERVAL
    done
    echo "[INFO] Monitoring complete. Data saved to $LOG_FILE."
}

# Cleanup function to release GPIO
cleanup_gpio() {
    echo "$SCL_PIN" > /sys/class/gpio/unexport 2>/dev/null
    echo "[INFO] Cleaned up GPIO $SCL_PIN."
}

# Main execution
trap cleanup_gpio EXIT
configure_gpio_output
monitor_scl &
manipulate_scl
wait
cleanup_gpi
