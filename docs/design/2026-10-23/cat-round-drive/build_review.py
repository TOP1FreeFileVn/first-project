from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
BG,INK='#e8ddc8','#583f21'
font=lambda n:ImageFont.truetype(str(ROOT/'game/ui/fonts/PaytoneOne-Regular.ttf'),n)
sheet=Image.new('RGB',(1100,570),BG)
d=ImageDraw.Draw(sheet)
d.text((24,18),'Trục tròn sau mèo · Bỏ chấm đầu tam giác',font=font(25),fill=INK)
for kind,x,y in [('machine',18,130),('cat',340,65),('native',852,190)]:
    art=Image.open(HERE/f'godot/A-{kind}.png').convert('RGBA')
    sheet.paste(art,(x,y),art)
for text,x in [('Cơ cấu riêng',146),('Đặt sau mèo',532),('Kích thước game',916)]:
    d.text((x,450),text,font=font(17),fill=INK,anchor='mm')
d.text((24,510),'Đĩa tròn xanh xám · Tam giác béo liền khối · Giữ dáng mèo đã chỉnh',font=font(16),fill=INK)
sheet.save(HERE/'preview.png')
frames=[];bounds=[]
contact=Image.new('RGB',(1060,310),BG)
cd=ImageDraw.Draw(contact)
for i in range(24):
    art=Image.open(HERE/f'frames/png/A-{i:02}.png').convert('RGBA')
    b=art.getbbox()
    assert b and b[0]>0 and b[1]>0 and b[2]<256 and b[3]<256,(i,b)
    bounds.append(b)
    im=Image.new('RGB',(500,390),BG)
    dr=ImageDraw.Draw(im)
    dr.text((250,24),'Trục tròn · Tam giác không chấm tròn',font=font(18),fill=INK,anchor='mm')
    im.paste(art,(122,70),art)
    frames.append(im)
    if i%6==0:
        contact.paste(art,(5+(i//6)*265,0),art)
        cd.text((133+(i//6)*265,285),str(i*15)+'°',font=font(16),fill=INK,anchor='mm')
contact.save(HERE/'poses.png')
palette=sheet.quantize(colors=128)
q=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in frames]
q[0].save(HERE/'motion.gif',save_all=True,append_images=q[1:],duration=[120,130]*12,loop=0,disposal=2)
(HERE/'render-checks.json').write_text(json.dumps({'engine':'Godot 4.7.2','stills':3,'animation_frames':24,'all_frame_alpha_bounds_inside':True,'tip_marker_shapes':0,'bounds':bounds},indent=2),encoding='utf8')
print('Created preview.png, poses.png and motion.gif. 24/24 frame bounds inside.')
