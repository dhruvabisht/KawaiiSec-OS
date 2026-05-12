# 🧪 KawaiiSec OS Quick Test Checklist

## 🎯 What to Look For

### **Boot Process (Plymouth Splash)**
- [ ] **Kawaii boot splash** appears (pink/purple colors)
- [ ] **Custom boot messages** with kawaii elements (🌸, 💖, etc.)
- [ ] **Progress bar** shows kawaii pink colors
- [ ] **No Debian branding** during boot

### **Desktop Environment**
- [ ] **XFCE desktop** loads successfully  
- [ ] **Default wallpaper** is one of our custom kawaii wallpapers
- [ ] **System shows "KawaiiSec OS"** in about dialogs

### **Wallpapers Test**
1. **Right-click desktop** → Change Wallpaper
2. **Check for these wallpapers**:
   - [ ] kawaii_cafe.png
   - [ ] dreamy_clouds.png  
   - [ ] classic_pastel_workspace.png
   - [ ] retro_terminal.png
3. **Try changing** to different wallpapers

### **Icon Theme Test**
- [ ] **Application icons** use KawaiiSec theme (not default)
- [ ] **Panel icons** reflect kawaii theme
- [ ] **File manager icon** is custom (not generic)

### **System Branding Test**
1. **Open terminal** and run:
   ```bash
   cat /etc/os-release
   hostname
   ```
2. **Should show**:
   - [ ] NAME="KawaiiSec OS"
   - [ ] hostname="kawaiisec"

## 🚨 If Something's Wrong

### **No Custom Wallpapers?**
Run in terminal:
```bash
ls /usr/share/backgrounds/kawaiisec/
xfdesktop --reload
```

### **Icons Not Working?**
Run in terminal:
```bash
ls /usr/share/icons/kawaiisec/
gtk-update-icon-cache -f -t /usr/share/icons/kawaiisec
```

### **No Plymouth Splash?**
The July 25th ISO might not have our latest Plymouth fixes. This is expected!

## ✅ Success Criteria

**MINIMUM SUCCESS** (July 25th ISO):
- [x] ISO boots successfully
- [x] XFCE desktop loads
- [x] Shows "KawaiiSec OS" branding
- [ ] Custom wallpapers available

**FULL SUCCESS** (After Docker fix + new build):
- [ ] Kawaii Plymouth splash screen
- [ ] All 4 custom wallpapers working
- [ ] KawaiiSec icon theme active
- [ ] Complete kawaii branding

## 📝 Test Results

**Date**: $(date)
**ISO Tested**: kawaiisec-os-2025.07.25-amd64.iso
**Test Method**: QEMU VM

**Results**:
- Boot: ⬜ Success / ⬜ Partial / ⬜ Failed
- Wallpapers: ⬜ All 4 / ⬜ Some / ⬜ None
- Icons: ⬜ Custom / ⬜ Default
- Plymouth: ⬜ Kawaii / ⬜ Default / ⬜ None
- Branding: ⬜ Complete / ⬜ Partial

**Notes**:
_Add any observations here..._
