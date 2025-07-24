#!/bin/bash

# KawaiiSec OS - Help and Quick Reference
# Comprehensive help for all KawaiiSec tools and labs

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Kawaii banner
echo -e "${PURPLE}"
echo "╭─────────────────────────────────────╮"
echo "│    🌸 KawaiiSec OS Help Center 🌸   │"
echo "│      Your Cybersecurity Companion   │"
echo "╰─────────────────────────────────────╯"
echo -e "${NC}"

show_main_menu() {
    echo
    echo -e "${CYAN}📚 Available Help Topics:${NC}"
    echo
    echo -e "${GREEN}1.${NC} ${BLUE}Quick Start${NC}        - Get started with KawaiiSec OS"
    echo -e "${GREEN}2.${NC} ${BLUE}Lab Environments${NC}   - Vulnerable apps and network labs"
    echo -e "${GREEN}3.${NC} ${BLUE}Tool Categories${NC}    - Installed security tools by category"
    echo -e "${GREEN}4.${NC} ${BLUE}Attack Scenarios${NC}   - Common penetration testing workflows"
    echo -e "${GREEN}5.${NC} ${BLUE}Blue Team Tools${NC}    - Defensive and monitoring tools"
    echo -e "${GREEN}6.${NC} ${BLUE}Cheat Sheets${NC}       - Quick reference commands"
    echo -e "${GREEN}7.${NC} ${BLUE}Troubleshooting${NC}   - Common issues and solutions"
    echo
    echo -e "${YELLOW}Usage: $0 [topic]${NC}"
    echo "Example: $0 labs"
    echo
}

show_quick_start() {
    echo -e "${PURPLE}🚀 Quick Start Guide${NC}"
    echo "=================="
    echo
    echo -e "${GREEN}1. Update and Install Tools:${NC}"
    echo "   sudo apt update && sudo apt upgrade"
    echo "   sudo apt install kawaiisec-tools"
    echo
    echo -e "${GREEN}2. Launch Vulnerable Applications:${NC}"
    echo "   launch_dvwa.sh          # Damn Vulnerable Web App"
    echo "   run_juice_shop.sh       # OWASP Juice Shop"
    echo
    echo -e "${GREEN}3. Start Lab Networks:${NC}"
    echo "   start_metasploitable3.sh    # Single vulnerable VMs"
    echo "   lab_net_topo.sh start basic # Multi-VM network"
    echo
    echo -e "${GREEN}4. Common First Steps:${NC}"
    echo "   nmap -sn 192.168.1.0/24     # Network discovery"
    echo "   nmap -sV target_ip           # Service enumeration"
    echo "   gobuster dir -u http://target_ip -w /usr/share/wordlists/dirb/common.txt"
    echo
    echo -e "${BLUE}💡 Pro Tip:${NC} Always start with reconnaissance!"
}

show_lab_environments() {
    echo -e "${PURPLE}🧪 Lab Environments${NC}"
    echo "==================="
    echo
    echo -e "${GREEN}🌸 Web Application Labs:${NC}"
    echo "  • DVWA (Damn Vulnerable Web App)"
    echo "    ${BLUE}Command:${NC} launch_dvwa.sh"
    echo "    ${BLUE}Access:${NC}  http://localhost:8080"
    echo "    ${BLUE}Focus:${NC}   SQL injection, XSS, command injection"
    echo
    echo "  • OWASP Juice Shop"
    echo "    ${BLUE}Command:${NC} run_juice_shop.sh"
    echo "    ${BLUE}Access:${NC}  http://localhost:3000"
    echo "    ${BLUE}Focus:${NC}   Modern web app vulnerabilities"
    echo
    echo -e "${GREEN}🎯 Infrastructure Labs:${NC}"
    echo "  • Metasploitable3"
    echo "    ${BLUE}Command:${NC} start_metasploitable3.sh"
    echo "    ${BLUE}VMs:${NC}     Windows + Linux + Kali control"
    echo "    ${BLUE}Focus:${NC}   System exploitation, privilege escalation"
    echo
    echo "  • Network Topology Lab"
    echo "    ${BLUE}Command:${NC} lab_net_topo.sh start [scenario]"
    echo "    ${BLUE}Scenarios:${NC} basic, internal, full"
    echo "    ${BLUE}Focus:${NC}   Network penetration, lateral movement"
    echo
    echo -e "${YELLOW}📋 Lab Management Commands:${NC}"
    echo "  • Status:  [script] status"
    echo "  • Stop:    [script] stop"
    echo "  • Logs:    [script] logs"
    echo "  • Help:    [script] --help"
}

