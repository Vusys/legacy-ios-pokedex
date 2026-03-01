#!/bin/bash
set -eo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Devices: name host
DEVICES=(
    "iPad 4 (6.1.3):192.168.1.117"
    "iPod 5 (6.1.3):192.168.1.165"
#    "iPad mini (8.4.1):192.168.1.160"
#    "iPhone 4S (6.1.3):192.168.1.145"
)

# Colors
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
DIM=$'\033[2m'
RESET=$'\033[0m'

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

export BOLD GREEN RED CYAN DIM RESET
export IPA_PATH IPAD_USER IPAD_PASS REMOTE_PATH

install_on_device() {
    local entry=$1
    local name="${entry%%:*}"
    local host="${entry##*:}"
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
export -f install_on_device

# Run all devices in parallel (kills cleanly with the script)
printf '%s\n' "${DEVICES[@]}" | parallel --will-cite --line-buffer --halt now,fail=1 --tagstring '  '"${BOLD}"'[{= s/:.*// =}]'"${RESET}" \
    'install_on_device {}' \
    && { echo ""; echo -e "${BOLD}${GREEN}All devices installed successfully.${RESET}"; } \
    || { echo ""; echo -e "${BOLD}${RED}Some device(s) failed.${RESET}"; exit 1; }
