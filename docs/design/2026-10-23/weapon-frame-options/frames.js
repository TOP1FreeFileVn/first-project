(function () {
  const C={ink:'#583f21',carton:'#dab47a',paper:'#ead4aa',steel:'#c5cfda',steelEdge:'#a7b4c3'};
  const TONES={green:'#9ccc80',blue:'#83bad4',purple:'#b193d0',orange:'#eab17c'};
  const shape=(P,d,fill,stroke=C.ink,width=3.2)=>P.shape(d,{fill,stroke,width});
  const rect=(P,x,y,w,h,r,fill,stroke=null,width=0)=>shape(P,Pen.rrect(x,y,w,h,r),fill,stroke,width);
  const bevel=[['M',18,2],['L',106,2],['L',122,18],['L',122,106],['L',106,122],['L',18,122],['L',2,106],['L',2,18],['Z']];
  function tray(P,tone) {
    shape(P,[['M',13,2],['L',111,2],['L',122,13],['L',122,111],['L',111,122],['L',13,122],['L',2,111],['L',2,13],['Z']],C.carton);
    rect(P,12,12,100,100,7,tone);
    // Broad unlined material patches, no pseudo-depth or offset underlay.
    rect(P,16,2.8,20,8,1,C.paper);
    rect(P,89,113.2,18,7.2,1,C.paper);
  }
  function steel(P,tone) {
    shape(P,bevel,C.steel);
    shape(P,[['M',20,11],['L',104,11],['L',113,20],['L',113,104],['L',104,113],['L',20,113],['L',11,104],['L',11,20],['Z']],tone,null,0);
    // Four broad guards are flat fills belonging to the same steel material.
    for(let i=0;i<4;i++) {
      P.save();P.translate(62,62);P.rotate(i*90);P.translate(-62,-62);
      shape(P,[['M',18,2.8],['L',34,2.8],['L',34,10.5],['L',21,10.5],['L',10.5,21],['L',10.5,34],['L',2.8,34],['L',2.8,18],['Z']],C.steelEdge,null,0);
      P.restore();
    }
    shape(P,bevel,null);
  }
  function label(P,tone) {
    shape(P,[['M',13,2],['L',111,2],['Q',122,2,122,13],['L',122,48],
      ['Q',111,49,111,62],['Q',111,75,122,76],['L',122,111],['Q',122,122,111,122],
      ['L',13,122],['Q',2,122,2,111],['L',2,76],['Q',13,75,13,62],
      ['Q',13,49,2,48],['L',2,13],['Q',2,2,13,2],['Z']],tone);
  }
  function corners(P,tone) {
    rect(P,5,5,114,114,10,tone);
    for(let i=0;i<4;i++) {
      P.save();P.translate(62,62);P.rotate(i*90);P.translate(-62,-62);
      shape(P,[['M',2,34],['L',2,14],['Q',2,2,14,2],['L',34,2],['L',34,12],
        ['L',17,12],['Q',12,12,12,17],['L',12,34],['Z']],C.carton);
      P.restore();
    }
  }
  function header(P,tone) {
    rect(P,2,2,120,120,11,tone);
    shape(P,[['M',13,2],['L',111,2],['Q',122,2,122,13],['L',122,30],
      ['L',2,30],['L',2,13],['Q',2,2,13,2],['Z']],C.paper,null,0);
    shape(P,Pen.rrect(2,2,120,120,11),null);
  }
  globalThis.WeaponFrameOptions={draw:{A:tray,B:steel,C:label,D:corners,E:header},tones:TONES};
})();
