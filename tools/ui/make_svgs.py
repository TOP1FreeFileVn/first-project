"""Generates the UI skin SVGs in game/ui/skin/ from the measured palette.

Every shape follows the measurements in .claude/skills/roguelike-idle-ui/reference/measurements.md.
Re-run after changing a colour or a proportion:  python -I tools/ui/make_svgs.py
(Hand edits to a generated SVG are lost on the next run; change this file instead.)
"""
import math
import os
import sys

OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join("game", "ui", "skin")

LINE = "#503737"
ICON_LINE = "#3c1e0c"
SHADOW = 'fill="#000000" fill-opacity="0.2"'
# Visible lobby/event features share the flat palette and brown line of the cats.
FLAT_FEATURE_ICONS = frozenset(("rail_limited", "rail_quest", "rail_online", "rail_checkin",
                                "rail_castle", "rail_patrol", "rail_event"))


def n(v):
    return ("%.2f" % v).rstrip("0").rstrip(".")


def svg(w, h, body, defs=""):
    head = f'<svg xmlns="http://www.w3.org/2000/svg" width="{n(w)}" height="{n(h)}" viewBox="0 0 {n(w)} {n(h)}">'
    return head + (f"<defs>{defs}</defs>" if defs else "") + body + "</svg>\n"


def rect(x, y, w, h, r, fill, extra=""):
    return f'<rect x="{n(x)}" y="{n(y)}" width="{n(w)}" height="{n(h)}" rx="{n(r)}" ry="{n(r)}" fill="{fill}"{extra}/>'


def poly(pts):
    return "M" + " L".join(f"{n(x)} {n(y)}" for x, y in pts) + " Z"


def circle_d(cx, cy, r):
    return f"M{n(cx - r)} {n(cy)} A{n(r)} {n(r)} 0 1 0 {n(cx + r)} {n(cy)} A{n(r)} {n(r)} 0 1 0 {n(cx - r)} {n(cy)} Z"


def ellipse_d(cx, cy, rx, ry):
    return f"M{n(cx - rx)} {n(cy)} A{n(rx)} {n(ry)} 0 1 0 {n(cx + rx)} {n(cy)} A{n(rx)} {n(ry)} 0 1 0 {n(cx - rx)} {n(cy)} Z"


