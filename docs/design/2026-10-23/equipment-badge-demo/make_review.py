from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
FONT = ROOT / 'game/ui/fonts/PaytoneOne-Regular.ttf'
canvas = Image.new('RGB', (1328, 440), '#79583e')
draw = ImageDraw.Draw(canvas)
draw.text((28, 18), 'HUY HIỆU NHÔ GÓC · CĂN GIỮA VÙNG NÉT THẬT',
          font=ImageFont.truetype(str(FONT), 26), fill='#fff1d1')
for index, (slot, title) in enumerate([
    ('weapon', 'Vũ khí'), ('helmet', 'Mũ'), ('armor', 'Giáp'), ('boots', 'Giày'),
]):
    card = Image.open(HERE / f'card_{slot}.png').convert('RGB')
    # Exclude the next row's protruding badge from the context crop.
    card = card.crop((0, 0, card.width, card.height - 8))
    card = card.resize((card.width * 2, card.height * 2), Image.Resampling.LANCZOS)
    x = 24 + index * 326
    canvas.paste(card, (x, 74))
    draw.text((x + 148, 383), title, anchor='mt',
              font=ImageFont.truetype(str(FONT), 23), fill='#fff1d1')
canvas.save(HERE / 'badge-closeup.png')
