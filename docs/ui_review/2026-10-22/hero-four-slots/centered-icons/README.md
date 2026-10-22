# Centered equipment icons and upright boots

Follow-up to the four-slot layout baseline in the parent folder. The original art square sat 11% of the card height below the card center. Production equipment cards now center the painted artwork in both axes, and the accepted boot art retains its authored upright orientation. Weapon artwork uses 68% of the card width to leave space below the level text; upright gear keeps the existing 78% size.

Run `powershell -ExecutionPolicy Bypass -File docs/ui_review/2026-10-22/hero-four-slots/centered-icons/run.ps1`. APPDATA and LOCALAPPDATA are isolated under `output/hero-centered-icons-profile`; persistence is disabled and sound is muted.

The review retains fresh and full fixtures at 360×640 and 450×800, native detail/upgrade/equip interactions, four-slot and art-bound checks. It additionally checks the painted alpha bounds are centered within one native pixel on both axes, controls have no rotation/deformation, and all five boot raster sizes record zero source rotation. Broad alpha bounding boxes no longer impose an artificial top caption clearance; small icon/header interactions are inspected in native captures.

## Final results

**863 checks, 12 native captures, 0 failures**; Godot exited 0. Maximum measured painted-center error is below 0.31 native pixels across all reviewed cards. All five boot raster sizes passed the zero-rotation contract, and the boots appear upright in the actual equipped and bag cards.

Visual review at both sizes confirms centered items, preserved card insets and complete detail actions. Enlarged sword and katana crops (`sword-header-inspection.png`, `katana-header-inspection.png`) confirm the final smaller weapon square clears the level text. The earlier trial at 78% had tip/label contact and was replaced before final capture. Held-character artwork hashes are unchanged.

The existing Windows root certificate warning is the only stderr message; no game script errors were reported.
