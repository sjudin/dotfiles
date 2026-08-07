#!/usr/bin/env bash

shopt -s nullglob

batteries=(/sys/class/power_supply/BAT*)
battery=${batteries[0]}

if [[ -n $battery && -f "$battery/capacity" && -f "$battery/status" ]]; then
  status=$(<"$battery/status")

  [[ $status == "Charging" ]] && printf "(+) "
  printf "%s%%" "$(<"$battery/capacity")"
  [[ $status != "Charging" ]] && printf " remaining"
fi

printf "\n"
