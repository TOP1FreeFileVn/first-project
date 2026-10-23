"""Build flat courtyard SVG props and remove their old baked bitmap versions.

The original terrain and legacy foreground assets stay intact. Only small,
explicit prop masks are restored from surrounding lawn; all other pixels must
remain identical. Run before Godot import after changing these SVG definitions.
"""
from pathlib import Path
import hashlib
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'game/assets/lobby/cardboard'
PROPS = ART / 'props'
REVIEW = ROOT / 'docs/design/2026-10-23/courtyard-props-style'
INK = '#583f21'

POST = '''<svg xmlns="http://www.w3.org/2000/svg" width="160" height="184" viewBox="0 0 160 184">
<g stroke-linecap="round" stroke-linejoin="round">
  <ellipse cx="80" cy="175" rx="64" ry="6" fill="#583f21" opacity="0.14"/>
  <!-- Broad flat cardboard foot, like the castle's front plane and side band. -->
  <path d="M20 153 C20 143 47 136 80 136 C113 136 140 143 140 153 V163 C140 172 113 179 80 179 C47 179 20 172 20 163 Z" fill="#d4a065" stroke="#583f21" stroke-width="6"/>
  <ellipse cx="80" cy="151" rx="60" ry="15" fill="#e8bb7c"/>
  <path d="M22 153 C34 162 57 166 80 166 C103 166 126 162 138 153" fill="none" stroke="#b07c45" stroke-width="3"/>
  <!-- Fixed bracket behind the post; no painted bevel or fine texture. -->
  <path d="M99 28 H130 Q137 28 137 34 V40 H99 Z" fill="#e8bb7c" stroke="#583f21" stroke-width="6"/>
  <path d="M137 42 V76" fill="none" stroke="#583f21" stroke-width="3"/>
  <path d="M58 25 H102 V142 C102 149 58 149 58 142 Z" fill="#f3dfae" stroke="#583f21" stroke-width="6"/>
  <path d="M94 28 H99 V140 Q97 144 94 143 Z" fill="#d4a065"/>
  <path d="M59 47 Q80 55 101 47 M59 63 Q80 71 101 63 M59 79 Q80 87 101 79 M59 95 Q80 103 101 95 M59 111 Q80 119 101 111 M59 127 Q80 135 101 127" fill="none" stroke="#b07c45" stroke-width="3"/>
  <ellipse cx="80" cy="25" rx="22" ry="9" fill="#e8bb7c" stroke="#583f21" stroke-width="6"/>
  <!-- One teal toy echoes the castle flag, with the same brown outline. -->
  <path d="M134 77 C123 77 122 90 129 101 L125 112 Q124 116 128 115 L137 110 L145 116 Q149 118 148 113 L145 102 C152 92 147 79 139 77 Z" fill="#70b1a5" stroke="#583f21" stroke-width="4"/>
  <circle cx="132" cy="86" r="2" fill="#583f21"/>
</g>
</svg>'''

YARN = '''<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 80 80">
<defs><clipPath id="ball"><circle cx="40" cy="38" r="31"/></clipPath></defs>
<ellipse cx="40" cy="72" rx="33" ry="5" fill="#583f21" opacity="0.14"/>
<circle cx="40" cy="38" r="31" fill="#e89e70"/>
<path d="M57 11 Q80 52 41 70 H77 V8 Z" fill="#c87f54" clip-path="url(#ball)"/>
<g fill="none" stroke-linecap="round" stroke-linejoin="round">
  <path d="M20 16 Q42 25 54 58 M12 32 Q26 41 33 65 M39 9 Q36 29 18 53 M58 20 Q48 36 44 58" stroke="#b07c45" stroke-width="3"/>
  <circle cx="40" cy="38" r="31" stroke="#583f21" stroke-width="6"/>
</g>
</svg>'''

PILLOW = '''<svg xmlns="http://www.w3.org/2000/svg" width="150" height="100" viewBox="0 0 150 100">
<g stroke-linecap="round" stroke-linejoin="round">
  <ellipse cx="75" cy="84" rx="65" ry="6" fill="#583f21" opacity="0.14"/>
  <path d="M14 43 C14 26 41 13 75 13 C109 13 136 26 136 43 V54 C136 71 109 83 75 83 C41 83 14 71 14 54 Z" fill="#4f9086"/>
  <ellipse cx="75" cy="42" rx="61" ry="29" fill="#70b1a5"/>
  <path d="M15 47 C22 62 47 71 75 71 C103 71 128 62 135 47" fill="none" stroke="#583f21" stroke-width="3"/>
  <path d="M55 41 Q75 49 95 41 M75 46 L66 33 M75 46 L85 33" fill="none" stroke="#4b7567" stroke-width="3"/>
  <path d="M14 43 C14 26 41 13 75 13 C109 13 136 26 136 43 V54 C136 71 109 83 75 83 C41 83 14 71 14 54 Z" fill="none" stroke="#583f21" stroke-width="6"/>
</g>
</svg>'''

