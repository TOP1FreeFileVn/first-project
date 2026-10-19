"""Isolated approval draft: eight new melee silhouettes in the flat cat palette.

Import ``make_weapons`` to render as UI icons or to supply make_units._WEAPONS.
Running this file writes only this proposal's weapons directory.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[5]
if str(ROOT / "tools" / "ui") not in sys.path:
    sys.path.insert(0, str(ROOT / "tools" / "ui"))
from make_svgs import WeaponIcon, circle_d, poly

INK = "#583f21"
STEEL = "#d6e0e3"
DARK_STEEL = "#8b9fa8"
GOLD = "#e6b358"
WOOD = "#b77d51"
LEATHER = "#8d6044"
BLUE = "#5faacf"
PURPLE = "#a47aca"
RED = "#cf635b"


def solid(icon, path, color):
    icon.shape(path, color, color, 64)


def plane(icon, path, color):
    icon.raw(f'<path d="{path}" fill="{color}"/>')


def mark(icon, path, color=INK, width=3.5):
    icon.raw(f'<path d="{path}" fill="none" stroke="{color}" '
             f'stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>')


def make_weapons():
    weapons = {}

    # Short sword: broad spearpoint, small crescent guard, honest leather grip.
    ic = WeaponIcon()
    solid(ic, "M38 106 L52 84 L65 92 L51 114 Q45 119 39 113 Z", LEATHER)
    solid(ic, "M57 77 L87 32 Q97 18 107 16 Q110 29 102 42 L77 89 Z", STEEL)
    plane(ic, "M67 82 L104 20 Q111 30 102 42 L77 89 Z", DARK_STEEL)
    solid(ic, "M43 75 Q64 88 86 89 L84 99 Q62 98 41 84 Z", DARK_STEEL)
    mark(ic, "M43 103 L52 109")
    weapons["kiem"] = ic

    # Bearded axe: curved cutting edge and deep beard, with a blue socket.
    ic = WeaponIcon()
    solid(ic, "M35 108 L79 30 Q83 23 90 27 Q96 30 92 37 L49 115 Q45 120 39 116 Z", WOOD)
    solid(ic, "M77 29 L60 31 L58 49 L76 55 Z", DARK_STEEL)
    solid(ic, "M82 28 Q103 21 113 30 Q124 52 109 82 L91 85 L95 64 L77 58 Z", STEEL)
    plane(ic, "M113 30 Q124 52 109 82 L101 83 Q115 54 106 33 Z", DARK_STEEL)
    solid(ic, "M75 32 L89 40 L78 61 L64 53 Z", BLUE)
    mark(ic, "M40 101 L51 108")
    weapons["riu"] = ic

    # Dao: noticeably curved, tip-heavy single-edged saber with a purple grip.
    ic = WeaponIcon()
    solid(ic, "M36 108 L52 84 L66 92 L50 115 Q45 120 39 115 Z", PURPLE)
    solid(ic, "M55 81 Q61 52 76 30 Q91 10 116 14 Q111 40 96 61 Q84 78 72 90 Z", STEEL)
    plane(ic, "M116 14 Q111 40 96 61 Q84 78 72 90 L65 85 Q92 62 116 14 Z", DARK_STEEL)
    solid(ic, "M43 77 Q66 91 82 87 L84 97 Q61 102 39 87 Z", GOLD)
    mark(ic, "M42 103 L52 110")
    weapons["dao"] = ic

    # Katana: long swept blade and long red handle; one broad wrap crossing.
    ic = WeaponIcon()
    solid(ic, "M30 111 L51 81 L64 90 L43 119 Q39 122 34 119 Z", RED)
    solid(ic, "M52 78 Q70 53 80 29 Q91 12 112 10 Q98 26 93 43 Q84 64 67 88 Z", STEEL)
    plane(ic, "M112 10 Q98 26 93 43 Q84 64 67 88 L62 84 Q84 55 89 35 Q94 20 112 10 Z", DARK_STEEL)
    solid(ic, "M43 77 L54 72 L75 87 L73 97 Z", GOLD)
    mark(ic, "M39 104 L48 110 M46 94 L56 100", "#f1cf96", 4)
    weapons["katana"] = ic

    # Spear: leaf-point and simple blue collar, with a long uncluttered shaft.
    ic = WeaponIcon()
    solid(ic, "M24 111 L75 40 L85 47 L35 119 Q31 123 27 119 Z", WOOD)
    solid(ic, "M72 44 Q73 23 104 9 Q111 36 88 54 Z", STEEL)
    plane(ic, "M104 9 Q111 36 88 54 L80 48 Z", DARK_STEEL)
    solid(ic, "M69 43 L83 52 L77 62 L63 52 Z", BLUE)
    weapons["giao"] = ic

    # Greatsword: heavy slab, stepped shoulders and blue neck, no rune clutter.
    ic = WeaponIcon()
    solid(ic, "M36 107 L51 85 L66 95 L52 116 Q47 120 41 116 Z", LEATHER)
    solid(ic, "M53 71 L83 24 L108 12 L115 40 L85 85 L74 82 L69 91 L51 80 L58 71 Z", STEEL)
    plane(ic, "M108 12 L115 40 L85 85 L74 82 L69 91 L61 86 Z", DARK_STEEL)
    solid(ic, "M50 79 L66 88 L73 82 L82 89 L70 104 L57 97 L44 89 Z", BLUE)
    weapons["cu_kiem"] = ic

    # Mace: one elongated forged head with shallow squared flanges. A single
    # outline keeps its steel face open when embedded at the cats' 10 px line.
    ic = WeaponIcon()
    solid(ic, "M35 107 L74 49 L87 58 L50 115 Q46 121 40 117 Z", WOOD)
    solid(ic, "M82 16 L99 19 L101 29 L112 35 L109 51 L100 53 L94 67 L77 70 L73 60 L62 54 L65 37 L74 34 Z", STEEL)
    plane(ic, "M99 19 L101 29 L112 35 L109 51 L100 53 L94 67 L77 70 L85 52 Z", DARK_STEEL)
    mark(ic, "M78 33 L74 45 L80 51", INK, 3.5)
    plane(ic, circle_d(88, 45, 5.5), PURPLE)
    mark(ic, "M42 103 L52 109")
    weapons["chuy"] = ic

    # Hammer: stout striking block to the right, clear hooked beak to the left.
    ic = WeaponIcon()
    solid(ic, "M35 108 L76 47 L89 56 L50 116 Q46 121 40 117 Z", RED)
    solid(ic, "M61 27 L80 29 L90 42 L74 58 L58 49 L49 63 L43 59 L47 42 Z", DARK_STEEL)
    solid(ic, "M82 24 L111 40 L101 63 L73 48 Z", STEEL)
    solid(ic, "M83 23 L92 28 L80 53 L71 48 Z", GOLD)
    solid(ic, "M106 36 L116 42 L104 67 L95 62 Z", GOLD)
    mark(ic, "M41 102 L52 109", GOLD, 5)
    weapons["bua"] = ic
    return weapons


if __name__ == "__main__":
    output = Path(__file__).resolve().parent / "weapons"
    output.mkdir(exist_ok=True)
    for key, icon in make_weapons().items():
        (output / f"weapon_{key}.svg").write_text(icon.flat_svg(128), encoding="utf-8")