show_tool_categories() {
    echo -e "${PURPLE}🛠️ Tool Categories${NC}"
    echo "=================="
    echo
    echo -e "${GREEN}🔍 Network Discovery & Scanning:${NC}"
    echo "  nmap, zenmap, masscan, netdiscover, arp-scan"
    echo
    echo -e "${GREEN}🔍 Vulnerability Assessment:${NC}"
    echo "  openvas, nikto, dirbuster, gobuster, wpscan, joomscan"
    echo
    echo -e "${GREEN}💥 Exploitation Frameworks:${NC}"
    echo "  metasploit-framework, armitage, beef-xss, set"
    echo
    echo -e "${GREEN}🌐 Web Application Testing:${NC}"
    echo "  burpsuite, zaproxy, sqlmap, xsstrike, dalfox"
    echo
    echo -e "${GREEN}📡 Wireless & RF Security:${NC}"
    echo "  aircrack-ng, reaver, wifite, kismet, bettercap"
    echo
    echo -e "${GREEN}🔐 Password Cracking:${NC}"
    echo "  hashcat, john, hydra, medusa"
    echo
    echo -e "${GREEN}🔬 Digital Forensics:${NC}"
    echo "  sleuthkit, autopsy, volatility, bulk-extractor, exiftool"
    echo
    echo -e "${GREEN}🔧 Reverse Engineering:${NC}"
    echo "  ghidra, radare2, binutils, ltrace, strace"
    echo
    echo -e "${GREEN}🕵️ OSINT & Reconnaissance:${NC}"
    echo "  maltego, theharvester, recon-ng, spiderfoot"
    echo
    echo -e "${GREEN}🛡️ Blue Team / SIEM:${NC}"
    echo "  snort, suricata, elasticsearch, kibana, logstash, osquery"
    echo
    echo -e "${GREEN}🎭 Steganography & CTF:${NC}"
    echo "  steghide, binwalk, foremost, python3-pwntools"
}

show_attack_scenarios() {
    echo -e "${PURPLE}🎯 Attack Scenarios${NC}"
    echo "==================="
    echo
    echo -e "${GREEN}📋 Basic Web App Penetration:${NC}"
    echo "  1. Launch target: launch_dvwa.sh"
    echo "  2. Directory enumeration: gobuster dir -u http://localhost:8080/dvwa"
    echo "  3. Vulnerability scanning: nikto -h http://localhost:8080/dvwa"
    echo "  4. Manual testing with Burp Suite"
    echo "  5. SQL injection: sqlmap -u 'http://localhost:8080/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit' --cookie='security=low; PHPSESSID=...'"
    echo
    echo -e "${GREEN}🏢 Network Penetration (Internal):${NC}"
    echo "  1. Start lab: lab_net_topo.sh start internal"
    echo "  2. Network discovery: nmap -sn 192.168.20.0/24"
    echo "  3. Port scanning: nmap -sV -sC 192.168.20.0/24"
    echo "  4. Service enumeration: enum4linux 192.168.20.20"
    echo "  5. Exploitation: msfconsole"
    echo "  6. Lateral movement: use auxiliary/scanner/smb/smb_login"
    echo
    echo -e "${GREEN}📱 Wireless Security Assessment:${NC}"
    echo "  1. Monitor mode: sudo airmon-ng start wlan0"
    echo "  2. Network discovery: sudo airodump-ng wlan0mon"
    echo "  3. Capture handshake: sudo airodump-ng -c [channel] --bssid [AP] -w capture wlan0mon"
    echo "  4. Crack password: aircrack-ng -w /usr/share/wordlists/rockyou.txt capture-01.cap"
    echo
    echo -e "${GREEN}🔍 OSINT Reconnaissance:${NC}"
    echo "  1. Domain enumeration: theharvester -d target.com -b google"
    echo "  2. Subdomain discovery: sublist3r -d target.com"
    echo "  3. Social media intelligence: recon-ng"
    echo "  4. Technical reconnaissance: maltego"
}

show_blue_team() {
    echo -e "${PURPLE}🛡️ Blue Team & Defense${NC}"
    echo "====================="
    echo
    echo -e "${GREEN}🔍 Monitoring & Detection:${NC}"
    echo "  • ELK Stack (Elasticsearch, Logstash, Kibana)"
    echo "  • Suricata IDS/IPS"
    echo "  • Snort Network IDS"
    echo "  • OSQuery endpoint monitoring"
    echo
    echo -e "${GREEN}📊 Log Analysis:${NC}"
    echo "  sudo tail -f /var/log/auth.log          # Authentication logs"
    echo "  sudo tail -f /var/log/apache2/access.log # Web server logs"
    echo "  journalctl -u ssh -f                   # SSH service logs"
    echo
    echo -e "${GREEN}🔒 Network Security:${NC}"
    echo "  sudo iptables -L                       # View firewall rules"
    echo "  sudo netstat -tulpn                    # Network connections"
    echo "  sudo ss -tulpn                         # Modern netstat alternative"
    echo
    echo -e "${GREEN}💾 Incident Response:${NC}"
    echo "  volatility -f memory.dump imageinfo     # Memory analysis"
    echo "  autopsy                                 # Digital forensics GUI"
    echo "  bulk_extractor -o output memory.dump    # Extract artifacts"
}

