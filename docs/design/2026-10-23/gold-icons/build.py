"""Three review-only gear coins beside the user's selected brilliant diamond."""
from pathlib import Path
from io import BytesIO
import base64
import json
import runpy
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
DEMO = HERE.parent / 'equipment-ui-demos'
existing = runpy.run_path(str(DEMO / 'build.py'))
assets = existing['assets'].copy()
source = (DEMO / 'demo.template.html').read_text(encoding='utf-8')
variants = (HERE / 'variants.template.html').read_text(encoding='utf-8').rstrip()
for key, slug in [('goldCoin', 'coin'), ('goldGear', 'gear'), ('goldPair', 'pair')]:
    assets[key] = 'data:image/svg+xml;base64,' + base64.b64encode((HERE / 'svg' / f'gold-{slug}-96.svg').read_bytes()).decode()
    variants = variants.replace('__GOLD_' + slug.upper() + '__', assets[key])
assets['gemBrilliant'] = 'data:image/svg+xml;base64,' + base64.b64encode((HERE.parent / 'diamond-icons/svg/diamond-brilliant-96.svg').read_bytes()).decode()
start = source.index('  <div class="eq-paper-preview')
end = source.index('\n</div>', start)
source = source[:start] + variants + source[end:]

# Clean only the two old icon footprints on the production header reference.
# Reconstruct the pill/background first; do not place new art over old art.
header = Image.open(BytesIO(base64.b64decode(assets['gameHeader'].split(',')[1]))).convert('RGBA')
original = header.copy()
header.resize((1350, 198)).save(HERE / 'header-original.png')
for bounds, footprint, inside, outside in [
    ((214, 19, 334, 48), (202, 16, 241, 56), 244, 199),
    ((73, 19, 195, 48), (64, 16, 100, 56), 102, 62),
]:
    pill = Image.new('L', header.size, 0)
    ImageDraw.Draw(pill).rounded_rectangle(bounds, radius=12, fill=255)
    x0, y0, x1, y1 = footprint
    for y in range(y0, y1):
        for x in range(x0, x1):
            header.putpixel((x, y), original.getpixel((inside if pill.getpixel((x, y)) else outside, y)))
header.save(HERE / 'header-clean.png')
png = BytesIO()
header.save(png, format='PNG', optimize=True)
assets['gameHeader'] = 'data:image/png;base64,' + base64.b64encode(png.getvalue()).decode()
source = source.replace("image('gameHeader','eq-game-header','Thanh tài nguyên hiện tại của game');", "image('gameHeader','eq-game-header','Thanh tài nguyên hiện tại của game')+image('gemBrilliant','eq-diamond-swatch','Kim cương bè đã chọn')+image(stage.dataset.gold,'eq-gold-swatch','Vàng mới');")
source = source.replace('</style>', '''#cat-equipment-demos .eq-phone[data-design="paperboard"] .eq-top{position:relative}
#cat-equipment-demos .eq-phone[data-design="paperboard"] .eq-top .eq-diamond-swatch,#cat-equipment-demos .eq-phone[data-design="paperboard"] .eq-top .eq-gold-swatch{position:absolute;top:50%;transform:translate(-50%,-50%);width:8.5%;height:64%;object-fit:contain;z-index:2;pointer-events:none}
#cat-equipment-demos .eq-phone[data-design="paperboard"] .eq-top .eq-diamond-swatch{left:48.7%}
#cat-equipment-demos .eq-phone[data-design="paperboard"] .eq-top .eq-gold-swatch{left:17.8%}
#cat-equipment-demos .gold-symbol-preview{display:flex;align-items:center;justify-content:center;gap:26px;width:min(390px,100%);height:116px;margin:0 auto;background:#dfbb87;color:#583f21;font-family:CatGame,sans-serif}
#cat-equipment-demos .gold-large{width:88px;height:88px;object-fit:contain}
#cat-equipment-demos .gold-native{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:9px;font-size:11px}
</style>''')
replacements = existing['replacements'].copy()
replacements['__ASSETS__'] = json.dumps(assets, ensure_ascii=False)
for token, value in replacements.items():
    source = source.replace(token, value)
assert '__GOLD_' not in source
output = HERE / 'gold-icon-demos.html'
output.write_text(source, encoding='utf-8')
assert output.stat().st_size < 1_000_000
print(f'{output}: {output.stat().st_size:,} bytes')
