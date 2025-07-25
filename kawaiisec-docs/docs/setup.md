---
id: setup
title: Getting Started
sidebar_label: Setup
---

# 🚀 Getting Started with KawaiiSec OS

## 📋 Prerequisites

Before installing KawaiiSec OS, make sure you have:
- A computer with at least 4GB RAM (8GB recommended)
- 20GB of free disk space (50GB recommended for full toolset)
- USB drive (8GB or larger) for live boot
- Internet connection for updates and additional tools
- UEFI or Legacy BIOS support

## 💾 Download KawaiiSec OS

### Latest Release: v2025.07.25

**Direct Download Links:**
- **ISO File**: [kawaiisec-os-2025.07.25-amd64.iso](https://github.com/dhruvabisht/KawaiiSec-OS/releases/latest/download/kawaiisec-os-2025.07.25-amd64.iso) (3.3GB)
- **SHA256 Checksum**: [kawaiisec-os-2025.07.25-amd64.iso.sha256](https://github.com/dhruvabisht/KawaiiSec-OS/releases/latest/download/kawaiisec-os-2025.07.25-amd64.iso.sha256)
- **MD5 Checksum**: [kawaiisec-os-2025.07.25-amd64.iso.md5](https://github.com/dhruvabisht/KawaiiSec-OS/releases/latest/download/kawaiisec-os-2025.07.25-amd64.iso.md5)

### 🔍 Verify Your Download

**On Linux/macOS:**
```bash
# Download the ISO
wget https://github.com/dhruvabisht/KawaiiSec-OS/releases/latest/download/kawaiisec-os-2025.07.25-amd64.iso

# Download checksums
wget https://github.com/dhruvabisht/KawaiiSec-OS/releases/latest/download/kawaiisec-os-2025.07.25-amd64.iso.sha256
wget https://github.com/dhruvabisht/KawaiiSec-OS/releases/latest/download/kawaiisec-os-2025.07.25-amd64.iso.md5

# Verify SHA256
sha256sum -c kawaiisec-os-2025.07.25-amd64.iso.sha256

# Verify MD5
md5sum -c kawaiisec-os-2025.07.25-amd64.iso.md5
```

**On Windows:**
```powershell
# Download using PowerShell
Invoke-WebRequest -Uri "https://github.com/dhruvabisht/KawaiiSec-OS/releases/latest/download/kawaiisec-os-2025.07.25-amd64.iso" -OutFile "kawaiisec-os-2025.07.25-amd64.iso"

# Verify using PowerShell
Get-FileHash -Algorithm SHA256 kawaiisec-os-2025.07.25-amd64.iso
Get-FileHash -Algorithm MD5 kawaiisec-os-2025.07.25-amd64.iso
```

## 💾 Installation Methods

### Method 1: Live USB Boot (Recommended)

#### Step 1: Create Bootable USB

**On Linux:**
```bash
# List USB devices (be very careful!)
lsblk

# Create bootable USB (replace /dev/sdX with your USB device)
sudo dd if=kawaiisec-os-2025.07.25-amd64.iso of=/dev/sdX bs=4M status=progress conv=fdatasync

# Verify the USB was written correctly
sudo dd if=/dev/sdX of=verify.iso bs=4M count=1
diff kawaiisec-os-2025.07.25-amd64.iso verify.iso
```

**On macOS:**
```bash
# List USB devices
diskutil list

# Unmount USB (replace /dev/diskX with your USB device)
diskutil unmountDisk /dev/diskX

# Create bootable USB
sudo dd if=kawaiisec-os-2025.07.25-amd64.iso of=/dev/diskX bs=4M

# Eject USB when done
diskutil eject /dev/diskX
```

**On Windows:**
- Use [Rufus](https://rufus.ie/) (recommended)
- Use [Balena Etcher](https://www.balena.io/etcher/)
- Use [Win32 Disk Imager](https://sourceforge.net/projects/win32diskimager/)

#### Step 2: Boot from USB

1. **Restart your computer**
2. **Enter BIOS/UEFI** (usually F2, F12, Del, or Esc)
3. **Disable Secure Boot** (if enabled)
4. **Set USB as first boot device**
5. **Save and exit BIOS**
6. **Choose boot option:**
   - "Try KawaiiSec OS" (Live mode)
   - "Install KawaiiSec OS" (Install to disk)

### Method 2: Virtual Machine

#### VMware Workstation/Player
1. **Create new VM:**
   - Type: Linux
   - Version: Debian 12 64-bit
   - Memory: 4GB minimum (8GB recommended)
   - Disk: 50GB minimum
   - Enable virtualization in BIOS

2. **Attach ISO and boot**

#### VirtualBox
1. **Create new VM:**
   - Type: Linux
   - Version: Debian 64-bit
   - Memory: 4GB minimum
   - Disk: 50GB minimum
   - Enable PAE/NX if available

2. **Attach ISO and boot**

#### Parallels (macOS)
1. **Create new VM:**
   - Select "Install Windows or other OS"
   - Choose "Linux" → "Debian"
   - Attach ISO file
   - Allocate 4GB+ RAM and 50GB+ disk

### Method 3: Dual Boot

**⚠️ Warning: This will modify your existing system!**

1. **Backup your data** before proceeding
2. **Create free space** on your hard drive (50GB+)
3. **Boot from USB** and choose "Install KawaiiSec OS"
4. **Select "Install alongside existing OS"**
5. **Follow the installation wizard**

## 🎨 First Boot Setup

### Welcome to KawaiiSec OS! 🌸

After installation, you'll be greeted with the KawaiiSec OS welcome screen:

#### 1. Initial Configuration
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install additional security tools
sudo kawaiisec-toolkit install

# Set up user preferences
kawaiisec-user-setup
```

#### 2. Choose Your Theme
```bash
# List available themes
kawaiisec-theme list

# Set your preferred theme
kawaiisec-theme set pastel-pink
kawaiisec-theme set dreamy-clouds
kawaiisec-theme set kawaii-cafe
kawaiisec-theme set retro-terminal
```

#### 3. Configure Security Tools
```bash
# Set up network scanning tools
sudo kawaiisec-network setup

# Configure password databases
kawaiisec-password setup

# Set up scanning profiles
kawaiisec-scan configure

# Initialize lab environment
kawaiisec-lab init
```

## 🔧 Advanced Configuration

### Customizing Your Desktop

```bash
# Change desktop environment settings
kawaiisec-desktop customize

# Customize terminal appearance
kawaiisec-terminal customize

# Set up workspace layout
kawaiisec-workspace setup

# Configure system sounds
kawaiisec-audio setup
```

### Security Tool Configuration

```bash
# Configure firewall rules
sudo kawaiisec-firewall setup

# Set up intrusion detection
sudo kawaiisec-ids configure

# Configure logging and monitoring
sudo kawaiisec-logging setup

# Set up automated security scans
sudo kawaiisec-automation setup
```

### Lab Environment Setup

```bash
# Initialize Docker lab environment
kawaiisec-lab docker init

# Set up vulnerable machines
kawaiisec-lab setup dvwa
kawaiisec-lab setup juice-shop
kawaiisec-lab setup metasploitable

# Configure network topology
kawaiisec-lab network setup
```

## 🆘 Troubleshooting

### Common Issues

#### USB Boot Not Working
```bash
# Check USB device
lsblk  # Linux
diskutil list  # macOS

# Verify ISO integrity
sha256sum -c kawaiisec-os-2025.07.25-amd64.iso.sha256

# Try different USB ports or USB drives
# Disable Secure Boot in BIOS/UEFI
# Enable Legacy Boot if available
```

#### Performance Issues
```bash
# Check system resources
htop
free -h
df -h

# Optimize VM settings
# Increase RAM allocation to 8GB+
# Enable virtualization in BIOS
# Close unnecessary applications
```

#### Network Problems
```bash
# Reset network configuration
sudo kawaiisec-network reset

# Check network status
kawaiisec-network status

# Configure network manually
sudo nano /etc/network/interfaces
```

#### Audio Issues
```bash
# Test audio system
kawaiisec-audio test

# Configure audio settings
kawaiisec-audio setup

# Install audio codecs if needed
sudo apt install ubuntu-restricted-extras
```

### Getting Help

```bash
# System information
kawaiisec-help system

# Tool documentation
kawaiisec-help tools

# Network diagnostics
kawaiisec-help network

# Lab setup help
kawaiisec-help lab
```

## 📚 Next Steps

Now that you have KawaiiSec OS installed:

1. **📖 Read the Documentation**: Explore our comprehensive guides
2. **🔧 Explore the Tools**: Check out the pre-installed security tools
3. **🧪 Practice Safely**: Use our lab environment for learning
4. **👥 Join the Community**: Connect with other KawaiiSec users
5. **🎯 Set Up Your Lab**: Configure vulnerable machines for practice

## 🆘 Need Help?

- 📖 **Documentation**: [docs.kawaiisec.os](https://docs.kawaiisec.os)
- 💬 **Discord**: [Join our server](https://discord.gg/kawaiisec)
- 🐛 **GitHub Issues**: [Report bugs](https://github.com/dhruvabisht/KawaiiSec-OS/issues)
- 📧 **Email**: support@kawaiisec.os
- 📱 **Telegram**: [@KawaiiSecOS](https://t.me/KawaiiSecOS)

## 🎯 System Requirements

### Minimum Requirements
- **CPU**: 2-core processor (64-bit)
- **RAM**: 4GB
- **Storage**: 20GB free space
- **Graphics**: 1024x768 resolution
- **Network**: Internet connection

### Recommended Requirements
- **CPU**: 4-core processor (64-bit)
- **RAM**: 8GB or more
- **Storage**: 50GB+ free space
- **Graphics**: 1920x1080 resolution
- **Network**: High-speed internet
- **USB**: 3.0 port for faster boot

---

*Remember: With great power comes great responsibility. Always use KawaiiSec OS ethically and legally! 🌸*

**Stay cute, stay secure! 💖** 