import fs from 'node:fs';import path from 'node:path';import{fileURLToPath}from'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));
for(const f of['pen.js','chest.js'])(0,eval)(fs.readFileSync(path.join(here,f),'utf8'));
const dir=path.join(here,'svg');fs.mkdirSync(dir,{recursive:true});
for(const size of[256,128,96,64,26])fs.writeFileSync(path.join(dir,`chest-polish-${size}.svg`),Pen.toSvg(ChestPilot.icon(size),size,size));
fs.writeFileSync(path.join(dir,'chest-polish-open-256.svg'),Pen.toSvg(ChestPilot.icon(256,1),256,256));
console.log('Exported polished chest paths.');
