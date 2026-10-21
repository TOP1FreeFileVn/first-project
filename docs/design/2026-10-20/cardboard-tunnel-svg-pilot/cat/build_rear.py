"""Minimal authored rear tabby for the isolated tunnel pilot.

Keeps the native silhouette, palette, outline and attachment registration.
No production assets or approved front-pose parts are changed.
"""
from __future__ import annotations
import copy
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
SOURCES=ROOT/'docs/design/2026-10-20/cat-spine-parts/svg/cat_tabby'
NS='http://www.w3.org/2000/svg'
ET.register_namespace('',NS)
def tag(n): return f'{{{NS}}}{n}'

def main():
    layers=[]
    source_hashes={}
    for name in ('tail','foot_L_image','foot_R_image','body','head'):
        source=SOURCES/f'{name}.svg'
        source_hashes[name]=hashlib.sha256(source.read_bytes()).hexdigest()
        root=ET.parse(source).getroot()
        if name=='head':
            group=root.find(tag('g'))
            group.set('id','head_rear')
            group.set('data-name','head_rear')
            for e in list(group):
                # Dot eyes and mouth are front-facing features; inner ears face away.
                if e.tag==tag('circle') or e.get('stroke')=='#3b2a1a' or e.get('fill')=='#f6b8b0':
                    group.remove(e)
                elif e.get('clip-path')=='url(#source_head)':
                    # Keep side-coat marks; lengthen the three crown stripes down
                    # the back of the skull without adding new silhouette ink.
                    for stripe in e:
                        d=stripe.get('d','')
                        for x in (112,128,144):
                            if d==f'M{x} 34 L{x} 54': stripe.set('d',f'M{x} 34 L{x} 76')
            destination=HERE/'head_rear.svg'
        else:
            destination=HERE/f'{name}.svg'
        destination.write_text(ET.tostring(root,encoding='unicode')+'\n',encoding='utf-8')
        layers.append((name,root))

    assembled=ET.Element(tag('svg'),dict(width='256',height='240',viewBox='0 0 256 240'))
    assembled.append(copy.deepcopy(layers[0][1].find(tag('defs'))))
    for name,root in layers:
        assembled.append(copy.deepcopy(root.find(tag('g'))))
    (HERE/'assembled_rear.svg').write_text(ET.tostring(assembled,encoding='unicode')+'\n',encoding='utf-8')
    manifest={
        'status':'isolated_pilot_art_not_approved_production_pose',
        'source': 'game/ui/skin/cat_tabby.svg',
        'parts_source':SOURCES.relative_to(ROOT).as_posix(),
        'source_part_sha256':source_hashes,
        'canvas':[256,240], 'ground_origin':[128,238],
        'main_outline_px':12,
        'layers_back_to_front':['tail','foot_L_image','foot_R_image','body','head_rear'],
        'foot_pivots':{'foot_L_image':[82,203],'foot_R_image':[174,203]},
        'head_pivot':[128,121],
        'authored_changes':['Remove visible face and pink inner ears for rear view.',
                            'Lengthen three crown fur stripes to form simple nape markings.',
                            'Omit front paw hook layers; retain native body, foot and tail vectors.'],
        'scope':'Rear pose and separable attachments only. No side pose, Spine skeleton or authored walk cycle.',
        'front_pose_rule':'Use untouched source cat-spine-parts/svg/cat_tabby parts when facing the viewer.',
        'alignment_rule':'All SVGs use the full256x240 canvas; visual offset from floor-root is(-128,-238).',
    }
    (HERE/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    print('Wrote rear tabby attachments and assembled_rear.svg')

if __name__=='__main__': main()
