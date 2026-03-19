#!/bin/bash
FLAG_FILE="/tmp/hypridle_inhibited"
# We watch the directory because watching a non-existent file is tricky
WATCH_DIR=$(dirname "$FLAG_FILE")

print_status() {
    if [ -f "/tmp/hypridle_inhibited" ]; then
        # Output JSON with the 'inhibited' class
        echo "{\"class\": \"inhibited\", \"alt\": \"inhibited\", \"tooltip\": \"Lock Inhibited\"}"
    else
        # Output JSON with the 'active' class
        echo "{\"class\": \"active\", \"alt\": \"active\", \"tooltip\": \"Lock Active\"}"
    fi
}

# print initial state
print_status

# Loop and wait for events
# -m: monitor mode (don't exit)
# -e: events to watch (create/delete)
inotifywait -m -e create -e delete "$WATCH_DIR" 2>/dev/null | while read -r directory event file; do
    # Only update if the specific flag file was the one changed
    if [ "$file" = "hypridle_inhibited" ]; then
        print_status
    fi
done
