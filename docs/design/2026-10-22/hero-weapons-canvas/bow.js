// Braced recurve bow. +X is its directed firing axis; the string is perpendicular.
(function () {
  const colors = {ink:'#583f21',secondary:'#946d46',wood:'#cfa265',grip:'#e0b97e'};
  const strokeProfiles = {main:13,secondary:6.5,string:4.4};
  const BODY = [
    ['M',-37,-98],['C',-17,-102,8,-81,14,-57],['L',17,-27],
    ['Q',18,-18,14,-14],['L',14,14],['Q',18,18,17,27],['L',14,57],
    ['C',8,81,-17,102,-37,98],['Q',-44,96,-39,89],
    ['C',-15,82,-11,57,-10,26],['L',-10,-26],
    ['C',-11,-57,-15,-82,-39,-89],['Q',-44,-96,-37,-98],['Z'],
  ];
  function draw(P,options={}) {
    const {main=13,secondary=6.5,string=4.4,roles=false}=options;
    const ink=roles?'#d45d46':colors.ink,sub=roles?'#168c91':colors.secondary;
    P.shape([['M',-38,-94],['L',-38,94]],{stroke:sub,width:string});
    P.shape(BODY,{fill:colors.wood});
    // The grip is a broad unoutlined region of the same warm material family.
    P.shape([['M',-10,-23],['L',16,-23],['Q',18,-18,14,-14],['L',14,14],
      ['Q',18,18,16,23],['L',-10,23],['Z']],{fill:colors.grip});
    for(const y of [-9,8]) P.shape([['M',-10,y+4],['Q',2,y+7,15,y-2]],{stroke:sub,width:secondary});
    P.shape(BODY,{stroke:ink,width:main});
    return P.ops;
  }
  globalThis.WeaponBow={draw,colors,strokeProfiles,grip:[0,0],firingAxis:[[ -38,0],[0,0]]};
})();
