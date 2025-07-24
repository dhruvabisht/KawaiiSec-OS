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

### Using the Build System

```bash
# Build everything
make all

# Install system-wide
make install-package

# Start lab environments
make labs-start

# Run tests
make test

# Clean up
make clean
```

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
