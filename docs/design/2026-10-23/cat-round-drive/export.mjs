import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
for(const f of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),...['common.js','round.js','cat.js'].map(f=>path.join(here,f))])vm.runInThisContext(fs.readFileSync(f,'utf8'));
const raw=fs.readFileSync(path.join(root,'game/assets/lobby/cardboard/cats/cat_cream/head.svg'),'utf8').replace(/^<svg[^>]*>/,'').replace(/<\/svg>\s*$/,'');
function svg(id,a,size,only=false){const body=TwoHandDrive.frame(a,id,only).layers.map(l=>l.type==='paths'?Pen.toSvgBody(l.ops):`<g transform="translate(${l.x} ${l.y}) rotate(${l.rotation*180/Math.PI}) scale(${l.scale}) translate(-128 -144)">${raw}</g>`).join('\n');return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="-64 -64 128 128">${body}</svg>`;}
fs.mkdirSync(path.join(here,'svg'),{recursive:true});fs.mkdirSync(path.join(here,'frames'),{recursive:true});
const metadata=[];
for(const id of Object.keys(MachineVariants).sort()){
 const v=MachineVariants[id];metadata.push({id,title:v.title,idea:v.idea,source:v.source});
 fs.writeFileSync(path.join(here,`svg/${id}-machine.svg`),svg(id,-.45,256,true));
 fs.writeFileSync(path.join(here,`svg/${id}-cat.svg`),svg(id,-.45,384));
 fs.writeFileSync(path.join(here,`svg/${id}-native.svg`),svg(id,-.45,128));
 for(let i=0;i<24;i++)fs.writeFileSync(path.join(here,`frames/${id}-${String(i).padStart(2,'0')}.svg`),svg(id,-.45-i/24*2*Math.PI,256));
}
fs.writeFileSync(path.join(here,'variants.json'),JSON.stringify(metadata,null,2));
console.log('Exported round drive: 3 still SVGs + 24 animation SVGs. Output tip has no circle.');
