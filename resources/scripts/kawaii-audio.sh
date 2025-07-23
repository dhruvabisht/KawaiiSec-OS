#!/bin/bash

# kawaii-audio.sh — KawaiiSec OS Audio Integration System
# 🌸 Handles all audio feedback for authentication, commands, and system events
# Cross-platform support: macOS, Linux, WSL

# Kawaii color palette for audio feedback
AUDIO_PINK='\033[1;35m'
AUDIO_PURPLE='\033[1;95m' 
AUDIO_CYAN='\033[1;36m'
AUDIO_MINT='\033[1;92m'
AUDIO_GRAY='\033[1;90m'
AUDIO_RESET='\033[0m'

# Get the directory where this script is located
# Handle both execution and sourcing scenarios
if [[ -n "${BASH_SOURCE[0]}" && "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    # Try to find the script location relative to current directory
    SCRIPT_DIR="$(pwd)"
    # Look for the audio script in common locations
    if [[ -f "resources/scripts/kawaii-audio.sh" ]]; then
        SCRIPT_DIR="$(pwd)/resources/scripts"
    elif [[ -f "../resources/scripts/kawaii-audio.sh" ]]; then
        SCRIPT_DIR="$(cd ../resources/scripts && pwd)"
    fi
fi

# From resources/scripts/ to resources/sounds/ is ../sounds/
KAWAII_AUDIO_DIR="${SCRIPT_DIR}/../sounds"

# Debug output (only if debug is enabled)
if [[ "${KAWAII_DEBUG:-}" == "true" ]]; then
    echo "DEBUG: BASH_SOURCE[0] = ${BASH_SOURCE[0]}" >&2
    echo "DEBUG: SCRIPT_DIR = $SCRIPT_DIR" >&2
    echo "DEBUG: Initial KAWAII_AUDIO_DIR = $KAWAII_AUDIO_DIR" >&2
    echo "DEBUG: Directory exists? $([ -d "$KAWAII_AUDIO_DIR" ] && echo 'YES' || echo 'NO')" >&2
fi

# Ensure the sounds directory exists, if not try alternative locations
if [[ ! -d "$KAWAII_AUDIO_DIR" ]]; then
    # Try different possible locations
    POSSIBLE_LOCATIONS=(
        "$SCRIPT_DIR/../sounds"  # From scripts/ to sounds/
        "$(pwd)/resources/sounds"  # From project root
        "$SCRIPT_DIR/../../resources/sounds"  # Up two levels then down
        "${SCRIPT_DIR%/*}/sounds"  # Remove one path component and add sounds
    )
    
    for location in "${POSSIBLE_LOCATIONS[@]}"; do
        if [[ -d "$location" ]]; then
            KAWAII_AUDIO_DIR="$location"
            break
        fi
    done
    
    if [[ "${KAWAII_DEBUG:-}" == "true" ]]; then
        echo "DEBUG: Fallback KAWAII_AUDIO_DIR = $KAWAII_AUDIO_DIR" >&2
    fi
fi

# Normalize the path to remove any .. references
if [[ -d "$KAWAII_AUDIO_DIR" ]]; then
    KAWAII_AUDIO_DIR="$(cd "$KAWAII_AUDIO_DIR" && pwd)"
    if [[ "${KAWAII_DEBUG:-}" == "true" ]]; then
        echo "DEBUG: Normalized KAWAII_AUDIO_DIR = $KAWAII_AUDIO_DIR" >&2
    fi
fi

# Audio file mappings (using .wav since the files are actually WAV format)
DENIED_SOUND="${KAWAII_AUDIO_DIR}/denied.wav"
WELCOME_SOUND="${KAWAII_AUDIO_DIR}/welcome.wav"
DID_IT_SOUND="${KAWAII_AUDIO_DIR}/did_it.wav"
NANI_SOUND="${KAWAII_AUDIO_DIR}/nani.wav"

# Detect audio player based on OS
detect_audio_player() {
    local audio_cmd=""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - use afplay
        audio_cmd="afplay"
        echo -e "${AUDIO_GRAY}🍎 macOS detected - Using afplay${AUDIO_RESET}" >&2
    elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux-musl"* ]]; then
        # Linux - check for available players
        if command -v paplay >/dev/null 2>&1; then
            audio_cmd="paplay"
        elif command -v aplay >/dev/null 2>&1; then
            audio_cmd="aplay"
        elif command -v mpg123 >/dev/null 2>&1; then
            audio_cmd="mpg123 -q"
        elif command -v ffplay >/dev/null 2>&1; then
            audio_cmd="ffplay -nodisp -autoexit -loglevel quiet"
        else
            echo -e "${AUDIO_GRAY}🐧 Linux detected but no audio player found${AUDIO_RESET}" >&2
            audio_cmd=""
        fi
        echo -e "${AUDIO_GRAY}🐧 Linux detected - Using ${audio_cmd:-'no audio'}${AUDIO_RESET}" >&2
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        # Windows/WSL - check for available players
        if command -v powershell.exe >/dev/null 2>&1; then
            audio_cmd="powershell.exe -c"
        elif command -v mpg123 >/dev/null 2>&1; then
            audio_cmd="mpg123 -q"
        else
            echo -e "${AUDIO_GRAY}🪟 Windows/WSL detected but no audio player found${AUDIO_RESET}" >&2
            audio_cmd=""
        fi
        echo -e "${AUDIO_GRAY}🪟 Windows/WSL detected - Using ${audio_cmd:-'no audio'}${AUDIO_RESET}" >&2
    else
        echo -e "${AUDIO_GRAY}❓ Unknown OS - Audio disabled${AUDIO_RESET}" >&2
        audio_cmd=""
    fi
    
    echo "$audio_cmd"
}

# Generic audio player function
play_audio_file() {
    local sound_file="$1"
    local message="$2"
    local audio_cmd="$3"
    
    if [[ -z "$audio_cmd" ]]; then
        return 0  # Silently skip if no audio player
    fi
    
    if [[ ! -f "$sound_file" ]]; then
        echo -e "${AUDIO_GRAY}🔇 Audio file not found: $(basename "$sound_file")${AUDIO_RESET}" >&2
        return 1
    fi
    
    if [[ -n "$message" ]]; then
        echo -e "$message" >&2
    fi
    
    # Handle different audio players
    case "$audio_cmd" in
        "afplay")
            $audio_cmd "$sound_file" 2>/dev/null &
            ;;
        "paplay"|"aplay")
            $audio_cmd "$sound_file" 2>/dev/null &
            ;;
        "mpg123 -q")
            mpg123 -q "$sound_file" 2>/dev/null &
            ;;
        "ffplay -nodisp -autoexit -loglevel quiet")
            ffplay -nodisp -autoexit -loglevel quiet "$sound_file" 2>/dev/null &
            ;;
        "powershell.exe -c")
            # Windows PowerShell audio playback
            powershell.exe -c "(New-Object Media.SoundPlayer '$sound_file').PlaySync();" 2>/dev/null &
            ;;
        *)
            echo -e "${AUDIO_GRAY}🔇 Unknown audio command: $audio_cmd${AUDIO_RESET}" >&2
            return 1
            ;;
    esac
}

