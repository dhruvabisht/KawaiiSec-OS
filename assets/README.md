# 🌸 KawaiiSec OS Assets

This directory contains all the systematically organized assets for KawaiiSec OS.

## 📁 Directory Structure

```
assets/
├── audio/                    # 🔊 Audio files for system feedback
│   ├── denied.wav           # Wrong password / access denied sound
│   ├── welcome.wav          # Correct password / successful login sound  
│   ├── did_it.wav           # Success / task completion sound
│   ├── nani.wav             # Error / command failure sound
│   └── README.md            # Audio system documentation
├── graphics/                # 🎨 Visual assets and images
│   ├── icons/               # App icons and favicons
│   │   ├── favicon.png      # Main favicon
│   │   ├── favicon.ico      # ICO format favicon
│   │   ├── favicon-16x16.png
│   │   ├── favicon-32x32.png
│   │   ├── android-chrome-192x192.png
│   │   ├── android-chrome-512x512.png
│   │   └── apple-touch-icon.png
│   ├── logos/               # Brand logos and identity
│   │   ├── Kawaii.png       # Main KawaiiSec logo
│   │   ├── logo.svg         # Vector logo
│   │   └── docusaurus.png   # Documentation logo
│   ├── wallpapers/          # Desktop wallpapers (future)
│   └── illustrations/       # UI illustrations and graphics
│       ├── undraw_docusaurus_react.svg
│       ├── undraw_docusaurus_tree.svg
│       ├── undraw_docusaurus_mountain.svg
│       └── docusaurus-social-card.jpg
├── scripts/                 # 🔧 System scripts and tools
│   ├── audio/               # Audio-related scripts
│   │   ├── kawaii-audio.sh  # Core audio integration system
│   │   └── kawaii-auth-demo.sh # Authentication demo with audio
│   ├── system/              # System-level utilities
│   │   ├── kawaii-plymouth.py # Plymouth boot theme generator
│   │   └── demo-plymouth.py # Plymouth theme demonstration
│   └── tools/               # System tools and utilities
│       ├── pinkmap.sh       # Kawaii nmap wrapper
│       ├── animefetch.sh    # System info display
│       └── detect-zsh-setup.sh # Shell setup detection
└── themes/                  # 🎭 Visual themes and customizations
    ├── boot/                # Plymouth boot splash themes
    │   ├── kawaiisec/       # Default KawaiiSec boot theme
    │   ├── requirements.txt # Python dependencies for theme generation
    │   └── README.md        # Boot theme documentation
    └── terminal/            # Terminal themes and configs
        └── uwu.zsh-theme    # Kawaii ZSH theme with audio integration
```

## 🚀 Quick Start

### Audio System
```bash
# Source the audio system
source assets/scripts/audio/kawaii-audio.sh

# Check system status
kawaii_audio_status

# Test sounds
kawaii_welcome    # Welcome sound
kawaii_did_it     # Success sound  
kawaii_nani       # Error sound
kawaii_denied     # Access denied sound
```

### Tools
```bash
# Run kawaii nmap scanner
assets/scripts/tools/pinkmap.sh <target-ip>

# Try authentication demo
assets/scripts/audio/kawaii-auth-demo.sh  # Password: kawaii123
```

### Terminal Theme
```bash
# Copy theme to OH-MY-ZSH
cp assets/themes/terminal/uwu.zsh-theme ~/.oh-my-zsh/custom/themes/

# Set in ~/.zshrc
ZSH_THEME="uwu"
```

### Boot Themes (Plymouth)
```bash
# Generate kawaii boot splash
python3 assets/scripts/system/kawaii-plymouth.py --generate --color pink

# Install theme (Linux only, requires root)
sudo python3 assets/scripts/system/kawaii-plymouth.py --install

# Demo all color schemes
python3 assets/scripts/system/demo-plymouth.py
```

## 🔧 Integration

All scripts automatically detect and use the new asset locations:
- **Audio files**: `assets/audio/*.wav`
- **Scripts**: `assets/scripts/{audio,tools}/*.sh`
- **Graphics**: `assets/graphics/{icons,logos,illustrations}/*`
- **Themes**: `assets/themes/terminal/*.zsh-theme`

## 🌟 Features

- **🔊 Cross-platform audio system** (macOS, Linux, WSL)
- **🎨 Organized graphics assets** (icons, logos, illustrations)
- **🔧 Modular script architecture** (audio, tools, system utilities)
- **🎭 Themed terminal experience** with audio feedback
- **🌸 Kawaii boot splash themes** with animated progress bars
- **📱 Complete icon set** for web and mobile
- **🐍 Python-based theme generators** for easy customization

## 📚 Documentation

- [Audio System](audio/README.md) - Complete audio integration guide
- [Graphics Assets](graphics/) - Visual asset guidelines
- [Scripts](scripts/) - Tool and utility documentation
- [Themes](themes/) - Theme customization guide

---

🌸 **Stay cute, stay organized!** 💖✨ 