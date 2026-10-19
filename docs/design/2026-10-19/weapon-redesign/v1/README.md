# Weapon design proposal 01

Status: **awaiting user review**. The 16 proposed weapons and their held poses
are isolated in this folder. Production weapon/unit art and gameplay data have
not been replaced. The requested removal of the title plaque above the Shop
has been applied in `game/menu/Home.gd`.

## Review images

- [All 16 weapon designs](weapons-proposal.png)
- [Old and new weapons side by side](weapons-before-after.png)
- [All 16 cats holding the proposal weapons](cats-with-proposal.png)
- [Native roster, upper rows](troops_proposal_top_450x800.png)
- [Native roster, lower rows](troops_proposal_bottom_450x800.png)
- [Native roster at 360 x 640](troops_proposal_bottom_360x640.png)
- [Shop with the title plaque removed](shop_without_title_450x800.png)

The proposal uses flat colors, rounded warm-brown outlines, broad metal and wood
shapes, and limited blue/purple/gold accents. The silhouettes distinguish each
weapon without fine engraving or small decoration. Ranged weapons, potion and
book have individual held positions so they leave the cat's eyes visible.

## Sources and validation

`weapon_melee.py`, `weapon_ranged.py`, and `weapon_magic.py` define the 16 icons.
`build_assets.py` emits the isolated weapon SVGs at 64/128/256 pixels and held-cat
SVGs at 256 x 240, using the existing unit body generator. `build_boards.py`
assembles the review boards from Godot's raster renders.

The native Godot fixture rendered all 16 icons/units, captured five native UI
screens at 450 x 800 and 360 x 640, and confirmed the Shop title is absent while
the header remains below the awning. The proposed unit textures are injected
only into the fixture's in-memory SpriteLib cache. PlayerData persistence is
disabled and the MCP client uses an isolated profile. Details: [runtime.json](runtime.json)
and [MCP log](mcp/mcp-results.json).

Rebuild and capture from the project root:

```powershell
python -B docs/design/2026-10-19/weapon-redesign/v1/build_assets.py
node tools/review/mcp_ui_review.mjs docs/design/2026-10-19/weapon-redesign/v1/capture-plan.json
python -B docs/design/2026-10-19/weapon-redesign/v1/build_boards.py
```
