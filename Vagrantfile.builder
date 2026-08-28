# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 LTS
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "kawaiisec-builder"
  
  # Configure VM resources
  config.vm.provider "virtualbox" do |vb|
    vb.name = "KawaiiSec-OS-Builder"
    vb.memory = "8192"  # 8GB RAM
    vb.cpus = 4         # 4 CPU cores
    vb.gui = false      # Headless mode
    
    # Enable nested virtualization if supported
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    
    # Increase video memory for better performance
    vb.customize ["modifyvm", :id, "--vram", "128"]
  end
  
  # Network configuration
  config.vm.network "private_network", type: "dhcp"
  
  # Sync the project directory
  config.vm.synced_folder ".", "/home/vagrant/KawaiiSec-OS", 
    owner: "vagrant", 
    group: "vagrant",
    mount_options: ["dmode=755,fmode=644"]
  
  # Provision the build environment
  config.vm.provision "shell", inline: <<-SHELL
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Install required packages for KawaiiSec OS building
    apt-get install -y \
      live-build \
      debootstrap \
      xorriso \
      isolinux \
      syslinux-utils \
      memtest86+ \
      dosfstools \
      squashfs-tools \
      qemu-system-x86 \
      qemu-utils \
      git \
      build-essential \
      wget \
      curl \
      file \
      rsync \
      htop \
      tree \
      vim
    
    # Clean up
    apt-get autoremove -y
    apt-get autoclean
    
    echo "🌸 KawaiiSec OS build environment ready!"
    echo "💡 To build the ISO:"
    echo "   vagrant ssh"
    echo "   cd KawaiiSec-OS"
    echo "   chmod +x build-iso.sh"
    echo "   sudo ./build-iso.sh"
  SHELL
  
  # Post-provision message
  config.vm.post_up_message = <<-MSG
    🌸 KawaiiSec OS Build Environment is ready!
    
    To get started:
    1. vagrant ssh
    2. cd KawaiiSec-OS
    3. sudo ./build-iso.sh
    
    The built ISO will be available in the synced folder.
  MSG
end 