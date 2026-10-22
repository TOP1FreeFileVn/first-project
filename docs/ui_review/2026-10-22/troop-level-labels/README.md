# Troop level labels

The team formation and unlocked collection cards now show `Lv N` instead
of a bare number. Team captions remain centered in white with a black outline;
the compact card captions use 22px type in a 72x28 area to stay clear of the
upper-right upgrade arrow. Locked cards keep their mystery artwork.

Native layout review: 360x640 and 450x800, 138 checks, 2 captures, 0 failures.
The fixture includes levels 1, 7, 12, 18, 20 and 30, with all upgrades available.
The runner uses an isolated profile and disables persistence and sound.

Use `tests/ui_review/TroopsStandingFormationReview.tscn -- --layout-only`
for this focused review; omit the user argument for the full interaction review.
