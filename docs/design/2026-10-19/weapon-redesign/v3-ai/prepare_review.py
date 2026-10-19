"""REJECTED stroke experiment: preserve for diagnosis, not production or approval.

The uniform held-contour band loses fill and closes openings. New reference:
https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5/?node-id=3470-2
See the reference-study README for the replacement design contract.

Prepare isolated AI rasters and reproducible review boards, without production edits.

Run again as raw/*.png arrives. The generated contours/craft remain raster art;
processing removes white canvas, reduces soft shading to flat material regions,
and adds a modest outer-only brown contour. --no-held skips local Godot renders.
"""
from __future__ import annotations

import argparse
from collections import deque
import json
from pathlib import Path
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
FONT = ROOT / "game/ui/fonts/PaytoneOne-Regular.ttf"
GODOT = Path("C:/Users/dangp/OneDrive/Desktop/Godot_v4.7.2-stable_win64.exe")
ITEMS = [("kiem", "Kiếm"), ("riu", "Rìu"), ("sung", "Súng"), ("gay_phep", "Gậy phép")]
INK, BG, PAPER, MUTED = "#583f21", "#d8e5df", "#f8f0df", "#6f746e"


def rgb(hexstr):
    return np.array([int(hexstr[i:i+2], 16) for i in (1, 3, 5)], dtype=np.uint8)


def exterior_mask(a, key):
    """Flood white-ish exterior; gun/staff can have enclosed white holes.

    Cool pale blade planes are protected because they are not neutral near-white.
    This is extraction, not removal of all pixels resembling a light color.
    """
    lo, hi = a.min(axis=2), a.max(axis=2)
    candidate = (lo >= 227) & ((hi.astype(int) - lo) <= 18)
    seeds = (lo >= 251) & ((hi.astype(int) - lo) <= 4)
    seen = np.zeros(candidate.shape, dtype=bool)
    h, w = seen.shape
    # Border flooding first; seed enclosed uniformly white holes sparsely after.
    queue = deque()
    for x in range(w):
        for y in (0, h-1):
            if candidate[y,x] and not seen[y,x]: seen[y,x] = True; queue.append((x,y))
    for y in range(h):
        for x in (0,w-1):
            if candidate[y,x] and not seen[y,x]: seen[y,x] = True; queue.append((x,y))
    def flood():
        while queue:
            x,y = queue.popleft()
            for xx,yy in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if 0 <= xx < w and 0 <= yy < h and candidate[yy,xx] and not seen[yy,xx]:
                    seen[yy,xx] = True; queue.append((xx,yy))
    flood()
    if key in ("sung", "gay_phep"):
        ys,xs = np.where(seeds & ~seen)
        for x,y in zip(xs[::8],ys[::8]):
            if not seen[y,x]:
                seen[y,x] = True; queue.append((int(x),int(y))); flood()
    return seen


