#!/bin/bash

# KawaiiSec OS Hardware Testing and Compatibility Report Generator
# Performs comprehensive hardware detection and testing for compatibility matrix

set -euo pipefail

# Configuration
REPORT_FILE="$HOME/kawaiisec_hw_report.txt"
MARKDOWN_FILE="$HOME/kawaiisec_hw_snippet.md"
TEMP_DIR="/tmp/kawaiisec-hwtest-$$"
LOG_FILE="/var/log/kawaiisec-hwtest.log"
REPORTS_DIR="hardware_reports"

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Hardware information variables (collected from user)
HARDWARE_BRAND=""
HARDWARE_MODEL=""
HARDWARE_YEAR=""
PLATFORM_TYPE=""
VM_PLATFORM=""
CPU_MODEL=""
RAM_SIZE=""
RAM_TYPE=""
STORAGE_TYPE=""
STORAGE_SIZE=""
WIFI_CHIPSET=""
ETHERNET_CONTROLLER=""
GPU_MODEL=""
TESTER_INITIALS=""
ADDITIONAL_NOTES=""

# Test results storage
declare -A TEST_RESULTS
declare -A TEST_ISSUES

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" 2>/dev/null || true
}

# Error handling
error_exit() {
    log "ERROR: $1"
    echo -e "${RED}❌ Test failed: $1${NC}" >&2
    cleanup
    exit 1
}

# Success message
success() {
    log "SUCCESS: $1"
    echo -e "${GREEN}✅ $1${NC}"
}

# Warning message  
warning() {
    log "WARNING: $1"
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Info message
info() {
    log "INFO: $1"
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Progress message
progress() {
    echo -e "${CYAN}🔍 $1${NC}"
}

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}

# Check if running as root for certain tests
check_root() {
    if [[ $EUID -ne 0 ]] && [[ "$1" == "required" ]]; then
        error_exit "This script must be run as root for complete hardware testing. Use: sudo $0"
    fi
    
    if [[ $EUID -ne 0 ]] && [[ "$1" == "optional" ]]; then
        warning "Some tests require root privileges. Run with sudo for complete results."
        return 1
    fi
    return 0
}

# Prompt user for hardware information
collect_hardware_info() {
    echo -e "${PURPLE}"
    echo "╭─────────────────────────────────────────╮"
    echo "│     🌸 Hardware Information Setup 🌸    │"
    echo "│   Please provide your system details    │"
    echo "╰─────────────────────────────────────────╯"
    echo -e "${NC}"
    
    echo -e "${CYAN}Let's gather some information about your hardware for the compatibility matrix.${NC}"
    echo ""
    
    # Hardware Brand and Model
    echo -e "${BLUE}📱 Hardware Information:${NC}"
    read -p "Hardware Brand (e.g., Dell, HP, ThinkPad, Custom): " HARDWARE_BRAND
    read -p "Hardware Model (e.g., XPS 13 9310, T480, Custom Build): " HARDWARE_MODEL
    read -p "Hardware Year (e.g., 2020, 2023, Unknown): " HARDWARE_YEAR
    echo ""
    
    # Platform Type
    echo -e "${BLUE}🖥️  Platform Information:${NC}"
    echo "1) Physical Hardware"
    echo "2) Virtual Machine"  
    echo "3) Cloud Instance"
    echo "4) Container"
    read -p "Select platform type (1-4): " platform_choice
    
    case $platform_choice in
        1) PLATFORM_TYPE="Physical Hardware";;
        2) PLATFORM_TYPE="Virtual Machine"
           read -p "VM Platform (VirtualBox, VMware, QEMU/KVM, etc.): " VM_PLATFORM;;
        3) PLATFORM_TYPE="Cloud Instance"
           read -p "Cloud Provider (AWS, GCP, Azure, etc.): " VM_PLATFORM;;
        4) PLATFORM_TYPE="Container"
           read -p "Container Platform (Docker, LXC, etc.): " VM_PLATFORM;;
        *) PLATFORM_TYPE="Unknown";;
    esac
    echo ""
    
    # CPU Information
    echo -e "${BLUE}🔧 System Specifications:${NC}"
    # Try to auto-detect CPU
    local detected_cpu=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d':' -f2 | sed 's/^ *//' || echo "")
    if [[ -n "$detected_cpu" ]]; then
        read -p "CPU Model (detected: $detected_cpu): " -i "$detected_cpu" -e CPU_MODEL
    else
        read -p "CPU Model (e.g., Intel i7-1165G7, AMD Ryzen 7 5800H): " CPU_MODEL
    fi
    
    # RAM Information
    local detected_ram=$(free -h 2>/dev/null | grep '^Mem:' | awk '{print $2}' || echo "")
    if [[ -n "$detected_ram" ]]; then
        read -p "RAM Size (detected: $detected_ram): " -i "$detected_ram" -e RAM_SIZE
    else
        read -p "RAM Size (e.g., 16GB, 32GB): " RAM_SIZE
    fi
    read -p "RAM Type (DDR4, DDR5, LPDDR4x, Unknown): " RAM_TYPE
    echo ""
    
    # Storage Information
    echo -e "${BLUE}💾 Storage Information:${NC}"
    read -p "Primary Storage Type (NVMe SSD, SATA SSD, HDD, eMMC): " STORAGE_TYPE
    read -p "Primary Storage Size (e.g., 512GB, 1TB): " STORAGE_SIZE
    echo ""
    
    # Network Information
    echo -e "${BLUE}🌐 Network Information:${NC}"
    read -p "WiFi Chipset (e.g., Intel AX210, Broadcom BCM4364, Unknown): " WIFI_CHIPSET
    read -p "Ethernet Controller (e.g., Intel I219-V, Realtek RTL8111, None): " ETHERNET_CONTROLLER
    echo ""
    
    # Graphics Information
    echo -e "${BLUE}🎮 Graphics Information:${NC}"
    local detected_gpu=$(lspci 2>/dev/null | grep -i vga | head -1 | cut -d':' -f3 | sed 's/^ *//' || echo "")
    if [[ -n "$detected_gpu" ]]; then
        read -p "GPU Model (detected: $detected_gpu): " -i "$detected_gpu" -e GPU_MODEL
    else
        read -p "GPU Model (e.g., Intel Iris Xe, NVIDIA RTX 3070, AMD Radeon): " GPU_MODEL
    fi
    echo ""
    
    # Tester Information
    echo -e "${BLUE}👤 Tester Information:${NC}"
    read -p "Your Initials (for attribution): " TESTER_INITIALS
    read -p "Additional Notes (optional): " ADDITIONAL_NOTES
    echo ""
    
    echo -e "${GREEN}✅ Hardware information collected!${NC}"
    echo ""
}

