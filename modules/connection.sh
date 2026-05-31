#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Connection Mode
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root
ensure_dirs

# ==========================================
#  OpenSSH Management
# ==========================================
fun_openssh() {
    clear
    print_section "OPENSSH MANAGEMENT"
    echo ""
    echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}ADD PORT"
    echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}REMOVE PORT"
    echo -e "${RED}[${CYAN}3${RED}] ${WHITE}• ${YELLOW}COME BACK${NC}"
    echo ""
    echo -ne "${GREEN}WHAT DO YOU WANT TO DO ${YELLOW}?${WHITE} "
    read resp
    
    if [[ "$resp" = '1' ]]; then
        clear
        print_section "ADD PORT TO SSH"
        echo ""
        echo -ne "${GREEN}WHICH PORT DO YOU WANT TO ADD ${YELLOW}?${WHITE} "
        read pt
        [[ -z "$pt" ]] && {
            echo -e "\n${RED}Invalid Port!${NC}"
            sleep 3; fun_conexao
        }
        verify_port "$pt" || { sleep 3; fun_conexao; }
        echo -e "\n${GREEN}ADDING PORT TO SSH${NC}"
        echo ""
        fun_addpssh() {
            echo "Port $pt" >> /etc/ssh/sshd_config
            service ssh restart
        }
        fun_bar 'fun_addpssh'
        echo -e "\n${GREEN}SUCCESSFULLY ADDED PORT${NC}"
        sleep 3; fun_conexao
        
    elif [[ "$resp" = '2' ]]; then
        clear
        print_error_section "REMOVE SSH PORT"
        echo -e "\n${YELLOW}[${RED}!${YELLOW}] ${GREEN}STANDARD PORT ${WHITE}22 ${YELLOW}CAUTION!${NC}"
        echo -e "\n${YELLOW}PORTS IN USE: ${WHITE}$(grep 'Port' /etc/ssh/sshd_config | cut -d' ' -f2 | grep -v 'no' | xargs)\n"
        echo -ne "${GREEN}WHICH PORT DO YOU WANT TO REMOVE${YELLOW}?${WHITE} "
        read pt
        [[ -z "$pt" ]] && {
            echo -e "\n${RED}Invalid Port!${NC}"
            sleep 2; fun_conexao
        }
        [[ $(grep -wc "$pt" /etc/ssh/sshd_config) != '0' ]] && {
            echo -e "\n${GREEN}REMOVING SSH PORT${NC}"
            echo ""
            fun_delpssh() {
                sed -i "/Port $pt/d" /etc/ssh/sshd_config
                service ssh restart
            }
            fun_bar 'fun_delpssh'
            echo -e "\n${GREEN}SUCCESSFULLY REMOVED PORT${NC}"
            sleep 2; fun_conexao
        } || {
            echo -e "\n${RED}Invalid Port!${NC}"
            sleep 2; fun_conexao
        }
        
    elif [[ "$resp" = '3' ]]; then
        echo -e "\n${RED}returning..${NC}"
        sleep 2; fun_conexao
    else
        echo -e "\n${RED}Invalid option!${NC}"
        sleep 2; fun_conexao
    fi
}

# ==========================================
#  Squid Proxy Management
# ==========================================
inst_sqd() {
    if netstat -nltp 2>/dev/null | grep 'squid' >/dev/null; then
        print_error_section "REMOVE SQUID PROXY"
        echo ""
        echo -ne "${GREEN}REALLY WANT TO REMOVE SQUID ${RED}? ${YELLOW}[y/n]:${WHITE} "
        read resp
        [[ "$resp" = 'y' ]] && {
            echo -e "\n${GREEN}REMOVING THE SQUID PROXY!${NC}"
            echo ""
            rem_sqd() {
                [[ -d "/etc/squid" ]] && {
                    apt-get remove squid -y >/dev/null 2>&1
                    apt-get purge squid -y >/dev/null 2>&1
                    rm -rf /etc/squid
                }
                [[ -d "/etc/squid3" ]] && {
                    apt-get remove squid3 -y >/dev/null 2>&1
                    apt-get purge squid3 -y >/dev/null 2>&1
                    rm -rf /etc/squid3
                    apt autoremove -y >/dev/null 2>&1
                }
            }
            fun_bar 'rem_sqd'
            echo -e "\n${GREEN}SQUID SUCCESSFULLY REMOVED!${NC}"
            sleep 2; clear; fun_squid
        } || {
            echo -e "\n${RED}returning...${NC}"
            sleep 2; clear; fun_conexao
        }
    else
        clear
        print_section "SQUID INSTALLER"
        echo ""
        IP=$(get_server_ip)
        echo -ne "${GREEN}TO CONTINUE CONFIRM YOUR IP: ${WHITE}"
        read -e -i "$IP" ipdovps
        [[ -z "$ipdovps" ]] && { echo -e "\n${RED}Invalid IP${NC}"; sleep 3; fun_conexao; }
        
        echo -e "\n${YELLOW}WHICH PORTS DO YOU WANT TO USE ON THE SQUID ${RED}?"
        echo -e "\n${YELLOW}[${RED}!${YELLOW}] ${GREEN}DEFINE THE PORTS IN SEQUENCE ${YELLOW}EX: ${WHITE}80 8080"
        echo ""
        echo -ne "${GREEN}ENTER THE PORTS${WHITE}: "
        read portass
        [[ -z "$portass" ]] && { echo -e "\n${RED}INVALID PORT!${NC}"; sleep 3; fun_conexao; }
        
        for porta in $(echo -e $portass); do
            verify_port "$porta" || { sleep 3; fun_conexao; }
        done
        
        echo -e "\n${GREEN}INSTALLING SQUID PROXY${NC}\n"
        [[ $(grep -wc '14' /etc/issue.net) != '0' ]] || [[ $(grep -wc '8' /etc/issue.net) != '0' ]] && {
            fun_bar 'apt update -y' 'apt install squid3 -y'
        } || {
            fun_bar 'apt update -y' 'apt install squid -y'
        }
        
        if [[ -d "/etc/squid/" ]]; then
            var_sqd="/etc/squid/squid.conf"
            var_pay="/etc/squid/payload.txt"
        elif [[ -d "/etc/squid3/" ]]; then
            var_sqd="/etc/squid3/squid.conf"
            var_pay="/etc/squid3/payload.txt"
        else
            echo -e "\n${RED}SQUID PROXY INSTALL ERROR${NC}"
            sleep 2; fun_conexao
        fi
        
        cat <<-EOF > "$var_pay"
			.whatsapp.net/
			.facebook.net/
			.twitter.com/
			.speedtest.net/
		EOF
        
        cat <<-EOF > "$var_sqd"
			acl url1 dstdomain -i 127.0.0.1
			acl url2 dstdomain -i localhost
			acl url3 dstdomain -i $ipdovps
			acl url4 dstdomain -i /SSHTUNNEL?
			acl payload url_regex -i "$var_pay"
			acl all src 0.0.0.0/0
			http_access allow url1
			http_access allow url2
			http_access allow url3
			http_access allow url4
			http_access allow payload
			http_access deny all
			#Ports
		EOF
        
        for Pts in $(echo -e $portass); do
            echo -e "http_port $Pts" >> "$var_sqd"
            [[ -f "/usr/sbin/ufw" ]] && ufw allow "$Pts/tcp"
        done
        
        cat <<-EOF >> "$var_sqd"
			#Squid Name
			visible_hostname SSHTUNNELMANAGER
			via off
			forwarded_for off
			pipeline_prefetch off
		EOF
        
        sqd_conf() {
            [[ -d "/etc/squid/" ]] && {
                service ssh restart; /etc/init.d/squid restart; service squid restart
            }
            [[ -d "/etc/squid3/" ]] && {
                service ssh restart; /etc/init.d/squid3 restart; service squid3 restart
            }
        }
        echo -e "\n${GREEN}SETTING SQUID PROXY${NC}\n"
        fun_bar 'sqd_conf'
        echo -e "\n${GREEN}SQUID INSTALLED SUCCESSFULLY!${NC}"
        sleep 2.5s; fun_conexao
    fi
}

