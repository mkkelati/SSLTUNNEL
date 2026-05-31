#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Remove Host DNS
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_section "REMOVE DNS HOST"
echo ""

echo -e "${YELLOW}Current hosts:${NC}"
echo ""
i=0
unset oP
for _host in $(grep -w "127.0.0.1" /etc/hosts | grep -v "localhost" | cut -d' ' -f2); do
    i=$(expr $i + 1)
    oP+="${i}:${_host}\n"
    [[ $i == [1-9] ]] && di=0$i || di=$i
    echo -e "${YELLOW}[${RED}$di${YELLOW}] ${WHITE}- ${GREEN}$_host${NC}"
done

[[ $i -eq 0 ]] && {
    echo -e "${YELLOW}No custom hosts found!${NC}"
    exit 0
}

echo ""
echo -ne "${GREEN}Select the host to remove ${YELLOW}[${WHITE}1${RED}-${WHITE}$i${YELLOW}]:${WHITE} "
read option

[[ -z "$option" ]] && {
    echo -e "\n${BG_RED} Invalid option! ${NC}"
    exit 1
}

host=$(echo -e "$oP" | grep -E "^$option:" | cut -d: -f2)
[[ -z "$host" ]] && {
    echo -e "\n${BG_RED} Invalid option! ${NC}"
    exit 1
}

hst=$(grep -v "127.0.0.1 $host" /etc/hosts)
echo "$hst" > /etc/hosts

echo -e "\n${GREEN}◇ Host ${WHITE}$host ${GREEN}removed successfully!${NC}"