# Initialize testing environment
init_testing() {
    progress "Initializing KawaiiSec OS Hardware Testing..."
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    # Create hardware reports directory in current working directory and home
    mkdir -p "$REPORTS_DIR" 
    mkdir -p "$HOME/$REPORTS_DIR"
    
    # Create log file if it doesn't exist
    if check_root optional; then
        touch "$LOG_FILE" 2>/dev/null || true
    fi
    
    # Clear previous reports
    > "$REPORT_FILE"
    > "$MARKDOWN_FILE"
    
    success "Testing environment initialized"
}

# Write report header with collected hardware info
write_report_header() {
    cat > "$REPORT_FILE" << EOF
🌸 KawaiiSec OS Hardware Compatibility Report
==============================================

Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')
Hostname: $(hostname)
User: $(whoami)
Kernel: $(uname -r)
Distribution: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")

Hardware Information:
- Brand/Model: $HARDWARE_BRAND $HARDWARE_MODEL ($HARDWARE_YEAR)
- Platform: $PLATFORM_TYPE$([ -n "$VM_PLATFORM" ] && echo " ($VM_PLATFORM)")
- CPU: $CPU_MODEL
- RAM: $RAM_SIZE $RAM_TYPE
- Storage: $STORAGE_SIZE $STORAGE_TYPE
- WiFi: $WIFI_CHIPSET
- Ethernet: $ETHERNET_CONTROLLER
- GPU: $GPU_MODEL
- Tester: $TESTER_INITIALS
- Notes: $ADDITIONAL_NOTES

Test Results Summary:
EOF
}

# Set test result helper function
set_test_result() {
    local test_name="$1"
    local result="$2"
    local issue="${3:-}"
    
    TEST_RESULTS["$test_name"]="$result"
    if [[ -n "$issue" ]]; then
        TEST_ISSUES["$test_name"]="$issue"
    fi
}

# System Information Collection
collect_system_info() {
    progress "Collecting system information..."
    
    cat >> "$REPORT_FILE" << EOF

📊 SYSTEM INFORMATION
=====================

Hardware Platform:
EOF
    
    # CPU Information
    echo "CPU:" >> "$REPORT_FILE"
    if command -v lscpu >/dev/null 2>&1; then
        lscpu | grep -E "(Model name|Architecture|CPU\(s\)|Thread|Core|Socket)" >> "$REPORT_FILE" 2>/dev/null || true
    else
        grep -E "(model name|cpu cores|processor)" /proc/cpuinfo | head -10 >> "$REPORT_FILE" 2>/dev/null || true
    fi
    
    echo "" >> "$REPORT_FILE"
    
    # Memory Information
    echo "Memory:" >> "$REPORT_FILE"
    if command -v free >/dev/null 2>&1; then
        free -h >> "$REPORT_FILE" 2>/dev/null || true
    fi
    echo "" >> "$REPORT_FILE"
    
    # DMI/SMBIOS Information
    if command -v dmidecode >/dev/null 2>&1 && check_root optional; then
        echo "System:" >> "$REPORT_FILE"
        dmidecode -t system 2>/dev/null | grep -E "(Manufacturer|Product Name|Version)" >> "$REPORT_FILE" || true
        echo "" >> "$REPORT_FILE"
        
        echo "BIOS:" >> "$REPORT_FILE"
        dmidecode -t bios 2>/dev/null | grep -E "(Vendor|Version|Release Date)" >> "$REPORT_FILE" || true
        echo "" >> "$REPORT_FILE"
    fi
    
    # Storage Information
    echo "Storage:" >> "$REPORT_FILE"
    if command -v lsblk >/dev/null 2>&1; then
        lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT >> "$REPORT_FILE" 2>/dev/null || true
    fi
    echo "" >> "$REPORT_FILE"
    
    # PCI Devices
    echo "PCI Devices:" >> "$REPORT_FILE"
    if command -v lspci >/dev/null 2>&1; then
        lspci >> "$REPORT_FILE" 2>/dev/null || true
    fi
    echo "" >> "$REPORT_FILE"
    
    # USB Devices
    echo "USB Devices:" >> "$REPORT_FILE"
    if command -v lsusb >/dev/null 2>&1; then
        lsusb >> "$REPORT_FILE" 2>/dev/null || true
    fi
    echo "" >> "$REPORT_FILE"
    
    success "System information collected"
}

