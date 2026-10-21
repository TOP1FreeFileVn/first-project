"""Record rendered bounds and a source-front/rear registration comparison."""
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
front=Image.open(ROOT/'docs/design/2026-10-20/cat-spine-parts/png/cat_tabby/original.png').convert('RGBA')
rear=Image.open(HERE/'png/assembled_rear.png').convert('RGBA')
front_a=np.array(front.getchannel('A'))
rear_a=np.array(rear.getchannel('A'))
data={'render_scale':3,'canvas':[256,240],'ground_origin':[128,238],
      'front_vs_rear_alpha_coverage_delta':int((rear_a>127).sum()-(front_a>127).sum()),
      'changed_alpha_pixels':int((front_a!=rear_a).sum()),'layers':{}}
for file in sorted((HERE/'png').glob('*.png')):
    bounds=Image.open(file).convert('RGBA').getchannel('A').getbbox()
    data['layers'][file.stem]={'alpha_bounds_render_px':list(bounds),
                              'alpha_bounds_logical_px':[round(v/3,3) for v in bounds]}
(HERE/'qa-bounds.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
board=Image.new('RGB',(720,440),'#f3ede2')
draw=ImageDraw.Draw(board)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
draw.text((24,16),'Native front / pilot rear',fill='#583f21',font=font)
for x,img,label in [(40,front,'Front source unchanged'),(400,rear,'Rear with original contour')]:
    draw.text((x,60),label,fill='#583f21',font=small)
    part=img.resize((256,240),Image.Resampling.LANCZOS)
    board.paste(part,(x,100),part)
    draw.line((x,338,x+256,338),fill='#b59264',width=1)
draw.text((24,368),'256 x 240 / floor (128,238) / main outline 12 px',fill='#583f21',font=small)
draw.text((24,397),'Pose preparation only; walk timing is driven by the pilot scene.',fill='#583f21',font=small)
board.save(HERE/'front-rear-review.png')
print(json.dumps(data,indent=2))
