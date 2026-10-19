"""Four isolated magic-weapon proposals, using the game's flat Icon renderer.

Importing this module has no output side effects. Run it directly to regenerate
only the four SVGs next to this proposal; production assets are never written.
"""

from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path


_REPO = Path(__file__).resolve().parents[5]
_spec = spec_from_file_location("_magic_proposal_icon_api", _REPO / "tools/ui/make_svgs.py")
_art = module_from_spec(_spec)
_spec.loader.exec_module(_art)

INK = "#583f21"
WOOD = "#b77d51"
GOLD = "#e6b358"
PURPLE = "#9c7bc4"
PLUM = "#82647f"
TEAL = "#78c7cb"
PINK = "#e899aa"
CREAM = "#fff0c9"


def _shape(icon, path, color, rotation=0):
    """Use equal tones so Icon.flat_svg preserves the chosen material color."""
    icon.shape(path, color, color, 64, rot=rotation)


def make_weapons():
    """Return the four magic proposals as normal, reusable Icon instances."""
    weapons = {}

    # A broad wooden fork, reminiscent of two cat ears, cradles a single orb.
    # The staff and its head share one material instead of small metallic wraps.
    icon = _art.Icon()
    rotation = 21
    _shape(icon, "M58 47 H73 L64 112 Q64 120 56 120 Q49 120 50 112 Z", WOOD, rotation)
    _shape(icon,
           "M43 13 L57 27 H71 L85 13 Q92 34 82 50 "
           "Q75 60 64 60 Q53 60 46 50 Q36 34 43 13 Z",
           WOOD, rotation)
    _shape(icon, _art.circle_d(64, 31, 20), TEAL, rotation)
    icon.raw('<path d="M64 12 L78 21 L64 33 L50 21 Z" fill="#b1e4df"/>', rotation)
    weapons["gay_phep"] = icon

    # Squat pear-shaped flask, a thick cork and one unmistakable brass collar.
    # The large brew shape and single bubble remain legible on a held sprite.
    icon = _art.Icon()
    _shape(icon,
           "M49 43 H79 L79 52 C83 64 102 66 105 86 "
           "C109 108 88 119 64 119 C40 119 19 108 23 86 "
           "C26 66 45 64 49 52 Z",
           CREAM)
    icon.raw('<path d="M29 81 Q44 75 64 81 Q85 88 99 81 L100 88 '
             'Q103 112 64 113 Q25 112 28 88 Z" fill="#e899aa"/>')
    icon.raw('<circle cx="46" cy="96" r="6.5" fill="#fff0c9"/>')
    _shape(icon, _art.rr_d(49, 29, 30, 25, 8), CREAM)
    _shape(icon, _art.rr_d(50, 13, 28, 22, 6), WOOD)
    _shape(icon, _art.rr_d(44, 44, 40, 10, 5), GOLD)
    weapons["thuoc"] = icon

    # A thick, rounded tome with a visible cream page block. The single diamond
    # and chunky side clasp replace the original small corners/star/rune ring.
    icon = _art.Icon()
    _shape(icon, _art.rr_d(28, 24, 84, 91, 9), CREAM)
    _shape(icon, _art.rr_d(17, 14, 85, 93, 10), PURPLE)
    _shape(icon, "M27 14 H37 V107 H27 Q17 107 17 97 V24 Q17 14 27 14 Z", "#8063a6")
    _shape(icon, _art.diamond(66, 60, 17, 23), GOLD)
    _shape(icon, _art.rr_d(93, 55, 23, 20, 6), GOLD)
    weapons["sach_phep"] = icon

    # A crooked wooden handle and substantial plum grip give the wand a new
    # profile. A clean five-point star carries a red gem; no sparkle clutter.
    icon = _art.Icon()
    _shape(icon,
           "M66 48 L79 55 L71 75 Q70 78 65 80 L57 85 "
           "L47 111 Q45 117 40 115 Q34 113 37 107 L46 81 "
           "Q47 76 52 73 L61 67 Z",
           WOOD)
    _shape(icon, "M42 90 L55 95 L47 113 Q44 120 38 116 Q32 113 35 106 Z", PLUM)
    _shape(icon, "M46 82 L51 74 L66 82 L61 91 Z", GOLD)
    _shape(icon, _art.poly(_art.star_pts(79, 35, 29, 14, 5)), CREAM)
    _shape(icon, _art.diamond(79, 35, 8, 10), "#ce776d")
    weapons["dua_phep"] = icon

    return weapons


def main():
    output = Path(__file__).resolve().parent / "weapons"
    output.mkdir(parents=True, exist_ok=True)
    for weapon_id, icon in make_weapons().items():
        (output / f"icon_w_{weapon_id}.svg").write_text(icon.flat_svg(128), encoding="utf-8")


if __name__ == "__main__":
    main()
