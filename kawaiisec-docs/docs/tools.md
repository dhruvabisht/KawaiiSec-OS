---
id: tools
title: Tools & Scripts
sidebar_label: Tools
---

## 🌸 animefetch.sh

Your adorable system info fetcher.

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

### 🧠 Bonus:

ASCII mascot output! Run with `--no-ascii` to skip the cute chibi.

### 🎨 Features:

* Cute hacker chibi with cat-ears ASCII art
* System information display
* Memory usage on macOS
* KawaiiSec branding

---

## 🎨 Terminal Themes

### 📂 Location:
```bash
resources/terminal-themes/
```

### 🌈 Available Themes:

* `uwu.zsh-theme` - Pastel kawaii prompt with soft pink, lavender-blue, and baby purple colors
* `detect-zsh-setup.sh` - Auto-detect script to help set up themes

### 🎨 Theme Setup:

Run the detection script to get setup instructions:
```bash
./resources/scripts/detect-zsh-setup.sh
```

---

## 🌸 pinkmap.sh

Your adorable nmap wrapper with sound effects!

### 📂 Location:
```bash
resources/scripts/pinkmap.sh
```

### ▶️ Run it:

```bash
./resources/scripts/pinkmap.sh <target-ip> [nmap-args]
```

### 📋 What it does:

* Cute pastel intro banner
* Runs nmap with your specified arguments
* Displays output with pink separators
* Plays sound notification if open ports found (macOS: Hero.aiff)
* Supports all standard nmap options

### 🎵 Sound Support:

* **macOS**: Uses system `Hero.aiff` sound
* **Linux**: Coming soon with `nani.mp3` bundle

---

## 🚀 Coming Soon

* ASCII mascot integration
* More kawaii security tools
* `tsundere-cron`: sassy cron manager
* `waifu-firewall`: GUI ufw frontend 