# Independent weapon-set review

Reviewed the final 15 new weapons and the accepted sword baseline. Production artwork was not changed by this review.

## Result

Passed native Godot rendering and independent face/bounds checks for the complete set. The 15 new compositions leave every original eye and mouth ink pixel unchanged. No weapon introduces opaque pixels at a sprite-canvas edge; no placement reports clipping.

The accepted sword is preserved as supplied. It retains its pre-existing 33 changed source pixels at the outer mouth edge (about 1% of mouth ink at the 3× working resolution); this is recorded as the accepted baseline, not attributed to the new set.

## Visual review

- Dao and katana now meet the same front-paw curve. Their blades have distinct broad-belly and narrow-swept silhouettes; no floating grip remains visible at native size.
- The bowstring reads as a subordinate thin line. The open gap between string and limbs survives the 48 px icon render.
- Axe, staff, greatsword, star wand, and hammer were rechecked after moving their heads away from the face. Both eyes and the mouth remain intact in all 15 new units.
- Flask, open book, firearm, crossbow, and cannon retain readable functional shapes at 128 × 120 unit size and 48 × 48 icon size. The cannon is supported by its carriage and meets the forward paw.
- Steel, wood, brass, and magical accents use broad flat material regions. Weapon silhouettes remain individually recognizable across the set.

## Native verification

The disposable [review_weapons.gd](native/review_weapons.gd) fixture loaded all 16 RGBA unit PNGs at 768 × 720 and all 16 RGBA icon PNGs at 48 × 48. Godot resized units to 128 × 120 using its native Lanczos operation, uploaded the images to `ImageTexture`, and rendered a real OpenGL viewport with Godot 4.7.2. The offscreen window was hidden.

The resulting [native screenshot](native/review_godot_preview.png) was opened and visually inspected. Runtime status: `WEAPON_ROLLOUT_NATIVE_REVIEW 16/16 []`. Geometry and face measurements are recorded in [independent-qa.json](independent-qa.json).

The engine emitted startup notices about the restricted user shader-cache directory and system root certificate store. Neither affected image loading, texture creation, resizing, or viewport capture; the fixture reported no failed asset checks.
