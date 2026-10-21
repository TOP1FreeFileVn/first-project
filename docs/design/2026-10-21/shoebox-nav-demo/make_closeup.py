from pathlib import Path
from PIL import Image

here = Path(__file__).resolve().parent
rows = []
for name in ['native-battle.png', 'native-shop.png']:
    image = Image.open(here / name).convert('RGB')
    rows.append(image.crop((0, 538, 360, 640)).resize((1080, 306), Image.Resampling.LANCZOS))
result = Image.new('RGB', (1080, 624), '#d6bc89')
result.paste(rows[0], (0, 0))
result.paste(rows[1], (0, 318))
result.save(here / 'changed-boxes-closeup.png')
print(here / 'changed-boxes-closeup.png')
