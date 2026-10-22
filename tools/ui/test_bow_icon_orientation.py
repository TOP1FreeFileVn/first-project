"""Regression for the bow's *directed aim*, not its undirected string axis.

The previous icon passed the -45 degree axis metadata check while its actual
bow belly faced down-right. Locate the existing string ink and grip paint in
each exported PNG independently of transform metadata; the grip must lie
up-left of the string, per the user's bow-only clarification. Other weapons
retain their existing direction. This is a check of the installed v4
palette. Update the semantic paint locators when replacing that source art.
"""
from pathlib import Path
import math
import unittest

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]


def paint_center(image: Image.Image, color: tuple[int, int, int]) -> np.ndarray:
    pixels = np.asarray(image.convert("RGBA"))
    distance = np.linalg.norm(pixels[:, :, :3].astype(float) - color, axis=2)
    y, x = np.where((distance < 18) & (pixels[:, :, 3] > 160))
    if not len(x):
        raise AssertionError(f"Missing expected semantic paint {color}")
    return np.array([x.mean(), y.mean()])


class BowIconDirectionTest(unittest.TestCase):
    def test_actual_bow_paint_faces_up_left_at_all_export_sizes(self):
        # The single existing +10% paint pass gives these string/grip colors.
        string_ink = (152, 108, 70)
        coral_grip = (254, 132, 100)
        for size in (32, 48, 64, 96, 256):
            with self.subTest(size=size):
                suffix = "" if size == 256 else f"_{size}"
                path = ROOT / f"game/ui/art/icon_hero_w_cung{suffix}.png"
                image = Image.open(path).convert("RGBA")
                self.assertEqual(image.size, (size, size))
                direction = paint_center(image, coral_grip) - paint_center(image, string_ink)
                self.assertLess(direction[0], 0, "Grip/belly must be left of the string")
                self.assertLess(direction[1], 0, "Grip/belly must be above the string")
                # At32/48px resampling mixes the narrow string with nearby ink;
                # retain a tolerant quadrant/diagonal check rather than exact
                # source-angle equality. The former down-right bow fails it.
                angle = math.degrees(math.atan2(direction[1], direction[0]))
                self.assertLess(abs(angle + 135), 20, f"Painted firing direction {angle:.2f} degrees")
                left, top, right, bottom = image.getchannel("A").getbbox()
                inset = math.ceil(size * .08)
                self.assertGreaterEqual(min(left, top, size - right, size - bottom), inset)


if __name__ == "__main__":
    unittest.main()
