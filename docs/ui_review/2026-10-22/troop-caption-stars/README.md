# Troop captions and compact stars

Collection names and corner levels now use a white fill with a 6 px black
outline in the 720 px layout, matching the existing standing formation levels.
The previous 3 px collection contour was too faint after downscaling.

Earned stars remain 24 px with centered alignment. HBox separation is -4 px,
overlapping the transparent icon insets so the painted stars sit closer without
covering each other. Only the earned 1/2/3 stars are displayed.

Native Godot captures cover 360×640 and 450×800, top and bottom of the real
collection. The existing five-column fixture's layout/content checks passed
1,010 checks with zero failures. Visual inspection includes the longer names
Gậy Phép, Bình Thuốc, Sách Phép and Đũa Phép, plus centered one/two/three-star
rows. There are no script errors; the renderer emits the environment's existing
certificate-store warning.

The follow-up shortens collection arrows to 84% height around the same pivot;
their width, corner placement and pulse remain. The same four native captures
and 1,010 layout/content checks passed again after this change.

Player changes are in memory only, using a disposable profile under
`output/troop-caption-stars-profile`. The capture fixture is
`output/TroopCaptionSpacingPreview.gd`, reusing the existing collection review.

- [Top at 450×800](top_450x800.png)
- [Top at 360×640](top_360x640.png)
- [Bottom at 450×800](bottom_450x800.png)
- [Kiếm card crop](kiem-card.png)
- [Kiếm card with shorter arrow](kiem-card-short-arrow.png)
