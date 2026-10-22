import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
vm.runInThisContext(fs.readFileSync(path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),'utf8'));
for(const f of ['common.js','set-a.js','set-b.js','set-c.js','set-d.js']){
 if(fs.existsSync(path.join(here,f)))vm.runInThisContext(fs.readFileSync(path.join(here,f),'utf8'));
}
fs.mkdirSync(path.join(here,'raw-svg'),{recursive:true});
const meta=[];
for(const id of Object.keys(NavOptions).sort()){
 const set=NavOptions[id];
 meta.push({id,title:set.title,concept:set.concept});
 for(const [key,draw]of Object.entries(set.icons)){
   const p=new Pen();draw(p);
   fs.writeFileSync(path.join(here,'raw-svg',`${id}-${key}.svg`),Pen.toSvg(p.ops,200,200));
 }
}
fs.writeFileSync(path.join(here,'variants.json'),JSON.stringify(meta,null,2));
console.log(`Exported ${meta.length} sets.`);
