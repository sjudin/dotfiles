#!/bin/sh

laptop_output="eDP-1"
lid_state_file="/proc/acpi/button/lid/LID/state"

read -r lid_state < "$lid_state_file"

case "$lid_state" in
    *open) swaymsg output "$laptop_output" enable ;;
    *closed) swaymsg output "$laptop_output" disable ;;
    *) echo "Could not get lid state" >&2; exit 1 ;;
esac
