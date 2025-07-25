#!/bin/bash

# KawaiiSec System Cleanup Script
# Automated cleanup of temporary files, caches, and old data

set -euo pipefail

# Configuration
CONFIG_FILE="/etc/kawaiisec/cleanup.conf"
LOG_FILE="/var/log/kawaiisec-cleanup.log"
MAX_LOG_SIZE="100M"
LOG_RETENTION_DAYS=30
SNAPSHOT_RETENTION_DAYS=7
PACKAGE_CACHE_RETENTION_DAYS=7
TEMP_FILE_AGE_HOURS=24

# Cleanup targets
TEMP_DIRECTORIES=(
    "/tmp"
    "/var/tmp"
    "/var/cache/apt/archives"
    "/var/log"
    "/home/*/.cache"
    "/root/.cache"
)

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Statistics tracking
declare -i files_cleaned=0
declare -i space_freed=0
declare -i errors=0

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    echo -e "${RED}❌ $1${NC}" >&2
    ((errors++))
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
    # Rotate log file if it's too large
    if [[ -f "$LOG_FILE" ]] && [[ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt $(numfmt --from=iec "$MAX_LOG_SIZE") ]]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        touch "$LOG_FILE"
    fi
    
    # Create log file if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
    log "KawaiiSec System Cleanup Started"
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

# Get directory size in bytes
get_dir_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sb "$dir" 2>/dev/null | cut -f1 || echo 0
    else
        echo 0
    fi
}

# Format bytes to human readable
format_bytes() {
    local bytes="$1"
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec-i --suffix=B "$bytes"
    else
        echo "${bytes}B"
    fi
}

# Clean temporary files
clean_temp_files() {
    info "Cleaning temporary files..."
    local files_removed=0
    local space_saved=0
    
    # Clean /tmp and /var/tmp
    for temp_dir in "/tmp" "/var/tmp"; do
        if [[ -d "$temp_dir" ]]; then
            info "Cleaning $temp_dir (files older than ${TEMP_FILE_AGE_HOURS}h)"
            local initial_size
            initial_size=$(get_dir_size "$temp_dir")
            
            # Remove old files and empty directories
            find "$temp_dir" -type f -atime +0 -mtime +0 -ctime +0 -delete 2>/dev/null || true
            find "$temp_dir" -type d -empty -delete 2>/dev/null || true
            
            # Calculate space saved
            local final_size
            final_size=$(get_dir_size "$temp_dir")
            local saved=$((initial_size - final_size))
            space_saved=$((space_saved + saved))
            
            success "Cleaned $temp_dir (saved: $(format_bytes $saved))"
        fi
    done
    
    # Clean user cache directories
    for cache_pattern in "/home/*/.cache" "/root/.cache"; do
        for cache_dir in $cache_pattern; do
            if [[ -d "$cache_dir" ]]; then
                info "Cleaning user cache: $cache_dir"
                local initial_size
                initial_size=$(get_dir_size "$cache_dir")
                
                # Clean thumbnails, browser cache, etc.
                find "$cache_dir" -type f -name "*.tmp" -delete 2>/dev/null || true
                find "$cache_dir" -type f -name "*~" -delete 2>/dev/null || true
                find "$cache_dir" -path "*/thumbnails/*" -atime +7 -delete 2>/dev/null || true
                
                local final_size
                final_size=$(get_dir_size "$cache_dir")
                local saved=$((initial_size - final_size))
                space_saved=$((space_saved + saved))
            fi
        done
    done
    
    space_freed=$((space_freed + space_saved))
    success "Temporary file cleanup completed (saved: $(format_bytes $space_saved))"
}

# Clean package manager cache
clean_package_cache() {
    info "Cleaning package manager cache..."
    local space_saved=0
    
    # APT cache cleanup
    if command -v apt >/dev/null 2>&1; then
        info "Cleaning APT cache..."
        local initial_size
        initial_size=$(get_dir_size "/var/cache/apt")
        
        # Clean old packages
        apt-get autoremove -y >/dev/null 2>&1 || true
        apt-get autoclean >/dev/null 2>&1 || true
        
        # Remove old downloaded packages
        find /var/cache/apt/archives -name "*.deb" -mtime +$PACKAGE_CACHE_RETENTION_DAYS -delete 2>/dev/null || true
        
        local final_size
        final_size=$(get_dir_size "/var/cache/apt")
        local saved=$((initial_size - final_size))
        space_saved=$((space_saved + saved))
        
        success "APT cache cleaned (saved: $(format_bytes $saved))"
    fi
    
    # Snap cache cleanup
    if command -v snap >/dev/null 2>&1; then
        info "Cleaning Snap cache..."
        local snap_space=0
        
        # Remove old snap revisions (keep 2 most recent)
        snap list --all | awk '/disabled/{print $1, $3}' | while read -r snapname revision; do
            if snap remove "$snapname" --revision="$revision" 2>/dev/null; then
                snap_space=$((snap_space + 100000000))  # Approximate 100MB per snap
            fi
        done 2>/dev/null || true
        
        space_saved=$((space_saved + snap_space))
        success "Snap cache cleaned (estimated saved: $(format_bytes $snap_space))"
    fi
    
    space_freed=$((space_freed + space_saved))
    success "Package cache cleanup completed (saved: $(format_bytes $space_saved))"
}

