#!/usr/bin/env python3
"""
🌸 KawaiiSec Plymouth Theme Demonstration 🌸
Shows off different kawaii boot themes and generates samples
"""

import subprocess
import time
import os
from pathlib import Path

def run_generator(color, theme_name):
    """Run the Plymouth generator with specified parameters"""
    cmd = [
        "python3", "assets/scripts/system/kawaii-plymouth.py",
        "--generate",
        "--color", color,
        "--theme-name", theme_name
    ]
    
    print(f"🎨 Generating {color} theme ({theme_name})...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print(f"✅ {color.capitalize()} theme generated successfully!")
        return True
    else:
        print(f"❌ Failed to generate {color} theme:")
        print(result.stderr)
        return False

def create_demo_background(color_name, output_path):
    """Create a sample background image for demonstration"""
    script = f'''
from PIL import Image, ImageDraw, ImageFont
import numpy as np

def create_demo_background():
    width, height = 800, 600  # Smaller for demo
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Color schemes
    colors = {{
        'pink': [(255, 178, 204), (204, 133, 255), (153, 200, 255)],
        'purple': [(204, 153, 255), (153, 102, 255), (102, 51, 255)], 
        'blue': [(178, 229, 255), (153, 200, 255), (102, 153, 255)],
        'mint': [(178, 255, 229), (153, 255, 200), (102, 255, 153)],
        'peach': [(255, 229, 178), (255, 200, 153), (255, 153, 102)]
    }}
    
    scheme = colors.get('{color_name}', colors['pink'])
    
    # Create gradient
    for y in range(height):
        t = y / height
        if t < 0.5:
            # First half: color 1 to color 2
            local_t = t * 2
            r = int(scheme[0][0] * (1-local_t) + scheme[1][0] * local_t)
            g = int(scheme[0][1] * (1-local_t) + scheme[1][1] * local_t)
            b = int(scheme[0][2] * (1-local_t) + scheme[1][2] * local_t)
        else:
            # Second half: color 2 to color 3
            local_t = (t - 0.5) * 2
            r = int(scheme[1][0] * (1-local_t) + scheme[2][0] * local_t)
            g = int(scheme[1][1] * (1-local_t) + scheme[2][1] * local_t)
            b = int(scheme[1][2] * (1-local_t) + scheme[2][2] * local_t)
        
        draw.line([(0, y), (width, y)], fill=(r, g, b, 255))
    
    # Add some sparkles
    for _ in range(50):
        x = np.random.randint(0, width)
        y = np.random.randint(0, height)
        size = np.random.randint(1, 4)
        
        # Draw sparkle as small cross
        draw.line([(x-size, y), (x+size, y)], fill=(255, 255, 255, 200), width=1)
        draw.line([(x, y-size), (x, y+size)], fill=(255, 255, 255, 200), width=1)
    
    # Add demo text
    try:
        font = ImageFont.load_default()
        text = f"KawaiiSec OS - {{'{color_name}'.title()}} Theme"
        text_bbox = draw.textbbox((0, 0), text, font=font)
        text_width = text_bbox[2] - text_bbox[0]
        text_x = (width - text_width) // 2
        text_y = height // 2 - 20
        
        # Text shadow
        draw.text((text_x+2, text_y+2), text, fill=(0, 0, 0, 128), font=font)
        # Main text
        draw.text((text_x, text_y), text, fill=(255, 255, 255, 255), font=font)
    except:
        pass  # Skip text if font loading fails
    
    return img

if __name__ == "__main__":
    bg = create_demo_background()
    bg.save("{output_path}", "PNG")
    print(f"✨ Created demo background: {output_path}")
'''
    
    # Write and execute the script
    script_path = Path("temp_bg_script.py")
    with open(script_path, 'w') as f:
        f.write(script)
    
    try:
        subprocess.run(["python3", str(script_path)], check=True)
        script_path.unlink()  # Clean up
        return True
    except subprocess.CalledProcessError:
        print(f"⚠️  Could not create demo background (PIL not available)")
        script_path.unlink()  # Clean up
        return False

def main():
    print("🌸 KawaiiSec Plymouth Theme Demonstration 🌸")
    print("=" * 50)
    
    # Color schemes to demonstrate
    themes = [
        ("pink", "kawaii-demo-pink"),
        ("purple", "kawaii-demo-purple"), 
        ("blue", "kawaii-demo-blue"),
        ("mint", "kawaii-demo-mint"),
        ("peach", "kawaii-demo-peach")
    ]
    
    generated_themes = []
    
    # Generate all themes
    for color, theme_name in themes:
        if run_generator(color, theme_name):
            generated_themes.append((color, theme_name))
            
            # Try to create a demo background
            theme_dir = Path(f"assets/themes/boot/{theme_name}")
            if theme_dir.exists():
                bg_path = theme_dir / "demo_background.png"
                create_demo_background(color, str(bg_path))
        
        time.sleep(0.5)  # Small delay between generations
    
    print("\n🎉 Demonstration Complete!")
    print("=" * 50)
    
    if generated_themes:
        print(f"✅ Generated {len(generated_themes)} kawaii boot themes:")
        for color, theme_name in generated_themes:
            theme_path = Path(f"assets/themes/boot/{theme_name}")
            print(f"   🎨 {color.capitalize()}: {theme_path}")
        
        print("\n📋 To install any theme:")
        print("   sudo python3 assets/scripts/system/kawaii-plymouth.py --install --theme-name <theme-name>")
        
        print("\n🧪 To test on Linux:")
        print("   sudo assets/themes/boot/<theme-name>/install.sh")
        
        print("\n📁 Theme files locations:")
        for color, theme_name in generated_themes:
            theme_dir = Path(f"assets/themes/boot/{theme_name}")
            if theme_dir.exists():
                files = list(theme_dir.glob("*"))
                print(f"   {color.capitalize()}: {len(files)} files in {theme_dir}")
    else:
        print("❌ No themes were generated successfully")
    
    print("\n🌸 Kawaii boot experience ready! 💖✨")

if __name__ == "__main__":
    main() 