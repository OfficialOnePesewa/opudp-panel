#!/bin/bash
# OPUDP Panel Installer - Compatible with Debian 10+/Ubuntu 20.04+
# Run as root (or with sudo)

set -euo pipefail

# --- Color Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --- Root Check ---
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root. Try: sudo bash install.sh"
fi

# --- OS Detection ---
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    error "Cannot detect OS. Only Debian/Ubuntu are supported."
fi

if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    error "Unsupported OS: $OS. This installer only works on Debian or Ubuntu."
fi

log "Detected $OS $VERSION"

# --- Pre-configure iptables-persistent to avoid interactive prompts ---
log "Pre-configuring iptables-persistent..."
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

# --- Update System & Install Dependencies ---
log "Updating package lists and installing dependencies..."
apt-get update -qq
apt-get install -y -qq curl wget jq openssl vnstat bc iptables debconf-utils

# Install iptables-persistent (non-interactive now)
apt-get install -y -qq iptables-persistent netfilter-persistent

# --- Determine Architecture ---
ARCH=$(uname -m)
case $ARCH in
    x86_64)  BIN_ARCH="amd64" ;;
    aarch64) BIN_ARCH="arm64" ;;
    armv7l)  BIN_ARCH="armv7" ;;
    *)
        error "Unsupported architecture: $ARCH"
        ;;
esac

log "Architecture: $ARCH -> binary suffix: $BIN_ARCH"

# --- Download and Install ZIVPN Binary ---
ZIVPN_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-${BIN_ARCH}"
log "Downloading ZIVPN from $ZIVPN_URL ..."
wget -q --show-progress -O /usr/local/bin/zivpn "$ZIVPN_URL" || error "Failed to download ZIVPN binary"
chmod +x /usr/local/bin/zivpn

# --- Create Configuration ---
log "Generating self-signed certificate..."
mkdir -p /etc/zivpn
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=GH/ST=Accra/L=Accra/O=OPUDP/CN=zivpn" \
    -keyout /etc/zivpn/zivpn.key \
    -out /etc/zivpn/zivpn.crt

log "Creating ZIVPN config..."
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

# --- Firewall Rules ---
log "Configuring iptables rules..."
# Clear any existing OPUDP-related rules (optional)
iptables -D INPUT -p udp --dport 5667 -j ACCEPT 2>/dev/null || true
iptables -D INPUT -p udp --dport 6000:19999 -j ACCEPT 2>/dev/null || true
iptables -t nat -D PREROUTING -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || true

# Add fresh rules
iptables -I INPUT -p udp --dport 5667 -j ACCEPT
iptables -I INPUT -p udp --dport 6000:19999 -j ACCEPT
iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j DNAT --to-destination :5667

log "Saving iptables rules..."
netfilter-persistent save

# --- Systemd Service ---
log "Creating systemd service..."
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

# --- Download OPUDP Panel Script ---
log "Downloading OPUDP panel script..."
wget -q --show-progress -O /usr/local/bin/opudp \
    "https://raw.githubusercontent.com/OfficialOnePesewa/opudp-panel/main/opudp"
chmod +x /usr/local/bin/opudp

# --- Completion ---
IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   OPUDP Panel Installation Complete!  ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "ZIVPN is running on UDP port 5667 (and forwards 6000-19999)."
echo -e "Manage your panel with: ${YELLOW}opudp${NC}"
echo ""
echo -e "Server IP: ${YELLOW}$IP${NC}"
echo -e "To start:  ${YELLOW}opudp${NC}"
echo -e "To check service: ${YELLOW}systemctl status zivpn${NC}"
echo ""
echo -e "If you face issues, ensure UDP ports are open in your VPS firewall."
echo -e "${GREEN}========================================${NC}"
