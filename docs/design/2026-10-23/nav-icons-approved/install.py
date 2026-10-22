"""Install the selected icons after native render, preserving existing nav assets."""
from pathlib import Path
from PIL import Image,ImageChops
import hashlib,json,shutil,importlib.util

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
TARGET=ROOT/'game/ui/skin/carton_nav'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
crop=(46,38,466,470)
baseline=ROOT/'docs/design/2026-10-21/bottom-nav-options/balanced-shop.png'
old=Image.open(baseline).convert('RGBA')
rerender=Image.open(HERE/'shop-original-full.png').convert('RGBA').crop(crop)
fresh=Image.open(HERE/'shop-fish-full.png').convert('RGBA').crop(crop)
assert ImageChops.difference(old,rerender).convert('RGB').getbbox() is None,'Original shop re-render must match before installation'
diff=ImageChops.difference(old,fresh).convert('RGB').getbbox()
assert diff and diff[0]>=100 and diff[1]>=280 and diff[2]<=320 and diff[3]<=400,diff
# The only changed shop pixels must stay inside the old sign board region.
fresh.save(HERE/'shop.png')
for name in ['shop','hero']:
    before=HERE/f'{name}-before.png'
    if not before.exists():shutil.copyfile(TARGET/f'{name}.png',before)
unchanged={name:sha(TARGET/name) for name in ['battle.png','troops.svg','summon.svg']}
shutil.copyfile(HERE/'shop.png',TARGET/'shop.png')
shutil.copyfile(HERE/'hero.png',TARGET/'hero.png')
assert all(sha(TARGET/name)==digest for name,digest in unchanged.items())
# Refresh only the two selected tab families; do not regenerate the whole skin.
spec=importlib.util.spec_from_file_location('_approved_nav_skin',ROOT/'tools/ui/make_svgs.py')
skin=importlib.util.module_from_spec(spec)
spec.loader.exec_module(skin)
shop=skin.make_icons()['tab_shop']
variants=[]
for size in skin.ICON_SIZES:
    suffix='' if size==128 else f'_{size}'
    for name,source in [('shop',shop.flat_svg(size)),('cat',skin.approved_tab_hero_svg(size))]:
        target=ROOT/'game/ui/skin'/f'icon_tab_{name}{suffix}.svg'
        target.write_text(source,encoding='utf-8')
        variants.append(str(target.relative_to(ROOT)))
manifest={
  'approved_selection':'C-hero helmet; original battle; original shop with blue fish on wood',
  'latest_clarification':'Remove the gold sign board on the shop, not the helmet nasal guard.',
  'hero_fixes':['material fills drawn before silhouette ink','right material plane meets the silhouette without a pale sliver','compact nasal guard'],
  'shop_original_rerender_matches_pixels':True,'shop_changed_bbox':diff,
  'shop_fish_profile':{'fill':'#8fdce6','outline':1.8,'logical_width':43,'logical_height':24,'eye_radius':1.4},
  'global_tab_variants':variants,
  'unchanged_assets_sha256':unchanged,
  'installed':{n:{'source':f'docs/design/2026-10-23/nav-icons-approved/{n}-source.svg','sha256':sha(TARGET/f'{n}.png')}for n in ['shop','hero']}
}
(HERE/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(f'Installed selected hero/shop PNGs and {len(variants)} shared tab SVGs. Shop changes confined to {diff}. Battle, troop and summon preserved.')
