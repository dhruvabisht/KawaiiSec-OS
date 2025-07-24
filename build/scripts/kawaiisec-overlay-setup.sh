#!/bin/bash

# KawaiiSec OS OverlayFS Setup Script
# Sets up overlay filesystem for immutable root with writable layer

set -euo pipefail

# Configuration
OVERLAY_BASE="/mnt/overlay"
LOWER_DIR="$OVERLAY_BASE/lower"
UPPER_DIR="$OVERLAY_BASE/upper"
WORK_DIR="$OVERLAY_BASE/work"
MERGED_DIR="/"
CONFIG_FILE="/etc/kawaiisec/overlay.conf"
LOG_FILE="/var/log/kawaiisec-overlay.log"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    echo -e "${RED}❌ $1${NC}" >&2
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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
}

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
    log "KawaiiSec OverlayFS Setup Started"
}

# Create overlay directories
create_overlay_dirs() {
    info "Creating overlay directories..."
    
    # Create base overlay directory
    mkdir -p "$OVERLAY_BASE"
    
    # Create overlay component directories
    mkdir -p "$LOWER_DIR"
    mkdir -p "$UPPER_DIR"
    mkdir -p "$WORK_DIR"
    
    # Set proper ownership and permissions
    chown root:root "$OVERLAY_BASE" "$LOWER_DIR" "$UPPER_DIR" "$WORK_DIR"
    chmod 755 "$OVERLAY_BASE"
    chmod 755 "$LOWER_DIR"
    chmod 755 "$UPPER_DIR"
    chmod 755 "$WORK_DIR"
    
    success "Overlay directories created"
}

# Create base system image
create_base_image() {
    info "Creating read-only base system image..."
    
    # Check if base image already exists
    if [[ -f "$LOWER_DIR/base-system.img" ]]; then
        warning "Base system image already exists, skipping creation"
        return 0
    fi
    
    # Create a compressed read-only image of the current root
    local temp_dir="/tmp/kawaiisec-base-$$"
    mkdir -p "$temp_dir"
    
    # Copy essential system files (excluding dynamic content)
    info "Copying system files to base image..."
    rsync -aAXH \
        --exclude='/dev/*' \
        --exclude='/proc/*' \
        --exclude='/sys/*' \
        --exclude='/tmp/*' \
        --exclude='/run/*' \
        --exclude='/mnt/*' \
        --exclude='/media/*' \
        --exclude='/var/tmp/*' \
        --exclude='/var/cache/*' \
        --exclude='/var/log/*' \
        --exclude='/home/*' \
        --exclude='/opt/kawaiisec/labs/*' \
        --exclude="$OVERLAY_BASE" \
        / "$temp_dir/"
    
    # Create compressed squashfs image
    info "Creating compressed base image..."
    mksquashfs "$temp_dir" "$LOWER_DIR/base-system.img" \
        -comp xz -b 1M -Xbcj x86 -e boot
    
    # Clean up temporary directory
    rm -rf "$temp_dir"
    
    # Set proper permissions on base image
    chmod 644 "$LOWER_DIR/base-system.img"
    
    success "Base system image created: $LOWER_DIR/base-system.img"
}

# Mount base image
mount_base_image() {
    info "Mounting base system image..."
    
    # Create mount point for base image
    local base_mount="$LOWER_DIR/mounted"
    mkdir -p "$base_mount"
    
    # Mount the squashfs image
    if ! mount -t squashfs -o loop,ro "$LOWER_DIR/base-system.img" "$base_mount"; then
        error_exit "Failed to mount base system image"
    fi
    
    success "Base system image mounted at $base_mount"
}

