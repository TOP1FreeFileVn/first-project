"""Casual weapon skill application: chunky adventure tools, approval draft v2.

Thesis: large useful heads, soft forged contours, a grip a cat could actually hold.
Shared construction is a honey-brass socket and a short coloured cloth grip.
The contours do the identifying: spade, deep beard, cleaver belly, swept crescent,
leaf, stepped slab, three forged flanges, and a striking block with one hooked beak.
This changes mass and construction from v1; it does not merely add decoration.

All material regions are opaque flat fills, with no light, shadow or gloss.
Import-safe; this module never writes production assets.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[5]
if str(ROOT / "tools" / "ui") not in sys.path:
    sys.path.insert(0, str(ROOT / "tools" / "ui"))
from make_svgs import WeaponIcon, ellipse_d

INK = "#583f21"
STEEL = "#d6e7e7"
EDGE = "#8daeb6"
BRASS = "#edbb5b"
WOOD = "#bd8154"
CORAL = "#df786a"
TEAL = "#69bcb5"
PURPLE = "#ad8bc9"
ANGLE = 30


def solid(icon, path, color, angle=ANGLE):
    icon.shape(path, color, color, 64, rot=angle)


def material(icon, path, color, angle=ANGLE):
    """A broad unoutlined material insert, not a simulated lighting plane."""
    icon.raw(f'<path d="{path}" fill="{color}"/>', rot=angle)


def mark(icon, path, color=INK, width=3.5, angle=ANGLE):
    icon.raw(f'<path d="{path}" fill="none" stroke="{color}" '
             f'stroke-width="{width}" stroke-linecap="round" '
             f'stroke-linejoin="round"/>', rot=angle)


def make_weapons():
    weapons = {}

    # 1. A broad, almost spade-shaped short sword. The guard has two short
    # upward wings instead of v1's long thin diagonal crossbar.
    ic = WeaponIcon()
    solid(ic, "M58 83 H71 V110 Q71 117 64 117 Q57 117 57 110 Z", CORAL)
    solid(ic, "M49 78 L44 49 Q43 38 53 24 L64 11 L75 24 Q85 38 84 49 L79 78 Z", STEEL)
    # A deliberately broad metal cutting strip follows the edge, not a shine.
    material(ic, "M75 24 Q85 38 84 49 L79 78 L70 78 L75 49 Q77 37 70 27 L64 18 L64 11 Z", EDGE)
    solid(ic, "M41 75 Q48 79 53 73 L58 80 H71 L77 73 Q82 79 89 75 L86 87 Q79 91 70 87 H58 Q49 91 44 86 Z", BRASS)
    mark(ic, "M59 103 L69 100")
    weapons["kiem"] = ic

    # 2. The great crescent reaches well below the socket. That open bite
    # makes a deep beard, rather than a rectangular axe painted silver.
    ic = WeaponIcon()
    solid(ic, "M58 29 H70 L72 111 Q72 117 65 117 Q58 117 57 111 Z", WOOD)
    solid(ic, "M59 26 L77 24 Q86 16 98 14 Q110 43 88 76 L71 83 L77 56 L58 49 Z", STEEL)
    material(ic, "M98 14 Q110 43 88 76 L71 83 L74 70 Q94 57 93 32 L91 18 Z", EDGE)
    solid(ic, "M54 29 L71 28 L73 51 L55 53 Z", BRASS)
    solid(ic, "M56 91 H73 V110 Q73 117 65 117 Q57 117 56 110 Z", TEAL)
    mark(ic, "M59 102 L70 98")
    weapons["riu"] = ic

    # 3. A front-heavy dao: blunt clipped top, concave spine, and a generous
    # cleaver belly. Its unequal sides cannot be confused with the short sword.
    ic = WeaponIcon()
    solid(ic, "M57 83 H70 V111 Q70 117 64 117 Q57 117 57 111 Z", WOOD)
    solid(ic, "M51 79 Q61 55 58 35 Q58 22 68 14 H91 Q106 56 78 86 L66 88 Z", STEEL)
    material(ic, "M91 14 Q106 56 78 86 L70 84 Q91 60 88 40 L82 14 Z", EDGE)
    solid(ic, "M49 81 Q63 90 79 82 L80 91 Q64 101 47 90 Z", BRASS)
    solid(ic, "M56 100 L71 100 V112 Q71 118 64 118 Q56 118 56 112 Z", PURPLE)
    weapons["dao"] = ic

    # 4. Thin, long, and strongly swept, with the unmistakable oval tsuba.
    # The long cloth handle balances the moon-like blade rather than a dao belly.
    ic = WeaponIcon()
    solid(ic, "M58 82 H70 V111 Q70 117 64 117 Q58 117 58 111 Z", CORAL)
    solid(ic, "M58 83 Q72 62 75 42 Q77 24 72 10 L82 13 Q96 50 72 86 Z", STEEL)
    solid(ic, ellipse_d(65, 86, 17, 7), BRASS)
    mark(ic, "M60 98 L68 94 M60 109 L68 105", INK, 3.5)
    weapons["katana"] = ic

    # 5. A large leaf takes almost half the spear's length. The thick shaft
    # and short brass neck feel like a cat's adventure gear, not a tiny pin.
    ic = WeaponIcon()
    solid(ic, "M58 54 H71 L70 112 Q70 118 64 118 Q58 118 58 112 Z", WOOD)
    solid(ic, "M64 10 Q86 23 85 39 Q84 54 64 67 Q44 54 43 39 Q42 23 64 10 Z", STEEL)
    mark(ic, "M64 29 V51", INK, 3.2)
    solid(ic, "M53 61 Q64 66 75 61 L73 75 H55 Z", BRASS)
    solid(ic, "M56 76 H72 V87 H56 Z", TEAL)
    weapons["giao"] = ic

    # 6. The giant's slab is deliberately asymmetric: a chopped top, one
    # projecting shoulder, and a stepped cutting edge over a comically short grip.
    ic = WeaponIcon()
    solid(ic, "M58 89 H71 V111 Q71 118 64 118 Q58 118 58 111 Z", CORAL)
    solid(ic, "M42 77 V52 H35 V24 L76 10 L94 28 V63 H84 V84 H65 L57 77 Z", STEEL)
    material(ic, "M76 10 L94 28 V63 H84 V84 H74 V56 H82 V30 Z", EDGE)
    solid(ic, "M47 84 H79 L83 94 H43 Z", BRASS)
    mark(ic, "M60 107 L69 104")
    weapons["cu_kiem"] = ic

    # 7. A forged flanged head, not a ball of round petals. Three large
    # projecting plates meet at deep angular valleys; the inner face stays open.
    ic = WeaponIcon()
    solid(ic, "M58 48 H71 V111 Q71 118 64 118 Q57 118 57 111 Z", WOOD)
    solid(ic, "M46 17 L57 32 L65 12 L74 32 L88 20 L101 40 L85 65 L65 78 L46 64 L32 40 Z", STEEL)
    # A single wide central iron web explains how the flanges are attached.
    material(ic, "M65 12 L74 32 L73 59 L65 73 L56 58 L57 32 Z", EDGE)
    solid(ic, "M54 75 H75 V88 H54 Z", BRASS)
    solid(ic, "M56 92 H73 V111 Q73 118 64 118 Q56 118 56 111 Z", PURPLE)
    weapons["chuy"] = ic

    # 8. A real mallet-sized striking block, one hooked beak on the reverse,
    # and a short coral grip. The brass rim is construction, not a highlight.
    ic = WeaponIcon()
    solid(ic, "M58 42 H71 V111 Q71 118 64 118 Q57 118 57 111 Z", WOOD)
    solid(ic, "M55 23 H35 L25 36 V56 L37 44 H55 Z", EDGE)
    solid(ic, "M50 15 H91 Q95 15 95 20 V54 Q95 59 91 59 H50 Z", STEEL)
    solid(ic, "M86 15 H97 V59 H86 Z", BRASS)
    solid(ic, "M56 87 H73 V111 Q73 118 64 118 Q56 118 56 111 Z", CORAL)
    mark(ic, "M60 103 L70 99")
    weapons["bua"] = ic
    return weapons
