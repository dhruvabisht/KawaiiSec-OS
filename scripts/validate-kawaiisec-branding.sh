#!/bin/bash

# KawaiiSec OS Branding Validation Script
# Validates that all branding elements are properly configured

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}"
echo "╭─────────────────────────────────────────╮"
echo "│   🌸 KawaiiSec OS Branding Validator 🌸│"
echo "│     Checking all branding elements     │"
echo "╰─────────────────────────────────────────╯"
echo -e "${NC}"

success_count=0
total_checks=0

check() {
    local description="$1"
    local condition="$2"
    total_checks=$((total_checks + 1))
    
    echo -n "🔍 Checking: $description... "
    
    if eval "$condition"; then
        echo -e "${GREEN}✅ PASS${NC}"
        success_count=$((success_count + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

echo -e "${BLUE}📋 Validating KawaiiSec OS Branding Configuration...${NC}"
echo

# Check hook files exist and are executable
check "Hook files exist" "[ -f hooks/normal/0001-kawaiisec-wallpapers.hook.chroot ]"
check "Hook files are executable" "[ -x hooks/normal/0001-kawaiisec-wallpapers.hook.chroot ]"
check "User branding hook exists" "[ -f hooks/normal/0002-kawaiisec-user-branding.hook.chroot ]"
check "Branding hook exists" "[ -f hooks/normal/0010-kawaiisec-branding.hook.chroot ]"
check "Syslinux hook exists" "[ -f hooks/normal/0015-kawaiisec-syslinux.hook.chroot ]"
check "Plymouth hook exists" "[ -f hooks/normal/0025-kawaiisec-plymouth.hook.chroot ]"

# Check wallpaper files exist
check "Wallpapers exist in includes.chroot" "[ -f includes.chroot/usr/share/backgrounds/kawaiisec/kawaii_cafe.png ]"
check "All 4 wallpapers present" "[ $(ls includes.chroot/usr/share/backgrounds/kawaiisec/*.png | wc -l) -eq 4 ]"

# Check syslinux configuration
check "Syslinux config exists" "[ -f config/bootloaders/syslinux/syslinux.cfg ]"
check "Syslinux shows KawaiiSec branding" "grep -q 'KawaiiSec OS Live' config/bootloaders/syslinux/syslinux.cfg"
check "Syslinux splash image exists" "[ -f config/bootloaders/syslinux/splash.png ]"

# Check auto/config settings
check "Auto config exists" "[ -f auto/config ]"
check "Hostname set to kawaiisec" "grep -q 'hostname=kawaiisec' auto/config"
check "Username set to kawaiisec" "grep -q 'username=kawaiisec' auto/config"

# Check Plymouth theme
check "Plymouth theme files exist" "[ -f assets/themes/boot/kawaiisec/kawaiisec.plymouth ]"
check "Plymouth script exists" "[ -f assets/themes/boot/kawaiisec/kawaiisec.script ]"

# Check desktop setup script
check "Desktop setup script exists" "[ -f includes.chroot/usr/local/bin/kawaiisec-desktop-setup.sh ]"
check "Desktop setup is executable" "[ -x includes.chroot/usr/local/bin/kawaiisec-desktop-setup.sh ]"

# Check firstboot script
check "Firstboot script exists" "[ -f includes.chroot/usr/local/bin/kawaiisec-firstboot.sh ]"
check "Firstboot service exists" "[ -f includes.chroot/etc/systemd/system/kawaiisec-firstboot.service ]"

# Check branding hook content
check "OS-release override in branding hook" "grep -q 'KawaiiSec OS' hooks/normal/0010-kawaiisec-branding.hook.chroot"
check "Wallpaper deployment in hook" "grep -q 'kawaii_cafe.png' hooks/normal/0010-kawaiisec-branding.hook.chroot"

echo
echo -e "${BLUE}📊 Validation Results:${NC}"
echo -e "✅ Passed: ${GREEN}$success_count${NC} / $total_checks checks"

if [ $success_count -eq $total_checks ]; then
    echo -e "${GREEN}🎉 ALL CHECKS PASSED! KawaiiSec OS branding is properly configured!${NC}"
    echo -e "${PURPLE}🚀 Ready to build the ISO with full KawaiiSec branding!${NC}"
    exit 0
else
    failed_count=$((total_checks - success_count))
    echo -e "${RED}❌ Failed: $failed_count checks${NC}"
    echo -e "${YELLOW}⚠️  Some branding elements need attention before building${NC}"
    exit 1
fi
