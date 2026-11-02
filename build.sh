#!/bin/bash
# Build for the Instinct 3 Solar by default, or another device from the manifest.
# Needs the Connect IQ SDK (installed with the SDK Manager) and a developer key
# (default: ~/.garmin/developer_key.der).
#
#   ./build.sh                  compile for the Instinct 3 Solar to bin/SaunaTracker.prg
#   ./build.sh run              compile, then run in the Connect IQ simulator
#   DEVICE=fr965 ./build.sh     compile for another device to bin/SaunaTracker-fr965.prg
#   DEVICE=fr965 ./build.sh run compile for that device and run it in the simulator
set -euo pipefail
cd "$(dirname "$0")"

DEVICE="${DEVICE:-instinct3solar45mm}"
SDK="$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"
KEY="${CIQ_KEY:-$HOME/.garmin/developer_key.der}"

if [ "$DEVICE" = "instinct3solar45mm" ]; then
    OUT=bin/SaunaTracker.prg
else
    OUT="bin/SaunaTracker-$DEVICE.prg"
fi

mkdir -p bin
"$SDK/bin/monkeyc" -d "$DEVICE" -f monkey.jungle -o "$OUT" -y "$KEY" -w

if [ "${1:-}" = "run" ]; then
    open "$SDK/bin/ConnectIQ.app" 2>/dev/null || "$SDK/bin/connectiq" &
    sleep 3
    "$SDK/bin/monkeydo" "$OUT" "$DEVICE"
fi
