"""Arrange actual native captures without altering their UI."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
FONT = ROOT / 'game/ui/fonts/PaytoneOne-Regular.ttf'
BODY = ROOT / 'game/ui/fonts/DejaVuSans.ttf'
canvas = Image.new('RGB', (1176, 785), '#f5eedf')
d = ImageDraw.Draw(canvas)
d.text((24,16),'SHOP · THỬ MÀU & GRADIENT',font=ImageFont.truetype(str(FONT),28),fill='#3b2b1e')
d.text((24,62),'Ảnh chạy thật trong Godot · Cùng bố cục, giá và phần thưởng · Bản thử để duyệt',font=ImageFont.truetype(str(BODY),17),fill='#583f21')
for i,(name,label) in enumerate([('flat','A · Giấy phẳng'),('honey','B · Mật ong – kem'),('teal','C · Xanh ngọc – kem')]):
    x=24+i*384
    d.text((x,102),label,font=ImageFont.truetype(str(FONT),23),fill='#3b2b1e')
    shot=Image.open(HERE/'captures'/f'{name}-360x640.png').convert('RGB')
    canvas.paste(shot,(x,143))
canvas.save(HERE/'comparison.png')
print('Wrote native comparison.png')
