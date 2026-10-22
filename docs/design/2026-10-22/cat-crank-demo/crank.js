// Proposal only: the front-facing lobby cat runs a tiny hand mill.
// Pin centre/reach, gear grid and production art are not changed.
(function(){
 const C={ink:'#583f21',cream:'#f2d2ac',wood:'#cfa466',top:'#e8c080',tape:'#f7dfad',seam:'#a57a48',pin:'#e7a957'};
 const MAIN=3.2,SECONDARY=1.9,REACH=54.204486;
 const path=(P,d,fill,stroke=C.ink,width=MAIN)=>P.shape(d,{fill,stroke,width});
 function ellipse(cx,cy,rx,ry){const d=Pen.circle(0,0,1);return d.map(([op,...a])=>[op,...a.map((n,i)=>n*(i%2?ry:rx)+(i%2?cy:cx))]);}
 function geometry(angle){
  const P=new Pen();
  const c=Math.cos(angle),s=Math.sin(angle),tip=[REACH*c,REACH*s];
  // Keep the real mechanical drive under the station. Only its outer tip shows.
  path(P,[['M',-s*6,c*6],['L',tip[0]-s*2.5,tip[1]+c*2.5],['L',tip[0]+s*2.5,tip[1]-c*2.5],['L',s*6,-c*6],['Z']],C.pin,C.ink,3);
  path(P,Pen.circle(...tip,2.5),C.top,C.ink,2);
  return P.ops;
 }
 function mill(){
  const P=new Pen();
  // A shallow warm wooden/cardboard housing, not a new gear or a building.
  path(P,[['M',-24,14],['Q',-26,17,-23,30],['L',-21,36],['Q',0,42,21,36],['L',24,17],['Q',24,14,22,14],['Z']],C.wood);
  path(P,[['M',-23,26],['Q',0,31,23,26],['L',22,30],['Q',0,35,-22,30],['Z']],C.tape,null,0);
  path(P,ellipse(0,14,24,7),C.top);
  path(P,ellipse(0,15,15,3.4),'#bb915b',null,0);
  return P.ops;
 }
 function crank(angle){
  const P=new Pen();
  const x=9*Math.cos(angle),y=12+4*Math.sin(angle);
  path(P,[['M',0,17],['L',0,10],['L',x,y]],null,C.ink,5.8);
  path(P,[['M',0,17],['L',0,10],['L',x,y]],null,C.wood,2.6);
  path(P,Pen.rrect(x-9,y-2,18,4,1.5),C.top,C.ink,2.5);
  return {ops:P.ops,x,y};
 }
 function arms(angle,bob){
  const P=new Pen(),grip=crank(angle);
  for(const side of [-1,1]){
   const sx=side*15,sy=4+bob,tx=grip.x+side*6,ty=grip.y;
   // Filled bent forearms have one silhouette; no dark stroke under a skin stroke.
   path(P,[['M',sx+side*3,sy],['Q',sx+side*6,sy+8,tx+side*3,ty+2],
    ['Q',tx,ty+5,tx-side*3,ty+1],['Q',sx-side*1,sy+4,sx-side*3,sy-1],['Z']],C.cream);
  }
  return P.ops;
 }
 function draw(ctx,parts,angle,showDrive=true){
  const bob=1.2*Math.sin(angle*2),lean=.025*Math.sin(angle);
  const play=ops=>Pen.toCanvas(ops,ctx);
  if(showDrive)play(geometry(angle));
  function catPart(name,move=true){ctx.save();ctx.translate(0,move?bob:0);if(move){ctx.translate(0,5);ctx.rotate(lean);ctx.translate(0,-5);}ctx.drawImage(parts[name],-35.84,-38,71.68,67.2);ctx.restore();}
  catPart('tail');catPart('foot_L_image',false);catPart('foot_R_image',false);catPart('body');
  play(mill());play(crank(angle).ops);play(arms(angle,bob));catPart('head');
 }
 globalThis.CatCrank={draw,geometry,mill,crank,arms,reach:REACH,main:MAIN,secondary:SECONDARY};
})();
