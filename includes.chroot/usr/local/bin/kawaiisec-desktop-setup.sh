#!/bin/bash

# KawaiiSec OS Desktop Environment Setup
# Installs and configures XFCE with KawaiiSec branding

set -euo pipefail

# Configuration
LOG_FILE="/var/log/kawaiisec-desktop-setup.log"
BACKGROUNDS_DIR="/usr/share/backgrounds/kawaiisec"
ICONS_DIR="/usr/share/icons/kawaiisec"
SKEL_DIR="/etc/skel"

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
    echo -e "${RED}❌ Desktop setup failed: $1${NC}" >&2
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

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run as root"
    fi
}

# Install XFCE Desktop Environment
install_xfce() {
    info "Installing XFCE Desktop Environment..."
    
    # Update package lists
    apt update || error_exit "Failed to update package lists"
    
    # Install XFCE and related packages
    apt install -y \
        xfce4 \
        xfce4-goodies \
        lightdm \
        lightdm-gtk-greeter \
        lightdm-gtk-greeter-settings \
        xorg \
        xserver-xorg \
        xfce4-terminal \
        thunar \
        xfce4-panel \
        xfce4-settings \
        xfce4-session \
        xfwm4 \
        xfdesktop4 \
        ristretto \
        mousepad \
        || error_exit "Failed to install XFCE packages"
    
    success "XFCE Desktop Environment installed successfully"
}

# Remove heavy desktop environments
remove_heavy_desktops() {
    info "Removing unnecessary desktop environments..."
    
    # Remove GNOME if installed
    apt remove --purge -y gnome* 2>/dev/null || true
    
    # Remove KDE if installed  
    apt remove --purge -y kde* plasma* 2>/dev/null || true
    
    # Clean up
    apt autoremove -y 2>/dev/null || true
    apt autoclean 2>/dev/null || true
    
    success "Cleaned up unnecessary desktop packages"
}

# Set XFCE as default desktop
set_xfce_default() {
    info "Setting XFCE as default desktop environment..."
    
    # Set default session
    echo 'xfce4-session' > /etc/X11/default-display-manager
    
    # Enable lightdm
    systemctl enable lightdm || warning "Failed to enable lightdm"
    
    success "XFCE set as default desktop"
}

# Configure lightdm with KawaiiSec branding
configure_lightdm() {
    info "Configuring lightdm with KawaiiSec branding..."
    
    # Ensure lightdm directory exists
    mkdir -p /etc/lightdm
    
    cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'EOF'
[greeter]
background=/usr/share/backgrounds/kawaiisec/kawaii_cafe.png
theme-name=Adwaita-dark
icon-theme-name=kawaiisec
font-name=Noto Sans 11
xft-antialias=true
xft-dpi=96
xft-hintstyle=slight
xft-rgba=rgb
show-indicators=~host;~spacer;~clock;~spacer;~layout;~session;~a11y;~power
show-clock=true
clock-format=%H:%M
user-background=true
hide-user-image=false
screensaver-timeout=300
EOF
    
    # Force lightdm to use our configuration
    chmod 644 /etc/lightdm/lightdm-gtk-greeter.conf
    
    success "Lightdm configured with KawaiiSec branding"
}

# Setup KawaiiSec branding directories
setup_branding_directories() {
    info "Setting up KawaiiSec branding directories..."
    
    # Create backgrounds directory
    mkdir -p "$BACKGROUNDS_DIR" || error_exit "Failed to create backgrounds directory"
    chmod 755 "$BACKGROUNDS_DIR"
    
    # Create icons directory
    mkdir -p "$ICONS_DIR" || error_exit "Failed to create icons directory"
    chmod 755 "$ICONS_DIR"
    
    # Create subdirectories for icons
    mkdir -p "$ICONS_DIR"/{16x16,22x22,24x24,32x32,48x48,64x64,128x128,256x256}/apps
    mkdir -p "$ICONS_DIR"/{16x16,22x22,24x24,32x32,48x48,64x64,128x128,256x256}/places
    mkdir -p "$ICONS_DIR"/{16x16,22x22,24x24,32x32,48x48,64x64,128x128,256x256}/actions
    
    success "Branding directories created"
}

