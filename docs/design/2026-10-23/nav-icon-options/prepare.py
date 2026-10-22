"""Fit identical paths to menu icon canvases; no raster dilation or repainting."""
from pathlib import Path
import json, re
from PIL import Image

HERE=Path(__file__).resolve().parent
(HERE/'svg').mkdir(exist_ok=True)
review={"status":"approval study; production unchanged", "fitting":[]}
for raw in sorted((HERE/'raw-png').glob('*.png')):
    bounds=Image.open(raw).convert('RGBA').getchannel('A').getbbox()
    x0,y0,x1,y1=bounds
    # One square canvas with visually equal max dimensions and a 4% safe area.
    span=max(x1-x0,y1-y0)/.92
    cx,cy=(x0+x1)/2,(y0+y1)/2
    box=f'{cx-span/2:.3f} {cy-span/2:.3f} {span:.3f} {span:.3f}'
    source=(HERE/'raw-svg'/f'{raw.stem}.svg').read_text(encoding='utf-8')
    for size in (200,96,64,44,26):
        out=re.sub(r'width="200" height="200" viewBox="0 0 200 200"',f'width="{size}" height="{size}" viewBox="{box}"',source,count=1)
        (HERE/'svg'/f'{raw.stem}-{size}.svg').write_text(out,encoding='utf-8')
    main=6.5 if raw.stem=='A-battle' else 7.5
    review['fitting'].append({"id":raw.stem,"original_bounds":bounds,"viewbox":box,
        "author_main":main,"author_secondary":4.2,
        "main_px_44":round(main*44/span,3),"secondary_px_44":round(4.2*44/span,3),
        "main_px_26":round(main*26/span,3),"secondary_px_26":round(4.2*26/span,3)})
(HERE/'review.json').write_text(json.dumps(review,ensure_ascii=False,indent=2),encoding='utf-8')
print(f'Fitted {len(review["fitting"])} icons; 5 render sizes each.')
