"""Arrange original Figma screenshots for stroke study; creates no new artwork."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
FONTS = Path('C:/Windows/Fonts')


def font(size, bold=False):
    return ImageFont.truetype(str(FONTS / ('segoeuib.ttf' if bold else 'segoeui.ttf')), size)


ITEMS = [
    ('armor', 'Giáp da · 3447:7563', ['Nét nâu đỏ trên da;', 'phần vai kim loại dùng xám.']),
    ('armor-steel', 'Giáp thép · 3447:7569', ['Nét mặt thép nhẹ hơn viền hình;', 'mảng xám rộng không phải stroke.']),
    ('armor-gold', 'Giáp vàng · 3447:7575', ['Nét nâu vàng đi theo vật liệu;', 'không dùng chung xám với thép.']),
    ('boots', 'Giày da · 3447:7581', ['Tiếp giáp mạnh hơn nét may;', 'giữ các mảng màu đủ rộng.']),
    ('boots-steel', 'Giày thép · 3447:7587', ['Một món có cả nét xám và nâu;', 'nét theo phần thép và dây da.']),
    ('crown', 'Vương miện · 3447:7600', ['Mép lỗ vẫn là viền hình đậm;', 'mặt sau xám là một diện màu.']),
    ('necklace', 'Dây chuyền · 3447:7618', ['Mép trong vòng chạm nền', 'vẫn giữ nét silhouette đậm.']),
    ('sword', 'Kiếm trên nhân vật · 3447:14466', ['Dải xám trên lưỡi là mặt bên;', 'tay che nét tại chỗ cầm.']),
    ('staff', 'Pháp sư · 3447:14816', ['Mảng xám tóc/áo là diện màu;', 'không tăng chúng thành nét.']),
]

canvas = Image.new('RGB', (1080, 1370), '#162e3c')
draw = ImageDraw.Draw(canvas)
draw.text((24, 16), 'HỌC LẠI STROKE TỪ FIGMA', font=font(27, True), fill='#f2e8d1')
draw.text((24, 54), 'Ảnh tham khảo phóng 2× · Không phải thiết kế mới · Không suy ra số px nét nguồn',
          font=font(18), fill='#b6c9d1')
for idx, (name, title, lines) in enumerate(ITEMS):
    x = (idx % 3) * 360
    y = 94 + (idx // 3) * 418
    draw.rounded_rectangle((x + 8, y, x + 352, y + 404), 12, fill='#294554')
    src = Image.open(ROOT / (name + '-figma.png')).convert('RGB')
    zoom = src.resize((src.width * 2, src.height * 2), Image.Resampling.NEAREST)
    canvas.paste(zoom, (x + (360 - zoom.width) // 2, y + 8 + (320 - zoom.height) // 2))
    draw.text((x + 20, y + 330), title, font=font(16, True), fill='#f2e8d1')
    for j, line in enumerate(lines):
        draw.text((x + 20, y + 354 + j * 21), line, font=font(16), fill='#c8d9df')
canvas.save(ROOT / 'stroke-reference-comparison.png')
print('Saved reference comparison: 1080 x 1370, original screenshots at 2x nearest-neighbor')
