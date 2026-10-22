from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

here = Path(__file__).resolve().parent
root = here.parents[3]
font_path = root / 'game/ui/fonts/PaytoneOne-Regular.ttf'
title = ImageFont.truetype(str(font_path), 25)
small = ImageFont.truetype(str(font_path), 14)
ink = '#583f21'
paper = '#f4f4ed'
def pic(name):
    return Image.open(here / 'godot' / name).convert('RGBA')

board = Image.new('RGBA', (1248, 630), '#e4e9e2')
d = ImageDraw.Draw(board)
for i, (slug, label) in enumerate([('bow','CUNG · LÊN TRÁI'),('staff','TRƯỢNG'),('axe','RÌU MỚI'),('katana','KATANA')]):
    x = 16 + i * 308
    d.rounded_rectangle((x,16,x+292,614),radius=18,fill=paper)
    d.text((x+146,36),label,font=title,fill=ink,anchor='mt')
    board.alpha_composite(pic(f'{slug}-icon-256.png'),(x+18,80))
    board.alpha_composite(pic(f'hero-{slug}-128.png'),(x+82,358))
    d.text((x+146,484),'128 × 120',font=small,fill='#796b56',anchor='mt')
    for size,offset in [(32,8),(48,49),(64,106),(96,181)]:
        board.alpha_composite(pic(f'{slug}-icon-{size}.png'),(x+offset,583-size))
board.convert('RGB').save(here / 'review.png')

axe = Image.new('RGBA',(760,590),'#e4e9e2')
ad = ImageDraw.Draw(axe)
for x in (16,388):
    ad.rounded_rectangle((x,16,x+356,574),radius=18,fill=paper)
ad.text((194,38),'RÌU · BẢN VẼ LẠI',font=title,fill=ink,anchor='mt')
ad.text((566,38),'CẦM TRÊN MÈO',font=title,fill=ink,anchor='mt')
axe.alpha_composite(pic('axe-icon-256.png'),(66,112))
axe.alpha_composite(pic('hero-axe-256.png'),(438,100))
for size,offset in [(32,29),(48,80),(64,149),(96,234)]:
    axe.alpha_composite(pic(f'axe-icon-{size}.png'),(16+offset,526-size))
    ad.text((16+offset+size/2,539),f'{size}px',font=small,fill='#796b56',anchor='mt')
axe.alpha_composite(pic('hero-axe-128.png'),(502,414))
ad.text((566,545),'128 × 120',font=small,fill='#796b56',anchor='mt')
axe.convert('RGB').save(here / 'axe-review.png')

oldnew=Image.new('RGBA',(980,230),'#e4e9e2')
od=ImageDraw.Draw(oldnew)
for i,(slug,label,old) in enumerate([('bow','CUNG','cung'),('staff','TRƯỢNG','gay_phep'),('axe','RÌU','riu'),('katana','KATANA','katana')]):
    x=10+i*245
    od.text((x+116,12),label,font=small,fill=ink,anchor='mt')
    oldnew.alpha_composite(Image.open(root/f'game/ui/art/icon_hero_w_{old}_96.png').convert('RGBA'),(x+6,58))
    oldnew.alpha_composite(pic(f'{slug}-icon-96.png'),(x+128,58))
    od.text((x+54,174),'Đang dùng',font=small,fill=ink,anchor='mt')
    od.text((x+176,174),'Bản mới',font=small,fill=ink,anchor='mt')
oldnew.convert('RGB').save(here/'before-after-96.png')
print('Saved native weapon review, axe focus and 96px before/after.')
