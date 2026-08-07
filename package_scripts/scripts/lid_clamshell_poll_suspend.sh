#!/bin/bash

swaymsg -t subscribe -m '["output"]' | while read -r _; do
    while read -r -t 1 _; do
        :
    done

    if grep -iq "closed" /proc/acpi/button/lid/*/state; then
        outputs=$(swaymsg -t get_outputs | grep -c '"name"')
        if (( outputs <= 1 )); then
            systemctl suspend
        fi
    fi
done