# Clean system logs
clean_system_logs() {
    info "Cleaning system logs..."
    local space_saved=0
    local initial_size
    initial_size=$(get_dir_size "/var/log")
    
    # Rotate and compress logs
    if command -v logrotate >/dev/null 2>&1; then
        logrotate -f /etc/logrotate.conf >/dev/null 2>&1 || true
    fi
    
    # Clean old log files
    find /var/log -type f -name "*.log.*" -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null || true
    find /var/log -type f -name "*.gz" -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null || true
    find /var/log -type f -name "*.old" -mtime +$LOG_RETENTION_DAYS -delete 2>/dev/null || true
    
    # Clean systemd journal
    if command -v journalctl >/dev/null 2>&1; then
        journalctl --vacuum-time=${LOG_RETENTION_DAYS}d >/dev/null 2>&1 || true
        journalctl --vacuum-size=100M >/dev/null 2>&1 || true
    fi
    
    # Clean wtmp and btmp
    if [[ -f /var/log/wtmp ]]; then
        if [[ $(stat -c%s /var/log/wtmp) -gt 10485760 ]]; then  # 10MB
            echo > /var/log/wtmp
        fi
    fi
    
    if [[ -f /var/log/btmp ]]; then
        if [[ $(stat -c%s /var/log/btmp) -gt 1048576 ]]; then  # 1MB
            echo > /var/log/btmp
        fi
    fi
    
    local final_size
    final_size=$(get_dir_size "/var/log")
    space_saved=$((initial_size - final_size))
    space_freed=$((space_freed + space_saved))
    
    success "System log cleanup completed (saved: $(format_bytes $space_saved))"
}

# Clean old snapshots
clean_old_snapshots() {
    info "Cleaning old Btrfs snapshots..."
    
    if ! command -v btrfs >/dev/null 2>&1; then
        info "Btrfs tools not available, skipping snapshot cleanup"
        return
    fi
    
    local snapshots_cleaned=0
    
    # Clean root snapshots
    if [[ -d "/.snapshots/root" ]]; then
        info "Cleaning old root snapshots..."
        if /usr/local/bin/kawaiisec-snapshot.sh cleanup root --retention $SNAPSHOT_RETENTION_DAYS 2>/dev/null; then
            ((snapshots_cleaned++))
        fi
    fi
    
    # Clean home snapshots
    if [[ -d "/home/.snapshots" ]]; then
        info "Cleaning old home snapshots..."
        if /usr/local/bin/kawaiisec-snapshot.sh cleanup home --retention $SNAPSHOT_RETENTION_DAYS 2>/dev/null; then
            ((snapshots_cleaned++))
        fi
    fi
    
    success "Snapshot cleanup completed ($snapshots_cleaned subvolumes processed)"
}

# Clean Docker resources
clean_docker_resources() {
    info "Cleaning Docker resources..."
    
    if ! command -v docker >/dev/null 2>&1; then
        info "Docker not available, skipping Docker cleanup"
        return
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        warning "Docker daemon not running, skipping Docker cleanup"
        return
    fi
    
    local space_saved=0
    
    # Clean stopped containers
    local containers_removed
    containers_removed=$(docker container prune -f 2>/dev/null | grep "Total reclaimed space" | awk '{print $4$5}' || echo "0B")
    
    # Clean unused images
    local images_removed
    images_removed=$(docker image prune -f 2>/dev/null | grep "Total reclaimed space" | awk '{print $4$5}' || echo "0B")
    
    # Clean unused volumes
    local volumes_removed
    volumes_removed=$(docker volume prune -f 2>/dev/null | grep "Total reclaimed space" | awk '{print $4$5}' || echo "0B")
    
    # Clean build cache
    local cache_removed
    cache_removed=$(docker builder prune -f 2>/dev/null | grep "Total reclaimed space" | awk '{print $4$5}' || echo "0B")
    
    success "Docker cleanup completed"
    info "  Containers: $containers_removed"
    info "  Images: $images_removed"
    info "  Volumes: $volumes_removed"
    info "  Build cache: $cache_removed"
}

