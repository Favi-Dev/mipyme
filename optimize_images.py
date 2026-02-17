import os
from PIL import Image

image_dir = "assets/images"
logo_file = "LOGOSOYPLUS.png"
onboarding_files = [f"onboarding_{i}.png" for i in range(1, 5)]

# Optimization settings
MAX_WIDTH_ONBOARDING = 800
MAX_WIDTH_LOGO = 400
QUALITY = 85

def optimize_image(filename, max_width):
    filepath = os.path.join(image_dir, filename)
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return

    original_size = os.path.getsize(filepath)
    
    with Image.open(filepath) as img:
        # Create backup if not exists
        backup_path = filepath + ".bak"
        if not os.path.exists(backup_path):
            img.save(backup_path)
            print(f"Created backup: {backup_path}")

        # Resize logic
        if img.width > max_width:
            ratio = max_width / float(img.width)
            new_height = int((float(img.height) * ratio))
            img = img.resize((max_width, new_height), Image.Resampling.LANCZOS)
        
        # Save optimized
        img.save(filepath, optimize=True, quality=QUALITY)
        
    new_size = os.path.getsize(filepath)
    reduction = (1 - new_size / original_size) * 100
    print(f"Optimized {filename}: {original_size/1024:.1f}KB -> {new_size/1024:.1f}KB ({reduction:.1f}% smaller)")

print("\n--- Optimizing Images ---")
optimize_image(logo_file, MAX_WIDTH_LOGO)
for f in onboarding_files:
    optimize_image(f, MAX_WIDTH_ONBOARDING)
print("--- Done ---")
