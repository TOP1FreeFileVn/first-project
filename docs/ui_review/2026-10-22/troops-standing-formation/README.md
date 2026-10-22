# Standing team formation review

Focused native Godot proof for the pinned formation in the production Troops page. The fixture uses the actual Home, TroopsPage, troop portraits and dedicated upgrade screen, with mouse events sent through the viewport.

The review captures 360×640 and 450×800 windows with five equipped cats, an upgrade screen opened by tapping a standing cat, visible swap targets, and three/four available team slots containing both an empty slot and castle-locked slots. Structural checks cover transparent individual slots, absence of names/rarity fields/ground circles, centered numeric levels below the portraits, bounds, overlap and native touch sizes. Focused interaction checks cover tap/back, swap-mode target selection, team dragging, collection replacement, benching and the final-unit guard. The collection must still render five columns.

All player changes are in memory (`PlayerData.persist = false`). The runner redirects APPDATA and LOCALAPPDATA into `output/troops-standing-formation-profile` before Godot starts, so autoload startup also uses a disposable profile. It does not change balance resources or player saves.

Run from the repository root with PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./docs/ui_review/2026-10-22/troops-standing-formation/run.ps1
```

Godot output is saved in `godot-run.log` and `godot-errors.log`; `manifest.json` records checks, screenshots, layout rectangles, the profile path and persistence state. Screenshots use the native requested dimensions. Visual review remains necessary for the character artwork and absence of a painted floor halo.

Verified on 2026-10-22 with Godot 4.7.2, Compatibility renderer: **360 checks passed, 0 failed; 10 native screenshots captured.** Formation touch targets are 58×77 px at 360×640 and 72.5×96.25 px at 450×800. Native tap/back, team swap, collection replacement, benching and the final-unit guard passed at both sizes. Visual inspection of full-team, swap-target and starter screenshots confirms free-standing cats, numeric levels, transparent slots and no floor circles; starter screenshots wait for transient bench feedback to fade.

The final stderr log contains only the sandbox's system certificate-store startup message. No GDScript parser or runtime errors remain. `manifest.json` confirms `persist: false` and the disposable profile under `output/troops-standing-formation-profile`.
