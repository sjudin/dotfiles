#!/bin/bash

# If a previous instance is running, we kill it before rerunning
# NOTE: This is not working currently
# script_name="fuzzy_lock.sh"
# for pid in $(pidof -x $script_name); do
#     if [ $pid != $$ ]; then
#         kill $pid
#     fi
# done

force=false
while getopts 'f' OPTION; do
    case "${OPTION}" in
        f) force=true;;
    esac
done

lock_screen() {
    # Take a screenshot
    scrot -o /tmp/screen_locked.png

    # Pixellate it 10x
    mogrify -scale 20% -scale 500% /tmp/screen_locked.png

    # Lock screen displaying this image.
    i3lock -n -i /tmp/screen_locked.png & # && echo mem > /sys/power/state

    # Turn the screen off after a delay.
    sleep 60
    if [[ $(pgrep i3lock | wc -l ) -ne 0 ]]; then
        xset dpms force off
    fi
}

# Only try to lock the screen if we are not playing sound, source:
# https://www.reddit.com/r/i3wm/comments/ak8fjy/how_do_you_guys_suspend_xautolocki3lock_when/
if [ $(grep -r "RUNNING" /proc/asound | wc -l) -eq 0 ] || [ $force = true ]; then
    lock_screen
fi

