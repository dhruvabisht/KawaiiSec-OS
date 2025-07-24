#!/usr/bin/env python3
"""
🌸 KawaiiSec Plymouth Boot Splash Generator 🌸
Generates beautiful kawaii boot splash themes for Plymouth
"""

import os
import sys
import json
import shutil
import subprocess
from pathlib import Path
from typing import Dict, List, Optional
import argparse

# Kawaii color palette
KAWAII_COLORS = {
    'pink': (1.0, 0.7, 0.8, 1.0),      # Pastel pink
    'purple': (0.8, 0.6, 1.0, 1.0),    # Lavender
    'blue': (0.7, 0.9, 1.0, 1.0),      # Baby blue  
    'mint': (0.7, 1.0, 0.9, 1.0),      # Mint green
    'peach': (1.0, 0.9, 0.7, 1.0),     # Peach
    'white': (1.0, 1.0, 1.0, 0.8),     # Semi-transparent white
    'dark': (0.2, 0.1, 0.3, 0.9),      # Dark purple
}

class KawaiiPlymouthGenerator:
    def __init__(self, theme_name: str = "kawaiisec", project_root: str = None):
        self.theme_name = theme_name
        self.project_root = Path(project_root) if project_root else Path(__file__).parent.parent.parent
        self.assets_dir = self.project_root / "assets"
        self.themes_dir = self.assets_dir / "themes" / "boot" 
        self.graphics_dir = self.assets_dir / "graphics"
        
        # Plymouth paths
        self.plymouth_themes_dir = Path("/usr/share/plymouth/themes")
        self.theme_install_dir = self.plymouth_themes_dir / self.theme_name
        
        # Ensure directories exist
        self.themes_dir.mkdir(parents=True, exist_ok=True)
        
    def generate_plymouth_config(self) -> str:
        """Generate the .plymouth configuration file"""
        config = f"""[Plymouth Theme]
Name=KawaiiSec OS
Description=Kawaii pastel boot splash for KawaiiSec OS with cute progress bar
ModuleName=script

[script]
ImageDir={self.theme_install_dir}
ScriptFile={self.theme_install_dir}/{self.theme_name}.script
"""
        return config
    
    def generate_plymouth_script(self, color_scheme: str = "pink") -> str:
        """Generate the Plymouth script with kawaii animations"""
        
        # Get color values
        primary_color = KAWAII_COLORS.get(color_scheme, KAWAII_COLORS['pink'])
        bg_color = KAWAII_COLORS['white']
        text_color = KAWAII_COLORS['dark']
        
        script = f'''// 🌸 KawaiiSec OS Plymouth Boot Splash 🌸
// Kawaii boot experience with cute progress animations

// Load assets
background_image = Image("background.png");
logo_image = Image("logo.png");
mascot_image = Image("mascot.png");

// Animation state
progress = 0.0;
time = 0.0;
pulse_phase = 0.0;

// Kawaii messages for different boot stages
boot_messages = [
    "🌸 Starting KawaiiSec OS...",
    "💖 Loading kawaii components...", 
    "✨ Initializing security systems...",
    "🎵 Setting up audio...",
    "🛡️ Activating protection...",
    "🌟 Almost ready nyaa~",
    "🎉 Welcome to KawaiiSec OS!"
];

current_message = 0;
message_timer = 0;

// Cute particle system for sparkles
particles = [];
max_particles = 20;

function create_particle(x, y) {{
    particle = [];
    particle.x = x + (Math.Random() - 0.5) * 100;
    particle.y = y + (Math.Random() - 0.5) * 50;
    particle.vx = (Math.Random() - 0.5) * 2;
    particle.vy = (Math.Random() - 0.5) * 2;
    particle.life = 1.0;
    particle.size = Math.Random() * 3 + 1;
    return particle;
}}

function update_particles(dt) {{
    for (i = 0; i < particles.GetLength(); i++) {{
        p = particles[i];
        if (p) {{
            p.x += p.vx * dt;
            p.y += p.vy * dt;
            p.life -= dt * 0.5;
            
            if (p.life <= 0) {{
                particles[i] = null;
            }}
        }}
    }}
}}

function draw_particles() {{
    for (i = 0; i < particles.GetLength(); i++) {{
        p = particles[i];
        if (p && p.life > 0) {{
            // Sparkle effect
            alpha = p.life;
            Window.SetSourceRGBA({primary_color[0]}, {primary_color[1]}, {primary_color[2]}, alpha);
            
            // Draw sparkle as a small cross
            size = p.size * p.life;
            Window.DrawLine(p.x - size, p.y, p.x + size, p.y, 1);
            Window.DrawLine(p.x, p.y - size, p.x, p.y + size, 1);
        }}
    }}
}}

function draw_kawaii_progress_bar(x, y, width, height, progress_val) {{
    // Background bar with rounded edges (simulated)
    Window.SetSourceRGBA({bg_color[0]}, {bg_color[1]}, {bg_color[2]}, {bg_color[3]});
    Window.FillRectangle(x, y, width, height);
    
    // Progress fill with pulsing effect
    pulse = Math.Sin(pulse_phase) * 0.2 + 0.8;
    fill_width = width * progress_val;
    
    if (fill_width > 0) {{
        Window.SetSourceRGBA(
            {primary_color[0]} * pulse, 
            {primary_color[1]} * pulse, 
            {primary_color[2]} * pulse, 
            {primary_color[3]}
        );
        Window.FillRectangle(x, y, fill_width, height);
        
        // Add sparkles at the progress edge
        if (Math.Random() < 0.3 && particles.GetLength() < max_particles) {{
            particles[particles.GetLength()] = create_particle(x + fill_width, y + height/2);
        }}
    }}
    
    // Cute border
    Window.SetSourceRGBA({text_color[0]}, {text_color[1]}, {text_color[2]}, 0.5);
    Window.DrawRectangle(x-1, y-1, width+2, height+2, 2);
}}

function draw_kawaii_text(text, x, y, size) {{
    // Simple text rendering (Plymouth's text is basic)
    Window.SetSourceRGBA({text_color[0]}, {text_color[1]}, {text_color[2]}, 0.9);
    // Note: Plymouth text positioning is approximate
    Window.WriteText(text, x, y);
}}

function get_boot_message() {{
    stage = Math.Floor(progress * boot_messages.GetLength());
    if (stage >= boot_messages.GetLength()) {{
        stage = boot_messages.GetLength() - 1;
    }}
    return boot_messages[stage];
}}

function refresh_callback() {{
    // Update timing
    time += 0.05;  // Approximate frame time
    pulse_phase += 0.1;
    message_timer += 0.05;
    
    // Get current progress from Plymouth
    progress = Plymouth.GetMode() == "boot" ? Plymouth.GetProgress() : 1.0;
    if (progress == 0) progress = time * 0.1; // Fallback animation
    if (progress > 1.0) progress = 1.0;
    
    // Update particles
    update_particles(0.05);
    
    // Clear screen
    Window.Clear();
    
    // Get screen dimensions
    screen_width = Window.GetWidth();
    screen_height = Window.GetHeight();
    
    // Draw background
    if (background_image) {{
        bg_x = (screen_width - background_image.GetWidth()) / 2;
        bg_y = (screen_height - background_image.GetHeight()) / 2;
        background_image.Draw(bg_x, bg_y);
    }} else {{
        // Fallback gradient background
        Window.SetSourceRGBA({bg_color[0]}, {bg_color[1]}, {bg_color[2]}, 1.0);
        Window.FillRectangle(0, 0, screen_width, screen_height);
    }}
    
    // Draw logo
    if (logo_image) {{
        logo_x = (screen_width - logo_image.GetWidth()) / 2;
        logo_y = screen_height * 0.3;
        logo_image.Draw(logo_x, logo_y);
    }}
    
    // Draw mascot with cute bobbing animation
    if (mascot_image) {{
        bob_offset = Math.Sin(time * 2) * 5;
        mascot_x = screen_width * 0.85;
        mascot_y = screen_height * 0.7 + bob_offset;
        mascot_image.Draw(mascot_x, mascot_y);
    }}
    
    // Progress bar
    bar_width = screen_width * 0.6;
    bar_height = 20;
    bar_x = (screen_width - bar_width) / 2;
    bar_y = screen_height * 0.75;
    
    draw_kawaii_progress_bar(bar_x, bar_y, bar_width, bar_height, progress);
    
    // Boot message
    message = get_boot_message();
    text_x = screen_width * 0.5 - 100; // Approximate centering
    text_y = bar_y + 40;
    draw_kawaii_text(message, text_x, text_y, 16);
    
    // Progress percentage
    percent_text = Math.Floor(progress * 100) + "%";
    percent_x = screen_width * 0.5 - 20;
    percent_y = bar_y - 25;
    draw_kawaii_text(percent_text, percent_x, percent_y, 14);
    
    // Draw sparkle particles
    draw_particles();
}}

// Event handlers
Plymouth.SetRefreshFunction(refresh_callback);

// Password prompt styling (if needed)
Plymouth.SetDisplayPasswordFunction(function(prompt, bullets) {{
    // Style password prompts with kawaii theme
    Window.SetSourceRGBA({text_color[0]}, {text_color[1]}, {text_color[2]}, 1.0);
    Window.WriteText(prompt, 50, Window.GetHeight() - 100);
    Window.WriteText(bullets, 50, Window.GetHeight() - 80);
}});

// Initial setup
refresh_callback();
'''
        return script
    
    def create_gradient_background(self, width: int = 1920, height: int = 1080) -> str:
        """Generate Python code to create gradient background using PIL"""
        return f'''
from PIL import Image, ImageDraw
import numpy as np

def create_kawaii_background(width={width}, height={height}):
    """Create a kawaii gradient background"""
    # Create image
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    
    # Create gradient from top to bottom
    for y in range(height):
        # Interpolate between colors
        t = y / height
        
        # Kawaii sunset gradient: pink -> purple -> blue
        if t < 0.4:
            # Pink to purple
            local_t = t / 0.4
            r = int(255 * (1.0 - local_t * 0.2))  # 255 -> 204
            g = int(178 * (1.0 - local_t * 0.25)) # 178 -> 133  
            b = int(204 * (1.0 + local_t * 0.25)) # 204 -> 255
        elif t < 0.8:
            # Purple to blue
            local_t = (t - 0.4) / 0.4
            r = int(204 * (1.0 - local_t * 0.25)) # 204 -> 153
            g = int(133 * (1.0 + local_t * 0.5))  # 133 -> 200
            b = 255  # Keep blue high
        else:
            # Blue to darker blue
            local_t = (t - 0.8) / 0.2
            r = int(153 * (1.0 - local_t * 0.3))  # 153 -> 107
            g = int(200 * (1.0 - local_t * 0.3))  # 200 -> 140
            b = int(255 * (1.0 - local_t * 0.1))  # 255 -> 230
        
        # Add subtle sparkle texture
        if np.random.random() < 0.001:  # Sparse sparkles
            r = min(255, r + 50)
            g = min(255, g + 50)
            b = min(255, b + 50)
        
        # Draw horizontal line
        draw = ImageDraw.Draw(img)
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))
    
    return img

if __name__ == "__main__":
    bg = create_kawaii_background()
    bg.save("background.png", "PNG")
    print("✨ Created kawaii gradient background!")
'''
    
    def generate_installation_script(self) -> str:
        """Generate bash installation script"""
        return f'''#!/bin/bash
# 🌸 KawaiiSec Plymouth Theme Installer 🌸

set -e

THEME_NAME="{self.theme_name}"
THEME_DIR="/usr/share/plymouth/themes/$THEME_NAME"
ASSETS_DIR="{self.themes_dir}"

echo "🌸 Installing KawaiiSec Plymouth Boot Splash Theme..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   exit 1
fi

# Install Plymouth if not present
if ! command -v plymouth &> /dev/null; then
    echo "📦 Installing Plymouth..."
    apt update
    apt install -y plymouth plymouth-themes
fi

# Create theme directory
echo "📁 Creating theme directory..."
mkdir -p "$THEME_DIR"

# Copy theme files
echo "📋 Installing theme files..."
cp "$ASSETS_DIR/{self.theme_name}.plymouth" "$THEME_DIR/"
cp "$ASSETS_DIR/{self.theme_name}.script" "$THEME_DIR/"

# Copy assets if they exist
for asset in background.png logo.png mascot.png; do
    if [[ -f "$ASSETS_DIR/$asset" ]]; then
        echo "🎨 Installing $asset..."
        cp "$ASSETS_DIR/$asset" "$THEME_DIR/"
    else
        echo "⚠️  $asset not found, theme will use fallback"
    fi
done

# Set theme as default
echo "🎭 Setting KawaiiSec as default Plymouth theme..."
plymouth-set-default-theme "$THEME_NAME"

# Update GRUB configuration
echo "🔧 Updating GRUB configuration..."
if ! grep -q "quiet splash" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& quiet splash/' /etc/default/grub
    echo "✅ Added 'quiet splash' to GRUB"
else
    echo "✅ GRUB already configured for Plymouth"
fi

# Update initramfs and GRUB
echo "🔄 Updating initramfs and GRUB..."
update-initramfs -u
update-grub

echo ""
echo "🎉 KawaiiSec Plymouth theme installed successfully!"
echo ""
echo "🧪 Test the theme:"
echo "   sudo plymouth --show-splash"
echo "   # Press Ctrl+Alt+F1 to return to terminal"
echo ""
echo "🔄 The theme will appear on next reboot!"
echo "🌸 Enjoy your kawaii boot experience! 💖"
'''
    
    def generate_assets(self, create_graphics: bool = True):
        """Generate all Plymouth theme files and assets"""
        print("🌸 Generating KawaiiSec Plymouth theme files...")
        
        # Create theme files
        theme_dir = self.themes_dir / self.theme_name
        theme_dir.mkdir(exist_ok=True)
        
        # Generate .plymouth config
        with open(theme_dir / f"{self.theme_name}.plymouth", 'w') as f:
            f.write(self.generate_plymouth_config())
        print(f"✅ Created {self.theme_name}.plymouth")
        
        # Generate .script file
        with open(theme_dir / f"{self.theme_name}.script", 'w') as f:
            f.write(self.generate_plymouth_script())
        print(f"✅ Created {self.theme_name}.script")
        
        # Generate installation script
        with open(theme_dir / "install.sh", 'w') as f:
            f.write(self.generate_installation_script())
        os.chmod(theme_dir / "install.sh", 0o755)
        print("✅ Created install.sh")
        
        # Generate background creation script
        if create_graphics:
            with open(theme_dir / "create_background.py", 'w') as f:
                f.write(self.create_gradient_background())
            print("✅ Created create_background.py")
            
            # Try to create background if PIL is available
            try:
                subprocess.run([sys.executable, str(theme_dir / "create_background.py")], 
                             cwd=theme_dir, check=True, capture_output=True)
                print("✅ Generated background.png")
            except (subprocess.CalledProcessError, FileNotFoundError):
                print("⚠️  PIL not available - run create_background.py manually to generate background")
        
        # Copy logo if available
        logo_sources = [
            self.graphics_dir / "logos" / "Kawaii.png",
            self.graphics_dir / "logos" / "logo.svg",
        ]
        
        for logo_src in logo_sources:
            if logo_src.exists():
                shutil.copy2(logo_src, theme_dir / "logo.png")
                print(f"✅ Copied logo from {logo_src}")
                break
        else:
            print("⚠️  No logo found in assets/graphics/logos/ - theme will use text fallback")
        
        return theme_dir
    
    def install_theme(self):
        """Install the theme to system Plymouth directory (requires root)"""
        if os.geteuid() != 0:
            print("❌ Installation requires root privileges. Run with sudo.")
            return False
            
        theme_dir = self.themes_dir / self.theme_name
        if not theme_dir.exists():
            print("❌ Theme not generated yet. Run --generate first.")
            return False
            
        print(f"🚀 Installing theme to {self.theme_install_dir}...")
        
        # Create system theme directory
        self.theme_install_dir.mkdir(parents=True, exist_ok=True)
        
        # Copy all theme files
        for file_path in theme_dir.glob("*"):
            if file_path.name not in ["install.sh", "create_background.py"]:
                shutil.copy2(file_path, self.theme_install_dir)
                print(f"✅ Installed {file_path.name}")
        
        # Set as default theme
        subprocess.run(["plymouth-set-default-theme", self.theme_name], check=True)
        print("✅ Set as default Plymouth theme")
        
        return True

def main():
    parser = argparse.ArgumentParser(description="🌸 KawaiiSec Plymouth Boot Splash Generator")
    parser.add_argument("--generate", action="store_true", help="Generate theme files")
    parser.add_argument("--install", action="store_true", help="Install theme (requires root)")
    parser.add_argument("--theme-name", default="kawaiisec", help="Theme name")
    parser.add_argument("--color", choices=list(KAWAII_COLORS.keys()), default="pink", 
                       help="Primary color scheme")
    parser.add_argument("--no-graphics", action="store_true", help="Skip graphic generation")
    
    args = parser.parse_args()
    
    if not args.generate and not args.install:
        parser.print_help()
        return
    
    generator = KawaiiPlymouthGenerator(args.theme_name)
    
    if args.generate:
        theme_dir = generator.generate_assets(not args.no_graphics)
        print(f"\n🎉 Theme generated in: {theme_dir}")
        print(f"📋 To install: sudo python3 {__file__} --install")
        print(f"🧪 Or run: sudo {theme_dir}/install.sh")
    
    if args.install:
        if generator.install_theme():
            print("\n🎉 Theme installed successfully!")
            print("🔄 Reboot to see your kawaii boot splash!")

if __name__ == "__main__":
    main() 