# SSH Tunnel Manager

A comprehensive VPS management tool for SSH tunneling, user management, and service administration.

## Features

- **User Management**: Create, remove, modify SSH users with connection limits and expiry dates
- **Connection Services**: OpenSSH, Dropbear, Stunnel (SSL), Squid Proxy, OpenVPN, SOCKS Proxy, WebSocket Proxy, SSLH, BadVPN
- **System Tools**: Speed test, banner management, system optimization, service restart, torrent blocking
- **Monitoring**: Online user monitoring, user reports, expired user cleanup
- **Backup**: Full user backup and restore
- **Extras**: DNS host management, connection limiter, Telegram bot integration

## Installation

```bash
# Clone the repository
git clone <your-repo-url> /root/ssltunnel
cd /root/ssltunnel

# Run the installer
chmod +x install.sh
bash install.sh
```

## Usage

After installation, type `menu` from any terminal to open the manager.

## Requirements

- Ubuntu/Debian Linux VPS
- Root access
- Minimum 512MB RAM

## Directory Structure

```
ssltunnel/
├── install.sh          # Main installer
├── menu.sh             # Main menu entry point
├── lib/
│   ├── functions.sh    # Shared utilities and functions
│   ├── proxy.py        # SOCKS proxy server
│   └── wsproxy.py      # WebSocket proxy server
└── modules/
    ├── create_user.sh      # Create SSH user
    ├── create_test_user.sh # Create temporary test user
    ├── remove_user.sh      # Remove users
    ├── change_password.sh  # Change user password
    ├── change_limit.sh     # Change connection limit
    ├── change_date.sh      # Change expiry date
    ├── user_monitor.sh     # Monitor online users
    ├── user_report.sh      # User status report
    ├── expired_cleaner.sh  # Clean expired users
    ├── user_backup.sh      # Backup/restore users
    ├── connection.sh       # Connection services manager
    ├── system_info.sh      # System information
    ├── speedtest.sh        # Speed test
    ├── banner.sh           # SSH banner management
    ├── optimize.sh         # System optimization
    ├── restart_services.sh # Restart all services
    ├── restart_system.sh   # Reboot system
    ├── change_root_pass.sh # Change root password
    ├── add_host.sh         # Add DNS host
    ├── remove_host.sh      # Remove DNS host
    ├── block_torrent.sh    # Toggle torrent blocking
    ├── limiter.sh          # Connection limiter
    ├── badvpn.sh           # BadVPN UDP gateway
    ├── telegram_bot.sh     # Telegram bot setup
    ├── update_script.sh    # Update manager
    └── uninstall.sh        # Uninstall manager
```

## License

Free for personal use.
