#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Telegram Bot
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_section "TELEGRAM BOT"
echo ""

if ps x | grep "bot_plus" | grep -v grep >/dev/null 2>&1; then
    echo -e "${GREEN}Telegram Bot Status: ${WHITE}RUNNING${NC}"
    echo ""
    echo -e "${RED}[${CYAN}1${RED}]${YELLOW} STOP BOT"
    echo -e "${RED}[${CYAN}2${RED}]${YELLOW} CONFIGURE BOT"
    echo -e "${RED}[${CYAN}0${RED}]${YELLOW} COME BACK"
else
    echo -e "${RED}Telegram Bot Status: ${WHITE}STOPPED${NC}"
    echo ""
    echo -e "${RED}[${CYAN}1${RED}]${YELLOW} START BOT"
    echo -e "${RED}[${CYAN}2${RED}]${YELLOW} CONFIGURE BOT"
    echo -e "${RED}[${CYAN}0${RED}]${YELLOW} COME BACK"
fi

echo ""
echo -ne "${GREEN}◇ WHAT DO YOU WANT TO DO ${RED}?${WHITE} : "
read resp

if [[ "$resp" = "1" ]]; then
    if ps x | grep "bot_plus" | grep -v grep >/dev/null 2>&1; then
        echo -e "\n${GREEN}Stopping Telegram Bot...${NC}"
        for pidb in $(screen -ls 2>/dev/null | grep "bot" | awk '{print $1}'); do
            screen -r -S "$pidb" -X quit 2>/dev/null
        done
        screen -wipe >/dev/null 2>&1
        echo -e "${RED}◇ Bot stopped!${NC}"
    else
        [[ ! -f "$MANAGER_DIR/bot_config.sh" ]] && {
            echo -e "\n${RED}Bot not configured! Use option 2 to configure.${NC}"
            sleep 3
            exit 0
        }
        echo -e "\n${GREEN}Starting Telegram Bot...${NC}"
        screen -dmS bot_plus bash "$MANAGER_DIR/bot_config.sh" 2>/dev/null
        echo -e "${GREEN}◇ Bot started!${NC}"
    fi
    sleep 3
    
elif [[ "$resp" = "2" ]]; then
    echo ""
    echo -ne "${GREEN}Enter your Telegram Bot Token:${WHITE} "
    read bot_token
    [[ -z "$bot_token" ]] && {
        echo -e "\n${RED}Invalid token!${NC}"
        exit 1
    }
    
    echo -ne "${GREEN}Enter your Telegram Chat ID:${WHITE} "
    read chat_id
    [[ -z "$chat_id" ]] && {
        echo -e "\n${RED}Invalid chat ID!${NC}"
        exit 1
    }
    
    # Save configuration
    cat > "$MANAGER_DIR/bot_config.sh" << BOTEOF
#!/bin/bash
BOT_TOKEN="$bot_token"
CHAT_ID="$chat_id"
MANAGER_DIR="$MANAGER_DIR"

echo "Telegram Bot configured with token: \$BOT_TOKEN"
echo "Chat ID: \$CHAT_ID"
BOTEOF
    chmod +x "$MANAGER_DIR/bot_config.sh"
    
    echo -e "\n${GREEN}◇ Bot configured successfully!${NC}"
    sleep 3
    
elif [[ "$resp" = "0" ]]; then
    exit 0
else
    echo -e "\n${RED}◇ Invalid option!${NC}"
    sleep 2
fi
