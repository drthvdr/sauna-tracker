#!/bin/bash
# Build for the Instinct 3 Solar. Needs the Connect IQ SDK (installed with the
# SDK Manager) and a developer key (default: ~/.garmin/developer_key.der).
#
#   ./build.sh        compile to bin/SaunaTracker.prg
#   ./build.sh run    compile, then run in the Connect IQ simulator
set -euo pipefail
cd "$(dirname "$0")"

DEVICE=instinct3solar45mm
SDK="$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"
KEY="${CIQ_KEY:-$HOME/.garmin/developer_key.der}"

mkdir -p bin
"$SDK/bin/monkeyc" -d "$DEVICE" -f monkey.jungle -o bin/SaunaTracker.prg -y "$KEY" -w

if [ "${1:-}" = "run" ]; then
    open "$SDK/bin/ConnectIQ.app" 2>/dev/null || "$SDK/bin/connectiq" &
    sleep 3
    "$SDK/bin/monkeydo" bin/SaunaTracker.prg "$DEVICE"
fi
