"""Flatten generated environment materials, then compose unchanged game cats/UI.

This is an approval mockup; production assets and gameplay are not modified.
"""
from pathlib import Path
from collections import deque
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parent
V2 = ROOT.parent / 'cardboard-castle-lobby-v2'
OUT = ROOT / 'processed'
OUT.mkdir(exist_ok=True)

def rgb(h):
    return tuple(bytes.fromhex(h.lstrip('#')))

INK = rgb('583f21')
LAWN = rgb('bcd17f')
im = Image.open(ROOT / 'flat-map-raw.png').convert('RGB')
src = np.asarray(im.filter(ImageFilter.MedianFilter(3))).astype(np.int16)
r, g, b = src[...,0], src[...,1], src[...,2]
h, w = r.shape
yy, xx = np.indices((h,w))
paint = np.empty((h,w,3), dtype=np.uint8)
paint[:] = LAWN

# Semantic green planes: one exact lawn fill, two exact foliage fills.
green = (g > r*1.025) & (g > b*1.15)
foliage = green & (r < 150)
paint[foliage] = rgb('8fb77b')
upper_leaf = green & (r >= 145) & (b < 107) & (yy < 210) & ((xx < 150) | (xx > w-150))
paint[upper_leaf] = rgb('a7c88a')
green_ink = green & (r < 132) & (g < 148)
paint[green_ink] = rgb('728051')

# Teal toy/flag areas and coral yarn have no lighting variation.
teal = (g > r*1.12) & (b > r*1.12) & (b > g*.76)
paint[teal] = rgb('64a8ad')
coral = (r > g*1.3) & (g < 180) & (b < 160) & (xx > 210) & (xx < 320) & (yy > 890) & (yy < 1005)
paint[coral] = rgb('e77767')

# Dark warm contours and dark doorway silhouettes share the cat's brown ink.
ink = (~green) & (r < 161) & (g < 128) & (b < 100)
ink |= (r < 100) & (g < 145) & (b < 145) & (~green)
paint[ink] = INK
paint[coral & (~ink) & (r < 195)] = rgb('bf5e4e')
cream = (~green) & (~teal) & (r > 222) & (g > 209) & (b > 163)
paint[cream] = rgb('fff0b6')

# Closed warm material regions are flattened as whole regions rather than
# posterized into contour bands. Open cream tape is protected by its own mask.
warm = (~green) & (~teal) & (~ink) & (~cream) & (~coral)
seen = np.zeros((h,w), dtype=bool)
palette = np.array([rgb(x) for x in ['e9bd7a','d3a15f','f4d9a4','a57a48','ead5a0']], dtype=float)
components = 0
for sy, sx in zip(*np.where(warm)):
    if seen[sy,sx]:
        continue
    q = deque([(int(sy), int(sx))])
    seen[sy,sx] = True
    pts = []
    while q:
        y,x = q.pop()
        pts.append((y,x))
        for ny,nx in ((y-1,x),(y+1,x),(y,x-1),(y,x+1)):
            if 0 <= ny < h and 0 <= nx < w and warm[ny,nx] and not seen[ny,nx]:
                seen[ny,nx] = True
                q.append((ny,nx))
    py,px = np.array(pts).T
    median = np.median(src[py,px], axis=0)
    color = palette[np.argmin(np.sum((palette-median)**2, axis=1))].astype(np.uint8)
    # The unoutlined path below the castle is a separate material plane.
    if len(pts) > 1000 and np.median(py) > 665 and np.median(px) < 550:
        color = np.array(rgb('ead5a0'), dtype=np.uint8)
    paint[py,px] = color
    components += 1

