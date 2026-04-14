```bash
#!/bin/bash
################################################################################
# OPUDP Panel - Universal Installer v4.0
# ✅ Compatible: Debian 10+, Ubuntu 18.04+, CentOS 8+, Fedora 33+
# 📧 Support: @OfficialOnePesewa | https://t.me/OfficialOnePesewa
################################################################################

set -e

# --- Colors ---
G="\e[1;32m"
R="\e[1;31m"
Y="\e[1;33m"
C="\e[1;36m"
NC="\e[0m"
BOLD="\e[1m"

# --- Global Variables ---
ZIVPN_VERSION="1.4.9"
OPUDP_REPO="OfficialOnePesewa/opudp-panel"
GITHUB_RAW="https://raw.githubusercontent.com/$OPUDP_REPO/main"
INSTALL_LOG="/var/log/opudp-install.log"

if [ "$EUID" -ne 0 ]; then
    echo -e "${R}[ERROR] Please run as root.${NC}"
    exit 1
fi

# --- Logging Functions ---
log_info() {
    echo -e "${C}[$(date +%H:%M:%S)]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_success() {
    echo -e "${G}[✓]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_error() {
    echo -e "${R}[✗]${NC} $1" | tee -a "$INSTALL_LOG"
}

log_warn() {
    echo -e "${Y}[⚠]${NC} $1" | tee -a "$INSTALL_LOG"
}

# --- OS Detection ---
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        OS_FAMILY=$(echo "$ID" | grep -oE "debian|ubuntu|centos|rhel|fedora" | head -1)
    else
        log_error "Could not detect OS"
        exit 1
    fi
    
    case "$OS_FAMILY" in
        debian|ubuntu)
            PKG_MANAGER="apt-get"
            INSTALL_CMD="apt-get install -y"
            UPDATE_CMD="apt-get update -qq"
            ;;
        centos|rhel|fedora)
            PKG_MANAGER="yum"
            INSTALL_CMD="yum install -y"
            UPDATE_CMD="yum check-update -q"
            ;;
        *)
            log_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

# --- Architecture Detection ---
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  BIN_ARCH="amd64" ;;
        aarch64) BIN_ARCH="arm64" ;;
        armv7l)  BIN_ARCH="armv7" ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
}

# --- Banner ---
banner() {
    clear
    echo -e "${C}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${G}${BOLD}   ██████╗ ██████╗ ██╗   ██╗██████╗ ██████╗            ${NC}"
    echo -e "${G}${BOLD}  ██╔═══██╗██╔══██╗██║   ██║██╔══██╗██╔══██╗           ${NC}"
    echo -e "${G}${BOLD}  ██║   ██║██████╔╝██║   ██║██║  ██║██████╔╝           ${NC}"
    echo -e "${G}${BOLD}  ██║   ██║██╔═══╝ ██║   ██║██║  ██║██╔═══╝            ${NC}"
    echo -e "${G}${BOLD}  ╚██████╔╝██║     ╚██████╔╝██████╔╝██║                ${NC}"
    echo -e "${G}${BOLD}   ╚═════╝ ╚═╝      ╚═════╝ ╚═════╝ ╚═╝   ${Y}UDP PANEL  ${NC}"
    echo -e "${C}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${Y}OPUDP Panel Installer v4.0${NC}"
    echo ""
}

# --- Main Installation ---
main() {
    banner
    
    log_info "Starting installation..."
    detect_os
    detect_arch
    
    echo ""
    echo -e "${Y}OS: $OS ($VER) | Arch: $BIN_ARCH | PKG: $PKG_MANAGER${NC}"
    echo ""
    
    # Update system
    log_info "[1/7] Updating system..."
    $UPDATE_CMD &>/dev/null || log_warn "Update had warnings"
    
    # Install dependencies
    log_info "[2/7] Installing dependencies..."
    DEPS="curl wget jq openssl vnstat bc"
    
    if [ "$OS_FAMILY" = "debian" ] || [ "$OS_FAMILY" = "ubuntu" ]; then
        DEPS="$DEPS iptables iptables-persistent netfilter-persistent"
        DEBIAN_FRONTEND=noninteractive $INSTALL_CMD $DEPS &>/dev/null
    else
        DEPS="$DEPS iptables iptables-services"
        $INSTALL_CMD $DEPS &>/dev/null
    fi
    log_success "Dependencies installed"
    
    # Enable BBR
    log_info "[3/7] Enabling BBR optimization..."
    if modinfo tcp_bbr &>/dev/null; then
        cat <<'EOF' >> /etc/sysctl.conf

# === BBR Congestion Control (OfficialOnePesewa) ===
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.core.netdev_max_backlog=5000
net.ipv4.tcp_max_syn_backlog=5000
net.ipv4.ip_local_port_range=10000 65000
net.ipv4.udp_mem=102400 873800 2097152
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=30
EOF
        sysctl -p -q &>/dev/null
        modprobe tcp_bbr &>/dev/null
        log_success "BBR enabled"
    else
        log_warn "BBR not available (optional)"
    fi
    
    # Fetch geo-IP
    log_info "[4/7] Fetching server info..."
    GEO=$(curl -4 -s --max-time 10 "https://ipapi.co/json/" 2>/dev/null || echo '{}')
    IP=$(echo "$GEO" | grep -oP '"ip":\s*"\K[^"]+' 2>/dev/null || echo "N/A")
    CITY=$(echo "$GEO" | grep -oP '"city":\s*"\K[^"]+' 2>/dev/null || echo "Unknown")
    COUNTRY=$(echo "$GEO" | grep -oP '"country_name":\s*"\K[^"]+' 2>/dev/null || echo "Unknown")
    ISP=$(echo "$GEO" | grep -oP '"org":\s*"\K[^"]+' 2>/dev/null || echo "Unknown")
    log_success "Server IP: $IP ($CITY, $COUNTRY)"
    
    # Download ZIVPN binary
    log_info "[5/7] Downloading ZIVPN binary ($BIN_ARCH)..."
    ZIVPN_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_${ZIVPN_VERSION}/udp-zivpn-linux-${BIN_ARCH}"
    
    if ! wget -q --show-progress -O /usr/local/bin/zivpn "$ZIVPN_URL" 2>&1; then
        log_error "Failed to download ZIVPN. Check internet or release availability."
        exit 1
    fi
    chmod +x /usr/local/bin/zivpn
    log_success "ZIVPN installed"
    
    # Configure ZIVPN
    log_info "[6/7] Configuring ZIVPN..."
    mkdir -p /etc/zivpn
    
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=GH/ST=Accra/L=Accra/O=OfficialOnePesewa/CN=zivpn" \
        -keyout "/etc/zivpn/zivpn.key" \
        -out "/etc/zivpn/zivpn.crt" 2>/dev/null
    
    cat <<'EOF' > /etc/zivpn/config.json
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
    log_success "ZIVPN configured"
    
    # Setup firewall
    log_info "[7/7] Configuring firewall..."
    
    if command -v ufw &>/dev/null; then
        ufw disable &>/dev/null || true
    fi
    
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p udp --dport 5667 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p udp --dport 6000:19999 -j ACCEPT 2>/dev/null || true
    iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || true
    
    if command -v netfilter-persistent &>/dev/null; then
        netfilter-persistent save &>/dev/null || true
    fi
    
    log_success "Firewall configured"
    
    # Create systemd service
    cat <<'EOF' > /etc/systemd/system/zivpn.service
[Unit]
Description=ZIVPN UDP Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload &>/dev/null
    systemctl enable zivpn &>/dev/null
    systemctl start zivpn &>/dev/null
    
    sleep 2
    if systemctl is-active --quiet zivpn; then
        log_success "ZIVPN service running"
    else
        log_warn "ZIVPN service check logs: journalctl -u zivpn -n 20"
    fi
    
    # Download OPUDP panel
    log_info "Downloading OPUDP panel..."
    if ! wget -q -O /usr/local/bin/opudp "${GITHUB_RAW}/opudp"; then
        log_error "Failed to download opudp"
        exit 1
    fi
    chmod +x /usr/local/bin/opudp
    log_success "OPUDP panel installed"
    
    # Summary
    clear
    echo -e "${C}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${G}${BOLD}           🎉 INSTALLATION SUCCESSFUL! 🎉${NC}"
    echo -e "${C}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${Y}Server Details:${NC}"
    echo -e "  IP       : ${G}$IP${NC}"
    echo -e "  Location : ${G}$CITY, $COUNTRY${NC}"
    echo -e "  ISP      : ${G}$ISP${NC}"
    echo ""
    echo -e "${Y}ZIVPN:${NC}"
    echo -e "  Port     : ${G}5667 (UDP)${NC}"
    echo -e "  NAT      : ${G}6000-19999${NC}"
    echo -e "  Config   : ${G}/etc/zivpn/config.json${NC}"
    echo -e "  Users DB : ${G}/etc/zivpn/users.db${NC}"
    echo ""
    echo -e "${Y}OPUDP Dashboard:${NC}"
    echo -e "  Command  : ${G}opudp${NC}"
    echo ""
    echo -e "${Y}Next Steps:${NC}"
    echo -e "  1. ${G}opudp${NC}                    # Open dashboard"
    echo -e "  2. Select ${G}6${NC}                  # Add new user"
    echo -e "  3. ${G}systemctl status zivpn${NC}   # Check status"
    echo ""
    echo -e "${M}Admin: @OfficialOnePesewa${NC}"
    echo -e "${M}Telegram: https://t.me/OfficialOnePesewa${NC}"
    echo ""
    echo -e "${C}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    log_success "Installation complete!"
}

trap 'log_error "Installation failed"; exit 1' ERR INT
main "$@"
