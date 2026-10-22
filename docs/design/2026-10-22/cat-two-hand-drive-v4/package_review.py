"""Package the Godot-rendered vector frames without changing the drawing."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
BG = '#e8ddc8'
INK = '#583f21'
font_file = ROOT / 'game/ui/fonts/PaytoneOne-Regular.ttf'
font = ImageFont.truetype(str(font_file), 19)
small = ImageFont.truetype(str(font_file), 14)
frames = []
bounds = []
for file in sorted((HERE / 'frames/png').glob('frame-*.png')):
    im = Image.open(file).convert('RGBA')
    box = im.getbbox()
    assert box and box[0] > 0 and box[1] > 0 and box[2] < 240 and box[3] < 240, (file, box)
    bounds.append({'file': file.name, 'alpha_bbox': box})
    frame = Image.new('RGB', (320, 320), BG)
    frame.paste(im, (40, 32), im)
    d = ImageDraw.Draw(frame)
    d.text((160, 294), 'Hai tay cùng nắm một cán', font=small, fill=INK, anchor='mm')
    frames.append(frame)
assert len(frames) == 24
# One shared palette prevents shimmer on the cream and ink fills.
palette_sheet = Image.new('RGB', (320 * 6, 320 * 4), BG)
for i, frame in enumerate(frames):
    palette_sheet.paste(frame, ((i % 6) * 320, (i // 6) * 320))
palette = palette_sheet.quantize(colors=128)
gif = [im.quantize(palette=palette, dither=Image.Dither.NONE) for im in frames]
gif[0].save(HERE / 'motion.gif', save_all=True, append_images=gif[1:], loop=0, duration=[120, 130] * 12, disposal=2)

review = Image.new('RGB', (1200, 560), BG)
d = ImageDraw.Draw(review)
d.text((25, 22), 'V4 · Tay mèo mập tròn, đôi chân măng cụt', font=font, fill=INK)
labels = ['Cán ở trên', 'Đẩy sang phải', 'Cán xuống dưới', 'Kéo về bên trái']
for i, label in enumerate(labels):
    im = Image.open(HERE / f'godot/pose-{i+1}-300.png').convert('RGBA')
    review.paste(im, (i * 300, 55), im)
    d.text((i * 300 + 150, 365), label, font=small, fill=INK, anchor='mm')
    im = Image.open(HERE / f'godot/pose-{i+1}-100.png').convert('RGBA')
    review.paste(im, (i * 300 + 100, 401), im)
d.text((600, 533), 'Hàng dưới: đúng kích thước ô 100 px · Render SVG bằng Godot', font=small, fill=INK, anchor='mm')
review.save(HERE / 'poses.png')

baseline = HERE.parent / 'cat-two-hand-drive-v3'
comparison = Image.new('RGB', (640, 395), BG)
d = ImageDraw.Draw(comparison)
for i, (folder, label) in enumerate([(baseline, 'V3 · Trước'), (HERE, 'V4 · Tay chân tròn')]):
    im = Image.open(folder / 'godot/pose-2-300.png').convert('RGBA')
    comparison.paste(im, (i * 320 + 10, 40), im)
    d.text((i * 320 + 160, 25), label, font=font, fill=INK, anchor='mm')
d.text((320, 369), 'Cùng kích thước đầu và đường viền · Cùng mặt đất', font=small, fill=INK, anchor='mm')
comparison.save(HERE / 'before-after.png')

(HERE / 'render-checks.json').write_text(json.dumps({'native_renderer': 'Godot 4.7.2', 'frame_count': 24, 'cycle_ms': 3000, 'all_frames_inside_canvas': True, 'bounds': bounds}, indent=2), encoding='utf-8')
print('Created motion.gif, poses.png, before-after.png and render-checks.json.')
