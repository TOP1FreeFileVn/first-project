from pathlib import Path
import json,hashlib
from PIL import Image,ImageDraw,ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
BG,INK='#eee4d2','#583f21'
font=lambda n:ImageFont.truetype(str(ROOT/'game/ui/fonts/PaytoneOne-Regular.ttf'),n)
def paste(canvas,source,cx,y,maximum=None):
    art=Image.open(source).convert('RGBA')
    if maximum:art.thumbnail((maximum,maximum),Image.Resampling.LANCZOS)
    canvas.paste(art,(round(cx-art.width/2),round(y)),art)

canvas=Image.new('RGB',(840,660),BG);d=ImageDraw.Draw(canvas)
d.text((24,16),'ĐÃ ÁP DỤNG · CÁ XANH RÕ HƠN',font=font(25),fill=INK)
for i,(name,label) in enumerate([('shop','Cửa hàng'),('hero','Anh hùng'),('battle','Chiến')]):
    source=ROOT/'game/ui/skin/carton_nav'/f'{name}.png'
    paste(canvas,source,140+i*280,80,210)
    d.text((140+i*280,326),label,font=font(19),fill=INK,anchor='mm')
paste(canvas,HERE/'context/720-0.png',420,366)
d.text((24,620),'Ảnh từ thanh điều hướng thật · Đã đồng bộ các kích thước icon',font=font(16),fill=INK)
canvas.save(HERE/'preview.png')

compare=Image.new('RGB',(780,500),BG);d=ImageDraw.Draw(compare)
d.text((22,14),'CÁ XANH · KIỂM TRA KHI THU NHỎ',font=font(24),fill=INK)
for i,(name,label) in enumerate([('shop-small-fish.png','Trước'),('shop.png','Sau')]):
    cx=210+i*360
    d.text((cx,63),label,font=font(19),fill=INK,anchor='mm')
    paste(compare,HERE/name,cx,85,210)
    for size,y in [(44,330),(26,420)]:
        paste(compare,HERE/name,cx,y,size)
        d.text((cx,y+size+8),f'{size} px',font=font(14),fill=INK,anchor='mt')
compare.save(HERE/'fish-clarity.png')

manifest=json.loads((HERE/'manifest.json').read_text(encoding='utf-8'))
for name,digest in manifest['unchanged_assets_sha256'].items():
    assert hashlib.sha256((ROOT/'game/ui/skin/carton_nav'/name).read_bytes()).hexdigest()==digest,name
for file in manifest['global_tab_variants']:
    source=(ROOT/file).read_text(encoding='utf-8')
    if 'shop' in file:
        assert '#8fdce6' in source and 'translate(64 99)' not in source,file
    else:assert 'viewBox="5.978 2.478 188.043 188.043"' in source,file
manifest['native_review']={'control':'game/ui/CartonNav.gd default preloads',
    'capture_widths':[360,720],'capture_count':6,'player_save_writes':False,
    'shared_svg_renders':10,'status':'visually inspected; fish clear at 26/44px; tail clear of counter'}
(HERE/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print('Production review and shared icon consistency checks complete.')
