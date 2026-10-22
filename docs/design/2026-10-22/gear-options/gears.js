// Review proposals only. One path list is shared by Canvas and SVG.
(function () {
  const INK = '#583f21', SEAM = '#9b784b';
  const MAIN = 3.2, SECONDARY = 1.9;
  const point = (a,r) => [Math.cos(a*Math.PI/180)*r, Math.sin(a*Math.PI/180)*r];
  function rounded(points,r=1.8) {
    const corners=points.map((p,i)=>{
      const a=points[(i+points.length-1)%points.length], b=points[(i+1)%points.length];
      const la=Math.hypot(a[0]-p[0],a[1]-p[1]),lb=Math.hypot(b[0]-p[0],b[1]-p[1]);
      const d=Math.min(r,la*.32,lb*.32);
      return {p, a:[p[0]+(a[0]-p[0])*d/la,p[1]+(a[1]-p[1])*d/la],b:[p[0]+(b[0]-p[0])*d/lb,p[1]+(b[1]-p[1])*d/lb]};
    });
    const path=[['M',...corners[0].a]];
    for(let i=0;i<corners.length;i++) {
      const c=corners[i];
      if(i)path.push(['L',...c.a]);
      path.push(['Q',...c.p,...c.b]);
    }
    path.push(['Z']);return path;
  }
  function profile(samples,r) {
    const pts=[];
    for(let i=0;i<8;i++)for(const [a,d] of samples)pts.push(point(a+i*45,d));
    return rounded(pts,r);
  }
  const formA=profile([[-22.5,37],[-15.5,43],[-11,43],[-10,54],[10,54],[11,43],[15.5,43]],2);
  // Selected B, fitted to the actual pin sweep and adjacent gear clearance.
  // The trapezoid caps and broad face remain; only root/flank clearance changes.
  const B_FIT={root:36.5,shoulder:43,flankAngle:14,capAngle:5.5,round:2.4};
  const formB=profile([[-22.5,B_FIT.root],[-B_FIT.flankAngle,B_FIT.shoulder],
    [-B_FIT.capAngle,54],[B_FIT.capAngle,54],[B_FIT.flankAngle,B_FIT.shoulder]],B_FIT.round);
  const formC=profile([[-22.5,36.5],[-20,44],[-16,54],[1,54],[11,47],[17,38]],3.1);
  function base(P,path,fill) {P.shape(path,{fill,stroke:INK,width:MAIN});}
  const defs={
    A:{title:'Răng khối bo',subtitle:'Răng ngắn, bản rộng · gọn và chắc',draw(P,fill){
      base(P,formA,fill);
      // Surface ring is subordinate to the exposed silhouette.
      P.shape(Pen.circle(0,0,35.8),{stroke:SEAM,width:SECONDARY});
    }},
    B:{title:'Bánh đúc',subtitle:'Khối tròn lớn · răng hình thang thấp',draw(P,fill){
      base(P,formB,fill);
      // Broad unlined face, not a highlight stroke.
      P.shape(Pen.circle(0,0,34),{fill:'#f4dfb4'});
    }},
    C:{title:'Răng cong',subtitle:'Răng quét nhẹ · cảm giác chuyển động',draw(P,fill){
      base(P,formC,fill);
      P.shape(Pen.circle(0,0,35),{stroke:SEAM,width:SECONDARY});
    }},
  };
  globalThis.GearOptions={defs,main:MAIN,secondary:SECONDARY,ink:INK,selectedProfile:B_FIT};
})();
