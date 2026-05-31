#!/bin/bash
# ============================================
#  SSH TUNNEL MANAGER - User Backup
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/functions.sh"

check_root
ensure_dirs

print_section "USER BACKUP"
echo ""

echo -e "${RED}[${CYAN}1${RED}]${YELLOW} BACKUP USERS"
echo -e "${RED}[${CYAN}2${RED}]${YELLOW} RESTORE USERS"
echo -e "${RED}[${CYAN}3${RED}]${YELLOW} COME BACK"
echo ""
echo -ne "${GREEN}◇ WHAT DO YOU WANT TO DO ${RED}?${WHITE} : "
read resp

backup_dir="$HOME/ssh_backup"

if [[ "$resp" = "1" ]]; then
    echo ""
    echo -e "${GREEN}◇ Creating user backup...${NC}"
    echo ""
    
    [[ ! -d "$backup_dir" ]] && mkdir -p "$backup_dir"
    
    # Backup passwd entries
    awk -F: '$3>=1000 && $1!="nobody"' /etc/passwd > "$backup_dir/passwd.bak"
    awk -F: '$3>=1000 && $1!="nobody"' /etc/shadow > "$backup_dir/shadow.bak"
    
    # Backup user database
    [[ -f "$USER_DB" ]] && cp "$USER_DB" "$backup_dir/usuarios.db.bak"
    
    # Backup passwords
    [[ -d "$PASSWD_DIR" ]] && cp -r "$PASSWD_DIR" "$backup_dir/passwd_dir.bak"
    
    # Create tarball
    backup_file="$HOME/ssh_users_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$backup_file" -C "$backup_dir" . >/dev/null 2>&1
    
    echo -e "${GREEN}◇ Backup created successfully!${NC}"
    echo -e "${GREEN}◇ File: ${WHITE}$backup_file${NC}"
    
    # Cleanup temp dir
    rm -rf "$backup_dir"
    
elif [[ "$resp" = "2" ]]; then
    echo ""
    echo -ne "${GREEN}◇ Enter the backup file path:${WHITE} "
    read backup_file
    
    [[ ! -f "$backup_file" ]] && {
        echo -e "\n${BG_RED} Backup file not found! ${NC}"
        exit 1
    }
    
    echo -e "\n${YELLOW}◇ Restoring users from backup...${NC}"
    echo ""
    
    tmp_restore="/tmp/ssh_restore_$$"
    mkdir -p "$tmp_restore"
    tar -xzf "$backup_file" -C "$tmp_restore" >/dev/null 2>&1
    
    # Restore users from passwd backup
    if [[ -f "$tmp_restore/passwd.bak" ]]; then
        while IFS=: read -r username x uid gid gecos home shell; do
            [[ -z "$username" ]] && continue
            if ! grep -q "^${username}:" /etc/passwd; then
                echo "${username}:${x}:${uid}:${gid}:${gecos}:${home}:${shell}" >> /etc/passwd
                # Get shadow entry
                shadow_entry=$(grep "^${username}:" "$tmp_restore/shadow.bak" 2>/dev/null)
                [[ -n "$shadow_entry" ]] && echo "$shadow_entry" >> /etc/shadow
                echo -e "${GREEN}◇ Restored user: ${WHITE}$username${NC}"
            else
                echo -e "${YELLOW}◇ User already exists: ${WHITE}$username${NC}"
            fi
        done < "$tmp_restore/passwd.bak"
    fi
    
    # Restore user database
    [[ -f "$tmp_restore/usuarios.db.bak" ]] && cp "$tmp_restore/usuarios.db.bak" "$USER_DB"
    
    # Restore passwords
    [[ -d "$tmp_restore/passwd_dir.bak" ]] && cp -r "$tmp_restore/passwd_dir.bak/"* "$PASSWD_DIR/" 2>/dev/null
    
    rm -rf "$tmp_restore"
    
    echo -e "\n${GREEN}◇ Users restored successfully!${NC}"
    
elif [[ "$resp" = "3" ]]; then
    exit 0
else
    echo -e "\n${RED}◇ Invalid option!${NC}"
fi
