// Shared approved art: a standing cat holds one crank grip with BOTH paws.
// Local unit = one pixel in the production 100 px master-cell review.
(function () {
  const C={ink:'#583f21',cat:'#f2d2ac',pad:'#ca8b7b',wood:'#d5ad72',cream:'#adc6c7',metal:'#91aaae',seam:'#5e7c82'};
  const MAIN=2.9,SECONDARY=1.6;
  const DRIVE={axisY:22,radius:13.5,face:9.2,orbit:9.5,hub:3.6};
  const shape=(P,d,fill,stroke=C.ink,width=MAIN)=>P.shape(d,{fill,stroke,width});
  const line=(P,d,color,width)=>shape(P,d,null,color,width);
  function capsule(P,a,b,r,fill){
    const len=Math.hypot(b[0]-a[0],b[1]-a[1]),theta=Math.atan2(b[1]-a[1],b[0]-a[0])*180/Math.PI;
    P.save();P.translate(...a);P.rotate(theta);shape(P,Pen.rrect(-r,-r,len+2*r,2*r,r),fill);P.restore();
  }
  function roundArm(P,start,end,side){
    const radius=4.2,shoulderRadius=5.2,dx=end[0]-start[0],dy=end[1]-start[1],len=Math.hypot(dx,dy);
    let nx=-dy/len,ny=dx/len;
    if(nx*side<0){nx=-nx;ny=-ny;}
    const bulge=Math.min(3.5,len*.15),control=[(start[0]+end[0])/2+nx*bulge,(start[1]+end[1])/2+ny*bulge];
    const left=[],right=[];
    let tipNormal=0;
    for(let i=0;i<=16;i++){
      const t=i/16,u=1-t,x=u*u*start[0]+2*u*t*control[0]+t*t*end[0],y=u*u*start[1]+2*u*t*control[1]+t*t*end[1];
      const vx=u*(control[0]-start[0])+t*(end[0]-control[0]),vy=u*(control[1]-start[1])+t*(end[1]-control[1]),vl=Math.hypot(vx,vy);
      // Only the proximal attachment is fuller; taper back to the accepted
      // 4.2 px wrist rather than enlarging the entire short forearm.
      const atRadius=radius+(shoulderRadius-radius)*(1-t)*(1-t);
      left.push([x-vy/vl*atRadius,y+vx/vl*atRadius]);right.push([x+vy/vl*atRadius,y-vx/vl*atRadius]);
      if(i===16)tipNormal=Math.atan2(vx,-vy);
    }
    const outline=left.map((p,i)=>[i?'L':'M',...p]);
    // Round the wrist cap; the round paw covers its contour after gripping.
    for(let i=1;i<=8;i++){const a=tipNormal-i*Math.PI/8;outline.push(['L',end[0]+radius*Math.cos(a),end[1]+radius*Math.sin(a)]);}
    for(const p of right.slice(0,-1).reverse())outline.push(['L',...p]);
    // The tapered arm polygon is already fully opaque. Do not add an unlined
    // disk or a second tube at its root: either can extend across the existing
    // torso ink and leave a fur-coloured notch in the external silhouette.
    shape(P,[...outline,['Z']],C.cat,null,0);
    // Leave the shoulder attachment open, avoiding a ring across the fur.
    line(P,outline,C.ink,MAIN);
  }
  function sole(P,x,y,side){
    P.save();P.translate(x,y);P.rotate(side*10);
    // The visible underside of a rear paw, not a plain ball of fur.
    shape(P,Pen.circle(0,0,6.5),C.cat);
    // Four separate toe beans. Material fills do not get extra outlines.
    for(const [cx,cy,rx,ry,tilt] of [[-3.05,-1.95,.8,.95,-18],[-1.1,-3,.82,1.05,-5],[1.1,-3.05,.85,1.1,6],[3.05,-1.9,.8,.95,18]]){
      P.save();P.translate(cx,cy);P.rotate(tilt);P.transform(rx,0,0,ry,0,0);
      shape(P,Pen.circle(0,0,1),C.pad,null,0);P.restore();
    }
    // A compact mochi-like cushion: broad base, shallow organic lobes.
    shape(P,[['M',0,.45],['C',-.7,-.2,-1.5,-.4,-1.95,.25],['C',-2.45,.8,-2.25,1.25,-2.45,1.9],['C',-2.95,3,-1.75,3.65,-.75,3.45],['Q',0,3.85,.75,3.45],['C',1.75,3.65,2.95,3,2.45,1.9],['C',2.25,1.25,2.45,.8,1.95,.25],['C',1.5,-.4,.7,-.2,0,.45],['Z']],C.pad,null,0);
    P.restore();
  }
  function pose(angle){
    // A freely rotating horizontal grip on an eccentric crank pin.
    // The two paw contacts preserve their separation for the whole revolution.
    const grip=[DRIVE.orbit*Math.cos(angle),DRIVE.axisY+DRIVE.orbit*Math.sin(angle)];
    const lean=.045*Math.cos(angle),bodyX=2.6*Math.cos(angle),bodyY=.8*Math.sin(angle);
    return {grip,lean,bodyX,bodyY,contacts:[[-7+grip[0],grip[1]],[7+grip[0],grip[1]]]};
  }
  function frame(angle,option='A',mechanismOnly=false){
    const p=pose(angle),layers=[],P=new Pen();
    const flush=()=>{if(P.ops.length){layers.push({type:'paths',ops:P.ops.splice(0)});}};
    MachineVariants[option].draw(P,angle);MachineBase.output(P,angle);flush();
    if(mechanismOnly)return {layers,pose:p};
    // Tail and low body; the two upturned soles are drawn in front of the wheel.
    line(P,[['M',-14,23],['C',-36,28,-33,8,-27,15]],C.ink,8.5);
    line(P,[['M',-14,23],['C',-36,28,-33,8,-27,15]],C.cat,3.4);
    P.save();P.translate(p.bodyX,p.bodyY);P.rotate(p.lean*180/Math.PI);
    // Compress the upper torso while keeping the foot contact height fixed.
    const torso=[['M',-14,2],['Q',-20,7,-20,18],['L',-19,24],['Q',-17,30,-9,30],['L',9,30],['Q',17,30,19,24],['L',20,18],['Q',20,7,14,2]];
    shape(P,[...torso,['Z']],C.cat,null,0);line(P,torso,C.ink,MAIN);
    P.restore();
    flush();
    // Keep the existing front-face drawing; its 12 px source line fits to 2.88 px.
    layers.push({type:'head',x:p.bodyX,y:3+p.bodyY,rotation:p.lean,scale:.24});
    // Visible bearing stand and shaft: slim enough not to read as a tabletop.
    shape(P,Pen.rrect(-8,33,16,6,2.5),C.metal);
    shape(P,Pen.rrect(-3.5,DRIVE.axisY,7,15,2.5),C.metal);
    // Flywheel: one silhouette, unlined cream plane, only functional spokes.
    shape(P,Pen.circle(0,DRIVE.axisY,DRIVE.radius),C.metal);
    shape(P,Pen.circle(0,DRIVE.axisY,DRIVE.face),C.cream,null,0);
    for(let i=0;i<3;i++){
      const a=angle+i*Math.PI*2/3;
      line(P,[['M',Math.cos(a)*3.7,DRIVE.axisY+Math.sin(a)*3.7],['L',Math.cos(a)*DRIVE.face,DRIVE.axisY+Math.sin(a)*DRIVE.face]],C.seam,SECONDARY);
    }
    capsule(P,[0,DRIVE.axisY],p.grip,2.4,C.metal);
    shape(P,Pen.circle(0,DRIVE.axisY,DRIVE.hub),C.cream);
    // The entire sole (fur contour + pads) sits in front, so the wheel cannot
    // erase the inner toe beans or leave pink fills floating on the metal.
    for(const side of [-1,1])sole(P,side*15,32.5+.9*Math.sin(angle)*side,side);
    flush();
    // The wheel is in front of the belly, but behind the upper chest/armpits.
    // Restore only this short fur bridge after the wheel. Its center ends below
    // y12 even at full body bob, above the wheel's inner opening (top y12.8).
    // This leaves the central face, crank and gap between the paws untouched.
    P.save();P.translate(p.bodyX,p.bodyY);P.rotate(p.lean*180/Math.PI);
    shape(P,[['M',-13,5],['Q',0,4,13,5],['L',13,12],['Q',0,10,-13,12],['Z']],C.cat,null,0);
    P.restore();
    // Each forearm ends at an exact contact on the same long grip.
    // Use an open shoulder edge so body+limb joins do not double their ink.
    for(let i=0;i<2;i++){
      const side=i===0?-1:1,tx=p.contacts[i][0],ty=p.contacts[i][1];
      const sx=side*13.5+p.bodyX,sy=12+p.bodyY;
      roundArm(P,[sx,sy],[tx,ty],side);
    }
    // One handle with visible ends and a visible centre between the two paws.
    shape(P,Pen.rrect(p.grip[0]-14,p.grip[1]-3.5,28,7,3.5),C.wood);
    for(const [x,y] of p.contacts){
      // Nearly round mittens, without human fingers or a square wrist.
      shape(P,[['M',x,y-4.7],['C',x+2.65,y-4.7,x+4.8,y-2.6,x+4.8,y],['C',x+4.8,y+2.6,x+2.65,y+4.7,x,y+4.7],['C',x-2.65,y+4.7,x-4.8,y+2.6,x-4.8,y],['C',x-4.8,y-2.6,x-2.65,y-4.7,x,y-4.7],['Z']],C.cat);
    }
    flush();
    return {layers,pose:p};
  }
  function draw(ctx,head,angle,option='A',mechanismOnly=false){
    for(const layer of frame(angle,option,mechanismOnly).layers){
      if(layer.type==='paths')Pen.toCanvas(layer.ops,ctx);
      else {ctx.save();ctx.translate(layer.x,layer.y);ctx.rotate(layer.rotation);ctx.scale(layer.scale,layer.scale);ctx.drawImage(head,-128,-144);ctx.restore();}
    }
  }
  globalThis.TwoHandDrive={draw,frame,pose,dimensions:DRIVE,main:MAIN,secondary:SECONDARY};
})();