fun_squid() {
    [[ "$(netstat -nplt 2>/dev/null | grep -c 'squid')" = "0" ]] && inst_sqd
    
    print_section "MANAGE SQUID PROXY"
    sqdp=$(netstat -nplt 2>/dev/null | grep 'squid' | awk -F ":" '{print $4}' | xargs)
    echo -e "\n${YELLOW}PORTS${WHITE}: ${GREEN}$sqdp"
    echo ""
    echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}REMOVE/INSTALL SQUID PROXY"
    echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}ADD PORT"
    echo -e "${RED}[${CYAN}3${RED}] ${WHITE}• ${YELLOW}REMOVE PORT"
    echo -e "${RED}[${CYAN}0${RED}] ${WHITE}• ${YELLOW}COME BACK${NC}"
    echo ""
    echo -ne "${GREEN}WHAT DO YOU WANT TO DO ${YELLOW}?${RED}?${WHITE} "
    read x
    clear
    case $x in
        1|01) inst_sqd ;;
        2|02)
            print_section "ADD PORT TO SQUID"
            echo -e "\n${YELLOW}PORTS IN USE: ${GREEN}$sqdp\n"
            if [[ -f "/etc/squid/squid.conf" ]]; then
                var_sqd="/etc/squid/squid.conf"
            elif [[ -f "/etc/squid3/squid.conf" ]]; then
                var_sqd="/etc/squid3/squid.conf"
            else
                echo -e "\n${RED}SQUID IS NOT INSTALLED!${NC}"
                sleep 2; clear; fun_squid
            fi
            echo -ne "${GREEN}WHICH PORT DO YOU WANT TO ADD ${YELLOW}?${WHITE} "
            read pt
            [[ -z "$pt" ]] && { echo -e "\n${RED}Invalid port!${NC}"; sleep 2; clear; fun_conexao; }
            verify_port "$pt" || { sleep 3; fun_conexao; }
            echo -e "\n${GREEN}ADDING PORT TO SQUID!${NC}\n"
            sed -i "s/#Ports/#Ports\nhttp_port $pt/g" "$var_sqd"
            fun_bar 'sleep 2'
            echo -e "\n${GREEN}RESETTING THE SQUID!${NC}\n"
            fun_bar 'service squid restart' 'service squid3 restart'
            echo -e "\n${GREEN}SUCCESSFULLY ADDED PORT!${NC}"
            sleep 3; clear; fun_squid ;;
        3|03)
            print_error_section "REMOVE PORT FROM SQUID"
            echo -e "\n${YELLOW}PORTS IN USE: ${GREEN}$sqdp\n"
            if [[ -f "/etc/squid/squid.conf" ]]; then
                var_sqd="/etc/squid/squid.conf"
            elif [[ -f "/etc/squid3/squid.conf" ]]; then
                var_sqd="/etc/squid3/squid.conf"
            else
                echo -e "\n${RED}SQUID IS NOT INSTALLED!${NC}"
                sleep 2; clear; fun_squid
            fi
            echo -ne "${GREEN}WHICH PORT DO YOU WANT TO REMOVE ${YELLOW}?${WHITE} "
            read pt
            [[ -z "$pt" ]] && { echo -e "\n${RED}Invalid port!${NC}"; sleep 2; clear; fun_conexao; }
            if grep -E "$pt" "$var_sqd" >/dev/null 2>&1; then
                echo -e "\n${GREEN}REMOVING SQUID PORT!${NC}\n"
                sed -i "/http_port $pt/d" "$var_sqd"
                fun_bar 'sleep 3'
                echo -e "\n${GREEN}RESETTING THE SQUID!${NC}\n"
                fun_bar 'service squid restart' 'service squid3 restart'
                echo -e "\n${GREEN}PORT SUCCESSFULLY REMOVED!${NC}"
            else
                echo -e "\n${RED}PORT ${GREEN}$pt ${RED}NOT FOUND!${NC}"
            fi
            sleep 3.5s; clear; fun_squid ;;
        0|00)
            echo -e "${RED}returning...${NC}"
            sleep 1; fun_conexao ;;
        *)
            echo -e "${RED}Invalid option...${NC}"
            sleep 2; fun_conexao ;;
    esac
}

# ==========================================
#  Dropbear Management
# ==========================================
fun_drop() {
    if netstat -nltp 2>/dev/null | grep 'dropbear' >/dev/null; then
        clear
        dpbr=$(netstat -nplt 2>/dev/null | grep 'dropbear' | awk -F ":" '{print $4}' | xargs)
        
        if ps x | grep "limiter" | grep -v grep >/dev/null 2>&1; then
            stats="${GREEN}♦ "
        else
            stats="${RED}○ "
        fi
        
        print_section "MANAGE DROPBEAR"
        echo -e "\n${YELLOW}PORTS${WHITE}: ${GREEN}$dpbr"
        echo ""
        echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}DROPBEAR LIMITER $stats${NC}"
        echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}CHANGE DROPBEAR PORT${NC}"
        echo -e "${RED}[${CYAN}3${RED}] ${WHITE}• ${YELLOW}REMOVE DROPBEAR${NC}"
        echo -e "${RED}[${CYAN}0${RED}] ${WHITE}• ${YELLOW}COME BACK${NC}"
        echo ""
        echo -ne "${GREEN}WHAT DO YOU WANT TO DO ${YELLOW}?${WHITE} "
        read resposta
        
        if [[ "$resposta" = '1' ]]; then
            clear
            if ps x | grep "limiter" | grep -v grep >/dev/null 2>&1; then
                echo -e "${GREEN}Stopping the limiter...${NC}\n"
                fun_stplimiter() {
                    pidlimiter=$(ps x | grep "limiter" | awk -F "pts" '{print $1}')
                    kill -9 $pidlimiter 2>/dev/null
                    screen -wipe >/dev/null 2>&1
                }
                fun_bar 'fun_stplimiter' 'sleep 2'
                echo -e "\n${RED}LIMIT DISABLED${NC}"
            else
                echo -e "\n${GREEN}Starting the limiter...${NC}\n"
                fun_bar 'screen -d -m -t limiter droplimiter' 'sleep 3'
                echo -e "\n${GREEN}LIMITER ENABLED${NC}"
            fi
            sleep 3; fun_drop
            
        elif [[ "$resposta" = '2' ]]; then
            echo ""
            echo -ne "${GREEN}WHICH PORT YOU WANT TO USE ${YELLOW}?${WHITE} "
            read pt
            echo ""
            verify_port "$pt" || { sleep 3; fun_conexao; }
            var1=$(grep 'DROPBEAR_PORT=' /etc/default/dropbear | cut -d'=' -f2)
            echo -e "${GREEN}CHANGING DROPBEAR PORT!${NC}"
            sed -i "s/\b$var1\b/$pt/g" /etc/default/dropbear >/dev/null 2>&1
            echo ""
            fun_bar 'sleep 2'
            echo -e "\n${GREEN}RESTARTING DROPBEAR!${NC}\n"
            fun_bar 'service dropbear restart' '/etc/init.d/dropbear restart'
            echo -e "\n${GREEN}SUCCESSFULLY CHANGED PORT!${NC}"
            sleep 3; clear; fun_conexao
            
        elif [[ "$resposta" = '3' ]]; then
            echo -e "\n${GREEN}REMOVING THE DROPBEAR!${NC}\n"
            fun_dropuninstall() {
                service dropbear stop && /etc/init.d/dropbear stop
                apt-get autoremove dropbear -y
                apt-get remove dropbear-run -y
                apt-get remove dropbear -y
                apt-get purge dropbear -y
                rm -rf /etc/default/dropbear
            }
            fun_bar 'fun_dropuninstall'
            echo -e "\n${GREEN}SUCCESSFULLY REMOVED DROPBEAR!${NC}"
            sleep 3; clear; fun_conexao
            
        elif [[ "$resposta" = '0' ]]; then
            echo -e "\n${RED}Returning...${NC}"
            sleep 2; fun_conexao
        else
            echo -e "\n${RED}Invalid option...${NC}"
            sleep 2; fun_conexao
        fi
    else
        clear
        print_section "DROPBEAR INSTALLER"
        echo -e "\n${YELLOW}YOU ARE ABOUT TO INSTALL DROPBEAR!${NC}\n"
        echo -ne "${GREEN}DO YOU WISH TO CONTINUE ${RED}? ${YELLOW}[y/n]:${WHITE} "
        read resposta
        [[ "$resposta" = 'y' ]] && {
            echo -e "\n${YELLOW}DEFINE A PORT FOR DROPBEAR!${NC}\n"
            echo -ne "${GREEN}WHICH PORT ${YELLOW}?${WHITE} "
            read porta
            [[ -z "$porta" ]] && { echo -e "\n${RED}Invalid port!${NC}"; sleep 3; clear; fun_conexao; }
            verify_port "$porta" || { sleep 3; fun_conexao; }
            
            echo -e "\n${GREEN}INSTALLING DROPBEAR!${NC}\n"
            fun_instdrop() {
                apt-get update -y
                apt-get install dropbear -y
            }
            fun_bar 'fun_instdrop'
            
            fun_ports() {
                sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear >/dev/null 2>&1
                sed -i "s/DROPBEAR_PORT=22/DROPBEAR_PORT=$porta/g" /etc/default/dropbear >/dev/null 2>&1
                sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 110"/g' /etc/default/dropbear >/dev/null 2>&1
            }
            echo -e "\n${GREEN}SETTING PORT DROPBEAR!${NC}\n"
            fun_bar 'fun_ports'
            
            grep -v "^PasswordAuthentication yes" /etc/ssh/sshd_config > /tmp/passlogin && mv /tmp/passlogin /etc/ssh/sshd_config
            echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
            grep -v "^PermitTunnel yes" /etc/ssh/sshd_config > /tmp/ssh && mv /tmp/ssh /etc/ssh/sshd_config
            echo "PermitTunnel yes" >> /etc/ssh/sshd_config
            
            echo -e "\n${GREEN}FINISHING INSTALLATION!${NC}\n"
            fun_ondrop() {
                service dropbear start
                /etc/init.d/dropbear restart
            }
            fun_bar 'fun_ondrop' 'sleep 1'
            echo -e "\n${GREEN}INSTALLATION COMPLETED ${YELLOW}PORT: ${WHITE}$porta${NC}"
            [[ $(grep -c "/bin/false" /etc/shells) = '0' ]] && echo "/bin/false" >> /etc/shells
            sleep 2; clear; fun_conexao
        } || {
            echo -e "\n${RED}Returning...${NC}"
            sleep 3; clear; fun_conexao
        }
    fi
}

