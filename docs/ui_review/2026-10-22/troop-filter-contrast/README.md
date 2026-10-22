# Troop filter contrast and caption alignment

The original button artwork and Paytone One font remain in use. Filter captions
now use dark brown #39291c in normal, hover, pressed, hover-pressed and focus
states. Contrast is 5.02:1 against the blue face (#6d9edb) and 10.33:1 against
the yellow face (#f5de73).

Native button text is centered horizontally. The vertical content margins use
each caption's shaped glyph bounds, including Vietnamese accents, to center it
on the raised face rather than the button's lower lip. The pressed margins move
the caption down 7 logical pixels with the original artwork.

Four native captures cover normal 450x800 / 360x640, held press and a selected
rarity. Real pointer input held the button with its dark caption, then selected
the common rarity on release. The temporary runner lives under output, loads
the production Home directly and disables persistence and sound. Geometry is
recorded in geometry.json. No parser or runtime errors occurred; stderr contains
the existing Windows certificate-store startup message.
