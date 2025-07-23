---
id: setup
title: Getting Started
sidebar_label: Setup
---

# 🚀 Getting Started with KawaiiSec OS

## 📋 Prerequisites

Before installing KawaiiSec OS, make sure you have:
- A computer with at least 4GB RAM
- 20GB of free disk space
- USB drive (8GB or larger) for live boot
- Internet connection for updates

## 💾 Installation Methods

### Method 1: Live USB Boot (Recommended)

1. **Download the ISO**
   ```bash
   # Download the latest KawaiiSec OS ISO
   wget https://github.com/dhruvabisht/KawaiiSec-OS/releases/latest/download/kawaiisec-os.iso
   ```

2. **Create Bootable USB**
   ```bash
   # Using dd command (Linux/macOS)
   sudo dd if=kawaiisec-os.iso of=/dev/sdX bs=4M status=progress
   
   # Replace /dev/sdX with your USB device
   # Be very careful with this command!
   ```

3. **Boot from USB**
   - Restart your computer
   - Enter BIOS/UEFI (usually F2, F12, or Del)
   - Select USB as boot device
   - Choose "Try KawaiiSec OS" or "Install KawaiiSec OS"

### Method 2: Virtual Machine

1. **Download the ISO** (same as above)

2. **Create VM**
   - Open VirtualBox or VMware
   - Create new VM with:
     - 4GB RAM minimum
     - 20GB disk space
     - Enable virtualization in BIOS

3. **Install in VM**
   - Attach the ISO to the VM
   - Boot and follow installation wizard

## 🎨 First Boot Setup

After installation, you'll be greeted with the KawaiiSec OS welcome screen:

1. **Choose Your Theme**
   - Select from various pastel themes
   - Customize colors and icons

2. **Update System**
   ```bash
   sudo apt update && sudo apt upgrade
   ```

3. **Install Additional Tools**
   ```bash
   # Install extra security tools
   sudo kawaiisec-toolkit install
   ```

## 🔧 Configuration

### Customizing Your Desktop

```bash
# Change theme
kawaiisec-theme set pastel-pink

# Customize terminal
kawaiisec-terminal customize

# Set up workspace layout
kawaiisec-workspace setup
```

### Security Tool Configuration

```bash
# Configure network tools
sudo kawaiisec-network setup

# Set up password databases
kawaiisec-password setup

# Configure scanning profiles
kawaiisec-scan configure
```

## 🆘 Troubleshooting

### Common Issues

**USB Boot Not Working**
- Check if Secure Boot is disabled in BIOS
- Try different USB ports
- Verify ISO download integrity

**Performance Issues**
- Increase VM RAM allocation
- Enable virtualization in BIOS
- Close unnecessary applications

**Network Problems**
```bash
# Reset network configuration
sudo kawaiisec-network reset

# Check network status
kawaiisec-network status
```

## 📚 Next Steps

Now that you have KawaiiSec OS installed:

1. **Explore the Tools**: Check out the pre-installed security tools
2. **Read the Documentation**: Learn about each tool's capabilities
3. **Join the Community**: Connect with other KawaiiSec users
4. **Practice Safely**: Use only on systems you own or have permission to test

## 🆘 Need Help?

- 📖 Check our [documentation](/)
- 💬 Join our [Discord server](https://discord.gg/kawaiisec)
- 🐛 Report bugs on [GitHub](https://github.com/dhruvabisht/KawaiiSec-OS/issues)
- 📧 Email us at support@kawaiisec.os

---

*Remember: With great power comes great responsibility. Always use KawaiiSec OS ethically and legally! 🌸* 