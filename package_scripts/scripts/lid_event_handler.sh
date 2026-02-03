#!/bin/sh

###############################################################################
# Script Name:  lid_event_handler.sh
# Description:  Automatically enables or disables the laptop's internal display
#               based on the physical lid state (open/closed).
# Dependencies: sway, swaymsg, acpi_button (kernel module)
#
# Usage:        This script is typically triggered by an ACPI event or 
#               run as a background daemon/uDev rule.
#
# Variables:    LAPTOP_OUTPUT - Set this to your display identifier 
#                               (e.g., "eDP-1").
###############################################################################

LAPTOP_OUTPUT="eDP-1"
LID_STATE_FILE="/proc/acpi/button/lid/LID0/state"

read -r LS < "$LID_STATE_FILE"

case "$LS" in
*open)   swaymsg output "$LAPTOP_OUTPUT" enable ;;
*closed) swaymsg output "$LAPTOP_OUTPUT" disable ;;
*)       echo "Could not get lid state" >&2 ; exit 1 ;;
esac
