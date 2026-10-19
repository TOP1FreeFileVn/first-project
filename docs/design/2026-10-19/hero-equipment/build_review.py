"""Disposable modular hero-equipment art proposal; never edits game assets.

Equipment silhouettes are preserved from the recorded GPT Image 2.5 runs.
This script removes studio backgrounds, flattens material fields and fits layers.
"""
from pathlib import Path
import importlib.util
import json
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
WEAPONS = HERE.parent / 'weapon-rollout'
spec = importlib.util.spec_from_file_location('weapon_clean', WEAPONS / 'build_review.py')
wlib = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wlib)
INK = np.array([88, 63, 33], np.uint8)
S = 3
SIZE = (256*S, 240*S)
FONT = ROOT / 'game/ui/fonts/PaytoneOne-Regular.ttf'
GEAR = ['helmet', 'armor', 'gloves', 'boots', 'amulet']
NAMES = dict(helmet='Mũ', armor='Giáp', gloves='Găng', boots='Giày', amulet='Bùa')
# Target fill boxes exclude the 9-unit structural outline added by normalize().
FITS = dict(helmet=(45, 9, 166, 61), armor=(67, 137, 122, 65),
            amulet=(117, 144, 22, 30))
POSES = {
    'melee': dict(weapon='kiem', label='01 · Cận chiến', grip=[512,794], scale=175/984, angle=-36, pad=0),
    'ranged': dict(weapon='cung', label='02 · Tầm xa', grip=[625,515], scale=90/918, angle=0, pad=128, flip=True),
    'magic': dict(weapon='gay_phep', label='03 · Phép', grip=[512,660], scale=116/862, angle=-46, pad=128),
    'heavy': dict(weapon='riu', label='04 · Hạng nặng', grip=[395,680], scale=112/950, angle=-48, pad=128),
}

def canvas():
    return Image.new('RGBA', SIZE)

def clean_source(id):
    raw = Image.open(HERE/'raw'/f'{id}.png').convert('RGB')
    a = np.array(raw)
    v = a.astype(np.int16)
    white = (v.min(2)>232) & ((v.max(2)-v.min(2))<22)
    fg = ~white
    centers = np.array([[91,60,25],[207,218,222],[151,173,183],
                        [228,177,76],[182,119,66],[80,118,190],
                        [213,88,79],[96,178,177]], float)
    colors = np.array([INK,[214,224,227],[164,182,191],
                       [223,172,88],[184,121,74],[79,127,208],
                       [213,91,79],[96,177,177]], np.uint8)
    dist = ((a.astype(np.float32)[:,:,None,:]-centers[None,None,:,:])**2).sum(3)
    idx = np.argmin(dist,2).astype(np.uint8)
    idx = np.array(Image.fromarray(idx).filter(ImageFilter.ModeFilter(7)))
    for k in range(1,len(colors)):
        keep = wlib.components((idx==k)&fg, minimum=100)
        idx[(idx==k)&fg&~keep]=0
    out = np.empty((*fg.shape,4),np.uint8)
    out[:,:,:3]=colors[idx]
    out[:,:,3]=fg*255
    im=Image.fromarray(out,'RGBA')
    im=im.crop(im.getbbox())
    im.save(HERE/'processed'/f'{id}-flat-source.png')
    return im

def normalize(im, width, height, outline=9):
    """Normalize exterior at final worn scale; keep generated interior seams."""
    inner=im.resize((round(width*S),round(height*S)),Image.Resampling.LANCZOS)
    inner=ImageOps.expand(inner,round((outline+2)*S))
    a=np.array(inner)
    fill=(a[:,:,3]>180)&(np.linalg.norm(a[:,:,:3].astype(float)-INK,axis=2)>35)
    # Exact round dilation around material fields, keeping functional openings.
    alpha=wlib.lib.disk(fill,round(outline*S))
    out=np.empty_like(a);out[:,:,:3]=INK;out[:,:,3]=alpha*255
    out[fill,:3]=a[fill,:3];out[fill,3]=255
    # Preserve source construction strokes wherever they are inside the contour.
    return Image.fromarray(out,'RGBA')

def fitted(im,box,outline=9):
    x,y,w,h=box
    n=normalize(im,w,h,outline)
    layer=canvas();pad=round((outline+2)*S)
    layer.alpha_composite(n,(round(x*S)-pad,round(y*S)-pad))
    return layer

