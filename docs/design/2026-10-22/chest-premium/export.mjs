import fs from'node:fs';import path from'node:path';import{fileURLToPath}from'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));for(const f of['pen.js','chest.js'])(0,eval)(fs.readFileSync(path.join(here,f),'utf8'));
const dir=path.join(here,'svg');fs.mkdirSync(dir,{recursive:true});
for(const size of[256,248,124,96,64,26]){const p=new Pen(),w=size*.9;p.translate(size/2,size/2-w*.05);p.scale(w/208);ChestPilot.chest(p,0,w<48);fs.writeFileSync(path.join(dir,`chest-premium-${size}.svg`),Pen.toSvg(p.ops,size,size))}
fs.writeFileSync(path.join(dir,'chest-premium-open-256.svg'),Pen.toSvg(ChestPilot.icon(256,1),256,256));console.log('Exported gold-only premium paths.');
