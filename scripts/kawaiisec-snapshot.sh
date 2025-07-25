#!/bin/bash

# KawaiiSec Btrfs Snapshot Management Script
# Handles creation, management, and cleanup of Btrfs snapshots

set -euo pipefail

# Configuration
CONFIG_FILE="/etc/kawaiisec/snapshots.conf"
LOG_FILE="/var/log/kawaiisec-snapshots.log"
SNAPSHOT_RETENTION_DAYS=7
SNAPSHOT_BASE_DIR="/.snapshots"

# Default subvolume configurations
declare -A SUBVOLUME_CONFIGS=(
    ["root"]="/::/@::/.snapshots/root"
    ["home"]="/home::/home/@::/home/.snapshots"
)

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
    log "KawaiiSec Snapshot Management Started"
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        info "Configuration loaded from $CONFIG_FILE"
    else
        info "Using default configuration"
    fi
}

# Check if Btrfs tools are available
check_btrfs() {
    if ! command -v btrfs >/dev/null 2>&1; then
        error_exit "btrfs-progs not installed. Please install: apt install btrfs-progs"
    fi
}

# Check if path is on Btrfs filesystem
is_btrfs() {
    local path="$1"
    local fstype
    fstype=$(stat -f -c %T "$path" 2>/dev/null)
    [[ "$fstype" == "btrfs" ]]
}

# Parse subvolume configuration
parse_subvol_config() {
    local config="$1"
    local mount_point subvol_path snapshot_dir
    
    IFS='::' read -r mount_point subvol_path snapshot_dir <<< "$config"
    
    echo "$mount_point" "$subvol_path" "$snapshot_dir"
}

# Create snapshot directory if it doesn't exist
create_snapshot_dir() {
    local snapshot_dir="$1"
    
    if [[ ! -d "$snapshot_dir" ]]; then
        info "Creating snapshot directory: $snapshot_dir"
        mkdir -p "$snapshot_dir"
        chmod 755 "$snapshot_dir"
    fi
}

# Generate snapshot name with timestamp
generate_snapshot_name() {
    local subvol_name="$1"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    echo "${subvol_name}_snapshot_${timestamp}"
}

# Create a Btrfs snapshot
create_snapshot() {
    local subvol_name="$1"
    local config mount_point subvol_path snapshot_dir
    local snapshot_name snapshot_path
    
    # Get configuration for this subvolume
    config="${SUBVOLUME_CONFIGS[$subvol_name]:-}"
    if [[ -z "$config" ]]; then
        error_exit "Unknown subvolume: $subvol_name"
    fi
    
    # Parse configuration
    read -r mount_point subvol_path snapshot_dir <<< "$(parse_subvol_config "$config")"
    
    info "Creating snapshot for subvolume: $subvol_name"
    info "Mount point: $mount_point, Subvolume: $subvol_path, Snapshots: $snapshot_dir"
    
    # Check if mount point exists and is Btrfs
    if [[ ! -d "$mount_point" ]]; then
        error_exit "Mount point does not exist: $mount_point"
    fi
    
    if ! is_btrfs "$mount_point"; then
        error_exit "Path is not on Btrfs filesystem: $mount_point"
    fi
    
    # Create snapshot directory
    create_snapshot_dir "$snapshot_dir"
    
    # Generate snapshot name and path
    snapshot_name=$(generate_snapshot_name "$subvol_name")
    snapshot_path="$snapshot_dir/$snapshot_name"
    
    # Create the snapshot
    info "Creating snapshot: $snapshot_path"
    if btrfs subvolume snapshot -r "$subvol_path" "$snapshot_path"; then
        success "Snapshot created: $snapshot_path"
        
        # Set snapshot properties
        btrfs property set -ts "$snapshot_path" ro true 2>/dev/null || true
        
        # Log snapshot information
        local snapshot_size
        snapshot_size=$(btrfs filesystem usage -b "$mount_point" 2>/dev/null | grep "Used:" | head -1 | awk '{print $2}' || echo "unknown")
        log "Snapshot info: name=$snapshot_name, path=$snapshot_path, size=$snapshot_size"
        
        return 0
    else
        error_exit "Failed to create snapshot: $snapshot_path"
    fi
}

