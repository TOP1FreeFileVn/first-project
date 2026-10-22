// Familiar hand-driven machines. Rear art only; the shared fat pusher stays separate.
(function () {
  const C={ink:'#583f21',blue:'#91aaae',light:'#adc6c7',seam:'#5e7c82',wood:'#c79c66',rope:'#e2cba1'};
  const MAIN=2.9,SECONDARY=1.6;
  const shape=(P,d,fill,stroke=C.ink,width=MAIN)=>P.shape(d,{fill,stroke,width});
  const line=(P,d,stroke=C.seam,width=SECONDARY)=>shape(P,d,null,stroke,width);
  function ellipse(x,y,rx,ry){return Pen.circle(0,0,1).map(([op,...a])=>[op,...a.map((n,i)=>n*(i%2?ry:rx)+(i%2?y:x))]);}
  function turnedEllipse(P,x,y,rx,ry,angle,fill,stroke=C.ink,width=MAIN){
    P.save();P.translate(x,y);P.rotate(angle);shape(P,ellipse(0,0,rx,ry),fill,stroke,width);P.restore();
  }
  globalThis.MachineVariants ||= {};
  Object.assign(MachineVariants,{
    E:{title:'Máy câu cuộn cước',source:'Máy câu spinning quay tay',idea:'Ống cuộn có hai vành, cần gạt dây vòng cung và chân kẹp cần câu.',draw(P,a){
      // The reel foot and bent stem distinguish a reel from a generic flywheel.
      shape(P,Pen.rrect(-28,-39,42,6,2.4),C.blue);
      shape(P,[['M',-10,-33],['L',-4,-33],['Q',-4,-12,10,2],['L',4,9],['Q',-14,-11,-10,-33],['Z']],C.blue);
      shape(P,[['M',-8,0],['Q',8,-9,22,1],['L',27,15],['Q',10,23,-4,14],['Q',-11,9,-8,0],['Z']],C.blue);
      // Horizontal wound spool, with the right flange exposed beyond the cat.
      shape(P,ellipse(14,-5,7.5,15),C.blue);
      shape(P,[['M',14,-17],['L',29,-17],['Q',35,-5,29,7],['L',14,7],['Q',21,-5,14,-17],['Z']],C.rope);
      shape(P,ellipse(29,-5,8.2,15),C.light);
      shape(P,ellipse(29,-5,5.6,11.3),C.rope,null,0);
      for(const x of [26.5,29.5,32.3])line(P,[['M',x,-13.5],['Q',x+3,-5,x,3.5]],C.wood,SECONDARY);
      // A fixed-looking bail rotates around the spool: its projected bow opens/closes.
      const bow=3.1*Math.cos(a);
      line(P,[['M',11,10],['Q',37,18,39,-4],['Q',40.5,-24,25+bow,-25],['Q',14,-26,11,-15]],C.ink,MAIN);
      shape(P,Pen.circle(12,10,2.5),C.blue);
      // Crank-axis collar; the shared handle and pusher are drawn by the composition.
      shape(P,Pen.circle(0,0,6.5),C.light);
    }},
    F:{title:'Bơm nước quay tay',source:'Bơm nước gang quay tay, thân đứng và vòi cong',idea:'Thân bơm đứng, vòi cong chúc xuống và chân đế thấp; màu xanh xám của gang sơn.',draw(P,a){
      // A real pump silhouette: casting, upright outlet and a downward-facing spout.
      shape(P,Pen.rrect(-34,31,68,7,2.5),C.blue);
      shape(P,[['M',-15,28],['L',-17,9],['Q',-18,-6,-6,-14],['Q',7,-23,17,-10],
        ['L',18,-25],['Q',18,-29,24,-29],['L',28,-29],['Q',32,-29,32,-23],['L',32,29],
        ['L',23,32],['L',-9,32],['Q',-15,32,-15,28],['Z']],C.blue);
      shape(P,[['M',25,-25],['Q',29,-39,37,-33],['Q',40.5,-30,40,-22],['L',40,-16],
        ['L',33,-16],['L',33,-23],['Q',34,-27,31,-27],['L',28,-20],['Z']],C.blue);
      shape(P,Pen.rrect(31.5,-18,9,4.5,1.3),C.light);
      shape(P,[['M',23,-22],['L',28,-22],['L',28,27],['L',23,27],['Z']],C.light,null,0);
      shape(P,Pen.circle(0,0,13.5),C.light);
      shape(P,Pen.circle(0,0,7),C.blue,null,0);
      // A subtle rotating axis key, rather than a separate output crank.
      const u=[Math.cos(a)*6,Math.sin(a)*6];
      line(P,[['M',-u[0],-u[1]],['L',u[0],u[1]]],C.seam,SECONDARY);
      line(P,[['M',35,-14.5],['L',39,-14.5]],C.seam,SECONDARY);
    }},
    G:{title:'Guồng quấn len gỗ',source:'Guồng quấn sợi len bốn tay có cọc giữ bối',idea:'Bốn thanh gỗ thẳng, cọc chặn ngang và các vòng len căng thành bối; guồng quay trên giá nhỏ.',draw(P,a){
      // The support stays fixed; only the wooden reel and the wound skein rotate.
      shape(P,Pen.rrect(-6,-2,12,38,3),C.blue);
      shape(P,Pen.rrect(-19,33,38,5.5,2.5),C.blue);
      P.save();P.rotate(a*180/Math.PI);
      shape(P,Pen.rrect(-4,-35,8,70,1.5),C.wood);
      shape(P,Pen.rrect(-35,-4,70,8,1.5),C.wood);
      // Peg crossbars hold a wound skein, unlike four propeller petals.
      for(let i=0;i<4;i++){
        P.save();P.rotate(i*90);
        shape(P,Pen.rrect(-7,-35,14,6,1.5),C.wood);
        P.restore();
      }
      for(const r of [30,32.5,35]){
        const d=[['M',0,-r],['L',r,0],['L',0,r],['L',-r,0],['Z']];
        line(P,d,C.rope,SECONDARY);
      }
      shape(P,Pen.circle(0,0,7),C.blue);
      shape(P,Pen.circle(0,0,2.3),C.light,null,0);
      P.restore();
    }},
    H:{title:'Máy hát loa kèn',source:'Máy hát đĩa loa kèn quay tay',idea:'Hộp máy thấp, đĩa quay và loa kèn loe lớn bên trên; nhận ra đồ vật ngay cả khi mèo che giữa.',draw(P,a){
      // Large flared horn, not a ring around the character's head.
      shape(P,[['M',10,15],['Q',29,6,24,-12],['L',39,-28],['Q',23,-42,7,-38],
        ['Q',18,-22,17,-13],['Q',22,1,8,8],['Z']],C.blue);
      turnedEllipse(P,22.5,-33.8,17.5,7.8,20,C.light);
      turnedEllipse(P,22.5,-33.8,13.4,4.6,20,C.seam,null,0);
      // Low music-box case and an actual turntable, with a side-mounted tonearm.
      shape(P,Pen.rrect(-35,20,70,18,4),C.blue);
      shape(P,[['M',-31,27],['L',31,27],['L',31,33],['L',-31,33],['Z']],C.light,null,0);
      shape(P,ellipse(0,19,29,5),C.light);
      shape(P,ellipse(0,18.7,23,3.6),C.seam,null,0);
      const x=20*Math.cos(a),y=18.7+2.7*Math.sin(a);
      line(P,[['M',x*.7,18.7+(y-18.7)*.7],['L',x,y]],C.light,SECONDARY);
      line(P,[['M',27,21],['L',26,12],['Q',25,9,20,11],['L',9,16]],C.ink,MAIN);
      shape(P,Pen.rrect(6.5,14.5,6.5,3,1.3),C.blue);
    }},
  });
})();
