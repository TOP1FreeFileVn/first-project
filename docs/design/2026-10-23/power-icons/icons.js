(function(){
 const C={ink:'#583f21',steel:'#d6e2e4',steelLight:'#f8f0d4',gold:'#efc56e',orange:'#f0ad65',secondary:'#a5763c'};
 const MAIN=5.8,SECONDARY=3.6;
 function shape(P,d,fill,stroke=C.ink,width=MAIN){P.shape(d,{fill,stroke,width});}
 function sword(P,angle){
  P.save();P.translate(48,46);P.rotate(angle);
  const blade=[['M',0,-36],['L',9,-22],['L',8,13],['L',-8,13],['L',-9,-22],['Z']];
  shape(P,blade,C.steel,null,0);
  shape(P,[['M',0,-36],['L',0,13],['L',-8,13],['L',-9,-22],['Z']],C.steelLight,null,0);
  shape(P,blade,null);
  shape(P,Pen.rrect(-5.5,16,11,16,3),C.orange);
  shape(P,Pen.rrect(-15,10,30,9,3.5),C.gold);
  shape(P,Pen.circle(0,34,5.7),C.gold);
  P.restore();
 }
 function crossed(P){sword(P,-43);sword(P,43);}
 function fist(P){
  // One warm cat-paw silhouette. Subordinate thumb/knuckle joins only.
  const body=[['M',25,74],['Q',18,69,17,58],['L',16,35],['Q',15,24,23,22],
   ['Q',29,20,33,25],['L',34,20],['Q',36,13,43,15],['Q',48,15,50,20],
   ['Q',53,13,60,16],['Q',65,18,65,25],['Q',71,21,77,27],['Q',81,31,79,40],
   ['L',75,57],['Q',74,69,67,75],['L',64,84],['L',29,84],['Z']];
  shape(P,body,C.gold);
  shape(P,[['M',30,57],['Q',39,48,48,52],['L',59,57],['Q',63,60,61,65],['Q',59,70,53,69],['L',40,66]],null,C.secondary,SECONDARY);
  shape(P,[['M',34,27],['L',35,40]],null,C.secondary,SECONDARY);
  shape(P,[['M',50,24],['L',50,37]],null,C.secondary,SECONDARY);
  shape(P,[['M',65,28],['L',63,39]],null,C.secondary,SECONDARY);
 }
 globalThis.PowerIconOptions={draw:{crossed,fist},main:MAIN,secondary:SECONDARY,colors:C};
})();
