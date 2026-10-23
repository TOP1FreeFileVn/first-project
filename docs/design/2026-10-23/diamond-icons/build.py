"""Three review-only diamond icons in the approved paperboard screen context."""
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
start = source.index('  <div class="eq-paper-preview')
end = source.index('\n</div>', start)
source = source[:start] + '''  <div class="viz-carousel viz-dotted-background" aria-label="Kim cương mới" data-previous-label="Mẫu trước" data-next-label="Mẫu tiếp">
    <section data-variant="Kim cương bè" aria-label="Kim cương bè"><div class="eq-stage" data-design="paperboard" data-gem="gemBrilliant"></div></section>
    <section data-variant="Viên thoi bo góc" aria-label="Viên thoi bo góc" hidden><div class="eq-stage" data-design="paperboard" data-gem="gemCushion"></div></section>
    <section data-variant="Pha lê ngắn" aria-label="Pha lê ngắn" hidden><div class="eq-stage" data-design="paperboard" data-gem="gemCrystal"></div></section>
  </div>''' + source[end:]
for key, slug in [('gemBrilliant', 'brilliant'), ('gemCushion', 'cushion'), ('gemCrystal', 'crystal')]:
    assets[key] = 'data:image/svg+xml;base64,' + base64.b64encode((HERE / 'svg' / f'diamond-{slug}-96.svg').read_bytes()).decode()

# The native header is a reference screenshot. Remove only the old gem footprint
# before placing a live candidate; do not stack the new icon over the old one.
header = Image.open(BytesIO(base64.b64decode(assets['gameHeader'].split(',')[1]))).convert('RGBA')
original = header.copy()
pill = Image.new('L', header.size, 0)
ImageDraw.Draw(pill).rounded_rectangle((214, 19, 334, 48), radius=12, fill=255)
for y in range(16, 56):
    for x in range(202, 241):
        header.putpixel((x, y), original.getpixel((244 if pill.getpixel((x, y)) else 199, y)))
png = BytesIO()
header.save(png, format='PNG', optimize=True)
assets['gameHeader'] = 'data:image/png;base64,' + base64.b64encode(png.getvalue()).decode()
source = source.replace("image('gameHeader','eq-game-header','Thanh tài nguyên hiện tại của game');", "image('gameHeader','eq-game-header','Thanh tài nguyên hiện tại của game')+image(stage.dataset.gem,'eq-diamond-swatch','Kim cương mới');")
source = source.replace('</style>', '''#cat-equipment-demos .eq-phone[data-design="paperboard"] .eq-top{position:relative}
#cat-equipment-demos .eq-phone[data-design="paperboard"] .eq-top .eq-diamond-swatch{position:absolute;left:48.7%;top:50%;transform:translate(-50%,-50%);width:8.5%;height:64%;object-fit:contain;z-index:2;pointer-events:none}
</style>''')
replacements = existing['replacements'].copy()
replacements['__ASSETS__'] = json.dumps(assets, ensure_ascii=False)
for token, value in replacements.items():
    source = source.replace(token, value)
output = HERE / 'diamond-icon-demos.html'
output.write_text(source, encoding='utf-8')
assert output.stat().st_size < 1_000_000
print(f'{output}: {output.stat().st_size:,} bytes')
