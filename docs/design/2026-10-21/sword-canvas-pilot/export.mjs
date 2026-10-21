// Exports the canvas-previewed sword as SVG (same path data as preview.html).
// node docs/design/2026-10-21/sword-canvas-pilot/export.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
for (const f of ['pen.js', 'sword.js']) (0, eval)(fs.readFileSync(path.join(here, f), 'utf8'));
const { Pen, SwordArt } = globalThis;

const out = path.join(here, 'svg');
fs.mkdirSync(out, { recursive: true });
const write = (name, text) => { fs.writeFileSync(path.join(out, name), text); console.log(path.join(out, name)); };

for (const size of [256, 96, 64]) write(`sword-icon-${size}.svg`, Pen.toSvg(SwordArt.icon(size), size, size));

// Held pose: unchanged hero layers + weapon + palm + paws, all on the 256x240 canvas.
const src = path.join(here, '../../2026-10-19/hero-equipment/sources');
const inner = (f) => fs.readFileSync(path.join(src, f), 'utf8').replace(/^[\s\S]*?<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '');
const { weapon, palm } = SwordArt.held();
write('sword-weapon-layer.svg', Pen.toSvg(weapon, 256, 240));
write('hero-sword.svg', Pen.toSvg([...weapon, ...palm], 256, 240, inner('hero-base.svg') + '\n')
  .replace('</svg>', inner('hero-paws.svg').replace(/<defs>[\s\S]*?<\/defs>/, '') + '\n</svg>'));
