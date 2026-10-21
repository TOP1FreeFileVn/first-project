// Export the canvas-previewed item to SVG from the same path data as preview.html.
// Copy next to item.js, rename ITEM below, then: node <dir>/export.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '../../../..');
for (const f of [path.join(root, '.claude/skills/canvas-vector-art/scripts/pen.js'), path.join(here, 'item.js')]) {
  (0, eval)(fs.readFileSync(f, 'utf8'));
}
const { Pen, Item } = globalThis;
const ITEM = 'item';

const out = path.join(here, 'svg');
fs.mkdirSync(out, { recursive: true });
const write = (name, text) => { fs.writeFileSync(path.join(out, name), text); console.log(path.join(out, name)); };

for (const size of [256, 96, 64]) write(`${ITEM}-icon-${size}.svg`, Pen.toSvg(Item.icon(size), size, size));

if (Item.held) {
  const src = path.join(root, 'docs/design/2026-10-19/hero-equipment/sources');
  const inner = (f) => fs.readFileSync(path.join(src, f), 'utf8')
    .replace(/^[\s\S]*?<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '');
  const { weapon, palm } = Item.held();
  write(`${ITEM}-weapon-layer.svg`, Pen.toSvg(weapon, 256, 240));
  write(`hero-${ITEM}.svg`, Pen.toSvg([...weapon, ...palm], 256, 240, inner('hero-base.svg') + '\n')
    .replace('</svg>', inner('hero-paws.svg').replace(/<defs>[\s\S]*?<\/defs>/, '') + '\n</svg>'));
}
