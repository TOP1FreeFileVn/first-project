# Approved clean axe integrated — 2026-10-22

The user approved the latest clean axe and requested applying it to the game.
The five hero inventory icons and `hero_cat_heavy.png` now use that version.
The head has two broad unlined steel fills; the wooden grip has no extra marks.
Icon direction remains up-right. The held version uses the original right-paw
socket, original cat/base/paw layers and the already-reviewed carry pose.

The 768×720 production hero was rendered by Godot from the same accepted SVG
paths at that resolution. It is not an enlargement of the 256×240 PNG.
`export.mjs` and `render.ps1 -Family axe` regenerate its native sources.
`python -B tools/ui/install_equipment_art.py --approved-weapon riu` installs
only these six production files. Full and icon-only installer runs retain
this source selection, so the old v4 axe cannot overwrite it.

`production-review.png` compares the saved previous production art against the
actual installed PNGs. The unchanged cat is displayed at the same size.
`before-hashes.json` and `verification.json` record all 169 production PNGs:
exactly six changed, while the other 163 stayed byte-identical, including all
five corrected up-left bow icons. Manifest output and source hashes match.
An isolated full installer rebuild under `output/approved-axe-rebuild-check/`
also reproduced all six approved axe files and the five up-left bow icons
byte-for-byte, without modifying any production files during that check.

Godot editor import finished with exit0. `EquipmentArtTest.tscn` then loaded
the real production resources and passed **101 checks, zero failures**, covering
five hero weapon appearances, native equipment routing, soldier routing and
the three stat-only gear slots. Logs are saved beside this file. The import
also reports existing certificate, Android tools and inaccessible local Python
dependency directories; these did not prevent the equipment runtime test.
The test's native hero snapshot is
`docs/ui_review/2026-10-22/hero-four-slots/art-routing/hero-riu_lua.png`.

Other proposed Canvas weapon redraws remain separate from this integration.
