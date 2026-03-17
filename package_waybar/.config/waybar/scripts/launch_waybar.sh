#!/bin/bash

# Kill any running instances
killall waybar

# Ask Linux if this specific machine has a battery hardware folder
if ls /sys/class/power_supply/BAT* > /dev/null 2>&1; then
    waybar -c ~/.config/waybar/config.jsonc &
else
    waybar -c ~/.config/waybar/desktop-config.jsonc &
fi
