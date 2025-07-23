---
id: tools
title: Tools & Scripts  
sidebar_label: Tools
---

# 🛠️ KawaiiSec OS Tools & Scripts

*v0.2 — Terminal Glow-up Edition* ✨

---

## 🌸 animefetch.sh

Your adorable system info fetcher with kawaii chibi mascot.

### 📂 Location:
```bash
resources/scripts/animefetch.sh
```

### ▶️ Run it:
```bash
./resources/scripts/animefetch.sh
```

### 📋 What it shows:
* Current user, host, uptime, OS, shell
* RAM usage on macOS (via vm_stat)
* Cute hacker chibi with cat-ears ASCII art
* System information with kawaii branding

### 🧠 Features:
* **ASCII Mascot**: Adorable chibi hacker with cat ears
* **System Info**: Clean, colorful system information display  
* **Memory Usage**: Real-time memory stats (macOS compatible)
* **Skip Option**: Use `--no-ascii` to run without the mascot

---

## 🎨 uwu.zsh-theme **[ENHANCED v0.2]**

Kawaii terminal theme with pastel colors, git integration, and cute status indicators.

### 📂 Location:
```bash
resources/terminal-themes/uwu.zsh-theme
```

### 🌈 Features:

#### **✨ Enhanced Kawaii Prompt**
* **User Status**: 🌸 for regular users, 🐱 for root
* **Git Integration**: 🌿 branch display with status indicators
* **Exit Status**: (◕‿◕) for success, (╥﹏╥) for errors  
* **Time Display**: Sparkly timestamp on right prompt

#### **🎨 Color Palette**
* **Pink**: Bright kawaii pink (#D75F87)
* **Purple**: Lavender purple (#D787AF) 
* **Blue**: Baby blue (#87D7FF)
* **Mint**: Kawaii mint green (#AFFFAF)
* **Peach**: Soft peach (#FFD7AF)

#### **💖 Git Status Indicators**
* **Clean Repo**: 💖 (heart emoji)
* **Uncommitted Changes**: ✨ (sparkles emoji)
* **Branch Display**: 🌿 with branch name

#### **🎯 Built-in Kawaii Commands**
* `uwu` - Show kawaii motivation message
* `nyan` - Display cute cat face  
* `kawaii-help` - List available kawaii commands

### 🔧 Installation:

#### **For Oh My Zsh Users:**
```bash
# Copy theme to Oh My Zsh themes directory
cp resources/terminal-themes/uwu.zsh-theme ~/.oh-my-zsh/custom/themes/

# Edit your ~/.zshrc
nano ~/.zshrc

# Set the theme
ZSH_THEME="uwu"

# Reload your shell
source ~/.zshrc
```

#### **For Raw ZSH Users:**
```bash
# Add to your ~/.zshrc
echo 'source /path/to/KawaiiSec-OS/resources/terminal-themes/uwu.zsh-theme' >> ~/.zshrc

# Reload your shell
source ~/.zshrc
```

#### **🕵️ Auto-Detection Script:**
```bash
./resources/scripts/detect-zsh-setup.sh
```

---

## 🌸 pinkmap.sh **[ENHANCED v0.2]**

Enhanced nmap wrapper with cross-platform sound effects and kawaii styling!

### 📂 Location:
```bash
resources/scripts/pinkmap.sh
```

### ▶️ Usage:
```bash
# Basic scan
./resources/scripts/pinkmap.sh <target-ip>

# Advanced scan with nmap options
./resources/scripts/pinkmap.sh <target-ip> [nmap-args]
```

### 🌟 v0.2 Enhancements:

#### **🎨 Kawaii Visual Design**
* **ASCII Banner**: Beautiful bordered banner with kawaii styling
* **Color Palette**: Full rainbow of kawaii colors (pink, purple, mint, peach)
* **Progress Indicators**: Cute scan progress with kawaii messages
* **Result Formatting**: Boxed output with professional styling

#### **🔊 Cross-Platform Sound Effects**
* **macOS**: Uses system `Hero.aiff` sound automatically
* **Linux**: Uses custom `nani.mp3` with auto-detection of audio players
* **Smart Detection**: Automatically finds available audio players
* **Graceful Fallback**: Works even without sound support

#### **💪 Enhanced Features**
* **Dependency Check**: Verifies nmap installation automatically
* **Better Error Handling**: Clear error messages with installation help
* **Temp File Management**: Secure temporary file handling
* **Usage Examples**: Built-in help with common scan patterns

#### **🎵 Linux Audio Support**
Automatically detects and uses:
* `aplay` (ALSA) 
* `paplay` (PulseAudio)
* `mpg123` (MP3 player)
* `ffplay` (FFmpeg)

### 📋 Examples:

```bash
# Basic host scan
./resources/scripts/pinkmap.sh 192.168.1.1

# SYN scan with OS detection  
./resources/scripts/pinkmap.sh 192.168.1.1 -sS -O

# Network discovery
./resources/scripts/pinkmap.sh 192.168.1.0/24 -sn

# Detailed service scan
./resources/scripts/pinkmap.sh 192.168.1.1 -sV -sC

# Stealth scan
./resources/scripts/pinkmap.sh 192.168.1.1 -sS -f -T2
```

### 🔊 Sound Setup (Linux):

1. **Add your kawaii sound**:
   ```bash
   # Get a cute anime "NANI?!" sound effect
   # Save it as: resources/sounds/nani.mp3
   ```

2. **Install audio player** (if needed):
   ```bash
   # Ubuntu/Debian  
   sudo apt install mpg123
   
   # Arch Linux
   sudo pacman -S mpg123
   ```

3. **Test it**:
   ```bash
   ./resources/scripts/pinkmap.sh 127.0.0.1
   ```

See `resources/sounds/README.md` for detailed sound setup instructions!

---

## 🚀 Coming Soon in v0.3

* **Live ISO builder** (Kali/Debian Testing based)
* **Preinstalled tools** in the OS image
* **Custom GRUB splash screen** with kawaii mascot
* **Installer automation** scripts

---

## 🧁 Future Kawaii Tools

* **`tsundere-cron`**: Sassy cron job manager with attitude
* **`waifu-firewall`**: Cute GUI frontend for ufw firewall
* **Desktop mascot**: Interactive kawaii mascot overlay

---

## 🎯 Usage Tips

### 🛡️ Ethical Hacking Reminders:
* **Always get permission** before scanning networks
* **Use responsibly** - these are professional security tools
* **Stay legal** - only test systems you own or have authorization for
* **Learn continuously** - security is an ongoing journey

### 💖 Kawaii Philosophy:
* **Stay cute** while staying secure
* **Make learning fun** with kawaii aesthetics  
* **Build community** - share your kawaii security setups
* **Hack responsibly** - cute tools, serious ethics

---

*Remember: With great power comes great responsibility... and adorable aesthetics! 🌸💖* 