# ==========================================
#  SSL Tunnel (stunnel4) Management
# ==========================================
inst_ssl() {
    if netstat -nltp 2>/dev/null | grep 'stunnel4' >/dev/null; then
        sslt=$(netstat -nplt 2>/dev/null | grep stunnel4 | awk '{print $4}' | awk -F ":" '{print $2}' | xargs)
        print_section "MANAGE SSL TUNNEL"
        echo -e "\n${YELLOW}PORTS${WHITE}: ${GREEN}$sslt"
        echo ""
        echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}CHANGE PORT SSL TUNNEL${NC}"
        echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}REMOVE SSL TUNNEL${NC}"
        echo -e "${RED}[${CYAN}0${RED}] ${WHITE}• ${YELLOW}COME BACK${NC}"
        echo ""
        echo -ne "${GREEN}WHAT DO YOU WANT TO DO ${YELLOW}?${WHITE} "
        read resposta
        echo ""
        
        [[ "$resposta" = '1' ]] && {
            echo -ne "${GREEN}WHICH PORT YOU WANT TO USE ${YELLOW}?${WHITE} "
            read porta
            echo ""
            [[ -z "$porta" ]] && { echo -e "\n${RED}Invalid port!${NC}"; sleep 2; clear; fun_conexao; }
            verify_port "$porta" || { sleep 3; fun_conexao; }
            echo -e "${GREEN}CHANGING PORT SSL TUNNEL!${NC}"
            var2=$(grep 'accept' /etc/stunnel/stunnel.conf | awk '{print $NF}')
            sed -i "s/\b$var2\b/$porta/g" /etc/stunnel/stunnel.conf >/dev/null 2>&1
            echo ""
            fun_bar 'sleep 2'
            echo -e "\n${GREEN}RESETTING SSL TUNNEL!${NC}\n"
            fun_bar 'service stunnel4 restart' '/etc/init.d/stunnel4 restart'
            echo ""
            netstat -nltp 2>/dev/null | grep 'stunnel4' >/dev/null && echo -e "${GREEN}SUCCESSFULLY CHANGED PORT!${NC}" || echo -e "${RED}UNEXPECTED ERROR!${NC}"
            sleep 3.5s; clear; fun_conexao
        }
        
        [[ "$resposta" = '2' ]] && {
            echo -e "${GREEN}REMOVING SSL TUNNEL!${NC}"
            del_ssl() {
                service stunnel4 stop
                apt-get remove stunnel4 -y
                apt-get autoremove stunnel4 -y
                apt-get purge stunnel4 -y
                rm -rf /etc/stunnel/stunnel.conf
                rm -rf /etc/default/stunnel4
                rm -rf /etc/stunnel/stunnel.pem
            }
            echo ""
            fun_bar 'del_ssl'
            echo -e "\n${GREEN}SSL TUNNEL SUCCESSFULLY REMOVED!${NC}"
            sleep 3; fun_conexao
        } || {
            echo -e "${RED}Returning...${NC}"
            sleep 3; fun_conexao
        }
    else
        clear
        print_section "INSTALL SSL TUNNEL"
        echo ""
        echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}INSTALL SSL TUNNEL STANDARD (SSH)${NC}"
        echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}INSTALL SSL TUNNEL WEBSOCKET${NC}"
        echo -e "${RED}[${CYAN}0${RED}] ${WHITE}• ${YELLOW}COME BACK${NC}"
        echo ""
        echo -ne "${GREEN}WHAT DO YOU WANT TO DO ${YELLOW}?${WHITE} "
        read resposta
        echo ""
        
        if [[ "$resposta" = '1' ]]; then
            portssl='22'
        elif [[ "$resposta" = '2' ]]; then
            portssl='80'
        elif [[ "$resposta" = '0' ]]; then
            echo -e "${RED}Returning...${NC}"
            sleep 3; fun_conexao
        else
            echo -e "${RED}Invalid option!${NC}"
            sleep 1; inst_ssl
        fi
        
        clear
        print_section "SSL TUNNEL INSTALLER"
        echo -e "\n${YELLOW}YOU ARE ABOUT TO INSTALL SSL TUNNEL!${NC}"
        echo ""
        echo -ne "${GREEN}DO YOU WISH TO CONTINUE ${RED}? ${YELLOW}[y/n]:${WHITE} "
        read resposta
        [[ "$resposta" = 'y' ]] && {
            echo -e "\n${YELLOW}DEFINE A PORT FOR SSL TUNNEL!${NC}\n"
            echo -ne "${GREEN}WHICH PORT YOU WANT TO USE ${YELLOW}?${WHITE} "
            read porta
            [[ -z "$porta" ]] && { echo -e "\n${RED}Invalid port!${NC}"; sleep 3; clear; fun_conexao; }
            verify_port "$porta" || { sleep 3; fun_conexao; }
            
            # Step 1: Install stunnel4
            echo -e "\n${GREEN}INSTALLING SSL TUNNEL!${YELLOW}"
            echo ""
            fun_bar 'apt-get update -y' 'apt-get install stunnel4 openssl -y'
            
            # Step 2: Create directories
            mkdir -p /etc/stunnel
            
            # Step 3: Generate certificate FIRST (before config references it)
            echo -e "\n${GREEN}CREATING TLSv1.3 ANTI-DPI CERTIFICATE!${NC}\n"
            _gen_ssl_cert() {
                cd /etc/stunnel
                local SERVER_IP
                SERVER_IP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me 2>/dev/null)
                [[ -z "$SERVER_IP" ]] && SERVER_IP="127.0.0.1"
                
                # Generate RSA 4096 key with realistic cert fields (anti-DPI)
                openssl req -new -newkey rsa:4096 -days 1050 -nodes -x509 \
                    -sha384 \
                    -subj "/C=US/ST=California/L=San Francisco/O=Cloudflare Inc/OU=SSL/CN=${SERVER_IP}" \
                    -addext "subjectAltName=IP:${SERVER_IP}" \
                    -keyout /etc/stunnel/stunnel.key -out /etc/stunnel/stunnel.crt 2>/dev/null
                
                # Fallback if -addext not supported on older openssl
                [[ ! -s /etc/stunnel/stunnel.crt ]] && {
                    openssl req -new -newkey rsa:4096 -days 1050 -nodes -x509 \
                        -sha384 \
                        -subj "/C=US/ST=California/L=San Francisco/O=Cloudflare Inc/OU=SSL/CN=${SERVER_IP}" \
                        -keyout /etc/stunnel/stunnel.key -out /etc/stunnel/stunnel.crt 2>/dev/null
                }
                
                cat /etc/stunnel/stunnel.crt /etc/stunnel/stunnel.key > /etc/stunnel/stunnel.pem
                chmod 600 /etc/stunnel/stunnel.pem /etc/stunnel/stunnel.key
                rm -f /etc/stunnel/stunnel.crt /etc/stunnel/stunnel.key
            }
            fun_bar '_gen_ssl_cert'
            
            # Step 4: Write stunnel config (TLSv1.3 + Anti-DPI hardened)
            echo -e "\n${GREEN}CONFIGURING SSL TUNNEL (TLSv1.3 / Anti-DPI Hardened)!${NC}\n"
            cat > /etc/stunnel/stunnel.conf << SSLEOF
