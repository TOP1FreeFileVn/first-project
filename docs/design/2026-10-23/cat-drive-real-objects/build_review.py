from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
BG, CARD, INK = '#e8ddc8', '#f7efdf', '#583f21'
font = lambda n: ImageFont.truetype(str(ROOT/'game/ui/fonts/PaytoneOne-Regular.ttf'), n)
variants = json.loads((HERE/'variants.json').read_text(encoding='utf8'))
assert len(variants) == 8

def text_lines(draw, text, width, n=15):
    lines, line = [], ''
    for word in text.split():
        test = (line+' '+word).strip()
        if line and draw.textbbox((0,0),test,font=font(n))[2] > width:
            lines.append(line)
            line = word
        else:
            line = test
    if line: lines.append(line)
    return lines

sheet = Image.new('RGB', (1280,1760), BG)
d = ImageDraw.Draw(sheet)
d.text((24,18), '8 cơ cấu từ đồ vật thật · A–H', font=font(29), fill=INK)
d.text((24,61), 'Giữ càng đẩy tam giác béo gốc · Máy riêng bên trái / đặt sau mèo bên phải', font=font(16), fill=INK)
for i,v in enumerate(variants):
    x,y = 16+(i%2)*632, 105+(i//2)*400
    d.rounded_rectangle((x,y,x+616,y+384), radius=16, fill=CARD)
    d.text((x+18,y+15), v['id']+' · '+v['title'], font=font(24), fill=INK)
    for kind,px,py,size in [('machine',22,84,224),('cat',316,57,280)]:
        art=Image.open(HERE/f"godot/{v['id']}-{kind}.png").convert('RGBA').resize((size,size),Image.Resampling.LANCZOS)
        sheet.paste(art,(x+px,y+py),art)
    d.text((x+134,y+316),'Đồ vật riêng',font=font(14),fill=INK,anchor='mm')
    d.text((x+456,y+316),'Đặt sau mèo',font=font(14),fill=INK,anchor='mm')
    for j,line in enumerate(text_lines(d,v['idea'],578,14)[:2]):
        d.text((x+18,y+341+j*19),line,font=font(14),fill=INK)
d.text((24,1724),'Bản thảo để chọn hình · Chưa thay vào game',font=font(15),fill=INK)
sheet.save(HERE/'options.png')
for first,last,name in [(0,4,'options-A-D.png'),(4,8,'options-E-H.png')]:
    part=Image.new('RGB',(1280,900),BG)
    pd=ImageDraw.Draw(part)
    pd.text((24,16),'Cơ cấu từ đồ vật thật · '+('A–D' if first==0 else 'E–H'),font=font(26),fill=INK)
    pd.text((24,54),'Cùng mèo, cùng tỷ lệ · Giữ càng đẩy tam giác béo gốc',font=font(16),fill=INK)
    part.paste(sheet.crop((0,105+(first//2)*400,1280,105+(first//2)*400+800)),(0,90))
    part.save(HERE/name)

frames,bounds=[],[]
for phase in range(24):
    im=Image.new('RGB',(1000,1020),BG)
    dr=ImageDraw.Draw(im)
    dr.text((18,12),'8 đồ vật thật · Giữ càng tam giác béo',font=font(22),fill=INK)
    for i,v in enumerate(variants):
        x,y=(i%4)*250,55+(i//4)*472
        dr.rounded_rectangle((x+6,y,x+244,y+456),radius=13,fill=CARD)
        # Small separate-object study above the animated cat allows identification.
        dr.text((x+125,y+22),v['id']+' · '+v['title'],font=font(13),fill=INK,anchor='mm')
        bare=Image.open(HERE/f"godot/{v['id']}-machine.png").convert('RGBA')
        im.paste(bare,(x+53,y+38),bare)
        art=Image.open(HERE/f"frames/png/{v['id']}-{phase:02}.png").convert('RGBA')
        box=art.getbbox()
        assert box and min(box[:2])>0 and box[2]<192 and box[3]<192,(v['id'],phase,box)
        bounds.append({'id':v['id'],'frame':phase,'bbox':box})
        im.paste(art,(x+29,y+220),art)
        dr.text((x+125,y+432),'Đặt sau mèo',font=font(13),fill=INK,anchor='mm')
    frames.append(im)
palette=sheet.resize((740,1017),Image.Resampling.LANCZOS).quantize(colors=128)
gif=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in frames]
gif[0].save(HERE/'motion.gif',save_all=True,append_images=gif[1:],loop=0,duration=[120,130]*12,disposal=2)
(HERE/'render-checks.json').write_text(json.dumps({'variant_count':8,'engine':'Godot 4.7.2','stills':24,'frames':192,'all_frame_alpha_bounds_inside':True,'bounds':bounds},indent=2),encoding='utf8')
print('Packaged 8 grounded concepts, two review sheets and motion.gif. All 192 frame bounds inside.')
