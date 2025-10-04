#!/usr/bin/env bash
# Usage: set-brightness.sh <brightness>
# brightness: float between 0.1 and 1.0 (example limits)

set -euo pipefail

# Default limits
MIN=0.1
MAX=1.0

# Read arg (use 2nd check to avoid empty string)
if [ $# -lt 1 ]; then
  echo "Usage: $0 <brightness>" >&2
  exit 2
fi

BRIGHTNESS_RAW="$1"

# Validate numeric (allow integers and decimals, optional leading dot)
if ! [[ $BRIGHTNESS_RAW =~ ^[0-9]*\.?[0-9]+$ ]]; then
  echo "Error: brightness must be a number (e.g. 0.7)" >&2
  exit 2
fi

# Convert to float using awk for safe comparison
BRIGHTNESS=$(awk -v v="$BRIGHTNESS_RAW" 'BEGIN{printf "%.3f", v}')

# Clamp
CLAMPED=$(awk -v v="$BRIGHTNESS" -v lo="$MIN" -v hi="$MAX" 'BEGIN{if(v<lo) v=lo; if(v>hi) v=hi; printf "%.3f", v}')

# Apply to all connected outputs
for OUT in $(xrandr --query | awk '/ connected/{print $1}'); do
  cmd="xrandr --output "$OUT" --brightness $CLAMPED"
  $cmd
done