def pair(im,id):
    a=np.array(im)
    # Generated matched pairs separated by the central white studio gap.
    left=im.crop((0,0,im.width//2,im.height));left=left.crop(left.getbbox())
    right=im.crop((im.width//2,0,im.width,im.height));right=right.crop(right.getbbox())
    layer=canvas()
    if id=='gloves':
        # Short mitten silhouettes centred on the unchanged native paw sockets.
        poses=[(94,166,left),(160,166,right)];w,h=28,27
    else:
        poses=[(84,211,left),(172,211,right)];w,h=36,24
    for x,y,item in poses:
        n=normalize(item,w,h,outline=9)
        layer.alpha_composite(n,(round(x*S-n.width/2),round(y*S-n.height/2)))
    return layer

def export_icon(id,im):
    crop=im.crop(im.getbbox())
    crop.save(HERE/'processed'/f'{id}-cropped.png')
    for size in (48,64,96):
        dst=Image.new('RGBA',(size,size))
        r=min((size-6)/crop.width,(size-6)/crop.height)
        thumb=crop.resize((round(crop.width*r),round(crop.height*r)),Image.Resampling.LANCZOS)
        dst.alpha_composite(thumb,((size-thumb.width)//2,(size-thumb.height)//2))
        dst.save(HERE/'processed'/f'icon_{id}_{size}.png')

def weapon_layer(pose):
    im=Image.open(WEAPONS/'processed'/f'{pose["weapon"]}.png').convert('RGBA')
    ratio=pose['scale']*S
    gx,gy=[(v+pose['pad'])*ratio for v in pose['grip']]
    scaled=im.resize((round(im.width*ratio),round(im.height*ratio)),Image.Resampling.LANCZOS)
    if pose.get('flip'):
        scaled=ImageOps.mirror(scaled);gx=scaled.width-gx
    if pose['weapon']=='riu':
        # The heavy pose uses a shorter reach; restore the exterior at its
        # final worn scale rather than shrinking its 9-unit edge to 7.2 units.
        a=np.array(scaled)
        fill=(a[:,:,3]>180)&(np.linalg.norm(a[:,:,:3].astype(float)-INK,axis=2)>35)
        alpha=wlib.lib.disk(fill,9*S)
        b=np.empty_like(a);b[:,:,:3]=INK;b[:,:,3]=alpha*255
        b[fill,:3]=a[fill,:3];b[fill,3]=255
        scaled=Image.fromarray(b,'RGBA')
    angle=pose['angle'];rot=scaled.rotate(angle,Image.Resampling.BICUBIC,expand=True)
    dx,dy=gx-scaled.width/2,gy-scaled.height/2;t=math.radians(angle)
    rx=math.cos(t)*dx+math.sin(t)*dy+rot.width/2
    ry=-math.sin(t)*dx+math.cos(t)*dy+rot.height/2
    x,y=round(160*S-rx),round(166*S-ry)
    layer=canvas();layer.alpha_composite(rot,(x,y))
    b=rot.getbbox();bounds=[(x+b[0])/S,(y+b[1])/S,(x+b[2])/S,(y+b[3])/S]
    return layer,dict(**pose,target_grip=[160,166],bounds=bounds,clipped=not(0<=bounds[0]<bounds[2]<=256 and 0<=bounds[1]<bounds[3]<=240))

def paste(dst,im,box):
    if isinstance(im,Path): im=Image.open(im).convert('RGBA')
    x,y,w,h=box;r=min(w/im.width,h/im.height)
    im=im.resize((round(im.width*r),round(im.height*r)),Image.Resampling.LANCZOS)
    dst.alpha_composite(im,(round(x+(w-im.width)/2),round(y+(h-im.height)/2)))

def board():
    out=Image.new('RGBA',(1440,1440),'#d8e5df');d=ImageDraw.Draw(out)
    f=lambda n:ImageFont.truetype(str(FONT),n)
    d.text((36,20),'MÈO ANH HÙNG · BỘ TRANG BỊ',font=f(34),fill='#583f21')
    d.text((36,76),'4 pose cầm vũ khí · 5 lớp đồ cố định · Viền chính 9 px',font=f(21),fill='#583f21')
    for i,id in enumerate(GEAR):
        x=32+i*278;y=132
        d.rounded_rectangle((x,y,x+264,y+246),20,fill='#edf1e7')
        d.text((x+16,y+12),NAMES[id],font=f(22),fill='#583f21')
        paste(out,HERE/'processed'/f'{id}-cropped.png',(x+24,y+56,216,128))
        out.alpha_composite(Image.open(HERE/'processed'/f'icon_{id}_48.png'),(x+108,y+190))
    for i,(id,pose) in enumerate(POSES.items()):
        x=32+i*352;y=404
        d.rounded_rectangle((x,y,x+336,y+496),22,fill='#edf1e7')
        d.text((x+16,y+14),pose['label'],font=f(22),fill='#583f21')
        paste(out,HERE/'processed'/f'hero_{id}.png',(x+12,y+68,312,292.5))
        out.alpha_composite(Image.open(HERE/'processed'/f'hero_{id}_128.png'),(x+18,y+367))
        d.text((x+164,y+404),'128 × 120',font=f(16),fill='#745b3d')
    d.rounded_rectangle((32,926,1408,1364),22,fill='#edf1e7')
    d.text((56,944),'CÙNG MỘT THÂN MÈO · THAY RIÊNG TỪNG LỚP',font=f(25),fill='#583f21')
    for i,(label,filename) in enumerate([('Nền mèo sạch','hero-base'),('Mặc đủ 5 đồ','hero-equipped'),('Cầm kiếm','hero_melee')]):
        p=HERE/('sources' if i==0 else 'processed')/f'{filename}.png'
        paste(out,p,(68+i*318,1018,290,272))
        d.text((88+i*318,1300),label,font=f(20),fill='#583f21')
    d.text((1040,1036),'Điểm gắn cố định',font=f(21),fill='#583f21')
    for i,line in enumerate(['Mũ · đầu','Giáp / bùa · thân','Găng · hai tay','Giày · hai chân','Cung: cầm sẵn']):
        d.text((1040,1090+i*42),line,font=f(19),fill='#745b3d')
    d.text((36,1390),'Bản duyệt artwork · Chưa thay asset game chính · Chưa phải animation tấn công',font=f(17),fill='#583f21')
    out.convert('RGB').save(HERE/'hero-equipment-review.png')

def main():
    (HERE/'processed').mkdir(exist_ok=True)
    layers={}
    for id in GEAR:
        if not (HERE/'raw'/f'{id}.png').exists():continue
        im=clean_source(id)
        layer=pair(im,id) if id in ('gloves','boots') else fitted(im,FITS[id],outline=4 if id=='amulet' else 9)
        layer.save(HERE/'processed'/f'layer_{id}.png');layers[id]=layer
        export_icon(id,layer)
    if len(layers)<5 or not (HERE/'sources/hero-base.png').exists():return
    base=Image.open(HERE/'sources/hero-body.png').convert('RGBA')
    head=Image.open(HERE/'sources/hero-head-noears.png').convert('RGBA')
    equip=base.copy()
    for id in ('boots','armor','amulet'):
        equip.alpha_composite(layers[id])
    equip.alpha_composite(head);equip.alpha_composite(layers['helmet'])
    equip.alpha_composite(layers['gloves'])
    equip.save(HERE/'processed/hero-equipped.png')
    metadata={}
    for id,pose in POSES.items():
        w,metadata[id]=weapon_layer(pose);w.save(HERE/'processed'/f'weapon_{id}.png')
        cat=base.copy()
        for gear in ('boots','armor','amulet'):cat.alpha_composite(layers[gear])
        cat.alpha_composite(head);cat.alpha_composite(layers['helmet'])
        cat.alpha_composite(w);cat.alpha_composite(layers['gloves'])
        cat.save(HERE/'processed'/f'hero_{id}.png')
        cat.resize((128,120),Image.Resampling.LANCZOS).save(HERE/'processed'/f'hero_{id}_128.png')
    (HERE/'anchors.json').write_text(json.dumps(dict(canvas=[256,240],fixed_layers=GEAR,main_outline=9,
        outline_exceptions=dict(amulet=4,bowstring=1.5),
        sockets=dict(left_paw=[94,166],right_paw=[160,166],helmet=[128,62],armor=[128,175],amulet=[128,159],boots=[[84,211],[172,211]]),
        poses=metadata,production_changed=False,attack_animation_implemented=False),indent=2),encoding='utf-8')
    board()
    print(json.dumps(metadata,indent=2))

if __name__=='__main__':main()
