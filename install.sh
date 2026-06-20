#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Installer
# ============================================

clear

# Check root
[[ "$(whoami)" != "root" ]] && {
    echo -e "\033[1;33m[\033[1;31mError\033[1;33m] \033[1;37m- \033[1;33m◇ YOU NEED TO RUN AS ROOT!\033[0m"
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\033[1;31m\033[0m"
tput setaf 7; tput setab 4; tput bold
printf '%40s%s%-12s\n' "◇─────── SSH TUNNEL MANAGER ───────◇"
tput sgr0
echo -e "\033[1;31m◇──────────────────────────────────────────────────────◇\033[0m"
echo ""
echo -e "\033[1;31m◇ ATTENTION! ⚠️  \033[1;33m THIS SCRIPT CONTAINS THE FOLLOWING!!\033[0m"
echo ""
echo -e "\033[1;31m◇ \033[1;33mINSTALL A SET OF SCRIPTS AS TOOLS FOR\033[0m"
echo -e "\033[1;33mNETWORK, SYSTEM AND USER MANAGEMENT.\033[0m"
echo ""
echo -e "\033[1;32m◇ TIP! \033[1;33mUSE THE DARK THEME IN YOUR TERMINAL\033[0m"
echo -e "\033[1;33mFOR A BETTER EXPERIENCE AND VIEW!\033[0m"
echo ""
echo -e "\033[1;31m◇──────────── SSH TUNNEL MANAGER ────────────◇\033[0m"
echo ""

echo -ne "\033[1;36m◇ Want to continue? [Y/N]: \033[1;37m"
read x
[[ $x = @(n|N) ]] && exit 0

echo -e "\n\033[1;36m◇ STARTING INSTALLATION...\033[0m"
sleep 2

# Kill any existing apt processes to avoid lock issues
kill_apt_locks() {
    killall apt-get 2>/dev/null
    killall dpkg 2>/dev/null
    sleep 1
    rm -f /var/lib/apt/lists/lock 2>/dev/null
    rm -f /var/lib/dpkg/lock 2>/dev/null
    rm -f /var/lib/dpkg/lock-frontend 2>/dev/null
    rm -f /var/cache/apt/archives/lock 2>/dev/null
    dpkg --configure -a 2>/dev/null
}
kill_apt_locks

# Progress bar function
fun_bar() {
    local comando=("$1" "$2")
    (
        [[ -e $HOME/fim ]] && rm -f $HOME/fim
        eval "${comando[0]}" >/dev/null 2>&1
        [[ -n "${comando[1]}" ]] && eval "${comando[1]}" >/dev/null 2>&1
        touch $HOME/fim
    ) &
    tput civis
    echo -ne "  \033[1;33m◇ PLEASE WAIT... \033[1;37m- \033[1;33m["
    while true; do
        for ((i = 0; i < 18; i++)); do
            echo -ne "\033[1;31m#"
            sleep 0.1s
        done
        [[ -e $HOME/fim ]] && rm -f $HOME/fim && break
        echo -e "\033[1;33m]"
        sleep 1s
        tput cuu1
        tput dl1
        echo -ne "  \033[1;33m◇ PLEASE WAIT... \033[1;37m- \033[1;33m["
    done
    echo -e "\033[1;33m]\033[1;37m -\033[1;32m◇ DONE!\033[1;37m"
    tput cnorm
}

# Handle existing user database
[[ -f "$HOME/usuarios.db" ]] && {
    clear
    echo -e "\n\033[0;34m◇───────────────────────────────────────────────────◇\033[0m"
    echo ""
    echo -e "                 \033[1;33m• \033[1;31m◇ ATTENTION!\033[1;33m• \033[0m"
    echo ""
    echo -e "\033[1;33mA User Database \033[1;32m(usuarios.db) \033[1;33mwas"
    echo -e "Found! Want to keep it by preserving the"
    echo -e "connection limits of users? Or want to"
    echo -e "create a new database?\033[0m"
    echo -e "\n\033[1;37m[\033[1;31m1\033[1;37m] \033[1;33mKeep Current Database\033[0m"
    echo -e "\033[1;37m[\033[1;31m2\033[1;37m] \033[1;33mCreate a New Database\033[0m"
    echo -e "\n\033[0;34m◇───────────────────────────────────────────────────◇\033[0m"
    echo ""
    tput setaf 2; tput bold
    read -p "Option?: " -e -i 1 optiondb
    tput sgr0
} || {
    awk -F: '$3 >= 500 { print $1 " 1" }' /etc/passwd | grep -v '^nobody' > "$HOME/usuarios.db"
}

[[ "$optiondb" = '2' ]] && awk -F: '$3 >= 500 { print $1 " 1" }' /etc/passwd | grep -v '^nobody' > "$HOME/usuarios.db"

clear
tput setaf 7; tput setab 4; tput bold
printf '%35s%s%-18s\n' "◇ WAIT FOR INSTALLATION."
tput sgr0
echo ""

# Update system
echo -e "         \033[1;33m[\033[1;31m!\033[1;33m] \033[1;32m◇ UPDATING SYSTEM...\033[1;33m[\033[1;31m!\033[1;33m]\033[0m"
echo ""
echo -e "    \033[1;33m◇ UPDATES USUALLY TAKE A LITTLE TIME!\033[0m"
echo ""
fun_attlist() {
    apt-get update -y
    [[ ! -d /etc/SSHTunnelManager ]] && mkdir -p /etc/SSHTunnelManager
    [[ ! -d /etc/SSHTunnelManager/passwd ]] && mkdir -p /etc/SSHTunnelManager/passwd
}
fun_bar 'fun_attlist'

clear
echo ""
echo -e "          \033[1;33m[\033[1;31m!\033[1;33m] \033[1;32m◇ INSTALLING PACKAGES\033[1;33m[\033[1;31m!\033[1;33m] \033[0m"
echo ""
echo -e "\033[1;33m◇ SOME PACKAGES ARE EXTREMELY NECESSARY!\033[0m"
echo ""

# Install required packages
inst_pct() {
    _pacotes=("bc" "cron" "screen" "nano" "unzip" "lsof" "net-tools" "dos2unix" "nload" "jq" "curl" "figlet" "python3" "dnsutils")
    for _prog in "${_pacotes[@]}"; do
        apt install "$_prog" -y 2>/dev/null
    done
    pip install speedtest-cli 2>/dev/null || pip3 install speedtest-cli 2>/dev/null
}
fun_bar 'inst_pct'

# Configure firewall
[[ -f "/usr/sbin/ufw" ]] && {
    ufw allow 443/tcp
    ufw allow 80/tcp
    ufw allow 3128/tcp
    ufw allow 8799/tcp
    ufw allow 8080/tcp
}

clear
echo ""
echo -e "              \033[1;33m[\033[1;31m!\033[1;33m] \033[1;32m◇ FINISHING...\033[1;33m[\033[1;31m!\033[1;33m] \033[0m"
echo ""
echo -e "      \033[1;33m◇ COMPLETING FUNCTIONS AND SETTINGS!\033[0m"
echo ""

# Install scripts to system paths
fun_install_scripts() {
    # Create manager license file
    echo "SSH Tunnel Manager v1.0.0" > /usr/lib/sshtunnelmanager
    
    # Create menu command
    cat > /usr/local/bin/menu << 'MENUEOF'
#!/bin/bash
cd /root/ssltunnel && bash menu.sh
MENUEOF
    chmod +x /usr/local/bin/menu
    
    # Create shortcut symlinks
    ln -sf /usr/local/bin/menu /usr/bin/menu 2>/dev/null
    ln -sf /usr/local/bin/menu /usr/bin/h 2>/dev/null
    
    # Create autostart file
    [[ ! -f /etc/autostart ]] && touch /etc/autostart
    
    # Ensure /bin/false is in shells for SSH tunneling
    [[ $(grep -c "/bin/false" /etc/shells) = '0' ]] && echo "/bin/false" >> /etc/shells
    
    # Set proper permissions on all scripts
    chmod +x "$SCRIPT_DIR/menu.sh"
    chmod +x "$SCRIPT_DIR/install.sh"
    chmod +x "$SCRIPT_DIR/lib/functions.sh"
    find "$SCRIPT_DIR/modules/" -name "*.sh" -exec chmod +x {} \;
    
    # Store IP
    wget -qO- ipv4.icanhazip.com > /etc/SSHTunnelManager/IP 2>/dev/null
    
    # Copy proxy scripts to manager directory
    cp -f "$SCRIPT_DIR/lib/proxy.py" /etc/SSHTunnelManager/proxy.py 2>/dev/null
    cp -f "$SCRIPT_DIR/lib/wsproxy.py" /etc/SSHTunnelManager/wsproxy.py 2>/dev/null
    chmod +x /etc/SSHTunnelManager/proxy.py /etc/SSHTunnelManager/wsproxy.py 2>/dev/null
}
fun_bar 'fun_install_scripts'

clear
echo ""
IP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me 2>/dev/null)
echo -e "       \033[1;33m  \033[1;32m◇ INSTALLATION COMPLETED.◇\033[1;33m  \033[0m"
echo ""
echo -e "\033[1;33m◇ MAIN COMMAND: \033[1;32mmenu\033[0m"
echo ""
echo -e "\033[1;33m◇ You can type ${GREEN}menu${YELLOW} at any time to open the manager.${NC}"
echo ""
echo -e "\033[1;33m◇ Server IP: \033[1;32m$IP\033[0m"
echo ""
echo -e "\033[1;31m◇──────────── SSH TUNNEL MANAGER ────────────◇\033[0m"
echo ""

# Offer domain setup after installation
echo -ne "\033[1;36m◇ Do you want to set up a domain for WS-ePro now? [Y/N]: \033[1;37m"
read setup_domain
if [[ "$setup_domain" =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/modules/domain_setup.sh"
fi

echo ""
echo -e "\033[1;33m◇ Installation complete! Type \033[1;32mmenu\033[1;33m to start.\033[0m"
echo ""
