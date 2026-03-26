import os
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)

INPUT_IMAGE_PATH = os.path.join(PROJECT_ROOT, "scripts", "input.jpg")
OUTPUT_MEM_PATH = os.path.join(PROJECT_ROOT, "rtl", "memory", "image.mem")
OUTPUT_JPG_PATH = os.path.join(PROJECT_ROOT, "scripts", "output.jpg")


"""
RGB is typically 24 bits, 8 bit red, 8 bit green and 8 bit blue 
Because BRAM unit is limited memory 18k I store the image data in RGB 565 
RGB 565 - 5 bits red, 6 bits green, 5 bits blue. A total of 16 bits. 
Total size of image is 80x80*16= 102.4k
Approximatly 6-8 block wills be used to store this image.
Move to PSRAM in the future? 64M
"""


def rgb_to_rgb565(r, g, b):
    """Convert 8 bit RGB to 16bit RGB565."""
    return ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)


def rgb565_to_rgb(value):
    """Convert RGB565 back to 8bit RGB for saving."""
    r = ((value >> 11) & 0x1F) << 3
    g = ((value >> 5) & 0x3F) << 2
    b = (value & 0x1F) << 3
    return r, g, b


def write_mem_file(img):
    """Writes the memory file using the hardcoded OUTPUT_MEM_PATH."""
    os.makedirs(os.path.dirname(OUTPUT_MEM_PATH), exist_ok=True)

    with open(OUTPUT_MEM_PATH, "w") as f:
        for y in range(img.height):
            for x in range(img.width):
                r, g, b = img.getpixel((x, y))
                rgb565 = rgb_to_rgb565(r, g, b)
                # Conver to 4 digit hex value
                f.write(f"{rgb565:04X}\n")

    print(f"Saved memory file to: {OUTPUT_MEM_PATH}")


def write_jpg(img):
    """Processes and saves the JPEG using the hardcoded OUTPUT_JPG_PATH."""
    pixels = img.load()

    for y in range(img.height):
        for x in range(img.width):
            r, g, b = pixels[x, y]
            rgb565 = rgb_to_rgb565(r, g, b)
            r2, g2, b2 = rgb565_to_rgb(rgb565)
            pixels[x, y] = (r2, g2, b2)

    img.save(OUTPUT_JPG_PATH, "JPEG")
    print(f"Saved processed image to: {OUTPUT_JPG_PATH}")


def process_image():
    """Main processing logic using hardcoded paths."""
    if not os.path.exists(INPUT_IMAGE_PATH):
        print(f"Error: Input file not found at {INPUT_IMAGE_PATH}")
        return

    img = Image.open(INPUT_IMAGE_PATH).convert("RGB")

    width, height = img.size
    if width != height:
        min_dim = min(width, height)
        img = img.crop((0, 0, min_dim, min_dim))

    img = img.resize((80, 80), Image.NEAREST)

    write_mem_file(img)
    write_jpg(img)


if __name__ == "__main__":
    process_image()
