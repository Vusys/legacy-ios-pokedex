#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/sync.sh"
"$SCRIPT_DIR/build.sh"
"$SCRIPT_DIR/install.sh"
