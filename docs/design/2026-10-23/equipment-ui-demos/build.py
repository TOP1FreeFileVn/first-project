"""Embed the unchanged production art in the review-only equipment UI demos."""
from pathlib import Path
from io import BytesIO
import base64
import json
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]

def data(path, size=None):
    path = ROOT / path
    if size:
        image = Image.open(path).convert('RGBA')
        image.thumbnail((size, size), Image.Resampling.LANCZOS)
        output = BytesIO()
        image.save(output, format='PNG', optimize=True)
        raw, mime = output.getvalue(), 'image/png'
    else:
        raw = path.read_bytes()
        mime = 'image/svg+xml' if path.suffix == '.svg' else 'font/ttf'
    return f'data:{mime};base64,' + base64.b64encode(raw).decode()

assets = {}
for key, file in {
    'sword':'icon_hero_w_kiem.png', 'bow':'icon_hero_w_cung.png',
    'staff':'icon_hero_w_gay_phep.png', 'axe':'icon_hero_w_riu.png',
    'katana':'icon_hero_w_katana.png', 'helmet':'icon_eq_helmet.png',
    'armor':'icon_eq_armor.png', 'boots':'icon_eq_boots.png',
    'heroSword':'hero_cat_melee.png', 'heroBow':'hero_cat_ranged.png',
    'heroStaff':'hero_cat_magic.png', 'heroAxe':'hero_cat_heavy.png',
    'heroKatana':'hero_cat_katana.png',
}.items():
    assets[key] = data('game/ui/art/' + file, 340 if key.startswith('hero') else 112)
for key, file in {
    'slotWeapon':'game/ui/art/icon_slot_weapon.svg',
    'slotHelmet':'game/ui/art/icon_slot_helmet.svg',
    'slotArmor':'game/ui/art/icon_slot_armor.svg',
    'slotBoots':'game/ui/art/icon_slot_boots.svg',
    'heart':'game/ui/skin/icon_heart.svg',
    'coin':'game/ui/skin/icon_coin.svg',
    'gem':'game/ui/skin/icon_gem.svg',
    'gear':'game/ui/skin/icon_gear.svg',
    'power':'docs/design/2026-10-23/power-icons/svg/power-crossed-96.svg',
    'back':'game/ui/skin/icon_back.svg',
    'shop':'game/ui/skin/icon_tab_shop.svg',
    'castle':'game/ui/skin/icon_tab_battle.svg',
    'army':'game/ui/skin/icon_tab_army.svg',
    'summon':'game/ui/skin/icon_chest.svg',
}.items():
    assets[key] = data(file)
assets['spear'] = data('game/ui/art/icon_w_giao.png', 48)

# Exact production chrome: preserve its approved navigation art and proportions.
production = Image.open(ROOT / 'docs/design/2026-10-23/weapon-frame-options/integration/full-bag_450x800.png').convert('RGBA')
for name, box in {'gameBottom': (0, 690, 450, 800), 'gameHeader': (0, 0, 450, 66)}.items():
    png = BytesIO()
    production.crop(box).save(png, format='PNG', optimize=True)
    assets[name] = 'data:image/png;base64,' + base64.b64encode(png.getvalue()).decode()

# A flat, restrained paper grain; the construction carries the material identity.
import random
rng = random.Random(23)
grain = Image.new('RGBA', (96, 96), (0, 0, 0, 0))
pixels = grain.load()
for y in range(96):
    for x in range(96):
        alpha = rng.choice([0, 0, 0, 3, 4, 5, 7])
        pixels[x, y] = (68, 43, 22, alpha)
grain_path = HERE / 'paper-grain.png'
grain.save(grain_path, optimize=True)

html = (HERE / 'demo.template.html').read_text(encoding='utf-8')
replacements = {
    '__ASSETS__': json.dumps(assets, ensure_ascii=False),
    '__FONT__': data('game/ui/fonts/PaytoneOne-Regular.ttf'),
    '__PATTERN__': data('game/ui/skin/bg_tile.svg'),
    '__BUTTON_YELLOW__': data('game/ui/skin/btn_yellow.svg'),
    '__BUTTON_GREEN__': data('game/ui/skin/btn_green.svg'),
    '__BUTTON_RED__': data('game/ui/skin/btn_red.svg'),
    '__PAPER__': data(grain_path.relative_to(ROOT), 96),
}
for token, value in replacements.items():
    html = html.replace(token, value)
output = HERE / 'equipment-ui-demos.html'
output.write_text(html, encoding='utf-8')
assert output.stat().st_size < 1_000_000
assert '__ASSETS__' not in html
print(f'{output}: {output.stat().st_size:,} bytes')
