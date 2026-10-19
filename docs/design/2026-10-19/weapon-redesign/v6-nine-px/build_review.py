"""Set both existing cat and generated sword to a measured 9-unit outer contour."""
from pathlib import Path
from collections import deque
import importlib.util
import json
import math
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
V4=HERE.parent/'v4-sword'
V5=HERE.parent/'v5-cat-stroke'
ORIGINAL=HERE.parent/'v3-ai/held-sources'
INK=np.array([88,63,33],np.uint8)
TARGET=9.0
UNIT_SCALE=175/984
FONT=ROOT/'game/ui/fonts/PaytoneOne-Regular.ttf'
ET.register_namespace('', 'http://www.w3.org/2000/svg')


def disk(mask,radius):
    """Exact Euclidean integer disk, rather than square MaxFilter corners."""
    result=np.zeros_like(mask)
    h,w=mask.shape
    for dy in range(-radius,radius+1):
        dx=int(math.sqrt(radius*radius-dy*dy))
        p=np.pad(mask,((0,0),(dx+1,dx)),constant_values=False)
        sums=np.cumsum(p,axis=1,dtype=np.int32)
        line=(sums[:,2*dx+1:]-sums[:,:-2*dx-1])>0
        if dy>=0: result[dy:]|=line[:h-dy]
        else: result[:dy]|=line[-dy:]
    return result


def clean_fill(a):
    foreground=(a[:,:,3]>128)
    mask=foreground&np.any(a[:,:,:3]!=INK,axis=2)
    seen=np.zeros(mask.shape,bool); keep=np.zeros_like(mask)
    h,w=mask.shape; removed=[]
    for y,x in zip(*np.where(mask)):
        if seen[y,x]: continue
        points=[];q=deque([(int(x),int(y))]);seen[y,x]=True
        while q:
            xx,yy=q.popleft();points.append((xx,yy))
            for nx,ny in ((xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)):
                if 0<=nx<w and 0<=ny<h and mask[ny,nx] and not seen[ny,nx]:
                    seen[ny,nx]=True;q.append((nx,ny))
        if len(points)>=512:
            xs,ys=zip(*points);keep[np.array(ys),np.array(xs)]=True
        else: removed.append(len(points))
    return keep,removed


def prepare():
    (HERE/'sources').mkdir(parents=True,exist_ok=True)
    (HERE/'processed').mkdir(exist_ok=True)
    for name in ('cat_kiem','front-paw'):
        tree=ET.parse(ORIGINAL/f'{name}.svg')
        for node in tree.iter():
            if node.get('stroke')=='#583f21':
                width=31.0 if float(node.get('stroke-width'))==30 else TARGET
                node.set('stroke-width',str(width))
        tree.write(HERE/'sources'/f'{name}.svg',encoding='utf-8',xml_declaration=True)
    a=np.array(Image.open(V4/'processed/kiem.png').convert('RGBA'))
    fill,removed=clean_fill(a)
    # Retain every pixel in the main generated material planes. Normalize the
    # outline around those planes, including diagonal tip edges. The center
    # divider and grip seams stay ink; no illustrated shape is reconstructed.
    radius=TARGET/UNIT_SCALE
    lo=math.floor(radius); fraction=radius-lo
    alpha=disk(fill,lo).astype(float)*(1-fraction)+disk(fill,lo+1).astype(float)*fraction
    out=np.zeros_like(a);out[:,:,:3]=INK;out[:,:,3]=np.rint(alpha*255).astype(np.uint8)
    out[fill,:3]=a[fill,:3];out[fill,3]=255
    assert np.array_equal(out[fill,:3],a[fill,:3])
    sword=Image.fromarray(out,'RGBA')
    sword.save(HERE/'processed/kiem.png')
    sword.crop(sword.getbbox()).save(HERE/'processed/kiem-cropped.png')
    (HERE/'processing.json').write_text(json.dumps(dict(target_unit_px=TARGET,
        source_scale_to_unit=UNIT_SCALE,outer_radius_source_px=radius,
        source_weapon='../v4-sword/processed/kiem.png',
        method='Euclidean outer contour around original material fields; fractional-radius alpha',
        material_fields_preserved=True,material_pixel_count=int(fill.sum()),
        tiny_exterior_fringe_components_removed=removed,
        production_changed=False),indent=2),encoding='utf-8')
    print('NINE_PX_SOURCES_PREPARED',radius)


