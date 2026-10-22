"""Build approved B menu frames without changing shared combat or rarity skin.

Run from the project root: python -I tools/ui/make_menu_panels.py
Board 128x136: L48/T48/R48/B48 slices in Ui.menu_panel_style.
Well 64x64: 24px slices, a quiet inset with no highlight or extra inner rim.
"""

from pathlib import Path


OUT = Path(__file__).resolve().parents[2] / "game/ui/skin/menu"
LINE = "#583f21"
# face, frame, restrained inner highlight; matched to the scrolling menu colors.
PALETTES = {
    "shop": ("#aac9d7", "#7ca0b4", "#cde1e8"),
    "hero": ("#b6cec4", "#8baa9b", "#d8e5da"),
    "troops": ("#c5d3aa", "#97ad7c", "#e0e7c9"),
    "castle": ("#b7cac4", "#88a49b", "#d5e0d7"),
    "patrol": ("#d0dbb8", "#92a777", "#dce5c5"),
    "events": ("#d4bbc4", "#ae8d9d", "#e8d6db"),
    "summon": ("#cec1d9", "#a38daf", "#e6ddeb"),
    "login": ("#d9c9a9", "#b39b75", "#eee3c9"),
    "quests": ("#b8d2d8", "#89aeb8", "#d8e6e9"),
    "profile": ("#b6cec4", "#8baa9b", "#d8e5da"),
    "settings": ("#b8ccd8", "#8ca8b8", "#dce6eb"),
}
SHOP_OFFERS = {
    "featured": ("#e7ca91", "#bd955e", ""),
    "wood": ("#bfd7ab", "#8daa7a", ""),
    "silver": ("#b2d4df", "#86aebd", ""),
}


def mix(a: str, b: str, amount: float) -> str:
    channels = [
        round(int(a[i:i + 2], 16) * (1 - amount) + int(b[i:i + 2], 16) * amount)
        for i in (1, 3, 5)
    ]
    return "#" + "".join(f"{channel:02x}" for channel in channels)


def rect(x, y, w, h, radius, fill, extra=""):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" '
            f'rx="{radius}" ry="{radius}" fill="{fill}"{extra}/>')


def svg(w, h, body, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}">' + (f"<defs>{defs}</defs>" if defs else "")
            + body + "</svg>\n")


def board(face, frame, highlight):
    # The full canvas is one flat frame; a second lower layer would read as a
    # raised button lip when the panel is stretched through its nine-slice.
    body = rect(0, 0, 128, 136, 44, LINE)
    body += rect(6, 6, 116, 124, 38, face)
    return svg(128, 136, body)


def well(face, frame, highlight):
    inset = mix(face, frame, 0.24)
    body = rect(0, 0, 64, 64, 22, frame)
    body += rect(2, 2, 60, 60, 20, inset)
    return svg(64, 64, body)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for context, palette in PALETTES.items():
        for kind, render in (("board", board), ("well", well)):
            (OUT / f"{context}_{kind}.svg").write_text(render(*palette), encoding="utf-8", newline="\n")
    (OUT / "patrol_scene.svg").write_text(board("#91ac65", "#7e9467", ""), encoding="utf-8", newline="\n")
    for offer, palette in SHOP_OFFERS.items():
        (OUT / f"shop_{offer}.svg").write_text(board(*palette), encoding="utf-8", newline="\n")
    print(f"Built {len(PALETTES) * 2 + 1 + len(SHOP_OFFERS)} menu panel SVGs in {OUT}")


if __name__ == "__main__":
    main()
