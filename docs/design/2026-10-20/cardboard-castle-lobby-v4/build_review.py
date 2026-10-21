"""Review-only raster refinement. Preserve generated silhouettes and source cats."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'processed'
OUT.mkdir(exist_ok=True)
V2 = ROOT.parent / 'cardboard-castle-lobby-v2'
raw = Image.open(ROOT / 'courtyard-raw.png').convert('RGB')
rgb = np.asarray(raw).astype(np.float32)
h,w = rgb.shape[:2]
y,x = np.indices((h,w))
r,g,b = rgb.transpose(2,0,1)
warm = (r > g*1.04) & (g > b*1.13)

# Continuous material blends compress shading without hard palette boundaries.
# The modest residual shading is intentional; no posterized contours are made.
paint = rgb.copy()
sky = (b > g*.94) & (g > r*1.12) & (y < 430)
paint[sky] = paint[sky]*.72 + np.array([179,220,219])*.28
lawn = (g > r*.99) & (r > g*.87) & (b < g*.76) & (y > 380)
paint[lawn] = paint[lawn]*.45 + np.array([194,207,132])*.55
path = warm & (r>170) & (y>780)
paint[path] = paint[path]*.56 + np.array([233,207,156])*.44

castle_area = (x>=100)&(x<790)&(y>=225)&(y<780)
castle_area &= ~((x>640)&(y>733))
castle_area &= ~((x<300)&(y>740))
fill = warm & castle_area & (r>165)
body_target = np.zeros_like(paint) + [233,190,123]
# Retain genuinely separate pale tape/cap and brown side planes.
pale = np.clip((g-208)/25,0,1)[...,None]
body_target = body_target*(1-pale)+np.array([246,222,166])*pale
side = np.clip((197-r)/30,0,1)[...,None]
body_target = body_target*(1-side)+np.array([205,162,101])*side
paint[fill] = paint[fill]*.30 + body_target[fill]*.70
ink = warm & (r<145)
strength = np.clip((151-r)/65,0,.52)[...,None]
paint = np.where(ink[...,None], paint*(1-strength)+np.array([88,63,33])*strength,paint)
refined = Image.fromarray(np.uint8(np.clip(paint,0,255)))

# Isolate only the existing AI castle pixels, including its teal flags.
teal = (r<g*.78)&(b>g*.83)&(b>r*1.1)
castle_mask = castle_area & (warm|teal)
# Select the connected keep/turret/flag component; a broad material mask would
# also pick up the edge tree's brown branch and the tunnel's upper cardboard.
connected_allow = np.asarray(Image.fromarray(np.uint8(castle_mask)*255).filter(ImageFilter.MaxFilter(3)))>0
connected = np.zeros((h,w),dtype=bool)
stack=[(500,450)]
connected[500,450]=True
while stack:
 cy,cx=stack.pop()
 for ny,nx in ((cy-1,cx),(cy+1,cx),(cy,cx-1),(cy,cx+1)):
  if 0<=ny<h and 0<=nx<w and connected_allow[ny,nx] and not connected[ny,nx]:
   connected[ny,nx]=True
   stack.append((ny,nx))
castle_mask &= connected
# Close tiny breaks in the generated ink, then fill its closed silhouette.
# This retains the AI outline while eliminating punched-out teal flag pixels.
mask_image = Image.fromarray(np.uint8(castle_mask)*255).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
padded = Image.new('L',(w+2,h+2),0)
padded.paste(mask_image,(1,1))
ImageDraw.floodfill(padded,(0,0),128,thresh=0)
castle_mask = np.asarray(padded.crop((1,1,w+1,h+1))) != 128
alpha = Image.fromarray(np.uint8(castle_mask)*255).filter(ImageFilter.GaussianBlur(.34))

# A clean warm ink edge on the three flags prevents cyan matte fringes. Only
# the outermost original flag perimeter is recolored, not its fish or fabric.
castle_pixels = np.asarray(refined).copy()
eroded = np.asarray(Image.fromarray(np.uint8(castle_mask)*255).filter(ImageFilter.MinFilter(7)))>0
edge = castle_mask & ~eroded
flag_rects = [(450,244,554,325),(204,428,267,496),(692,431,755,498)]
flag_region = np.zeros((h,w),dtype=bool)
for fx0,fy0,fx1,fy1 in flag_rects:
 flag_region[fy0:fy1,fx0:fx1]=True
castle_pixels[edge & flag_region] = [88,63,33]
castle = Image.fromarray(castle_pixels).convert('RGBA')
castle.putalpha(alpha)
castle = castle.crop((100,225,790,780))

# Clear the old larger castle with quiet local terrain colors. Its exact
# silhouette is then fitted between the two native UI rails as a separate layer.
# Interpolate each removed run from actual adjacent source terrain. This keeps
# the original hill/lawn shading and prevents a different-color castle-shaped
# patch. The tunnel and scratching post are explicitly excluded from this mask.
erase = Image.fromarray(np.uint8(castle_mask)*255).filter(ImageFilter.MaxFilter(7))
erase_array = np.asarray(erase)>0
source_pixels = np.asarray(refined).astype(np.float32).copy()
# The old broad shadow belongs to the old castle width, so remove it before
# reconstructing terrain and add a smaller contact shadow at the fitted foot.
old_shadow = (y>=665)&(y<755)&(x>=60)&(x<835)&(r<184)&(g>r*1.04)&(b<g*.82)
source_pixels[old_shadow] = source_pixels[old_shadow]*.08 + np.array([194,207,132])*.92
replacement = source_pixels.copy()
for row in range(h):
 indices=np.flatnonzero(erase_array[row])
 if not len(indices):
  continue
 splits=np.where(np.diff(indices)>1)[0]+1
 for run in np.split(indices,splits):
  first,last=int(run[0]),int(run[-1])
  left=max(0,first-1)
  right=min(w-1,last+1)
  left_color=np.median(source_pixels[max(0,row-1):min(h,row+2),max(0,left-2):left+1],axis=(0,1))
  right_color=np.median(source_pixels[max(0,row-1):min(h,row+2),right:min(w,right+3)],axis=(0,1))
  blend=np.linspace(0,1,last-first+1)[:,None]
  replacement[row,first:last+1]=left_color*(1-blend)+right_color*blend
# Reconstruct the small sky/hill span that the original main flag hid. Its
# local hill edge is interpolated from the adjacent visible AI terrain, so no
# rectangular flag-shaped pale patch remains after moving the castle.
hill_test=(b<g*.91)&(r>g*.83)&(r<g*1.03)&(y>=180)&(y<370)
hill_columns=[]
for cx in [410,580]:
 hits=np.flatnonzero(hill_test[:,cx])
 hill_columns.append(float(hits[0]) if len(hits) else (327 if cx==410 else 290))
hill_edge=np.interp(np.arange(w),[410,580],hill_columns)
hill_mix=np.clip((y-hill_edge[None,:]+.7)/1.4,0,1)[...,None]
sky_color=np.median(source_pixels[230:245,400:420],axis=(0,1))
hill_color=np.median(source_pixels[338:350,400:420],axis=(0,1))
terrain_field=sky_color*(1-hill_mix)+hill_color*hill_mix
flag_hole_mask=Image.new('L',(w,h))
ImageDraw.Draw(flag_hole_mask).rectangle((424,225,566,345),fill=255)
flag_hole_mask=flag_hole_mask.filter(ImageFilter.GaussianBlur(9))
flag_hole_weight=np.asarray(flag_hole_mask,dtype=np.float32)[...,None]/255
replacement=replacement*(1-flag_hole_weight)+terrain_field*flag_hole_weight
base = Image.fromarray(np.uint8(np.clip(replacement,0,255)))
base = base.resize((720,1280),Image.Resampling.LANCZOS).convert('RGBA')
# Join the fitted ramp to the unchanged original path with its own material.
join_mask=Image.new('L',(720,1280))
ImageDraw.Draw(join_mask).polygon([(285,635),(389,635),(402,664),(333,668),(315,657),(286,654)],fill=255)
join_mask=join_mask.filter(ImageFilter.GaussianBlur(.65))
path_color=tuple(np.asarray(base)[666,363,:3])
base.paste(Image.new('RGBA',base.size,path_color+(255,)),(0,0),join_mask)
contact=Image.new('RGBA',base.size)
ImageDraw.Draw(contact).ellipse((142,590,604,633),fill=(103,137,78,65))
base=Image.alpha_composite(base,contact)
castle_scale = .646
castle = castle.resize((round(castle.width*castle_scale),round(castle.height*castle_scale)),Image.Resampling.LANCZOS)
# Source doorway-bottom anchor [433,700] -> destination [365,595].
# Keeping the ramp near its original ground height also joins the existing path.
castle_pos = (round(365-(433-100)*castle_scale), round(595-(700-225)*castle_scale))
castle_layer = Image.new('RGBA',(720,1280))
castle_layer.alpha_composite(castle,castle_pos)
castle_layer.save(OUT/'castle-layer.png')
bounds = castle_layer.getbbox()
castle_layer.crop(bounds).save(OUT/'castle-crop.png')
base.convert('RGB').save(OUT/'terrain-background.png')
base = Image.alpha_composite(base,castle_layer)
base.convert('RGB').save(OUT/'courtyard-background.png')

placements = [
 {'id':'cream','source':'game/ui/skin/cat_cream.svg','raster':'../cardboard-castle-lobby-v2/processed/cat_cream.png','x':115,'y':682,'width':96,'height':90,'place':'inside the cardboard tunnel'},
 {'id':'tabby','source':'game/ui/skin/cat_tabby.svg','raster':'../cardboard-castle-lobby-v2/processed/cat_tabby.png','x':323,'y':686,'width':108,'height':101,'place':'central path in the playground'},
 {'id':'calico','source':'game/ui/skin/cat_calico.svg','raster':'../cardboard-castle-lobby-v2/processed/cat_calico.png','x':496,'y':772,'width':96,'height':90,'place':'inside the cardboard sleeping tray; front wall restored above feet'},
]

# Exact original tray front wall is composited above the calico's lower body.
# This is an extracted raster foreground, not a newly illustrated box edge.
occlusion = Image.new('RGBA',(720,1280))
tray_mask = Image.new('L',(720,1280))
dmask = ImageDraw.Draw(tray_mask)
dmask.polygon([(444,808),(572,829),(571,878),(443,860)],fill=255)
tray_mask = tray_mask.filter(ImageFilter.GaussianBlur(.28))
occlusion.paste(base,(0,0),tray_mask)
occlusion.save(OUT/'cat-occlusion-overlay.png')

record = {
 'review_only':True,'screen':[720,1280],
 'background':'processed/courtyard-background.png',
 'terrain_background':'processed/terrain-background.png',
 'castle_layer':'processed/castle-layer.png',
 'occlusion_overlay':'processed/cat-occlusion-overlay.png',
 'layer_order':['background','native cat cream','native cat tabby','native cat calico','cat-occlusion-overlay','native UI overlay'],
 'cats':placements,
 'castle':{'source':'courtyard-raw.png','source_region':[100,225,790,780],'source_doorway_anchor':[433,700],'destination_doorway_anchor':[365,595],'scale_from_raw':castle_scale,'bounds':list(bounds)},
 'processing':'Continuous material blending; source silhouettes/linework preserved. Residual broad shading retained; no hard quantization or SVG redraw.',
}
(ROOT/'placements.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')

def with_cats(background):
 scene=background.convert('RGBA')
 for item in placements:
  cat=Image.open(V2/'processed'/Path(item['raster']).name).convert('RGBA')
  cat=cat.resize((item['width'],item['height']),Image.Resampling.LANCZOS)
  scene.alpha_composite(cat,(item['x'],item['y']))
 return Image.alpha_composite(scene,occlusion)

scene = with_cats(base)
scene.convert('RGB').save(ROOT/'map-with-cats.png')
ui = Image.open(V2/'ui-overlay-ground-lobby-with-title.png').convert('RGBA')
mockup=Image.alpha_composite(scene,ui)
mockup.convert('RGB').save(ROOT/'lobby-courtyard.png')

FONT='C:/Windows/Fonts/arial.ttf'
BOLD='C:/Windows/Fonts/arialbd.ttf'
inkcolor='#583f21'
board=Image.new('RGB',(1536,1470),'#e6eedf')
d=ImageDraw.Draw(board)
d.text((32,25),'SẢNH LÂU ĐÀI HỘP GIẤY · SÂN CHƠI MÈO',font=ImageFont.truetype(BOLD,33),fill=inkcolor)
d.text((32,76),'Giữ tạo hình AI; giảm tô loang, vừa hai rail; mèo dùng nguyên asset trong game',font=ImageFont.truetype(FONT,23),fill=inkcolor)
board.paste(scene.convert('RGB'),(24,130))
board.paste(mockup.convert('RGB'),(792,130))
d.text((24,1422),'Cảnh và mèo gốc',font=ImageFont.truetype(BOLD,23),fill=inkcolor)
d.text((792,1422),'Thử cùng UI native · chưa đưa vào game',font=ImageFont.truetype(FONT,22),fill=inkcolor)
board.save(ROOT/'courtyard-review.png')

small=Image.new('RGB',(1024,970),'#e6eedf')
ds=ImageDraw.Draw(small)
ds.text((24,20),'ẢNH GỐC VÀ BẢN CHỈNH ĐỂ DUYỆT',font=ImageFont.truetype(BOLD,27),fill=inkcolor)
for xpos,image,label in [(24,raw,'Gốc: thành quá rộng, tô loang'),(524,base,'Chỉnh: giữ hình, giảm shading')]:
 small.paste(image.convert('RGB').resize((475,844),Image.Resampling.LANCZOS),(xpos,75))
 ds.text((xpos,932),label,font=ImageFont.truetype(FONT,20),fill=inkcolor)
small.save(ROOT/'raw-vs-refined.png')
print(json.dumps({'background':str(OUT/'courtyard-background.png'),'placements':str(ROOT/'placements.json'),'castle_bounds':bounds,'cats':placements},ensure_ascii=True))
