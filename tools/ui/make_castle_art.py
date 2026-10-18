"""Draw the cat fortress used by the lobby, castle page and battle wall.

Independent of the general skin generator: python tools/ui/make_castle_art.py
All artwork is original flat SVG; dimensions retain the existing gameplay/layout.
"""
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "game/ui/skin"
INK = "#583f21"
STONE = "#ead8b4"
SHADE = "#ceb78e"
LIGHT = "#f8ebcb"
BLUE = "#80b9cc"
BLUE_DARK = "#5f92a7"
GOLD = "#f2ce77"


def n(value):
    return f"{value:.2f}".rstrip("0").rstrip(".")


def svg(width, height, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
            f'viewBox="0 0 {width} {height}">{body}</svg>\n')


def path(d, fill, width=4, color=INK, extra=""):
    return (f'<path d="{d}" fill="{fill}" stroke="{color}" stroke-width="{n(width)}" '
            f'stroke-linecap="round" stroke-linejoin="round" {extra}/>')


def rect(x, y, w, h, r, fill, width=4, color=INK):
    return (f'<rect x="{n(x)}" y="{n(y)}" width="{n(w)}" height="{n(h)}" '
            f'rx="{n(r)}" fill="{fill}" stroke="{color}" stroke-width="{n(width)}"/>')


def ellipse(x, y, rx, ry, fill, opacity=1):
    return (f'<ellipse cx="{n(x)}" cy="{n(y)}" rx="{n(rx)}" ry="{n(ry)}" '
            f'fill="{fill}" opacity="{opacity}"/>')


def paw(x, y, scale=1, color=INK):
    out = ellipse(x, y + 3 * scale, 6 * scale, 4.7 * scale, color)
    for dx, dy in [(-6, -4), (0, -7), (6, -4)]:
        out += ellipse(x + dx * scale, y + dy * scale, 2.8 * scale, 3.2 * scale, color)
    return out


def banner(x, y, width=32, height=42):
    out = path(f"M{x} {y}h{width}v{height - 9}l{-width / 2} 9l{-width / 2} -9Z", BLUE, 3)
    out += path(f"M{x + 5} {y + 3}v{height - 15}", "none", 2, "#c1e0e5")
    return out + paw(x + width / 2, y + height * .48, width / 31, GOLD)


def arch(x, y, width, height, fill, line=4):
    r = width / 2
    return path(f"M{x} {y + height}V{y + r}a{r} {r} 0 0 1 {width} 0v{height - r}Z", fill, line)


def tower(x, y, width, height, with_banner=True):
    """Round-ended stone tower; a few large blocks survive at lobby scale."""
    out = ellipse(x + width / 2, y + height + 2, width * .57, 6, INK, .12)
    out += rect(x + 4, y + 21, width - 8, height - 21, 7, STONE)
    out += path(f"M{x + width - 15} {y + 25}v{height - 31}h9V{y + 25}Z", SHADE, 0)
    out += rect(x + 1, y + height - 11, width - 2, 14, 4, SHADE, 3)
    # Cat-ear end merlons and a square centre merlon share one soft silhouette.
    out += path(
        f"M{x} {y + 26}V{y + 2}q0 -5 5 -3l9 9v8h{width / 2 - 23}V{y + 3}"
        f"h18v13h{width / 2 - 23}v-8l9 -9q5 -2 5 3v24Z", LIGHT, 4)
    out += path(f"M{x + 6} {y + 30}h{width - 12}", "none", 3, SHADE)
    out += arch(x + width * .5 - 5, y + 36, 10, 18, BLUE_DARK, 3)
    for yy, left in [(y + 64, 8), (y + 83, width * .43)]:
        if yy < y + height - 15:
            out += path(f"M{x + left} {yy}h{width * .35}", "none", 2.5, SHADE)
    if with_banner:
        out += banner(x + width * .5 - 13, y + height - 52, 26, 35)
    return out


