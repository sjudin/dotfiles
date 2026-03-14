#!/usr/bin/env bash

# Dependencies: wl-clipboard, cliphist, rofi, awk

# ==========================================
# STATE 0: The "Direct Run" Bypass
# ==========================================
if [ -z "$ROFI_RETV" ]; then
    exec rofi -show Clipboard -modi "Clipboard:$0"
fi

# ==========================================
# STATE 1: Display the List
# ==========================================
if [ -z "$1" ]; then
    echo -en "\x00prompt\x1f📋 Clipboard\n"

    # Grab the list, truncate long text, and inject the native copy icon
    cliphist list | awk -F'\t' '{
        id = $1;
        text = $2;
        if (length(text) > 65) {
            text = substr(text, 1, 65) "...";
        }
        # Replaces the massive \t (Tab) with two normal spaces!
        printf "%s  %s\0icon\x1fedit-copy\n", id, text;
    }'
    exit 0
fi

# ==========================================
# STATE 2: Process the Selection
# ==========================================
# Extract just the ID number (the very first word) from the Rofi selection
id=$(echo "$1" | awk '{print $1}')

if [ -n "$id" ]; then
    # cliphist decode needs the ID followed by a tab to fetch the exact entry
    printf "%s\t" "$id" | cliphist decode | wl-copy

    if command -v notify-send > /dev/null 2>&1; then
        notify-send -t 1500 -u low "📋 Copied" "Item ready to paste!"
    fi
fi
