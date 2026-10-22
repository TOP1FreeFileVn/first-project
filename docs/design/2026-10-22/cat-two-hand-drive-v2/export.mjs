import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
for(const p of ['.claude/skills/canvas-vector-art/scripts/pen.js','docs/design/2026-10-22/cat-two-hand-drive-v2/drive.js'])vm.runInThisContext(fs.readFileSync(path.join(root,p),'utf8'));
const raw=fs.readFileSync(path.join(root,'game/assets/lobby/cardboard/cats/cat_cream/head.svg'),'utf8').replace(/^<svg[^>]*>/,'').replace(/<\/svg>\s*$/,'');
function svg(a,size){const body=TwoHandDrive.frame(a).layers.map(l=>l.type==='paths'?Pen.toSvgBody(l.ops):`<g transform="translate(${l.x} ${l.y}) rotate(${l.rotation*180/Math.PI}) scale(${l.scale}) translate(-128 -144)">${raw}</g>`).join('\n');return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="-50 -50 100 100">${body}</svg>`;}
fs.mkdirSync(path.join(here,'svg'),{recursive:true});
for(let i=0;i<4;i++){const a=-Math.PI/2+i*Math.PI/2;for(const s of [100,300])fs.writeFileSync(path.join(here,`svg/pose-${i+1}-${s}.svg`),svg(a,s));}
// Export real vector frames so the GIF and engine check use the same geometry.
fs.mkdirSync(path.join(here,'frames'),{recursive:true});
for(let i=0;i<24;i++)fs.writeFileSync(path.join(here,`frames/frame-${String(i).padStart(2,'0')}.svg`),svg(-Math.PI/2+i/24*2*Math.PI,240));
console.log('Exported 8 pose SVGs and 24 animation frame SVGs.');
