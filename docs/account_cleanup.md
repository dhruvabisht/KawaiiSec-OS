# 🧹 KawaiiSec OS Account Cleanup System

## Overview

The KawaiiSec OS Account Cleanup System is a robust security tool designed to detect, document, and remove demo/test accounts before packaging and release. This system helps ensure that no unauthorized or temporary accounts remain in production deployments.

## Features

- **Automated Detection**: Scans for accounts matching suspicious patterns (demo, test, guest, etc.)
- **Safety First**: Dry-run mode by default - no changes made without explicit consent
- **Whitelist Support**: Protects legitimate accounts that match suspicious patterns
- **Multiple Removal Options**: Choose between account removal or account locking
- **Comprehensive Logging**: All actions are logged with timestamps and details
- **Interactive & Automated Modes**: Supports both manual confirmation and batch processing
- **Detailed Reporting**: Generates comprehensive reports of all actions taken

## Quick Start

### 1. Basic Scan (Safe)
```bash
# Scan for suspicious accounts without making changes
make account-cleanup
# or
sudo kawaiisec-account-cleanup.sh scan
```

### 2. Create Configuration Files
```bash
# Generate default configuration and whitelist files
make account-cleanup-config
# or
kawaiisec-account-cleanup.sh config
```

### 3. Edit Whitelist (Important!)
```bash
# Add legitimate accounts to protect them
sudo nano /etc/kawaiisec/account_whitelist.txt
```

### 4. Remove Suspicious Accounts
```bash
# DESTRUCTIVE: Permanently removes accounts
make account-cleanup-force
# or
sudo kawaiisec-account-cleanup.sh --force cleanup

# SAFER: Just lock/disable accounts
make account-cleanup-lock
# or
sudo kawaiisec-account-cleanup.sh --lock-only --force cleanup
```

## Suspicious Account Patterns

The system automatically flags accounts matching these patterns (case-insensitive):

- `demo` - Demo accounts
- `test` - Test accounts  
- `student` - Student accounts
- `guest` - Guest accounts
- `temp` - Temporary accounts
- `lab` - Lab accounts
- `kali` - Default Kali accounts
- `user` - Generic user accounts
- `admin` - Generic admin accounts
- `pentest` - Penetration testing accounts
- `training` - Training accounts
- `workshop` - Workshop accounts
- `example` - Example accounts
- `sample` - Sample accounts
- `trial` - Trial accounts

## Account Whitelist System

### Purpose
The whitelist protects legitimate accounts that might match suspicious patterns (e.g., a real instructor account named "demo-instructor").

### Configuration File
Location: `/etc/kawaiisec/account_whitelist.txt`

### Format
```bash
# KawaiiSec OS Account Whitelist
# One account name per line
# Lines starting with # are comments

instructor
teacher
admin-real
staff
kawaiisec-admin
```

### Example Legitimate Accounts
- `instructor` - Course instructor
- `teacher` - Teaching staff
- `admin-real` - Legitimate administrator
- `staff` - Staff accounts
- `kawaiisec-admin` - KawaiiSec system administrator
- `demo-instructor` - Legitimate demo instructor account
- `lab-coordinator` - Lab coordinator account

## Command Line Usage

### Basic Commands
```bash
# Scan for suspicious accounts (dry-run)
kawaiisec-account-cleanup.sh scan

# Process suspicious accounts interactively
kawaiisec-account-cleanup.sh cleanup

# Create configuration files
kawaiisec-account-cleanup.sh config

# Show help
kawaiisec-account-cleanup.sh --help
```

### Options
```bash
--dry-run           # Show what would be done (default)
--force             # Actually remove/lock accounts
--lock-only         # Lock accounts instead of removing
--interactive       # Prompt for each account (default)
--non-interactive   # No prompts (for automation)
--config FILE       # Use custom configuration file
--whitelist FILE    # Use custom whitelist file
```

