#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - User Limiter
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root
ensure_dirs

# Check limiter status and toggle
if ps x | grep "limiter" | grep -v grep | wc -l | grep -q "0"; then
    # Start limiter
    clear
    echo -e "\n${GREEN}◇ STARTING USER LIMITER...${NC}"
    echo ""
    
    # Create the limiter script if not exists
    if [[ ! -f "$MANAGER_DIR/limiter.sh" ]]; then
        cat > "$MANAGER_DIR/limiter.sh" << 'LIMEOF'
#!/bin/bash
USER_DB="/root/usuarios.db"
while true; do
    while read line; do
        user=$(echo "$line" | awk '{print $1}')
        limit=$(echo "$line" | awk '{print $2}')
        [[ -z "$user" || -z "$limit" ]] && continue
        
        online=$(ps -u "$user" 2>/dev/null | grep -c "sshd")
        if [[ "$online" -gt "$limit" ]]; then
            excess=$((online - limit))
            for pid in $(ps -u "$user" -o pid= 2>/dev/null | head -n "$excess"); do
                kill -9 "$pid" 2>/dev/null
            done
        fi
    done < "$USER_DB"
    sleep 30
done
LIMEOF
        chmod +x "$MANAGER_DIR/limiter.sh"
    fi
    
    fun_bar 'screen -dmS limiter bash '"$MANAGER_DIR"'/limiter.sh' 'sleep 3'
    
    [[ $(grep -wc "limiter" "$AUTOSTART_FILE") = '0' ]] && {
        echo -e "ps x | grep 'limiter' | grep -v 'grep' && echo 'ON' || screen -dmS limiter bash $MANAGER_DIR/limiter.sh" >> "$AUTOSTART_FILE"
    }
    
    echo -e "\n${GREEN}◇ USER LIMITER ACTIVATED!${NC}"
    sleep 3
else
    # Stop limiter
    clear
    echo -e "${GREEN}◇ STOPPING USER LIMITER...${NC}"
    echo ""
    fun_stplimiter() {
        sleep 1
        screen -r -S "limiter" -X quit 2>/dev/null
        screen -wipe >/dev/null 2>&1
        [[ $(grep -wc "limiter" "$AUTOSTART_FILE") != '0' ]] && {
            sed -i '/limiter/d' "$AUTOSTART_FILE"
        }
        sleep 1
    }
    fun_bar 'fun_stplimiter' 'sleep 3'
    echo -e "\n${RED}◇ USER LIMITER STOPPED!${NC}"
    sleep 3
fi
