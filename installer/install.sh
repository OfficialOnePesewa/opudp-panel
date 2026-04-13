#!/bin/bash
################################################################################
# OPUDP Panel - Universal Installer v4.0
# ✅ Compatible: Debian 10+, Ubuntu 18.04+, CentOS 8+, Fedora 33+
# ✅ Tested on: Contabo, Linode, DigitalOcean, Vultr, AWS, Azure
# 📧 Support: @OfficialOnePesewa | https://t.me/OfficialOnePesewa
################################################################################

set -e

# --- Colors ---
G="\e[1;32m"    # Green
R="\e[1;31m"    # Red
Y="\e[1;33m"    # Yellow
C="\e[1;36m"    # Cyan
NC="\e[0m"      # No Color
BOLD="\e[1m"

# --- Global Variables ---
ZIVPN_VERSION="1.4.9"
OPUDP_REPO="OfficialOnePesewa/opudp-panel"
GITHUB_RAW="https://raw.githubusercontent.com/$OPUDP_REPO/main"
INSTALL_LOG="/var/log/opudp-install.log"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

################################################################################
# 1. ROOT CHECK
################################################################################
if [ "$EUID" -ne 0 ]; then
    echo -e "${R}[ERROR] Please run as root.${NC}"
    exit 1
fi

################################################################################
# 2. UTILITY FUNCTIONS
################################################################################

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

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        OS_FAMILY=$(echo "$ID" | grep -oE "debian|ubuntu|centos|rhel|fedora" | head -1)
    else
        log_error "Could not detect OS. Please check /etc/os-release"
        exit 1
    fi
    
    # Normalize OS family
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
            log_error "Unsupported OS: $OS ($OS_FAMILY)"
            exit 1
            ;;
    esac
}

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

check_kernel_version() {
    KERNEL_VER=$(uname -r | cut -d. -f1)
    if [ "$KERNEL_VER" -lt 4 ]; then
        log_warn "Kernel version 4.x+ recommended for BBR. Current: $(uname -r)"
    else
        log_success "Kernel version OK: $(uname -r)"
    fi
}

check_dependencies() {
    local missing=0
    for cmd in curl wget jq openssl systemctl iptables; do
        if ! command -v $cmd &>/dev/null; then
            log_warn "Missing: $cmd"
            missing=1
        fi
    done
    return $missing
}

vps_compatibility_check() {
    log_info "Running VPS compatibility checks..."
    
    # Check if running in container (warn user)
    if grep -qi docker /proc/1/cgroup 2>/dev/null || [ -f /.dockerenv ]; then
        log_warn "Docker container detected. Some features may be limited."
    fi
    
    # Check if systemd is available
    if ! command -v systemctl &>/dev/null; then
        log_error "systemd not found. Please use a systemd-based distro."
        exit 1
    fi
    
    # Check if iptables is available
    if ! command -v iptables &>/dev/null; then
        log_warn "iptables not found. Installing..."
        $INSTALL_CMD iptables iptables-persistent netfilter-persistent
    fi
    
    # Check available memory (minimum 256MB recommended)
    MEM_MB=$(grep MemTotal /proc/meminfo | awk '{print $2 / 1024}' | cut -d. -f1)
    if [ "$MEM_MB" -lt 256 ]; then
        log_error "Insufficient memory. Minimum 256MB required. Available: ${MEM_MB}MB"
        exit 1
    fi
    
    log_success "Compatibility checks passed"
}

################################################################################
# 3. SYSTEM SETUP
################################################################################

banner() {
    clear
    echo -e "${C}${BOLD}████████████████████████████████████████████████████████████${NC}"
    echo -e "${G}${BOLD}   ██████╗ ██████╗ ██╗   ██╗██████╗ ██████╗            ${NC}"
    echo -e "${G}${BOLD}  ██╔═══██╗██╔══██╗██║   ██║██╔══██╗██╔══██╗           ${NC}"
    echo -e "${G}${BOLD}  ██║   ██║██████╔╝██║   ██║██║  ██║██████╔╝           ${NC}"
    echo -e "${G}${BOLD}  ██║   ██║██╔═══╝ ██║   ██║██║  ██║██╔═══╝            ${NC}"
    echo -e "${G}${BOLD}  ╚██████╔╝██║     ╚██████╔╝██████╔╝██║                ${NC}"
    echo -e "${G}${BOLD}   ╚═════╝ ╚═╝      ╚═════╝ ╚═════╝ ╚═╝   ${Y}UDP PANEL  ${NC}"
    echo -e "${C}${BOLD}████████████████████████████████████████████████████████████${NC}"
    echo ""
    echo -e "${Y}OPUDP Panel Installer v4.0${NC}"
    echo -e "OS: ${Y}$OS ($VER)${NC} | Arch: ${Y}$BIN_ARCH${NC}"
    echo -e "Package Manager: ${Y}$PKG_MANAGER${NC}"
    echo ""
}

