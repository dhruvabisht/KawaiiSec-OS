#!/bin/bash

# KawaiiSec Disk Quota Setup and Management Script
# Configures user and group quotas on filesystems

set -euo pipefail

# Configuration
CONFIG_FILE="/etc/kawaiisec/quotas.conf"
LOG_FILE="/var/log/kawaiisec-quotas.log"
DEFAULT_USER_SOFT_LIMIT="5G"
DEFAULT_USER_HARD_LIMIT="6G"
DEFAULT_GROUP_SOFT_LIMIT="20G"
DEFAULT_GROUP_HARD_LIMIT="25G"
GRACE_PERIOD="7days"

# Quota filesystems (filesystem:mount_point)
QUOTA_FILESYSTEMS=(
    "/home"
    "/opt/kawaiisec"
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
    log "KawaiiSec Quota Setup Started"
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

# Check if quota tools are available
check_quota_tools() {
    local missing_tools=()
    
    for tool in quotacheck quotaon quotaoff quota setquota repquota; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        error_exit "Missing quota tools: ${missing_tools[*]}. Install with: apt install quota"
    fi
}

# Check if filesystem supports quotas
check_filesystem_support() {
    local mount_point="$1"
    local fstype
    
    fstype=$(findmnt -n -o FSTYPE "$mount_point" 2>/dev/null)
    
    case "$fstype" in
        ext4|ext3|ext2|xfs|btrfs)
            return 0
            ;;
        *)
            warning "Filesystem $fstype may not support quotas: $mount_point"
            return 1
            ;;
    esac
}

# Update fstab with quota options
update_fstab() {
    local mount_point="$1"
    local fstab_backup="/etc/fstab.backup-quotas-$(date +%Y%m%d-%H%M%S)"
    
    info "Updating /etc/fstab for quota support on $mount_point"
    
    # Create backup
    cp /etc/fstab "$fstab_backup"
    success "fstab backed up to $fstab_backup"
    
    # Check if quota options already exist
    if grep -q "usrquota\|grpquota" /etc/fstab && grep -q "$mount_point" /etc/fstab; then
        warning "Quota options may already exist in fstab for $mount_point"
        return 0
    fi
    
    # Add quota options to fstab
    local device
    device=$(findmnt -n -o SOURCE "$mount_point" 2>/dev/null)
    
    if [[ -z "$device" ]]; then
        error_exit "Could not find device for mount point: $mount_point"
    fi
    
    # Create temporary fstab with quota options
    awk -v device="$device" -v mount_point="$mount_point" '
    {
        if ($1 == device && $2 == mount_point) {
            # Add quota options if not present
            if ($4 !~ /usrquota/ && $4 !~ /grpquota/) {
                if ($4 == "defaults") {
                    $4 = "defaults,usrquota,grpquota"
                } else {
                    $4 = $4 ",usrquota,grpquota"
                }
            }
        }
        print
    }' /etc/fstab > /etc/fstab.tmp
    
    # Replace fstab
    mv /etc/fstab.tmp /etc/fstab
    success "Updated fstab with quota options for $mount_point"
}

# Remount filesystem with quota options
remount_with_quotas() {
    local mount_point="$1"
    
    info "Remounting $mount_point with quota options..."
    
    if mount -o remount,usrquota,grpquota "$mount_point"; then
        success "Remounted $mount_point with quota options"
    else
        warning "Failed to remount $mount_point. A reboot may be required."
        return 1
    fi
}

# Create quota files
create_quota_files() {
    local mount_point="$1"
    
    info "Creating quota files for $mount_point..."
    
    # Run quotacheck to create quota files
    if quotacheck -cugm "$mount_point"; then
        success "Quota files created for $mount_point"
    else
        error_exit "Failed to create quota files for $mount_point"
    fi
    
    # Set proper permissions on quota files
    chmod 600 "$mount_point"/aquota.{user,group} 2>/dev/null || true
}

# Enable quotas
enable_quotas() {
    local mount_point="$1"
    
    info "Enabling quotas for $mount_point..."
    
    if quotaon "$mount_point"; then
        success "Quotas enabled for $mount_point"
    else
        error_exit "Failed to enable quotas for $mount_point"
    fi
}

