#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Common Functions
# ============================================

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
BG_RED='\033[41;1;37m'
BG_BLUE='\033[44;1;37m'
NC='\033[0m'

# Paths
MANAGER_DIR="/etc/SSHTunnelManager"
PASSWD_DIR="$MANAGER_DIR/passwd"
USER_DB="/root/usuarios.db"
AUTOSTART_FILE="/etc/autostart"
MANAGER_VERSION="1.0.0"
MANAGER_LICENSE="/usr/lib/sshtunnelmanager"

# Progress bar animation
fun_bar() {
    local comando=("$1" "$2")
    (
        [[ -e $HOME/fim ]] && rm -f $HOME/fim
        eval "${comando[0]}" >/dev/null 2>&1
        [[ -n "${comando[1]}" ]] && eval "${comando[1]}" >/dev/null 2>&1
        touch $HOME/fim
    ) &
    tput civis
    echo -ne "  ${YELLOW}Please Wait... ${WHITE}- ${YELLOW}["
    while true; do
        for ((i = 0; i < 18; i++)); do
            echo -ne "${RED}#"
            sleep 0.1s
        done
        [[ -e $HOME/fim ]] && rm -f $HOME/fim && break
        echo -e "${YELLOW}]"
        sleep 1s
        tput cuu1
        tput dl1
        echo -ne "  ${YELLOW}Please Wait... ${WHITE}- ${YELLOW}["
    done
    echo -e "${YELLOW}]${WHITE} -${GREEN} DONE!${NC}"
    tput cnorm
}

# Header display
print_header() {
    local title="$1"
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    echo -e "${BG_BLUE}     ◇  SSH TUNNEL MANAGER - ${title}  ◇     ${NC}"
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
}

# Section header
print_section() {
    local title="$1"
    echo -e "${BG_BLUE}          ${title}          ${NC}"
}

# Error section header
print_error_section() {
    local title="$1"
    echo -e "${BG_RED}          ${title}          ${NC}"
}

# Get server IP
get_server_ip() {
    local ip
    ip=$(wget -qO- ipv4.icanhazip.com 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -s ifconfig.me 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(hostname -I | awk '{print $1}')
    echo "$ip"
}

# Verify port availability
verify_port() {
    local porta="$1"
    local PT
    PT=$(lsof -V -i tcp -P -n 2>/dev/null | grep -v "ESTABLISHED" | grep -v "COMMAND" | grep "LISTEN")
    for pton in $(echo -e "$PT" | cut -d: -f2 | cut -d' ' -f1 | uniq); do
        local svcs
        svcs=$(echo -e "$PT" | grep -w "$pton" | awk '{print $1}' | uniq)
        if [[ "$porta" = "$pton" ]]; then
            echo -e "\n${RED}PORT ${YELLOW}$porta ${RED}IN USE BY ${WHITE}$svcs${NC}"
            return 1
        fi
    done
    return 0
}

# Validate username
validate_username() {
    local username="$1"
    
    [[ -z "$username" ]] && {
        echo -e "\n${BG_RED} Empty or invalid username! ${NC}\n"
        return 1
    }
    [[ "$(grep -wc "$username" /etc/passwd)" != '0' ]] && {
        echo -e "\n${BG_RED} This user already exists! ${NC}\n"
        return 1
    }
    [[ ${username} != ?(+|-)+([a-zA-Z0-9]) ]] && {
        echo -e "\n${BG_RED} Invalid username! No spaces, accents or special characters! ${NC}\n"
        return 1
    }
    local sizemin=${#username}
    [[ $sizemin -lt 2 ]] && {
        echo -e "\n${BG_RED} Username too short! Use at least 2 characters! ${NC}\n"
        return 1
    }
    local sizemax=${#username}
    [[ $sizemax -gt 20 ]] && {
        echo -e "\n${BG_RED} Username too long! Maximum 20 characters! ${NC}\n"
        return 1
    }
    return 0
}

# Validate password
validate_password() {
    local password="$1"
    
    [[ -z "$password" ]] && {
        echo -e "\n${BG_RED} Empty or invalid password! ${NC}\n"
        return 1
    }
    local sizepass=${#password}
    [[ $sizepass -lt 4 ]] && {
        echo -e "\n${BG_RED} Password too short! Use at least 4 characters! ${NC}\n"
        return 1
    }
    return 0
}

# Get system info
get_system_info() {
    local system
    if [[ "$(grep -c "Ubuntu" /etc/issue.net)" = "1" ]]; then
        system=$(cut -d' ' -f1 /etc/issue.net)
        system+=" "
        system+=$(cut -d' ' -f2 /etc/issue.net | awk -F "." '{print $1}')
    elif [[ "$(grep -c "Debian" /etc/issue.net)" = "1" ]]; then
        system=$(cut -d' ' -f1 /etc/issue.net)
        system+=" "
        system+=$(cut -d' ' -f3 /etc/issue.net)
    else
        system=$(cut -d' ' -f1 /etc/issue.net)
    fi
    echo "$system"
}

# Get online SSH users count
get_online_ssh_users() {
    ps -x | grep sshd | grep -v root | grep priv | wc -l
}

# Get expired users count
get_expired_users() {
    local count=0
    while IFS= read -r user; do
        local exp_date
        exp_date=$(chage -l "$user" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
        [[ "$exp_date" != "never" && -n "$exp_date" ]] && {
            local exp_epoch today_epoch
            exp_epoch=$(date -d "$exp_date" +%s 2>/dev/null)
            today_epoch=$(date +%s)
            [[ -n "$exp_epoch" && "$today_epoch" -gt "$exp_epoch" ]] && count=$((count + 1))
        }
    done < <(awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody)
    echo "$count"
}

# Get total users count
get_total_users() {
    awk -F: '$3>=1000 {print $1}' /etc/passwd | grep -v nobody | wc -l
}

# Check if running as root
check_root() {
    [[ "$(whoami)" != "root" ]] && {
        echo -e "${RED}[ERROR]${WHITE} - ${YELLOW}YOU NEED TO RUN AS ROOT!${NC}"
        exit 1
    }
}

# Service status indicator
service_status() {
    local service_name="$1"
    if netstat -nltp 2>/dev/null | grep "$service_name" >/dev/null 2>&1; then
        echo -e "${GREEN}♦ "
    else
        echo -e "${RED}○ "
    fi
}

# Process status indicator
process_status() {
    local process_name="$1"
    if ps x | grep "$process_name" | grep -v grep >/dev/null 2>&1; then
        echo -e "${GREEN}♦ "
    else
        echo -e "${RED}○ "
    fi
}

# Ensure manager directories exist
ensure_dirs() {
    [[ ! -d "$MANAGER_DIR" ]] && mkdir -p "$MANAGER_DIR"
    [[ ! -d "$PASSWD_DIR" ]] && mkdir -p "$PASSWD_DIR"
    [[ ! -f "$USER_DB" ]] && touch "$USER_DB"
    [[ ! -f "$AUTOSTART_FILE" ]] && touch "$AUTOSTART_FILE"
}
