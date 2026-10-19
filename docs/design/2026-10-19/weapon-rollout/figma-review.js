
const page=await figma.getNodeByIdAsync("3539:2");
await figma.setCurrentPageAsync(page);
await figma.loadFontAsync({family:"Paytone One",style:"Regular"});
const assets={"bua-held":{"success":true,"imageHash":"4b934ea1cc0b9de43419ac472f414c55f78f8c69","sizeBytes":97674,"contentType":"image/png","placedOnNodeId":"3620:33"},"bua-isolated":{"success":true,"imageHash":"0ca31f0b41f5632276ae6efa41f865501141c093","sizeBytes":9533,"contentType":"image/png","placedOnNodeId":"3620:32"},"chuy-held":{"success":true,"imageHash":"b3bcf421e6ee3d0356b34a2435f33f15d432f958","sizeBytes":102676,"contentType":"image/png","placedOnNodeId":"3620:31"},"chuy-isolated":{"success":true,"imageHash":"7e58f4910230e83fb786d6541f39baa299f6584e","sizeBytes":12120,"contentType":"image/png","placedOnNodeId":"3620:30"},"cung-held":{"success":true,"imageHash":"2573b169cdad9c7574c45d9f02412489d4a72df4","sizeBytes":89503,"contentType":"image/png","placedOnNodeId":"3620:12"},"cung-isolated":{"success":true,"imageHash":"ca8c4e02260f4fca5ee051c32c9c43d3d5cd7a67","sizeBytes":10987,"contentType":"image/png","placedOnNodeId":"3620:10"},"cu_kiem-held":{"success":true,"imageHash":"8ff35567ea6b61ae3212826c92cb10d4b30e398b","sizeBytes":92743,"contentType":"image/png","placedOnNodeId":"3620:29"},"cu_kiem-isolated":{"success":true,"imageHash":"1878e36435de07fdfef34bdec31e9442a7dec392","sizeBytes":9830,"contentType":"image/png","placedOnNodeId":"3620:28"},"dai_bac-held":{"success":true,"imageHash":"0594a5b2eafac293d5cacdb5cba4feab90b5f4f4","sizeBytes":98973,"contentType":"image/png","placedOnNodeId":"3620:16"},"dai_bac-isolated":{"success":true,"imageHash":"490d4fc70f99438f97487b12e7bebc6ce9403f4e","sizeBytes":18750,"contentType":"image/png","placedOnNodeId":"3620:17"},"dao-held":{"success":true,"imageHash":"4ed9566280b13691e71342a611462ce9df7ec468","sizeBytes":102019,"contentType":"image/png","placedOnNodeId":"3620:8"},"dao-isolated":{"success":true,"imageHash":"3bc416a5c11644c3a9c2524d842b8748ef745b11","sizeBytes":8469,"contentType":"image/png","placedOnNodeId":"3620:7"},"dua_phep-held":{"success":true,"imageHash":"82c04de160b758b3cfc62cf7bede8b315645c3ff","sizeBytes":98634,"contentType":"image/png","placedOnNodeId":"3620:25"},"dua_phep-isolated":{"success":true,"imageHash":"2f7788939adf9611c983defd7a25342b73b182bd","sizeBytes":11868,"contentType":"image/png","placedOnNodeId":"3620:24"},"gay_phep-held":{"success":true,"imageHash":"00a5feff801eab78704349cd53e91a3b6e8ca600","sizeBytes":101718,"contentType":"image/png","placedOnNodeId":"3620:19"},"gay_phep-isolated":{"success":true,"imageHash":"62a8258656e4d226e16bd8bb980e9437579e66ee","sizeBytes":9650,"contentType":"image/png","placedOnNodeId":"3620:18"},"giao-held":{"success":true,"imageHash":"7b98012c31f3ac672aa7c0181849f14e765728b0","sizeBytes":94486,"contentType":"image/png","placedOnNodeId":"3620:27"},"giao-isolated":{"success":true,"imageHash":"d4efeaf1f0851e584effb1ebcff912895354543e","sizeBytes":7307,"contentType":"image/png","placedOnNodeId":"3620:26"},"katana-held":{"success":true,"imageHash":"fbf249547029c823d4e13999d8edb9d42eb4a300","sizeBytes":105781,"contentType":"image/png","placedOnNodeId":"3620:9"},"katana-isolated":{"success":true,"imageHash":"186dba9c4608d84f1c63e8834a3301739cc07437","sizeBytes":5912,"contentType":"image/png","placedOnNodeId":"3620:6"},"kiem-held":{"success":true,"imageHash":"51a3da8bface21c4f61b3f72026b430ac1ca4593","sizeBytes":101405,"contentType":"image/png","placedOnNodeId":"3620:5"},"kiem-isolated":{"success":true,"imageHash":"a3832ff54c3cfb902df937f798bb8321be641864","sizeBytes":8180,"contentType":"image/png","placedOnNodeId":"3620:3"},"no-held":{"success":true,"imageHash":"ecbf82a9a479ce20cb7b86616c251d4cbaeecb5c","sizeBytes":91719,"contentType":"image/png","placedOnNodeId":"3620:13"},"no-isolated":{"success":true,"imageHash":"eb0f97feef49c4133c62452828b5580325d90256","sizeBytes":17739,"contentType":"image/png","placedOnNodeId":"3620:11"},"riu-held":{"success":true,"imageHash":"86f2946845d5ddbbbf76280d46b3c4db3e882f42","sizeBytes":109747,"contentType":"image/png","placedOnNodeId":"3620:4"},"riu-isolated":{"success":true,"imageHash":"9430de3e90da8302635d0fc2564e78ecd11cd8cd","sizeBytes":10867,"contentType":"image/png","placedOnNodeId":"3620:2"},"sach_phep-held":{"success":true,"imageHash":"5f062baeb6d3f9e990f2edf5777825e62c970685","sizeBytes":84398,"contentType":"image/png","placedOnNodeId":"3620:23"},"sach_phep-isolated":{"success":true,"imageHash":"a11f55617a0c7b21e119b429e04aa16f7b11b73a","sizeBytes":15361,"contentType":"image/png","placedOnNodeId":"3620:22"},"sung-held":{"success":true,"imageHash":"297032eb94bacf8853b67755f08704dddcfa692a","sizeBytes":98275,"contentType":"image/png","placedOnNodeId":"3620:15"},"sung-isolated":{"success":true,"imageHash":"6c173668a3627494871cbfab0b61d7f275033ca3","sizeBytes":16621,"contentType":"image/png","placedOnNodeId":"3620:14"},"thuoc-held":{"success":true,"imageHash":"b4afefb434513dd9944de204f42dbf6ed07cf290","sizeBytes":89542,"contentType":"image/png","placedOnNodeId":"3620:21"},"thuoc-isolated":{"success":true,"imageHash":"1610eddd068e681b8ad4ea60c77215b5d9a6d568","sizeBytes":17308,"contentType":"image/png","placedOnNodeId":"3620:20"}};
const roster=[["kiem","Kiếm · Đã duyệt"],["riu","Rìu"],["dao","Đao"],["katana","Katana"],["cung","Cung"],["no","Nỏ"],["sung","Súng"],["dai_bac","Đại bác"],["gay_phep","Gậy phép"],["thuoc","Thuốc"],["sach_phep","Sách phép"],["dua_phep","Đũa phép"],["giao","Giáo"],["cu_kiem","Cự kiếm"],["chuy","Chùy"],["bua","Búa"]];
const created=[],mutated=[],cards=[];
const c=hex=>({r:parseInt(hex.slice(1,3),16)/255,g:parseInt(hex.slice(3,5),16)/255,b:parseInt(hex.slice(5,7),16)/255});
const solid=hex=>[{type:"SOLID",color:c(hex)}];
function layout(name,direction,width,height,fill=null){
 const n=figma.createAutoLayout(direction,{name,itemSpacing:8});
 n.resize(width,height);
 n.primaryAxisSizingMode="FIXED";n.counterAxisSizingMode="FIXED";
 n.fills=fill?solid(fill):[];created.push(n.id);return n;
}
function label(parent,txt,size,width,height){
 const n=figma.createText();n.fontName={family:"Paytone One",style:"Regular"};
 n.fontSize=size;n.characters=txt;n.fills=solid("#583f21");
 n.textAutoResize="NONE";n.resize(width,height);parent.appendChild(n);created.push(n.id);return n;
}
function slot(parent,name,w,h){
 const n=layout(name,"VERTICAL",w,h);n.primaryAxisAlignItems="CENTER";n.counterAxisAlignItems="CENTER";parent.appendChild(n);return n;
}
const root=figma.createAutoLayout("VERTICAL",{name:"Bộ vũ khí · 15 mẫu mới + kiếm duyệt · 9 px",itemSpacing:16});
page.appendChild(root);created.push(root.id);
root.x=7939;root.y=0;root.resize(1440,1900);
root.primaryAxisSizingMode="AUTO";root.counterAxisSizingMode="FIXED";
root.paddingTop=32;root.paddingBottom=32;root.paddingLeft=32;root.paddingRight=32;
root.fills=solid("#d8e5df");root.cornerRadius=24;
label(root,"BỘ VŨ KHÍ · 15 MẪU MỚI",32,1376,54);
label(root,"Cùng kiếm đã duyệt · Viền 9 px · Dây cung 1,5 px · Đao / katana đã giảm cong",18,1376,36);
for(let row=0;row<4;row++){
 const line=layout("Hàng "+(row+1),"HORIZONTAL",1376,410);line.itemSpacing=16;root.appendChild(line);
 for(let col=0;col<4;col++){
  const [id,name]=roster[row*4+col];
  const card=layout(name,"VERTICAL",332,410,"#edf1e7");
  card.cornerRadius=22;card.paddingTop=14;card.paddingBottom=14;card.paddingLeft=14;card.paddingRight=14;
  line.appendChild(card);card.itemSpacing=8;
  label(card,name,21,304,36);
  const artrow=layout(id+" / phóng lớn","HORIZONTAL",304,184);artrow.itemSpacing=8;card.appendChild(artrow);
  const isoSlot=slot(artrow,"Vũ khí rời",112,184);
  const heldSlot=slot(artrow,"Mèo cầm",184,184);
  for(const [kind,parent,maxW,maxH] of [["isolated",isoSlot,106,180],["held",heldSlot,184,172.5]]){
   const n=await figma.getNodeByIdAsync(assets[id+"-"+kind].placedOnNodeId);
   const r=Math.min(maxW/n.width,maxH/n.height);
   n.resize(n.width*r,n.height*r);parent.appendChild(n);n.name=id+" / "+kind;n.fills=[{type:"IMAGE",imageHash:assets[id+"-"+kind].imageHash,scaleMode:"FIT"}];mutated.push(n.id);
  }
  const native=layout(id+" / kích thước thật","HORIZONTAL",304,120);native.itemSpacing=30;card.appendChild(native);
  const nativeUnit=figma.createRectangle();nativeUnit.name=id+" / 128 × 120";nativeUnit.resize(128,120);
  nativeUnit.fills=[{type:"IMAGE",imageHash:assets[id+"-held"].imageHash,scaleMode:"FIT"}];native.appendChild(nativeUnit);created.push(nativeUnit.id);
  const iconSlot=slot(native,"Icon 48 px",100,120);
  const icon=figma.createRectangle();icon.name=id+" / icon 48 px";icon.resize(48,48);icon.fills=[{type:"IMAGE",imageHash:assets[id+"-isolated"].imageHash,scaleMode:"FIT"}];iconSlot.appendChild(icon);created.push(icon.id);
  label(card,"128 × 120 / icon 48 px",13,304,22);
  cards.push({id,cardNodeId:card.id,isolatedNodeId:assets[id+"-isolated"].placedOnNodeId,heldNodeId:assets[id+"-held"].placedOnNodeId});
 }
}
label(root,"Bản duyệt · Mỗi ảnh là một layer riêng · Chưa thay artwork game chính",16,1376,30);
figma.viewport.scrollAndZoomIntoView([root]);
await root.screenshot({scale:0.75});
return {rootNodeId:root.id,createdNodeIds:created,mutatedNodeIds:mutated,cards,width:root.width,height:root.height,allImages:32};
