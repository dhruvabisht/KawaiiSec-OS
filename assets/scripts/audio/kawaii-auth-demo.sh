#!/bin/bash

# kawaii-auth-demo.sh — Authentication Demo with KawaiiSec Audio Integration
# 🌸 Demonstrates proper password validation with audio feedback

# Source the KawaiiSec audio system
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/kawaii-audio.sh" ]]; then
    source "${SCRIPT_DIR}/kawaii-audio.sh"
    echo "🎵 KawaiiSec audio system loaded!"
else
    echo "🔇 Audio system not found - continuing without sound"
    kawaii_denied() { echo "❌ Access denied! (no audio)"; }
    kawaii_welcome() { echo "✅ Welcome! (no audio)"; }
fi

# Colors for output
PINK='\033[1;35m'
CYAN='\033[1;36m'
MINT='\033[1;92m'
GRAY='\033[1;90m'
WHITE='\033[1;97m'
RESET='\033[0m'

# Demo credentials (for demonstration purposes only!)
CORRECT_PASSWORD="kawaii123"

show_banner() {
    echo -e "${PINK}"
    cat << "EOF"
    ╔══════════════════════════════════════════════╗
    ║         🌸 KawaiiSec Auth Demo 🌸           ║
    ║      Audio Integration Demonstration        ║
    ╚══════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
}

show_usage() {
    echo -e "${CYAN}✨ This demo shows audio integration for:${RESET}"
    echo -e "  🔓 ${WHITE}Correct Password${RESET} → ${MINT}welcome.mp3${RESET}"
    echo -e "  ❌ ${WHITE}Wrong Password${RESET}   → ${PINK}denied.mp3${RESET}"
    echo ""
    echo -e "${GRAY}Demo password: ${WHITE}kawaii123${RESET}"
    echo -e "${GRAY}Try entering wrong passwords to hear both sounds!${RESET}"
    echo ""
}

# Main authentication function
authenticate_user() {
    local password="$1"
    
    # Simulate authentication check
    if [[ "$password" == "$CORRECT_PASSWORD" ]]; then
        return 0  # Success
    else
        return 1  # Failure
    fi
}

# Main demo loop
main() {
    show_banner
    show_usage
    
    local attempts=0
    local max_attempts=3
    
    while [[ $attempts -lt $max_attempts ]]; do
        echo -e "${CYAN}🔐 Enter password (attempt $((attempts + 1))/$max_attempts):${RESET}"
        read -s password
        echo ""  # New line after hidden input
        
        if authenticate_user "$password"; then
            echo -e "${MINT}✨ Authentication successful!${RESET}"
            kawaii_welcome
            echo -e "${GRAY}🎉 You would now have access to the system!${RESET}"
            break
        else
            echo -e "${PINK}❌ Authentication failed!${RESET}"
            kawaii_denied
            ((attempts++))
            
            if [[ $attempts -lt $max_attempts ]]; then
                echo -e "${GRAY}💭 Try again... (hint: the password is shown above)${RESET}"
                echo ""
            fi
        fi
    done
    
    if [[ $attempts -eq $max_attempts ]]; then
        echo -e "${PINK}🚫 Maximum attempts exceeded. Access denied!${RESET}"
        kawaii_denied
        echo -e "${GRAY}📝 In a real system, this would lock the account.${RESET}"
    fi
    
    echo ""
    echo -e "${CYAN}🌸 Demo complete! Audio integration working correctly.${RESET}"
    echo -e "${GRAY}   To use in your scripts, see the README documentation.${RESET}"
}

# Run main function
main "$@" 