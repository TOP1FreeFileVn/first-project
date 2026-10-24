# Hero outer-surface alternatives

**Decision:** the user rejected all three enclosed panels below. They remain
review history and must not be applied to production.

## Current proposal: framed information

The user requested backgrounds and frames around combat power, stats, skill and
troop synergy. `HeroInfoReview.tscn` keeps the open hero composition and adds:

- A cream power plaque with dark brown text and border below the animated feet.
- One dark slate panel for HP / ATK / DEF, with no vertical dividing lines.
- Two matching framed areas for skill and troop synergy.

These surfaces are opaque, have one outline and no drop shadow. The four
equipment-card frames, larger skeletal hero and original bottom navigation are
preserved. This remains a review-only design.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-24/hero-surface-review/run-review.ps1 -Framed
python -B docs/design/2026-10-24/hero-surface-review/assemble.py --framed
```

The native review passed **215 checks, 50 captures, zero failures** at 360×640
and 450×800. The four weapon forms play real idle, each sampled pose clears the
equipment columns and power plaque, all information labels fit inside their
frames, and the inventory retains usable height. Player-save hashes match.

- [Framed information detail](framed-detail.png)
- [Full page at 360×640](native/framed_360x640.png)
- [Four weapon forms playing idle](framed-four-idle.gif)
- [Report](native/framed-review.json)

## Follow-up: open composition

The new proposal removes the enclosing panel, stat lines, lower color band and
combat-power box. It uses a continuous slate-blue patterned background, cream
text and an approximately 20% larger hero. The original equipment-card frames
and bottom navigation remain unchanged. This is still review-only.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-24/hero-surface-review/run-review.ps1 -Open
python -B docs/design/2026-10-24/hero-surface-review/assemble.py --open
```

The final open-composition run passed **131 checks, 50 captures, zero failures**.
It verifies two phone sizes, useful inventory height, and natural idle in all
four requested weapon forms. Every sampled animation frame is clear of the
equipment columns and power text. A separate review background keeps the design
stable through Home's periodic shared-surface refreshes. Player-save hashes match.

- [Open composition detail](open-detail.png)
- [Four weapon forms playing idle](open-four-idle.gif)
- [Full page](native/open_450x800.png)
- [Report](native/open-review.json)

A concurrent cleanup of shared production scripts briefly prevented the review
from compiling. The missing `Ui` preload used by `GearBoard.draw_tile()` was
restored; the final scene runs without script errors. No proposed UI redesign
was applied to production.

## Rejected enclosed surfaces

Review-only designs for the enclosing hero panel and its combat-power plaque.
The production game is not switched to a new palette until a design is chosen.

- **A — blue grey:** `#CBDDDA`, dark teal outline `#354E50`, soft corners.
- **B — cream paper:** `#F0E0C3`, brown outline `#654D3B`, clipped corners and one small fold.
- **C — grey lavender:** `#DED7E8`, muted plum outline `#54485F`, rounded corners.

All alternatives reuse the real `Home`/`HeroCatPage`, equipment cards, artwork,
game font and bottom navigation. The enclosing outline is a single 3-logical-pixel
line without a shadow. Stat-table dividing lines are removed for this proposal.
The equipment-card designs and rarity colors are preserved.

## Review

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File docs/design/2026-10-24/hero-surface-review/run-review.ps1
python -B docs/design/2026-10-24/hero-surface-review/assemble.py
```

Native rendering completed with **75 checks, 54 captures, zero failures** at
360×640 and 450×800. All four requested weapon forms (sword, bow, staff and axe)
load idle and naturally change their bone poses. Save hashes are unchanged; the
review uses an isolated profile with persistence disabled. The exit log contains
the environment's root-certificate-store warning; no script errors were reported.

- [Compare the three outer surfaces](comparison.png)
- [Four weapon forms playing skeletal idle](four-weapon-idle.gif)
- [Full page with blue-grey surface](native/surface-0_450x800.png)
- [Native report](native/review.json)

The comparison uses actual viewport crops. The GIF uses natural-time captures,
without seeking the animation or animating a flattened cat image. Card-interior
pixel checks exclude antialiased edges that blend with the different backgrounds.
