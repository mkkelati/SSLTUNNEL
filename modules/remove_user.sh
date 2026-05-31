#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Remove SSH User
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root
ensure_dirs

remove_ovp() {
    local user="$1"
    if [[ -e /etc/debian_version ]]; then
        GROUPNAME=nogroup
    fi
    (
        cd /etc/openvpn/easy-rsa/ 2>/dev/null
        ./easyrsa --batch revoke "$user" 2>/dev/null
        ./easyrsa gen-crl 2>/dev/null
        rm -rf "pki/reqs/${user}.req" "pki/private/${user}.key" "pki/issued/${user}.crt"
        rm -rf /etc/openvpn/crl.pem
        cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn 2>/dev/null
        chown nobody:$GROUPNAME /etc/openvpn/crl.pem 2>/dev/null
        [[ -e "$HOME/${user}.ovpn" ]] && rm "$HOME/${user}.ovpn"
        [[ -e "/var/www/html/openvpn/${user}.zip" ]] && rm "/var/www/html/openvpn/${user}.zip"
    ) >/dev/null 2>&1
}

print_section "REMOVE SSH USER"
echo ""
echo -e "${RED}[${CYAN}1${RED}]${YELLOW} REMOVE A USER"
echo -e "${RED}[${CYAN}2${RED}]${YELLOW} REMOVE ALL USERS"
echo -e "${RED}[${CYAN}3${RED}]${YELLOW} COME BACK"
echo ""
read -p "$(echo -e "${GREEN}◇ WHAT DO YOU WANT TO DO${RED} ?${WHITE} : ")" -e -i 1 resp

if [[ "$resp" = "1" ]]; then
    clear
    print_section "REMOVE SSH USER"
    echo ""
    echo -e "${YELLOW}◇ LIST OF USERS: ${NC}"
    echo ""
    
    _userT=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody)
    i=0
    unset _userPass
    while read _user; do
        [[ -z "$_user" ]] && continue
        i=$(expr $i + 1)
        _oP=$i
        [[ $i == [1-9] ]] && i=0$i
        echo -e "${RED}[${CYAN}$i${RED}] ${WHITE}- ${GREEN}$_user${NC}"
        _userPass+="\n${_oP}:${_user}"
    done <<< "${_userT}"
    
    [[ $i -eq 0 ]] && {
        echo -e "${YELLOW}No users found!${NC}"
        exit 0
    }
    
    echo ""
    num_user=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | wc -l)
    echo -ne "${GREEN}◇ Enter or select a user ${YELLOW}[${CYAN}1${RED}-${CYAN}$num_user${YELLOW}]${WHITE}: "
    read option
    user=$(echo -e "${_userPass}" | grep -E "\b$option\b" | cut -d: -f2)
    
    if [[ -z "$option" ]]; then
        echo -e "\n${BG_RED} User is empty or invalid! ${NC}"
        exit 1
    elif [[ -z "$user" ]]; then
        echo -e "\n${BG_RED} User is empty or invalid! ${NC}"
        exit 1
    else
        if grep -w "$user" /etc/passwd >/dev/null 2>&1; then
            echo ""
            pkill -f "$user" >/dev/null 2>&1
            deluser --force "$user" >/dev/null 2>&1
            echo -e "${BG_RED} ◇ User $user successfully removed! ${NC}"
            grep -v "^${user}[[:space:]]" "$USER_DB" > /tmp/ph
            cat /tmp/ph > "$USER_DB"
            rm -f "$PASSWD_DIR/$user"
            [[ -e /etc/openvpn/server.conf ]] && remove_ovp "$user"
        else
            echo -e "\n${BG_RED} The User $user does not exist! ${NC}"
        fi
    fi
    
elif [[ "$resp" = "2" ]]; then
    clear
    print_section "REMOVE ALL USERS"
    echo ""
    echo -ne "${YELLOW}◇ YOU REALLY WANT TO REMOVE ALL USERS ${WHITE}[y/n]: "
    read opc
    if [[ "$opc" = "y" ]]; then
        echo -e "\n${YELLOW}◇ Please Wait...${NC}"
        for user in $(awk -F: '$3 > 900 {print $1}' /etc/passwd | grep -vi "nobody"); do
            pkill -f "$user" >/dev/null 2>&1
            deluser --force "$user" >/dev/null 2>&1
            [[ -e /etc/openvpn/server.conf ]] && remove_ovp "$user"
        done
        rm -f "$USER_DB" && touch "$USER_DB"
        rm -f "$PASSWD_DIR"/* >/dev/null 2>&1
        rm -f *.zip >/dev/null 2>&1
        echo -e "\n${GREEN}◇ SUCCESSFULLY REMOVED ALL USERS!${NC}"
    else
        echo -e "\n${RED}◇ Returning to the menu...${NC}"
    fi
    
elif [[ "$resp" = "3" ]]; then
    exit 0
else
    echo -e "\n${RED}◇ Invalid option!${NC}"
fi
