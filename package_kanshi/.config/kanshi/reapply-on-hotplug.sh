#!/usr/bin/env bash

# Reapply the variadic laptop-only profile when a display is plugged or
# unplugged. Kanshi keeps a manually selected profile active when it continues
# to match, but does not reapply it to a newly connected output.

lock_file="${XDG_RUNTIME_DIR:-/tmp}/kanshi-reapply-on-hotplug-${UID}.lock"
exec 9>"$lock_file"
flock -n 9 || exit 0

connected_outputs() {
    local connector connector_state

    for connector in /sys/class/drm/card*-*/status; do
        [ -r "$connector" ] || continue
        read -r connector_state < "$connector"
        [ "$connector_state" = "connected" ] && printf '%s\n' "$connector"
    done | sort
}

previous=$(connected_outputs)

while IFS= read -r _; do
    # Coalesce the burst of events emitted while an output is initialized.
    while IFS= read -r -t 1 _; do
        :
    done

    current=$(connected_outputs)
    [ "$current" = "$previous" ] && continue
    previous=$current

    profile=$(kanshictl status 2>/dev/null | sed -n 's/^Current profile: //p')
    if [ "$profile" = "solo_laptop" ]; then
        echo "Physical output connection changed; reapplying solo_laptop"
        kanshictl switch solo_laptop
    fi
# Do not let the long-lived swaymsg child inherit the singleton lock.
done < <(exec 9>&-; swaymsg -t subscribe -m '["output"]')
