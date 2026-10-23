"""Rig the three lobby cats (cream, tabby, calico) like the soldiers, with play animations.

Same construction as the reviewed soldier cat: one rounded body with its marks kept inside,
two leg stubs behind it, hook paws at the chest; plus separate ears so they can twitch.
No clothes and no weapon: these are the house cats.

Animations (frame px, Y up in the skeleton):
  idle     breathing, slow tail, an ear flick
  walk     the soldiers' trot, a little calmer
  scratch  stretched up on the post, paws clawing down in turn
  bat      batting at the yarn / the fish toy: one paw swipes, the other follows
  knead    kneading the pillow, paws pressing in turn, eyes closed
  nap      curled low, slow deep breaths (for the bed)
  happy    when tapped: ears perk, head up, paws lift, happy squint

    python -I tools/ui/make_lobby_cat_rigs.py
Writes game/assets/units/lobby_<kind>/lobby_<kind>.{json,atlas,png}.
"""
import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import make_soldier_spine as spine
from make_cat_rigs import BODY, L_PAW, R_PAW, W, clip, leg, line
from make_soldier_spine import keys, to_skel
from make_svgs import CAT_EAR, CAT_EYE, CAT_HEAD, CAT_LINE, CATS, ellipse_d, svg

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "docs" / "design" / "2026-10-23" / "lobby-cat-rigs"
GAME = ROOT / "game" / "assets" / "units"
TAIL = "M186 198 Q236 204 232 158 Q230 142 218 142"

def marks(kind, region):
    fill, m = CATS[kind]
    if kind == "tabby":
        if region == "body":
            s = "".join(f'<path d="M44 {y} Q68 {y + 6} 92 {y}" fill="none" stroke="{m}" stroke-width="8" stroke-linecap="round"/>'
                        f'<path d="M164 {y} Q188 {y + 6} 212 {y}" fill="none" stroke="{m}" stroke-width="8" stroke-linecap="round"/>' for y in (150, 168, 186))
        else:
            s = "".join(f'<path d="M{x0} 34 L{x0} 54" stroke="{m}" stroke-width="8" stroke-linecap="round"/>' for x0 in (112, 128, 144))
            s += "".join(f'<path d="M{a} {y} Q{(a + b) / 2} {y + 4} {b} {y}" fill="none" stroke="{m}" stroke-width="7" stroke-linecap="round"/>'
                         for a, b, y in ((36, 60, 100), (36, 58, 116), (196, 220, 100), (198, 220, 116)))
        return f'<g clip-path="url(#{region})">{s}</g>'
    if kind == "calico":
        if region == "body":
            return f'<g clip-path="url(#body)"><path d="{ellipse_d(170, 186, 30, 24)}" fill="{m[0]}"/></g>'
        return (f'<g clip-path="url(#head)"><path d="{ellipse_d(78, 66, 40, 34)}" fill="{m[0]}"/>'
                f'<path d="{ellipse_d(186, 60, 30, 26)}" fill="{m[1]}"/></g>')
    return ""

def ear(fill, sx, colour):
    def x(v):
        return 128 + sx * (v - 128)
    out = f'<path d="M{x(46)} 90 Q{x(48)} 34 {x(58)} 16 Q{x(64)} 8 {x(74)} 16 Q{x(100)} 32 {x(120)} 46 Z" fill="{fill}" {line()}/>'
    return out + f'<path d="M{x(60)} 72 Q{x(61)} 40 {x(66)} 30 Q{x(70)} 26 {x(76)} 30 Q{x(92)} 40 {x(104)} 48 Z" fill="{colour}"/>'

def parts(kind):
    fill, _ = CATS[kind]
    defs = clip("body", BODY) + clip("head", CAT_HEAD)
    face = (f'<circle cx="104" cy="96" r="9" fill="{CAT_EYE}"/><circle cx="152" cy="96" r="9" fill="{CAT_EYE}"/>'
            f'<path d="M110 110 Q119 124 128 112 Q137 124 146 110" fill="none" stroke="{CAT_EYE}" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round"/>')
    head = f'<path d="{CAT_HEAD}" fill="{fill}"/>' + marks(kind, "head") + f'<path d="{CAT_HEAD}" fill="none" {line()}/>' + face
    # Closed eyes, a separate slot shown for knead / nap.
    shut = f'<path d="{CAT_HEAD}" fill="none" stroke="none"/>' + "".join(
        f'<path d="M{cx - 11} 96 Q{cx} 104 {cx + 11} 96" fill="none" stroke="{CAT_EYE}" stroke-width="6" stroke-linecap="round"/>' for cx in (104, 152))
    lids = "".join(f'<circle cx="{cx}" cy="96" r="12" fill="{fill}"/>' for cx in (104, 152))
    return {
        "tail": f'<path d="{TAIL}" fill="none" stroke="{CAT_LINE}" stroke-width="{13 + 2 * W}" stroke-linecap="round"/>'
                f'<path d="{TAIL}" fill="none" stroke="{fill}" stroke-width="13" stroke-linecap="round"/>',
        "leg_l": leg(90, fill), "leg_r": leg(166, fill),
        "body": f'<path d="{BODY}" fill="{fill}"/>' + marks(kind, "body") + f'<path d="{BODY}" fill="none" {line()}/>',
        "ear_l": ear(fill, 1, CAT_EAR), "ear_r": ear(fill, -1, CAT_EAR),
        "head": head,
        "eyes_shut": lids + shut,
        "paw_l": f'<path d="{L_PAW}" fill="none" {line(13)}/>',
        "paw_r": f'<path d="{R_PAW}" fill="none" {line(13)}/>',
    }, defs

