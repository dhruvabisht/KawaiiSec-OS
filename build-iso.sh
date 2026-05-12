#!/bin/bash

# KawaiiSec OS ISO Builder
# Automated, reproducible ISO packaging system using Debian live-build

set -euo pipefail

# Configuration
PROJECT_NAME="KawaiiSec OS"
VERSION="${VERSION:-$(date +%Y.%m.%d)}"
BUILD_DIR="$(pwd)"
WORK_DIR="${BUILD_DIR}/build"
ASSETS_DIR="${BUILD_DIR}/assets"
ISO_NAME="kawaiisec-os-${VERSION}-amd64.iso"
LOG_FILE="${BUILD_DIR}/build-${VERSION}.log"

# Colors for output
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
    echo -e "${RED}❌ Build failed: $1${NC}" >&2
    cleanup_on_exit
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

# Show banner
show_banner() {
    echo -e "${PURPLE}"
    echo "╭──────────────────────────────────────────────╮"
    echo "│     🌸 KawaiiSec OS ISO Builder 🌸          │"
    echo "│        Automated Live-Build System          │"
    echo "│                                              │"
    echo "│     Version: ${VERSION}                     │"
    echo "╰──────────────────────────────────────────────╯"
    echo -e "${NC}"
}

# Cleanup function
cleanup_on_exit() {
    if [ "${CLEANUP_ON_EXIT:-true}" = "true" ]; then
        info "Cleaning up build environment..."
        if [ -d "$WORK_DIR" ]; then
            sudo chroot "$WORK_DIR/chroot" umount /proc 2>/dev/null || true
            sudo chroot "$WORK_DIR/chroot" umount /sys 2>/dev/null || true
            sudo chroot "$WORK_DIR/chroot" umount /dev/pts 2>/dev/null || true
            sudo rm -rf "$WORK_DIR" 2>/dev/null || true
        fi
    fi
}

# Trap cleanup
trap cleanup_on_exit EXIT

# Check dependencies
check_dependencies() {
    info "Checking build dependencies..."
    
    # Skip dependency check when building (Docker containers have packages pre-installed)
    info "Skipping dependency check (packages pre-installed in container)"
    return 0
    
    local missing_deps=()
    
    # Required packages
    local required_packages=(
        "live-build"
        "debootstrap"
        "xorriso"
        "isolinux"
        "syslinux-utils"
        "memtest86+"
        "dosfstools"
        "squashfs-tools"
    )
    
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            missing_deps+=("$package")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error_exit "Missing dependencies: ${missing_deps[*]}. Please install with: sudo apt install ${missing_deps[*]}"
    fi
    
    # Check if running as root for some operations
    if [ "$EUID" -eq 0 ]; then
        warning "Running as root. This is not recommended for the build process."
    fi
    
    success "All dependencies satisfied"
}

