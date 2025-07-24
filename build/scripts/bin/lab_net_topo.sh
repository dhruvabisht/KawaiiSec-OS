#!/bin/bash

# KawaiiSec OS - Lab Network Topology Launcher
# Deploys a comprehensive lab network with multiple VMs and segments

set -e

SCRIPT_NAME="Lab Network Topology"
LAB_DIR="/opt/kawaiisec/labs/vagrant/network-lab"
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
echo "│ 🌐 KawaiiSec Network Topology Lab 🌐│"
echo "│     Multi-VM Network Simulation     │"
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

# Function to initialize lab network environment
init_environment() {
    if [ ! -f "${VAGRANT_DIR}/Vagrantfile" ]; then
        print_status "Setting up lab network topology for first time..."
        
        # Create Vagrantfile for complex network topology
        cat > "${VAGRANT_DIR}/Vagrantfile" << 'EOF'
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  
  # ====== DMZ Network (192.168.10.0/24) ======
  
  # Web Server (DMZ)
  config.vm.define "web-server" do |web|
    web.vm.box = "ubuntu/focal64"
    web.vm.hostname = "web-server"
    web.vm.network "private_network", ip: "192.168.10.10", virtualbox__intnet: "dmz"
    web.vm.network "private_network", ip: "192.168.1.10", virtualbox__intnet: "external"
    
    web.vm.provider "virtualbox" do |v|
      v.name = "KawaiiSec-WebServer"
      v.memory = 1024
      v.cpus = 1
      v.gui = false
    end
    
    web.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y apache2 php mysql-server
      
      # Install DVWA on web server
      cd /var/www/html
      git clone https://github.com/digininja/DVWA.git dvwa
      chown -R www-data:www-data dvwa
      
      # Basic Apache config
      systemctl enable apache2
      systemctl start apache2
      
      echo "Web server setup complete! DVWA available at /dvwa"
    SHELL
  end

  # Database Server (DMZ)
  config.vm.define "db-server" do |db|
    db.vm.box = "ubuntu/focal64"
    db.vm.hostname = "db-server"
    db.vm.network "private_network", ip: "192.168.10.20", virtualbox__intnet: "dmz"
    
    db.vm.provider "virtualbox" do |v|
      v.name = "KawaiiSec-DBServer"
      v.memory = 1024
      v.cpus = 1
      v.gui = false
    end
    
    db.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y mysql-server postgresql
      
      # Configure MySQL
      mysql -e "CREATE DATABASE testdb;"
      mysql -e "CREATE USER 'testuser'@'%' IDENTIFIED BY 'password';"
      mysql -e "GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'%';"
      
      # Allow remote connections
      sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
      systemctl restart mysql
      
      echo "Database server setup complete!"
    SHELL
  end

  # ====== Internal Network (192.168.20.0/24) ======
  
  # Domain Controller (Windows)
  config.vm.define "domain-controller" do |dc|
    dc.vm.box = "StefanScherer/windows_2019"
    dc.vm.hostname = "dc01"
    dc.vm.communicator = "winrm"
    dc.vm.network "private_network", ip: "192.168.20.10", virtualbox__intnet: "internal"
    
    dc.vm.provider "virtualbox" do |v|
      v.name = "KawaiiSec-DomainController"
      v.memory = 2048
      v.cpus = 2
      v.gui = false
    end
  end

  # File Server
  config.vm.define "file-server" do |fs|
    fs.vm.box = "ubuntu/focal64"
    fs.vm.hostname = "file-server"
    fs.vm.network "private_network", ip: "192.168.20.20", virtualbox__intnet: "internal"
    
    fs.vm.provider "virtualbox" do |v|
      v.name = "KawaiiSec-FileServer"
      v.memory = 1024
      v.cpus = 1
      v.gui = false
    end
    
    fs.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y samba nfs-kernel-server vsftpd
      
      # Configure Samba
      mkdir -p /srv/samba/shared
      chmod 777 /srv/samba/shared
      
      # Basic Samba config
      cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
      cat >> /etc/samba/smb.conf << 'SAMBA_EOF'
[shared]
   path = /srv/samba/shared
   browsable = yes
   writable = yes
   guest ok = yes
   read only = no
SAMBA_EOF
      
      systemctl restart smbd
      systemctl enable smbd
      
      echo "File server setup complete!"
    SHELL
  end

  # Client Workstation 1
  config.vm.define "workstation1" do |ws1|
    ws1.vm.box = "ubuntu/focal64"
    ws1.vm.hostname = "workstation1"
    ws1.vm.network "private_network", ip: "192.168.20.100", virtualbox__intnet: "internal"
    
    ws1.vm.provider "virtualbox" do |v|
      v.name = "KawaiiSec-Workstation1"
      v.memory = 1024
      v.cpus = 1
      v.gui = true
    end
    
    ws1.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y ubuntu-desktop-minimal firefox
      
      # Install some vulnerable software for testing
      apt-get install -y telnetd rsh-server
      
      echo "Workstation 1 setup complete!"
    SHELL
  end

  # Client Workstation 2 (Windows)
  config.vm.define "workstation2" do |ws2|
    ws2.vm.box = "StefanScherer/windows_10"
    ws2.vm.hostname = "workstation2"
    ws2.vm.communicator = "winrm"
    ws2.vm.network "private_network", ip: "192.168.20.101", virtualbox__intnet: "internal"
    
    ws2.vm.provider "virtualbox" do |v|
      v.name = "KawaiiSec-Workstation2"
      v.memory = 2048
      v.cpus = 2
      v.gui = true
    end
  end

  # ====== Management Network (192.168.30.0/24) ======
  
  # Firewall/Router (pfSense)
  config.vm.define "firewall" do |fw|
    fw.vm.box = "ubuntu/focal64"
    fw.vm.hostname = "firewall"
    fw.vm.network "private_network", ip: "192.168.1.1", virtualbox__intnet: "external"
    fw.vm.network "private_network", ip: "192.168.10.1", virtualbox__intnet: "dmz"
    fw.vm.network "private_network", ip: "192.168.20.1", virtualbox__intnet: "internal"
    fw.vm.network "private_network", ip: "192.168.30.1", virtualbox__intnet: "management"
    
    fw.vm.provider "virtualbox" do |v|
      v.name = "KawaiiSec-Firewall"
      v.memory = 1024
      v.cpus = 1
      v.gui = false
    end
    
    fw.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y iptables-persistent
      
      # Enable IP forwarding
      echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
      sysctl -p
      
      # Basic firewall rules
      iptables -A FORWARD -i eth1 -o eth2 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT
      iptables -A FORWARD -i eth1 -o eth3 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      iptables -A FORWARD -i eth3 -o eth1 -j ACCEPT
      
      # Save rules
      iptables-save > /etc/iptables/rules.v4
      
      echo "Firewall setup complete!"
    SHELL
  end

  # Monitoring Server
  config.vm.define "monitoring" do |mon|
    mon.vm.box = "ubuntu/focal64"
    mon.vm.hostname = "monitoring"
    mon.vm.network "private_network", ip: "192.168.30.10", virtualbox__intnet: "management"
    
    mon.vm.provider "virtualbox" do |v|
      v.name = "KawaiiSec-Monitoring"
      v.memory = 2048
      v.cpus = 2
      v.gui = false
    end
    
    mon.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y docker.io docker-compose
      
      # Start ELK stack for monitoring
      mkdir -p /opt/elk
      cd /opt/elk
      
      cat > docker-compose.yml << 'ELK_EOF'
version: '3.7'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.14.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    
  kibana:
    image: docker.elastic.co/kibana/kibana:7.14.0
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch
ELK_EOF
      
      systemctl enable docker
      systemctl start docker
      docker-compose up -d
      
      echo "Monitoring server with ELK stack setup complete!"
    SHELL
  end

  # ====== Attack Box (Kali Linux) ======
  
  config.vm.define "kali-attacker" do |kali|
    kali.vm.box = "kalilinux/rolling"
    kali.vm.hostname = "kali-attacker"
    kali.vm.network "private_network", ip: "192.168.1.100", virtualbox__intnet: "external"
    
    kali.vm.provider "virtualbox" do |v|
      v.name = "KawaiiSec-Kali-Attacker"
      v.memory = 4096
      v.cpus = 2
      v.gui = true
    end
    
    kali.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y metasploit-framework nmap masscan gobuster
      
      # Initialize Metasploit database
      msfdb init
      
      # Add lab hosts to /etc/hosts
      cat >> /etc/hosts << 'HOSTS_EOF'
# Lab Network Hosts
192.168.1.1    firewall
192.168.10.10  web-server
192.168.10.20  db-server
192.168.20.10  domain-controller dc01
192.168.20.20  file-server
192.168.20.100 workstation1
192.168.20.101 workstation2
192.168.30.10  monitoring
HOSTS_EOF
      
      # Create recon script
      cat > /home/vagrant/recon.sh << 'RECON_EOF'
#!/bin/bash
echo "Starting network reconnaissance..."
nmap -sn 192.168.1.0/24 192.168.10.0/24 192.168.20.0/24 192.168.30.0/24
echo "Detailed scan of discovered hosts..."
nmap -sV -sC 192.168.10.10 192.168.10.20 192.168.20.20
RECON_EOF
      chmod +x /home/vagrant/recon.sh
      chown vagrant:vagrant /home/vagrant/recon.sh
      
      echo "Kali attacker setup complete!"
    SHELL
  end
end
EOF
        
        print_success "Vagrantfile for network topology created successfully!"
    fi
}

