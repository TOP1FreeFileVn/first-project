"""Rig every dungeon monster (make_units.ENEMIES) for skeletal animation, like the cats.

Three body plans:
- Walkers (goblins, orcs, skeletons, the mole, the mushroom): the cats' construction. One
  rounded body with its marks and clothes kept inside it, two leg stubs behind it, paws at
  the chest, the weapon in the right paw. Their art comes from make_units.py's pieces.
- The slime: a blob that hops and squashes, its face riding on it.
- The bat: a body that hovers and two wings that flap.

    python -I tools/ui/make_monster_rigs.py [unit_id ...]   (default: all 13)
Writes game/assets/units/<id>/<id>.{json,atlas,png}; work files in docs/design/2026-10-23/monster-rigs/<id>/.
"""
import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import make_units as U
import make_soldier_spine as spine
from make_cat_rigs import BODY, L_PAW, R_PAW, PIVOTS, W, clip, leg, line
from make_soldier_spine import keys, to_skel
from make_svgs import CAT_EYE, CAT_HEAD, CAT_LINE, circle_d, ellipse_d, svg

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "docs" / "design" / "2026-10-23" / "monster-rigs"
GAME = ROOT / "game" / "assets" / "units"

def paw(d):
    return f'<path d="{d}" fill="none" {line(13)}/>'

def ears(skin, skin_dark):
    out = ""
    for sx in (1, -1):
        def x(v, sx=sx):
            return 128 + sx * (v - 128)
        out += f'<path d="M{x(52)} 84 L{x(2)} 58 Q{x(0)} 52 {x(8)} 54 L{x(56)} 66 Z" fill="{skin}" {line(10)}/>'
        out += f'<path d="M{x(44)} 74 L{x(16)} 60 L{x(46)} 66 Z" fill="{skin_dark}"/>'
    return out

def tunic(fill):
    return f'<g clip-path="url(#body)"><path d="M84 130 L172 130 Q186 166 172 196 L84 196 Q70 166 84 130 Z" fill="{fill}" {line(8)}/></g>'

def walker(skin, *, skin_dark=None, body_extra="", head_extra="", face=None, weapon=None, held="",
           paw_l_extra="", cape="", head_shape=None, has_ears=False):
    """Parts of a cat-built monster. `held` replaces the weapon layer (e.g. the bomb)."""
    defs = clip("body", BODY) + clip("head", CAT_HEAD)
    head_d = head_shape or CAT_HEAD
    parts = {}
    if cape:
        parts["cape"] = f'<g transform="translate(0 16) scale(1 0.86)">{cape}</g>'
    parts["leg_l"] = leg(90, skin)
    parts["leg_r"] = leg(166, skin)
    parts["body"] = f'<path d="{BODY}" fill="{skin}"/>' + body_extra + f'<path d="{BODY}" fill="none" {line()}/>'
    parts["paw_l"] = paw(L_PAW) + paw_l_extra
    head = ears(skin, skin_dark) if has_ears else ""
    head += f'<path d="{head_d}" fill="{skin}" {line()}/>' + (face if face is not None else U.grumpy_face()) + head_extra
    parts["head"] = head
    if weapon:
        wdefs, wbody = U.weapon(weapon, 130, 54, 1.0, "w")
        defs += wdefs
        parts["weapon"] = wbody
    elif held:
        parts["weapon"] = held
    parts["paw_r"] = paw(R_PAW)
    return parts, defs

CHEF_HAT = f'<path d="M80 52 Q60 20 92 14 Q110 -6 136 8 Q166 -4 176 22 Q200 30 176 54 Q128 40 80 52 Z" fill="#ffffff" {line(9)}/>'

def goblin(weapon=None, extra="", held=""):
    return walker(U.GOBLIN, skin_dark=U.GOBLIN_DARK, has_ears=True, body_extra=tunic("#9c6b3c") + extra,
                  face=U.grumpy_face("#c9302c"), weapon=weapon, held=held)

def orc(weapon, hat="", king=False):
    tusks = "".join(f'<path d="M{128 + sx * 22 - 6} 120 L{128 + sx * 22} 100 L{128 + sx * 22 + 6} 120 Z" fill="#fff8e7" {line(5)}/>' for sx in (1, -1))
    crown = (f'<path d="M78 44 L86 6 L106 28 L128 0 L150 28 L170 6 L178 44 Q128 30 78 44 Z" fill="#ffd23f" {line(9)}/>'
             f'<circle cx="128" cy="26" r="7" fill="#e0504a" {line(4)}/>') if king else ""
    return walker(U.ORC, skin_dark=U.ORC_DARK, has_ears=True, body_extra=tunic("#7a3d2a" if king else "#ffffff"),
                  face=U.grumpy_face(CAT_EYE), head_extra=tusks + crown + hat, weapon=weapon,
                  cape=U.cape("#ffd23f") if king else "")

