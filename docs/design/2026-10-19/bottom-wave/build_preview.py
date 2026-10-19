from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
FONT = ROOT / 'game/ui/fonts/DejaVuSans.ttf'
TITLE = ImageFont.truetype(str(FONT), 21)
BODY = ImageFont.truetype(str(FONT), 17)
INK = '#583f21'

# Native game screenshots, reduced to mobile viewing size side by side.
board = Image.new('RGB', (768, 738), '#fff7e9')
d = ImageDraw.Draw(board)
for x, file_name, title, subtitle in [
    (16, '01-footer-wave.png', 'A · Lượn nhẹ ở dải tên', 'Giữ 5 ô như hiện tại'),
    (392, '02-dock-wave.png', 'B · Thanh sóng liền', 'Nhô mềm ở tab đang chọn'),
]:
    d.text((x + 4, 14), title, font=TITLE, fill=INK)
    d.text((x + 4, 44), subtitle, font=BODY, fill=INK)
    screen = Image.open(HERE / file_name).convert('RGB')
    board.paste(screen.resize((360, 640), Image.Resampling.LANCZOS), (x, 78))
board.save(HERE / 'comparison.png')

# Larger navigation detail so the subtle curve in A can be reviewed.
detail = Image.new('RGB', (752, 452), '#fff7e9')
d = ImageDraw.Draw(detail)
for y, file_name, title in [
    (10, '01-footer-wave.png', 'A · Chỉ uốn đường chia dải tên tab'),
    (234, '02-dock-wave.png', 'B · Mép trên của cả thanh dưới uốn liền'),
]:
    d.text((16, y), title, font=TITLE, fill=INK)
    detail.paste(Image.open(HERE / file_name).convert('RGB').crop((0, 1100, 720, 1280)), (16, y + 32))
detail.save(HERE / 'bottom-detail.png')
