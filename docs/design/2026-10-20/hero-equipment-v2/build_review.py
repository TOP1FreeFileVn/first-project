"""Versioned raster revision of the recorded GPT Image 2.5 equipment designs.

Retains generated contours, simplifies narrow trim, and authors shared interior
boundaries by role at the final worn scale. No production assets are changed.
"""
from pathlib import Path
from collections import deque
import importlib.util
import json
import shutil
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from stroke_tools import fill_internal_ink, shared_boundary, round_stroke_mask

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
V1=ROOT/'docs/design/2026-10-19/hero-equipment'
spec=importlib.util.spec_from_file_location('hero_v1',V1/'build_review.py')
old=importlib.util.module_from_spec(spec);spec.loader.exec_module(old)
S=3;SIZE=(768,720);INK=np.array([88,63,33],np.uint8)
INNER_INK=np.array([98,101,107],np.uint8)
COLORS=np.array([INK,[214,224,227],[164,182,191],[223,172,88],
                 [151,101,57],[79,127,208],[213,91,79],[96,177,177]],np.uint8)
GEAR=['helmet','armor','gloves','boots','amulet']
NAMES=dict(helmet='Mũ',armor='Giáp',gloves='Găng',boots='Giày',amulet='Bùa')
FONT=ROOT/'game/ui/fonts/PaytoneOne-Regular.ttf'
MEASUREMENTS=[]
ROLEMAP={
 'helmet':[(1,3,9,'crown-to-brim'),(1,6,9,'plume-attachment'),(1,2,4.5,'ear-inset')],
 'armor':[(1,2,9,'overlapping-lower-plate'),(1,5,4.5,'blue-neck-trim'),(1,3,3.5,'clasp'),(5,3,3.5,'clasp-trim')],
 'gloves':[(1,5,9,'cuff-to-mitten')],
 'boots':[(1,4,9,'upper-to-sole'),(1,5,4.5,'shaft-panel'),(4,5,9,'sole-to-shaft')],
 'amulet':[(3,6,2.5,'inset-gem-setting')],
}

def canvas():return Image.new('RGBA',SIZE)

def broad_components(labels,fg,id):
    """Flatten gradients within original ink-separated material planes."""
    mask=(labels>0)&fg;seen=np.zeros_like(mask);h,w=mask.shape
    out=np.zeros_like(labels)
    for y,x in zip(*np.where(mask)):
        if seen[y,x]:continue
        q=deque([(int(y),int(x))]);seen[y,x]=True;ys=[];xs=[]
        while q:
            yy,xx=q.popleft();ys.append(yy);xs.append(xx)
            for ny,nx in ((yy-1,xx),(yy+1,xx),(yy,xx-1),(yy,xx+1)):
                if 0<=ny<h and 0<=nx<w and mask[ny,nx] and not seen[ny,nx]:
                    seen[ny,nx]=True;q.append((ny,nx))
        if len(ys)<100:continue
        yy=np.array(ys);xx=np.array(xs)
        k=int(np.bincount(labels[yy,xx],minlength=8).argmax())
        if k in (1,2):
            if id=='armor':k=2 if yy.mean()>610 else 1
            elif id in ('gloves','boots'):k=1
        if id in ('gloves','boots') and k==3:k=5
        out[yy,xx]=k
    return out

def source(id):
    p=V1/'raw'/f'{id}.png'
    a=np.array(Image.open(p).convert('RGB'));v=a.astype(np.int16)
    fg=~((v.min(2)>232)&((v.max(2)-v.min(2))<22))
    centers=np.array([[91,60,25],[207,218,222],[151,173,183],[228,177,76],
                      [133,94,47],[80,118,190],[213,88,79],[96,178,177]],float)
    dist=((a.astype(np.float32)[:,:,None,:]-centers[None,None,:,:])**2).sum(3)
    idx=np.argmin(dist,2).astype(np.uint8)
    if id=='boots':
        yy=np.indices(idx.shape)[0]
        sole=(yy>640)&(a[:,:,0]>=96)&(a[:,:,0]<=116)&(a[:,:,1]>=66)&(a[:,:,1]<=84)&(a[:,:,2]>=33)&(a[:,:,2]<=49)&fg
        idx[sole]=4
    # Brown sole is a material only in boots; other brown remains structural ink.
    if id!='boots':idx[idx==4]=0
    idx=np.array(Image.fromarray(idx).filter(ImageFilter.ModeFilter(5)))
    idx=broad_components(idx,fg,id)
    filled=fill_internal_ink(idx,fg)
    ys,xs=np.where(fg);box=(xs.min(),ys.min(),xs.max()+1,ys.max()+1)
    labels=filled[box[1]:box[3],box[0]:box[2]]
    obj=fg[box[1]:box[3],box[0]:box[2]]
    np.savez_compressed(HERE/'sources'/f'{id}-labels.npz',labels=labels,object_mask=obj,source_bbox=box)
    return labels,obj