# Function to show network diagram
show_network_diagram() {
    echo
    echo -e "${PURPLE}🌐 Network Topology Diagram:${NC}"
    echo
    echo "                     INTERNET"
    echo "                         │"
    echo "                  ┌─────────────┐"
    echo "                  │  Firewall   │ (192.168.1.1)"
    echo "                  │ (pfSense)   │"
    echo "                  └─────┬───────┘"
    echo "                        │"
    echo "          ┌─────────────┼─────────────┐"
    echo "          │             │             │"
    echo "    ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐"
    echo "    │    DMZ    │ │ Internal  │ │Management │"
    echo "    │192.168.10│ │192.168.20 │ │192.168.30 │"
    echo "    └───────────┘ └───────────┘ └───────────┘"
    echo "          │             │             │"
    echo "    ┌─────┴─────┐ ┌─────┴─────┐ ┌─────┴─────┐"
    echo "    │Web Server │ │Domain Ctrl│ │Monitoring │"
    echo "    │  (.10)    │ │   (.10)   │ │   (.10)   │"
    echo "    │           │ │           │ │   (ELK)   │"
    echo "    │DB Server  │ │File Server│ └───────────┘"
    echo "    │  (.20)    │ │   (.20)   │"
    echo "    └───────────┘ │           │"
    echo "                  │Workstat1  │"
    echo "                  │  (.100)   │"
    echo "                  │           │"
    echo "                  │Workstat2  │"
    echo "                  │  (.101)   │"
    echo "                  └───────────┘"
    echo
    echo "    ┌─────────────┐"
    echo "    │ Kali Linux  │ (192.168.1.100)"
    echo "    │  Attacker   │ <- External Access"
    echo "    └─────────────┘"
    echo
}

