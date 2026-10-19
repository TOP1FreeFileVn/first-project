"""Measure the held sword, then change only the native cat's outline widths."""
from pathlib import Path
import importlib.util
import json
import math
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
PREVIOUS=HERE.parent/'v4-sword'
SOURCES=HERE.parent/'v3-ai/held-sources'
ROOT=HERE.parents[4]
INK=np.array([88,63,33])
FONT=ROOT/'game/ui/fonts/PaytoneOne-Regular.ttf'
ET.register_namespace('', 'http://www.w3.org/2000/svg')


def measure_sword():
    image=Image.open(PREVIOUS/'processed/kiem.png').convert('RGBA')
    a=np.array(image)
    mask=(np.linalg.norm(a[:,:,:3].astype(float)-INK,axis=2)<15)&(a[:,:,3]>128)
    samples=[]
    for y in range(260,581,16):
        row=mask[y]
        runs=[]
        start=None
        for x in range(280,741):
            if row[x] and start is None: start=x
            elif not row[x] and start is not None:
                runs.append((start,x));start=None
        assert len(runs)==3,(y,runs)
        samples.append(dict(y=y,left=runs[0],right=runs[-1]))
    slopes={side:float(np.polyfit([s['y'] for s in samples],
           [sum(s[side])/2 for s in samples],1)[0]) for side in ('left','right')}
    scale=175/image.getbbox()[3]
    widths=[]
    for s in samples:
        for side in ('left','right'):
            width=(s[side][1]-s[side][0])/math.sqrt(1+slopes[side]**2)
            widths.append(width*scale)
    target=float(np.median(widths))
    result=dict(method='42 normal-to-edge samples on straight blade edges; center divider excluded',
        source_scale_to_unit=scale,samples=samples,slopes=slopes,
        sword_unit_width_median=target,sword_unit_width_min=float(min(widths)),
        sword_unit_width_max=float(max(widths)),native_128_width=target/2,
        cat_before_unit_width=12,cat_after_svg_unit_width=target)
    (HERE/'measurement.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    return target


def prepare():
    (HERE/'sources').mkdir(parents=True,exist_ok=True)
    (HERE/'processed').mkdir(exist_ok=True)
    target=measure_sword()
    edits=[]
    for name in ('cat_kiem','front-paw'):
        tree=ET.parse(SOURCES/f'{name}.svg')
        for node in tree.iter():
            if node.get('stroke')=='#583f21':
                old=float(node.get('stroke-width'))
                # The tail uses a dark under-stroke plus a 13px coat stroke.
                # Each visible edge is half their difference, not width 30.
                width=13+2*target if old==30 else target
                node.set('stroke-width',f'{width:.6f}')
                edits.append(dict(source=name,before=old,after=width))
        tree.write(HERE/'sources'/f'{name}.svg',encoding='utf-8',xml_declaration=True)
    (HERE/'stroke-edits.json').write_text(json.dumps(edits,indent=2),encoding='utf-8')
    print('TARGET_OUTLINE_UNIT_PX',target,'NATIVE_128',target/2)


def compose():
    spec=importlib.util.spec_from_file_location('v4_review',PREVIOUS/'prepare_review.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    module.SOURCE=HERE/'sources'
    unit,placement=module.hold(Image.open(PREVIOUS/'processed/kiem.png').convert('RGBA'))
    unit.save(HERE/'processed/unit_kiem.png')
    unit.resize((128,120),Image.Resampling.LANCZOS).save(HERE/'processed/unit_kiem_128.png')
    # Measure rasterized helmet crown after Godot at 3x; curve is nearly level here.
    cat=np.array(Image.open(HERE/'sources/cat_kiem.png').convert('RGBA'))
    mask=(np.linalg.norm(cat[:,:,:3].astype(float)-INK,axis=2)<25)&(cat[:,:,3]>128)
    widths=[]
    for x in range(126*3,131*3):
        ys=np.where(mask[20:85,x])[0]
        assert len(ys)>0
        widths.append(len(ys)/3)
    measurement=json.loads((HERE/'measurement.json').read_text())
    # Antialias-aware coverage recovers fractional pixel widths; a binary
    # threshold would round this 6.22px contour to 6px on the 3x fixture.
    rgba=cat.astype(float)
    fill=np.array([201,211,221],float)
    delta=INK-fill
    coverage=np.clip(((rgba[20:85,378:393,:3]-fill)*delta).sum(2)/(delta*delta).sum(),0,1)
    coverage*=rgba[20:85,378:393,3]/255
    actual=float(np.median(coverage.sum(0)/3))
    measurement.update(cat_rendered_binary_threshold_width=float(np.median(widths)),
        cat_rendered_crown_unit_width_median=actual,
        rendered_measurement='ink coverage fraction along near-horizontal crown normal, including antialias alpha',
        actual_difference_unit_px=abs(actual-measurement['sword_unit_width_median']),
        actual_difference_native_128_px=abs(actual-measurement['sword_unit_width_median'])/2,
        match_tolerance_unit_px=0.02,
        match_passed=abs(actual-measurement['sword_unit_width_median'])<=0.02)
    assert measurement['match_passed'],measurement
    (HERE/'measurement.json').write_text(json.dumps(measurement,indent=2),encoding='utf-8')
    board=Image.new('RGBA',(1120,820),'#d8e5df');d=ImageDraw.Draw(board)
    def f(size): return ImageFont.truetype(str(FONT),size)
    d.text((32,18),'MÈO · CÂN NÉT VỚI KIẾM',font=f(32),fill='#583f21')
    target=measurement['sword_unit_width_median']
    d.text((32,69),f'Nét mèo giảm từ 12 còn {target:.2f} px · Nét kiếm: {target:.2f} px (canvas 256 × 240)',font=f(19),fill='#583f21')
    for i,(label,path) in enumerate([('Trước: mèo nét 12 px',PREVIOUS/'processed/unit_kiem.png'),
                                    (f'Sau: mèo nét {target:.2f} px',HERE/'processed/unit_kiem.png')]):
        x=32+i*540
        d.rounded_rectangle((x,118,x+516,650),24,fill='#edf1e7')
        d.text((x+24,135),label,font=f(23),fill='#583f21')
        module.paste(board,path,(x+10,190,496,430))
        small=Image.open(path).convert('RGBA').resize((128,120),Image.Resampling.LANCZOS)
        board.alpha_composite(small,(x+194,668))
    d.text((32,677),'128 × 120',font=f(16),fill='#583f21')
    board.convert('RGB').save(HERE/'cat-stroke-review.png')
    (HERE/'processing.json').write_text(json.dumps(dict(status='awaiting_user_review',
        production_changed=False,weapon_changed=False,cat_change='warm brown outline widths only',
        face_and_marks='unchanged source geometry and facial strokes',placement=placement,
        measurement_file='measurement.json'),indent=2),encoding='utf-8')
    print(json.dumps(measurement,indent=2))


if __name__=='__main__':
    import sys
    prepare() if '--prepare' in sys.argv else compose()
