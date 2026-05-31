#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Create SSH User
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root
ensure_dirs

IP=$(get_server_ip)

print_section "CREATE SSH USER"
echo ""

# Username
echo -ne "${GREEN}Username:${WHITE} "
read username
validate_username "$username" || exit 1

# Password
echo -ne "${GREEN}Password:${WHITE} "
read password
validate_password "$password" || exit 1

# Days to expire
echo -ne "${GREEN}Days to expire:${WHITE} "
read dias
[[ -z "$dias" ]] && {
    echo -e "\n${BG_RED} Number of days empty! ${NC}\n"
    exit 1
}
[[ ${dias} != ?(+|-)+([0-9]) ]] && {
    echo -e "\n${BG_RED} Invalid number of days! ${NC}\n"
    exit 1
}
[[ $dias -lt 1 ]] && {
    echo -e "\n${BG_RED} Number must be greater than zero! ${NC}\n"
    exit 1
}

# Connection limit
echo -ne "${GREEN}Connection limit:${WHITE} "
read sshlimiter
[[ -z "$sshlimiter" ]] && {
    echo -e "\n${BG_RED} Connection limit empty! ${NC}\n"
    exit 1
}
[[ ${sshlimiter} != ?(+|-)+([0-9]) ]] && {
    echo -e "\n${BG_RED} Invalid connection limit! ${NC}\n"
    exit 1
}
[[ $sshlimiter -lt 1 ]] && {
    echo -e "\n${BG_RED} Connection limit must be greater than zero! ${NC}\n"
    exit 1
}

# Create the user
final=$(date "+%Y-%m-%d" -d "+$dias days")
gui=$(date "+%d/%m/%Y" -d "+$dias days")
pass=$(perl -e 'print crypt($ARGV[0], "password")' "$password")
useradd -e "$final" -M -s /bin/false -p "$pass" "$username" >/dev/null 2>&1

# Store password and user database entry
echo "$password" > "$PASSWD_DIR/$username"
echo "$username $sshlimiter" >> "$USER_DB"

# Display account info
clear
echo -e "${GREEN}===================================="
echo -e "${GREEN}     SSH TUNNEL MANAGER"
echo -e "${GREEN}===================================="
echo ""
echo -e "${RED}◈─────⪧ IMPORTANT ⪦──────◈"
echo ""
echo -e "${GREEN}◈⪧ 🚫 NO SPAM"
echo -e "${GREEN}◈⪧ ⚠️  NO DDOS"
echo -e "${GREEN}◈⪧ 🎭 NO Hacking"
echo -e "${GREEN}◈⪧ ⛔️ NO Carding"
echo -e "${GREEN}◈⪧ 🙅‍♂️ NO Torrent"
echo -e "${GREEN}◈⪧ ❌ NO MultiLogin"
echo -e "${GREEN}◈⪧ 🤷‍♂️ NO Illegal Activities"
echo ""
echo -e "${WHITE}◈─────⪧ SSH ACCOUNT ⪦─────◈"
echo ""
echo -e "${GREEN}◈ Host / IP   :⪧  ${RED}$IP"
echo -e "${GREEN}◈ Username    :⪧  ${RED}$username"
echo -e "${GREEN}◈ Password    :⪧  ${RED}$password"
echo -e "${GREEN}◈ Login Limit :⪧  ${RED}$sshlimiter"
echo -e "${GREEN}◈ Expire Date :⪧  ${RED}$gui"
echo ""
echo -e "${WHITE}◈──────⪧ PORTS ⪦ ───────◈"
echo ""
echo -e "${GREEN}◈ SSH      ⌁  22"
[[ -e /etc/stunnel/stunnel.conf ]] && echo -e "${GREEN}◈ SSL      ⌁  $(netstat -nplt 2>/dev/null | grep stunnel | awk '{print $4}' | cut -d: -f2 | head -1)"
[[ -e /etc/default/dropbear ]] && echo -e "${GREEN}◈ DropBear ⌁  $(grep 'DROPBEAR_PORT=' /etc/default/dropbear | cut -d'=' -f2)"
echo ""
echo -e "${WHITE}◈───⪧ ONLINE USER COUNT ⪦────◈"
echo ""
echo -e "${GREEN}http://$IP:8888/server/online"
echo ""
echo -e "${WHITE}◈─────────────────────────────────◈"
echo -e "${WHITE}©️   SSH TUNNEL MANAGER SCRIPT"
echo -e "${WHITE}◈─────────────────────────────────◈${NC}"
