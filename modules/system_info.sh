#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - System Info / Details
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

IP=$(get_server_ip)

clear
print_section "VPS INFORMATION"
echo ""

# System info
system=$(get_system_info)
kernel=$(uname -r)
arch=$(uname -m)
hostname=$(hostname)
uptime=$(uptime -p)

# RAM
ram_total=$(free -h | grep -i mem | awk '{print $2}')
ram_used=$(free -h | grep -i mem | awk '{print $3}')
ram_free=$(free -h | grep -i mem | awk '{print $4}')

# Disk
disk_total=$(df -h / | awk 'NR==2{print $2}')
disk_used=$(df -h / | awk 'NR==2{print $3}')
disk_free=$(df -h / | awk 'NR==2{print $4}')
disk_perc=$(df -h / | awk 'NR==2{print $5}')

# CPU
cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
cpu_cores=$(grep -c cpu[0-9] /proc/stat)
cpu_usage=$(top -bn1 | awk '/Cpu/ { cpu = "" 100 - $8 "%" }; END { print cpu }')

# Network
total_users=$(get_total_users)
online_users=$(get_online_ssh_users)

echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
echo -e "${GREEN}◈ SYSTEM INFORMATION${NC}"
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
echo -e "${GREEN}◈ OS:         ${WHITE}$system"
echo -e "${GREEN}◈ Kernel:     ${WHITE}$kernel"
echo -e "${GREEN}◈ Arch:       ${WHITE}$arch"
echo -e "${GREEN}◈ Hostname:   ${WHITE}$hostname"
echo -e "${GREEN}◈ IP:         ${WHITE}$IP"
echo -e "${GREEN}◈ Uptime:     ${WHITE}$uptime"
echo ""
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
echo -e "${GREEN}◈ CPU INFORMATION${NC}"
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
echo -e "${GREEN}◈ Model:      ${WHITE}$cpu_model"
echo -e "${GREEN}◈ Cores:      ${WHITE}$cpu_cores"
echo -e "${GREEN}◈ Usage:      ${WHITE}$cpu_usage"
echo ""
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
echo -e "${GREEN}◈ MEMORY${NC}"
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
echo -e "${GREEN}◈ RAM Total:  ${WHITE}$ram_total"
echo -e "${GREEN}◈ RAM Used:   ${WHITE}$ram_used"
echo -e "${GREEN}◈ RAM Free:   ${WHITE}$ram_free"
echo ""
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
echo -e "${GREEN}◈ DISK${NC}"
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
echo -e "${GREEN}◈ Total:      ${WHITE}$disk_total"
echo -e "${GREEN}◈ Used:       ${WHITE}$disk_used ($disk_perc)"
echo -e "${GREEN}◈ Free:       ${WHITE}$disk_free"
echo ""
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
echo -e "${GREEN}◈ USERS${NC}"
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
echo -e "${GREEN}◈ Total:      ${WHITE}$total_users"
echo -e "${GREEN}◈ Online:     ${WHITE}$online_users${NC}"
echo ""

# Services status
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
echo -e "${GREEN}◈ SERVICES${NC}"
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"

for svc in ssh sshd dropbear stunnel4 squid squid3 openvpn sslh apache2; do
    if systemctl is-active "$svc" >/dev/null 2>&1; then
        echo -e "${GREEN}◈ $svc: ${WHITE}RUNNING${NC}"
    elif service "$svc" status >/dev/null 2>&1; then
        echo -e "${GREEN}◈ $svc: ${WHITE}RUNNING${NC}"
    fi
done
