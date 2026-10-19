# Sky and distant islands: lobby background demo

Status: accepted and applied to the production menu on 2026-10-19.

The production sky now has three independently drifting cloud layers and gently
floating distant islands. Horizontal cloud motion is twice the first animated
version's speed; the islands retain their gentle bobbing. The Shop tab uses a
deeper blue scrolling gear/paw pattern with a striped cartoon awning, drawn in
`game/ui/skin/shop_awning.svg` to match the shop icon's rounded cloth and brown
outlines.
In the Shop, the awning sits above the avatar/currency/settings row. The title
plaque was removed at the user's request.
Other tabs retain their original header position.

The editable source is `game/ui/skin/bg_sky_islands.svg`. Run
`python tools/ui/split_sky_layers.py` to regenerate the five production layers
(`bg_sky_base`, `bg_sky_clouds_far`, `bg_sky_clouds_near`, `bg_sky_clouds_front`,
and `bg_sky_distant_islands`). `Ui.menu_bg()` composites these with
`game/ui/menu_sky.gdshader`. Screen coordinates and a shared animation clock keep
the Castle overlay aligned with the header and navigation background.
The PNGs below preserve the original before/after art study.

The proposed backdrop replaces the repeating paw/gear pattern with a blue-gray
sky, broad rounded clouds, and three small distant grass islands. The foreground
castle, characters, interface, typography, and layout are the existing native UI.
Distant scenery uses muted outlines and colors to keep attention on the stage.

- `background.svg`: editable self-contained 720 × 1280 vector source.
- `demo.png`: native Godot capture with the proposed backdrop.
- `current.png`: matching native capture with the production backdrop.
- `comparison.png`: before/after overview.
- `SkyIslandsPreview.tscn`: isolated preview scene.
- `SkyIslandsLive.tscn`: interactive 450 × 800 preview of the current production
  sky animation and Shop background; keeps the window open.

Historical comparison capture (rerunning replaces the saved comparison inputs):

```powershell
node tools/review/mcp_ui_review.mjs docs/design/2026-10-19/sky-islands-demo/capture-plan.json
```

The harness disables PlayerData persistence and uses an isolated MCP profile.
The static comparison freezes the same UI pose for both captures; the live
preview keeps the production background and UI animations running.

Current motion and Shop runtime checks are in
`docs/ui_review/2026-10-19/menu-background-motion/`.
