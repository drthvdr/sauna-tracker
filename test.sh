#!/bin/bash
# Runs the unit tests in the Connect IQ simulator, once for each watch.
#
#   ./test.sh              every watch listed in manifest.xml
#   ./test.sh fr965        only the watches named
#
# Needs the Connect IQ SDK and a developer key, like build.sh. The tests use the simulator
# window, so don't leave another app running in it. monkeydo exits with 1 even when every
# test passes, so the result is read from its output instead of its exit code.
set -uo pipefail
cd "$(dirname "$0")"

SDK="$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"
KEY="${CIQ_KEY:-$HOME/.garmin/developer_key.der}"

if [ "$#" -gt 0 ]; then
    DEVICES=("$@")
else
    DEVICES=($(grep -o 'iq:product id="[^"]*"' manifest.xml | cut -d'"' -f2))
fi

# The simulator listens on port 1234; start it if it isn't running.
if ! nc -z 127.0.0.1 1234 2>/dev/null; then
    open "$SDK/bin/ConnectIQ.app" 2>/dev/null || "$SDK/bin/connectiq" &
    for _ in $(seq 1 30); do
        nc -z 127.0.0.1 1234 2>/dev/null && break
        sleep 1
    done
fi

mkdir -p bin
failed=0
for device in "${DEVICES[@]}"; do
    echo "=== $device ==="
    prg="bin/test-$device.prg"
    log="bin/test-$device.log"

    if ! "$SDK/bin/monkeyc" -t -d "$device" -f monkey.jungle -o "$prg" -y "$KEY" -w; then
        echo "BUILD FAILED for $device"
        failed=1
        continue
    fi

    perl -e 'alarm 180; exec @ARGV' "$SDK/bin/monkeydo" "$prg" "$device" -t > "$log" 2>&1
    if grep -q '^PASSED' "$log" && grep -q '^Ran [1-9]' "$log"; then
        grep -E '^(Ran |PASSED)' "$log"
    else
        cat "$log"
        echo "TESTS FAILED for $device"
        failed=1
    fi
done

if [ "$failed" -eq 0 ]; then
    echo "All tests passed on: ${DEVICES[*]}"
else
    echo "Some tests failed."
fi
exit "$failed"