# Network Interface Testing
test_networking() {
    progress "Testing network interfaces..."
    
    cat >> "$REPORT_FILE" << EOF

🌐 NETWORK TESTING
==================

Network Interfaces:
EOF
    
    # List all network interfaces
    if command -v ip >/dev/null 2>&1; then
        ip link show >> "$REPORT_FILE" 2>/dev/null || true
    elif command -v ifconfig >/dev/null 2>&1; then
        ifconfig -a >> "$REPORT_FILE" 2>/dev/null || true
    fi
    echo "" >> "$REPORT_FILE"
    
    # Test Ethernet interfaces
    echo "Ethernet Testing:" >> "$REPORT_FILE"
    local ethernet_found=false
    local ethernet_working=false
    
    for interface in $(ip link show 2>/dev/null | grep -E '^[0-9]+:' | grep -E 'eth|eno|enp|ens' | cut -d: -f2 | tr -d ' ' || true); do
        if [[ -n "$interface" ]]; then
            ethernet_found=true
            echo "  Interface: $interface" >> "$REPORT_FILE"
            
            # Check if interface is up
            if ip link show "$interface" 2>/dev/null | grep -q "state UP"; then
                echo "    Status: UP" >> "$REPORT_FILE"
                ethernet_working=true
            else
                echo "    Status: DOWN" >> "$REPORT_FILE"
            fi
            
            # Check driver information
            if [[ -e "/sys/class/net/$interface/device/driver" ]]; then
                local driver=$(readlink "/sys/class/net/$interface/device/driver" | xargs basename 2>/dev/null || echo "Unknown")
                echo "    Driver: $driver" >> "$REPORT_FILE"
            fi
        fi
    done
    
    if [[ "$ethernet_found" == "true" ]]; then
        if [[ "$ethernet_working" == "true" ]]; then
            echo "  Result: ✅ Ethernet working" >> "$REPORT_FILE"
            set_test_result "ethernet" "✅"
        else
            echo "  Result: ⚠️ Ethernet detected but not active" >> "$REPORT_FILE"
            set_test_result "ethernet" "⚠️" "Interface detected but not active"
        fi
    else
        echo "  Result: ❌ No Ethernet interfaces found" >> "$REPORT_FILE"
        set_test_result "ethernet" "❌" "No Ethernet interfaces detected"
    fi
    echo "" >> "$REPORT_FILE"
    
    # Test WiFi interfaces
    echo "WiFi Testing:" >> "$REPORT_FILE"
    local wifi_found=false
    local wifi_working=false
    
    for interface in $(ip link show 2>/dev/null | grep -E '^[0-9]+:' | grep -E 'wlan|wlp|wls|wlo' | cut -d: -f2 | tr -d ' ' || true); do
        if [[ -n "$interface" ]]; then
            wifi_found=true
            echo "  Interface: $interface" >> "$REPORT_FILE"
            
            # Check if interface exists
            if ip link show "$interface" >/dev/null 2>&1; then
                echo "    Status: Detected" >> "$REPORT_FILE"
                wifi_working=true
                
                # Try to get WiFi information
                if command -v iwconfig >/dev/null 2>&1; then
                    local wifi_info=$(iwconfig "$interface" 2>/dev/null | grep -E "(IEEE|ESSID|Mode)" || echo "No wireless extensions")
                    echo "    Info: $wifi_info" >> "$REPORT_FILE"
                fi
            fi
            
            # Check driver information
            if [[ -e "/sys/class/net/$interface/device/driver" ]]; then
                local driver=$(readlink "/sys/class/net/$interface/device/driver" | xargs basename 2>/dev/null || echo "Unknown")
                echo "    Driver: $driver" >> "$REPORT_FILE"
            fi
        fi
    done
    
    if [[ "$wifi_found" == "true" ]]; then
        if [[ "$wifi_working" == "true" ]]; then
            echo "  Result: ✅ WiFi adapter detected" >> "$REPORT_FILE"
            set_test_result "wifi" "✅"
        else
            echo "  Result: ⚠️ WiFi adapter found but may have issues" >> "$REPORT_FILE"
            set_test_result "wifi" "⚠️" "WiFi adapter detected but may have driver issues"
        fi
    else
        echo "  Result: ❌ No WiFi interfaces found" >> "$REPORT_FILE"
        set_test_result "wifi" "❌" "No WiFi interfaces detected"
    fi
    echo "" >> "$REPORT_FILE"
    
    # Network connectivity test
    echo "Connectivity Testing:" >> "$REPORT_FILE"
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        echo "  Internet: ✅ Connected" >> "$REPORT_FILE"
        set_test_result "connectivity" "✅"
    else
        echo "  Internet: ❌ No connectivity" >> "$REPORT_FILE"
        set_test_result "connectivity" "❌" "No internet connectivity"
    fi
    
    # DNS resolution test
    if nslookup google.com >/dev/null 2>&1; then
        echo "  DNS: ✅ Working" >> "$REPORT_FILE"
    else
        echo "  DNS: ❌ Resolution failed" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    success "Network testing completed"
}

# Audio System Testing
test_audio() {
    progress "Testing audio system..."
    
    cat >> "$REPORT_FILE" << EOF

🔊 AUDIO TESTING
================

Audio Devices:
EOF
    
    local audio_working=false
    
    # ALSA devices
    if command -v aplay >/dev/null 2>&1; then
        echo "ALSA Playback Devices:" >> "$REPORT_FILE"
        local playback_devices=$(aplay -l 2>/dev/null | grep -c "^card" || echo "0")
        if [[ "$playback_devices" -gt 0 ]]; then
            aplay -l >> "$REPORT_FILE" 2>/dev/null
            audio_working=true
        else
            echo "  No playback devices found" >> "$REPORT_FILE"
        fi
        echo "" >> "$REPORT_FILE"
        
        echo "ALSA Capture Devices:" >> "$REPORT_FILE"
        arecord -l >> "$REPORT_FILE" 2>/dev/null || echo "  No capture devices found" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
    
    # PulseAudio status
    echo "PulseAudio Status:" >> "$REPORT_FILE"
    if command -v pulseaudio >/dev/null 2>&1; then
        if pgrep pulseaudio >/dev/null 2>&1; then
            echo "  Service: ✅ Running" >> "$REPORT_FILE"
            
            # Try to get PulseAudio device list
            if command -v pactl >/dev/null 2>&1; then
                echo "  Sinks:" >> "$REPORT_FILE"
                pactl list short sinks >> "$REPORT_FILE" 2>/dev/null || echo "    No sinks found" >> "$REPORT_FILE"
                echo "  Sources:" >> "$REPORT_FILE"
                pactl list short sources >> "$REPORT_FILE" 2>/dev/null || echo "    No sources found" >> "$REPORT_FILE"
            fi
        else
            echo "  Service: ❌ Not running" >> "$REPORT_FILE"
        fi
    else
        echo "  Service: ❌ Not installed" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    # Audio driver information
    echo "Audio Drivers:" >> "$REPORT_FILE"
    if command -v lspci >/dev/null 2>&1; then
        lspci | grep -i audio >> "$REPORT_FILE" 2>/dev/null || echo "  No PCI audio devices found" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    # Test basic audio functionality
    echo "Audio Testing:" >> "$REPORT_FILE"
    if command -v speaker-test >/dev/null 2>&1; then
        # Test for 1 second, suppress output
        if timeout 2 speaker-test -t sine -f 1000 -l 1 >/dev/null 2>&1; then
            echo "  Test: ✅ Basic audio test passed" >> "$REPORT_FILE"
            set_test_result "audio" "✅"
        else
            echo "  Test: ⚠️ Audio test failed (may be normal without speakers)" >> "$REPORT_FILE"
            if [[ "$audio_working" == "true" ]]; then
                set_test_result "audio" "⚠️" "Audio devices detected but test failed (may be normal)"
            else
                set_test_result "audio" "❌" "No audio devices detected"
            fi
        fi
    else
        echo "  Test: ❓ speaker-test not available" >> "$REPORT_FILE"
        if [[ "$audio_working" == "true" ]]; then
            set_test_result "audio" "⚠️" "Audio devices detected but cannot test"
        else
            set_test_result "audio" "❌" "No audio devices detected"
        fi
    fi
    echo "" >> "$REPORT_FILE"
    
    success "Audio testing completed"
}