def measure():
    a=np.array(Image.open(HERE/'processed/kiem.png').convert('RGBA')).astype(float)
    ink=(np.linalg.norm(a[:,:,:3]-INK,axis=2)<10)
    coverage=a[:,:,3]/255*ink
    widths=[]
    for y in range(260,581,16):
        widths.append(float(coverage[y,330:429].sum()*UNIT_SCALE))
        widths.append(float(coverage[y,595:695].sum()*UNIT_SCALE))
    cat=np.array(Image.open(HERE/'sources/cat_kiem.png').convert('RGBA')).astype(float)
    steel=np.array([201,211,221],float);delta=INK.astype(float)-steel
    cat_coverage=np.clip(((cat[15:85,378:393,:3]-steel)*delta).sum(2)/(delta*delta).sum(),0,1)
    cat_coverage*=cat[15:85,378:393,3]/255
    cat_width=float(np.median(cat_coverage.sum(0)/3))
    sword_width=float(np.median(widths))
    result=dict(target_unit_px=TARGET,sword_body_unit_px=sword_width,cat_crown_unit_px=cat_width,
        difference_unit_px=abs(sword_width-cat_width),
        sword_body_native_128_px=sword_width/2,cat_native_128_px=cat_width/2,
        method='42 normal samples of blade body, plus antialias-aware crown coverage',
        tolerance_unit_px=0.03,
        passed=abs(sword_width-TARGET)<0.03 and abs(cat_width-TARGET)<0.03)
    assert result['passed'],result
    (HERE/'measurement.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    return result


def compose():
    spec=importlib.util.spec_from_file_location('v4_review',V4/'prepare_review.py')
    lib=importlib.util.module_from_spec(spec);spec.loader.exec_module(lib)
    sword=Image.open(HERE/'processed/kiem.png').convert('RGBA')
    ratio=UNIT_SCALE*3
    sw=sword.resize((round(sword.width*ratio),round(sword.height*ratio)),Image.Resampling.LANCZOS)
    angle=-32;grip=(512*ratio,794*ratio)
    rotated=sw.rotate(angle,Image.Resampling.BICUBIC,expand=True)
    dx,dy=grip[0]-sw.width/2,grip[1]-sw.height/2
    theta=math.radians(angle)
    gx=math.cos(theta)*dx+math.sin(theta)*dy+rotated.width/2
    gy=-math.sin(theta)*dx+math.cos(theta)*dy+rotated.height/2
    x,y=round(160*3-gx),round(166*3-gy)
    unit=Image.open(HERE/'sources/cat_kiem.png').convert('RGBA')
    unit.alpha_composite(rotated,(x,y))
    unit.alpha_composite(Image.open(HERE/'sources/front-paw.png').convert('RGBA'))
    bbox=rotated.getbbox();bounds=[x+bbox[0],y+bbox[1],x+bbox[2],y+bbox[3]]
    assert 0<=bounds[0]<bounds[2]<=768 and 0<=bounds[1]<bounds[3]<=720,bounds
    unit.save(HERE/'processed/unit_kiem.png')
    unit.resize((128,120),Image.Resampling.LANCZOS).save(HERE/'processed/unit_kiem_128.png')
    result=measure()
    board=Image.new('RGBA',(1120,820),'#d8e5df');d=ImageDraw.Draw(board)
    def f(size):return ImageFont.truetype(str(FONT),size)
    d.text((32,18),'MÈO VÀ KIẾM · CÙNG VIỀN 9 PX',font=f(30),fill='#583f21')
    d.text((32,69),'Canvas 256 × 240: 9 px · Khi thu 128 × 120: 4,5 px',font=f(19),fill='#583f21')
    for i,(label,path) in enumerate([('Kiếm rời · Viền 9 px',HERE/'processed/kiem-cropped.png'),
                                    ('Mèo cầm kiếm · Cùng viền 9 px',HERE/'processed/unit_kiem.png')]):
        x=32+i*540;d.rounded_rectangle((x,118,x+516,650),24,fill='#edf1e7')
        d.text((x+24,135),label,font=f(22),fill='#583f21')
        lib.paste(board,path,(x+20,194,476,420))
    board.alpha_composite(Image.open(HERE/'processed/unit_kiem_128.png').convert('RGBA'),(110,674))
    d.text((282,689),'128 × 120 · Giữ nguyên tỷ lệ và cách cầm',font=f(19),fill='#583f21')
    d.text((282,729),'Bản duyệt · Chưa thay asset game chính',font=f(18),fill='#583f21')
    board.convert('RGB').save(HERE/'nine-px-review.png')
    print(json.dumps(result,indent=2))


if __name__=='__main__':
    import sys
    prepare() if '--prepare' in sys.argv else compose()
