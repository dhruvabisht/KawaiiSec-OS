#!/bin/bash

# GUARANTEED WALLPAPER FIX
# This script copies wallpapers directly from your project to the VM

echo "🎨 DIRECT WALLPAPER FIX - No more games!"

# Copy wallpapers from your project to a USB/shared folder
# Then run this script in the VM

WALLPAPER_SOURCE="/media/usb/wallpapers"  # Adjust path as needed
DEST_DIR="/usr/share/backgrounds"

if [ ! -d "$WALLPAPER_SOURCE" ]; then
    echo "❌ Please copy wallpapers to $WALLPAPER_SOURCE first"
    echo "From your Mac:"
    echo "1. Copy kawaiisec-docs/res/Wallpapers/* to a USB drive"  
    echo "2. Mount USB in VM"
    echo "3. Run this script"
    exit 1
fi

echo "📂 Copying wallpapers..."
sudo mkdir -p "$DEST_DIR"
sudo cp "$WALLPAPER_SOURCE"/*.png "$DEST_DIR/"

echo "✅ Wallpapers copied. Now they should appear in desktop settings!"
ls -la "$DEST_DIR"/*.png

echo "🔄 Refreshing desktop..."
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$DEST_DIR/kawaii_cafe.png"
