#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - Block/Unblock Torrent
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root

if [[ -e /etc/Plus-torrent ]]; then
    clear
    print_error_section "UNBLOCK TORRENT"
    echo ""
    echo -ne "${GREEN}WANT TO UNBLOCK TORRENT ${RED}? ${YELLOW}[y/n]:${WHITE} "
    read resp
    [[ "$resp" = 'y' ]] && {
        fun_unblock() {
            iptables -D FORWARD -m string --algo bm --string "BitTorrent" -j DROP 2>/dev/null
            iptables -D FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP 2>/dev/null
            iptables -D FORWARD -m string --algo bm --string "peer_id=" -j DROP 2>/dev/null
            iptables -D FORWARD -m string --algo bm --string ".torrent" -j DROP 2>/dev/null
            iptables -D FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP 2>/dev/null
            iptables -D FORWARD -m string --algo bm --string "torrent" -j DROP 2>/dev/null
            iptables -D FORWARD -m string --algo bm --string "info_hash" -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --algo bm --string "BitTorrent" -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --algo bm --string "BitTorrent protocol" -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --algo bm --string "peer_id=" -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --algo bm --string ".torrent" -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --algo bm --string "info_hash" -j DROP 2>/dev/null
            rm -f /etc/Plus-torrent
        }
        echo ""
        fun_bar 'fun_unblock'
        echo -e "\n${GREEN}◇ TORRENT UNBLOCKED!${NC}"
        sleep 2
    } || {
        echo -e "\n${RED}Returning...${NC}"
        sleep 2
    }
else
    clear
    print_section "BLOCK TORRENT"
    echo ""
    echo -ne "${GREEN}WANT TO BLOCK TORRENT ${RED}? ${YELLOW}[y/n]:${WHITE} "
    read resp
    [[ "$resp" = 'y' ]] && {
        fun_block() {
            iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
            iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
            iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
            iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
            iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
            iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
            iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
            iptables -A OUTPUT -m string --algo bm --string "BitTorrent" -j DROP
            iptables -A OUTPUT -m string --algo bm --string "BitTorrent protocol" -j DROP
            iptables -A OUTPUT -m string --algo bm --string "peer_id=" -j DROP
            iptables -A OUTPUT -m string --algo bm --string ".torrent" -j DROP
            iptables -A OUTPUT -m string --algo bm --string "info_hash" -j DROP
            touch /etc/Plus-torrent
        }
        echo ""
        fun_bar 'fun_block'
        echo -e "\n${GREEN}◇ TORRENT BLOCKED!${NC}"
        sleep 2
    } || {
        echo -e "\n${RED}Returning...${NC}"
        sleep 2
    }
fi
