# Bottom UI — wavy concept previews

Status: both the shared wavy dock and the focused wavy divider were rejected by the user. Do not use these drafts as an accepted design reference. No proposal was integrated into production. The new direction is in `../bottom-divider/`.

User clarified that the requested wave belongs to the bottom navigation UI, not to content-panel borders.

- A (`01-footer-wave.png`): keep the current five tiles; make the selected tab's cream caption divider a shallow, broad S-wave.
- B (`02-dock-wave.png`): one continuous warm sand dock with a soft raised crest below the selected tab and subtle curves at the sides. Existing game icons, order, brown outline, and cream/sand palette are retained. This is the preferred direction for a flowing bottom silhouette.
- `03-castle-dock-wave.png`: B shown below the actual Castle page.
- `comparison.png`: full-screen comparison at mobile viewing size.
- `bottom-detail.png`: larger bottom-navigation comparison.

The preview harness instantiates the current production Home scene, then overrides its navigation only in the disposable scene. PlayerData.persist is disabled. No production scripts, themes, or skin assets were changed for this task.

Validation: local Godot MCP captured the current version and both proposals at 720 × 1280; the review scene exited 0. The existing Windows certificate-store warning was unrelated to the preview. Both rendered navigation designs were visually inspected.

The SVGs are authored at the target displayed dimensions. A future implementation should draw or scale the curve as a whole, rather than stretch its central segment using the current nine-slice settings. B currently previews the selected middle tab; selection movement and touch behavior are not implemented in this visual draft.
