#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Change Connection Limit
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root
ensure_dirs

print_section "CHANGE CONNECTION LIMIT"
echo ""

# List users with their current limits
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
    current_limit=$(grep "^${_user} " "$USER_DB" 2>/dev/null | awk '{print $2}')
    echo -e "${RED}[${CYAN}$i${RED}] ${WHITE}- ${GREEN}$_user ${YELLOW}(limit: ${WHITE}${current_limit:-N/A}${YELLOW})${NC}"
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

echo -ne "${GREEN}New connection limit:${WHITE} "
read newlimit

[[ -z "$newlimit" ]] && {
    echo -e "\n${BG_RED} Limit is empty! ${NC}"
    exit 1
}
[[ ${newlimit} != ?(+|-)+([0-9]) ]] && {
    echo -e "\n${BG_RED} Invalid number! ${NC}"
    exit 1
}
[[ $newlimit -lt 1 ]] && {
    echo -e "\n${BG_RED} Limit must be greater than zero! ${NC}"
    exit 1
}

# Update user database
if grep -q "^${user} " "$USER_DB"; then
    sed -i "s/^${user} .*/${user} ${newlimit}/" "$USER_DB"
else
    echo "${user} ${newlimit}" >> "$USER_DB"
fi

echo -e "\n${GREEN}◇ Connection limit for ${WHITE}$user ${GREEN}changed to ${WHITE}$newlimit${NC}"
