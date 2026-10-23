(function(){
 const C={ink:'#583f21',gold:'#f5c65d',light:'#ffe3a0',deep:'#d79a3e',stamp:'#b47a2c'};
 const MAIN=5.8;
 const fill=(P,d,color)=>P.shape(d,{fill:color});
 const outline=(P,d)=>P.shape(d,{stroke:C.ink,width:MAIN});
 function cog(cx,cy,outer,root){
  const d=[];
  for(let tooth=0;tooth<8;tooth++){
   for(const [angle,r] of [[-22.5,root],[-14,root],[-10,outer],[10,outer],[14,root]]){
    const rad=(tooth*45+angle-90)*Math.PI/180;
    d.push([d.length?'L':'M',cx+Math.cos(rad)*r,cy+Math.sin(rad)*r]);
   }
  }
  d.push(['Z']);return d;
 }
 function stamp(P,cx,cy,r){
  fill(P,cog(cx,cy,r,r*.76),C.stamp);
  fill(P,Pen.circle(cx,cy,r*.32),C.light);
 }
 function coin(P){
  const rim=Pen.circle(48,48,36.5);
  fill(P,rim,C.gold);
  fill(P,Pen.circle(48,48,24.5),C.light);
  stamp(P,48,48,21);
  outline(P,rim);
 }
 function gear(P){
  const rim=cog(48,48,39,31.5);
  fill(P,rim,C.gold);
  fill(P,Pen.circle(48,48,21.5),C.light);
  fill(P,Pen.circle(48,48,8),C.deep);
  outline(P,rim);
 }
 function pair(P){
  const rear=Pen.circle(37,35,25.5);
  fill(P,rear,C.deep);
  fill(P,Pen.circle(37,35,16),C.gold);
  outline(P,rear);
  const front=Pen.circle(58,58,27.5);
  fill(P,front,C.gold);
  fill(P,Pen.circle(58,58,18),C.light);
  stamp(P,58,58,15.5);
  outline(P,front);
 }
 globalThis.GoldIconOptions={draw:{coin,gear,pair},colors:C,main:MAIN};
})();
