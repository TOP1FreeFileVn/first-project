// Review board only. SVGs are supplied from the adjacent original vector files.
const ids = [], variableIds = [], collectionIds = [];
const mark = n => { ids.push(n.id); return n; };
const rgb = h => ({r:parseInt(h.slice(1,3),16)/255,g:parseInt(h.slice(3,5),16)/255,b:parseInt(h.slice(5,7),16)/255});
const hex = c => '#'+[c.r,c.g,c.b].map(v=>Math.round(v*255).toString(16).padStart(2,'0')).join('');
const palette = {
  ink:'#583f21',cream:'#fff0c9',sand:'#f4e2bc',bronze:'#c6a46c',steel:'#c4d4da',ivory:'#f5f5e9',
  leather:'#a76c47',gold:'#f5c565',infantry:'#df6a59',ranged:'#759b63',mage:'#83b8c5',cavalry:'#bd8f62',
  sky:'#80b0e7',panel:'#fff0d6',tile:'#f7e4c1',tileBorder:'#d2b78a',sizeStrip:'#dce8ef',sizeBorder:'#c5d3d9',paper:'#fff7e9'
};
const pageName='4 hệ · Bản duyệt 01';
const existingPage=figma.root.children.find(p=>p.name===pageName);
if(existingPage) return {alreadyExists:true,pageId:existingPage.id,children:existingPage.children.map(n=>({id:n.id,name:n.name}))};
await Promise.all([figma.loadFontAsync({family:'Paytone One',style:'Regular'}),figma.loadFontAsync({family:'Nunito',style:'Regular'})]);
const page=mark(figma.createPage());page.name=pageName;await figma.setCurrentPageAsync(page);
const collection=figma.variables.createVariableCollection('Gear Meow / Class draft 01');collectionIds.push(collection.id);
collection.renameMode(collection.modes[0].modeId,'Draft');const mode=collection.modes[0].modeId;
const vars={};const byHex={};
for(const [name,h] of Object.entries(palette)){
  const prim=figma.variables.createVariable('primitive/'+name,collection,'COLOR');
  prim.scopes=[];prim.setValueForMode(mode,rgb(h));prim.setVariableCodeSyntax('WEB','var(--gm-draft-'+name+')');variableIds.push(prim.id);
  const semantic=figma.variables.createVariable('color/'+name,collection,'COLOR');
  semantic.scopes=['FRAME_FILL','SHAPE_FILL','STROKE_COLOR','TEXT_FILL'];
  semantic.setValueForMode(mode,{type:'VARIABLE_ALIAS',id:prim.id});semantic.setVariableCodeSyntax('WEB','var(--gm-class-'+name+')');variableIds.push(semantic.id);
  vars[name]=semantic;byHex[h]=semantic;
}
const paint=name=>figma.variables.setBoundVariableForPaint({type:'SOLID',color:rgb(palette[name])},'color',vars[name]);
function bindSvg(root){
  for(const n of [root,...root.findAll(()=>true)]){
    for(const field of ['fills','strokes']){
      if(!(field in n)||!Array.isArray(n[field]))continue;
      n[field]=n[field].map(p=>p.type==='SOLID'&&byHex[hex(p.color)]?figma.variables.setBoundVariableForPaint(p,'color',byHex[hex(p.color)]):p);
    }
  }
}
const components={};
for(const [i,key] of ['infantry','ranged','mage','cavalry'].entries()){
  const svg=figma.createNodeFromSvg(ASSETS[key]);
  const comp=mark(figma.createComponent());comp.name='class_'+key+'_draft01';comp.resize(128,128);comp.fills=[];
  page.appendChild(comp);comp.x=1480+i*176;comp.y=80;
  for(const child of [...svg.children])comp.appendChild(child);svg.remove();
  comp.description='Gear Meow · Huy hiệu hệ, bản duyệt 01. Nét nâu, nền kem; độ hiếm vẫn thuộc nền thẻ. Ưu tiên 32 px trở lên.';
  bindSvg(comp);components[key]=comp;
}
const nameStyle=figma.createTextStyle();nameStyle.name='Gear Meow / Class draft / Name';
nameStyle.fontName={family:'Paytone One',style:'Regular'};nameStyle.fontSize=25;nameStyle.lineHeight={unit:'PIXELS',value:36};
function auto(parent,name,dir,w,h,fill=null,gap=0,pad=0){
  const n=mark(figma.createAutoLayout(dir));n.name=name;n.resize(w,h);n.primaryAxisSizingMode='FIXED';n.counterAxisSizingMode='FIXED';
  n.itemSpacing=gap;n.paddingLeft=pad;n.paddingRight=pad;n.paddingTop=pad;n.paddingBottom=pad;n.fills=fill?[paint(fill)]:[];
  n.clipsContent=false;if(parent)parent.appendChild(n);return n;
}
function txt(parent,value,size,body=false,center=false,width=null){
  const n=mark(figma.createText());n.name=value;n.fontName={family:body?'Nunito':'Paytone One',style:'Regular'};n.fontSize=size;
  n.lineHeight={unit:'PIXELS',value:size*1.4};n.characters=value;n.fills=[paint('ink')];
  if(width){n.textAutoResize='HEIGHT';n.resize(width,n.height);}else n.textAutoResize='WIDTH_AND_HEIGHT';
  n.textAlignHorizontal=center?'CENTER':'LEFT';parent.appendChild(n);return n;
}
function badge(parent,key,size){const n=mark(components[key].createInstance());parent.appendChild(n);n.rescale(size/128);return n;}
function stylePanel(n){n.cornerRadius=20;n.strokes=[paint('ink')];n.strokeWeight=3;n.strokeAlign='INSIDE';}
const board=auto(page,'Gear Meow · 4 hệ & vòng khắc chế · Duyệt 01','VERTICAL',1280,1144,'sky',24,48);
board.x=80;board.y=80;board.paddingTop=28;board.paddingBottom=24;board.primaryAxisSizingMode='AUTO';
const header=auto(board,'Tiêu đề','VERTICAL',1184,128,null,4);
txt(header,'GEAR MEOW  /  BẢN DUYỆT 01',18);
txt(header,'Biểu tượng & khắc chế hệ',40);
txt(header,'Bốn hình tượng riêng, cùng nét viền nâu và huy hiệu kem của game.',18,true);
const main=auto(board,'Icon & vòng khắc chế','HORIZONTAL',1184,650,null,24);
const legend=auto(main,'Bộ 4 hệ','VERTICAL',448,650,'panel',18,20);stylePanel(legend);
txt(legend,'4 HỆ QUÂN',23);
const names={infantry:['Bộ binh','Kiếm & khiên'],ranged:['Tầm xa','Cung & tên'],mage:['Pháp sư','Trượng phép'],cavalry:['Kỵ binh','Đầu ngựa']};
for(const pair of [['infantry','ranged'],['mage','cavalry']]){
  const row=auto(legend,'Hai hệ','HORIZONTAL',408,230,null,16);
  for(const key of pair){
    const card=auto(row,names[key][0],'VERTICAL',196,230,'tile',0,10);card.cornerRadius=16;card.strokes=[paint('tileBorder')];card.strokeWeight=2;card.counterAxisAlignItems='CENTER';
    badge(card,key,132);const label=txt(card,names[key][0],25,false,true,176);await label.setTextStyleIdAsync(nameStyle.id);
    txt(card,names[key][1],16,true,true,176);
  }
}
txt(legend,'Hình khối rõ · màu nhấn nhẹ',16,true,true,408);
const circlePanel=auto(main,'Vòng khắc chế','VERTICAL',712,650,'panel',0,28);stylePanel(circlePanel);
txt(circlePanel,'VÒNG KHẮC CHẾ',23);
const circle=mark(figma.createFrame());circle.name='Tầm xa > Bộ binh > Pháp sư > Kỵ binh > Tầm xa';circle.resize(656,536);circle.fills=[];circle.clipsContent=false;circlePanel.appendChild(circle);
const point=(r,a)=>{a*=Math.PI/180;return[328+r*Math.cos(a),268+r*Math.sin(a)];};
const pointString=pts=>pts.map((p,i)=>(i?'L':'M')+p.map(v=>v.toFixed(2)).join(' ')).join(' ')+'Z';
for(const [start,end] of [[-68,-32],[22,58],[112,148],[202,238]]){
  const angles=Array.from({length:21},(_,i)=>start+(end-start)*i/20);
  const pts=[...angles.map(a=>point(190,a)),point(201,end),point(180,end+9),point(159,end),...angles.reverse().map(a=>point(170,a))];
  const arrow=mark(figma.createNodeFromSvg('<svg xmlns="http://www.w3.org/2000/svg" width="656" height="536" viewBox="0 0 656 536"><path d="'+pointString(pts)+'" fill="#f5c565" stroke="#583f21" stroke-width="3" stroke-linejoin="round"/></svg>'));
  circle.appendChild(arrow);arrow.name='Mũi tên khắc chế';arrow.x=0;arrow.y=0;bindSvg(arrow);
}
for(const [key,x,y] of [['ranged',328,88],['infantry',508,268],['mage',328,448],['cavalry',148,268]]){
  const n=badge(circle,key,110);n.x=x-55;n.y=y-55;
}
const center=auto(circle,'Quy tắc sát thương','VERTICAL',180,132,null,0);center.x=238;center.y=222;center.counterAxisAlignItems='CENTER';
txt(center,'SÁT THƯƠNG',17,false,true,180);txt(center,'KHẮC CHẾ',20,false,true,180);txt(center,'×2',43,false,true,180);
for(const angle of [-45,45,135,225]){
  const [x,y]=point(233,angle);const pill=auto(circle,'Hệ số ×2','VERTICAL',54,34,'paper',0);pill.x=x-27;pill.y=y-17;pill.cornerRadius=12;
  pill.strokes=[paint('bronze')];pill.strokeWeight=2;pill.primaryAxisAlignItems='CENTER';pill.counterAxisAlignItems='CENTER';txt(pill,'×2',21);
}
txt(circlePanel,'Mũi tên chỉ hệ bị khắc',17,true,true,656);
const sizePanel=auto(board,'Kiểm tra kích thước nhỏ','VERTICAL',1184,202,'panel',14,24);stylePanel(sizePanel);
const sizeTitle=auto(sizePanel,'Tiêu đề kích thước','HORIZONTAL',1136,32,null,0);sizeTitle.primaryAxisAlignItems='SPACE_BETWEEN';
txt(sizeTitle,'KIỂM TRA KHI THU NHỎ',22);txt(sizeTitle,'48 / 32 / 24 px',17,true);
const sizes=auto(sizePanel,'48, 32, 24 px trên nền xanh','HORIZONTAL',1136,108,'sizeStrip',0,20);sizes.cornerRadius=12;sizes.strokes=[paint('sizeBorder')];sizes.strokeWeight=1;sizes.counterAxisAlignItems='CENTER';
for(const key of ['infantry','ranged','mage','cavalry']){
  const group=auto(sizes,names[key][0],'HORIZONTAL',274,64,null,10);group.counterAxisAlignItems='CENTER';
  for(const size of [48,32,24])badge(group,key,size);txt(group,names[key][0],19);
}
const footer=auto(board,'Chú thích','HORIZONTAL',1184,24,null,0);footer.primaryAxisAlignItems='SPACE_BETWEEN';
txt(footer,'4 hệ · Mũi tên chỉ chiều khắc chế · Sát thương ×2',17);txt(footer,'DRAFT · 01',14,true);
const nodes=[board,...board.findAll(()=>true)];const counts={};for(const n of nodes)counts[n.type]=(counts[n.type]||0)+1;
const imageNodes=nodes.filter(n=>'fills' in n&&Array.isArray(n.fills)&&n.fills.some(p=>p.type==='IMAGE')).map(n=>n.id);
const fonts=[...new Set(nodes.filter(n=>n.type==='TEXT').map(n=>n.fontName.family))];
const componentsOut=Object.fromEntries(Object.entries(components).map(([k,n])=>[k,n.id]));
for(const c of Object.values(components))for(const n of c.findAll(()=>true))ids.push(n.id);
for(const n of board.findAll(()=>true))if(!ids.includes(n.id))ids.push(n.id);
return {pageId:page.id,boardId:board.id,width:board.width,height:board.height,components:componentsOut,createdNodeIds:ids,collectionIds,variableIds,textStyleId:nameStyle.id,counts,imageNodes,fonts};