### Examples
```bash
# Safe scan
kawaiisec-account-cleanup.sh

# Interactive removal
kawaiisec-account-cleanup.sh --force cleanup

# Lock accounts instead of removing
kawaiisec-account-cleanup.sh --lock-only --force cleanup

# Automated removal (no prompts)
kawaiisec-account-cleanup.sh --non-interactive --force cleanup

# Use custom whitelist
kawaiisec-account-cleanup.sh --whitelist /path/to/whitelist.txt scan
```

## Makefile Integration

### Available Targets

```bash
# Safe scanning
make account-cleanup                # Dry-run scan
make account-cleanup-status         # Show system status

# Configuration
make account-cleanup-config         # Create config files

# Account processing (requires confirmation)
make account-cleanup-force          # Remove accounts permanently
make account-cleanup-lock           # Lock accounts (safer)
```

### Pre-Release Integration

Add account cleanup to your release process:

```bash
# In your build/release script
make account-cleanup-config         # Ensure config exists
make account-cleanup                # Scan for issues
# Review results, update whitelist if needed
make account-cleanup-force          # Clean up before packaging
```

## Logging and Reporting

### Log File
Location: `/var/log/kawaiisec-account-cleanup.log`

Contains detailed information about:
- All scan results
- Account processing actions
- Errors and warnings
- Timestamps for all operations

### Report Generation
Each run generates a comprehensive report in `/tmp/` with:
- Summary statistics
- Configuration details
- List of suspicious patterns checked
- Whitelist status
- Detailed log excerpts

Reports are also copied to the user's home directory when run with sudo.

## Safety Features

### 1. Dry-Run by Default
- No changes made without explicit `--force` flag
- Shows exactly what would be done
- Allows review before actual changes

### 2. Whitelist Protection
- Prevents removal of legitimate accounts
- Easy to configure and maintain
- Checked before any account processing

### 3. Interactive Confirmation
- Prompts for each account by default
- Shows account details before processing
- Options: Yes/No/Skip/Quit

### 4. Comprehensive Logging
- All actions logged with timestamps
- Detailed account information recorded
- Error tracking and reporting

### 5. Multiple Processing Options
- **Remove**: Permanently delete account and home directory
- **Lock**: Disable login but preserve data
- **Skip**: Leave account unchanged

## Configuration Files

### Main Configuration
File: `/etc/kawaiisec/account-cleanup.conf`

```bash
# KawaiiSec OS Account Cleanup Configuration
# Default behavior
DRY_RUN=true
FORCE_REMOVAL=false
INTERACTIVE=true
LOCK_ONLY=false

# Logging
LOG_FILE="/var/log/kawaiisec-account-cleanup.log"

# Additional suspicious patterns
CUSTOM_SUSPICIOUS_PATTERNS=(
    # Add custom patterns here
)
```

### Account Whitelist
File: `/etc/kawaiisec/account_whitelist.txt`

Simple text file with one account name per line. Comments start with `#`.

## Integration with Package Building

### Debian Package Integration
The account cleanup system is automatically configured during package installation:

1. Configuration files are created
2. Default whitelist is installed
3. Initial scan is performed
4. System is ready for use

### CI/CD Integration
Example workflow for automated testing:

```yaml
# Example GitHub Actions step
- name: Test Account Cleanup
  run: |
    # Create test accounts
    sudo useradd demo-test
    sudo useradd student-test
    sudo useradd legitimate-user
    
    # Add legitimate account to whitelist
    echo "legitimate-user" | sudo tee -a /etc/kawaiisec/account_whitelist.txt
    
    # Run cleanup
    sudo kawaiisec-account-cleanup.sh --non-interactive --force cleanup
    
    # Verify results
    ! id demo-test 2>/dev/null      # Should be removed
    ! id student-test 2>/dev/null   # Should be removed
    id legitimate-user              # Should remain
```

## Troubleshooting

### Common Issues

