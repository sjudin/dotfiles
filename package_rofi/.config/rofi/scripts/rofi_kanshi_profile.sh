#!/usr/bin/env bash

# Dependencies: kanshi (kanshictl), jq, rofi, sway

config="${XDG_CONFIG_HOME:-$HOME/.config}/kanshi/config"

profiles() {
    awk '
        /^[[:space:]]*profile[[:space:]]+[^[:space:]{]+[[:space:]]*\{/ {
            name = $2
            sub(/\{.*/, "", name)
            print name
        }
    ' "$config"
}

profile_outputs() {
    awk -v wanted="$1" '
        /^[[:space:]]*profile[[:space:]]+[^[:space:]{]+[[:space:]]*\{/ {
            profile = $2
            sub(/\{.*/, "", profile)
            active = (profile == wanted)
            next
        }

        active && /^[[:space:]]*}/ {
            active = 0
            next
        }

        active && /^[[:space:]]*(\.\.\.)?output[[:space:]]+/ {
            line = $0
            sub(/^[[:space:]]*/, "", line)
            variadic = (line ~ /^\.\.\./)
            sub(/^(\.\.\.)?output[[:space:]]+/, "", line)

            if (substr(line, 1, 1) == "\"") {
                line = substr(line, 2)
                end = index(line, "\"")
                criteria = substr(line, 1, end - 1)
            } else {
                split(line, fields, /[[:space:]]+/)
                criteria = fields[1]
            }

            printf "%d\t%s\n", variadic, criteria
        }
    ' "$config"
}

load_connected_outputs() {
    local connector connector_name connector_state name outputs_json row
    local drm_available=0
    local -a sway_outputs=()
    local -A physically_connected=()

    for connector in /sys/class/drm/card*-*/status; do
        [ -r "$connector" ] || continue
        drm_available=1
        read -r connector_state < "$connector"
        [ "$connector_state" = "connected" ] || continue

        connector_name=${connector%/status}
        connector_name=${connector_name##*/}
        connector_name=${connector_name#*-}
        physically_connected["$connector_name"]=1
    done

    outputs_json=$(swaymsg -t get_outputs 2>/dev/null) || return 1
    mapfile -t sway_outputs < <(
        jq -r '.[] | [.name, ([.make, .model, .serial] | join(" "))] | @tsv' \
            <<< "$outputs_json"
    )

    connected_outputs=()
    for row in "${sway_outputs[@]}"; do
        IFS=$'\t' read -r name _ <<< "$row"
        if [ "$drm_available" -eq 0 ] || [ "${physically_connected[$name]:-0}" -eq 1 ]; then
            connected_outputs+=("$row")
        fi
    done

    [ "${#connected_outputs[@]}" -gt 0 ]
}

profile_is_applicable() {
    local profile=$1 variadic criteria index name identifier found
    local matched=0
    local -a used=() variadic_criteria=()

    while IFS=$'\t' read -r variadic criteria; do
        if [ "$variadic" -eq 1 ]; then
            variadic_criteria+=("$criteria")
            continue
        fi

        found=-1
        for index in "${!connected_outputs[@]}"; do
            [ "${used[index]:-0}" -eq 1 ] && continue
            IFS=$'\t' read -r name identifier <<< "${connected_outputs[index]}"

            if [[ "$name" == $criteria || "$identifier" == $criteria ]]; then
                found=$index
                break
            fi
        done

        [ "$found" -ge 0 ] || return 1
        used[found]=1
        ((matched += 1))
    done < <(profile_outputs "$profile")

    # Every remaining output must be accepted by a variadic criterion.
    for index in "${!connected_outputs[@]}"; do
        [ "${used[index]:-0}" -eq 1 ] && continue
        IFS=$'\t' read -r name identifier <<< "${connected_outputs[index]}"
        found=0

        for criteria in "${variadic_criteria[@]}"; do
            if [[ "$name" == $criteria || "$identifier" == $criteria ]]; then
                found=1
                break
            fi
        done

        [ "$found" -eq 1 ] || return 1
    done

    [ "$matched" -gt 0 ] || [ "${#variadic_criteria[@]}" -gt 0 ]
}

# Allow the script to be launched directly as well as through Rofi's mode switcher.
if [ -z "$ROFI_RETV" ]; then
    exec rofi -show Displays -modi "Displays:$0"
fi

if [ ! -r "$config" ]; then
    printf '\0message\x1fKanshi config not found: %s\n' "$config"
    exit 0
fi

# Display available profiles and mark the one kanshi currently uses.
if [ -z "$1" ]; then
    current=$(kanshictl status 2>/dev/null | sed -n 's/^Current profile: //p')
    outputs_available=0
    load_connected_outputs && outputs_available=1
    printf '\0prompt\x1f󰍹 Displays\n'

    while IFS= read -r profile; do
        if [ "$outputs_available" -eq 1 ] && ! profile_is_applicable "$profile"; then
            continue
        fi

        if [ "$profile" = "$current" ]; then
            printf '[Current] %s\0icon\x1fvideo-display\n' "$profile"
        else
            printf '%s\0icon\x1fvideo-display\n' "$profile"
        fi
    done < <(profiles)
    exit 0
fi

selected=${1#\[Current\] }

# Only pass profile names read from the config to kanshictl.
if ! profiles | grep -Fqx -- "$selected"; then
    notify-send -t 2500 -u critical "Display profile not changed" "Unknown profile: $selected"
    exit 1
fi

if kanshictl switch "$selected"; then
    notify-send -i video-display -t 2000 -u low "Display profile activated" "$selected"
else
    notify-send -t 3000 -u critical "Display profile not changed" \
        "The connected outputs do not match $selected"
    exit 1
fi
