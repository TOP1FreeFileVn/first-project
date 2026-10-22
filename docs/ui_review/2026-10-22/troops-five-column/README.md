# Compact troop cards — native visual review

Final native Godot run: **1,196 checks, 18 captures, 0 failures** at **360×640** and **450×800**. The production viewport remains 720×1280 with canvas-item stretching.

The fixture loads the real Home and TroopsPage, then supplies disposable in-memory player state. `APPDATA` and `LOCALAPPDATA` point to `output/troops-five-column-profile`; `PlayerData.persist` is false. Progression constants and balance resources remain unchanged. Current progression supports three stars, so the fixture covers one, two, and three earned stars. “Five” refers to the five cards in each complete collection row.

Coverage:

- All 16 unlocked troops, valid one/two-digit levels, current maximum star count, and longest existing names.
- Five-card rendered rows, no horizontal overflow or overlapping cards, portrait/text/star bounds, centered earned stars, and game-font white text with black outlines.
- Upgrade arrows above the upper-right border, team checks at the lower-right, simultaneous ready/equipped state, vertical arrow motion at a fixed scale without clipping, no arrows when resources are unavailable, and team checks retained in that state.
- All four rarity filters and their actual troop counts.
- Locked black silhouettes with centered light question marks and no earned stars or upgrade/team markers.
- Native pointer taps open the dedicated upgrade screen; modal layering hides the roster markers; Back restores roster scroll and rarity filter; arrow animation resumes.

Representative captures:

- `all-top_360x640.png` and `all-top_450x800.png`: compact collection and pinned team.
- `all-bottom_360x640.png` and `all-bottom_450x800.png`: remaining collection cards.
- `locked-mixed_360x640.png`: black locked silhouettes and question marks.
- `no-resources_360x640.png`: equipped checks with unavailable upgrades.
- `card-opens-detail_360x640.png`: native dedicated upgrade screen.
- `rarity-0` through `rarity-3` at both window sizes: filtered collections.

`manifest.json` records every result, capture, and isolated profile location. `godot.log` records the final run. The only engine error in that run is the environment's known Windows root-certificate-store warning; there are no GDScript or resource errors.

Run from the repository root:

```powershell
$reviewRoot = (Get-Location).Path
$env:APPDATA = Join-Path $reviewRoot 'output\troops-five-column-profile\roaming'
$env:LOCALAPPDATA = Join-Path $reviewRoot 'output\troops-five-column-profile\local'
& 'C:\Users\dangp\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe' --path $reviewRoot --windowed --rendering-method gl_compatibility --max-fps 60 --log-file 'docs/ui_review/2026-10-22/troops-five-column/godot.log' 'res://tests/ui_review/TroopsFiveColumnReview.tscn'
```