# Create overlay mount script
create_mount_script() {
    info "Creating overlay mount script..."
    
    local script_path="/usr/local/bin/kawaiisec-mount-overlay.sh"
    
    cat > "$script_path" << 'EOF'
#!/bin/bash

# KawaiiSec OverlayFS Mount Script
# Mounts the overlay filesystem during boot

set -euo pipefail

OVERLAY_BASE="/mnt/overlay"
LOWER_DIR="$OVERLAY_BASE/lower/mounted"
UPPER_DIR="$OVERLAY_BASE/upper"
WORK_DIR="$OVERLAY_BASE/work"

# Function to mount overlay
mount_overlay() {
    # Check if already mounted
    if mountpoint -q /; then
        echo "Root already mounted as overlay"
        return 0
    fi
    
    # Mount the overlay
    mount -t overlay kawaiisec-overlay \
        -o lowerdir="$LOWER_DIR",upperdir="$UPPER_DIR",workdir="$WORK_DIR" \
        /
    
    echo "OverlayFS mounted successfully"
}

# Function to unmount overlay
unmount_overlay() {
    if mountpoint -q /; then
        umount /
        echo "OverlayFS unmounted"
    fi
}

# Function to reset overlay (remove all changes)
reset_overlay() {
    echo "WARNING: This will remove all changes made to the system!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        rm -rf "$UPPER_DIR"/*
        rm -rf "$WORK_DIR"/*
        echo "Overlay reset completed"
    else
        echo "Reset cancelled"
    fi
}

# Function to show overlay status
show_status() {
    echo "KawaiiSec OverlayFS Status:"
    echo "=========================="
    echo "Base image: $OVERLAY_BASE/lower/base-system.img"
    echo "Lower dir:  $LOWER_DIR"
    echo "Upper dir:  $UPPER_DIR"
    echo "Work dir:   $WORK_DIR"
    echo ""
    
    if mountpoint -q /; then
        echo "Status: OverlayFS is ACTIVE"
        echo "Upper dir usage: $(du -sh "$UPPER_DIR" 2>/dev/null | cut -f1)"
    else
        echo "Status: OverlayFS is INACTIVE"
    fi
}

# Main function
case "${1:-status}" in
    mount)
        mount_overlay
        ;;
    unmount)
        unmount_overlay
        ;;
    reset)
        reset_overlay
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {mount|unmount|reset|status}"
        echo ""
        echo "Commands:"
        echo "  mount   - Mount the overlay filesystem"
        echo "  unmount - Unmount the overlay filesystem"
        echo "  reset   - Reset overlay (remove all changes)"
        echo "  status  - Show overlay status"
        exit 1
        ;;
esac
EOF

    chmod +x "$script_path"
    success "Overlay mount script created at $script_path"
}

# Create systemd service for overlay
create_systemd_service() {
    info "Creating systemd service for overlay management..."
    
    local service_file="/etc/systemd/system/kawaiisec-overlay.service"
    
    cat > "$service_file" << EOF
[Unit]
Description=KawaiiSec OverlayFS Management
Documentation=man:kawaiisec-overlay-setup(8)
DefaultDependencies=false
Conflicts=shutdown.target
After=local-fs-pre.target
Before=local-fs.target shutdown.target
RequiresMountsFor=$OVERLAY_BASE

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/kawaiisec-mount-overlay.sh mount
ExecStop=/usr/local/bin/kawaiisec-mount-overlay.sh unmount
TimeoutSec=300

# Security settings
NoNewPrivileges=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictSUIDSGID=true

[Install]
WantedBy=local-fs.target
EOF

    chmod 644 "$service_file"
    success "Systemd service created at $service_file"
}

# Update fstab for overlay
update_fstab() {
    info "Updating /etc/fstab for overlay support..."
    
    # Backup current fstab
    cp /etc/fstab /etc/fstab.backup-overlay
    
    # Add overlay mount entry (commented out by default)
    if ! grep -q "kawaiisec-overlay" /etc/fstab; then
        cat >> /etc/fstab << EOF

# KawaiiSec OverlayFS Configuration
# Uncomment the following line to enable overlay filesystem on boot
# kawaiisec-overlay / overlay defaults,lowerdir=$LOWER_DIR/mounted,upperdir=$UPPER_DIR,workdir=$WORK_DIR 0 0

# Overlay component directories
$OVERLAY_BASE/lower $LOWER_DIR none bind,ro 0 0
$OVERLAY_BASE/upper $UPPER_DIR none bind 0 0
$OVERLAY_BASE/work $WORK_DIR none bind 0 0
EOF
        success "fstab updated with overlay configuration"
    else
        warning "Overlay configuration already exists in fstab"
    fi
}

# Create configuration file
create_config() {
    info "Creating overlay configuration file..."
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    cat > "$CONFIG_FILE" << EOF
# KawaiiSec OverlayFS Configuration
# Generated on $(date)

# Overlay directories
OVERLAY_BASE="$OVERLAY_BASE"
LOWER_DIR="$LOWER_DIR"
UPPER_DIR="$UPPER_DIR"
WORK_DIR="$WORK_DIR"

# Base system image
BASE_IMAGE="$LOWER_DIR/base-system.img"

# Options
COMPRESSION="xz"
BLOCK_SIZE="1M"
AUTO_MOUNT="false"

# Maintenance
MAX_UPPER_SIZE="2G"
CLEANUP_INTERVAL="weekly"
SNAPSHOT_RETENTION="7"
EOF

    chmod 644 "$CONFIG_FILE"
    success "Configuration file created at $CONFIG_FILE"
}

# Create maintenance script
create_maintenance_script() {
    info "Creating overlay maintenance script..."
    
    local maint_script="/usr/local/bin/kawaiisec-overlay-maintenance.sh"
    
    cat > "$maint_script" << 'EOF'
#!/bin/bash

# KawaiiSec OverlayFS Maintenance Script
# Performs maintenance tasks on overlay filesystem

set -euo pipefail

# Source configuration
if [[ -f /etc/kawaiisec/overlay.conf ]]; then
    source /etc/kawaiisec/overlay.conf
fi

LOG_FILE="/var/log/kawaiisec-overlay-maintenance.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check upper directory size
check_upper_size() {
    local current_size max_size_bytes current_size_bytes
    
    max_size_bytes=$(numfmt --from=iec "${MAX_UPPER_SIZE:-2G}")
    current_size=$(du -sb "$UPPER_DIR" 2>/dev/null | cut -f1)
    current_size_bytes=${current_size:-0}
    
    if [[ $current_size_bytes -gt $max_size_bytes ]]; then
        log "WARNING: Upper directory size ($(numfmt --to=iec $current_size_bytes)) exceeds maximum (${MAX_UPPER_SIZE:-2G})"
        return 1
    fi
    
    log "Upper directory size check passed ($(numfmt --to=iec $current_size_bytes))"
    return 0
}

# Clean temporary files from upper directory
clean_temp_files() {
    log "Cleaning temporary files from upper directory..."
    
    # Remove common temporary files
    find "$UPPER_DIR" -type f -name "*.tmp" -mtime +1 -delete 2>/dev/null || true
    find "$UPPER_DIR" -type f -name ".#*" -mtime +1 -delete 2>/dev/null || true
    find "$UPPER_DIR" -type f -path "*/tmp/*" -mtime +1 -delete 2>/dev/null || true
    
    log "Temporary file cleanup completed"
}

# Update base image
update_base_image() {
    log "Updating base system image..."
    
    # This would typically be done during system updates
    # For now, just log the action
    log "Base image update scheduled for next maintenance window"
}

# Generate usage report
generate_report() {
    local report_file="/var/log/kawaiisec-overlay-report.txt"
    
    cat > "$report_file" << REPORT
KawaiiSec OverlayFS Usage Report
Generated: $(date)

Overlay Directories:
===================
Base: $OVERLAY_BASE
Lower: $LOWER_DIR
Upper: $UPPER_DIR
Work: $WORK_DIR

Disk Usage:
===========
Upper Directory: $(du -sh "$UPPER_DIR" 2>/dev/null | cut -f1)
Work Directory:  $(du -sh "$WORK_DIR" 2>/dev/null | cut -f1)
Base Image:      $(ls -lh "$LOWER_DIR/base-system.img" 2>/dev/null | awk '{print $5}')

Mount Status:
=============
$(mountpoint / && echo "OverlayFS: ACTIVE" || echo "OverlayFS: INACTIVE")

Recent Changes:
===============
$(find "$UPPER_DIR" -type f -mtime -7 2>/dev/null | head -20)

REPORT

    log "Usage report generated: $report_file"
}

# Main maintenance function
main() {
    log "Starting overlay maintenance..."
    
    check_upper_size || true
    clean_temp_files
    update_base_image
    generate_report
    
    log "Overlay maintenance completed"
}

# Run main function
main "$@"
EOF

    chmod +x "$maint_script"
    success "Maintenance script created at $maint_script"
}

# Create systemd timer for maintenance
create_maintenance_timer() {
    info "Creating systemd timer for overlay maintenance..."
    
    # Service file
    cat > "/etc/systemd/system/kawaiisec-overlay-maintenance.service" << EOF
[Unit]
Description=KawaiiSec OverlayFS Maintenance
Documentation=man:kawaiisec-overlay-setup(8)

[Service]
Type=oneshot
ExecStart=/usr/local/bin/kawaiisec-overlay-maintenance.sh
User=root
StandardOutput=journal
StandardError=journal
EOF

    # Timer file
    cat > "/etc/systemd/system/kawaiisec-overlay-maintenance.timer" << EOF
[Unit]
Description=KawaiiSec OverlayFS Maintenance Timer
Documentation=man:kawaiisec-overlay-setup(8)
Requires=kawaiisec-overlay-maintenance.service

[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
EOF

    # Set permissions
    chmod 644 /etc/systemd/system/kawaiisec-overlay-maintenance.{service,timer}
    
    # Enable timer
    systemctl daemon-reload
    systemctl enable kawaiisec-overlay-maintenance.timer
    
    success "Maintenance timer created and enabled"
}

# Show usage information
show_usage() {
    echo "KawaiiSec OverlayFS Setup Script"
    echo "Usage: $0 [OPTIONS] COMMAND"
    echo ""
    echo "Commands:"
    echo "  setup     - Complete overlay setup"
    echo "  create    - Create overlay directories only"
    echo "  mount     - Mount overlay filesystem"
    echo "  unmount   - Unmount overlay filesystem"
    echo "  status    - Show overlay status"
    echo "  help      - Show this help message"
    echo ""
    echo "Options:"
    echo "  --base-dir DIR    - Set overlay base directory (default: $OVERLAY_BASE)"
    echo "  --force          - Force operation even if already configured"
    echo "  --verbose        - Enable verbose output"
}

# Cleanup function
cleanup() {
    info "Cleaning up temporary files..."
    # Add cleanup tasks if needed
}

# Signal handlers
trap cleanup EXIT
trap 'error_exit "Setup interrupted"' INT TERM

# Parse command line arguments
FORCE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --base-dir)
            OVERLAY_BASE="$2"
            LOWER_DIR="$OVERLAY_BASE/lower"
            UPPER_DIR="$OVERLAY_BASE/upper"
            WORK_DIR="$OVERLAY_BASE/work"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help|help)
            show_usage
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

COMMAND=${1:-setup}

# Main execution
main() {
    check_root
    init_logging
    
    case "$COMMAND" in
        setup)
            info "Starting complete OverlayFS setup..."
            create_overlay_dirs
            create_base_image
            mount_base_image
            create_mount_script
            create_systemd_service
            update_fstab
            create_config
            create_maintenance_script
            create_maintenance_timer
            success "OverlayFS setup completed successfully!"
            info "To enable overlay on boot, uncomment the overlay line in /etc/fstab"
            info "Use 'kawaiisec-mount-overlay.sh status' to check overlay status"
            ;;
        create)
            create_overlay_dirs
            ;;
        mount)
            /usr/local/bin/kawaiisec-mount-overlay.sh mount 2>/dev/null || error_exit "Mount script not found. Run setup first."
            ;;
        unmount)
            /usr/local/bin/kawaiisec-mount-overlay.sh unmount 2>/dev/null || error_exit "Mount script not found. Run setup first."
            ;;
        status)
            /usr/local/bin/kawaiisec-mount-overlay.sh status 2>/dev/null || error_exit "Mount script not found. Run setup first."
            ;;
        *)
            error_exit "Unknown command: $COMMAND. Use --help for usage information."
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 