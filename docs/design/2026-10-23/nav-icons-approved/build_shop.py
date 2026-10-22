from pathlib import Path
import re

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
source=(HERE/'shop-original-source.svg').read_text(encoding='utf-8')
# Retain the established kiosk. The wood counter itself is the sign's support.
sign='<path d="M47 84 L81 84 Q89 84 89 92 L89 101 Q89 109 81 109 L47 109 Q39 109 39 101 L39 92 Q39 84 47 84 Z" fill="#f5c565" stroke="#583f21" stroke-width="3"/>'
assert source.count(sign)==1,'Original sign board not found'
source=source.replace(sign,'')
fish_source=(HERE/'fish-source.svg').read_text(encoding='utf-8')
fish='<g id="fish-sign">'+re.sub(r'^<svg[^>]*>|</svg>\s*$','',fish_source).strip()+'</g>'
source,n=re.subn(r'<g transform="translate\(64 99\) scale\(0\.43\)">.*?</g>',fish,source)
assert n==1,'Original paw mark not found'
(HERE/'shop-source.svg').write_text(source,encoding='utf-8')
print('Shop source: original kiosk, larger cyan fish directly on wood; no gold sign board.')
