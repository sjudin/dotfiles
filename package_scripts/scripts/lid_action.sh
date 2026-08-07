#!/usr/bin/env bash
# Enable the laptop screen when the lid opens. When it closes, suspend if no
# external screen is connected; otherwise disable the laptop screen.
if [ $# -lt 1 ]; then
    echo "Usage: ${0##*/} open|closed" >&2
    exit 1
fi

lid_state=$1
outputs_count=$(swaymsg -t get_outputs | grep -c '"name"')
laptop_screen='eDP-1'

function notify {
    notify-send "Clamshell mode" "$1"
}

case "$lid_state" in
    open)
        swaymsg -- output "${laptop_screen}" enable
        notify "Laptop screen enabled"
        ;;
    closed)
        if (( outputs_count <= 1 )); then
            notify "Sleeping"
            swaymsg -- exec systemctl suspend
        else
            notify "Laptop screen off"
            swaymsg -- output "${laptop_screen}" disable
        fi
        ;;
    *)
        echo "Usage: ${0##*/} open|closed" >&2
        exit 1
        ;;
esac
