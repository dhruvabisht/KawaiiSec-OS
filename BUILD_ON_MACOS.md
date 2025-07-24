# 🌸 Building KawaiiSec OS on macOS

Since KawaiiSec OS requires a Debian/Ubuntu Linux environment for building, here are several options to build it on macOS:

## 🚀 Option 1: UTM (Recommended for Apple Silicon)

UTM is a virtualization app for macOS that works well on both Intel and Apple Silicon Macs.

### Setup UTM Virtual Machine

1. **Install UTM:**
   ```bash
   brew install --cask utm
   ```

2. **Download Ubuntu Server 22.04 LTS:**
   - Get the ARM64 version for Apple Silicon or AMD64 for Intel Macs
   - Download from: https://ubuntu.com/download/server

3. **Create VM in UTM:**
   - **System:** Linux
   - **RAM:** 8GB minimum (16GB recommended)
   - **Storage:** 50GB minimum
   - **CPU Cores:** 4-8 cores
   - **Architecture:** ARM64 (Apple Silicon) or x86_64 (Intel)

4. **Install Ubuntu Server:**
   - Follow the installation wizard
   - Enable SSH server during installation
   - Create a user account

5. **Configure the VM:**
   ```bash
   # Update system
   sudo apt update && sudo apt upgrade -y
   
   # Install required packages
   sudo apt install -y live-build debootstrap xorriso isolinux \
     syslinux-utils memtest86+ dosfstools squashfs-tools \
     qemu-system-x86 qemu-utils git build-essential
   
   # Clone KawaiiSec OS
   git clone https://github.com/dhruvabisht/KawaiiSec-OS.git
   cd KawaiiSec-OS
   
   # Build the ISO
   chmod +x build-iso.sh
   sudo ./build-iso.sh
   ```

## 🐳 Option 2: Docker (Recommended - Easy Setup)

Use Docker to create a Debian build environment with automatic ISO export:

### Enhanced Docker Build Environment

1. **Install Docker Desktop:**
   ```bash
   brew install --cask docker
   ```

2. **Clone and Build (All-in-One):**
   ```bash
   # The project includes pre-configured Docker setup
   git clone https://github.com/dhruvabisht/KawaiiSec-OS.git
   cd KawaiiSec-OS
   
   # Build ISO using the enhanced Docker script
   ./docker-build.sh
   ```

3. **What Happens Automatically:**
   - 🔨 Builds optimized Docker container (AMD64 for Mac compatibility)
   - 🚀 Runs the full ISO build process
   - 📦 **Exports ISO to `./output/` directory on your Mac**
   - ✅ Includes checksums and build logs
   - 🧹 Cleans up containers automatically

4. **Your ISO Will Be Here:**
   ```bash
   ls -la ./output/
   # kawaiisec-os-YYYY.MM.DD-amd64.iso
   # kawaiisec-os-YYYY.MM.DD-amd64.iso.sha256
   # kawaiisec-os-YYYY.MM.DD-amd64.iso.md5
   # build-report-YYYY.MM.DD.txt
   ```

### Advanced Docker Options

```bash
# Clean build from scratch
./docker-build.sh --clean

# Use ARM64 native build (Apple Silicon, may have issues)
./docker-build.sh --arm64

# Extract ISO from stuck containers (if needed)
./docker-build.sh --extract

# Or use the quick extraction script
./extract-iso.sh
```

### Troubleshooting Docker Issues

If your ISO doesn't appear in `./output/`:

1. **Check build logs:**
   ```bash
   docker logs $(docker ps -a | grep kawaiisec | awk '{print $1}')
   ```

2. **Manually extract from container:**
   ```bash
   ./extract-iso.sh
   ```

3. **Verify Docker resources:**
   - Ensure Docker has at least 8GB RAM allocated
   - Ensure at least 20GB free disk space

## 🌐 Option 3: Vagrant (VirtualBox)

Use Vagrant with VirtualBox for a reproducible build environment:

### Setup Vagrant Environment

1. **Install Dependencies:**
   ```bash
   brew install --cask virtualbox vagrant
   ```

