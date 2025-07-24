#!/bin/bash

# KawaiiSec OS First Boot Setup Wizard
# Creates initial user account and sets up basic system configuration

set -euo pipefail

# Configuration
MARKER_FILE="/var/lib/kawaiisec/firstboot-done"
MARKER_DIR="/var/lib/kawaiisec"
LOG_FILE="/var/log/kawaiisec-firstboot.log"

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
    echo -e "${RED}❌ Setup failed: $1${NC}" >&2
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

# Check if we're running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
}

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
    log "KawaiiSec OS First Boot Setup Started"
}

# Show welcome screen
show_welcome() {
    whiptail --title "🌸 KawaiiSec OS First Boot Setup 🌸" \
        --msgbox "Welcome to KawaiiSec OS!\n\nThis wizard will help you set up your system for the first time:\n\n• Create your user account\n• Configure initial settings\n• Set up security tools\n• Initialize lab environments\n\nPress OK to continue." \
        16 70
}

# Get username from user
get_username() {
    local username
    while true; do
        username=$(whiptail --title "User Account Setup" \
            --inputbox "Enter your desired username:" \
            10 50 "kawaiisec" 3>&1 1>&2 2>&3)
        
        if [[ $? -ne 0 ]]; then
            exit 1
        fi
        
        # Validate username
        if [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]] && [[ ${#username} -le 32 ]]; then
            if ! id "$username" &>/dev/null; then
                echo "$username"
                return
            else
                whiptail --title "Error" --msgbox "User '$username' already exists. Please choose a different username." 8 60
            fi
        else
            whiptail --title "Invalid Username" --msgbox "Username must:\n• Start with a letter or underscore\n• Contain only lowercase letters, numbers, underscore, and hyphen\n• Be 32 characters or less" 10 60
        fi
    done
}

# Get password from user
get_password() {
    local password confirm_password
    while true; do
        password=$(whiptail --title "Password Setup" \
            --passwordbox "Enter password for your account:" \
            10 50 3>&1 1>&2 2>&3)
        
        if [[ $? -ne 0 ]]; then
            exit 1
        fi
        
        if [[ ${#password} -lt 8 ]]; then
            whiptail --title "Weak Password" --msgbox "Password must be at least 8 characters long." 8 50
            continue
        fi
        
        confirm_password=$(whiptail --title "Confirm Password" \
            --passwordbox "Confirm your password:" \
            10 50 3>&1 1>&2 2>&3)
        
        if [[ $? -ne 0 ]]; then
            exit 1
        fi
        
        if [[ "$password" == "$confirm_password" ]]; then
            echo "$password"
            return
        else
            whiptail --title "Password Mismatch" --msgbox "Passwords do not match. Please try again." 8 50
        fi
    done
}

# Create user account
create_user() {
    local username="$1"
    local password="$2"
    
    info "Creating user account: $username"
    
    # Create user with home directory
    useradd -m -s /bin/bash -G sudo,docker,wireshark,audio,video "$username" || error_exit "Failed to create user account"
    
    # Set password
    echo "$username:$password" | chpasswd || error_exit "Failed to set user password"
    
    # Create user directories
    mkdir -p "/home/$username"/{Desktop,Documents,Downloads,Pictures,Videos,Labs}
    
    # Set ownership
    chown -R "$username:$username" "/home/$username"
    
    success "User account '$username' created successfully"
}

# Configure system settings
configure_system() {
    local username="$1"
    
    info "Configuring system settings..."
    
    # Set hostname
    echo "kawaiisec" > /etc/hostname
    hostnamectl set-hostname kawaiisec
    
    # Update hosts file
    sed -i "s/127.0.1.1.*/127.0.1.1\tkawaiisec/" /etc/hosts
    
    # Enable services
    systemctl enable ssh
    systemctl enable docker
    systemctl enable kawaiisec-firstboot.service
    
    # Configure sudo
    echo "$username ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$username"
    
    success "System configuration completed"
}

# Initialize security tools
init_security_tools() {
    local username="$1"
    
    info "Initializing security tools..."
    
    # Initialize Metasploit database
    if command -v msfdb >/dev/null 2>&1; then
        if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw msf; then
            msfdb init >/dev/null 2>&1 || warning "Failed to initialize Metasploit database"
        fi
        success "Metasploit database initialized"
    fi
    
    # Start Docker service
    systemctl enable docker >/dev/null 2>&1 || true
    systemctl start docker >/dev/null 2>&1 || true
    
    # Pull essential Docker images in background
    {
        docker pull vulnerables/web-dvwa:latest >/dev/null 2>&1 || true
        docker pull bkimminich/juice-shop:latest >/dev/null 2>&1 || true
        docker pull postgres:13 >/dev/null 2>&1 || true
    } &
    
    success "Security tools initialized"
}

# Set up lab environments
setup_labs() {
    local username="$1"
    
    info "Setting up lab environments..."
    
    # Create lab directories
    mkdir -p /opt/kawaiisec/labs/{docker,vagrant,custom}
    mkdir -p "/home/$username/Labs"
    
    # Set ownership
    chown -R "$username:$username" "/home/$username/Labs"
    
    # Create symlink for easy access
    ln -sf /opt/kawaiisec/labs "/home/$username/Labs/KawaiiSec"
    
    success "Lab environments configured"
}

# Set up desktop environment
setup_desktop_environment() {
    local username="$1"
    
    info "Setting up desktop environment..."
    
    # Run desktop setup script if available
    if [[ -f /usr/local/bin/kawaiisec-desktop-setup.sh ]]; then
        /usr/local/bin/kawaiisec-desktop-setup.sh || warning "Desktop setup encountered issues"
    fi
    
    # Set up user desktop preferences
    mkdir -p "/home/$username/.config/xfce4/xfconf/xfce-perchannel-xml"
    
    # Copy default configurations if they exist
    if [[ -d /etc/skel/.config ]]; then
        cp -r /etc/skel/.config/* "/home/$username/.config/" 2>/dev/null || true
    fi
    
    # Set ownership
    chown -R "$username:$username" "/home/$username/.config"
    
    success "Desktop environment configured"
}

# Show completion message
show_completion() {
    local username="$1"
    
    whiptail --title "🌸 Setup Complete! 🌸" \
        --msgbox "KawaiiSec OS setup completed successfully!\n\n✅ User account '$username' created\n✅ System configured\n✅ Security tools initialized\n✅ Lab environments ready\n\nYour system will reboot shortly.\n\nAfter reboot, log in with your new account and run:\n  kawaiisec-help.sh\n\nEnjoy exploring cybersecurity with KawaiiSec OS! 🌸" \
        18 70
}

# Create completion marker
create_marker() {
    mkdir -p "$MARKER_DIR"
    touch "$MARKER_FILE"
    chmod 644 "$MARKER_FILE"
    log "First boot setup marked as completed"
}

# Main function
main() {
    # Initialize
    check_root
    init_logging
    
    info "Starting KawaiiSec OS first boot setup"
    
    # Check if already completed
    if [[ -f "$MARKER_FILE" ]]; then
        info "First boot setup already completed"
        exit 0
    fi
    
    # Check if running in live environment
    if grep -q "boot=live" /proc/cmdline; then
        info "Running in live environment, skipping first boot setup"
        exit 0
    fi
    
    # Show welcome and collect user information
    show_welcome
    
    local username password
    username=$(get_username)
    password=$(get_password)
    
    # Perform setup steps
    create_user "$username" "$password"
    configure_system "$username"
    init_security_tools "$username"
    setup_labs "$username"
    setup_desktop_environment "$username"
    
    # Mark as completed
    create_marker
    
    # Show completion message
    show_completion "$username"
    
    info "KawaiiSec OS first boot setup completed successfully"
    
    # Schedule reboot in 30 seconds to allow user to read completion message
    shutdown -r +1 "KawaiiSec OS setup completed. Rebooting..." >/dev/null 2>&1 || true
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 