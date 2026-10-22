# Hero equipment: four active slots

Native Home/Hero screen review after removing gloves and amulets from hero equipment. The active slots are weapon, helmet, armor and boots, arranged as two slots on each side of the hero. Original held-hero artwork is checked against the existing 2026-10-21 baseline.

Run `powershell -ExecutionPolicy Bypass -File docs/ui_review/2026-10-22/hero-four-slots/run.ps1` from the repository. It delegates current checks to the `centered-icons` runner, which isolates APPDATA and LOCALAPPDATA under `output/hero-centered-icons-profile`; the scene disables save persistence and sound. Historical review images are preserved.

The original captures and manifest in this folder are the four-slot layout baseline. Current reruns write to `centered-icons/` to preserve that baseline after the follow-up icon centering and upright boots correction.

Checks cover fresh accounts and all 13 active items at 360×640 and 450×800, the two equipment columns, useful bag height, card art insets, all eight remaining art families, native navigation, detail open/close, one upgrade and a spare-weapon equip. Full fixture: four equipped items and nine spare items. Fresh fixture: three equipped items and four spare items.

Results are recorded in `manifest.json` with exact card/art bounds and native captures. The scene exits nonzero for a failed assertion.

## Results

- Native UI: **758 checks, 12 captures, 0 failures**. Both display sizes passed fresh-profile, full-inventory, bag, detail, upgrade and equip checks. Images were visually inspected: two cards per side, no removed gear, no card overflow, usable bag height and complete detail actions.
- Focused equipment removal and save migration: **75 checks, 0 failures**.
- Remaining equipment art routing: **101 checks, 0 failures**.

The native Godot run exited 0. Its only stderr message is the existing Windows root certificate store warning; no game script errors were reported. No player save or held-character artwork was changed by this review.
