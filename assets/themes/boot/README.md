# 🌸 KawaiiSec Plymouth Boot Themes

Beautiful kawaii boot splash themes for KawaiiSec OS using Plymouth.

## 🎨 Features

- **🌈 Kawaii Gradient Background** - Pastel pink to purple to blue sunset
- **✨ Sparkle Particle Effects** - Animated sparkles at progress bar edge
- **💖 Pulsing Progress Bar** - Smooth filling with cute pulsing animation
- **🎭 Kawaii Boot Messages** - Context-aware loading messages
- **🌸 Mascot Animation** - Optional bobbing mascot character
- **🎨 Multiple Color Schemes** - Pink, purple, blue, mint, peach themes

## 🚀 Quick Start

### 1. Install Dependencies

```bash
# Install Python dependencies
pip install -r assets/themes/boot/requirements.txt

# Install Plymouth (Ubuntu/Debian)
sudo apt install plymouth plymouth-themes
```

### 2. Generate Theme

```bash
# Generate default pink theme
python3 assets/scripts/system/kawaii-plymouth.py --generate

# Generate with different color scheme
python3 assets/scripts/system/kawaii-plymouth.py --generate --color purple
```

### 3. Install Theme

```bash
# Install to system (requires root)
sudo python3 assets/scripts/system/kawaii-plymouth.py --install

# Or use the generated installer
sudo assets/themes/boot/kawaiisec/install.sh
```

### 4. Test & Reboot

```bash
# Test the theme immediately
sudo plymouth --show-splash
# Press Ctrl+Alt+F1 to return

# Reboot to see full boot experience
sudo reboot
```

## 🎨 Color Schemes

The generator supports multiple kawaii color palettes:

- **`pink`** (default) - Classic kawaii pink theme
- **`purple`** - Royal lavender theme  
- **`blue`** - Baby blue theme
- **`mint`** - Fresh mint green theme
- **`peach`** - Warm peach theme

```bash
# Generate different color themes
python3 assets/scripts/system/kawaii-plymouth.py --generate --color mint
python3 assets/scripts/system/kawaii-plymouth.py --generate --color blue
```

## 📁 Theme Structure

Generated themes contain:

```
assets/themes/boot/kawaiisec/
├── kawaiisec.plymouth       # Plymouth theme configuration
├── kawaiisec.script         # Main animation script (JavaScript-like)
├── install.sh              # Automated installer script
├── create_background.py     # Background generation script
├── background.png           # Generated gradient background
└── logo.png                # KawaiiSec logo (if available)
```

## 🛠️ Customization

### Background Graphics

To create custom backgrounds:

```bash
# Generate kawaii gradient background
cd assets/themes/boot/kawaiisec/
python3 create_background.py
```

### Mascot Characters

Add a mascot by placing `mascot.png` in the theme directory:

```bash
# Copy your kawaii mascot
cp /path/to/your/mascot.png assets/themes/boot/kawaiisec/mascot.png
```

### Boot Messages

Edit the `boot_messages` array in the `.script` file:

```javascript
boot_messages = [
    "🌸 Starting KawaiiSec OS...",
    "💖 Loading kawaii components...", 
    "✨ Initializing security systems...",
    // Add your own messages!
];
```

### Colors & Effects

Modify the color values in the Python generator or directly in the script:

```javascript
// In the .script file
Window.SetSourceRGBA(1.0, 0.7, 0.8, 1.0);  // RGBA pink
```

## 🔧 Advanced Usage

### Manual Installation

```bash
# 1. Copy theme to Plymouth directory
sudo cp -r assets/themes/boot/kawaiisec /usr/share/plymouth/themes/

# 2. Set as default theme
sudo plymouth-set-default-theme kawaiisec

# 3. Update GRUB config
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& quiet splash/' /etc/default/grub

# 4. Update initramfs and GRUB
sudo update-initramfs -u
sudo update-grub
```

### Multiple Themes

Generate and manage multiple themes:

```bash
# Generate different named themes
python3 assets/scripts/system/kawaii-plymouth.py --generate --theme-name kawaii-pink --color pink
python3 assets/scripts/system/kawaii-plymouth.py --generate --theme-name kawaii-blue --color blue

# Switch between themes
sudo plymouth-set-default-theme kawaii-pink
sudo plymouth-set-default-theme kawaii-blue
```

### Development Mode

Skip graphic generation for faster iteration:

```bash
python3 assets/scripts/system/kawaii-plymouth.py --generate --no-graphics
```

## 🧪 Testing

### Preview Theme

```bash
# Show splash immediately (for testing)
sudo plymouth --show-splash

# In another terminal, simulate progress
for i in {1..100}; do 
    echo $i | sudo tee /sys/class/graphics/fb0/progress > /dev/null
    sleep 0.1
done
```

### Debug Mode

```bash
# Run Plymouth in debug mode
sudo plymouth --debug --show-splash
```

### Reset to Default

```bash
# Reset to Ubuntu default theme
sudo plymouth-set-default-theme ubuntu-logo
sudo update-initramfs -u
```

## 🎯 Integration with KawaiiSec

The boot theme integrates with other KawaiiSec components:

- **🎨 Graphics**: Uses logos from `assets/graphics/logos/`
- **🌸 Branding**: Consistent kawaii aesthetic with terminal themes
- **🔊 Audio**: Future integration with boot sound effects
- **🎭 Themes**: Part of the unified theming system

## 🐛 Troubleshooting

### Common Issues

**Theme not appearing:**
```bash
# Check current theme
sudo plymouth-set-default-theme --list
sudo plymouth-set-default-theme --print-current

# Regenerate initramfs
sudo update-initramfs -u
```

**Graphics not loading:**
```bash
# Check file permissions
ls -la /usr/share/plymouth/themes/kawaiisec/
sudo chmod 644 /usr/share/plymouth/themes/kawaiisec/*
```

**Script errors:**
```bash
# Check Plymouth logs
sudo journalctl -u plymouth-start
```

### Performance Issues

- Reduce `max_particles` in the script for slower hardware
- Use smaller background images (1920x1080 instead of 4K)
- Disable mascot animation for faster boot

## 📱 Compatibility

- **Ubuntu 20.04+**: Full support
- **Debian 11+**: Full support  
- **Fedora 35+**: Compatible with minor adjustments
- **Arch Linux**: Compatible with AUR Plymouth packages
- **Other Distros**: May require Plymouth package installation

## 🌟 Examples

### Corporate Theme
```bash
python3 assets/scripts/system/kawaii-plymouth.py --generate --color blue --theme-name kawaii-corporate
```

### Cute Theme
```bash
python3 assets/scripts/system/kawaii-plymouth.py --generate --color pink --theme-name kawaii-cute
```

### Hacker Theme
```bash
python3 assets/scripts/system/kawaii-plymouth.py --generate --color purple --theme-name kawaii-hacker
```

## 🔮 Future Features

- [ ] Animated mascot sprites
- [ ] Boot sound integration
- [ ] Weather-based color themes
- [ ] User avatar support
- [ ] Multi-monitor awareness
- [ ] Seasonal theme variants

---

🌸 **Boot into kawaii paradise!** 💖✨ 