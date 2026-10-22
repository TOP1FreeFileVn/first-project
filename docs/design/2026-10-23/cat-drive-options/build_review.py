from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
BG='#e8ddc8'
CARD='#f7efdf'
INK='#583f21'
ff=ROOT/'game/ui/fonts/PaytoneOne-Regular.ttf'
font=lambda n:ImageFont.truetype(str(ff),n)
variants=json.loads((HERE/'variants.json').read_text(encoding='utf8'))
assert len(variants)==12

sheet=Image.new('RGB',(1200,1510),BG)
d=ImageDraw.Draw(sheet)
d.text((24,20),'12 hướng máy sau mèo · Chọn A–L',font=font(26),fill=INK)
d.text((24,60),'Mỗi ô: máy riêng bên trái / có mèo bên phải. Cùng palette và cùng tỷ lệ mèo.',font=font(15),fill=INK)
for i,v in enumerate(variants):
    x=16+(i%3)*396;y=100+(i//3)*340
    d.rounded_rectangle((x,y,x+380,y+324),radius=15,fill=CARD)
    title=v['id']+' · '+v['title']
    f=font(19)
    if d.textbbox((0,0),title,font=f)[2]>350:f=font(17)
    d.text((x+14,y+13),title,font=f,fill=INK)
    for suffix,px,py in [('machine',5,94),('cat',150,54)]:
        im=Image.open(HERE/f"godot/{v['id']}-{suffix}.png").convert('RGBA')
        sheet.paste(im,(x+px,y+py),im)
    d.text((x+76,y+275),'Máy riêng',font=font(12),fill=INK,anchor='mm')
    d.text((x+262,y+275),'Khi có mèo',font=font(12),fill=INK,anchor='mm')
    words=v['idea'].split();lines=[];line=''
    for word in words:
        candidate=(line+' '+word).strip()
        if d.textbbox((0,0),candidate,font=font(12))[2]>350 and line:lines.append(line);line=word
        else:line=candidate
    if line:lines.append(line)
    for j,line in enumerate(lines[:2]):d.text((x+14,y+290+j*16),line,font=font(12),fill=INK)
d.text((24,1480),'Concept để duyệt · Chưa thay vào game · Chọn mẫu rồi mới hoàn thiện cơ khí.',font=font(14),fill=INK)
sheet.save(HERE/'options.png')
for start,end,name in [(0,6,'options-A-F.png'),(6,12,'options-G-L.png')]:
    y=100+(start//3)*340
    crop=sheet.crop((0,y,1200,y+680))
    crop.save(HERE/name)

frames=[];bounds=[]
for phase in range(24):
    im=Image.new('RGB',(900,1050),BG);d=ImageDraw.Draw(im)
    d.text((15,10),'12 cơ cấu cùng quay · A–L',font=font(20),fill=INK)
    for i,v in enumerate(variants):
        x=(i%3)*300;y=45+(i//3)*248
        d.rounded_rectangle((x+6,y,x+294,y+238),radius=11,fill=CARD)
        d.text((x+150,y+17),v['id']+' · '+v['title'],font=font(14),fill=INK,anchor='mm')
        art=Image.open(HERE/f"frames/png/{v['id']}-{phase:02}.png").convert('RGBA')
        box=art.getbbox();assert box and box[0]>0 and box[1]>0 and box[2]<192 and box[3]<192,(v['id'],phase,box)
        bounds.append({'id':v['id'],'frame':phase,'bbox':box})
        im.paste(art,(x+54,y+32),art)
    frames.append(im)
palette=sheet.resize((900,1132),Image.Resampling.LANCZOS).quantize(colors=128)
gif=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in frames]
gif[0].save(HERE/'motion.gif',save_all=True,append_images=gif[1:],loop=0,duration=[120,130]*12,disposal=2)
(HERE/'render-checks.json').write_text(json.dumps({'variant_count':12,'engine':'Godot4.7.2','stills':36,'frames':288,'all_frame_alpha_bounds_inside':True,'bounds':bounds},indent=2),encoding='utf8')
print('Created options.png, A–F/G–L sheets, motion.gif and native render bounds.')
