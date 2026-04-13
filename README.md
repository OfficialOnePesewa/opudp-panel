OPUDP Panel - VPN User Management Dashboard
OPUDP is a complete UDP VPN solution based on ZIVPN core, featuring a colorful dashboard, user management, bandwidth tracking, and one‑click installation.
✨ Features
🚀 One‑liner install – Fully automated setup (all Linux distros)
🎨 Colorful TUI dashboard – Easy to use menu interface
👥 User management – Add, remove, extend, list users
⏳ Expiry & quota – Validity days + bandwidth limits
🔄 Auto‑update panel – Stay up‑to‑date with opudp --update
🔥 Firewall integration – iptables + NAT forwarding (automatic)
📊 Live logs & stats – Monitor connections & bandwidth
🧪 Trial users – Create temporary accounts (1‑60 minutes)
💾 Backup & restore – Save all user data
🤖 BBR Optimization – High-performance TCP congestion control
📱 Multi-device support – HWID binding (optional)
🖥️ Tested Platforms
Operating Systems:
Ubuntu 18.04 LTS → 24.04 LTS ✅
Debian 10, 11, 12 ✅
CentOS 8, RHEL 8/9 ✅
Fedora 33+ ✅
AlmaLinux, Rocky Linux ✅
VPS Providers:
Contabo ⭐ Recommended
Linode, DigitalOcean, Vultr
AWS EC2, Azure, Google Cloud
Hetzner, OVH, Scaleway
BuyVM, Hostinger, and more
Architectures:
x86_64 (Intel/AMD) ✅
ARM64 (AWS Graviton, Apple Silicon) ✅
ARMv7 (32-bit ARM) ✅
📥 One‑Liner Installation
Run the following command as root on your Linux VPS:
sudo bash <(curl -s https://raw.githubusercontent.com/OfficialOnePesewa/opudp-panel/main/installer/install.sh)
Or using wget:
sudo bash <(wget -O- https://raw.githubusercontent.com/OfficialOnePesewa/opudp-panel/main/installer/install.sh)
What gets installed:
ZIVPN UDP binary (v1.4.9)
OPUDP dashboard command
Firewall rules (iptables + NAT)
BBR optimization
Systemd service auto-start
🚀 Quick Start
After installation, simply type:
opudp
This opens the dashboard with 20+ options:
1) Start ZIVPN              11) Bandwidth + Expiry
2) Stop ZIVPN               12) Reset Bandwidth
3) Restart ZIVPN            13) Speed Test
4) Status                   14) Live Logs
5) List Users + Expiry      15) Backup All Data
6) Add User                 16) Restore Backup
7) Remove User              17) Change Port Range
8) Renew / Extend User      18) Auto-Update Panel
9) Cleanup Expired          19) Set Connection Limit
10) Connection Stats        20) Trial User (1-60m)

99) UNINSTALL               0) Exit
📋 Add New User (Example)
1. Type: opudp
2. Select: 6 (Add User)
3. Enter password: MySecurePass123
4. Enter validity: 30 (days)
5. Enter quota: 10GB
6. Enter device ID: (optional, press Enter to skip)
7. User created! ✅
User will see:
Password: MySecurePass123
Expiry: 2026-05-13
Quota: 10GB
Server IP: [Your IP]
🔧 Configuration Files
After installation, find configs at:
/etc/zivpn/config.json          # ZIVPN server config
/etc/zivpn/users.db             # User database
/etc/zivpn/zivpn.key            # SSL private key
/etc/zivpn/zivpn.crt            # SSL certificate
/var/log/opudp-install.log      # Installation log
🛠️ Manual Commands
# Open dashboard
opudp

# Check ZIVPN service status
systemctl status zivpn

# View ZIVPN logs
journalctl -u zivpn -f

# Restart ZIVPN
systemctl restart zivpn

# Backup users database
cp /etc/zivpn/users.db /etc/zivpn/users.db.backup

# View all users
cat /etc/zivpn/users.db

# Uninstall everything
systemctl stop zivpn
rm -rf /etc/zivpn /usr/local/bin/{zivpn,opudp}
📊 Server Specifications
Minimum Requirements:
256MB RAM
20GB Storage
Linux OS (Debian/Ubuntu/CentOS/RHEL/Fedora)
systemd
Recommended:
1-2GB RAM
50GB+ Storage
Ubuntu 22.04 LTS Server
Contabo or similar provider
🔌 Network Details
After installation:
ZIVPN Port: 5667 (UDP)
NAT Range: 6000-19999 (UDP)
SSH Port: 22 (TCP, preserved)
Max Connections: Configurable per user
Bandwidth: Trackable per user
🆘 Troubleshooting
ZIVPN service not starting?
journalctl -u zivpn -n 50
# Check /etc/zivpn/config.json format
Can't connect to VPN?
# Verify firewall rules
sudo iptables -L -n | grep 5667

# Check if port is open
sudo netstat -tlunp | grep 5667
Permission denied running opudp?
sudo opudp
# Or
sudo chmod +x /usr/local/bin/opudp
📚 Documentation
Compatibility Matrix
Installation Guide
User Management
Troubleshooting
📞 Support
Telegram: @OfficialOnePesewa
Channel: t.me/OfficialOnePesewa
Issues: GitHub Issues
📝 Version & Changelog
Current Version: 4.0.0
v4.0.0 (Latest)
✅ Universal installer (all Linux distros)
✅ BBR optimization enabled
✅ 15+ VPS providers tested
✅ Improved error handling
✅ Rebranded to @OfficialOnePesewa
v3.0
Multi-user support
Colorful dashboard
Trial user feature
v2.0
Initial release
⚖️ License
MIT License - See LICENSE file
🙏 Credits
Author: @OfficialOnePesewa
Core: ZIVPN (zahidbd2)
Based on: NOOBS UPD Panel
Ready to get started?
sudo bash <(curl -s https://raw.githubusercontent.com/OfficialOnePesewa/opudp-panel/main/installer/install.sh)
Made with ❤️ for the open-source community.
