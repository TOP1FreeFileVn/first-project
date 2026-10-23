(function(){
 const C={ink:'#583f21',light:'#e2d0fa',mid:'#b787e4',deep:'#9362c4'};
 const MAIN=5.8;
 const fill=(P,d,color)=>P.shape(d,{fill:color});
 const outline=(P,d)=>P.shape(d,{stroke:C.ink,width:MAIN});
 function brilliant(P){
  const d=[['M',28,17],['L',68,17],['L',86,37],['Q',88,40,85,44],['L',51,80],['Q',48,84,45,80],['L',11,44],['Q',8,40,10,37],['Z']];
  fill(P,d,C.mid);
  fill(P,[['M',28,17],['L',68,17],['L',86,39],['L',10,39],['Z']],C.light);
  fill(P,[['M',35,39],['L',61,39],['L',48,82],['Z']],C.deep);
  outline(P,d);
 }
 function cushion(P){
  const d=[['M',43,12],['Q',48,9,54,13],['L',80,35],['Q',87,41,82,49],['L',54,80],['Q',48,87,41,81],['L',14,58],['Q',8,52,13,44],['Z']];
  fill(P,d,C.mid);
  fill(P,[['M',43,12],['Q',48,9,54,13],['L',80,35],['Q',83,38,84,41],['L',47,60],['L',12,50],['Q',11,47,13,44],['Z']],C.light);
  fill(P,[['M',47,60],['L',84,41],['Q',84,46,82,49],['L',54,80],['Q',48,87,41,81],['L',14,58],['Q',11,55,12,50],['Z']],C.deep);
  outline(P,d);
 }
 function crystal(P){
  const d=[['M',32,13],['L',64,13],['L',78,28],['L',78,57],['L',51,83],['Q',48,86,45,83],['L',18,57],['L',18,28],['Z']];
  fill(P,d,C.mid);
  fill(P,[['M',32,13],['L',64,13],['L',59,30],['L',59,60],['L',48,85],['L',37,60],['L',37,30],['Z']],C.light);
  fill(P,[['M',64,13],['L',78,28],['L',78,57],['L',48,85],['L',59,60],['L',59,30],['Z']],C.deep);
  outline(P,d);
 }
 globalThis.DiamondIconOptions={draw:{brilliant,cushion,crystal},colors:C,main:MAIN};
})();
