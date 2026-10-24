"""Arrange unmodified native screenshots for design approval."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
CAPTURES = HERE / "captures"
FONT = ROOT / "game/ui/fonts/PaytoneOne-Regular.ttf"
OPTIONS = [
    ("a-reference", "A · Sát mẫu"),
    ("b-paper", "B · Ô thoại giấy"),
    ("c-floating", "C · Ô thoại nổi"),
]


def compare_cards():
    cards = [Image.open(CAPTURES / f"{stem}-450x800-card.png").convert("RGB") for stem, _ in OPTIONS]
    padding, label_h, gap = 20, 42, 20
    width = max(card.width for card in cards) + 2 * padding
    height = 2 * padding + sum(card.height + label_h for card in cards) + gap * 2
    board = Image.new("RGB", (width, height), "#f1ebde")
    draw = ImageDraw.Draw(board)
    font = ImageFont.truetype(str(FONT), 24)
    y = padding
    for card, (_, label) in zip(cards, OPTIONS):
        draw.text((padding, y + 2), label, fill="#443629", font=font)
        y += label_h
        board.paste(card, (padding, y))
        y += card.height + gap
    board.save(HERE / "compare-cards.png")


def compare_screens():
    screens = [Image.open(CAPTURES / f"{stem}-360x640.png").convert("RGB") for stem, _ in OPTIONS]
    padding, label_h, gap = 20, 44, 20
    board = Image.new("RGB", (2 * padding + sum(screen.width for screen in screens) + gap * 2,
                               2 * padding + label_h + 640), "#f1ebde")
    draw = ImageDraw.Draw(board)
    font = ImageFont.truetype(str(FONT), 24)
    x = padding
    for screen, (_, label) in zip(screens, OPTIONS):
        draw.text((x, padding + 2), label, fill="#443629", font=font)
        board.paste(screen, (x, padding + label_h))
        x += screen.width + gap
    board.save(HERE / "compare-screens.png")


if __name__ == "__main__":
    compare_cards()
    compare_screens()
    print("Wrote compare-cards.png and compare-screens.png")
