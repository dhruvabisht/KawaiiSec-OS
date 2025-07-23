# 🔧 KawaiiSec Scripts

Organized collection of system scripts and utilities for KawaiiSec OS.

## 📁 Directory Structure

### 🎵 Audio Scripts (`audio/`)
- **`kawaii-audio.sh`** - Core audio integration system
  - Cross-platform audio support (macOS, Linux, WSL)
  - Functions for authentication and command feedback
  - Automatic audio player detection
  
- **`kawaii-auth-demo.sh`** - Authentication demonstration
  - Shows proper audio integration for login systems
  - Interactive demo with password validation
  - Test password: `kawaii123`

### 🛠️ Tool Scripts (`tools/`)
- **`pinkmap.sh`** - Kawaii nmap wrapper
  - Network scanning with audio feedback
  - Cute output formatting and sound effects
  - Integrated with kawaii-audio system
  
- **`animefetch.sh`** - System information display
  - Kawaii-style system info fetcher
  - Alternative to neofetch with anime aesthetic
  
- **`detect-zsh-setup.sh`** - Shell setup detection
  - Detects and configures ZSH environment
  - Helps with theme installation

## 🚀 Usage Examples

### Audio Integration
```bash
# Source the audio system
source assets/scripts/audio/kawaii-audio.sh

# Use in your scripts
if authenticate_user; then
    kawaii_welcome
    echo "Login successful!"
else
    kawaii_denied
    echo "Access denied!"
fi

# Command execution with feedback
kawaii_exec "sudo systemctl start apache2"
```

### Tools
```bash
# Scan network with kawaii style
assets/scripts/tools/pinkmap.sh 192.168.1.1

# Get system information
assets/scripts/tools/animefetch.sh

# Setup shell environment
assets/scripts/tools/detect-zsh-setup.sh
```

## 🔗 Integration

Scripts automatically use the organized asset structure:
- Audio files from `../audio/`
- Graphics from `../../graphics/`
- Cross-referencing between script categories

## 🌸 Development

When adding new scripts:
1. Place in appropriate subdirectory (`audio/` or `tools/`)
2. Use the centralized asset paths
3. Follow kawaii naming conventions
4. Include proper error handling
5. Add audio feedback where appropriate

---

💖 **Cute code, reliable tools!** ✨ 