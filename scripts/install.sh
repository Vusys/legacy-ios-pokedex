#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Auto-increment build number
BUILDNUM_FILE="$SCRIPT_DIR/../.buildnum"
if [ -f "$BUILDNUM_FILE" ]; then
    BUILD=$(cat "$BUILDNUM_FILE")
else
    BUILD=1
fi
BUILD=$((BUILD + 1))
echo "$BUILD" > "$BUILDNUM_FILE"
echo "==> Build #${BUILD}"

echo "==> Packaging IPA..."
$SSH "cd $IPAD_PROJECT && \
  ldid -S $APP_NAME && \
  rm -rf Payload ${APP_NAME}.ipa && \
  mkdir -p Payload/${APP_NAME}.app && \
  cp $APP_NAME Payload/${APP_NAME}.app/ && \
  cp Info.plist Payload/${APP_NAME}.app/ && \
  cp icons/*.png Payload/${APP_NAME}.app/ 2>/dev/null; \
  cp -r data Payload/${APP_NAME}.app/ 2>/dev/null; \
  cp -r sprites Payload/${APP_NAME}.app/ 2>/dev/null; \
  cd $IPAD_PROJECT && \
  zip -qr ${APP_NAME}.ipa Payload/ && \
  rm -rf Payload"

echo "==> Installing..."
$SSH "ipainstaller -f $IPAD_PROJECT/${APP_NAME}.ipa 2>&1 || true"
echo "==> Done. Build #${BUILD} installed."
