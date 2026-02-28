#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Devices: name host
DEVICES=(
    "iPad:192.168.1.117"
    "iPod:192.168.1.165"
    "iPad 8.4.1:192.168.1.160"
)

# Colors
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

# Find IPA: use argument or latest from builds/
if [ -n "$1" ]; then
    IPA_PATH="$1"
else
    IPA_PATH=$(ls -t "$DEST_DIR"/*.ipa 2>/dev/null | head -1)
fi

if [ -z "$IPA_PATH" ] || [ ! -f "$IPA_PATH" ]; then
    echo -e "${RED}Error: No IPA found. Pass a path or run install.sh first.${RESET}"
    exit 1
fi

IPA_NAME=$(basename "$IPA_PATH")
REMOTE_PATH="/tmp/$IPA_NAME"

echo -e "${BOLD}${CYAN}==> Installing ${IPA_NAME} on ${#DEVICES[@]} devices${RESET}"
echo ""

# Prefix every line of stdin with the device name tag
tag() {
    local name=$1
    while IFS= read -r line; do
        echo -e "  ${BOLD}[${name}]${RESET} $line"
    done
}

install_on_device() {
    local name=$1
    local host=$2
    local start=$(date +%s)

    echo "${DIM}($host)${RESET} Sending IPA..."
    sshpass -p "$IPAD_PASS" scp -o StrictHostKeyChecking=no \
        "$IPA_PATH" "${IPAD_USER}@${host}:${REMOTE_PATH}" 2>&1

    echo "Installing..."
    sshpass -p "$IPAD_PASS" ssh -o StrictHostKeyChecking=no \
        "${IPAD_USER}@${host}" "ipainstaller -f ${REMOTE_PATH} 2>&1; rm -f ${REMOTE_PATH}" 2>&1

    local elapsed=$(( $(date +%s) - start ))
    echo "${GREEN}Done${RESET} ${DIM}(${elapsed}s)${RESET}"
}

# Run all devices in parallel, streaming output with device tags
PIDS=()
STATUS_FILES=()
for entry in "${DEVICES[@]}"; do
    name="${entry%%:*}"
    host="${entry##*:}"
    STATUS_FILE=$(mktemp)
    STATUS_FILES+=("$name:$STATUS_FILE")
    (
        install_on_device "$name" "$host" 2>&1 | tag "$name"
        echo "${PIPESTATUS[0]}" > "$STATUS_FILE"
    ) &
    PIDS+=($!)
done

# Wait for all and check results
FAILED=0
for i in "${!PIDS[@]}"; do
    wait "${PIDS[$i]}" || true
    info=${STATUS_FILES[$i]}
    name="${info%%:*}"
    sf="${info##*:}"
    exit_code=$(cat "$sf" 2>/dev/null)
    rm -f "$sf"
    if [ "${exit_code:-1}" -ne 0 ]; then
        echo -e "  ${BOLD}[$name]${RESET} ${RED}FAILED${RESET}"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
if [ $FAILED -eq 0 ]; then
    echo -e "${BOLD}${GREEN}All devices installed successfully.${RESET}"
else
    echo -e "${BOLD}${RED}${FAILED} device(s) failed.${RESET}"
    exit 1
fi