def flatten_materials(a, key):
    """Broad hue/value regions retain the generator's construction and engraving.

    No shape is redrawn. Every interior region is selected from a tiny matte
    project palette; medial filter suppresses generated grain before mapping.
    """
    clean = np.asarray(Image.fromarray(a).filter(ImageFilter.MedianFilter(5)))
    r,g,b = (clean[:,:,i].astype(float) for i in range(3))
    mx,mn = clean.max(axis=2).astype(float), clean.min(axis=2).astype(float)
    out = np.empty_like(clean); out[:] = rgb(INK)
    steel = ((b > r+1) & (g > r) & (mx-mn < 75)) | ((mx-mn < 24) & (r > 150))
    out[steel] = rgb("#d6e0e3")
    # Thresholds lie BETWEEN the source's material planes, away from noisy values
    # within the right blade plane (~208) and recessed fuller (~169).
    out[steel & (r < 216)] = rgb("#b3c4cc")
    out[steel & (r < 190)] = rgb("#8b9fa8")
    purple = (b > g+12) & (r > g+8) & (b > r*.85)
    out[purple] = rgb("#a281c4")
    out[purple & (mx < 145)] = rgb("#8264a8")
    teal = (g > r+22) & (b > r+15) & (mx-mn > 45)
    out[teal] = rgb("#69bdb7")
    out[teal & (g < 155)] = rgb("#40978f")
    warm = ~steel & ~purple & ~teal & (r > g+10)
    # Red wrap has much more red-to-green distance than honey brass.
    coral = warm & ((r-g) > (g-b)*1.8) & (b > g*.6) & (r > 145) & (key == "kiem")
    out[coral] = rgb("#df786a")
    out[coral & (r < 190)] = rgb("#bd5b49")
    gold = warm & ((g-b) > (r-g)*1.25) & (r >= 170)
    out[gold] = rgb("#e6b358")
    wood = warm & ~coral & ~gold & (r > 126)
    out[wood] = rgb("#b77d51")
    wood_dark={"kiem":145,"riu":170,"sung":142,"gay_phep":145}[key]
    out[wood & (r < wood_dark)] = rgb("#99663e")
    leather = warm & (r >= 95) & (r <= 145) & (g > 65)
    out[leather] = rgb("#805a36")
    # Darkest original outlines keep one exact shared warm-brown ink.
    out[mx < 104] = rgb(INK)
    # Palette-mode cleanup removes threshold chatter, preserving broad craft lines.
    indexed = Image.fromarray(out).quantize(colors=16,method=Image.Quantize.MAXCOVERAGE,
                                           dither=Image.Dither.NONE)
    return np.asarray(indexed.filter(ImageFilter.ModeFilter(15)).convert("RGB")).copy()


def dilate_round(mask, radius):
    """Exact binary disk dilation, using row prefix sums rather than square caps."""
    radius=int(radius)
    if radius<=0: return mask.copy()
    h,w=mask.shape; result=np.zeros_like(mask,dtype=bool)
    for dy in range(-radius,radius+1):
        dx=int((radius*radius-dy*dy)**.5)
        padded=np.pad(mask,((0,0),(dx+1,dx)),constant_values=False)
        sums=np.cumsum(padded,axis=1,dtype=np.int32)
        line=(sums[:,2*dx+1:]-sums[:,:-2*dx-1])>0
        if dy>=0: result[dy:] |= line[:h-dy]
        else: result[:dy] |= line[-dy:]
    return result


def uniform_contour(im, inside, outside):
    """Replace, rather than stack, the original variable-weight exterior ink.

    For held props the combined band is exactly10unitpx:3 inside/7 outside
    the original edge, retaining narrow staff/handle fill. Caps/joins are round.
    """
    mask=np.asarray(im.getchannel("A"))>=128
    outer=dilate_round(mask,outside)
    # Pad as foreground before complement dilation so canvas borders erode too.
    eroded=~dilate_round(~np.pad(mask,((inside,inside),(inside,inside)),constant_values=False),inside)
    eroded=eroded[inside:-inside,inside:-inside] if inside else eroded
    out=np.asarray(im).copy(); band=outer & ~eroded
    out[band,:3]=rgb(INK);out[:,:,3]=outer.astype(np.uint8)*255
    return Image.fromarray(out,"RGBA")


