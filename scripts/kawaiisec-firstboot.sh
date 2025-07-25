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
            --inputbox "Enter your username:\n\n(3-32 characters, alphanumeric and underscore only)" \
            10 60 "" 3>&1 1>&2 2>&3)
        
        # Check if user cancelled
        if [[ $? -ne 0 ]]; then
            error_exit "Setup cancelled by user"
        fi
        
        # Validate username
        if [[ -z "$username" ]]; then
            whiptail --title "Invalid Username" \
                --msgbox "Username cannot be empty. Please try again." 8 50
            continue
        fi
        
        if [[ ! "$username" =~ ^[a-zA-Z0-9_]{3,32}$ ]]; then
            whiptail --title "Invalid Username" \
                --msgbox "Username must be 3-32 characters long and contain only letters, numbers, and underscores." 10 60
            continue
        fi
        
        # Check if user already exists
        if id "$username" &>/dev/null; then
            whiptail --title "User Exists" \
                --msgbox "User '$username' already exists. Please choose a different username." 8 60
            continue
        fi
        
        break
    done
    
    echo "$username"
}

# Get password from user with confirmation
get_password() {
    local password confirm_password
    
    while true; do
        password=$(whiptail --title "Password Setup" \
            --passwordbox "Enter password for your account:\n\n(Minimum 8 characters recommended)" \
            10 60 3>&1 1>&2 2>&3)
        
        # Check if user cancelled
        if [[ $? -ne 0 ]]; then
            error_exit "Setup cancelled by user"
        fi
        
        # Check password length
        if [[ ${#password} -lt 6 ]]; then
            whiptail --title "Password Too Short" \
                --msgbox "Password must be at least 6 characters long. Please try again." 8 60
            continue
        fi
        
        confirm_password=$(whiptail --title "Confirm Password" \
            --passwordbox "Please confirm your password:" \
            8 60 3>&1 1>&2 2>&3)
        
        # Check if user cancelled
        if [[ $? -ne 0 ]]; then
            error_exit "Setup cancelled by user"
        fi
        
        # Check if passwords match
        if [[ "$password" != "$confirm_password" ]]; then
            whiptail --title "Password Mismatch" \
                --msgbox "Passwords do not match. Please try again." 8 50
            continue
        fi
        
        break
    done
    
    echo "$password"
}

# Create user account
create_user() {
    local username="$1"
    local password="$2"
    
    info "Creating user account: $username"
    
    # Create user with home directory
    if ! useradd -m -s /bin/bash "$username"; then
        error_exit "Failed to create user account"
    fi
    
    # Set password
    if ! echo "$username:$password" | chpasswd; then
        error_exit "Failed to set user password"
    fi
    
    # Add user to sudo group
    if ! usermod -aG sudo "$username"; then
        error_exit "Failed to add user to sudo group"
    fi
    
    # Add user to additional groups for security tools
    usermod -aG docker,wireshark,vboxusers,dialout "$username" 2>/dev/null || true
    
    success "User account '$username' created successfully"
}

# Configure system settings
configure_system() {
    local username="$1"
    
    info "Configuring system settings..."
    
    # Set hostname if not already set to something meaningful
    if [[ "$(hostname)" == "localhost" ]] || [[ "$(hostname)" == "debian" ]]; then
        hostnamectl set-hostname "kawaiisec-$(tr -dc 'a-z0-9' < /dev/urandom | head -c 6)"
        success "Hostname configured"
    fi
    
    # Configure timezone
    if whiptail --title "Timezone Configuration" \
        --yesno "Would you like to configure your timezone now?\n\n(Current: $(timedatectl show --property=Timezone --value))" \
        10 60; then
        
        dpkg-reconfigure tzdata
        success "Timezone configured"
    fi
    
    # Enable firewall
    if command -v ufw >/dev/null 2>&1; then
        ufw --force enable >/dev/null 2>&1 || true
        success "Firewall enabled"
    fi
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
    echo "KawaiiSec OS first boot setup completed on $(date)" > "$MARKER_FILE"
    success "Setup marker created"
}

# Cleanup function
cleanup() {
    info "Cleaning up temporary files..."
    # Remove any temporary files if needed
}

# Setup desktop environment for the user
setup_desktop_environment() {
    local username="$1"
    
    if command -v xfce4-session >/dev/null 2>&1; then
        info "XFCE desktop environment detected, configuring for user: $username"
        
        # Ensure proper desktop configuration for new users
        if [ -d /etc/skel/.config/xfce4 ]; then
            info "XFCE default configuration already available"
        else
            warning "XFCE configuration missing, running desktop setup..."
            /usr/local/bin/kawaiisec-desktop-setup.sh 2>/dev/null || warning "Desktop setup failed"
        fi
        
        # Apply user-specific desktop settings
        whiptail --title "Desktop Environment" \
            --msgbox "XFCE desktop environment is configured with KawaiiSec branding.\n\nFeatures:\n• Lightweight and fast\n• KawaiiSec wallpapers and themes\n• Security tool integration\n• Multiple workspaces\n\nYou can customize the desktop after login using the Settings Manager." \
            14 70
            
        log "Desktop environment configured for user: $username"
    else
        info "No desktop environment detected, running in server mode"
    fi
}

# Signal handlers
trap cleanup EXIT
trap 'error_exit "Setup interrupted"' INT TERM

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