"""Second magic proposal: substantial asymmetric silhouettes, flat cat materials."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / "tools" / "ui"))

from make_svgs import Icon, circle_d, diamond, poly

INK = "#583f21"
WOOD = "#bd8154"
BRASS = "#edbb5b"
CORAL = "#df786a"
TEAL = "#69bcb5"
PURPLE = "#ad8bc9"
CREAM = "#fff0c9"


def _shape(icon, path, colour):
    icon.shape(path, colour, colour, 64)


def make_weapons():
    """Return crescent staff, squat flask, ajar tome and solid four-point wand."""
    weapons = {}

    # A brass crescent, rather than a fork or orb, cradles one large teal diamond.
    # The broad bent stem gives the handmade staff a continuous readable contour.
    icon = Icon()
    _shape(icon,
           "M60 54 L75 59 L69 79 L66 112 Q66 120 58 119 "
           "Q50 118 52 110 L55 77 Z", WOOD)
    _shape(icon,
           "M83 14 Q62 8 46 24 Q36 34 41 49 Q45 65 60 67 "
           "Q75 70 88 57 L80 47 Q70 58 58 50 "
           "Q49 44 53 32 Q59 18 83 14 Z", BRASS)
    _shape(icon, diamond(73, 31, 16, 20), TEAL)
    _shape(icon, "M54 61 L75 62 L73 73 L53 72 Z", BRASS)
    weapons["gay_phep"] = icon

    # Squat teardrop flask: neck/cork lean away from the wide belly; the low,
    # asymmetric wave is liquid, not a shine layer or simulated transparency.
    icon = Icon()
    _shape(icon,
           "M44 45 L72 42 L77 59 Q105 70 106 88 "
           "Q109 111 83 116 Q57 122 34 111 Q18 103 23 84 "
           "Q26 71 42 59 Z", CREAM)
    icon.raw('<path d="M29 82 Q46 93 65 81 Q84 69 99 83 L100 91 '
             'Q101 107 80 111 Q55 116 36 107 Q27 101 29 82 Z" fill="#df786a"/>')
    icon.raw('<circle cx="44" cy="96" r="5.5" fill="#fff0c9"/>')
    _shape(icon, "M43 31 L71 26 L76 52 L44 57 Z", CREAM)
    _shape(icon, "M44 15 L67 11 L73 32 L47 37 Z", WOOD)
    _shape(icon, "M39 46 L76 40 L79 51 L41 58 Z", BRASS)
    weapons["thuoc"] = icon

    # An ajar, thick, slanted tome: visible page block, broad spine and two brass
    # corner blocks. One large crescent replaces the old central diamond/clasp.
    icon = Icon()
    _shape(icon, "M32 26 L113 38 L103 116 L26 103 Z", PURPLE)
    _shape(icon, "M33 26 L109 38 L100 108 L28 97 Z", CREAM)
    _shape(icon, "M22 13 L100 27 L90 100 L14 87 Z", PURPLE)
    _shape(icon, "M22 13 L36 16 L26 89 L14 87 Z", WOOD)
    _shape(icon, "M36 16 L51 18 L48 32 L33 29 Z", BRASS)
    _shape(icon, "M76 83 L92 86 L90 100 L74 97 Z", BRASS)
    icon.raw('<path d="M72 42 Q55 39 48 53 Q42 67 56 76 '
             'Q68 82 77 71 Q61 75 57 62 Q54 50 72 42 Z" fill="#edbb5b"/>')
    weapons["sach_phep"] = icon

    # The four-point head is deliberately solid. Soft concave sides and a thick
    # kinked wooden stem give the wand a different contour from the five-star v1.
    icon = Icon()
    _shape(icon,
           "M71 57 L84 64 L73 81 L58 86 L49 111 "
           "Q46 119 39 115 Q33 112 38 103 L49 78 "
           "Q51 74 56 73 L65 70 Z", WOOD)
    _shape(icon, "M40 94 L55 101 L49 114 Q45 120 39 116 Q33 113 36 107 Z", PURPLE)
    _shape(icon, "M65 61 L80 68 L73 80 L58 74 Z", BRASS)
    _shape(icon,
           "M79 9 Q83 28 91 31 L113 38 Q92 42 88 50 "
           "L79 69 Q74 48 66 45 L45 38 Q66 34 71 27 Z", CREAM)
    weapons["dua_phep"] = icon

    return weapons


if __name__ == "__main__":
    target = Path(__file__).resolve().parent / "weapons"
    target.mkdir(exist_ok=True)
    for key, icon in make_weapons().items():
        (target / f"icon_w_{key}.svg").write_text(icon.flat_svg(128), encoding="utf-8")