# Clean user-specific files
clean_user_files() {
    info "Cleaning user-specific temporary files..."
    local users_processed=0
    
    # Process regular users (UID >= 1000)
    while IFS=: read -r username _ uid _ _ home_dir _; do
        if [[ $uid -ge 1000 && $uid -le 60000 && -d "$home_dir" ]]; then
            info "Cleaning user files for: $username"
            
            # Clean browser caches
            for browser_cache in "$home_dir"/.cache/google-chrome "$home_dir"/.cache/chromium "$home_dir"/.cache/firefox; do
                if [[ -d "$browser_cache" ]]; then
                    find "$browser_cache" -type f -atime +7 -delete 2>/dev/null || true
                fi
            done
            
            # Clean download folders of old files
            if [[ -d "$home_dir/Downloads" ]]; then
                find "$home_dir/Downloads" -type f -atime +30 -size +100M -delete 2>/dev/null || true
            fi
            
            # Clean trash
            for trash_dir in "$home_dir"/.local/share/Trash "$home_dir"/.Trash; do
                if [[ -d "$trash_dir" ]]; then
                    find "$trash_dir" -type f -mtime +7 -delete 2>/dev/null || true
                    find "$trash_dir" -type d -empty -delete 2>/dev/null || true
                fi
            done
            
            ((users_processed++))
        fi
    done < /etc/passwd
    
    success "User file cleanup completed ($users_processed users processed)"
}

# Clean system caches
clean_system_caches() {
    info "Cleaning system caches..."
    
    # Clean font cache
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f >/dev/null 2>&1 || true
    fi
    
    # Clean man page cache
    if [[ -d /var/cache/man ]]; then
        find /var/cache/man -type f -mtime +30 -delete 2>/dev/null || true
    fi
    
    # Clean thumbnail cache
    if [[ -d /var/cache/thumbnails ]]; then
        find /var/cache/thumbnails -type f -atime +30 -delete 2>/dev/null || true
    fi
    
    # Clean shared memory
    if [[ -d /dev/shm ]]; then
        find /dev/shm -type f -user root -mtime +1 -delete 2>/dev/null || true
    fi
    
    success "System cache cleanup completed"
}

# Generate cleanup report
generate_report() {
    local report_file="/var/log/kawaiisec-cleanup-report.txt"
    
    cat > "$report_file" << REPORT
KawaiiSec System Cleanup Report
Generated: $(date)

Summary:
========
Files cleaned: $files_cleaned
Space freed: $(format_bytes $space_freed)
Errors encountered: $errors

Disk Usage After Cleanup:
========================
Root filesystem:
$(df -h / | tail -1)

Home filesystem:
$(df -h /home 2>/dev/null | tail -1 || echo "N/A")

Memory Usage:
============
$(free -h)

Recent Log Entries:
==================
$(tail -20 "$LOG_FILE" 2>/dev/null || echo "No recent log entries")

REPORT

    chmod 644 "$report_file"
    log "Cleanup report generated: $report_file"
}

# Create cleanup configuration
create_config() {
    info "Creating cleanup configuration..."
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    cat > "$CONFIG_FILE" << EOF
# KawaiiSec Cleanup Configuration
# Generated on $(date)

# Log settings
MAX_LOG_SIZE="$MAX_LOG_SIZE"
LOG_RETENTION_DAYS=$LOG_RETENTION_DAYS

# Cleanup settings
SNAPSHOT_RETENTION_DAYS=$SNAPSHOT_RETENTION_DAYS
PACKAGE_CACHE_RETENTION_DAYS=$PACKAGE_CACHE_RETENTION_DAYS
TEMP_FILE_AGE_HOURS=$TEMP_FILE_AGE_HOURS

# Directories to clean
TEMP_DIRECTORIES=(
$(printf '    "%s"\n' "${TEMP_DIRECTORIES[@]}")
)

# Features to enable/disable
CLEAN_TEMP_FILES=true
CLEAN_PACKAGE_CACHE=true
CLEAN_SYSTEM_LOGS=true
CLEAN_SNAPSHOTS=true
CLEAN_DOCKER=true
CLEAN_USER_FILES=true
CLEAN_SYSTEM_CACHES=true
EOF

    chmod 644 "$CONFIG_FILE"
    success "Configuration file created: $CONFIG_FILE"
}

