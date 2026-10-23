// node docs/design/2026-10-23/soldier-rig-v2/export.mjs -> svg/<part>.svg (256x240 each)
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url';
const here = path.dirname(fileURLToPath(import.meta.url));
for (const f of ['../../../../.claude/skills/canvas-vector-art/scripts/pen.js', 'cat.js']) (0, eval)(fs.readFileSync(path.join(here, f), 'utf8'));
fs.mkdirSync(path.join(here, 'svg'), { recursive: true });
for (const n of Cat.names()) fs.writeFileSync(path.join(here, `svg/${n}.svg`), Pen.toSvg(Cat.part(n), 256, 240));
fs.writeFileSync(path.join(here, 'rig.json'), JSON.stringify({ order: Cat.ORDER, pivots: Cat.PIVOTS }, null, 1));
console.log('parts:', Cat.names().join(' '), '+ weapon.svg');
