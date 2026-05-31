#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Uninstall Script
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_error_section "UNINSTALL SSH TUNNEL MANAGER"
echo ""

echo -e "${RED}⚠️  WARNING: This will remove the SSH Tunnel Manager!${NC}"
echo ""
echo -e "${YELLOW}The following will be removed:${NC}"
echo -e "${YELLOW}◈ Manager scripts and configuration${NC}"
echo -e "${YELLOW}◈ Menu command from /usr/local/bin${NC}"
echo ""
echo -ne "${RED}ARE YOU SURE ${YELLOW}? [y/n]:${WHITE} "
read resp

[[ "$resp" = 'y' ]] && {
    echo -e "\n${GREEN}◇ Removing SSH Tunnel Manager...${NC}\n"
    
    fun_uninstall() {
        # Remove menu command
        rm -f /usr/local/bin/menu /bin/menu /bin/h
        
        # Remove autostart entries
        [[ -f /etc/autostart ]] && rm -f /etc/autostart
        
        # Remove auto-execution from profile
        sed -i '/menu;/d' /etc/profile 2>/dev/null
        
        # Remove manager license
        rm -f /usr/lib/sshtunnelmanager
        
        # Remove manager directory
        rm -rf /etc/SSHTunnelManager
    }
    fun_bar 'fun_uninstall'
    
    echo -e "\n${GREEN}◇ SSH TUNNEL MANAGER REMOVED SUCCESSFULLY!${NC}"
    echo -e "${YELLOW}◇ Note: Users and services were NOT removed.${NC}"
    sleep 3
    clear
    exit 0
} || {
    echo -e "\n${RED}◇ Uninstall cancelled.${NC}"
    sleep 2
}
