#!/bin/bash

# KawaiiSec OS Firewall Setup
# Configures UFW with secure defaults and opens required lab ports

set -euo pipefail

# Configuration
SCRIPT_NAME="KawaiiSec Firewall Setup"
CONFIG_FILE="/etc/kawaiisec/lab_ports.conf"
LOG_FILE="/var/log/kawaiisec-firewall.log"
BACKUP_DIR="/etc/kawaiisec/ufw-backup"

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    echo -e "${RED}❌ Firewall setup failed: $1${NC}" >&2
    exit 1
}

# Success message
success() {
    log "SUCCESS: $1"
    echo -e "${GREEN}✅ $1${NC}"
}

# Warning message  
warning() {
    log "WARNING: $1"
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Info message
info() {
    log "INFO: $1"
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Show banner
show_banner() {
    echo -e "${PURPLE}"
    echo "╭─────────────────────────────────────────╮"
    echo "│  🛡️  KawaiiSec OS Firewall Setup 🛡️   │"
    echo "│     Hardened Lab-Ready Protection      │"
    echo "╰─────────────────────────────────────────╯"
    echo -e "${NC}"
}

# Check if we're running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
}

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$BACKUP_DIR"
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
    log "KawaiiSec OS Firewall Setup Started"
}

# Install UFW if not present
install_ufw() {
    if ! command -v ufw >/dev/null 2>&1; then
        info "Installing UFW (Uncomplicated Firewall)..."
        apt-get update >/dev/null 2>&1
        apt-get install -y ufw >/dev/null 2>&1
        success "UFW installed successfully"
    else
        info "UFW is already installed"
    fi
}

# Backup existing UFW configuration
backup_ufw_config() {
    if [ -d /etc/ufw ]; then
        local backup_file="$BACKUP_DIR/ufw-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
        info "Backing up existing UFW configuration to $backup_file"
        tar -czf "$backup_file" -C /etc ufw >/dev/null 2>&1
        success "UFW configuration backed up"
    fi
}

# Reset UFW to clean state
reset_ufw() {
    info "Resetting UFW to clean state..."
    ufw --force reset >/dev/null 2>&1
    success "UFW reset completed"
}

# Set UFW default policies
set_default_policies() {
    info "Setting secure default policies..."
    
    # Deny all incoming connections by default
    ufw default deny incoming >/dev/null 2>&1
    log "Set default incoming policy: DENY"
    
    # Allow all outgoing connections by default
    ufw default allow outgoing >/dev/null 2>&1
    log "Set default outgoing policy: ALLOW"
    
    # Allow all forwarding (for container networking)
    ufw default allow routed >/dev/null 2>&1
    log "Set default routed policy: ALLOW"
    
    success "Default policies configured"
}

# Read lab ports configuration
read_lab_ports_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        warning "Lab ports configuration file not found: $CONFIG_FILE"
        info "Using default lab ports configuration"
        return 1
    fi
    
    info "Reading lab ports configuration from $CONFIG_FILE"
    return 0
}

# Allow essential services
allow_essential_services() {
    info "Configuring essential services..."
    
    # SSH (default port 22)
    ufw allow ssh comment 'SSH access' >/dev/null 2>&1
    log "Allowed SSH (22/tcp)"
    
    # SSH alternative port for lab environments
    ufw allow 2222/tcp comment 'SSH alternative port for labs' >/dev/null 2>&1
    log "Allowed SSH alternative (2222/tcp)"
    
    success "Essential services configured"
}

# Allow lab environment ports
allow_lab_ports() {
    info "Configuring lab environment ports..."
    
    # Web services
    ufw allow 80/tcp comment 'HTTP for web labs' >/dev/null 2>&1
    ufw allow 443/tcp comment 'HTTPS for web labs' >/dev/null 2>&1
    log "Allowed HTTP/HTTPS (80,443/tcp)"
    
    # Vulnerable web applications
    ufw allow 8080/tcp comment 'DVWA' >/dev/null 2>&1
    ufw allow 3000/tcp comment 'OWASP Juice Shop' >/dev/null 2>&1
    ufw allow 8081/tcp comment 'Apache vulnerable server' >/dev/null 2>&1
    log "Allowed vulnerable web apps (8080,3000,8081/tcp)"
    
    # Database services for labs
    ufw allow 3306/tcp comment 'MySQL for labs' >/dev/null 2>&1
    ufw allow 5432/tcp comment 'PostgreSQL for labs' >/dev/null 2>&1
    log "Allowed database services (3306,5432/tcp)"
    
    # ELK Stack
    ufw allow 9200/tcp comment 'Elasticsearch' >/dev/null 2>&1
    ufw allow 9300/tcp comment 'Elasticsearch cluster' >/dev/null 2>&1
    ufw allow 5601/tcp comment 'Kibana' >/dev/null 2>&1
    ufw allow 5044/tcp comment 'Logstash beats input' >/dev/null 2>&1
    ufw allow 9600/tcp comment 'Logstash monitoring' >/dev/null 2>&1
    log "Allowed ELK Stack (9200,9300,5601,5044,9600/tcp)"
    
    # FTP services for labs
    ufw allow 21/tcp comment 'FTP control' >/dev/null 2>&1
    ufw allow 30000:30009/tcp comment 'FTP passive ports' >/dev/null 2>&1
    log "Allowed FTP services (21,30000-30009/tcp)"
    
    # Metasploitable ports
    ufw allow 2223/tcp comment 'Metasploitable SSH' >/dev/null 2>&1
    ufw allow 2380/tcp comment 'Metasploitable HTTP' >/dev/null 2>&1
    ufw allow 2443/tcp comment 'Metasploitable HTTPS' >/dev/null 2>&1
    ufw allow 2321/tcp comment 'Metasploitable FTP' >/dev/null 2>&1
    ufw allow 2325/tcp comment 'Metasploitable SMTP' >/dev/null 2>&1
    ufw allow 2353/tcp comment 'Metasploitable DNS' >/dev/null 2>&1
    ufw allow 2389/tcp comment 'Metasploitable LDAP' >/dev/null 2>&1
    log "Allowed Metasploitable services (2223,2380,2443,2321,2325,2353,2389/tcp)"
    
    success "Lab environment ports configured"
}

