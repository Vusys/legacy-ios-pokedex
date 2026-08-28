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
# it tries at -o7 -- unreadable at thousands of files. So: capture each
# job's output ourselves and only print it when that file actually fails
# (corrupt/truncated download, animated PNG, etc.) -- a real reason instead
# of a bare exit code, and a one-line "[N/total] path" otherwise for
# progress (parallel's --bar/--progress try to write terminal control codes
# to /dev/tty, which doesn't exist in CI or other non-interactive shells).
#
# A handful of unoptimizable sprites isn't worth failing the whole build
# over -- optipng leaves a failed file untouched, so it just ships as
# whatever process.php produced. set +e/-e brackets only this command so a
# nonzero exit here (parallel returns the number of failed jobs) doesn't
# trip `set -e` and abort the script.
set +e
find "$SPRITES_DIR" -name '*.png' -print0 \
    | parallel -0 -j "$JOBS" '
        out=$(optipng -o7 -strip all "{}" 2>&1)
        rc=$?
        if [ "$rc" -eq 0 ]; then
            echo "[{#}/'"$COUNT"'] {}"
        else
            printf "[{#}/'"$COUNT"'] FAILED (exit %s): {}\n%s\n" "$rc" "$out" >&2
        fi
        exit "$rc"
    '
FAILED="$?"
set -e

AFTER="$(du -sk "$SPRITES_DIR" | cut -f1)"
echo "Done. $SPRITES_DIR: $((BEFORE / 1024))MB -> $((AFTER / 1024))MB"

if [ "$FAILED" -gt 0 ] && [ "$FAILED" -eq "$COUNT" ]; then
    echo "::error::All $COUNT sprites failed to optimize -- optipng/parallel setup is likely broken." >&2
    exit 1
elif [ "$FAILED" -gt 0 ]; then
    echo "::warning::$FAILED of $COUNT sprite(s) failed to optimize -- left unmodified, see FAILED lines above." >&2
fi
