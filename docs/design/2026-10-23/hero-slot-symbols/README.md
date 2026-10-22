# Hero equipment slot symbols

Brief: empty equipment slots use their own quiet monochrome category symbols, never a faded picture of an actual item. Use a diagonal sword, a plain rounded helmet, a simple shirt and two upright boot outlines. These symbols also identify the slot in the card corner. No item colours, rarity decoration, levels, upgrade arrows or material details belong in an empty slot.

`symbols.js` records the paths through the shared Canvas/SVG Pen. `export.mjs` writes only four slot families at32/48/64/96/256px into `game/ui/art`, separate from `icon_eq_*` and `icon_hero_w_*`. The sole ink is a muted mint-brown `#66766c`, with rounded caps/joins. Glyph strokes are6units on a96px canvas; these UI symbols do not replace the equipment main/secondary art profiles.

Export with `node docs/design/2026-10-23/hero-slot-symbols/export.mjs`; inspect native Godot on HeroCatPage at360/450px screen width.
