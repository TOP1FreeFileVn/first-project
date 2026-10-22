from pathlib import Path
import shutil
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/ui_review/2026-10-23/cat-drive'
BG,INK='#e8ddc8','#583f21'
font=lambda n:ImageFont.truetype(str(ROOT/'game/ui/fonts/PaytoneOne-Regular.ttf'),n)
sheet=Image.new('RGB',(1024,1140),BG)
d=ImageDraw.Draw(sheet)
d.text((18,13),'Trong game · 24 pha quanh một vòng quay',font=font(21),fill=INK)
for cell,i in enumerate(range(0,96,4)):
    x=(cell%4)*256;y=50+(cell//4)*180
    im=Image.open(OUT/f'phase-{i:03d}.png').resize((170,170),Image.Resampling.LANCZOS)
    sheet.paste(im,(x+43,y))
    d.text((x+24,y+12),str(i*3.75)+'°',font=font(12),fill=INK)
sheet.save(OUT/'phase-contact.png')
detail=Image.new('RGB',(1024,540),BG)
dd=ImageDraw.Draw(detail)
dd.text((18,14),'Viền thân và tay · Ảnh từ Core trong game',font=font(21),fill=INK)
for cell,i in enumerate([0,12,24,36,48,60,72,84]):
    im=Image.open(OUT/f'phase-{i:03d}.png').crop((70,125,187,213)).resize((234,176),Image.Resampling.NEAREST)
    x=(cell%4)*256+11;y=64+(cell//4)*230
    detail.paste(im,(x,y))
    dd.text((x+117,y+195),str(i*3.75)+'°',font=font(15),fill=INK,anchor='mm')
detail.save(OUT/'joint-details.png')
old=ROOT/'docs/ui_review/2026-10-22/battle-cardboard-castle'
for size in ['450x800','360x640']:
    shutil.copy2(old/f'layers-cat-round-fight_{size}.png',OUT/f'battle_{size}.png')
shutil.copy2(old/'layers-cat-round-manifest.json',OUT/'battle-manifest.json')
print('Packaged native phase contact, joint details and actual battle captures.')
