#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Update Script
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_section "UPDATE SCRIPT"
echo ""

echo -e "${YELLOW}Checking for updates...${NC}"
echo ""

# Check if git is available
if command -v git &>/dev/null; then
    if [[ -d "$SCRIPT_DIR/.git" ]]; then
        cd "$SCRIPT_DIR"
        git fetch origin 2>/dev/null
        LOCAL=$(git rev-parse HEAD 2>/dev/null)
        REMOTE=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)
        
        if [[ "$LOCAL" != "$REMOTE" ]]; then
            echo -e "${YELLOW}Update available!${NC}"
            echo -ne "${GREEN}DO YOU WANT TO UPDATE ${RED}? ${YELLOW}[y/n]:${WHITE} "
            read resp
            [[ "$resp" = 'y' ]] && {
                echo -e "\n${GREEN}Updating...${NC}\n"
                fun_bar 'git pull origin main 2>/dev/null || git pull origin master 2>/dev/null'
                echo -e "\n${GREEN}◇ SCRIPT UPDATED SUCCESSFULLY!${NC}"
            } || {
                echo -e "\n${RED}Update cancelled.${NC}"
            }
        else
            echo -e "${GREEN}◇ Script is already up to date!${NC}"
        fi
    else
        echo -e "${YELLOW}No git repository found. Manual update required.${NC}"
        echo -e "${YELLOW}Please re-download the script to update.${NC}"
    fi
else
    echo -e "${RED}Git is not installed. Install it with: apt install git${NC}"
fi

sleep 3
