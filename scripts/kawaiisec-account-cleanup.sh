#!/bin/bash

# KawaiiSec OS Account Cleanup Script
# Detects, removes, and documents demo/test accounts before packaging and release

set -euo pipefail

# Configuration
CONFIG_FILE="/etc/kawaiisec/account-cleanup.conf"
WHITELIST_FILE="/etc/kawaiisec/account_whitelist.txt"
LOG_FILE="/var/log/kawaiisec-account-cleanup.log"
DRY_RUN=true
FORCE_REMOVAL=false
INTERACTIVE=true
LOCK_ONLY=false

# Account patterns to detect (case-insensitive)
SUSPICIOUS_PATTERNS=(
    "demo"
    "test"
    "student" 
    "guest"
    "temp"
    "lab"
    "kali"
    "user"
    "admin"
    "pentest"
    "training"
    "workshop"
    "example"
    "sample"
    "trial"
)

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Statistics tracking
declare -i accounts_found=0
declare -i accounts_processed=0
declare -i accounts_removed=0
declare -i accounts_locked=0
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

# Question/prompt message
question() {
    echo -e "${CYAN}❓ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root for account management operations"
    fi
}

# Initialize logging
init_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
    log "KawaiiSec Account Cleanup Started"
    
    # Log current mode
    if [[ "$DRY_RUN" == "true" ]]; then
        log "Mode: DRY RUN (no changes will be made)"
    elif [[ "$LOCK_ONLY" == "true" ]]; then
        log "Mode: LOCK ONLY (accounts will be disabled, not removed)"
    else
        log "Mode: FORCE REMOVAL (accounts will be permanently deleted)"
    fi
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        info "Configuration loaded from $CONFIG_FILE"
    else
        info "Using default configuration (no config file found)"
    fi
}