# List snapshots for a subvolume
list_snapshots() {
    local subvol_name="$1"
    local config mount_point subvol_path snapshot_dir
    
    # Get configuration for this subvolume
    config="${SUBVOLUME_CONFIGS[$subvol_name]:-}"
    if [[ -z "$config" ]]; then
        error_exit "Unknown subvolume: $subvol_name"
    fi
    
    # Parse configuration
    read -r mount_point subvol_path snapshot_dir <<< "$(parse_subvol_config "$config")"
    
    info "Listing snapshots for subvolume: $subvol_name"
    
    if [[ ! -d "$snapshot_dir" ]]; then
        warning "Snapshot directory does not exist: $snapshot_dir"
        return 0
    fi
    
    echo -e "${BLUE}Snapshots for $subvol_name:${NC}"
    echo "=========================="
    
    local snapshot_count=0
    for snapshot in "$snapshot_dir"/*; do
        if [[ -d "$snapshot" ]]; then
            local snapshot_name snapshot_date snapshot_size
            snapshot_name=$(basename "$snapshot")
            
            # Extract date from snapshot name
            if [[ "$snapshot_name" =~ ([0-9]{8}_[0-9]{6}) ]]; then
                snapshot_date=$(date -d "${BASH_REMATCH[1]:0:8} ${BASH_REMATCH[1]:9:2}:${BASH_REMATCH[1]:11:2}:${BASH_REMATCH[1]:13:2}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "unknown")
            else
                snapshot_date="unknown"
            fi
            
            # Get snapshot size
            snapshot_size=$(du -sh "$snapshot" 2>/dev/null | cut -f1 || echo "unknown")
            
            printf "  %-30s  %s  %s\n" "$snapshot_name" "$snapshot_date" "$snapshot_size"
            ((snapshot_count++))
        fi
    done
    
    if [[ $snapshot_count -eq 0 ]]; then
        echo "  No snapshots found"
    else
        echo ""
        echo "Total snapshots: $snapshot_count"
    fi
}

# Delete old snapshots
cleanup_snapshots() {
    local subvol_name="$1"
    local retention_days="${2:-$SNAPSHOT_RETENTION_DAYS}"
    local config mount_point subvol_path snapshot_dir
    
    # Get configuration for this subvolume
    config="${SUBVOLUME_CONFIGS[$subvol_name]:-}"
    if [[ -z "$config" ]]; then
        error_exit "Unknown subvolume: $subvol_name"
    fi
    
    # Parse configuration
    read -r mount_point subvol_path snapshot_dir <<< "$(parse_subvol_config "$config")"
    
    info "Cleaning up snapshots older than $retention_days days for: $subvol_name"
    
    if [[ ! -d "$snapshot_dir" ]]; then
        warning "Snapshot directory does not exist: $snapshot_dir"
        return 0
    fi
    
    local deleted_count=0
    local cutoff_date
    cutoff_date=$(date -d "$retention_days days ago" '+%Y%m%d_%H%M%S')
    
    for snapshot in "$snapshot_dir"/*; do
        if [[ -d "$snapshot" ]]; then
            local snapshot_name snapshot_date_str
            snapshot_name=$(basename "$snapshot")
            
            # Extract date from snapshot name
            if [[ "$snapshot_name" =~ ([0-9]{8}_[0-9]{6}) ]]; then
                snapshot_date_str="${BASH_REMATCH[1]}"
                
                # Compare dates
                if [[ "$snapshot_date_str" < "$cutoff_date" ]]; then
                    info "Deleting old snapshot: $snapshot_name"
                    if btrfs subvolume delete "$snapshot"; then
                        success "Deleted snapshot: $snapshot_name"
                        ((deleted_count++))
                    else
                        warning "Failed to delete snapshot: $snapshot_name"
                    fi
                fi
            else
                warning "Snapshot name format not recognized: $snapshot_name"
            fi
        fi
    done
    
    info "Cleanup completed. Deleted $deleted_count snapshots"
}

# Restore from snapshot
restore_snapshot() {
    local subvol_name="$1"
    local snapshot_name="$2"
    local config mount_point subvol_path snapshot_dir
    local snapshot_path backup_path
    
    # Get configuration for this subvolume
    config="${SUBVOLUME_CONFIGS[$subvol_name]:-}"
    if [[ -z "$config" ]]; then
        error_exit "Unknown subvolume: $subvol_name"
    fi
    
    # Parse configuration
    read -r mount_point subvol_path snapshot_dir <<< "$(parse_subvol_config "$config")"
    
    snapshot_path="$snapshot_dir/$snapshot_name"
    
    # Verify snapshot exists
    if [[ ! -d "$snapshot_path" ]]; then
        error_exit "Snapshot does not exist: $snapshot_path"
    fi
    
    warning "This will replace the current subvolume with the snapshot!"
    warning "Current subvolume: $subvol_path"
    warning "Snapshot: $snapshot_path"
    
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        info "Restore cancelled by user"
        return 0
    fi
    
    # Create backup of current subvolume
    backup_path="${subvol_path}.backup.$(date '+%Y%m%d_%H%M%S')"
    info "Creating backup of current subvolume: $backup_path"
    
    if ! btrfs subvolume snapshot "$subvol_path" "$backup_path"; then
        error_exit "Failed to create backup snapshot"
    fi
    
    # Remove current subvolume
    info "Removing current subvolume: $subvol_path"
    if ! btrfs subvolume delete "$subvol_path"; then
        error_exit "Failed to delete current subvolume"
    fi
    
    # Restore from snapshot
    info "Restoring from snapshot: $snapshot_path"
    if btrfs subvolume snapshot "$snapshot_path" "$subvol_path"; then
        # Make the restored subvolume writable
        btrfs property set -ts "$subvol_path" ro false 2>/dev/null || true
        success "Successfully restored from snapshot: $snapshot_name"
        info "Backup of original subvolume: $backup_path"
    else
        error_exit "Failed to restore from snapshot"
    fi
}

# Show disk usage of snapshots
show_usage() {
    local subvol_name="$1"
    local config mount_point subvol_path snapshot_dir
    
    # Get configuration for this subvolume
    config="${SUBVOLUME_CONFIGS[$subvol_name]:-}"
    if [[ -z "$config" ]]; then
        error_exit "Unknown subvolume: $subvol_name"
    fi
    
    # Parse configuration
    read -r mount_point subvol_path snapshot_dir <<< "$(parse_subvol_config "$config")"
    
    echo -e "${BLUE}Disk usage for $subvol_name snapshots:${NC}"
    echo "========================================"
    
    if [[ ! -d "$snapshot_dir" ]]; then
        echo "No snapshot directory found"
        return 0
    fi
    
    # Show total usage of snapshot directory
    echo "Total snapshot usage: $(du -sh "$snapshot_dir" 2>/dev/null | cut -f1)"
    echo ""
    
    # Show individual snapshot sizes
    echo "Individual snapshots:"
    for snapshot in "$snapshot_dir"/*; do
        if [[ -d "$snapshot" ]]; then
            local snapshot_name snapshot_size
            snapshot_name=$(basename "$snapshot")
            snapshot_size=$(du -sh "$snapshot" 2>/dev/null | cut -f1)
            printf "  %-30s  %s\n" "$snapshot_name" "$snapshot_size"
        fi
    done
    
    # Show filesystem usage
    echo ""
    echo "Filesystem usage:"
    btrfs filesystem usage "$mount_point" 2>/dev/null || df -h "$mount_point"
}

# Show script usage
show_help() {
    cat << EOF
KawaiiSec Btrfs Snapshot Management Script

Usage: $0 COMMAND [OPTIONS]

Commands:
  create SUBVOL      Create a snapshot of the specified subvolume
  list SUBVOL        List snapshots for the specified subvolume
  cleanup SUBVOL     Clean up old snapshots (older than retention period)
  restore SUBVOL SNAPSHOT  Restore subvolume from snapshot
  usage SUBVOL       Show disk usage of snapshots
  help               Show this help message

Subvolumes:
  root               Root filesystem (/)
  home               Home directory (/home)

Options:
  --retention DAYS   Set retention period for cleanup (default: $SNAPSHOT_RETENTION_DAYS)
  --config FILE      Use custom configuration file
  --verbose         Enable verbose output

Examples:
  $0 create root                    # Create snapshot of root subvolume
  $0 list home                      # List home snapshots
  $0 cleanup root --retention 14    # Clean up root snapshots older than 14 days
  $0 restore home home_snapshot_20231201_120000  # Restore home from snapshot

Configuration:
  Configuration file: $CONFIG_FILE
  Log file: $LOG_FILE

EOF
}

# Parse command line arguments
VERBOSE=false
RETENTION_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --retention)
            RETENTION_OVERRIDE="$2"
            shift 2
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help|help)
            show_help
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

# Main execution
main() {
    local command="${1:-help}"
    local subvol_name="${2:-}"
    local extra_arg="${3:-}"
    
    # Initialize
    init_logging
    load_config
    check_btrfs
    
    # Override retention if specified
    if [[ -n "$RETENTION_OVERRIDE" ]]; then
        SNAPSHOT_RETENTION_DAYS="$RETENTION_OVERRIDE"
    fi
    
    case "$command" in
        create)
            if [[ -z "$subvol_name" ]]; then
                error_exit "Subvolume name required for create command"
            fi
            create_snapshot "$subvol_name"
            ;;
        list)
            if [[ -z "$subvol_name" ]]; then
                error_exit "Subvolume name required for list command"
            fi
            list_snapshots "$subvol_name"
            ;;
        cleanup)
            if [[ -z "$subvol_name" ]]; then
                error_exit "Subvolume name required for cleanup command"
            fi
            cleanup_snapshots "$subvol_name"
            ;;
        restore)
            if [[ -z "$subvol_name" ]] || [[ -z "$extra_arg" ]]; then
                error_exit "Subvolume name and snapshot name required for restore command"
            fi
            restore_snapshot "$subvol_name" "$extra_arg"
            ;;
        usage)
            if [[ -z "$subvol_name" ]]; then
                error_exit "Subvolume name required for usage command"
            fi
            show_usage "$subvol_name"
            ;;
        help)
            show_help
            ;;
        *)
            error_exit "Unknown command: $command. Use 'help' for usage information."
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 