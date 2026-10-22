// Shop sign: a single broad cyan fish with an open tail notch. This is a
// secondary emblem on the original stall, so its ink stays below the kiosk line.
(function(){
globalThis.drawShopFish=function(p){
 const body=[['M',55,92],['C',65,83,78,85,86,97],
  ['C',77,108,65,111,55,102],['L',43,108],['L',46,97],
  ['L',43,88],['Z']];
 p.shape(body,{fill:'#8fdce6',stroke:'#583f21',width:1.8});
 p.shape(Pen.circle(78,95.6,1.4),{fill:'#583f21'});
};
})();
