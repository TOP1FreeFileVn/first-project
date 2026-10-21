from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

base = Path(__file__).parent
manifest = json.loads((base / "manifest.json").read_text(encoding="utf-8"))
font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 18)
title_font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 24)

for kind in ("tunnel", "bed"):
    captures = [item for item in manifest["captures"] if item["kind"] == kind]
    sheet = Image.new("RGB", (1240, 1080), "#F2E9DA")
    draw = ImageDraw.Draw(sheet)
    draw.text((18, 12), f"Production {kind} / front-only resident / 20 Hz geometry review", font=title_font, fill="#433A2B")
    for index, capture in enumerate(captures):
        x, y = 10 + (index % 4) * 310, 52 + (index // 4) * 340
        sheet.paste(Image.open(base / capture["file"]).convert("RGB"), (x, y))
        phase = capture["local_phase"]
        if phase == 0 or phase >= 25:
            label = "rest inside"
        elif phase < 10:
            label = "exit"
        elif phase < 13:
            label = "walk outside"
        elif phase < 23:
            label = "approach"
        else:
            label = "enter"
        draw.text((x + 4, y + 305), f"Phase {phase:05.2f}s | {label}", font=font, fill="#433A2B")
    sheet.save(base / f"{kind}-contact-sheet.png")
    print(base / f"{kind}-contact-sheet.png")
