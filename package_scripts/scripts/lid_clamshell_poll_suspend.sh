#!/bin/bash

# Subscribe to output events
swaymsg -t subscribe -m '["output"]' | while read -r event; do

    # --- DEBOUNCE LOGIC ---
    # When one event hits, wait some time and 'eat' any other
    # events that arrived in the pipe during that time.
    while read -t 1.0 -r extra_events; do
        continue
    done

    if grep -iq "closed" /proc/acpi/button/lid/*/state; then
        OUTPUTS=$(swaymsg -t get_outputs | grep name | wc -l)
        if [ "$OUTPUTS" -le 1 ]; then
            systemctl suspend
        fi
    fi
done
