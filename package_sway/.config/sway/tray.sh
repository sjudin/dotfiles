#!/bin/bash

pkill -f blueman-applet
pkill -f iwgtk
pkill -f arch-update

blueman-applet &
iwgtk -i &
sleep 3 && arch-update --tray

