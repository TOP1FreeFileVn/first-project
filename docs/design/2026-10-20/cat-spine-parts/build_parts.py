"""Review-only vector repartition of existing cats; never touches production art.

All attachments keep a 256 x 240 canvas. The two lower feet get real filled
overlap geometry; forepaws remain the original separate C-shaped strokes.
"""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
NS = 'http://www.w3.org/2000/svg'
ET.register_namespace('', NS)
def tag(name): return f'{{{NS}}}{name}'
BODY = ('M76 116 L180 116 Q206 116 208 150 L212 204 Q213 232 184 232 '
        'Q156 234 145 221 Q128 206 111 221 Q100 234 72 232 Q43 232 44 204 '
        'L48 150 Q50 116 76 116 Z')
TORSO = ('M76 116 L180 116 Q206 116 208 150 L212 204 L145 204 L145 221 '
         'Q128 206 111 221 L111 204 L44 204 L48 150 Q50 116 76 116 Z')
UPPER_INK = 'M44 204 L48 150 Q50 116 76 116 L180 116 Q206 116 208 150 L212 204'
NOTCH = 'M145 221 Q128 206 111 221'
FOOT_L = 'M44 204 Q43 232 72 232 Q100 234 111 221 L123 204 L123 184 L56 184 Z'
FOOT_R = 'M145 221 Q156 234 184 232 Q213 232 212 204 L200 184 L133 184 L133 204 Z'
INK_L = 'M44 204 Q43 232 72 232 Q100 234 111 221'
INK_R = 'M145 221 Q156 234 184 232 Q213 232 212 204'
PAW_L = 'M104 152 Q114 166 106 174 Q97 181 84 172'
PAW_R = 'M152 152 Q142 166 150 174 Q159 181 172 172'
SOURCES = {f'cat_{kind}': ROOT / f'game/ui/skin/cat_{kind}.svg'
           for kind in ('cream', 'tabby', 'grey', 'calico', 'hero')}
SOURCES['hero_neutral_9px'] = ROOT / 'docs/design/2026-10-19/hero-equipment/sources/hero-neutral.svg'

def path(d, **attrs):
    return ET.Element(tag('path'), {'d': d, **{k.replace('_', '-'): str(v) for k,v in attrs.items()}})

def svg(defs, groups):
    out = ET.Element(tag('svg'), dict(width='256', height='240', viewBox='0 0 256 240'))
    out.append(copy.deepcopy(defs))
    for group in groups: out.append(copy.deepcopy(group))
    return ET.tostring(out, encoding='unicode') + '\n'

def write_svg(file, defs, groups):
    file.parent.mkdir(parents=True, exist_ok=True)
    file.write_text(svg(defs, groups), encoding='utf-8')

