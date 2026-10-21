# Isolated native art review

Run `powershell -ExecutionPolicy Bypass -File ./run.ps1` after the parent folder's `hero-equipment-review.png` and four `processed/hero-{melee,ranged,magic,heavy}.png` files exist. Hero sources must be 768 × 720, retaining the unchanged 256 × 240 authoring canvas at 3×.

The helper starts a hidden Godot 4.7.2 compatibility-renderer process, without production scenes, game autoloads or audio. It redirects only the child process's `APPDATA` to `native/profile-roaming/` and `LOCALAPPDATA` to `native/profile-local/`; the parent environment remains unchanged. The custom Godot directory is `StudioHeroV3`, so its final user directory must resolve to `native/profile-roaming/StudioHeroV3/`. The GDScript rejects any other resolved location before reading the board. Relative parent traversal is deliberately absent from the project setting because Godot sanitizes it.

Outputs are `native/godot-review.png`, `native/review-status.json`, four `processed/hero-*-128-godot.png` thumbnails, and logs. This checks image loading, scaling and native rendering only. Artwork fit, authored stroke quality, grip placement and legibility still require visual inspection. It does not establish runtime equipment integration.
