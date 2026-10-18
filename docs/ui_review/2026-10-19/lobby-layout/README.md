# Lobby layout review

`tests/ui_review/LobbyLayoutPreview.tscn` renders the real production Home with an
isolated profile and `PlayerData.persist = false`. It changes only the in-memory fixture.

The fixture captures native 720×1280 and native 360×640 images for four cases:

- `normal_lobby`: 2,400 gold, 260 gems, CHEAT hidden, level index 2 unlocked.
- `normal_locked`: the same profile, with locked neighbor level index 3 selected.
- `stress_lobby`: 100,000,397 gold, 9,998,139 gems, CHEAT visible, level index 2.
- `stress_locked`: the stress profile with locked neighbor level index 3.

Each case produces a full image, a native header crop, and a geometry JSON. The JSON
contains exact displayed currency text, visibility, minimum sizes, and control rectangles
for the named header, four shortcuts, island, pager, rewards, and battle action group.
`design_rect` uses the 720×1280 canvas; `render_rect` uses actual screenshot pixels.
Rectangles are `[x, y, width, height]`. The small images are rendered by Godot at 360×640.

Run the existing `tools/review/mcp_ui_review.mjs` with `lobby-layout-plan.json`.
The separate `lobby-layout-routes-plan.json` / `LobbyRoutesPreview.tscn` reuses the
existing EventIconsPreview script to cover the four shortcuts and their return paths
using real viewport mouse input (22 route checks), including free/paid Events branches.
Its exported output directory is `lobby-layout/routes`, and `routes_only = true` skips
screenshots and icon sheets. It preserves the previous `event-icons` review artifacts.

The `before/` folder preserves the latest native normal lobby captures immediately
before this header, shortcut-frame, and battle-action-spacing revision.
