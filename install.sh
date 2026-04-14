#!/bin/bash
# OPUDP Panel Installer - Debian 10+ / Ubuntu 20.04+
# Run as root: curl -fsSL https://raw.githubusercontent.com/OfficialOnePesewa/opudp-panel/main/install.sh | bash

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()    { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[[ $EUID -eq 0 ]] || error "Run as root: curl -fsSL ... | bash"

# OS Check
. /etc/os-release
[[ "$ID" =~ ^(ubuntu|debian)$ ]] || error "Only Debian/Ubuntu supported"

log "Detected $PRETTY_NAME"

# Pre-seed iptables-persistent to avoid prompts
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

# Install dependencies
apt-get update -qq
apt-get install -y -qq curl wget jq openssl vnstat bc iptables debconf-utils iptables-persistent netfilter-persistent

# Architecture detection
ARCH=$(uname -m)
case $ARCH in
    x86_64)  BIN_ARCH="amd64" ;;
    aarch64) BIN_ARCH="arm64" ;;
    armv7l)  BIN_ARCH="armv7" ;;
    *) error "Unsupported architecture: $ARCH" ;;
esac

# Download ZIVPN binary
ZIVPN_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-${BIN_ARCH}"
log "Downloading ZIVPN..."
wget -q --show-progress -O /usr/local/bin/zivpn "$ZIVPN_URL" || error "Download failed"
chmod +x /usr/local/bin/zivpn

# Config directory and self-signed certificate
mkdir -p /etc/zivpn
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=GH/ST=Accra/L=Accra/O=OPUDP/CN=zivpn" \
    -keyout /etc/zivpn/zivpn.key \
    -out /etc/zivpn/zivpn.crt

# Create default config (password-only auth mode)
cat > /etc/zivpn/config.json <<EOF
{
    "listen": ":5667",
    "cert": "/etc/zivpn/zivpn.crt",
    "key": "/etc/zivpn/zivpn.key",
    "obfs": "zivpn",
    "auth": {
        "mode": "passwords",
        "config": []
    }
}
EOF
touch /etc/zivpn/users.db
chmod 600 /etc/zivpn/users.db

# Firewall rules
iptables -I INPUT -p udp --dport 5667 -j ACCEPT
iptables -I INPUT -p udp --dport 6000:19999 -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j DNAT --to-destination :5667
netfilter-persistent save

# Systemd service
cat > /etc/systemd/system/zivpn.service <<EOF
[Unit]
Description=ZIVPN UDP Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now zivpn

# Download panel script
wget -q --show-progress -O /usr/local/bin/opudp \
    "https://raw.githubusercontent.com/OfficialOnePesewa/opudp-panel/main/opudp"
chmod +x /usr/local/bin/opudp

# Completion message
IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || hostname -I | awk '{print $1}')
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   OPUDP Panel Installation Complete!  ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Server IP: ${YELLOW}$IP${NC}"
echo -e "Run '${YELLOW}opudp${NC}' to open the management menu."
echo ""
echo -e "To connect with ZIVPN app:"
echo -e "  - UDP Server: $IP"
echo -e "  - UDP Password: (create a user in panel)"
echo ""