# Load whitelist
load_whitelist() {
    local -a whitelist=()
    
    if [[ -f "$WHITELIST_FILE" ]]; then
        while IFS= read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            whitelist+=("$line")
        done < "$WHITELIST_FILE"
        
        if [[ ${#whitelist[@]} -gt 0 ]]; then
            info "Loaded ${#whitelist[@]} whitelisted accounts from $WHITELIST_FILE"
            log "Whitelisted accounts: ${whitelist[*]}"
        else
            info "Whitelist file found but contains no valid entries"
        fi
    else
        warning "No whitelist file found at $WHITELIST_FILE"
        info "All matching accounts will be flagged for removal"
    fi
    
    # Export whitelist for other functions
    printf '%s\n' "${whitelist[@]}" > /tmp/kawaiisec-whitelist.$$
}

# Check if account is whitelisted
is_whitelisted() {
    local username="$1"
    
    if [[ -f /tmp/kawaiisec-whitelist.$$ ]]; then
        if grep -Fxq "$username" /tmp/kawaiisec-whitelist.$$; then
            return 0
        fi
    fi
    
    return 1
}

# Get all user accounts with UID >= 1000
get_user_accounts() {
    local -a user_accounts=()
    
    # Read /etc/passwd and filter for UID >= 1000
    while IFS=: read -r username _ uid gid _ home shell; do
        # Skip if UID < 1000 (system accounts)
        [[ $uid -lt 1000 ]] && continue
        
        # Skip nobody user (usually UID 65534)
        [[ "$username" == "nobody" ]] && continue
        
        user_accounts+=("$username:$uid:$gid:$home:$shell")
    done < /etc/passwd
    
    log "Found ${#user_accounts[@]} user accounts with UID >= 1000"
    
    # Export for other functions
    printf '%s\n' "${user_accounts[@]}" > /tmp/kawaiisec-accounts.$$
}

# Check if username matches suspicious patterns
is_suspicious_account() {
    local username="$1"
    local pattern
    
    for pattern in "${SUSPICIOUS_PATTERNS[@]}"; do
        # Case-insensitive pattern matching
        if [[ "${username,,}" =~ ${pattern,,} ]]; then
            return 0
        fi
    done
    
    return 1
}

# Get account information
get_account_info() {
    local username="$1"
    local uid gid home shell
    local last_login="Never"
    local processes=0
    local home_size="0"
    
    # Parse account details
    if account_line=$(grep "^$username:" /etc/passwd); then
        IFS=: read -r _ _ uid gid _ home shell <<< "$account_line"
    else
        return 1
    fi
    
    # Get last login
    if command -v lastlog >/dev/null 2>&1; then
        last_login=$(lastlog -u "$username" 2>/dev/null | tail -1 | awk '{for(i=4;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/[[:space:]]*$//')
        [[ -z "$last_login" || "$last_login" =~ Never ]] && last_login="Never"
    fi
    
    # Count running processes
    processes=$(pgrep -u "$username" 2>/dev/null | wc -l)
    
    # Get home directory size
    if [[ -d "$home" ]]; then
        home_size=$(du -sh "$home" 2>/dev/null | cut -f1 || echo "0")
    fi
    
    # Check if account is locked
    local locked="No"
    if passwd -S "$username" 2>/dev/null | grep -q " L "; then
        locked="Yes"
    fi
    
    echo "UID: $uid, GID: $gid, Home: $home, Shell: $shell, Last Login: $last_login, Processes: $processes, Home Size: $home_size, Locked: $locked"
}

# Scan for suspicious accounts
scan_accounts() {
    local -a suspicious_accounts=()
    local username uid gid home shell
    
    info "Scanning for suspicious demo/test accounts..."
    
    # Load user accounts
    get_user_accounts
    
    # Check each account
    while IFS= read -r account_line; do
        [[ -z "$account_line" ]] && continue
        
        IFS=: read -r username uid gid home shell <<< "$account_line"
        
        if is_suspicious_account "$username"; then
            ((accounts_found++))
            
            if is_whitelisted "$username"; then
                log "WHITELISTED: $username (matches pattern but is whitelisted)"
                info "Account '$username' matches suspicious pattern but is whitelisted - SKIPPING"
            else
                suspicious_accounts+=("$username")
                log "SUSPICIOUS: $username ($(get_account_info "$username"))"
            fi
        fi
    done < /tmp/kawaiisec-accounts.$$
    
    if [[ ${#suspicious_accounts[@]} -eq 0 ]]; then
        success "No suspicious accounts found that aren't whitelisted"
        return 0
    fi
    
    echo ""
    warning "Found ${#suspicious_accounts[@]} suspicious accounts:"
    echo ""
    
    # Display detailed information about each suspicious account
    for username in "${suspicious_accounts[@]}"; do
        echo -e "${RED}🚨 Suspicious Account: ${YELLOW}$username${NC}"
        echo -e "   $(get_account_info "$username")"
        echo ""
    done
    
    # Export suspicious accounts for processing
    printf '%s\n' "${suspicious_accounts[@]}" > /tmp/kawaiisec-suspicious.$$
    
    return ${#suspicious_accounts[@]}
}

# Confirm account removal
confirm_removal() {
    local username="$1"
    local response
    
    if [[ "$INTERACTIVE" == "false" ]]; then
        return 0
    fi
    
    echo ""
    question "Process account '$username'?"
    if [[ "$LOCK_ONLY" == "true" ]]; then
        echo -e "${CYAN}This will LOCK the account (disable login but preserve data)${NC}"
    else
        echo -e "${RED}This will PERMANENTLY DELETE the account and home directory${NC}"
    fi
    
    while true; do
        read -p "Continue? [y/N/s(skip)/q(quit)]: " response
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo]|"")
                return 1
                ;;
            [Ss]|[Ss][Kk][Ii][Pp])
                return 1
                ;;
            [Qq]|[Qq][Uu][Ii][Tt])
                info "User chose to quit"
                exit 0
                ;;
            *)
                echo "Please answer y(yes), n(no), s(skip), or q(quit)"
                ;;
        esac
    done
}

# Lock account
lock_account() {
    local username="$1"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "DRY RUN: Would lock account '$username'"
        return 0
    fi
    
    if usermod -L "$username" 2>/dev/null; then
        success "Locked account '$username'"
        log "LOCKED: $username"
        ((accounts_locked++))
        return 0
    else
        warning "Failed to lock account '$username'"
        ((errors++))
        return 1
    fi
}

# Remove account
remove_account() {
    local username="$1"
    local home_dir
    
    # Get home directory before deletion
    home_dir=$(getent passwd "$username" | cut -d: -f6)
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "DRY RUN: Would remove account '$username' and home directory '$home_dir'"
        return 0
    fi
    
    # Kill any running processes for this user
    if pgrep -u "$username" >/dev/null 2>&1; then
        warning "Killing processes for user '$username'"
        pkill -TERM -u "$username" 2>/dev/null || true
        sleep 2
        pkill -KILL -u "$username" 2>/dev/null || true
    fi
    
    # Remove the account and home directory
    if userdel -r "$username" 2>/dev/null; then
        success "Removed account '$username' and home directory '$home_dir'"
        log "REMOVED: $username (home: $home_dir)"
        ((accounts_removed++))
        return 0
    else
        warning "Failed to remove account '$username'"
        # Try without removing home directory
        if userdel "$username" 2>/dev/null; then
            warning "Removed account '$username' but failed to remove home directory '$home_dir'"
            log "PARTIAL_REMOVAL: $username (account removed, home directory may remain)"
            ((accounts_removed++))
            return 0
        else
            error_exit "Failed to remove account '$username'"
            return 1
        fi
    fi
}

# Process accounts
process_accounts() {
    local username
    
    if [[ ! -f /tmp/kawaiisec-suspicious.$$ ]]; then
        info "No suspicious accounts to process"
        return 0
    fi
    
    info "Processing suspicious accounts..."
    echo ""
    
    while IFS= read -r username; do
        [[ -z "$username" ]] && continue
        
        ((accounts_processed++))
        
        if confirm_removal "$username"; then
            if [[ "$LOCK_ONLY" == "true" ]]; then
                lock_account "$username"
            else
                remove_account "$username"
            fi
        else
            info "Skipped account '$username'"
        fi
        
        echo ""
    done < /tmp/kawaiisec-suspicious.$$
}

# Generate report
generate_report() {
    local report_file="/tmp/kawaiisec-account-cleanup-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$report_file" << EOF
KawaiiSec OS Account Cleanup Report
Generated: $(date)
Mode: $(if [[ "$DRY_RUN" == "true" ]]; then echo "DRY RUN"; elif [[ "$LOCK_ONLY" == "true" ]]; then echo "LOCK ONLY"; else echo "FORCE REMOVAL"; fi)

SUMMARY:
========
Accounts Found: $accounts_found
Accounts Processed: $accounts_processed
Accounts Removed: $accounts_removed
Accounts Locked: $accounts_locked
Errors: $errors

CONFIGURATION:
==============
Config File: $CONFIG_FILE
Whitelist File: $WHITELIST_FILE
Log File: $LOG_FILE

SUSPICIOUS PATTERNS CHECKED:
============================
$(printf '%s\n' "${SUSPICIOUS_PATTERNS[@]}")

WHITELIST STATUS:
=================
EOF

    if [[ -f "$WHITELIST_FILE" ]]; then
        echo "Whitelist file found: $WHITELIST_FILE" >> "$report_file"
        echo "Whitelisted accounts:" >> "$report_file"
        grep -v "^#" "$WHITELIST_FILE" | grep -v "^[[:space:]]*$" >> "$report_file" || echo "None" >> "$report_file"
    else
        echo "No whitelist file found at $WHITELIST_FILE" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "DETAILED LOG:" >> "$report_file"
    echo "=============" >> "$report_file"
    tail -50 "$LOG_FILE" >> "$report_file" 2>/dev/null || echo "Log file not accessible" >> "$report_file"
    
    success "Report generated: $report_file"
    
    # Copy to user's home directory if running interactively
    if [[ -n "${SUDO_USER:-}" && -d "/home/${SUDO_USER}" ]]; then
        cp "$report_file" "/home/${SUDO_USER}/"
        chown "${SUDO_USER}:${SUDO_USER}" "/home/${SUDO_USER}/$(basename "$report_file")"
        info "Report also saved to /home/${SUDO_USER}/$(basename "$report_file")"
    fi
}

# Show statistics
show_statistics() {
    echo ""
    echo -e "${PURPLE}📊 Account Cleanup Statistics${NC}"
    echo "================================"
    echo -e "Accounts Found:     ${YELLOW}$accounts_found${NC}"
    echo -e "Accounts Processed: ${BLUE}$accounts_processed${NC}"
    echo -e "Accounts Removed:   ${RED}$accounts_removed${NC}"
    echo -e "Accounts Locked:    ${YELLOW}$accounts_locked${NC}"
    echo -e "Errors:             ${RED}$errors${NC}"
    echo ""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${CYAN}ℹ️  This was a DRY RUN - no changes were made${NC}"
        echo -e "${CYAN}ℹ️  Use --force to actually remove accounts${NC}"
    fi
}

# Create default configuration
create_default_config() {
    local config_dir
    config_dir=$(dirname "$CONFIG_FILE")
    
    info "Creating default configuration..."
    
    mkdir -p "$config_dir"
    
    cat > "$CONFIG_FILE" << 'EOF'
# KawaiiSec OS Account Cleanup Configuration
# Generated automatically

# Default behavior
DRY_RUN=true
FORCE_REMOVAL=false
INTERACTIVE=true
LOCK_ONLY=false

# Logging
LOG_FILE="/var/log/kawaiisec-account-cleanup.log"

# Additional suspicious patterns (beyond the built-in list)
# Add one pattern per line
CUSTOM_SUSPICIOUS_PATTERNS=(
    # Add custom patterns here
    # "yourpattern"
)
EOF

    chmod 644 "$CONFIG_FILE"
    success "Default configuration created at $CONFIG_FILE"
}

# Create default whitelist
create_default_whitelist() {
    local whitelist_dir
    whitelist_dir=$(dirname "$WHITELIST_FILE")
    
    info "Creating default whitelist..."
    
    mkdir -p "$whitelist_dir"
    
    cat > "$WHITELIST_FILE" << 'EOF'
# KawaiiSec OS Account Whitelist
# Accounts listed here will NOT be removed during cleanup
# One account name per line
# Lines starting with # are comments

# Example legitimate accounts:
# instructor
# teacher
# admin-real
# staff
# kawaiisec-admin

# Add your legitimate accounts below:

EOF

    chmod 644 "$WHITELIST_FILE"
    success "Default whitelist created at $WHITELIST_FILE"
    warning "Please edit $WHITELIST_FILE to add legitimate accounts that should be preserved"
}

# Show usage information
show_usage() {
    cat << EOF
KawaiiSec OS Account Cleanup Script
Detects, removes, and documents demo/test accounts before packaging and release

USAGE:
    $0 [OPTIONS] [COMMAND]

COMMANDS:
    scan        Scan for suspicious accounts (default)
    cleanup     Scan and process suspicious accounts  
    config      Create default configuration files
    help        Show this help message

OPTIONS:
    --dry-run           Show what would be done without making changes (default)
    --force             Actually remove/lock accounts (disables dry-run)
    --lock-only         Lock accounts instead of removing them
    --non-interactive   Don't prompt for confirmation
    --interactive       Prompt for each account (default)
    --config FILE       Use custom configuration file
    --whitelist FILE    Use custom whitelist file
    --help              Show this help message

EXAMPLES:
    $0                                  # Dry-run scan (safe)
    $0 --force cleanup                  # Actually remove suspicious accounts
    $0 --lock-only --force cleanup      # Lock suspicious accounts
    $0 --non-interactive --force cleanup # Automated removal
    $0 config                           # Create default config files

SAFETY FEATURES:
    • Dry-run mode by default (no changes made)
    • Whitelist support to protect legitimate accounts
    • Comprehensive logging of all actions
    • Interactive confirmation for each account
    • Detailed reporting

FILES:
    $CONFIG_FILE     - Configuration file
    $WHITELIST_FILE  - Account whitelist
    $LOG_FILE        - Activity log

SUSPICIOUS PATTERNS:
$(printf '    %s\n' "${SUSPICIOUS_PATTERNS[@]}")

EOF
}

# Cleanup temporary files
cleanup_temp() {
    rm -f /tmp/kawaiisec-*.$$
}

# Main function  
main() {
    local command="scan"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                DRY_RUN=false
                FORCE_REMOVAL=true
                shift
                ;;
            --lock-only)
                LOCK_ONLY=true
                shift
                ;;
            --interactive)
                INTERACTIVE=true
                shift
                ;;
            --non-interactive)
                INTERACTIVE=false
                shift
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --whitelist)
                WHITELIST_FILE="$2"
                shift 2
                ;;
            --help|help)
                show_usage
                exit 0
                ;;
            scan|cleanup|config)
                command="$1"
                shift
                ;;
            *)
                error_exit "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done
    
    # Set trap for cleanup
    trap cleanup_temp EXIT
    
    # Check root privileges for non-config commands
    if [[ "$command" != "config" ]]; then
        check_root
    fi
    
    # Initialize
    init_logging
    load_config
    
    case "$command" in
        scan)
            info "Running account scan..."
            load_whitelist
            if scan_accounts; then
                success "Account scan completed - no suspicious accounts found"
            else
                warning "Account scan completed - $? suspicious accounts found"
                info "Use 'cleanup' command to process these accounts"
            fi
            show_statistics
            generate_report
            ;;
        cleanup)
            info "Running account cleanup..."
            load_whitelist
            if scan_accounts; then
                success "No suspicious accounts found"
            else
                process_accounts
            fi
            show_statistics
            generate_report
            ;;
        config)
            info "Creating default configuration files..."
            create_default_config
            create_default_whitelist
            success "Configuration files created"
            echo ""
            info "Next steps:"
            echo "1. Edit $WHITELIST_FILE to add legitimate accounts"
            echo "2. Review $CONFIG_FILE for additional settings"
            echo "3. Run '$0 scan' to test the configuration"
            ;;
        *)
            error_exit "Unknown command: $command. Use --help for usage information."
            ;;
    esac
    
    log "KawaiiSec Account Cleanup Completed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 