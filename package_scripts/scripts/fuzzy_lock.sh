#!/usr/bin/env bash


lock_screen() {
    # Take a screenshot
    scrot -o /tmp/screen_locked.png

    # Pixellate it 10x
    mogrify -scale 20% -scale 500% /tmp/screen_locked.png

    # Lock screen displaying this image.
    i3lock -n -i /tmp/screen_locked.png
}

lock_screen
