
from PIL import Image, ImageDraw
import numpy as np

def create_kawaii_background(width=1920, height=1080):
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