def mix(a, b, t):
    a = [int(a[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join("%02x" % round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def lighten(c, t):
    return mix(c, "#ffffff", t)


## Art edited by hand (exported from the Figma page "Game · Art SVG (sửa được)") lives here
## under the same file name and wins over the generated version, so regenerating never
## throws away an edit. Delete an override to go back to the generated art.
OVERRIDES = os.path.join(os.path.dirname(OUT), "skin_overrides")


def save(name, content):
    override = os.path.join(OVERRIDES, name + ".svg")
    if os.path.exists(override):
        with open(override, encoding="utf-8") as fh:
            content = fh.read()
    with open(os.path.join(OUT, name + ".svg"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(content)


# --- Buttons (bth_*): outline thicker at the bottom, light rim, two-tone face, end glints --------

BUTTON_TONES = {  # light, dull, outline, rim
    "yellow": ("#faea76", "#ebc76d", "#c37c3c", "#fff480"),
    "orange": ("#ffbe8b", "#efa569", "#d37c45", "#ffc288"),
    "blue": ("#6bc6ef", "#51b4de", "#2c7ea2", "#79d7ff"),
    "green": ("#78ec80", "#59d961", "#4d8928", "#85f98d"),
    "red": ("#f56161", "#eb4e4d", "#ba3a38", "#ff6c6c"),
    "purple": ("#f68ff1", "#e66fe6", "#b54ab5", "#ffafff"),
    "grey": ("#cccccc", "#b2b2b2", "#808080", "#dadada"),
    "white": ("#f7f5f4", "#e2dedc", "#8c8582", "#ffffff"),
    "tab": ("#73a4de", "#6294d6", "#414a89", "#79acdf"),
}


def paw_mark(cx, cy, s, fill, opacity):
    """Small paw print (main pad + 4 toes) used as the button signature."""
    out = f'<g fill="{fill}" fill-opacity="{opacity}">'
    out += f'<path d="{ellipse_d(cx, cy + 3 * s, 6 * s, 5 * s)}"/>'
    for dx, dy in ((-7, -4), (-2.5, -8), (2.5, -8), (7, -4)):
        out += f'<path d="{ellipse_d(cx + dx * s, cy + dy * s, 2.3 * s, 2.8 * s)}"/>'
    return out + "</g>"


def button(tone, pressed):
    """Cat-game button, our own look (not Gear Defenders' bth_*): one shared dark-brown
    outline like the cat sprites, a flat single-colour face on a deeper lip band (the cat-game
    `ui 1` slabs), soft rounded corners, and a faint paw print in the top-right corner — inside
    the unstretched 9-slice corner, so it stays crisp at any button width. Pressed: the face
    drops onto the lip."""
    light, dull, _outline, _rim = BUTTON_TONES[tone]
    face = mix(light, dull, 0.35)
    lip = mix(dull, "#000000", 0.22)
    w, h, r, line = 128, 92, 26, 4.5
    sink = 7 if pressed else 0
    body = rect(0, 8, w, h - 4, r, "#000000", ' fill-opacity="0.18"')
    body += rect(0, sink, w, h - sink, r, CAT_LINE)
    body += rect(line, sink + line, w - 2 * line, h - sink - 2 * line, r - line, lip)
    lip_h = 3 if pressed else 10  # pressed: the face sits almost flush on the lip
    body += rect(line, sink + line, w - 2 * line, h - sink - 2 * line - lip_h, r - line, face)
    body += paw_mark(106, sink + 18, 0.8, "#ffffff", 0.45 if tone != "white" else 0.0)
    if tone == "white":
        body += paw_mark(106, sink + 18, 0.8, CAT_LINE, 0.18)
    return svg(w, 100, body)


# --- Containers -------------------------------------------------------------------------------

def board():
    body = rect(0, 8, 96, 96, 26, "#000000", ' fill-opacity="0.2"')
    body += rect(0, 0, 96, 96, 26, LINE) + rect(3, 3, 90, 90, 23, "#cea364") + rect(14, 14, 68, 68, 16, "#dabf96")
    body += rect(18, 18, 60, 60, 13, "none", ' stroke="#e8d4ae" stroke-width="2"')
    return svg(96, 104, body)


def board_header():
    # Tiles horizontally under the board's top edge: pale band with standing triangles.
    body = rect(0, 0, 52, 46, 0, "#e2cba4") + f'<path d="{poly([(0, 46), (26, 30), (52, 46)])}" fill="#dabf96"/>'
    return svg(52, 46, body)


def well():
    defs = f'<clipPath id="in">{rect(2, 2, 60, 60, 12, "#000")}</clipPath>'
    body = rect(0, 0, 64, 64, 14, "#c9a77a") + rect(2, 2, 60, 60, 12, "#d2b386")
    body += '<g clip-path="url(#in)"><rect x="0" y="0" width="64" height="8" fill="#c4a275"/></g>'
    body += '<rect x="14" y="61" width="36" height="2" fill="#e8d3ac"/>'
    return svg(64, 64, body, defs)


def blue_panel():
    defs = '<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6894d5"/><stop offset="1" stop-color="#568bc9"/></linearGradient>'
    body = '<rect x="0" y="0" width="32" height="64" fill="url(#g)"/><rect x="0" y="0" width="32" height="5" fill="#335d91"/><rect x="0" y="5" width="32" height="3" fill="#7aa6e3"/>'
    return svg(32, 64, body, defs)


def sheet():
    body = rect(0, 6, 64, 64, 16, "#000000", ' fill-opacity="0.2"') + rect(0, 0, 64, 64, 16, LINE)
    body += rect(3, 3, 58, 58, 13, "#fffdfb") + rect(6, 6, 52, 52, 10, "#f1e7df")
    return svg(64, 70, body)


def hex_points(x0, y0, x1, y1, tip):
    cy = (y0 + y1) / 2
    return [(x0, cy), (x0 + tip, y0), (x1 - tip, y0), (x1, cy), (x1 - tip, y1), (x0 + tip, y1)]


def title_plaque():
    # bg_qbnzsx: orange-beige bar with pointed ends.
    pts = hex_points(3, 3, 117, 45, 16)
    d = poly(pts)
    defs = f'<clipPath id="p"><path d="{d}"/></clipPath>'
    body = f'<g opacity="0.2" transform="translate(0 3)"><path d="{d}" fill="#000" stroke="#000" stroke-width="5" stroke-linejoin="round"/></g>'
    body += f'<path d="{d}" fill="#e2a04d"/>'
    body += '<g clip-path="url(#p)"><rect x="0" y="0" width="120" height="6" fill="#fbb762"/><rect x="0" y="42" width="120" height="4" fill="#f8b663"/></g>'
    body += f'<path d="{d}" fill="none" stroke="{LINE}" stroke-width="5" stroke-linejoin="round"/>'
    return svg(120, 51, body, defs)


def section_plaque():
    # bg_fenye_01: blue pill with a diamond at each end.
    ink = "#333344"
    defs = '<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#71abdf"/><stop offset="1" stop-color="#5e97d1"/></linearGradient>'
    body = rect(14, 4, 122, 40, 12, "url(#g)", f' stroke="{ink}" stroke-width="4"')
    body += '<rect x="26" y="8" width="98" height="3" rx="1.5" fill="#96c9fc"/><rect x="26" y="37" width="98" height="3" rx="1.5" fill="#93c6f9"/>'
    for cx in (14, 136):
        dia = poly([(cx, 10), (cx + 14, 24), (cx, 38), (cx - 14, 24)])
        body += f'<path d="{dia}" fill="#6699cc" stroke="{ink}" stroke-width="3.5" stroke-linejoin="round"/>'
        body += f'<path d="{poly([(cx, 14), (cx + 5, 19), (cx, 24), (cx - 5, 19)])}" fill="#9ac4f5"/>'
    return svg(150, 48, body, defs)


def soft_pill(w, h, color, alpha):
    return svg(w, h, rect(0, 0, w, h, h / 2, color, f' fill-opacity="{alpha}"'))


def hud_bg():
    defs = '<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d6c0b6"/><stop offset="1" stop-color="#efe2db"/></linearGradient>'
    return svg(16, 128, '<rect x="0" y="0" width="16" height="126" fill="url(#g)"/><rect x="0" y="126" width="16" height="2" fill="#c9b1a6"/>', defs)


def avatar_frame():
    body = rect(0, 4, 80, 80, 14, "#000000", ' fill-opacity="0.2"') + rect(0, 0, 80, 80, 14, LINE)
    body += rect(3, 3, 74, 74, 11, "#ffffff") + rect(6, 6, 68, 68, 9, "#f3e6d8")
    return svg(80, 84, body)


def lv_plaque():
    return svg(60, 26, rect(0, 0, 60, 26, 9, LINE) + rect(2, 2, 56, 22, 7, "#9c7f74"))


def nav_cell():
    """Unselected tab: a light grey tile, cat-brown outline, soft top light."""
    # Light grey (user, 2026-10-18): the dark slate muddied the icons' brown outlines.
    body = rect(2, 6, 140, 104, 18, CAT_LINE)
    body += rect(5, 9, 134, 98, 15, "#cfd3d8") + rect(5, 9, 134, 40, 15, "#dde0e4")
    body += rect(5, 30, 134, 19, 0, "#dde0e4") + '<rect x="18" y="13" width="108" height="4" rx="2" fill="#ffffff" fill-opacity="0.7"/>'
    return svg(144, 112, body)


def nav_selected():
    """Selected tab, our own look: a taller warm block (orange to deep orange, so the gold parts
    of the tab icons and the white label stand out: 1.9-2.7:1 for gold, was 1.2), cat-brown outline,
    faint paw prints, a light streak on top."""
    # The outline is centred on the path: inset it by half its width (2) on every side, or the
    # canvas clips half the left/right strokes and they look thinner than the top.
    edge = "M2 136 L2 22 Q2 6 18 6 L134 6 Q150 6 150 22 L150 136"
    d = edge + " Z"
    defs = (f'<clipPath id="c"><path d="{d}"/></clipPath>'
            '<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f07b2a"/>'
            '<stop offset="1" stop-color="#d9562a"/></linearGradient>')
    body = f'<path d="{d}" fill="url(#g)"/>'
    body += '<g clip-path="url(#c)">'
    for x, y in ((30, 40), (122, 64), (40, 112), (110, 126), (76, 88)):
        body += paw_mark(x, y, 1.5, "#ffffff", 0.18)
    body += '<rect x="16" y="10" width="120" height="6" rx="3" fill="#ffffff" fill-opacity="0.55"/></g>'
    body += f'<path d="{edge}" fill="none" stroke="{CAT_LINE}" stroke-width="4" stroke-linejoin="round"/>'
    return svg(152, 136, body, defs)


# --- Bars -------------------------------------------------------------------------------------

BAR_FILLS = {"red": ("#ff8f8f", "#f04a4a"), "blue": ("#9ff0ff", "#2ec8f2"), "green": ("#8dff6e", "#2bd62b"),
             "yellow": ("#fff58a", "#ffd21f")}


def bar_track(w, h, r, inner, inset):
    return svg(w, h, rect(0, 0, w, h, r, LINE) + rect(inset, inset, w - inset * 2, h - inset * 2, r - inset, inner))


def bar_fill(light, body_col, w, h, r, light_ratio):
    defs = f'<clipPath id="f">{rect(0, 0, w, h, r, "#000")}</clipPath>'
    body = rect(0, 0, w, h, r, body_col) + f'<g clip-path="url(#f)"><rect x="0" y="0" width="{w}" height="{n(h * light_ratio)}" fill="{light}"/></g>'
    return svg(w, h, body, defs)


# --- Cards ------------------------------------------------------------------------------------

KAPAI = {  # ring, face, inner, bottom glow
    "green": ("#e2fbd8", "#86d46b", "#7ac85f", "#c4f0b4"),
    "orange": ("#ffe3c1", "#f7af6f", "#f2a866", "#ffd7ae"),
    "yellow": ("#fff4c2", "#f3d36a", "#eccb5c", "#fbe7a0"),
    "blue": ("#d6f0ff", "#6cbbe8", "#5eaedc", "#b6e2fb"),
    "purple": ("#efd9ff", "#b98be8", "#ad7fdf", "#dcc4f7"),
    "red": ("#ffd6d0", "#ec7f74", "#e2726a", "#f7b8b0"),
}
ITEM = {"cream": ("#eed5c7", "#f8e7dd"), "blue": ("#5babe2", "#86c6f0"), "orange": ("#f0a55d", "#f8c48c"),
        "red": ("#d65b5e", "#ea8a88"), "purple": ("#a77be0", "#c6a4f0")}


def unit_card(tone):
    ring, face, inner, glow = KAPAI[tone]
    w, h = 124, 142
    defs = f'<clipPath id="f">{rect(5, 5, w - 10, h - 10, 8, "#000")}</clipPath>'
    body = rect(0, 4, w, h, 12, "#000000", ' fill-opacity="0.2"') + rect(0, 0, w, h, 12, LINE)
    body += rect(2.5, 2.5, w - 5, h - 5, 10, ring) + rect(5, 5, w - 10, h - 10, 8, face)
    body += rect(10, 10, w - 20, h - 31, 6, inner)
    body += f'<g clip-path="url(#f)"><rect x="0" y="{h - 9}" width="{w}" height="4" fill="{glow}"/></g>'
    return svg(w, h + 4, body, defs)


def item_card(tone):
    face, hi = ITEM[tone]
    w, h = 140, 154
    defs = f'<clipPath id="f">{rect(2.5, 2.5, w - 5, h - 5, 10, "#000")}</clipPath>'
    body = rect(0, 4, w, h, 12, "#000000", ' fill-opacity="0.2"') + rect(0, 0, w, h, 12, LINE)
    body += rect(2.5, 2.5, w - 5, h - 5, 10, face)
    body += f'<g clip-path="url(#f)"><rect x="0" y="0" width="{w}" height="6.5" fill="{hi}"/></g>'
    body += rect(9.5, 10.5, w - 19, h - 44.5, 8, hi, ' fill-opacity="0.35"')
    return svg(w, h + 4, body, defs)


# --- Badges -----------------------------------------------------------------------------------

def shield(fill, ink):
    pts = [(4, 4), (28, 4), (28, 19), (16, 31), (4, 19)]
    d = poly(pts)
    defs = f'<clipPath id="s"><path d="{d}"/></clipPath>'
    body = f'<path d="{d}" fill="{fill}"/><g clip-path="url(#s)"><rect x="0" y="0" width="32" height="12" fill="{lighten(fill, 0.2)}"/></g>'
    body += f'<path d="{d}" fill="none" stroke="{ink}" stroke-width="3.5" stroke-linejoin="round"/>'
    return svg(32, 34, body, defs)


def flower():
    pts = []
    for i in range(48):
        a = math.tau * i / 48
        r = 14 * (0.86 + 0.14 * math.cos(a * 6))
        pts.append((17 + math.cos(a) * r, 17 + math.sin(a) * r))
    return svg(34, 34, f'<path d="{poly(pts)}" fill="#f2eeeb" stroke="{LINE}" stroke-width="2.5" stroke-linejoin="round"/>')


def check():
    body = '<circle cx="15" cy="15" r="13.5" fill="#335522"/><circle cx="15" cy="15" r="11.5" fill="#55dd66"/>'
    body += '<circle cx="15" cy="13" r="8" fill="#6ee67d"/>'
    tick = "M9.5 15 L13.5 19 L20.5 11"
    body += f'<path d="{tick}" fill="none" stroke="#2c5f1b" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>'
    body += f'<path d="{tick}" fill="none" stroke="#ffffff" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/>'
    return svg(30, 30, body)


def dot_red():
    body = '<circle cx="15" cy="17" r="13" fill="#000000" fill-opacity="0.2"/><circle cx="15" cy="15" r="13" fill="#3c1e0c"/>'
    body += '<circle cx="15" cy="15" r="10.5" fill="#d93f3f"/><path d="M5 13 A10.5 10.5 0 0 1 25 13 Z" fill="#f25c5c"/>'
    body += rect(13, 7, 4, 10, 2, "#ffffff") + '<circle cx="15" cy="21" r="2.2" fill="#ffffff"/>'
    return svg(30, 32, body)


def plus_small():
    body = '<circle cx="9" cy="9" r="8.5" fill="#503737"/><circle cx="9" cy="9" r="6.5" fill="#59d961"/>'
    body += rect(5, 8, 8, 2.4, 1.2, "#ffffff") + rect(7.8, 5, 2.4, 8, 1.2, "#ffffff")
    return svg(18, 18, body)


# --- Scene pieces -----------------------------------------------------------------------------

def platform():
    defs = '<linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#c9b0a8"/><stop offset="1" stop-color="#e0cfcf"/></linearGradient>'
    body = f'<path d="{ellipse_d(90, 44, 76, 29)}" {SHADOW}/>'
    body += f'<path d="{ellipse_d(90, 38, 75, 28)}" fill="#668899"/><path d="{ellipse_d(90, 38, 72, 26)}" fill="#69cff1"/>'
    body += f'<path d="{ellipse_d(90, 36, 70, 23)}" fill="#7bdeff"/><path d="{ellipse_d(90, 36, 61, 19)}" fill="#6183a5"/>'
    body += f'<path d="{ellipse_d(90, 36, 59, 17)}" fill="url(#g)"/>'
    return svg(180, 76, body, defs)


def bush():
    blobs = [(30, 46, 26), (80, 46, 26), (55, 34, 32)]
    body = "".join(f'<path d="{ellipse_d(x, y, r + 3, r * 0.8 + 3)}" fill="#3f7a3a"/>' for x, y, r in blobs)
    body += "".join(f'<path d="{ellipse_d(x, y, r, r * 0.8)}" fill="#5cad4a"/><path d="{ellipse_d(x, y - r * 0.25, r * 0.7, r * 0.45)}" fill="#74c45c"/>' for x, y, r in blobs)
    return svg(110, 76, body)


def wall_scene():
    w, h = 720, 470
    stone, mortar = "#ddd5cd", "#b4a69a"
    body = f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ebdcd5"/><rect x="0" y="0" width="{w}" height="96" fill="#93cf68"/>'
    body += "".join(f'<rect x="0" y="{14 + k * 14}" width="{w}" height="6" fill="#9dd673"/>' for k in range(6))
    for x in (0, w - 64):
        body += f'<path d="{poly([(x, 0), (x + 64, 0), (x + 64, 30), (x + 32, 48), (x, 30)])}" fill="#4f7fd0"/>'
    for x in range(-10, w, 50):
        body += f'<rect x="{x}" y="78" width="34" height="22" fill="{stone}" stroke="{mortar}" stroke-width="2"/>'
    body += f'<rect x="0" y="96" width="{w}" height="92" fill="{stone}"/>'
    for y in (96, 188):
        body += f'<rect x="0" y="{y - 1.5}" width="{w}" height="3" fill="{mortar}"/>'
    for y in (120, 144, 168):
        body += f'<rect x="0" y="{y - 1}" width="{w}" height="2" fill="{mortar}" fill-opacity="0.5"/>'
    for cx in (w * 0.2, w * 0.8):
        body += f'<path d="M{n(cx - 92)} 188 A92 70 0 0 1 {n(cx + 92)} 188 Z" fill="#93cf68" stroke="{mortar}" stroke-width="4"/>'
    body += f'<rect x="0" y="188" width="{w}" height="6" fill="#cfc3b8"/>'
    return svg(w, h, body)


# --- Icons (128x128, ~52 px radius around (64, 60)) -----------------------------------------------

# Stroke rules. Measured on the Gear Defenders icons (coinIcon 72 px, gemIcon 72, aixin_b 146,
# gear4 123): the dark outline is 3-4 *screen* pixels from 72 px up, sits *outside* the shape
# (fills keep their full size), and is a little heavier at the bottom. Inner edges where parts
# overlap are thinner than the silhouette (line-weight hierarchy).
# Below ~64 px a 3.5 px outline swallows thin parts (tested: a 32 px bow became a dark blob), so
# small sizes get a thinner outline: ~5.5% of the icon, clamped to 2-4 px (optical sizing).
# Icons are generated per display size (ICON_SIZES) so each gets its own outline.
ICON_SIZES = (32, 48, 64, 96, 128)
INNER_PX = 1.1       # inner part edges: a fixed hairline, or they eat thin parts (bow limbs)
LIP_PX = 0.035       # extra outline under the shape, as a share of the icon size
SHADOW_PX = 0.05     # drop shadow offset, as a share of the icon size


def outline_px(size):
    return max(2.0, min(4.0, size * 0.055))


class Icon:
    """Records the parts of one icon; svg(size) renders it with a constant-pixel outline.

    Layers, back to front: drop shadow of the whole silhouette, the lip (silhouette shifted
    down), the silhouette outline (every part stroked 2x outline *under* its fill, so the visible
    stroke is outside), then each part's fill with its light top and a thin inner edge, then
    details (`raw`)."""

    def __init__(self):
        self.parts = []

    def shape(self, d, light, dull, split, width=None, rot=0):
        """`rot` turns the shape about the icon centre; the light/dull split stays horizontal.
        `width` is ignored: outlines are set per size (see the module notes)."""
        self.parts.append(("shape", d, light, dull, split, rot))

    def line(self, d, width, color="#ffffff", rot=0):
        """An open stroke (X, +, chevron, padlock shackle) that gets the same outline."""
        self.parts.append(("line", d, width, color, rot))

    def raw(self, s, rot=0, gloss=False):
        """Extra SVG. `gloss` marks shine/sparkle decoration that the flat cat style drops
        (anything with a fill/stroke opacity counts as gloss too)."""
        gloss = gloss or "opacity" in s
        self.parts.append(("raw", f'<g transform="rotate({n(rot)} 64 64)">{s}</g>' if rot else s, gloss))

    def shine(self, x, y, rx, ry=None):
        self.raw(f'<path d="{ellipse_d(x, y, rx, ry or rx)}" fill="#ffffff" fill-opacity="0.85"/>', gloss=True)

    def flat_svg(self, size=128, line=None):
        """The same parts in the cat style (cat-sprite-art skill), for things cats hold or wear
        (weapons, equipment): every part one flat colour with its own even #583f21 outline
        (~5% of the size, 2.5 px minimum), open strokes as a dark stroke under a colour
        stroke like the cat tail, and no gloss: no light/dull split, rim light, lip, drop
        shadow, shine or sparkles. Later parts cover earlier outlines, as in the cat sprites."""
        # `line`: outline width in the 128 grid, to match a sprite it is drawn into (a held
        # weapon must carry the cat's 12 px line, not an icon's).
        w = line if line is not None else max(2.5, size * 0.05) * 128 / size
        k = (62 - w / 2) / 62  # fit the outline inside the canvas
        rot_attr = lambda r: f' transform="rotate({n(r)} 64 64)"' if r else ""
        out = ""
        for part in self.parts:
            kind = part[0]
            if kind == "shape":
                _, d, light, dull, _split, rot = part
                out += (f'<path d="{d}"{rot_attr(rot)} fill="{mix(light, dull, 0.4)}" stroke="{CAT_LINE}" '
                        f'stroke-width="{n(w)}" stroke-linejoin="round"/>')
            elif kind == "line":
                _, d, width, color, rot = part
                cap = 'fill="none" stroke-linecap="round" stroke-linejoin="round"'
                out += f'<path d="{d}"{rot_attr(rot)} {cap} stroke="{CAT_LINE}" stroke-width="{n(width + 1.4 * w)}"/>'
                out += f'<path d="{d}"{rot_attr(rot)} {cap} stroke="{color}" stroke-width="{n(width)}"/>'
            elif not part[2]:
                out += part[1]
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 128 128">'
                f'<g transform="translate(64 64) scale({n(k)}) translate(-64 -64)">{out}</g></svg>\n')

    def svg(self, size=128):
        o_px = outline_px(size) * 128 / size    # outline width in the 128 grid
        k = min(1.0, (63 - o_px - LIP_PX * 128) / 60)  # shrink the art so outline + lip fit
        o = o_px / k                            # same width inside the scaled group
        rot_attr = lambda r: f' transform="rotate({n(r)} 64 64)"' if r else ""
        defs, sil, fills = "", "", ""
        for i, part in enumerate(self.parts):
            kind = part[0]
            if kind == "shape":
                _, d, light, dull, split, rot = part
                sil += f'<path d="{d}"{rot_attr(rot)} fill="{ICON_LINE}" stroke="{ICON_LINE}" stroke-width="{n(2 * o)}" stroke-linejoin="round"/>'
                defs += f'<clipPath id="c{i}"><path d="{d}"{rot_attr(rot)}/></clipPath>'
                fills += f'<path d="{d}"{rot_attr(rot)} fill="{dull}"/>'
                fills += f'<g clip-path="url(#c{i})"><rect x="-64" y="-64" width="256" height="{n(split + 64)}" fill="{light}"/></g>'
                rim = 3.2 * 128 / size / k + 2.5
                fills += (f'<g clip-path="url(#c{i})"><path d="{d}" transform="translate({n(rim * 0.6)} {n(rim * 0.8)}){rot_attr(rot).replace(' transform="', ' ').rstrip(chr(34)) if rot else ""}" '
                          f'fill="none" stroke="#ffffff" stroke-opacity="0.55" stroke-width="{n(rim)}" stroke-linejoin="round"/></g>')
                fills += f'<path d="{d}"{rot_attr(rot)} fill="none" stroke="{ICON_LINE}" stroke-width="{n(INNER_PX * 128 / size / k)}" stroke-linejoin="round"/>'
            elif kind == "line":
                _, d, width, color, rot = part
                cap = 'fill="none" stroke-linecap="round" stroke-linejoin="round"'
                sil += f'<path d="{d}"{rot_attr(rot)} {cap} stroke="{ICON_LINE}" stroke-width="{n(width + 2 * o)}"/>'
                fills += f'<path d="{d}"{rot_attr(rot)} {cap} stroke="{color}" stroke-width="{n(width)}"/>'
            else:
                fills += part[1]
        body = f'<g transform="translate(64 64) scale({n(k)}) translate(-64 -64)">'
        body += f'<g opacity="0.2" transform="translate(0 {n(SHADOW_PX * 128 / k)})">{sil.replace(ICON_LINE, "#000000")}</g>'
        body += f'<g transform="translate(0 {n(LIP_PX * 128 / k)})">{sil}</g>'
        body += sil + fills + "</g>"
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 128 128">'
                f"<defs>{defs}</defs>{body}</svg>\n")


def star_pts(cx, cy, ro, ri, k=5):
    return [(cx + math.cos(-math.pi / 2 + math.pi * i / k) * (ro if i % 2 == 0 else ri),
             cy + math.sin(-math.pi / 2 + math.pi * i / k) * (ro if i % 2 == 0 else ri)) for i in range(k * 2)]


def gear_pts(cx, cy, r, teeth=8):
    pts, step = [], math.tau / teeth
    for i in range(teeth):
        a = step * i
        for da, rr in ((-0.27, 0.76), (-0.16, 1.0), (0.16, 1.0), (0.27, 0.76)):
            pts.append((cx + math.cos(a + step * da) * r * rr, cy + math.sin(a + step * da) * r * rr))
    return pts


def coin(ic, cx=64, cy=60, r=48):
    ic.shape(circle_d(cx, cy, r), "#ffdd11", "#fcc90e", cy - r * 0.05)
    ic.raw(f'<circle cx="{n(cx)}" cy="{n(cy)}" r="{n(r * 0.64)}" fill="none" stroke="#be7a47" stroke-width="{n(r * 0.09)}"/>')
    ic.raw(f'<path d="{poly(gear_pts(cx, cy, r * 0.38, 7))}" fill="#e8b021"/><circle cx="{n(cx)}" cy="{n(cy)}" r="{n(r * 0.14)}" fill="#ffdd11"/>')
    ic.shine(cx - r * 0.42, cy - r * 0.42, r * 0.13)


def gem(ic, cx=64, cy=62, r=50):
    pts = [(cx - 0.88 * r, cy - 0.25 * r), (cx - 0.45 * r, cy - 0.8 * r), (cx + 0.45 * r, cy - 0.8 * r), (cx + 0.88 * r, cy - 0.25 * r), (cx, cy + 0.88 * r)]
    ic.shape(poly(pts), "#dca4ff", "#a95cf2", cy - 0.1 * r)
    lines = [((cx - 0.88 * r, cy - 0.25 * r), (cx + 0.88 * r, cy - 0.25 * r)), ((cx - 0.3 * r, cy - 0.25 * r), (cx, cy + 0.88 * r)), ((cx + 0.3 * r, cy - 0.25 * r), (cx, cy + 0.88 * r))]
    for a, b in lines:
        ic.raw(f'<path d="M{n(a[0])} {n(a[1])} L{n(b[0])} {n(b[1])}" stroke="#7a32c4" stroke-opacity="0.5" stroke-width="{n(r * 0.07)}"/>')
    ic.shine(cx - 0.42 * r, cy - 0.5 * r, r * 0.12)


def feature_paw(ic, cx, cy, scale=1, fill="#fff0c9"):
    """Small flat heraldic paw; fewer, larger parts survive the feature-icon sizes."""
    pads = ["M-17 10 Q-18 3 -11 -1 Q-6 -4 -4 -8 Q0 -12 4 -8 "
            "Q6 -4 11 -1 Q18 3 17 10 Q16 17 9 16 Q0 13 -9 16 Q-16 17 -17 10 Z"]
    pads += [ellipse_d(x, y, rx, ry) for x, y, rx, ry in
             ((-21, -11, 5, 6.5), (-9, -23, 5.5, 7), (9, -23, 5.5, 7), (21, -11, 5, 6.5))]
    body = ''.join(f'<path d="{d}" fill="{fill}" stroke="#583f21" stroke-width="2.8" stroke-linejoin="round"/>' for d in pads)
    ic.raw(f'<g transform="translate({n(cx)} {n(cy)}) scale({n(scale)})">{body}</g>')


def make_icons():
    icons = {}
    ic = Icon(); coin(ic); icons["coin"] = ic
    ic = Icon(); gem(ic); icons["gem"] = ic

    ic = Icon()
    pts = []
    for i in range(48):
        t = math.tau * i / 48
        pts.append((64 + 16 * math.sin(t) ** 3 * 3.0, 58 - (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) * 3.0 - 7.5))
    ic.shape(poly(pts), "#f25c5c", "#d93f3f", 66)
    ic.raw(f'<path d="{ellipse_d(40, 38, 10, 6.5)}" fill="#ffffff" fill-opacity="0.9"/>')
    icons["heart"] = ic

    for name, tones in (("star", ("#ffe14d", "#ffc21f")), ("star_off", ("#c9c0bb", "#a49a95"))):
        ic = Icon()
        ic.shape(poly(star_pts(64, 64, 54, 28)), tones[0], tones[1], 70)
        if name == "star":
            ic.shine(57, 42, 6.5)
        icons[name] = ic

    ic = Icon()
    ic.shape(poly(gear_pts(64, 62, 52)), "#ffe14d", "#f7d541", 62)
    ic.raw('<circle cx="64" cy="62" r="27" fill="#f3af38"/><circle cx="64" cy="62" r="19" fill="#914d1a"/><circle cx="64" cy="62" r="12.5" fill="#c4782a"/>')
    ic.shine(41, 36, 5.5)
    icons["gear"] = ic

    ic = Icon()
    bolt = [(0.18, -1.0), (-0.58, 0.12), (-0.06, 0.12), (-0.22, 1.0), (0.58, -0.16), (0.06, -0.16)]
    ic.shape(poly([(64 + x * 52, 62 + y * 52) for x, y in bolt]), "#ffc35a", "#ff9a1f", 58)
    icons["bolt"] = ic

    ic = Icon()
    pads = [ellipse_d(64, 78, 27, 22)] + [ellipse_d(64 + x * 52, 62 + y * 52, 10.5, 12.5) for x, y in ((-0.64, -0.2), (-0.24, -0.58), (0.24, -0.58), (0.64, -0.2))]
    for d in pads:
        ic.shape(d, "#ffc8d5", "#ff97b2", 200, 8)
    ic.shine(52, 72, 5)
    icons["paw"] = ic

    ic = Icon()
    ic.shape("M17 60 L111 60 L111 100 Q111 107 104 107 L24 107 Q17 107 17 100 Z", "#e0604f", "#c2473c", 80)
    ic.shape("M14 60 L14 40 Q14 28 30 28 L98 28 Q114 28 114 40 L114 60 Z", "#ee7462", "#d65848", 46)
    ic.raw('<rect x="31" y="28" width="12" height="79" fill="#ffcf3a"/><rect x="85" y="28" width="12" height="79" fill="#ffcf3a"/><rect x="17" y="58" width="94" height="6" fill="#8e2f28"/>')
    ic.shape("M53 50 L75 50 Q78 50 78 53 L78 74 Q78 77 75 77 L53 77 Q50 77 50 74 L50 53 Q50 50 53 50 Z", "#ffdd11", "#fcc90e", 60, 6)
    ic.raw(f'<path d="{poly([(64, 55), (71, 63), (64, 71), (57, 63)])}" fill="#b768f5"/>')
    ic.shine(30, 38, 4.5)
    icons["chest"] = ic

    ic = Icon()
    ic.line("M42 58 L42 44 A22 22 0 0 1 86 44 L86 58", 13, "#d9dcff")
    ic.shape("M34 52 L94 52 Q108 52 108 66 L108 98 Q108 112 94 112 L34 112 Q20 112 20 98 L20 66 Q20 52 34 52 Z", "#d9dcff", "#898fc2", 96, 10)
    ic.raw(f'<path d="{ellipse_d(64, 80, 7, 11)}" fill="{ICON_LINE}"/>')
    icons["lock"] = ic

    def strokes(lines):
        ic = Icon()
        for ln in lines:
            ic.line(ln, 22)
        return ic

    icons["close"] = strokes(["M38 36 L90 88", "M90 36 L38 88"])
    icons["plus"] = strokes(["M64 28 L64 96", "M30 62 L98 62"])
    icons["back"] = strokes(["M76 32 L46 62 L76 92"])

    ic = Icon()
    ic.raw(rect(20, 32, 88, 64, 18, "#4b4444") + f'<path d="{poly([(52, 46), (82, 64), (52, 82)])}" fill="#ffffff"/>')
    icons["ad"] = ic

    # Badges: same outline system as every icon (they used to have their own centred strokes).
    for tone, cols in (("blue", ("#9bd6ff", "#70c2fc")), ("orange", ("#ffc27a", "#ffa64d"))):
        ic = Icon()
        ic.shape(poly([(22, 14), (106, 14), (106, 74), (64, 114), (22, 74)]), cols[0], cols[1], 46)
        icons[f"badge_shield_{tone}"] = ic
    ic = Icon()
    ic.shape(circle_d(64, 64, 50), "#6ee67d", "#55dd66", 60)
    ic.line("M40 66 L57 82 L88 48", 18)
    icons["badge_check"] = ic
    ic = Icon()
    ic.shape(circle_d(64, 64, 50), "#f25c5c", "#d93f3f", 56)
    ic.raw(rr_d(56, 28, 16, 46, 8).join(['<path d="', '" fill="#ffffff"/>']) + '<circle cx="64" cy="92" r="9" fill="#ffffff"/>')
    icons["badge_dot"] = ic
    ic = Icon()
    ic.shape(circle_d(64, 64, 50), "#7bea82", "#59d961", 60)
    ic.line("M64 38 L64 90", 18)
    ic.line("M38 64 L90 64", 18)
    icons["badge_plus"] = ic
    ic = Icon()
    pts = []
    for i in range(48):
        a = math.tau * i / 48
        r = 54 * (0.86 + 0.14 * math.cos(a * 6))
        pts.append((64 + math.cos(a) * r, 64 + math.sin(a) * r))
    ic.shape(poly(pts), "#ffffff", "#f2eeeb", 64)
    icons["badge_flower"] = ic

    # Side-rail feature icons, each drawn for its name (not reused currency icons).
    ic = Icon()  # Thông hành: winged gold crest with a crown
    for sx in (1, -1):
        def x(v, sx=sx):
            return 64 + sx * (v - 64)
        ic.shape(poly([(x(38), 62), (x(6), 44), (x(4), 26), (x(22), 34), (x(12), 14), (x(34), 28), (x(42), 34)]), "#ffffff", "#cfe6ff", 40)
    ic.shape("M30 30 L98 30 L98 68 Q98 98 64 116 Q30 98 30 68 Z", "#ffe14d", "#f0b323", 64)
    ic.shape("M42 42 L86 42 L86 68 Q86 88 64 100 Q42 88 42 68 Z", "#ff7a7a", "#e04b4b", 66)
    ic.shape(poly([(48, 76), (48, 56), (56, 64), (64, 50), (72, 64), (80, 56), (80, 76)]), "#ffe14d", "#f0b323", 64)
    ic.raw('<circle cx="64" cy="62" r="3.5" fill="#e04b4b"/>')
    icons["rail_pass"] = ic

    ic = Icon()  # VIP: tilted purple card with gold VIP letters
    ic.shape(rr_d(10, 28, 108, 72, 14), "#c58bff", "#8f4fe0", 60, rot=-10)
    ic.raw('<path d="' + rr_d(18, 36, 92, 56, 10) + '" fill="none" stroke="#ffe680" stroke-width="3" stroke-opacity="0.8"/>', -10)
    for d in ("M28 46 L38 80 L48 46", "M62 46 L62 80", "M76 80 L76 46 L88 46 Q100 46 100 56 Q100 66 88 66 L76 66"):
        ic.line(d, 10, "#ffe14d", rot=-10)
    ic.raw(f'<path d="{poly(star_pts(106, 20, 12, 4, 4))}" fill="#fff3a0"/>')
    icons["rail_vip"] = ic

    ic = Icon()  # A blue parcel with a soft coral bow; the time is shown beside the icon.
    ic.shape(rr_d(22, 51, 84, 65, 9), "#83b8c5", "#83b8c5", 80)
    ic.raw('<path d="M55 54 L73 54 L73 113 L55 113 Z" fill="#fff0c9"/>')
    ic.shape("M62 40 Q32 44 26 24 Q24 11 40 15 Q54 19 62 40 Z", "#df6a59", "#df6a59", 25)
    ic.shape("M66 40 Q96 44 102 24 Q104 11 88 15 Q74 19 66 40 Z", "#df6a59", "#df6a59", 25)
    ic.shape(rr_d(15, 40, 98, 23, 7), "#83b8c5", "#83b8c5", 51)
    ic.shape(rr_d(53, 33, 22, 28, 7), "#df6a59", "#df6a59", 45)
    feature_paw(ic, 64, 94, 0.58)
    icons["rail_limited"] = ic

    ic = Icon()  # Nhiệm vụ: a chubby clipboard, with two large readable check marks.
    ic.shape(rr_d(22, 19, 84, 99, 12), "#bd8f62", "#bd8f62", 68)
    ic.raw(f'<path d="{rr_d(31, 31, 66, 77, 6)}" fill="#fff0c9" stroke="#583f21" stroke-width="3"/>')
    ic.shape(rr_d(45, 10, 38, 26, 8), "#f5c565", "#f5c565", 23)
    ic.raw('<path d="M56 22 L72 22" stroke="#583f21" stroke-width="4" stroke-linecap="round"/>')
    for y in (57, 83):
        ic.raw(f'<path d="M39 {y} L46 {y + 7} L56 {y - 6}" fill="none" stroke="#759b63" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>')
        ic.raw(f'<path d="M67 {y} L87 {y}" stroke="#b99d73" stroke-width="5" stroke-linecap="round"/>')
    icons["rail_quest"] = ic

    ic = Icon()  # Countdown: a simple pocket watch, including at the 24px counter size.
    ic.shape(rr_d(55, 12, 18, 22, 5), "#bd8f62", "#bd8f62", 22)
    ic.shape(rr_d(47, 5, 34, 14, 5), "#f5c565", "#f5c565", 12)
    ic.shape(circle_d(64, 70, 47), "#f5c565", "#f5c565", 70)
    ic.raw(f'<path d="{circle_d(64, 70, 36)}" fill="#fff0c9" stroke="#583f21" stroke-width="3"/>')
    ic.raw('<path d="M64 46 L64 71 L83 81" fill="none" stroke="#583f21" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>')
    icons["rail_online"] = ic

    ic = Icon()  # Quà 7 ngày: rounded tear-off calendar, with a large hand-drawn seven.
    ic.shape(rr_d(16, 23, 96, 94, 13), "#fff0c9", "#fff0c9", 76)
    ic.raw('<path d="M30 26 L98 26 Q109 26 109 39 L109 48 L19 48 L19 39 Q19 26 30 26 Z" fill="#df6a59"/>')
    ic.raw('<path d="M19 48 L109 48" stroke="#583f21" stroke-width="3"/>')
    for x in (40, 88):
        ic.shape(rr_d(x - 5, 10, 10, 24, 5), "#f5c565", "#f5c565", 22)
    ic.raw('<path d="M43 60 L85 60 L85 71 L65 103 L49 103 L70 73 L43 73 Z" fill="#83b8c5" stroke="#583f21" stroke-width="3" stroke-linejoin="round"/>')
    icons["rail_checkin"] = ic

    ic = Icon()  # Miniature of the warm-stone, blue-roof cat fortress in the stage art.
    ic.shape("M12 53 L12 35 L24 35 L24 45 L34 45 L34 35 L45 35 L45 113 L12 113 Z", "#ead5ac", "#ead5ac", 74)
    ic.shape("M83 113 L83 35 L94 35 L94 45 L104 45 L104 35 L116 35 L116 113 Z", "#ead5ac", "#ead5ac", 74)
    ic.shape(rr_d(39, 37, 50, 77, 4), "#ead5ac", "#ead5ac", 76)
    ic.shape("M36 40 L47 13 Q48 11 51 15 L61 25 L67 25 L77 15 Q80 11 81 13 L92 40 Z", "#83b8c5", "#83b8c5", 26)
    ic.raw('<path d="M57 67 L57 56 Q64 45 71 56 L71 67 Z" fill="#83b8c5" stroke="#583f21" stroke-width="3"/>')
    ic.shape("M49 114 L49 91 Q49 78 64 78 Q79 78 79 91 L79 114 Z", "#bd8f62", "#bd8f62", 96)
    ic.raw('<path d="M64 82 L64 112 M52 96 L76 96" stroke="#583f21" stroke-width="3"/>')
    icons["rail_castle"] = ic

    ic = Icon()  # Empty tick box (settings toggles); ticked = badge_check
    ic.shape(rr_d(16, 16, 96, 96, 22), "#ffffff", "#ece4dc", 76)
    icons["box_empty"] = ic

    ic = Icon()  # Tuần tra: compact brass telescope, blue lens and a broad wooden stand.
    for d in ("M62 71 L33 115", "M64 72 L67 115", "M67 70 L99 115"):
        ic.line(d, 7, "#bd8f62")
    ic.shape(rr_d(16, 38, 82, 30, 7), "#f5c565", "#f5c565", 53, rot=-25)
    ic.shape(rr_d(49, 34, 28, 38, 5), "#83b8c5", "#83b8c5", 53, rot=-25)
    ic.shape(rr_d(92, 31, 18, 44, 6), "#f5c565", "#f5c565", 53, rot=-25)
    ic.raw(f'<path d="{rr_d(100, 37, 5, 32, 2.5)}" fill="#fff0c9"/>', rot=-25)
    icons["rail_patrol"] = ic

    ic = Icon()  # Sự kiện: a festival pennant, with the game's paw in place of a star.
    ic.shape("M28 22 L100 22 L100 84 Q100 88 96 91 L68 113 Q64 117 60 113 L32 91 Q28 88 28 84 Z", "#83b8c5", "#83b8c5", 68)
    ic.raw('<path d="M37 30 L91 30 L91 81 L64 102 L37 81 Z" fill="none" stroke="#f5c565" stroke-width="4" stroke-linejoin="round"/>')
    ic.shape(rr_d(14, 13, 100, 13, 6), "#bd8f62", "#bd8f62", 20)
    feature_paw(ic, 64, 67, 0.75)
    icons["rail_event"] = ic

    # Equipment slot icons (hero gear and soldier-class gear).
    ic = Icon()  # Mũ: knight helmet with a visor slit
    ic.shape("M24 74 Q22 22 64 18 Q106 22 104 74 L104 98 Q104 110 92 110 L36 110 Q24 110 24 98 Z", "#e6eef6", "#aab8c6", 60)
    ic.shape(rr_d(30, 62, 68, 14, 6), "#5d6773", "#3f4852", 70)
    ic.raw('<path d="M64 22 L64 58" stroke="#ffd23f" stroke-width="7" stroke-linecap="round"/>')
    ic.shine(44, 36, 5)
    icons["eq_helmet"] = ic

    ic = Icon()  # Giáp: breastplate
    ic.shape("M30 24 L50 18 Q64 30 78 18 L98 24 L112 44 L100 56 L96 108 Q64 120 32 108 L28 56 L16 44 Z", "#9fd0ff", "#5b9be0", 60)
    ic.raw('<path d="M64 34 L64 104" stroke="#ffd23f" stroke-width="6" stroke-linecap="round"/><path d="M40 70 Q64 80 88 70" fill="none" stroke="#3f74b8" stroke-width="5" stroke-linecap="round"/>')
    ic.shine(42, 40, 5)
    icons["eq_armor"] = ic

    ic = Icon()  # Găng: gauntlet
    ic.shape(rr_d(34, 64, 60, 50, 12), "#d48f57", "#a8673a", 84)
    for i, x in enumerate((36, 52, 68)):
        ic.shape(rr_d(x, 26 + (6 if i == 0 else 0), 14, 46, 7), "#e6eef6", "#aab8c6", 44)
    ic.shape(rr_d(82, 50, 26, 14, 7), "#e6eef6", "#aab8c6", 56, rot=-30)
    ic.raw('<rect x="34" y="84" width="60" height="8" fill="#ffd23f"/>')
    icons["eq_gloves"] = ic

    ic = Icon()  # Giày: boot
    ic.shape("M40 16 L76 16 L76 74 L106 84 Q116 88 114 104 L114 112 L32 112 L32 96 Q40 92 40 80 Z", "#b8763f", "#8f5530", 70)
    ic.raw('<rect x="38" y="30" width="40" height="9" fill="#ffd23f"/><rect x="30" y="104" width="86" height="9" rx="3" fill="#5c3520"/>')
    ic.shine(52, 26, 4)
    icons["eq_boots"] = ic

    ic = Icon()  # Nhẫn: gold ring with a gem
    ic.line("M64 112 A32 32 0 1 1 64.1 112", 14, "#ffd23f")
    ic.shape(poly([(64, 18), (82, 34), (64, 54), (46, 34)]), "#9ff0ff", "#35b9e6", 34)
    ic.shine(58, 30, 4)
    icons["eq_ring"] = ic

    ic = Icon()  # Bùa: amulet on a chain
    ic.line("M30 18 Q64 70 98 18", 7, "#ffd23f")
    ic.shape(circle_d(64, 82, 30), "#ffe14d", "#f0b323", 76)
    ic.shape(circle_d(64, 82, 16), "#ff8b8b", "#e04b4b", 80)
    ic.shine(56, 74, 4)
    icons["eq_amulet"] = ic

    ic = Icon()  # Lính: a broad, soft-pointed shield carrying our cat-paw crest.
    # Flat coral + warm gold match the cat equipment; no faceted/glossy UI treatment.
    rim = ("M64 9 Q91 9 112 19 Q116 21 116 27 L114 61 "
           "Q112 95 69 119 Q64 122 59 119 Q16 95 14 61 "
           "L12 27 Q12 21 16 19 Q37 9 64 9 Z")
    field = ("M64 25 Q85 25 100 32 L99 60 Q97 85 64 104 "
             "Q31 85 29 60 L28 32 Q43 25 64 25 Z")
    ic.shape(rim, "#f5c565", "#f5c565", 64)
    # Inner edges stay lighter than the silhouette, so the crest has breathing room.
    ic.raw(f'<path d="{field}" fill="#df6a59" stroke="#583f21" stroke-width="3.2" stroke-linejoin="round"/>')
    pads = ["M48 79 Q47 72 53 68 Q58 65 60 62 Q64 57 68 62 "
            "Q70 65 75 68 Q81 72 80 79 Q79 86 72 85 Q64 82 56 85 Q49 86 48 79 Z"]
    pads += [ellipse_d(x, y, rx, ry) for x, y, rx, ry in
             ((44, 58, 5, 6.5), (56, 47, 5.5, 7), (72, 47, 5.5, 7), (84, 58, 5, 6.5))]
    for pad in pads:
        ic.raw(f'<path d="{pad}" fill="#fff0c9" stroke="#583f21" stroke-width="2.8" stroke-linejoin="round"/>')
    icons["tab_army"] = ic

    ic = Icon()  # Up arrow: this item can be upgraded now
    ic.shape("M64 10 L112 62 L84 62 L84 114 L44 114 L44 62 L16 62 Z", "#8ff07c", "#3fbf4a", 60)
    icons["badge_up"] = ic

    # Bottom-nav tab icons: small illustrated scenes (stall, cat, swords, gears, crystal ball,
    # sack) like the reference games, not reused currency icons.
    ic = Icon()  # Cửa hàng: a friendly paw-sign kiosk, with four broad blue/cream scallops.
    for x in (23, 95):
        ic.shape(rr_d(x, 35, 10, 47, 4), "#bd8f62", "#bd8f62", 59)
    ic.shape(rr_d(18, 73, 92, 44, 8), "#bd8f62", "#bd8f62", 95)
    ic.shape(rr_d(13, 68, 102, 13, 5), "#f5c565", "#f5c565", 75)
    roof = "M12 33 L26 13 Q28 10 33 10 L95 10 Q100 10 102 13 L116 33 Z"
    ic.shape(roof, "#83b8c5", "#83b8c5", 24)
    for i in range(4):
        x = 12 + 26 * i
        col = "#83b8c5" if i % 2 == 0 else "#fff0c9"
        ic.shape(f"M{x} 33 L{x + 26} 33 L{x + 26} 45 Q{x + 13} 61 {x} 45 Z", col, col, 44)
    ic.raw(f'<path d="{rr_d(39, 84, 50, 25, 8)}" fill="#f5c565" stroke="#583f21" stroke-width="3"/>')
    feature_paw(ic, 64, 99, 0.43)
    icons["tab_shop"] = ic

    # Mèo: not an Icon — the tab uses the hero cat head in the cat sprite style (see main()).

    ic = Icon()  # Chiến: a matched pair of short knight swords, in the flat cat style.
    # Finish the back sword before drawing the front one, keeping the X easy to read.
    for rot in (43, -43):
        ic.shape(rr_d(56, 88, 16, 28, 5), "#83b8c5", "#83b8c5", 100, rot=rot)
        ic.shape(circle_d(64, 117, 8), "#f5c565", "#f5c565", 117, rot=rot)
        blade = "M61 5 Q64 1 67 5 L81 25 L81 81 L47 81 L47 25 Z"
        ic.shape(blade, "#f5f5e9", "#f5f5e9", 42, rot=rot)
        # A single quiet steel bevel is a material detail, not a shiny highlight.
        ic.raw('<path d="M64 8 L77.8 27 L77.8 78 L64 78 Z" fill="#c4d4da"/>', rot)
        guard = ("M42 78 Q64 84 86 78 Q90 77 90 82 L90 87 "
                 "Q90 91 86 92 Q64 98 42 92 Q38 91 38 87 L38 82 Q38 77 42 78 Z")
        ic.shape(guard, "#f5c565", "#f5c565", 86, rot=rot)
    icons["tab_battle"] = ic

    ic = Icon()  # Bánh răng: two meshing gears
    ic.shape(poly(gear_pts(96, 34, 26, 7)), "#9fdcff", "#4aa4ef", 32)
    ic.raw('<circle cx="96" cy="34" r="10" fill="#2f6fae"/><circle cx="96" cy="34" r="5" fill="#9fdcff"/>')
    ic.shape(poly(gear_pts(52, 74, 46, 9)), "#ffe14d", "#f7c52f", 72)
    ic.raw('<circle cx="52" cy="74" r="24" fill="#f3af38"/><circle cx="52" cy="74" r="16" fill="#914d1a"/><circle cx="52" cy="74" r="9" fill="#ffd23f"/>')
    ic.shine(30, 52, 5)
    icons["tab_gear"] = ic

    ic = Icon()  # Triệu hồi: glowing crystal ball on a golden stand
    ic.shape(rr_d(26, 100, 76, 16, 7), "#c9814c", "#a8673a", 106)
    ic.shape("M40 102 L88 102 L80 82 L48 82 Z", "#ffe14d", "#f0b323", 90)
    ic.shape(circle_d(64, 52, 40), "#c8f2ff", "#5cc6f0", 46)
    ic.raw(f'<path d="{poly(star_pts(64, 52, 20, 6, 4))}" fill="#ffffff"/>')
    ic.raw('<path d="M40 40 Q64 18 88 40" fill="none" stroke="#ffffff" stroke-opacity="0.55" stroke-width="5" stroke-linecap="round"/>')
    ic.raw(f'<path d="{poly(star_pts(104, 20, 9, 3, 4))}" fill="#fff3a0"/><path d="{poly(star_pts(24, 30, 6, 2, 4))}" fill="#fff3a0"/>')
    icons["tab_summon"] = ic

    ic = Icon()  # Kho: tied loot sack with a coin peeking out
    coin(ic, 88, 42, 14)
    ic.shape("M30 58 Q18 114 64 116 Q110 114 98 58 Q86 46 64 46 Q42 46 30 58 Z", "#f0c487", "#d39a58", 76)
    ic.shape("M42 48 L34 26 L52 36 L64 22 L76 36 L94 26 L86 48 Z", "#f0c487", "#d39a58", 36)
    ic.shape(rr_d(42, 42, 44, 12, 6), "#e0604f", "#a8323a", 46)
    ic.raw('<path d="M48 80 Q64 72 80 80 M54 96 Q64 90 74 96" fill="none" stroke="#c4884a" stroke-width="5" stroke-linecap="round"/>')
    icons["tab_bag"] = ic

    ic = Icon()
    for x, y, r in ((40, 74, 30), (88, 74, 30), (64, 44, 30)):
        coin(ic, x, y, r)
    icons["coins"] = ic
    ic = Icon()
    for x, y, r in ((38, 76, 30), (90, 76, 30), (64, 46, 34)):
        gem(ic, x, y, r)
    icons["gems"] = ic
    return icons


# --- Weapons (one per soldier tier in the "Solider" design sheet) ---------------------------------

METAL = ("#f2f6fa", "#b7c3cf")
IRON = ("#a9b4bf", "#6f7b88")
WOOD = ("#d2945a", "#9a5f33")
DARK_WOOD = ("#8a5634", "#5c3520")
GOLD = ("#ffe14d", "#f0b323")
LEATHER = ("#e0604f", "#a8323a")


def rr_d(x, y, w, h, r):
    r = min(r, w / 2, h / 2)
    return (f"M{n(x + r)} {n(y)} L{n(x + w - r)} {n(y)} Q{n(x + w)} {n(y)} {n(x + w)} {n(y + r)} L{n(x + w)} {n(y + h - r)} "
            f"Q{n(x + w)} {n(y + h)} {n(x + w - r)} {n(y + h)} L{n(x + r)} {n(y + h)} Q{n(x)} {n(y + h)} {n(x)} {n(y + h - r)} "
            f"L{n(x)} {n(y + r)} Q{n(x)} {n(y)} {n(x + r)} {n(y)} Z")


def sparkle(ic, x, y, r):
    ic.raw(f'<path d="{poly(star_pts(x, y, r, r * 0.3, 4))}" fill="#ffffff"/>', gloss=True)


WeaponIcon = Icon  # same outline as every icon (kept as a name for the weapon section)


def wraps(ic, x, y0, y1, w, color, rot=0, step=6.0):
    """Diagonal binding lines across a grip / shaft (drawn in the weapon's own frame)."""
    out = ""
    y = y0 + step * 0.5
    while y < y1:
        out += f'<path d="M{n(x - w / 2 + 1)} {n(y + 2)} L{n(x + w / 2 - 1)} {n(y - 2)}" stroke="{color}" stroke-width="2.6" stroke-linecap="round"/>'
        y += step
    ic.raw(out, rot)


def diamond(cx, cy, rx, ry):
    return poly([(cx, cy - ry), (cx + rx, cy), (cx, cy + ry), (cx - rx, cy)])


def blade_light(ic, pts_light, rot, opacity=0.4):
    """Light half of a blade (the bevel facing the light)."""
    ic.raw(f'<path d="{poly(pts_light)}" fill="#ffffff" fill-opacity="{opacity}"/>', rot, gloss=True)


def make_weapons():
    w = {}
    STEEL = ("#f4f8fb", "#b9c6d2")
    DARK_STEEL = ("#c3ccd6", "#7d8996")
    BRONZE = ("#f2c46b", "#c98a2e")

    # --- Bộ binh ---------------------------------------------------------------------------
    ic = WeaponIcon()  # Kiếm (common): straight sword, iron cross-guard, leather grip
    r = 45
    ic.shape(poly([(64, 4), (75, 18), (75, 78), (53, 78), (53, 18)]), *STEEL, 60, rot=r)
    blade_light(ic, [(64, 4), (53, 18), (53, 78), (64, 78)], r)
    ic.raw('<path d="M64 20 L64 74" stroke="#9aa8b6" stroke-width="3" stroke-linecap="round"/>', r)
    ic.shape(rr_d(36, 77, 56, 11, 5), *DARK_STEEL, 80, rot=r)
    for x in (36, 92):
        ic.shape(circle_d(x, 82.5, 7), *DARK_STEEL, 82, rot=r)
    ic.shape(rr_d(57, 88, 14, 24, 4), "#a8673a", "#7a4524", 100, rot=r)
    wraps(ic, 64, 88, 112, 14, "#5c3520", r)
    ic.shape(circle_d(64, 117, 7.5), *DARK_STEEL, 116, rot=r)
    w["kiem"] = ic

    ic = WeaponIcon()  # Rìu (rare): bearded axe, riveted head, bound haft
    r = 35
    ic.shape(rr_d(58, 12, 12, 108, 6), "#d9a06a", "#a8673a", 60, rot=r)
    wraps(ic, 64, 78, 104, 12, "#7a4524", r)
    ic.shape(rr_d(56, 112, 16, 10, 4), *DARK_STEEL, 116, rot=r)
    ic.shape("M68 18 Q100 4 114 28 Q122 50 110 76 Q96 64 78 66 L68 60 Z", *STEEL, 40, rot=r)
    ic.raw('<path d="M100 10 Q120 30 112 70" fill="none" stroke="#ffffff" stroke-opacity="0.7" stroke-width="5" stroke-linecap="round"/>', r)
    ic.shape(poly([(58, 26), (36, 36), (58, 48)]), *DARK_STEEL, 36, rot=r)
    ic.shape(rr_d(56, 20, 16, 44, 4), "#4aa4ef", "#2c74d6", 40, rot=r)
    for y in (28, 44, 56):
        ic.raw(f'<circle cx="64" cy="{y}" r="2.6" fill="#ffffff"/>', r)
    w["riu"] = ic

    ic = WeaponIcon()  # Đao (epic): broad saber, gold guard with an amethyst, purple grip
    r = 40
    ic.shape("M55 88 L53 30 Q55 6 84 3 Q93 30 75 88 Z", *STEEL, 50, rot=r)
    blade_light(ic, [(55, 88), (53, 30), (60, 14), (64, 88)], r, 0.35)
    ic.raw('<path d="M80 8 Q88 34 72 86" fill="none" stroke="#ffffff" stroke-opacity="0.75" stroke-width="3.5" stroke-linecap="round"/>', r)
    ic.shape("M36 90 Q64 80 92 90 Q64 102 36 90 Z", "#ffe14d", "#f0b323", 90, rot=r)
    ic.shape(diamond(64, 91, 8, 7), "#e6b8ff", "#a95cf2", 90, rot=r)
    ic.shape(rr_d(57, 98, 14, 18, 4), "#8f5fd0", "#5e3398", 106, rot=r)
    wraps(ic, 64, 98, 116, 14, "#3d1f66", r)
    ic.shape(circle_d(64, 120, 6.5), "#ffe14d", "#f0b323", 118, rot=r)
    w["dao"] = ic

    ic = WeaponIcon()  # Katana (legendary): long curved blade with a hamon, gold tsuba, red wrap
    r = 45
    ic.shape("M58 84 L59 16 Q62 0 72 8 L70 84 Z", *STEEL, 46, rot=r)
    ic.raw('<path d="M66 80 Q68 72 65 64 Q62 56 66 48 Q69 40 65 32 Q62 24 66 14" fill="none" stroke="#ffffff" stroke-width="3" stroke-linecap="round"/>', r)
    ic.raw('<path d="M60 80 L61 18" stroke="#8e9aa6" stroke-width="2" stroke-linecap="round"/>', r)
    ic.shape(rr_d(58, 82, 14, 8, 3), "#ffe14d", "#f0b323", 86, rot=r)
    ic.shape(circle_d(64, 94, 13), "#ffe14d", "#f0b323", 92, rot=r)
    for dx, dy in ((-6, -6), (6, -6), (-6, 6), (6, 6)):
        ic.raw(f'<circle cx="{64 + dx}" cy="{94 + dy}" r="2.4" fill="#b8860b"/>', r)
    ic.shape(rr_d(57, 104, 14, 18, 5), "#e24a5a", "#a8263a", 112, rot=r)
    ic.raw("".join(f'<path d="{diamond(64, y, 4, 3)}" fill="#fff3e0"/>' for y in (108, 114, 120)), r)
    ic.shape(circle_d(64, 124, 5), "#ffe14d", "#f0b323", 122, rot=r)
    sparkle(ic, 104, 20, 9)
    sparkle(ic, 24, 96, 6)
    w["katana"] = ic

    # --- Tầm xa ------------------------------------------------------------------------------
    ic = WeaponIcon()  # Cung (common): recurve bow with gold tips and a nocked arrow
    r = -20
    ic.line("M44 14 L44 114", 3, "#f3e6d8", rot=r)
    ic.shape("M40 6 Q116 64 40 122 L50 122 Q98 64 50 6 Z", "#d9a06a", "#a8673a", 60, rot=r)
    ic.shape(rr_d(70, 52, 14, 24, 5), "#e0604f", "#a8323a", 64, rot=r)
    for y in (8, 120):
        ic.shape(circle_d(45, y, 6), "#ffe14d", "#f0b323", y, rot=r)
    ic.shape(rr_d(30, 61, 80, 6, 3), "#d9a06a", "#a8673a", 64, rot=r)
    ic.shape(poly([(108, 56), (124, 64), (108, 72)]), *STEEL, 64, rot=r)
    ic.shape(poly([(30, 56), (42, 61), (42, 67), (30, 72), (34, 64)]), "#ff8b7a", "#d8433a", 64, rot=r)
    w["cung"] = ic

    ic = WeaponIcon()  # Nỏ (rare): steel prod, wooden stock, loaded bolt, brass fittings
    ic.shape(rr_d(55, 38, 18, 82, 7), "#d9a06a", "#a8673a", 70)
    ic.raw('<path d="M60 60 L60 112 M68 60 L68 112" stroke="#b8763f" stroke-width="2"/>')
    ic.line("M14 56 L64 74 L114 56", 3, "#f3e6d8")
    ic.shape("M10 50 Q64 20 118 50 L118 61 Q64 33 10 61 Z", *DARK_STEEL, 44)
    for x in (12, 116):
        ic.shape(circle_d(x, 56, 7), *BRONZE, 56)
    ic.shape(rr_d(59, 14, 10, 60, 3), "#d9a06a", "#a8673a", 40)
    ic.shape(poly([(64, 2), (73, 18), (55, 18)]), *STEEL, 12)
    ic.shape(rr_d(54, 44, 20, 10, 3), *BRONZE, 48)
    ic.shape(rr_d(54, 86, 20, 8, 3), *BRONZE, 90)
    ic.line("M60 96 Q50 104 58 112", 4, "#5c3520")
    w["no"] = ic

    ic = WeaponIcon()  # Súng (epic): flintlock musket, brass bands, grained stock
    r = -28
    ic.shape(rr_d(4, 52, 88, 14, 5), *DARK_STEEL, 58, rot=r)
    ic.raw('<path d="M8 55 L88 55" stroke="#ffffff" stroke-opacity="0.6" stroke-width="2.5"/>', r)
    ic.shape("M80 50 L124 56 L124 84 L104 86 L90 70 L80 68 Z", "#b97440", "#8a5634", 66, rot=r)
    ic.raw('<path d="M94 62 Q108 64 120 62 M96 72 Q110 76 120 74" fill="none" stroke="#6b3f24" stroke-width="2.5" stroke-linecap="round"/>', r)
    for x in (24, 50, 74):
        ic.shape(rr_d(x, 49, 7, 20, 2), *BRONZE, 58, rot=r)
    ic.shape(rr_d(2, 48, 8, 22, 3), *BRONZE, 58, rot=r)
    ic.shape("M80 46 L88 38 L94 42 L88 50 Z", *DARK_STEEL, 44, rot=r)
    ic.raw('<path d="M84 68 Q86 82 98 80" fill="none" stroke="#3c1e0c" stroke-width="4.5" stroke-linecap="round"/>', r)
    w["sung"] = ic

    ic = WeaponIcon()  # Đại bác (legendary): bronze cannon on a carriage, balls stacked
    ic.shape("M30 82 L100 48 Q114 42 118 56 L119 62 Q119 74 106 78 L38 102 Q24 102 24 90 Z", *BRONZE, 60)
    ic.raw('<path d="M36 82 L104 52" stroke="#ffffff" stroke-opacity="0.6" stroke-width="4" stroke-linecap="round"/>')
    for x, y in ((56, 74), (80, 63)):
        ic.raw(f'<path d="M{x} {y - 12} L{x + 8} {y + 14}" stroke="#a8671f" stroke-width="7" stroke-linecap="round"/>')
    ic.shape(ellipse_d(113, 59, 9, 15), "#5d4020", "#3c2410", 59)
    ic.shape("M14 100 L74 86 L80 108 L20 118 Z", "#b97440", "#8a5634", 100)
    ic.shape(circle_d(46, 106, 20), "#d9a06a", "#a8673a", 104)
    ic.raw("".join(f'<path d="M46 106 L{n(46 + math.cos(a) * 16)} {n(106 + math.sin(a) * 16)}" stroke="#7a4524" stroke-width="4"/>' for a in [i * math.pi / 3 for i in range(6)]))
    ic.shape(circle_d(46, 106, 6), *BRONZE, 104)
    for x, y in ((96, 112), (110, 112), (103, 100)):
        ic.shape(circle_d(x, y, 8), "#6b7380", "#3f4852", y)
    w["dai_bac"] = ic

    # --- Pháp sư -----------------------------------------------------------------------------
    ic = WeaponIcon()  # Gậy phép (common): staff with a crescent holding a glowing orb
    r = 25
    ic.shape(rr_d(58, 42, 12, 84, 6), "#b97440", "#8a5634", 60, rot=r)
    wraps(ic, 64, 64, 84, 12, "#ffd23f", r, 7)
    ic.shape(rr_d(56, 40, 16, 8, 3), *BRONZE, 44, rot=r)
    ic.shape("M44 44 Q38 12 64 4 Q90 12 84 44 Q78 30 64 30 Q50 30 44 44 Z", "#8a5634", "#5c3520", 26, rot=r)
    ic.raw('<circle cx="64" cy="24" r="22" fill="#9ff0ff" fill-opacity="0.35"/>', r)
    ic.shape(circle_d(64, 24, 14), "#d6f8ff", "#3fa9e8", 22, rot=r)
    ic.raw(f'<path d="{poly(star_pts(64, 24, 8, 2.5, 4))}" fill="#ffffff"/>', r)
    sparkle(ic, 104, 18, 8)
    sparkle(ic, 22, 44, 5)
    w["gay_phep"] = ic

    ic = WeaponIcon()  # Thuốc (rare): round flask, pink brew with bubbles, cork and gold tie
    ic.shape(circle_d(64, 82, 38), "#eefaff", "#c3e6f4", 70)
    ic.raw('<clipPath id="flask"><circle cx="64" cy="82" r="36"/></clipPath>'
           '<g clip-path="url(#flask)"><rect x="20" y="78" width="88" height="44" fill="#ff7fa2"/>'
           '<path d="M26 80 Q46 72 64 80 Q82 88 102 80 L102 84 L26 84 Z" fill="#ffb3c8"/></g>')
    for x, y, rr in ((50, 98, 5), (74, 106, 3.5), (80, 92, 2.5), (60, 110, 2.5)):
        ic.raw(f'<circle cx="{x}" cy="{y}" r="{rr}" fill="#ffe3ec"/>')
    ic.shape(rr_d(50, 28, 28, 22, 5), "#eefaff", "#c3e6f4", 36)
    ic.shape(rr_d(52, 10, 24, 20, 6), "#d9a06a", "#a8673a", 18)
    ic.shape(rr_d(48, 42, 32, 7, 3), "#ffe14d", "#f0b323", 46)
    ic.shine(46, 66, 6, 10)
    w["thuoc"] = ic

    ic = WeaponIcon()  # Sách phép (epic): tome with gold corners, clasp and a glowing rune
    ic.shape(rr_d(32, 22, 80, 92, 8), "#fffaf0", "#e8dcc8", 60)
    ic.raw("".join(f'<path d="M106 {y} L112 {y}" stroke="#d8ccb6" stroke-width="2"/>' for y in range(30, 110, 6)))
    ic.shape(rr_d(14, 16, 88, 96, 10), "#c79bf0", "#7d4fc4", 60)
    ic.shape(rr_d(14, 16, 18, 96, 8), "#9a6ad8", "#5e3398", 60)
    for x, y in ((90, 18), (90, 98)):
        ic.shape(poly([(x, y), (x + 12, y), (x + 12, y + 12)]) if y < 50 else poly([(x + 12, y), (x + 12, y + 12), (x, y + 12)]), "#ffe14d", "#f0b323", y)
    ic.raw('<circle cx="62" cy="64" r="26" fill="#ffe680" fill-opacity="0.3"/>')
    ic.raw('<circle cx="62" cy="64" r="22" fill="none" stroke="#ffe14d" stroke-width="3" stroke-dasharray="5 4"/>')
    ic.shape(poly(star_pts(62, 64, 15, 6)), "#fff3a0", "#ffd23f", 60)
    ic.shape(rr_d(96, 56, 14, 18, 4), "#ffe14d", "#f0b323", 64)
    w["sach_phep"] = ic

    ic = WeaponIcon()  # Đũa phép (legendary): spiral wand, gold bands, star tip trailing sparkles
    r = 35
    ic.shape(rr_d(58, 44, 12, 80, 6), "#8a5634", "#5c3520", 60, rot=r)
    ic.raw("".join(f'<path d="M58 {y} Q64 {y + 4} 70 {y - 2}" fill="none" stroke="#c9905d" stroke-width="2.5"/>' for y in range(56, 120, 9)), r)
    for y in (44, 88):
        ic.shape(rr_d(56, y, 16, 7, 3), "#ffe14d", "#f0b323", y + 4, rot=r)
    ic.raw('<circle cx="64" cy="26" r="26" fill="#fff3a0" fill-opacity="0.35"/>', r)
    ic.shape(poly(star_pts(64, 26, 24, 11)), "#fff3a0", "#ffc21f", 26, rot=r)
    ic.raw('<circle cx="64" cy="26" r="5" fill="#ffffff"/>', r)
    for x, y, s in ((106, 18, 9), (90, 46, 6), (26, 30, 6), (110, 50, 4)):
        sparkle(ic, x, y, s)
    w["dua_phep"] = ic

    # --- Kỵ binh -----------------------------------------------------------------------------
    ic = WeaponIcon()  # Giáo (common): leaf-blade spear, red tassel, bound shaft
    r = 45
    ic.shape(rr_d(59, 34, 10, 92, 5), "#d9a06a", "#a8673a", 60, rot=r)
    wraps(ic, 64, 90, 120, 10, "#7a4524", r, 7)
    ic.shape("M57 46 Q48 62 54 76 L64 62 L74 76 Q80 62 71 46 Z", "#ff8b7a", "#d8433a", 60, rot=r)
    ic.shape("M64 2 Q82 22 72 42 L56 42 Q46 22 64 2 Z", *STEEL, 26, rot=r)
    ic.raw('<path d="M64 8 L64 38" stroke="#9aa8b6" stroke-width="2.5" stroke-linecap="round"/>', r)
    ic.shape(rr_d(55, 40, 18, 9, 3), *BRONZE, 44, rot=r)
    w["giao"] = ic

    ic = WeaponIcon()  # Cự kiếm (rare): broad greatsword with a glowing rune, winged guard, gem
    r = 45
    ic.shape(poly([(64, 0), (83, 16), (83, 78), (45, 78), (45, 16)]), *STEEL, 52, rot=r)
    blade_light(ic, [(64, 0), (45, 16), (45, 78), (64, 78)], r)
    ic.raw('<path d="M58 24 L64 18 L70 24 M58 40 L70 40 M64 34 L64 66 M58 58 L70 52" fill="none" stroke="#4aa4ef" stroke-width="3.5" stroke-linecap="round"/>', r)
    ic.shape("M24 84 Q30 74 46 78 L82 78 Q98 74 104 84 Q98 94 82 90 L46 90 Q30 94 24 84 Z", *BRONZE, 84, rot=r)
    ic.shape(diamond(64, 84, 9, 8), "#bfe6ff", "#3f86c8", 82, rot=r)
    ic.shape(rr_d(57, 90, 14, 24, 4), "#5b8fd6", "#2f5f9e", 102, rot=r)
    wraps(ic, 64, 90, 114, 14, "#1f3f6e", r)
    ic.shape(circle_d(64, 119, 7), *BRONZE, 118, rot=r)
    w["cu_kiem"] = ic

    ic = WeaponIcon()  # Chùy (epic): morning star with spikes, gold band, bound handle
    r = 30
    ic.shape(rr_d(58, 58, 12, 64, 6), "#b97440", "#8a5634", 60, rot=r)
    wraps(ic, 64, 90, 116, 12, "#5c3520", r, 7)
    ic.shape(rr_d(55, 58, 18, 10, 3), *BRONZE, 62, rot=r)
    ic.shape(poly(star_pts(64, 36, 38, 24, 8)), *DARK_STEEL, 30, rot=r)
    ic.shape(circle_d(64, 36, 24), *STEEL, 30, rot=r)
    ic.raw('<path d="M42 36 Q64 46 86 36" fill="none" stroke="#ffd23f" stroke-width="5"/>', r)
    ic.shape(diamond(64, 34, 7, 7), "#e6b8ff", "#a95cf2", 32, rot=r)
    w["chuy"] = ic

    ic = WeaponIcon()  # Búa (legendary): war hammer, gold-rimmed head with a rune, bound handle
    r = 30
    ic.shape(rr_d(58, 46, 12, 80, 6), "#b97440", "#8a5634", 60, rot=r)
    wraps(ic, 64, 92, 120, 12, "#5c3520", r, 7)
    ic.shape(rr_d(22, 14, 84, 42, 10), *DARK_STEEL, 32, rot=r)
    ic.raw('<path d="M30 20 L98 20" stroke="#ffffff" stroke-opacity="0.6" stroke-width="4" stroke-linecap="round"/>', r)
    for x in (22, 94):
        ic.shape(rr_d(x, 10, 12, 50, 4), "#ffe14d", "#f0b323", 30, rot=r)
    ic.shape(rr_d(54, 12, 20, 46, 4), "#ffe14d", "#f0b323", 30, rot=r)
    ic.shape(diamond(64, 35, 8, 10), "#ff9a8a", "#e04b4b", 34, rot=r)
    sparkle(ic, 108, 16, 8)
    w["bua"] = ic
    return w


# --- Cats (style of the cat-game sprites on the "Asset bổ sung" page) ------------------------------
# Flat fills with no shading, one even dark-brown line (#583f21, ~4% of the height, round joins),
# a wide mochi head over a rounded body, triangle ears with pink insides, arms drawn as two
# curves on the belly, a curled tail behind, dot eyes and an "ω" mouth.

CAT_LINE = "#583f21"
CAT_EAR = "#f6b8b0"
CAT_EYE = "#3b2a1a"
CATS = {  # fill, stripe/patch colours
    "cream": ("#f2d2ac", None),
    "tabby": ("#f9d27b", "#d89f4c"),
    "grey": ("#c4c4c4", "#8a8a8a"),
    "calico": ("#fdfaf5", ("#f2a65a", "#4a3a32")),
    "hero": ("#f5a25d", "#fdfaf5"),  # ginger with a white muzzle and chest: no regular cat has it
}
CAT_HEAD = "M128 34 C196 34 214 58 214 92 C214 128 186 144 128 144 C70 144 42 128 42 92 C42 58 60 34 128 34 Z"
CAT_BODY = ("M76 116 L180 116 Q206 116 208 150 L212 204 Q213 232 184 232 Q156 234 145 221 Q128 206 111 221 "
            "Q100 234 72 232 Q43 232 44 204 L48 150 Q50 116 76 116 Z")


def _line(width=12):
    return f'stroke="{CAT_LINE}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"'


def cat_svg(kind, head_only=False):
    fill, marks = CATS[kind]
    defs = f'<clipPath id="head"><path d="{CAT_HEAD}"/></clipPath><clipPath id="body"><path d="{CAT_BODY}"/></clipPath>'
    body = ""
    if not head_only:
        # Tail behind the body: dark stroke under a colour stroke.
        tail = "M182 210 Q236 214 232 166 Q230 150 220 150"
        body += f'<path d="{tail}" fill="none" stroke="{CAT_LINE}" stroke-width="30" stroke-linecap="round"/>'
        body += f'<path d="{tail}" fill="none" stroke="{fill}" stroke-width="13" stroke-linecap="round"/>'
        if kind == "hero":
            # Blue cape with a gold hem, then the main sword slung across the back (hilt by the
            # left shoulder, sheath tip by the right foot).
            body += f'<path d="M54 128 L202 128 L234 228 Q128 248 22 228 Z" fill="#4f7fd0" {_line()}/>'
            body += '<path d="M30 220 Q128 240 226 220" fill="none" stroke="#ffd23f" stroke-width="8" stroke-linecap="round"/>'
            for width, colour in ((24, CAT_LINE), (12, "#6b3d26")):
                body += f'<path d="M206 222 L44 112" stroke="{colour}" stroke-width="{width}" stroke-linecap="round"/>'
            for width, colour in ((20, CAT_LINE), (9, "#8a5634")):
                body += f'<path d="M44 112 L22 84" stroke="{colour}" stroke-width="{width}" stroke-linecap="round"/>'
            body += f'<path d="M30 128 L58 98" stroke="{CAT_LINE}" stroke-width="20" stroke-linecap="round"/><path d="M30 128 L58 98" stroke="#ffd23f" stroke-width="9" stroke-linecap="round"/>'
            body += f'<circle cx="18" cy="78" r="9" fill="#ffd23f" {_line(6)}/>'
        body += f'<path d="{CAT_BODY}" fill="{fill}" {_line()}/>'
        if kind == "tabby" or kind == "grey":
            body += '<g clip-path="url(#body)">' + "".join(
                f'<path d="M50 {y} Q72 {y + 6} 92 {y}" fill="none" stroke="{marks}" stroke-width="8" stroke-linecap="round"/>'
                f'<path d="M164 {y} Q184 {y + 6} 206 {y}" fill="none" stroke="{marks}" stroke-width="8" stroke-linecap="round"/>'
                for y in (150, 172, 194)) + "</g>"
        if kind == "calico":
            body += f'<g clip-path="url(#body)"><path d="{ellipse_d(170, 196, 30, 26)}" fill="{marks[0]}"/></g>'
            body += f'<path d="{CAT_BODY}" fill="none" {_line()}/>'
        if kind == "hero":
            body += f'<g clip-path="url(#body)"><path d="{ellipse_d(128, 152, 40, 46)}" fill="{marks}"/></g>'
            body += f'<path d="{CAT_BODY}" fill="none" {_line()}/>'
        body += f'<path d="M104 152 Q114 166 106 174 Q97 181 84 172" fill="none" {_line(13)}/><path d="M152 152 Q142 166 150 174 Q159 181 172 172" fill="none" {_line(13)}/>'
        if kind == "hero":  # gold clasps holding the cape at the shoulders
            body += f'<circle cx="74" cy="134" r="8" fill="#ffd23f" {_line(6)}/><circle cx="182" cy="134" r="8" fill="#ffd23f" {_line(6)}/>'
    # Ears (outer, then pink inside), then the head over their bases.
    for sx in (1, -1) if kind != "hero" else ():  # the hero's ears are part of its helmet
        def x(v):
            return 128 + sx * (v - 128)
        body += f'<path d="M{x(46)} 90 Q{x(48)} 34 {x(58)} 16 Q{x(64)} 8 {x(74)} 16 Q{x(100)} 32 {x(120)} 46 Z" fill="{fill}" {_line()}/>'
        body += f'<path d="M{x(60)} 72 Q{x(61)} 40 {x(66)} 30 Q{x(70)} 26 {x(76)} 30 Q{x(92)} 40 {x(104)} 48 Z" fill="{CAT_EAR}"/>'
    body += f'<path d="{CAT_HEAD}" fill="{fill}"/>'
    if kind in ("tabby", "grey"):
        body += '<g clip-path="url(#head)">' + "".join(
            f'<path d="M{x0} 34 L{x0} 54" stroke="{marks}" stroke-width="8" stroke-linecap="round"/>' for x0 in (112, 128, 144))
        body += "".join(f'<path d="M{a} {y} Q{(a + b) / 2} {y + 4} {b} {y}" fill="none" stroke="{marks}" stroke-width="7" stroke-linecap="round"/>'
                        for a, b, y in ((36, 60, 100), (36, 58, 116), (196, 220, 100), (198, 220, 116))) + "</g>"
    if kind == "calico":
        body += f'<g clip-path="url(#head)"><path d="{ellipse_d(78, 66, 40, 34)}" fill="{marks[0]}"/><path d="{ellipse_d(186, 60, 30, 26)}" fill="{marks[1]}"/></g>'
    if kind == "hero":
        body += f'<g clip-path="url(#head)"><path d="{ellipse_d(128, 116, 42, 26)}" fill="{marks}"/></g>'
    body += f'<path d="{CAT_HEAD}" fill="none" {_line()}/>'
    # Face.
    body += f'<circle cx="104" cy="96" r="9" fill="{CAT_EYE}"/><circle cx="152" cy="96" r="9" fill="{CAT_EYE}"/>'
    body += f'<path d="M110 110 Q119 124 128 112 Q137 124 146 110" fill="none" stroke="{CAT_EYE}" stroke-width="7.5" stroke-linecap="round" stroke-linejoin="round"/>'
    if kind == "hero":
        # Determined brows, then a silver knight helmet with metal cat ears, a gold band, a centre
        # ridge and a red plume: the silhouette no other cat has.
        body += f'<path d="M90 82 L114 88" stroke="{CAT_EYE}" stroke-width="7" stroke-linecap="round"/><path d="M166 82 L142 88" stroke="{CAT_EYE}" stroke-width="7" stroke-linecap="round"/>'
        helmet = "M46 84 Q44 40 56 20 Q63 11 72 20 L96 38 Q128 28 160 38 L184 20 Q193 11 200 20 Q212 40 210 84 Q128 66 46 84 Z"
        body += f'<path d="{helmet}" fill="#dfe6ee" {_line()}/>'
        body += '<path d="M56 76 Q128 58 200 76" fill="none" stroke="#ffd23f" stroke-width="9" stroke-linecap="round"/>'
        body += '<path d="M128 34 L128 62" stroke="#b6c3cf" stroke-width="6" stroke-linecap="round"/>'
        body += f'<path d="M62 54 L64 30 L82 42 Z" fill="{CAT_EAR}"/><path d="M194 54 L192 30 L174 42 Z" fill="{CAT_EAR}"/>'
        body += f'<path d="M124 34 Q122 6 146 2 Q176 -2 196 12 Q176 10 166 16 Q184 20 170 30 Q150 24 136 38 Z" fill="#e0504a" {_line(8)}/>'
        body += '<path d="M136 26 Q152 12 182 12" fill="none" stroke="#ff8b7a" stroke-width="5" stroke-linecap="round"/>'
    if head_only:
        return f'<svg xmlns="http://www.w3.org/2000/svg" width="184" height="148" viewBox="36 0 184 148"><defs>{defs}</defs>{body}</svg>\n'
    return svg(256, 240, body, defs)


# --- Lobby pieces ------------------------------------------------------------------------------

def stage_island():
    """The current stage as an isometric grass block: a rhombus top seen at an angle, a lit
    left dirt face and a darker right face, a grass lip hanging over the edges, trees at the
    back corners and bushes at the front ones (back to front), like Gear Defenders' islands.
    560x400; the top's centre (where the cat stands) is at (280, 168)."""
    w, h = 560, 400
    L, T, R, B = (34, 168), (280, 58), (526, 168), (280, 278)
    D = 96  # side depth
    Ld, Bd, Rd = (L[0], L[1] + D), (B[0], B[1] + D), (R[0], R[1] + D)
    ln = f'stroke="{LINE}" stroke-width="7" stroke-linejoin="round"'
    body = f'<path d="{ellipse_d(280, 384, 230, 16)}" fill="#000" fill-opacity="0.16"/>'
    body += f'<path d="{poly([L, B, Bd, Ld])}" fill="#b8763f" {ln}/>'
    body += f'<path d="{poly([B, R, Rd, Bd])}" fill="#8f5530" {ln}/>'
    for k in (0.38, 0.7):  # strata parallel to the top edges
        y = D * k
        body += f'<path d="M{L[0] + 6} {n(L[1] + y)} L{B[0]} {n(B[1] + y)}" stroke="#9c6234" stroke-width="5" stroke-linecap="round"/>'
        body += f'<path d="M{B[0]} {n(B[1] + y)} L{R[0] - 6} {n(R[1] + y)}" stroke="#74431f" stroke-width="5" stroke-linecap="round"/>'
    for x, y, r in ((110, 248, 10), (200, 318, 12), (360, 300, 11), (452, 252, 9)):
        body += f'<path d="{ellipse_d(x, y, r * 1.5, r)}" fill="#d49a63" fill-opacity="0.7"/>'
    # Grass top with a wavy lip hanging over the two side faces.
    lip = []
    for i in range(13):
        t = i / 12
        lip.append((L[0] + (B[0] - L[0]) * t, L[1] + (B[1] - L[1]) * t + (16 if i % 2 else 8)))
    for i in range(1, 13):
        t = i / 12
        lip.append((B[0] + (R[0] - B[0]) * t, B[1] + (R[1] - B[1]) * t + (16 if i % 2 else 8)))
    body += f'<path d="{poly([L, T, R] + lip[::-1])}" fill="#5fae47" {ln}/>'
    body += f'<path d="{poly([L, T, R, B])}" fill="#8fd16a" {ln}/>'
    body += f'<path d="{poly([(L[0] + 40, L[1]), (T[0], T[1] + 20), (R[0] - 40, R[1]), (B[0], B[1] - 20)])}" fill="#9ddb76"/>'
    for x, y in ((170, 140), (400, 196), (330, 120), (190, 214)):  # grass tufts
        body += f'<path d="M{x - 8} {y} l4 -12 l4 8 l4 -14 l4 14 l4 -8 l4 12 Z" fill="#6cbf52"/>'

    def tree(x, y, sc):
        out = f'<path d="{ellipse_d(x, y + 4, 26 * sc, 9 * sc)}" fill="#000" fill-opacity="0.15"/>'
        out += f'<rect x="{n(x - 8 * sc)}" y="{n(y - 34 * sc)}" width="{n(16 * sc)}" height="{n(38 * sc)}" rx="5" fill="#8a5634" stroke="{LINE}" stroke-width="6"/>'
        for dx, dy, r in ((-22, -50, 28), (22, -50, 28), (0, -76, 32)):
            out += f'<path d="{circle_d(x + dx * sc, y + dy * sc, r * sc)}" fill="#4f9d3f" stroke="{LINE}" stroke-width="6"/>'
        for dx, dy, r in ((-22, -56, 14), (0, -84, 16), (20, -58, 10)):
            out += f'<path d="{circle_d(x + dx * sc, y + dy * sc, r * sc)}" fill="#74c45c"/>'
        return out

    def bush(x, y, sc):
        out = ""
        for dx, dy, r in ((-14, 0, 15), (14, 0, 15), (0, -9, 18)):
            out += f'<path d="{circle_d(x + dx * sc, y + dy * sc, r * sc)}" fill="#5aa947" stroke="{LINE}" stroke-width="5"/>'
        out += f'<path d="{circle_d(x - 4 * sc, y - 14 * sc, 7 * sc)}" fill="#86d066"/>'
        return out

    body += tree(120, 156, 1.0) + tree(440, 156, 1.0) + tree(280, 96, 0.8)  # back row
    return svg(w, h, body)


def callout():
    """Yellow speech tag pointing down (the "Triệu hồi 10" hint above a nav tab)."""
    d = "M14 4 L146 4 Q156 4 156 14 L156 34 Q156 44 146 44 L90 44 L80 56 L70 44 L14 44 Q4 44 4 34 L4 14 Q4 4 14 4 Z"
    return svg(160, 60, f'<path d="{d}" fill="#ffe680" stroke="{LINE}" stroke-width="4" stroke-linejoin="round"/>'
                        '<rect x="12" y="8" width="136" height="10" rx="5" fill="#fff4b8"/>')


def fish_flat(size):
    """Cá, the in-battle resource, drawn like the cats (cat-sprite-art rules), not like the UI
    icons: flat fills, one even #583f21 line about 5% of the size (2.5 px minimum), a dot eye.
    A plump blue fish facing right with a pale belly and a forked tail. 128 grid."""
    w = max(2.5, size * 0.05) * 128 / size
    ln = f'stroke="{CAT_LINE}" stroke-width="{n(w)}" stroke-linejoin="round" stroke-linecap="round"'
    body_d = "M28 64 Q44 28 82 28 Q114 30 122 64 Q114 98 82 100 Q44 100 28 64 Z"
    out = f'<path d="M34 64 L8 38 Q6 32 12 33 Q24 40 40 56 Z M34 64 L8 90 Q6 96 12 95 Q24 88 40 72 Z" fill="#7fb6e0" {ln}/>'
    out += f'<path d="M66 32 Q78 14 96 22 Q92 28 90 34 Z" fill="#7fb6e0" {ln}/>'
    out += f'<path d="{body_d}" fill="#9fd0f2"/>'
    out += '<g clip-path="url(#fb)"><path d="M20 74 Q76 96 130 72 L130 110 L20 110 Z" fill="#e6f4fb"/></g>'
    out += f'<path d="{body_d}" fill="none" {ln}/>'
    out += f'<path d="M84 44 Q76 64 84 84" fill="none" {ln}/>'
    out += f'<circle cx="104" cy="56" r="7" fill="{CAT_EYE}"/>'
    out += f'<path d="M110 74 Q114 78 118 74" fill="none" stroke="{CAT_EYE}" stroke-width="{n(w * 0.7)}" stroke-linecap="round"/>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 128 128"><defs><clipPath id="fb"><path d="{body_d}"/></clipPath></defs>{out}</svg>\n'


def bg_tile():
    """Lobby backdrop tile: a gear and a cat paw in white at low opacity on transparent.
    Ui.pattern_bg repeats it on a diagonal and scrolls it (game/ui/pattern_scroll.gdshader).
    Two of each per tile, offset half a tile, so the rows read as a diagonal weave."""
    def gear(cx, cy, r, rot):
        pts = []
        for k in range(32):
            ang = math.radians(k * 360 / 32 + rot)
            rr = r if k % 4 in (1, 2) else r * 0.76
            pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
        return f'<path d="{poly(pts)} {circle_d(cx, cy, r * 0.3)}" fill-rule="evenodd"/>'
    body = '<g fill="#ffffff" fill-opacity="0.16">'
    body += gear(60, 60, 36, 8) + gear(180, 180, 30, 20)
    body += "</g>"
    body += paw_mark(180, 64, 3.4, "#ffffff", 0.16) + paw_mark(60, 184, 3.0, "#ffffff", 0.16)
    return svg(240, 240, body)


def rail_bg():
    return svg(96, 96, rect(0, 0, 96, 96, 30, "#2b3a55", ' fill-opacity="0.18"'))


SHORTCUT_TONES = {
    "peach": ("#f0cbb8", "#c79375"),
    "sage": ("#cbdcb6", "#97ae7e"),
    "lavender": ("#d9c8e8", "#ad94c2"),
    "sand": ("#f1d9a7", "#c3a06d"),
}


def shortcut_card(tone):
    """One small feature tile: pastel icon field, cream caption band and a flat base lip."""
    face, lip = SHORTCUT_TONES[tone]
    body = rect(3, 8, 102, 117, 20, lip, f' stroke="{CAT_LINE}" stroke-width="3.5"')
    body += rect(3, 3, 102, 117, 20, face)
    body += '<g clip-path="url(#featureface)"><rect x="3" y="88" width="102" height="32" fill="#fff0d3"/></g>'
    body += '<path d="M5 88 L103 88" stroke="#b89a70" stroke-width="2"/>'
    body += rect(9, 9, 90, 105, 15, "none", ' stroke="#fff0d3" stroke-width="2"')
    body += rect(3, 3, 102, 117, 20, "none", f' stroke="{CAT_LINE}" stroke-width="3.5"')
    return svg(108, 128, body, '<clipPath id="featureface">' + rect(3, 3, 102, 117, 20, "#fff") + '</clipPath>')


GEAR_TONES = {'green': ('#7fd45f', '#c9f2b0', '#5aa947'), 'blue': ('#5fb0ea', '#bfe6ff', '#3f86c8'), 'purple': ('#b07be6', '#e6cdff', '#8752c4'), 'orange': ('#f7a24f', '#ffe2b0', '#d47b2a'), 'grey': ('#a9a39e', '#dcd6d0', '#86807b')}


def gear_card_bg(tone):
    """Rarity card behind an item: face colour with a soft light centre (the item sits in it),
    faint diagonal stripes, a darker foot band, cat-brown outline. 128x128, 9-slice safe."""
    face, glow, foot = GEAR_TONES[tone]
    defs = (f'<clipPath id="c">{rect(4, 4, 120, 120, 16, "#000")}</clipPath>'
            f'<radialGradient id="r" cx="0.5" cy="0.55" r="0.55"><stop offset="0" stop-color="{glow}"/>'
            f'<stop offset="1" stop-color="{face}"/></radialGradient>')
    body = rect(0, 4, 128, 124, 20, "#000000", ' fill-opacity="0.22"')
    body += rect(0, 0, 128, 124, 20, CAT_LINE)
    body += f'<rect x="4" y="4" width="120" height="116" rx="16" fill="url(#r)"/>'
    body += '<g clip-path="url(#c)">'
    for x in range(-120, 160, 22):
        body += f'<path d="M{x} 128 L{x + 128} 0" stroke="#ffffff" stroke-opacity="0.10" stroke-width="7"/>'
    body += f'<rect x="0" y="100" width="128" height="24" fill="{foot}"/>'
    body += '<rect x="12" y="8" width="104" height="4" rx="2" fill="#ffffff" fill-opacity="0.45"/></g>'
    return svg(128, 128, body, defs)


BATTLE_COG_TONES = {
    # face, recessed centre, inset rim: cat-game pastels, no gloss or metal shading.
    "tier_1": ("#ead5ac", "#c9ad81", "#fff5d9"),
    "tier_2": ("#80bfd7", "#5998b1", "#c4eaf0"),
    "tier_3": ("#b49cd6", "#8d70b4", "#e4d7f2"),
    "tier_4": ("#eead6c", "#cf8248", "#ffe2b0"),
    "tier_5": ("#aec778", "#7fa054", "#e1edbc"),
    "idle": ("#aaa995", "#858675", "#d5d4bf"),
}


def battle_cog(fill, centre, rim):
    """Chunky disk + short broad teeth, adapted from Gear Defenders for the cat game.

    Outer 54, shoulder 44 and a 36.5 deep clearance notch keep the 100px grid and
    8-tooth pin drive. Tooth/gap centres stay at .3/.8 of a pitch. PinMeshTest checks
    the rounded contour, including its 3px ink, rather than an ideal wedge.
    """
    points = []
    pitch = math.tau / 8
    for tooth in range(8):
        for fraction, radius in ((0.05, 44), (0.18, 54), (0.42, 54), (0.55, 44), (0.8, 36.5)):
            a = (tooth + fraction) * pitch
            points.append((64 + math.cos(a) * radius, 64 + math.sin(a) * radius))
    # Rounded flat caps and concave notches, not long pointed spokes.
    entries, exits = [], []
    for index, point in enumerate(points):
        def towards(other):
            distance = math.dist(point, other)
            cut = min(2.2, distance * 0.22)
            return tuple(p + (q - p) * cut / distance for p, q in zip(point, other))
        entries.append(towards(points[index - 1]))
        exits.append(towards(points[(index + 1) % len(points)]))
    coord = lambda point: f"{n(point[0])} {n(point[1])}"
    path = f"M{coord(entries[0])}"
    for index, point in enumerate(points):
        path += f" Q{coord(point)} {coord(exits[index])} L{coord(entries[(index + 1) % len(points)])}"
    body = f'<path d="{path} Z" fill="{fill}" stroke="{CAT_LINE}" stroke-width="3" stroke-linejoin="round"/>'
    # A continuous inset lip follows the complete silhouette. All colours remain flat.
    body += f'<path d="{path} Z" transform="translate(64 64) scale(.94) translate(-64 -64)" fill="none" stroke="{rim}" stroke-width="2" stroke-linejoin="round"/>'
    body += f'<circle cx="64" cy="64" r="29.5" fill="{centre}"/>'
    return svg(128, 128, body)


def make_battle_cogs():
    os.makedirs(OUT, exist_ok=True)
    for tone, palette in BATTLE_COG_TONES.items():
        save(f"battle_cog_{tone}", battle_cog(*palette))


def main():
    os.makedirs(OUT, exist_ok=True)
    save("stage_island", stage_island())
    save("callout", callout())
    save("rail_bg", rail_bg())
    for tone in SHORTCUT_TONES:
        save("shortcut_" + tone, shortcut_card(tone))
    save("bg_tile", bg_tile())
    for tone in BUTTON_TONES:
        save(f"btn_{tone}", button(tone, False))
        save(f"btn_{tone}_pressed", button(tone, True))
    save("board", board())
    save("board_header", board_header())
    save("well", well())
    save("blue_panel", blue_panel())
    save("sheet", sheet())
    save("title_plaque", title_plaque())
    save("section_plaque", section_plaque())
    save("info_strip", soft_pill(48, 44, "#59331f", 0.16))
    # HUD currency pill: a full pill (radius = half the height) so it never stretches into a
    # box, dark translucent with a soft inner shadow line along the top.
    save("hud_pill", svg(40, 36, rect(0, 0, 40, 36, 18, "#5a3a32", ' fill-opacity="0.32"')
                     + '<rect x="10" y="3" width="20" height="3" rx="1.5" fill="#3c1e0c" fill-opacity="0.18"/>'))
    save("counter", soft_pill(40, 38, "#594026", 0.2))
    save("hud_bg", hud_bg())
    save("avatar_frame", avatar_frame())
    save("lv_plaque", lv_plaque())
    save("nav_cell", nav_cell())
    for tone in GEAR_TONES:
        save(f"gear_bg_{tone}", gear_card_bg(tone))
    save("nav_selected", nav_selected())
    make_battle_cogs()
    save("bar_track_hp", bar_track(40, 28, 14, "#88776f", 3))
    save("bar_track_exp", bar_track(40, 14, 7, "#cab1a5", 2))
    save("bar_track_item", bar_track(40, 20, 6, "#837975", 2))
    for tone, (light, body_col) in BAR_FILLS.items():
        save(f"bar_fill_{tone}", bar_fill(light, body_col, 30, 22, 11, 0.38))
    save("bar_fill_exp", bar_fill("#fff7a8", "#f8e439", 30, 10, 5, 0.35))
    save("bar_fill_item", bar_fill("#5fd0ff", "#00a4e3", 30, 16, 4, 0.3))
    for tone in KAPAI:
        save(f"card_unit_{tone}", unit_card(tone))
    for tone in ITEM:
        save(f"card_item_{tone}", item_card(tone))
    save("shield_blue", shield("#70c2fc", "#345e87"))
    save("shield_orange", shield("#ffa64d", "#8a4a1c"))
    save("flower", flower())
    save("check", check())
    save("dot_red", dot_red())
    save("plus_small", plus_small())
    save("platform", platform())
    save("bush", bush())
    save("wall_scene", wall_scene())
    for prefix, icons in (("icon_", make_icons()), ("icon_w_", make_weapons())):
        for name, ic in icons.items():
            # Things cats hold or wear (weapons, eq_* equipment) follow the cat style
            # (user rule, 2026-10-18), and so do the bottom-nav tab icons, next to the hero cat head;
            # other UI icons keep the icon style.
            flat = prefix == "icon_w_" or name.startswith(("eq_", "tab_")) or name in FLAT_FEATURE_ICONS
            draw = ic.flat_svg if flat else ic.svg
            save(f"{prefix}{name}", draw(128))
            for size in ICON_SIZES[:-1]:
                save(f"{prefix}{name}_{size}", draw(size))
    for size in ICON_SIZES:  # the fish is drawn in the cat style, not the icon style
        save("icon_fish" + ("" if size == 128 else f"_{size}"), fish_flat(size))
    # Mèo tab = the hero cat's head in the flat cat style, squared up, one file per icon size.
    head = cat_svg("hero", head_only=True)
    for size in ICON_SIZES:
        square = head.replace('width="184" height="148" viewBox="36 0 184 148"',
                              f'width="{size}" height="{size}" viewBox="36 -18 184 184"')
        save("icon_tab_cat" + ("" if size == 128 else f"_{size}"), square)
    for kind in CATS:
        save(f"cat_{kind}", cat_svg(kind))
        save(f"cat_head_{kind}", cat_svg(kind, head_only=True))
    print("SVGs written to", OUT)


if __name__ == "__main__":
    main()