def resize_labels(labels,obj,w,h,warps=None):
    if warps:
        # Piecewise vertical reallocation keeps generated row contours; makes
        # room for the main join without inventing a replacement silhouette.
        sy=[p[0] for p in warps];dy=[p[1] for p in warps]
        yy=np.interp(np.linspace(0,1,round(h*S)),dy,sy)
        rows=np.clip(np.rint(yy*(labels.shape[0]-1)).astype(int),0,labels.shape[0]-1)
        labels=labels[rows];obj=obj[rows]
    n=(round(w*S),round(h*S))
    labs=np.array(Image.fromarray(labels).resize(n,Image.Resampling.NEAREST))
    mask=np.array(Image.fromarray(obj.astype(np.uint8)*255).resize(n,Image.Resampling.NEAREST))>128
    return labs,mask

def render(id,labels,obj,w,h,outer=9,warps=None):
    labels,obj=resize_labels(labels,obj,w,h,warps)
    if id=='amulet' and outer==9:
        # Broaden the generated bezel so its metal remains visible between
        # the9px pendant silhouette and2.5px inset detail.
        red=labels==6
        core=np.array(Image.fromarray(red.astype(np.uint8)*255).filter(ImageFilter.MinFilter(13)))>128
        labels[red&~core]=3
    pad=round((outer/2+2)*S)
    labels=np.pad(labels,pad);obj=np.pad(obj,pad)
    # A single centre-line along the generated silhouette; never an outline
    # expanded around each separate material field.
    inner=np.array(Image.fromarray(obj.astype(np.uint8)*255).filter(ImageFilter.MinFilter(3)))>128
    edge=obj&~inner
    border=round_stroke_mask(edge,outer*S, supersample=2)
    alpha=np.maximum(border,obj.astype(np.uint8)*255)
    a=np.empty((*obj.shape,4),np.uint8);a[:,:,:3]=COLORS[labels];a[:,:,3]=alpha
    a[border>0,:3]=INK
    for ka,kb,width,name in ROLEMAP[id]:
        path=shared_boundary(labels,ka,kb,object_mask=obj)
        if not path.any():continue
        stroke=round_stroke_mask(path,width*S,supersample=2,clip_mask=obj)
        # Preserve antialias coverage on stroke edges, rather than turning
        # every nonzero mask sample into opaque ink.
        t=stroke[:,:,None].astype(float)/255
        a[:,:,:3]=np.rint(a[:,:,:3]*(1-t)+INNER_INK*t).astype(np.uint8)
        MEASUREMENTS.append(dict(item=id,boundary=name,role='main' if width==9 else 'secondary' if width>=4 else 'detail',
                                 authored_width_unit_px=width,centreline_pixels=int(path.sum())))
    im=Image.fromarray(a,'RGBA')
    return im,pad

def place(layer,im,x,y,pad):
    layer.alpha_composite(im,(round(x*S)-pad,round(y*S)-pad))

def build_item(id,labels,obj):
    layer=canvas()
    if id=='helmet':
        im,pad=render(id,labels,obj,175,67,warps=[(0,0),(.43,.30),(.72,.62),(.85,.91),(1,1)])
        place(layer,im,40.5,6,pad)
    elif id=='armor':
        im,pad=render(id,labels,obj,132,73)
        place(layer,im,62,132,pad)
    elif id in ('gloves','boots'):
        mid=labels.shape[1]//2
        for side,x in enumerate([94,160] if id=='gloves' else [84,172]):
            sl=slice(0,mid) if side==0 else slice(mid,labels.shape[1])
            la=labels[:,sl];ma=obj[:,sl];ys,xs=np.where(ma)
            la=la[ys.min():ys.max()+1,xs.min():xs.max()+1];ma=ma[ys.min():ys.max()+1,xs.min():xs.max()+1]
            if id=='gloves':
                # Gold/blue lip becomes one blue cuff; its main mitten join
                # retains 9px with a larger readable cuff and mitten below.
                im,pad=render(id,la,ma,43,45,warps=[(0,0),(.23,.35),(1,1)])
                place(layer,im,x-21.5,143,pad)
            else:
                im,pad=render(id,la,ma,44,40,warps=[(0,0),(.68,.50),(1,1)])
                place(layer,im,x-22,187,pad)
    else:
        # Cord and pendant are fit separately to keep the main body outline9
        # while the cord remains a subordinate functional line.
        cord=obj&(labels==5);ys,xs=np.where(cord)
        la=labels[ys.min():ys.max()+1,xs.min():xs.max()+1];ma=cord[ys.min():ys.max()+1,xs.min():xs.max()+1]
        im,pad=render(id,la,ma,43,18,outer=4.5)
        place(layer,im,106.5,140,pad)
        pendant=obj&np.isin(labels,[3,6]);ys,xs=np.where(pendant)
        la=labels[ys.min():ys.max()+1,xs.min():xs.max()+1];ma=pendant[ys.min():ys.max()+1,xs.min():xs.max()+1]
        im,pad=render(id,la,ma,31,37,outer=9)
        place(layer,im,112.5,155,pad)
    layer.save(HERE/'processed'/f'layer_{id}.png')
    crop=layer.crop(layer.getbbox());crop.save(HERE/'processed'/f'{id}-cropped.png')
    for size in (48,64,96):
        out=Image.new('RGBA',(size,size));old.paste(out,crop,(3,3,size-6,size-6));out.save(HERE/'processed'/f'icon_{id}_{size}.png')
    return layer

