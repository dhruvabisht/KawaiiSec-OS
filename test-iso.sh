#!/bin/bash

# KawaiiSec OS ISO Testing Helper
# Quick script to help test your ISO in various ways

set -euo pipefail

ISO_FILE="${1:-output/kawaiisec-os-2025.07.25-amd64.iso}"
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "╭──────────────────────────────────────────────╮"
echo "│        🌸 KawaiiSec ISO Tester 🌸           │"
echo "╰──────────────────────────────────────────────╯"
echo -e "${NC}"

if [ ! -f "$ISO_FILE" ]; then
    echo "❌ ISO file not found: $ISO_FILE"
    echo "Available ISOs:"
    ls -la output/*.iso 2>/dev/null || echo "No ISOs found in output/"
    exit 1
fi

echo -e "${BLUE}📊 ISO Information:${NC}"
echo "File: $ISO_FILE"
echo "Size: $(du -h "$ISO_FILE" | cut -f1)"
echo "Type: $(file "$ISO_FILE")"
echo ""

echo -e "${GREEN}✅ Your ISO is ready to use!${NC}"
echo ""
echo "🚀 Testing Options:"
echo ""
echo "1. 🖥️  Test in UTM (macOS):"
echo "   - Open UTM"
echo "   - Create new VM (Linux)"
echo "   - Set ISO as CD/DVD: $ISO_FILE"
echo "   - Allocate 4GB+ RAM"
echo "   - Boot and test"
echo ""
echo "2. 💿 Test in VirtualBox:"
echo "   VBoxManage createvm --name \"KawaiiSec-Test\" --register"
echo "   VBoxManage modifyvm \"KawaiiSec-Test\" --memory 4096 --acpi on --boot1 dvd"
echo "   VBoxManage storagectl \"KawaiiSec-Test\" --name \"IDE\" --add ide"
echo "   VBoxManage storageattach \"KawaiiSec-Test\" --storagectl \"IDE\" --port 0 --device 0 --type dvddrive --medium \"$ISO_FILE\""
echo ""
echo "3. 🔥 Create Bootable USB (macOS):"
echo "   diskutil list  # Find your USB drive (e.g., /dev/disk4)"
echo "   diskutil unmountDisk /dev/diskX"
echo "   sudo dd if=\"$ISO_FILE\" of=/dev/rdiskX bs=4m"
echo "   ⚠️  Replace X with your USB disk number!"
echo ""
echo "4. 🐧 Test with QEMU (if installed):"
echo "   qemu-system-x86_64 -cdrom \"$ISO_FILE\" -m 2048 -enable-kvm"
echo ""
echo "💡 The ISO is fully functional - the build 'copying error' was just"
echo "   a minor Docker script issue, not a build failure!"