# Function to start VMs based on scenario
start_scenario() {
    cd "${VAGRANT_DIR}"
    
    case "${1:-basic}" in
        basic)
            print_status "Starting basic scenario (Web + DB + Kali)..."
            vagrant up web-server db-server kali-attacker
            ;;
        internal)
            print_status "Starting internal network scenario..."
            vagrant up domain-controller file-server workstation1 kali-attacker
            ;;
        full)
            print_status "Starting full network topology (this will take a long time)..."
            vagrant up
            ;;
        web)
            print_status "Starting web tier only..."
            vagrant up web-server db-server firewall
            ;;
        *)
            print_error "Invalid scenario: $1"
            echo "Available scenarios: basic, internal, full, web"
            exit 1
            ;;
    esac
    
    print_success "Scenario '$1' started successfully!"
    show_network_info
}

# Function to show network information
show_network_info() {
    echo
    echo -e "${GREEN}📡 Network Configuration:${NC}"
    echo -e "${BLUE}External Network:${NC}    192.168.1.0/24"
    echo -e "${BLUE}DMZ Network:${NC}         192.168.10.0/24"
    echo -e "${BLUE}Internal Network:${NC}    192.168.20.0/24"
    echo -e "${BLUE}Management Network:${NC}  192.168.30.0/24"
    echo
    echo -e "${YELLOW}🖥️  Key Systems:${NC}"
    echo "• Kali Attacker:     192.168.1.100"
    echo "• Firewall:          192.168.1.1"
    echo "• Web Server:        192.168.10.10"
    echo "• Database Server:   192.168.10.20"
    echo "• Domain Controller: 192.168.20.10"
    echo "• File Server:       192.168.20.20"
    echo "• Workstation 1:     192.168.20.100"
    echo "• Workstation 2:     192.168.20.101"
    echo "• Monitoring:        192.168.30.10"
    echo
    echo -e "${PURPLE}🎯 Attack Scenarios:${NC}"
    echo "1. External → DMZ penetration"
    echo "2. DMZ → Internal lateral movement"
    echo "3. Domain privilege escalation"
    echo "4. Data exfiltration through firewall"
    echo
    echo -e "${BLUE}💡 Quick Commands:${NC}"
    echo "• SSH to Kali:  vagrant ssh kali-attacker"
    echo "• Run recon:    vagrant ssh kali-attacker -c '/home/vagrant/recon.sh'"
    echo "• View topology: $0 diagram"
}

