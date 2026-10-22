// Real-object rear machines. Cat/front crank and the original broad triangular
// output pusher are supplied by the common review, not drawn in this file.
(function () {
  const C=MachineBase.C, MAIN=2.9, SECONDARY=1.6;
  const INK=C.ink, BLUE=C.blue, LIGHT=C.light, SEAM=C.seam;
  const WOOD=C.wood||'#d5ad72';
  const shape=(P,d,fill,stroke=INK,width=MAIN)=>P.shape(d,{fill,stroke,width});
  const line=(P,d,stroke=SEAM,width=SECONDARY)=>shape(P,d,null,stroke,width);
  const box=(P,x,y,w,h,r,fill=BLUE)=>shape(P,Pen.rrect(x,y,w,h,r),fill);
  const circle=(P,x,y,r,fill=LIGHT,stroke=INK,width=MAIN)=>shape(P,Pen.circle(x,y,r),fill,stroke,width);
  const ellipse=(P,x,y,rx,ry,fill=BLUE,stroke=INK,width=MAIN)=>{
    // Direct cubic ellipse preserves the same fitted line weight on both axes.
    const k=.5523;
    shape(P,[['M',x,y-ry],['C',x+rx*k,y-ry,x+rx,y-ry*k,x+rx,y],
      ['C',x+rx,y+ry*k,x+rx*k,y+ry,x,y+ry],
      ['C',x-rx*k,y+ry,x-rx,y+ry*k,x-rx,y],
      ['C',x-rx,y-ry*k,x-rx*k,y-ry,x,y-ry],['Z']],fill,stroke,width);
  };

  function ropeWinch(P,a) {
    // Two separated bearing stands, not a U-shaped frame around the cat.
    box(P,-34,-31,8,64,3,BLUE);box(P,26,-31,8,64,3,BLUE);
    box(P,-38,31,16,7,2.5,LIGHT);box(P,22,31,16,7,2.5,LIGHT);
    // A visible top drum is wrapped with rope; its horizontal axle rests on posts.
    box(P,-25,-42,50,20,4,WOOD);
    for(const x of [-15,-5,5,15]) line(P,[['M',x,-40],['Q',x-2,-32,x,-24]],INK);
    ellipse(P,-26,-32,4,12,LIGHT);ellipse(P,26,-32,4,12,LIGHT);
    line(P,[['M',26,-32],['L',26+1.6*Math.cos(a),-32+7*Math.sin(a)]],SEAM);
    // Rope runs over the right bearing and holds a small hanging bucket.
    line(P,[['M',29,-32],['L',37,-32],['L',37,6]],INK,SECONDARY);
    line(P,[['M',31,9],['Q',35.5,1,40,9]],INK,SECONDARY);
    shape(P,[['M',30,9],['L',40,9],['L',38.5,22],['Q',35,24,31.5,22],['Z']],LIGHT);
    line(P,[['M',31.5,12],['L',38.5,12]],SEAM);
  }

  function foodGrinder(P,a) {
    // Classic table-mounted crank grinder: funnel, barrel, bent outlet and clamp.
    box(P,24,-2,7,35,2.5,BLUE);box(P,12,32,26,6,2,LIGHT);
    line(P,[['M',35,10],['L',35,29]],INK,SECONDARY);
    line(P,[['M',31.5,24],['L',38.5,24]],INK,SECONDARY);
    box(P,-32,-17,64,21,6,BLUE);
    shape(P,[['M',-29,-15],['L',-37,-15],['Q',-40,-15,-40,-11],
      ['L',-40,3],['L',-30,3],['L',-30,-5],['L',-25,-5],['Z']],LIGHT);
    line(P,[['M',-38,0],['L',-32,0]],SEAM);
    // The broad hopper remains above the cat's head, so this reads as a grinder.
    shape(P,[['M',-23,-42],['L',25,-42],['L',16,-28],['L',10,-25],
      ['L',10,-14],['L',-2,-14],['L',-2,-25],['L',-14,-28],['Z']],BLUE);
    ellipse(P,1,-41.5,24,3,LIGHT);
    line(P,[['M',-13,-30],['L',15,-30]],SEAM);
    // Only the small barrel-end shaft rotates; the hopper and clamp stay fixed.
    ellipse(P,31,-6,4.5,8,LIGHT);
    line(P,[['M',31,-6],['L',31+1.8*Math.cos(a),-6+4.7*Math.sin(a)]],SEAM);
  }

  function sewingMachine(P,a) {
    // Long bed, left upright/handwheel, arched over-arm and right needle assembly.
    box(P,-39,29,78,9,3,BLUE);
    shape(P,[['M',-27,29],['L',-27,-22],['Q',-27,-42,-9,-42],
      ['L',17,-42],['Q',34,-42,34,-29],['L',34,-8],
      ['Q',34,-4,29,-4],['L',22,-4],['L',22,-19],
      ['Q',22,-26,14,-26],['L',-2,-26],['Q',-10,-26,-10,-16],
      ['L',-10,29],['Z']],BLUE);
    // Right presser-foot/needle is recognizably separate from the curved head.
    box(P,28,-9,8,8,2,LIGHT);
    line(P,[['M',32,-1],['L',32,25]],INK,SECONDARY);
    line(P,[['M',26,26],['L',38,26]],INK,SECONDARY);
    line(P,[['M',28,23],['L',28,27]],SEAM);
    // A real large side handwheel: rim fixed, three spokes turn with the crank.
    circle(P,-28.5,-10,11.5,LIGHT);
    circle(P,-28.5,-10,7.7,BLUE,null,0);
    for(let i=0;i<3;i++){
      const t=a+i*Math.PI*2/3;
      line(P,[['M',-28.5+Math.cos(t)*2.5,-10+Math.sin(t)*2.5],
        ['L',-28.5+Math.cos(t)*8.2,-10+Math.sin(t)*8.2]],SEAM);
    }
    circle(P,-28.5,-10,2.4,LIGHT,null,0);
  }

  function filmProjector(P,a) {
    // The two reels above the cat and lens outside its right cheek carry identity.
    box(P,-31,-22,62,48,5,BLUE);
    box(P,-8,24,16,8,2,LIGHT);box(P,-36,31,72,7,3,BLUE);
    line(P,[['M',-18,-31],['L',-22,-13]],INK,SECONDARY);
    line(P,[['M',18,-31],['L',22,-13]],INK,SECONDARY);
    for(const x of [-18,18]){
      circle(P,x,-31,12.2,LIGHT);
      // Reel perforations rotate around the fixed spindle, instead of orbiting
      // the whole projector. Quiet material-colored holes remain readable small.
      for(let i=0;i<3;i++){
        const t=a+i*Math.PI*2/3;
        circle(P,x+Math.cos(t)*6.9,-31+Math.sin(t)*6.9,2.5,SEAM,null,0);
      }
      circle(P,x,-31,2,BLUE,null,0);
    }
    box(P,25,-8,11,18,2,LIGHT);
    shape(P,[['M',35,-9],['L',40,-12],['L',40,14],['L',35,11],['Z']],BLUE);
    line(P,[['M',39,-8],['L',39,10]],SEAM);
    // One film-access seam on the casing; the rest is left plain for the cat.
    line(P,[['M',-26,-13],['L',-26,17]],SEAM);
  }

  globalThis.MachineVariants ||= {};
  Object.assign(globalThis.MachineVariants,{
    A:{title:'Tời kéo xô',idea:'Cuộn dây lớn trên hai gối đỡ, dây buông xuống chiếc xô bên phải.',source:'Tời cuộn dây quay tay và xô kéo nước.',draw:ropeWinch},
    B:{title:'Máy xay quay tay',idea:'Phễu nạp phía trên, ống xay nằm ngang, vòi ra và chân vít kẹp bàn.',source:'Máy xay thực phẩm bằng gang quay tay.',draw:foodGrinder},
    C:{title:'Máy khâu cổ',idea:'Thân cổ cong, bánh đà bên trái, kim và bàn ép bên phải.',source:'Máy may cơ tay quay với thân cổ ngỗng và bánh đà.',draw:sewingMachine},
    D:{title:'Máy chiếu phim',idea:'Hai cuộn phim nổi trên đầu, ống kính nhô bên phải, thân máy có chân đế.',source:'Máy chiếu phim quay tay hai cuộn đầu thế kỷ20.',draw:filmProjector},
  });
})();