def compose(layers):
    body=Image.open(V1/'sources/hero-body.png').convert('RGBA')
    head=Image.open(V1/'sources/hero-head-noears.png').convert('RGBA')
    meta={}
    for id,pose0 in old.POSES.items():
        pose=dict(pose0)
        if id=='melee':pose['angle']=-42
        weapon,meta[id]=old.weapon_layer(pose)
        weapon.save(HERE/'processed'/f'weapon_{id}.png')
        cat=body.copy()
        for gear in ('boots','armor','amulet'):cat.alpha_composite(layers[gear])
        cat.alpha_composite(head);cat.alpha_composite(layers['helmet']);cat.alpha_composite(weapon);cat.alpha_composite(layers['gloves'])
        cat.save(HERE/'processed'/f'hero_{id}.png')
        cat.resize((128,120),Image.Resampling.LANCZOS).save(HERE/'processed'/f'hero_{id}_128.png')
    equip=body.copy()
    for gear in ('boots','armor','amulet'):equip.alpha_composite(layers[gear])
    equip.alpha_composite(head);equip.alpha_composite(layers['helmet']);equip.alpha_composite(layers['gloves'])
    equip.save(HERE/'processed/hero-equipped.png')
    return meta

def board():
    im=Image.new('RGBA',(1440,1420),'#d8e5df');d=ImageDraw.Draw(im);f=lambda n:ImageFont.truetype(str(FONT),n)
    d.text((36,20),'TRANG BỊ MÈO ANH HÙNG · V2',font=f(34),fill='#583f21')
    d.text((36,76),'Nét chính trong / ngoài: 9 px · Nét phụ 4–5 px · Chi tiết 2–3 px',font=f(20),fill='#583f21')
    for i,id in enumerate(GEAR):
        x=32+i*278;y=126
        d.rounded_rectangle((x,y,x+264,y+270),20,fill='#edf1e7')
        d.text((x+16,y+12),NAMES[id],font=f(22),fill='#583f21')
        old.paste(im,HERE/'processed'/f'{id}-cropped.png',(x+22,y+56,220,148))
        im.alpha_composite(Image.open(HERE/'processed'/f'icon_{id}_48.png'),(x+106,y+210))
    for i,(id,pose) in enumerate(old.POSES.items()):
        x=32+i*352;y=420
        d.rounded_rectangle((x,y,x+336,y+492),22,fill='#edf1e7')
        d.text((x+16,y+12),pose['label'],font=f(22),fill='#583f21')
        old.paste(im,HERE/'processed'/f'hero_{id}.png',(x+12,y+62,312,292.5))
        im.alpha_composite(Image.open(HERE/'processed'/f'hero_{id}_128.png'),(x+18,y+362))
        d.text((x+166,y+403),'128 × 120',font=f(16),fill='#745b3d')
    d.rounded_rectangle((32,938,1408,1344),22,fill='#edf1e7')
    d.text((56,952),'CÙNG TỶ LỆ · TRƯỚC / SAU',font=f(25),fill='#583f21')
    old.paste(im,V1/'processed/hero-equipped.png',(78,1012,310,291))
    old.paste(im,HERE/'processed/hero-equipped.png',(440,1012,310,291))
    d.text((152,1302),'Bản trước',font=f(19),fill='#583f21');d.text((520,1302),'Bản sửa V2',font=f(19),fill='#583f21')
    for i,line in enumerate(['Một đường nối chính cho cổ găng / đế giày','Gộp dải trang trí hẹp để giữ khoảng màu','Mặt bùa lớn hơn · Dây và ổ đá mảnh hơn','5 lớp mặc cố định trong cả 4 pose']):
        d.text((812,1046+i*58),line,font=f(18),fill='#745b3d')
    d.text((36,1370),'Bản duyệt artwork · Chưa thay asset game chính · 4 tư thế cầm, chưa phải animation',font=f(17),fill='#583f21')
    im.convert('RGB').save(HERE/'hero-equipment-v2.png')

def main():
    for folder in ('sources','processed','manifests'):(HERE/folder).mkdir(exist_ok=True)
    layers={}
    for id in GEAR:
        labs,obj=source(id);layers[id]=build_item(id,labs,obj);print('BUILT',id,flush=True)
    meta=compose(layers);board()
    (HERE/'stroke-contract.json').write_text(json.dumps(dict(canvas=[256,240],render_scale=S,main=9,secondary=[4,5],detail=[2,3],outer_ink='#583f21',interior_ink='#62656B',
        authored_boundaries=MEASUREMENTS,source='../../2026-10-19/hero-equipment/raw',
        pipeline='original generated silhouettes; material-plane flattening; vertical module reallocation; one authored shared boundary per role',
        production_changed=False,attack_animation_implemented=False,poses=meta),indent=2),encoding='utf-8')

if __name__=='__main__':main()
