# OPUDP Panel - VPN User Management Dashboard

**OPUDP** is a complete UDP VPN solution based on ZIVPN core, featuring a colorful dashboard, user management, bandwidth tracking, and one‑click installation.

## ✨ Features

- 🚀 **One‑liner install** – Fully automated setup (all Linux distros)
- 🎨 **Colorful TUI dashboard** – Easy to use menu interface
- 👥 **User management** – Add, remove, extend, list users
- ⏳ **Expiry & quota** – Validity days + bandwidth limits
- 🔄 **Auto‑update panel** – Stay up‑to‑date with `opudp --update`
- 🔥 **Firewall integration** – iptables + NAT forwarding (automatic)
- 📊 **Live logs & stats** – Monitor connections & bandwidth
- 🧪 **Trial users** – Create temporary accounts (1‑60 minutes)
- 💾 **Backup & restore** – Save all user data
- 🤖 **BBR Optimization** – High-performance TCP congestion control

## 🖥️ Tested Platforms

**Operating Systems:**
- Ubuntu 18.04 LTS → 24.04 LTS ✅
- Debian 10, 11, 12 ✅
- CentOS 8, RHEL 8/9 ✅
- Fedora 33+ ✅

**VPS Providers:**
- Contabo, Linode, DigitalOcean, Vultr, AWS, Azure, Google Cloud, Hetzner, OVH, and more ✅

**Architectures:**
- x86_64, ARM64, ARMv7 ✅

## 📥 Installation

Run as **root**:

```bash
sudo bash <(curl -s https://raw.githubusercontent.com/OfficialOnePesewa/opudp-panel/main/installer/install.sh)
🚀 Usage
opudp
📊 Menu Options
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
🔧 Configuration Files
/etc/zivpn/config.json          # ZIVPN config
/etc/zivpn/users.db             # User database
/var/log/opudp-install.log      # Install logs
🛠️ Manual Commands
opudp                                    # Open dashboard
systemctl status zivpn                   # Check status
journalctl -u zivpn -f                   # View logs
systemctl restart zivpn                  # Restart service
cat /etc/zivpn/users.db                  # View users
📞 Support
Telegram: @OfficialOnePesewa
Issues: GitHub Issues
⚖️ License
MIT License
Version: 4.0.0
Admin: @OfficialOnePesewa
Made with ❤️
