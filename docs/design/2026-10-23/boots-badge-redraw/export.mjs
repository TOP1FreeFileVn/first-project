import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));
for(const f of [path.resolve(here,'../../../../.claude/skills/canvas-vector-art/scripts/pen.js'),path.join(here,'boots.js')]) (0,eval)(fs.readFileSync(f,'utf8'));
fs.writeFileSync(path.join(here,'boots-glyph.svg'),Pen.toSvg(BootsBadge.icon(256),256,256));
