"""Isolated ranged-weapon art proposal; importing does not write any game assets."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / "tools" / "ui"))

from make_svgs import Icon, circle_d, ellipse_d, poly, rr_d

INK = "#583f21"
STEEL = "#d6e0e3"
DARK_STEEL = "#8b9fa8"
GOLD = "#e6b358"
WOOD = "#b77d51"
RED = "#cd6254"
LINEN = "#f0dfb4"
BLUE = "#68a9c5"
PURPLE = "#9b78ba"


def shape(ic, path, colour):
    ic.shape(path, colour, colour, 64)


def detail(ic, path, colour=INK, width=3.5):
    ic.raw(f'<path d="{path}" fill="none" stroke="{colour}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>')


def make_weapons():
    weapons = {}

    # A deep recurve, linen string pulled back to one nocked arrow, large leather grip.
    ic = Icon()
    ic.line("M42 14 L32 64 L42 114", 3.2, LINEN)
    shape(ic, "M44 8 Q49 28 71 39 Q91 49 91 64 Q91 79 71 89 Q49 100 44 120 L32 114 Q44 93 61 82 Q75 74 75 64 Q75 54 61 46 Q44 35 32 14 Z", WOOD)
    shape(ic, rr_d(73, 50, 19, 28, 5), RED)
    detail(ic, "M77 57 L88 62 M77 66 L88 71", "#9c4d3f", 3.2)
    shape(ic, "M14 57 L30 61 L30 67 L14 72 L19 64 Z", RED)
    ic.line("M27 64 L106 64", 4, WOOD)
    shape(ic, poly([(103, 54), (120, 64), (103, 74)]), STEEL)
    weapons["cung"] = ic

    # Compact T-shaped iron prod, stout wooden stock, one brass lock and blue grip.
    ic = Icon()
    shape(ic, "M53 41 Q64 34 75 41 L73 105 L79 117 L49 117 L55 104 Z", WOOD)
    ic.line("M17 48 L64 77 L111 48", 3.2, LINEN)
    shape(ic, "M10 40 Q30 23 50 30 L64 38 L78 30 Q98 23 118 40 L112 55 Q94 42 79 47 L64 56 L49 47 Q34 42 16 55 Z", DARK_STEEL)
    shape(ic, rr_d(57, 19, 14, 50, 4), WOOD)
    shape(ic, poly([(64, 7), (76, 26), (52, 26)]), STEEL)
    shape(ic, rr_d(50, 59, 28, 13, 4), GOLD)
    shape(ic, rr_d(53, 90, 22, 24, 5), BLUE)
    detail(ic, "M61 78 L67 78", "#835d40", 4)
    weapons["no"] = ic

    # Short flintlock blunderbuss: large flared muzzle and a broad curved pistol stock.
    ic = Icon()
    shape(ic, "M21 52 L47 49 Q62 58 74 66 L66 82 L53 81 Q51 99 38 115 L15 107 Q31 88 28 75 L13 67 Z", WOOD)
    ic.line("M51 76 Q65 92 75 77", 4, GOLD)
    shape(ic, "M37 42 L77 37 L105 21 L119 56 L88 62 L46 67 Z", DARK_STEEL)
    shape(ic, "M92 24 L105 17 L121 57 L107 63 Z", GOLD)
    shape(ic, "M104 28 Q116 39 115 52 Q108 48 104 39 Z", INK)
    shape(ic, "M49 41 L60 39 L67 63 L55 66 Z", GOLD)
    shape(ic, "M36 44 L33 33 L41 25 L50 32 L44 43 Z", STEEL)
    shape(ic, "M23 90 L43 97 L37 112 L17 106 Z", PURPLE)
    weapons["sung"] = ic

    # Wide bronze barrel, a plain wood carriage and two large wheels. No loose props.
    ic = Icon()
    shape(ic, "M24 78 L90 77 L108 103 L17 103 Z", WOOD)
    shape(ic, circle_d(87, 98, 19), WOOD)
    shape(ic, circle_d(87, 98, 7), GOLD)
    shape(ic, "M22 43 Q20 31 33 28 L98 18 L112 53 L40 79 Q27 81 23 68 Z", GOLD)
    shape(ic, "M28 60 L105 35 L110 48 L40 74 Q29 77 28 60 Z", "#c59146")
    shape(ic, "M88 18 L100 14 L116 55 L103 61 Z", GOLD)
    shape(ic, ellipse_d(108, 36, 10, 21), INK)
    shape(ic, "M52 27 L64 25 L77 67 L65 72 Z", GOLD)
    shape(ic, circle_d(36, 99, 23), WOOD)
    detail(ic, "M36 80 L36 118 M18 99 L54 99", "#80583d", 5)
    shape(ic, circle_d(36, 99, 7), GOLD)
    weapons["dai_bac"] = ic

    return weapons


if __name__ == "__main__":
    target = Path(__file__).resolve().parent / "weapons"
    target.mkdir(exist_ok=True)
    for key, icon in make_weapons().items():
        (target / f"icon_w_{key}.svg").write_text(icon.flat_svg(128), encoding="utf-8")
