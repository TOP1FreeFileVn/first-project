import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '../../../../..');
for (const file of [path.join(root, '.claude/skills/canvas-vector-art/scripts/pen.js'), path.join(here, '../frames.js')]) {
  vm.runInThisContext(fs.readFileSync(file, 'utf8'));
}
const palettes = JSON.parse(fs.readFileSync(path.join(here, 'palettes.json'), 'utf8'));
fs.mkdirSync(path.join(here, 'svg'), {recursive: true});
for (const palette of palettes) {
  for (const [tone, color] of Object.entries(palette.tones)) {
    const pen = new Pen();
    WeaponFrameOptions.draw.A(pen, color);
    // Reuse the approved A paths unchanged; only its material fills differ.
    for (const op of pen.ops) {
      if (op.fill === '#dab47a') op.fill = palette.carton;
      if (op.fill === '#ead4aa') op.fill = palette.tape;
    }
    fs.writeFileSync(path.join(here, `svg/${palette.id}-${tone}.svg`), Pen.toSvg(pen.ops, 124, 124));
  }
}
console.log('Exported 12 A-frame palette drafts. Production files unchanged.');
