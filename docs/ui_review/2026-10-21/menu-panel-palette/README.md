# Menu panel palette review — 2026-10-21

The beige/gold Board and Well panels in Shop, Hero, Troops, Castle, Patrol and Events now follow their screen palettes. The shape, padding, rarity cards and buttons remain consistent with the existing game art.

[Before / after comparison](menu-panels-before-after.png)

## Native validation

- Godot 4.7.2, Compatibility renderer, actual 720 × 1280 and 360 × 640 windows.
- **67 checks, 16 captures, 0 failures**, process exit 0.
- Real Home navigation, Hero item-sheet opening/closing, Castle back route and native wheel scrolling to all three workshop actions, Events → Patrol and back.
- Battle probe retains the original `Background.gd`, contains no menu-context panels and does not start a wave.
- A separate workspace-local APPDATA/LOCALAPPDATA profile and `PlayerData.persist = false` keep all player changes in RAM.
- [Manifest](manifest.json) records checks, captures and measured label colors; [log](godot.log) contains the existing Windows root-certificate-store warning, with no script errors or cleanup warnings.

## Readability

Contrast is calculated from each changed panel's actual imported texture center, multiplied by its StyleBox modulation, and its Label font color. Labels on their own Button, ProgressBar or nested panel are excluded from this face comparison. This measures text against the flat panel face, not every composited screen pixel.

| Screen | Measured contrast | Review |
| --- | --- | --- |
| Shop | 7.77:1; purple pity text 4.95:1 | Pale blue fits the shop roof and distinguishes yellow action buttons. |
| Hero | 5.25–5.71:1; green stat delta 4.95:1 | Mint Board/Well panels coordinate with the backdrop and preserve equipment rarity colors. |
| Troops | 6.18:1 | Sage team board separates from colorful roster cards. |
| Castle / workshop | 7.91:1 | Stone green suits the cardboard castle; all workshop buttons remain reachable. |
| Events | 6.75:1 | Rose rows fit the event backdrop and preserve the purple featured banner. |
| Patrol | 8.15:1 | Sage information panel removes the yellow cast; rate, storage and timer read clearly. |

All measured labels use no outline. There are no new overlaps, clipped labels or distorted panel borders in the reviewed captures. Some existing secondary labels remain small on a 360 px window; their layout and typography are a separate future UI pass.

Additional captures: [Hero detail](hero-detail_360x640.png), [Castle workshop](castle-workshop_360x640.png), [Patrol](patrol_360x640.png), [Shop at 720 px](shop_720x1280.png).

## Reproduce

Run `tests/ui_review/MenuPanelPalette.tscn` with the Compatibility renderer and isolated workspace-local `APPDATA` and `LOCALAPPDATA` variables. The fixture creates fresh RAM state before instantiating Home. Run `make-contact.py` afterward with Pillow installed to rebuild the comparison from these captures and the earlier `menu-pattern-background` captures.