def castle():
    """A compact 300x230 fortress, shared between the menu surfaces."""
    out = ellipse(150, 211, 136, 14, INK, .13)
    # Flags and a tall central keep sit behind the curtain wall.
    out += path("M153 50V9", "none", 4)
    out += path("M155 11h37l-9 11 9 11h-37Z", BLUE, 3)
    out += paw(169, 21, .72, GOLD)
    out += rect(111, 50, 78, 120, 7, SHADE)
    out += path("M102 56l17 -31 13 17h36l13 -17 17 31Z", "#da996d", 4)
    out += path("M112 54h76", "none", 3, "#f1bc8c")
    out += arch(137, 72, 26, 33, BLUE_DARK, 4)
    out += path("M150 77v25M140 92h20", "none", 2.5, "#c1e0e5")
    out += rect(52, 134, 196, 67, 6, STONE)
    out += path("M56 151h188M59 177h37m108 0h37M82 154v20m136 -20v20", "none", 3, SHADE)
    # The gate has one quiet arch, brass hinges and three broad timber planks.
    out += arch(116, 145, 68, 60, "#bd8658", 5)
    out += path("M128 197v-36m15 38v-43m15 43v-43m14 42v-36", "none", 2.5, "#8e6849")
    out += path("M124 176h18m16 0h18", "none", 4, INK)
    out += ellipse(151, 185, 3.5, 3.5, GOLD)
    out += path("M108 132l8 -16h68l8 16Z", LIGHT, 4)
    out += paw(150, 126, .75, BLUE_DARK)
    out += tower(31, 79, 60, 123)
    out += tower(209, 79, 60, 123)
    out += path("M109 207h82l12 9H97Z", LIGHT, 3)
    return out


def battle_wall():
    """720x152, rendered at y624: wall top near700, foot no lower than762."""
    out = ellipse(360, 132, 351, 10, INK, .13)
    out += rect(-8, 76, 736, 52, 8, STONE, 4)
    out += rect(-8, 116, 736, 16, 4, SHADE, 3)
    # A straight, uncluttered parapet marks the battlefield boundary at y700.
    for x in range(94, 629, 47):
        out += path(f"M{x} 77V64h24v13", LIGHT, 3)
    out += path("M92 82h536", "none", 3, LIGHT)
    # Masonry is deliberately larger and quieter than the characters.
    out += path("M96 104h198m132 0h198", "none", 2.5, SHADE)
    for x in [126, 214, 486, 574]:
        out += path(f"M{x} 85v17m44 4v10", "none", 2.5, SHADE)
    out += arch(307, 62, 106, 70, "#be8e63", 4)
    out += path("M325 123V85m18 41V77m18 49V76m18 50V78m18 45V86", "none", 3, "#956f4d")
    out += path("M317 105h30m26 0h30", "none", 4)
    out += ellipse(361, 112, 4, 4, GOLD)
    out += path("M304 63l12 -19h88l12 19Z", LIGHT, 4)
    out += paw(360, 55, 1.0, BLUE_DARK)
    out += tower(18, 11, 76, 119)
    out += tower(626, 11, 76, 119)
    out += path("M302 134h116l12 7H290Z", "#e9cc99", 3)
    return svg(720, 152, out)


def menu_island():
    """560x400 stage, with the fortress behind the hero and enemy lineup."""
    out = ellipse(280, 370, 226, 14, INK, .14)
    out += path("M30 191L280 299 530 191v67L280 367 30 258Z", "#c99a6b", 6)
    out += path("M280 299v68l250 -109v-67Z", "#ad815d", 5)
    out += path("M36 221l244 107 244 -107M37 246l243 105 243 -105", "none", 3, "#9c7655")
    out += path("M30 191L280 83l250 108L280 299Z", "#9cbd7a", 6)
    out += path("M48 188L280 97l232 91L280 280Z", "#bfd49a", 0)
    # Broad sandy courtyard and a gate path leave ample room for the unit overlays.
    out += path("M122 188L280 118l158 70 -158 72Z", "#dfd5aa", 0)
    out += path("M247 192l33 -13 95 66 -34 16Z", "#e9dfbb", 0)
    for x, y in [(85, 194), (170, 255), (390, 255), (475, 194)]:
        out += path(f"M{x - 6} {y}l3 -10 5 7 5 -8 3 11", "none", 3, "#82a660")
    # Symmetric low shrubs frame the fort without covering the character positions.
    for x in [93, 467]:
        out += ellipse(x, 184, 30, 8, INK, .1)
        out += path(f"M{x - 24} 180q-14 -20 7 -27q0 -25 23 -18q21 1 18 22q23 9 5 25Z", "#8db479", 4)
    out += '<g transform="translate(145 2) scale(.9)">' + castle() + '</g>'
    for x, y in [(171, 280), (220, 300), (346, 310), (398, 282)]:
        out += ellipse(x, y, 11, 5, "#dfba87")
    return svg(560, 400, out)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    assets = {
        "battle_castle_wall": battle_wall(),
        "menu_castle": svg(300, 230, castle()),
        "menu_castle_island": menu_island(),
    }
    for name, content in assets.items():
        (OUT / f"{name}.svg").write_text(content, encoding="utf-8", newline="\n")
    print("Castle art: " + ", ".join(assets))


if __name__ == "__main__":
    main()
