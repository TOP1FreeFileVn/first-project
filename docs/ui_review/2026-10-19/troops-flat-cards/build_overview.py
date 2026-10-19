from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
font = ImageFont.truetype(str(ROOT / 'game/ui/fonts/DejaVuSans.ttf'), 18)
top = Image.open(HERE / 'top_720.png').convert('RGB')
bottom = Image.open(HERE / 'bottom_720.png').convert('RGB')

# The top capture contains two earned counts and two locked rarities. The scrolled
# capture contains the third earned count at y=554, with the same native card size.
cards = [
    (top, (24, 538, 181, 778), '1 sao'),
    (top, (193, 538, 350, 778), '2 sao'),
    (bottom, (24, 554, 181, 794), '3 sao'),
    (top, (362, 538, 519, 778), 'Khóa · Sử thi'),
    (top, (531, 538, 688, 778), 'Khóa · H.thoại'),
]
board = Image.new('RGB', (912, 292), '#e6edf2')
draw = ImageDraw.Draw(board)
for i, (source, rect, label) in enumerate(cards):
    x = 16 + i * 178
    draw.text((x, 10), label, font=font, fill='#583f21')
    board.paste(source.crop(rect), (x, 42))
board.save(HERE / 'card-overview.png')