MASKS = [
    ('scratching-post', [(561,613),(612,613),(617,623),(639,623),(643,645),(666,665),(670,703),(656,724),(651,738),(661,753),(659,774),(641,783),(550,785),(518,778),(513,760),(516,741),(530,731),(558,727)], (445,565,720,820)),
    ('yarn', [(207,783),(224,783),(239,792),(248,809),(250,826),(244,847),(231,860),(210,863),(187,859),(168,853),(168,837),(174,823),(180,801),(193,787)], (95,735,285,920)),
    ('pillow', [(629,826),(654,827),(678,835),(695,846),(703,862),(702,882),(691,898),(674,906),(651,912),(620,913),(596,907),(576,895),(565,880),(566,862),(573,846),(589,835),(607,829)], (505,789,720,968)),
]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def lawn_field(pixels, context, excluded):
    height, width = pixels.shape[:2]
    yy, xx = np.indices((height,width))
    rr,gg,bb = pixels.transpose(2,0,1)
    x0,y0,x1,y1=context
    valid=(rr>170)&(gg>185)&(gg<225)&(rr<gg*.995)&(rr>gg*.88)&(bb<gg*.8)&(bb>gg*.5)
    valid &= (xx>=x0)&(xx<x1)&(yy>=y0)&(yy<y1)&~excluded
    nx=(xx-(x0+x1)/2)/(x1-x0)
    ny=(yy-(y0+y1)/2)/(y1-y0)
    features=np.stack([np.ones_like(nx),nx,ny,nx*nx,nx*ny,ny*ny],axis=-1)
    design,targets=features[valid],pixels[valid]
    keep=np.ones(len(targets),dtype=bool)
    for _ in range(4):
        coeff=np.linalg.lstsq(design[keep],targets[keep],rcond=None)[0]
        residual=np.max(np.abs(design@coeff-targets),axis=1)
        keep=residual<max(2.5,float(np.median(residual))*2.8)
    return features@coeff

def main():
    PROPS.mkdir(exist_ok=True)
    REVIEW.mkdir(parents=True,exist_ok=True)
    source=ART/'terrain-clean.png'
    original=Image.open(source).convert('RGB')
    pixels=np.asarray(original).astype(np.float32)
    clean=pixels.copy()
    masks=[]
    for name,points,context in MASKS:
        mask=Image.new('L',original.size)
        ImageDraw.Draw(mask).polygon(points,fill=255)
        mask=mask.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(2))
        if name == 'scratching-post':
            # The upper post touches the existing castle contact shadow. Keep
            # that shadow/lawn intact and remove only the warm prop pixels here.
            rr,gg,bb=pixels.transpose(2,0,1)
            foreground=(rr>gg*1.01)|(bb>gg*.84)
            local=Image.fromarray(np.uint8(foreground)*255).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1))
            values=np.asarray(mask).copy()
            values[:642]=np.minimum(values[:642],np.asarray(local)[:642])
            mask=Image.fromarray(values)
        masks.append(mask)
    union=np.maximum.reduce([np.asarray(m) for m in masks])
    for (name,points,context),mask in zip(MASKS,masks):
        weight=np.asarray(mask,dtype=np.float32)/255
        field=lawn_field(pixels,context,union>0)
        clean=clean*(1-weight[...,None])+field*weight[...,None]
        mask.save(REVIEW/f'cleanup-{name}-mask.png')
    result=Image.fromarray(np.uint8(np.clip(np.rint(clean),0,255)))
    target=ART/'terrain-props-clean.png'
    result.save(target,optimize=True)
    assert np.array_equal(np.asarray(result)[union==0],np.asarray(original)[union==0])
    records=[]
    for name,svg,origin,ground in [
        ('scratching-post',POST,[80,176],[590,780]),
        ('yarn',YARN,[40,74],[214,854]),
        ('pillow',PILLOW,[75,80],[630,903]),
    ]:
        path=PROPS/f'{name}.svg'
        path.write_text(svg+'\n',encoding='utf-8')
        records.append(dict(file=path.relative_to(ART).as_posix(),origin=origin,ground=ground,sha256=sha(path)))
    manifest=dict(style_reference='game/assets/lobby/castle-tiers/castle-tier-2-body.svg',
        contour=dict(main_color=INK,main_world_px=6,secondary_world_px=3),
        terrain=dict(file=target.name,source=source.name,source_sha256=sha(source),sha256=sha(target),pixels_outside_masks_unchanged=True,masks=[m[0] for m in MASKS]),
        props=records,
        layered_props=[dict(kind=kind,origin=[128,224],scale=scale,
                            main_local_px=main,secondary_local_px=secondary,
                            files={p.name:sha(p) for p in sorted((ART/kind).glob('*.svg'))})
                       for kind,scale,main,secondary in [('tunnel',0.82,7.3,3.65),('bed',0.86,7,3.5)]],
        layer_rule='Each static prop uses foot Y-sort; tunnel/bed retain rear, interior, cat slot, front.',
        palette=dict(cardboard='#e8bb7c',side='#d4a065',detail='#b07c45',tape='#f3dfae',inside='#6b4a2b',teal='#70b1a5'))
    (PROPS/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(dict(static_props=len(records),terrain=target.name,pixels_outside_masks_unchanged=True)))

if __name__=='__main__':
    main()