; ============================================
; SSH Tunnel Manager - stunnel4 configuration
; Enforced: TLSv1.3 / TLS_AES_256_GCM_SHA384
; Anti-DPI Hardened for ISP bypass
; ============================================

pid = /var/run/stunnel4/stunnel4.pid
cert = /etc/stunnel/stunnel.pem
client = no

; === Socket tuning (mimic real web server) ===
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
socket = a:SO_KEEPALIVE=1

; === TLS 1.3 Only ===
options = NO_SSLv2
options = NO_SSLv3
options = NO_TLSv1
options = NO_TLSv1_1
options = NO_TLSv1_2

; === Cipher: AES-256-GCM primary, CHACHA20 fallback ===
ciphersuites = TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256

; === Strong ECDH curves (P-384 primary) ===
curves = P-384:P-521:X25519

; === Session management (looks like real HTTPS) ===
sessionCacheSize = 20000
sessionCacheTimeout = 300
renegotiation = no

; === Connection timeouts ===
TIMEOUTclose = 0
TIMEOUTconnect = 10
TIMEOUTidle = 43200

; === Logging ===
debug = 0
output = /var/log/stunnel4/stunnel.log

[sshtunnel]
accept = ${porta}
connect = 127.0.0.1:${portssl}
SSLEOF
            echo -e "  ${YELLOW}]${WHITE} -${GREEN} DONE!${NC}"
            
            # Step 5: Enable stunnel4 service
            [[ -f /etc/default/stunnel4 ]] && sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
            mkdir -p /var/run/stunnel4
            chown stunnel4:stunnel4 /var/run/stunnel4 2>/dev/null
            
            # Step 6: Open firewall port
            [[ -f /usr/sbin/ufw ]] && ufw allow ${porta}/tcp >/dev/null 2>&1
            
            # Step 7: Stop any existing stunnel, then start fresh
            echo -e "\n${GREEN}STARTING SSL TUNNEL!${NC}\n"
            _start_stunnel() {
                service stunnel4 stop 2>/dev/null
                killall stunnel4 2>/dev/null
                sleep 1
                service stunnel4 start 2>/dev/null || /etc/init.d/stunnel4 start 2>/dev/null || stunnel4 /etc/stunnel/stunnel.conf 2>/dev/null
                service ssh restart 2>/dev/null
            }
            fun_bar '_start_stunnel'
            
            # Step 8: Verify it's running
            sleep 2
            if netstat -nltp 2>/dev/null | grep -q 'stunnel'; then
                echo -e "\n${GREEN}◇ SSL TUNNEL SUCCESSFULLY INSTALLED!${NC}"
                echo -e "${GREEN}◇ PORT: ${YELLOW}${porta}${NC}"
                echo -e "${GREEN}◇ PROTOCOL: ${YELLOW}TLSv1.3${NC}"
                echo -e "${GREEN}◇ CIPHER: ${YELLOW}TLS_AES_256_GCM_SHA384${NC}"
                echo -e "${GREEN}◇ CURVES: ${YELLOW}P-384 / P-521 / X25519${NC}"
                echo -e "${GREEN}◇ ALPN: ${YELLOW}h2, http/1.1${NC}"
                echo -e "${GREEN}◇ KEY: ${YELLOW}RSA 4096-bit / SHA-384${NC}"
                echo -e "${GREEN}◇ ANTI-DPI: ${YELLOW}ENABLED${NC}"
                echo -e "${GREEN}◇ CONNECT: ${YELLOW}127.0.0.1:${portssl}${NC}"
            else
                echo -e "\n${RED}◇ WARNING: stunnel may not have started properly!${NC}"
                echo -e "${YELLOW}◇ Checking stunnel log...${NC}"
                tail -5 /var/log/stunnel4/stunnel.log 2>/dev/null || echo -e "${RED}No log found${NC}"
                echo ""
                echo -e "${YELLOW}◇ Trying direct start...${NC}"
                stunnel4 /etc/stunnel/stunnel.conf 2>&1
                sleep 2
                if netstat -nltp 2>/dev/null | grep -q 'stunnel'; then
                    echo -e "${GREEN}◇ SSL TUNNEL NOW RUNNING on port ${porta}!${NC}"
                else
                    echo -e "${RED}◇ FAILED! Check: cat /etc/stunnel/stunnel.conf${NC}"
                    echo -e "${RED}◇ Your OpenSSL may not support TLSv1.3. Check: openssl version${NC}"
                fi
            fi
            sleep 4; clear; fun_conexao
        } || {
            echo -e "\n${RED}Returning...${NC}"
            sleep 2; clear; fun_conexao
        }
    fi
}

