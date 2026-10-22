(function(){
const {C,shape,rect,circle}=NavArt;
NavOptions.C={title:'Biểu tượng vật phẩm',concept:'Túi tiền • Mũ hiệp sĩ • Rìu chiến',icons:{
 shop(p){
   // A cloth purse with a recognisable open, pinched mouth.
   shape(p,[['M',66,58],['L',56,28],['Q',78,36,96,25],['Q',113,20,132,31],['L',119,59],['C',139,80,159,104,157,137],['Q',156,172,119,174],['L',69,174],['Q',33,172,35,139],['C',34,107,48,81,66,58],['Z']],C.blue);
   rect(p,62,52,63,15,7,C.gold);
   shape(p,[['M',59,126],['L',75,114],['Q',97,93,124,116],['Q',103,144,75,128],['L',59,140],['Z']],C.cream,'none');
   circle(p,111,118,3,C.ink,'none');
   // A single clean coin in front, rather than a stack of dark rings.
   circle(p,150,154,24,C.gold);
   shape(p,[['M',150,143],['L',150,165]],null,'secondary','#b87d35');
 },
 hero(p){
   shape(p,[['M',83,56],['C',66,29,92,9,125,20],['Q',142,26,145,43],['Q',115,32,107,63],['Z']],C.red);
   shape(p,[['M',43,87],['L',43,47],['Q',43,36,53,44],['L',78,62],['Q',100,55,122,62],['L',147,44],['Q',157,36,157,47],['L',157,87],['L',163,147],['Q',138,174,100,177],['Q',62,174,37,147],['Z']],C.steel);
   shape(p,[['M',100,63],['L',100,96],['L',157,96],['L',159,145],['Q',135,168,100,173],['Z']],C.steel2,'none');
   shape(p,[['M',57,64],['L',57,83],['L',75,77],['Z']],C.blueDark,'none');
   shape(p,[['M',143,64],['L',143,83],['L',125,77],['Z']],C.blueDark,'none');
   // A single broad dark eye opening; the gold bridge separates it.
   shape(p,[['M',53,99],['Q',100,92,147,99],['L',143,119],['Q',100,112,57,119],['Z']],C.ink,'none');
   shape(p,[['M',94,91],['L',106,91],['L',109,144],['L',100,154],['L',91,144],['Z']],C.gold,'none');
   shape(p,[['M',59,139],['L',76,145],['M',141,139],['L',124,145]],null,'secondary','#8da4ae');
 },
 battle(p){
   // A battle axe keeps this silhouette separate from the existing troop shield.
   p.save();p.translate(100,104);p.rotate(36);
   rect(p,-10,-66,20,142,7,C.wood);
   rect(p,-11,22,22,43,5,C.blue);
   rect(p,-13,67,26,13,4,C.gold);
   const head=[['M',-49,-82],['Q',-21,-57,14,-67],['L',27,-66],
      ['Q',37,-75,58,-76],['Q',45,-46,59,-15],
      ['Q',35,-14,24,-32],['L',12,-33],['Q',-17,-28,-50,-4],
      ['Q',-65,-41,-49,-82],['Z']];
   shape(p,head,C.steel,'none');
   shape(p,[['M',-49,-82],['Q',-42,-49,-50,-4],['Q',-37,-14,-23,-21],
      ['Q',-34,-46,-26,-65],['Q',-40,-72,-49,-82],['Z']],C.white,'none');
   shape(p,[['M',34,-68],['Q',28,-44,37,-22],['Q',46,-14,59,-15],
      ['Q',45,-46,58,-76],['Q',43,-74,34,-68],['Z']],C.steel2,'none');
   shape(p,head,null);
   rect(p,-13,-65,26,32,4,C.gold);
   p.restore();
 }
}};
})();
