import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
for(const file of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),path.join(here,'helmet.js'),path.join(here,'boots.js')]) (0,eval)(fs.readFileSync(file,'utf8'));
fs.mkdirSync(path.join(here,'svg'),{recursive:true});
const report={};
for(const [slug,api] of [['helmet',GearHelmet],['boots',GearBoots]]) {
 for(const size of [32,48,64,96,256]) fs.writeFileSync(path.join(here,`svg/${slug}-icon-${size}.svg`),Pen.toSvg(api.icon(size),size,size));
 fs.writeFileSync(path.join(here,`svg/${slug}-roles-256.svg`),Pen.toSvg(api.icon(256,true),256,256));
 report[slug]={profile:api.strokeProfiles,colors:api.colors,strokes:api.icon(256).filter(o=>o.stroke).map(o=>({ink:o.stroke,width:o.width}))};
}
fs.writeFileSync(path.join(here,'source-strokes.json'),JSON.stringify({items:report,note:'Authored widths; inspect native PNGs separately. Proposal only.'},null,2)+'\n');
console.log('Exported helmet and boots from shared Canvas geometry.');
