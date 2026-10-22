# Approved equipment frame integration

The user selected frame A and palette 1 on 2026-10-23. Production `Ui.gear_card`
now uses the dedicated `CardEquipmentGreen/Blue/Purple/Orange` theme variants for
equipped gear, the five-column inventory and item comparison sheets.

The four installed SVGs match the approved natural-palette drafts byte for
byte. All previous skin SVGs were verified unchanged. The narrow skin and theme
install commands are documented in `game/ui/FrameStyle.md`; full rebuilds also
include this frame. Zero texture margins preserve the original square geometry
and tape proportions. Equipment artwork, levels, badges, upgrade arrows and
empty-slot symbols retain their existing layout and assets.

`ReviewEquipmentFrames.tscn` captures the actual Home/Hero route with no visual
overrides at 450×800 and 360×640. The fresh profile, full thirteen-item catalog
(four worn and nine spare), five cards per row, and native bow comparison were
reviewed. `review.json` records 33 passing checks, six native captures and no
save writes. Only the existing root-certificate-store warning appeared during
the native review; there were no script or runtime failures.

Main captures: `full-bag_360x640.png`, `full-bag_450x800.png`,
`bow-comparison_450x800.png`.
