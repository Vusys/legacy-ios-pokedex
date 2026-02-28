#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

TOTAL_STEPS=3
DEPLOY_START=$(date +%s)

step() {
    local step_num=$1
    local label=$2
    echo ""
    echo -e "${BOLD}${CYAN}[$step_num/$TOTAL_STEPS]${RESET} ${BOLD}$label${RESET}"
}

elapsed() {
    local start=$1
    local end=$(date +%s)
    local secs=$((end - start))
    echo "${secs}s"
}

STEP_START=$(date +%s)
step 1 "Syncing source to iPad..."
"$SCRIPT_DIR/sync.sh"
echo -e "${DIM}    Sync finished in $(elapsed $STEP_START)${RESET}"

STEP_START=$(date +%s)
step 2 "Compiling on device..."
"$SCRIPT_DIR/build.sh"
echo -e "${DIM}    Build finished in $(elapsed $STEP_START)${RESET}"

STEP_START=$(date +%s)
step 3 "Packaging & installing..."
"$SCRIPT_DIR/install.sh"
echo -e "${DIM}    Install finished in $(elapsed $STEP_START)${RESET}"

echo ""
echo -e "${BOLD}${GREEN}Deploy complete${RESET} ${DIM}(total: $(elapsed $DEPLOY_START))${RESET}"
