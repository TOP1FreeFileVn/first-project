# Chest light polish — native production review

This folder owns only the review harness and its captured evidence. Production
art and animation live in `game/ui/ChestOpening.gd` and `game/ui/ChestLight.gd`.

Run from the repository root after production changes are ready:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-23/chest-light-polish/run-review.ps1
```

The runner launches a hidden **native rendering** window with the Dummy audio
driver; no editor or import pass. `APPDATA` and `LOCALAPPDATA` point to
`output/chest-light-review-profile`. The scene disables PlayerData persistence,
snapshots/restores the original in-memory state, and compares save hashes. It
passes safe fixture dictionaries directly to production ChestOpening and calls
no loot grant or chest purchase API.

Coverage:

- Actual production Home and menu pattern behind the opening overlay.
- 360×640 and 450×800 native viewport captures.
- Closed wait, moving open mouth, face-up common/rare/epic reward cards.
- Native Skip taps during wait, charging and card reveal, plus fast summary.
- Native Done taps, one closed signal, freed overlay layer and return to Shop.
- No fixture loot granted, no persisted save change, original profile restored.

Outputs: `review.json`, stage PNGs, a native `frames/` sequence,
`opening-preview.gif` and `native-states.png`. GIF packaging uses local Python
Pillow and only combines actual captured game frames. Logs remain under the
isolated output profile. `-SkipGif` skips Python packaging.

Verified final native run: **214 checks, 20 stage captures, 30 sequence frames,
0 failures**. The total includes checks that each recorded frame saved correctly;
the frame count can vary slightly with native renderer cadence. The final report
records the exact images used by the GIF. No loot was granted, the isolated save
hash remained unchanged, and the original in-memory profile/persistence setting
were restored.

The visible rhythm now uses a 1.2-second breathing cycle at the closed seam,
the existing rarity-dependent 0.35–0.85-second wind-up with an 80 ms anticipation
beat, and a localized opening flash that fades in 0.16 seconds. The warm shaft
fades upward; the softer reward halo/rays follow the revealed card's rarity.

Final teardown stops and releases the review's muted looping audio before the
Dummy-driver process exits. The verbose investigation identified the initial
exit warning as `lobby.wav` playback, not a light texture/cache leak. After this
harness-only cleanup, the final run has no leaked object/resource warning and
no script errors. The unrelated Windows root certificate-store warning remains.
