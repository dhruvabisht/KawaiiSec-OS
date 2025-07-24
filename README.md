# 🌸 KawaiiSec OS - Comprehensive Penetration Testing Distribution

KawaiiSec OS is a Kali Linux-based educational distribution designed for cybersecurity learning and teaching. It provides a comprehensive collection of penetration testing tools, automated lab environments, and advanced storage management features.

## ✨ Features

### 🔧 Security Tools
- **130+ security tools** across all major categories
- Network discovery and scanning (Nmap, Masscan, Netdiscover)
- Vulnerability assessment (OpenVAS, Nikto, WPScan)  
- Exploitation frameworks (Metasploit, SET, BeEF)
- Web application testing (Burp Suite, OWASP ZAP, SQLMap)
- Wireless security (Aircrack-ng, Wifite, Kismet)
- Password cracking (Hashcat, John, Hydra)
- Digital forensics (Sleuthkit, Volatility, Autopsy)
- Reverse engineering (Ghidra, Radare2)
- OSINT tools (Maltego, theHarvester, Recon-ng)

### 🏠 Lab Environments
- **One-command deployment** of vulnerable applications
- OWASP Juice Shop, DVWA, Metasploitable3
- Docker and Vagrant support
- Automated network topology setup
- Educational scenarios and tutorials

### 🗄️ Advanced Storage Management
- **First-boot setup wizard** with user account creation
- **Automated Btrfs snapshots** with configurable retention
- **OverlayFS support** for immutable root filesystem
- **Disk quota management** with monitoring and alerts
- **Automated system cleanup** and maintenance
- **Comprehensive logging** and reporting

### 🧹 Account Security Management
- **Demo/test account cleanup** system with automated detection
- **Whitelist protection** for legitimate accounts
- **Safe dry-run mode** with detailed reporting before changes
- **Multiple processing options** (remove, lock, or skip accounts)
- **Pre-release security scanning** and documentation
- **CI/CD integration** for automated account auditing

### 🖥️ Hardware Compatibility System
- **Comprehensive hardware testing** across virtualization and physical systems
- **Automated compatibility reports** for community contribution
- **Hardware compatibility matrix** with detailed test results
- **CI/CD integration** for continuous compatibility validation
- **Community-driven testing** with easy contribution workflow

## 🌸 ISO Building

KawaiiSec OS now includes a fully automated, reproducible ISO packaging system:

```bash
# Install live-build dependencies
sudo apt install live-build debootstrap xorriso isolinux

# Build KawaiiSec OS ISO
make iso

# Validate the built ISO
make validate-iso

# Test in QEMU virtual machine
make test-iso-qemu
```

**Complete Documentation:** See [`docs/release.md`](docs/release.md) for comprehensive build instructions, customization options, and troubleshooting.

## 🎯 Recent Updates

### ✨ New in Latest Version
- **🌸 Complete ISO Build System** - Automated, reproducible live ISO generation
- **🛠️ Live-Build Integration** - Debian live-build with custom hooks and configurations  
- **✅ ISO Validation Suite** - Comprehensive post-build verification and testing
- **🚀 GitHub Actions CI/CD** - Automated building, testing, and releases
- **📊 Build Reporting** - Detailed build logs, validation reports, and artifact management
- **🖥️ QEMU Integration** - Automated boot testing and VM validation
- **📦 Makefile Targets** - Easy `make iso`, `make validate-iso`, `make test-iso-qemu` commands

## 🚀 Quick Start

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/KawaiiSec-OS.git
   cd KawaiiSec-OS
   ```

2. **Build and install:**
   ```bash
   make all
   make install-package
   ```

3. **First boot:**
   - The first-boot wizard will automatically run on first startup
   - Create your user account and configure basic settings
   - Storage management features will be initialized

### Hardware Compatibility Testing

Before installation, check if your hardware is supported:

1. **View the compatibility matrix:**
   ```bash
   # View online compatibility matrix
   xdg-open docs/hardware_matrix.md
   ```

2. **Test your hardware:**
   ```bash
   # Download and run hardware test
   wget https://raw.githubusercontent.com/your-org/KawaiiSec-OS/main/scripts/kawaiisec-hwtest.sh
   chmod +x kawaiisec-hwtest.sh
   sudo ./kawaiisec-hwtest.sh
   
   # Or if you have the repository cloned:
   sudo scripts/kawaiisec-hwtest.sh
   
   # Or use the Makefile target:
   make hwtest
   ```

3. **Contribute your results:**
   - The test script generates both a detailed report and a markdown snippet
   - Copy the markdown snippet to `docs/hardware_matrix.md`
   - Submit a pull request or create an issue with your results
   - Help improve hardware support for the community!

### Using the Build System

```bash
# Build everything
make all

