"""Independent geometry, face, fixed-layer, and PNG audit. No artwork edits."""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image

FOLDER = Path(__file__).resolve().parent.parent
POSES = ['melee', 'ranged', 'magic', 'heavy']
GEAR = ['helmet', 'armor', 'gloves', 'boots', 'amulet']
BOXES = {'brows': (86,78,170,92), 'eyes': (95,87,161,105), 'mouth': (106,106,150,124)}


def load(path):
    im = Image.open(FOLDER/path).convert('RGBA')
    assert im.size == (768,720), path
    return im


def main():
    head = load('sources/hero-head-noears.png')
    face = np.array(head)
    yy,xx = np.mgrid[:720,:768]
    ink = np.max(np.abs(face[:,:,:3].astype(int)-[59,42,26]),2) <= 1
    layers = {id:load(f'processed/layer_{id}.png') for id in GEAR}
    base = load('sources/hero-body.png')
    anchors = json.loads((FOLDER/'anchors.json').read_text('utf-8'))
    report = {'scope':'4 carry references and 5 fixed modular equipment layers',
              'production_modified':False, 'attack_animation_implemented':False,
              'failures':[], 'poses':[], 'layers':[]}
    for pose in POSES:
        unit = load(f'processed/hero_{pose}.png')
        a = np.array(unit)
        difference = np.max(np.abs(face.astype(int)-a.astype(int)),2)>4
        face_report = {}
        for part,(x1,y1,x2,y2) in BOXES.items():
            mask = ink & (xx>=x1*3)&(xx<x2*3)&(yy>=y1*3)&(yy<y2*3)
            changed = int((mask&difference).sum())
            face_report[part] = {'source_ink_pixels':int(mask.sum()), 'covered_ink_pixels':changed}
            if changed:
                report['failures'].append(f'{pose}: {part} has {changed} covered source ink pixels')
        alpha = a[:,:,3]
        edge = int((alpha[0]>32).sum()+(alpha[-1]>32).sum()+(alpha[:,0]>32).sum()+(alpha[:,-1]>32).sum())
        if edge:
            report['failures'].append(f'{pose}: opaque pixels on canvas edge')
        # Reconstruct from literally identical gear-layer PNGs and base, with
        # only the weapon changing. Equality proves no pose-specific refit.
        expected = base.copy()
        for id in ('boots','armor','amulet'):
            expected.alpha_composite(layers[id])
        expected.alpha_composite(head)
        expected.alpha_composite(layers['helmet'])
        expected.alpha_composite(load(f'processed/weapon_{pose}.png'))
        expected.alpha_composite(layers['gloves'])
        mismatch = int(np.any(np.array(expected)!=a,2).sum())
        if mismatch:
            report['failures'].append(f'{pose}: fixed-layer reconstruction differs in {mismatch} pixels')
        metadata = anchors['poses'][pose]
        if metadata['clipped']:
            report['failures'].append(f'{pose}: weapon bounds report clipping')
        report['poses'].append({'id':pose, 'face':face_report, 'edge_pixels':edge,
            'fixed_layer_reconstruction_mismatch_pixels':mismatch, 'weapon_bounds_unit_px':metadata['bounds'],
            'target_grip':metadata['target_grip'], 'sprite_alpha_bbox_source_px':list(unit.getbbox())})
    for id,layer in layers.items():
        bbox = layer.getbbox()
        icons = {}
        for size in (48,64,96):
            p = FOLDER/f'processed/icon_{id}_{size}.png'
            icon = Image.open(p)
            assert icon.mode=='RGBA' and icon.size==(size,size), str(p)
            icons[str(size)] = list(icon.getbbox())
        report['layers'].append({'id':id, 'canvas':[768,720], 'bbox_unit_px':[v/3 for v in bbox],
            'sha256':hashlib.sha256(layer.tobytes()).hexdigest(), 'icon_alpha_bboxes':icons})
    native = FOLDER/'native-qa/status.json'
    report['native'] = json.loads(native.read_text('utf-8')) if native.exists() else None
    report['passed'] = not report['failures']
    (FOLDER/'qa.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps({'passed':report['passed'], 'failures':report['failures']}))


if __name__=='__main__':
    main()
