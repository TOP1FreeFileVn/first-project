# Native chest integration review

Production `ChestArt`, `DrawnIcon`, `ShopPage` and `ChestOpening` at 360×640 and 450×800. This review uses the actual tier palettes and opening tween. The final source combines the [basic chest polish](../../../design/2026-10-22/chest-polish/README.md) with the [premium gold construction](../../../design/2026-10-22/chest-premium/README.md).

Run from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File docs/ui_review/2026-10-22/chest-integration/run.ps1 -ImportAssets
```

The runner isolates APPDATA and LOCALAPPDATA under ignored `output/chest-integration-profile`, disables player-data persistence, mutes sound and uses Godot's native OpenGL renderer. It does not alter the normal player profile.

The full three-tier run passed **175 checks with 43 captures and zero failures**. The final gold revision then passed **136 focused checks with 31 captures and zero failures**: the featured Shop art is 248 px versus the basic chests' 200 px, the opening prop is 300 px versus 250 px, and the gold body, lid and latch use additional reinforcement geometry. The rejected lid gem and under-lock tab are absent.

That final run used `-ImportAssets -GoldOnly`. It updated native icons, comparison boards, actual Shop, live icon routes, Battle lobby and gold opening states at both sizes. Existing wood/silver opening captures remain from the full pass because their art and animation did not change. `manifest.json` records the scope of both passes; the preceding full manifest and key screenshots are retained locally in ignored `output/chest-integration-flat-polish-baseline`.

`manifest.json` records every capture, painted icon bounds, real Shop stage dimensions, live icon resource paths, total checks and failures. The review covers all three tiers at 26/48/64/96/128/256 px, the real Shop, drop-to-wait, flying-lid and card-reveal states, accepted SVG routing at 32/48/64/96/128 px and the actual Battle lobby reward counter. Existing equipment PNG overrides keep priority. The existing 2026-10-21 chest review remains unchanged.

Useful images:

- [Shop at 450×800](shop-450x800.png)
- [Final gold chest crop](gold-chest-final.png)
- [All tier paints and small symbols](tier-and-small-symbols.png)
- [Separate lid and stationary base/latch](separate-lid-states.png)
- [Wood wait state](actual-wait-wood-450x800.png)
- [Wood opening state](actual-open-wood-450x800.png)
- [Gold card reveal](actual-card-gold-450x800.png)
- [Live accepted SVG icon sizes](accepted-chest-icon-routes.png)
- [Battle lobby reward counter](lobby-chest-counter-450x800.png)

The final native game run emitted only the Windows root-certificate warning, with no game script or asset errors. The separate editor import exited successfully; its log also records existing Android build-tools, nested-project and inaccessible local YAML-directory warnings.
