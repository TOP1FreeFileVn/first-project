from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
BG,INK='#eee4d2','#583f21'
font=lambda n:ImageFont.truetype(str(ROOT/'game/ui/fonts/PaytoneOne-Regular.ttf'),n)
def txt(d,xy,s,n=20,fill=INK,anchor=None):
    d.text(xy,s,font=font(n),fill=fill,anchor=anchor)
def paste(im,art,x,y):
    if isinstance(art,Path):art=Image.open(art).convert('RGBA')
    im.paste(art,(round(x),round(y)),art)
titles={'A':'Gọn và rõ','B':'Phố hộp giấy','C':'Biểu tượng vật phẩm','D':'Đoàn phiêu lưu'}
names={'A':['Quầy mái vải','Mèo hiệp sĩ','Song kiếm'],
       'B':['Tiệm hộp giấy','Hiệp sĩ carton','Cổng thành'],
       'C':['Túi tiền cá','Mũ hiệp sĩ','Rìu chiến'],
       'D':['Xe hàng rong','Anh hùng áo choàng','Cờ chiến trận']}
sheet=Image.new('RGB',(940,1320),BG)
d=ImageDraw.Draw(sheet)
txt(d,(26,18),'3 ICON ĐIỀU HƯỚNG · 4 PHƯƠNG ÁN',27)
txt(d,(26,61),'Chọn theo bộ A–D hoặc ghép từng icon.',17)
for j,label in enumerate(['CỬA HÀNG','ANH HÙNG','CHIẾN']):
    txt(d,(360+j*215,109),label,18,anchor='mm')
for i,id in enumerate(titles):
    y=142+i*286
    if i%2==0:d.rectangle((18,y-6,922,y+270),fill='#f7efdf')
    txt(d,(33,y+8),id,46)
    title=titles[id].split(' ')
    lines={'A':['Gọn và rõ'],'B':['Phố hộp giấy'],'C':['Biểu tượng','vật phẩm'],'D':['Đoàn phiêu lưu']}[id]
    for k,line in enumerate(lines):txt(d,(33,y+77+k*28),line,18)
    for j,key in enumerate(['shop','hero','battle']):
        cx=360+j*215
        art=Image.open(HERE/'png'/f'{id}-{key}-200.png').convert('RGBA')
        art=art.resize((154,154),Image.Resampling.LANCZOS)
        paste(sheet,art,cx-77,y+1)
        txt(d,(cx,y+176),names[id][j],16,anchor='mm')
        paste(sheet,HERE/'png'/f'{id}-{key}-44.png',cx-46,y+198)
        paste(sheet,HERE/'png'/f'{id}-{key}-26.png',cx+20,y+207)
        txt(d,(cx-24,y+254),'44 px',12,anchor='mm')
        txt(d,(cx+33,y+254),'26 px',12,anchor='mm')
txt(d,(26,1300),'Bản duyệt · Chưa thay icon đang dùng trong game',14,anchor='ls')
sheet.save(HERE/'options.png')

# Before/after strip and exact unscaled thumbnail QA contact sheet.
small=Image.new('RGB',(860,478),BG);sd=ImageDraw.Draw(small)
txt(sd,(20,18),'KIỂM TRA Ở KÍCH THƯỚC THẬT',22)
for j,key in enumerate(['shop','hero','battle']):
    cx=326+j*204
    old=Image.open(ROOT/'game/ui/skin/carton_nav'/f'{key}.png').convert('RGBA')
    old.thumbnail((44,44),Image.Resampling.LANCZOS)
    paste(small,old,cx-22,62)
txt(sd,(20,75),'Đang dùng',17)
for i,id in enumerate(titles):
    y=139+i*77
    txt(sd,(20,y+12),f'{id} · {titles[id]}',15)
    for j,key in enumerate(['shop','hero','battle']):
        cx=326+j*204
        paste(small,HERE/'png'/f'{id}-{key}-44.png',cx-44,y)
        paste(small,HERE/'png'/f'{id}-{key}-26.png',cx+24,y+9)
small.save(HERE/'native-sizes.png')

if len(list((HERE/'context').glob('*.png')))==12:
    context=Image.new('RGB',(940,1165),BG);cd=ImageDraw.Draw(context)
    txt(cd,(26,20),'ĐẶT THỬ TRÊN THANH HỘP TRONG GAME',25)
    txt(cd,(26,62),'Giữ nguyên hộp, chữ, chuyển động và hai icon Lính / Triệu hồi.',16)
    for i,id in enumerate(titles):
        y=108+i*258
        txt(cd,(28,y),f'{id} · {titles[id]}',22)
        # Captures are 720px from the actual production CartonNav control.
        paste(context,HERE/'context'/f'{id}-2.png',110,y+34)
    txt(cd,(26,1144),'Ảnh từ Godot · Tab Chiến đang mở · Các icon còn lại ở trạng thái đóng',14)
    context.save(HERE/'in-game.png')

review=json.loads((HERE/'review.json').read_text(encoding='utf-8'))
review['verification']={"renderer":"Godot 4.7.2", "rendered_icons":60,
    "menu_control":"game/ui/CartonNav.gd", "context_captures":12,
    "production_modified":False,"save_writes":False,
    "alpha_threshold_for_clipping":16,
    "clipped_native_icons":[], "max_native_edge_alpha":0}
for f in sorted((HERE/'png').glob('*.png')):
    im=Image.open(f).convert('RGBA');alpha=im.getchannel('A')
    # Lanczos may leave 1–5/255 alpha ringing in the transparent safety border.
    # Inspect meaningful contour coverage rather than treating this as a cut edge.
    bounds=alpha.point(lambda a:255 if a>=16 else 0).getbbox()
    edge=max(max(alpha.crop((0,0,im.width,1)).getextrema()),
             max(alpha.crop((0,im.height-1,im.width,im.height)).getextrema()),
             max(alpha.crop((0,0,1,im.height)).getextrema()),
             max(alpha.crop((im.width-1,0,im.width,im.height)).getextrema()))
    review['verification']['max_native_edge_alpha']=max(review['verification']['max_native_edge_alpha'],edge)
    if not bounds or bounds[0]==0 or bounds[1]==0 or bounds[2]==im.width or bounds[3]==im.height:
        review['verification']['clipped_native_icons'].append(f.name)
review['observations']=[
    "A: strongest immediate shop / hero / combat recognition. Crossed-sword main reduced to 6.5 author units after the first visual review.",
    "B: broad cardboard-town silhouettes. Castle/gate semantics are close to the unchanged summon portal, so A or D is stronger for battle navigation.",
    "C: item-symbol direction. Replaced sword/shield with an axe to avoid duplicating the unchanged troop shield. Purse may read currency/wallet rather than shop.",
    "D: red flag has a distinct silhouette/color and reads campaign. The cart's tow handle is subordinate at 26px; broad wheels and awning retain its identity.",
    "Facial features and small shop goods are subordinate at 26px; silhouettes, material blocks and the selected 44px view carry the roles."
]
(HERE/'review.json').write_text(json.dumps(review,ensure_ascii=False,indent=2),encoding='utf-8')
assert not review['verification']['clipped_native_icons'],review['verification']
print('Created options.png, native-sizes.png and in-game.png. No clipped native icons.')
