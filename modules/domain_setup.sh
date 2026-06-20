#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Domain Setup
#  Verify and configure domain for WS-ePro
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

DOMAIN_FILE="$MANAGER_DIR/domain"

check_root

# Get VPS IP
get_vps_ip() {
    local ip
    ip=$(wget -qO- ipv4.icanhazip.com 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -s ifconfig.me 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(hostname -I | awk '{print $1}')
    echo "$ip"
}

# Resolve domain to IP
resolve_domain() {
    local domain="$1"
    local resolved
    resolved=$(dig +short "$domain" A 2>/dev/null | grep -E '^[0-9]+\.' | head -1)
    [[ -z "$resolved" ]] && resolved=$(host "$domain" 2>/dev/null | grep "has address" | awk '{print $NF}' | head -1)
    [[ -z "$resolved" ]] && resolved=$(nslookup "$domain" 2>/dev/null | awk '/^Address: / { print $2 }' | head -1)
    echo "$resolved"
}

# Show current domain status
show_domain_status() {
    if [[ -f "$DOMAIN_FILE" ]]; then
        local current_domain
        current_domain=$(cat "$DOMAIN_FILE")
        echo -e "${GREEN}◇ Current Domain: ${YELLOW}$current_domain${NC}"
    else
        echo -e "${RED}◇ No domain configured${NC}"
    fi
}

# Main domain setup
domain_setup() {
    clear
    print_header "DOMAIN SETUP"
    echo ""
    show_domain_status
    echo ""

    local vps_ip
    vps_ip=$(get_vps_ip)
    echo -e "${GREEN}◇ VPS IP: ${WHITE}$vps_ip${NC}"
    echo ""
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    echo ""
    echo -e "${RED}[${CYAN}1${RED}] ${WHITE}◇ ${YELLOW}SET UP / CHANGE DOMAIN"
    echo -e "${RED}[${CYAN}2${RED}] ${WHITE}◇ ${YELLOW}REMOVE DOMAIN"
    echo -e "${RED}[${CYAN}3${RED}] ${WHITE}◇ ${YELLOW}CHECK DOMAIN STATUS"
    echo -e "${RED}[${CYAN}0${RED}] ${WHITE}◇ ${YELLOW}COME BACK"
    echo ""
    echo -ne "${GREEN}◇ WHAT DO YOU WANT TO DO ${YELLOW}?${WHITE} : "
    read option

    case "$option" in
        1) setup_domain "$vps_ip" ;;
        2) remove_domain ;;
        3) check_domain_status "$vps_ip" ;;
        0) return ;;
        *) echo -e "\n${RED}◇ Invalid option!${NC}"; sleep 2; domain_setup ;;
    esac
}

# Setup/change domain
setup_domain() {
    local vps_ip="$1"
    clear
    print_header "DOMAIN SETUP"
    echo ""
    echo -e "${GREEN}◇ VPS IP: ${WHITE}$vps_ip${NC}"
    echo ""
    echo -e "${YELLOW}◇ Make sure your domain A record points to: ${WHITE}$vps_ip${NC}"
    echo -e "${YELLOW}◇ Example: yourdomain.com → A Record → $vps_ip${NC}"
    echo ""
    echo -ne "${GREEN}◇ ENTER YOUR DOMAIN (e.g. example.com): ${WHITE}"
    read domain

    # Validate input
    [[ -z "$domain" ]] && {
        echo -e "\n${RED}◇ No domain entered!${NC}"
        sleep 2; domain_setup; return
    }

    # Remove protocol prefix if user accidentally added it
    domain=$(echo "$domain" | sed 's|https\?://||' | sed 's|/.*||')

    # Basic domain format validation
    if ! echo "$domain" | grep -qP '^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)+$'; then
        echo -e "\n${RED}◇ Invalid domain format!${NC}"
        echo -e "${YELLOW}◇ Use format like: example.com or sub.example.com${NC}"
        sleep 3; domain_setup; return
    fi

    echo ""
    echo -e "${YELLOW}◇ Verifying domain ${WHITE}$domain${YELLOW} points to ${WHITE}$vps_ip${YELLOW}...${NC}"
    echo ""

    # Resolve domain
    local resolved_ip
    resolved_ip=$(resolve_domain "$domain")

    if [[ -z "$resolved_ip" ]]; then
        echo -e "${RED}◇ ERROR: Could not resolve domain ${WHITE}$domain${NC}"
        echo -e "${YELLOW}◇ Make sure the domain DNS is properly configured.${NC}"
        echo -e "${YELLOW}◇ DNS changes can take up to 24-48 hours to propagate.${NC}"
        echo ""
        echo -ne "${GREEN}◇ Press ENTER to return${NC}"; read
        domain_setup; return
    fi

    echo -e "${GREEN}◇ Domain resolves to: ${WHITE}$resolved_ip${NC}"

    # Compare resolved IP with VPS IP
    if [[ "$resolved_ip" != "$vps_ip" ]]; then
        echo ""
        echo -e "${RED}◇ DOMAIN VERIFICATION FAILED!${NC}"
        echo -e "${RED}◇ Domain ${WHITE}$domain${RED} points to ${WHITE}$resolved_ip${NC}"
        echo -e "${RED}◇ But your VPS IP is ${WHITE}$vps_ip${NC}"
        echo ""
        echo -e "${YELLOW}◇ Please update your DNS A record to point to: ${WHITE}$vps_ip${NC}"
        echo ""
        echo -ne "${GREEN}◇ Press ENTER to return${NC}"; read
        domain_setup; return
    fi

    # Domain verified successfully
    echo ""
    echo -e "${GREEN}◇ ✓ DOMAIN VERIFIED SUCCESSFULLY!${NC}"
    echo -e "${GREEN}◇ ${WHITE}$domain ${GREEN}→ ${WHITE}$vps_ip ${GREEN}✓${NC}"
    echo ""

    # Save domain
    echo "$domain" > "$DOMAIN_FILE"
    chmod 644 "$DOMAIN_FILE"

    echo -e "${GREEN}◇ Domain saved and configured!${NC}"
    echo ""
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    echo -e "${GREEN}◇ WS-ePro / HTTP Injector Configuration:${NC}"
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    echo ""
    
    # Show WebSocket port if active
    local ws_port
    ws_port=$(netstat -nltp 2>/dev/null | grep 'python' | grep -v '127.0.0.1' | awk '{print $4}' | cut -d: -f2 | head -1)
    
    # Show SSL port if active
    local ssl_port
    ssl_port=$(netstat -nltp 2>/dev/null | grep 'stunnel' | awk '{print $4}' | cut -d: -f2 | head -1)

    echo -e "${GREEN}◇ Domain: ${WHITE}$domain${NC}"
    echo -e "${GREEN}◇ VPS IP: ${WHITE}$vps_ip${NC}"
    [[ -n "$ws_port" ]] && echo -e "${GREEN}◇ WebSocket Port: ${WHITE}$ws_port${NC}"
    [[ -n "$ssl_port" ]] && echo -e "${GREEN}◇ SSL Port: ${WHITE}$ssl_port${NC}"
    echo ""
    echo -e "${YELLOW}◇ Use ${WHITE}$domain${YELLOW} as Host in HTTP Injector / ePro${NC}"
    echo ""
    echo -ne "${GREEN}◇ Press ENTER to return${NC}"; read
    domain_setup
}

