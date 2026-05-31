#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Banner Management
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

print_section "SSH BANNER MANAGEMENT"
echo ""

echo -e "${RED}[${CYAN}1${RED}]${YELLOW} SET CUSTOM BANNER"
echo -e "${RED}[${CYAN}2${RED}]${YELLOW} REMOVE BANNER"
echo -e "${RED}[${CYAN}3${RED}]${YELLOW} VIEW CURRENT BANNER"
echo -e "${RED}[${CYAN}0${RED}]${YELLOW} COME BACK"
echo ""
echo -ne "${GREEN}◇ WHAT DO YOU WANT TO DO ${RED}?${WHITE} : "
read resp

if [[ "$resp" = "1" ]]; then
    echo ""
    echo -e "${YELLOW}Enter your banner text (type END on a new line when done):${NC}"
    banner_text=""
    while IFS= read -r line; do
        [[ "$line" = "END" ]] && break
        banner_text+="$line\n"
    done
    
    echo -e "$banner_text" > /etc/ssh/banner.txt
    
    # Add banner config to sshd_config if not present
    if ! grep -q "^Banner" /etc/ssh/sshd_config; then
        echo "Banner /etc/ssh/banner.txt" >> /etc/ssh/sshd_config
    else
        sed -i "s|^Banner.*|Banner /etc/ssh/banner.txt|" /etc/ssh/sshd_config
    fi
    
    service ssh restart >/dev/null 2>&1
    echo -e "\n${GREEN}◇ Banner set successfully!${NC}"
    
elif [[ "$resp" = "2" ]]; then
    sed -i '/^Banner/d' /etc/ssh/sshd_config
    rm -f /etc/ssh/banner.txt
    service ssh restart >/dev/null 2>&1
    echo -e "\n${GREEN}◇ Banner removed successfully!${NC}"
    
elif [[ "$resp" = "3" ]]; then
    echo ""
    if [[ -f /etc/ssh/banner.txt ]]; then
        echo -e "${YELLOW}Current banner:${NC}"
        echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
        cat /etc/ssh/banner.txt
        echo -e "${BLUE}◇───────────────────────────────────────────────◇${NC}"
    else
        echo -e "${YELLOW}No banner is currently set.${NC}"
    fi
    
elif [[ "$resp" = "0" ]]; then
    exit 0
else
    echo -e "\n${RED}◇ Invalid option!${NC}"
fi
