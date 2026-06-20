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
                _do_update() {
                    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null
                    # Copy updated proxy scripts to manager directory
                    cp -f "$SCRIPT_DIR/lib/proxy.py" /etc/SSHTunnelManager/proxy.py 2>/dev/null
                    cp -f "$SCRIPT_DIR/lib/wsproxy.py" /etc/SSHTunnelManager/wsproxy.py 2>/dev/null
                    chmod +x /etc/SSHTunnelManager/proxy.py /etc/SSHTunnelManager/wsproxy.py 2>/dev/null
                    # Set permissions on new/updated scripts
                    find "$SCRIPT_DIR/modules/" -name "*.sh" -exec chmod +x {} \;
                    chmod +x "$SCRIPT_DIR/lib/functions.sh" 2>/dev/null
                    # Restart wsproxy if running
                    if ps x | grep -w wsproxy.py | grep -v grep >/dev/null 2>&1; then
                        local ws_port
                        ws_port=$(netstat -nltp 2>/dev/null | grep 'python' | grep -v '127.0.0.1' | awk '{print $4}' | cut -d: -f2 | head -1)
                        for pidproxy in $(screen -ls 2>/dev/null | grep ".ws" | awk '{print $1}'); do
                            screen -r -S "$pidproxy" -X quit
                        done
                        sleep 1
                        [[ -n "$ws_port" ]] && screen -dmS ws python3 /etc/SSHTunnelManager/wsproxy.py "$ws_port" 2>/dev/null
                    fi
                }
                fun_bar '_do_update'
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
