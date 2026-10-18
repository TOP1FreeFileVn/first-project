"""Unit sprites in the flat cat style (see the cat-sprite-art skill): the 16 cat soldiers,
the cat generals and the dungeon monsters that replaced the old human troops.

Each sprite is one 256x240 SVG `game/ui/skin/unit_<id>.svg` with the held weapon baked in
(the weapon icon from make_svgs.make_weapons, embedded). SpriteLib loads them for unit keys
"art:<id>" and Unit.gd animates them (hop, lean, swing).

Run after make_svgs.py (make_svgs.main calls this too):  python -I tools/ui/make_units.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import make_svgs as base
from make_svgs import CAT_BODY, CAT_EAR, CAT_EYE, CAT_HEAD, CAT_LINE, CATS, circle_d, ellipse_d, poly, svg

INF, RNG, MAG, CAV = range(4)
COAT = {INF: "tabby", RNG: "grey", MAG: "calico", CAV: "cream"}
## Trim colour by rarity: leather, blue, purple, gold.
TRIM = ["#b98a5a", "#5fb0ea", "#b07be6", "#ffd23f"]
STEEL, BRONZE, LEAF, ROBE, TABARD = "#c9d3dd", "#d9a35a", "#6aa84f", "#5b6fd6", "#d9534f"
L_PAW = "M104 152 Q114 166 106 174 Q97 181 84 172"
R_PAW = "M152 152 Q142 166 150 174 Q159 181 172 172"

# id, class, rarity, weapon icon (the 16 soldiers of the "Solider (sửa)" tab)
SOLDIERS = [
    ("kiem", INF, 0, "kiem"), ("riu", INF, 1, "riu"), ("dao", INF, 2, "dao"), ("katana", INF, 3, "katana"),
    ("cung", RNG, 0, "cung"), ("no", RNG, 1, "no"), ("sung", RNG, 2, "sung"), ("dai_bac", RNG, 3, "dai_bac"),
    ("gay_phep", MAG, 0, "gay_phep"), ("thuoc", MAG, 1, "thuoc"), ("sach_phep", MAG, 2, "sach_phep"), ("dua_phep", MAG, 3, "dua_phep"),
    ("giao", CAV, 0, "giao"), ("cu_kiem", CAV, 1, "cu_kiem"), ("chuy", CAV, 2, "chuy"), ("bua", CAV, 3, "bua"),
]
# Generals (Heroes.gd ids): coat, class outfit, rarity trim, weapon. They always wear a cape.
GENERALS = {
    "valor": ("tabby", INF, 3, "katana"), "storm": ("cream", CAV, 3, "giao"), "ember": ("grey", RNG, 2, "no"),
    "sage": ("calico", MAG, 2, "gay_phep"), "iron": ("grey", INF, 1, "cu_kiem"), "shadow": ("black", RNG, 1, "dao"),
}
EXTRA_COATS = {"black": ("#5a5260", "#433c48")}


def line(width=12):
    return f'stroke="{CAT_LINE}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"'


def stroke_path(d, width=13):
    return f'<path d="{d}" fill="none" {line(width)}/>'


_WEAPONS = None


def weapon(name, x, y, scale, tag):
    """The weapon icon's art as a group at (x, y), ids renamed so several can share a file."""
    global _WEAPONS
    if _WEAPONS is None:
        _WEAPONS = base.make_weapons()
    # The flat (cat style) drawing; it has no <defs> of its own.
    # Outline as heavy as the cat's 12 px line (a bit less, so thin handles survive).
    text = _WEAPONS[name].flat_svg(128, line=10.0 / scale)
    body = text[text.index(">", text.index("<svg")) + 1:text.rindex("</svg>")]
    return "", f'<g transform="translate({x} {y}) scale({scale})">{body}</g>'


def coat_of(kind):
    return EXTRA_COATS.get(kind) or CATS[kind]


# --- Cats -------------------------------------------------------------------------------------

