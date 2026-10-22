import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
for(const file of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),path.join(here,'frames.js')])
 vm.runInThisContext(fs.readFileSync(file,'utf8'));
fs.mkdirSync(path.join(here,'svg'),{recursive:true});
for(const [key,draw] of Object.entries(WeaponFrameOptions.draw))
 for(const [tone,color] of Object.entries(WeaponFrameOptions.tones)) {
  const P=new Pen();draw(P,color);
  fs.writeFileSync(path.join(here,`svg/${key}-${tone}.svg`),Pen.toSvg(P.ops,124,124));
 }
console.log('Exported20 review-only frame SVGs; production theme unchanged.');
