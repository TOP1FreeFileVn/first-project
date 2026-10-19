"""Clean generated illustrations and compose disposable cat-held review assets.

The weapons come from GPT Image generations, never from the vector generators.
Raw generations/prompts are kept separately. Production art is not modified.
"""
from pathlib import Path
from collections import deque
import importlib.util
import json
import math
import shutil
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
V6=HERE.parent/'weapon-redesign/v6-nine-px'
spec=importlib.util.spec_from_file_location('nine_px',V6/'build_review.py')
lib=importlib.util.module_from_spec(spec);spec.loader.exec_module(lib)
INK=np.array([88,63,33],np.uint8)
FONT=ROOT/'game/ui/fonts/PaytoneOne-Regular.ttf'
IDS=['kiem','riu','dao','katana','cung','no','sung','dai_bac',
     'gay_phep','thuoc','sach_phep','dua_phep','giao','cu_kiem','chuy','bua']
NAMES=['Kiếm','Rìu','Đao','Katana','Cung','Nỏ','Súng','Đại bác',
       'Gậy phép','Thuốc','Sách phép','Đũa phép','Giáo','Cự kiếm','Chùy','Búa']
# Source grips and optical sizes are individually measured on each generation.
POSES={
 'riu':dict(grip=[395,680],scale=140/950,angle=-24,paw=[160,166]),
 'dao':dict(grip=[473,874],scale=145/980,angle=-25,paw=[160,166]),
 'katana':dict(grip=[510,850],scale=155/950,angle=-28,paw=[160,166]),
 'cung':dict(grip=[625,515],scale=90/918,angle=-75,paw=[160,166]),
 'no':dict(grip=[512,490],scale=88/960,angle=0,paw=[160,166]),
 'sung':dict(grip=[170,620],scale=80/966,angle=4,paw=[160,166]),
 'dai_bac':dict(grip=[200,530],scale=92/901,angle=0,paw=[160,185]),
 'giao':dict(grip=[513,782],scale=160/980,angle=-23,paw=[160,166]),
 'gay_phep':dict(grip=[512,660],scale=116/862,angle=-46,paw=[160,166]),
 'thuoc':dict(grip=[385,330],scale=60/967,angle=8,paw=[160,166]),
 'sach_phep':dict(grip=[120,620],scale=80/1000,angle=0,paw=[160,170]),
 'cu_kiem':dict(grip=[512,815],scale=100/950,angle=-54,paw=[162,170]),
 'dua_phep':dict(grip=[512,747],scale=110/950,angle=-48,paw=[160,166]),
 'chuy':dict(grip=[512,755],scale=125/1014,angle=-39,paw=[160,166]),
 'bua':dict(grip=[511,725],scale=110/955,angle=-55,paw=[160,166]),
}

def straighten_blade(a,id):
    """Reduce the generated blade bend without reconstructing its artwork.

    Each row keeps its original cross-section; only its centerline is moved.
    The blade root, guard and grip stay fixed at the same source coordinates.
    """
    if id not in ('dao','katana'):return a
    v=a.astype(np.int16)
    steel=(v[:,:,2]>v[:,:,0]-20)&(v[:,:,1]>v[:,:,0]-10)&(v.min(2)>95)&(v.min(2)<225)
    steel[705:]=False
    ys=[];centers=[]
    for y in range(15,705):
        xx=np.where(steel[y])[0]
        if len(xx)>12:ys.append(y);centers.append((xx[0]+xx[-1])/2)
    yy=np.array(ys);cc=np.array(centers)
    # A cubic centerline avoids transferring palette/antialias fluctuations
    # into tiny wobbles in the new blade edge.
    smooth=np.polyval(np.polyfit(yy,cc,3),yy)
    bottom=float(np.median(smooth[-16:]));lean=26 if id=='dao' else 7
    target=bottom+lean*(1-(yy-yy[0])/(yy[-1]-yy[0]))
    shift=np.interp(np.arange(a.shape[0]),yy,(target-smooth)*.88)
    shift[yy[-1]+1:]=0
    # Continue the measured top shift through the outlined tip above steel.
    result=np.full_like(a,255)
    for y,dx in enumerate(np.rint(shift).astype(int)):
        if dx>=0:result[y,dx:]=a[y,:a.shape[1]-dx]
        else:result[y,:dx]=a[y,-dx:]
    return result

