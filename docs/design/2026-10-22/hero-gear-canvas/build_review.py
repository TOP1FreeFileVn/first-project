from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

here = Path(__file__).resolve().parent
root = here.parents[3]
font_file = root / 'game/ui/fonts/PaytoneOne-Regular.ttf'
title_font = ImageFont.truetype(str(font_file), 26)
small_font = ImageFont.truetype(str(font_file), 14)
ink = '#583f21'
board = Image.new('RGBA', (720, 560), '#e4e9e2')
draw = ImageDraw.Draw(board)

for index, (slug, title) in enumerate([('helmet', 'MŨ SẮT'), ('boots', 'ĐÔI GIÀY GIÁP')]):
    left = 20 + index * 350
    draw.rounded_rectangle((left, 20, left + 330, 540), radius=20, fill='#f4f4ed')
    draw.text((left + 165, 42), title, font=title_font, fill=ink, anchor='mt')
    board.alpha_composite(Image.open(here / f'godot/{slug}-icon-256.png').convert('RGBA'), (left + 37, 102))
    for size, x in [(32, left + 28), (48, left + 82), (64, left + 152), (96, left + 220)]:
        board.alpha_composite(Image.open(here / f'godot/{slug}-icon-{size}.png').convert('RGBA'), (x, 480 - size))
        draw.text((x + size / 2, 498), f'{size}px', font=small_font, fill='#796b56', anchor='mt')

board.convert('RGB').save(here / 'review.png')
print('Saved native Godot review.png')
