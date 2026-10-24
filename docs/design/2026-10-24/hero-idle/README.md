# Restored equipment hero idle — 24 October 2026

The equipment hero uses the approved ginger model's separated parts and an authored Spine idle clip. The machine operator in the battle scene remains separate. The preview follows the equipped weapon's melee, ranged, magic, heavy or katana family; removing the weapon selects the bare family.

`HeroIdleReview.tscn` mounts the production Home/Hero UI with isolated, nonpersistent inventory data at 360×640 and 450×800. It taps the real equipment controls, verifies the selected Spine family, compares naturally advancing bone poses, and records visible attachment bounds against the preview and adjacent cards. It also checks remaining inventory space and restores the in-memory profile without saving.

Run only after the new production hero assets are imported:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-24/hero-idle/run-review.ps1
python -B docs/design/2026-10-24/hero-idle/make-gif.py
```

The runner requires a fresh `native/review.json`, zero failures and a successful completion marker. `native/idle-0_450x800.png` is the first actual production frame; the GIFs use 16 consecutive natural-time viewport captures. The review does not seek or manually process the rig and does not substitute art or layout.

Native verification passed **256 checks, 42 captures and zero failures** across both display sizes. The five weapon families and bare state all load the matching production Spine assets. Natural-time samples confirm the idle clock and bone poses advance. Painted attachment bounds stay inside the stage and clear of the side cards; visual review of four idle phases confirms clearance above the combat-power plaque. Save hashes match before and after the review.

- [450×800 production screenshot](native/idle-0_450x800.png) · [360×640 screenshot](native/idle-0_360x640.png)
- [450×800 idle GIF](native/hero-idle_450x800.gif) · [360×640 idle GIF](native/hero-idle_360x640.gif)
- [Verification report](native/review.json)

The runtime exit log also reports two CanvasItem RIDs and four ObjectDB instances left at shutdown. Read-only inspection did not establish their source; these cleanup warnings are not covered by the successful visual/interaction checks. No production cleanup behavior was changed in this review.