def components(mask,minimum=120):
    """Drop palette fringes, retain substantial illustrated material planes."""
    seen=np.zeros_like(mask);keep=np.zeros_like(mask);h,w=mask.shape
    for y,x in zip(*np.where(mask)):
        if seen[y,x]:continue
        points=[];q=deque([(int(x),int(y))]);seen[y,x]=True
        while q:
            xx,yy=q.popleft();points.append((xx,yy))
            for nx,ny in ((xx-1,yy),(xx+1,yy),(xx,yy-1),(xx,yy+1)):
                if 0<=nx<w and 0<=ny<h and mask[ny,nx] and not seen[ny,nx]:
                    seen[ny,nx]=True;q.append((nx,ny))
        if len(points)>=minimum:
            xs,ys=zip(*points);keep[np.array(ys),np.array(xs)]=True
    return keep

def clean(id,pose):
    original=Image.open(HERE/'raw'/f'{id}.png').convert('RGB')
    a=straighten_blade(np.array(original),id);v=a.astype(np.int16)
    # White studio background, including functional holes between strings/limbs.
    white=(v.min(2)>230)&((v.max(2)-v.min(2))<25)
    foreground=~white
    # Broad common matte material fields, sampled from accepted sword and raw set.
    centers=np.array([[91,60,25],[207,218,222],[151,173,183],
        [228,177,76],[182,119,66],[153,94,55],[96,178,177],
        [151,110,192],[241,227,192],[213,88,79]],float)
    colors=np.array([[88,63,33],[214,224,227],[164,182,191],
        [223,172,88],[184,121,74],[184,121,74],[96,177,177],
        [154,117,198],[237,222,184],[213,91,79]],np.uint8)
    distances=((a.astype(np.float32)[:,:,None,:]-centers[None,None,:,:])**2).sum(3)
    if id in ('riu','dao','katana','giao','cu_kiem','chuy','bua'):
        distances[:,:,[6,7,8,9]]=1e9
    idx=np.argmin(distances,2)
    # Local mode removes nearest-palette gradient speckles without moving the
    # generated object contour or erasing broad material regions.
    idx=np.array(Image.fromarray(idx.astype(np.uint8)).filter(ImageFilter.ModeFilter(9)))
    # Remove isolated antialias/gradient specks separately for each material.
    # Warm handle variants share one material before component filtering.
    idx[idx==5]=4
    for k in range(1,len(colors)):
        keep=components((idx==k)&foreground)
        idx[(idx==k)&foreground&~keep]=0
    fill=(idx!=0)&foreground
    if id=='cung':
        fill[132:879,360:390]=False
    pad=128
    fill=np.pad(fill,pad)
    idx=np.pad(idx,pad)
    foreground=np.pad(foreground,pad)
    radius=9/pose['scale'];lo=math.floor(radius);frac=radius-lo
    alpha=lib.disk(fill,lo).astype(float)*(1-frac)+lib.disk(fill,lo+1).astype(float)*frac
    # Preserve source ink-only construction (bowstrings/trigger bridges),
    # at its lighter structural weight rather than a second heavy silhouette.
    alpha=np.maximum(alpha,foreground.astype(float))
    if id=='cung':
        # The original string is x≈375 and only7px wide. Keep that subordinate
        # line independent from the9px outer contour around material fields.
        # This is the measured original string path, not a rebuilt weapon.
        string=Image.new('L',(out_w:=fill.shape[1],fill.shape[0]))
        ImageDraw.Draw(string).line([(375+pad,117+pad),(375+pad,891+pad)],fill=255,width=round(1.5/pose['scale']))
        alpha=np.maximum(alpha,np.array(string)/255)
    out=np.empty((*fill.shape,4),np.uint8);out[:,:,:3]=INK;out[:,:,3]=np.rint(alpha*255).astype(np.uint8)
    out[fill,:3]=colors[idx[fill]];out[fill,3]=255
    im=Image.fromarray(out,'RGBA')
    im.save(HERE/'processed'/f'{id}.png')
    im.crop(im.getbbox()).save(HERE/'processed'/f'{id}-cropped.png')
    return im,dict(padding_source=pad,outer_contour_target_unit_px=9,
        radius_source_px=radius,palette='shared matte material fields',
        source_artwork_preserved=True,original_raw_unchanged=True,
        blade_bend_reduced=id in ('dao','katana'))

