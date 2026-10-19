# Held-weapon composition from the user's main library

Inspected 2026-10-19. The user explicitly added [Figma page 3443:2](https://www.figma.com/design/wMtwWaYIiKUchUdq5YdTm5?node-id=3443-2), **Asset chính · Kho PNG**, to the weapon design references. This source supplies direct medieval/fantasy character-held equipment, including sword, axe, spear, staff, bow, crossbow, greatsword, book, potion and dagger examples. Use it alongside the firearm detail study from page 3470:2.

## Evidence and coverage

Inspected the first and sixth variants of all 21 Hero groups (42 source entries, not necessarily 42 unique designs), the first sticker sheet, and six selected whole-character examples in detail. Source PNGs are indexed in `docs/asset_reference/figma_assets.json`, under `_GameProj/GameRes/Icon/Unit/Hero*/`. Original source art is 256 x 256 with transparent padding; do not compare stroke pixels across these canvases without considering visible character size.

The reproducible contact sheets, six unchanged source PNGs and source-node/hash manifest are in `docs/design/2026-10-19/weapon-redesign/reference-study/held-characters/`. Images cropped for large inspection and images resized to 128 x 128 are labeled separately. A 128 px inspection image is not evidence of the source game's runtime display size.

| Example | Image node | Observed construction / pose |
| --- | --- | --- |
| Hero2 / 1, sword | `3447:14466` | Compact blade diagonally outside the left cheek, rising from a clear circular hand. One broad pale steel facet, simple brass guard. Hand hides the grip connection. |
| Hero6 / 1, axe | `3447:14706` | Head beside shoulder, large steel crescent, broad brass attachment. Shaft passes through the visible hand; face remains readable. |
| Hero4 / 6, spear | `3447:14656` | Shaft nearly horizontal below the face, across the torso; short spearhead projects to the side. Distinct pose and proportions from an upright sword. |
| Hero8 / 6, staff | `3447:14816` | Short side-held staff; oversized purple orb with a broad flat highlight, simple supporting head and readable shaft below the hand. |
| Hero9 / 4, crossbow | `3447:14844` | Low across the abdomen, with arrow projecting sideways. Bow, stock and thin string leave broad open triangular gaps. |
| Hero16 / 6, tome | `3447:14336` | Open book below chin and to the side, supported by a visible hand. Broad pale page regions and cover/emblem establish the object. |

## What changes in the design process

**Compose the whole character and prop relationship first.** Establish the grip point, weapon direction, head position and visible fill areas before polishing an isolated inventory icon. Keep the existing game cat unchanged, using it as the placement/scale template. Do not make a large isolated asset and assume that uniform scaling plus one diagonal placement fits every role.

**Design hand occlusion deliberately.** The hand covers part of the grip or supporting edge, establishing contact. It must not consume the guard, all of the handle or the weapon's identifying feature. Plan which part is behind the hand and which part stays visible; separate rear/front layers where required by the engine.

**Use pose to identify function.** Sword beside shoulder, long spear at waist, low crossbow, short side-held staff and open supported book are distinct configurations. Adapt the pose to the current cat's anatomy and the game's camera rather than copying human limbs or costume.

**Reserve clear space for the face and functional head.** Weapons can overlap clothing or lower torso while eyes and mouth stay legible. Avoid tangencies between blade/head and cheek, helmet, ear or tail outlines. Long weapons may project to the side; check the complete sprite bounds and animation range.

**Retain broad material planes and selective accents.** Steel frequently has a large light facet, wood stays a broad warm shape, and magic equipment uses an oversized colored focal mass. The reference is not uniformly single-fill: a broad flat highlight or second plane can explain material. Avoid turning this into a blanket ban on all highlights, and avoid soft photoreal shading inconsistent with the current cats.

**Match optical line hierarchy, not a universal number.** In the small character examples, weapon silhouettes belong to the same warm contour family as the figure. Essential part boundaries and strings can be much thinner. A ring with the cat's full exterior width on every opening would destroy the crossbow and staff; design the fill/space first.

**Study families across variants.** Many Hero groups keep their weapon silhouette and pose stable while armor/headgear/cape detail increases. Do not automatically redesign or enlarge the weapon for every rarity. These are observed visual variants; their file numbers alone do not establish gameplay upgrade rules.

**Distinguish presentation layers.** Sticker variants have a white decal border and sometimes a circular badge/background; those treatments do not belong on the held sprite. The source page contains UI icons, character sprites, equipment icons, siege units, stickers and effects. Match the relevant use case.

## Review gate for the next proposal

Show the new equipment held by the unchanged current cat, side by side with the closest full-character reference and with the earlier proposal at equal apparent size. Also show the isolated item and a native-size cat thumbnail. Reject blocked face features, floating grips, lost material fills, closed negative spaces, clipped tips and a set made from one reused diagonal pose. Direct melee references now exist: consult these before extrapolating from the firearm catalogue.
