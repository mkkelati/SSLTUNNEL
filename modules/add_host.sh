#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Add Host DNS
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_section "ADD DNS HOST"
echo ""

echo -e "${YELLOW}Current hosts:${NC}"
echo ""
for _host in $(grep -w "127.0.0.1" /etc/hosts | grep -v "localhost" | cut -d' ' -f2); do
    echo -e "${GREEN}$_host${NC}"
done

echo ""
echo -ne "${YELLOW}Enter the host to add${WHITE}: "
read host

[[ -z "$host" ]] && {
    echo -e "\n${BG_RED} Empty or invalid field! ${NC}"
    exit 1
}

if [[ "$(grep -w "$host" /etc/hosts | wc -l)" -gt "0" ]]; then
    echo -e "\n${BG_RED} This host is already added! ${NC}"
    exit 1
fi

sed -i "3i\\127.0.0.1 $host" /etc/hosts

echo -e "\n${GREEN}◇ Host added successfully!${NC}"
