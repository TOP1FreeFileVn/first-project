from pathlib import Path
import json
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
TARGET=ROOT/'game/assets/battle/cat-drive'
spec=json.loads((TARGET/'source.json').read_text(encoding='utf8'))
size,pad=spec['frame_size'],spec['padding']
stride=size+2*pad
atlas=Image.new('RGBA',(spec['columns']*stride,spec['rows']*stride))
for i in range(spec['frames']):
    im=Image.open(ROOT/f'output/cat-drive-build/png/cat-{i:03d}.png').convert('RGBA')
    assert im.size==(size,size)
    bounds=im.getbbox()
    assert bounds and bounds[0]>pad and bounds[1]>pad and bounds[2]<size-pad and bounds[3]<size-pad,(i,bounds)
    # Poses have transparent clearance at every edge, plus a 2px gutter.
    atlas.paste(im,((i%spec['columns'])*stride+pad,(i//spec['columns'])*stride+pad))
atlas.save(TARGET/'cat_poses.png',optimize=True)
print(f'Packed {spec["frames"]} poses: {atlas.width}x{atlas.height}; all alpha bounds clear.')