update_system() {
    log_info "[1/8] Updating system packages..."
    $UPDATE_CMD &>/dev/null || log_warn "Package update had warnings"
    log_success "System packages updated"
}

install_dependencies() {
    log_info "[2/8] Installing dependencies..."
    
    DEPS="curl wget jq openssl vnstat bc netcat-openbsd"
    
    case "$OS_FAMILY" in
        debian|ubuntu)
            DEPS="$DEPS iptables iptables-persistent netfilter-persistent"
            ;;
        centos|rhel|fedora)
            DEPS="$DEPS iptables iptables-services"
            ;;
    esac
    
    # Use non-interactive mode for Debian/Ubuntu
    if [ "$OS_FAMILY" = "debian" ] || [ "$OS_FAMILY" = "ubuntu" ]; then
        DEBIAN_FRONTEND=noninteractive $INSTALL_CMD $DEPS &>/dev/null || {
            log_error "Failed to install dependencies"
            exit 1
        }
    else
        $INSTALL_CMD $DEPS &>/dev/null || {
            log_error "Failed to install dependencies"
            exit 1
        }
    fi
    
    log_success "Dependencies installed"
}

enable_bbr() {
    log_info "[3/8] Enabling BBR congestion control..."
    
    # Check if BBR kernel module exists
    if modinfo tcp_bbr &>/dev/null; then
        cat <<'EOF' >> /etc/sysctl.conf

# === BBR Congestion Control (OfficialOnePesewa) ===
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# TCP Performance Tuning
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 65536 67108864
net.core.netdev_max_backlog=5000
net.ipv4.tcp_max_syn_backlog=5000
net.ipv4.ip_local_port_range=10000 65000

# UDP and Connection Tweaks
net.ipv4.udp_mem=102400 873800 2097152
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=30
EOF
        
        sysctl -p -q &>/dev/null
        modprobe tcp_bbr &>/dev/null
        log_success "BBR optimization enabled"
    else
        log_warn "BBR kernel module not available. Skipping BBR setup."
    fi
}

fetch_geo_ip() {
    log_info "[4/8] Fetching server information..."
    
    # Try primary endpoint first, fallback to secondary
    GEO=$(curl -4 -s --max-time 10 "https://ipapi.co/json/" 2>/dev/null || \
          curl -4 -s --max-time 10 "https://ip-api.com/json/" 2>/dev/null || \
          echo '{}')
    
    IP=$(echo "$GEO" | grep -oP '"ip":\s*"\K[^"]+' 2>/dev/null || echo "N/A")
    CITY=$(echo "$GEO" | grep -oP '"city":\s*"\K[^"]+' 2>/dev/null || echo "Unknown")
    COUNTRY=$(echo "$GEO" | grep -oP '"country_name":\s*"\K[^"]+' 2>/dev/null || echo "Unknown")
    ISP=$(echo "$GEO" | grep -oP '"org":\s*"\K[^"]+' 2>/dev/null || echo "Unknown")
    
    log_success "Server IP: $IP ($CITY, $COUNTRY)"
}

download_zivpn_binary() {
    log_info "[5/8] Downloading ZIVPN binary (v$ZIVPN_VERSION, $BIN_ARCH)..."
    
    ZIVPN_URL="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_${ZIVPN_VERSION}/udp-zivpn-linux-${BIN_ARCH}"
    
    if ! wget -q --show-progress -O /usr/local/bin/zivpn "$ZIVPN_URL" 2>&1 | tee -a "$INSTALL_LOG"; then
        log_error "Failed to download ZIVPN binary"
        log_warn "Check internet connection or ZIVPN release availability"
        exit 1
    fi
    
    chmod +x /usr/local/bin/zivpn
    log_success "ZIVPN binary installed"
}

setup_zivpn_config() {
    log_info "[6/8] Configuring ZIVPN..."
    
    mkdir -p /etc/zivpn
    
    # Generate self-signed certificate
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=GH/ST=Accra/L=Accra/O=OfficialOnePesewa/CN=zivpn" \
        -keyout "/etc/zivpn/zivpn.key" \
        -out "/etc/zivpn/zivpn.crt" 2>/dev/null || {
        log_error "SSL certificate generation failed"
        exit 1
    }
    
    # Create config.json
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
    
    # Create empty users database
    touch /etc/zivpn/users.db
    chmod 600 /etc/zivpn/users.db
    
    log_success "ZIVPN configuration created"
}

