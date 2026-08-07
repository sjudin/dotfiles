#!/bin/bash

STATE_FILE="$HOME/.config/waybar/.disk_state"

state=root
[ -f "$STATE_FILE" ] && state=$(<"$STATE_FILE")

if [ "$1" == "toggle" ]; then
    [ "$state" == "root" ] && echo "home" > "$STATE_FILE" || echo "root" > "$STATE_FILE"
    exit 0
fi

if [ "$state" == "root" ]; then
    target_path="/"
    alt="root"
else
    target_path="$HOME"
    alt="home"
fi

percent_num=$(df -h "$target_path" | awk 'NR==2 {gsub(/%/, "", $5); print $5}')

printf '{"text": %d, "alt": "%s"}\n' "$percent_num" "$alt"
