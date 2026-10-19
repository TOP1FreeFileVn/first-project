"""Prepare the user-rated iteration 2. No silhouette dilation or code redraw."""
from pathlib import Path
from collections import deque
import json
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
SOURCE = HERE.parent / 'v3-ai/held-sources'
OUT = HERE / 'processed'
INK = '#583f21'
BG = '#d8e5df'
FONT = ROOT / 'game/ui/fonts/PaytoneOne-Regular.ttf'


def extract():
    im = Image.open(HERE / 'raw/kiem-iteration-2.png').convert('RGB')
    a = np.asarray(im)
    # Only remove near-white pixels connected to the outside, protecting steel.
    candidate = (a.min(2) > 229) & (a.max(2).astype(int)-a.min(2) < 28)
    seen = np.zeros(candidate.shape, bool)
    q = deque()
    h,w = seen.shape
    for x in range(w):
        for y in (0,h-1):
            if candidate[y,x]: seen[y,x]=True; q.append((x,y))
    for y in range(h):
        for x in (0,w-1):
            if candidate[y,x] and not seen[y,x]: seen[y,x]=True; q.append((x,y))
    while q:
        x,y=q.popleft()
        for xx,yy in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
            if 0<=xx<w and 0<=yy<h and candidate[yy,xx] and not seen[yy,xx]:
                seen[yy,xx]=True; q.append((xx,yy))
    im=im.convert('RGBA'); im.putalpha(Image.fromarray((~seen).astype('uint8')*255))
    im.save(OUT/'kiem-alpha-original.png')
    # Five broad material classes, sampled from this generation, far apart in RGB.
    # No threshold on blade luminance, smoothing, morphological halo, or redraw.
    centers=np.array([[96,63,23],[207,218,222],[152,175,185],[225,172,79],[180,114,73]],float)
    colors=np.array([[88,63,33],[214,224,227],[164,182,191],[223,172,88],[184,121,74]],np.uint8)
    idx=np.argmin(((a.astype(float)[:,:,None,:]-centers[None,None,:,:])**2).sum(3),2)
    flat=Image.fromarray(colors[idx]).convert('RGBA'); flat.putalpha(im.getchannel('A'))
    flat.save(OUT/'kiem.png')
    return flat


def hold(sword, angle=-32, height=175):
    ratio=height*3/sword.getbbox()[3]
    sw=sword.resize((round(sword.width*ratio),round(sword.height*ratio)),Image.Resampling.LANCZOS)
    # Grip center is measured on this generation, not inherited from V3.
    grip=(512*ratio,794*ratio)
    rotated=sw.rotate(angle,Image.Resampling.BICUBIC,expand=True)
    dx,dy=grip[0]-sw.width/2,grip[1]-sw.height/2
    theta=math.radians(angle)
    gx=math.cos(theta)*dx+math.sin(theta)*dy+rotated.width/2
    gy=-math.sin(theta)*dx+math.cos(theta)*dy+rotated.height/2
    x,y=round(160*3-gx),round(166*3-gy)
    base=Image.open(SOURCE/'cat_kiem.png').convert('RGBA')
    base.alpha_composite(rotated,(x,y))
    base.alpha_composite(Image.open(SOURCE/'front-paw.png').convert('RGBA'))
    bbox=rotated.getbbox()
    bounds=[x+bbox[0],y+bbox[1],x+bbox[2],y+bbox[3]]
    assert 0 <= bounds[0] < bounds[2] <= base.width and 0 <= bounds[1] < bounds[3] <= base.height, bounds
    return base,dict(angle_degrees=angle,unrotated_height_unit_px=height,
                     source_grip=[512,794],unit_grip=[160,166],front_paw_occlusion=True,
                     weapon_bounds_unit_px=[round(v/3,2) for v in bounds])


def font(size): return ImageFont.truetype(str(FONT),size)


def paste(im, source, box):
    if isinstance(source,Path): source=Image.open(source).convert('RGBA')
    ratio=min(box[2]/source.width,box[3]/source.height)
    source=source.resize((round(source.width*ratio),round(source.height*ratio)),Image.Resampling.LANCZOS)
    im.alpha_composite(source,(round(box[0]+(box[2]-source.width)/2),round(box[1]+(box[3]-source.height)/2)))


def main():
    OUT.mkdir(exist_ok=True)
    sword=extract()
    sword.crop(sword.getbbox()).save(OUT/'kiem-cropped.png')
    unit,placement=hold(sword)
    unit.save(OUT/'unit_kiem.png')
    unit.resize((128,120),Image.Resampling.LANCZOS).save(OUT/'unit_kiem_128.png')
    board=Image.new('RGBA',(1120,800),BG); d=ImageDraw.Draw(board)
    d.text((32,18),'KIẾM · BẢN THỬ 04',font=font(32),fill=INK)
    d.text((32,69),'Kiếm cầm tăng 52% · Giữ nguyên thiết kế và nét gốc',font=font(19),fill=INK)
    d.rounded_rectangle((32,116,380,632),24,fill='#f5ecd9')
    d.rounded_rectangle((402,116,1088,632),24,fill='#edf1e7')
    d.text((60,132),'Kiếm rời',font=font(22),fill=INK)
    d.text((432,132),'Ghép lên mèo hiện tại',font=font(22),fill=INK)
    cropped=sword.crop(sword.getbbox())
    paste(board,cropped,(60,181,292,420))
    paste(board,unit,(456,181,590,423))
    d.text((32,664),'128 × 120',font=font(18),fill=INK)
    board.alpha_composite(Image.open(OUT/'unit_kiem_128.png').convert('RGBA'),(220,652))
    d.text((392,667),'Giữ nguyên nhân vật, đặt cán sau bàn chân.',font=font(18),fill=INK)
    d.text((392,705),'Mẫu để duyệt · Chưa thay asset trong game',font=font(18),fill=INK)
    board.convert('RGB').save(HERE/'sword-v4-review.png')
    # Pose contact sheet is private QA, not the approval deliverable.
    poses=Image.new('RGBA',(1024,720),BG); pd=ImageDraw.Draw(poses)
    for i,(angle,height) in enumerate([(-35,110),(-42,112),(-50,115),(-55,110)]):
        u,p=hold(sword,angle,height)
        paste(poses,u,(i%2*512,i//2*360,512,320))
        pd.text((i%2*512+10,i//2*360+320),f'{angle} deg / {height}px',font=font(18),fill=INK)
    poses.convert('RGB').save(HERE/'pose-contact-sheet.png')
    (HERE/'processing.json').write_text(json.dumps(dict(status='awaiting_user_review',
        selected_iteration=2,user_feedback='8/10 on iteration 2',production_changed=False,
        background='connected exterior near-white extraction',colors='five flat material fields',
        contour='original generated contour; no added dilation',placement=placement,
        user_scale_request='Larger whole weapon to fit the cat contour; 175 vs previous 115 unit height (+52.2%)',
        source_cat='../v3-ai/held-sources/cat_kiem.png',
        outputs=['processed/kiem.png','processed/unit_kiem.png','processed/unit_kiem_128.png','sword-v4-review.png']),
        ensure_ascii=False,indent=2),encoding='utf-8')
    print('V4_REVIEW_PREPARED')


if __name__=='__main__': main()