# Initialize audio system
init_kawaii_audio() {
    if [[ -z "$KAWAII_AUDIO_PLAYER" ]]; then
        export KAWAII_AUDIO_PLAYER=$(detect_audio_player)
    fi
}

# Authentication Functions
kawaii_denied() {
    local audio_cmd="${KAWAII_AUDIO_PLAYER:-$(detect_audio_player)}"
    play_audio_file "$DENIED_SOUND" "${AUDIO_PINK}❌ Access denied! (╥﹏╥)${AUDIO_RESET}" "$audio_cmd"
}

kawaii_welcome() {
    local audio_cmd="${KAWAII_AUDIO_PLAYER:-$(detect_audio_player)}"
    play_audio_file "$WELCOME_SOUND" "${AUDIO_MINT}✨ Welcome back! (◕‿◕)${AUDIO_RESET}" "$audio_cmd"
}

# Terminal Command Functions
kawaii_did_it() {
    local audio_cmd="${KAWAII_AUDIO_PLAYER:-$(detect_audio_player)}"
    play_audio_file "$DID_IT_SOUND" "${AUDIO_CYAN}🎉 Task completed successfully! ٩(◕‿◕)۶${AUDIO_RESET}" "$audio_cmd"
}

kawaii_nani() {
    local audio_cmd="${KAWAII_AUDIO_PLAYER:-$(detect_audio_player)}"
    play_audio_file "$NANI_SOUND" "${AUDIO_PURPLE}💥 NANI?! Command failed! (°o°)${AUDIO_RESET}" "$audio_cmd"
}

