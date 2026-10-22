"""Assemble native vector renders. One local unit = one board px."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
BG='#e8ddc8'
INK='#583f21'
font=ImageFont.truetype(str(ROOT/'game/ui/fonts/PaytoneOne-Regular.ttf'),19)
small=ImageFont.truetype(str(ROOT/'game/ui/fonts/PaytoneOne-Regular.ttf'),14)
frames=[]
bounds=[]
for f in sorted((HERE/'frames/png').glob('frame-*.png')):
    im=Image.open(f).convert('RGBA')
    box=im.getbbox()
    assert box and box[0]>0 and box[1]>0 and box[2]<320 and box[3]<320,(f,box)
    bounds.append({'file':f.name,'alpha_bbox':box})
    frame=Image.new('RGB',(360,390),BG)
    frame.paste(im,(20,15),im)
    ImageDraw.Draw(frame).text((180,360),'Mèo trước · máy tời phía sau',font=small,fill=INK,anchor='mm')
    frames.append(frame)
assert len(frames)==24
palette_sheet=Image.new('RGB',(2160,1560),BG)
for i,im in enumerate(frames):palette_sheet.paste(im,((i%6)*360,(i//6)*390))
palette=palette_sheet.quantize(colors=128)
gif=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in frames]
gif[0].save(HERE/'motion.gif',save_all=True,append_images=gif[1:],loop=0,duration=[120,130]*12,disposal=2)

review=Image.new('RGB',(1200,570),BG)
d=ImageDraw.Draw(review)
d.text((25,23),'V7 · Máy tời xanh xám, vành vuông bo phía sau mèo',font=font,fill=INK)
labels=['Cán ở trên','Đẩy sang phải','Cán xuống dưới','Kéo về bên trái']
for i,label in enumerate(labels):
    im=Image.open(HERE/f'godot/pose-{i+1}-384.png').convert('RGBA')
    im=im.resize((300,300),Image.Resampling.LANCZOS)
    review.paste(im,(i*300,53),im)
    d.text((i*300+150,360),label,font=small,fill=INK,anchor='mm')
    im=Image.open(HERE/f'godot/pose-{i+1}-128.png').convert('RGBA')
    review.paste(im,(i*300+86,388),im)
d.text((600,545),'Hàng dưới: 1 đơn vị = 1 px bàn gear · Render SVG bằng Godot',font=small,fill=INK,anchor='mm')
review.save(HERE/'poses.png')

comparison=Image.new('RGB',(800,490),BG)
d=ImageDraw.Draw(comparison)
for i,label in enumerate(['V6 · Trước','V7 · Cụm truyền động mới']):
    if i==0:
        im=Image.open(HERE.parent/'cat-two-hand-drive-v6/godot/pose-2-300.png').convert('RGBA')
        comparison.paste(im,(50,100),im)
    else:
        im=Image.open(HERE/'godot/pose-2-384.png').convert('RGBA')
        comparison.paste(im,(408,58),im)
    d.text((i*400+200,25),label,font=font,fill=INK,anchor='mm')
d.text((400,460),'Cùng tỷ lệ mèo · Cụm máy màu lạnh tách khỏi lông kem',font=small,fill=INK,anchor='mm')
comparison.save(HERE/'before-after.png')

detail=Image.new('RGB',(800,470),BG)
d=ImageDraw.Draw(detail)
d.text((400,25),'Vành vuông bo + thanh nối hai trục + cần đẩy',font=font,fill=INK,anchor='mm')
im=Image.open(HERE/'godot/mechanism.png').convert('RGBA')
detail.paste(im,(20,58),im)
im=Image.open(HERE/'godot/pose-2-384.png').convert('RGBA')
detail.paste(im,(410,58),im)
d.text((212,443),'Cụm máy khi ẩn mèo',font=small,fill=INK,anchor='mm')
d.text((602,443),'Khi có mèo ở lớp trước',font=small,fill=INK,anchor='mm')
detail.save(HERE/'mechanism-review.png')
(HERE/'render-checks.json').write_text(json.dumps({'native_renderer':'Godot 4.7.2','frame_count':24,'cycle_ms':3000,'viewBox':[-64,-64,128,128],'all_frames_inside_canvas':True,'bounds':bounds},indent=2),encoding='utf-8')
print('Created motion.gif, poses.png, before-after.png, mechanism-review.png and render-checks.json.')
