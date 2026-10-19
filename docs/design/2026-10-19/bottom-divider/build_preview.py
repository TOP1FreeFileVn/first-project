from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
font = ImageFont.truetype(str(ROOT / 'game/ui/fonts/DejaVuSans.ttf'), 21)
small = ImageFont.truetype(str(ROOT / 'game/ui/fonts/DejaVuSans.ttf'), 17)
board = Image.new('RGB', (960, 364), '#fff7e9')
draw = ImageDraw.Draw(board)
for x, name, title, detail in [
    (12, 'rim', 'A · Gờ vàng mỏng', 'Tạo chiều sâu nhẹ'),
    (332, 'paw', 'B · Dấu chân mèo', 'Thêm nét riêng của game'),
    (652, 'plaque', 'C · Dải tên nổi', 'Vát hai đầu như bảng tên'),
]:
    draw.text((x + 3, 12), title, font=font, fill='#583f21')
    draw.text((x + 3, 43), detail, font=small, fill='#583f21')
    tile = Image.open(HERE / ('shop-' + name + '.png')).convert('RGB').crop((3, 1122, 182, 1280))
    board.paste(tile.resize((304, 269), Image.Resampling.LANCZOS), (x, 82))
board.save(HERE / 'comparison.png')

# Matching 1x bottom-nav strips for checking the small detail in the whole bar.
detail_board = Image.new('RGB', (752, 666), '#fff7e9')
draw = ImageDraw.Draw(detail_board)
for y, name, title in [(8, 'rim', 'A · Gờ vàng mỏng'), (230, 'paw', 'B · Dấu chân mèo'), (452, 'plaque', 'C · Dải tên nổi')]:
    draw.text((16, y), title, font=font, fill='#583f21')
    detail_board.paste(Image.open(HERE / ('shop-' + name + '.png')).convert('RGB').crop((0, 1100, 720, 1280)), (16, y + 32))
detail_board.save(HERE / 'whole-bar-comparison.png')
