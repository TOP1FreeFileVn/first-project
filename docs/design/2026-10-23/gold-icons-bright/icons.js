(function(){
 const C={ink:'#583f21',gold:'#ffda20',light:'#ffe963',edge:'#f5ae06',stamp:'#cd8800'};
 const MAIN=5.8,SECONDARY=3.1,STACK_SEAM=3.5;
 const fill=(P,d,color)=>P.shape(d,{fill:color});
 const outline=(P,d)=>P.shape(d,{stroke:C.ink,width:MAIN});
 function ellipse(cx,cy,rx,ry){
  const k=.5523;
  return [['M',cx,cy-ry],['C',cx+rx*k,cy-ry,cx+rx,cy-ry*k,cx+rx,cy],['C',cx+rx,cy+ry*k,cx+rx*k,cy+ry,cx,cy+ry],['C',cx-rx*k,cy+ry,cx-rx,cy+ry*k,cx-rx,cy],['C',cx-rx,cy-ry*k,cx-rx*k,cy-ry,cx,cy-ry],['Z']];
 }
 function gear(cx,cy,r){
  const d=[];
  for(let tooth=0;tooth<8;tooth++)for(const [a,k] of [[-22.5,.75],[-14,.75],[-10,1],[10,1],[14,.75]]){
   const t=(tooth*45+a-90)*Math.PI/180;
   d.push([d.length?'L':'M',cx+Math.cos(t)*r*k,cy+Math.sin(t)*r*k]);
  }
  d.push(['Z']);return d;
 }
 function stamp(P,cx,cy,r){
  fill(P,gear(cx,cy,r),C.stamp);
  fill(P,Pen.circle(cx,cy,r*.32),C.gold);
 }
 function classic(P){
  const rim=Pen.circle(48,48,37);
  fill(P,rim,C.edge);
  fill(P,Pen.circle(48,48,30.5),C.gold);
  stamp(P,48,48,15);
  outline(P,rim);
 }
 function tilted(P){
  P.save();P.translate(48,48);P.rotate(22);P.translate(-48,-48);
  const body=[['M',44,12.5],['L',52,12.5],['C',67.46,12.5,80,28.39,80,48],['C',80,67.61,67.46,83.5,52,83.5],['L',44,83.5],['C',28.54,83.5,16,67.61,16,48],['C',16,28.39,28.54,12.5,44,12.5],['Z']];
  fill(P,body,C.edge);
  const front=ellipse(44,48,28,35.5);
  fill(P,front,C.gold);
  P.shape(front,{stroke:C.stamp,width:SECONDARY});
  P.save();P.translate(44,48);P.transform(.76,0,0,1,0,0);stamp(P,0,0,14);P.restore();
  outline(P,body);
  P.restore();
 }
 function stack(P){
  const body=[['M',14,29],['C',14,9,82,9,82,29],['L',82,65],['C',82,85,14,85,14,65],['Z']];
  fill(P,body,C.edge);
  fill(P,ellipse(48,29,34,14),C.gold);
  for(const y of [45,61])P.shape([['M',16,y],['C',19,y+16,77,y+16,80,y]],{stroke:C.stamp,width:STACK_SEAM});
  P.shape([['M',14,29],['C',14,48,82,48,82,29]],{stroke:C.stamp,width:SECONDARY});
  P.save();P.translate(48,29);P.transform(1,0,0,.42,0,0);stamp(P,0,0,16);P.restore();
  outline(P,body);
 }
 globalThis.BrightGoldOptions={draw:{classic,tilted,stack},colors:C,main:MAIN,secondary:SECONDARY};
})();
