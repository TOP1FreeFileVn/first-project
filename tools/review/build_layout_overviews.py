"""Arrange native Godot captures for the lobby and chest layout reviews."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2] / "docs/ui_review/2026-10-19"
TITLE = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 24)
CAPTION = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 18)
SMALL = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 16)
INK = "#583f21"


def paste_native(canvas, folder, filename, at, expected=(360, 640)):
    shot = Image.open(ROOT / folder / filename).convert("RGB")
    if shot.size != expected:
        raise ValueError(f"Unexpected native size: {filename}: {shot.size}")
    canvas.paste(shot, at)


def chest_overview():
    canvas = Image.new("RGB", (1120, 756), "#e9dfcd")
    draw = ImageDraw.Draw(canvas)
    draw.text((12, 10), "Mở rương · nhận thưởng cân giữa", fill=INK, font=TITLE)
    cases = [
        (12, "fast_two_360x640.png", "2 thẻ · thẻ lớn, cụm gọn"),
        (380, "skip_eight_360x640.png", "8 thẻ · vừa màn hình"),
        (748, "many_new_scrolled_360x640.png", "16 thẻ · cuộn đến cuối"),
    ]
    for x, filename, caption in cases:
        draw.text((x, 47), caption, fill=INK, font=CAPTION)
        paste_native(canvas, "chest-layout", filename, (x, 76))
    draw.text((12, 728), "Ảnh Godot gốc 360 × 640 · nút luôn hiện · đã thử cuộn và bấm thật", fill=INK, font=SMALL)
    canvas.save(ROOT / "chest-layout/overview.png")


def lobby_overview():
    canvas = Image.new("RGB", (760, 908), "#e9dfcd")
    draw = ImageDraw.Draw(canvas)
    draw.text((12, 10), "Sảnh · header, thẻ sự kiện và nút trận chiến", fill=INK, font=TITLE)
    for x, filename, caption in [
        (12, "before/lobby_360x640.png", "Trước"),
        (388, "normal_lobby_360x640.png", "Sau"),
    ]:
        draw.text((x, 47), caption, fill=INK, font=CAPTION)
        paste_native(canvas, "lobby-layout", filename, (x, 76))
    draw.text((20, 734), "Header số dư lớn + CHEAT · ảnh cắt gốc 720 px", fill=INK, font=CAPTION)
    paste_native(canvas, "lobby-layout", "stress_lobby_720x1280_header.png", (20, 772), (720, 112))
    canvas.save(ROOT / "lobby-layout/overview.png")


if __name__ == "__main__":
    chest_overview()
    lobby_overview()
