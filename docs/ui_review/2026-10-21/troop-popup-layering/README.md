# Troop popup decoration layering regression

Production Home with eight unlocked troops, five teamed troops and enough gold to upgrade. The fixture opens Mèo Đao through its native roster button at 360×640 and 450×800.

Latest native run: **59 checks, 14 captures, 0 failures**, exit code 0. Player data stays in RAM (`PlayerData.persist = false`) under an isolated profile.

At each size the fixture freezes underlying arrow motion and compares the real arrow/check ink regions covered by the opaque popup panel. The fixed popup and the same popup with underlying markers hidden are pixel-identical. A runtime-only negative control raises arrows to z=8 and checks to z=1, reproducing the reported bleed; the comparison detects changed pixels. Restoring z=0 returns to zero changed pixels. `manifest.json` contains the sampled regions and exact counts.

`negative-control-raised-markers_*.png` intentionally shows the old defect to validate the regression test. `popup-fixed_*.png` and `popup-restored_*.png` show production behavior.

The fixture also presses the popup's upgrade and close buttons through native pointer events, verifies exact gold spending and one gained level, and checks that fresh roster arrows resume their pulse naturally after closing. No production code is changed by the negative control.

Run `tests/ui_review/TroopPopupLayering.tscn` with Godot in native rendering mode, without `--headless`, using an isolated APPDATA/LOCALAPPDATA profile.
