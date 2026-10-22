import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here,'../../../..');
for (const f of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),path.join(here,'board.js')])
  (0,eval)(fs.readFileSync(f,'utf8'));
const out = path.join(root,'game/assets/battle/cardboard-board');
fs.mkdirSync(out,{recursive:true});
fs.writeFileSync(path.join(out,'board.svg'),Pen.toSvg(CardboardBoard.layer(),720,480));
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify({
  id:'battle-cardboard-board-v2-edge-to-edge',source:'docs/design/2026-10-22/battle-cardboard-board/board.js',
  canvas:[720,480],world_rect:[0,720,720,480],opaque_backing_bounds:[2.3,14,717.7,474],
  visible_outer_horizontal_bounds:[0,720],
  grid_world_origin:[60,760],cell_size:100,grid:[6,4],main_stroke:CardboardBoard.main,
  secondary_stroke:CardboardBoard.secondary,palette:CardboardBoard.colors,
  notes:['Opaque carton backing covers the old rounded tray in battle_map_field.svg.',
    'No gameplay cells, hitboxes, gear sizes or production mechanics are changed.',
    'The outer contour reaches both screen edges; the deck and gear registration stay fixed.',
    'No ramp and no cast shadow; render beneath the castle facade, board cells and gear.'],
},null,2)+'\n');
console.log(path.join(out,'board.svg'));
