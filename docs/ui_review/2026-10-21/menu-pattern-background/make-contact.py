from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parent
items = [
    ("Shop - blue", "shop-restored"),
    ("Hero - mint", "hero"),
    ("Troops - sage", "troops"),
    ("Summon - violet", "summon"),
    ("Castle - stone green", "battle-castle"),
    ("Patrol - leaf green", "battle-patrol"),
    ("Events - rose", "battle-events"),
    ("Profile - blue green", "battle-profile"),
    ("Settings - slate blue", "battle-settings"),
]
sheet = Image.new("RGB", (1128, 2064), "#eee8dd")
draw = ImageDraw.Draw(sheet)
font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 18)
for i, (label, filename) in enumerate(items):
    x = 12 + (i % 3) * 376
    y = 12 + (i // 3) * 688
    draw.text((x + 3, y + 2), label, fill="#493c2c", font=font)
    image = Image.open(root / f"{filename}_360x640.png").convert("RGB")
    sheet.paste(image, (x, y + 32))
sheet.save(root / "menu-contexts-contact.png")
