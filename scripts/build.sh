#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "==> Building on device..."
$SSH "cd $IPAD_PROJECT && clang -arch armv7 \
  -isysroot $IPAD_SDK \
  -miphoneos-version-min=6.0 \
  -fobjc-arc \
  -framework UIKit \
  -framework Foundation \
  -framework CoreGraphics \
  -framework QuartzCore \
  -o $APP_NAME \
  *.m 2>&1"
echo "==> Build complete."
