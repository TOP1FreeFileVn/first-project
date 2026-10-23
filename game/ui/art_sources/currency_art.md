# Approved currency and combat-power art

The canonical SVGs `currency_coin.svg`, `currency_gem.svg` and
`power_crossed.svg` are the designs approved on 2026-10-23: bright front-facing
gold with a small gear stamp, wide brilliant purple diamond, and crossed swords.

Run `python -B tools/ui/install_currency_art.py` to regenerate the production
base, 32, 48, 64 and 96 pixel variants. `--check` verifies all 25 SVGs and their
manifest without writing. The 128 pixel base keeps the same 96 unit viewBox and
geometry. This changes only the viewport, without redrawing or adding strokes.

The `coins` and `gems` names deliberately alias the accepted single shapes.
No new coin pile or gem stack has been approved. Production code currently
requests the singular names; plural aliases keep that vocabulary consistent.

`Ui.tex` loads accepted assets from `game/ui/art` before the generated skin.
Legacy `make_svgs.py` output therefore cannot overwrite these production
selections. Runtime loading and regeneration do not depend on `docs/design`.

After the normal Godot editor import, run
`godot --headless --path . res://tools/ui/verify_currency_art.tscn` to
check all 30 loader requests (including 24 pixel requests using the 32 pixel
source) and produce native 24/32/48 pixel review PNGs in
`output/currency-art-qa`. Plural requests are included in the coverage. This
runs as a scene so the game's normal autoload dependencies are available.