def cat_parts(kind):
    """Body (with its marks) and head (with marks, outline and face) of a plain cat, no ears."""
    fill, marks = coat_of(kind)
    tail = "M182 210 Q236 214 232 166 Q230 150 220 150"
    back = f'<path d="{tail}" fill="none" stroke="{CAT_LINE}" stroke-width="30" stroke-linecap="round"/>'
    back += f'<path d="{tail}" fill="none" stroke="{fill}" stroke-width="13" stroke-linecap="round"/>'
    body = f'<path d="{CAT_BODY}" fill="{fill}" {line()}/>'
    if kind in ("tabby", "grey"):
        body += '<g clip-path="url(#body)">' + "".join(
            f'<path d="M50 {y} Q72 {y + 6} 92 {y}" fill="none" stroke="{marks}" stroke-width="8" stroke-linecap="round"/>'
            f'<path d="M164 {y} Q184 {y + 6} 206 {y}" fill="none" stroke="{marks}" stroke-width="8" stroke-linecap="round"/>'
            for y in (150, 172, 194)) + "</g>"
    if kind == "calico":
        body += f'<g clip-path="url(#body)"><path d="{ellipse_d(170, 196, 30, 26)}" fill="{marks[0]}"/></g>'
        body += f'<path d="{CAT_BODY}" fill="none" {line()}/>'
    head = f'<path d="{CAT_HEAD}" fill="{fill}"/>'
    if kind in ("tabby", "grey"):
        head += '<g clip-path="url(#head)">' + "".join(
            f'<path d="M{a} {y} Q{(a + b) / 2} {y + 4} {b} {y}" fill="none" stroke="{marks}" stroke-width="7" stroke-linecap="round"/>'
            for a, b, y in ((36, 60, 100), (36, 58, 116), (196, 220, 100), (198, 220, 116))) + "</g>"
    if kind == "calico":
        head += f'<g clip-path="url(#head)"><path d="{ellipse_d(78, 76, 40, 34)}" fill="{marks[0]}"/><path d="{ellipse_d(186, 70, 30, 26)}" fill="{marks[1]}"/></g>'
    head += f'<path d="{CAT_HEAD}" fill="none" {line()}/>'
    head += f'<circle cx="104" cy="96" r="9" fill="{CAT_EYE}"/><circle cx="152" cy="96" r="9" fill="{CAT_EYE}"/>'
    head += f'<path d="M110 110 Q119 124 128 112 Q137 124 146 110" fill="none" stroke="{CAT_EYE}" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round"/>'
    return back, body, head


def outfit(klass, trim, dark=False):
    """Clothes over the body, per class; `trim` is the rarity colour."""
    if klass == INF:  # steel breastplate with a trim belt
        out = f'<path d="M84 130 L172 130 Q184 168 170 198 L86 198 Q72 168 84 130 Z" fill="{STEEL}" {line(10)}/>'
        out += '<path d="M128 138 L128 186" stroke="#aab6c2" stroke-width="6" stroke-linecap="round"/>'
        out += f'<path d="M86 190 L170 190" stroke="{trim}" stroke-width="10" stroke-linecap="round"/>'
    elif klass == RNG:  # tunic and the quiver strap
        tunic = "#3f3a4a" if dark else LEAF
        out = f'<path d="M84 130 L172 130 Q186 170 172 204 L84 204 Q70 170 84 130 Z" fill="{tunic}" {line(10)}/>'
        out += '<path d="M92 134 L168 198" stroke="#8a5634" stroke-width="10" stroke-linecap="round"/>'
        out += f'<circle cx="128" cy="166" r="7" fill="{trim}" {line(5)}/>'
    elif klass == MAG:  # long robe with a trimmed hem
        out = f'<path d="M80 128 L176 128 Q194 186 204 226 L52 226 Q62 186 80 128 Z" fill="{ROBE}" {line(10)}/>'
        out += f'<path d="M58 214 Q128 228 198 214" fill="none" stroke="{trim}" stroke-width="9" stroke-linecap="round"/>'
        out += f'<path d="M128 132 L128 218" stroke="{trim}" stroke-width="6" stroke-linecap="round"/>'
    else:  # cavalry tabard with an emblem
        out = f'<path d="M90 128 L166 128 L172 210 L128 198 L84 210 Z" fill="{TABARD}" {line(10)}/>'
        out += f'<circle cx="128" cy="160" r="13" fill="{trim}" {line(6)}/>'
    return out


