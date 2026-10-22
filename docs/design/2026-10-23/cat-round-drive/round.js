(function(){
  const C=MachineBase.C;
  globalThis.MachineVariants.A={
    title:'Trục tròn quay',
    source:'Trục tròn đơn giản như hướng ban đầu',
    idea:'Đĩa tròn xanh xám sau mèo, tam giác béo liền khối; bỏ chấm tròn ở đầu.',
    draw(P,a){
      P.shape(Pen.circle(0,0,34),{fill:C.blue,stroke:C.ink,width:2.9});
      // A flat, unlined face and three quiet structural spokes reveal rotation.
      P.shape(Pen.circle(0,0,26.5),{fill:C.light});
      for(let i=0;i<3;i++){
        const t=a+i*Math.PI*2/3;
        P.shape([['M',Math.cos(t)*5,Math.sin(t)*5],['L',Math.cos(t)*27,Math.sin(t)*27]],{stroke:C.seam,width:1.6});
      }
      P.shape(Pen.circle(0,0,6),{fill:C.blue});
    }
  };
})();
