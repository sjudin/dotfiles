#!/bin/bash

pkill -f pasystray
pkill -f blueman-applet
pkill -f nm-applet
pkill -f flameshot

pasystray --notify=all &
blueman-applet &
nm-applet --indicator &
flameshot &

