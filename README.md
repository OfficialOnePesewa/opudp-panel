# OPUDP Panel - VPN User Management Dashboard

**OPUDP** is a complete UDP VPN solution based on ZIVPN core.

## ✨ Features

- 🚀 One‑liner install
- 🎨 Colorful dashboard
- 👥 User management
- ⏳ Expiry & quota tracking
- 🔄 Auto‑update
- 🔥 Firewall integration
- 📊 Live logs & stats
- 🧪 Trial users
- 💾 Backup & restore
- 🤖 BBR Optimization

## 📥 Installation

Run as **root**:

```bash
sudo bash <(curl -s https://raw.githubusercontent.com/OfficialOnePesewa/opudp-panel/main/install.sh)
Or with wget:
sudo bash <(wget -O- https://raw.githubusercontent.com/OfficialOnePesewa/opudp-panel/main/install.sh)
🚀 Usage
opudp
📋 Menu Options
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
🛠️ Commands
opudp                              # Open dashboard
systemctl status zivpn             # Check status
journalctl -u zivpn -f             # View logs
cat /etc/zivpn/users.db            # View users
📞 Support
Telegram: @OfficialOnePesewa
Channel: t.me/OfficialOnePesewa
⚖️ License
MIT License
Version: 4.0.0
Admin: @OfficialOnePesewa
