#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Main Menu
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root
ensure_dirs

# Secondary menu (more options)
menu2() {
    local stsf autm stsbot
    [[ -e /etc/Plus-torrent ]] && stsf=$(echo -e "${GREEN}♦ ") || stsf=$(echo -e "${RED}○ ")
    autm=$(grep "menu;" /etc/profile >/dev/null 2>&1 && echo -e "${GREEN}♦ " || echo -e "${RED}○ ")
    stsbot=$(ps x | grep "bot_plus" | grep -v grep >/dev/null 2>&1 && echo -e "${GREEN}♦ " || echo -e "${RED}○ ")

    local _ons _expuser _onop _ondrp _onli
    _ons=$(get_online_ssh_users)
    _expuser=$(get_expired_users)
    _onli=$_ons
    
    [[ -e /etc/openvpn/openvpn-status.log ]] && _onop=$(grep -c "10.8.0" /etc/openvpn/openvpn-status.log) || _onop="0"
    [[ -e /etc/default/dropbear ]] && {
        local _drp
        _drp=$(ps aux | grep dropbear | grep -v grep | wc -l)
        _ondrp=$((_drp - 1))
    } || _ondrp="0"
    _onli=$((_ons + _onop + _ondrp))
    
    local _ram _usor _usop _core _system _hora _tuser
    _ram=$(printf ' %-9s' "$(free -h | grep -i mem | awk '{print $2}')")
    _usor=$(printf '%-8s' "$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')")
    _usop=$(printf '%-1s' "$(top -bn1 | awk '/Cpu/ { cpu = "" 100 - $8 "%" }; END { print cpu }')")
    _core=$(printf '%-1s' "$(grep -c cpu[0-9] /proc/stat)")
    _system=$(printf '%-14s' "$(get_system_info)")
    _hora=$(printf '%(%H:%M:%S)T')
    _tuser=$(get_total_users)

    clear
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    echo -e "${BG_RED}           •  SSH TUNNEL MANAGER  •            ${NC}"
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    echo -e "${GREEN}◇ SYSTEM          ◇ RAM MEMORY    ◇ PROCESSOR"
    echo -e "${RED}OS: ${WHITE}$_system ${RED}Total:${WHITE}$_ram ${RED}CPU cores: ${WHITE}$_core${NC}"
    echo -e "${RED}Up Time: ${WHITE}$_hora  ${RED}In use: ${WHITE}$_usor ${RED}In use: ${WHITE}$_usop${NC}"
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    echo -e "${GREEN}◇ Online:${WHITE} $_onli   ${RED}◇ Expired: ${WHITE}$_expuser${YELLOW}  ◇ Total: ${WHITE}$_tuser${NC}"
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    echo ""
    echo -e "${RED}[${CYAN}20${RED}] ${WHITE}◇ ${YELLOW}ADD HOST DNS ${RED}             [${CYAN}26${RED}] ${WHITE}◇ ${YELLOW}CHANGE ROOT PASSWORD"
    echo -e "${RED}[${CYAN}21${RED}] ${WHITE}◇ ${YELLOW}REMOVE HOST DNS ${RED}          [${CYAN}27${RED}] ${WHITE}◇ ${YELLOW}SELF EXECUTION $autm"
    echo -e "${RED}[${CYAN}22${RED}] ${WHITE}◇ ${YELLOW}RESTART SYSTEM ${RED}           [${CYAN}28${RED}] ${WHITE}◇ ${YELLOW}UPDATE SCRIPT"
    echo -e "${RED}[${CYAN}23${RED}] ${WHITE}◇ ${YELLOW}RESTART SERVICES ${RED}         [${CYAN}29${RED}] ${WHITE}◇ ${YELLOW}REMOVE SCRIPT"
    echo -e "${RED}[${CYAN}24${RED}] ${WHITE}◇ ${YELLOW}BLOCK TORRENT $stsf${RED}        [${CYAN}30${RED}] ${WHITE}◇ ${YELLOW}COME BACK ${GREEN}<<<${RED}"
    echo -e "${RED}[${CYAN}25${RED}] ${WHITE}◇ ${YELLOW}TELEGRAM BOT $stsbot${RED}       [${CYAN}00${RED}] ${WHITE}◇ ${YELLOW}EXIT ${GREEN}<<<${NC}"
    echo ""
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    echo ""
    echo -ne "${GREEN}◇ WHAT DO YOU WANT TO DO ${YELLOW}?${RED}?${WHITE} : "
    read x
    case "$x" in
        20) clear; bash "$SCRIPT_DIR/modules/add_host.sh"
            echo -ne "\n${RED}◇ ENTER ${YELLOW}to return to ${GREEN}MENU!${NC}"; read
            menu2 ;;
        21) clear; bash "$SCRIPT_DIR/modules/remove_host.sh"
            echo -ne "\n${RED}◇ ENTER ${YELLOW}to return to ${GREEN}MENU!${NC}"; read
            menu2 ;;
        22) clear; bash "$SCRIPT_DIR/modules/restart_system.sh" ;;
        23) clear; bash "$SCRIPT_DIR/modules/restart_services.sh"; sleep 3 ;;
        24) bash "$SCRIPT_DIR/modules/block_torrent.sh"; menu2 ;;
        25) bash "$SCRIPT_DIR/modules/telegram_bot.sh"; menu2 ;;
        26) clear; bash "$SCRIPT_DIR/modules/change_root_pass.sh"; sleep 3; menu2 ;;
        27) 
            if grep "menu;" /etc/profile >/dev/null 2>&1; then
                clear
                echo -e "${GREEN}◇ DISABLING AUTO-RUN${NC}"
                sed -i '/menu;/d' /etc/profile
                echo ""
                echo -e "${RED}◇ AUTO RUN DISABLED!${NC}"
            else
                clear
                echo -e "${GREEN}◇ ACTIVATING AUTO-RUN${NC}"
                grep -v "^menu;" /etc/profile > /tmp/tmpass && mv /tmp/tmpass /etc/profile
                echo "menu;" >> /etc/profile
                echo ""
                echo -e "${GREEN}◇ AUTO RUN ON!${NC}"
            fi
            sleep 1.5s
            menu2 ;;
        28) clear; bash "$SCRIPT_DIR/modules/update_script.sh"; menu2 ;;
        29) clear; bash "$SCRIPT_DIR/modules/uninstall.sh" ;;
        30) main_menu ;;
        0|00)
            echo -e "${RED}◇ Going out...${NC}"
            sleep 2; clear; exit ;;
        *)
            echo -e "\n${RED}◇ Invalid option!${NC}"
            sleep 2; menu2 ;;
    esac
}

