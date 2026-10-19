"""Independent read-only geometry/face audit of the reviewed weapon set.

Only writes independent-qa.json. Artwork, poses, and builder stay untouched.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image

FOLDER = Path(__file__).resolve().parent.parent
IDS = [
    'kiem', 'riu', 'dao', 'katana', 'cung', 'no', 'sung', 'dai_bac',
    'gay_phep', 'thuoc', 'sach_phep', 'dua_phep', 'giao', 'cu_kiem', 'chuy', 'bua',
]
FACE_BOXES = {
    'left_eye': (95, 87, 113, 105),
    'right_eye': (143, 87, 161, 105),
    'mouth': (106, 106, 150, 124),
}


def main():
    report = {
        'scope': '15 new weapons plus accepted sword baseline',
        'method': 'Compare original face-ink pixels against composed PNG at 3x source size; '
                  'load all unit/icon PNGs; inspect native viewport screenshot separately.',
        'production_modified': False,
        'items': [],
        'failures': [],
    }
    for id in IDS:
        unit_path = FOLDER / 'processed' / f'unit_{id}.png'
        cat_path = FOLDER / 'sources' / f'cat_{id}.png'
        icon_path = FOLDER / 'processed' / f'icon_w_{id}_48.png'
        if not all(p.exists() for p in (unit_path, cat_path, icon_path)):
            report['failures'].append(f'{id}: missing unit, source cat, or 48px icon')
            continue
        unit = np.array(Image.open(unit_path).convert('RGBA'))
        source = np.array(Image.open(cat_path).convert('RGBA'))
        icon = Image.open(icon_path).convert('RGBA')
        assert unit.shape == source.shape == (720, 768, 4), id
        assert icon.size == (48, 48), id
        yy, xx = np.mgrid[:720, :768]
        source_face_ink = np.max(np.abs(source[:, :, :3].astype(int) - [59, 42, 26]), axis=2) <= 1
        difference = np.max(np.abs(unit.astype(int) - source.astype(int)), axis=2) > 4
        face = {}
        for part, (x1, y1, x2, y2) in FACE_BOXES.items():
            mask = source_face_ink & (xx >= x1*3) & (xx < x2*3) & (yy >= y1*3) & (yy < y2*3)
            changed = int((mask & difference).sum())
            face[part] = {'original_ink_pixels': int(mask.sum()), 'covered_ink_pixels': changed}
            if changed and id != 'kiem':
                report['failures'].append(f'{id}: {part} has {changed} covered ink pixels')
        alpha = unit[:, :, 3]
        introduced_alpha = (alpha > 32) & (source[:, :, 3] <= 32)
        edge_pixels = int(introduced_alpha[0].sum() + introduced_alpha[-1].sum()
                          + introduced_alpha[:, 0].sum() + introduced_alpha[:, -1].sum())
        if edge_pixels:
            report['failures'].append(f'{id}: newly introduced opaque pixels meet canvas edge')
        metadata_path = FOLDER / 'processed' / f'{id}.json'
        metadata = json.loads(metadata_path.read_text('utf-8')) if metadata_path.exists() else {}
        placement = metadata.get('placement', {})
        if placement.get('clipping', False):
            report['failures'].append(f'{id}: builder reports clipping')
        report['items'].append({
            'id': id, 'unit_size': [768, 720], 'icon_size': [48, 48],
            'face_ink_coverage': face, 'new_opaque_pixels_on_canvas_edge': edge_pixels,
            'placement_bounds_unit_px': placement.get('weapon_bounds_unit_px'),
            'builder_clipping': placement.get('clipping'),
            'accepted_baseline': id == 'kiem',
        })
    report['complete_items'] = len(report['items'])
    report['expected_items'] = len(IDS)
    native_path = FOLDER / 'native' / 'review_native_status.json'
    report['native_runtime'] = json.loads(native_path.read_text('utf-8')) if native_path.exists() else None
    report['passed_geometry_and_face_audit'] = not report['failures'] and len(report['items']) == 16
    (FOLDER / 'independent-qa.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps({'complete': report['complete_items'], 'passed': report['passed_geometry_and_face_audit'],
                      'failures': report['failures']}, ensure_ascii=False))


if __name__ == '__main__':
    main()
