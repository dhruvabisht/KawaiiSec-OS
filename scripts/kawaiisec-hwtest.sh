#!/bin/bash

# KawaiiSec OS Hardware Testing and Compatibility Report Generator
# Performs comprehensive hardware detection and testing for compatibility matrix

set -euo pipefail

# Configuration
REPORT_FILE="$HOME/kawaiisec_hw_report.txt"
TEMP_DIR="/tmp/kawaiisec-hwtest-$$"
LOG_FILE="/var/log/kawaiisec-hwtest.log"

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# Initialize testing environment
init_testing() {
    progress "Initializing KawaiiSec OS Hardware Testing..."
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    # Create log file if it doesn't exist
    if check_root optional; then
        touch "$LOG_FILE" 2>/dev/null || true
    fi
    
    # Clear previous report
    > "$REPORT_FILE"
    
    success "Testing environment initialized"
}

# Write report header
write_report_header() {
    cat > "$REPORT_FILE" << EOF
🌸 KawaiiSec OS Hardware Compatibility Report
==============================================

Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')
Hostname: $(hostname)
User: $(whoami)
Kernel: $(uname -r)
Distribution: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")

Test Results Summary:
EOF
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
        else
            echo "  Result: ⚠️ Ethernet detected but not active" >> "$REPORT_FILE"
        fi
    else
        echo "  Result: ❌ No Ethernet interfaces found" >> "$REPORT_FILE"
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
        else
            echo "  Result: ⚠️ WiFi adapter found but may have issues" >> "$REPORT_FILE"
        fi
    else
        echo "  Result: ❌ No WiFi interfaces found" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    # Network connectivity test
    echo "Connectivity Testing:" >> "$REPORT_FILE"
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        echo "  Internet: ✅ Connected" >> "$REPORT_FILE"
    else
        echo "  Internet: ❌ No connectivity" >> "$REPORT_FILE"
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
    
    # ALSA devices
    if command -v aplay >/dev/null 2>&1; then
        echo "ALSA Playback Devices:" >> "$REPORT_FILE"
        aplay -l >> "$REPORT_FILE" 2>/dev/null || echo "  No playback devices found" >> "$REPORT_FILE"
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
        else
            echo "  Test: ⚠️ Audio test failed (may be normal without speakers)" >> "$REPORT_FILE"
        fi
    else
        echo "  Test: ❓ speaker-test not available" >> "$REPORT_FILE"
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
    
    # Graphics cards
    if command -v lspci >/dev/null 2>&1; then
        echo "Graphics Cards:" >> "$REPORT_FILE"
        lspci | grep -i -E "(vga|display|3d)" >> "$REPORT_FILE" 2>/dev/null || echo "  No graphics cards found" >> "$REPORT_FILE"
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
        lsmod | grep -E "(i915|amdgpu|nvidia|nouveau|radeon)" >> "$REPORT_FILE" 2>/dev/null || echo "    No common graphics drivers loaded" >> "$REPORT_FILE"
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
        else
            echo "  Test: ⚠️ 3D acceleration test failed" >> "$REPORT_FILE"
        fi
    else
        echo "  Test: ❓ Cannot test (no X session or glxgears unavailable)" >> "$REPORT_FILE"
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
    
    # USB controllers
    if command -v lspci >/dev/null 2>&1; then
        lspci | grep -i usb >> "$REPORT_FILE" 2>/dev/null || echo "  No USB controllers found" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
    
    # USB devices
    echo "Connected USB Devices:" >> "$REPORT_FILE"
    if command -v lsusb >/dev/null 2>&1; then
        lsusb >> "$REPORT_FILE" 2>/dev/null || echo "  No USB devices found" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    # USB device tree
    if command -v usb-devices >/dev/null 2>&1; then
        echo "USB Device Tree:" >> "$REPORT_FILE"
        usb-devices >> "$REPORT_FILE" 2>/dev/null || echo "  USB device tree unavailable" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
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
        echo "  Available: $(cat /sys/power/state)" >> "$REPORT_FILE"
    else
        echo "  Power state information unavailable" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
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
    fi
    echo "" >> "$REPORT_FILE"
    
    # Bluetooth
    echo "Bluetooth:" >> "$REPORT_FILE"
    if command -v bluetoothctl >/dev/null 2>&1; then
        if systemctl is-active bluetooth >/dev/null 2>&1; then
            echo "  Service: ✅ Running" >> "$REPORT_FILE"
            echo "  Controllers:" >> "$REPORT_FILE"
            bluetoothctl list >> "$REPORT_FILE" 2>/dev/null || echo "    No controllers found" >> "$REPORT_FILE"
        else
            echo "  Service: ❌ Not running" >> "$REPORT_FILE"
        fi
    else
        echo "  Service: ❌ Not installed" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
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

# Kernel Module and Driver Analysis
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
    
    # Count different status types by analyzing the report
    local total_tests=0
    local working_tests=0
    local partial_tests=0
    local failed_tests=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ ✅ ]]; then
            ((working_tests++))
            ((total_tests++))
        elif [[ "$line" =~ ⚠️ ]]; then
            ((partial_tests++))
            ((total_tests++))
        elif [[ "$line" =~ ❌ ]]; then
            ((failed_tests++))
            ((total_tests++))
        fi
    done < "$REPORT_FILE"
    
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
    
    # Recommendations
    echo "Recommendations:" >> "$REPORT_FILE"
    
    # Check for common issues and provide recommendations
    if grep -q "❌.*WiFi" "$REPORT_FILE"; then
        echo "  - Install additional WiFi firmware packages" >> "$REPORT_FILE"
        echo "  - Consider USB WiFi adapter if internal WiFi unsupported" >> "$REPORT_FILE"
    fi
    
    if grep -q "❌.*Audio" "$REPORT_FILE"; then
        echo "  - Check ALSA mixer settings" >> "$REPORT_FILE"
        echo "  - Install additional audio codecs" >> "$REPORT_FILE"
    fi
    
    if grep -q "❌.*Graphics" "$REPORT_FILE"; then
        echo "  - Install proprietary GPU drivers if available" >> "$REPORT_FILE"
        echo "  - Check for BIOS/UEFI graphics settings" >> "$REPORT_FILE"
    fi
    
    if grep -q "⚠️.*firmware" "$REPORT_FILE"; then
        echo "  - Install firmware-linux-nonfree package" >> "$REPORT_FILE"
        echo "  - Check manufacturer website for latest drivers" >> "$REPORT_FILE"
    fi
    
    echo "  - Report results to KawaiiSec OS hardware compatibility matrix" >> "$REPORT_FILE"
    echo "  - Consider contributing to improve hardware support" >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
    
    success "Test summary generated"
}