2. **Create Vagrantfile:**
   ```ruby
   Vagrant.configure("2") do |config|
     config.vm.box = "ubuntu/jammy64"
     config.vm.hostname = "kawaiisec-builder"
     
     # Configure resources
     config.vm.provider "virtualbox" do |vb|
       vb.memory = "8192"
       vb.cpus = 4
       vb.name = "KawaiiSec-Builder"
     end
     
     # Provision build environment
     config.vm.provision "shell", inline: <<-SHELL
       apt-get update
       apt-get install -y live-build debootstrap xorriso isolinux \
         syslinux-utils memtest86+ dosfstools squashfs-tools \
         git build-essential
     SHELL
     
     # Sync project directory
     config.vm.synced_folder ".", "/home/vagrant/KawaiiSec-OS"
   end
   ```

3. **Start and Build:**
   ```bash
   # Start VM
   vagrant up
   
   # SSH into VM
   vagrant ssh
   
   # Build ISO
   cd KawaiiSec-OS
   chmod +x build-iso.sh
   sudo ./build-iso.sh
   ```

## ☁️ Option 4: GitHub Actions (Cloud Build)

Use GitHub Actions for automated cloud building:

### Setup GitHub Actions Workflow

Create `.github/workflows/build-iso.yml`:

```yaml
name: Build KawaiiSec OS ISO

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build-iso:
    runs-on: ubuntu-22.04
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y live-build debootstrap xorriso isolinux \
          syslinux-utils memtest86+ dosfstools squashfs-tools
    
    - name: Build ISO
      run: |
        chmod +x build-iso.sh
        sudo ./build-iso.sh
    
    - name: Upload ISO artifact
      uses: actions/upload-artifact@v4
      with:
        name: kawaiisec-os-iso
        path: kawaiisec-os-*.iso
        retention-days: 30
```

## 🎯 Recommended Approach

For **Any Mac (Intel or Apple Silicon)**: Use **Enhanced Docker** (Option 2) - **Easiest Setup!**
For **Advanced Users**: Use **UTM** (Option 1) for full Linux experience  
For **Automated Builds**: Use **GitHub Actions** (Option 4)
For **Legacy Setups**: Use **Vagrant** (Option 3)

**🌸 Why Docker is Recommended:**
- ✅ Works on both Intel and Apple Silicon Macs
- ✅ Automatic ISO export to your Mac filesystem  
- ✅ No VM setup required
- ✅ Pre-configured build environment
- ✅ Easy troubleshooting tools included

## 📋 Build Requirements Checklist

Before building, ensure your Linux environment has:
- [ ] Ubuntu 20.04+ or Debian 11+
- [ ] 8GB RAM minimum (16GB recommended)
- [ ] 20GB free disk space minimum
- [ ] All required packages installed
- [ ] sudo privileges
- [ ] Fast internet connection

## 🚀 Quick Start Commands

Once you have a Linux environment set up:

```bash
# Clone the repository
git clone https://github.com/dhruvabisht/KawaiiSec-OS.git
cd KawaiiSec-OS

# Make build script executable
chmod +x build-iso.sh

# Install dependencies (if not already installed)
sudo apt update
sudo apt install -y live-build debootstrap xorriso isolinux \
  syslinux-utils memtest86+ dosfstools squashfs-tools

# Build the ISO
sudo ./build-iso.sh

# Validate the ISO
sudo ./scripts/validate-iso.sh ./kawaiisec-os-*.iso
```

## 📤 Getting the ISO Back to macOS

The process varies by build method:

1. **From Enhanced Docker (Recommended):** ✅ **Automatic!** ISO appears in `./output/`
2. **From UTM/Vagrant:** Copy the ISO file to a shared folder
3. **From Basic Docker:** Use `./extract-iso.sh` or `docker cp`
4. **From GitHub Actions:** Download the artifact from the Actions tab

### Quick ISO Export Commands

If you used a different method and need to extract your ISO:

```bash
# From any Docker container
./extract-iso.sh

# Manual Docker copy (if you know container name)
docker cp <container_name>:/home/builder/workspace/kawaiisec-os-*.iso ./output/

# From Vagrant VM
vagrant ssh -c "cp /home/vagrant/KawaiiSec-OS/kawaiisec-os-*.iso /vagrant/"
```

The built ISO can then be used with:
- **UTM** for testing on macOS
- **VirtualBox** for cross-platform testing  
- **QEMU** for command-line testing
- **Balena Etcher** for creating bootable USB drives
- **dd command** for USB creation: `sudo dd if=output/kawaiisec-os-*.iso of=/dev/diskN bs=4m`

## 🎉 Next Steps

Once you have the ISO built, you can:
1. Test it in a virtual machine
2. Create a bootable USB drive
3. Deploy it to physical hardware
4. Contribute back to the project

Choose the option that works best for your setup and let's get building! 🌸 