flat = Image.fromarray(paint).filter(ImageFilter.ModeFilter(3))
# Fit the castle between the existing rails and below the plain stage name.
# Keep all generated contours; only scale this cutout and repaint its old lawn.
clean = np.asarray(flat).copy()
castle_mask = (xx >= 110) & (xx < 750) & (yy >= 180) & (yy < 665)
castle_mask &= ~((xx > 600) & (yy > 630))  # preserve the scratching-post top
castle_mask &= np.any(clean != np.array(LAWN), axis=-1)
castle_layer = Image.fromarray(clean).convert('RGBA')
castle_layer.putalpha(Image.fromarray((castle_mask*255).astype('uint8')))
castle_layer = castle_layer.crop((110,180,750,665))
clean[castle_mask] = LAWN
flat = Image.fromarray(clean).convert('RGBA')
castle_layer = castle_layer.resize((525,398), Image.Resampling.LANCZOS)
flat.alpha_composite(castle_layer, ((w-525)//2,290))
flat = flat.convert('RGB')
flat.save(OUT / 'flat-map-auto-clean.png')
# Final contour cleanup follows the generated design in transparent SVG layers.
# This removes speckled quantization edges without changing the actual cats.
manual_layers = [ROOT / 'playground-clean.png', OUT / 'castle-clean.png']
if all(path.exists() for path in manual_layers):
    final_map = Image.new('RGBA',(720,1280),LAWN+(255,))
    for path in manual_layers:
        layer = Image.open(path).convert('RGBA')
        assert layer.size == (720,1280), path
        final_map = Image.alpha_composite(final_map,layer)
    flat = final_map.convert('RGB')
else:
    flat = flat.resize((720,1280), Image.Resampling.LANCZOS)
flat.save(OUT / 'flat-map-clean.png')
scene = flat.convert('RGBA')

# Reuse actual game cats, preserving their faces, colors and strokes.
residents = [
    ('cat_cream.png', (91,616), 96),
    ('cat_tabby.png', (304,609), 120),
    ('cat_calico.png', (455,711), 96),
]
for name,pos,width in residents:
    cat = Image.open(V2 / 'processed' / name).convert('RGBA')
    cat = cat.resize((width,round(width*cat.height/cat.width)), Image.Resampling.LANCZOS)
    scene.alpha_composite(cat,pos)
scene.convert('RGB').save(ROOT / 'map-with-cats.png')
overlay = Image.open(V2 / 'ui-overlay-ground-lobby-with-title.png').convert('RGBA')
mockup = Image.alpha_composite(scene,overlay)
mockup.convert('RGB').save(ROOT / 'lobby-flat-style.png')

board = Image.new('RGB',(1512,1460),'#e6eedf')
d = ImageDraw.Draw(board)
font = lambda size,bold=False: ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf' if bold else 'C:/Windows/Fonts/arial.ttf',size)
d.text((35,25),'SẢNH LÂU ĐÀI HỘP GIẤY · STYLE MÈO',font=font(35,True),fill=INK)
d.text((35,78),'Màu phẳng · viền nâu tròn · mặt đất liền · khu vui chơi',font=font(23),fill=INK)
board.paste(scene.convert('RGB'),(24,130))
board.paste(mockup.convert('RGB'),(768,130))
d.text((24,1426),'Bản cảnh tổng thể',font=font(22,True),fill=INK)
d.text((768,1426),'Ghép UI và tên màn sắp tới',font=font(22,True),fill=INK)
board.save(ROOT / 'flat-style-review.png')

# Large split comparison with the earlier background + same native cream cat.
old = Image.open(V2 / 'ground-playground-raw.png').convert('RGB').resize((360,640),Image.Resampling.LANCZOS)
new = flat.resize((360,640),Image.Resampling.LANCZOS)
comparison = Image.new('RGB',(780,780),'#e6eedf')
cd = ImageDraw.Draw(comparison)
cd.text((24,20),'ĐỒNG BỘ NỀN VỚI MÈO GỐC',font=font(28,True),fill=INK)
cat = Image.open(V2 / 'processed' / 'cat_cream.png').convert('RGBA').resize((78,73),Image.Resampling.LANCZOS)
for x,base,label in [(20,old,'Trước: tô loang, nhiều chi tiết'),(400,new,'Sau: mảng phẳng, nét tròn')]:
    comparison.paste(base,(x,78))
    comparison.paste(cat,(x+155,78+365),cat)
    cd.text((x,738),label,font=font(20,True),fill=INK)
comparison.save(ROOT / 'style-comparison.png')

(ROOT / 'manifest.json').write_text(json.dumps({
    'review_only':True,'model':'gpt-image-2.5-sunburst','route':'Figma generate_image',
    'file_key':'2uKzqvXeOSPQqfaow6s7TU','generated_node_id':'61:2',
    'prompt':'prompts/flat-cat-map.txt','raw':'flat-map-raw.png',
    'cleanup':'Flat material study, followed by smooth SVG contour cleanup traced from the generated castle/playground; raw retained.',
    'source_size':[w,h],'screen_size':[720,1280],
    'flat_material_colors':len(np.unique(paint.reshape(-1,3),axis=0)),
    'contour_cleanup_layers':[str(p.relative_to(ROOT)) for p in manual_layers if p.exists()],
    'warm_components':components,
    'unchanged_cat_sources':[f'game/ui/skin/{Path(x[0]).stem}.svg' for x in residents],
    'production_code_modified':False
},ensure_ascii=False,indent=2),encoding='utf-8')
print('Built flat map, native-cat/UI composite, and style comparison.')
