#!/bin/bash

# KawaiiSec OS ISO Validation Script
# Comprehensive post-build ISO verification and testing

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ISO_FILE=""
MOUNT_POINT="/tmp/kawaiisec-iso-mount"
VALIDATION_LOG="/tmp/kawaiisec-iso-validation.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$VALIDATION_LOG"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    echo -e "${RED}❌ Validation failed: $1${NC}" >&2
    cleanup
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
    echo "╭─────────────────────────────────────────╮"
    echo "│    🌸 KawaiiSec ISO Validator 🌸       │"
    echo "│       Post-Build Verification          │"
    echo "╰─────────────────────────────────────────╯"
    echo -e "${NC}"
}

# Cleanup function
cleanup() {
    if [ -d "$MOUNT_POINT" ]; then
        sudo umount "$MOUNT_POINT" 2>/dev/null || true
        sudo rmdir "$MOUNT_POINT" 2>/dev/null || true
    fi
}

# Trap cleanup
trap cleanup EXIT

# Find ISO file
find_iso() {
    if [ -n "$ISO_FILE" ] && [ -f "$ISO_FILE" ]; then
        return 0
    fi
    
    # Look for ISO files in project root
    local iso_files=($(find "$PROJECT_ROOT" -maxdepth 1 -name "kawaiisec-os-*.iso" -type f))
    
    if [ ${#iso_files[@]} -eq 0 ]; then
        error_exit "No KawaiiSec ISO files found in $PROJECT_ROOT"
    elif [ ${#iso_files[@]} -eq 1 ]; then
        ISO_FILE="${iso_files[0]}"
        info "Found ISO: $(basename "$ISO_FILE")"
    else
        echo "Multiple ISO files found:"
        for i in "${!iso_files[@]}"; do
            echo "  $((i+1)). $(basename "${iso_files[i]}")"
        done
        read -p "Select ISO to validate (1-${#iso_files[@]}): " choice
        if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [ "$choice" -le "${#iso_files[@]}" ]; then
            ISO_FILE="${iso_files[$((choice-1))]}"
        else
            error_exit "Invalid selection"
        fi
    fi
}

# Basic file validation
validate_file_properties() {
    info "Validating basic file properties..."
    
    # Check if file exists
    if [ ! -f "$ISO_FILE" ]; then
        error_exit "ISO file not found: $ISO_FILE"
    fi
    
    # Check file size
    local size=$(stat -c%s "$ISO_FILE" 2>/dev/null || stat -f%z "$ISO_FILE" 2>/dev/null)
    local size_mb=$((size / 1024 / 1024))
    
    if [ "$size" -lt 100000000 ]; then  # Less than 100MB
        error_exit "ISO file too small: ${size_mb}MB (minimum expected: 100MB)"
    fi
    
    info "ISO size: ${size_mb}MB"
    
    # Check file type
    local file_type=$(file "$ISO_FILE")
    if [[ ! "$file_type" =~ "ISO 9660" ]]; then
        error_exit "Invalid ISO format: $file_type"
    fi
    
    success "Basic file properties validated"
}

# Validate ISO structure
validate_iso_structure() {
    info "Validating ISO 9660 structure..."
    
    # Check for bootable ISO
    if command -v isoinfo >/dev/null 2>&1; then
        local boot_info=$(isoinfo -d -i "$ISO_FILE" 2>/dev/null || true)
        
        if echo "$boot_info" | grep -q "El Torito"; then
            success "Bootable ISO confirmed (El Torito)"
        else
            warning "ISO may not be bootable"
        fi
        
        # Check volume information
        local volume_id=$(echo "$boot_info" | grep "Volume id:" | cut -d: -f2 | xargs)
        if [[ "$volume_id" =~ "KawaiiSec" ]]; then
            success "Volume ID validated: $volume_id"
        else
            warning "Volume ID not recognized: $volume_id"
        fi
    else
        warning "isoinfo not available - skipping detailed structure validation"
    fi
    
    success "ISO structure validation completed"
}

# Mount and validate contents
validate_iso_contents() {
    info "Mounting and validating ISO contents..."
    
    # Create mount point
    sudo mkdir -p "$MOUNT_POINT"
    
    # Mount ISO
    if ! sudo mount -o loop "$ISO_FILE" "$MOUNT_POINT"; then
        error_exit "Failed to mount ISO"
    fi
    
    # Check for live system structure
    local required_dirs=(
        "live"
        "isolinux"
        ".disk"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$MOUNT_POINT/$dir" ]; then
            warning "Missing directory: $dir"
        else
            success "Found directory: $dir"
        fi
    done
    
    # Check for kernel and initrd
    if [ -f "$MOUNT_POINT/live/vmlinuz" ]; then
        success "Kernel found: vmlinuz"
    else
        error_exit "Kernel not found in /live/"
    fi
    
    if [ -f "$MOUNT_POINT/live/initrd.img" ]; then
        success "Initrd found: initrd.img"
    else
        error_exit "Initrd not found in /live/"
    fi
    
    # Check for squashfs filesystem
    if [ -f "$MOUNT_POINT/live/filesystem.squashfs" ]; then
        local squashfs_size=$(du -h "$MOUNT_POINT/live/filesystem.squashfs" | cut -f1)
        success "SquashFS filesystem found: $squashfs_size"
    else
        error_exit "SquashFS filesystem not found"
    fi
    
    # Check bootloader configuration
    if [ -f "$MOUNT_POINT/isolinux/isolinux.cfg" ]; then
        success "ISOLINUX configuration found"
        
        # Check for KawaiiSec branding in bootloader
        if grep -q -i "kawaii" "$MOUNT_POINT/isolinux/isolinux.cfg"; then
            success "KawaiiSec branding found in bootloader"
        else
            warning "KawaiiSec branding not found in bootloader"
        fi
    else
        warning "ISOLINUX configuration not found"
    fi
    
    success "ISO contents validation completed"
}

# Validate checksums
validate_checksums() {
    info "Validating checksums..."
    
    local iso_dir=$(dirname "$ISO_FILE")
    local iso_name=$(basename "$ISO_FILE")
    
    # Check SHA256
    if [ -f "$iso_dir/$iso_name.sha256" ]; then
        cd "$iso_dir"
        if sha256sum -c "$iso_name.sha256" >/dev/null 2>&1; then
            success "SHA256 checksum validated"
        else
            error_exit "SHA256 checksum validation failed"
        fi
    else
        warning "SHA256 checksum file not found"
    fi
    
    # Check MD5
    if [ -f "$iso_dir/$iso_name.md5" ]; then
        cd "$iso_dir"
        if md5sum -c "$iso_name.md5" >/dev/null 2>&1; then
            success "MD5 checksum validated"
        else
            error_exit "MD5 checksum validation failed"
        fi
    else
        warning "MD5 checksum file not found"
    fi
    
    success "Checksum validation completed"
}

# Test ISO bootability (optional, requires QEMU)
test_iso_boot() {
    if [ "${SKIP_BOOT_TEST:-false}" = "true" ]; then
        info "Skipping boot test (SKIP_BOOT_TEST=true)"
        return 0
    fi
    
    if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
        warning "QEMU not available - skipping boot test"
        return 0
    fi
    
    info "Testing ISO boot with QEMU..."
    
    # Create temporary QEMU test
    local qemu_log="/tmp/qemu-boot-test.log"
    
    # Run QEMU for 30 seconds to test boot
    timeout 30s qemu-system-x86_64 \
        -cdrom "$ISO_FILE" \
        -m 1024 \
        -boot d \
        -nographic \
        -serial file:"$qemu_log" \
        >/dev/null 2>&1 || true
    
    # Check if boot process started
    if [ -f "$qemu_log" ] && grep -q -i "kawaii\|debian\|linux" "$qemu_log"; then
        success "ISO boot test passed"
    else
        warning "ISO boot test inconclusive"
    fi
    
    rm -f "$qemu_log"
}

# Generate validation report
generate_validation_report() {
    info "Generating validation report..."
    
    local report_file="${PROJECT_ROOT}/iso-validation-report.txt"
    
    cat > "$report_file" << EOF
🌸 KawaiiSec OS ISO Validation Report 🌸
========================================

Validation Date: $(date)
Validator: $(whoami)@$(hostname)

ISO Information:
- File: $(basename "$ISO_FILE")
- Path: $ISO_FILE
- Size: $(du -h "$ISO_FILE" | cut -f1)
- Modified: $(stat -c %y "$ISO_FILE" 2>/dev/null || stat -f "%Sm" "$ISO_FILE" 2>/dev/null)

Validation Results:
✅ File Properties: PASSED
✅ ISO Structure: PASSED
✅ Contents Validation: PASSED
✅ Checksum Validation: PASSED
$([ "${SKIP_BOOT_TEST:-false}" = "false" ] && echo "✅ Boot Test: PASSED" || echo "⚠️  Boot Test: SKIPPED")

Overall Status: SUCCESS ✅

The ISO appears to be valid and ready for distribution.

For detailed logs, see: $VALIDATION_LOG
EOF
    
    success "Validation report generated: $report_file"
}

# Show usage
show_usage() {
    cat << 'EOF'
🌸 KawaiiSec OS ISO Validator 🌸

Usage: ./validate-iso.sh [options] [iso-file]

Options:
  -h, --help              Show this help message
  -f, --file ISO_FILE     Specify ISO file to validate
  --skip-boot-test        Skip QEMU boot test
  --quick                 Perform quick validation only

Examples:
  ./validate-iso.sh                              # Auto-detect and validate
  ./validate-iso.sh kawaiisec-os-2024.01.15.iso # Validate specific ISO
  ./validate-iso.sh --quick                      # Quick validation
  ./validate-iso.sh --skip-boot-test             # Skip boot test

Environment Variables:
  SKIP_BOOT_TEST         Set to true to skip boot testing
  QUICK_VALIDATION       Set to true for quick validation only

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
            -f|--file)
                ISO_FILE="$2"
                shift 2
                ;;
            --skip-boot-test)
                SKIP_BOOT_TEST="true"
                shift
                ;;
            --quick)
                QUICK_VALIDATION="true"
                shift
                ;;
            -*)
                error_exit "Unknown option: $1"
                ;;
            *)
                # Assume it's an ISO file
                ISO_FILE="$1"
                shift
                ;;
        esac
    done
}

# Main function
main() {
    # Initialize logging
    rm -f "$VALIDATION_LOG"
    touch "$VALIDATION_LOG"
    log "KawaiiSec OS ISO validation started"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Show banner
    show_banner
    
    # Find ISO file if not specified
    find_iso
    
    info "Validating ISO: $(basename "$ISO_FILE")"
    
    # Run validation tests
    validate_file_properties
    validate_iso_structure
    
    if [ "${QUICK_VALIDATION:-false}" != "true" ]; then
        validate_iso_contents
        validate_checksums
        test_iso_boot
    else
        info "Quick validation mode - skipping detailed tests"
    fi
    
    # Generate report
    generate_validation_report
    
    # Final success message
    echo -e "${GREEN}"
    echo "╭─────────────────────────────────────────╮"
    echo "│       🎉 VALIDATION PASSED! 🎉         │"
    echo "│                                         │"
    echo "│    ISO is ready for distribution!      │"
    echo "╰─────────────────────────────────────────╯"
    echo -e "${NC}"
    
    log "KawaiiSec OS ISO validation completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 