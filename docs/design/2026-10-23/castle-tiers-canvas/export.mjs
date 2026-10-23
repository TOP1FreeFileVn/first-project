// node docs/design/2026-10-23/castle-tiers-canvas/export.mjs -> svg/castle-tier-{1..5}.svg (440x360)
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url';
const here = path.dirname(fileURLToPath(import.meta.url));
const run = (f) => new Function(fs.readFileSync(f, 'utf8'))();
run(path.join(here, '../../../../.claude/skills/canvas-vector-art/scripts/pen.js'));
run(path.join(here, 'castle.js'));
fs.mkdirSync(path.join(here, 'svg'), { recursive: true });
const anchors = {};
for (let t = 1; t <= 5; t++) {
  fs.writeFileSync(path.join(here, `svg/castle-tier-${t}.svg`), Pen.toSvg(Castle.draw(t, 440), 440, 380));
  const body = Castle.draw(t, 440, { cloth: false });
  fs.writeFileSync(path.join(here, `svg/castle-tier-${t}-body.svg`), Pen.toSvg(body, 440, 380));
  anchors[t] = body.anchors;
}
// Cloth canvases: hoist corner at (PAD, PAD); extra room below/right for the wave.
const PAD = 8;
fs.writeFileSync(path.join(here, 'svg/flag-big.svg'), Pen.toSvg(Castle.cloth(true, 440, PAD), 80, 56));
fs.writeFileSync(path.join(here, 'svg/flag-small.svg'), Pen.toSvg(Castle.cloth(false, 440, PAD), 56, 42));
fs.writeFileSync(path.join(here, 'svg/anchors.json'), JSON.stringify({ canvas: [440, 380], pad: PAD, gate_ramp: [220, 354], tiers: anchors }, null, 1));
console.log('exported', Object.keys(anchors).length, 'tiers + flags + anchors.json');
