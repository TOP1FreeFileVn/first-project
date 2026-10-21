# Gear selling, chest art and equipment icon layout

## Production changes

- The permanent battle sell control is gone. Dragging a sellable gear replaces the full-width Ready button with a temporary drop target. Hover changes the target and previews the credited whole-coin amount, including wallet-cap limits. Releasing outside keeps the gear. Skill gears cannot be sold; merges, swaps and right-click selling retain their existing behavior.
- Drag input cannot click through to a shop offer or Ready. Starting a wave is blocked while dragging; focus loss and phase changes restore the held gear.
- Wood, silver and gold chests share a broader rounded silhouette, a warm brown contour, two broad straps and a paw lock. Their original gameplay identities and lid animation remain intact. Small smooth vector accents replace the old pixel blast without changing loot or skip/close behavior.
- Hero equipment card art is positioned against the full card, below the slot/level row, rather than inside the face's themed content margins. Five weapons and gloves/boots/amulet use a 45-degree up-right functional axis; helmet/armor remain upright. All ten icon families have 8% transparent safety margins at every size, including the previously oversized base images. Character-held art remains unchanged.

## Evidence

- [Temporary sell target, 360×640](gear-sell-drop/hover_360x640.png), [idle Ready button](gear-sell-drop/idle_360x640.png), [sell checks](gear-sell-drop/manifest.json), [wallet-cap checks](gear-sell-drop/wallet-capacity/manifest.json).
- [Chest comparison](../../design/2026-10-21/chest-redesign/before-after-native.png), [actual opening, 360×640](../../design/2026-10-21/chest-redesign/actual-open-360x640.png), [art checks](../../design/2026-10-21/chest-redesign/manifest.json).
- [Chest summary and routes](../2026-10-19/chest-layout/manifest.json).
- [Actual hero equipment, 360×640](equipment-icon-layout/hero-all-items_360x640.png), [comparison sheet](equipment-icon-layout/comparison-detail_360x640.png), [native checks](equipment-icon-layout/manifest.json).
- [Equipment icon source sheet](../../design/2026-10-21/equipment-icon-fit/after-sheet.png), [source axes and regeneration evidence](../../design/2026-10-21/equipment-icon-fit/README.md).

All runtime fixtures use workspace-isolated APPDATA/LOCALAPPDATA and disable PlayerData persistence. Existing production saves are not test fixtures.

## Verification

- GearSellDropTest: 116 checks, six native captures, zero failures at 720×1280 and 360×640. Wallet-capacity follow-up: 26 checks, two captures, zero failures.
- ChestArtRedesign: 37 checks, ten native captures, zero failures at both sizes; actual Shop and wait/open/card states inspected.
- ChestOpeningLayoutPreview: ten native captures, 30 passing routes; fast opening, skip, many rewards, gold-only rewards, scrolling, close/view-troops and preservation of already-granted loot.
- PinMeshTest, FishSkillTest and DeploymentTest passed after the selling change.
- EquipmentArtTest: 103 checks, zero failures. Fifty icon variants pass the transparent-inset check; all 119 other PNGs, including held characters, retain their prior hashes. Repeated icon installation is idempotent, and a full isolated regeneration reproduces all 169 PNGs byte-for-byte.
- EquipmentIconLayout: 628 checks, ten native captures, zero failures. Actual Home/Hero navigation, 17 equipped/spare cards, one/two-card details, alpha containment, caption clearance, bag scrolling, equip/upgrade/close and unchanged held-art hashes were checked at both sizes.

Godot reports the host certificate-store warning in isolated runs; it does not prevent rendering or the tested routes.
