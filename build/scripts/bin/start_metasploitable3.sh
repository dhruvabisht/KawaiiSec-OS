#!/bin/bash

# KawaiiSec OS - Metasploitable3 Launcher
# Launches Metasploitable3 using Vagrant

set -e

SCRIPT_NAME="Metasploitable3 Launcher"
LAB_DIR="/opt/kawaiisec/labs/vagrant/metasploitable3"
VAGRANT_DIR="${LAB_DIR}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Kawaii banner
echo -e "${PURPLE}"
echo "╭─────────────────────────────────────╮"
echo "│ 🎯 KawaiiSec Metasploitable3 Launch 🎯│"
echo "│    Intentionally Vulnerable VMs     │"
echo "╰─────────────────────────────────────╯"
echo -e "${NC}"

# Function to print colored messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Vagrant is installed
if ! command -v vagrant &> /dev/null; then
    print_error "Vagrant is not installed. Please install Vagrant and try again."
    exit 1
fi

# Check if VirtualBox is installed
if ! command -v VBoxManage &> /dev/null; then
    print_error "VirtualBox is not installed. Please install VirtualBox and try again."
    exit 1
fi

# Create lab directory if it doesn't exist
mkdir -p "${LAB_DIR}"

# Function to initialize Metasploitable3 environment
init_environment() {
    if [ ! -f "${VAGRANT_DIR}/Vagrantfile" ]; then
        print_status "Setting up Metasploitable3 environment for first time..."
        
        # Create Vagrantfile if it doesn't exist
        cat > "${VAGRANT_DIR}/Vagrantfile" << 'EOF'
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Windows 2008 Server
  config.vm.define "ms3-windows" do |windows|
    windows.vm.box = "rapid7/metasploitable3-win2k8"
    windows.vm.hostname = "metasploitable3-win2k8"
    windows.vm.communicator = "winrm"
    windows.winrm.basic_auth_only = true
    windows.winrm.timeout = 300
    windows.winrm.retry_limit = 20
    windows.vm.network "private_network", ip: "192.168.57.10"
    
    windows.vm.provider "virtualbox" do |v|
      v.name = "Metasploitable3-Windows"
      v.memory = 2048
      v.cpus = 2
      v.gui = false
    end
  end

  # Ubuntu Linux
  config.vm.define "ms3-linux" do |linux|
    linux.vm.box = "rapid7/metasploitable3-ub1404"
    linux.vm.hostname = "metasploitable3-ub1404"
    linux.vm.network "private_network", ip: "192.168.57.11"
    
    linux.vm.provider "virtualbox" do |v|
      v.name = "Metasploitable3-Linux"
      v.memory = 2048
      v.cpus = 2
      v.gui = false
    end
  end

  # Kali Control Machine
  config.vm.define "kali-control" do |kali|
    kali.vm.box = "kalilinux/rolling"
    kali.vm.hostname = "kali-control"
    kali.vm.network "private_network", ip: "192.168.57.100"
    
    kali.vm.provider "virtualbox" do |v|
      v.name = "KawaiiSec-Kali-Control"
      v.memory = 4096
      v.cpus = 2
      v.gui = true
    end
    
    # Provisioning script for Kali
    kali.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y metasploit-framework nmap
      
      # Start Metasploit database
      msfdb init
      
      # Add target hosts to /etc/hosts
      echo "192.168.57.10 ms3-windows metasploitable3-win2k8" >> /etc/hosts
      echo "192.168.57.11 ms3-linux metasploitable3-ub1404" >> /etc/hosts
      
      echo "Kali control machine setup complete!"
    SHELL
  end
end
EOF
        print_success "Vagrantfile created successfully!"
    fi
}

# Function to start VMs
start_vms() {
    cd "${VAGRANT_DIR}"
    
    case "${1:-all}" in
        windows|win)
            print_status "Starting Metasploitable3 Windows..."
            vagrant up ms3-windows
            ;;
        linux)
            print_status "Starting Metasploitable3 Linux..."
            vagrant up ms3-linux
            ;;
        kali)
            print_status "Starting Kali control machine..."
            vagrant up kali-control
            ;;
        all)
            print_status "Starting all VMs (this may take a while)..."
            vagrant up
            ;;
        *)
            print_error "Invalid target: $1"
            exit 1
            ;;
    esac
    
    print_success "VM(s) started successfully!"
    show_connection_info
}

