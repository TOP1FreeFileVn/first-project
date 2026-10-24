// node docs/design/2026-10-24/blueprint-icons/export.mjs -> game/ui/art/icon_blueprint_<slot>[_<size>].svg
import fs from 'node:fs'; import path from 'node:path'; import { fileURLToPath } from 'node:url';
const here = path.dirname(fileURLToPath(import.meta.url));
for (const f of ['../../../../.claude/skills/canvas-vector-art/scripts/pen.js', 'blueprint.js']) (0, eval)(fs.readFileSync(path.join(here, f), 'utf8'));
const out = path.join(here, '../../../../game/ui/art');
for (const slot of Blueprint.SLOTS) {
  fs.writeFileSync(path.join(out, `icon_blueprint_${slot}.svg`), Pen.toSvg(Blueprint.draw(slot, 256), 256, 256));
  for (const size of [32, 48, 64, 96]) fs.writeFileSync(path.join(out, `icon_blueprint_${slot}_${size}.svg`), Pen.toSvg(Blueprint.draw(slot, size), size, size));
}
console.log('exported', Blueprint.SLOTS.length * 5, 'blueprint icons');
