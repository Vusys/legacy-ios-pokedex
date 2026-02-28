#!/bin/bash
# Resize icon-org.png into all iOS 6 icon sizes needed by the app.
# Requires ImageMagick (convert).

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE="$PROJECT_DIR/icon-org.png"
DEST="$PROJECT_DIR/src/icons"

if [ ! -f "$SOURCE" ]; then
    echo "Error: $SOURCE not found"
    exit 1
fi

if ! command -v convert &>/dev/null; then
    echo "Error: ImageMagick is required (install with: pacman -S imagemagick)"
    exit 1
fi

mkdir -p "$DEST"

declare -A sizes=(
    ["Icon-57.png"]=57
    ["Icon-57@2x.png"]=114
    ["Icon-72.png"]=72
    ["Icon-72@2x.png"]=144
)

for name in "${!sizes[@]}"; do
    size="${sizes[$name]}"
    echo "Generating $name (${size}x${size})..."
    convert "$SOURCE" -resize "${size}x${size}" -quality 100 "$DEST/$name"
done

echo "Done. Icons written to $DEST/"
