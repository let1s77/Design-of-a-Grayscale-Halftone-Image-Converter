from PIL import Image
import os

# Get the directory where this script is located
script_dir = os.path.dirname(os.path.abspath(__file__))

size = 512
img_path = os.path.join(script_dir, '101_mansion.jpg')
output_path = os.path.join(script_dir, 'test.bmp')

img = Image.open(img_path)
img = img.resize((size, size))
img.save(output_path, 'BMP')
img.close()

print(f"Successfully converted {img_path} to {output_path}")