# Graphics System Testing
test_graphics() {
    progress "Testing graphics system..."
    
    cat >> "$REPORT_FILE" << EOF

🖥️ GRAPHICS TESTING
===================

Graphics Hardware:
EOF
    
    local graphics_working=false
    
    # Graphics cards
    if command -v lspci >/dev/null 2>&1; then
        echo "Graphics Cards:" >> "$REPORT_FILE"
        local gpu_count=$(lspci | grep -i -E "(vga|display|3d)" | wc -l)
        if [[ "$gpu_count" -gt 0 ]]; then
            lspci | grep -i -E "(vga|display|3d)" >> "$REPORT_FILE" 2>/dev/null
            graphics_working=true
        else
            echo "  No graphics cards found" >> "$REPORT_FILE"
        fi
        echo "" >> "$REPORT_FILE"
    fi
    
    # Display detection
    echo "Display Information:" >> "$REPORT_FILE"
    if command -v xrandr >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
        xrandr >> "$REPORT_FILE" 2>/dev/null || echo "  Cannot detect displays (no X session)" >> "$REPORT_FILE"
    else
        echo "  Cannot detect displays (no X session or xrandr unavailable)" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    # Graphics drivers
    echo "Graphics Drivers:" >> "$REPORT_FILE"
    
    # Check loaded graphics modules
    if command -v lsmod >/dev/null 2>&1; then
        echo "  Loaded modules:" >> "$REPORT_FILE"
        local graphics_modules=$(lsmod | grep -E "(i915|amdgpu|nvidia|nouveau|radeon)" | wc -l)
        if [[ "$graphics_modules" -gt 0 ]]; then
            lsmod | grep -E "(i915|amdgpu|nvidia|nouveau|radeon)" >> "$REPORT_FILE" 2>/dev/null
        else
            echo "    No common graphics drivers loaded" >> "$REPORT_FILE"
        fi
    fi
    
    # OpenGL information
    if command -v glxinfo >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
        echo "  OpenGL:" >> "$REPORT_FILE"
        glxinfo | grep -E "(OpenGL vendor|OpenGL renderer|OpenGL version)" >> "$REPORT_FILE" 2>/dev/null || echo "    OpenGL information unavailable" >> "$REPORT_FILE"
    else
        echo "  OpenGL: Cannot test (no X session or glxinfo unavailable)" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    # 3D acceleration test
    echo "3D Acceleration:" >> "$REPORT_FILE"
    if command -v glxgears >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
        if timeout 5 glxgears >/dev/null 2>&1; then
            echo "  Test: ✅ 3D acceleration appears working" >> "$REPORT_FILE"
            set_test_result "graphics" "✅"
        else
            echo "  Test: ⚠️ 3D acceleration test failed" >> "$REPORT_FILE"
            if [[ "$graphics_working" == "true" ]]; then
                set_test_result "graphics" "⚠️" "GPU detected but 3D acceleration test failed"
            else
                set_test_result "graphics" "❌" "No graphics hardware detected"
            fi
        fi
    else
        echo "  Test: ❓ Cannot test (no X session or glxgears unavailable)" >> "$REPORT_FILE"
        if [[ "$graphics_working" == "true" ]]; then
            set_test_result "graphics" "⚠️" "GPU detected but cannot test 3D acceleration"
        else
            set_test_result "graphics" "❌" "No graphics hardware detected"
        fi
    fi
    echo "" >> "$REPORT_FILE"
    
    success "Graphics testing completed"
}

# USB System Testing
test_usb() {
    progress "Testing USB system..."
    
    cat >> "$REPORT_FILE" << EOF

🔌 USB TESTING
==============

USB Controllers:
EOF
    
    local usb_working=false
    
    # USB controllers
    if command -v lspci >/dev/null 2>&1; then
        local usb_controllers=$(lspci | grep -i usb | wc -l)
        if [[ "$usb_controllers" -gt 0 ]]; then
            lspci | grep -i usb >> "$REPORT_FILE" 2>/dev/null
            usb_working=true
        else
            echo "  No USB controllers found" >> "$REPORT_FILE"
        fi
        echo "" >> "$REPORT_FILE"
    fi
    
    # USB devices
    echo "Connected USB Devices:" >> "$REPORT_FILE"
    if command -v lsusb >/dev/null 2>&1; then
        local usb_devices=$(lsusb | wc -l)
        if [[ "$usb_devices" -gt 0 ]]; then
            lsusb >> "$REPORT_FILE" 2>/dev/null
            usb_working=true
        else
            echo "  No USB devices found" >> "$REPORT_FILE"
        fi
    fi
    echo "" >> "$REPORT_FILE"
    
    # USB device tree
    if command -v usb-devices >/dev/null 2>&1; then
        echo "USB Device Tree:" >> "$REPORT_FILE"
        usb-devices >> "$REPORT_FILE" 2>/dev/null || echo "  USB device tree unavailable" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
    
    if [[ "$usb_working" == "true" ]]; then
        set_test_result "usb" "✅"
    else
        set_test_result "usb" "❌" "No USB controllers or devices detected"
    fi
    
    success "USB testing completed"
}