ORDER = ["tail", "leg_l", "leg_r", "body", "ear_l", "ear_r", "head", "eyes_shut", "paw_l", "paw_r"]
BONES = {  # bone: (parent, pivot in frame px)
    "hip": ("root", (128, 200)), "body": ("hip", (128, 200)), "tail": ("body", (186, 200)),
    "head": ("body", (128, 140)), "ear_l": ("head", (82, 60)), "ear_r": ("head", (174, 60)),
    "paw_l": ("body", (104, 150)), "paw_r": ("body", (152, 150)),
    "leg_l": ("root", (90, 190)), "leg_r": ("root", (166, 190)),
}
SLOT_BONE = {"eyes_shut": "head"}

def anims():
    def loop(period, n=4):
        return [round(period * i / n, 4) for i in range(n + 1)]
    walk = spine.run_animation()
    # Calmer than a soldier's run: lower bounce, smaller swings, slower.
    for tl in walk["bones"].values():
        for ch, ks in tl.items():
            for k in ks:
                if "time" in k:
                    k["time"] = round(k["time"] * 1.5, 4)
                for c in ("x", "y", "value"):
                    if c in k and ch != "scale":
                        k[c] = round(k[c] * 0.6, 3)
    walk["bones"]["ear_l"] = {"rotate": keys(loop(0.66), value=[0, 4, 0, -2, 0])}
    t = loop(2.4, 6)
    idle = {"bones": {
        "hip": {"scale": keys(loop(2.4, 2), x=[1, 1.02, 1], y=[1, 1.035, 1])},
        "tail": {"rotate": keys(loop(2.4), value=[0, 12, 0, -10, 0])},
        "ear_r": {"rotate": keys(t, value=[0, 0, 0, -16, 6, 0, 0])},
    }}
    T = loop(0.6)
    scratch = {"bones": {   # stretched up the post, paws raking down in turn
        "hip": {"scale": keys([0], x=[0.96], y=[1.1])},
        "body": {"translate": keys([0], x=[0], y=[10])},
        "head": {"rotate": keys(T, value=[0, -3, 0, 3, 0])},
        "paw_l": {"translate": keys(T, x=[0, 0, 0, 0, 0], y=[44, 20, 44, 44, 44]), "rotate": keys(T, value=[-40, -20, -40, -40, -40])},
        "paw_r": {"translate": keys(T, x=[0, 0, 0, 0, 0], y=[44, 44, 44, 20, 44]), "rotate": keys(T, value=[40, 40, 40, 20, 40])},
        "tail": {"rotate": keys(T, value=[0, 14, 0, -14, 0])},
    }}
    B = [0, 0.18, 0.3, 0.5, 0.68, 0.8, 1.0]
    bat = {"bones": {   # swipe right paw, then left, at a toy in front
        "hip": {"translate": keys(B, x=[0] * 7, y=[0, -3, 2, 0, -3, 2, 0])},
        "body": {"rotate": keys(B, value=[0, 4, -6, 0, -4, 6, 0])},
        "head": {"rotate": keys(B, value=[0, -4, 4, 0, 4, -4, 0])},
        "paw_r": {"rotate": keys(B, value=[0, 50, -40, 0, 0, 0, 0]), "translate": keys(B, x=[0, -4, 14, 0, 0, 0, 0], y=[0, 26, 8, 0, 0, 0, 0])},
        "paw_l": {"rotate": keys(B, value=[0, 0, 0, 0, -50, 40, 0]), "translate": keys(B, x=[0, 0, 0, 0, 4, -14, 0], y=[0, 0, 0, 0, 26, 8, 0])},
        "ear_l": {"rotate": keys(B, value=[0, 6, 0, 0, 6, 0, 0])}, "ear_r": {"rotate": keys(B, value=[0, -6, 0, 0, -6, 0, 0])},
        "tail": {"rotate": keys(B, value=[0, 20, -10, 0, -20, 10, 0])},
    }}
    # The paw reaches the toy at 0.3 s and 0.8 s: the game pushes the yarn / swings the fish there.
    bat["events"] = [{"time": 0.3, "name": "swipe"}, {"time": 0.8, "name": "swipe"}]
    H = [0, 0.15, 0.45, 0.9]
    happy = {"bones": {   # tapped: ears perk, head tilts up, paws lift, tail shoots up; eyes shut (a happy squint)
        "head": {"rotate": keys(H, value=[0, 8, -4, 0]), "translate": keys(H, x=[0, 0, 0, 0], y=[0, 6, 4, 0])},
        "ear_l": {"rotate": keys(H, value=[0, -14, -10, 0])}, "ear_r": {"rotate": keys(H, value=[0, 14, 10, 0])},
        "paw_l": {"translate": keys(H, x=[0, 0, 0, 0], y=[0, 18, 14, 0]), "rotate": keys(H, value=[0, -20, -14, 0])},
        "paw_r": {"translate": keys(H, x=[0, 0, 0, 0], y=[0, 18, 14, 0]), "rotate": keys(H, value=[0, 20, 14, 0])},
        "tail": {"rotate": keys(H, value=[0, -30, -24, 0])},
    }, "slots": {"eyes_shut": {"attachment": [{"name": "eyes_shut"}]}}}
    K = loop(0.8)
    knead = {"bones": {   # paws press down in turn, eyes shut, slow sway
        "hip": {"translate": keys([0], x=[0], y=[-6])},
        "body": {"rotate": keys(K, value=[0, 3, 0, -3, 0])},
        "paw_l": {"translate": keys(K, x=[0, 0, 0, 0, 0], y=[-4, -18, -4, -4, -4])},
        "paw_r": {"translate": keys(K, x=[0, 0, 0, 0, 0], y=[-4, -4, -4, -18, -4])},
        "tail": {"rotate": keys(loop(1.6), value=[0, 8, 0, -8, 0])},
    }, "slots": {"eyes_shut": {"attachment": [{"name": "eyes_shut"}]}}}
    N = loop(3.0, 2)
    nap = {"bones": {   # curled low and round, deep slow breaths
        "hip": {"translate": keys([0], x=[0], y=[-18]), "scale": keys(N, x=[1.12, 1.16, 1.12], y=[0.82, 0.86, 0.82])},
        "head": {"translate": keys(N, x=[0, 0, 0], y=[-14, -12, -14]), "rotate": keys([0], value=[6])},
        "paw_l": {"translate": keys([0], x=[6], y=[-30])}, "paw_r": {"translate": keys([0], x=[-6], y=[-30])},
        "tail": {"rotate": keys([0], value=[40])},
    }, "slots": {"eyes_shut": {"attachment": [{"name": "eyes_shut"}]}}}
    return {"idle": idle, "walk": walk, "scratch": scratch, "bat": bat, "knead": knead, "nap": nap, "happy": happy}

