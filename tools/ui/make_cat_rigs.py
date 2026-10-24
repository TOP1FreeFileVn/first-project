"""Draw every cat soldier and general as separate rig parts, then build its Spine skeleton.

The construction is the reviewed sword cat (docs/design/2026-10-23/soldier-rig-v2/cat.js):
one rounded body with its coat marks kept inside it, two leg stubs drawn behind the body
(only the feet show), hook paws at the chest, the right paw drawn again over the weapon grip.
Clothes, headgear, capes and weapons come from make_units.py so every cat keeps its look.

    python -I tools/ui/make_cat_rigs.py [unit_id ...]     (default: all 16 soldiers)
Writes game/assets/units/<unit_id>/<unit_id>.{json,atlas,png} (Spine 4.2) via make_soldier_spine.
Work files (part SVGs, renders): docs/design/2026-10-23/cat-rigs/<unit_id>/.
"""
import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import make_svgs as base
import make_units as U
import make_soldier_spine as spine
from make_svgs import CAT_EYE, CAT_HEAD, CAT_LINE, ellipse_d, svg

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "docs" / "design" / "2026-10-23" / "cat-rigs"
GAME = ROOT / "game" / "assets" / "units"
W = 9   # the accepted main line

# Body with its bottom at y206 so ~28 px of each foot shows below it.
BODY = ("M80 118 L176 118 Q204 118 206 150 L207 182 Q208 206 180 206 L76 206 Q48 206 49 182 "
        "L50 150 Q52 118 80 118 Z")
TAIL = "M186 198 Q236 204 232 158 Q230 142 218 142"
L_PAW = "M104 150 Q114 164 106 172 Q97 179 84 170"
R_PAW = "M152 150 Q142 164 150 172 Q159 181 172 170"
PIVOTS = {"tail": [186, 200], "cape": [128, 128], "leg_l": [90, 190], "leg_r": [166, 190], "body": [128, 200],
          "paw_l": [104, 150], "head": [128, 140], "weapon": [156, 168], "paw_r": [152, 150]}
STYLE = {U.INF: "slash", U.CAV: "slash", U.RNG: "shoot", U.MAG: "cast"}

def line(width=W):
    return f'stroke="{CAT_LINE}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"'

def clip(name, d):
    return f'<clipPath id="{name}"><path d="{d}"/></clipPath>'

def leg(x, fill):
    d = f"M{x - 20} 176 L{x - 21} 218 Q{x - 21} 235 {x} 235 Q{x + 21} 235 {x + 21} 218 L{x + 20} 176 Z"
    toes = "".join(f'<path d="M{x + dx} 226 L{x + dx} 233" {line(4)}/>' for dx in (-7, 7))
    return f'<path d="{d}" fill="{fill}" {line()}/>' + toes

def coat_marks(kind, region):
    """Stripes / patches for the body or head, clipped to that shape."""
    fill, marks = U.coat_of(kind)
    if kind in ("tabby", "grey"):
        if region == "body":
            strokes = "".join(f'<path d="M44 {y} Q68 {y + 6} 92 {y}" fill="none" stroke="{marks}" stroke-width="8" stroke-linecap="round"/>'
                              f'<path d="M164 {y} Q188 {y + 6} 212 {y}" fill="none" stroke="{marks}" stroke-width="8" stroke-linecap="round"/>'
                              for y in (150, 168, 186))
        else:
            strokes = "".join(f'<path d="M{a} {y} Q{(a + b) / 2} {y + 4} {b} {y}" fill="none" stroke="{marks}" stroke-width="7" stroke-linecap="round"/>'
                              for a, b, y in ((36, 60, 100), (36, 58, 116), (196, 220, 100), (198, 220, 116)))
        return f'<g clip-path="url(#{region})">{strokes}</g>'
    if kind == "calico":
        shape = ellipse_d(170, 186, 30, 24) if region == "body" else ellipse_d(78, 76, 40, 34) + ellipse_d(186, 70, 30, 26)
        if region == "head":
            return (f'<g clip-path="url(#head)"><path d="{ellipse_d(78, 76, 40, 34)}" fill="{marks[0]}"/>'
                    f'<path d="{ellipse_d(186, 70, 30, 26)}" fill="{marks[1]}"/></g>')
        return f'<g clip-path="url(#body)"><path d="{shape}" fill="{marks[0]}"/></g>'
    return ""