def skeleton(weapon, eye="#5fd0ff", shield=False):
    ribs = '<path d="M128 126 L128 204" stroke="#c9c2b0" stroke-width="8" stroke-linecap="round"/>'
    ribs += "".join(f'<path d="M86 {y} Q128 {y + 10} 170 {y}" fill="none" stroke="{U.BONE_DARK}" stroke-width="7" stroke-linecap="round"/>' for y in (146, 164, 182))
    face = "".join(f'<path d="{ellipse_d(cx, 92, 18, 16)}" fill="{CAT_EYE}"/><circle cx="{cx}" cy="94" r="5" fill="{eye}"/>' for cx in (100, 156))
    face += f'<path d="M122 116 L128 106 L134 116 Z" fill="{CAT_EYE}"/><rect x="102" y="122" width="52" height="14" rx="4" fill="#ffffff" {line(5)}/>'
    face += "".join(f'<path d="M{xx} 123 L{xx} 135" stroke="{CAT_LINE}" stroke-width="4"/>' for xx in (115, 128, 141))
    shield_art = (f'<path d="{circle_d(70, 172, 40)}" fill="#8f9cab" {line(10)}/><path d="{circle_d(70, 172, 14)}" fill="#ffd23f" {line(6)}/>') if shield else ""
    return walker(U.BONE, body_extra=f'<g clip-path="url(#body)">{ribs}</g>', face=face, weapon=weapon, paw_l_extra=shield_art)

def mole():
    fur = "#8a6a52"
    belly = f'<g clip-path="url(#body)"><path d="{ellipse_d(128, 176, 34, 28)}" fill="#b08b6c"/></g>'
    claw = lambda cx: (f'<path d="{ellipse_d(cx, 166, 20, 15)}" fill="#f2c9b5" {line(8)}/>'
                       + "".join(f'<path d="M{cx + k} 176 L{cx + k} 190" stroke="#fff8e7" stroke-width="6" stroke-linecap="round"/>' for k in (-10, 0, 10)))
    face = (f'<circle cx="106" cy="94" r="6" fill="{CAT_EYE}"/><circle cx="150" cy="94" r="6" fill="{CAT_EYE}"/>'
            f'<path d="{ellipse_d(128, 114, 18, 13)}" fill="#f28fa0" {line(7)}/>')
    hat = (f'<path d="M62 70 Q62 22 128 20 Q194 22 194 70 Z" fill="#ffd23f" {line()}/>'
           f'<path d="M44 74 Q128 58 212 74 Q214 84 200 84 Q128 70 56 84 Q42 84 44 74 Z" fill="#f0b323" {line(9)}/>'
           f'<path d="{circle_d(128, 42, 13)}" fill="#fff8b0" {line(7)}/>')
    parts, defs = walker(fur, body_extra=belly, face=face, head_extra=hat)
    parts["paw_l"] = claw(88)
    parts["paw_r"] = claw(168)
    return parts, defs

def mushroom():
    # The stem is the body (with the face on it); the cap is the "head".
    stem = "M84 130 L172 130 Q194 172 198 196 Q200 208 182 208 L74 208 Q56 208 58 196 Q62 172 84 130 Z"
    face = (f'<circle cx="108" cy="166" r="8" fill="{CAT_EYE}"/><circle cx="148" cy="166" r="8" fill="{CAT_EYE}"/>'
            f'<path d="M116 184 Q128 194 140 184" fill="none" stroke="{CAT_EYE}" stroke-width="7" stroke-linecap="round"/>')
    cap = "M24 130 Q22 40 128 26 Q234 40 232 130 Q128 112 24 130 Z"
    spots = "".join(f'<path d="{circle_d(cx, cy, r)}" fill="#fff8e7"/>' for cx, cy, r in ((80, 76, 16), (140, 58, 13), (186, 90, 15), (118, 100, 9)))
    wdefs, wbody = U.weapon("thuoc", 140, 92, 0.75, "w")
    parts = {"leg_l": leg(92, "#f5e6c8"), "leg_r": leg(164, "#f5e6c8"),
             "body": f'<path d="{stem}" fill="#f5e6c8" {line()}/>' + face,
             # No hook paws: on the stem they would cover the face; the potion is held at the side.
             "head": f'<path d="{cap}" fill="#e0504a" {line()}/>' + spots,
             "weapon": wbody}
    return parts, wdefs

def bomb():
    return (f'<path d="{circle_d(186, 150, 30)}" fill="#3a3a44" {line(9)}/><path d="{ellipse_d(176, 140, 8, 6)}" fill="#8a8a96"/>'
            f'<path d="M200 124 Q210 106 224 104" fill="none" stroke="#c9a26b" stroke-width="6" stroke-linecap="round"/>'
            f'<path d="M226 90 L229 97 L236 100 L229 103 L226 110 L223 103 L216 100 L223 97 Z" fill="#ffb938"/>')

