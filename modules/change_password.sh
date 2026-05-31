#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Change User Password
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root
ensure_dirs

print_section "CHANGE USER PASSWORD"
echo ""

# List users
echo -e "${YELLOW}◇ LIST OF USERS:${NC}"
echo ""
_userT=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody)
i=0
unset _userPass
while read _user; do
    [[ -z "$_user" ]] && continue
    i=$(expr $i + 1)
    _oP=$i
    [[ $i == [1-9] ]] && i=0$i
    local_pass=""
    [[ -e "$PASSWD_DIR/$_user" ]] && local_pass=$(cat "$PASSWD_DIR/$_user")
    echo -e "${RED}[${CYAN}$i${RED}] ${WHITE}- ${GREEN}$_user ${YELLOW}(pass: ${WHITE}${local_pass:-unknown}${YELLOW})${NC}"
    _userPass+="\n${_oP}:${_user}"
done <<< "${_userT}"

[[ $i -eq 0 ]] && {
    echo -e "${YELLOW}No users found!${NC}"
    exit 0
}

echo ""
num_user=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | wc -l)
echo -ne "${GREEN}◇ Select a user ${YELLOW}[${CYAN}1${RED}-${CYAN}$num_user${YELLOW}]${WHITE}: "
read option
user=$(echo -e "${_userPass}" | grep -E "\b$option\b" | cut -d: -f2)

[[ -z "$user" ]] && {
    echo -e "\n${BG_RED} Invalid selection! ${NC}"
    exit 1
}

echo -ne "${GREEN}New password:${WHITE} "
read newpass
validate_password "$newpass" || exit 1

# Change the password
pass_crypt=$(perl -e 'print crypt($ARGV[0], "password")' "$newpass")
usermod -p "$pass_crypt" "$user"
echo "$newpass" > "$PASSWD_DIR/$user"

echo -e "\n${GREEN}◇ Password for ${WHITE}$user ${GREEN}successfully changed to ${WHITE}$newpass${NC}"
