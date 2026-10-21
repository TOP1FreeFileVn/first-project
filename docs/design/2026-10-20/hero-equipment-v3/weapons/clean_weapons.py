"""Clean selected generated weapon rasters without geometric line edits.

Allowed changes: remove white matte, flatten region palette, fit intact image.
No dilation, morphology, skeletonization, or contour reconstruction.
"""
from pathlib import Path
import math, json
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parents[4]
OUT=ROOT/'clean'
OUT.mkdir(exist_ok=True)
S=3
SRC_BASE=PROJECT/'docs/design/2026-10-19/hero-equipment/sources'
CONFIG={
 'sword':dict(iteration=2,node='42:2',source_grip=[512,800],scale=.18,angle=-30,mirror=False,
   palette_source=[[93,63,28],[212,222,224],[170,187,195],[219,165,77],[234,116,84],[148,77,54]],
   palette_target=[[88,63,33],[214,224,227],[164,182,191],[223,172,88],[231,120,91],[152,78,57]],
   measured_main_source=49.5,measured_note='Blade side contour horizontal sections y300,450,550; both sides49–50px. Grip outer border36–37px.'),
 'bow':dict(iteration=3,node='52:2',source_grip=[680,505],scale=.145,angle=0,mirror=True,
   palette_source=[[93,65,33],[191,124,63],[189,139,100],[226,116,86],[227,172,85],[151,77,54]],
   palette_target=[[88,63,33],[184,123,66],[184,123,66],[231,120,91],[223,172,88],[152,78,57]],
   measured_main_source=47.0,measured_note='Wood arc horizontal sections y350,650 around45–47px; y25050–56px.Grip boundary is selectively thinner~12px. Thin functional string retained, not enlarged.'),
 'staff':dict(iteration=3,node='50:2',source_grip=[512,835],scale=.20,angle=-22,mirror=False,
   palette_source=[[88,61,28],[181,116,59],[219,166,78],[232,118,91],[112,196,188],[154,80,56]],
   palette_target=[[88,63,33],[184,123,66],[223,172,88],[231,120,91],[113,200,188],[152,78,57]],
   measured_main_source=42,measured_note='Straight wood shaft at y400,500,700:42px each side. Orb contour and grip edge thinner; not claimed uniform9px.'),
}
report={}
for name,c in CONFIG.items():
 raw=np.asarray(Image.open(ROOT/'raw'/f"{name}-iteration-{c['iteration']}.png").convert('RGB')).astype(float)
 src=np.array(c['palette_source'],float)
 dst=np.array(c['palette_target'],np.uint8)
 labels=((raw[:,:,None,:]-src[None,None,:,:])**2).sum(3).argmin(2)
 rgba=np.zeros((*raw.shape[:2],4),np.uint8)
 rgba[:,:,:3]=dst[labels]
 rgba[:,:,3]=255
 white=raw.min(2)>238
 rgba[white,3]=0
 # Keep the generated thin bow string distinct from a broad light wood plane.
 if name=='bow':
  yy,xx=np.indices(raw.shape[:2])
  string=(xx<335)&(yy>75)&(yy<945)&(labels==2)&~white
  rgba[string,:3]=[161,139,106]
 # Recover AA coverage where the warm contour meets the white matte.
 edge=(raw.min(2)>135)&(raw[:,:,0]>raw[:,:,2]+2)&(raw[:,:,1]>raw[:,:,2])&~white
 alpha=np.clip((255-raw[:,:,2])/(255-src[0,2]),0,1)
 rgba[edge,:3]=dst[0]
 rgba[edge,3]=np.round(alpha[edge]*255).astype(np.uint8)
 weapon=Image.fromarray(rgba,'RGBA')
 bbox=weapon.getbbox()
 weapon.save(OUT/f'{name}-source-clean.png')
 crop=weapon.crop(bbox)
 pad=Image.new('RGBA',(crop.width+32,crop.height+32))
 pad.alpha_composite(crop,(16,16))
 pad.save(OUT/f'{name}.png')
 # Exact full-source coordinates, no cropped-coordinate ambiguity.
 grip=list(c['source_grip'])
 if c['mirror']:
  weapon=weapon.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
  grip[0]=weapon.width-grip[0]
 ratio=c['scale']*S
 scaled=weapon.resize((round(weapon.width*ratio),round(weapon.height*ratio)),Image.Resampling.LANCZOS)
 rot=scaled.rotate(c['angle'],Image.Resampling.BICUBIC,expand=True)
 gx,gy=grip[0]*ratio,grip[1]*ratio
 dx,dy=gx-scaled.width/2,gy-scaled.height/2
 t=math.radians(c['angle'])
 rx=math.cos(t)*dx+math.sin(t)*dy+rot.width/2
 ry=-math.sin(t)*dx+math.cos(t)*dy+rot.height/2
 x,y=round(160*S-rx),round(166*S-ry)
 layer=Image.new('RGBA',(256*S,240*S))
 layer.alpha_composite(rot,(x,y))
 layer.save(OUT/f'{name}-held-layer.png')
 local=rot.getbbox()
 bounds=[(x+local[0])/S,(y+local[1])/S,(x+local[2])/S,(y+local[3])/S]
 cat=Image.open(SRC_BASE/'hero-base.png').convert('RGBA')
 cat.alpha_composite(layer)
 cat.alpha_composite(Image.open(SRC_BASE/'hero-paws.png').convert('RGBA'))
 cat.save(OUT/f'hero-{name}-context.png')
 cat.resize((128,120),Image.Resampling.LANCZOS).save(OUT/f'hero-{name}-128.png')
 icon=Image.new('RGBA',(64,64))
 thumb=pad.copy()
 thumb.thumbnail((60,60),Image.Resampling.LANCZOS)
 icon.alpha_composite(thumb,((64-thumb.width)//2,(64-thumb.height)//2))
 icon.save(OUT/f'{name}-64.png')
 report[name]={**c,'source_bbox':list(bbox),'source_image':[1024,1024],
  'crop_grip':[c['source_grip'][0]-bbox[0]+16,c['source_grip'][1]-bbox[1]+16],
  'target_grip':[160,166],'transformed_source_grip':grip,'held_bounds':bounds,
  'clipped':not(0<=bounds[0]<bounds[2]<=256 and 0<=bounds[1]<bounds[3]<=240),
  'estimated_fitted_main':round(c['measured_main_source']*c['scale'],2),
  'cleanup':'White matte extraction and palette flattening; broad light wood plane unified with wood. Original geometry retained.',
  'model':'gpt-image-2.5-sunburst','generation_file':'2uKzqvXeOSPQqfaow6s7TU',
  'provenance':'Text-only generation informed by viewed references; no image-input conditioning.'}
(ROOT/'processing.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
fontpath=Path('C:/Windows/Fonts')
def font(n,bold=False):return ImageFont.truetype(str(fontpath/('segoeuib.ttf' if bold else 'segoeui.ttf')),n)
board=Image.new('RGB',(1200,980),'#d7e4dd')
d=ImageDraw.Draw(board)
d.text((24,18),'HERO EQUIPMENT V3 - WEAPON FAMILIES',font=font(28,True),fill='#583f21')
d.text((24,58),'Text-only GPT Image 2.5 generation. White matte / palette cleanup only.',font=font(17),fill='#54685f')
for col,(name,c) in enumerate(CONFIG.items()):
 x=col*400
 d.rounded_rectangle((x+16,96,x+384,962),18,fill='#eaf0e8')
 d.text((x+34,110),name.upper(),font=font(24,True),fill='#583f21')
 iso=Image.open(OUT/f'{name}.png')
 iso.thumbnail((160,325),Image.Resampling.LANCZOS)
 board.paste(iso,(x+200-iso.width//2,150),iso)
 context=Image.open(OUT/f'hero-{name}-context.png')
 context=context.resize((330,309),Image.Resampling.LANCZOS)
 board.paste(context,(x+35,475),context)
 native=Image.open(OUT/f'hero-{name}-128.png')
 board.paste(native,(x+40,798),native)
 icon=Image.open(OUT/f'{name}-64.png')
 board.paste(icon,(x+220,822),icon)
 fit=report[name]['estimated_fitted_main']
 d.text((x+34,930),f'Main measured fit approx {fit}px',font=font(17),fill='#54685f')
board.save(ROOT/'weapon-contact-sheet.png')
print(json.dumps({n:{k:v for k,v in r.items() if k in ['source_bbox','source_grip','held_bounds','clipped','estimated_fitted_main']} for n,r in report.items()},ensure_ascii=False))
