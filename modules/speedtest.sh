#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Speedtest
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_section "TESTING SERVER SPEED"
echo ""

fun_tst() {
    speedtest --share > /tmp/speed 2>/dev/null || speedtest-cli --share > /tmp/speed 2>/dev/null
}

fun_bar 'fun_tst'
echo ""

if [[ -f /tmp/speed ]]; then
    png=$(cat /tmp/speed | grep -i "ping" | awk -F: '{print $NF}' | xargs)
    down=$(cat /tmp/speed | grep -i "download" | awk -F: '{print $NF}' | xargs)
    upl=$(cat /tmp/speed | grep -i "upload" | awk -F: '{print $NF}' | xargs)
    lnk=$(cat /tmp/speed | grep -i "share" | awk '{print $NF}' | xargs)

    echo -e "${BLUE}◇─────────────────────────────────────────◇${NC}"
    echo -e "${GREEN}◇ PING (LATENCY):${WHITE} $png"
    echo -e "${GREEN}◇ DOWNLOAD:${WHITE} $down"
    echo -e "${GREEN}◇ UPLOAD:${WHITE} $upl"
    [[ -n "$lnk" ]] && echo -e "${GREEN}◇ LINK: ${CYAN}$lnk${NC}"
    echo -e "${BLUE}◇─────────────────────────────────────────◇${NC}"
    rm -f /tmp/speed
else
    echo -e "${RED}Speedtest failed! Make sure speedtest-cli is installed.${NC}"
    echo -e "${YELLOW}Install with: pip install speedtest-cli${NC}"
fi