# Install KawaiiSec wallpapers and assets
install_branding_assets() {
    info "Installing KawaiiSec branding assets..."
    
    # Copy wallpapers if they exist
    if [ -d "/usr/share/kawaiisec/res/Wallpapers" ]; then
        cp /usr/share/kawaiisec/res/Wallpapers/* "$BACKGROUNDS_DIR/" 2>/dev/null || true
    fi
    
    # Copy logos and icons if they exist  
    if [ -d "/usr/share/kawaiisec/assets/graphics/logos" ]; then
        cp /usr/share/kawaiisec/assets/graphics/logos/* "$ICONS_DIR/" 2>/dev/null || true
    fi
    
    # Copy icons from the new location
    if [ -d "/usr/share/icons/kawaiisec" ]; then
        cp /usr/share/icons/kawaiisec/* "$ICONS_DIR/" 2>/dev/null || true
    fi
    
    # Set appropriate permissions
    find "$BACKGROUNDS_DIR" -type f -exec chmod 644 {} \; 2>/dev/null || true
    find "$ICONS_DIR" -type f -exec chmod 644 {} \; 2>/dev/null || true
    
    # Create icon theme index
    cat > "$ICONS_DIR/index.theme" << 'EOF'
[Icon Theme]
Name=KawaiiSec
Comment=KawaiiSec OS Icon Theme
Inherits=Adwaita,hicolor

Directories=16x16/apps,22x22/apps,24x24/apps,32x32/apps,48x48/apps,64x64/apps,128x128/apps,256x256/apps

[16x16/apps]
Size=16
Context=Applications
Type=Fixed

[22x22/apps]
Size=22
Context=Applications
Type=Fixed

[24x24/apps]
Size=24
Context=Applications
Type=Fixed

[32x32/apps]
Size=32
Context=Applications
Type=Fixed

[48x48/apps]
Size=48
Context=Applications
Type=Fixed

[64x64/apps]
Size=64
Context=Applications
Type=Fixed

[128x128/apps]
Size=128
Context=Applications
Type=Fixed

[256x256/apps]
Size=256
Context=Applications
Type=Fixed
EOF
    
    success "KawaiiSec branding assets installed"
}

# Configure XFCE defaults
configure_xfce_defaults() {
    info "Configuring XFCE default settings..."
    
    # Create skel directory structure
    mkdir -p "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml"
    mkdir -p "$SKEL_DIR/.config/xfce4/desktop"
    mkdir -p "$SKEL_DIR/.config/xfce4/panel"
    
    # Also configure for root user (important for live mode)
    mkdir -p "/root/.config/xfce4/xfconf/xfce-perchannel-xml"
    mkdir -p "/root/.config/xfce4/desktop"
    mkdir -p "/root/.config/xfce4/panel"
    
    # Configure wallpaper
    cat > "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorLVDS1" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/kawaiisec/kawaii_cafe.png"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF
    
    # Configure panel
    cat > "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="30"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="separator"/>
    <property name="plugin-3" type="string" value="tasklist"/>
    <property name="plugin-4" type="string" value="separator"/>
    <property name="plugin-5" type="string" value="systray"/>
    <property name="plugin-6" type="string" value="clock"/>
  </property>
</channel>
EOF
    
    # Set permissions
    chown -R root:root "$SKEL_DIR/.config"
    chmod -R 644 "$SKEL_DIR/.config"
    find "$SKEL_DIR/.config" -type d -exec chmod 755 {} \;
    
    success "XFCE default settings configured"
}

# Create desktop entries for KawaiiSec tools
create_desktop_entries() {
    info "Creating desktop entries for KawaiiSec tools..."
    
    mkdir -p /usr/share/applications/kawaiisec
    
    # Terminal entry
    cat > /usr/share/applications/kawaiisec/kawaiisec-terminal.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=KawaiiSec Terminal
Comment=KawaiiSec OS Terminal
Exec=xfce4-terminal
Icon=/usr/share/icons/kawaiisec/terminal.png
Terminal=false
Categories=System;TerminalEmulator;
StartupNotify=true
EOF
    
    # File manager entry
    cat > /usr/share/applications/kawaiisec/kawaiisec-files.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=KawaiiSec Files
Comment=Browse and manage files
Exec=thunar
Icon=/usr/share/icons/kawaiisec/file_manager.png
Terminal=false
Categories=System;FileManager;
StartupNotify=true
MimeType=inode/directory;
EOF
    
    # Web browser entry
    cat > /usr/share/applications/kawaiisec/kawaiisec-browser.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=KawaiiSec Browser
Comment=Web browser for security testing
Exec=firefox-esr
Icon=/usr/share/icons/kawaiisec/browser.png
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
EOF
    
    success "Desktop entries created"
}

# Main function
main() {
    log "Starting KawaiiSec Desktop Environment Setup"
    
    echo -e "${PURPLE}"
    echo "╭─────────────────────────────────────╮"
    echo "│   🌸 KawaiiSec Desktop Setup 🌸    │"
    echo "│    Installing XFCE Environment     │"
    echo "╰─────────────────────────────────────╯"
    echo -e "${NC}"
    
    check_root
    install_xfce
    remove_heavy_desktops
    set_xfce_default
    setup_branding_directories
    install_branding_assets
    configure_lightdm
    configure_xfce_defaults
    create_desktop_entries
    
    success "KawaiiSec Desktop Environment setup completed successfully!"
    info "Lightdm display manager enabled and configured"
    info "XFCE set as default desktop environment"
    info "KawaiiSec branding and themes applied"
    
    echo -e "${GREEN}✨ Desktop environment ready! Reboot to enjoy your new KawaiiSec desktop! ✨${NC}"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 