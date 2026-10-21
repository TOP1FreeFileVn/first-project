"""Offline design review. Reuses native captures and game icon/font art only."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
CAPTURES = ROOT / 'docs/ui_review/2026-10-21/menu-frame-rollout'
FONT = ROOT / 'game/ui/fonts/PaytoneOne-Regular.ttf'
S = 3
LABELS = ['Cửa hàng', 'Anh hùng', 'Chiến', 'Lính', 'Triệu hồi']
NAMES = ['shop', 'hero', 'battle', 'troops', 'summon']
INK = '#58452f'
TITLES = {'a':'A · Thanh liền mềm', 'b':'B · Huy hiệu tròn', 'c':'C · Nếp giấy'}
DESC = {
 'a':'Gọn, nhẹ · tab chọn là một mảng vàng',
 'b':'Icon có điểm tựa · nhận diện từng tab rõ',
 'c':'Ấm, thủ công · cùng chất liệu lâu đài giấy',
}

class Canvas:
 def __init__(self,w,h,fill=(0,0,0,0)):
  self.im = Image.new('RGBA',(round(w*S),round(h*S)),fill)
  self.d = ImageDraw.Draw(self.im)
 def rr(self,rect,fill,r=0,line=None,width=1):
  self.d.rounded_rectangle(tuple(round(v*S) for v in rect),round(r*S),fill=fill,outline=line,width=max(1,round(width*S)))
 def ellipse(self,rect,fill,line=None,width=1):
  self.d.ellipse(tuple(round(v*S) for v in rect),fill=fill,outline=line,width=max(1,round(width*S)))
 def poly(self,points,fill,line=None,width=1):
  pts=[(round(x*S),round(y*S)) for x,y in points]
  self.d.polygon(pts,fill=fill)
  if line:self.d.line(pts+[pts[0]],fill=line,width=round(width*S),joint='curve')
 def line(self,points,fill,width=1):
  self.d.line([(round(x*S),round(y*S)) for x,y in points],fill=fill,width=round(width*S),joint='curve')
 def text(self,xy,text,size,fill=INK,anchor='mm'):
  self.d.text(tuple(round(v*S) for v in xy),text,font=ImageFont.truetype(str(FONT),round(size*S)),fill=fill,anchor=anchor)
 def paste(self,im,xy,size=None):
  if size:im=im.resize(tuple(round(v*S) for v in size),Image.Resampling.LANCZOS)
  self.im.alpha_composite(im,(round(xy[0]*S),round(xy[1]*S)))
 def save(self,path):self.im.convert('RGB').save(path)

icons={}
for name in NAMES:
 im=Image.open(HERE/f'icon-{name}.png').convert('RGBA')
 im=im.crop(im.getbbox())
 icons[name]=im
 # Cropped sources are also used by external design canvases.
 im.save(HERE/f'balanced-{name}.png')

def icon(c,i,cx,cy,maxsize):
 im=icons[NAMES[i]]
 scale=maxsize/max(im.size)
 w,h=im.width*scale,im.height*scale
 c.paste(im,(cx-w/2,cy-h/2),(w,h))

def badge(c,cx,cy):
 c.ellipse((cx-4.2,cy-4.2,cx+4.2,cy+4.2),'#e36b60','#fff1c7',1)
 c.text((cx,cy-.1),'!',6.4,'#fff6df')

def nav(option,active=2):
 c=Canvas(360,84)
 if option=='a':
  c.rr((5,10,355,81),'#81734f',18)
  c.rr((5,7,355,78),'#d9ddba',18,'#8e7e58',1.3)
  x=6+active*70
  c.rr((x+2,10,x+68,75),'#b59a61',14)
  c.rr((x+2,8,x+68,72),'#f1d58c',14,'#a58a52',1.1)
  for i in range(5):
   cx=41+i*70
   icon(c,i,cx,32.5,37.5 if i!=1 else 37)
   c.text((cx,61.5),LABELS[i],10.2,INK if i==active else '#716749')
   if i in [0,1,3]:badge(c,cx+22,17)
 elif option=='b':
  c.rr((-5,25,365,91),'#8f9365',18)
  c.rr((-5,22,365,88),'#cdd5ac',18,'#86916a',1.2)
  c.line([(12,24),(348,24)],'#dce3bc',1)
  for i in range(5):
   cx=36+i*72
   if i==active:
    c.ellipse((cx-25,3,cx+25,53),'#ba9650')
    c.ellipse((cx-25,1,cx+25,51),'#efcb73','#8d7548',1.5)
    c.ellipse((cx-21.5,4.5,cx+21.5,47.5),'#f8e7b0','#e3b85e',1)
   else:
    c.ellipse((cx-23,5,cx+23,51),'#b3bf92')
    c.ellipse((cx-23,3,cx+23,49),'#dfe5c5','#9ba77e',1.1)
   icon(c,i,cx,26.5,35.5 if i!=1 else 35)
   c.text((cx,64),LABELS[i],10.5,INK if i==active else '#64714c')
   if i in [0,1,3]:badge(c,cx+21,9)
  c.rr((36+active*72-10,74,36+active*72+10,76),'#a98645',1)
 elif option=='c':
  c.rr((-5,26,365,89),'#b49b73',10,'#927854',1.2)
  for i in range(5):
   x=4+i*72; y=5 if i==active else 12
   face='#efd194' if i==active else '#d9c6a3'
   c.rr((x,y+2,x+64,80),'#a58b62',7)
   c.rr((x,y,x+64,77),face,7,'#927753',1.2)
   c.poly([(x+50,y),(x+64,y+14),(x+50,y+14)],'#b79c6f','#a28b65',.75)
   c.poly([(x+50,y),(x+62,y+12),(x+50,y+12)],'#f6dfb0' if i==active else '#e8d8b9')
   icon(c,i,x+32,35.5,36.5 if i!=1 else 36)
   c.text((x+32,64.5),LABELS[i],10.3,INK if i==active else '#756345')
   if i in [0,1,3]:badge(c,x+58,23)
 return c.im

def clean_background(context):
 im=Image.open(CAPTURES/f'{context}_360x640.png').convert('RGBA')
 # Remove the old selected tab from y=563; continue only the local backdrop.
 strip=im.crop((0,538,360,560)).filter(ImageFilter.GaussianBlur(7)).resize((360,84),Image.Resampling.BICUBIC)
 im.alpha_composite(strip,(0,556))
 return im

backgrounds={name:clean_background(name) for name in ['battle','shop','hero']}
for name,im in backgrounds.items():im.convert('RGB').save(HERE/f'background-{name}.png')
for option in 'abc':
 for active in range(5):
  im=nav(option,active)
  im.save(HERE/f'nav-{option}-{active}.png')
 base=backgrounds['battle'].resize((1080,1920),Image.Resampling.LANCZOS)
 base.alpha_composite(nav(option),(0,556*S))
 base.convert('RGB').save(HERE/f'option-{option}.png')

comparison=Canvas(1168,803,'#e9eee2')
comparison.text((30,23),'BA HƯỚNG LÀM LẠI THANH ĐIỀU HƯỚNG',19,anchor='lt')
comparison.text((30,55),'Cùng icon, font và màn hình game · chỉ thay cấu trúc thanh dưới',11,'#79816d',anchor='lt')
for j,option in enumerate('abc'):
 x=28+j*382
 comparison.text((x,91),TITLES[option],17,anchor='lt')
 comparison.rr((x-1,123,x+361,765),'#8e9b80',16)
 phone=Image.open(HERE/f'option-{option}.png').convert('RGBA')
 comparison.paste(phone,(x,124),(360,640))
 comparison.text((x,779),DESC[option],10.6,'#6b755c',anchor='lt')
comparison.save(HERE/'comparison.png')

bars=Canvas(1168,430,'#e9eee2')
bars.text((28,22),'SO SÁNH THANH DƯỚI · CÙNG KÍCH THƯỚC',19,anchor='lt')
for j,option in enumerate('abc'):
 x=28+j*382
 bars.text((x,65),TITLES[option],16,anchor='lt')
 for k,context in enumerate(['battle','shop','hero']):
  y=105+k*102
  crop=backgrounds[context].crop((0,556,360,640)).resize((1080,252),Image.Resampling.LANCZOS)
  crop.alpha_composite(nav(option,2 if context=='battle' else 0 if context=='shop' else 1))
  bars.paste(crop,(x,y),(360,84))
  if j==0:bars.text((x+5,y+4),{'battle':'Sảnh','shop':'Shop','hero':'Anh hùng'}[context],7.5,'#4f654e',anchor='lt')
bars.save(HERE/'bar-comparison.png')

(HERE/'qa.json').write_text(json.dumps({'mode':'offline visual proposals only','production_files_changed':False,'native_source':str(CAPTURES.relative_to(ROOT)),'icon_sources':['game/ui/skin/icon_tab_'+n+'.svg' for n in ['shop','cat','battle','army','summon']],'font':'game/ui/fonts/PaytoneOne-Regular.ttf','bar_height_px':84,'equal_slots':5,'states_rendered':15},ensure_ascii=False,indent=2),encoding='utf-8')
print('Rendered 3 phone concepts, 15 nav states and 2 comparison sheets.')
