#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - VPS Optimize
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_section "VPS OPTIMIZATION"
echo ""

echo -e "${YELLOW}This will optimize your VPS with the following:${NC}"
echo ""
echo -e "${GREEN}◈ Clean package cache"
echo -e "${GREEN}◈ Clean temporary files"
echo -e "${GREEN}◈ Optimize network settings"
echo -e "${GREEN}◈ Clear system logs${NC}"
echo ""
echo -ne "${GREEN}DO YOU WISH TO CONTINUE ${RED}? ${YELLOW}[y/n]:${WHITE} "
read resp

[[ "$resp" != 'y' ]] && { echo -e "\n${RED}Returning...${NC}"; exit 0; }

echo ""
echo -e "${GREEN}◇ Cleaning package cache...${NC}"
fun_clean() {
    apt-get autoremove -y >/dev/null 2>&1
    apt-get autoclean -y >/dev/null 2>&1
    apt-get clean >/dev/null 2>&1
}
fun_bar 'fun_clean'

echo -e "${GREEN}◇ Cleaning temporary files...${NC}"
fun_tmp() {
    rm -rf /tmp/* >/dev/null 2>&1
    rm -rf /var/tmp/* >/dev/null 2>&1
}
fun_bar 'fun_tmp'

echo -e "${GREEN}◇ Optimizing network settings...${NC}"
fun_net() {
    # TCP optimization
    cat > /tmp/sysctl_opt.conf << 'SYSEOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.core.somaxconn=4096
net.ipv4.tcp_max_syn_backlog=4096
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.ip_local_port_range=1024 65535
SYSEOF
    
    # Only add settings not already present
    while IFS= read -r line; do
        key=$(echo "$line" | cut -d= -f1)
        if ! grep -q "^${key}" /etc/sysctl.conf 2>/dev/null; then
            echo "$line" >> /etc/sysctl.conf
        fi
    done < /tmp/sysctl_opt.conf
    rm -f /tmp/sysctl_opt.conf
    sysctl -p >/dev/null 2>&1
}
fun_bar 'fun_net'

echo -e "${GREEN}◇ Clearing old system logs...${NC}"
fun_logs() {
    find /var/log -type f -name "*.gz" -delete 2>/dev/null
    find /var/log -type f -name "*.1" -delete 2>/dev/null
    journalctl --vacuum-time=7d >/dev/null 2>&1
}
fun_bar 'fun_logs'

echo -e "\n${GREEN}◇ VPS OPTIMIZATION COMPLETED!${NC}"