# Command execution wrapper with audio feedback
kawaii_exec() {
    local cmd="$*"
    echo -e "${AUDIO_GRAY}🚀 Executing: $cmd${AUDIO_RESET}" >&2
    
    if eval "$cmd"; then
        kawaii_did_it
        return 0
    else
        local exit_code=$?
        kawaii_nani
        return $exit_code
    fi
}

# Authentication wrapper
kawaii_auth() {
    local auth_cmd="$*"
    
    if eval "$auth_cmd"; then
        kawaii_welcome
        return 0
    else
        kawaii_denied
        return 1
    fi
}

# Install audio dependencies
install_kawaii_audio_deps() {
    echo -e "${AUDIO_PURPLE}🎵 Installing KawaiiSec audio dependencies...${AUDIO_RESET}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${AUDIO_MINT}✅ macOS has built-in audio support!${AUDIO_RESET}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt >/dev/null 2>&1; then
            echo -e "${AUDIO_CYAN}📦 Installing via apt...${AUDIO_RESET}"
            sudo apt update && sudo apt install -y pulseaudio-utils alsa-utils mpg123
        elif command -v pacman >/dev/null 2>&1; then
            echo -e "${AUDIO_CYAN}📦 Installing via pacman...${AUDIO_RESET}"
            sudo pacman -S --needed pulseaudio alsa-utils mpg123
        elif command -v yum >/dev/null 2>&1; then
            echo -e "${AUDIO_CYAN}📦 Installing via yum...${AUDIO_RESET}"
            sudo yum install -y pulseaudio-utils alsa-utils mpg123
        else
            echo -e "${AUDIO_GRAY}❓ Unknown package manager - please install audio utilities manually${AUDIO_RESET}"
        fi
    else
        echo -e "${AUDIO_GRAY}❓ Please install appropriate audio players for your system${AUDIO_RESET}"
    fi
}

# Show audio system status
kawaii_audio_status() {
    echo -e "${AUDIO_PURPLE}🎵 KawaiiSec Audio System Status${AUDIO_RESET}"
    echo -e "${AUDIO_GRAY}════════════════════════════════${AUDIO_RESET}"
    
    local audio_cmd="${KAWAII_AUDIO_PLAYER:-$(detect_audio_player)}"
    echo -e "Audio Player: ${AUDIO_CYAN}${audio_cmd:-'Not available'}${AUDIO_RESET}"
    echo -e "Sounds Directory: ${AUDIO_GRAY}$KAWAII_AUDIO_DIR${AUDIO_RESET}"
    
    echo -e "\nSound Files:"
    for sound_file in "$DENIED_SOUND" "$WELCOME_SOUND" "$DID_IT_SOUND" "$NANI_SOUND"; do
        local filename=$(basename "$sound_file")
        if [[ -f "$sound_file" ]]; then
            echo -e "  ✅ ${AUDIO_MINT}$filename${AUDIO_RESET}"
        else
            echo -e "  ❌ ${AUDIO_PINK}$filename${AUDIO_RESET} (missing)"
        fi
    done
    
    echo -e "\nAvailable Functions:"
    echo -e "  ${AUDIO_CYAN}kawaii_denied${AUDIO_RESET}    - Wrong password sound"
    echo -e "  ${AUDIO_CYAN}kawaii_welcome${AUDIO_RESET}   - Correct password sound"
    echo -e "  ${AUDIO_CYAN}kawaii_did_it${AUDIO_RESET}    - Success sound"
    echo -e "  ${AUDIO_CYAN}kawaii_nani${AUDIO_RESET}      - Error sound"
    echo -e "  ${AUDIO_CYAN}kawaii_exec${AUDIO_RESET}      - Execute with audio feedback"
    echo -e "  ${AUDIO_CYAN}kawaii_auth${AUDIO_RESET}      - Authenticate with audio feedback"
}

# Initialize on source
init_kawaii_audio

# Export functions for use in other scripts
export -f kawaii_denied kawaii_welcome kawaii_did_it kawaii_nani
export -f kawaii_exec kawaii_auth play_audio_file
export -f kawaii_audio_status install_kawaii_audio_deps 