# Install system-wide
make install-package

# Test hardware compatibility
make hwtest

# Start lab environments
make labs-start

# Run tests
make test

# Clean up
make clean
```

### System Requirements

#### Minimum Requirements
- **CPU**: x86_64 architecture (ARM64 support in development)
- **RAM**: 4GB (8GB recommended)
- **Storage**: 20GB free space (SSD recommended)
- **Network**: Ethernet or WiFi connectivity

#### Recommended Requirements
- **CPU**: Multi-core x86_64 processor (Intel i5/AMD Ryzen 5 or better)
- **RAM**: 16GB or more
- **Storage**: 50GB+ NVMe SSD
- **Network**: Ethernet + WiFi with good Linux driver support
- **Graphics**: Integrated or discrete GPU with Linux drivers

#### Hardware Compatibility
- **Excellent**: Intel integrated graphics, mainstream WiFi chipsets
- **Good**: AMD graphics, common network controllers
- **Limited**: NVIDIA graphics (requires proprietary drivers)
- **Unsupported**: Apple Silicon Macs (ARM64 support in development)

For detailed compatibility information, see our [Hardware Compatibility Matrix](docs/hardware_matrix.md).

## 🔧 Storage Management

### First-Boot Wizard
The system includes an interactive first-boot wizard that:
- Creates your initial user account with sudo privileges
- Configures basic system settings (timezone, hostname)
- Initializes security tools and lab environments
- Sets up storage management features

### Btrfs Snapshots
Automated snapshot management with:
- Daily snapshots of root and home filesystems
- Configurable retention (default: 7 days)
- Space-efficient copy-on-write storage
- Easy restore from snapshots

```bash
# Create manual snapshot
kawaiisec-snapshot.sh create root

# List available snapshots
kawaiisec-snapshot.sh list home

# Restore from snapshot
kawaiisec-snapshot.sh restore root snapshot_name
```

### OverlayFS Support
For educational environments requiring system reset:
- Read-only base system with writable overlay
- Easy reset to clean state between sessions
- Reduced wear on storage devices

```bash
# Setup OverlayFS
kawaiisec-overlay-setup.sh setup

# Reset system to clean state
kawaiisec-mount-overlay.sh reset
```

### Disk Quotas
Prevent disk space exhaustion with:
- Per-user quotas (default: 5GB soft, 6GB hard)
- Group quotas for shared projects
- Automated monitoring and alerts
- Grace periods for soft limit violations

```bash
# Setup quotas
kawaiisec-quota-setup.sh setup

# Add quota for user
kawaiisec-quota-setup.sh add-user alice /home 3G 4G

# Check quota usage
kawaiisec-quota-setup.sh report /home
```

### Automated Cleanup
Daily maintenance tasks include:
- Temporary file cleanup
- Package cache management
- Log rotation and compression
- Old snapshot removal

```bash
# Run manual cleanup
kawaiisec-cleanup.sh all

# Preview what would be cleaned
kawaiisec-cleanup.sh dry-run
```

### Account Security Management
Robust system for detecting and removing demo/test accounts:

```bash
# Scan for suspicious accounts (safe)
make account-cleanup

# Create configuration files
make account-cleanup-config

# Remove suspicious accounts (with confirmation)
make account-cleanup-force

# Lock accounts instead of removing (safer)
make account-cleanup-lock
```

## 📊 Hardware Testing & Contribution

### Testing Your Hardware

KawaiiSec OS includes a comprehensive hardware testing system:

```bash
# Run automated hardware compatibility test
sudo kawaiisec-hwtest.sh

