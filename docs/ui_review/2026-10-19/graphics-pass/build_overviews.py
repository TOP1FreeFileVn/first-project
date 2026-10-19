"""Arrange fresh production screenshots; no artwork or game behavior changes."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
INK = '#583f21'
TITLE = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', 26)
LABEL = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', 18)
SMALL = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 15)

def make(name, title, shots):
    rows = (len(shots) + 2) // 3
    image = Image.new('RGB', (1128, 92 + rows * 686), '#e9dfcd')
    draw = ImageDraw.Draw(image)
    draw.text((16, 12), title, font=TITLE, fill=INK)
    draw.text((16, 49), 'Game hiện tại · ảnh 720 × 1280 thu về 360 px · profile tạm, không ghi save', font=SMALL, fill=INK)
    for i, (key, label) in enumerate(shots):
        x = 12 + (i % 3) * 376
        y = 88 + (i // 3) * 686
        draw.text((x, y), label, font=LABEL, fill=INK)
        shot = Image.open(HERE / 'screens' / (key + '.png')).convert('RGB')
        if shot.size != (720,1280):
            raise ValueError((key,shot.size))
        image.paste(shot.resize((360,640),Image.Resampling.LANCZOS),(x,y+30))
    image.save(HERE / (name+'.png'))

make('menu-overview','Đồ họa hiện tại · 6 màn chính',[
    ('01_lobby','Sảnh'),('03_hero','Anh hùng'),('04_troops','Lính'),
    ('02_shop','Cửa hàng'),('05_summon','Triệu hồi'),('13_castle','Thành')])
make('detail-overview','Đồ họa hiện tại · chi tiết & popup',[
    ('06_equipment_detail','Trang bị'),('07_equipment_compare','So sánh trang bị'),('08_troop_detail','Chi tiết lính'),
    ('09_events','Sự kiện'),('09_login','Điểm danh'),('09_quests','Nhiệm vụ')])
make('battle-overview','Đồ họa hiện tại · bản đồ & chiến đấu',[
    ('10_locked_stage','Hầm chưa mở'),('11_battle_shop','Xếp bánh răng'),('12_battle_fight','Trong trận')])
print('Built 3 overviews from 15 fresh screenshots')
