(function(){
 const ink='#583f21',blue='#91aaae',light='#adc6c7',seam='#5e7c82',MAIN=2.9,SECONDARY=1.6;
 const s=(P,d,fill=blue,stroke=ink,width=MAIN)=>P.shape(d,{fill,stroke,width});
 function bar(P,a,b,r,fill=blue){const dx=b[0]-a[0],dy=b[1]-a[1],len=Math.hypot(dx,dy);P.save();P.translate(...a);P.rotate(Math.atan2(dy,dx)*180/Math.PI);s(P,Pen.rrect(-r,-r,len+2*r,2*r,r),fill);P.restore();}
 function hollowCircle(r,inner){const outer=Pen.circle(0,0,r),c=inner*.5523;return [...outer,['M',0,-inner],['C',-c,-inner,-inner,-c,-inner,0],['C',-inner,c,-c,inner,0,inner],['C',c,inner,inner,c,inner,0],['C',inner,-c,c,-inner,0,-inner],['Z']];}
 Object.assign(globalThis.MachineVariants,{
 I:{title:'Cam chữ S',idea:'Hai cánh cong nối liền, không có vành bao.',draw(P,a){P.save();P.rotate(a*180/Math.PI);s(P,[['M',-30,-19],['C',-15,-30,-4,-16,1,-3],['C',8,12,19,17,29,10],['Q',36,6,35,15],['C',22,32,5,23,-3,6],['C',-10,-9,-20,-16,-29,-9],['Q',-38,-4,-36,-12],['Q',-35,-16,-30,-19],['Z']]);P.restore();}},
 J:{title:'Trục vít',idea:'Trục xoắn bên hông kéo bánh truyền bên trong.',draw(P,a){
  bar(P,[-30,-29],[-30,29],3.4,light);
  for(const y of [-28,28])s(P,Pen.rrect(-37,y-4,14,8,3),blue);
  // Three broad thread flights move in phase, rather than thin noisy coils.
  const offset=((a/(Math.PI*2))%1+1)%1*12;
  for(let i=0;i<3;i++){const y=-22+i*14+offset*.45;s(P,[['M',-36,y-2],['Q',-30,y-5,-24,y-3],['L',-24,y+2],['Q',-30,y,-36,y+3],['Z']],blue);}
  P.save();P.rotate(-a*180/Math.PI);s(P,Pen.rrect(-17,-17,34,34,9),light);P.restore();
 }},
 K:{title:'Guồng lồng',idea:'Vành tròn và hai nan to, như đồ chơi vận động.',draw(P,a){
  P.save();P.rotate(a*180/Math.PI);s(P,hollowCircle(35,26),blue);
  for(const deg of [25,115]){P.save();P.rotate(deg);bar(P,[-26,0],[26,0],3.2,light);P.restore();}P.restore();
  for(const side of [-1,1])s(P,Pen.rrect(side*23-4,29,8,9,3),blue);
 }},
 L:{title:'Càng kéo chữ X',idea:'Hai đòn chéo đóng mở, bốn đầu bo tròn.',draw(P,a){
  const x=25+4*Math.sin(a),y=24-3*Math.sin(a);
  bar(P,[-x,-y],[x,y],3.6,blue);bar(P,[x,-y],[-x,y],3.6,light);
  for(const xx of [-x,x])for(const yy of [-y,y])s(P,Pen.circle(xx,yy,4.4),blue);
 }}
 });
})();