# Write report footer
write_report_footer() {
    cat >> "$REPORT_FILE" << EOF

📞 SUPPORT AND CONTRIBUTION
===========================

To contribute this hardware report:
1. Visit: https://github.com/your-org/KawaiiSec-OS
2. Fork the repository and edit docs/hardware_matrix.md
3. Add your hardware details to the appropriate table
4. Submit a pull request with this report attached

For support:
- Documentation: https://kawaiisec.com/docs
- Community Forum: https://forum.kawaiisec.com
- Discord: https://discord.gg/kawaiisec
- Email: hardware@kawaiisec.org

Generated by KawaiiSec OS Hardware Testing Script v1.0
Report saved to: $REPORT_FILE

🌸 Thank you for contributing to KawaiiSec OS! 🌸
EOF
}

# Display results summary
display_results() {
    echo ""
    echo -e "${PURPLE}🌸 KawaiiSec OS Hardware Test Complete! 🌸${NC}"
    echo ""
    echo -e "${BLUE}📊 Report Summary:${NC}"
    echo -e "  📄 Full report: ${CYAN}$REPORT_FILE${NC}"
    echo -e "  📝 Log file: ${CYAN}$LOG_FILE${NC}"
    echo ""
    
    # Display quick summary
    local total_tests=0
    local working_tests=0
    local failed_tests=0
    
    while IFS= read -r line; do
        if [[ "$line" =~ ✅ ]]; then
            ((working_tests++))
            ((total_tests++))
        elif [[ "$line" =~ ❌ ]]; then
            ((failed_tests++))
            ((total_tests++))
        fi
    done < "$REPORT_FILE"
    
    if [[ $total_tests -gt 0 ]]; then
        local working_percentage=$(( working_tests * 100 / total_tests ))
        echo -e "${BLUE}🎯 Compatibility Score: ${GREEN}$working_percentage%${NC} ($working_tests/$total_tests tests passed)"
    fi
    
    echo ""
    echo -e "${YELLOW}📤 Next Steps:${NC}"
    echo "  1. Review the detailed report at $REPORT_FILE"
    echo "  2. Submit your results to the hardware compatibility matrix"
    echo "  3. Visit: https://github.com/your-org/KawaiiSec-OS/docs/hardware_matrix.md"
    echo ""
    echo -e "${GREEN}🙏 Thank you for helping improve KawaiiSec OS hardware support!${NC}"
}

# Main function
main() {
    # Check for help flag
    if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        echo -e "${PURPLE}🌸 KawaiiSec OS Hardware Testing Script${NC}"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -h, --help     Show this help message"
        echo "  --quick        Run quick tests only (skip detailed analysis)"
        echo "  --no-root      Skip tests requiring root privileges"
        echo ""
        echo "This script performs comprehensive hardware compatibility testing"
        echo "and generates a detailed report for the KawaiiSec OS hardware matrix."
        echo ""
        echo "Report will be saved to: $REPORT_FILE"
        exit 0
    fi
    
    # Check if quick mode requested
    local quick_mode=false
    local skip_root=false
    
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
    echo "│       Compatibility Assessment          │"
    echo "╰─────────────────────────────────────────╯"
    echo -e "${NC}"
    
    # Check root requirements
    if [[ "$skip_root" == "false" ]]; then
        check_root optional
    fi
    
    # Setup trap for cleanup
    trap cleanup EXIT
    
    # Run tests
    init_testing
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
    write_report_footer
    
    # Display results
    display_results
    
    log "Hardware testing completed successfully"
    success "Hardware testing completed! Report saved to $REPORT_FILE"
}

# Run main function with all arguments
main "$@" 