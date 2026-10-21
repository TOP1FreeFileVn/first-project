"""Measure and show assembly without touching production files."""
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
manifest=json.loads((HERE/'manifest.json').read_text())
FONT='C:/Windows/Fonts/arial.ttf'
font=ImageFont.truetype(FONT,22)
small=ImageFont.truetype(FONT,17)
board=Image.new('RGB',(1120,1832),'#f3ede2')
draw=ImageDraw.Draw(board)
draw.text((24,16),'CAT LOWER FEET / VECTOR ATTACHMENTS',font=font,fill='#583f21')
for i,label in enumerate(['Source pose','Separated assembly','Exploded / feet independent']):
    draw.text((24+i*368,56),label,font=small,fill='#583f21')
metrics={}
attachment_bounds={}
for row,(cat,entry) in enumerate(manifest['cats'].items()):
    folder=HERE/'png'/cat
    original=np.array(Image.open(folder/'original.png').convert('RGBA')).astype(np.int16)
    assembled=np.array(Image.open(folder/'assembled.png').convert('RGBA')).astype(np.int16)
    # Transparent RGB values do not influence an actual rendered comparison.
    premult_original=original[:,:,:3]*original[:,:,3,None]/255.0
    premult_assembled=assembled[:,:,:3]*assembled[:,:,3,None]/255.0
    delta=np.max(np.abs(premult_original-premult_assembled),axis=2)
    alpha_delta=np.abs(original[:,:,3]-assembled[:,:,3])
    visible=np.maximum(original[:,:,3],assembled[:,:,3])>0
    metrics[cat]={
        'render_scale':3,'pixel_dimensions':[768,720],
        'visible_pixels':int(visible.sum()),
        'premult_rgb_mean_abs_0_255':round(float(np.abs(premult_original-premult_assembled).mean()),6),
        'visible_pixels_with_channel_delta_gt8':int(((delta>8)| (alpha_delta>8)).sum()),
        'fraction_visible_pixels_delta_gt8':round(float((((delta>8)|(alpha_delta>8))&visible).sum()/visible.sum()),6),
        'alpha_coverage_difference_px':int((assembled[:,:,3]>127).sum()-(original[:,:,3]>127).sum()),
    }
    attachment_bounds[cat]={}
    for layer in entry['layer_order_back_to_front']:
        bounds=Image.open(folder/f'{layer}.png').convert('RGBA').getchannel('A').getbbox()
        attachment_bounds[cat][layer]={'canvas_alpha_bounds_px':[round(v/3,3) for v in bounds],
                                      'render_alpha_bounds_px':list(bounds)}
    top=94+row*288
    draw.text((24,top),cat+' / '+str(entry['source_body_stroke_px'])+' px',font=small,fill='#583f21')
    for col,asset in enumerate(['original','assembled','exploded']):
        image=Image.open(folder/f'{asset}.png').convert('RGBA').resize((256,240),Image.Resampling.LANCZOS)
        board.paste(image,(24+col*368,top+28),image)
    # Show exact magnified difference in a dedicated transparent png, not the board.
    dif=np.zeros_like(original,dtype=np.uint8)
    hit=(delta>8)|(alpha_delta>8)
    dif[hit]=[234,73,91,255]
    Image.fromarray(dif,'RGBA').save(folder/'assembly-difference.png')
board.save(HERE/'review.png')
(HERE/'qa.json').write_text(json.dumps(metrics,indent=2)+'\n')
(HERE/'attachment-bounds.json').write_text(json.dumps(attachment_bounds,indent=2)+'\n')
print(json.dumps(metrics,indent=2))
