#!/bin/bash

# KawaiiSec OS Build Validation Script
# Checks for common issues that could cause build failures

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Error handling
error_exit() {
    echo -e "${RED}❌ Validation failed: $1${NC}" >&2
    exit 1
}

# Success message
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Warning message
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Info message
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo -e "${BLUE}🔍 KawaiiSec OS Build Validation${NC}"
echo "=================================="

# Check script permissions
info "Checking script permissions..."
for script in scripts/*.sh; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        warning "Script $script is not executable"
        chmod +x "$script"
        success "Fixed permissions for $script"
    fi
done

# Check hook permissions
info "Checking hook permissions..."
for hook in hooks/normal/*.hook.chroot; do
    if [ -f "$hook" ] && [ ! -x "$hook" ]; then
        warning "Hook $hook is not executable"
        chmod +x "$hook"
        success "Fixed permissions for $hook"
    fi
done

# Check required assets exist
info "Checking required assets..."
required_assets=(
    "kawaiisec-docs/res/Wallpapers/kawaii_cafe.png"
    "kawaiisec-docs/res/Wallpapers/dreamy_clouds.png"
    "kawaiisec-docs/res/Wallpapers/classic_pastel_workspace.png"
    "kawaiisec-docs/res/Wallpapers/retro_terminal.png"
    "assets/graphics/logos/Kawaii.png"
    "config/bootloaders/syslinux/splash.png"
    "config/bootloaders/syslinux/syslinux.cfg"
)

for asset in "${required_assets[@]}"; do
    if [ ! -f "$asset" ]; then
        error_exit "Required asset not found: $asset"
    else
        success "Asset found: $asset"
    fi
done

# Check package lists for problematic packages
info "Checking package lists..."
problematic_packages=(
    "terminator"
    "chromium"
)

for pkg in "${problematic_packages[@]}"; do
    if grep -q "^$pkg$" config/package-lists/*.list.chroot; then
        warning "Problematic package found: $pkg"
    fi
done

# Check for duplicate entries in package lists
info "Checking for duplicate package entries..."
for pkglist in config/package-lists/*.list.chroot; do
    if [ -f "$pkglist" ]; then
        duplicates=$(grep -v '^#' "$pkglist" | grep -v '^$' | sort | uniq -d)
        if [ -n "$duplicates" ]; then
            warning "Duplicate packages found in $pkglist:"
            echo "$duplicates"
        fi
    fi
done

# Check hook execution order
info "Checking hook execution order..."
hooks=($(ls hooks/normal/*.hook.chroot 2>/dev/null | sort))
if [ ${#hooks[@]} -gt 0 ]; then
    success "Hooks found: ${#hooks[@]}"
    for hook in "${hooks[@]}"; do
        echo "  - $(basename "$hook")"
    done
else
    warning "No hooks found in hooks/normal/"
fi

# Check Docker configuration
if command -v docker >/dev/null 2>&1; then
    info "Checking Docker configuration..."
    if docker info >/dev/null 2>&1; then
        success "Docker is running"
    else
        warning "Docker is not running"
    fi
else
    warning "Docker not found"
fi

# Check build environment
info "Checking build environment..."
if [ -f "auto/config" ] && [ -x "auto/config" ]; then
    success "Build configuration script found and executable"
else
    error_exit "Build configuration script missing or not executable"
fi

if [ -f "auto/build" ] && [ -x "auto/build" ]; then
    success "Build script found and executable"
else
    error_exit "Build script missing or not executable"
fi

# Check output directory
info "Checking output directory..."
if [ -d "output" ]; then
    success "Output directory exists"
    chmod 755 output
else
    warning "Output directory missing, will be created during build"
fi

echo ""
echo -e "${GREEN}🎉 Build validation completed successfully!${NC}"
echo -e "${BLUE}💡 You can now run: ./docker-build.sh${NC}" 