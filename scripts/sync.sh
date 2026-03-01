#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "==> Syncing source to iPad..."

# Clean previous source on iPad
$SSH "rm -rf $IPAD_PROJECT"
$SSH "mkdir -p $IPAD_PROJECT"

# Sync all .h and .m files (flat in src/)
cd "$SCRIPT_DIR/../src"
tar cf - *.h *.m Info.plist 2>/dev/null | $SSH "cd $IPAD_PROJECT && tar xf -"

# Sync icons
if [ -d icons ]; then
    tar cf - icons/ | $SSH "cd $IPAD_PROJECT && tar xf -"
fi

# Sync data directory (plists)
if [ -d data ]; then
    tar cf - data/ | $SSH "cd $IPAD_PROJECT && tar xf -"
fi

# Sync sprites
if [ -d sprites ]; then
    tar cf - sprites/ | $SSH "cd $IPAD_PROJECT && tar xf -"
fi

# Sync textures
if [ -d textures ]; then
    tar cf - textures/ | $SSH "cd $IPAD_PROJECT && tar xf -"
fi

echo "==> Sync complete."