# Allow Docker networking
configure_docker_networking() {
    info "Configuring Docker networking rules..."
    
    # Allow Docker containers to communicate
    ufw allow from 172.17.0.0/16 comment 'Docker default bridge' >/dev/null 2>&1
    ufw allow from 172.20.0.0/16 comment 'KawaiiSec lab network' >/dev/null 2>&1
    log "Allowed Docker networking (172.17.0.0/16, 172.20.0.0/16)"
    
    # Allow container to host communication
    ufw allow in on docker0 >/dev/null 2>&1 || true
    log "Allowed Docker bridge interface"
    
    success "Docker networking configured"
}

# Configure additional security rules
configure_security_rules() {
    info "Configuring additional security rules..."
    
    # Rate limiting for SSH
    ufw limit ssh comment 'Rate limit SSH connections' >/dev/null 2>&1
    log "Applied SSH rate limiting"
    
    # Allow loopback interface
    ufw allow in on lo >/dev/null 2>&1
    ufw allow out on lo >/dev/null 2>&1
    log "Allowed loopback interface"
    
    # Allow DHCP client
    ufw allow out 67 comment 'DHCP client' >/dev/null 2>&1
    ufw allow out 68 comment 'DHCP client' >/dev/null 2>&1
    log "Allowed DHCP client"
    
    # Allow DNS
    ufw allow out 53 comment 'DNS queries' >/dev/null 2>&1
    log "Allowed DNS queries"
    
    # Allow NTP
    ufw allow out 123 comment 'NTP time sync' >/dev/null 2>&1
    log "Allowed NTP time sync"
    
    success "Additional security rules configured"
}

# Enable UFW
enable_ufw() {
    info "Enabling UFW firewall..."
    
    # Enable UFW non-interactively
    ufw --force enable >/dev/null 2>&1
    
    # Verify UFW is active
    if ufw status | grep -q "Status: active"; then
        success "UFW firewall enabled and active"
    else
        error_exit "Failed to enable UFW firewall"
    fi
}

# Show firewall status
show_status() {
    info "Current firewall configuration:"
    echo -e "${CYAN}"
    ufw status verbose
    echo -e "${NC}"
    
    log "Firewall status displayed"
}

# Create systemd service for firewall management
create_systemd_service() {
    info "Creating systemd service for firewall management..."
    
    cat > /etc/systemd/system/kawaiisec-firewall.service << 'EOF'
[Unit]
Description=KawaiiSec OS Firewall Setup
After=network.target
Wants=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/kawaiisec-firewall-setup.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload >/dev/null 2>&1
    systemctl enable kawaiisec-firewall.service >/dev/null 2>&1
    
    success "Systemd service created and enabled"
}

# Test firewall configuration
test_firewall() {
    info "Testing firewall configuration..."
    
    # Check UFW status
    if ! ufw status | grep -q "Status: active"; then
        error_exit "UFW is not active"
    fi
    
    # Test essential ports are open
    local test_ports=("22" "80" "443" "3000" "8080")
    for port in "${test_ports[@]}"; do
        if ufw status | grep -q "${port}/tcp.*ALLOW"; then
            log "Port ${port}/tcp is correctly allowed"
        else
            warning "Port ${port}/tcp may not be configured correctly"
        fi
    done
    
    success "Firewall configuration test completed"
}

# Parse command line arguments
parse_args() {
    case "${1:-setup}" in
        setup|install)
            return 0
            ;;
        reset)
            RESET_MODE=true
            return 0
            ;;
        status)
            STATUS_ONLY=true
            return 0
            ;;
        test)
            TEST_ONLY=true
            return 0
            ;;
        *)
            echo "Usage: $0 {setup|reset|status|test}"
            echo "  setup  - Configure UFW with KawaiiSec defaults (default)"
            echo "  reset  - Reset UFW to clean state and reconfigure"
            echo "  status - Show current firewall status"
            echo "  test   - Test firewall configuration"
            exit 1
            ;;
    esac
}

# Main function
main() {
    # Parse arguments
    parse_args "${1:-setup}"
    
    # Initialize
    show_banner
    check_root
    init_logging
    
    # Handle different modes
    if [[ "${STATUS_ONLY:-false}" == "true" ]]; then
        show_status
        exit 0
    fi
    
    if [[ "${TEST_ONLY:-false}" == "true" ]]; then
        test_firewall
        exit 0
    fi
    
    # Main setup process
    info "Starting KawaiiSec OS firewall configuration"
    
    install_ufw
    backup_ufw_config
    
    # Reset if requested or if this is a fresh setup
    if [[ "${RESET_MODE:-false}" == "true" ]] || ! ufw status | grep -q "Status: active"; then
        reset_ufw
    fi
    
    # Configure firewall
    set_default_policies
    allow_essential_services
    allow_lab_ports
    configure_docker_networking
    configure_security_rules
    
    # Enable and test
    enable_ufw
    create_systemd_service
    test_firewall
    
    # Show final status
    show_status
    
    success "KawaiiSec OS firewall setup completed successfully"
    info "Firewall logs available at: $LOG_FILE"
    info "Configuration backup saved to: $BACKUP_DIR"
    
    log "KawaiiSec OS Firewall Setup Completed Successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 