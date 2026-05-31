#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Change Root Password
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_section "CHANGE ROOT PASSWORD"
echo ""

echo -ne "${GREEN}Enter new root password:${WHITE} "
read -s newpass
echo ""
echo -ne "${GREEN}Confirm new root password:${WHITE} "
read -s confirmpass
echo ""

[[ -z "$newpass" ]] && {
    echo -e "\n${BG_RED} Password cannot be empty! ${NC}"
    exit 1
}
[[ "$newpass" != "$confirmpass" ]] && {
    echo -e "\n${BG_RED} Passwords do not match! ${NC}"
    exit 1
}

echo "root:$newpass" | chpasswd

echo -e "\n${GREEN}◇ Root password changed successfully!${NC}"
