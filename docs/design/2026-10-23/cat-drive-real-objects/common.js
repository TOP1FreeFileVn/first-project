(function(){
  const C={ink:'#583f21',blue:'#91aaae',light:'#adc6c7',seam:'#5e7c82',wood:'#d5ad72',rope:'#e8cfa4'};
  const reach=Math.sqrt(100**2+54**2-200*54*Math.cos(Math.PI/8));
  // Geometry copied from CogDraw.draw_orb: original broad triangular/trapezoid
  // drive arm, with unchanged root, base half-width, pin centre and tip radius.
  const arm={root:15,baseHalf:15,tipRadius:2.5};
  function output(P,a){
    P.save();P.rotate(a*180/Math.PI);
    P.shape([['M',arm.root,-arm.baseHalf],['L',reach,-arm.tipRadius],['L',reach,arm.tipRadius],['L',arm.root,arm.baseHalf],['Z']],{fill:C.blue,stroke:C.ink,width:3});
    P.shape(Pen.circle(reach,0,arm.tipRadius+1),{fill:C.ink});
    P.shape(Pen.circle(reach,0,arm.tipRadius-1),{fill:C.light});
    P.restore();
  }
  globalThis.MachineBase={C,reach,arm,output};
  globalThis.MachineVariants={};
})();
