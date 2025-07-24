# 🌸 KawaiiSec OS Release Documentation

This document describes the complete process for building, validating, and releasing KawaiiSec OS ISO images using our automated live-build system.

## 📋 Table of Contents

- [System Overview](#system-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Build System Architecture](#build-system-architecture)
- [Manual Building](#manual-building)
- [Automated CI/CD](#automated-cicd)
- [Validation & Testing](#validation--testing)
- [Release Process](#release-process)
- [Troubleshooting](#troubleshooting)

## System Overview

The KawaiiSec OS ISO build system is based on Debian live-build with extensive customizations:

- **Base System**: Debian Bookworm (12.x)
- **Desktop Environment**: XFCE with kawaii theming
- **Security Tools**: Comprehensive pentesting and forensics toolkit
- **Lab Environments**: Pre-configured vulnerable applications
- **Build System**: Automated with Debian live-build
- **CI/CD**: GitHub Actions with artifact management
- **Validation**: Multi-stage ISO verification and boot testing

## Prerequisites

### System Requirements

**Host System:**
- Ubuntu 20.04+ or Debian 11+ (recommended)
- 8GB RAM minimum (16GB recommended)
- 20GB free disk space minimum
- Fast internet connection
- sudo privileges

**Software Dependencies:**
```bash
sudo apt update
sudo apt install -y \
  live-build \
  debootstrap \
  xorriso \
  isolinux \
  syslinux-utils \
  memtest86+ \
  dosfstools \
  squashfs-tools \
  qemu-system-x86 \
  qemu-utils
```

### Recommended Tools
```bash
# For advanced validation
sudo apt install -y \
  genisoimage \
  isomd5sum \
  file \
  cdrtools

# For testing
sudo apt install -y \
  virtualbox \
  vagrant
```

## Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/dhruvabisht/KawaiiSec-OS.git
cd KawaiiSec-OS
```

### 2. Build ISO
```bash
# Simple build
make iso

# Or use the build script directly
./build-iso.sh
```

### 3. Validate
```bash
# Validate the built ISO
make validate-iso

# Or use the validation script directly
./scripts/validate-iso.sh
```

### 4. Test
```bash
# Test in QEMU
make test-iso-qemu

# Or manually
qemu-system-x86_64 -cdrom kawaiisec-os-*.iso -m 2048
```

## Build System Architecture

### Directory Structure
```
KawaiiSec-OS/
├── auto/                          # Live-build automation scripts
│   ├── config                     # Build configuration
│   ├── clean                      # Cleanup script
│   └── build                      # Build execution
├── config/                        # Live-build configuration
│   ├── package-lists/             # Package inclusion lists
│   │   ├── kawaiisec.list.chroot  # Core packages
│   │   ├── security-extras.list.chroot
│   │   └── development.list.chroot
│   └── bootloaders/               # Boot configuration
├── hooks/                         # Custom build hooks
│   └── normal/
│       ├── 0010-kawaiisec-branding.hook.chroot
│       ├── 0020-kawaiisec-security.hook.chroot
│       └── 0030-kawaiisec-cleanup.hook.chroot
├── includes.chroot/               # Files to include in chroot
│   ├── usr/local/bin/             # Custom scripts
│   ├── etc/kawaiisec/             # Configuration files
│   ├── etc/systemd/system/        # System services
│   └── usr/share/kawaiisec/       # Assets and resources
├── build-iso.sh                   # Main build script
├── scripts/validate-iso.sh        # ISO validation
└── .github/workflows/iso-release.yml  # CI/CD pipeline
```

### Build Process Flow

1. **Environment Setup**: Clean previous builds, prepare directories
2. **Configuration**: Apply live-build settings (Debian version, packages, etc.)
3. **Package Installation**: Install base system and security tools
4. **Customization Hooks**: Apply branding, configure tools, setup labs
5. **ISO Generation**: Create bootable hybrid ISO image
6. **Validation**: Verify ISO structure, boot capability, checksums
7. **Artifacts**: Generate checksums, build reports, validation reports

### Package Categories

**Core System** (`kawaiisec.list.chroot`):
- Base Debian system with live-boot
- XFCE desktop environment
- Essential system utilities
- Network and development tools

**Security Tools** (`security-extras.list.chroot`):
- Penetration testing tools (nmap, metasploit, burp suite)
- Forensics tools (autopsy, volatility, sleuthkit)
- OSINT tools (recon-ng, theharvester)
- Wireless security tools (aircrack-ng, kismet)

**Development Tools** (`development.list.chroot`):
- Programming languages (Python, Go, Ruby)
- Debugging tools (gdb, valgrind, strace)
- Version control and editors
- Database clients

## Manual Building

### Basic Build
```bash
# Build with default settings
./build-iso.sh

# Build with specific version
./build-iso.sh -v 2024.01.15

# Build with custom options
./build-iso.sh --no-cleanup -v custom-build
```

### Build Options
```bash
./build-iso.sh [options]

Options:
  -h, --help          Show help message
  -c, --clean         Clean previous builds (default: true)
  -v, --version VER   Set version string (default: YYYY.MM.DD)
  -q, --quiet         Reduce output verbosity
  --no-cleanup        Don't cleanup on exit (for debugging)
  --validate-only     Only validate existing ISO

Environment Variables:
  VERSION            Override version string
  CLEAN_BUILD        Set to false to skip cleaning
  CLEANUP_ON_EXIT    Set to false to keep build artifacts
```

### Advanced Customization

**Adding Packages:**
```bash
# Edit package lists
vim config/package-lists/kawaiisec.list.chroot

# Add new package list
echo "custom-tool" > config/package-lists/custom.list.chroot
```

**Custom Scripts:**
```bash
# Add to includes.chroot
cp my-script.sh includes.chroot/usr/local/bin/
chmod +x includes.chroot/usr/local/bin/my-script.sh
```

**Build Hooks:**
```bash
# Create custom hook
cat > hooks/normal/9999-custom.hook.chroot << 'EOF'
#!/bin/bash
echo "Running custom configuration..."
# Your customizations here
EOF
chmod +x hooks/normal/9999-custom.hook.chroot
```

## Automated CI/CD

### GitHub Actions Workflow

The CI/CD pipeline automatically builds and releases ISOs:

**Triggers:**
- Push to `main` or `develop` branches
- New version tags (`v*`)
- Manual workflow dispatch
- Pull requests (build only)

**Build Matrix:**
- Architecture: AMD64 (with ARM64 planned)
- Base: Debian Bookworm

**Workflow Steps:**
1. **Environment Setup**: Install live-build dependencies
2. **Build Configuration**: Set version, prepare build environment
3. **ISO Build**: Execute automated build with timeout protection
4. **Validation**: Comprehensive ISO verification
5. **Testing**: Quick boot test with QEMU
6. **Artifacts**: Upload ISO, checksums, build reports
7. **Release**: Create GitHub release for tags

### Manual CI Trigger
```bash
# Trigger manual build via GitHub CLI
gh workflow run "🌸 KawaiiSec OS ISO Release" \
  --field build_iso=true \
  --field create_release=false \
  --field version_override="2024.01.15-custom"
```

### Accessing Build Artifacts

**GitHub Actions Artifacts:**
- Navigate to Actions → Latest workflow run
- Download artifacts from the "Artifacts" section
- Available for 30 days

**Release Assets:**
- Visit Releases page
- Download ISO, checksums, and build reports
- Permanent storage for tagged releases

## Validation & Testing

### Validation Levels

**Quick Validation:**
```bash
./scripts/validate-iso.sh --quick
```
- File properties check
- ISO structure verification
- Basic integrity validation

**Full Validation:**
```bash
./scripts/validate-iso.sh
```
- Complete file system verification
- Boot capability testing
- Checksum validation
- Content analysis

**Custom Validation:**
```bash
# Skip boot test
./scripts/validate-iso.sh --skip-boot-test

# Validate specific file
./scripts/validate-iso.sh -f kawaiisec-os-2024.01.15-amd64.iso
```

### Testing Methods

**QEMU Testing:**
```bash
# Quick test
make test-iso-qemu

# Manual QEMU with specific options
qemu-system-x86_64 \
  -cdrom kawaiisec-os-*.iso \
  -m 4096 \
  -enable-kvm \
  -netdev user,id=net0 \
  -device rtl8139,netdev=net0
```

**VirtualBox Testing:**
```bash
# Create VM and attach ISO
VBoxManage createvm --name "KawaiiSec-Test" --register
VBoxManage modifyvm "KawaiiSec-Test" --memory 4096 --cpus 2
VBoxManage storagectl "KawaiiSec-Test" --name "IDE" --add ide
VBoxManage storageattach "KawaiiSec-Test" --storagectl "IDE" \
  --port 0 --device 0 --type dvddrive --medium kawaiisec-os-*.iso
VBoxManage startvm "KawaiiSec-Test"
```

**Physical Hardware Testing:**
```bash
# Create bootable USB
sudo dd if=kawaiisec-os-*.iso of=/dev/sdX bs=4M status=progress

# Or use specialized tools
sudo unetbootin isofile="kawaiisec-os-*.iso" usbdev="/dev/sdX"
```

### Validation Reports

The validation system generates comprehensive reports:

**ISO Validation Report:**
```
🌸 KawaiiSec OS ISO Validation Report 🌸
========================================

Validation Date: 2024-01-15 12:00:00
Validator: builder@kawaiisec-build

ISO Information:
- File: kawaiisec-os-2024.01.15-amd64.iso
- Size: 2.8GB
- SHA256: a1b2c3d4e5f6...

Validation Results:
✅ File Properties: PASSED
✅ ISO Structure: PASSED  
✅ Contents Validation: PASSED
✅ Checksum Validation: PASSED
✅ Boot Test: PASSED

Overall Status: SUCCESS ✅
```

## Release Process

### Version Numbering

**Stable Releases:** `YYYY.MM.DD` (e.g., `2024.01.15`)
**Development Builds:** `YYYY.MM.DD-dev` (e.g., `2024.01.15-dev`)
**Release Candidates:** `YYYY.MM.DD-rc1` (e.g., `2024.01.15-rc1`)
**Custom Builds:** `YYYY.MM.DD-custom` (e.g., `2024.01.15-custom`)

### Release Workflow

1. **Pre-Release Testing:**
   ```bash
   # Build and test locally
   make release-iso
   make test-iso-qemu
   
   # Manual testing checklist
   # - Boot process
   # - Desktop environment
   # - Security tools
   # - Lab environments
   # - Network connectivity
   ```

2. **Create Release:**
   ```bash
   # Tag release
   git tag -a v2024.01.15 -m "KawaiiSec OS v2024.01.15"
   git push origin v2024.01.15
   
   # CI will automatically build and create GitHub release
   ```

3. **Post-Release:**
   ```bash
   # Update documentation
   # Announce on social media
   # Update download links
   # Monitor for issues
   ```

### Release Checklist

**Pre-Release:**
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Version numbers updated
- [ ] Changelog prepared
- [ ] Security tools verified
- [ ] Lab environments tested

**Release:**
- [ ] Git tag created
- [ ] CI build successful
- [ ] ISO validation passed
- [ ] GitHub release created
- [ ] Release notes published

**Post-Release:**
- [ ] Download links updated
- [ ] Community notification sent
- [ ] Documentation site updated
- [ ] Mirror sites notified
- [ ] Social media announcement

## Troubleshooting

### Common Build Issues

**Insufficient Disk Space:**
```bash
# Check available space
df -h

# Clean build artifacts
make iso-clean

# Clean Docker (if applicable)
docker system prune -af
```

**Package Installation Failures:**
```bash
# Check package lists for typos
grep -n "^[^#]" config/package-lists/*.list.chroot

# Test package availability
apt-cache search package-name

# Check Debian repository status
curl -I http://deb.debian.org/debian/
```

**Hook Execution Errors:**
```bash
# Check hook permissions
find hooks -name "*.hook.chroot" -exec ls -la {} \;

# Make hooks executable
find hooks -name "*.hook.chroot" -exec chmod +x {} \;

# Debug hook execution
./build-iso.sh --no-cleanup -v debug
# Check build/chroot.log for details
```

**Live-Build Configuration Issues:**
```bash
# Reset live-build configuration
lb clean
./auto/config

# Check configuration
lb config --help

# Verify auto scripts
chmod +x auto/config auto/clean auto/build
```

### Validation Failures

**ISO Mount Failures:**
```bash
# Check ISO integrity
file kawaiisec-os-*.iso

# Test mount manually
sudo mkdir -p /mnt/test-iso
sudo mount -o loop kawaiisec-os-*.iso /mnt/test-iso
ls -la /mnt/test-iso
sudo umount /mnt/test-iso
```

**Boot Test Failures:**
```bash
# Skip boot test if QEMU unavailable
SKIP_BOOT_TEST=true ./scripts/validate-iso.sh

# Test with different QEMU options
qemu-system-x86_64 -cdrom kawaiisec-os-*.iso -m 1024 -nographic
```

**Checksum Mismatches:**
```bash
# Regenerate checksums
sha256sum kawaiisec-os-*.iso > kawaiisec-os-*.iso.sha256
md5sum kawaiisec-os-*.iso > kawaiisec-os-*.iso.md5

# Verify file integrity
sha256sum -c kawaiisec-os-*.iso.sha256
```

### CI/CD Issues

**GitHub Actions Failures:**
```yaml
# Check workflow logs in GitHub Actions tab
# Common issues:
# - Timeout (increase BUILD_TIMEOUT)
# - Disk space (clean more aggressively)
# - Network issues (retry failed steps)
```

**Artifact Upload Issues:**
```bash
# Check artifact size limits
# GitHub Actions: 10GB per workflow run
# Releases: 2GB per file

# Compress if needed
gzip kawaiisec-os-*.iso
```

### Performance Optimization

**Faster Builds:**
```bash
# Use more CPU cores
export MAKEFLAGS="-j$(nproc)"

# Cache APT packages
sudo apt-get install apt-cacher-ng

# Use local mirror
# Edit auto/config to use local Debian mirror
```

**Reduced ISO Size:**
```bash
# Remove documentation packages
echo "# Documentation" > config/package-lists/docs.list.chroot
echo "man-db-" >> config/package-lists/docs.list.chroot

# Remove language packs
echo "# Locales" > config/package-lists/locales.list.chroot
echo "locales-all-" >> config/package-lists/locales.list.chroot
```

## Support and Resources

**Documentation:**
- [Debian Live Manual](https://live-team.pages.debian.net/live-manual/)
- [Live-Build Documentation](https://manpages.debian.org/testing/live-build/lb.1.en.html)
- [KawaiiSec Documentation](https://github.com/dhruvabisht/KawaiiSec-OS/tree/main/docs)

**Community:**
- GitHub Issues: Report bugs and request features
- GitHub Discussions: Ask questions and share experiences
- Pull Requests: Contribute improvements

**Contact:**
- Project Repository: https://github.com/dhruvabisht/KawaiiSec-OS
- Issue Tracker: https://github.com/dhruvabisht/KawaiiSec-OS/issues

---

💖 **Happy building with kawaii vibes!** 🌸 