# Power Management Testing (for laptops)
test_power_management() {
    progress "Testing power management..."
    
    cat >> "$REPORT_FILE" << EOF

🔋 POWER MANAGEMENT TESTING
===========================

Battery Information:
EOF
    
    # Check for battery
    local battery_found=false
    local suspend_available=false
    
    if [[ -d "/sys/class/power_supply" ]]; then
        for battery in /sys/class/power_supply/BAT*; do
            if [[ -d "$battery" ]]; then
                battery_found=true
                local bat_name=$(basename "$battery")
                echo "  Battery: $bat_name" >> "$REPORT_FILE"
                
                # Battery status
                if [[ -f "$battery/status" ]]; then
                    echo "    Status: $(cat "$battery/status")" >> "$REPORT_FILE"
                fi
                
                # Battery capacity
                if [[ -f "$battery/capacity" ]]; then
                    echo "    Capacity: $(cat "$battery/capacity")%" >> "$REPORT_FILE"
                fi
                
                # Battery technology
                if [[ -f "$battery/technology" ]]; then
                    echo "    Technology: $(cat "$battery/technology")" >> "$REPORT_FILE"
                fi
                echo "" >> "$REPORT_FILE"
            fi
        done
    fi
    
    if [[ "$battery_found" == "false" ]]; then
        echo "  No batteries detected (desktop system)" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
    
    # AC adapter
    echo "AC Adapter:" >> "$REPORT_FILE"
    local ac_found=false
    if [[ -d "/sys/class/power_supply" ]]; then
        for ac in /sys/class/power_supply/A{C,DP}*; do
            if [[ -d "$ac" ]]; then
                ac_found=true
                local ac_name=$(basename "$ac")
                echo "  Adapter: $ac_name" >> "$REPORT_FILE"
                
                if [[ -f "$ac/online" ]]; then
                    local online=$(cat "$ac/online")
                    if [[ "$online" == "1" ]]; then
                        echo "    Status: ✅ Connected" >> "$REPORT_FILE"
                    else
                        echo "    Status: ❌ Disconnected" >> "$REPORT_FILE"
                    fi
                fi
            fi
        done
    fi
    
    if [[ "$ac_found" == "false" ]]; then
        echo "  No AC adapter detected" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    # Suspend/resume support
    echo "Power States:" >> "$REPORT_FILE"
    if [[ -f "/sys/power/state" ]]; then
        local power_states=$(cat /sys/power/state)
        echo "  Available: $power_states" >> "$REPORT_FILE"
        if echo "$power_states" | grep -q "mem"; then
            suspend_available=true
        fi
    else
        echo "  Power state information unavailable" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    # Set power management test result
    if [[ "$battery_found" == "true" ]] && [[ "$suspend_available" == "true" ]]; then
        set_test_result "power_mgmt" "✅"
    elif [[ "$battery_found" == "true" ]] || [[ "$suspend_available" == "true" ]]; then
        set_test_result "power_mgmt" "⚠️" "Partial power management support"
    else
        set_test_result "power_mgmt" "❌" "No power management features detected"
    fi
    
    success "Power management testing completed"
}

# Additional Hardware Testing
test_additional_hardware() {
    progress "Testing additional hardware..."
    
    cat >> "$REPORT_FILE" << EOF

📷 ADDITIONAL HARDWARE TESTING
===============================

Webcam/Camera:
EOF
    
    # Camera devices
    local camera_found=false
    for video_dev in /dev/video*; do
        if [[ -c "$video_dev" ]]; then
            camera_found=true
            echo "  Device: $video_dev" >> "$REPORT_FILE"
            
            # Try to get device info
            if command -v v4l2-ctl >/dev/null 2>&1; then
                local device_info=$(v4l2-ctl --device="$video_dev" --info 2>/dev/null | grep -E "(Card type|Driver name)" || echo "Info unavailable")
                echo "    $device_info" >> "$REPORT_FILE"
            fi
        fi
    done
    
    if [[ "$camera_found" == "false" ]]; then
        echo "  No camera devices found" >> "$REPORT_FILE"
        set_test_result "camera" "❌" "No camera devices detected"
    else
        set_test_result "camera" "✅"
    fi
    echo "" >> "$REPORT_FILE"
    
    # Bluetooth
    echo "Bluetooth:" >> "$REPORT_FILE"
    local bluetooth_working=false
    if command -v bluetoothctl >/dev/null 2>&1; then
        if systemctl is-active bluetooth >/dev/null 2>&1; then
            echo "  Service: ✅ Running" >> "$REPORT_FILE"
            echo "  Controllers:" >> "$REPORT_FILE"
            local bt_controllers=$(bluetoothctl list 2>/dev/null | wc -l)
            if [[ "$bt_controllers" -gt 0 ]]; then
                bluetoothctl list >> "$REPORT_FILE" 2>/dev/null
                bluetooth_working=true
            else
                echo "    No controllers found" >> "$REPORT_FILE"
            fi
        else
            echo "  Service: ❌ Not running" >> "$REPORT_FILE"
        fi
    else
        echo "  Service: ❌ Not installed" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    if [[ "$bluetooth_working" == "true" ]]; then
        set_test_result "bluetooth" "✅"
    else
        set_test_result "bluetooth" "❌" "Bluetooth service not running or no controllers"
    fi
    
    # Thermal monitoring
    echo "Thermal Sensors:" >> "$REPORT_FILE"
    if command -v sensors >/dev/null 2>&1; then
        sensors >> "$REPORT_FILE" 2>/dev/null || echo "  No thermal sensors detected" >> "$REPORT_FILE"
    else
        echo "  sensors command not available" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    success "Additional hardware testing completed"
}