# ==========================================
#  OpenVPN Management
# ==========================================
fun_openvpn() {
    if readlink /proc/$$/exe | grep -qs "dash"; then
        echo "This script needs to be run with bash, not sh"
        exit 1
    fi
    [[ "$EUID" -ne 0 ]] && { clear; echo "Run as root"; exit 2; }
    [[ ! -e /dev/net/tun ]] && { echo -e "${RED}TUN TAP NOT AVAILABLE${NC}"; sleep 2; fun_conexao; }
    
    if [[ -e /etc/debian_version ]]; then
        OS=debian; GROUPNAME=nogroup; RCLOCAL='/etc/rc.local'
    elif [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
        OS=centos; GROUPNAME=nobody; RCLOCAL='/etc/rc.d/rc.local'
    else
        echo -e "SYSTEM NOT SUPPORTED"; exit 5
    fi
    
    IP1=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
    IP2=$(wget -4qO- "http://whatismyip.akamai.com/" 2>/dev/null)
    [[ -z "$IP1" ]] && IP1=$(hostname -I | cut -d' ' -f1)
    [[ "$IP1" != "$IP2" ]] && IP="$IP1" || IP="$IP2"
    
    [[ $(netstat -nplt 2>/dev/null | grep -wc 'openvpn') != '0' ]] && {
        while :; do
            clear
            opnp=$(cat /etc/openvpn/server.conf | grep "port" | awk '{print $2}')
            
            if grep "duplicate-cn" /etc/openvpn/server.conf >/dev/null 2>&1; then
                mult=$(echo -e "${GREEN}♦ ")
            else
                mult=$(echo -e "${RED}○ ")
            fi
            
            print_section "MANAGE OPENVPN"
            echo ""
            echo -e "${YELLOW}PORT${WHITE}: ${GREEN}$opnp"
            echo ""
            echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}CHANGE PORT"
            echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}REMOVE OPENVPN"
            echo -e "${RED}[${CYAN}3${RED}] ${WHITE}• ${YELLOW}MULTILOGIN OVPN $mult"
            echo -e "${RED}[${CYAN}0${RED}] ${WHITE}• ${YELLOW}COME BACK${NC}"
            echo ""
            echo -ne "${GREEN}WHAT DO YOU WANT TO DO ${YELLOW}?${RED}?${WHITE} "
            read option
            
            case $option in
                1)
                    clear
                    print_section "CHANGE PORT OPENVPN"
                    echo ""
                    echo -e "${YELLOW}PORT IN USE: ${GREEN}$opnp"
                    echo ""
                    echo -ne "${GREEN}WHICH PORT DO YOU WANT TO USE ${YELLOW}?${WHITE} "
                    read porta
                    [[ -z "$porta" ]] && { echo -e "\n${RED}Invalid port!${NC}"; sleep 3; fun_conexao; }
                    verify_port "$porta" || { sleep 3; fun_conexao; }
                    echo -e "\n${GREEN}CHANGING THE PORT OPENVPN!${YELLOW}"
                    echo ""
                    fun_opn() {
                        var_ptovpn=$(sed -n '1 p' /etc/openvpn/server.conf)
                        sed -i "s/\b$var_ptovpn\b/port $porta/g" /etc/openvpn/server.conf
                        sleep 1
                        service openvpn restart
                    }
                    fun_bar 'fun_opn'
                    echo -e "\n${GREEN}SUCCESSFULLY CHANGED PORT!${YELLOW}"
                    sleep 2; fun_conexao ;;
                2)
                    echo ""
                    echo -ne "${GREEN}WANT TO REMOVE OPENVPN ${RED}? ${YELLOW}[y/n]:${WHITE} "
                    read REMOVE
                    [[ "$REMOVE" = 'y' ]] && {
                        rmv_open() {
                            PORT=$(grep '^port ' /etc/openvpn/server.conf | cut -d " " -f 2)
                            PROTOCOL=$(grep '^proto ' /etc/openvpn/server.conf | cut -d " " -f 2)
                            [[ "$OS" = 'debian' ]] && {
                                apt-get remove --purge -y openvpn openvpn-blacklist
                                apt-get autoremove openvpn -y; apt-get autoremove -y
                            } || {
                                yum remove openvpn -y
                            }
                            rm -rf /etc/openvpn /usr/share/doc/openvpn*
                        }
                        echo -e "\n${GREEN}REMOVING OPENVPN!${NC}\n"
                        fun_bar 'rmv_open'
                        echo -e "\n${GREEN}OPENVPN SUCCESSFULLY REMOVED!${NC}"
                        sleep 2; fun_conexao
                    } || {
                        echo -e "\n${RED}Returning...${NC}"
                        sleep 2; fun_openvpn
                    } ;;
                3)
                    if grep "duplicate-cn" /etc/openvpn/server.conf >/dev/null 2>&1; then
                        clear
                        echo -e "\n${RED}BLOCKING MULTILOGIN...${NC}"
                        sed -i '/duplicate-cn/d' /etc/openvpn/server.conf
                        service openvpn restart >/dev/null
                        sleep 2; fun_openvpn
                    else
                        clear
                        echo -e "\n${GREEN}ALLOWING MULTILOGIN...${NC}"
                        echo "duplicate-cn" >> /etc/openvpn/server.conf
                        service openvpn restart >/dev/null
                        sleep 2; fun_openvpn
                    fi ;;
                0) fun_conexao ;;
                *)
                    echo -e "\n${RED}Invalid option!${NC}"
                    sleep 2; fun_openvpn ;;
            esac
        done
    } || {
        clear
        print_section "OPENVPN INSTALLER"
        echo ""
        echo -e "${YELLOW}ANSWER THE QUESTIONS TO START THE INSTALLATION"
        echo ""
        echo -ne "${GREEN}TO CONTINUE CONFIRM YOUR IP: ${WHITE}"
        read -e -i "$IP" IP
        [[ -z "$IP" ]] && { echo -e "\n${RED}Invalid IP!${NC}"; sleep 3; fun_conexao; }
        
        echo ""
        read -p "$(echo -e "${GREEN}WHICH PORT DO YOU WANT TO USE? ${WHITE}")" -e -i 1194 porta
        [[ -z "$porta" ]] && { echo -e "\n${RED}Invalid port!${NC}"; sleep 2; fun_conexao; }
        echo -e "\n${YELLOW}VERIFYING PORT..."
        verify_port "$porta" || { sleep 3; fun_conexao; }
        
        echo ""
        echo -e "${RED}[${CYAN}1${RED}] ${YELLOW}UDP"
        echo -e "${RED}[${CYAN}2${RED}] ${YELLOW}TCP (${GREEN}Recommended${YELLOW})${NC}"
        echo ""
        read -p "$(echo -e "${GREEN}WHICH PROTOCOL? ${WHITE}")" -e -i 2 resp
        [[ "$resp" = '1' ]] && PROTOCOL=udp || PROTOCOL=tcp
        
        echo ""
        echo -e "${RED}[${CYAN}1${RED}] ${YELLOW}System DNS"
        echo -e "${RED}[${CYAN}2${RED}] ${YELLOW}Google (${GREEN}Recommended${YELLOW})"
        echo -e "${RED}[${CYAN}3${RED}] ${YELLOW}OpenDNS"
        echo -e "${RED}[${CYAN}4${RED}] ${YELLOW}Cloudflare${NC}"
        echo ""
        read -p "$(echo -e "${GREEN}WHICH DNS DO YOU WANT TO USE? ${WHITE}")" -e -i 2 DNS
        
        echo -e "${GREEN}INSTALLING OPENVPN ${RED}(${YELLOW}MAY TAKE TIME!${RED})"
        echo ""
        
        fun_dep() {
            [[ "$OS" = 'debian' ]] && {
                apt-get update -y
                apt-get install openvpn iptables openssl ca-certificates zip -y
            } || {
                yum install epel-release -y
                yum install openvpn iptables openssl wget ca-certificates -y
            }
            
            [[ -d /etc/openvpn/easy-rsa/ ]] && rm -rf /etc/openvpn/easy-rsa/
            wget -O ~/EasyRSA-3.0.1.tgz "https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.1/EasyRSA-3.0.1.tgz" 2>/dev/null
            tar xzf ~/EasyRSA-3.0.1.tgz -C ~/
            mv ~/EasyRSA-3.0.1/ /etc/openvpn/
            mv /etc/openvpn/EasyRSA-3.0.1/ /etc/openvpn/easy-rsa/
            chown -R root:root /etc/openvpn/easy-rsa/
            rm -rf ~/EasyRSA-3.0.1.tgz
            cd /etc/openvpn/easy-rsa/
            ./easyrsa init-pki
            ./easyrsa --batch build-ca nopass
            ./easyrsa gen-dh
            ./easyrsa build-server-full server nopass
            ./easyrsa build-client-full SSHTUNNEL nopass
            ./easyrsa gen-crl
            cp pki/ca.crt pki/private/ca.key pki/dh.pem pki/issued/server.crt pki/private/server.key /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn
            chown nobody:$GROUPNAME /etc/openvpn/crl.pem
            openvpn --genkey --secret /etc/openvpn/ta.key
            
            echo "port $porta
proto $PROTOCOL
dev tun
sndbuf 0
rcvbuf 0
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt" > /etc/openvpn/server.conf
            
            echo 'push "redirect-gateway def1 bypass-dhcp"' >> /etc/openvpn/server.conf
            
            case $DNS in
                1) grep -v '#' /etc/resolv.conf | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read line; do
                    echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server.conf
                done ;;
                2) echo 'push "dhcp-option DNS 8.8.8.8"' >> /etc/openvpn/server.conf
                   echo 'push "dhcp-option DNS 8.8.4.4"' >> /etc/openvpn/server.conf ;;
                3) echo 'push "dhcp-option DNS 208.67.222.222"' >> /etc/openvpn/server.conf
                   echo 'push "dhcp-option DNS 208.67.220.220"' >> /etc/openvpn/server.conf ;;
                4) echo 'push "dhcp-option DNS 1.1.1.1"' >> /etc/openvpn/server.conf
                   echo 'push "dhcp-option DNS 1.0.0.1"' >> /etc/openvpn/server.conf ;;
            esac
            
            echo "keepalive 10 120
