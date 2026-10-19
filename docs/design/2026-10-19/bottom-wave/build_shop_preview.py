from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
font = ImageFont.truetype(str(ROOT / 'game/ui/fonts/DejaVuSans.ttf'), 23)
out = Image.new('RGB', (756, 380), '#fff7e9')
draw = ImageDraw.Draw(out)
for x, file_name, title in [
    (20, '04-shop-current.png', 'Hiện tại'),
    (398, '05-shop-footer-wave.png', 'Đường ngăn lượn sóng'),
]:
    draw.text((x, 14), title, font=font, fill='#583f21')
    tile = Image.open(HERE / file_name).convert('RGB').crop((4, 1122, 181, 1280))
    out.paste(tile.resize((354, 316), Image.Resampling.LANCZOS), (x, 52))
out.save(HERE / 'shop-divider-comparison.png')
