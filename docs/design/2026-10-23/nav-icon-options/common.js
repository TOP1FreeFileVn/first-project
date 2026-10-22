(function(){
  const C = {
    ink:'#583f21', seam:'#92714e', cream:'#fff2cc', white:'#fffaf1',
    steel:'#dce6eb', steel2:'#b5cbd3', blue:'#73b5cb', blueDark:'#4285aa',
    gold:'#f7cb69', ochre:'#c78e4e', wood:'#d4a36b', red:'#ef7767',
    ginger:'#f5ad62', pink:'#f5b7a3', green:'#9fc996', paper:'#e8bf80'
  };
  const S = { main:7.5, secondary:4.2 };
  const shape=(p,d,fill=null,role='main',ink=null)=>p.shape(d,{fill,stroke:role==='none'?null:(ink||(role==='secondary'?C.seam:C.ink)),width:role==='main'?S.main:role==='secondary'?S.secondary:0});
  const rect=(p,x,y,w,h,r,fill,role='main',ink=null)=>shape(p,Pen.rrect(x,y,w,h,r),fill,role,ink);
  const circle=(p,x,y,r,fill,role='main',ink=null)=>shape(p,Pen.circle(x,y,r),fill,role,ink);
  function paw(p,x,y,s,fill=C.ochre){p.save();p.translate(x,y);p.scale(s);shape(p,[['M',-13,9],['C',-13,1,-8,-3,-5,-5],['Q',0,-12,5,-5],['C',8,-3,13,1,13,9],['Q',13,16,6,13],['Q',0,10,-6,13],['Q',-13,16,-13,9],['Z']],fill,'none');for(const [a,b,r]of [[-13,-7,4.2],[-5,-15,4.2],[5,-15,4.2],[13,-7,4.2]])circle(p,a,b,r,fill,'none');p.restore();}
  function face(p,x=100,y=111,s=1){p.save();p.translate(x,y);p.scale(s);circle(p,-23,-5,5.2,C.ink,'none');circle(p,23,-5,5.2,C.ink,'none');shape(p,[['M',-12,8],['Q',-6,19,0,9],['Q',6,19,12,8]],null,'secondary',C.ink);p.restore();}
  globalThis.NavArt={C,S,shape,rect,circle,paw,face};
  globalThis.NavOptions={};
})();