# Convert size to blocks (1 block = 1024 bytes)
size_to_blocks() {
    local size="$1"
    local blocks
    
    # Convert size to bytes, then to blocks
    case "${size: -1}" in
        K|k) blocks=$((${size%?} * 1)) ;;
        M|m) blocks=$((${size%?} * 1024)) ;;
        G|g) blocks=$((${size%?} * 1024 * 1024)) ;;
        T|t) blocks=$((${size%?} * 1024 * 1024 * 1024)) ;;
        *) blocks=$((size / 1024)) ;;
    esac
    
    echo "$blocks"
}

# Set default quota for a user
set_user_quota() {
    local username="$1"
    local mount_point="$2"
    local soft_limit="${3:-$DEFAULT_USER_SOFT_LIMIT}"
    local hard_limit="${4:-$DEFAULT_USER_HARD_LIMIT}"
    
    local soft_blocks hard_blocks
    soft_blocks=$(size_to_blocks "$soft_limit")
    hard_blocks=$(size_to_blocks "$hard_limit")
    
    info "Setting quota for user $username on $mount_point (soft: $soft_limit, hard: $hard_limit)"
    
    if setquota -u "$username" "$soft_blocks" "$hard_blocks" 0 0 "$mount_point"; then
        success "Quota set for user $username"
    else
        warning "Failed to set quota for user $username"
        return 1
    fi
}

# Set default quota for a group
set_group_quota() {
    local groupname="$1"
    local mount_point="$2"
    local soft_limit="${3:-$DEFAULT_GROUP_SOFT_LIMIT}"
    local hard_limit="${4:-$DEFAULT_GROUP_HARD_LIMIT}"
    
    local soft_blocks hard_blocks
    soft_blocks=$(size_to_blocks "$soft_limit")
    hard_blocks=$(size_to_blocks "$hard_limit")
    
    info "Setting quota for group $groupname on $mount_point (soft: $soft_limit, hard: $hard_limit)"
    
    if setquota -g "$groupname" "$soft_blocks" "$hard_blocks" 0 0 "$mount_point"; then
        success "Quota set for group $groupname"
    else
        warning "Failed to set quota for group $groupname"
        return 1
    fi
}

# Set grace period
set_grace_period() {
    local mount_point="$1"
    local grace="${2:-$GRACE_PERIOD}"
    
    info "Setting grace period to $grace for $mount_point"
    
    # Set grace period for users and groups
    if setquota -t -u "$grace" "$grace" "$mount_point" && \
       setquota -t -g "$grace" "$grace" "$mount_point"; then
        success "Grace period set to $grace"
    else
        warning "Failed to set grace period"
        return 1
    fi
}

# Apply default quotas to existing users
apply_default_quotas() {
    local mount_point="$1"
    
    info "Applying default quotas to existing users on $mount_point..."
    
    local user_count=0
    
    # Apply quotas to all regular users (UID >= 1000)
    while IFS=: read -r username _ uid _; do
        if [[ $uid -ge 1000 && $uid -le 60000 ]]; then
            if set_user_quota "$username" "$mount_point"; then
                ((user_count++))
            fi
        fi
    done < /etc/passwd
    
    # Apply quotas to common groups
    local group_count=0
    for group in users staff sudo; do
        if getent group "$group" >/dev/null 2>&1; then
            if set_group_quota "$group" "$mount_point"; then
                ((group_count++))
            fi
        fi
    done
    
    success "Applied quotas to $user_count users and $group_count groups"
}

# Show quota report
show_quota_report() {
    local mount_point="$1"
    
    echo -e "${BLUE}Quota Report for $mount_point${NC}"
    echo "==============================="
    
    # User quotas
    echo -e "\n${PURPLE}User Quotas:${NC}"
    repquota -u "$mount_point" 2>/dev/null || echo "No user quotas found"
    
    # Group quotas
    echo -e "\n${PURPLE}Group Quotas:${NC}"
    repquota -g "$mount_point" 2>/dev/null || echo "No group quotas found"
    
    # Quota status
    echo -e "\n${PURPLE}Quota Status:${NC}"
    quotaon -p "$mount_point" 2>/dev/null || echo "Quotas not enabled"
}