# Function to stop all VMs
stop_all() {
    cd "${VAGRANT_DIR}"
    print_status "Stopping all VMs..."
    vagrant halt
    print_success "All VMs stopped!"
}

# Function to show VM status
show_status() {
    cd "${VAGRANT_DIR}"
    print_status "Checking VM status..."
    vagrant status
}

# Parse command line arguments
case "${1:-basic}" in
    start)
        init_environment
        start_scenario "${2:-basic}"
        ;;
    stop)
        stop_all
        ;;
    status)
        show_status
        ;;
    diagram)
        show_network_diagram
        ;;
    info)
        show_network_info
        ;;
    ssh)
        cd "${VAGRANT_DIR}"
        vagrant ssh "${2:-kali-attacker}"
        ;;
    destroy)
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
        ;;
    *)
        echo "Usage: $0 {start|stop|status|diagram|info|ssh|destroy} [scenario/vm]"
        echo
        echo "Commands:"
        echo "  start [scenario] - Start VMs for scenario (default: basic)"
        echo "  stop             - Stop all VMs"
        echo "  status           - Show VM status"
        echo "  diagram          - Show network topology diagram"
        echo "  info             - Show network and system information"
        echo "  ssh [vm]         - SSH into VM (default: kali-attacker)"
        echo "  destroy          - Destroy all VMs"
        echo
        echo "Scenarios:"
        echo "  basic            - Web + DB + Kali (quick start)"
        echo "  internal         - Domain + File + Workstations + Kali"
        echo "  web              - Web tier + Firewall"
        echo "  full             - Complete network topology (resource intensive)"
        echo
        echo "Examples:"
        echo "  $0 start basic   - Quick web app testing setup"
        echo "  $0 start full    - Complete enterprise network"
        echo "  $0 diagram       - Show network diagram"
        echo "  $0 ssh kali      - Access Kali attack box"
        exit 1
        ;;
esac 