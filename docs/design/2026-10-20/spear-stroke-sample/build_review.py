"""Clean the generated spear palette and composite on the unchanged cat.

No dilation, contour rebuilding, skeletonization or region-edge generation.
"""
from pathlib import Path
import json
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[3]
SOURCES = PROJECT / 'docs/design/2026-10-19/hero-equipment/sources'
OUT = ROOT / 'processed'
OUT.mkdir(exist_ok=True)
S = 3
raw = np.asarray(Image.open(ROOT / 'raw/spear-iteration-3.png').convert('RGB')).astype(float)
# Source color samples describe existing painted regions; boundaries are retained.
src = np.array([[97,68,31],[208,213,217],[169,175,180],[225,176,67],
                [215,125,41],[247,119,83],[120,51,17]], dtype=float)
dst = np.array([[88,63,33],[214,224,227],[164,182,191],[223,172,88],
                [184,123,66],[231,120,91],[152,78,57]], dtype=np.uint8)
labels = ((raw[:,:,None,:] - src[None,None,:,:])**2).sum(3).argmin(2)
# Distinguish the three dark red wrap seams from warm-brown silhouette ink.
yy,xx = np.indices(raw.shape[:2])
seams = (yy>690)&(yy<910)&(xx>472)&(xx<552)&(raw[:,:,0]<200)&(raw[:,:,1]<95)&(raw[:,:,0]>raw[:,:,1]*1.65)
labels[seams]=6
rgba = np.zeros((*raw.shape[:2],4),dtype=np.uint8)
rgba[:,:,:3] = dst[labels]
rgba[:,:,3] = 255
white = raw.min(2)>238
rgba[white,3] = 0
# Keep coverage of warm contour pixels blended into the white matte.
edge = (raw.min(2)>135)&(raw[:,:,0]>raw[:,:,2]+2)&(raw[:,:,1]>raw[:,:,2])&~white
alpha = np.clip((255-raw[:,:,2])/(255-src[0,2]),0,1)
rgba[edge,:3] = dst[0]
rgba[edge,3] = np.round(alpha[edge]*255).astype(np.uint8)
weapon = Image.fromarray(rgba,'RGBA')
bbox = weapon.getbbox()
weapon.save(OUT/'spear-source-clean.png')
isolated=weapon.crop(bbox)
padded=Image.new('RGBA',(isolated.width+32,isolated.height+32))
padded.alpha_composite(isolated,(16,16))
padded.save(OUT/'spear.png')

scale, angle = .24, -24
grip = (512,720)
ratio = scale*S
scaled = weapon.resize((round(weapon.width*ratio),round(weapon.height*ratio)),Image.Resampling.LANCZOS)
rot = scaled.rotate(angle,Image.Resampling.BICUBIC,expand=True)
gx,gy=grip[0]*ratio,grip[1]*ratio
dx,dy=gx-scaled.width/2,gy-scaled.height/2
t=math.radians(angle)
rx=math.cos(t)*dx+math.sin(t)*dy+rot.width/2
ry=-math.sin(t)*dx+math.cos(t)*dy+rot.height/2
x,y=round(160*S-rx),round(166*S-ry)
layer=Image.new('RGBA',(256*S,240*S))
layer.alpha_composite(rot,(x,y))
layer.save(OUT/'spear-held-layer.png')
cat=Image.open(SOURCES/'hero-base.png').convert('RGBA')
cat.alpha_composite(layer)
cat.alpha_composite(Image.open(SOURCES/'hero-paws.png').convert('RGBA'))
cat.save(OUT/'hero-spear.png')
cat.resize((128,120),Image.Resampling.LANCZOS).save(OUT/'hero-spear-128.png')
for size in [48,64]:
    icon=Image.new('RGBA',(size,size))
    thumb=weapon.crop(bbox)
    thumb.thumbnail((size-4,size-4),Image.Resampling.LANCZOS)
    icon.alpha_composite(thumb,((size-thumb.width)//2,(size-thumb.height)//2))
    icon.save(OUT/f'spear-icon-{size}.png')
local=rot.getbbox()
bounds=[(x+local[0])/S,(y+local[1])/S,(x+local[2])/S,(y+local[3])/S]
meta=dict(source='raw/spear-iteration-3.png', palette_source_rgb=src.tolist(),
          palette_target_rgb=dst.tolist(), cleanup='Palette flattening and white-matte extraction only; no morphological line edits.',
          canvas=[256,240],render_scale=S,scale=scale,angle=angle,source_grip=grip,target_grip=[160,166],
          held_bounds=bounds,clipped=not(0<=bounds[0]<bounds[2]<=256 and 0<=bounds[1]<bounds[3]<=240),
          source_straight_shaft_main_width_px=34, fitted_shaft_main_width_estimate=34*scale,
          main_width_note='9 px design target; generated contour varies locally. Straight shaft is about 8.2 unit px, not certified as exactly 9 everywhere.')
assert not meta['clipped'],bounds
(ROOT/'processing.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')

FONTS=Path('C:/Windows/Fonts')
def font(n,bold=False):return ImageFont.truetype(str(FONTS/('segoeuib.ttf' if bold else 'segoeui.ttf')),n)
board=Image.new('RGB',(1024,760),'#d7e4dd')
d=ImageDraw.Draw(board)
d.text((28,18),'THƯƠNG · BẢN THỬ NÉT',font=font(28,True),fill='#583f21')
d.text((28,57),'Đầu thép · khớp đồng · cán gỗ · tay quấn da',font=font(18),fill='#54685f')
for box in [(24,98,355,734),(375,98,1000,530),(375,550,1000,734)]:
    d.rounded_rectangle(box,18,fill='#eaf0e8')
d.text((45,113),'Vũ khí riêng',font=font(20,True),fill='#583f21')
large=weapon.crop(bbox)
large.thumbnail((285,505),Image.Resampling.LANCZOS)
board.paste(large,(189-large.width//2,157),large)
d.text((45,681),'Nét quấn da: nâu đỏ, nhẹ hơn.',font=font(16),fill='#586b62')
d.text((45,704),'Mặt thép tách bằng mảng màu.',font=font(16),fill='#586b62')
d.text((398,113),'Cầm trên mèo',font=font(20,True),fill='#583f21')
big=cat.resize((410,384),Image.Resampling.LANCZOS)
board.paste(big,(485,137),big)
d.text((398,563),'Kích thước trong game',font=font(19,True),fill='#583f21')
native=cat.resize((128,120),Image.Resampling.LANCZOS)
board.paste(native,(449,597),native)
d.text((610,597),'128 × 120',font=font(16),fill='#586b62')
icon=Image.open(OUT/'spear-icon-64.png')
board.paste(icon,(784,630),icon)
d.text((850,647),'Icon 64 px',font=font(16),fill='#586b62')
board.save(ROOT/'review.png')
print(json.dumps({'held_bounds':bounds,'clipped':meta['clipped'],'board':[1024,760]}))
