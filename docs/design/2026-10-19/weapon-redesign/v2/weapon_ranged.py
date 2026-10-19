"""Second ranged proposal: handmade, chunky silhouettes; import has no writes."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / "tools" / "ui"))

from make_svgs import Icon, circle_d, ellipse_d, poly, rr_d

INK = "#583f21"
STEEL = "#d6e7e7"
DARK_STEEL = "#8daeb6"
BRASS = "#edbb5b"
WOOD = "#bd8154"
CORAL = "#df786a"
TEAL = "#69bcb5"
CREAM = "#fff0c9"


def _shape(icon, path, colour):
    icon.shape(path, colour, colour, 64)


def _line(icon, path, colour=INK, width=3.0):
    # Strings and seams need one stroke rather than the Icon.line double border.
    icon.raw(f'<path d="{path}" fill="none" stroke="{colour}" '
             f'stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>')


def make_weapons():
    """Return bow, crossbow, blunderbuss and cannon as normal Icon objects."""
    weapons = {}

    # Carved uneven recurves: the large clear string/limb gap reads at 48 px.
    # One arrow and one substantial cloth grip replace knots and extra hardware.
    icon = Icon()
    _line(icon, "M40 16 L38 112", width=3.5)
    _shape(icon,
           "M39 11 Q54 12 54 27 L49 39 Q77 50 80 65 "
           "Q81 84 57 101 L51 114 Q47 121 35 116 "
           "L40 103 Q62 81 62 66 Q61 53 36 41 "
           "L41 26 L33 19 Z", WOOD)
    _shape(icon, "M63 52 Q73 50 81 57 L81 77 Q71 83 63 76 Z", CORAL)
    _shape(icon, "M14 60 L29 64 L29 70 L13 75 L18 67 Z", CORAL)
    _line(icon, "M24 67 L103 67", WOOD, 4)
    _shape(icon, poly([(102, 56), (118, 67), (102, 78)]), STEEL)
    weapons["cung"] = icon

    # Shallow, broad steel T with a thick tapered stock. One string V sits behind
    # the lock; the bolt and teal butt are the two main readable secondary masses.
    icon = Icon()
    _shape(icon,
           "M55 42 L73 42 L76 93 Q80 107 72 115 "
           "L49 111 Q53 94 54 80 Z", WOOD)
    _line(icon, "M17 43 L64 72 L111 43", width=3.0)
    _shape(icon,
           "M11 33 Q30 28 47 34 L64 43 L81 34 Q98 28 117 33 "
           "L113 51 Q95 46 82 52 L64 61 L46 52 Q31 46 15 51 Z",
           DARK_STEEL)
    _line(icon, "M64 58 L64 25", WOOD, 6)
    _shape(icon, poly([(64, 10), (74, 29), (54, 29)]), STEEL)
    _shape(icon, rr_d(51, 61, 27, 13, 4), BRASS)
    _shape(icon, "M53 91 L75 92 L75 108 Q73 116 66 115 L49 111 Z", TEAL)
    weapons["no"] = icon

    # Toy blunderbuss: the fat trumpet mouth dominates a rounded curved stock.
    # A single brass rim, one hammer and the stock heel keep the construction clear.
    icon = Icon()
    _shape(icon,
           "M17 60 L43 59 L60 72 L54 88 L44 89 "
           "Q42 105 28 115 L11 107 Q26 91 23 80 L13 77 Z", WOOD)
    _line(icon, "M49 80 Q63 98 72 80", BRASS, 4.5)
    _shape(icon,
           "M36 54 L82 47 Q95 41 102 34 L112 67 "
           "Q99 68 88 74 L44 80 Z", STEEL)
    _shape(icon, "M99 32 L111 28 L119 70 L107 75 Z", BRASS)
    _shape(icon,
           "M108 38 Q113 45 114 61 Q109 59 107 51 Q105 42 108 38 Z", INK)
    _shape(icon, "M43 54 L40 42 L47 34 L56 39 L51 49 L54 54 Z", DARK_STEEL)
    _shape(icon, "M16 96 L34 105 L28 115 L11 107 Z", CORAL)
    weapons["sung"] = icon

    # A short pot-bellied steel barrel, broad brass mouth and oversized wood
    # wheels distinguish this from the old long, all-brass box carriage.
    icon = Icon()
    _shape(icon, "M23 77 L94 76 L108 100 L18 100 Z", WOOD)
    _shape(icon, circle_d(91, 96, 20), WOOD)
    _shape(icon, circle_d(91, 96, 6.5), BRASS)
    _shape(icon,
           "M34 27 Q17 30 21 53 Q21 74 39 77 "
           "Q64 81 102 69 L102 32 Q61 18 34 27 Z", STEEL)
    _shape(icon, "M49 72 L65 70 L66 84 L49 85 Z", DARK_STEEL)
    _shape(icon, ellipse_d(104, 50, 13, 25), BRASS)
    _shape(icon, ellipse_d(108, 50, 6.5, 15), INK)
    _shape(icon, circle_d(35, 94, 23), WOOD)
    _shape(icon, circle_d(35, 94, 8), BRASS)
    weapons["dai_bac"] = icon

    return weapons


if __name__ == "__main__":
    target = Path(__file__).resolve().parent / "weapons"
    target.mkdir(exist_ok=True)
    for key, icon in make_weapons().items():
        (target / f"icon_w_{key}.svg").write_text(icon.flat_svg(128), encoding="utf-8")
