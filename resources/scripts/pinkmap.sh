#!/bin/bash

# pinkmap.sh — Cute Nmap Wrapper with Sound Effects (macOS version)

# ANSI colors
PINK='\033[1;35m'
CYAN='\033[1;36m'
RESET='\033[0m'

# Intro banner
echo -e "${PINK}"
echo "     🌸 pinkmap — powered by NMAP + KawaiiSec 🌸"
echo "        Scanning with style, please wait... 💻💖"
echo -e "${RESET}"

# Check for target
if [ -z "$1" ]; then
  echo -e "${CYAN}Usage:${RESET} $0 <target-ip> [nmap-args]"
  exit 1
fi

# Run nmap and store output
nmap_output=$(nmap "$@" | tee /tmp/pinkmap-output.txt)

# Display output with pink separators
echo -e "${PINK}═══════════════════════════════════════════════${RESET}"
echo "$nmap_output"
echo -e "${PINK}═══════════════════════════════════════════════${RESET}"

# Play sound if open ports found (macOS)
if grep -q "open" /tmp/pinkmap-output.txt; then
  echo -e "${PINK}✨ OPEN PORTS FOUND! ✨${RESET}"
  afplay /System/Library/Sounds/Hero.aiff
else
  echo -e "${CYAN}No open ports found.${RESET}"
fi 