# Check quota usage
check_quota_usage() {
    local mount_point="$1"
    local threshold="${2:-80}"  # Alert threshold percentage
    
    info "Checking quota usage on $mount_point (threshold: ${threshold}%)"
    
    # Check user quotas
    local violations=0
    while read -r line; do
        if [[ "$line" =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]+[^[:space:]]+[[:space:]]+([0-9]+)[[:space:]]+([0-9]+) ]]; then
            local username="${BASH_REMATCH[1]}"
            local used="${BASH_REMATCH[2]}"
            local soft_limit="${BASH_REMATCH[3]}"
            
            if [[ $soft_limit -gt 0 ]]; then
                local usage_percent=$((used * 100 / soft_limit))
                if [[ $usage_percent -ge $threshold ]]; then
                    warning "User $username quota usage: ${usage_percent}% ($used/$soft_limit blocks)"
                    ((violations++))
                fi
            fi
        fi
    done < <(repquota -u "$mount_point" 2>/dev/null | tail -n +6)
    
    if [[ $violations -gt 0 ]]; then
        warning "Found $violations quota violations on $mount_point"
    else
        success "No quota violations found on $mount_point"
    fi
}

# Create quota monitoring script
create_monitoring_script() {
    local script_path="/usr/local/bin/kawaiisec-quota-monitor.sh"
    
    info "Creating quota monitoring script..."
    
    cat > "$script_path" << 'EOF'
#!/bin/bash

# KawaiiSec Quota Monitoring Script
# Monitors quota usage and sends alerts

set -euo pipefail

LOG_FILE="/var/log/kawaiisec-quota-monitor.log"
ALERT_THRESHOLD=90
EMAIL_ALERT=false
ADMIN_EMAIL="admin@localhost"

# Source configuration
if [[ -f /etc/kawaiisec/quotas.conf ]]; then
    source /etc/kawaiisec/quotas.conf
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check quota usage for all configured filesystems
check_all_quotas() {
    local total_violations=0
    
    for mount_point in "${QUOTA_FILESYSTEMS[@]}"; do
        if [[ -d "$mount_point" ]]; then
            log "Checking quotas for $mount_point"
            
            # Check if quotas are enabled
            if ! quotaon -p "$mount_point" >/dev/null 2>&1; then
                log "WARNING: Quotas not enabled on $mount_point"
                continue
            fi
            
            # Check user quotas
            while read -r line; do
                if [[ "$line" =~ ^[[:space:]]*([^[:space:]]+)[[:space:]]+[^[:space:]]+[[:space:]]+([0-9]+)[[:space:]]+([0-9]+) ]]; then
                    local username="${BASH_REMATCH[1]}"
                    local used="${BASH_REMATCH[2]}"
                    local soft_limit="${BASH_REMATCH[3]}"
                    
                    if [[ $soft_limit -gt 0 ]]; then
                        local usage_percent=$((used * 100 / soft_limit))
                        if [[ $usage_percent -ge $ALERT_THRESHOLD ]]; then
                            local message="QUOTA ALERT: User $username on $mount_point: ${usage_percent}% used"
                            log "$message"
                            
                            # Send email alert if configured
                            if [[ "$EMAIL_ALERT" == "true" ]]; then
                                echo "$message" | mail -s "KawaiiSec Quota Alert" "$ADMIN_EMAIL" 2>/dev/null || true
                            fi
                            
                            ((total_violations++))
                        fi
                    fi
                fi
            done < <(repquota -u "$mount_point" 2>/dev/null | tail -n +6)
        fi
    done
    
    log "Quota monitoring completed. Total violations: $total_violations"
}

# Generate quota usage report
generate_report() {
    local report_file="/var/log/kawaiisec-quota-report.txt"
    
    cat > "$report_file" << REPORT
KawaiiSec Quota Usage Report
Generated: $(date)

REPORT

    for mount_point in "${QUOTA_FILESYSTEMS[@]}"; do
        if [[ -d "$mount_point" ]] && quotaon -p "$mount_point" >/dev/null 2>&1; then
            cat >> "$report_file" << REPORT

Filesystem: $mount_point
===================
$(repquota -u "$mount_point" 2>/dev/null)

REPORT
        fi
    done
    
    log "Quota report generated: $report_file"
}

# Main monitoring function
main() {
    log "Starting quota monitoring..."
    check_all_quotas
    generate_report
    log "Quota monitoring completed"
}

main "$@"
EOF

    chmod +x "$script_path"
    success "Quota monitoring script created at $script_path"
}