def split_cat(name, source):
    original = ET.parse(source).getroot()
    defs = copy.deepcopy(original.find(tag('defs')))
    children = [e for e in original if e.tag != tag('defs')]
    # Semantic layer names body/head must not shadow original clipPath IDs.
    for e in defs.iter():
        if e.get('id') in ('head', 'body'):
            e.set('id', 'source_'+e.get('id'))
    for child in children:
        for e in child.iter():
            if e.get('clip-path') in ('url(#head)', 'url(#body)'):
                e.set('clip-path', e.get('clip-path').replace('url(#','url(#source_'))
    first_body = next(i for i,e in enumerate(children) if e.get('d') == BODY)
    first_head = next(i for i,e in enumerate(children[first_body+1:], first_body+1)
                      if e.get('d', '').startswith(('M46 90', 'M128 34 C196')))
    groups = {}
    def new_group(key):
        g=ET.Element(tag('g'), {'id': key, 'data-name': key}); groups[key]=g; return g
    tail = new_group('tail')
    for e in children[:2]: tail.append(copy.deepcopy(e))
    if first_body > 2:
        back = new_group('back_accessories')
        for e in children[2:first_body]: back.append(copy.deepcopy(e))
    left, right, torso = (new_group(k) for k in ('foot_L_image', 'foot_R_image', 'body'))
    geometries = [('foot_L_image', left, FOOT_L, [INK_L]),
                  ('foot_R_image', right, FOOT_R, [INK_R]),
                  ('body', torso, TORSO, [UPPER_INK, NOTCH])]
    for key, group, fill_shape, strokes in geometries:
        clip=ET.SubElement(defs, tag('clipPath'), {'id': f'rig_{key}'})
        clip.append(path(fill_shape))
    paw_left, paw_right = new_group('paw_L_image'), new_group('paw_R_image')
    for e in children[first_body:first_head]:
        d=e.get('d')
        if d == BODY:
            for key, group, fill_shape, strokes in geometries:
                if e.get('fill', 'black') != 'none':
                    group.append(path(fill_shape, fill=e.get('fill', 'black')))
                if e.get('stroke', 'none') != 'none':
                    attrs={k:v for k,v in e.attrib.items() if k.startswith('stroke')}
                    for contour in strokes:
                        group.append(ET.Element(tag('path'), {'d': contour, 'fill':'none', **attrs}))
        elif e.get('clip-path') == 'url(#source_body)':
            for key, group, fill_shape, strokes in geometries:
                clipped=ET.SubElement(group, tag('g'), {'clip-path': f'url(#rig_{key})'})
                clipped.append(copy.deepcopy(e))
        elif d in (PAW_L, PAW_R):
            (paw_left if d == PAW_L else paw_right).append(copy.deepcopy(e))
        else:
            torso.append(copy.deepcopy(e))
    head=new_group('head')
    for e in children[first_head:]: head.append(copy.deepcopy(e))
    destination=HERE / 'svg' / name
    for key, group in groups.items(): write_svg(destination / f'{key}.svg', defs, [group])
    write_svg(destination / 'assembled.svg', defs, groups.values())
    # Exploded layout and a deliberately modest foot motion for seam inspection.
    exploded=[]
    for key,g in groups.items():
        g=copy.deepcopy(g)
        offset={'foot_L_image':(-40,0), 'foot_R_image':(40,0), 'head':(0,-4)}.get(key,(0,0))
        if any(offset): g.set('transform', f'translate({offset[0]} {offset[1]})')
        exploded.append(g)
    write_svg(destination / 'exploded.svg', defs, exploded)
    swing=[]
    for key,g in groups.items():
        g=copy.deepcopy(g)
        if key=='foot_L_image': g.set('transform', 'translate(0 -4) rotate(10 82 203)')
        if key=='foot_R_image': g.set('transform', 'rotate(-10 174 203)')
        swing.append(g)
    write_svg(destination / 'overlap-test.svg', defs, swing)
    return {'source':source.relative_to(ROOT).as_posix(),
            'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
            'source_body_stroke_px':float(children[first_body].get('stroke-width')),
            'layer_order_back_to_front':list(groups),
            'directory':destination.relative_to(HERE).as_posix()}

def main():
    manifest={'canvas':[256,240], 'scope':'Review-only Figma/Spine preparation; no production art edits.',
              'naming':'L/R are image left/right, not anatomical left/right.',
              'pivots_canvas_px': {'foot_L_image':[82,203], 'foot_R_image':[174,203],
                                   'body':[128,176], 'head':[128,121], 'tail':[182,210],
                                   'paw_L_image':[94,166], 'paw_R_image':[162,166]},
              'feet_hidden_top_y':184,
              'feet_contour_start_y':204,
              'rig_note':'Open foot contours retain original curves. Upper foot fills overlap behind torso without new cut strokes. Small-motion proof only; no Spine skeleton or animation authored.',
              'cats':{name:split_cat(name, source) for name, source in SOURCES.items()}}
    (HERE/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    print(f'Wrote {len(SOURCES)} separated cats to {HERE / "svg"}')

if __name__=='__main__': main()
