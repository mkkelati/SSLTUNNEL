#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Restart Services
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_section "RESTART SERVICES"
echo ""

fun_restart() {
    service ssh restart 2>/dev/null
    [[ -e /etc/default/dropbear ]] && service dropbear restart 2>/dev/null
    [[ -e /etc/stunnel/stunnel.conf ]] && service stunnel4 restart 2>/dev/null
    [[ -d /etc/squid ]] && service squid restart 2>/dev/null
    [[ -d /etc/squid3 ]] && service squid3 restart 2>/dev/null
    [[ -e /etc/openvpn/server.conf ]] && service openvpn restart 2>/dev/null
    [[ "$(netstat -nltp 2>/dev/null | grep 'sslh' | wc -l)" != '0' ]] && service sslh restart 2>/dev/null
    service cron restart 2>/dev/null
}

echo -e "${GREEN}◇ Restarting all services...${NC}"
echo ""
fun_bar 'fun_restart'
echo -e "\n${GREEN}◇ ALL SERVICES RESTARTED SUCCESSFULLY!${NC}"
