#!/bin/bash

# KawaiiSec OS Wallpaper Auto-Setter
# Ensures the kawaii wallpaper is applied to all connected monitors in XFCE

set -e

# Path to the desired wallpaper
WALLPAPER="/usr/share/backgrounds/kawaiisec/kawaii_cafe.png"

# Wait for xfconfd to start
sleep 5

# Get all monitors and screens
properties=$(xfconf-query -c xfce4-desktop -l | grep "last-image" || true)

if [ -n "$properties" ]; then
    echo "Applying wallpaper to existing properties..."
    for prop in $properties; do
        xfconf-query -c xfce4-desktop -p "$prop" -s "$WALLPAPER"
    done
fi

# Try to find and set for all monitors even if not in config yet
monitors=$(xfconf-query -c xfce4-desktop -l | grep -o "monitor[^/]*" | sort -u || true)

for monitor in $monitors; do
    # For each monitor, set all workspaces
    for i in {0..3}; do
        prop="/backdrop/screen0/$monitor/workspace$i/last-image"
        xfconf-query -c xfce4-desktop -p "$prop" -n -t string -s "$WALLPAPER" 2>/dev/null || \
        xfconf-query -c xfce4-desktop -p "$prop" -s "$WALLPAPER"
        
        # Also set image-style to 5 (stretched/zoomed)
        xfconf-query -c xfce4-desktop -p "/backdrop/screen0/$monitor/workspace$i/image-style" -n -t int -s 5 2>/dev/null || \
        xfconf-query -c xfce4-desktop -p "/backdrop/screen0/$monitor/workspace$i/image-style" -s 5
    done
done

echo "✅ Wallpapers applied to all monitors!"