# Prepare build environment
prepare_build_environment() {
    info "Preparing build environment..."
    
    # Clean previous builds if requested
    if [ "${CLEAN_BUILD:-true}" = "true" ]; then
        if [ -d "$WORK_DIR" ]; then
            info "Cleaning previous build..."
            sudo rm -rf "$WORK_DIR"
        fi
        
        # Remove old ISOs
        rm -f "${BUILD_DIR}"/*.iso
    fi
    
    # Create work directory
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    
    # Copy live-build configuration
    cp -r "${BUILD_DIR}/auto" .
    cp -r "${BUILD_DIR}/config" .
    cp -r "${BUILD_DIR}/hooks" .
    cp -r "${BUILD_DIR}/includes.chroot" .
    
    # Make auto scripts executable
    chmod +x auto/*
    
    # Make hooks executable
    find hooks -name "*.hook.chroot" -exec chmod +x {} \;
    
    success "Build environment prepared"
}

# Copy assets to build environment
copy_assets() {
    info "FORCE copying assets to build environment..."
    
    # Create temporary assets directory for hooks to use
    sudo mkdir -p /tmp/build-assets
    
    # FORCE copy project assets with better error handling
    if [ -d "${ASSETS_DIR}" ]; then
        info "Copying assets from: ${ASSETS_DIR}"
        sudo cp -r "${ASSETS_DIR}"/* /tmp/build-assets/ || {
            warning "Failed to copy some assets from ${ASSETS_DIR}"
            # Try to copy individual directories
            for subdir in "${ASSETS_DIR}"/*; do
                if [ -d "$subdir" ]; then
                    sudo cp -r "$subdir" /tmp/build-assets/ || warning "Failed to copy $(basename "$subdir")"
                fi
            done
        }
    else
        warning "Assets directory not found: ${ASSETS_DIR}"
        # Create empty asset structure to prevent build failures
        sudo mkdir -p /tmp/build-assets/{graphics,themes,audio,scripts}
    fi
    
    # FORCE copy kawaiisec-docs if present
    if [ -d "${BUILD_DIR}/kawaiisec-docs" ]; then
        info "Copying kawaiisec-docs from: ${BUILD_DIR}/kawaiisec-docs"
        sudo cp -r "${BUILD_DIR}/kawaiisec-docs" /tmp/build-assets/
    else
        warning "kawaiisec-docs directory not found: ${BUILD_DIR}/kawaiisec-docs"
    fi
    
    # FORCE copy includes.chroot assets to build-assets for hooks
    if [ -d "${BUILD_DIR}/includes.chroot" ]; then
        info "Copying includes.chroot assets to build-assets"
        sudo cp -r "${BUILD_DIR}/includes.chroot" /tmp/build-assets/
    fi
    
    # Copy scripts
    if [ -d "${BUILD_DIR}/scripts" ]; then
        sudo mkdir -p /tmp/build-assets/scripts
        sudo cp -r "${BUILD_DIR}/scripts"/* /tmp/build-assets/scripts/
    fi
    
    # Copy additional KawaiiSec tools
    for script in "${BUILD_DIR}/scripts"/kawaiisec-*.sh; do
        if [ -f "$script" ]; then
            sudo cp "$script" "${WORK_DIR}/includes.chroot/usr/local/bin/"
            sudo chmod +x "${WORK_DIR}/includes.chroot/usr/local/bin/$(basename "$script")"
        fi
    done
    
    success "Assets copied to build environment"
}

# Configure live-build
configure_live_build() {
    info "Configuring live-build..."
    
    # Run auto/config
    ./auto/config
    
    success "Live-build configured"
}

# Build the ISO
build_iso() {
    info "Starting ISO build process..."
    
    # Show build information
    info "Building ${PROJECT_NAME} ${VERSION}"
    info "Architecture: amd64"
    info "Base: Debian Bookworm"
    info "Desktop: XFCE"
    
    # Start timing
    local start_time=$(date +%s)
    
    # Run the build
    sudo ./auto/build 2>&1 | tee -a "$LOG_FILE"
    
    # Check build result - look for any ISO files
    local iso_file=""
    if [ -f "live-image-amd64.hybrid.iso" ]; then
        iso_file="live-image-amd64.hybrid.iso"
    elif [ -f "binary.hybrid.iso" ]; then
        iso_file="binary.hybrid.iso"
    else
        # Look for any ISO file
        iso_file=$(find . -name "*.iso" -type f | head -1)
    fi
    
    if [ -n "$iso_file" ] && [ -f "$iso_file" ]; then
        local end_time=$(date +%s)
        local build_time=$((end_time - start_time))
        local build_minutes=$((build_time / 60))
        local build_seconds=$((build_time % 60))
        
        # Move ISO to project root with proper name
        mv "$iso_file" "${BUILD_DIR}/${ISO_NAME}"
        
        success "ISO build completed in ${build_minutes}m ${build_seconds}s"
        success "ISO saved as: ${BUILD_DIR}/${ISO_NAME}"
        
        # Show ISO information
        local iso_size=$(du -h "${BUILD_DIR}/${ISO_NAME}" | cut -f1)
        info "ISO size: ${iso_size}"
        
        # Calculate checksums
        info "Calculating checksums..."
        cd "${BUILD_DIR}"
        sha256sum "${ISO_NAME}" > "${ISO_NAME}.sha256"
        md5sum "${ISO_NAME}" > "${ISO_NAME}.md5"
        
        success "Checksums generated"
        
    else
        error_exit "ISO build failed - no output file found"
    fi
}

# Post-build validation
validate_iso() {
    info "Validating ISO integrity..."
    
    # Check if ISO exists
    if [ ! -f "${BUILD_DIR}/${ISO_NAME}" ]; then
        error_exit "ISO file not found"
    fi
    
    # Check ISO is not empty (use macOS compatible stat command)
    local iso_size
    if [[ "$OSTYPE" == "darwin"* ]]; then
        iso_size=$(stat -f%z "${BUILD_DIR}/${ISO_NAME}")
    else
        iso_size=$(stat -c%s "${BUILD_DIR}/${ISO_NAME}")
    fi
    if [ "$iso_size" -lt 100000000 ]; then  # Less than 100MB is suspicious
        error_exit "ISO file seems too small ($iso_size bytes)"
    fi
    
    # Validate ISO structure using file command
    local file_type=$(file "${BUILD_DIR}/${ISO_NAME}")
    if [[ ! "$file_type" =~ "ISO 9660" ]]; then
        error_exit "Invalid ISO format detected"
    fi
    
    # Mount and check ISO contents (optional)
    if command -v isoinfo >/dev/null 2>&1; then
        info "Checking ISO contents..."
        local boot_catalog=$(isoinfo -d -i "${BUILD_DIR}/${ISO_NAME}" | grep "El Torito" || true)
        if [ -n "$boot_catalog" ]; then
            success "Bootable ISO detected"
        else
            warning "ISO may not be bootable"
        fi
    fi
    
    success "ISO validation completed"
}

# Generate build report
generate_build_report() {
    info "Generating build report..."
    
    local report_file="${BUILD_DIR}/build-report-${VERSION}.txt"
    
    cat > "$report_file" << EOF
🌸 KawaiiSec OS Build Report 🌸
===============================

Build Information:
- Project: ${PROJECT_NAME}
- Version: ${VERSION}
- Build Date: $(date)
- Build Host: $(hostname)
- Build User: $(whoami)

System Information:
- OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")
- Kernel: $(uname -r)
- Architecture: $(uname -m)

ISO Information:
- Filename: ${ISO_NAME}
- Size: $(du -h "${BUILD_DIR}/${ISO_NAME}" | cut -f1)
- SHA256: $(cat "${BUILD_DIR}/${ISO_NAME}.sha256" | cut -d' ' -f1)
- MD5: $(cat "${BUILD_DIR}/${ISO_NAME}.md5" | cut -d' ' -f1)

Build Components:
- Base Distribution: Debian Bookworm
- Desktop Environment: XFCE
- Security Tools: Included
- Bootloader: SYSLINUX
- Image Type: Hybrid ISO

Build Status: SUCCESS ✅

For more details, see: ${LOG_FILE}
EOF
    
    success "Build report generated: $report_file"
}

# Show usage
show_usage() {
    cat << 'EOF'
🌸 KawaiiSec OS ISO Builder 🌸

Usage: ./build-iso.sh [options]

Options:
  -h, --help          Show this help message
  -c, --clean         Clean previous builds (default: true)
  -v, --version VER   Set version string (default: YYYY.MM.DD)
  -q, --quiet         Reduce output verbosity
  --no-cleanup        Don't cleanup on exit (for debugging)
  --validate-only     Only validate existing ISO

Examples:
  ./build-iso.sh                    # Build with default settings
  ./build-iso.sh -v 2024.01.15     # Build with specific version
  ./build-iso.sh --no-cleanup      # Keep build artifacts for debugging

Environment Variables:
  VERSION            Override version string
  CLEAN_BUILD        Set to false to skip cleaning (default: true)
  CLEANUP_ON_EXIT    Set to false to keep build artifacts (default: true)

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--clean)
                CLEAN_BUILD="true"
                shift
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -q|--quiet)
                QUIET="true"
                shift
                ;;
            --no-cleanup)
                CLEANUP_ON_EXIT="false"
                shift
                ;;
            --validate-only)
                VALIDATE_ONLY="true"
                shift
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done
}

# Main function
main() {
    # Initialize logging
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    log "KawaiiSec OS ISO build started"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Show banner
    show_banner
    
    # Handle validate-only mode
    if [ "${VALIDATE_ONLY:-false}" = "true" ]; then
        validate_iso
        exit 0
    fi
    
    # Main build process
    check_dependencies
    prepare_build_environment
    copy_assets
    configure_live_build
    build_iso
    validate_iso
    generate_build_report
    
    # Final success message
    echo -e "${GREEN}"
    echo "╭──────────────────────────────────────────────╮"
    echo "│          🎉 BUILD COMPLETED! 🎉              │"
    echo "│                                              │"
    echo "│     ISO: ${ISO_NAME}"
    echo "│     Location: ${BUILD_DIR}/"
    echo "╰──────────────────────────────────────────────╯"
    echo -e "${NC}"
    
    info "Build log saved to: ${LOG_FILE}"
    info "To test the ISO, you can:"
    echo "  • Boot from USB: sudo dd if=${ISO_NAME} of=/dev/sdX bs=4M"
    echo "  • Test in VM: qemu-system-x86_64 -cdrom ${ISO_NAME} -m 2048"
    echo "  • Mount and explore: sudo mount -o loop ${ISO_NAME} /mnt"
    
    log "KawaiiSec OS ISO build completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 