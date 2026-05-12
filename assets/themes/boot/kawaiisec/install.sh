#!/bin/bash
# 🌸 KawaiiSec Plymouth Theme Installer 🌸

set -e

THEME_NAME="kawaiisec"
THEME_DIR="/usr/share/plymouth/themes/$THEME_NAME"
ASSETS_DIR="/Applications/Dhruva/Projects/KawaiiSec-OS/assets/assets/themes/boot"

echo "🌸 Installing KawaiiSec Plymouth Boot Splash Theme..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   exit 1
fi

# Install Plymouth if not present
if ! command -v plymouth &> /dev/null; then
    echo "📦 Installing Plymouth..."
    apt update
    apt install -y plymouth plymouth-themes
fi

# Create theme directory
echo "📁 Creating theme directory..."
mkdir -p "$THEME_DIR"

# Copy theme files
echo "📋 Installing theme files..."
cp "$ASSETS_DIR/kawaiisec.plymouth" "$THEME_DIR/"
cp "$ASSETS_DIR/kawaiisec.script" "$THEME_DIR/"

# Copy assets if they exist
for asset in background.png logo.png mascot.png; do
    if [[ -f "$ASSETS_DIR/$asset" ]]; then
        echo "🎨 Installing $asset..."
        cp "$ASSETS_DIR/$asset" "$THEME_DIR/"
    else
        echo "⚠️  $asset not found, theme will use fallback"
    fi
done

# Set theme as default
echo "🎭 Setting KawaiiSec as default Plymouth theme..."
plymouth-set-default-theme "$THEME_NAME"

# Update GRUB configuration
echo "🔧 Updating GRUB configuration..."
if ! grep -q "quiet splash" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& quiet splash/' /etc/default/grub
    echo "✅ Added 'quiet splash' to GRUB"
else
    echo "✅ GRUB already configured for Plymouth"
fi

# Update initramfs and GRUB
echo "🔄 Updating initramfs and GRUB..."
update-initramfs -u
update-grub

echo ""
echo "🎉 KawaiiSec Plymouth theme installed successfully!"
echo ""
echo "🧪 Test the theme:"
echo "   sudo plymouth --show-splash"
echo "   # Press Ctrl+Alt+F1 to return to terminal"
echo ""
echo "🔄 The theme will appear on next reboot!"
echo "🌸 Enjoy your kawaii boot experience! 💖"
