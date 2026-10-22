import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));
const root=path.resolve(here,'../../../..');
for(const f of [path.join(root,'.claude/skills/canvas-vector-art/scripts/pen.js'),path.join(here,'castle.js')]) (0,eval)(fs.readFileSync(f,'utf8'));
const out=path.join(root,'game/assets/battle/cardboard-castle');
fs.mkdirSync(out,{recursive:true});
for(const name of ['rear','facade','composite']) {
  fs.writeFileSync(path.join(out,name+'.svg'),Pen.toSvg(CardboardCastle.layer(name),720,240));
  console.log(name+'.svg');
}
// Delete only the stale asset produced by v1; the user explicitly removed the ramp.
fs.rmSync(path.join(out,'ramp.svg'),{force:true});
const manifest={
  id:'battle-cardboard-castle-v2-open-gate',status:'in-game-demo-open-gate',
  source:'docs/design/2026-10-22/battle-cardboard-castle/castle.js',
  canvas:[720,240],origin:[0,0],world_placement:['0','Battle.WALL_Y - 180'],
  wall_line_y:180,ramp:false,art_end_y:220.3,
  outer_sides_centerline_x:[CardboardCastle.main / 2,720 - CardboardCastle.main / 2],
  gate:{straight_jambs_x:[313,407],head_top_y:140,crown_y:148,straight_jamb_start_y:181,floor_y:[193,218],clear_alpha_sample:[360,170],gate_leaves:'folded outward, outside the aperture'},
  layers_back_to_front:['rear.svg','facade.svg upper band y0..164','ACTORS','facade.svg low band y164..240'],
  runtime_split:{
    source:'game/battle/Background.gd',cut_y:164,cut_world_y:684,
    rear:{asset:'rear.svg',source_rect:[0,0,720,240],z_index:0},
    upper:{asset:'facade.svg',source_rect:[0,0,720,164],destination_local:[0,0],z_index:0},
    lower:{asset:'facade.svg',source_rect:[0,164,720,76],destination_local:[0,164],node:'CastleForeground',z_index:2},
    reason:'Real units deploy/rally across all columns at world y650..664. Only the low wall band may cover actors; placing the full facade above units permanently hides the hero and supports.',
  },
  composite:'composite.svg',main_stroke_px:CardboardCastle.main,secondary_stroke_px:CardboardCastle.secondary,palette:CardboardCastle.colors,
  notes:[
    'Single castle appearance; no unreviewed upgrade tiers.',
    'All layers retain the same full canvas and registration.',
    'Runtime draws rear plus facade y0..164 behind actors; only facade y164..240 is foreground at z2.',
    'The full-facade Canvas depth proof is a geometry illustration with a cat foot at local y218, not the actual runtime spawn at local y144.',
    'The upper cat-shaped gateway is clear alpha; the separate warm recessed floor ends flush with the facade.',
    'No ramp, projecting platform, staircase, or solid painted gate panel.',
    'The two triangular roof flaps above the central box were removed; battlements, flags and the cat-shaped doorway are unchanged.',
    'Outer wing centerlines sit at x2.3 and717.7 so their full 4.6 px vertical contours fit inside the 720 px canvas.',
    'This asset does not change gameplay paths, collision, unit limits or gear positions.',
  ],
};
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
