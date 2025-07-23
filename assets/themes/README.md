# 🎭 KawaiiSec Themes

Beautiful and functional themes for KawaiiSec OS experience.

## 📁 Directory Structure

### 🖥️ Terminal Themes (`terminal/`)
- **`uwu.zsh-theme`** - Kawaii ZSH theme with audio integration
  - Cute emoji-based prompt design
  - Integrated audio feedback for command success/failure
  - Git status indicators with kawaii symbols
  - Automatic command execution sound effects

## 🚀 Installation

### ZSH Theme Setup
```bash
# Copy theme to OH-MY-ZSH custom themes
cp assets/themes/terminal/uwu.zsh-theme ~/.oh-my-zsh/custom/themes/

# Edit your ~/.zshrc
echo 'ZSH_THEME="uwu"' >> ~/.zshrc

# Reload your shell
source ~/.zshrc
```

### Manual Installation
```bash
# If not using OH-MY-ZSH, source directly in ~/.zshrc
echo 'source /path/to/KawaiiSec-OS/assets/themes/terminal/uwu.zsh-theme' >> ~/.zshrc
```

## 🌟 Features

### Kawaii Terminal Theme
- **🌸 Cute Prompt**: Sakura and cat emojis for user status
- **🎵 Audio Integration**: Success/failure sounds for commands
- **🌿 Git Status**: Visual indicators for repository state
- **⚡ Performance**: Fast and responsive prompt
- **😊 Emotional Feedback**: Happy/sad faces based on command exit codes

### Theme Elements
- **User Status**: `🌸user` (normal) or `🐱root` (root user)
- **Git Branch**: `🌿 branch-name` with status indicators
- **Command Status**: `(◕‿◕)` (success) or `(╥﹏╥)` (error)
- **Time Display**: `✨ HH:MM:SS ✨` on the right

## 🔧 Customization

### Audio Settings
The theme automatically detects and uses the KawaiiSec audio system:
```bash
# Test audio integration
kawaii-test-welcome   # Test welcome sound
kawaii-test-success   # Test success sound
kawaii-test-error     # Test error sound
kawaii-test-denied    # Test denied sound
```

### Color Customization
Edit the theme file to customize colors:
```bash
local kawaii_pink="%F{213}"      # Bright pink
local kawaii_purple="%F{177}"    # Lavender purple  
local kawaii_blue="%F{117}"      # Baby blue
local kawaii_mint="%F{158}"      # Mint green
```

### Disable Audio
To use the theme without audio:
```bash
# Set this before sourcing the theme
export KAWAII_AUDIO_DISABLE=true
```

## 🎨 Preview

```
🌸dhruva @ kawaii-laptop 📁 ~/KawaiiSec-OS 🌿 main 💖     ✨ 15:30:42 ✨
(◕‿◕) ⚡ ls -la
# ... command output ...

🌸dhruva @ kawaii-laptop 📁 ~/KawaiiSec-OS 🌿 main ✨     ✨ 15:30:45 ✨
(╥﹏╥) ⚡ invalid-command
# Error with sad face and error sound
```

## 📱 Compatibility

- **ZSH**: Primary target shell
- **OH-MY-ZSH**: Full compatibility
- **Prezto**: Compatible with minor adjustments
- **Terminal Apps**: iTerm2, Terminal.app, Alacritty, etc.
- **Operating Systems**: macOS, Linux, WSL

## 🔧 Troubleshooting

### Audio Not Working
1. Check if audio system is available: `kawaii_audio_status`
2. Install audio dependencies: `install_kawaii_audio_deps`
3. Test individual sounds: `kawaii_welcome`, `kawaii_did_it`

### Theme Not Loading
1. Verify theme location: `ls ~/.oh-my-zsh/custom/themes/uwu.zsh-theme`
2. Check ZSH_THEME setting: `echo $ZSH_THEME`
3. Reload configuration: `source ~/.zshrc`

### Slow Performance
1. Disable audio: `export KAWAII_AUDIO_DISABLE=true`
2. Check git repository status update frequency
3. Consider using a faster terminal emulator

---

🌸 **Kawaii terminal experience awaits!** 💖✨ 