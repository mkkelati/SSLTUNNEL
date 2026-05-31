#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - BadVPN
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_section "BADVPN UDP GATEWAY"
echo ""

if ps x | grep "udpvpn" | grep -v grep >/dev/null 2>&1; then
    echo -e "${GREEN}BadVPN Status: ${WHITE}RUNNING${NC}"
    echo ""
    echo -e "${RED}[${CYAN}1${RED}]${YELLOW} STOP BADVPN"
    echo -e "${RED}[${CYAN}2${RED}]${YELLOW} RESTART BADVPN"
    echo -e "${RED}[${CYAN}0${RED}]${YELLOW} COME BACK"
    echo ""
    echo -ne "${GREEN}◇ WHAT DO YOU WANT TO DO ${RED}?${WHITE} : "
    read resp
    
    if [[ "$resp" = "1" ]]; then
        echo -e "\n${GREEN}◇ Stopping BadVPN...${NC}"
        fun_stopbadvpn() {
            kill $(ps x | grep 'udpvpn' | grep -v grep | awk '{print $1}') >/dev/null 2>&1
            screen -wipe >/dev/null 2>&1
            [[ $(grep -wc "udpvpn" /etc/autostart) != '0' ]] && sed -i '/udpvpn/d' /etc/autostart
        }
        fun_bar 'fun_stopbadvpn'
        echo -e "\n${RED}◇ BadVPN STOPPED!${NC}"
        sleep 3
        
    elif [[ "$resp" = "2" ]]; then
        echo -ne "\n${GREEN}Which port? ${WHITE}"
        read porta
        [[ -z "$porta" ]] && porta=7300
        kill $(ps x | grep 'udpvpn' | grep -v grep | awk '{print $1}') >/dev/null 2>&1
        sleep 1
        screen -dmS udpvpn badvpn-udpgw --listen-addr "127.0.0.1:$porta" --max-clients 200 --max-connections-for-client 10 2>/dev/null
        echo -e "\n${GREEN}◇ BadVPN restarted on port $porta!${NC}"
        sleep 3
    fi
else
    echo -e "${RED}BadVPN Status: ${WHITE}STOPPED${NC}"
    echo ""
    echo -e "${RED}[${CYAN}1${RED}]${YELLOW} START BADVPN"
    echo -e "${RED}[${CYAN}2${RED}]${YELLOW} INSTALL BADVPN"
    echo -e "${RED}[${CYAN}0${RED}]${YELLOW} COME BACK"
    echo ""
    echo -ne "${GREEN}◇ WHAT DO YOU WANT TO DO ${RED}?${WHITE} : "
    read resp
    
    if [[ "$resp" = "1" ]]; then
        if [[ -f /usr/bin/badvpn-udpgw ]]; then
            echo -ne "\n${GREEN}Which port? ${WHITE}"
            read porta
            [[ -z "$porta" ]] && porta=7300
            screen -dmS udpvpn badvpn-udpgw --listen-addr "127.0.0.1:$porta" --max-clients 200 --max-connections-for-client 10 2>/dev/null
            echo -e "\n${GREEN}◇ BadVPN started on port $porta!${NC}"
            
            [[ $(grep -wc "udpvpn" /etc/autostart 2>/dev/null) = '0' ]] && {
                echo -e "ps x | grep 'udpvpn' | grep -v 'grep' && echo 'ON' || screen -dmS udpvpn badvpn-udpgw --listen-addr 127.0.0.1:$porta --max-clients 200 --max-connections-for-client 10" >> /etc/autostart
            }
        else
            echo -e "\n${RED}BadVPN not installed! Choose option 2 to install.${NC}"
        fi
        sleep 3
        
    elif [[ "$resp" = "2" ]]; then
        echo -e "\n${GREEN}◇ Installing BadVPN...${NC}\n"
        fun_instbadvpn() {
            apt-get update -y
            wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/januda-ui/DRAGON-VPS-MANAGER/main/Install/badvpn-udpgw" 2>/dev/null
            chmod +x /usr/bin/badvpn-udpgw
        }
        fun_bar 'fun_instbadvpn'
        
        echo -ne "${GREEN}Which port? ${WHITE}"
        read porta
        [[ -z "$porta" ]] && porta=7300
        screen -dmS udpvpn badvpn-udpgw --listen-addr "127.0.0.1:$porta" --max-clients 200 --max-connections-for-client 10 2>/dev/null
        
        [[ $(grep -wc "udpvpn" /etc/autostart 2>/dev/null) = '0' ]] && {
            echo -e "ps x | grep 'udpvpn' | grep -v 'grep' && echo 'ON' || screen -dmS udpvpn badvpn-udpgw --listen-addr 127.0.0.1:$porta --max-clients 200 --max-connections-for-client 10" >> /etc/autostart
        }
        
        echo -e "\n${GREEN}◇ BadVPN installed and started on port $porta!${NC}"
        sleep 3
    fi
fi