# Show cleanup statistics
show_statistics() {
    echo -e "${BLUE}Cleanup Statistics:${NC}"
    echo "==================="
    echo "Files cleaned: $files_cleaned"
    echo "Space freed: $(format_bytes $space_freed)"
    echo "Errors: $errors"
    echo ""
    
    # Show current disk usage
    echo -e "${BLUE}Current Disk Usage:${NC}"
    echo "==================="
    df -h / /home 2>/dev/null | grep -v "^Filesystem" || df -h /
    echo ""
    
    # Show memory usage
    echo -e "${BLUE}Memory Usage:${NC}"
    echo "============="
    free -h
}

# Perform dry run (show what would be cleaned)
dry_run() {
    info "Performing dry run (no actual cleanup)..."
    
    echo -e "${YELLOW}Files that would be cleaned:${NC}"
    
    # Show temp files
    echo -e "\n${BLUE}Temporary files:${NC}"
    find /tmp /var/tmp -type f -atime +0 -mtime +0 -ctime +0 2>/dev/null | head -10
    echo "  ... and more"
    
    # Show package cache
    echo -e "\n${BLUE}Package cache files:${NC}"
    find /var/cache/apt/archives -name "*.deb" -mtime +$PACKAGE_CACHE_RETENTION_DAYS 2>/dev/null | head -5
    echo "  ... and more"
    
    # Show old logs
    echo -e "\n${BLUE}Old log files:${NC}"
    find /var/log -type f -name "*.log.*" -mtime +$LOG_RETENTION_DAYS 2>/dev/null | head -5
    echo "  ... and more"
    
    info "Dry run completed. Use 'all' command to perform actual cleanup."
}

# Show usage information
show_usage() {
    cat << EOF
KawaiiSec System Cleanup Script

Usage: $0 COMMAND [OPTIONS]

Commands:
  all                Run all cleanup tasks
  temp               Clean temporary files only
  cache              Clean package cache only
  logs               Clean system logs only
  snapshots          Clean old snapshots only
  docker             Clean Docker resources only
  users              Clean user files only
  system             Clean system caches only
  dry-run            Show what would be cleaned (no actual cleanup)
  config             Create default configuration file
  report             Generate cleanup report
  stats              Show cleanup statistics
  help               Show this help message

Options:
  --retention-days N Set snapshot retention days
  --config FILE      Use custom configuration file
  --verbose          Enable verbose output
  --force            Force cleanup without confirmations

Examples:
  $0 all                           # Run all cleanup tasks
  $0 temp --verbose                # Clean temp files with verbose output
  $0 snapshots --retention-days 3  # Clean snapshots older than 3 days
  $0 dry-run                       # Preview what would be cleaned

Configuration:
  Configuration file: $CONFIG_FILE
  Log file: $LOG_FILE

EOF
}

# Parse command line arguments
VERBOSE=false
FORCE=false
RETENTION_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --retention-days)
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
        --force)
            FORCE=true
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

# Main execution
main() {
    local command="${1:-all}"
    
    # Initialize
    init_logging
    load_config
    
    # Override retention if specified
    if [[ -n "$RETENTION_OVERRIDE" ]]; then
        SNAPSHOT_RETENTION_DAYS="$RETENTION_OVERRIDE"
    fi
    
    # Record start time
    local start_time
    start_time=$(date +%s)
    
    case "$command" in
        all)
            info "Starting complete system cleanup..."
            clean_temp_files
            clean_package_cache
            clean_system_logs
            clean_old_snapshots
            clean_docker_resources
            clean_user_files
            clean_system_caches
            generate_report
            ;;
        temp)
            clean_temp_files
            ;;
        cache)
            clean_package_cache
            ;;
        logs)
            clean_system_logs
            ;;
        snapshots)
            clean_old_snapshots
            ;;
        docker)
            clean_docker_resources
            ;;
        users)
            clean_user_files
            ;;
        system)
            clean_system_caches
            ;;
        dry-run)
            dry_run
            return 0
            ;;
        config)
            create_config
            return 0
            ;;
        report)
            generate_report
            return 0
            ;;
        stats)
            show_statistics
            return 0
            ;;
        help)
            show_usage
            return 0
            ;;
        *)
            error_exit "Unknown command: $command. Use 'help' for usage information."
            ;;
    esac
    
    # Calculate execution time
    local end_time duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Show final statistics
    echo ""
    success "Cleanup completed in ${duration}s"
    show_statistics
    
    log "Cleanup completed: files=$files_cleaned, space=$(format_bytes $space_freed), errors=$errors, duration=${duration}s"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 