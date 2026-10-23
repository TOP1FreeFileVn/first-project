import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../../..');
for(const f of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),path.join(here,'castle.js')])(0,eval)(fs.readFileSync(f,'utf8'));
const out=path.join(root,'game/assets/battle/cardboard-castle');
fs.mkdirSync(out,{recursive:true});
for(const name of ['rear','facade','composite'])fs.writeFileSync(path.join(out,name+'.svg'),Pen.toSvg(CardboardCastle.layer(name),720,240));
// Upgrade tiers 1-5: rear (bare poles behind units) + facade (wall in front). Cloths are drawn
// by the game from tiers.json anchors, reusing the lobby flag art.
const tiers={};
for(let t=1;t<=5;t++){
 for(const name of ['rear','facade'])fs.writeFileSync(path.join(out,`tier-${t}-${name}.svg`),Pen.toSvg(CardboardCastle.draw(t,name).ops,720,240));
 tiers[t]=CardboardCastle.draw(t,'composite').anchors;
}
fs.writeFileSync(path.join(out,'tiers.json'),JSON.stringify({canvas:[720,240],flag_pad:8,tiers},null,1)+String.fromCharCode(10));
const manifest={
 id:'battle-cardboard-castle-v3-flat-gate',status:'in-game',
 source:'docs/design/2026-10-23/battle-flat-gate/castle.js',canvas:[720,240],origin:[0,0],
 world_placement:['0','Battle.WALL_Y - 184'],wall_line_y:184,ramp:false,art_end_y:220.3,
 outer_sides_centerline_x:[CardboardCastle.main/2,720-CardboardCastle.main/2],
 geometry:{projection:'front-facing flat 2D',side_tower_windows:0,extruded_side_faces:0,gate_leaves:0,recessed_floor:false},
 gate:{straight_jambs_x:[313,407],head_top_y:140,crown_y:148,straight_jamb_start_y:181,base_y:218,
  world_base_y:734,gear_table_top_y:734,clear_alpha_samples:[[360,170],[360,205]],gate_leaves:'none'},
 layers_back_to_front:['rear.svg flags','ACTORS','facade.svg complete opaque wall and transparent aperture'],
 runtime_layers:{source:'game/battle/Background.gd',
  rear:{asset:'rear.svg',source_rect:[0,0,720,240],z_index:0},
  foreground:{asset:'facade.svg',source_rect:[0,0,720,240],destination_local:[0,0],node:'CastleForeground',z_index:2},
  reason:'The entire opaque gate and towers must cover units; only the transparent doorway and space above the battlements reveal them.'},
 composite:'composite.svg',main_stroke_px:CardboardCastle.main,secondary_stroke_px:CardboardCastle.secondary,palette:CardboardCastle.colors,
 notes:['No side windows, projecting jamb leaves, receding side faces or recessed floor.',
 'Whole facade lifted4logicalpx so its baseline and the gear-table top edge share world y734; gameplay wall and gear coordinates unchanged.',
 'Clear cat-shaped aperture remains. The full opaque facade now occludes actors; no horizontal actor split. Flags, battlements, tape and paw stamps retain cardboard identity.'],
};
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log('Exported flat 2D castle: no side doors/depth, clear gateway, base aligned to table.');