def export_icons(id,im):
    crop=im.crop(im.getbbox())
    for size in (32,48,64,96):
        icon=Image.new('RGBA',(size,size));r=min((size-4)/crop.width,(size-4)/crop.height)
        small=crop.resize((round(crop.width*r),round(crop.height*r)),Image.Resampling.LANCZOS)
        icon.alpha_composite(small,((size-small.width)//2,(size-small.height)//2))
        icon.save(HERE/'processed'/f'icon_w_{id}_{size}.png')

def compose(id,im,pose):
    ratio=pose['scale']*3;angle=pose['angle'];pad=128
    scaled=im.resize((round(im.width*ratio),round(im.height*ratio)),Image.Resampling.LANCZOS)
    grip=[(v+pad)*ratio for v in pose['grip']]
    rot=scaled.rotate(angle,Image.Resampling.BICUBIC,expand=True)
    dx,dy=grip[0]-scaled.width/2,grip[1]-scaled.height/2
    theta=math.radians(angle)
    gx=math.cos(theta)*dx+math.sin(theta)*dy+rot.width/2
    gy=-math.sin(theta)*dx+math.cos(theta)*dy+rot.height/2
    x,y=round(pose['paw'][0]*3-gx),round(pose['paw'][1]*3-gy)
    cat=Image.open(HERE/'sources'/f'cat_{id}.png').convert('RGBA')
    cat.alpha_composite(rot,(x,y))
    cat.alpha_composite(Image.open(HERE/'sources/front-paw.png').convert('RGBA'))
    bounds=rot.getbbox();bounds=[x+bounds[0],y+bounds[1],x+bounds[2],y+bounds[3]]
    cat.save(HERE/'processed'/f'unit_{id}.png')
    cat.resize((128,120),Image.Resampling.LANCZOS).save(HERE/'processed'/f'unit_{id}_128.png')
    export_icons(id,im)
    return dict(**pose,weapon_bounds_unit_px=[round(v/3,2) for v in bounds],
        clipping=not(0<=bounds[0]<bounds[2]<=768 and 0<=bounds[1]<bounds[3]<=720))

def paste(canvas,source,box):
    if isinstance(source,Path):source=Image.open(source).convert('RGBA')
    ratio=min(box[2]/source.width,box[3]/source.height)
    source=source.resize((round(source.width*ratio),round(source.height*ratio)),Image.Resampling.LANCZOS)
    canvas.alpha_composite(source,(round(box[0]+(box[2]-source.width)/2),round(box[1]+(box[3]-source.height)/2)))

def board():
    im=Image.new('RGBA',(1440,1760),'#d8e5df');d=ImageDraw.Draw(im)
    f=lambda n:ImageFont.truetype(str(FONT),n)
    d.text((36,20),'BỘ VŨ KHÍ · 15 MẪU MỚI',font=f(32),fill='#583f21')
    d.text((36,72),'Cùng kiếm đã duyệt · Viền 9 px trên canvas 256 × 240',font=f(19),fill='#583f21')
    for i,(id,name) in enumerate(zip(IDS,NAMES)):
        x=32+(i%4)*352;y=124+(i//4)*400
        d.rounded_rectangle((x,y,x+336,y+382),22,fill='#edf1e7')
        d.text((x+16,y+10),name+(' · Đã duyệt' if id=='kiem' else ''),font=f(21),fill='#583f21')
        p=HERE/'processed'/f'{id}-cropped.png'
        if p.exists():paste(im,p,(x+18,y+54,126,192))
        p=HERE/'processed'/f'unit_{id}.png'
        if p.exists():paste(im,p,(x+140,y+68,186,176))
        p=HERE/'processed'/f'unit_{id}_128.png'
        if p.exists():im.alpha_composite(Image.open(p).convert('RGBA'),(x+14,y+250))
        p=HERE/'processed'/f'icon_w_{id}_48.png'
        if p.exists():im.alpha_composite(Image.open(p).convert('RGBA'),(x+190,y+275))
        d.text((x+154,y+340),'128 × 120 / 48 px',font=f(13),fill='#745b3d')
    d.text((36,1730),'Bản duyệt · Chưa thay artwork game chính',font=f(16),fill='#583f21')
    im.convert('RGB').save(HERE/'weapon-set-review.png')

def main():
    (HERE/'processed').mkdir(exist_ok=True)
    for name in ('kiem.png','kiem-cropped.png','unit_kiem.png','unit_kiem_128.png'):
        shutil.copyfile(V6/'processed'/name,HERE/'processed'/name)
    export_icons('kiem',Image.open(HERE/'processed/kiem.png').convert('RGBA'))
    if (HERE/'poses.json').exists():POSES.update(json.loads((HERE/'poses.json').read_text('utf-8')))
    ids=sys.argv[1:] or [id for id in IDS if id!='kiem' and (HERE/'raw'/f'{id}.png').exists() and id in POSES]
    for id in ids:
        im,processing=clean(id,POSES[id])
        placement=compose(id,im,POSES[id]) if (HERE/'sources'/f'cat_{id}.png').exists() else None
        (HERE/'processed'/f'{id}.json').write_text(json.dumps(dict(processing=processing,placement=placement),indent=2),encoding='utf-8')
        print(id,placement)
    board()

if __name__=='__main__':main()
