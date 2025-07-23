#!/bin/bash

# pinkmap.sh — Cute Nmap Wrapper with Sound Effects 
# 🌸 KawaiiSec OS v0.2 — Terminal Glow-up Edition 🌸
# Supports macOS and Linux with kawaii sound effects!

# Kawaii color palette
PINK='\033[1;35m'
PURPLE='\033[1;95m' 
CYAN='\033[1;36m'
MINT='\033[1;92m'
PEACH='\033[1;93m'
GRAY='\033[1;90m'
WHITE='\033[1;97m'
RESET='\033[0m'

# Kawaii banner with ASCII art
show_banner() {
    echo -e "${PINK}"
    cat << "EOF"
    ╔══════════════════════════════════════════════╗
    ║           🌸 pinkmap v0.2 🌸                ║
    ║      Powered by NMAP + KawaiiSec OS         ║
    ║     Scanning with style, nyaa~ 💻💖        ║
    ╚══════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
}

# Source the KawaiiSec audio system
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../audio/kawaii-audio.sh" ]]; then
    source "${SCRIPT_DIR}/../audio/kawaii-audio.sh"
    KAWAII_AUDIO_ENABLED=true
else
    echo -e "${GRAY}🔇 KawaiiSec audio system not found - sound disabled${RESET}"
    KAWAII_AUDIO_ENABLED=false
fi

# Show usage with kawaii styling
show_usage() {
    echo -e "${CYAN}✨ Usage:${RESET}"
    echo -e "  ${WHITE}$0 <target-ip> [nmap-args]${RESET}"
    echo -e ""
    echo -e "${PINK}Examples:${RESET}"
    echo -e "  ${GRAY}$0 192.168.1.1${RESET}                    # Basic scan"
    echo -e "  ${GRAY}$0 192.168.1.1 -sS -O${RESET}            # SYN scan with OS detection"  
    echo -e "  ${GRAY}$0 192.168.1.0/24 -sn${RESET}            # Ping sweep"
    echo -e ""
    echo -e "${PURPLE}🌸 Stay cute, stay ethical! 💖${RESET}"
}

# Main execution
main() {
    # Show kawaii banner
    show_banner
    
    # Check for target argument
    if [ -z "$1" ]; then
        show_usage
        exit 1
    fi
    
    # Check if nmap is installed
    if ! command -v nmap >/dev/null 2>&1; then
        echo -e "${PINK}❌ Error: nmap is not installed!${RESET}"
        echo -e "${CYAN}💡 Install with: sudo apt install nmap (Linux) or brew install nmap (macOS)${RESET}"
        exit 1
    fi
    
    # Initialize audio system
    if [[ "$KAWAII_AUDIO_ENABLED" == true ]]; then
        echo -e "${MINT}🎵 KawaiiSec audio system ready!${RESET}"
    fi
    
    # Create temp file for output
    temp_file=$(mktemp /tmp/pinkmap-XXXXXX.txt)
    trap 'rm -f "$temp_file"' EXIT
    
    # Show scan info
    echo -e "${PEACH}🎯 Target: ${WHITE}$1${RESET}"
    echo -e "${PEACH}⚡ Args: ${WHITE}${*:2}${RESET}"
    echo -e "${MINT}🚀 Starting scan... Please wait nyaa~${RESET}"
    echo ""
    
    # Run nmap with kawaii progress
    echo -e "${PURPLE}╔══════════════════════════════════════════════╗${RESET}"
    echo -e "${PURPLE}║                 SCAN RESULTS                 ║${RESET}" 
    echo -e "${PURPLE}╚══════════════════════════════════════════════╝${RESET}"
    
    # Execute nmap and capture output
    if nmap_output=$(nmap "$@" 2>&1 | tee "$temp_file"); then
        echo -e "${PURPLE}╔══════════════════════════════════════════════╗${RESET}"
        echo -e "${PURPLE}║                 SCAN COMPLETE                ║${RESET}"
        echo -e "${PURPLE}╚══════════════════════════════════════════════╝${RESET}"
        
        # Check for open ports and play sound
        if grep -qi "open" "$temp_file"; then
            echo -e "${PINK}✨ NANI?! OPEN PORTS FOUND! ✨${RESET}"
            echo -e "${MINT}🎉 Time to investigate further~ 💖${RESET}"
            if [[ "$KAWAII_AUDIO_ENABLED" == true ]]; then
                kawaii_nani
            fi
        else
            echo -e "${CYAN}🛡️  No open ports detected - Target is well protected!${RESET}"
            echo -e "${GRAY}💤 Nothing suspicious here, moving on...${RESET}"
            if [[ "$KAWAII_AUDIO_ENABLED" == true ]]; then
                kawaii_did_it
            fi
        fi
    else
        echo -e "${PINK}❌ Scan failed! Check your target and permissions.${RESET}"
        if [[ "$KAWAII_AUDIO_ENABLED" == true ]]; then
            kawaii_nani
        fi
        exit 1
    fi
    
    # Kawaii goodbye message
    echo ""
    echo -e "${PURPLE}🌸 Scan complete! Remember to hack responsibly~ 💖${RESET}"
    echo -e "${GRAY}   Report generated: $(date)${RESET}"
}

# Run main function with all arguments
main "$@" 