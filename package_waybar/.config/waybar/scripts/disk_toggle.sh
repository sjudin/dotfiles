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

# Fetch the usage based on the current state and format for Waybar
if [ "$STATE" == "root" ]; then
    USAGE=$(df -h / | awk 'NR==2 {print $5}')
    echo "{\"text\": \"$USAGE 󰋊\", \"tooltip\": \"Root (/) Usage: $USAGE\"}"
else
    USAGE=$(df -h $HOME | awk 'NR==2 {print $5}')
    echo "{\"text\": \"$USAGE 󰋊\", \"tooltip\": \"Home ($HOME) Usage: $USAGE\"}"
fi