def headgear(klass, trim, dark=False):
    if klass == INF:  # kettle hat: a steel dome with a wide brim and a trim band
        out = f'<path d="M62 70 Q62 18 128 16 Q194 18 194 70 Z" fill="{STEEL}" {line()}/>'
        out += f'<path d="M36 72 Q128 50 220 72 Q224 86 208 86 Q128 66 48 86 Q32 86 36 72 Z" fill="{STEEL}" {line(10)}/>'
        out += f'<path d="M68 62 Q128 46 188 62" fill="none" stroke="{trim}" stroke-width="9" stroke-linecap="round"/>'
    elif klass == RNG:  # hood with cat-ear points and a feather
        hood = "#3f3a4a" if dark else LEAF
        out = f'<path d="M36 104 Q30 44 58 16 L80 34 Q128 18 176 34 L198 16 Q226 44 220 104 Q204 66 128 60 Q52 66 36 104 Z" fill="{hood}" {line()}/>'
        out += f'<path d="M190 40 Q222 10 236 22 Q220 30 200 50 Z" fill="{trim}" {line(6)}/>'
    elif klass == MAG:  # wizard hat bent at the tip, trim band and star
        out = f'<path d="M66 58 Q104 40 116 6 Q122 -8 134 2 Q150 30 190 58 Z" fill="{ROBE}" {line()}/>'
        out += f'<path d="M34 62 Q128 40 222 62 Q226 74 210 76 Q128 58 46 76 Q30 74 34 62 Z" fill="{ROBE}" {line(10)}/>'
        out += f'<path d="M80 52 Q128 38 176 52" fill="none" stroke="{trim}" stroke-width="8" stroke-linecap="round"/>'
        out += f'<path d="{poly(base.star_pts(132, 30, 11, 5, 5))}" fill="#ffe14d"/>'
    else:  # bronze helmet with a standing brush crest
        crest = trim if trim != TRIM[0] else "#e0504a"
        out = f'<path d="M78 50 Q86 6 128 4 Q170 6 178 50 Q128 30 78 50 Z" fill="{crest}" {line(9)}/>'
        out += f'<path d="M56 76 Q54 26 128 24 Q202 26 200 76 Q128 60 56 76 Z" fill="{BRONZE}" {line()}/>'
        out += '<path d="M66 68 Q128 52 190 68" fill="none" stroke="#b07a35" stroke-width="7" stroke-linecap="round"/>'
    return out


def cape(trim):
    out = f'<path d="M60 128 L196 128 L228 226 Q128 244 28 226 Z" fill="#c9443f" {line()}/>'
    out += f'<path d="M34 218 Q128 236 222 218" fill="none" stroke="{trim}" stroke-width="8" stroke-linecap="round"/>'
    return out


def cat_soldier(kind, klass, rarity, weapon_name, general=False):
    trim = TRIM[rarity]
    dark = kind == "black"
    defs = f'<clipPath id="head"><path d="{CAT_HEAD}"/></clipPath><clipPath id="body"><path d="{CAT_BODY}"/></clipPath>'
    back, body, head = cat_parts(kind)
    out = back
    if rarity == 3 or general:
        out += cape(trim if general else "#ffd23f")
    out += body + outfit(klass, trim, dark)
    out += stroke_path(L_PAW) + stroke_path(R_PAW)
    out += head + headgear(klass, trim, dark)
    if general:  # small gold crown pinned on the headgear's side
        out += f'<path d="M150 26 L156 6 L166 20 L176 2 L184 22 L194 10 L194 32 Z" fill="#ffd23f" {line(6)}/>'
    wdefs, wbody = weapon(weapon_name, 130, 54, 1.0, "w")
    out += wbody + stroke_path(R_PAW)
    return svg(256, 240, out, defs + wdefs)


# --- Monsters (the dungeon enemies) -----------------------------------------------------------

GOBLIN, GOBLIN_DARK = "#8fcf5a", "#6fae44"
BONE, BONE_DARK = "#f1ede2", "#c9c2b0"
ORC, ORC_DARK = "#6fa85a", "#4f8a3f"


