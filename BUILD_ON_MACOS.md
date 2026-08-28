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

## 🐳 Option 2: Docker (Cross-Platform)

Use Docker to create a Debian build environment:

### Create Docker Build Environment

1. **Install Docker Desktop:**
   ```bash
   brew install --cask docker
   ```

2. **Create Dockerfile:**
   ```dockerfile
   FROM debian:bookworm
   
   # Install build dependencies
   RUN apt-get update && apt-get install -y \
       live-build \
       debootstrap \
       xorriso \
       isolinux \
       syslinux-utils \
       memtest86+ \
       dosfstools \
       squashfs-tools \
       git \
       sudo \
       && rm -rf /var/lib/apt/lists/*
   
   # Create build user
   RUN useradd -m -s /bin/bash builder && \
       echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
   
   USER builder
   WORKDIR /home/builder
   
   CMD ["/bin/bash"]
   ```

3. **Build and Run Container:**
   ```bash
   # Build the container
   docker build -t kawaiisec-builder .
   
   # Run with volume mount
   docker run -it --privileged \
     -v $(pwd):/home/builder/KawaiiSec-OS \
     kawaiisec-builder
   
   # Inside container:
   cd KawaiiSec-OS
   sudo ./build-iso.sh
   ```

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

For **Apple Silicon Macs**: Use **UTM** (Option 1)
For **Intel Macs**: Use **Docker** (Option 2) or **Vagrant** (Option 3)
For **Automated Builds**: Use **GitHub Actions** (Option 4)

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

After building in a VM or container:

1. **From UTM/Vagrant:** Copy the ISO file to a shared folder
2. **From Docker:** Use `docker cp` to extract the ISO
3. **From GitHub Actions:** Download the artifact from the Actions tab

The built ISO can then be used with:
- **UTM** for testing on macOS
- **VirtualBox** for cross-platform testing  
- **QEMU** for command-line testing
- **USB flash drive** for physical hardware testing

## 🎉 Next Steps

Once you have the ISO built, you can:
1. Test it in a virtual machine
2. Create a bootable USB drive
3. Deploy it to physical hardware
4. Contribute back to the project

Choose the option that works best for your setup and let's get building! 🌸 