# Remove domain configuration
remove_domain() {
    clear
    print_header "REMOVE DOMAIN"
    echo ""

    if [[ ! -f "$DOMAIN_FILE" ]]; then
        echo -e "${RED}◇ No domain is currently configured!${NC}"
        echo ""
        echo -ne "${GREEN}◇ Press ENTER to return${NC}"; read
        domain_setup; return
    fi

    local current_domain
    current_domain=$(cat "$DOMAIN_FILE")
    echo -e "${YELLOW}◇ Current domain: ${WHITE}$current_domain${NC}"
    echo ""
    echo -ne "${RED}◇ Are you sure you want to remove it? [Y/N]: ${WHITE}"
    read confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -f "$DOMAIN_FILE"
        echo -e "\n${GREEN}◇ Domain removed successfully!${NC}"
    else
        echo -e "\n${YELLOW}◇ Cancelled.${NC}"
    fi
    sleep 2; domain_setup
}

# Check current domain status
check_domain_status() {
    local vps_ip="$1"
    clear
    print_header "DOMAIN STATUS"
    echo ""

    if [[ ! -f "$DOMAIN_FILE" ]]; then
        echo -e "${RED}◇ No domain configured!${NC}"
        echo ""
        echo -ne "${GREEN}◇ Press ENTER to return${NC}"; read
        domain_setup; return
    fi

    local current_domain resolved_ip
    current_domain=$(cat "$DOMAIN_FILE")
    resolved_ip=$(resolve_domain "$current_domain")

    echo -e "${GREEN}◇ Configured Domain: ${WHITE}$current_domain${NC}"
    echo -e "${GREEN}◇ VPS IP: ${WHITE}$vps_ip${NC}"
    echo -e "${GREEN}◇ Domain resolves to: ${WHITE}${resolved_ip:-FAILED}${NC}"
    echo ""

    if [[ "$resolved_ip" == "$vps_ip" ]]; then
        echo -e "${GREEN}◇ ✓ Domain is correctly pointing to this VPS${NC}"
    else
        echo -e "${RED}◇ ✗ Domain is NOT pointing to this VPS!${NC}"
        echo -e "${YELLOW}◇ Please update your DNS A record.${NC}"
    fi

    echo ""
    
    # Show active services
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    echo -e "${GREEN}◇ Active Connection Services:${NC}"
    echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    
    local ws_port ssl_port ssh_port dropbear_port
    ws_port=$(netstat -nltp 2>/dev/null | grep 'python' | grep -v '127.0.0.1' | awk '{print $4}' | cut -d: -f2 | head -1)
    ssl_port=$(netstat -nltp 2>/dev/null | grep 'stunnel' | awk '{print $4}' | cut -d: -f2 | head -1)
    ssh_port=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -1)
    [[ -z "$ssh_port" ]] && ssh_port="22"
    
    echo ""
    echo -e "${GREEN}◇ SSH: ${WHITE}$current_domain:$ssh_port${NC}"
    [[ -n "$ssl_port" ]] && echo -e "${GREEN}◇ SSL/TLS: ${WHITE}$current_domain:$ssl_port${NC}"
    [[ -n "$ws_port" ]] && echo -e "${GREEN}◇ WebSocket: ${WHITE}$current_domain:$ws_port${NC}"
    echo ""
    echo -e "${YELLOW}◇ WS-ePro Payload Example:${NC}"
    echo -e "${WHITE}GET / HTTP/1.1[crlf]Host: $current_domain[crlf]Upgrade: websocket[crlf]Connection: Upgrade[crlf][crlf]${NC}"
    echo ""
    echo -ne "${GREEN}◇ Press ENTER to return${NC}"; read
    domain_setup
}

domain_setup