def outfit(klass, trim, dark):
    """make_units.outfit, lifted to fit the shorter body (its hems ended near y204-226)."""
    shift = {U.INF: -6, U.RNG: -12, U.MAG: -22, U.CAV: -6}[klass]
    return f'<g clip-path="url(#body)"><g transform="translate(0 0) scale(1 {1 + shift / 100})">{U.outfit(klass, trim, dark)}</g></g>'

def parts(kind, klass, rarity, weapon_name, general=False):
    trim = U.TRIM[rarity]
    dark = kind == "black"
    fill, _ = U.coat_of(kind)
    defs = clip("body", BODY) + clip("head", CAT_HEAD)
    tail = (f'<path d="{TAIL}" fill="none" stroke="{CAT_LINE}" stroke-width="{13 + 2 * W}" stroke-linecap="round"/>'
            f'<path d="{TAIL}" fill="none" stroke="{fill}" stroke-width="13" stroke-linecap="round"/>')
    body = (f'<path d="{BODY}" fill="{fill}"/>' + coat_marks(kind, "body") + outfit(klass, trim, dark)
            + f'<path d="{BODY}" fill="none" {line()}/>')
    head = (f'<path d="{CAT_HEAD}" fill="{fill}"/>' + coat_marks(kind, "head") + f'<path d="{CAT_HEAD}" fill="none" {line()}/>'
            f'<circle cx="104" cy="96" r="9" fill="{CAT_EYE}"/><circle cx="152" cy="96" r="9" fill="{CAT_EYE}"/>'
            f'<path d="M110 110 Q119 124 128 112 Q137 124 146 110" fill="none" stroke="{CAT_EYE}" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round"/>'
            + U.headgear(klass, trim, dark))
    if general:   # small gold crown pinned on the headgear's side
        head += f'<path d="M150 26 L156 6 L166 20 L176 2 L184 22 L194 10 L194 32 Z" fill="#ffd23f" {line(6)}/>'
    wdefs, wbody = U.weapon(weapon_name, 130, 54, 1.0, "w")
    out = {"tail": tail}
    if rarity == 3 or general:
        out["cape"] = f'<g transform="translate(0 16) scale(1 0.86)">{U.cape(trim if general else "#ffd23f")}</g>'
    out.update({"leg_l": leg(90, fill), "leg_r": leg(166, fill), "body": body,
                "paw_l": f'<path d="{L_PAW}" fill="none" {line(13)}/>', "head": head, "weapon": wbody,
                "paw_r": f'<path d="{R_PAW}" fill="none" {line(13)}/>'})
    return out, defs + wdefs

def roster():
    for tid, klass, rarity, weapon_name in U.SOLDIERS:
        yield tid, (U.COAT[klass], klass, rarity, weapon_name, False)

def build(uid, spec):
    kind, klass, rarity, weapon_name, general = spec
    layers, defs = parts(kind, klass, rarity, weapon_name, general)
    folder = WORK / uid
    (folder / "svg").mkdir(parents=True, exist_ok=True)
    for name, body in layers.items():
        (folder / "svg" / f"{name}.svg").write_text(svg(256, 240, body, defs), encoding="utf-8")
    (folder / "svg" / "assembled.svg").write_text(svg(256, 240, "".join(layers.values()), defs), encoding="utf-8")
    order = list(layers)
    (folder / "rig.json").write_text(json.dumps({"order": order, "pivots": {k: PIVOTS[k] for k in order}}), encoding="utf-8")
    spine.main(folder, uid, STYLE[klass])
    dest = GAME / uid
    dest.mkdir(parents=True, exist_ok=True)
    for ext in ("json", "atlas", "png"):
        shutil.copy(folder / "spine" / f"{uid}.{ext}", dest / f"{uid}.{ext}")

def main(ids):
    specs = dict(roster())
    for uid in ids or specs:
        build(uid, specs[uid])

if __name__ == "__main__":
    main(sys.argv[1:])
