#!/bin/bash
FLAG_FILE="/tmp/hypridle_inhibited"
WATCH_DIR=$(dirname "$FLAG_FILE")
FLAG_NAME=$(basename "$FLAG_FILE")

print_status() {
    if [ -f "$FLAG_FILE" ]; then
        echo '{"class": "inhibited", "alt": "inhibited", "tooltip": "Lock Inhibited"}'
    else
        echo '{"class": "active", "alt": "active", "tooltip": "Lock Active"}'
    fi
}

print_status

inotifywait -m -e create -e delete "$WATCH_DIR" 2>/dev/null | while read -r directory event file; do
    if [ "$file" = "$FLAG_NAME" ]; then
        print_status
    fi
done
