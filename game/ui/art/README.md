# Production art overrides

These PNGs are the production equipment revisions selected on 2026-10-20.
`Ui.tex()` prefers PNGs, then SVGs in this directory, with the generated SVG skin
as its fallback. `SpriteLib` uses the PNG equipment overrides. Rebuilding the
legacy skin does not replace these production files.

- Soldier art: final weapon rollout, with the later accepted spear sample.
- Hero art: corrected `hero-equipment-v4` poses, plus the final katana pose on
  the same original hero, and the approved clean Canvas axe from 2026-10-22.
  Only the held weapon changes the hero's appearance.
- Helmet, armor and boots remain standalone icons and stat
  equipment. They do not add costume layers to the hero.
- Gloves and amulets were removed from active equipment on 2026-10-22. Their
  images remain here as historical assets; old item records are archived in saves.
- Soldier and hero weapon icons are separate when their reviewed art differs.

`equipment-sources.json` records each installed PNG, its source revision, and
SHA-256 hashes. Reinstall with:

```text
python -B tools/ui/install_equipment_art.py
```

Run `res://tests/EquipmentArtTest.tscn` to check production routing, native icon
sizes, all hero weapon looks, and the stat-only equipment contract. Its report
and native runtime pictures are in
`docs/ui_review/2026-10-22/hero-four-slots/art-routing/`. The earlier six-slot
report remains in `docs/design/2026-10-20/equipment-production-check/`.

The 2026-10-21 inventory revision fits the original ten hero equipment icon families
inside an 8% transparent inset at 32/48/64/96/256 px. Their functional main axes
point up-right at 45 degrees; helmet and armor remain upright. On 2026-10-22,
boots also returned to their accepted upright source pose, with a horizontal
sole and zero rotation. This does not rotate character-held art. Reinstall
only these icons with `--icons-only`, or just boots with `--gear-only boots`.
Source anchors, transforms and measurements are recorded in the manifest; see
`docs/design/2026-10-21/equipment-icon-fit/README.md` for the composition rules
and before/after evidence.

The approved 2026-10-22 axe replaces `icon_hero_w_riu{,_32,_48,_64,_96}.png`
and `hero_cat_heavy.png`. Its smooth wooden grip and two unlined steel fills
are copied from the reviewed native Godot renders in
`docs/design/2026-10-22/hero-weapons-canvas/`. Icons keep their authored up-right
orientation; the held axe keeps its separate right-paw carry. Reinstall only
these six files with `--approved-weapon riu`. Full and icon-only installs also
retain this revision. The 768x720 hero is rendered from the same accepted SVG
paths at production resolution, without upscaling the 256x240 raster.

To regenerate the axe sources before reinstalling:

```text
node docs/design/2026-10-22/hero-weapons-canvas/export.mjs
powershell -File docs/design/2026-10-22/hero-weapons-canvas/render.ps1 -Family axe
python -B tools/ui/install_equipment_art.py --approved-weapon riu
```

The existing bow icon correction remains up-left (-135 screen degrees), with
its character-held pose unchanged. Its narrow reinstall is `--weapon-only cung`.

On 2026-10-23 the user requested applying the latest Canvas equipment set.
Silver helmet/armor/paired boots and new bow/staff/katana now use their reviewed
native 32/48/64/96/256 renders. Bow/staff/katana held heroes use the same SVG
paths rendered natively at 768x720. Sword and the approved clean axe retain their
pixels. The original October 20 selections above remain historical context;
the per-asset manifest identifies the current source. Install this set alone with:

```text
python -B tools/ui/install_equipment_art.py --latest-hero-set
```

Full and icon-only installs also retain these newer sources. The narrow
`--gear-only boots` and `--weapon-only cung` flags now select the latest Canvas
family. Source mapping, render command, actual copied icon/held review images
and hash verification are in `docs/design/2026-10-23/hero-equipment-integration/`.

Hero slot category symbols are independent `icon_slot_{weapon,helmet,armor,boots}`
SVG families, generated from `docs/design/2026-10-23/hero-slot-symbols/`.
Empty slots use these monochrome glyphs rather than fading a real item PNG.
The same symbols identify slot families in card corners; item art remains separate.

The `icon_chest*.svg` symbols use the same layered chest paths as the live shop
and opening animation. Rebuild them and `art_sources/ChestPaths.gd` with
`node tools/ui/build_chest_paths.mjs`. The source and small-size design review
are versioned under `docs/design/2026-10-22/chest-polish/` for the unchanged
wood/silver construction and `docs/design/2026-10-22/chest-premium/` for the
gold-only cap and reinforcement. Generic wood symbols always use the basic
geometry, independently of the gold tier.
