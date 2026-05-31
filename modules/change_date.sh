#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Change Expiry Date
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root
ensure_dirs

print_section "CHANGE EXPIRY DATE"
echo ""

# List users with expiry dates
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
    exp_date=$(chage -l "$_user" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
    echo -e "${RED}[${CYAN}$i${RED}] ${WHITE}- ${GREEN}$_user ${YELLOW}(expires: ${WHITE}${exp_date:-never}${YELLOW})${NC}"
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

echo -ne "${GREEN}New number of days from today:${WHITE} "
read dias

[[ -z "$dias" ]] && {
    echo -e "\n${BG_RED} Number of days empty! ${NC}"
    exit 1
}
[[ ${dias} != ?(+|-)+([0-9]) ]] && {
    echo -e "\n${BG_RED} Invalid number! ${NC}"
    exit 1
}
[[ $dias -lt 1 ]] && {
    echo -e "\n${BG_RED} Number must be greater than zero! ${NC}"
    exit 1
}

# Change expiry date
final=$(date "+%Y-%m-%d" -d "+$dias days")
gui=$(date "+%d/%m/%Y" -d "+$dias days")
chage -E "$final" "$user"

echo -e "\n${GREEN}◇ Expiry date for ${WHITE}$user ${GREEN}changed to ${WHITE}$gui${NC}"
