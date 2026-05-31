#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - User Report
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root
ensure_dirs

print_section "USER REPORT"
echo ""

echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
printf "${YELLOW}%-15s %-12s %-8s %-15s${NC}\n" "USERNAME" "PASSWORD" "LIMIT" "EXPIRES"
echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"

_userT=$(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody)
total=0
expired=0
active=0

while read _user; do
    [[ -z "$_user" ]] && continue
    total=$((total + 1))
    
    # Get password
    local_pass="N/A"
    [[ -e "$PASSWD_DIR/$_user" ]] && local_pass=$(cat "$PASSWD_DIR/$_user")
    
    # Get limit
    limit=$(grep "^${_user} " "$USER_DB" 2>/dev/null | awk '{print $2}')
    [[ -z "$limit" ]] && limit="N/A"
    
    # Get expiry
    exp_date=$(chage -l "$_user" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
    [[ -z "$exp_date" ]] && exp_date="never"
    
    # Check if expired
    status_color="${GREEN}"
    if [[ "$exp_date" != "never" ]]; then
        exp_epoch=$(date -d "$exp_date" +%s 2>/dev/null)
        today_epoch=$(date +%s)
        if [[ -n "$exp_epoch" && "$today_epoch" -gt "$exp_epoch" ]]; then
            status_color="${RED}"
            expired=$((expired + 1))
        else
            active=$((active + 1))
        fi
    else
        active=$((active + 1))
    fi
    
    printf "${status_color}%-15s %-12s %-8s %-15s${NC}\n" "$_user" "$local_pass" "$limit" "$exp_date"
done <<< "${_userT}"

echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
echo ""
echo -e "${GREEN}◈ Total users: ${WHITE}$total"
echo -e "${GREEN}◈ Active:      ${WHITE}$active"
echo -e "${RED}◈ Expired:     ${WHITE}$expired${NC}"