def grumpy_face(eye=CAT_EYE, y=96):
    out = f'<circle cx="104" cy="{y}" r="9" fill="{eye}"/><circle cx="152" cy="{y}" r="9" fill="{eye}"/>'
    out += f'<path d="M88 {y - 18} L114 {y - 10}" stroke="{CAT_EYE}" stroke-width="7" stroke-linecap="round"/>'
    out += f'<path d="M168 {y - 18} L142 {y - 10}" stroke="{CAT_EYE}" stroke-width="7" stroke-linecap="round"/>'
    out += f'<path d="M108 {y + 20} Q128 {y + 30} 148 {y + 20}" fill="none" stroke="{CAT_EYE}" stroke-width="7" stroke-linecap="round"/>'
    out += f'<path d="M116 {y + 22} L120 {y + 31} L125 {y + 24} Z" fill="#ffffff"/>'
    return out


def humanoid(skin, skin_dark, ears=True, ear_shape="goblin"):
    """Cat-like body and bun head in a monster skin, with long goblin ears or none."""
    out = f'<path d="{CAT_BODY}" fill="{skin}" {line()}/>'
    out += stroke_path(L_PAW) + stroke_path(R_PAW)
    if ears:
        for sx in (1, -1):
            def x(v, sx=sx):
                return 128 + sx * (v - 128)
            out += f'<path d="M{x(52)} 84 L{x(2)} 58 Q{x(0)} 52 {x(8)} 54 L{x(56)} 66 Z" fill="{skin}" {line(10)}/>'
            out += f'<path d="M{x(44)} 74 L{x(16)} 60 L{x(46)} 66 Z" fill="{skin_dark}"/>'
    out += f'<path d="{CAT_HEAD}" fill="{skin}" {line()}/>'
    return out


def goblin(weapon_name=None, extra="", held=""):
    out = humanoid(GOBLIN, GOBLIN_DARK)
    out += f'<path d="M84 130 L172 130 Q186 170 172 204 L84 204 Q70 170 84 130 Z" fill="#9c6b3c" {line(10)}/>' + extra
    out += stroke_path(L_PAW) + stroke_path(R_PAW)
    out += grumpy_face("#c9302c")
    defs = ""
    if weapon_name:
        defs, wbody = weapon(weapon_name, 130, 54, 1.0, "w")
        out += wbody + stroke_path(R_PAW)
    return svg(256, 240, out + held, defs)


def skeleton(weapon_name, eye="#5fd0ff", shield=False):
    out = f'<path d="{CAT_BODY}" fill="{BONE}" {line()}/>'
    out += '<path d="M128 126 L128 220" stroke="#c9c2b0" stroke-width="8" stroke-linecap="round"/>'
    for y in (148, 168, 188):
        out += f'<path d="M86 {y} Q128 {y + 10} 170 {y}" fill="none" stroke="{BONE_DARK}" stroke-width="7" stroke-linecap="round"/>'
    out += stroke_path(L_PAW) + stroke_path(R_PAW)
    out += f'<path d="{CAT_HEAD}" fill="{BONE}" {line()}/>'
    for cx in (100, 156):
        out += f'<path d="{ellipse_d(cx, 92, 18, 16)}" fill="{CAT_EYE}"/><circle cx="{cx}" cy="94" r="5" fill="{eye}"/>'
    out += f'<path d="M122 116 L128 106 L134 116 Z" fill="{CAT_EYE}"/>'
    out += f'<rect x="102" y="122" width="52" height="14" rx="4" fill="#ffffff" {line(5)}/>'
    for xx in (115, 128, 141):
        out += f'<path d="M{xx} 123 L{xx} 135" stroke="{CAT_LINE}" stroke-width="4"/>'
    if shield:
        out += f'<path d="{circle_d(70, 176, 40)}" fill="#8f9cab" {line(10)}/><path d="{circle_d(70, 176, 14)}" fill="#ffd23f" {line(6)}/>'
    defs, wbody = weapon(weapon_name, 130, 54, 1.0, "w")
    return svg(256, 240, out + wbody + stroke_path(R_PAW), defs)


