from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
font = ImageFont.truetype(str(ROOT / 'game/ui/fonts/DejaVuSans.ttf'), 22)
small = ImageFont.truetype(str(ROOT / 'game/ui/fonts/DejaVuSans.ttf'), 17)
for page in ['lobby', 'troops', 'shop']:
    board = Image.new('RGB', (948, 626), '#fff7e9')
    draw = ImageDraw.Draw(board)
    for x, key, title, desc, color in [
        (12, 'current', 'Hiện tại', 'Xanh sáng · họa tiết rõ', '#6fa3e0'),
        (328, 'blue-gray', 'Xanh lam xám', 'Họa tiết nhẹ hơn', '#9bb5c4'),
        (644, 'sage', 'Xanh lá xám', 'Họa tiết nhẹ hơn', '#a0b8a3'),
    ]:
        draw.ellipse((x, 13, x + 20, 33), fill=color, outline='#583f21', width=1)
        draw.text((x + 29, 7), title, font=font, fill='#583f21')
        draw.text((x, 41), desc, font=small, fill='#583f21')
        screen = Image.open(HERE / f'{key}-{page}.png').convert('RGB')
        board.paste(screen.resize((300, 533), Image.Resampling.LANCZOS), (x, 78))
    board.save(HERE / f'{page}-comparison.png')
