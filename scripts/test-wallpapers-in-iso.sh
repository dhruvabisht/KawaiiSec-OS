#!/bin/bash

# Test if wallpapers are actually in the ISO
# This mounts the ISO and checks for wallpapers

set -euo pipefail

ISO_FILE="${1:-output/kawaiisec-os-2025.08.17-amd64.iso}"

if [ ! -f "$ISO_FILE" ]; then
    echo "❌ ISO file not found: $ISO_FILE"
    exit 1
fi

echo "🔍 Testing wallpapers in ISO: $ISO_FILE"

# Create temporary mount point
MOUNT_POINT="/tmp/kawaiisec-iso-test-$$"
mkdir -p "$MOUNT_POINT"

# Mount the ISO (macOS compatible)
if hdiutil attach "$ISO_FILE" -mountpoint "$MOUNT_POINT" -nobrowse -quiet; then
    echo "✅ ISO mounted at $MOUNT_POINT"
    
    echo ""
    echo "🔍 Checking for wallpapers in mounted ISO:"
    
    # Check various locations where wallpapers might be
    echo "📂 Checking /usr/share/backgrounds:"
    find "$MOUNT_POINT" -path "*/usr/share/backgrounds*" -name "*.png" 2>/dev/null || echo "No wallpapers found in backgrounds"
    
    echo ""
    echo "📂 Checking for kawaii_cafe.png specifically:"
    find "$MOUNT_POINT" -name "kawaii_cafe.png" 2>/dev/null || echo "kawaii_cafe.png not found"
    
    echo ""
    echo "📂 Checking for any PNG files:"
    find "$MOUNT_POINT" -name "*.png" 2>/dev/null | head -10 || echo "No PNG files found"
    
    # Unmount
    hdiutil detach "$MOUNT_POINT" -quiet || true
    rmdir "$MOUNT_POINT" 2>/dev/null || true
    
else
    echo "❌ Failed to mount ISO"
    exit 1
fi

echo ""
echo "🎯 If no wallpapers were found, the build process is not copying them correctly."
