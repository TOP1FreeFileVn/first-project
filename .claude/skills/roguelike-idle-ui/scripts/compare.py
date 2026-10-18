"""Puts images side by side at the same height for a visual check.

Usage: python -I compare.py OUT.png IMG1 IMG2 [...] [--height 1100]
Put the reference first and the render after it.
"""
import sys

from PIL import Image


def main(argv):
    height = 1100
    if "--height" in argv:
        i = argv.index("--height")
        height = int(argv[i + 1])
        argv = argv[:i] + argv[i + 2:]
    out, paths = argv[0], argv[1:]
    tiles = []
    for path in paths:
        im = Image.open(path).convert("RGB")
        tiles.append(im.resize((max(1, int(im.size[0] * height / im.size[1])), height), Image.LANCZOS))
    gap = 20
    sheet = Image.new("RGB", (sum(t.size[0] for t in tiles) + gap * (len(tiles) - 1), height), (30, 30, 30))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0))
        x += t.size[0] + gap
    sheet.save(out)
    print("Saved", out)


if __name__ == "__main__":
    main(sys.argv[1:])
