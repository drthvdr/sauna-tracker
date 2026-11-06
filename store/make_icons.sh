#!/bin/bash
# Regenerates every icon from the SVG sources in this folder (macOS: it uses sips).
#
#   store/icon-500.png, icon-128-24bit.png, icon-128-64color.png   the store icons
#   resources*/drawables/launcher_icon.png                         the small icon on each watch
#
# icon.svg is the full-color art, icon-lowcolor.svg the 64-color version for memory-in-pixel
# watches, and icon-mono.svg the one-bit version for the Instinct's launcher icon.
set -euo pipefail
cd "$(dirname "$0")"

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP:?}"' EXIT

sips -s format png icon.svg --out icon-500.png >/dev/null
sips -s format png icon-lowcolor.svg --out "$TMP/low500.png" >/dev/null
sips -s format png icon-mono.svg --out "$TMP/mono500.png" >/dev/null

# The two 128px on-device store icons.
sips -z 128 128 icon-500.png --out "$TMP/full128.png" >/dev/null
sips -z 128 128 "$TMP/low500.png" --out "$TMP/low128.png" >/dev/null
python3 -I device_icons.py "$TMP/full128.png" "$TMP/low128.png" .

# Launcher icons, each at the size the watch asks for.
sips -z 65 65 icon-500.png --out ../resources-fr965/drawables/launcher_icon.png >/dev/null
sips -z 56 56 icon-500.png --out ../resources-vivoactive5/drawables/launcher_icon.png >/dev/null
sips -z 60 60 icon-500.png --out ../resources-fr265s/drawables/launcher_icon.png >/dev/null
sips -z 54 54 icon-500.png --out ../resources-fr165/drawables/launcher_icon.png >/dev/null   # also used by the 165 Music
sips -z 62 62 "$TMP/mono500.png" --out "$TMP/mono62.png" >/dev/null
python3 -I device_icons.py --mono "$TMP/mono62.png" ../resources/drawables/launcher_icon.png