# Create systemd timer for quota monitoring
create_monitoring_timer() {
    info "Creating systemd timer for quota monitoring..."
    
    # Service file
    cat > "/etc/systemd/system/kawaiisec-quota-monitor.service" << EOF
[Unit]
Description=KawaiiSec Quota Monitoring
Documentation=man:kawaiisec-quota-setup(8)

[Service]
Type=oneshot
ExecStart=/usr/local/bin/kawaiisec-quota-monitor.sh
User=root
StandardOutput=journal
StandardError=journal
EOF

    # Timer file
    cat > "/etc/systemd/system/kawaiisec-quota-monitor.timer" << EOF
[Unit]
Description=KawaiiSec Quota Monitoring Timer
Documentation=man:kawaiisec-quota-setup(8)
Requires=kawaiisec-quota-monitor.service

[Timer]
OnCalendar=daily
AccuracySec=1h
Persistent=true
RandomizedDelaySec=30m

[Install]
WantedBy=timers.target
EOF

    # Set permissions
    chmod 644 /etc/systemd/system/kawaiisec-quota-monitor.{service,timer}
    
    # Enable and start timer
    systemctl daemon-reload
    systemctl enable kawaiisec-quota-monitor.timer
    systemctl start kawaiisec-quota-monitor.timer
    
    success "Quota monitoring timer created and enabled"
}

# Create configuration file
create_config() {
    info "Creating quota configuration file..."
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    cat > "$CONFIG_FILE" << EOF
# KawaiiSec Quota Configuration
# Generated on $(date)

# Default user quota limits
DEFAULT_USER_SOFT_LIMIT="$DEFAULT_USER_SOFT_LIMIT"
DEFAULT_USER_HARD_LIMIT="$DEFAULT_USER_HARD_LIMIT"

# Default group quota limits
DEFAULT_GROUP_SOFT_LIMIT="$DEFAULT_GROUP_SOFT_LIMIT"
DEFAULT_GROUP_HARD_LIMIT="$DEFAULT_GROUP_HARD_LIMIT"

# Grace period for soft limit violations
GRACE_PERIOD="$GRACE_PERIOD"

# Filesystems with quotas enabled
QUOTA_FILESYSTEMS=(
$(printf '    "%s"\n' "${QUOTA_FILESYSTEMS[@]}")
)

# Monitoring settings
ALERT_THRESHOLD=90
EMAIL_ALERT=false
ADMIN_EMAIL="admin@localhost"
EOF

    chmod 644 "$CONFIG_FILE"
    success "Configuration file created at $CONFIG_FILE"
}

# Setup quotas for a filesystem
setup_filesystem_quotas() {
    local mount_point="$1"
    
    info "Setting up quotas for filesystem: $mount_point"
    
    # Check if mount point exists
    if [[ ! -d "$mount_point" ]]; then
        error_exit "Mount point does not exist: $mount_point"
    fi
    
    # Check filesystem support
    if ! check_filesystem_support "$mount_point"; then
        warning "Filesystem may not support quotas: $mount_point"
    fi
    
    # Update fstab
    update_fstab "$mount_point"
    
    # Try to remount with quota options
    if ! remount_with_quotas "$mount_point"; then
        warning "Could not remount $mount_point. Manual reboot may be required."
    fi
    
    # Create quota files
    create_quota_files "$mount_point"
    
    # Enable quotas
    enable_quotas "$mount_point"
    
    # Set grace period
    set_grace_period "$mount_point"
    
    # Apply default quotas
    apply_default_quotas "$mount_point"
    
    success "Quota setup completed for $mount_point"
}

