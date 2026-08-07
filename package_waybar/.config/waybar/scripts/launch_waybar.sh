#!/bin/bash

killall waybar

if compgen -G "/sys/class/power_supply/BAT*" >/dev/null; then
    config=config.jsonc
else
    config=desktop-config.jsonc
fi

waybar -c "$HOME/.config/waybar/$config" &