def orc(weapon_name, hat="", king=False):
    out = ""
    if king:
        out += cape("#ffd23f")
    out += humanoid(ORC, ORC_DARK)
    out += f'<path d="M84 130 L172 130 Q186 170 172 204 L84 204 Q70 170 84 130 Z" fill="{"#7a3d2a" if king else "#ffffff"}" {line(10)}/>'
    out += stroke_path(L_PAW) + stroke_path(R_PAW)
    out += grumpy_face(CAT_EYE)
    for sx in (1, -1):  # tusks
        x0 = 128 + sx * 22
        out += f'<path d="M{x0 - 6} 120 L{x0} 100 L{x0 + 6} 120 Z" fill="#fff8e7" {line(5)}/>'
    if king:
        out += f'<path d="M78 44 L86 6 L106 28 L128 0 L150 28 L170 6 L178 44 Q128 30 78 44 Z" fill="#ffd23f" {line(9)}/>'
        out += f'<circle cx="128" cy="26" r="7" fill="#e0504a" {line(4)}/>'
    out += hat
    defs, wbody = weapon(weapon_name, 130, 54, 1.0, "w")
    return svg(256, 240, out + wbody + stroke_path(R_PAW), defs)


def slime():
    blob = "M40 222 Q28 150 78 110 Q128 72 178 110 Q228 150 216 222 Q128 238 40 222 Z"
    out = f'<path d="{blob}" fill="#7fd99a" {line()}/>'
    out += f'<path d="{ellipse_d(96, 128, 18, 10)}" fill="#ffffff" fill-opacity="0.55"/>'
    out += f'<circle cx="106" cy="162" r="10" fill="{CAT_EYE}"/><circle cx="150" cy="162" r="10" fill="{CAT_EYE}"/>'
    out += f'<path d="M116 184 Q128 194 140 184" fill="none" stroke="{CAT_EYE}" stroke-width="7" stroke-linecap="round"/>'
    return svg(256, 240, out)


def bat():
    out = ""
    for sx in (1, -1):
        def x(v, sx=sx):
            return 128 + sx * (v - 128)
        wing = f"M{x(100)} 130 Q{x(60)} 70 {x(8)} 92 Q{x(26)} 120 {x(16)} 150 Q{x(44)} 146 {x(46)} 172 Q{x(74)} 160 {x(100)} 176 Z"
        out += f'<path d="{wing}" fill="#5b4583" {line(10)}/>'
        out += f'<path d="M{x(96)} 98 L{x(84)} 54 L{x(116)} 84 Z" fill="#7b5ea7" {line(9)}/>'
    out += f'<path d="{circle_d(128, 140, 54)}" fill="#7b5ea7" {line()}/>'
    out += f'<path d="{ellipse_d(128, 168, 30, 20)}" fill="#9a7dc6"/>'
    out += f'<circle cx="108" cy="130" r="12" fill="#ffffff" {line(5)}/><circle cx="148" cy="130" r="12" fill="#ffffff" {line(5)}/>'
    out += '<circle cx="110" cy="132" r="5" fill="#e0504a"/><circle cx="146" cy="132" r="5" fill="#e0504a"/>'
    out += f'<path d="M114 156 L120 168 L126 156 M130 156 L136 168 L142 156" fill="#ffffff" stroke="{CAT_LINE}" stroke-width="4" stroke-linejoin="round"/>'
    return svg(256, 240, out)


def mole():
    fur = "#8a6a52"
    out = f'<path d="{CAT_BODY}" fill="{fur}" {line()}/>'
    out += f'<path d="{ellipse_d(128, 180, 34, 30)}" fill="#b08b6c"/>'
    for sx in (1, -1):  # big digging claws
        cx = 128 + sx * 40
        out += f'<path d="{ellipse_d(cx, 168, 20, 15)}" fill="#f2c9b5" {line(8)}/>'
        for k in (-10, 0, 10):
            out += f'<path d="M{cx + k} 178 L{cx + k} 192" stroke="#fff8e7" stroke-width="6" stroke-linecap="round"/>'
    out += f'<path d="{CAT_HEAD}" fill="{fur}" {line()}/>'
    out += f'<circle cx="106" cy="94" r="6" fill="{CAT_EYE}"/><circle cx="150" cy="94" r="6" fill="{CAT_EYE}"/>'
    out += f'<path d="{ellipse_d(128, 114, 18, 13)}" fill="#f28fa0" {line(7)}/>'
    # Miner's hard hat with a lamp.
    out += f'<path d="M62 70 Q62 22 128 20 Q194 22 194 70 Z" fill="#ffd23f" {line()}/>'
    out += f'<path d="M44 74 Q128 58 212 74 Q214 84 200 84 Q128 70 56 84 Q42 84 44 74 Z" fill="#f0b323" {line(9)}/>'
    out += f'<path d="{circle_d(128, 42, 13)}" fill="#fff8b0" {line(7)}/>'
    return svg(256, 240, out)


