# Accepted equipment art

These PNGs are the production equipment revisions selected on 2026-10-20.
`Ui.tex()` and `SpriteLib` prefer this directory, with the generated SVG skin as
the fallback for other art. Rebuilding the SVG skin does not replace these PNGs.

- Soldier art: final weapon rollout, with the later accepted spear sample.
- Hero art: corrected `hero-equipment-v4` poses, plus the final katana pose on
  the same original hero. Only the held weapon changes the hero's appearance.
- Helmet, armor, gloves, boots and amulet remain standalone icons and stat
  equipment. They do not add costume layers to the hero.
- Soldier and hero weapon icons are separate when their reviewed art differs.

`equipment-sources.json` records each installed PNG, its source revision, and
SHA-256 hashes. Reinstall with:

```text
python -B tools/ui/install_equipment_art.py
```

Run `res://tests/EquipmentArtTest.tscn` to check production routing, native icon
sizes, all hero weapon looks, and the stat-only equipment contract. Its report
and native runtime pictures are in
`docs/design/2026-10-20/equipment-production-check/`.

The 2026-10-21 inventory revision fits all ten hero equipment icon families
inside an 8% transparent inset at 32/48/64/96/256 px. Their functional main axes
point up-right at 45 degrees; helmet and armor remain upright. This does not
rotate character-held art. Reinstall only these icons with `--icons-only`.
Source anchors, transforms and measurements are recorded in the manifest; see
`docs/design/2026-10-21/equipment-icon-fit/README.md` for the composition rules
and before/after evidence.
