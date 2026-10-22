// B: a tiny cardboard town. Paper construction links the set; each function
// keeps a different silhouette so the three destinations survive at 26 px.
(function(){
  const {C,shape,rect,circle,paw,face}=NavArt;

  function shop(p){
    // Posts and a single dark stall opening, behind the goods and counter.
    rect(p,34,77,132,90,8,C.paper);
    rect(p,46,91,108,51,3,C.ink,'none');
    // Two large goods shapes are enough; avoid a row of tiny merchandise.
    shape(p,[['M',57,136],['L',60,116],['Q',61,111,66,111],['L',84,111],['Q',89,111,90,116],['L',93,136],['Z']],C.gold);
    shape(p,[['M',69,111],['Q',75,103,81,111]],null,'secondary',C.ochre);
    circle(p,127,124,15,C.green);
    shape(p,[['M',127,110],['Q',128,102,136,103]],null,'secondary',C.ink);
    // One scalloped contour. Stripes are unlined material planes.
    const awning=[['M',43,43],['L',157,43],['L',178,78],['L',178,90],
      ['Q',162,111,146,90],['Q',130,111,114,90],['Q',98,111,82,90],
      ['Q',66,111,50,90],['Q',34,111,18,90],['L',18,78],['Z']];
    shape(p,awning,C.cream,'none');
    for(const i of [0,2,4]){
      const a=43+i*22.8,b=a+22.8,x=18+i*32;
      shape(p,[['M',a,43],['L',b,43],['L',x+32,78],['L',x+32,90],
        ['Q',x+16,111,x,90],['L',x,78],['Z']],C.blue,'none');
    }
    shape(p,awning,null);
    // A broad front board makes a low, wide merchant silhouette.
    rect(p,27,133,146,39,7,C.paper);
    shape(p,[['M',31,134],['L',169,134]],null,'main');
    paw(p,100,153,.72,C.ochre);
  }

  function hero(p){
    // Red folded-paper crest behind the cap, large enough to read as hero.
    shape(p,[['M',87,66],['Q',76,50,87,34],['Q',103,17,126,32],
      ['Q',107,33,109,46],['Q',112,56,106,66],['Z']],C.red);
    // The accepted broad ginger head and plain cream muzzle stay visible.
    shape(p,[['M',100,77],['C',147,77,174,92,174,126],
      ['C',174,159,149,176,100,176],['C',51,176,26,159,26,126],
      ['C',26,92,53,77,100,77],['Z']],C.ginger);
    shape(p,[['M',100,132],['C',121,132,136,142,132,155],
      ['C',128,173,72,173,68,155],['C',64,142,79,132,100,132],['Z']],C.white,'none');
    // Cardboard cat-ear helmet: one outer edge, unlined ear and band planes.
    const helmet=[['M',29,108],['L',35,45],['Q',36,39,43,43],['L',73,66],
      ['Q',100,61,127,66],['L',157,43],['Q',164,39,165,45],
      ['L',171,108],['Q',100,95,29,108],['Z']];
    shape(p,helmet,C.paper,'none');
    shape(p,[['M',43,57],['L',62,73],['L',41,84],['Z']],C.ochre,'none');
    shape(p,[['M',157,57],['L',159,84],['L',138,73],['Z']],C.ochre,'none');
    shape(p,[['M',31,98],['Q',100,86,169,98],['L',171,108],
      ['Q',100,95,29,108],['Z']],C.cream,'none');
    shape(p,helmet,null);
    shape(p,[['M',100,67],['L',100,87]],null,'secondary');
    face(p,100,134,1);
    shape(p,[['M',69,117],['L',85,122]],null,'secondary',C.ink);
    shape(p,[['M',115,122],['L',131,117]],null,'secondary',C.ink);
  }

  function battle(p){
    // A pennant and square crenellations make this read as a fortress,
    // distinct from the shop's horizontal canopy and counter.
    shape(p,[['M',102,76],['L',102,27]],null,'main');
    shape(p,[['M',103,28],['L',138,37],['L',103,49],['Z']],C.red);
    const wall=[['M',26,172],['L',26,56],['L',45,56],['L',45,72],
      ['L',61,72],['L',61,56],['L',80,56],['L',80,79],
      ['L',120,79],['L',120,56],['L',139,56],['L',139,72],
      ['L',155,72],['L',155,56],['L',174,56],['L',174,172],['Z']];
    shape(p,wall,C.paper);
    // Functional carton seams, not a border around every material patch.
    shape(p,[['M',80,83],['L',80,96]],null,'secondary');
    shape(p,[['M',120,83],['L',120,96]],null,'secondary');
    // An open cat-ear gate is one dark negative shape, with no inset frame.
    shape(p,[['M',72,172],['L',72,126],['Q',72,115,78,109],
      ['L',78,97],['Q',78,91,84,96],['L',96,106],['Q',100,104,104,106],
      ['L',116,96],['Q',122,91,122,97],['L',122,109],
      ['Q',128,115,128,126],['L',128,172],['Z']],C.ink,'none');
    // Two broad slots, not a miniature brick pattern.
    for(const x of [49,151])shape(p,[['M',x-6,126],['L',x-6,112],
      ['Q',x,103,x+6,112],['L',x+6,126],['Z']],C.ink,'none');
    shape(p,[['M',31,151],['L',54,151]],null,'secondary');
    shape(p,[['M',146,151],['L',169,151]],null,'secondary');
  }

  NavOptions.B={title:'Phố hộp giấy',
    concept:'Cửa tiệm mái bạt thấp, mèo hiệp sĩ đội mũ carton và cổng thành tai mèo; cùng chất giấy, khác rõ hình dáng.',
    icons:{shop,hero,battle}};
})();
