import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)), root=path.resolve(here,'../../../..');
for(const file of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),path.join(here,'symbols.js')])
  vm.runInThisContext(fs.readFileSync(file,'utf8'));
const out=path.join(root,'game/ui/art');
for(const [slot,draw] of Object.entries(HeroSlotSymbols.draw)) {
  for(const size of [32,48,64,96,256]) {
    const P=new Pen(); P.scale(size/96); draw(P);
    const suffix=size===256 ? '' : `_${size}`;
    fs.writeFileSync(path.join(out,`icon_slot_${slot}${suffix}.svg`),Pen.toSvg(P.ops,size,size));
  }
}
console.log('Exported four independent monochrome equipment-slot symbol families.');
