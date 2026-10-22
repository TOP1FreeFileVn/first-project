// Rear mechanisms only. The shared composition owns cat, hand crank and output pin.
(function () {
  const C={ink:'#583f21',blue:'#91aaae',light:'#adc6c7',seam:'#5e7c82'};
  const MAIN=2.9,SECONDARY=1.6;
  const shape=(P,d,fill,stroke=C.ink,width=MAIN)=>P.shape(d,{fill,stroke,width});
  const line=(P,d,stroke=C.seam,width=SECONDARY)=>shape(P,d,null,stroke,width);
  function ellipse(cx,cy,rx,ry){
    return Pen.circle(0,0,1).map(([op,...a])=>[op,...a.map((v,i)=>v*(i%2?ry:rx)+(i%2?cy:cx))]);
  }
  function capsule(P,a,b,r,fill){
    const angle=Math.atan2(b[1]-a[1],b[0]-a[0])*180/Math.PI,len=Math.hypot(b[0]-a[0],b[1]-a[1]);
    P.save();P.translate(...a);P.rotate(angle);shape(P,Pen.rrect(-r,-r,len+2*r,2*r,r),fill);P.restore();
  }
  function pulley(P,x,y,r,a){
    shape(P,Pen.circle(x,y,r),C.blue);
    shape(P,Pen.circle(x,y,r-3),C.light,null,0);
    for(let i=0;i<3;i++){
      const b=a+i*Math.PI*2/3;
      line(P,[['M',x+Math.cos(b)*2,y+Math.sin(b)*2],['L',x+Math.cos(b)*(r-3.4),y+Math.sin(b)*(r-3.4)]]);
    }
    shape(P,Pen.circle(x,y,2.1),C.blue,null,0);
  }
  globalThis.MachineVariants ||= {};
  Object.assign(MachineVariants,{
    E:{title:'Hai puly kéo đai',idea:'Cặp puly nối bằng hai nhánh đai; bánh trên lệch vai để thấy đường truyền động.',draw(P,a){
      const c0=[0,0],c1=[26,-16],r=10;
      const dx=c1[0],dy=c1[1],len=Math.hypot(dx,dy),nx=-dy/len,ny=dx/len;
      // A diagonal axle brace, rather than a frame around the cat.
      capsule(P,c0,c1,4.3,C.light);
      for(const side of [-1,1]){
        const x0=nx*r*side,y0=ny*r*side,x1=c1[0]+x0,y1=c1[1]+y0;
        line(P,[['M',x0,y0],['L',x1,y1]],C.ink,MAIN);
        // One short belt registration mark travels along each straight run.
        const t=((a/(Math.PI*2))*side%1+1)%1;
        const f=.12+.76*t;
        const x=x0+(x1-x0)*f,y=y0+(y1-y0)*f;
        line(P,[['M',x-dx/len*1.7,y-dy/len*1.7],['L',x+dx/len*1.7,y+dy/len*1.7]],C.light,SECONDARY);
      }
      pulley(P,...c0,r,a);pulley(P,...c1,r,a);
    }},
    F:{title:'Ống tời hai vành',idea:'Ống tời đứng với hai vành đĩa rộng, thân cuộn hẹp; chuyển động nhìn thấy trên mặt vành.',draw(P,a){
      // A vertical spool silhouette: two broad end flanges, no enclosing stand.
      shape(P,[['M',-23,-25],['L',23,-25],['L',23,24],['Q',0,32,-23,24],['Z']],C.blue);
      shape(P,[['M',-15,-23],['L',10,-23],['L',10,26],['Q',-3,29,-15,25],['Z']],C.light,null,0);
      shape(P,ellipse(0,24,31.5,7),C.blue);
      shape(P,ellipse(0,24,23,3.5),C.light,null,0);
      shape(P,ellipse(0,-25,31.5,7),C.blue);
      shape(P,ellipse(0,-25,24,3.8),C.light,null,0);
      // A pair of moving rim keys makes rotation legible without stripes on fur.
      for(const phase of [a,a+Math.PI]){
        const x=24*Math.cos(phase),y=-25+3.7*Math.sin(phase);
        line(P,[['M',x*.78,-25+(y+25)*.78],['L',x,y]],C.seam,SECONDARY);
      }
      const x=19*Math.sin(a);
      line(P,[['M',x,-18],['L',x,19]],C.seam,SECONDARY);
    }},
    G:{title:'Cặp con lăn đứng',idea:'Hai con lăn tách hai bên vai, mỗi bên có ổ đỡ riêng; khối giữa để trống cho mèo.',draw(P,a){
      // The central coupling is hidden by the cat, leaving two separate roller bodies.
      capsule(P,[-27,3],[27,3],3.7,C.light);
      for(const side of [-1,1]){
        const x=side*27;
        shape(P,Pen.rrect(x-6,-20,12,46,5),C.blue);
        shape(P,Pen.rrect(x-3,-17,6,39,3),C.light,null,0);
        // Compact bearing caps remain individual pieces, not a U-shaped chair.
        shape(P,Pen.rrect(x-8,-25,16,8,3.2),C.blue);
        shape(P,Pen.rrect(x-8,23,16,8,3.2),C.blue);
        const stripe=x+Math.sin(a*side)*3.5;
        line(P,[['M',stripe,-14],['L',stripe,19]],C.seam,SECONDARY);
        shape(P,ellipse(x,-21,3.8,1.9),C.light,null,0);
        shape(P,ellipse(x,27,3.8,1.9),C.light,null,0);
      }
    }},
    H:{title:'Cam đối trọng lưỡi liềm',idea:'Một khối cam đặc lệch tâm, quay quanh trục; dáng lưỡi liềm mở khác hẳn vành tròn.',draw(P,a){
      P.save();P.rotate(a*180/Math.PI);
      // Open crescent counterweight, no central hole or closed backrest contour.
      shape(P,[['M',-11,-32],['C',14,-34,34,-18,34,3],['C',30,22,11,35,-11,31],
        ['Q',4,24,10,13],['Q',20,-6,-11,-32],['Z']],C.blue);
      // One broad material plane, without an extra seam around every curved edge.
      shape(P,[['M',21,-21],['C',32,-13,34,1,29,14],['Q',25,23,17,28],
        ['Q',25,10,23,-2],['Q',24,-13,21,-21],['Z']],C.light,null,0);
      capsule(P,[0,0],[22,0],3.4,C.blue);
      shape(P,Pen.circle(0,0,7),C.light);
      shape(P,Pen.circle(0,0,2.4),C.blue,null,0);
      P.restore();
    }},
  });
})();
