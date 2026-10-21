"""White matte extraction and flat palette only. No contour rebuilding/dilation."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageOps, ImageDraw

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'processed'
OUT.mkdir(exist_ok=True)
DST_BROWN=[88,63,33]
items={
    'gauntlet':dict(raw='gauntlet-iteration-4.png',src=[[99,68,33],[214,224,228],[224,174,74],[225,122,87]],dst=[DST_BROWN,[214,224,227],[223,172,88],[231,120,91]],fit=[38,34],centers=[[94,166],[160,166]],sample_y=450),
    'boot':dict(raw='boot-iteration-2.png',src=[[92,63,31],[215,225,229],[155,174,183],[224,173,73],[225,122,89]],dst=[DST_BROWN,[214,224,227],[164,182,191],[223,172,88],[231,120,91]],fit=[48,30],centers=[[84,216],[172,216]],sample_y=590),
}
meta={}
for name,cfg in items.items():
    raw=np.asarray(Image.open(ROOT/'raw'/cfg['raw']).convert('RGB')).astype(float)
    src=np.array(cfg['src'],dtype=float)
    labels=((raw[:,:,None,:]-src[None,None,:,:])**2).sum(3).argmin(2)
    rgba=np.zeros((*raw.shape[:2],4),dtype=np.uint8)
    rgba[:,:,:3]=np.array(cfg['dst'],dtype=np.uint8)[labels]
    rgba[:,:,3]=255
    white=raw.min(2)>235
    rgba[white,3]=0
    # Retain matte coverage only on the warm outer silhouette blend.
    edge=(raw.min(2)>135)&(raw[:,:,0]>raw[:,:,2]+3)&(raw[:,:,1]>raw[:,:,2])&~white
    alpha=np.clip((255-raw[:,:,2])/(255-src[0,2]),0,1)
    rgba[edge,:3]=DST_BROWN
    rgba[edge,3]=np.round(alpha[edge]*255).astype(np.uint8)
    clean=Image.fromarray(rgba,'RGBA')
    bbox=clean.getbbox()
    isolated=clean.crop(bbox)
    padded=Image.new('RGBA',(isolated.width+32,isolated.height+32))
    padded.alpha_composite(isolated,(16,16))
    padded.save(OUT/f'{name}.png')
    clean.save(OUT/f'{name}-source-clean.png')
    # Fixed layer size on a256x240canvas. Only scaling/mirroring source, no addedink.
    w,h=cfg['fit']
    single=isolated.resize((w*3,h*3),Image.Resampling.LANCZOS)
    layer=Image.new('RGBA',(256*3,240*3))
    bounds=[]
    for i,(cx,cy) in enumerate(cfg['centers']):
        piece=ImageOps.mirror(single) if i==0 else single
        x,y=round((cx-w/2)*3),round((cy-h/2)*3)
        layer.alpha_composite(piece,(x,y))
        bounds.append([x/3,y/3,(x+piece.width)/3,(y+piece.height)/3])
    layer.save(OUT/f'{name}-pair-layer-3x.png')
    layer.resize((256,240),Image.Resampling.LANCZOS).save(OUT/f'{name}-pair-layer.png')
    row=cfg['sample_y']
    active=np.where(rgba[row,:,3]>200)[0]
    start=int(active[0]);end=start
    while end<1024 and rgba[row,end,3]>200 and labels[row,end]==0:end+=1
    line=end-start
    meta[name]=dict(raw='raw/'+cfg['raw'],source_bbox=list(bbox),padded_asset=f'processed/{name}.png',source_canvas=[1024,1024],fit_dimensions=[w,h],native_pair_bounds=bounds,source_main_sample=dict(y=row,left_edge_start=start,width=line),fitted_sample_main_width=line*w/(bbox[2]-bbox[0]),fit_note='Aspect fitted to target rectangle for paw/foot mounting; generated widths vary; this is not exact9px certification.',cleanup='White matte removed; source painted regions palette flattened. No dilation, skeletonization, contour reconstruction, or new linework.',mirror_left=True)
board=Image.new('RGB',(700,360),'#d7e4dd')
d=ImageDraw.Draw(board)
for x,name in [(50,'gauntlet'),(380,'boot')]:
    piece=Image.open(OUT/f'{name}.png')
    piece.thumbnail((260,230),Image.Resampling.LANCZOS)
    board.paste(piece,(x+(260-piece.width)//2,20+(230-piece.height)//2),piece)
    d.text((x,270),name+' - generated contour retained',fill='#583f21')
    small=Image.open(OUT/f'{name}.png');small.thumbnail((48,34),Image.Resampling.LANCZOS)
    board.paste(small,(x,300),small)
board.save(OUT/'details-review.png')
(ROOT/'processing.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')
print(json.dumps(meta,indent=2))