def mushroom():
    stem = "M84 130 L172 130 Q196 180 200 220 Q128 236 56 220 Q60 180 84 130 Z"
    out = f'<path d="{stem}" fill="#f5e6c8" {line()}/>'
    out += stroke_path(L_PAW) + stroke_path(R_PAW)
    out += f'<circle cx="108" cy="168" r="8" fill="{CAT_EYE}"/><circle cx="148" cy="168" r="8" fill="{CAT_EYE}"/>'
    out += f'<path d="M116 186 Q128 196 140 186" fill="none" stroke="{CAT_EYE}" stroke-width="7" stroke-linecap="round"/>'
    cap = "M24 130 Q22 40 128 26 Q234 40 232 130 Q128 112 24 130 Z"
    out += f'<path d="{cap}" fill="#e0504a" {line()}/>'
    for cx, cy, r in ((80, 76, 16), (140, 58, 13), (186, 90, 15), (118, 100, 9)):
        out += f'<path d="{circle_d(cx, cy, r)}" fill="#fff8e7"/>'
    defs, wbody = weapon("thuoc", 140, 92, 0.75, "w")
    return svg(256, 240, out + wbody + stroke_path(R_PAW), defs)


def bomb_held():
    out = f'<path d="{circle_d(186, 150, 30)}" fill="#3a3a44" {line(9)}/>'
    out += f'<path d="{ellipse_d(176, 140, 8, 6)}" fill="#8a8a96"/>'
    out += f'<path d="M200 124 Q210 106 224 104" fill="none" stroke="#c9a26b" stroke-width="6" stroke-linecap="round"/>'
    out += f'<path d="{poly(base.star_pts(226, 100, 10, 4, 5))}" fill="#ffb938"/>'
    return out + stroke_path(R_PAW)


ENEMIES = {
    "pawn": lambda: slime(),
    "warrior": lambda: goblin("kiem"),
    "archer": lambda: goblin("cung"),
    "miner": lambda: mole(),
    "smith": lambda: goblin("bua", extra=f'<path d="M92 150 L164 150 L160 210 L96 210 Z" fill="#6b4a2e" {line(8)}/>'),
    "lancer": lambda: skeleton("giao"),
    "assassin": lambda: bat(),
    "guard": lambda: skeleton("cu_kiem", shield=True),
    "fire_archer": lambda: skeleton("no", eye="#ff7a2a"),
    "monk": lambda: mushroom(),
    "cook": lambda: orc("chuy", hat=f'<path d="M80 52 Q60 20 92 14 Q110 -6 136 8 Q166 -4 176 22 Q200 30 176 54 Q128 40 80 52 Z" fill="#ffffff" {line(9)}/>'),
    "bomber": lambda: goblin(held=bomb_held()),
    "general": lambda: orc("riu", king=True),
}


def main():
    for tid, klass, rarity, weapon_name in SOLDIERS:
        base.save(f"unit_{tid}", cat_soldier(COAT[klass], klass, rarity, weapon_name))
    for hid, (kind, klass, rarity, weapon_name) in GENERALS.items():
        base.save(f"unit_hero_{hid}", cat_soldier(kind, klass, rarity, weapon_name, general=True))
    for tid, draw in ENEMIES.items():
        base.save(f"unit_{tid}", draw())
    print(f"{len(SOLDIERS)} soldiers, {len(GENERALS)} generals, {len(ENEMIES)} monsters written")


if __name__ == "__main__":
    main()
