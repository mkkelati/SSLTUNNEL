#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Expired User Cleaner
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root
ensure_dirs

print_section "EXPIRED USER CLEANER"
echo ""

today_epoch=$(date +%s)
removed=0

_userT=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody)
while read _user; do
    [[ -z "$_user" ]] && continue
    exp_date=$(chage -l "$_user" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
    
    [[ "$exp_date" = "never" || -z "$exp_date" ]] && continue
    
    exp_epoch=$(date -d "$exp_date" +%s 2>/dev/null)
    [[ -z "$exp_epoch" ]] && continue
    
    if [[ "$today_epoch" -gt "$exp_epoch" ]]; then
        pkill -f "$_user" >/dev/null 2>&1
        deluser --force "$_user" >/dev/null 2>&1
        grep -v "^${_user}[[:space:]]" "$USER_DB" > /tmp/ph
        cat /tmp/ph > "$USER_DB"
        rm -f "$PASSWD_DIR/$_user"
        echo -e "${RED}◇ Removed expired user: ${WHITE}$_user ${YELLOW}(expired: $exp_date)${NC}"
        removed=$((removed + 1))
    fi
done <<< "${_userT}"

if [[ $removed -eq 0 ]]; then
    echo -e "${GREEN}◇ No expired users found!${NC}"
else
    echo -e "\n${GREEN}◇ Successfully removed ${WHITE}$removed ${GREEN}expired user(s)!${NC}"
fi

# Update expired count file
get_expired_users > /etc/SSHTunnelManager/Exp 2>/dev/null
