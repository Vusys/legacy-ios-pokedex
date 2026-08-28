#!/bin/bash
# optimize-sprites.sh - Losslessly recompress every generated sprite PNG with
# optipng at max settings, in parallel across all available cores.
#
# Run this after tools/process.php regenerates src/sprites/ from freshly
# downloaded PokeAPI images. -o7 is slow (optipng tries up to 240 filter/
# compression combinations per file) but this only needs to run when sprites
# actually change, and the output is pixel-identical -- just smaller.
set -euo pipefail

cd "$(dirname "$0")/.."

SPRITES_DIR="src/sprites"

if ! command -v optipng >/dev/null 2>&1; then
    echo "optipng not found -- install it first (e.g. apt-get install optipng / brew install optipng)." >&2
    exit 1
fi

if ! command -v parallel >/dev/null 2>&1; then
    echo "GNU parallel not found -- install it first (e.g. apt-get install parallel / brew install parallel)." >&2
    exit 1
fi

if [ ! -d "$SPRITES_DIR" ]; then
    echo "No $SPRITES_DIR directory found -- run tools/process.php first." >&2
    exit 1
fi

# nproc covers Linux (dev box, GHA runner); fall back for other platforms.
JOBS="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"

BEFORE="$(du -sk "$SPRITES_DIR" | cut -f1)"
COUNT="$(find "$SPRITES_DIR" -name '*.png' | wc -l)"
echo "Optimizing $COUNT PNGs in $SPRITES_DIR with optipng -o7 ($JOBS parallel jobs)..."

# optipng's default (non -quiet) output dumps every filter/compression trial
# it tries at -o7 -- unreadable at thousands of files. -quiet plus one echo
# per completed job gives real progress without that noise or needing a tty
# (parallel's --bar/--progress try to write terminal control codes to
# /dev/tty, which doesn't exist in CI or other non-interactive shells).
find "$SPRITES_DIR" -name '*.png' -print0 \
    | parallel -0 -j "$JOBS" 'optipng -o7 -strip all -quiet {} && echo "[{#}/'"$COUNT"'] {}"'

AFTER="$(du -sk "$SPRITES_DIR" | cut -f1)"
echo "Done. $SPRITES_DIR: $((BEFORE / 1024))MB -> $((AFTER / 1024))MB"
