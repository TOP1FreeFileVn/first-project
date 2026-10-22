// Build phase-indexed foreground art from the approved shared Canvas paths.
// The output triangle and rear rotor are NOT baked into these frames: runtime
// rotates them continuously at the actual GearBoard pin angle.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const source=path.join(root,'docs/design/2026-10-23/cat-round-drive');
const out=path.join(root,'output/cat-drive-build');
const target=path.join(root,'game/assets/battle/cat-drive');
for(const f of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),...['common.js','round.js','cat.js'].map(f=>path.join(source,f))])vm.runInThisContext(fs.readFileSync(f,'utf8'));
const head=fs.readFileSync(path.join(root,'game/assets/lobby/cardboard/cats/cat_cream/head.svg'),'utf8').replace(/^<svg[^>]*>/,'').replace(/<\/svg>\s*$/,'');
const wrap=(body,size=128)=>`<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="-64 -64 128 128">${body}</svg>`;
fs.mkdirSync(path.join(out,'svg'),{recursive:true});fs.mkdirSync(target,{recursive:true});
// Build intermediates and isolated app profiles must not enter Godot imports.
fs.writeFileSync(path.join(root,'output','.gdignore'),'');
const count=96;
for(let i=0;i<count;i++){
  const angle=i*Math.PI*2/count;
  const layers=TwoHandDrive.frame(angle).layers.slice(1);
  const body=layers.map(l=>l.type==='paths'?Pen.toSvgBody(l.ops):`<g transform="translate(${l.x} ${l.y}) rotate(${l.rotation*180/Math.PI}) scale(${l.scale}) translate(-128 -144)">${head}</g>`).join('\n');
  fs.writeFileSync(path.join(out,`svg/cat-${String(i).padStart(3,'0')}.svg`),wrap(body));
}
const P=new Pen();MachineVariants.A.draw(P,0);
fs.writeFileSync(path.join(target,'rear_disc.svg'),wrap(Pen.toSvgBody(P.ops),256));
const manifest={source:'docs/design/2026-10-23/cat-round-drive',frames:count,frame_size:128,padding:2,columns:12,rows:8,phase:'positive radians; nearest pose to actual board.pin_angle()',baked_parts:'cat, front crank, soles, opaque arm attachments, grip and paws',continuous_parts:'rear disc and fat triangular output; no tip circle',main:2.9,secondary:1.6};
fs.writeFileSync(path.join(target,'source.json'),JSON.stringify(manifest,null,2)+'\n');
console.log('Exported 96 foreground cat poses and the continuous rear rotor.');