WALKERS = {
    "warrior": (lambda: goblin("kiem"), "slash"),
    "archer": (lambda: goblin("cung"), "shoot"),
    "smith": (lambda: goblin("bua", extra=f'<g clip-path="url(#body)"><path d="M92 148 L164 148 L160 204 L96 204 Z" fill="#6b4a2e" {line(8)}/></g>'), "slash"),
    "bomber": (lambda: goblin(held=bomb()), "shoot"),
    "lancer": (lambda: skeleton("giao"), "slash"),
    "guard": (lambda: skeleton("cu_kiem", shield=True), "slash"),
    "fire_archer": (lambda: skeleton("no", eye="#ff7a2a"), "shoot"),
    "miner": (mole, "slash"),
    "monk": (mushroom, "cast"),
    "cook": (lambda: orc("chuy", hat=CHEF_HAT), "cast"),
    "general": (lambda: orc("riu", king=True), "slash"),
}
MONSTER_PIVOTS = dict(PIVOTS, head=[128, 132])
# The mushroom has no paws; its potion still needs a parent bone, so it rides the body.

# --- Slime and bat: their own bones and moves --------------------------------------------

def slime_parts():
    blob = "M40 222 Q28 150 78 110 Q128 72 178 110 Q228 150 216 222 Q128 238 40 222 Z"
    face = (f'<circle cx="106" cy="162" r="10" fill="{CAT_EYE}"/><circle cx="150" cy="162" r="10" fill="{CAT_EYE}"/>'
            f'<path d="M116 184 Q128 194 140 184" fill="none" stroke="{CAT_EYE}" stroke-width="7" stroke-linecap="round"/>')
    return {"body": f'<path d="{blob}" fill="#7fd99a" {line()}/><path d="{ellipse_d(96, 128, 18, 10)}" fill="#c9f0d4"/>',
            "face": face}, ""

def slime_anims():
    run_t = [0, 0.12, 0.26, 0.38, 0.5]
    att_t = [0, 0.16, 0.24, 0.34, 0.5]
    return {
        "idle": {"bones": {"body": {"scale": keys([0, 0.5, 1.0], x=[1, 1.05, 1], y=[1, 0.95, 1])}}},
        # Squash, spring up and stretch, land and squash: one hop.
        "run": {"bones": {"body": {"translate": keys(run_t, x=[0, 0, 0, 0, 0], y=[0, 0, 26, 0, 0]),
                                   "scale": keys(run_t, x=[1.12, 1.18, 0.9, 1.15, 1.12], y=[0.88, 0.82, 1.12, 0.85, 0.88])},
                          "face": {"translate": keys(run_t, x=[0, 0, 0, 0, 0], y=[-3, -5, 3, -4, -3])}}},
        # Lean back, then a bouncing body slam forward.
        "attack": {"bones": {"body": {"translate": keys(att_t, x=[0, -10, 18, 8, 0], y=[0, 0, 10, 0, 0]),
                                      "scale": keys(att_t, x=[1, 1.15, 0.88, 1.1, 1], y=[1, 0.85, 1.12, 0.92, 1]),
                                      "rotate": keys(att_t, value=[0, 8, -12, -4, 0])}},
                   "events": [{"time": 0.24, "name": "hit"}]},
    }

def bat_parts():
    parts = {}
    for side, sx in (("wing_l", 1), ("wing_r", -1)):
        def x(v, sx=sx):
            return 128 + sx * (v - 128)
        wing = f"M{x(100)} 130 Q{x(60)} 70 {x(8)} 92 Q{x(26)} 120 {x(16)} 150 Q{x(44)} 146 {x(46)} 172 Q{x(74)} 160 {x(100)} 176 Z"
        parts[side] = f'<path d="{wing}" fill="#5b4583" {line(10)}/>'
    ear_art = "".join(f'<path d="M{128 + sx * -32} 98 L{128 + sx * -44} 54 L{128 + sx * -12} 84 Z" fill="#7b5ea7" {line(9)}/>' for sx in (1, -1))
    body = ear_art + f'<path d="{circle_d(128, 140, 54)}" fill="#7b5ea7" {line()}/><path d="{ellipse_d(128, 168, 30, 20)}" fill="#9a7dc6"/>'
    body += (f'<circle cx="108" cy="130" r="12" fill="#ffffff" {line(5)}/><circle cx="148" cy="130" r="12" fill="#ffffff" {line(5)}/>'
             '<circle cx="110" cy="132" r="5" fill="#e0504a"/><circle cx="146" cy="132" r="5" fill="#e0504a"/>'
             f'<path d="M114 156 L120 168 L126 156 M130 156 L136 168 L142 156" fill="#ffffff" stroke="{CAT_LINE}" stroke-width="4" stroke-linejoin="round"/>')
    parts["body"] = body
    return {"wing_l": parts["wing_l"], "wing_r": parts["wing_r"], "body": parts["body"]}, ""

