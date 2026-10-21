"""Generated hero equipment proposal. Palette/alpha cleanup, no contour rebuilding."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[3]
SOURCES = PROJECT / 'docs/design/2026-10-19/hero-equipment/sources'
OLD = PROJECT / 'docs/design/2026-10-19/hero-equipment/processed'
SPEAR = HERE.parent / 'spear-stroke-sample/processed'
OUT = HERE / 'processed'
OUT.mkdir(exist_ok=True)
S = 3
SIZE = (768, 720)
INK = '#583f21'
GEAR = ['helmet', 'armor', 'gloves', 'boots', 'amulet']
LABELS = dict(helmet='Mũ tai mèo', armor='Giáp ngực', gloves='Găng tay', boots='Giày thép', amulet='Bùa ngọc',
              melee='Cận chiến · Kiếm', ranged='Tầm xa · Cung', magic='Phép · Trượng', heavy='Hạng nặng · Rìu')
FONT_DIR = Path('C:/Windows/Fonts')
def font(n, bold=False):
    return ImageFont.truetype(str(FONT_DIR / ('segoeuib.ttf' if bold else 'segoeui.ttf')), n)
def canvas(): return Image.new('RGBA', SIZE)
def opened(path): return Image.open(path).convert('RGBA')

def clean(name, raw_name, samples, targets):
    a = np.asarray(Image.open(HERE/'raw'/raw_name).convert('RGB')).astype(float)
    src = np.array(samples, float)
    dst = np.array(targets, np.uint8)
    labels = ((a[:,:,None,:]-src[None,None,:,:])**2).sum(3).argmin(2)
    out = np.empty((*a.shape[:2],4),np.uint8)
    out[:,:,:3] = dst[labels]
    out[:,:,3] = 255
    white = a.min(2)>238
    out[white,3] = 0
    edge = (a.min(2)>135)&(a[:,:,0]>a[:,:,2]+8)&(a[:,:,1]>a[:,:,2])&~white
    coverage = np.clip((255-a[:,:,2])/(255-src[0,2]),0,1)
    out[edge,:3] = dst[0]
    out[edge,3] = np.round(coverage[edge]*255).astype(np.uint8)
    im = Image.fromarray(out,'RGBA')
    im.save(OUT/f'{name}-source-clean.png')
    im = im.crop(im.getbbox())
    im.save(OUT/f'{name}.png')
    return im

def fit(im, width, x, y):
    ratio = width*S/im.width
    thumb = im.resize((round(im.width*ratio), round(im.height*ratio)), Image.Resampling.LANCZOS)
    layer = canvas()
    layer.alpha_composite(thumb,(round(x*S),round(y*S)))
    return layer, [x,y,x+thumb.width/S,y+thumb.height/S], ratio/S

def icons(name,im):
    for size in (48,64,96):
        tile=Image.new('RGBA',(size,size))
        thumb=im.copy();thumb.thumbnail((size-6,size-6),Image.Resampling.LANCZOS)
        tile.alpha_composite(thumb,((size-thumb.width)//2,(size-thumb.height)//2))
        tile.save(OUT/f'{name}-icon-{size}.png')

helmet = clean('helmet','helmet-iteration-2.png',
    [[98,72,34],[201,214,220],[163,183,194],[223,174,78],[174,129,37],[243,126,81]],
    [[88,63,33],[214,224,227],[164,182,191],[223,172,88],[175,128,57],[231,120,91]])
armor = clean('armor','armor-iteration-3.png',
    [[94,69,33],[211,222,227],[171,191,201],[223,174,79],[80,129,204],[142,161,172]],
    [[88,63,33],[214,224,227],[164,182,191],[223,172,88],[79,127,208],[139,161,173]])
amulet = clean('amulet','amulet.png',
    [[91,62,26],[222,171,74],[91,181,187]],
    [[88,63,33],[223,172,88],[96,177,177]])
layers={}; fits={}
for name,im,w,x,y in [('helmet',helmet,190,33,8),('armor',armor,120,68,119),('amulet',amulet,16,120,149)]:
    layers[name],bounds,scale=fit(im,w,x,y)
    fits[name]=dict(bounds=bounds,scale=scale,aspect_preserved=True)
    layers[name].save(OUT/f'{name}-worn-layer.png')

for name,base in [('gloves','gauntlet'),('boots','boot')]:
    layers[name]=opened(HERE/f'gear-details/processed/{base}-pair-layer-3x.png')
    layers[name].save(OUT/f'{name}-worn-layer.png')
    single=opened(HERE/f'gear-details/processed/{base}.png')
    single=single.crop(single.getbbox());single.save(OUT/f'{name}.png')

# The necklace connector is a quiet ochre surface line, subordinate to the cat.
necklace=canvas();nd=ImageDraw.Draw(necklace)
nd.line([(111*S,142*S),(118*S,151*S),(128*S,154*S),(138*S,151*S),(145*S,142*S)],fill='#b87b42',width=2*S,joint='curve')
necklace.alpha_composite(layers['amulet'])
layers['amulet']=necklace
necklace.save(OUT/'amulet-worn-layer.png')

weapons={}
for pose,name in [('melee','sword')]:
    weapons[pose]=opened(HERE/f'weapons/clean/{name}-held-layer.png')
    opened(HERE/f'weapons/clean/{name}.png').save(OUT/f'{name}.png')
weapons['ranged']=opened(HERE/'weapons/authored/bow-refined-layer.png')
weapons['magic']=opened(OUT/'staff-refined-layer.png')
weapons['heavy']=opened(HERE/'weapons-heavy/processed/heavy-axe-held-layer-3x.png')
for name,im in [('bow',weapons['ranged']),('staff',weapons['magic']),('axe',opened(HERE/'weapons-heavy/processed/heavy-axe.png'))]:
    im.crop(im.getbbox()).save(OUT/f'{name}.png')

def brighten(im):
    a=np.array(im)
    rgb=a[:,:,:3].astype(float)
    # Increase painted sRGB values by ten percent; preserve warm contour ink.
    ink=np.array([88,63,33],float)
    preserve=np.linalg.norm(rgb-ink,axis=2)<30
    raised=np.clip(np.round(rgb*1.10),0,255).astype(np.uint8)
    a[:,:,:3]=np.where(preserve[:,:,None],a[:,:,:3],raised)
    return Image.fromarray(a,'RGBA')

def compose(pose,ls,ws):
    cat=opened(SOURCES/'hero-body.png')
    for name in ['armor','boots','amulet']:cat.alpha_composite(ls[name])
    cat.alpha_composite(opened(SOURCES/'hero-head-noears.png'))
    cat.alpha_composite(ls['helmet'])
    cat.alpha_composite(ws[pose])
    cat.alpha_composite(ls['gloves'])
    return cat

original_heroes={p:compose(p,layers,weapons) for p in weapons}
for name in layers: layers[name]=brighten(layers[name]);layers[name].save(OUT/f'{name}-worn-layer.png')
for pose in weapons: weapons[pose]=brighten(weapons[pose])
for name in GEAR+['sword','bow','staff','axe']:
    original=opened(OUT/f'{name}.png');original.save(OUT/f'{name}-tone-original.png')
    brighten(original).save(OUT/f'{name}.png')

heroes={}
for pose,weapon in weapons.items():
    cat=compose(pose,layers,weapons)
    cat.save(OUT/f'hero-{pose}.png')
    cat.resize((128,120),Image.Resampling.LANCZOS).save(OUT/f'hero-{pose}-128.png')
    heroes[pose]=cat
    weapon.save(OUT/f'{pose}-weapon-layer.png')

fixed=canvas()
for name in ['armor','boots','amulet','helmet','gloves']: fixed.alpha_composite(layers[name])
fixed.save(OUT/'fixed-five-gear-layer.png')
for name in GEAR+['sword','bow','staff','axe']: icons(name,opened(OUT/f'{name}.png'))

def paste(dst,im,box):
    if isinstance(im,Path): im=opened(im)
    x,y,w,h=box
    ratio=min(w/im.width,h/im.height)
    thumb=im.resize((round(im.width*ratio),round(im.height*ratio)),Image.Resampling.LANCZOS)
    dst.alpha_composite(thumb,(round(x+(w-thumb.width)/2),round(y+(h-thumb.height)/2)))

board=Image.new('RGBA',(1600,1480),'#d7e4dd');d=ImageDraw.Draw(board)
d.text((36,23),'MÈO ANH HÙNG · TRỌN BỘ TRANG BỊ',font=font(34,True),fill=INK)
d.text((36,73),'Màu trang bị sáng hơn 10% · 4 cách cầm vũ khí · 5 lớp đồ cố định',font=font(22),fill='#54685f')
d.text((36,111),'Bản thiết kế v3 — giữ nguyên khuôn mặt, thân mèo và áo choàng.',font=font(18),fill='#54685f')
for i,name in enumerate(GEAR):
    x=24+i*316;y=160
    d.rounded_rectangle((x,y,x+304,y+246),20,fill='#eaf0e8')
    d.text((x+17,y+13),LABELS[name],font=font(23,True),fill=INK)
    paste(board,OUT/f'{name}.png',(x+25,y+58,254,145))
    d.text((x+17,y+211),'Lớp đeo cố định cho cả 4 pose',font=font(17),fill='#54685f')

for i,(pose,cat) in enumerate(heroes.items()):
    x=24+i*394;y=426
    d.rounded_rectangle((x,y,x+382,y+599),20,fill='#eaf0e8')
    d.text((x+17,y+13),LABELS[pose],font=font(23,True),fill=INK)
    paste(board,cat,(x+4,y+65,374,351))
    d.text((x+18,y+431),'128 × 120 · kích thước thật',font=font(17),fill='#54685f')
    native=opened(OUT/f'hero-{pose}-128.png')
    board.alpha_composite(native,(x+39,y+468))
    iconname=dict(melee='sword',ranged='bow',magic='staff',heavy='axe')[pose]
    board.alpha_composite(opened(OUT/f'{iconname}-icon-64.png'),(x+243,y+493))
    d.text((x+224,y+566),'Icon 64 px',font=font(17),fill='#54685f')

d.rounded_rectangle((24,1046,1576,1456),20,fill='#eaf0e8')
d.text((44,1060),'SO SÁNH CÙNG TỈ LỆ',font=font(24,True),fill=INK)
oldpath=OLD/'hero_melee.png'
if oldpath.exists():
    paste(board,oldpath,(40,1111,340,312));d.text((135,1420),'Bộ cũ',font=font(19,True),fill=INK)
paste(board,heroes['melee'],(390,1111,340,312));d.text((489,1420),'Bộ mới v3',font=font(19,True),fill=INK)
d.text((784,1130),'Nét theo vật liệu',font=font(24,True),fill=INK)
for j,line in enumerate(['Viền nâu ấm; đường nối nhẹ hơn theo vật liệu.',
                         'Mảng thép và màu trang trí không bị bao nét dày.',
                         'Dây cung mảnh; các đôi găng, giày đối xứng.',
                         'Thương 9/10 là mẫu nét; rìu có pose riêng.',
                         'Bốn pose dùng chung vị trí mũ, giáp, găng, giày, bùa.']):
    d.text((784,1175+j*39),line,font=font(20),fill='#54685f')
d.text((784,1391),'Bản duyệt artwork · chưa thay trang bị trong game.',font=font(19,True),fill=INK)
board.convert('RGB').save(HERE/'hero-equipment-review.png')

nativeboard=Image.new('RGBA',(640,184),'#d7e4dd');nd=ImageDraw.Draw(nativeboard)
for i,pose in enumerate(heroes):
    nativeboard.alpha_composite(opened(OUT/f'hero-{pose}-128.png'),(i*160+16,8))
    nd.text((i*160+16,140),{'melee':'Kiếm','ranged':'Cung','magic':'Trượng','heavy':'Rìu'}[pose],font=font(18,True),fill=INK)
nativeboard.convert('RGB').save(HERE/'native-size-review.png')

tone=Image.new('RGBA',(1440,960),'#d7e4dd');td=ImageDraw.Draw(tone)
td.text((32,20),'THỬ MÀU TRANG BỊ · +10% ĐỘ SÁNG',font=font(30,True),fill=INK)
td.text((32,68),'Giữ viền nâu và màu mèo gốc; tăng sáng mảng màu trang bị.',font=font(20),fill='#54685f')
for row,pose in enumerate(['ranged','magic']):
    y=118+row*414
    for col,(label,cat) in enumerate([('Tông trước',original_heroes[pose]),('Sáng hơn 10%',heroes[pose])]):
        x=24+col*708
        td.rounded_rectangle((x,y,x+688,y+396),18,fill='#eaf0e8')
        td.text((x+18,y+12),label+' · '+('Cung' if pose=='ranged' else 'Trượng'),font=font(24,True),fill=INK)
        paste(tone,cat,(x+20,y+53,348,326))
        tone.alpha_composite(cat.resize((128,120),Image.Resampling.LANCZOS),(x+492,y+140))
        td.text((x+478,y+281),'128 × 120',font=font(18),fill='#54685f')
tone.convert('RGB').save(HERE/'tone-plus-10-review.png')

bowboard=Image.new('RGBA',(1120,700),'#d7e4dd');bd=ImageDraw.Draw(bowboard)
bd.text((28,20),'CUNG · CHỈNH LẠI TRỤC CHUÔI',font=font(32,True),fill=INK)
bd.text((28,69),'Chuôi liền thân · Hai điểm nối cân · Màu trang bị sáng hơn 10%',font=font(21),fill='#54685f')
bd.rounded_rectangle((20,112,398,678),20,fill='#eaf0e8')
bd.rounded_rectangle((416,112,1100,678),20,fill='#eaf0e8')
bd.text((40,128),'Dáng cung sau khi sửa',font=font(23,True),fill=INK)
paste(bowboard,OUT/'bow.png',(52,182,313,443))
bd.text((438,128),'Cầm trên mèo',font=font(23,True),fill=INK)
paste(bowboard,heroes['ranged'],(428,176,440,412))
bowboard.alpha_composite(heroes['ranged'].resize((128,120),Image.Resampling.LANCZOS),(924,325))
bd.text((916,465),'128 × 120',font=font(18),fill='#54685f')
bd.text((438,625),'Dây mảnh; chuôi nằm đúng tâm bàn tay cố định.',font=font(21),fill='#54685f')
bowboard.convert('RGB').save(HERE/'bow-grip-fix-review.png')

report=dict(canvas=[256,240],render_scale=3,gear_fits=fits,fixed_paws=[[94,166],[160,166]],
    cleanup='Palette flattening, white matte removal and aspect-preserving placement only; no dilation or contour rebuilding.',
    line_note='9px main target. Sword generated8.91. Bow/staff/axe manually authored9px; bowstring1.4px. Small gear contour varies~6-7px.',
    color_adjustment='Painted sRGB values multiplied1.10 with255clamp; contour pixels within30 RGBdistance of#583f21 preserved. Cat/base unchanged.',
    accepted_spear_reference='../spear-stroke-sample/processing.json',weapons='weapons/processing.json',bow_refinement='weapons/authored/authored-processing.json',heavy_refinement='weapons-heavy/processing.json',paired_gear='gear-details/processing.json',
    scope='Design review set, not production integration or combat animation.',layers=['body','armor','boots','amulet','head-noears','helmet','weapon','gloves'])
(HERE/'processing.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'board':str(HERE/'hero-equipment-review.png'),'gear_fits':fits}))
