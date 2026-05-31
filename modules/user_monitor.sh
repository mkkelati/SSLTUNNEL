#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Online User Monitor
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_section "ONLINE USER MONITOR"
echo ""

# SSH Users
echo -e "${YELLOW}◇ SSH CONNECTED USERS:${NC}"
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"

_userT=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody)
total_online=0

while read _user; do
    [[ -z "$_user" ]] && continue
    _online=$(ps -u "$_user" 2>/dev/null | grep -c "sshd")
    if [[ $_online -gt 0 ]]; then
        total_online=$(($total_online + $_online))
        echo -e "${GREEN}◈ ${WHITE}$_user ${YELLOW}- ${GREEN}$_online connection(s)${NC}"
    fi
done <<< "${_userT}"

[[ $total_online -eq 0 ]] && echo -e "${RED}  No SSH users online${NC}"

echo ""
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"

# Dropbear users
[[ -e /etc/default/dropbear ]] && {
    echo ""
    echo -e "${YELLOW}◇ DROPBEAR CONNECTED USERS:${NC}"
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    _drp=$(ps aux | grep dropbear | grep -v grep | grep -v "/usr/sbin" | wc -l)
    echo -e "${GREEN}◈ Dropbear connections: ${WHITE}$_drp${NC}"
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
}

# OpenVPN users
[[ -e /etc/openvpn/openvpn-status.log ]] && {
    echo ""
    echo -e "${YELLOW}◇ OPENVPN CONNECTED USERS:${NC}"
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    _onop=$(grep -c "10.8.0" /etc/openvpn/openvpn-status.log 2>/dev/null)
    echo -e "${GREEN}◈ OpenVPN connections: ${WHITE}$_onop${NC}"
    
    # List connected clients
    grep "10.8.0" /etc/openvpn/openvpn-status.log 2>/dev/null | while read line; do
        client_name=$(echo "$line" | cut -d',' -f1)
        client_ip=$(echo "$line" | cut -d',' -f2)
        [[ -n "$client_name" ]] && echo -e "  ${GREEN}◈ ${WHITE}$client_name ${YELLOW}(${WHITE}$client_ip${YELLOW})${NC}"
    done
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
}

echo ""
echo -e "${GREEN}◈ Total online: ${WHITE}$total_online${NC}"
