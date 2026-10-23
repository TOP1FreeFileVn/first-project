"""Place the two review icons in the existing paperboard UI without replacing production art."""
from pathlib import Path
import base64
import json
import runpy

HERE = Path(__file__).resolve().parent
DEMO = HERE.parent / 'equipment-ui-demos'
existing = runpy.run_path(str(DEMO / 'build.py'))
source = (DEMO / 'demo.template.html').read_text(encoding='utf-8')
assets = existing['assets'].copy()
replacements = existing['replacements'].copy()
replacements['__ASSETS__'] = json.dumps(assets, ensure_ascii=False)
for token, value in replacements.items():
    source = source.replace(token, value)
source = source.replace('id="cat-equipment-demos"', 'id="cat-equipment-demos" aria-label="Hai kiếm chéo · nhãn lực chiến tăng tương phản"')
output = HERE / 'power-icon-demos.html'
output.write_text(source, encoding='utf-8')
assert output.stat().st_size < 1_000_000
print(f'{output}: {output.stat().st_size:,} bytes')
