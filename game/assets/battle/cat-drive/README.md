# Cat-operated round drive

Approved source: `docs/design/2026-10-23/cat-round-drive/`.

`rear_disc.svg` rotates continuously. `CatDrive.gd` draws the original broad triangle at the exact `GearBoard.pin_angle()`, without a separate circle at its end. Neither changes physical pin reach, pin radius, tooth phase or production.

`cat_poses.png` contains 96 phase-indexed foreground poses at 128px, with transparent 2px gutters. At a 100px board cell, the largest hand displacement between adjacent poses is under 0.63px. It has no timer: its pose follows the same pin angle, so it also slows down under load. Head/torso, crank, soles, opaque arm attachments, handle and paws are composited from the same Canvas paths as the approved SVG. Arms and paws cover the front wheel. No rear-view cat artwork is used.

Rebuild in order:

1. `node tools/ui/build_cat_drive.mjs`
2. Godot `--headless --path . --script res://tools/ui/render_cat_drive.gd`
3. `python tools/ui/pack_cat_drive.py`
4. Godot import and native UI review.

The renderer stays in Core's own CanvasItem, preserving its position, damage tint and existing sibling/drag ordering. Miniature menu grids keep their compact legacy orb renderer.
