# Approved lobby integration review

Final production rerun includes the cleaned terrain, live tunnel and bed, calico lane at x528, pillow occlusion, and imported yarn foreground.

- `CardboardLobbyIntegration.tscn`: **85 checks, 7 native screenshots, 0 failures**, process exit 0. Window sizes: 720Ã—1280, 450Ã—800, 360Ã—640.
- `CardboardInteractionReview.tscn`: **561 deterministic samples across 28 seconds at 20 Hz, 4 parent handoffs, 0 failures**, process exit 0. Maximum per-sample logical position change: **1.006 px**.
- All production sprite textures load. No script/runtime/resource errors. Windows emits a root-certificate-store warning, unrelated to local rendering.

The integration fixture uses a workspace-isolated APPDATA/LOCALAPPDATA profile and disables PlayerData persistence. It exercises real viewport clicks for stage arrows, Shop/Battle navigation, Castle opening/closing, and Login opening/closing. It checks that page/resource refreshes preserve the same world and actors, hidden scenes pause, returning resumes, locked battle actions stay disabled, and unlocked battle actions remain connected. It never starts a battle.

`manifest.json` records the integration assertions and screenshot states. Screenshots include the lobby at all three sizes, locked stage and Shop at 450Ã—800, and Hero/equipment detail at 360Ã—640.

`interactions/manifest.json` contains the complete 20 Hz position/parent/state timeline. The deterministic review checks stable actor identity, positive uniform scale, unchanged front layers, no hiding/fading/flip, world-position continuity through reparenting, fixed rear/interior/occupant/front order, exclusive reservations, and occupancy matching the actual scene parent. It renders 22 critical-phase crops covering inside, exit, approach, entry, and immediately before/after both handoffs for both residents.

Visual review of the seven production screens and both contact sheets found no material clipping, missing terrain, black backgrounds, size jumps, or handoff discontinuities. The yarn now covers the cream cat at its foreground crossing. The calico tail clears the bed corner. Front-facing entry and exit are intentional; this review does not assert a full Spine animation cycle.

- [Tunnel contact sheet](interactions/tunnel-contact-sheet.png)
- [Bed contact sheet](interactions/bed-contact-sheet.png)
- [Small lobby screenshot](lobby_360x640.png)

Harness scenes are under `tests/ui_review/`. Launch with Godot 4.7.2, `--rendering-method gl_compatibility`, and a workspace-isolated profile. Regenerate contact sheets with `interactions/create_contact_sheets.py` after rerunning the deterministic scene.
