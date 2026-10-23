# Bright gold currency proposals

**Production update — 2026-10-23:** the bright front-facing `classic` coin
(leftmost proposal), with its small gear stamp, is now integrated throughout
the game. Canonical source: `game/ui/art_sources/currency_coin.svg`; regenerate
with `tools/ui/install_currency_art.py`. The notes below record the earlier demo stage.

User feedback: the previous muted ochre/cream coins did not read as bright gold.
Create fresh coin constructions with a large saturated yellow face, orange-gold
rim and a smaller gear stamp. Compare a front coin, an angled thick coin and a
low three-coin stack. Keep the accepted brilliant purple diamond unchanged.

Palette: yellow `#FFDA20`, light yellow `#FFE963`, orange edge `#F5AE06`,
emboss/seam `#CD8800`, main outline `#583F21`. Avoid a cream face and a large
brown gear. Main contour 5.8/96 = 1.45px at24, 1.93px at32. The angled coin's
inset rim uses secondary 3.1/96 = 0.78px at24, 1.03px at32. Stack seams use
secondary 3.5/96 = 0.88px at24, 1.17px at32. Stamp and material planes are
filled shapes, not additional stroke classes. Gear stamps remain subordinate
to currency recognition. No gradient, white sparkle, glow or drop shadow.

Canvas source and exported SVG share the same Pen paths. Review all3 at24/32
and rasterize in Godot. This folder contains proposals only; no production
asset, economy or player save is changed.

Round1 review: the saturated faces now read as yellow gold at24px. The tilted
coin had two dark contours merging into a heavy crescent. Round2 resolves the
thickness as one external body silhouette, with a quieter ochre face boundary.
No doubled main edge or extra dark ring is retained.

Final check: all3 exported SVGs rendered successfully in Godot at24/32px and
the six native PNGs were visually inspected. Canvas and Godot retain the same
construction. The comparison board loads all images without script errors or
horizontal overflow. Prefer the front-facing bright coin for the persistent
resource header; the stack reads better as a reward/amount icon.
