"""Weapon-only hero appearance, fixed-hand occlusion and stat-only gear icons."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps

HERE=Path(__file__).resolve().parent
V3=HERE.parent/'hero-equipment-v3'
PROJECT=HERE.parents[3]
SOURCES=PROJECT/'docs/design/2026-10-19/hero-equipment/sources'
OUT=HERE/'processed';OUT.mkdir(exist_ok=True)
S=3;SIZE=(768,720);INK='#583f21'
FONT=Path('C:/Windows/Fonts')
NAMES=dict(melee='Kiếm · Tay phải',ranged='Cung · Tay trái',magic='Trượng · Tay phải',heavy='Rìu · Tay phải')
GEAR=dict(helmet='Mũ',armor='Giáp',gloves='Găng',boots='Giày',amulet='Bùa')
def opened(p):return Image.open(p).convert('RGBA')
def font(n,bold=False):return ImageFont.truetype(str(FONT/('segoeuib.ttf' if bold else 'segoeui.ttf')),n)
def canvas():return Image.new('RGBA',SIZE)
def brighten(im):
    a=np.array(im);rgb=a[:,:,:3].astype(float)
    preserve=np.linalg.norm(rgb-np.array([88,63,33]),axis=2)<30
    a[:,:,:3]=np.where(preserve[:,:,None],a[:,:,:3],np.clip(np.round(rgb*1.10),0,255).astype(np.uint8))
    return Image.fromarray(a,'RGBA')
def paste(dst,im,box):
    if isinstance(im,Path):im=opened(im)
    x,y,w,h=box;r=min(w/im.width,h/im.height)
    thumb=im.resize((round(im.width*r),round(im.height*r)),Image.Resampling.LANCZOS)
    dst.alpha_composite(thumb,(round(x+(w-thumb.width)/2),round(y+(h-thumb.height)/2)))

base=opened(SOURCES/'hero-base.png');paws=opened(SOURCES/'hero-paws.png')
weapons=dict(melee=opened(V3/'processed/melee-weapon-layer.png'),
             ranged=opened(HERE/'bow/bow-left-weapon-layer.png'),
             magic=brighten(opened(HERE/'staff/staff-right-layer-original-tone.png')),
             heavy=opened(V3/'processed/heavy-weapon-layer.png'))
weapons['magic'].save(HERE/'staff/staff-right-weapon-layer.png')

# A rounded patch of the cat's original ginger fur fills the native paw bowl.
# The unchanged C contour stays in front. There is no cuff or equipment glove.
right_mask=Image.new('L',SIZE);md=ImageDraw.Draw(right_mask)
poly=[151,156,168,176]
md.ellipse([round(v*S) for v in poly],fill=255)
left_mask=Image.new('L',SIZE)
left_mask.paste(ImageOps.mirror(right_mask),(-2*S,0))
right_mask.save(OUT/'right-palm-mask.png');left_mask.save(OUT/'left-palm-mask.png')
heroes={};meta={}
for pose,w in weapons.items():
    assert w.size==SIZE,(pose,w.size)
    hand='left' if pose=='ranged' else 'right'
    mask=left_mask if hand=='left' else right_mask
    cat=base.copy();cat.alpha_composite(w)
    fur=Image.new('RGBA',SIZE,base.getpixel((185*S,180*S)))
    cat=Image.composite(fur,cat,mask)
    cat.alpha_composite(paws)
    cat.save(OUT/f'hero-{pose}.png')
    cat.resize((128,120),Image.Resampling.LANCZOS).save(OUT/f'hero-{pose}-128.png')
    heroes[pose]=cat;w.save(OUT/f'{pose}-weapon-layer.png')
    bounds=w.getbbox()
    assert 0<bounds[0]<bounds[2]<SIZE[0] and 0<bounds[1]<bounds[3]<SIZE[1],(pose,bounds)
    meta[pose]=dict(hand=hand,target_grip=[94,166] if hand=='left' else [160,166],
                    alpha_bounds=[v/S for v in bounds],clipped=False)

for name in GEAR:
    for size in [48,64,96]:
        opened(V3/f'processed/{name}-icon-{size}.png').save(OUT/f'{name}-icon-{size}.png')
    opened(V3/f'processed/{name}.png').save(OUT/f'{name}.png')

board=Image.new('RGBA',(1600,1260),'#d7e4dd');d=ImageDraw.Draw(board)
d.text((32,20),'MÈO ANH HÙNG · VŨ KHÍ QUYẾT ĐỊNH NGOẠI HÌNH',font=font(30,True),fill=INK)
d.text((32,69),'Cung cầm tay trái · Trượng nắm giữa chuôi · Giữ mèo và áo choàng gốc',font=font(22),fill='#54685f')
d.text((32,107),'Màu sáng hơn 10% · Không mặc mũ, giáp, găng, giày hay bùa lên mèo.',font=font(20),fill='#54685f')
for i,(pose,cat) in enumerate(heroes.items()):
    x=20+i*395;y=158
    d.rounded_rectangle((x,y,x+380,y+621),20,fill='#eaf0e8')
    d.text((x+17,y+14),NAMES[pose],font=font(22,True),fill=INK)
    paste(board,cat,(x+2,y+60,376,352))
    board.alpha_composite(opened(OUT/f'hero-{pose}-128.png'),(x+126,y+453))
    d.text((x+87,y+585),'128 × 120 · kích thước thật',font=font(17),fill='#54685f')
d.rounded_rectangle((20,802,1580,1238),20,fill='#eaf0e8')
d.text((42,818),'5 Ô TRANG BỊ · CHỈ CỘNG CHỈ SỐ',font=font(26,True),fill=INK)
d.text((42,861),'Icon dùng trong túi đồ và màn nâng cấp; không đổi hình mèo khi trang bị.',font=font(21),fill='#54685f')
for i,(name,label) in enumerate(GEAR.items()):
    x=44+i*307
    paste(board,OUT/f'{name}.png',(x,917,272,180))
    d.text((x+100,1118),label,font=font(23,True),fill=INK)
d.text((42,1188),'Bản duyệt v4 · Bốn pose cầm, chưa phải hoạt ảnh tấn công.',font=font(18),fill='#54685f')
board.convert('RGB').save(HERE/'hero-equipment-review.png')

native=Image.new('RGBA',(640,184),'#d7e4dd');nd=ImageDraw.Draw(native)
for i,pose in enumerate(heroes):
    native.alpha_composite(opened(OUT/f'hero-{pose}-128.png'),(i*160+16,8))
    nd.text((i*160+16,142),dict(melee='Kiếm',ranged='Cung trái',magic='Trượng',heavy='Rìu')[pose],font=font(18,True),fill=INK)
native.convert('RGB').save(HERE/'native-size-review.png')

focus=Image.new('RGBA',(1280,790),'#d7e4dd');fd=ImageDraw.Draw(focus)
fd.text((28,20),'CUNG TAY TRÁI · TRƯỢNG NẮM ĐÚNG CHUÔI',font=font(30,True),fill=INK)
fd.text((28,66),'Chỉ vũ khí hiện trên mèo; năm món còn lại dùng icon và cộng chỉ số.',font=font(21),fill='#54685f')
for i,pose in enumerate(['ranged','magic']):
    x=20+i*630;y=112
    fd.rounded_rectangle((x,y,x+610,y+655),20,fill='#eaf0e8')
    fd.text((x+20,y+14),NAMES[pose],font=font(25,True),fill=INK)
    paste(focus,heroes[pose],(x+18,y+62,440,413))
    focus.alpha_composite(opened(OUT/f'hero-{pose}-128.png'),(x+461,y+206))
    fd.text((x+466,y+341),'128 × 120',font=font(17),fill='#54685f')
    fd.text((x+20,y+516),'Mèo gốc · Áo choàng xanh · Màu vũ khí +10%',font=font(20),fill='#54685f')
    fd.text((x+20,y+563),'Chuôi được bàn tay che ở đúng điểm nắm.',font=font(20),fill='#54685f')
focus.convert('RGB').save(HERE/'pose-fix-review.png')

report=dict(version=4,display_rule='Only held weapon is visible. Helmet, armor, gloves, boots, amulet are stat-only item icons.',
    canvas=[256,240],render_scale=3,poses=meta,base='../../2026-10-19/hero-equipment/sources/hero-base.png',
    pawn_layer='../../2026-10-19/hero-equipment/sources/hero-paws.png',
    palm_occlusion='Rounded local ginger-fur fill sampled from original coat inside the native paw bowl, then unchanged C contour. No cuff or added glove outline.',
    right_palm_ellipse=poly,left_palm_transform='x_new=254-x; bow and mask only, not cat/cape',
    staff=dict(source='staff/staff-right.svg',source_grip=[0,8],target_grip=[160,166],clockwise_angle=44,crystal_source_center=[0,-96],
               connector_axis='Crystal, brass socket and shaft all local x=0; same44degree rotation without independent crown rotation.',
               rationale='Grip is the actual centre of the leather wrap. The crystal and socket are coaxial with the shaft.'),
    bow=dict(source='bow/bow-left.svg',main_native=9,string_native=3,string_role='Visible secondary structural line',string_source_color='#8a6240',string_brightened_color='#986c46'),
    brightness='Sword/axe reuse v3 bright10 once. Authored bow and staff original-tone rasters each receive one1.10 paint pass; brown main ink preserved.',
    runtime='Design review only; gameplay stats already follow weapon/five-stat-item contract in game/core/HeroCat.gd.')
(HERE/'processing.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(meta))
