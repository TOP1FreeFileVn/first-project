"""Retain generated silhouette concept; manually author broad fills and main line.

No automatic dilation, morphology, skeletonization, or region-edge tracing.
"""
from pathlib import Path
import json
import math
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'processed'
OUT.mkdir(exist_ok=True)
raw=np.asarray(Image.open(ROOT/'raw/heavy-axe.png').convert('RGB')).astype(float)
src=np.array([[100,59,21],[210,220,226],[157,174,184],[228,172,77],[202,124,37],[229,111,82],[148,69,51]],dtype=float)
dst=np.array([[88,63,33],[214,224,227],[164,182,191],[223,172,88],[184,123,66],[231,120,91],[152,78,57]],dtype=np.uint8)
labels=((raw[:,:,None,:]-src[None,None,:,:])**2).sum(3).argmin(2)
yy,xx=np.indices(raw.shape[:2])
wrap=(xx>325)&(xx<455)&(yy>600)&(yy<900)&(raw[:,:,0]>110)&(raw[:,:,1]<100)&(raw[:,:,2]>30)
labels[wrap]=6
rgba=np.zeros((*raw.shape[:2],4),dtype=np.uint8)
rgba[:,:,:3]=dst[labels];rgba[:,:,3]=255
white=raw.min(2)>238;rgba[white,3]=0
edge=(raw.min(2)>135)&(raw[:,:,0]>raw[:,:,2]+3)&(raw[:,:,1]>raw[:,:,2])&~white
alpha=np.clip((255-raw[:,:,2])/(255-src[0,2]),0,1)
rgba[edge,:3]=dst[0];rgba[edge,3]=np.round(alpha[edge]*255).astype(np.uint8)
Image.fromarray(rgba,'RGBA').save(OUT/'heavy-axe-generated-clean.png')

# Deliberate Bezier refinement of the generated axe: keep broad hooked beard,
# asymmetric cutting belly, straight stout shaft, brass socket, coral wrap.
# Broaden shaft/steel fills together with9-unit main contours at final native use.
blade='M51 40 C63.6 41 75.3 36 82.5 29 Q86.1 25 87.9 31 C96.9 50 96 72 81.6 88 C76.2 94 68.1 97 63.6 97 Q61.8 96 63.6 91 C73.5 71 66.3 61 51 61 Z'
art=f'''<defs><clipPath id="steel"><path d="{blade}"/></clipPath></defs>
<g stroke="#583f21" stroke-width="9" stroke-linejoin="round" stroke-linecap="round">
<path d="M32 27 Q40 23 48 27 L49 111 Q50 133 48 153 Q40 158 31 153 L32 110 Q34 68 32 27Z" fill="#b87b42"/>
<path d="M31 149 Q40 147 49 149 L50 160 Q50 168 40 168 Q29 168 30 160Z" fill="#dfac58"/>
<path d="M31 110 Q40 108 49 110 Q51 119 49 128 Q51 141 48 152 Q40 156 31 152 Q29 140 31 130 Q29 119 31 110Z" fill="#e7785b"/>
</g>
<path d="M32 126 Q40 125 48 120 M32 143 Q40 142 48 137" fill="none" stroke="#984e39" stroke-width="2.4" stroke-linecap="round"/>
<path d="{blade}" fill="#d6e0e3"/>
<g clip-path="url(#steel)"><path d="M51 40 C63.6 42 73.5 38 82.5 34 C88.8 58 83.4 74 64.5 91 C72.6 72 64.5 61 51 61Z" fill="#a4b6bf"/></g>
<path d="{blade}" fill="none" stroke="#583f21" stroke-width="9" stroke-linejoin="round" stroke-linecap="round"/>
<path d="M31 37 Q40 35 49 37 L50 62 Q40 65 30 61Z" fill="#dfac58" stroke="#583f21" stroke-width="9" stroke-linejoin="round"/>
<path d="M33 57 Q40 59 47 57" fill="none" stroke="#ac7d32" stroke-width="2.3" stroke-linecap="round"/>
'''
def svg(width,height,view,content):return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="{view}">{content}</svg>'
(OUT/'heavy-axe-authored.svg').write_text(svg(440,720,'0 0 110 180',art),encoding='utf-8')
held=f'<g transform="translate(160 166) rotate(27) translate(-40 -128)">{art}</g>'
(OUT/'heavy-axe-held.svg').write_text(svg(768,720,'0 0 256 240',held),encoding='utf-8')
info=dict(model='gpt-image-2.5-sunburst',generation_node='56:2',generated_clean='processed/heavy-axe-generated-clean.png',refinement='Manual Bezier authoring preserving generated bearded-head concept; proportions, broad fills, and line hierarchy deliberately refined. NOT automatic dilation, morphology, skeletonization, tracing or segmented-boundary reconstruction.',source_svg='processed/heavy-axe-authored.svg',source_canvas=[440,720],authoring_viewbox=[0,0,110,180],main_stroke_author_units=9,main_stroke_source_pixels=36,held_svg='processed/heavy-axe-held.svg',held_canvas=[256,240],render_scale=3,grip_author_units=[40,128],target_grip=[160,166],rotation_clockwise_degrees=27,main_stroke_native_units=9,wrap_seam_native_units=2.4,socket_surface_line_native_units=2.3,steel_planes='Broad flat fills, unlined shared boundary.',generated_main_note='Generated source had only~20-24pxcontour at1024 and did not pass fitted main-line target; manual refinement is disclosed separately.')
(ROOT/'processing.json').write_text(json.dumps(info,indent=2),encoding='utf-8')
print(json.dumps(info,indent=2))
