# Equipment sort funnel review

The equipment inventory's funnel button opens a local dropdown. Players choose
rarity or item level, then a high-to-low or low-to-high order. Each choice applies
immediately and closes the menu. Category filters preserve the selected sort.

`EquipmentSortReview.tscn` mounts the actual Home/Hero page at 360×640 and 450×800.
It inherits the production inventory and native mouse input helpers from the
equipment integration review. The fixture includes item levels 1 through 10 and
does not substitute or restyle production controls.

The review checks real rarity and level ordering in both directions, preservation
through weapon/defense filters, dropdown containment inside the visible viewport,
outside-tap dismissal without inventory mutation, original bottom navigation,
and unchanged save hashes. It restores the original in-memory player profile.

Run after production edits and imports finish, without another Godot process
importing or reviewing this project:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-24/equipment-sort-review/run-review.ps1
```

The hidden rendering window uses an isolated profile under
`output/equipment-sort-review-profile`. The runner requires a fresh
`native/review.json`, a successful completion marker, and zero failures.

Native verification passed **273 checks, 16 captures, zero failures** at both
window sizes. Actual spare items sort by rarity and level in both directions;
weapon/defense filters preserve the selected level order. All menu options remain
inside the dropdown and viewport. Clicking the backdrop closes it without
changing inventory or order. Save hashes remain `absent` before and after, and
the original in-memory profile and persistence flag are restored.

Visual review confirmed a compact dropdown aligned below the funnel, with the
selected criterion and order highlighted. The runtime log contains no script
errors; it reports a Windows root-certificate-store read error unrelated to the
local review.

- [Rarity menu at 360×640](native/sort-menu-rarity_360x640.png)
- [Level menu at 450×800](native/sort-menu-level_450x800.png)
- [Level ascending at 450×800](native/sort-level-ascending_450x800.png)
- [Verification report](native/review.json)
