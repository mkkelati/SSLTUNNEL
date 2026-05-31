#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Create Test User
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root
ensure_dirs

IP=$(get_server_ip)

print_section "CREATE TEST USER"
echo ""

# Username
echo -ne "${GREEN}Username:${WHITE} "
read username
validate_username "$username" || exit 1

# Password
echo -ne "${GREEN}Password:${WHITE} "
read password
validate_password "$password" || exit 1

# Minutes for test account
echo -ne "${GREEN}Duration (minutes):${WHITE} "
read minutos
[[ -z "$minutos" ]] && {
    echo -e "\n${BG_RED} Duration is empty! ${NC}\n"
    exit 1
}
[[ ${minutos} != ?(+|-)+([0-9]) ]] && {
    echo -e "\n${BG_RED} Invalid duration! ${NC}\n"
    exit 1
}
[[ $minutos -lt 1 ]] && {
    echo -e "\n${BG_RED} Duration must be greater than zero! ${NC}\n"
    exit 1
}

# Create user with 1 day expiry
final=$(date "+%Y-%m-%d" -d "+1 days")
gui=$(date "+%d/%m/%Y %H:%M" -d "+$minutos minutes")
pass=$(perl -e 'print crypt($ARGV[0], "password")' "$password")
useradd -e "$final" -M -s /bin/false -p "$pass" "$username" >/dev/null 2>&1

# Store password and user database entry (limit 1 connection for test)
echo "$password" > "$PASSWD_DIR/$username"
echo "$username 1" >> "$USER_DB"

# Schedule automatic removal
(
    sleep $((minutos * 60))
    pkill -f "$username" >/dev/null 2>&1
    userdel --force "$username" >/dev/null 2>&1
    grep -v "^${username}[[:space:]]" "$USER_DB" > /tmp/ph
    cat /tmp/ph > "$USER_DB"
    rm -f "$PASSWD_DIR/$username"
) &

# Display account info
clear
echo -e "${GREEN}===================================="
echo -e "${GREEN}     SSH TUNNEL MANAGER - TEST"
echo -e "${GREEN}===================================="
echo ""
echo -e "${WHITE}◈─────⪧ TEST ACCOUNT ⪦─────◈"
echo ""
echo -e "${GREEN}◈ Host / IP   :⪧  ${RED}$IP"
echo -e "${GREEN}◈ Username    :⪧  ${RED}$username"
echo -e "${GREEN}◈ Password    :⪧  ${RED}$password"
echo -e "${GREEN}◈ Login Limit :⪧  ${RED}1"
echo -e "${GREEN}◈ Duration    :⪧  ${RED}$minutos minutes"
echo -e "${GREEN}◈ Expires at  :⪧  ${RED}$gui"
echo ""
echo -e "${WHITE}◈──────⪧ PORTS ⪦ ───────◈"
echo ""
echo -e "${GREEN}◈ SSH      ⌁  22"
[[ -e /etc/stunnel/stunnel.conf ]] && echo -e "${GREEN}◈ SSL      ⌁  $(netstat -nplt 2>/dev/null | grep stunnel | awk '{print $4}' | cut -d: -f2 | head -1)"
[[ -e /etc/default/dropbear ]] && echo -e "${GREEN}◈ DropBear ⌁  $(grep 'DROPBEAR_PORT=' /etc/default/dropbear | cut -d'=' -f2)"
echo ""
echo -e "${YELLOW}◈ This account will be automatically removed after $minutos minutes${NC}"
echo ""
echo -e "${WHITE}◈─────────────────────────────────◈"
echo -e "${WHITE}©️   SSH TUNNEL MANAGER SCRIPT"
echo -e "${WHITE}◈─────────────────────────────────◈${NC}"
