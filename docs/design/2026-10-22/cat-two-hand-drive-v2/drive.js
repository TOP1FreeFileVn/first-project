// Concept only: a standing cat holds one crank grip with BOTH paws.
// Local unit = one pixel in the production 100 px master-cell review.
(function () {
  const C={ink:'#583f21',cat:'#f2d2ac',wood:'#d5ad72',cream:'#f4dfb4',metal:'#93adae',seam:'#92764e'};
  const MAIN=2.9,SECONDARY=1.6;
  const DRIVE={axisY:22,radius:13.5,face:9.2,orbit:9.5,hub:3.6};
  const shape=(P,d,fill,stroke=C.ink,width=MAIN)=>P.shape(d,{fill,stroke,width});
  const line=(P,d,color,width)=>shape(P,d,null,color,width);
  function capsule(P,a,b,r,fill){
    const len=Math.hypot(b[0]-a[0],b[1]-a[1]),theta=Math.atan2(b[1]-a[1],b[0]-a[0])*180/Math.PI;
    P.save();P.translate(...a);P.rotate(theta);shape(P,Pen.rrect(-r,-r,len+2*r,2*r,r),fill);P.restore();
  }
  function pose(angle){
    // A freely rotating horizontal grip on an eccentric crank pin.
    // The two paw contacts preserve their separation for the whole revolution.
    const grip=[DRIVE.orbit*Math.cos(angle),DRIVE.axisY+DRIVE.orbit*Math.sin(angle)];
    const lean=.045*Math.cos(angle),bodyX=2.6*Math.cos(angle),bodyY=.8*Math.sin(angle);
    return {grip,lean,bodyX,bodyY,contacts:[[-7+grip[0],grip[1]],[7+grip[0],grip[1]]]};
  }
  function frame(angle){
    const p=pose(angle),layers=[],P=new Pen();
    const flush=()=>{if(P.ops.length){layers.push({type:'paths',ops:P.ops.splice(0)});}};
    // Tail, standing body, separate weight-bearing feet. No table or mill housing.
    line(P,[['M',-14,23],['C',-36,28,-33,8,-27,15]],C.ink,8.5);
    line(P,[['M',-14,23],['C',-36,28,-33,8,-27,15]],C.cat,3.4);
    P.save();P.translate(p.bodyX,p.bodyY);P.rotate(p.lean*180/Math.PI);
    // Compress the upper torso while keeping the foot contact height fixed.
    const torso=[['M',-14,-4],['Q',-20,1,-20,12],['L',-19,24],['Q',-17,30,-9,30],['L',9,30],['Q',17,30,19,24],['L',20,12],['Q',20,1,14,-4]];
    shape(P,[...torso,['Z']],C.cat,null,0);line(P,torso,C.ink,MAIN);
    P.restore();
    for(const side of [-1,1]){
      const shift=.9*Math.sin(angle)*side;
      shape(P,Pen.rrect(side*15-7,29+shift,14,10,5),C.cat);
    }
    flush();
    // Keep the existing front-face drawing; its 12 px source line fits to 2.88 px.
    layers.push({type:'head',x:p.bodyX,y:-3+p.bodyY,rotation:p.lean,scale:.24});
    // Visible bearing stand and shaft: slim enough not to read as a tabletop.
    shape(P,Pen.rrect(-8,33,16,6,2.5),C.wood);
    shape(P,Pen.rrect(-3.5,DRIVE.axisY,7,15,2.5),C.metal);
    // Flywheel: one silhouette, unlined cream plane, only functional spokes.
    shape(P,Pen.circle(0,DRIVE.axisY,DRIVE.radius),C.wood);
    shape(P,Pen.circle(0,DRIVE.axisY,DRIVE.face),C.cream,null,0);
    for(let i=0;i<3;i++){
      const a=angle+i*Math.PI*2/3;
      line(P,[['M',Math.cos(a)*3.7,DRIVE.axisY+Math.sin(a)*3.7],['L',Math.cos(a)*DRIVE.face,DRIVE.axisY+Math.sin(a)*DRIVE.face]],C.seam,SECONDARY);
    }
    capsule(P,[0,DRIVE.axisY],p.grip,2.4,C.metal);
    shape(P,Pen.circle(0,DRIVE.axisY,DRIVE.hub),C.cream);
    flush();
    // Each forearm ends at an exact contact on the same long grip.
    // Use an open shoulder edge so body+limb joins do not double their ink.
    for(let i=0;i<2;i++){
      const side=i===0?-1:1,tx=p.contacts[i][0],ty=p.contacts[i][1];
      const sx=side*13.5+p.bodyX,sy=6+p.bodyY;
      const ex=sx+side*(3.5+Math.sin(angle)),ey=(sy+ty)/2+2;
      shape(P,[['M',sx-side*3,sy-1],['Q',ex-side*3,ey-2,tx-3,ty-1],
        ['Q',tx-3,ty+5,tx+3,ty+3],['Q',ex+side*5,ey+6,sx+side*4,sy+2]],C.cat,null,0);
      line(P,[['M',sx-side*3,sy-1],['Q',ex-side*3,ey-2,tx-3,ty-1]],C.ink,MAIN);
      line(P,[['M',tx+3,ty+3],['Q',ex+side*5,ey+6,sx+side*4,sy+2]],C.ink,MAIN);
    }
    // One handle with visible ends and a visible centre between the two paws.
    shape(P,Pen.rrect(p.grip[0]-14,p.grip[1]-3.5,28,7,3.5),C.wood);
    for(const [x,y] of p.contacts){
      shape(P,[['M',x-4.1,y-2],['Q',x-4.2,y-5.5,x-.5,y-5.5],['Q',x+4.1,y-5.5,x+4.1,y-1],['L',x+4.1,y+2],['Q',x+3.4,y+6,x-.6,y+5.4],['Q',x-4.1,y+5,x-4.1,y+1],['Z']],C.cat);
    }
    flush();
    return {layers,pose:p};
  }
  function draw(ctx,head,angle){
    for(const layer of frame(angle).layers){
      if(layer.type==='paths')Pen.toCanvas(layer.ops,ctx);
      else {ctx.save();ctx.translate(layer.x,layer.y);ctx.rotate(layer.rotation);ctx.scale(layer.scale,layer.scale);ctx.drawImage(head,-128,-144);ctx.restore();}
    }
  }
  globalThis.TwoHandDrive={draw,frame,pose,dimensions:DRIVE,main:MAIN,secondary:SECONDARY};
})();
