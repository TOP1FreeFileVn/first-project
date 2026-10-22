// Almost straight single-edge blade, long grip, restrained steel/wood palette.
(function () {
  const colors={ink:'#583f21',secondary:'#946d46',steel:'#d9e0e8',steelPlane:'#a8b4c7',grip:'#cfa265'};
  const strokeProfiles={main:13,secondary:6.5};
  function draw(P,options={}) {
    const {main=13,secondary=6.5,roles=false}=options;
    const ink=roles?'#d45d46':colors.ink,sub=roles?'#168c91':colors.secondary;
    const blade=[['M',-12,-29],['L',-11,-133],['Q',-10,-149,1,-162],
      ['L',14,-151],['L',13,-29],['Z']];
    P.shape(blade,{fill:colors.steel});
    P.shape([['M',1,-162],['L',14,-151],['L',13,-29],['L',3,-29],['Z']],{fill:colors.steelPlane});
    P.shape(blade,{stroke:ink,width:main});
    const handle=Pen.rrect(-11,-20,22,61,6);
    P.shape(handle,{fill:colors.grip});
    for(const y of [-3,14,30]) P.shape([['M',-11,y+4],['L',11,y-5]],{stroke:sub,width:secondary});
    P.shape(handle,{stroke:ink,width:main});
    // Guard hides the blade/grip contact once. No gem or double inner border.
    P.shape(Pen.rrect(-25,-33,50,15,6),{fill:colors.steelPlane,stroke:ink,width:main});
    return P.ops;
  }
  globalThis.WeaponKatana={draw,colors,strokeProfiles,grip:[0,0]};
})();