# Generate markdown snippet for easy copy-paste
generate_markdown_snippet() {
    progress "Generating markdown snippet for hardware matrix..."
    
    # Determine the appropriate table based on platform type
    local table_section=""
    local table_row=""
    
    case "$PLATFORM_TYPE" in
        "Virtual Machine")
            table_section="Virtualization Platforms"
            # Determine CPU architecture
            local cpu_arch="x86_64"
            if echo "$CPU_MODEL" | grep -qi "arm\|aarch64\|m1\|m2"; then
                cpu_arch="ARM64"
            fi
            
            table_row="| **$VM_PLATFORM** 🆕 | Latest | $cpu_arch | $RAM_SIZE | ✅/✅ | ${TEST_RESULTS[connectivity]:-❓} | ${TEST_RESULTS[connectivity]:-❓} | ${TEST_RESULTS[ethernet]:-❓} | ${TEST_RESULTS[audio]:-❓} | ${TEST_RESULTS[graphics]:-❓} | ✅ | ${TEST_RESULTS[power_mgmt]:-❓} | ${TEST_ISSUES[connectivity]:-}${TEST_ISSUES[ethernet]:-}${TEST_ISSUES[audio]:-}${TEST_ISSUES[graphics]:-} | $(date '+%Y-%m-%d') | $TESTER_INITIALS |"
            ;;
        "Cloud Instance")
            table_section="Cloud Providers"
            table_row="| **$VM_PLATFORM** 🆕 | Standard | 2 vCPU | $RAM_SIZE | ${STORAGE_TYPE} | ${TEST_RESULTS[ethernet]:-❓} | ${TEST_RESULTS[connectivity]:-❓} | ~60s | No GUI support (headless) | $(date '+%Y-%m-%d') | $TESTER_INITIALS |"
            ;;
        "Physical Hardware")
            # Determine if laptop or desktop based on power management
            if [[ "${TEST_RESULTS[power_mgmt]:-}" == "✅" ]] || echo "$HARDWARE_MODEL" | grep -qi "laptop\|thinkpad\|macbook\|xps\|elitebook"; then
                table_section="Physical Hardware - Laptops"
                table_row="| **$HARDWARE_BRAND $HARDWARE_MODEL** 🆕 | $CPU_MODEL | $GPU_MODEL | $RAM_SIZE $RAM_TYPE | $STORAGE_SIZE $STORAGE_TYPE | $WIFI_CHIPSET | $ETHERNET_CONTROLLER | ✅/✅ | ${TEST_RESULTS[connectivity]:-❓} | ${TEST_RESULTS[connectivity]:-❓} | ${TEST_RESULTS[wifi]:-❓} | ${TEST_RESULTS[audio]:-❓} | ${TEST_RESULTS[graphics]:-❓} | ✅ | ${TEST_RESULTS[camera]:-❓} | ${TEST_RESULTS[power_mgmt]:-❓} | $ADDITIONAL_NOTES | $(date '+%Y-%m-%d') | $TESTER_INITIALS |"
            else
                table_section="Physical Hardware - Desktops"
                table_row="| **$HARDWARE_BRAND $HARDWARE_MODEL** 🆕 | $CPU_MODEL | $GPU_MODEL | $RAM_SIZE $RAM_TYPE | $STORAGE_SIZE $STORAGE_TYPE | $WIFI_CHIPSET | $ETHERNET_CONTROLLER | Audio System | ✅/✅ | ${TEST_RESULTS[connectivity]:-❓} | ${TEST_RESULTS[connectivity]:-❓} | ${TEST_RESULTS[ethernet]:-❓} | ${TEST_RESULTS[audio]:-❓} | ${TEST_RESULTS[graphics]:-❓} | ${TEST_RESULTS[usb]:-❓} | ✅ | $ADDITIONAL_NOTES | $(date '+%Y-%m-%d') | $TESTER_INITIALS |"
            fi
            ;;
        *)
            table_section="General Hardware"
            table_row="| **$HARDWARE_BRAND $HARDWARE_MODEL** 🆕 | $CPU_MODEL | $GPU_MODEL | $RAM_SIZE | $STORAGE_SIZE | ${TEST_RESULTS[ethernet]:-❓} | ${TEST_RESULTS[wifi]:-❓} | ${TEST_RESULTS[audio]:-❓} | ${TEST_RESULTS[graphics]:-❓} | $ADDITIONAL_NOTES | $(date '+%Y-%m-%d') | $TESTER_INITIALS |"
            ;;
    esac
    
    cat > "$MARKDOWN_FILE" << EOF
# 🌸 Hardware Compatibility Report - $HARDWARE_BRAND $HARDWARE_MODEL

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')  
**Platform**: $PLATFORM_TYPE$([ -n "$VM_PLATFORM" ] && echo " ($VM_PLATFORM)")  
**Tester**: $TESTER_INITIALS

## 📋 Quick Copy-Paste for Hardware Matrix

