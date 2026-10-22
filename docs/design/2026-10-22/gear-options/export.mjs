import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'../../../..');
for(const f of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),path.join(here,'gears.js'),path.join(here,'variants-detail.js')])
  (0,eval)(fs.readFileSync(f,'utf8'));
const defs={...GearOptions.defs,...GearDetail};
const out=path.join(here,'svg');fs.mkdirSync(out,{recursive:true});
const metadata=[];
for(const[id,d]of Object.entries(defs)){
  const P=new Pen();P.translate(64,64);P.rotate(13.5);d.draw(P,'#ead5ac');
  fs.writeFileSync(path.join(out,`${id}.svg`),Pen.toSvg(P.ops,128,128));
  metadata.push({id,title:d.title,description:d.subtitle,file:`svg/${id}.svg`,main:3.2,secondary:1.9});
}
fs.writeFileSync(path.join(here,'manifest.json'),JSON.stringify({status:'B-selected',selected:'B',selected_profile:GearOptions.selectedProfile,canvas:[128,128],outer:54,teeth:8,shape_phase_degrees:13.5,actual_450px_scale:.625,main_450px:2,secondary_450px:1.1875,proposals:metadata,notes:['Canvas and SVG share paths.','Selected B is fitted for the production pin/gear clearance cycle. See B-pinmesh-stdout.log and selection.json for verification.']},null,2)+'\n');
console.log('Exported six review SVGs. Selected B uses the production clearance fit.');
if(process.argv.includes('--install=B')){
  const canonical=path.join(root,'game/ui/art_sources/battle_cog_B.svg');
  fs.mkdirSync(path.dirname(canonical),{recursive:true});
  fs.copyFileSync(path.join(out,'B.svg'),canonical);
  console.log('Installed selected B source; regenerate only make_battle_cogs().');
}
