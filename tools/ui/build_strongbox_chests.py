"""Prepare the selected generated B strongboxes without retracing their art.

The source pixels provide every contour and keyhole. This recipe only removes
the simple outer matte, collapses mild generated surface gradients into a
restrained palette and separates animation layers. It does not dilate ink,
trace silhouettes or add vector detail. Originals are never modified.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / "game/ui/art/chests/strongbox-b"
REVIEW = ROOT / "docs/design/2026-10-23/chest-b-production"
CONCEPT = ROOT / "docs/design/2026-10-23/chest-concept-options/png"
INK = (88, 63, 33)
AUTHOR_WIDTH = 208
FONT = ROOT / "game/ui/fonts/PaytoneOne-Regular.ttf"


SPECS = {
    "wood": {
        "source": CONCEPT / "B1.png", "seam": 114,
        "lock": [160, 100, 270, 203], "strap_sample_y": 94,
        "lock_seam_left": [164, 160], "lock_seam_right": [265, 269], "seam_ink": [-6,8],
        "main_source_width": 13.5,
        "measurement_samples": {"left_wall_rows": [150,160,180], "left_wall_widths": [14,14,15], "bottom_column": 140, "bottom_width": 13},
        "palette": {"main": INK, "body": (236,169,102),
                    "metal": (243,197,107), "secondary": (176,124,69)},
        "anchors": {
            "main": [(76,48,17),(85,55,22),(90,58,25)],
            "secondary": [(144,90,30),(167,107,50),(190,128,62),(203,143,74)],
            "body": [(243,165,91),(252,184,111),(246,170,96),(255,196,126)],
            "metal": [(253,224,118),(250,207,100),(246,197,88),(255,231,150)],
        },
    },
    "silver": {
        "source": CONCEPT / "B2.png", "seam": 114,
        "lock": [158, 99, 267, 203], "strap_sample_y": 94,
        "lock_seam_left": [162, 158], "lock_seam_right": [263, 266], "seam_ink": [-6,8],
        "main_source_width": 13.5,
        "measurement_samples": {"left_wall_rows": [150,160,180], "left_wall_widths": [14,14,14], "bottom_column": 140, "bottom_width": 13},
        "palette": {"main": INK, "body": (155,205,224),
                    "metal": (231,232,220), "metal_secondary": (150,170,163),
                    "body_secondary": (106,152,172)},
        "anchors": {
            "main": [(71,41,9),(80,48,13),(91,59,25),(104,83,55)],
            "body": [(166,208,236),(151,195,224),(213,237,247),(154,201,230)],
            "metal": [(227,223,211),(250,248,238),(218,215,204)],
            "metal_secondary": [(129,124,111),(172,174,167),(150,151,140)],
            "body_secondary": [(105,143,166),(115,153,174)],
        },
    },
    "gold": {
        "source": REVIEW / "gold-source-crop.png", "seam": 333,
        "raw": ROOT / "output/imagegen/chest-options-2026-10-23/B-v2-raw.png",
        "lock": [492,276,824,599], "strap_sample_y": 260,
        "lock_seam_left": [500,492], "lock_seam_right": [816,823], "seam_ink": [-19,21],
        "main_source_width": 28.5,
        "measurement_samples": {"left_wall_rows": [410,440,480], "left_wall_widths": [30,30,30], "bottom_column": 450, "bottom_width": 27},
        "palette": {"main": INK, "body": (246,107,88), "metal": (255,211,99),
                    "metal_shadow": (225,170,57), "metal_highlight": (255,241,158),
                    "secondary": (169,117,38)},
        "anchors": {
            "main": [(86,45,7),(97,52,10),(102,59,17)],
            "secondary": [(153,98,17),(171,112,25)],
            "body": [(255,96,82),(255,113,94),(252,102,83),(255,139,118)],
            "metal": [(255,209,81),(255,218,92),(250,204,78)],
            "metal_shadow": [(223,169,53),(229,174,51),(237,185,59)],
            "metal_highlight": [(255,246,163),(255,240,148),(255,229,113)],
        },
    },
}


def relative(path):
    return path.relative_to(ROOT).as_posix()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def clean_palette(source, spec):
    """Nearest material samples share a single flat target fill.

    The exterior AA is recovered against the known pale matte, only within
    two pixels of the already-existing alpha boundary. No pixel is added
    outside the source alpha. No morphological ink expansion is performed.
    """
    a = np.asarray(source.convert("RGBA")).copy()
    rgb = a[..., :3].astype(np.float32)
    samples, targets = [], []
    for role, colors in spec["anchors"].items():
        for color in colors:
            samples.append(color)
            targets.append(spec["palette"][role])
    samples, targets = np.float32(samples), np.float32(targets)
    out = np.empty_like(rgb)
    # Limit the temporary tensor; all pixels are mapped deterministically.
    for y in range(0, source.height, 48):
        block = rgb[y:y+48]
        distance = ((block[..., None, :] - samples) ** 2).sum(axis=-1)
        labels = distance.argmin(axis=-1)
        if 'metal_highlight' in spec['palette']:
            # Gold's explicitly requested polish retains a short material
            # ramp. Smooth sample interpolation avoids noisy hard bands on
            # its curved recessed fasteners; red samples all map identically.
            weight=np.exp(-(distance-distance.min(axis=-1,keepdims=True))/260)
            out[y:y+48]=(weight[...,None]*targets).sum(axis=-2)/weight.sum(axis=-1,keepdims=True)
        else:
            out[y:y+48] = targets[labels]
    if "body_secondary" in spec["palette"]:
        # A blue lid highlight is still blue material, never silver flecks.
        blue = (rgb[...,2]-rgb[...,0] > 15) & (rgb[...,2]-rgb[...,1] > 3)
        blue_bright = blue & (rgb.mean(axis=2) > 155)
        out[blue_bright] = spec["palette"]["body"]
    # A half-source-pixel AA pass removes quantization stairs at material
    # boundaries without moving or dilating any contour mask.
    out = np.asarray(Image.fromarray(out.astype(np.uint8)).filter(ImageFilter.GaussianBlur(.45))).copy()
    alpha = a[..., 3].astype(np.float32) / 255
    outside = Image.fromarray(np.uint8(alpha == 0) * 255)
    near_border = np.asarray(outside.filter(ImageFilter.MaxFilter(5))) > 0
    matte = np.float32((246,240,224))
    source_ink = np.float32(spec["anchors"]["main"][0])
    vector = matte - source_ink
    coverage = np.clip(((matte-rgb) * vector).sum(axis=2) / (vector*vector).sum(), 0, 1)
    edge = near_border & (alpha > 0)
    alpha[edge] *= coverage[edge]
    out[edge] = INK
    return Image.fromarray(np.dstack((out.astype(np.uint8), np.uint8(np.rint(alpha*255)))))


def lock_mask(source, spec):
    """Select source lock, preserving its pixel contour and rounded corners.

    Where the opening seam merges with the lock's brown contour, its two
    exterior sides are interpolated across that short occlusion. Everywhere
    else the actual source brown runs determine the boundary. This is a
    layer-selection mask, not newly drawn lock art.
    """
    a = np.asarray(source.convert("RGBA"))
    x0,y0,x1,y1 = spec["lock"]
    dark = (a[...,0] < 120) & (a[...,1] < 100)
    mask = np.zeros(a.shape[:2], dtype=np.uint8)
    seam = spec["seam"]
    for y in range(y0, y1):
        xs = np.flatnonzero(dark[y, x0:x1]) + x0
        if not len(xs):
            continue
        a0,a1=spec["seam_ink"]
        if seam+a0 <= y <= seam+a1:
            u = (y-(seam+a0))/(a1-a0)
            lo = round(spec["lock_seam_left"][0]*(1-u)+spec["lock_seam_left"][1]*u)
            hi = round(spec["lock_seam_right"][0]*(1-u)+spec["lock_seam_right"][1]*u)
        else:
            lo,hi = int(xs[0]),int(xs[-1])
        mask[y,lo:hi+1] = 255
    return mask


def pad(image, padding):
    result = Image.new("RGBA", (image.width+padding*2, image.height+padding*2))
    result.alpha_composite(image, (padding,padding))
    return result


def make_layers(tier, spec):
    source = Image.open(spec["source"]).convert("RGBA")
    closed = clean_palette(source, spec)
    rgba = np.asarray(closed).copy()
    seam = spec["seam"]
    lock = lock_mask(source, spec)
    latch_a = rgba.copy()
    latch_a[...,3] = np.minimum(latch_a[...,3], lock)
    lid_a = rgba.copy()
    last_lid_y = seam + spec['seam_ink'][1]
    lid_a[last_lid_y+1:, :, 3] = 0
    # A tiny lock-occluded area belongs to the moving lid. Restore the actual
    # strap pattern from an adjacent unobscured row, then the level rear seam.
    for y in range(spec["lock"][1], last_lid_y+1):
        selected = lock[y] > 0
        if y < seam+spec['seam_ink'][0]:
            lid_a[y,selected] = rgba[spec["strap_sample_y"],selected]
        else:
            lid_a[y,selected,:3] = INK
            lid_a[y,selected,3] = 255
    body_a = rgba.copy()
    body_a[:seam,:,3] = 0
    # Assign the outside antialias pixels in the closed overlap to lid only.
    # This prevents source alpha being composited twice along the two side
    # pixels; opaque artwork and all contours remain unchanged.
    overlap=body_a[seam:last_lid_y+1,:,3]
    overlap[overlap<255]=0
    # Latch is fixed. Its below-seam source pixels remain exactly under its
    # own overlay in body; no hidden detail is invented behind it.
    padding = 20
    images = {"closed": closed, "body": Image.fromarray(body_a),
              "lid": Image.fromarray(lid_a), "latch": Image.fromarray(latch_a)}
    outdir = DEST/tier
    outdir.mkdir(parents=True, exist_ok=True)
    for name, image in images.items():
        pad(image,padding).save(outdir/f"{name}.png", optimize=True)
    Image.fromarray(lock).save(outdir/"latch-mask.png", optimize=True)
    source_bbox = source.getchannel("A").getbbox()
    width = source_bbox[2]-source_bbox[0]
    s = AUTHOR_WIDTH/width
    cx = (source_bbox[0]+source_bbox[2]-1)/2
    record = {
        "source": relative(spec["source"]), "source_sha256": digest(spec["source"]),
        "source_frame": list(source.size), "source_alpha_bbox": list(source_bbox),
        "source_seam": [cx,seam], "author_width": AUTHOR_WIDTH,
        "scale_from_source": s,
        "texture_rect": [round(-(cx+padding)*s,4),round(-(seam+padding)*s,4),
                         round((source.width+padding*2)*s,4),round((source.height+padding*2)*s,4)],
        "main_width": round(spec["main_source_width"]*s,3),
        "main_measurement": {"method": "Opaque brown runs on straight source wall/bottom, away from rounded joins; source-R<120/G<100/A>240. Fitted by uniform208/sourceAlphaWidth.",
                             "source_samples": spec["measurement_samples"],
                             "fitted_range": [round(min(spec["measurement_samples"]["left_wall_widths"]+[spec["measurement_samples"]["bottom_width"]])*s,3),round(max(spec["measurement_samples"]["left_wall_widths"]+[spec["measurement_samples"]["bottom_width"]])*s,3)]},
        "cavity_rect": [-96,-2,192,15],
        "latch_half_width": round((spec["lock"][2]-spec["lock"][0])/2*s,3),
        "textures": {name:relative(outdir/f"{name}.png") for name in images},
        "palette": {role:'#'+''.join(f'{c:02x}' for c in color) for role,color in spec['palette'].items()},
        "layer_order": ["cavity", "body", "lid", "latch"],
        "layer_notes": "Fixed body and latch; moving lid contains repaired strap/seam only where source lock occluded them. All four textures share texture_rect. Original generated contour/keyhole preserved; no ink dilation.",
    }
    if 'raw' in spec:
        record['raw_source']=relative(spec['raw'])
        record['raw_source_sha256']=digest(spec['raw'])
        record['gloss_policy']='User requested a richer slightly polished gold shop chest; four authored gold tones retained, coral field flattened.'
        record['raw_crop']=spec.get('raw_crop')
    for size in (128,96,64,48,32):
        icon=Image.new("RGBA",(size,size))
        cropped=closed.crop(closed.getchannel('A').getbbox())
        target_width=round(size*.90)
        resized=cropped.resize((target_width,round(cropped.height*target_width/cropped.width)),Image.Resampling.LANCZOS)
        icon.alpha_composite(resized,((size-resized.width)//2,(size-resized.height)//2))
        icon.save(outdir/f"icon_{size}.png",optimize=True)
    # Unpadded layer review and assembled views at source pixels.
    return record, source, images


def fit(image, rect):
    x,y,w,h = rect
    target=image.copy()
    target.thumbnail((w,h),Image.Resampling.LANCZOS)
    return target,(round(x+(w-target.width)/2),round(y+(h-target.height)/2))


def review(all_results):
    REVIEW.mkdir(parents=True,exist_ok=True)
    board=Image.new("RGB",(1420,1120),"#f3eee0")
    draw=ImageDraw.Draw(board)
    def label(x,y,t,size=26):
        draw.text((x,y),t,font=ImageFont.truetype(str(FONT),size),fill=INK)
    label(35,18,"B — selected strongboxes",34)
    label(35,70,"Source concept",23)
    label(490,70,"Clean palette / gold polish",23)
    label(950,70,"Separated lid / fixed latch",23)
    for i,(tier,(record,source,images)) in enumerate(all_results.items()):
        y=112+i*325
        label(35,y,tier.title(),24)
        for image,x in [(source,35),(images['closed'],490)]:
            tile,pos=fit(image,(x,y+35,405,252))
            board.paste(tile,pos,tile)
        preview=Image.new('RGBA',(source.width+90,source.height+100))
        # Rear mouth deliberately simple; native runtime supplies the rim.
        d=ImageDraw.Draw(preview)
        seam=record['source_seam'][1]
        d.rounded_rectangle((62,seam+42,preview.width-62,seam+80),radius=12,fill='#704c2c',outline=INK,width=12)
        preview.alpha_composite(images['body'],(45,55))
        lid=images['lid'].rotate(9,Image.Resampling.BICUBIC,expand=False,center=(source.width/2,seam))
        preview.alpha_composite(lid,(53,10))
        preview.alpha_composite(images['latch'],(45,55))
        tile,pos=fit(preview,(950,y+13,425,280))
        board.paste(tile,pos,tile)
    label(35,1090,"Same source contours • no new ornament • prototype layers",17)
    board.save(REVIEW/'production-comparison.png',optimize=True)
    thumbs=Image.new('RGB',(970,500),'#e6ece1')
    d=ImageDraw.Draw(thumbs)
    for i,tier in enumerate(all_results):
        d.text((22,22+i*150),tier.title(),font=ImageFont.truetype(str(FONT),23),fill=INK)
        for j,size in enumerate((128,96,64,48,32)):
            im=Image.open(DEST/tier/f'icon_{size}.png')
            x=170+j*155; y=15+i*150+(128-size)//2
            thumbs.paste(im,(x,y),im)
            d.text((x,144+i*150),str(size)+'px',font=ImageFont.truetype(str(FONT),16),fill=INK)
    thumbs.save(REVIEW/'actual-size-icons.png',optimize=True)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--tiers',nargs='+',default=['wood','silver','gold'])
    args=parser.parse_args()
    DEST.mkdir(parents=True,exist_ok=True)
    if 'gold' in args.tiers:
        REVIEW.mkdir(parents=True,exist_ok=True)
        raw=Image.open(SPECS['gold']['raw']).convert('RGBA')
        a=np.asarray(raw).copy()
        rgb=a[...,:3].astype(np.int16)
        candidate=(np.max(np.abs(rgb-np.array([246,240,224])),axis=2)<27)
        flood=Image.fromarray(np.uint8(candidate)*255).copy()
        ImageDraw.floodfill(flood,(0,0),128)
        a[np.asarray(flood)==128,3]=0
        unmatte=Image.fromarray(a)
        box=unmatte.getchannel('A').getbbox()
        box=(box[0]-8,box[1]-8,box[2]+8,box[3]+8)
        SPECS['gold']['raw_crop']=list(box)
        unmatte.crop(box).save(SPECS['gold']['source'],optimize=True)
    manifest_path=DEST/'manifest.json'
    manifest=json.loads(manifest_path.read_text('utf-8')) if manifest_path.exists() else {
        'schema':1,'family':'B strongboxes','author_width':AUTHOR_WIDTH,'tiers':{},
        'raw_reference':'output/imagegen/chest-options-2026-10-23/B-raw.png',
        'recipe':relative(Path(__file__).resolve()),
    }
    results={}
    for tier in args.tiers:
        result=make_layers(tier,SPECS[tier]); manifest['tiers'][tier]=result[0]; results[tier]=result
    manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n','utf-8')
    (DEST/'assets.gd').write_text('# Generated by tools/ui/build_strongbox_chests.py; do not edit by hand.\nextends RefCounted\n\nconst DATA := '+json.dumps(manifest,ensure_ascii=False,indent=2)+'\n','utf-8')
    review(results)
    print(json.dumps({'manifest':relative(manifest_path),'tiers':list(results)},indent=2))


if __name__=='__main__':
    main()