show_cheat_sheets() {
    echo -e "${PURPLE}📋 Cheat Sheets${NC}"
    echo "==============="
    echo
    echo -e "${GREEN}🔍 Nmap Quick Reference:${NC}"
    echo "  nmap -sn 192.168.1.0/24              # Ping scan"
    echo "  nmap -sS -O target                   # SYN scan + OS detection"
    echo "  nmap -sV -sC target                  # Service version + default scripts"
    echo "  nmap -p- --min-rate 1000 target     # Fast full port scan"
    echo
    echo -e "${GREEN}💉 Metasploit Essentials:${NC}"
    echo "  msfconsole                           # Start Metasploit"
    echo "  search cve:2021                      # Search by CVE"
    echo "  use exploit/windows/smb/ms17_010     # Select exploit"
    echo "  set RHOSTS 192.168.1.100             # Set target"
    echo "  exploit                              # Run exploit"
    echo
    echo -e "${GREEN}🌐 Web Testing Commands:${NC}"
    echo "  gobuster dir -u http://target -w /usr/share/wordlists/dirb/common.txt"
    echo "  nikto -h http://target"
    echo "  sqlmap -u 'http://target/page?id=1' --batch"
    echo "  wpscan --url http://target --enumerate p,t,u"
    echo
    echo -e "${GREEN}🔐 Hash Cracking:${NC}"
    echo "  hashcat -m 1400 hashes.txt rockyou.txt    # SHA256"
    echo "  hashcat -m 1000 hashes.txt rockyou.txt    # NTLM"
    echo "  john --wordlist=rockyou.txt hashes.txt    # John the Ripper"
    echo "  hydra -l admin -P passwords.txt http-post-form target"
}

show_troubleshooting() {
    echo -e "${PURPLE}🔧 Troubleshooting${NC}"
    echo "=================="
    echo
    echo -e "${GREEN}🐳 Docker Issues:${NC}"
    echo "  ${YELLOW}Problem:${NC} Docker daemon not running"
    echo "  ${BLUE}Solution:${NC} sudo systemctl start docker"
    echo
    echo "  ${YELLOW}Problem:${NC} Permission denied"
    echo "  ${BLUE}Solution:${NC} sudo usermod -aG docker \$USER && newgrp docker"
    echo
    echo -e "${GREEN}📦 Vagrant Issues:${NC}"
    echo "  ${YELLOW}Problem:${NC} VirtualBox kernel modules not loaded"
    echo "  ${BLUE}Solution:${NC} sudo /sbin/vboxconfig"
    echo
    echo "  ${YELLOW}Problem:${NC} Vagrant box not found"
    echo "  ${BLUE}Solution:${NC} vagrant box add [box-name] --provider virtualbox"
    echo
    echo -e "${GREEN}🔧 Tool Issues:${NC}"
    echo "  ${YELLOW}Problem:${NC} Metasploit database not initialized"
    echo "  ${BLUE}Solution:${NC} sudo msfdb init"
    echo
    echo "  ${YELLOW}Problem:${NC} Missing wordlists"
    echo "  ${BLUE}Solution:${NC} sudo apt install seclists wordlists"
    echo
    echo -e "${GREEN}🌐 Network Issues:${NC}"
    echo "  ${YELLOW}Problem:${NC} Can't access lab VMs"
    echo "  ${BLUE}Solution:${NC} Check VirtualBox network settings and firewall rules"
    echo
    echo "  ${YELLOW}Problem:${NC} VM networking not working"
    echo "  ${BLUE}Solution:${NC} Restart networking: sudo systemctl restart networking"
    echo
    echo -e "${BLUE}📞 Support:${NC} For more help, check /usr/share/doc/kawaiisec-tools/"
}

# Parse command line arguments
case "${1:-menu}" in
    menu|help|--help|-h)
        show_main_menu
        ;;
    quickstart|quick|start)
        show_quick_start
        ;;
    labs|lab|environments)
        show_lab_environments
        ;;
    tools|categories)
        show_tool_categories
        ;;
    scenarios|attacks)
        show_attack_scenarios
        ;;
    blue|defense|blueteam)
        show_blue_team
        ;;
    cheat|cheatsheet|commands)
        show_cheat_sheets
        ;;
    troubleshoot|trouble|fix)
        show_troubleshooting
        ;;
    *)
        echo -e "${RED}Unknown topic: $1${NC}"
        echo
        show_main_menu
        exit 1
        ;;
esac

echo
echo -e "${PURPLE}🌸 Happy Hacking with KawaiiSec OS! 🌸${NC}" 