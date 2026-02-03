#!/bin/bash

pkill -f blueman-applet
pkill -f iwgtk
pkill -f arch-update

blueman-applet &
iwgtk -i &
arch-update --tray &