# Main menu
main_menu() {
    while true; do
        local stsl stsu
        stsl=$(process_status "limiter")
        stsu=$(process_status "udpvpn")
        
        local _ons _expuser _onop _ondrp _onli
        _ons=$(get_online_ssh_users)
        _expuser=$(get_expired_users)
        _onli=$_ons
        
        [[ -e /etc/openvpn/openvpn-status.log ]] && _onop=$(grep -c "10.8.0" /etc/openvpn/openvpn-status.log) || _onop="0"
        [[ -e /etc/default/dropbear ]] && {
            local _drp
            _drp=$(ps aux | grep dropbear | grep -v grep | wc -l)
            _ondrp=$((_drp - 1))
        } || _ondrp="0"
        _onli=$((_ons + _onop + _ondrp))
        
        local _ram _usor _usop _core _system _hora _tuser
        _ram=$(printf ' %-9s' "$(free -h | grep -i mem | awk '{print $2}')")
        _usor=$(printf '%-8s' "$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')")
        _usop=$(printf '%-1s' "$(top -bn1 | awk '/Cpu/ { cpu = "" 100 - $8 "%" }; END { print cpu }')")
        _core=$(printf '%-1s' "$(grep -c cpu[0-9] /proc/stat)")
        _system=$(printf '%-14s' "$(get_system_info)")
        _hora=$(printf '%(%H:%M:%S)T')
        _tuser=$(get_total_users)
        
        clear
        echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
        echo -e "${BG_RED}           •  SSH TUNNEL MANAGER  •            ${NC}"
        echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
        echo -e "${GREEN}◇ SYSTEM          ◇ RAM MEMORY    ◇ PROCESSOR"
        echo -e "${RED}OS: ${WHITE}$_system ${RED}Total:${WHITE}$_ram ${RED}CPU cores: ${WHITE}$_core${NC}"
        echo -e "${RED}Up Time: ${WHITE}$_hora  ${RED}In use: ${WHITE}$_usor ${RED}In use: ${WHITE}$_usop${NC}"
        echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
        echo -e "${GREEN}◇ Online:${WHITE} $_onli   ${RED}◇ Expired: ${WHITE}$_expuser${YELLOW}  ◇ Total: ${WHITE}$_tuser${NC}"
        echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
        echo ""
        echo -e "${RED}[${CYAN}01${RED}] ${WHITE}◇ ${YELLOW}CREATE USER ${RED}              [${CYAN}11${RED}] ${WHITE}◇ ${YELLOW}SPEEDTEST"
        echo -e "${RED}[${CYAN}02${RED}] ${WHITE}◇ ${YELLOW}CREATE TEST USER ${RED}         [${CYAN}12${RED}] ${WHITE}◇ ${YELLOW}BANNER"
        echo -e "${RED}[${CYAN}03${RED}] ${WHITE}◇ ${YELLOW}REMOVE USER ${RED}              [${CYAN}13${RED}] ${WHITE}◇ ${YELLOW}NETWORK TRAFFIC"
        echo -e "${RED}[${CYAN}04${RED}] ${WHITE}◇ ${YELLOW}ONLINE USER MONITOR ${RED}      [${CYAN}14${RED}] ${WHITE}◇ ${YELLOW}VPS OPTIMIZE"
        echo -e "${RED}[${CYAN}05${RED}] ${WHITE}◇ ${YELLOW}CHANGE EXPIRY DATE ${RED}       [${CYAN}15${RED}] ${WHITE}◇ ${YELLOW}USER BACKUP"
        echo -e "${RED}[${CYAN}06${RED}] ${WHITE}◇ ${YELLOW}CHANGE LIMIT ${RED}             [${CYAN}16${RED}] ${WHITE}◇ ${YELLOW}USER LIMITER $stsl"
        echo -e "${RED}[${CYAN}07${RED}] ${WHITE}◇ ${YELLOW}CHANGE PASSWORD ${RED}          [${CYAN}17${RED}] ${WHITE}◇ ${YELLOW}BAD VPN $stsu"
        echo -e "${RED}[${CYAN}08${RED}] ${WHITE}◇ ${YELLOW}REMOVE EXPIRED ${RED}           [${CYAN}18${RED}] ${WHITE}◇ ${YELLOW}VPS INFO"
        echo -e "${RED}[${CYAN}09${RED}] ${WHITE}◇ ${YELLOW}USER REPORT ${RED}              [${CYAN}19${RED}] ${WHITE}◇ ${YELLOW}MORE OPTIONS ${RED}>${YELLOW}>${GREEN}>${NC}"
        echo -e "${RED}[${CYAN}10${RED}] ${WHITE}◇ ${YELLOW}CONNECTION MODE ${RED}           [${CYAN}00${RED}] ${WHITE}◇ ${YELLOW}EXIT ${GREEN}<<<${NC}"
        echo ""
        echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
        echo ""
        echo -ne "${GREEN}◇ WHAT DO YOU WANT TO DO ${YELLOW}?${RED}?${WHITE} : "
        read x
        
        case "$x" in
            1|01)
                clear; bash "$SCRIPT_DIR/modules/create_user.sh"
                echo -ne "\n${RED}◇ ENTER ${YELLOW}to return to ${GREEN}MENU!${NC}"; read ;;
            2|02)
                clear; bash "$SCRIPT_DIR/modules/create_test_user.sh"
                echo -ne "\n${RED}◇ ENTER ${YELLOW}to return to ${GREEN}MENU!${NC}"; read ;;
            3|03)
                clear; bash "$SCRIPT_DIR/modules/remove_user.sh"; sleep 3 ;;
            4|04)
                clear; bash "$SCRIPT_DIR/modules/user_monitor.sh"
                echo -ne "\n${RED}◇ ENTER ${YELLOW}to return to ${GREEN}MENU!${NC}"; read ;;
            5|05)
                clear; bash "$SCRIPT_DIR/modules/change_date.sh"; sleep 3 ;;
            6|06)
                clear; bash "$SCRIPT_DIR/modules/change_limit.sh"; sleep 3 ;;
            7|07)
                clear; bash "$SCRIPT_DIR/modules/change_password.sh"; sleep 3 ;;
            8|08)
                clear; bash "$SCRIPT_DIR/modules/expired_cleaner.sh"
                echo ""; sleep 3 ;;
            9|09)
                clear; bash "$SCRIPT_DIR/modules/user_report.sh"
                echo -ne "\n${RED}◇ ENTER ${YELLOW}to return to ${GREEN}MENU!${NC}"; read ;;
            10)
                bash "$SCRIPT_DIR/modules/connection.sh"; exit ;;
            11)
                clear; bash "$SCRIPT_DIR/modules/speedtest.sh"
                echo -ne "\n${RED}◇ ENTER ${YELLOW}to return to ${GREEN}MENU!${NC}"; read ;;
            12)
                clear; bash "$SCRIPT_DIR/modules/banner.sh"; sleep 3 ;;
            13)
                clear
                echo -e "${GREEN}◇ TO EXIT PRESS: CTRL + C${CYAN}"
                sleep 4; nload ;;
            14)
                clear; bash "$SCRIPT_DIR/modules/optimize.sh"
                echo -ne "\n${RED}◇ ENTER ${YELLOW}to return to ${GREEN}MENU!${NC}"; read ;;
            15)
                bash "$SCRIPT_DIR/modules/user_backup.sh"
                echo -ne "\n${RED}◇ ENTER ${YELLOW}to return to ${GREEN}MENU!${NC}"; read ;;
            16)
                bash "$SCRIPT_DIR/modules/limiter.sh" ;;
            17)
                clear; bash "$SCRIPT_DIR/modules/badvpn.sh"; exit ;;
            18)
                clear; bash "$SCRIPT_DIR/modules/system_info.sh"
                echo -ne "\n${RED}◇ ENTER ${YELLOW}to return to ${GREEN}MENU!${NC}"; read ;;
            19)
                menu2 ;;
            0|00)
                echo -e "${RED}◇ Going out...${NC}"
                sleep 2; clear; exit ;;
            *)
                echo -e "\n${RED}◇ Invalid option!${NC}"
                sleep 2 ;;
        esac
    done
}

main_menu
