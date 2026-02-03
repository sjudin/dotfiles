#!/usr/bin/env bash
# When lid closed:
#   Only turns off screen (clamshell mode) when more than 1 output found,
#   Goes to sleep otherwise.
# When lid opened:
#   Turns screen back on.
#
# SYNOPSIS
#   ./lid_action.sh STATE [options]
#
# ARGUMENTS
#   state
#       Either 'closed' or 'open' to represent the current lid state
if [ $# -lt 1 ]; then
    echo "Missing lid state argument"
    exit 1
fi

lid_state=$1; shift
outputs_count=$(swaymsg -t get_outputs | grep name | wc -l)
laptop_screen='eDP-1'

function notify {
    notify-send "Clamshell mode" "$1"
}

if [[ ${lid_state} == "open" ]]; then
    swaymsg -- output "${laptop_screen}" enable
    notify "Laptop screen enabled"
else
    if [[ ${outputs_count} == 1 ]]; then
        notify "Sleeping"
        swaymsg -- exec systemctl suspend
    else
        notify "Laptop screen off"
        swaymsg -- output "${laptop_screen}" disable
    fi
fi
