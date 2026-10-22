// Selected C helmet. Fixes: material fills cannot paint over the silhouette;
// the gold nasal guard ends above the cheeks instead of reading as a long tie.
(function(){
globalThis.drawApprovedHelmet=function(p){
 const INK='#583f21', STEEL='#dce6eb', SIDE='#b5cbd3', GOLD='#f7cb69';
 const main=7.5, secondary=4.2;
 const draw=(d,fill,stroke=null,width=0)=>p.shape(d,{fill,stroke,width});
 const crest=[['M',83,56],['C',66,29,92,9,125,20],['Q',142,26,145,43],['Q',115,32,107,63],['Z']];
 draw(crest,'#ef7767',INK,main);
 const helmet=[['M',43,87],['L',43,47],['Q',43,36,53,44],['L',78,62],
   ['Q',100,55,122,62],['L',147,44],['Q',157,36,157,47],['L',157,87],
   ['L',163,147],['Q',138,174,100,177],['Q',62,174,37,147],['Z']];
 draw(helmet,STEEL);
 // Broad material plane. The exact outer contour is redrawn after every fill.
 draw([['M',100,63],['L',100,96],['L',158,96],['L',163,147],
   ['Q',138,174,100,177],['Z']],SIDE);
 draw([['M',57,64],['L',57,83],['L',75,77],['Z']],'#4285aa');
 draw([['M',143,64],['L',143,83],['L',125,77],['Z']],'#4285aa');
 draw([['M',53,99],['Q',100,92,147,99],['L',143,119],
   ['Q',100,112,57,119],['Z']],INK);
 draw([['M',94,91],['L',106,91],['L',108,125],['L',100,135],['L',92,125],['Z']],GOLD);
 draw([['M',59,139],['L',76,145],['M',141,139],['L',124,145]],null,'#8da4ae',secondary);
 draw(helmet,null,INK,main);
};
})();
