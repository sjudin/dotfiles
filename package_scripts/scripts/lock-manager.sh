#!/bin/bash

# --- Configuration ---
TIMEOUT=10
KBD_DEVICE='tpacpi::kbd_backlight'

# 1. Save current keyboard brightness
# We capture this so we can restore it to the exact same level later
KBD_VAL=$(brightnessctl -d "$KBD_DEVICE" get)

# --- Safety Trap ---
# If script is killed or finishes, restore everything
trap 'jobs -p | xargs -r kill; swaymsg "output * dpms on"; brightnessctl -d "$KBD_DEVICE" set "$KBD_VAL"; exit' EXIT INT TERM

# 2. Start the Idle Listener
# - Timeout: Turn screen OFF AND keyboard OFF (set 0)
# - Resume: Turn screen ON AND restore keyboard brightness
swayidle -w \
    timeout "$TIMEOUT" "swaymsg 'output * dpms off'; brightnessctl -d '$KBD_DEVICE' set 0" \
    resume "swaymsg 'output * dpms on'; brightnessctl -d '$KBD_DEVICE' set '$KBD_VAL'" &

# 3. Handshake Delay
sleep 0.1

# 4. Start Hyprlock
hyprlock --immediate-render

# (Cleanup runs automatically via trap when hyprlock exits)
