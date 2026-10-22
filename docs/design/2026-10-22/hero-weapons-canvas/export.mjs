import fs from 'node:fs';import path from 'node:path';import{fileURLToPath}from'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
for(const f of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),...['bow.js','staff.js','axe.js','katana.js','art.js'].map(n=>path.join(here,n))])(0,eval)(fs.readFileSync(f,'utf8'));
const src=path.join(root,'docs/design/2026-10-19/hero-equipment/sources');
const inner=name=>fs.readFileSync(path.join(src,name),'utf8').replace(/^[\s\S]*?<svg[^>]*>/,'').replace(/<\/svg>\s*$/,'');
const base=inner('hero-base.svg'),paws=inner('hero-paws.svg').replace(/<defs>[\s\S]*?<\/defs>/,'');
fs.mkdirSync(path.join(here,'svg'),{recursive:true});const record={};
const write=(n,s)=>fs.writeFileSync(path.join(here,'svg',n),s);
for(const[slug,d]of Object.entries(HeroWeaponArt.definitions)){
 for(const size of[32,48,64,96,256])write(`${slug}-icon-${size}.svg`,Pen.toSvg(HeroWeaponArt.icon(slug,size),size,size));
 write(`${slug}-roles-256.svg`,Pen.toSvg(HeroWeaponArt.icon(slug,256,true),256,256));
 const held=HeroWeaponArt.held(slug);write(`${slug}-held-layer.svg`,Pen.toSvg(held.weapon,256,240));
 const hero=Pen.toSvg([...held.weapon,...held.palm],256,240,base+'\n').replace('</svg>',paws+'\n</svg>');
 write(`hero-${slug}-256.svg`,hero);
 write(`hero-${slug}-128.svg`,hero.replace('width="256" height="240"','width="128" height="120"'));
 if(slug==='axe')write('hero-axe-768.svg',hero.replace('width="256" height="240"','width="768" height="720"'));
 record[slug]={iconFit:HeroWeaponArt.fit(slug),held:d.pose,hand:d.hand,socket:held.socket,iconStrokes:HeroWeaponArt.icon(slug,256).filter(o=>o.stroke).map(o=>({width:o.width,ink:o.stroke})),heldStrokes:held.weapon.filter(o=>o.stroke).map(o=>({width:o.width,ink:o.stroke})),aim:slug==='bow'?'string-to-grip firing vector at -135deg screen (up-left), not string axis':'grip-to-head at -45deg screen'};
}
fs.writeFileSync(path.join(here,'source-profiles.json'),JSON.stringify(record,null,2)+'\n');console.log('Exported four weapon icons, role views and unchanged-cat held poses.');
