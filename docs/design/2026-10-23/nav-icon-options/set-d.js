// D: one travelling-adventure family, with three intentionally distinct contours.
(function(){
  const {C,S,shape,rect,circle,face}=NavArt;
  const ellipse=(x,y,rx,ry)=>Pen.circle(0,0,1).map(([op,...a])=>[op,...a.map((v,i)=>v*(i%2?ry:rx)+(i%2?y:x))]);
  NavOptions.D={
    title:'Đoàn phiêu lưu',
    concept:'Xe hàng rong, mèo hiệp sĩ và cờ chiến trận: ba biểu tượng cùng nét nâu, màu phẳng và khối lớn.',
    icons:{
      shop(p){
        // Two supports and the tow handle sit behind a real wheeled cart.
        rect(p,39,73,9,51,3,C.wood);
        rect(p,145,73,9,51,3,C.wood);
        shape(p,[['M',148,149],['L',170,131],['Q',177,126,178,135]],null,'main');
        circle(p,62,166,14,C.blueDark);
        circle(p,135,166,14,C.blueDark);
        circle(p,62,166,4,C.gold,'none');
        circle(p,135,166,4,C.gold,'none');
        rect(p,36,107,124,48,7,C.wood);
        // One broad counter edge, without little drawers or framed price labels.
        rect(p,31,104,134,11,4,C.cream);
        const roof=[['M',37,47],['L',157,47],['L',174,76],['L',174,89],
          ['Q',150,107,125,89],['Q',100,107,74,89],['Q',47,107,21,89],['L',21,76],['Z']];
        shape(p,roof,C.blue,'none');
        shape(p,[['M',77,47],['L',117,47],['L',125,76],['L',125,89],
          ['Q',100,107,74,89],['L',74,76],['Z']],C.cream,'none');
        shape(p,roof,null,'main');
        // The fish itself is the shop sign: a large unframed gold silhouette.
        shape(p,[['M',75,133],['Q',91,118,111,126],['L',124,119],['L',122,133],
          ['L',125,146],['L',111,139],['Q',91,148,75,133],['Z']],C.gold,'none');
        circle(p,85,131,2.4,C.ink,'none');
      },
      hero(p){
        // Broad blue cape: the bust remains a character, not a face in a badge.
        shape(p,[['M',67,128],['Q',41,135,35,172],['Q',100,182,165,172],
          ['Q',160,135,133,128],['L',117,148],['L',83,148],['Z']],C.blue,'main');
        shape(p,[['M',86,145],['L',114,145],['L',108,171],['L',92,171],['Z']],C.cream,'none');
        shape(p,[['M',61,145],['Q',100,154,139,145],['L',136,154],
          ['Q',100,162,64,154],['Z']],C.gold,'none');
        const head=[['M',100,72],['C',138,72,158,86,158,111],
          ['C',158,139,134,151,100,151],['C',66,151,42,139,42,111],
          ['C',42,86,62,72,100,72],['Z']];
        shape(p,head,C.ginger,'none');
        shape(p,ellipse(100,133,29,14),C.white,'none');
        shape(p,head,null,'main');
        // Built-in metal cat ears and a small red plume are the hero's silhouette.
        const helmet=[['M',45,101],['Q',43,68,55,47],['Q',62,40,72,48],['L',88,61],
          ['Q',104,57,119,61],['L',137,48],['Q',145,41,151,49],['Q',161,70,157,101],
          ['Q',100,87,45,101],['Z']];
        shape(p,helmet,C.steel,'none');
        shape(p,[['M',49,87],['Q',102,74,154,87],['L',154,95],
          ['Q',102,83,49,95],['Z']],C.gold,'none');
        shape(p,helmet,null,'main');
        shape(p,[['M',104,61],['Q',102,35,121,27],['Q',141,20,157,31],
          ['Q',143,35,140,43],['Q',130,40,124,52],['L',113,57],['Z']],C.red,'main');
        shape(p,[['M',102,62],['L',102,79]],null,'secondary',C.steel2);
        face(p,100,116);
        shape(p,[['M',72,101],['L',87,105]],null,'secondary',C.ink);
        shape(p,[['M',128,101],['L',113,105]],null,'secondary',C.ink);
      },
      battle(p){
        // A battle standard, deliberately unlike both a shop canopy and a cat bust.
        rect(p,47,30,9,147,3,C.wood);
        circle(p,51.5,26,6,C.gold);
        shape(p,[['M',57,42],['Q',110,29,171,43],['L',146,89],['L',171,139],
          ['Q',111,125,57,139],['Z']],C.red,'main');
        // A single broad silver sword emblem survives at the smallest nav size.
        shape(p,[['M',110,53],['L',121,68],['L',121,95],['L',131,95],['L',131,105],
          ['L',116,105],['L',116,119],['L',105,119],['L',105,105],['L',90,105],
          ['L',90,95],['L',100,95],['L',100,68],['Z']],C.steel,'none');
      },
    },
  };
})();