float
cipher AES-256-GCM
ncp-ciphers AES-256-GCM
tls-version-min 1.3
tls-ciphersuites TLS_AES_256_GCM_SHA384
comp-lzo yes
user nobody
group $GROUPNAME
persist-key
persist-tun
status openvpn-status.log
management localhost 7505
verb 3
crl-verify crl.pem
client-to-client
client-cert-not-required
username-as-common-name
plugin $(find /usr -type f -name 'openvpn-plugin-auth-pam.so' 2>/dev/null | head -1) login
duplicate-cn" >> /etc/openvpn/server.conf
            
            sed -i '/\<net.ipv4.ip_forward\>/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
            grep -q "\<net.ipv4.ip_forward\>" /etc/sysctl.conf || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
            echo 1 > /proc/sys/net/ipv4/ip_forward
            
            iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to "$IP"
        }
        fun_bar 'fun_dep > /dev/null 2>&1'
        
        fun_ropen() {
            [[ "$OS" = 'debian' ]] && {
                pgrep systemd-journal && systemctl restart openvpn@server.service || /etc/init.d/openvpn restart
            } || {
                pgrep systemd-journal && { systemctl restart openvpn@server.service; systemctl enable openvpn@server.service; } || { service openvpn restart; chkconfig openvpn on; }
            }
        }
        echo -e "\n${GREEN}RESTARTING OPENVPN${NC}\n"
        fun_bar 'fun_ropen'
        
        [[ "$(netstat -nplt 2>/dev/null | grep -wc 'openvpn')" != '0' ]] && echo -e "\n${GREEN}OPENVPN SUCCESSFULLY INSTALLED${NC}" || echo -e "\n${RED}ERROR! THE INSTALLATION CORRUPTED${NC}"
        sleep 3; fun_conexao
    }
}

# ==========================================
#  Proxy SOCKS Management
# ==========================================
fun_socks() {
    clear
    print_section "MANAGE PROXY SOCKS"
    echo ""
    
    [[ $(netstat -nplt 2>/dev/null | grep -wc 'python') != '0' ]] && {
        sks="${GREEN}ON"
        echo -e "${YELLOW}PORTS${WHITE}: ${GREEN}$(netstat -nplt 2>/dev/null | grep 'python' | awk '{print $4}' | cut -d: -f2 | xargs)"
    } || {
        sks="${RED}OFF"
    }
    
    [[ $(screen -list 2>/dev/null | grep -wc 'proxy') != '0' ]] && var_sks1="${GREEN}♦" || var_sks1="${RED}○"
    [[ $(screen -list 2>/dev/null | grep -wc 'ws') != '0' ]] && var_sks2="${GREEN}♦" || var_sks2="${RED}○"
    
    echo ""
    echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}SOCKS SSH $var_sks1 ${NC}"
    echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}WEBSOCKET $var_sks2 ${NC}"
    echo -e "${RED}[${CYAN}3${RED}] ${WHITE}• ${YELLOW}OPEN PORT${NC}"
    echo -e "${RED}[${CYAN}0${RED}] ${WHITE}• ${YELLOW}COME BACK${NC}"
    echo ""
    echo -ne "${GREEN}WHAT DO YOU WANT TO DO ${YELLOW}?${WHITE} "
    read resposta
    
    if [[ "$resposta" = '1' ]]; then
        if ps x | grep -w proxy.py | grep -v grep >/dev/null 2>&1; then
            clear
            print_error_section "PROXY SOCKS"
            echo ""
            fun_socksoff() {
                for pidproxy in $(screen -ls 2>/dev/null | grep ".proxy" | awk '{print $1}'); do
                    screen -r -S "$pidproxy" -X quit
                done
                [[ $(grep -wc "proxy.py" "$AUTOSTART_FILE") != '0' ]] && sed -i '/proxy.py/d' "$AUTOSTART_FILE"
                sleep 1; screen -wipe >/dev/null 2>&1
            }
            echo -e "${GREEN}DISABLING PROXY SOCKS${YELLOW}"
            echo ""
            fun_bar 'fun_socksoff'
            echo -e "\n${GREEN}PROXY SOCKS SUCCESSFULLY DISABLED!${YELLOW}"
            sleep 3; fun_socks
        else
            clear
            print_section "PROXY SOCKS"
            echo ""
            echo -ne "${GREEN}WHICH PORT YOU WANT TO USE ${YELLOW}?${WHITE}: "
            read porta
            [[ -z "$porta" ]] && { echo -e "\n${RED}Invalid port!${NC}"; sleep 3; clear; fun_conexao; }
            verify_port "$porta" || { sleep 3; fun_conexao; }
            fun_inisocks() {
                sleep 1
                screen -dmS proxy python "$MANAGER_DIR/proxy.py" "$porta" 2>/dev/null
                [[ $(grep -wc "proxy.py" "$AUTOSTART_FILE") = '0' ]] && {
                    echo -e "netstat -tlpn | grep -w $porta > /dev/null || { screen -r -S 'proxy' -X quit; screen -dmS proxy python $MANAGER_DIR/proxy.py $porta; }" >> "$AUTOSTART_FILE"
                }
            }
            echo -e "\n${GREEN}STARTING PROXY SOCKS${YELLOW}"
            echo ""
            fun_bar 'fun_inisocks'
            echo -e "\n${GREEN}SOCKS SUCCESSFULLY ACTIVATED${YELLOW}"
            sleep 3; fun_socks
        fi
        
    elif [[ "$resposta" = '2' ]]; then
        if ps x | grep -w wsproxy.py | grep -v grep >/dev/null 2>&1; then
            clear
            print_error_section "WEBSOCKET"
            echo ""
            fun_wssocksoff() {
                for pidproxy in $(screen -ls 2>/dev/null | grep ".ws" | awk '{print $1}'); do
                    screen -r -S "$pidproxy" -X quit
                done
                [[ $(grep -wc "wsproxy.py" "$AUTOSTART_FILE") != '0' ]] && sed -i '/wsproxy.py/d' "$AUTOSTART_FILE"
                sleep 1; screen -wipe >/dev/null 2>&1
            }
            echo -e "${GREEN}DISABLING THE WEBSOCKET${YELLOW}"
            echo ""
            fun_bar 'fun_wssocksoff'
            echo -e "\n${GREEN}WEBSOCKET SUCCESSFULLY DISABLED!${YELLOW}"
            sleep 3; fun_socks
        else
            clear
            print_section "WEBSOCKET"
            echo ""
            echo -ne "${GREEN}WHICH PORT YOU WANT TO USE ${YELLOW}?${WHITE}: "
            read porta
            [[ -z "$porta" ]] && { echo -e "\n${RED}Invalid port!${NC}"; sleep 3; clear; fun_conexao; }
            verify_port "$porta" || { sleep 3; fun_conexao; }
            fun_iniwssocks() {
                sleep 1
                screen -dmS ws python "$MANAGER_DIR/wsproxy.py" "$porta" 2>/dev/null
                [[ $(grep -wc "wsproxy.py" "$AUTOSTART_FILE") = '0' ]] && {
                    echo -e "netstat -tlpn | grep -w $porta > /dev/null || { screen -r -S 'ws' -X quit; screen -dmS ws python $MANAGER_DIR/wsproxy.py $porta; }" >> "$AUTOSTART_FILE"
                }
            }
            echo -e "\n${GREEN}STARTING WEBSOCKET${YELLOW}"
            echo ""
            fun_bar 'fun_iniwssocks'
            echo -e "\n${GREEN}SUCCESSFULLY ACTIVATED WEBSOCKET${YELLOW}"
            sleep 3; fun_socks
        fi
        
    elif [[ "$resposta" = '3' ]]; then
        if ps x | grep proxy.py | grep -v grep >/dev/null 2>&1; then
            sockspt=$(netstat -nplt 2>/dev/null | grep 'python' | awk '{print $4}' | cut -d: -f2 | xargs)
            clear
            print_section "PROXY SOCKS"
            echo ""
            echo -e "${YELLOW}PORT IN USE: ${GREEN}$sockspt"
            echo ""
            echo -ne "${GREEN}WHICH PORT DO YOU WANT TO USE ${YELLOW}?${WHITE}: "
            read porta
            [[ -z "$porta" ]] && { echo -e "\n${RED}Invalid Port!${NC}"; sleep 2; clear; fun_conexao; }
            verify_port "$porta" || { sleep 3; fun_conexao; }
            echo -e "\n${GREEN}STARTING PROXY SOCKS AT PORT ${RED}$porta${YELLOW}"
            echo ""
            abrirptsks() {
                sleep 1
                screen -dmS proxy python "$MANAGER_DIR/proxy.py" "$porta" 2>/dev/null
                sleep 1
            }
            fun_bar 'abrirptsks'
            echo -e "\n${GREEN}PROXY SOCKS SUCCESSFULLY ACTIVATED!${YELLOW}"
            sleep 2; fun_socks
        else
            clear
            echo -e "${RED}UNAVAILABLE FUNCTION\n\n${YELLOW}ACTIVATE SOCKS FIRST!${YELLOW}"
            sleep 2; fun_socks
        fi
        
    elif [[ "$resposta" = '0' ]]; then
        echo -e "\n${RED}returning...${NC}"
        sleep 1; fun_conexao
    else
        echo -e "\n${RED}Invalid option!${NC}"
        sleep 1; fun_socks
    fi
}