def build(kind):
    uid = f"lobby_{kind}"
    layers, defs = parts(kind)
    folder = WORK / uid
    (folder / "svg").mkdir(parents=True, exist_ok=True)
    for name, body in layers.items():
        (folder / "svg" / f"{name}.svg").write_text(svg(256, 240, body, defs), encoding="utf-8")
    out = folder / "spine"
    out.mkdir(exist_ok=True)
    rendered = spine.render_parts(folder, ORDER)
    page = spine.pack({n: im for n, (im, _) in rendered.items()}, uid, out)
    world = {"root": (0, 0)}
    bones = [{"name": "root"}]
    for b, (parent, pivot) in BONES.items():
        wx, wy = to_skel(*pivot)
        world[b] = (wx, wy)
        px, py = world[parent]
        bones.append({"name": b, "parent": parent, "x": round(wx - px, 2), "y": round(wy - py, 2)})
    k = 1 / spine.RENDER_SCALE
    slots, atts = [], {}
    for n in ORDER:
        bone = SLOT_BONE.get(n, n)
        im, box = rendered[n]
        cx, cy = to_skel((box[0] + box[2]) / 2 * k, (box[1] + box[3]) / 2 * k)
        bx, by = world[bone]
        slot = {"name": n, "bone": bone}
        if n != "eyes_shut":   # shut eyes are hidden until an animation shows them
            slot["attachment"] = n
        slots.append(slot)
        atts[n] = {n: {"x": round(cx - bx, 2), "y": round(cy - by, 2), "scaleX": k, "scaleY": k, "width": im.width, "height": im.height}}
    skel = {"skeleton": {"spine": "4.2.0", "x": -128, "y": -8, "width": 256, "height": 240, "images": "./", "audio": ""},
            "bones": bones, "slots": slots, "skins": [{"name": "default", "attachments": atts}],
            "events": {"swipe": {}}, "animations": anims()}
    names = {b["name"] for b in bones}
    for a in skel["animations"].values():
        a["bones"] = {b: tl for b, tl in a["bones"].items() if b in names}
    (out / f"{uid}.json").write_text(json.dumps(skel, indent=1), encoding="utf-8")
    dest = GAME / uid
    dest.mkdir(parents=True, exist_ok=True)
    for ext in ("json", "atlas", "png"):
        shutil.copy(out / f"{uid}.{ext}", dest / f"{uid}.{ext}")
    print(uid, f"{len(bones)} bones, {len(slots)} slots, page {page[0]}x{page[1]}")

if __name__ == "__main__":
    for kind in sys.argv[1:] or ["cream", "tabby", "calico"]:
        build(kind)
