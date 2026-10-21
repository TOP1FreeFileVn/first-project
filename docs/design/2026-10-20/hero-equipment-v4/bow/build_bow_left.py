"""Build the left bow with a visible secondary string, brightened once."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageOps
ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parents[4]
V3=PROJECT/'docs/design/2026-10-20/hero-equipment-v3'
SOURCES=PROJECT/'docs/design/2026-10-19/hero-equipment/sources'
ROOT.mkdir(exist_ok=True)
source_path=ROOT/'bow-left-layer-original-tone.png'
# Godot has already mirrored the authored vector into the left socket.
# Apply the requested +10% color treatment once, preserving the main brown ink.
orig=np.array(Image.open(source_path).convert('RGBA'))
rgb=orig[:,:,:3].astype(float)
ink=np.linalg.norm(rgb-np.array([88,63,33]),axis=2)<30
expected=orig.copy()
expected[:,:,:3]=np.where(ink[:,:,None],orig[:,:,:3],np.clip(np.round(rgb*1.10),0,255).astype(np.uint8))
layer=Image.fromarray(expected,'RGBA')
layer.save(ROOT/'bow-left-weapon-layer.png')
bbox=layer.getbbox()
layer.crop(bbox).save(ROOT/'bow-left-isolated.png')
paws=Image.open(SOURCES/'hero-paws.png').convert('RGBA')
left_paw=Image.new('RGBA',paws.size)
left_paw.alpha_composite(paws.crop((0,0,128*3,240*3)),(0,0))
left_paw.save(ROOT/'bow-left-original-paw-occlusion.png')
paws.save(ROOT/'original-paws-occlusion.png')
cat=Image.open(SOURCES/'hero-base.png').convert('RGBA')
fur_color=cat.getpixel((185*3,180*3))
cat.alpha_composite(layer)
right_mask=Image.new('L',cat.size)
ImageDraw.Draw(right_mask).ellipse([v*3 for v in [151,156,168,176]],fill=255)
left_mask=Image.new('L',cat.size)
left_mask.paste(ImageOps.mirror(right_mask),(-6,0))
cat=Image.composite(Image.new('RGBA',cat.size,fur_color),cat,left_mask)
cat.alpha_composite(paws)
cat.save(ROOT/'hero-bow-left.png')
cat.resize((128,120),Image.Resampling.LANCZOS).save(ROOT/'hero-bow-left-128.png')
# Pixel geometry check on the unchanged nativey166 leather center.
a=np.array(layer)
row=a[166*3]
coral=expected[166*3,94*3,:3]
xs=np.where((np.linalg.norm(row[:,:3]-coral,axis=1)<1)&(row[:,3]>254))[0]
xs=xs[(xs>80*3)&(xs<108*3)]
center=float((xs.min()+xs.max()+1)/6)
report={
 'scope':'Bow moved to left hand only. Bare hero/cape/head and original paw strokes; no wearable gear layers.',
 'source':'bow-left.svg',
 'source_sha256':hashlib.sha256((ROOT/'bow-left.svg').read_bytes()).hexdigest(),
 'raster_source_sha256':hashlib.sha256(source_path.read_bytes()).hexdigest(),
 'color_adjustment':'Godot SVG original-tone raster receives one1.10 paint pass; main brown ink preserved.',
 'transformation':'Authored SVG wraps only weapon with translate(254 0) scale(-1 1); x_new=254-x_old. Cat and paws are not mirrored.',
 'canvas':[256,240],'raster':[768,720],'source_grip':[160,166],'target_grip':[94,166],
 'raster_leather_center_x_at_y166':center,
 'main_native':9,'string_native':3,'surface_native':1.8,
 'string_role':'Visible secondary structural line, distinct from main9. No fill substitute.',
 'string_source_color':'#8a6240','string_brightened_color':'#986c46',
 'string_axis_native':32,'string_span_native':[97,231],
 'bounds_native':[round(v/3,3) for v in bbox],
 'clipped':not(0<=bbox[0]<bbox[2]<=768 and 0<=bbox[1]<bbox[3]<=720),
 'layers_order':['original hero-base','bow-left-weapon-layer','local ginger palm fill','original hero-paws'],
 'paw_occlusion':'Small rounded ginger-fur mask inside the left paw bowl, followed by unchanged original C contour. No added cuff or glove outline.',
}
(ROOT/'processing.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
fontroot=Path('C:/Windows/Fonts')
def f(n,b=False):return ImageFont.truetype(str(fontroot/('segoeuib.ttf' if b else 'segoeui.ttf')),n)
board=Image.new('RGB',(960,680),'#d7e4dd');d=ImageDraw.Draw(board)
d.text((24,18),'CUNG - TAY TRAI',font=f(30,True),fill='#583f21')
d.text((24,62),'Only bow mirrored / original cat, cape and paws / no wearable gear',font=f(18),fill='#54685f')
d.rounded_rectangle((18,105,644,657),18,fill='#eaf0e8')
d.rounded_rectangle((662,105,942,657),18,fill='#eaf0e8')
big=cat.resize((552,518),Image.Resampling.LANCZOS);board.paste(big,(54,126),big)
d.text((682,128),'128x120',font=f(21,True),fill='#583f21')
small=cat.resize((128,120),Image.Resampling.LANCZOS);board.paste(small,(738,178),small)
d.text((682,344),'Left grip94,166',font=f(19,True),fill='#583f21')
d.text((682,392),'Main9px / secondary3px',font=f(18),fill='#54685f')
d.text((682,438),'Color+10% applied once',font=f(18),fill='#54685f')
d.text((682,484),'Original paw on top',font=f(18),fill='#54685f')
board.save(ROOT/'bow-left-review.png')
print(json.dumps(report,ensure_ascii=False))
