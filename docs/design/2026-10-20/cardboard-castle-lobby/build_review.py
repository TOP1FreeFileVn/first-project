"""Review boards only: GPT Image 2.5 concepts composited with current game UI.

Raw generated images stay unchanged. Keys remove the mint sheet and optional
green lawn for concept compositing; these cutouts are not production sprites.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
INK = '#583f21'
BG = '#e5eee5'
FONT = Path('C:/Windows/Fonts/arial.ttf')
BOLD = Path('C:/Windows/Fonts/arialbd.ttf')
OUT = ROOT / 'processed'
OUT.mkdir(exist_ok=True)

def font(size, bold=False):
    return ImageFont.truetype(str(BOLD if bold else FONT), size)

def text(draw, xy, value, size=24, bold=False, fill=INK, anchor=None):
    draw.text(xy, value, font=font(size, bold), fill=fill, anchor=anchor)

def cutout(im, remove_lawn=False):
    p = np.asarray(im.convert('RGB')).astype(float)
    r, g, b = p[..., 0], p[..., 1], p[..., 2]
    # Background is pale mint; no subject colors share this combination.
    mint = (r > 175) & (g > 190) & (b > 175) & (g > r) & (g > b+3) & (b > r - 13)
    alpha = np.where(mint, 0, 255).astype('uint8')
    if remove_lawn:
        green = (g > r * 1.035) & (g > b * 1.15)
        alpha[green] = 0
    rgba = im.convert('RGBA')
    rgba.putalpha(Image.fromarray(alpha))
    return rgba

def fit_alpha(image, width, height):
    box = image.getbbox()
    image = image.crop(box)
    factor = min(width / image.width, height / image.height)
    return image.resize((round(image.width * factor), round(image.height * factor)), Image.Resampling.LANCZOS)

raw_dirs = Image.open(ROOT / 'directions-raw.png')
directions = []
for i in range(3):
    asset = cutout(raw_dirs.crop((i*512, 120, (i+1)*512, 810)))
    asset.save(OUT / f'direction-{chr(97+i)}.png')
    directions.append(asset)

board = Image.new('RGB', (1600, 940), BG)
d = ImageDraw.Draw(board)
text(d, (54, 38), 'LÂU ĐÀI HỘP GIẤY', 44, True)
text(d, (56, 96), 'Ba hướng tạo hình cho sảnh mèo', 25)
names = ['A · Pháo đài hộp giấy', 'B · Nhà mèo khổng lồ', 'C · Tháp hộp xếp tầng']
notes = ['Cân đối · rõ dáng lâu đài · dễ mở rộng', 'Dáng đầu mèo lớn · gần gũi · vui mắt', 'Lệch tầng có chủ ý · nghịch ngợm · nhiều góc chơi']
for i, asset in enumerate(directions):
    x = 40 + i*520
    d.rounded_rectangle((x, 153, x+500, 850), radius=24, fill='#f1f4e9')
    art = fit_alpha(asset, 475, 570)
    board.paste(art, (x+(500-art.width)//2, 205+(570-art.height)//2), art)
    text(d, (x+22, 785), names[i], 26, True)
    text(d, (x+22, 822), notes[i], 17)
text(d, (56, 892), 'Bản thảo duyệt tạo hình · hướng A được phát triển thành chuỗi nâng cấp ở trang kế tiếp', 22)
board.save(ROOT / 'directions-review.png')

raw = Image.open(ROOT / 'progression-raw.png')
regions = [(0,40,768,465), (768,40,1536,465), (0,470,744,1024), (768,470,1536,1024)]
# Anchor = bottom-center of the ORIGINAL entrance, measured on the raw sheet.
anchors = [(370,374), (1115,374), (377,885), (1114,895)]
stages = []
castles = []
for i, (region, anchor) in enumerate(zip(regions, anchors), 1):
    image = raw.crop(region)
    stage = cutout(image)
    castle = cutout(image, remove_lawn=True)
    stage.save(OUT / f'stage-{i}-lawn.png')
    castle.save(OUT / f'stage-{i}-castle.png')
    stages.append(stage)
    castles.append((castle, (anchor[0]-region[0], anchor[1]-region[1])))

names = ['01 · Ổ hộp đầu tiên', '02 · Pháo đài mèo', '03 · Thành hai tầng', '04 · Vương quốc hộp giấy']
notes = ['Hộp gốc, cổng mèo, băng keo và cờ cá.', 'Thêm hai tháp thấp, mở rộng hai bên.', 'Giữ cổng cũ; thêm tầng giữa và ban công.', 'Thêm sân, cầu nối, tháp phụ và kho cá.']
board = Image.new('RGB', (1600, 1370), BG)
d = ImageDraw.Draw(board)
text(d, (54, 36), 'CÀNG NÂNG CẤP, CÀNG ĐỦ ĐẦY', 40, True)
text(d, (56, 94), 'Cùng một lâu đài lớn dần bằng các phần mới — giữ nhận diện hộp ban đầu', 24)
for i, (image, anchor) in enumerate(castles):
    col, row = i%2, i//2
    x, y = 40+col*780, 151+row*572
    d.rounded_rectangle((x, y, x+740, y+548), radius=24, fill='#f1f4e9')
    # Same scale and doorway anchor, so the additions can be compared honestly.
    art = stages[i].resize((round(stages[i].width*.86), round(stages[i].height*.86)), Image.Resampling.LANCZOS)
    target = (x+355, y+390)
    pos = (round(target[0]-anchor[0]*.86), round(target[1]-anchor[1]*.86))
    board.paste(art, pos, art)
    text(d, (x+26, y+448), names[i], 29, True)
    text(d, (x+26, y+491), notes[i], 22)
text(d, (56, 1321), 'Bốn nấc tạo hình đề xuất; chưa gắn vào cấp hoặc chi phí nâng cấp trong game.', 22)
board.save(ROOT / 'upgrade-review.png')

empty = Image.open(ROOT / 'empty-lobby.png').convert('RGBA')
base = Image.open(ROOT / 'base-island.png').convert('RGBA').resize((528,377), Image.Resampling.LANCZOS)
hero = Image.open(ROOT / 'hero-cat.png').convert('RGBA')
hero = hero.resize((163,153), Image.Resampling.LANCZOS)
screens = []
for i, (castle, anchor) in enumerate(castles):
    screen = empty.copy()
    screen.alpha_composite(base, (96,385))
    scale = .52
    art = castle.resize((round(castle.width*scale), round(castle.height*scale)), Image.Resampling.LANCZOS)
    pos = (round(390-anchor[0]*scale), round(579-anchor[1]*scale))
    screen.alpha_composite(art, pos)
    screen.alpha_composite(hero, (151,476))
    screen.convert('RGB').save(ROOT / f'lobby-stage-{i+1}.png')
    screens.append(screen)

board = Image.new('RGB', (1600, 876), BG)
d = ImageDraw.Draw(board)
text(d, (40, 25), 'THỬ TRONG SẢNH HIỆN TẠI', 35, True)
text(d, (40, 77), 'Giữ UI để kiểm tra tỷ lệ; cùng góc máy và vị trí cửa qua cả bốn nấc', 23)
for i, screen in enumerate(screens):
    x = 32 + i*392
    thumb = screen.resize((360,640), Image.Resampling.LANCZOS)
    board.paste(thumb, (x,135))
    text(d, (x+180, 805), names[i], 21, True, anchor='mm')
text(d, (40, 844), 'Mockup ghép để duyệt · tranh concept chưa phải sprite hoàn thiện', 20)
board.save(ROOT / 'lobby-upgrades-review.png')

(ROOT / 'generation-manifest.json').write_text(json.dumps({
    'purpose':'Approval concepts only; production game unchanged',
    'route':'Figma generate_image', 'model':'gpt-image-2.5-sunburst',
    'file_key':'2uKzqvXeOSPQqfaow6s7TU',
    'generations':[
        {'node_id':'57:2','image':'directions-raw.png','prompt':'prompts/directions.txt'},
        {'node_id':'58:2','image':'progression-raw.png','prompt':'prompts/progression.txt'}
    ],
    'composite':{'castle_scale':.52,'doorway_anchor':[390,579], 'screen':[720,1280], 'scene':'current lobby UI, native island and hero'},
    'caveat':'Generated seams and contour styles require native art cleanup after direction approval. No level thresholds or progression rules implemented.'
}, ensure_ascii=False, indent=2), encoding='utf-8')
print('Built 3 review boards and 4 lobby mockups.')
