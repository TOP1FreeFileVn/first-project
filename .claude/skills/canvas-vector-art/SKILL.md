---
name: canvas-vector-art
description: Claude's own pipeline for drawing vector game art (weapons, gear, items, props, icons) for the cat defender — draw with code on an HTML canvas, screenshot and look, fix, then export the identical paths to SVG and verify in Godot. Use whenever Claude must draw or redraw an SVG item/icon by itself instead of hand-typing SVG coordinates or reusing make_svgs.py shapes.
---

# Canvas-first vector art (Claude pipeline)

Adopted 2026-10-21 after the sword pilot (`docs/design/2026-10-21/sword-canvas-pilot/compare.png`): the user chose this as Claude's standard way to author vector art. It exists because Claude draws badly **blind**. Typing `<path d="…">` without seeing the result produced the weak `draw_sword_sample.py` sword. The fix is a loop where every change is rendered and **looked at** before moving on.

The art rules still come from the other skills. This skill is only the *how*:
- Style: `.claude/skills/cat-sprite-art/SKILL.md` and `tools/skills/casual-weapon-design/` (read `references/cat-defender.md`, `references/accepted-spear.md`, `references/internal-strokes.md` for weapons/gear).
- Items are flat cat style: flat fills, one even `#583f21` contour, round joins/caps, no gradients/shine/shadow (memory: items-in-cat-style).

## Tools (all already on this machine)

| Purpose | Tool |
|---|---|
| Shared drawing core (canvas + SVG from one path list) | `.claude/skills/canvas-vector-art/scripts/pen.js` |
| Screenshot an HTML page for Claude to see | `scripts/snap.ps1` (headless Edge) |
| Render exported SVG with the game's renderer | `scripts/godot_render.ps1` (uses `tools/ui/render_svg_png.gd`) |
| Starter files | `template/item.js`, `template/preview.html`, `template/export.mjs` |
| Node | `C:\Program Files\nodejs\node.exe` (`node` on PATH) |

No npm packages, no Playwright. Do not install any.

## Steps

### 0. Brief before drawing
Read the style skills above. Look at (Read the PNG) the item being replaced and the accepted spear review. Write 3–5 lines in the reply or the work folder's README: visual thesis, the one defining contour, materials/colours, where it is held. Do not start drawing without the reference images in context.

### 1. Set up the work folder
```
docs/design/<YYYY-MM-DD>/<item>-canvas/
```
Copy `template/item.js`, `template/preview.html`, `template/export.mjs` into it. In `export.mjs` set `ITEM` to the item slug. The template paths assume the folder sits exactly at `docs/design/<date>/<name>/` (four levels under the repo root); keep that depth.

### 2. Draw in `item.js`
- **Local frame:** origin = grip centre (or the item's natural pivot), functional head toward −y, total length ≈ 200 units. All placement (icon tilt, paw socket, rotation) happens in `icon()` / `held()` with `P.translate/rotate/scale`, never by editing coordinates.
- **Path API:** `P.shape(cmds, {fill, stroke, width})` with absolute `['M',x,y]`, `['L',x,y]`, `['Q',cx,cy,x,y]`, `['C',…]`, `['Z']`. Helpers `Pen.circle(cx,cy,r)`, `Pen.rrect(x,y,w,h,r)`. Stroke width is in local units and scales with the pen.
- **Layer order per part:** (1) fill → (2) darker flat material plane clipped by shape, *no line on that shared boundary* → (3) secondary seams (wraps, rivets) in a material-tinted, thinner stroke (~0.45–0.5 × main) → (4) the main contour last. Draw back parts first (blade, grip, pommel, then guard on top).
- **Line weight:** main contour `w = 10` local units on both icon and held calls (≈ 8–9 px on the 256×240 hero canvas after `scale(0.82)`, matching the accepted spear). Don't use thinner than 0.45 × w for anything that must survive 64 px.
- **Chunky proportions:** the first attempt is always too thin. Start wide: sword blade ±18–24, grip ±11, pommel r 13, gem r ≥ 6.
- **Mirror symmetric parts** with a loop or `P.save(); P.transform(-1,0,0,1,0,0); …; P.restore()` instead of retyping coordinates.
- **Held pose:** right-paw socket (160,166) for sword/staff/axe; left-paw (94,166) for bow; rotate around the grip. Keep the palm patch (`PALM #f5a25d`) inside the paw's C so grip shows above and below. Stat-only gear (helmet, armor, gloves, boots, amulet) gets no `held()`; delete it.

### 3. Look — mandatory every round
```
powershell -File .claude/skills/canvas-vector-art/scripts/snap.ps1 -Page docs/design/<date>/<item>-canvas/preview.html -Out docs/design/<date>/<item>-canvas/round-<n>.png
```
Then **Read the PNG**. Never skip this and never judge from code. Check, in this order:
1. Silhouette reads as the item in the 64 px icon and on the 128×120 cat.
2. Cat's eyes and mouth are fully clear; nothing crosses the face outline.
3. Grip is visible above and below the paw; the item doesn't float.
4. Mass: blade/head not thin; no dark tangle where lines meet.
5. Interior detail survives 64 px; remove what turns to mush.
6. Nothing clipped at the canvas edge.

Write the failures you see as a short list, fix them in `item.js`, re-snap with the next round number. Expect 2–3 rounds; stop when the checklist passes, not after a fixed count. Keep the round PNGs; they are the review trail.

### 4. Export
```
node docs/design/<date>/<item>-canvas/export.mjs
```
Writes `svg/<item>-icon-{256,96,64}.svg`, and for held items `svg/<item>-weapon-layer.svg` + `svg/hero-<item>.svg` (unchanged hero layers + weapon + palm + paws).

### 5. Verify in Godot
```
powershell -File .claude/skills/canvas-vector-art/scripts/godot_render.ps1 -Dir docs/design/<date>/<item>-canvas
```
Read `godot/hero-<item>.png` and `godot/<item>-icon-64.png`. They must match the canvas round. If Godot differs (it shouldn't with plain paths), simplify the path rather than adding SVG features.

### 6. Compare and hand over
Build a small `compare.html` next to the files (old vs new at equal size, plus native 128×120 and 64 px), snap it to `compare.png`, Read it. Give the user the folder path and `compare.png`, list what changed in construction (not just colour/stroke), and ask for a score. **Don't overwrite production art** (`ui/skin/`, `ui/art/`, `tools/ui/make_svgs.py`) until the user approves; integration is a separate step.

## Pitfalls already hit
- First round of the sword: blade too slim, guard over the mouth, icon too small. All three were only visible in the screenshot.
- Edge's `--screenshot` returns before the file exists; `snap.ps1` waits for it. Without `--allow-file-access-from-files` the cat images won't load.
- Opening `preview.html` by double-click may not show the cat (file-URL image rules); use `snap.ps1` or point the user at the PNG.
- `render_svg_png.gd` renders at 2× then downsizes; pass forward-slash paths.
- PowerShell prints Node/Godot stderr as red NativeCommandError even on success; check the output files, not the colour.

## Reference pilot
`docs/design/2026-10-21/sword-canvas-pilot/`: `sword.js` is a complete worked example (leaf blade with two steel planes, wrapped grip, bow-tie guard with gem, pommel, held at the right paw).