setup_firewall() {
    log_info "[7/8] Configuring firewall rules..."
    
    # Disable UFW if present (conflicts with iptables)
    if command -v ufw &>/dev/null; then
        ufw disable &>/dev/null || true
        log_warn "UFW disabled (conflicts with iptables)"
    fi
    
    # Allow SSH (critical!)
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
    
    # Allow ZIVPN ports
    iptables -I INPUT -p udp --dport 5667 -j ACCEPT 2>/dev/null || true
    iptables -I INPUT -p udp --dport 6000:19999 -j ACCEPT 2>/dev/null || true
    
    # NAT forwarding for UDP range
    iptables -t nat -A PREROUTING -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null || true
    
    # Persist rules
    if command -v netfilter-persistent &>/dev/null; then
        netfilter-persistent save &>/dev/null || true
    elif [ -f /etc/iptables/rules.v4 ]; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    fi
    
    log_success "Firewall rules configured"
}

setup_systemd_service() {
    log_info "[8/8] Creating systemd service..."
    
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
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload &>/dev/null
    systemctl enable zivpn &>/dev/null
    systemctl start zivpn &>/dev/null || {
        log_error "Failed to start ZIVPN service"
        log_info "Check logs: journalctl -u zivpn -n 20"
    }
    
    # Verify service is running
    sleep 2
    if systemctl is-active --quiet zivpn; then
        log_success "ZIVPN service running"
    else
        log_warn "ZIVPN service failed to start (check logs)"
    fi
}

download_opudp_panel() {
    log_info "Downloading OPUDP panel..."
    
    mkdir -p /usr/lib/opudp
    
    # Download main executable
    if ! wget -q -O /usr/local/bin/opudp "${GITHUB_RAW}/opudp"; then
        log_error "Failed to download opudp panel"
        exit 1
    fi
    chmod +x /usr/local/bin/opudp
    
    log_success "OPUDP panel installed"
}

################################################################################
# 4. FINAL SUMMARY
################################################################################

show_summary() {
    clear
    echo -e "${C}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${G}${BOLD}           🎉 INSTALLATION SUCCESSFUL! 🎉${NC}"
    echo -e "${C}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${Y}Server Details:${NC}"
    echo -e "  IP Address    : ${G}$IP${NC}"
    echo -e "  Location      : ${G}${CITY}, ${COUNTRY}${NC}"
    echo -e "  ISP           : ${G}$ISP${NC}"
    echo ""
    echo -e "${Y}ZIVPN Setup:${NC}"
    echo -e "  Binary        : ${G}/usr/local/bin/zivpn${NC}"
    echo -e "  Config        : ${G}/etc/zivpn/config.json${NC}"
    echo -e "  Users DB      : ${G}/etc/zivpn/users.db${NC}"
    echo -e "  Listen Port   : ${G}5667 (UDP)${NC}"
    echo -e "  NAT Range     : ${G}6000-19999${NC}"
    echo ""
    echo -e "${Y}OPUDP Dashboard:${NC}"
    echo -e "  Command       : ${G}opudp${NC}"
    echo -e "  Binary        : ${G}/usr/local/bin/opudp${NC}"
    echo ""
    echo -e "${Y}Next Steps:${NC}"
    echo -e "  1. Type ${G}opudp${NC} to open the dashboard"
    echo -e "  2. Create your first user (Option 6)"
    echo -e "  3. Check status with ${G}systemctl status zivpn${NC}"
    echo -e "  4. View logs with ${G}journalctl -u zivpn -f${NC}"
    echo ""
    echo -e "${Y}Support:${NC}"
    echo -e "  Admin    : ${G}@OfficialOnePesewa${NC}"
    echo -e "  Telegram : ${G}https://t.me/OfficialOnePesewa${NC}"
    echo -e "  Logs     : ${G}$INSTALL_LOG${NC}"
    echo ""
    echo -e "${C}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

################################################################################
# 5. MAIN EXECUTION
################################################################################

main() {
    banner
    
    # Initialization
    log_info "Starting OPUDP Panel Installation..."
    log_info "Timestamp: $TIMESTAMP"
    log_info "Installer Log: $INSTALL_LOG"
    echo ""
    
    # Pre-flight checks
    log_info "Running pre-flight checks..."
    detect_os
    detect_arch
    check_kernel_version
    check_dependencies || log_warn "Some dependencies may be missing (will attempt auto-install)"
    vps_compatibility_check
    echo ""
    
    # Installation steps
    update_system
    install_dependencies
    enable_bbr
    fetch_geo_ip
    download_zivpn_binary
    setup_zivpn_config
    setup_firewall
    setup_systemd_service
    download_opudp_panel
    
    echo ""
    show_summary
    
    log_success "Installation completed successfully!"
}

# Error handling
trap 'log_error "Installation interrupted or failed"; exit 1' ERR INT

# Run main installation
main "$@"