# Show usage information
show_usage() {
    cat << EOF
KawaiiSec Disk Quota Setup and Management Script

Usage: $0 COMMAND [OPTIONS]

Commands:
  setup              Setup quotas on all configured filesystems
  setup-fs PATH      Setup quotas on specific filesystem
  add-user USER [PATH] [SOFT] [HARD]  Add quota for user
  add-group GROUP [PATH] [SOFT] [HARD]  Add quota for group
  report [PATH]      Show quota report
  check [PATH]       Check quota usage
  monitor            Run quota monitoring
  help               Show this help message

Options:
  --soft-limit SIZE  Set soft limit (e.g., 5G, 500M)
  --hard-limit SIZE  Set hard limit (e.g., 6G, 600M)
  --grace PERIOD     Set grace period (e.g., 7days, 2weeks)
  --threshold PCT    Set alert threshold percentage
  --config FILE      Use custom configuration file

Examples:
  $0 setup                           # Setup quotas on all filesystems
  $0 setup-fs /home                  # Setup quotas on /home only
  $0 add-user alice /home 3G 4G      # Set 3G/4G quota for alice on /home
  $0 report /home                    # Show quota report for /home
  $0 check /home --threshold 85      # Check usage with 85% threshold

Configuration:
  Configuration file: $CONFIG_FILE
  Log file: $LOG_FILE

EOF
}

# Parse command line arguments
SOFT_LIMIT_OVERRIDE=""
HARD_LIMIT_OVERRIDE=""
GRACE_OVERRIDE=""
THRESHOLD_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --soft-limit)
            SOFT_LIMIT_OVERRIDE="$2"
            shift 2
            ;;
        --hard-limit)
            HARD_LIMIT_OVERRIDE="$2"
            shift 2
            ;;
        --grace)
            GRACE_OVERRIDE="$2"
            shift 2
            ;;
        --threshold)
            THRESHOLD_OVERRIDE="$2"
            shift 2
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
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
    local command="${1:-help}"
    local arg1="${2:-}"
    local arg2="${3:-}"
    local arg3="${4:-}"
    local arg4="${5:-}"
    
    # Initialize
    check_root
    init_logging
    load_config
    check_quota_tools
    
    # Override defaults if specified
    [[ -n "$SOFT_LIMIT_OVERRIDE" ]] && DEFAULT_USER_SOFT_LIMIT="$SOFT_LIMIT_OVERRIDE"
    [[ -n "$HARD_LIMIT_OVERRIDE" ]] && DEFAULT_USER_HARD_LIMIT="$HARD_LIMIT_OVERRIDE"
    [[ -n "$GRACE_OVERRIDE" ]] && GRACE_PERIOD="$GRACE_OVERRIDE"
    
    case "$command" in
        setup)
            create_config
            for mount_point in "${QUOTA_FILESYSTEMS[@]}"; do
                setup_filesystem_quotas "$mount_point"
            done
            create_monitoring_script
            create_monitoring_timer
            success "Quota setup completed for all filesystems"
            ;;
        setup-fs)
            if [[ -z "$arg1" ]]; then
                error_exit "Mount point required for setup-fs command"
            fi
            setup_filesystem_quotas "$arg1"
            ;;
        add-user)
            if [[ -z "$arg1" ]]; then
                error_exit "Username required for add-user command"
            fi
            local mount_point="${arg2:-/home}"
            local soft="${arg3:-$DEFAULT_USER_SOFT_LIMIT}"
            local hard="${arg4:-$DEFAULT_USER_HARD_LIMIT}"
            set_user_quota "$arg1" "$mount_point" "$soft" "$hard"
            ;;
        add-group)
            if [[ -z "$arg1" ]]; then
                error_exit "Group name required for add-group command"
            fi
            local mount_point="${arg2:-/home}"
            local soft="${arg3:-$DEFAULT_GROUP_SOFT_LIMIT}"
            local hard="${arg4:-$DEFAULT_GROUP_HARD_LIMIT}"
            set_group_quota "$arg1" "$mount_point" "$soft" "$hard"
            ;;
        report)
            local mount_point="${arg1:-/home}"
            show_quota_report "$mount_point"
            ;;
        check)
            local mount_point="${arg1:-/home}"
            local threshold="${THRESHOLD_OVERRIDE:-80}"
            check_quota_usage "$mount_point" "$threshold"
            ;;
        monitor)
            if [[ -f "/usr/local/bin/kawaiisec-quota-monitor.sh" ]]; then
                /usr/local/bin/kawaiisec-quota-monitor.sh
            else
                error_exit "Quota monitoring script not found. Run 'setup' first."
            fi
            ;;
        help)
            show_usage
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