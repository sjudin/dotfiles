#!/bin/bash

STATE_FILE="$HOME/.config/waybar/.disk_state"

# Initialize state if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "root" > "$STATE_FILE"
fi

STATE=$(cat "$STATE_FILE")

# Handle the toggle action on click
if [ "$1" == "toggle" ]; then
    if [ "$STATE" == "root" ]; then
        echo "home" > "$STATE_FILE"
    else
        echo "root" > "$STATE_FILE"
    fi
    exit 0
fi

if [ "$STATE" == "root" ]; then
    TARGET_PATH="/"
    ALT="root"
else
    TARGET_PATH="$HOME"
    ALT="home"
fi

# Fetch the raw percentage number (stripping the % sign for the JSON spec)
PERCENT_NUM=$(df -h "$TARGET_PATH" | awk 'NR==2 {print $5}' | tr -d '%')

# Use printf to safely construct and output the single JSON object
printf '{"text": %d, "alt": "%s"}\n' "$PERCENT_NUM" "$ALT"

