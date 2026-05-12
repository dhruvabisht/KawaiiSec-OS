#!/bin/bash

# KawaiiSec OS Asset Validation Script
# Validates that all branding assets are properly configured

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Test function
test_asset() {
    local description="$1"
    local test_command="$2"
    
    echo -n "Testing: $description... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
        return 1
    fi
}

# Warning function
warn_asset() {
    local description="$1"
    local message="$2"
    
    echo -e "${YELLOW}⚠️  WARNING: $description - $message${NC}"
    ((WARNINGS++))
}

echo -e "${PURPLE}"
echo "╭──────────────────────────────────────────────╮"
echo "│     🌸 KawaiiSec OS Asset Validator 🌸      │"
echo "│      Checking branding asset deployment      │"
echo "╰──────────────────────────────────────────────╯"
echo -e "${NC}"

echo -e "${BLUE}📋 Validating wallpapers...${NC}"
test_asset "Wallpaper source directory exists" "[ -d 'kawaiisec-docs/res/Wallpapers' ]"
test_asset "Includes.chroot wallpapers exist" "[ -d 'includes.chroot/usr/share/backgrounds/kawaiisec' ]"
test_asset "Kawaii Cafe wallpaper exists" "[ -f 'kawaiisec-docs/res/Wallpapers/kawaii_cafe.png' ]"
test_asset "Dreamy Clouds wallpaper exists" "[ -f 'kawaiisec-docs/res/Wallpapers/dreamy_clouds.png' ]"
test_asset "Classic Pastel wallpaper exists" "[ -f 'kawaiisec-docs/res/Wallpapers/classic_pastel_workspace.png' ]"
test_asset "Retro Terminal wallpaper exists" "[ -f 'kawaiisec-docs/res/Wallpapers/retro_terminal.png' ]"

echo -e "${BLUE}📋 Validating icon theme...${NC}"
test_asset "Icon theme directory exists" "[ -d 'includes.chroot/usr/share/icons/kawaiisec' ]"
test_asset "Icon theme index exists" "[ -f 'includes.chroot/usr/share/icons/kawaiisec/index.theme' ]"
test_asset "Main Kawaii icon exists" "[ -f 'includes.chroot/usr/share/icons/kawaiisec/Kawaii.png' ]"
test_asset "Browser icon exists" "[ -f 'includes.chroot/usr/share/icons/kawaiisec/browser.png' ]"
test_asset "Terminal icon exists" "[ -f 'includes.chroot/usr/share/icons/kawaiisec/terminal.png' ]"
test_asset "File manager icon exists" "[ -f 'includes.chroot/usr/share/icons/kawaiisec/file_manager.png' ]"

# Check icon sizes
for size in 32x32 48x48; do
    test_asset "Icon size directory $size exists" "[ -d 'includes.chroot/usr/share/icons/kawaiisec/$size/apps' ]"
    test_asset "$size Kawaii icon exists" "[ -f 'includes.chroot/usr/share/icons/kawaiisec/$size/apps/Kawaii.png' ]"
done

echo -e "${BLUE}📋 Validating Plymouth theme...${NC}"
test_asset "Plymouth theme directory exists" "[ -d 'assets/themes/boot/kawaiisec' ]"
test_asset "Plymouth configuration exists" "[ -f 'assets/themes/boot/kawaiisec/kawaiisec.plymouth' ]"
test_asset "Plymouth script exists" "[ -f 'assets/themes/boot/kawaiisec/kawaiisec.script' ]"
test_asset "Plymouth installer exists" "[ -f 'assets/themes/boot/kawaiisec/install.sh' ]"

echo -e "${BLUE}📋 Validating build hooks...${NC}"
test_asset "Main branding hook exists" "[ -f 'hooks/normal/0010-kawaiisec-branding.hook.chroot' ]"
test_asset "Plymouth hook exists" "[ -f 'hooks/normal/0025-kawaiisec-plymouth.hook.chroot' ]"
test_asset "Branding hook is executable" "[ -x 'hooks/normal/0010-kawaiisec-branding.hook.chroot' ]"
test_asset "Plymouth hook is executable" "[ -x 'hooks/normal/0025-kawaiisec-plymouth.hook.chroot' ]"

echo -e "${BLUE}📋 Validating desktop setup scripts...${NC}"
test_asset "Desktop setup script exists" "[ -f 'includes.chroot/usr/local/bin/kawaiisec-desktop-setup.sh' ]"
test_asset "First boot script exists" "[ -f 'includes.chroot/usr/local/bin/kawaiisec-firstboot.sh' ]"
test_asset "Desktop setup script is executable" "[ -x 'includes.chroot/usr/local/bin/kawaiisec-desktop-setup.sh' ]"
test_asset "First boot script is executable" "[ -x 'includes.chroot/usr/local/bin/kawaiisec-firstboot.sh' ]"

echo -e "${BLUE}📋 Validating configuration files...${NC}"

# Check if hooks contain proper asset copying logic
if grep -q "FORCE" hooks/normal/0010-kawaiisec-branding.hook.chroot; then
    echo -e "${GREEN}✅ Branding hook contains FORCE deployment logic${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Branding hook missing FORCE deployment logic${NC}"
    ((FAILED++))
fi

if grep -q "KawaiiSec" includes.chroot/usr/local/bin/kawaiisec-desktop-setup.sh; then
    echo -e "${GREEN}✅ Desktop setup script contains KawaiiSec configuration${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Desktop setup script missing KawaiiSec configuration${NC}"
    ((FAILED++))
fi

# Check Plymouth script for kawaii elements
if grep -q "kawaii\|🌸\|💖" assets/themes/boot/kawaiisec/kawaiisec.script; then
    echo -e "${GREEN}✅ Plymouth script contains kawaii elements${NC}"
    ((PASSED++))
else
    warn_asset "Plymouth script" "Missing kawaii elements"
fi

echo ""
echo -e "${PURPLE}📊 Validation Summary:${NC}"
echo -e "${GREEN}✅ Passed: $PASSED${NC}"
echo -e "${RED}❌ Failed: $FAILED${NC}"
echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All critical assets validated successfully!${NC}"
    echo -e "${BLUE}💡 Your KawaiiSec OS should now have proper branding.${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some assets are missing or misconfigured.${NC}"
    echo -e "${YELLOW}💡 Please check the failed items above.${NC}"
    exit 1
fi
