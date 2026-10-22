(function(){
  const C={ink:'#583f21',blue:'#91aaae',light:'#adc6c7',seam:'#5e7c82'};
  const reach=Math.sqrt(100**2+54**2-200*54*Math.cos(Math.PI/8));
  const arm={root:15,baseHalf:15,tipRadius:2.5};
  function output(P,a){
    P.save();P.rotate(a*180/Math.PI);
    // Original fat triangle, now one continuous silhouette with a blunt end.
    // No separate end circle, dot, rivet, cap or contrasting marker.
    P.shape([['M',15,-15],['L',reach,-2.5],['L',reach,2.5],['L',15,15],['Z']],{fill:C.blue,stroke:C.ink,width:3});
    P.restore();
  }
  globalThis.MachineBase={C,reach,arm,output};
  globalThis.MachineVariants={};
})();
