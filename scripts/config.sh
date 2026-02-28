#!/bin/bash
IPAD_HOST="192.168.1.147"
IPAD_USER="mobile"
IPAD_PASS="alpine"
IPAD_PROJECT="/var/mobile/Pokedex"
IPAD_SDK="/var/sdk"
APP_NAME="Pokedex"
BUNDLE_ID="com.vusys.pokedex"
VERSION="1.4"

# Host destination for built IPAs
DEST_DIR="$(cd "$(dirname "$0")/.." && pwd)/builds"

SSH_CMD="sshpass -p $IPAD_PASS ssh -o StrictHostKeyChecking=no"
SCP_CMD="sshpass -p $IPAD_PASS scp -o StrictHostKeyChecking=no"
SSH="$SSH_CMD ${IPAD_USER}@${IPAD_HOST}"
SSH_ROOT="$SSH_CMD root@${IPAD_HOST}"
