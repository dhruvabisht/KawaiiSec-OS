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
    info "Removing heavy desktop environments..."
    
    # Remove GNOME components
    apt purge -y \
        gnome-shell \
        gnome-session \
        gdm3 \
        nautilus \
        gnome-control-center \
        gnome-terminal \
        2>/dev/null || true
    
    # Remove KDE components
    apt purge -y \
        kde-plasma-desktop \
        plasma-desktop \
        sddm \
        kdm \
        konqueror \
        dolphin \
        konsole \
        2>/dev/null || true
    
    # Remove MATE components
    apt purge -y \
        mate-desktop-environment \
        mate-desktop-environment-core \
        lightdm-settings \
        2>/dev/null || true
    
    # Clean up unused packages
    apt autoremove -y || warning "Some packages could not be auto-removed"
    apt autoclean || warning "Package cache cleanup had issues"
    
    success "Heavy desktop environments removed"
}

# Set XFCE as default session
set_xfce_default() {
    info "Setting XFCE as the default session..."
    
    # Set x-session-manager alternative
    if [ -f /usr/bin/xfce4-session ]; then
        update-alternatives --install /usr/bin/x-session-manager x-session-manager /usr/bin/xfce4-session 50
        update-alternatives --set x-session-manager /usr/bin/xfce4-session
        success "XFCE set as default session manager"
    else
        warning "XFCE session manager not found"
    fi
    
    # Enable and configure lightdm
    systemctl enable lightdm || error_exit "Failed to enable lightdm"
    
    # Configure lightdm greeter
    cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'EOF'
[greeter]
background=/usr/share/backgrounds/kawaiisec/kawaii_cafe.png
theme-name=Adwaita-dark
icon-theme-name=kawaiisec
font-name=Sans 11
xft-antialias=true
xft-dpi=96
xft-hintstyle=hintslight
xft-rgba=rgb
show-indicators=~language;~session;~power
show-clock=true
clock-format=%H:%M
position=50%,center 50%,center
EOF
    
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
    if [ -d "/usr/share/kawaiisec/kawaiisec-docs/res/Wallpapers" ]; then
        cp /usr/share/kawaiisec/kawaiisec-docs/res/Wallpapers/* "$BACKGROUNDS_DIR/" 2>/dev/null || true
    fi
    
    # Copy logos and icons if they exist  
    if [ -d "/usr/share/kawaiisec/assets/graphics/logos" ]; then
        cp /usr/share/kawaiisec/assets/graphics/logos/* "$ICONS_DIR/" 2>/dev/null || true
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
Directories=16x16/apps,22x22/apps,24x24/apps,32x32/apps,48x48/apps,64x64/apps,128x128/apps,256x256/apps,16x16/places,22x22/places,24x24/places,32x32/places,48x48/places,64x64/places,128x128/places,256x256/places,16x16/actions,22x22/actions,24x24/actions,32x32/actions,48x48/actions,64x64/actions,128x128/actions,256x256/actions

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

[16x16/places]
Size=16
Context=Places
Type=Fixed

[22x22/places]
Size=22
Context=Places
Type=Fixed

[24x24/places]
Size=24
Context=Places
Type=Fixed

[32x32/places]
Size=32
Context=Places
Type=Fixed

[48x48/places]
Size=48
Context=Places
Type=Fixed

[64x64/places]
Size=64
Context=Places
Type=Fixed

[128x128/places]
Size=128
Context=Places
Type=Fixed

[256x256/places]
Size=256
Context=Places
Type=Fixed

[16x16/actions]
Size=16
Context=Actions
Type=Fixed

[22x22/actions]
Size=22
Context=Actions
Type=Fixed

[24x24/actions]
Size=24
Context=Actions
Type=Fixed

[32x32/actions]
Size=32
Context=Actions
Type=Fixed

[48x48/actions]
Size=48
Context=Actions
Type=Fixed

[64x64/actions]
Size=64
Context=Actions
Type=Fixed

[128x128/actions]
Size=128
Context=Actions
Type=Fixed

[256x256/actions]
Size=256
Context=Actions
Type=Fixed
EOF
    
    success "KawaiiSec branding assets installed"
}

# Configure XFCE default settings
configure_xfce_defaults() {
    info "Configuring XFCE default settings..."
    
    # Create XFCE config directory in skeleton
    mkdir -p "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml"
    
    # Desktop settings
    cat > "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/kawaiisec/kawaii_cafe.png"/>
          <property name="image-style" type="int" value="5"/>
          <property name="color-style" type="int" value="0"/>
          <property name="image-show" type="bool" value="true"/>
        </property>
      </property>
    </property>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="file-icons" type="empty">
      <property name="show-home" type="bool" value="true"/>
      <property name="show-filesystem" type="bool" value="true"/>
      <property name="show-removable" type="bool" value="true"/>
      <property name="show-trash" type="bool" value="true"/>
    </property>
  </property>
</channel>
EOF

    # Panel settings
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
    <property name="plugin-2" type="string" value="tasklist"/>
    <property name="plugin-3" type="string" value="separator"/>
    <property name="plugin-4" type="string" value="systray"/>
    <property name="plugin-5" type="string" value="clock"/>
    <property name="plugin-6" type="string" value="actions"/>
  </property>
</channel>
EOF

    # Window manager settings
    cat > "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Default"/>
    <property name="title_font" type="string" value="Sans Bold 9"/>
    <property name="button_layout" type="string" value="O|SHMC"/>
    <property name="click_to_focus" type="bool" value="true"/>
    <property name="focus_delay" type="int" value="250"/>
    <property name="raise_delay" type="int" value="250"/>
    <property name="double_click_time" type="int" value="250"/>
    <property name="double_click_distance" type="int" value="5"/>
    <property name="double_click_action" type="string" value="maximize"/>
    <property name="easy_click" type="string" value="Alt"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="snap_to_windows" type="bool" value="false"/>
    <property name="snap_width" type="int" value="10"/>
    <property name="workspace_count" type="int" value="4"/>
    <property name="workspace_names" type="array">
      <value type="string" value="Workspace 1"/>
      <value type="string" value="Workspace 2"/>
      <value type="string" value="Workspace 3"/>
      <value type="string" value="Workspace 4"/>
    </property>
  </property>
</channel>
EOF

    # Session settings
    cat > "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-session" version="1.0">
  <property name="startup" type="empty">
    <property name="screensaver" type="empty">
      <property name="enabled" type="bool" value="true"/>
    </property>
  </property>
  <property name="general" type="empty">
    <property name="FailsafeSessionName" type="string" value="Failsafe"/>
    <property name="SessionName" type="string" value="Default"/>
    <property name="SaveOnExit" type="bool" value="true"/>
  </property>
</channel>
EOF

    # Set permissions
    chmod -R 644 "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/"
    find "$SKEL_DIR/.config" -type d -exec chmod 755 {} \;
    
    success "XFCE default settings configured"
}

# Create desktop entries for KawaiiSec tools
create_desktop_entries() {
    info "Creating desktop entries for KawaiiSec tools..."
    
    mkdir -p /usr/share/applications
    
    # KawaiiSec Help desktop entry
    cat > /usr/share/applications/kawaiisec-help.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=KawaiiSec Help
Comment=KawaiiSec OS Help and Documentation
Exec=kawaiisec-help.sh
Icon=help-browser
Terminal=false
Categories=System;Documentation;
EOF

    # Lab Environment Manager
    cat > /usr/share/applications/kawaiisec-labs.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=KawaiiSec Labs
Comment=Manage KawaiiSec Lab Environments
Exec=xfce4-terminal -e "bash -c 'echo Choose a lab environment:; echo 1. DVWA; echo 2. Juice Shop; echo 3. Metasploitable3; read -p \"Enter choice [1-3]: \" choice; case $choice in 1) launch_dvwa.sh;; 2) run_juice_shop.sh;; 3) start_metasploitable3.sh;; *) echo Invalid choice;; esac; read -p \"Press Enter to continue...\"'"
Icon=applications-system
Terminal=false
Categories=System;Security;
EOF

    chmod 644 /usr/share/applications/kawaiisec-*.desktop
    
    success "Desktop entries created"
}

# Main execution function
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