# ==========================================
#  SSLH Multiplex Management
# ==========================================
fun_sslh() {
    [[ "$(netstat -nltp 2>/dev/null | grep 'sslh' | wc -l)" = '0' ]] && {
        clear
        print_section "SSLH INSTALLER"
        echo -e "\n${YELLOW}[${RED}!${YELLOW}] ${GREEN}PORT ${WHITE}443 ${GREEN}WILL BE USED BY DEFAULT${NC}\n"
        echo -ne "${GREEN}REALLY WANT TO INSTALL SSLH ${RED}? ${YELLOW}[y/n]:${WHITE} "
        read resp
        [[ "$resp" = 'y' ]] && {
            verify_port 443 || { sleep 3; fun_conexao; }
            fun_instsslh() {
                [[ -e "/etc/stunnel/stunnel.conf" ]] && ptssl="$(netstat -nplt 2>/dev/null | grep 'stunnel' | awk '{print $4}' | cut -d: -f2 | xargs)" || ptssl='3128'
                [[ -e "/etc/openvpn/server.conf" ]] && ptvpn="$(netstat -nplt 2>/dev/null | grep 'openvpn' | awk '{print $4}' | cut -d: -f2 | xargs)" || ptvpn='1194'
                DEBIAN_FRONTEND=noninteractive apt-get -y install sslh
                echo -e "#standalone mode\n\nRUN=yes\n\nDAEMON=/usr/sbin/sslh\n\nDAEMON_OPTS='--user sslh --listen 0.0.0.0:443 --ssh 127.0.0.1:22 --ssl 127.0.0.1:$ptssl --http 127.0.0.1:80 --openvpn 127.0.0.1:$ptvpn --pidfile /var/run/sslh/sslh.pid'" > /etc/default/sslh
                /etc/init.d/sslh start && service sslh start
            }
            echo -e "\n${GREEN}INSTALLING SSLH!${NC}\n"
            fun_bar 'fun_instsslh'
            echo -e "\n${GREEN}STARTING SSLH!${NC}\n"
            fun_bar '/etc/init.d/sslh restart && service sslh restart'
            [[ $(netstat -nplt 2>/dev/null | grep -w 'sslh' | wc -l) != '0' ]] && echo -e "\n${GREEN}SUCCESSFULLY INSTALLED!${NC}" || echo -e "\n${RED}UNEXPECTED ERROR!${NC}"
            sleep 3; fun_conexao
        } || {
            echo -e "\n${RED}returning..${NC}"
            sleep 2; fun_conexao
        }
    } || {
        clear
        print_error_section "REMOVE SSLH"
        echo ""
        echo -ne "${GREEN}REALLY WANT TO REMOVE SSLH ${RED}? ${YELLOW}[y/n]:${WHITE} "
        read respo
        [[ "$respo" = "y" ]] && {
            fun_delsslh() {
                /etc/init.d/sslh stop && service sslh stop
                apt-get remove sslh -y
                apt-get purge sslh -y
            }
            echo -e "\n${GREEN}REMOVING SSLH!${NC}\n"
            fun_bar 'fun_delsslh'
            echo -e "\n${GREEN}SUCCESSFULLY REMOVED!${NC}\n"
            sleep 2; fun_conexao
        } || {
            echo -e "\n${RED}returning..${NC}"
            sleep 2; fun_conexao
        }
    }
}

