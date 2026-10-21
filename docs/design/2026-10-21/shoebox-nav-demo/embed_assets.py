"""Embed only the game's art/font into the self-contained review fragment."""
from pathlib import Path
from PIL import Image, ImageFilter
from io import BytesIO
import base64
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OLD = HERE.parent / 'bottom-nav-options'
CAPTURES = ROOT / 'docs/ui_review/2026-10-21/menu-frame-rollout'

def uri(data, mime):
    return 'data:' + mime + ';base64,' + base64.b64encode(data).decode('ascii')

def webp(image, quality=85):
    output = BytesIO()
    image.save(output, 'WEBP', quality=quality, method=6)
    return uri(output.getvalue(), 'image/webp')

fragment = HERE / 'shoebox-nav.html'
source = fragment.read_text(encoding='utf-8')
font_rule = re.search(r'@font-face\{[^\n]+', source).group(0)
source = re.sub(r'<style>[\s\S]*?</style>',
                lambda _: '<style>\n' + font_rule + '\n' + (HERE / 'review.css').read_text(encoding='utf-8') + '</style>', source)
source = source.replace('<span class="shoe-lid"><span></span></span>', '')
source = source.replace('hộp giày', 'hộp carton hai cánh')
motion = json.loads((HERE / 'art-v3/carton-motion.json').read_text(encoding='utf-8'))
for constant, key in [('closed', 'left_closed'), ('opened', 'left_open')]:
    source = re.sub(r'  const ' + constant + r'=\[.*?\];',
                    lambda _, c=constant, k=key: '  const ' + c + '=' + json.dumps(motion[k], separators=(',', ':')) + ';', source)
assets = {}
for name in ['shop', 'hero', 'battle', 'troops', 'summon']:
    icon = Image.open(OLD / f'balanced-{name}.png').convert('RGBA')
    icon.thumbnail((160, 160), Image.Resampling.LANCZOS)
    assets[f'@@ICON_{name.upper()}@@'] = webp(icon, 95)
    path = OLD / f'background-{name}.png'
    if path.exists():
        background = Image.open(path).convert('RGB').resize((360, 640))
    else:
        background = Image.open(CAPTURES / f'{name}_360x640.png').convert('RGB')
        band = background.crop((0, 535, 360, 552)).resize((360, 105))
        background.paste(band.filter(ImageFilter.GaussianBlur(14)), (0, 535))
    if name == 'shop':
        # The old source has a blurred fragment of the previous navigation at y550.
        # Keep this empty stage beneath the shop cards clean for the new boxes.
        background.paste('#4e78a3', (0, 538, 360, 640))
    background.save(HERE / f'clean-{name}.png')
    page_uri = webp(background)
    assets[f'@@PAGE_{name.upper()}@@'] = page_uri
    # Also refresh an already embedded review after an art refinement.
    index = ['shop', 'hero', 'battle', 'troops', 'summon'].index(name)
    source = re.sub(r'(<img data-page="' + str(index) + r'"[^>]*?src=")[^"]*(")',
                    lambda match: match.group(1) + page_uri + match.group(2), source)
assets['@@FONT@@'] = uri((ROOT / 'game/ui/fonts/PaytoneOne-Regular.ttf').read_bytes(), 'font/ttf')
for label, name in [('FRONT', 'box-front'), ('INSIDE', 'box-inside'), ('SHELF', 'nav-shelf')]:
    assets[f'@@V3_{label}@@'] = uri((HERE / 'art-v3' / f'{name}.svg').read_bytes(), 'image/svg+xml')
for placeholder, value in assets.items():
    source = source.replace(placeholder, value)
assert '@@' not in source, 'Unresolved embedded art'
assert len(source.encode('utf-8')) < 1_000_000
fragment.write_text(source, encoding='utf-8')
print(f'Embedded {len(assets)} resources; fragment {fragment.stat().st_size:,} bytes')
