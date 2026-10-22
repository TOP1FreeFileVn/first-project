import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
for(const f of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),path.join(here,'hero.js'),path.join(here,'fish.js')])vm.runInThisContext(fs.readFileSync(f,'utf8'));
const p=new Pen();drawApprovedHelmet(p);
const svg=Pen.toSvg(p.ops,200,200).replace('width="200" height="200" viewBox="0 0 200 200"',
 'width="512" height="512" viewBox="5.978 2.478 188.043 188.043"');
fs.writeFileSync(path.join(here,'hero-source.svg'),svg);
const fish=new Pen();drawShopFish(fish);
const fishSvg=Pen.toSvg(fish.ops,128,128);
fs.writeFileSync(path.join(here,'fish-source.svg'),fishSvg);
const canonical=path.join(root,'game/ui/art_sources');
fs.mkdirSync(canonical,{recursive:true});
fs.writeFileSync(path.join(canonical,'nav_hero.svg'),svg);
fs.writeFileSync(path.join(canonical,'nav_shop_fish.svg'),fishSvg);
console.log('Exported selected helmet and larger cyan fish; canonical regeneration sources updated.');