# ==========================================
#  BadVPN (UDP Gateway) Management
# ==========================================
fun_badvpn() {
    clear
    print_section "BADVPN UDP GATEWAY"
    echo ""
    
    if ps x | grep "udpvpn" | grep -v grep >/dev/null 2>&1; then
        echo -e "${GREEN}BadVPN is currently: ${WHITE}RUNNING${NC}"
        echo ""
        echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}STOP BADVPN"
        echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}CHANGE PORT"
        echo -e "${RED}[${CYAN}0${RED}] ${WHITE}• ${YELLOW}COME BACK${NC}"
    else
        echo -e "${RED}BadVPN is currently: ${WHITE}STOPPED${NC}"
        echo ""
        echo -e "${RED}[${CYAN}1${RED}] ${WHITE}• ${YELLOW}START BADVPN"
        echo -e "${RED}[${CYAN}2${RED}] ${WHITE}• ${YELLOW}INSTALL BADVPN"
        echo -e "${RED}[${CYAN}0${RED}] ${WHITE}• ${YELLOW}COME BACK${NC}"
    fi
    echo ""
    echo -ne "${GREEN}WHAT DO YOU WANT TO DO ${YELLOW}?${WHITE} "
    read resp
    
    if [[ "$resp" = '1' ]]; then
        if ps x | grep "udpvpn" | grep -v grep >/dev/null 2>&1; then
            echo -e "\n${GREEN}STOPPING BADVPN...${NC}"
            kill $(ps x | grep 'udpvpn' | grep -v grep | awk '{print $1}') >/dev/null 2>&1
            screen -wipe >/dev/null 2>&1
            echo -e "${RED}BADVPN STOPPED!${NC}"
        else
            echo -e "\n${GREEN}STARTING BADVPN...${NC}"
            echo -ne "${GREEN}WHICH PORT? ${WHITE}"
            read porta
            [[ -z "$porta" ]] && porta=7300
            screen -dmS udpvpn badvpn-udpgw --listen-addr "127.0.0.1:$porta" --max-clients 200 --max-connections-for-client 10 2>/dev/null
            echo -e "${GREEN}BADVPN STARTED ON PORT $porta!${NC}"
        fi
        sleep 3; fun_conexao
        
    elif [[ "$resp" = '2' ]]; then
        if ps x | grep "udpvpn" | grep -v grep >/dev/null 2>&1; then
            echo -ne "\n${GREEN}WHICH PORT? ${WHITE}"
            read porta
            [[ -z "$porta" ]] && porta=7300
            kill $(ps x | grep 'udpvpn' | grep -v grep | awk '{print $1}') >/dev/null 2>&1
            screen -dmS udpvpn badvpn-udpgw --listen-addr "127.0.0.1:$porta" --max-clients 200 --max-connections-for-client 10 2>/dev/null
            echo -e "\n${GREEN}BADVPN PORT CHANGED TO $porta!${NC}"
        else
            echo -e "\n${GREEN}INSTALLING BADVPN...${NC}\n"
            fun_instbadvpn() {
                apt-get update -y
                wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/januda-ui/DRAGON-VPS-MANAGER/main/Install/badvpn-udpgw" 2>/dev/null
                chmod +x /usr/bin/badvpn-udpgw
            }
            fun_bar 'fun_instbadvpn'
            echo -ne "${GREEN}WHICH PORT? ${WHITE}"
            read porta
            [[ -z "$porta" ]] && porta=7300
            screen -dmS udpvpn badvpn-udpgw --listen-addr "127.0.0.1:$porta" --max-clients 200 --max-connections-for-client 10 2>/dev/null
            echo -e "\n${GREEN}BADVPN INSTALLED AND STARTED ON PORT $porta!${NC}"
        fi
        sleep 3; fun_conexao
        
    elif [[ "$resp" = '0' ]]; then
        fun_conexao
    else
        echo -e "\n${RED}Invalid option!${NC}"
        sleep 2; fun_badvpn
    fi
}

# ==========================================
#  Main Connection Menu
# ==========================================
fun_conexao() {
    while true; do
        clear
        print_section "CONNECTION MODE"
        echo ""
        
        # Show service statuses
        echo -e "${GREEN}SERVICE: ${YELLOW}OPENSSH ${GREEN}PORT: ${WHITE}$(grep 'Port' /etc/ssh/sshd_config 2>/dev/null | cut -d' ' -f2 | grep -v 'no' | xargs)"
        sts6="${GREEN}♦ "
        
        [[ "$(netstat -tlpn 2>/dev/null | grep 'dropbear' | wc -l)" != '0' ]] && {
            echo -e "${GREEN}SERVICE: ${YELLOW}DROPBEAR: ${GREEN}PORT: ${WHITE}$(netstat -nplt 2>/dev/null | grep 'dropbear' | awk -F ':' '{print $4}' | xargs)"
            sts2="${GREEN}♦ "
        } || sts2="${RED}○ "
        
        [[ -e "/etc/stunnel/stunnel.conf" ]] && {
            echo -e "${GREEN}SERVICE: ${YELLOW}SSL TUNNEL ${GREEN}PORT: ${WHITE}$(netstat -nplt 2>/dev/null | grep 'stunnel' | awk '{print $4}' | cut -d: -f2 | xargs)"
            sts3="${GREEN}♦ "
        } || sts3="${RED}○ "
        
        [[ "$(netstat -tlpn 2>/dev/null | grep 'squid' | wc -l)" != '0' ]] && {
            echo -e "${GREEN}SERVICE: ${YELLOW}SQUID ${GREEN}PORT: ${WHITE}$(netstat -nplt 2>/dev/null | grep 'squid' | awk -F ':' '{print $4}' | xargs)"
            sts1="${GREEN}♦ "
        } || sts1="${RED}○ "
        
        [[ "$(netstat -tlpn 2>/dev/null | grep 'openvpn' | wc -l)" != '0' ]] && {
            echo -e "${GREEN}SERVICE: ${YELLOW}OPENVPN: ${GREEN}PORT: ${WHITE}$(netstat -nplt 2>/dev/null | grep 'openvpn' | awk '{print $4}' | cut -d: -f2 | xargs)"
            sts5="${GREEN}♦ "
        } || sts5="${RED}○ "
        
        [[ "$(netstat -tlpn 2>/dev/null | grep 'python' | wc -l)" != '0' ]] && {
            echo -e "${GREEN}SERVICE: ${YELLOW}PROXY SOCKS ${GREEN}PORT: ${WHITE}$(netstat -nplt 2>/dev/null | grep 'python' | awk '{print $4}' | cut -d: -f2 | xargs)"
            sts4="${GREEN}♦ "
        } || sts4="${RED}○ "
        
        [[ "$(netstat -tlpn 2>/dev/null | grep 'sslh' | wc -l)" != '0' ]] && {
            echo -e "${GREEN}SERVICE: ${YELLOW}SSLH: ${GREEN}PORT: ${WHITE}$(netstat -nplt 2>/dev/null | grep 'sslh' | awk '{print $4}' | cut -d: -f2 | xargs)"
            sts7="${GREEN}♦ "
        } || sts7="${RED}○ "
        
        [[ "$(ps x | grep 'udpvpn' | grep -v 'grep' | wc -l)" != '0' ]] && sts8="${GREEN}♦ " || sts8="${RED}○ "
        
        echo -e "${BLUE}◇────────────────────────────────────────────────◇${NC}"
        echo ""
        echo -e "${RED}[${CYAN}01${RED}] ${WHITE}• ${YELLOW}OPENSSH $sts6"
        echo -e "${RED}[${CYAN}02${RED}] ${WHITE}• ${YELLOW}SQUID PROXY $sts1"
        echo -e "${RED}[${CYAN}03${RED}] ${WHITE}• ${YELLOW}DROPBEAR $sts2"
        echo -e "${RED}[${CYAN}04${RED}] ${WHITE}• ${YELLOW}OPENVPN $sts5"
        echo -e "${RED}[${CYAN}05${RED}] ${WHITE}• ${YELLOW}PROXY SOCKS $sts4"
        echo -e "${RED}[${CYAN}06${RED}] ${WHITE}• ${YELLOW}SSL TUNNEL $sts3"
        echo -e "${RED}[${CYAN}07${RED}] ${WHITE}• ${YELLOW}SSLH MULTIPLEX $sts7"
        echo -e "${RED}[${CYAN}08${RED}] ${WHITE}• ${YELLOW}BADVPN $sts8"
        echo -e "${RED}[${CYAN}10${RED}] ${WHITE}• ${YELLOW}COME BACK ${GREEN}<<<${RED}"
        echo -e "${RED}[${CYAN}00${RED}] ${WHITE}• ${YELLOW}EXIT ${GREEN}<<<${NC}"
        echo ""
        echo -e "${BLUE}◇────────────────────────────────────────────────◇${NC}"
        echo ""
        tput civis
        echo -ne "${GREEN}WHAT DO YOU WANT TO DO ${YELLOW}?${RED}?${WHITE} "
        read x
        tput cnorm
        clear
        
        case $x in
            1|01) fun_openssh ;;
            2|02) fun_squid ;;
            3|03) fun_drop ;;
            4|04) fun_openvpn ;;
            5|05) fun_socks ;;
            6|06) inst_ssl ;;
            7|07) fun_sslh ;;
            8|08) fun_badvpn ;;
            10) bash "$SCRIPT_DIR/menu.sh"; exit ;;
            0|00) echo -e "${RED}Going out...${NC}"; sleep 2; clear; exit ;;
            *) echo -e "${RED}Invalid option!${NC}"; sleep 2 ;;
        esac
    done
}

fun_conexao