def prepare(key):
    source = Image.open(HERE/"raw"/f"{key}.png").convert("RGB")
    a = np.asarray(source)
    foreground = Image.fromarray((~exterior_mask(a, key)).astype(np.uint8)*255)
    flat = flatten_materials(a, key)
    inner = np.asarray(foreground.filter(ImageFilter.MinFilter(5)))
    # Force anti-aliased white/ink fringe back to ink before adding outer contour.
    edge = (np.asarray(foreground)>0) & (inner==0)
    flat[edge] = rgb(INK)
    subject = Image.fromarray(flat, "RGB").convert("RGBA")
    subject.putalpha(foreground)
    contour=subject
    bbox = contour.getbbox()
    contour = contour.crop((max(0,bbox[0]-8),max(0,bbox[1]-8),
                            min(source.width,bbox[2]+8),min(source.height,bbox[3]+8)))
    # Standard high-resolution square export gives predictable layout and alpha.
    out = Image.new("RGBA", (768,768))
    contour.thumbnail((704,704),Image.Resampling.LANCZOS)
    out.alpha_composite(contour,((768-contour.width)//2,(768-contour.height)//2))
    out.save(HERE/"processed"/f"{key}_flat_base.png")
    out=uniform_contour(out,18,18)
    out.save(HERE/"processed"/f"{key}.png")
    for size in (48,64,128,256):
        out.resize((size,size),Image.Resampling.LANCZOS).save(HERE/"processed"/f"{key}_{size}.png")
    return {"id":key,"raw_size":source.size,"foreground_bbox":bbox,
            "output_size":[768,768],"standalone_contour_total_px":36,
            "held_contour_unit_px":10,
            "alpha":"transparent","color_mode":"matte limited project palette"}


def font(size): return ImageFont.truetype(str(FONT),size)


def text_center(d,text,cx,y,size,fill=INK):
    b=d.textbbox((0,0),text,font=font(size))
    d.text((cx-(b[2]-b[0])/2,y),text,font=font(size),fill=fill)


def put(canvas,path,box,crop=False):
    if not path.exists(): return
    im=Image.open(path).convert("RGBA")
    if crop: im=im.crop(im.getchannel("A").getbbox())
    ratio=min(box[2]/im.width,box[3]/im.height)
    im=im.resize((round(im.width*ratio),round(im.height*ratio)),Image.Resampling.LANCZOS)
    canvas.alpha_composite(im,(round(box[0]+(box[2]-im.width)/2),round(box[1]+(box[3]-im.height)/2)))


def boards(available):
    w,h=1440,620
    canvas=Image.new("RGBA",(w,h),BG); d=ImageDraw.Draw(canvas)
    d.text((32,19),"VŨ KHÍ CASUAL · GPT IMAGE 2.5",font=font(34),fill=INK)
    d.text((32,70),"Bản thử 03 · Hình dáng do AI tạo · Làm sạch nền và màu để ghép cùng mèo",font=font(20),fill=MUTED)
    for i,(key,name) in enumerate(ITEMS):
        x=32+i*350
        d.rounded_rectangle((x,119,x+326,556),radius=22,fill=PAPER,outline="#bcae93",width=2)
        if key in available: put(canvas,HERE/"processed"/f"{key}.png",(x+8,133,310,350))
        else: text_center(d,"Đang tạo",x+163,280,22,MUTED)
        text_center(d,name,x+163,498,27)
    d.text((32,580),"Thiết kế để duyệt · Chưa thay vũ khí trong game",font=font(19),fill=MUTED)
    canvas.convert("RGB").save(HERE/"weapons-gpt-v3.png")

    canvas=Image.new("RGBA",(1440,1100),BG); d=ImageDraw.Draw(canvas)
    d.text((32,18),"SO SÁNH BẢN SVG 02 / GPT IMAGE 03",font=font(33),fill=INK)
    d.text((32,69),"Cùng ô so sánh · Căn theo phần hình nhìn thấy · Đối chiếu cấu tạo và cá tính",font=font(20),fill=MUTED)
    for i,(key,name) in enumerate(ITEMS):
        x=32+(i%2)*704; y=120+(i//2)*466
        d.rounded_rectangle((x,y,x+672,y+438),radius=22,fill=PAPER,outline="#bcae93",width=2)
        text_center(d,name,x+336,y+10,26)
        text_center(d,"SVG 02",x+168,y+55,18,MUTED)
        text_center(d,"GPT 03",x+504,y+55,18)
        put(canvas,HERE.parent/"v2"/"rendered"/f"new_icon_{key}.png",(x+30,y+105,276,295),crop=True)
        put(canvas,HERE/"processed"/f"{key}.png",(x+366,y+105,276,295),crop=True)
    d.text((32,1060),"Tài sản gốc trong game giữ nguyên trong lúc duyệt",font=font(19),fill=MUTED)
    canvas.convert("RGB").save(HERE/"v2-vs-gpt.png")

    canvas=Image.new("RGBA",(1160,650),BG); d=ImageDraw.Draw(canvas)
    d.text((30,18),"KIỂM TRA Ở KÍCH THƯỚC NHỎ",font=font(32),fill=INK)
    d.text((30,66),"48 px / 64 px giữ nguyên kích thước · Dáng đen 64 px để kiểm tra nhận diện",font=font(19),fill=MUTED)
    for i,(key,name) in enumerate(ITEMS):
        y=120+i*121
        d.rounded_rectangle((30,y,1130,y+104),radius=15,fill=PAPER)
        d.text((54,y+30),name,font=font(23),fill=INK)
        for xx,sz in ((330,48),(480,64)):
            d.text((xx-64,y+35),str(sz),font=font(18),fill=MUTED)
            path=HERE/"processed"/f"{key}_{sz}.png"
            if path.exists(): canvas.alpha_composite(Image.open(path).convert("RGBA"),(xx,y+(104-sz)//2))
        path=HERE/"processed"/f"{key}_64.png"
        if path.exists():
            im=Image.open(path).convert("RGBA"); sil=Image.new("RGBA",im.size,INK); sil.putalpha(im.getchannel("A"))
            canvas.alpha_composite(sil,(715,y+20))
        d.text((813,y+34),"Silhouette",font=font(18),fill=MUTED)
    canvas.convert("RGB").save(HERE/"native-size-review.png")


def render_cat_sources():
    """Render unchanged current cats and their front paw via Godot SVG support."""
    sys.path.insert(0,str(ROOT/"tools/ui"))
    import make_units as units
    from make_svgs import svg
    units.weapon=lambda *args,**kwargs:("","")
    folder=HERE/"held-sources"; folder.mkdir(exist_ok=True)
    paths=[]
    for key,_ in ITEMS:
        _,klass,rarity,weapon=next(i for i in units.SOLDIERS if i[0]==key)
        path=folder/f"cat_{key}.svg"
        path.write_text(units.cat_soldier(units.COAT[klass],klass,rarity,weapon),encoding="utf-8")
        paths.append(path)
    paw=folder/"front-paw.svg"; paw.write_text(svg(256,240,units.stroke_path(units.R_PAW)),encoding="utf-8"); paths.append(paw)
    res_paths=["res://"+p.relative_to(ROOT).as_posix() for p in paths]
    gd=folder/"rasterize.gd"
    gd.write_text('extends SceneTree\nfunc _initialize():\n'+
                  '\tfor source in '+json.dumps(res_paths)+':\n'+
                  '\t\tvar image := Image.new()\n'+
                  '\t\tassert(image.load_svg_from_string(FileAccess.get_file_as_string(source), 3.0) == OK)\n'+
                  '\t\tassert(image.save_png(source.replace(".svg", ".png")) == OK)\n'+
                  '\tprint("V3_AI_CAT_SOURCES_RENDERED")\n\tquit()\n',encoding="utf-8")
    result=subprocess.run([str(GODOT),"--headless","--path",str(ROOT),"--log-file",str(folder/"godot-engine.log"),"--script",str(gd)],
                          capture_output=True,text=True,encoding="utf-8",errors="replace",timeout=60)
    (folder/"godot-render.log").write_text(result.stdout+result.stderr,encoding="utf-8")
    if result.returncode: raise RuntimeError(result.stdout+result.stderr)


# Grip coordinates on each 768px processed square, and intended unit dimensions.
# Tuned per generated asset. Face/eyes stay unchanged and visible; paw overlays grip.
HELD={"kiem":((.175,.80),118),"riu":((.17,.79),104),
      "sung":((.28,.74),117),"gay_phep":((.28,.80),145)}


def held_board(available):
    folder=HERE/"held-sources"
    if not (folder/"front-paw.png").exists(): render_cat_sources()
    paw=Image.open(folder/"front-paw.png").convert("RGBA")
    for key in available:
        cat=Image.open(folder/f"cat_{key}.png").convert("RGBA")
        before=HERE/"processed"/f"unit_{key}_before_stroke.png"
        current=HERE/"processed"/f"unit_{key}.png"
        if not before.exists() and current.exists():
            Image.open(current).save(before)
        prop=Image.open(HERE/"processed"/f"{key}_flat_base.png").convert("RGBA")
        (gx,gy),size=HELD[key]
        prop=prop.resize((size*3,size*3),Image.Resampling.LANCZOS)
        # Add padding before contour normalization, keeping grip coordinates.
        padded=Image.new("RGBA",(prop.width+90,prop.height+90));padded.alpha_composite(prop,(45,45))
        prop=uniform_contour(padded,9,21)
        # Current front right paw's center is around (160,166) in the unit canvas.
        x=round((160-gx*size)*3)-45; y=round((166-gy*size)*3)-45
        cat.alpha_composite(prop,(x,y)); cat.alpha_composite(paw,(0,0))
        cat.save(HERE/"processed"/f"unit_{key}.png")
        cat.resize((128,120),Image.Resampling.LANCZOS).save(HERE/"processed"/f"unit_{key}_128.png")
    canvas=Image.new("RGBA",(1440,690),BG);d=ImageDraw.Draw(canvas)
    d.text((32,18),"BẢN GPT 03 · KHI MÈO CẦM",font=font(34),fill=INK)
    d.text((32,70),"Giữ nguyên mèo hiện tại · Căn điểm cầm riêng · Vũ khí bitmap nền trong suốt",font=font(20),fill=MUTED)
    for i,(key,name) in enumerate(ITEMS):
        x=32+i*350
        d.rounded_rectangle((x,118,x+326,650),radius=22,fill=PAPER,outline="#bcae93",width=2)
        put(canvas,HERE/"processed"/f"unit_{key}.png",(x+8,137,310,340))
        text_center(d,name,x+163,480,26)
        path=HERE/"processed"/f"unit_{key}_128.png"
        if path.exists(): canvas.alpha_composite(Image.open(path).convert("RGBA"),(x+99,529))
    d.text((32,660),"Mẫu ghép để duyệt · Chưa thay texture của game chính",font=font(18),fill=MUTED)
    canvas.convert("RGB").save(HERE/"cats-with-gpt-v3.png")
    canvas=Image.new("RGBA",(1440,1040),BG);d=ImageDraw.Draw(canvas)
    d.text((32,18),"NÉT VIỀN VŨ KHÍ · TRƯỚC / SAU",font=font(34),fill=INK)
    d.text((32,70),"Mèo 12 px · Vũ khí mới 10 px ở hệ tọa độ nhân vật · Bo tròn, cùng màu nâu",font=font(20),fill=MUTED)
    for i,(key,name) in enumerate(ITEMS):
        x=32+(i%2)*704;y=118+(i//2)*440
        d.rounded_rectangle((x,y,x+672,y+420),radius=22,fill=PAPER)
        text_center(d,name,x+336,y+8,25)
        text_center(d,"Trước: khoảng 2–3 px",x+168,y+48,17,MUTED)
        text_center(d,"Sau: nét đều 10 px",x+504,y+48,17)
        put(canvas,HERE/"processed"/f"unit_{key}_before_stroke.png",(x+18,y+88,300,300))
        put(canvas,HERE/"processed"/f"unit_{key}.png",(x+354,y+88,300,300))
    canvas.convert("RGB").save(HERE/"stroke-before-after.png")


def main():
    parser=argparse.ArgumentParser();parser.add_argument("--no-held",action="store_true");args=parser.parse_args()
    (HERE/"processed").mkdir(exist_ok=True)
    records=[];available=[]
    for key,_ in ITEMS:
        if (HERE/"raw"/f"{key}.png").exists():
            records.append(prepare(key));available.append(key)
    boards(available)
    if not args.no_held and available: held_board(available)
    (HERE/"processing.json").write_text(json.dumps({"available":available,"items":records,
        "production_changed":False,"workflow":"connected white extraction + matte material mapping + outer-only contour",
        "review_status":"rejected_stroke_experiment",
        "issue_notes":[
            "A uniform 10-unit contour band erases narrow material fills and closes functional openings.",
            "Sword guard/pommel, axe grip, gun trigger gap and staff coil lose readable construction.",
            "New reference source is Figma node 3470:2; study intentional material panels, mechanisms and cutouts.",
            "Preserve these outputs as a rejected experiment; see the reference-study README for the new art contract."
        ],
        "reference_source":"https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5/?node-id=3470-2"
        },ensure_ascii=False,indent=2),encoding="utf-8")
    print("Prepared:",", ".join(available))


if __name__=="__main__":main()
