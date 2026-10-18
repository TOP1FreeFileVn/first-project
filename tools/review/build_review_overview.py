"""Assemble annotated evidence from the 2026-10-19 runtime UI review."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/ui_review/2026-10-19"
FONT = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 17)
SMALL = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 14)
PANELS = [
    ("12_battle_fight", "1. Quân che bàn bánh răng", "Quân sống chồng lên chân dung và gear.", [(290, 755, 478, 953)]),
    ("04_troops", "2. Khung lệch / chữ nhỏ", "Khung mất lề phải; số thẻ chỉ 13 px.", [(24, 189, 719, 473), (155, 700, 342, 727)]),
    ("05_summon", "3. Nhịp dọc chưa cân", "CTA cao; vùng nền trống khoảng 310 px.", [(25, 836, 695, 1138)]),
    ("02_shop", "4. Tab sát đáy màn hình", "Nhãn tab kết thúc ở y=1280, đệm đáy=0.", [(6, 1244, 179, 1279)]),
]
canvas = Image.new("RGB", (760, 1440), "#f4f0e9")
draw = ImageDraw.Draw(canvas)
for index, (key, title, subtitle, boxes) in enumerate(PANELS):
    x = 10 + (index % 2) * 380
    y = 10 + (index // 2) * 720
    draw.text((x, y), title, fill="#362b25", font=FONT)
    draw.text((x, y + 25), subtitle, fill="#57483d", font=SMALL)
    screen = Image.open(OUT / "before" / f"{key}.png").convert("RGB")
    screen = screen.resize((360, 640), Image.Resampling.LANCZOS)
    mark = ImageDraw.Draw(screen)
    for box in boxes:
        mark.rectangle(tuple(round(v / 2) for v in box), outline="#ff2851", width=3)
    canvas.paste(screen, (x, y + 55))
canvas.save(OUT / "overview.png")

fixed = Image.new("RGB", (760, 1440), "#f4f0e9")
fixed_draw = ImageDraw.Draw(fixed)
for index, (key, title, subtitle) in enumerate([
    ("12_battle_fight", "Bàn bánh răng mới", "Quân ở trên tường; bàn nền phẳng, nét nâu."),
    ("04_troops", "Đội hình và thẻ lính", "Lề đều 24 px; tên, cấp và số thẻ rõ hơn."),
    ("05_summon", "Triệu hồi", "Banner giãn cao; nút chính gần vùng dưới."),
    ("02_shop", "Cửa hàng và thanh tab", "Nội dung giãn đều; nhãn tab cách đáy 20 px."),
]):
    x = 10 + index % 2 * 380
    y = 10 + index // 2 * 720
    fixed_draw.text((x, y), title, fill="#362b25", font=FONT)
    fixed_draw.text((x, y + 25), subtitle, fill="#57483d", font=SMALL)
    screen = Image.open(OUT / "screens" / f"{key}.png").convert("RGB")
    fixed.paste(screen.resize((360, 640), Image.Resampling.LANCZOS), (x, y + 55))
fixed.save(OUT / "fixed_overview.png")

comparison = Image.new("RGB", (1440, 620), "#f4f0e9")
comparison_draw = ImageDraw.Draw(comparison)
for x, folder, caption in [(0, "before", "Trước"), (720, "screens", "Sau · bánh răng theo nét mèo")]:
    comparison_draw.text((x + 24, 20), caption, fill="#362b25", font=FONT)
    shot = Image.open(OUT / folder / "12_battle_fight.png").convert("RGB")
    comparison.paste(shot.crop((0, 720, 720, 1280)), (x, 60))
comparison.save(OUT / "gear_before_after.png")

refresh = Image.new("RGB", (1140, 720), "#f4f0e9")
refresh_draw = ImageDraw.Draw(refresh)
for index, (key, title, subtitle) in enumerate([
    ("01_lobby", "Sảnh · thành mèo mới", "Đảo và kiến trúc cùng bảng màu của mèo."),
    ("12_battle_fight", "Bản đồ · tường · bánh răng", "Cảnh phẳng, trung tâm yên để đọc trận đấu."),
    ("13_castle", "Trang Thành", "Dùng chung art thành với sảnh và tường."),
]):
    x = 10 + index * 380
    refresh_draw.text((x, 10), title, fill="#362b25", font=FONT)
    refresh_draw.text((x, 35), subtitle, fill="#57483d", font=SMALL)
    screen = Image.open(OUT / "screens" / f"{key}.png").convert("RGB")
    refresh.paste(screen.resize((360, 640), Image.Resampling.LANCZOS), (x, 65))
refresh.save(OUT / "art_refresh_overview.png")