# Function to show connection information
show_connection_info() {
    echo
    echo -e "${PURPLE}📡 Network Configuration:${NC}"
    echo -e "${GREEN}🖥️  Windows Target:${NC} 192.168.57.10 (ms3-windows)"
    echo -e "${GREEN}🐧 Linux Target:${NC}   192.168.57.11 (ms3-linux)"
    echo -e "${GREEN}🥷 Kali Control:${NC}   192.168.57.100 (kali-control)"
    echo
    echo -e "${BLUE}💡 Quick Access Commands:${NC}"
    echo "• SSH to Kali:    vagrant ssh kali-control"
    echo "• SSH to Linux:   vagrant ssh ms3-linux"
    echo "• RDP to Windows: Use RDP client to 192.168.57.10"
    echo
    echo -e "${YELLOW}🔐 Default Credentials:${NC}"
    echo "Windows: vagrant/vagrant"
    echo "Linux:   vagrant/vagrant"
    echo "Kali:    vagrant/vagrant"
    echo
    echo -e "${RED}⚠️  Security Notice:${NC}"
    echo "These VMs are intentionally vulnerable!"
    echo "Use only in isolated lab environments."
}

# Function to stop VMs
stop_vms() {
    cd "${VAGRANT_DIR}"
    
    case "${1:-all}" in
        windows|win)
            print_status "Stopping Metasploitable3 Windows..."
            vagrant halt ms3-windows
            ;;
        linux)
            print_status "Stopping Metasploitable3 Linux..."
            vagrant halt ms3-linux
            ;;
        kali)
            print_status "Stopping Kali control machine..."
            vagrant halt kali-control
            ;;
        all)
            print_status "Stopping all VMs..."
            vagrant halt
            ;;
        *)
            print_error "Invalid target: $1"
            exit 1
            ;;
    esac
    
    print_success "VM(s) stopped successfully!"
}

# Function to show VM status
show_status() {
    cd "${VAGRANT_DIR}"
    print_status "Checking VM status..."
    vagrant status
}

# Function to destroy VMs
destroy_vms() {
    cd "${VAGRANT_DIR}"
    print_warning "This will permanently destroy all VMs!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        vagrant destroy -f
        print_success "All VMs destroyed!"
    else
        print_status "Operation cancelled."
    fi
}

# Parse command line arguments
case "${1:-start}" in
    start)
        init_environment
        start_vms "${2}"
        ;;
    stop)
        stop_vms "${2}"
        ;;
    restart)
        print_status "Restarting VMs..."
        stop_vms "${2}"
        start_vms "${2}"
        ;;
    status)
        show_status
        ;;
    destroy)
        destroy_vms
        ;;
    ssh)
        cd "${VAGRANT_DIR}"
        vagrant ssh "${2:-kali-control}"
        ;;
    info)
        show_connection_info
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|destroy|ssh|info} [target]"
        echo
        echo "Commands:"
        echo "  start [target]   - Start VMs (default: all)"
        echo "  stop [target]    - Stop VMs (default: all)"
        echo "  restart [target] - Restart VMs (default: all)"
        echo "  status           - Show VM status"
        echo "  destroy          - Destroy all VMs"
        echo "  ssh [vm]         - SSH into VM (default: kali-control)"
        echo "  info             - Show connection information"
        echo
        echo "Targets:"
        echo "  all              - All VMs (default)"
        echo "  windows|win      - Windows Metasploitable3"
        echo "  linux            - Linux Metasploitable3"
        echo "  kali             - Kali control machine"
        echo
        echo "Examples:"
        echo "  $0 start windows - Start only Windows VM"
        echo "  $0 ssh kali      - SSH into Kali control machine"
        exit 1
        ;;
esac 