# View test results
cat ~/kawaiisec_hw_report.txt      # Detailed technical report
cat ~/kawaiisec_hw_snippet.md      # Ready-to-submit matrix entry
```

### Contributing Test Results

Help improve hardware compatibility by contributing your test results:

1. **Run the hardware test** on your system
2. **Review the generated markdown snippet** (`~/kawaiisec_hw_snippet.md`)
3. **Add your results to the compatibility matrix**:
   - Fork this repository
   - Edit `docs/hardware_matrix.md`
   - Copy the table row from your snippet
   - Submit a pull request

4. **Join the community**:
   - [Hardware Compatibility Matrix](docs/hardware_matrix.md)
   - [Community Forum](https://forum.kawaiisec.com)
   - [Discord](https://discord.gg/kawaiisec) - `#hardware-help` channel

### Automated Testing

Our CI/CD pipeline continuously tests hardware compatibility:
- **Weekly testing** on major cloud platforms
- **Regression testing** for previously working hardware  
- **Community-driven** quarterly testing events
- **Real-time updates** to the compatibility matrix

## 🧪 Lab Environments

### Available Labs
- **OWASP Juice Shop**: Modern web application security
- **DVWA**: Classic vulnerable web application
- **Metasploitable3**: Intentionally vulnerable Linux/Windows
- **Custom scenarios**: Educational penetration testing labs

### Docker Labs
```bash
# Start all lab environments
make labs-start

# Access individual labs
launch_dvwa.sh        # DVWA at http://localhost:8080
run_juice_shop.sh     # Juice Shop at http://localhost:3000

# Stop labs
make labs-stop
```

### Vagrant Labs
```bash
# Start Metasploitable3
start_metasploitable3.sh

# Network topology lab
lab_net_topo.sh
```

## 📊 System Monitoring and Maintenance

### Automated Services
KawaiiSec OS includes several systemd services for automation:

- `kawaiisec-firstboot.service`: First-boot setup wizard
- `kawaiisec-snapshot@.timer`: Daily snapshot creation
- `kawaiisec-cleanup.timer`: Daily system cleanup
- `kawaiisec-quota-monitor.timer`: Quota usage monitoring

### Logging and Reports
All system activities are logged with regular reports:
- `/var/log/kawaiisec-firstboot.log`: First-boot setup
- `/var/log/kawaiisec-snapshots.log`: Snapshot operations
- `/var/log/kawaiisec-cleanup.log`: Cleanup activities
- `/var/log/kawaiisec-quotas.log`: Quota management

## 🛠️ Development

### Setting up Development Environment
```bash
make dev-setup
```

### Running Tests
```bash
make test              # All tests
make test-scripts      # Shell script tests
make test-docker       # Docker configuration tests
make lint              # Code linting
```

### Building Packages
```bash
make build-package     # Build Debian package
make test-package      # Test package integrity
make release-prepare   # Prepare for release
```

## 📁 Directory Structure

```
KawaiiSec-OS/
├── assets/           # Themes, graphics, audio
├── debian/           # Debian packaging files
├── docs/            # Documentation
├── labs/            # Lab configurations
├── scripts/         # Management scripts
├── systemd/         # Systemd service files
├── config/          # Configuration examples
└── kawaiisec-docs/  # Documentation website
```

## 🔐 Security Considerations

### Storage Security
- File system encryption support (LUKS)
- Secure mount options for system partitions
- Quota enforcement to prevent DoS attacks
- Immutable root filesystem option

### User Management
- Sudo access controls
- Group-based permissions for security tools
- User quota enforcement
- Session isolation capabilities

## 📖 Documentation

Comprehensive documentation is available:
- [Quick Start Guide](docs/quick-start-lab-guide.md)
- [Partitioning Guide](docs/partitioning.md)
- [Hardware Compatibility Matrix](docs/hardware_matrix.md)
- [Desktop Environment Setup](docs/desktop_environment.md)
- [Firewall Configuration](docs/firewall.md)
- [API Documentation](kawaiisec-docs/)

### Online Documentation
```bash
# Serve documentation locally
make docs-serve
# Access at http://localhost:8000
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow shell script best practices
- Add tests for new features
- Update documentation
- Use conventional commit messages

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Kali Linux team for the base distribution
- OWASP for vulnerable applications
- Security community for tool development
- Contributors and testers

## 📞 Support

- **Documentation**: [docs/](docs/)
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Security**: security@kawaiisec.org

---

**🌸 Happy hacking with KawaiiSec OS! 🌸**
