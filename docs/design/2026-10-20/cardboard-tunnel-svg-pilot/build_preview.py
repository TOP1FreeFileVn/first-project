"""Export a small looping preview from the actual Godot pilot captures."""
from pathlib import Path
import argparse
import json
from PIL import Image, ImageDraw, ImageFont

parser = argparse.ArgumentParser()
parser.add_argument('--bed', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parent
if args.bed:
    root = root / 'bed-preview'
gif_name = 'bed-demo.gif' if args.bed else 'tunnel-demo.gif'
files = sorted((root / 'capture').glob('frame_*.png'))
assert len(files) == 230, len(files)
palette = Image.open(files[180]).convert('RGB').resize((880, 608)).quantize(colors=192)
frames = []
for path in files:
    frame = Image.open(path).convert('RGB').resize((880, 608), Image.Resampling.LANCZOS)
    frames.append(frame.quantize(palette=palette, dither=Image.Dither.NONE))
frames[0].save(root / gif_name, save_all=True, append_images=frames[1:], duration=100, loop=0, disposal=1, optimize=True)

board = Image.new('RGB', (1100, 850), '#e9efdf')
draw = ImageDraw.Draw(board)
heading = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf', 24)
label = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 20)
title = 'KHAY NGHỈ SVG · MÈO LUÔN HIỆN MẶT TRƯỚC' if args.bed else 'ỐNG CHUI SVG · MÈO LUÔN HIỆN MẶT TRƯỚC'
draw.text((24, 18), title, font=heading, fill='#583f21')
shots = [(20, '1. Đi phía trước'), (75, '2. Đi phía sau vật thể'), (163, '3. Đi vào · giữ mặt trước'), (180, '4. Nghỉ trên đệm' if args.bed else '4. Ngồi trong ống')]
for i, (frame_number, caption) in enumerate(shots):
    x = 18 + (i % 2) * 550
    y = 60 + (i // 2) * 390
    image = Image.open(files[frame_number]).convert('RGB')
    crop = image.crop((28, 180, 732, 610)).resize((526, 321), Image.Resampling.LANCZOS)
    board.paste(crop, (x, y))
    draw.text((x + 6, y + 332), caption, font=label, fill='#583f21')
board.save(root / 'interaction-review.png')
print(json.dumps({'gif': gif_name, 'frames': len(frames), 'duration_seconds': 23, 'contact_sheet': 'interaction-review.png', 'gif_bytes': (root/gif_name).stat().st_size}))
