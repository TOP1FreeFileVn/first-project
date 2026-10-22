(function(){
const {C,shape,rect,circle,face}=NavArt;
function sword(p,angle){
  p.save();p.translate(100,99);p.rotate(angle);
  rect(p,-9,35,18,36,5,C.blue);
  circle(p,0,76,11,C.gold);
  const blade=[['M',0,-87],['L',17,-64],['L',17,24],['L',-17,24],['L',-17,-64],['Z']];
  shape(p,blade,C.white);
  shape(p,[['M',0,-80],['L',13,-62],['L',13,21],['L',0,21],['Z']],C.steel2,'none');
  shape(p,blade,null);
  shape(p,[['M',-29,24],['Q',0,34,29,24],['L',31,37],['Q',0,49,-31,37],['Z']],C.gold);
  p.restore();
}
NavOptions.A={title:'Gọn và rõ',concept:'Quầy mái vải • Mèo hiệp sĩ • Song kiếm',icons:{
  shop(p){
    rect(p,39,76,122,99,10,C.wood);
    rect(p,54,85,92,43,0,C.white,'none');
    shape(p,[['M',25,66],['L',48,27],['Q',51,22,59,22],['L',141,22],['Q',149,22,152,27],['L',175,66],['L',175,79],['Q',150,111,125,80],['Q',100,111,75,80],['Q',50,111,25,79],['Z']],C.blue);
    shape(p,[['M',75,28],['L',125,28],['L',125,80],['Q',100,103,75,80],['Z']],C.cream,'none');
    shape(p,[['M',25,66],['L',175,66]],null,'secondary',C.blueDark);
    rect(p,24,123,152,18,6,C.gold);
    // A broad fish emblem, without miniature paw rings or extra inset frame.
    shape(p,[['M',80,158],['Q',103,139,123,157],['Q',103,176,80,158],['L',68,148],['L',68,168],['Z']],C.cream,'none');
    circle(p,111,156,2.8,C.ink,'none');
  },
  hero(p){
    // One crest, a broad helmet shell, then the unaltered cat face language.
    shape(p,[['M',92,53],['C',82,22,105,8,132,17],['Q',149,21,155,34],['Q',128,27,111,57],['Z']],C.red);
    shape(p,[['M',31,93],['Q',26,129,46,150],['Q',65,174,100,174],['Q',135,174,154,150],['Q',174,129,169,93],['Z']],C.ginger);
    shape(p,[['M',100,125],['C',74,125,63,140,66,150],['C',69,164,85,169,100,169],['C',115,169,131,164,134,150],['C',137,140,126,125,100,125],['Z']],C.white,'none');
    shape(p,[['M',28,103],['L',37,46],['Q',39,38,45,42],['L',76,66],['Q',100,58,124,66],['L',155,42],['Q',161,38,163,46],['L',172,103],['Q',100,90,28,103],['Z']],C.steel);
    shape(p,[['M',47,59],['L',43,83],['L',68,76],['Z']],C.pink,'none');
    shape(p,[['M',153,59],['L',157,83],['L',132,76],['Z']],C.pink,'none');
    shape(p,[['M',100,65],['L',100,85]],null,'secondary','#95aab4');
    shape(p,[['M',31,92],['Q',100,79,169,92],['L',172,103],['Q',100,90,28,103],['Z']],C.gold,'none');
    shape(p,[['M',28,103],['Q',100,90,172,103]],null);
    face(p,100,127,.95);
    shape(p,[['M',70,111],['L',83,115],['M',130,111],['L',117,115]],null,'secondary',C.ink);
  },
  battle(p){
    // The compact crossed pair has a tighter fitted canvas than the head/shop.
    // Its named menu contour profile is 6.5 local units, avoiding dark guards.
    const begin=p.ops.length;sword(p,43);sword(p,-43);
    for(const op of p.ops.slice(begin))if(op.stroke)op.width=+(op.width*6.5/7.5).toFixed(2);
  }
}};
})();
