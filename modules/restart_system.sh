#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Restart System
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_section "RESTART SYSTEM"
echo ""

echo -ne "${YELLOW}ARE YOU SURE YOU WANT TO RESTART THE SYSTEM ${RED}? ${YELLOW}[y/n]:${WHITE} "
read resp

[[ "$resp" = 'y' ]] && {
    echo -e "\n${GREEN}◇ SYSTEM WILL RESTART IN 5 SECONDS...${NC}"
    sleep 5
    reboot
} || {
    echo -e "\n${RED}◇ Returning...${NC}"
    sleep 2
}
