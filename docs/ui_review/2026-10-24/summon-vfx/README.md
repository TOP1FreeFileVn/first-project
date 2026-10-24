# Summon effects — 2026-10-24

The summon banner and opening now share a flat lilac paw portal with warm brown
contours, cream orbit marks and mint motes. A floating card gathers the motes,
compresses briefly and releases the results. Cards fan into their slots and flip;
rare cards receive a local ring, stars and a short title. The troop showcase uses
the same portal beneath the existing character art.

`game/ui/SummonPortal.gd` draws and animates the portal natively in Godot. Bursts
are bounded and expire after 0.8 seconds. Full-screen white flashes and random
interface shakes have been replaced by local effects.

`SummonOpening.gd` tracks and cancels presentation tweens when skipping. Skipping
during charge, card flight, a rare reveal or showcase leaves one stable face-up
result grid. Repeated skip cannot duplicate controls, and fast taps preserve a
rare card's reveal beat. Reward, cost, pity and inventory logic is unchanged.

## Native review

Run `powershell -NoProfile -ExecutionPolicy Bypass -File
docs/ui_review/2026-10-24/summon-vfx/run.ps1 -Record` from the project root.
The fixture uses supplied results and an isolated workspace profile with
`PlayerData.persist = false`. Both 450×800 and 360×640 passed **179 checks** and
saved **18 captures** each, covering natural x1/x10, all presentation stages,
native skip/done clicks, skip stability, repeated input, fast taps, menu-context
restoration and unchanged player data. The fallback without Home still reaches
its original 0.9 dim level.

The first render exposed degenerate star polygons at the end of their fade.
Stars below 0.75 source pixels or 0.01 alpha are now omitted; the final runs have
no script or polygon-render errors. The Windows certificate-store warning and
Dummy audio-driver shutdown warnings are unrelated to the visual checks.

`manifest-*.json` records checks, captures, profile and recording length.
`python docs/ui_review/2026-10-24/summon-vfx/build_preview.py` packages the native
recording as `summon-preview.gif` and builds `overview.png`.
