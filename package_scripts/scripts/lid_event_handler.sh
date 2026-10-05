#!/bin/sh

laptop_output="eDP-1"
lid_state_file="/proc/acpi/button/lid/LID/state"

external_output_connected() {
    for connector in /sys/class/drm/card*-*/status; do
        [ -r "$connector" ] || continue
        case "$connector" in
            *-eDP-*) continue ;;
        esac

        read -r connector_state < "$connector"
        [ "$connector_state" = "connected" ] && return 0
    done

    return 1
}

read -r lid_state < "$lid_state_file"

case "$lid_state" in
    *open) swaymsg output "$laptop_output" enable ;;
    *closed)
        if external_output_connected; then
            swaymsg output "$laptop_output" disable
        fi
        ;;
    *) echo "Could not get lid state" >&2; exit 1 ;;
esac
