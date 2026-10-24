import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'../../../..');
for(const f of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),path.join(here,'glyphs.js')]) (0,eval)(fs.readFileSync(f,'utf8'));
for(const kind of ['weapon','helmet','armor','boots']) {
  const svg=Pen.toSvg(EquipmentBadgeFilled.icon(kind),256,256);
  fs.writeFileSync(path.join(here,'svg',`equipment_badge_${kind}.svg`),svg);
  fs.writeFileSync(path.join(root,'game/ui/art',`equipment_badge_${kind}.svg`),svg);
}
console.log('Exported identical Canvas paths to 4 native category glyph SVGs.');
