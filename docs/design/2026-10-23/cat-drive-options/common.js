(function(){
  const C={ink:'#583f21',blue:'#91aaae',light:'#adc6c7',seam:'#5e7c82'};
  const reach=Math.sqrt(100**2+54**2-200*54*Math.cos(Math.PI/8));
  function output(P,a){
    P.save();P.rotate(a*180/Math.PI);
    // A curved cast push lever: broad at the shoulder, narrow at the working pin.
    P.shape([['M',3,-5],['C',15,-8,30,-9,40,-4],['Q',47,-1.8,reach,-2],['L',reach,2],['C',44,2,38,3,31,3],['Q',16,3,3,6],['Z']],{fill:C.blue,stroke:C.ink,width:2.9});
    P.shape(Pen.circle(reach,0,3.5),{fill:C.ink});
    P.shape(Pen.circle(reach,0,1.5),{fill:C.light});
    P.shape(Pen.circle(0,0,4),{fill:C.light,stroke:C.ink,width:2.9});
    P.restore();
  }
  globalThis.MachineBase={C,reach,output};
  globalThis.MachineVariants=globalThis.MachineVariants||{};
})();
