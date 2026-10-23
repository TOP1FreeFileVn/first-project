"""Analytical shop layout board. This does not build or modify game UI."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
GAME_FONT = ROOT / 'game/ui/fonts/PaytoneOne-Regular.ttf'
BODY_FONT = ROOT / 'game/ui/fonts/DejaVuSans.ttf'
INK = '#3b2b1e'
LINE = '#583f21'
PAPER = '#f2dcab'
BLUE = '#345873'
YELLOW = '#ffe281'

def font(size, body=False):
    return ImageFont.truetype(str(BODY_FONT if body else GAME_FONT), size)

im = Image.new('RGB', (1500, 1130), '#f6f1e6')
d = ImageDraw.Draw(im)

def text(x, y, value, size=20, fill=INK, body=False):
    d.text((x,y), value, font=font(size,body), fill=fill)

def wrap(x,y,value,width,size=19,fill=INK,body=True,line_height=None):
    words=value.split()
    lines=[]
    line=''
    for word in words:
        candidate=(line+' '+word).strip()
        if d.textlength(candidate,font=font(size,body))>width and line:
            lines.append(line)
            line=word
        else:
            line=candidate
    if line: lines.append(line)
    for line in lines:
        text(x,y,line,size,fill,body)
        y+=line_height or size+9
    return y

def panel(rect,fill=PAPER,radius=22,width=3):
    d.rounded_rectangle(rect,radius=radius,fill=fill,outline=LINE,width=width)

def centered(rect,label,size=18,fill=INK):
    ft=font(size)
    box=d.textbbox((0,0),label,font=ft)
    w=d.textlength(label,font=ft)
    x=(rect[0]+rect[2]-w)/2
    y=(rect[1]+rect[3]-(box[3]-box[1]))/2-box[1]
    d.text((x,y),label,font=ft,fill=fill)

def button(rect,label,primary=True,size=18):
    # Button-only lower shadow follows the game's existing convention.
    d.rounded_rectangle((rect[0],rect[1]+4,rect[2],rect[3]+4),radius=15,fill=LINE)
    panel(rect,YELLOW if primary else '#f8edcf',15,3)
    ft=font(size)
    box=d.textbbox((0,0),label,font=ft)
    x=(rect[0]+rect[2]-d.textlength(label,font=ft))/2
    y=(rect[1]+rect[3]-(box[3]-box[1]))/2-box[1]
    d.text((x,y),label,font=ft,fill='white',stroke_width=1,stroke_fill=INK)

def chest(kind,rect):
    asset=Image.open(ROOT/f'game/ui/art/chests/strongbox-b/{kind}/closed.png').convert('RGBA')
    asset=asset.crop(asset.getbbox())
    asset.thumbnail((rect[2]-rect[0],rect[3]-rect[1]),Image.Resampling.LANCZOS)
    im.paste(asset,(int((rect[0]+rect[2]-asset.width)/2),int((rect[1]+rect[3]-asset.height)/2)),asset)

text(38,26,'SHOP: DỄ HIỂU GIÁ TRỊ, DỄ CHỌN ĐÚNG',34)
text(40,82,'Nghiên cứu tài liệu + audit UI · 24/10/2026 · Chưa thử với người chơi / chưa có kết quả tăng mua',18,body=True)
text(40,127,'Ảnh game hiện tại',24)
text(540,127,'Sơ đồ hướng thử',24)
text(1040,127,'Vai trò màu & thứ tự sửa',24)

source=Image.open(ROOT/'docs/ui_review/2026-10-23/chest-b-integration/shop-450x800.png').convert('RGB')
im.paste(source,(40,172))

# A deliberately schematic proposal. All prices/rewards are current game data.
px,py=540,172
d.rounded_rectangle((px,py,px+450,py+800),radius=15,fill=BLUE)
# Keep original header/awning and bottom navigation as reference, rather than
# implying that the research author redesigned approved navigation.
im.paste(source.crop((0,0,450,135)),(px,py))
im.paste(source.crop((0,697,450,800)),(px,py+697))
panel((px+14,py+144,px+436,py+390))
text(px+30,py+158,'Rương Vàng',24)
chest('gold',(px+28,py+205,px+173,py+310))
text(px+190,py+207,'25 thẻ lính',24)
text(px+190,py+244,'Ít nhất 3 thẻ Hiếm',17)
button((px+186,py+282,px+420,py+331),'Mở 1 lần · 120',True,18)
gem=Image.open(ROOT/'game/ui/art/icon_gem_32.png').convert('RGBA') if (ROOT/'game/ui/art/icon_gem_32.png').exists() else None
if gem:
    gem.thumbnail((22,22),Image.Resampling.LANCZOS)
    im.paste(gem,(px+196,py+296),gem)
text(px+30,py+341,'Bảo đảm Sử thi: còn 10 lần mở',16,fill='#69328c')
text(px+30,py+365,'Vật phẩm & tỷ lệ  ›',15)

text(px+16,py+411,'Rương tiếp tế',20,fill='#fff2c2')
for kind,x,title,reward,extra,action in [
    ('wood',px+14,'Rương Gỗ','3 thẻ lính','+ 50–100 vàng','Mở miễn phí'),
    ('silver',px+232,'Rương Bạc','8 thẻ lính','','Mở · 600 vàng')]:
    panel((x,py+451,x+204,py+659),'#e4ddc4')
    centered((x,py+463,x+204,py+490),title,20)
    chest(kind,(x+60,py+500,x+144,py+558))
    centered((x,py+567,x+204,py+590),reward,17)
    if extra: centered((x,py+592,x+204,py+610),extra,14)
    button((x+10,py+615,x+194,py+650),action,False,16)
text(px+20,py+673,'Cuộn tiếp: Đổi kim cương  ↓',14,fill='#fff2c2')

swatches=[('Nền xanh trầm',BLUE),('Giấy ấm',PAPER),('Chữ nâu đậm',INK),('CTA vàng sáng',YELLOW)]
y=180
for label,color in swatches:
    d.rounded_rectangle((1040,y,1098,y+46),radius=9,fill=color,outline=LINE,width=2)
    text(1113,y,label,19)
    text(1113,y+26,color.upper(),15,body=True)
    y+=70
y=wrap(1040,487,'Màu là vai trò trong bố cục. Không có màu nút nào được chứng minh luôn bán tốt hơn.',410,20)
for heading,body in [
    ('1. Giá trị trước','Số thẻ + bảo đảm + giá nằm cùng cụm, dễ quét.'),
    ('2. Một cấp nhấn chính','Nút mở nổi hơn link tỷ lệ và nút phụ.'),
    ('3. Nội dung thật','Giữ giá/phần thưởng. Không tự gắn “Best Value”.'),
    ('4. Kiểm chứng hành vi','Tìm đúng rương, hiểu đúng giá, rồi mới đo lượt tiêu tiền.')]:
    y+=23
    text(1040,y,heading,20)
    y=wrap(1040,y+34,body,405,18)

text(40,993,'Bằng chứng: ảnh native Godot 450×800.',17,body=True)
wrap(540,993,'Minh họa phân tích, chưa áp dụng. Không phải ảnh game mới. Header/bottom bar giữ từ ảnh gốc.',450,17)
text(40,1083,'Đọc báo cáo: README.md · Màu và bố cục đề xuất là giả thuyết cần thử; chưa có dữ liệu conversion.',18,body=True)
im.save(OUT/'direction-board.png')

def luminance(hex_color):
    c=[int(hex_color[i:i+2],16)/255 for i in (1,3,5)]
    c=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in c]
    return sum(a*b for a,b in zip(c,(.2126,.7152,.0722)))

pairs=[('current_gold',INK,'#e7ca91'),('current_wood',INK,'#bfd7ab'),
       ('current_silver',INK,'#b2d4df'),('current_pity','#69328c','#e7ca91'),
       ('proposed_paper',INK,PAPER)]
contrast=[]
for name,foreground,background in pairs:
    low,high=sorted((luminance(foreground),luminance(background)))
    contrast.append({'pair':name,'foreground':foreground,'background':background,'ratio':round((high+.05)/(low+.05),4)})
(OUT/'contrast.json').write_text(json.dumps({'method':'WCAG sRGB relative luminance; flat authored pairs only, not outlined label certification','pairs':contrast},indent=2)+'\n',encoding='utf-8')
print('Wrote direction-board.png and contrast.json')