#### 1. Script Not Found
```bash
# Error: Account cleanup script not found
# Solution: Ensure script is executable and in PATH
chmod +x scripts/kawaiisec-account-cleanup.sh
sudo cp scripts/kawaiisec-account-cleanup.sh /usr/local/bin/
```

#### 2. Permission Denied
```bash
# Error: Permission denied
# Solution: Run with sudo for account management
sudo kawaiisec-account-cleanup.sh scan
```

#### 3. Legitimate Account Removed
```bash
# Problem: Important account was accidentally removed
# Solution: Add to whitelist and restore from backup
echo "important-account" >> /etc/kawaiisec/account_whitelist.txt
# Restore account from system backup
```

#### 4. No Accounts Found
```bash
# If no suspicious accounts are found but you expect some:
# 1. Check if accounts have UID >= 1000
# 2. Verify account names match suspicious patterns
# 3. Check if accounts are already in whitelist
kawaiisec-account-cleanup.sh --help  # Review patterns
```

### Log Analysis
```bash
# View recent activity
tail -f /var/log/kawaiisec-account-cleanup.log

# Search for specific account
grep "username" /var/log/kawaiisec-account-cleanup.log

# View error messages
grep "ERROR" /var/log/kawaiisec-account-cleanup.log
```

## Best Practices

### 1. Pre-Release Checklist
- [ ] Review and update account whitelist
- [ ] Run account scan and review results  
- [ ] Test whitelist protection
- [ ] Run cleanup in dry-run mode first
- [ ] Verify all legitimate accounts are preserved
- [ ] Check log files for any issues
- [ ] Generate and review cleanup report

### 2. Whitelist Management
- Keep whitelist up-to-date with legitimate accounts
- Document why each account is whitelisted
- Review whitelist regularly
- Use descriptive account names to avoid false positives

### 3. Testing Strategy
- Always test in a non-production environment first
- Create test accounts matching suspicious patterns
- Verify whitelist protection works correctly
- Test both interactive and non-interactive modes

### 4. Automation Integration
- Include account cleanup in CI/CD pipelines
- Run scans regularly during development
- Automate whitelist updates when adding legitimate accounts
- Generate reports for security audits

## Security Considerations

### 1. Account Verification
- Verify account ownership before removal
- Check for active processes or services
- Review home directory contents
- Confirm accounts are actually unauthorized

### 2. Data Preservation
- Consider using lock mode instead of removal for sensitive accounts
- Backup important data before account removal
- Document removal decisions for audit trails

### 3. System Impact
- Be aware that removing accounts may affect running services
- Check for cron jobs, systemd services, or other dependencies
- Test account removal in staging environment first

## Contributing

### Adding Suspicious Patterns
To add new suspicious account patterns:

1. Edit the script directly, or
2. Add patterns to configuration file:
```bash
# In /etc/kawaiisec/account-cleanup.conf
CUSTOM_SUSPICIOUS_PATTERNS=(
    "newpattern"
    "another-pattern"
)
```

### Reporting Issues
When reporting issues, include:
- Command used
- Expected vs actual behavior
- Relevant log entries
- System configuration details

### Community Guidelines
- Test all changes thoroughly
- Update documentation for new features
- Follow existing code style and patterns
- Include examples in documentation

## Related Documentation

- [KawaiiSec OS Quick Start Guide](quick-start-lab-guide.md)
- [Hardware Compatibility](hardware_matrix.md)
- [Performance Optimization](performance.md)
- [Firewall Configuration](firewall.md)

## Support

- **Documentation**: This file and related docs
- **Community Forum**: https://forum.kawaiisec.com
- **Issue Tracker**: GitHub Issues
- **Discord**: #system-security channel

---

*This system helps maintain the security and integrity of KawaiiSec OS by ensuring no unauthorized demo or test accounts remain in production deployments. Always review results and test thoroughly before deploying to production systems.* 🌸 