def bat_anims():
    def flap(period, lift):
        t = [0, period / 2, period]
        return {"wing_l": {"rotate": keys(t, value=[18, -26, 18])}, "wing_r": {"rotate": keys(t, value=[-18, 26, -18])},
                "body": {"translate": keys(t, x=[0, 0, 0], y=[0, lift, 0])}}
    att_t = [0, 0.14, 0.22, 0.32, 0.5]
    attack = {"wing_l": {"rotate": keys(att_t, value=[0, -34, 30, 10, 0])}, "wing_r": {"rotate": keys(att_t, value=[0, 34, -30, -10, 0])},
              "body": {"translate": keys(att_t, x=[0, -6, 16, 8, 0], y=[0, 14, -10, -4, 0]),
                       "rotate": keys(att_t, value=[0, 10, -16, -6, 0])}}
    return {"idle": {"bones": flap(0.5, 6)}, "run": {"bones": flap(0.24, 10)},
            "attack": {"bones": attack, "events": [{"time": 0.22, "name": "hit"}]}}

SPECIAL = {
    "pawn": (slime_parts, slime_anims, {"body": ("root", [128, 226]), "face": ("body", [128, 170])}),
    "assassin": (bat_parts, bat_anims, {"body": ("root", [128, 140]), "wing_l": ("body", [104, 132]), "wing_r": ("body", [152, 132])}),
}

def build_special(uid):
    make_parts, make_anims, bones_spec = SPECIAL[uid]
    layers, defs = make_parts()
    folder = WORK / uid
    write_svgs(folder, layers, defs)
    out = folder / "spine"
    out.mkdir(exist_ok=True)
    parts = spine.render_parts(folder, list(layers))
    page = spine.pack({n: im for n, (im, _) in parts.items()}, uid, out)
    world = {"root": (0, 0)}
    bones = [{"name": "root"}]
    for b, (parent, pivot) in bones_spec.items():
        wx, wy = to_skel(*pivot)
        world[b] = (wx, wy)
        px, py = world[parent]
        bones.append({"name": b, "parent": parent, "x": round(wx - px, 2), "y": round(wy - py, 2)})
    k = 1 / spine.RENDER_SCALE
    slots, atts = [], {}
    for n in layers:
        im, box = parts[n]
        cx, cy = to_skel((box[0] + box[2]) / 2 * k, (box[1] + box[3]) / 2 * k)
        bx, by = world[n]
        slots.append({"name": n, "bone": n, "attachment": n})
        atts[n] = {n: {"x": round(cx - bx, 2), "y": round(cy - by, 2), "scaleX": k, "scaleY": k, "width": im.width, "height": im.height}}
    skel = {"skeleton": {"spine": "4.2.0", "x": -128, "y": -8, "width": 256, "height": 240, "images": "./", "audio": ""},
            "bones": bones, "slots": slots, "skins": [{"name": "default", "attachments": atts}],
            "events": {"hit": {}}, "animations": make_anims()}
    (out / f"{uid}.json").write_text(json.dumps(skel, indent=1), encoding="utf-8")
    print(out / f"{uid}.json", f"{len(bones)} bones, {len(slots)} slots, page {page[0]}x{page[1]}")
    install(folder, uid)

def write_svgs(folder, layers, defs):
    (folder / "svg").mkdir(parents=True, exist_ok=True)
    for name, body in layers.items():
        (folder / "svg" / f"{name}.svg").write_text(svg(256, 240, body, defs), encoding="utf-8")
    (folder / "svg" / "assembled.svg").write_text(svg(256, 240, "".join(layers.values()), defs), encoding="utf-8")

def install(folder, uid):
    dest = GAME / uid
    dest.mkdir(parents=True, exist_ok=True)
    for ext in ("json", "atlas", "png"):
        shutil.copy(folder / "spine" / f"{uid}.{ext}", dest / f"{uid}.{ext}")

def build_walker(uid):
    make, style = WALKERS[uid]
    layers, defs = make()
    folder = WORK / uid
    write_svgs(folder, layers, defs)
    order = list(layers)
    (folder / "rig.json").write_text(json.dumps({"order": order, "pivots": {k: MONSTER_PIVOTS[k] for k in order}}), encoding="utf-8")
    spine.main(folder, uid, style)
    install(folder, uid)

def main(ids):
    for uid in ids or list(WALKERS) + list(SPECIAL):
        (build_special if uid in SPECIAL else build_walker)(uid)

if __name__ == "__main__":
    main(sys.argv[1:])
