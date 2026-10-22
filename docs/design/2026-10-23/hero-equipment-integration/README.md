# Latest hero equipment integration — 23 October 2026

The user asked to apply the new equipment after the Hero page still displayed the older art. The runtime already preferred `game/ui/art/*.png`; the installer still selected the October 20 sources for the three stat-only items and the bow, staff and katana.

The latest silver helmet, armor and **paired boots** now replace all five native icon sizes. The new bow, staff and katana replace their five inventory icons and their held hero composites. Sword and the approved clean axe keep their existing pixels; soldier art and item stats remain unchanged. Helmet, armor and boots stay stat-only icons.

| Source | Production family |
| --- | --- |
| `2026-10-22/hero-gear-canvas/godot/helmet-icon-{size}.png` | `icon_eq_helmet` |
| `2026-10-22/armor-canvas/godot/armor-icon-{size}.png` | `icon_eq_armor` |
| `2026-10-22/hero-gear-canvas/godot/boots-icon-{size}.png` | `icon_eq_boots` |
| `2026-10-22/hero-weapons-canvas/godot/bow-icon-{size}.png` | `icon_hero_w_cung` |
| `2026-10-22/hero-weapons-canvas/godot/staff-icon-{size}.png` | `icon_hero_w_gay_phep` |
| `2026-10-22/hero-weapons-canvas/godot/katana-icon-{size}.png` | `icon_hero_w_katana` |
| This folder's `godot/hero-{bow,staff,katana}-768.png` | `hero_cat_{ranged,magic,katana}.png` |

Sizes are 32, 48, 64, 96 and 256. The 256 variant has no numeric suffix in production. Held composites use the identical reviewed SVG paths, viewBox, cat, palm and paws, rendered at **768×720**; they are not enlarged PNGs.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-23/hero-equipment-integration/render_held.ps1
python -B tools/ui/install_equipment_art.py --latest-hero-set
python -B docs/design/2026-10-23/hero-equipment-integration/verify_integration.py
```

The full installer and its existing icon/gear/weapon flags also select these latest sources, preventing a later reinstall from restoring old art. `--latest-hero-set` updates only these 33 PNGs and their manifest records. `equipment-sources.json` records source paths, hashes and rendering operations. The original hash snapshot is kept in `before-sha256.json`; verification proves all 136 other production PNGs, including sword and axe, are unchanged.

`installed-icons.png` shows the actual copied icons at the four small native sizes. `installed-held.png` shows the copied production hero composites downsampled for review. Runtime import/cache refresh and empty-slot presentation are checked separately in the root task.

Native runtime review is now complete: `runtime/review.json` records69/69 checks and14 screenshots at450x800/360x640, using the production Home/Hero page. Fresh, fully empty and full-bag states use the expected item PNGs and separate `icon_slot_*` category symbols. Actual taps open/close details and equip the bow; save hashes remain unchanged. `runtime/fresh-three-worn_450x800.png` matches the user's reported slot state; `runtime/all-four-empty_450x800.png` shows all four dedicated placeholders. The existing `EquipmentArtTest` also passes101 checks for production routing and stat-only equipment behavior.