Add this row to the **$table_section** table in \`docs/hardware_matrix.md\`:

\`\`\`markdown
$table_row
\`\`\`

## 📊 Test Results Summary

| Component | Status | Notes |
|-----------|--------|-------|
$(for component in ethernet wifi audio graphics usb power_mgmt camera bluetooth connectivity; do
    if [[ -n "${TEST_RESULTS[$component]:-}" ]]; then
        echo "| $(echo $component | tr '_' ' ' | tr '[:lower:]' '[:upper:]') | ${TEST_RESULTS[$component]} | ${TEST_ISSUES[$component]:-} |"
    fi
done)

## 🔧 Hardware Specifications

- **Brand/Model**: $HARDWARE_BRAND $HARDWARE_MODEL ($HARDWARE_YEAR)
- **Platform**: $PLATFORM_TYPE$([ -n "$VM_PLATFORM" ] && echo " ($VM_PLATFORM)")
- **CPU**: $CPU_MODEL
- **RAM**: $RAM_SIZE $RAM_TYPE  
- **Storage**: $STORAGE_SIZE $STORAGE_TYPE
- **WiFi**: $WIFI_CHIPSET
- **Ethernet**: $ETHERNET_CONTROLLER
- **GPU**: $GPU_MODEL

## 📝 Additional Notes

$ADDITIONAL_NOTES

## 📄 Full Report

For complete technical details, see: \`$REPORT_FILE\`

---

*Generated by KawaiiSec OS Hardware Testing Script v2.0* 🌸

**Next Steps:**
1. Review the test results above
2. Copy the table row and add it to \`docs/hardware_matrix.md\`
3. Submit a PR or create an issue with your results
4. Thank you for contributing to KawaiiSec OS! 

**Useful Links:**
- [Hardware Matrix Documentation](docs/hardware_matrix.md)
- [GitHub Repository](https://github.com/your-org/KawaiiSec-OS)
- [Community Forum](https://forum.kawaiisec.com)
EOF

    success "Markdown snippet generated: $MARKDOWN_FILE"
}

# Analyze drivers and kernel modules
analyze_drivers() {
    progress "Analyzing drivers and kernel modules..."
    
    cat >> "$REPORT_FILE" << EOF

🔧 DRIVER AND MODULE ANALYSIS
=============================

Loaded Kernel Modules:
EOF
    
    if command -v lsmod >/dev/null 2>&1; then
        echo "Total modules loaded: $(lsmod | wc -l)" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        echo "Network Drivers:" >> "$REPORT_FILE"
        lsmod | grep -E "(e1000|igb|ixgbe|r8169|iwlwifi|ath|rtl|mt76)" >> "$REPORT_FILE" 2>/dev/null || echo "  No common network drivers loaded" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        echo "Graphics Drivers:" >> "$REPORT_FILE"
        lsmod | grep -E "(i915|amdgpu|nvidia|nouveau|radeon)" >> "$REPORT_FILE" 2>/dev/null || echo "  No common graphics drivers loaded" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        echo "Audio Drivers:" >> "$REPORT_FILE"
        lsmod | grep -E "(snd_|alsa)" >> "$REPORT_FILE" 2>/dev/null || echo "  No ALSA drivers loaded" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        echo "USB Drivers:" >> "$REPORT_FILE"
        lsmod | grep -E "(usb|hid)" | head -10 >> "$REPORT_FILE" 2>/dev/null || echo "  No USB drivers loaded" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
    
    # Firmware status
    echo "Firmware Status:" >> "$REPORT_FILE"
    if dmesg | grep -i firmware >/dev/null 2>&1; then
        echo "Recent firmware messages:" >> "$REPORT_FILE"
        dmesg | grep -i firmware | tail -10 >> "$REPORT_FILE" 2>/dev/null || true
    else
        echo "  No firmware messages in dmesg" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    success "Driver analysis completed"
}

# Generate test summary
generate_summary() {
    progress "Generating test summary..."
    
    cat >> "$REPORT_FILE" << EOF

📋 TEST SUMMARY
===============

Compatibility Assessment:
EOF
    
    # Count different status types by analyzing the test results
    local total_tests=0
    local working_tests=0
    local partial_tests=0
    local failed_tests=0
    
    for result in "${TEST_RESULTS[@]}"; do
        ((total_tests++))
        case "$result" in
            "✅") ((working_tests++));;
            "⚠️") ((partial_tests++));;
            "❌") ((failed_tests++));;
        esac
    done
    
    echo "  Total Tests: $total_tests" >> "$REPORT_FILE"
    echo "  Working: $working_tests ($(( total_tests > 0 ? working_tests * 100 / total_tests : 0 ))%)" >> "$REPORT_FILE"
    echo "  Partial: $partial_tests ($(( total_tests > 0 ? partial_tests * 100 / total_tests : 0 ))%)" >> "$REPORT_FILE"
    echo "  Failed: $failed_tests ($(( total_tests > 0 ? failed_tests * 100 / total_tests : 0 ))%)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Overall compatibility rating
    if [[ $total_tests -gt 0 ]]; then
        local working_percentage=$(( working_tests * 100 / total_tests ))
        
        if [[ $working_percentage -ge 90 ]]; then
            echo "  Overall Rating: ✅ Excellent Compatibility" >> "$REPORT_FILE"
        elif [[ $working_percentage -ge 70 ]]; then
            echo "  Overall Rating: ⚠️ Good Compatibility" >> "$REPORT_FILE"
        elif [[ $working_percentage -ge 50 ]]; then
            echo "  Overall Rating: ⚠️ Fair Compatibility" >> "$REPORT_FILE"
        else
            echo "  Overall Rating: ❌ Poor Compatibility" >> "$REPORT_FILE"
        fi
    else
        echo "  Overall Rating: ❓ Unable to determine" >> "$REPORT_FILE"
    fi
    
    echo "" >> "$REPORT_FILE"
    
    # Recommendations based on test results
    echo "Recommendations:" >> "$REPORT_FILE"
    
    if [[ "${TEST_RESULTS[wifi]:-}" == "❌" ]]; then
        echo "  - Install additional WiFi firmware packages" >> "$REPORT_FILE"
        echo "  - Consider USB WiFi adapter if internal WiFi unsupported" >> "$REPORT_FILE"
    fi
    
    if [[ "${TEST_RESULTS[audio]:-}" == "❌" ]]; then
        echo "  - Check ALSA mixer settings" >> "$REPORT_FILE"
        echo "  - Install additional audio codecs" >> "$REPORT_FILE"
    fi
    
    if [[ "${TEST_RESULTS[graphics]:-}" == "❌" ]]; then
        echo "  - Install proprietary GPU drivers if available" >> "$REPORT_FILE"
        echo "  - Check for BIOS/UEFI graphics settings" >> "$REPORT_FILE"
    fi
    
    if grep -q "firmware" <<< "${TEST_ISSUES[@]:-}"; then
        echo "  - Install firmware-linux-nonfree package" >> "$REPORT_FILE"
        echo "  - Check manufacturer website for latest drivers" >> "$REPORT_FILE"
    fi
    
    echo "  - Report results to KawaiiSec OS hardware compatibility matrix" >> "$REPORT_FILE"
    echo "  - Consider contributing to improve hardware support" >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
    
    success "Test summary generated"
}

# Save reports to hardware_reports directory
save_reports() {
    progress "Saving reports to hardware_reports directory..."
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local hw_identifier="${HARDWARE_BRAND}_${HARDWARE_MODEL}"
    hw_identifier=$(echo "$hw_identifier" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
    
    local report_basename="${hw_identifier}_${timestamp}"
    
    # Save to current directory's hardware_reports
    if [[ -d "$REPORTS_DIR" ]]; then
        cp "$REPORT_FILE" "$REPORTS_DIR/${report_basename}_report.txt"
        cp "$MARKDOWN_FILE" "$REPORTS_DIR/${report_basename}_snippet.md"
        
        success "Reports saved to $REPORTS_DIR/"
    fi
    
    # Save to home directory's hardware_reports  
    if [[ -d "$HOME/$REPORTS_DIR" ]]; then
        cp "$REPORT_FILE" "$HOME/$REPORTS_DIR/${report_basename}_report.txt"
        cp "$MARKDOWN_FILE" "$HOME/$REPORTS_DIR/${report_basename}_snippet.md"
        
        success "Reports saved to $HOME/$REPORTS_DIR/"
    fi
    
    echo -e "${CYAN}📁 Report files created:${NC}"
    echo "  - Detailed report: $REPORT_FILE"
    echo "  - Markdown snippet: $MARKDOWN_FILE"
    echo "  - Archive copies: $REPORTS_DIR/${report_basename}_*"
}

# Display results summary
display_results() {
    echo ""
    echo -e "${PURPLE}🌸 KawaiiSec OS Hardware Test Complete! 🌸${NC}"
    echo ""
    echo -e "${BLUE}📊 Report Summary:${NC}"
    echo -e "  📄 Full report: ${CYAN}$REPORT_FILE${NC}"
    echo -e "  📝 Markdown snippet: ${CYAN}$MARKDOWN_FILE${NC}"
    echo -e "  📂 Archived reports: ${CYAN}$REPORTS_DIR/${NC}"
    echo -e "  📋 Log file: ${CYAN}$LOG_FILE${NC}"
    echo ""
    
    # Display quick summary
    local total_tests=${#TEST_RESULTS[@]}
    local working_tests=0
    local failed_tests=0
    
    for result in "${TEST_RESULTS[@]}"; do
        case "$result" in
            "✅") ((working_tests++));;
            "❌") ((failed_tests++));;
        esac
    done
    
    if [[ $total_tests -gt 0 ]]; then
        local working_percentage=$(( working_tests * 100 / total_tests ))
        echo -e "${BLUE}🎯 Compatibility Score: ${GREEN}$working_percentage%${NC} ($working_tests/$total_tests tests passed)"
    fi
    
    echo ""
    echo -e "${YELLOW}📤 Next Steps:${NC}"
    echo "  1. Review the markdown snippet: $MARKDOWN_FILE"
    echo "  2. Copy the table row from the snippet into docs/hardware_matrix.md"
    echo "  3. Submit a GitHub PR or create an issue with your results"
    echo "  4. Visit: https://github.com/your-org/KawaiiSec-OS"
    echo ""
    echo -e "${GREEN}🙏 Thank you for helping improve KawaiiSec OS hardware support!${NC}"
}

# Write report footer
write_report_footer() {
    cat >> "$REPORT_FILE" << EOF

📞 SUPPORT AND CONTRIBUTION
===========================

To contribute this hardware report:
1. Visit: https://github.com/your-org/KawaiiSec-OS
2. Fork the repository and edit docs/hardware_matrix.md
3. Add your hardware details to the appropriate table using: $MARKDOWN_FILE
4. Submit a pull request with this report attached

For support:
- Documentation: https://kawaiisec.com/docs
- Community Forum: https://forum.kawaiisec.com
- Discord: https://discord.gg/kawaiisec
- Email: hardware@kawaiisec.org

Generated by KawaiiSec OS Hardware Testing Script v2.0
Report saved to: $REPORT_FILE
Markdown snippet: $MARKDOWN_FILE

🌸 Thank you for contributing to KawaiiSec OS! 🌸
EOF
}

# Main function
main() {
    # Check for help flag
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        echo -e "${PURPLE}🌸 KawaiiSec OS Hardware Testing Script v2.0${NC}"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -h, --help       Show this help message"
        echo "  --quick          Run quick tests only (skip detailed analysis)"
        echo "  --no-root        Skip tests requiring root privileges"
        echo "  --no-prompts     Skip interactive hardware information prompts"
        echo ""
        echo "This script performs comprehensive hardware compatibility testing"
        echo "and generates detailed reports plus markdown snippets for easy"
        echo "contribution to the KawaiiSec OS hardware compatibility matrix."
        echo ""
        echo "Reports will be saved to:"
        echo "  - Detailed report: $REPORT_FILE"
        echo "  - Markdown snippet: $MARKDOWN_FILE"
        echo "  - Archive: $REPORTS_DIR/"
        exit 0
    fi
    
    # Check if quick mode requested
    local quick_mode=false
    local skip_root=false
    local skip_prompts=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --quick)
                quick_mode=true
                shift
                ;;
            --no-root)
                skip_root=true
                shift
                ;;
            --no-prompts)
                skip_prompts=true
                shift
                ;;
            *)
                warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    # Welcome message
    echo -e "${PURPLE}"
    echo "╭─────────────────────────────────────────╮"
    echo "│     🌸 KawaiiSec OS Hardware Test 🌸    │"
    echo "│       Compatibility Assessment v2.0     │"
    echo "╰─────────────────────────────────────────╯"
    echo -e "${NC}"
    
    # Check root requirements
    if [[ "$skip_root" == "false" ]]; then
        check_root optional
    fi
    
    # Setup trap for cleanup
    trap cleanup EXIT
    
    # Initialize testing environment
    init_testing
    
    # Collect hardware information from user
    if [[ "$skip_prompts" == "false" ]]; then
        collect_hardware_info
    else
        # Set default values for non-interactive mode
        HARDWARE_BRAND="Unknown"
        HARDWARE_MODEL="Unknown"
        HARDWARE_YEAR="Unknown"
        PLATFORM_TYPE="Unknown"
        CPU_MODEL="Auto-detected"
        RAM_SIZE="Auto-detected"
        TESTER_INITIALS="AUTO"
        ADDITIONAL_NOTES="Generated in non-interactive mode"
    fi
    
    # Run tests
    write_report_header
    collect_system_info
    test_networking
    test_audio
    test_graphics
    test_usb
    test_power_management
    test_additional_hardware
    
    if [[ "$quick_mode" == "false" ]]; then
        analyze_drivers
    fi
    
    generate_summary
    generate_markdown_snippet
    write_report_footer
    save_reports
    
    # Display results
    display_results
    
    log "Hardware testing completed successfully"
    success "Hardware testing completed! Reports saved and ready for submission."
}

# Run main function with all arguments
main "$@" 