#!/usr/bin/env bash

# Dependencies: jq, libpulse (for pactl)

if command -v notify-send > /dev/null 2>&1; then SEND="notify-send"; else SEND="true"; fi

# ==========================================
# STATE 0: The "Direct Run" Bypass
# ==========================================
if [ -z "$ROFI_RETV" ]; then
    exec rofi -show Audio -modi "Audio:$0"
fi

# ==========================================
# Fetch current state
# ==========================================
default_sink=$(pactl get-default-sink)
sinks_json=$(pactl -f json list sinks)

default_source=$(pactl get-default-source)
sources_json=$(pactl -f json list sources)

# ==========================================
# STATE 1: Display the List
# ==========================================
if [ -z "$1" ]; then
    echo -en "\x00prompt\x1f🔊 Audio\n"

    # 1. Print Sinks (Outputs)
    echo "$sinks_json" | jq -r --arg def "$default_sink" '
      .[] | . as $sink | 
      select(
        if $sink.ports and $sink.active_port then
          ([$sink.ports[] | select(.name == $sink.active_port)][0].availability != "not available")
        else true end
      ) |
      (if .name == $def then "[Current Sink] " else "[Sink] " end) + .description + "\u0000icon\u001f" + .properties."device.icon_name"
    '

    # 2. Print Sources (Inputs)
    echo "$sources_json" | jq -r --arg def "$default_source" '
      .[] | . as $src | 
      select(.name | endswith(".monitor") | not) |
      select(
        if $src.ports and $src.active_port then
          ([$src.ports[] | select(.name == $src.active_port)][0].availability != "not available")
        else true end
      ) |
      (if .name == $def then "[Current Mic] " else "[Mic] " end) + .description + "\u0000icon\u001f" + .properties."device.icon_name"
    '
    exit 0
fi

# ==========================================
# STATE 2: Process the Selection
# ==========================================
chosen_desc="$1"

# Check if the user selected a Sink
chosen_sink=$(echo "$sinks_json" | jq -r --arg sel "$chosen_desc" --arg def "$default_sink" '
  .[] | select(((if .name == $def then "[Current Sink] " else "[Sink] " end) + .description) == $sel) | .name
')

if [ -n "$chosen_sink" ]; then
    if [ "$chosen_sink" != "$default_sink" ]; then
        if pactl set-default-sink "$chosen_sink"; then
            clean_notif=$(echo "$sinks_json" | jq -r --arg name "$chosen_sink" '.[] | select(.name == $name) | .description')
            $SEND -i audio-speakers -t 2000 -u low "Output Activated" "$clean_notif"
        fi
    fi
    exit 0
fi

# Check if the user selected a Source (Mic)
chosen_source=$(echo "$sources_json" | jq -r --arg sel "$chosen_desc" --arg def "$default_source" '
  .[] | select(((if .name == $def then "[Current Mic] " else "[Mic] " end) + .description) == $sel) | .name
')

if [ -n "$chosen_source" ]; then
    if [ "$chosen_source" != "$default_source" ]; then
        if pactl set-default-source "$chosen_source"; then
            clean_notif=$(echo "$sources_json" | jq -r --arg name "$chosen_source" '.[] | select(.name == $name) | .description')
            $SEND -i audio-input-microphone -t 2000 -u low "Input Activated" "$clean_notif"
        fi
    fi
    exit 0
fi
