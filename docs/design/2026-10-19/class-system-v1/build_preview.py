"""Build review-only class badges and a Vietnamese art board. No game assets change."""
from pathlib import Path
import json
import math
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
INK = '#583f21'
CLASSES = [
    ('infantry', 'Bộ binh', 'Kiếm & khiên', '#df6a59'),
    ('ranged', 'Tầm xa', 'Cung & tên', '#759b63'),
    ('mage', 'Pháp sư', 'Trượng phép', '#83b8c5'),
    ('cavalry', 'Kỵ binh', 'Đầu ngựa', '#bd8f62'),
]

def badge_svg(key):
    svg = (HERE / f'glyph-{key}.svg').read_text(encoding='utf-8')
    body = svg[svg.index('>') + 1:svg.rindex('</svg>')]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">'
            f'<circle cx="64" cy="67" r="56" fill="#c6a46c" stroke="{INK}" stroke-width="5"/>'
            f'<circle cx="64" cy="61" r="56" fill="#fff0c9" stroke="{INK}" stroke-width="5"/>'
            '<circle cx="64" cy="61" r="47" fill="#f4e2bc"/>'
            f'<g transform="translate(8 5) scale(.875)">{body}</g></svg>')

def p(cx, cy, r, a):
    a = math.radians(a)
    return (cx + r * math.cos(a), cy + r * math.sin(a))

def arrow_points(cx, cy, start, end):
    angles = [start + (end - start) * i / 20 for i in range(21)]
    return ([p(cx, cy, 190, a) for a in angles] +
            [p(cx, cy, 201, end), p(cx, cy, 180, end + 9), p(cx, cy, 159, end)] +
            [p(cx, cy, 170, a) for a in reversed(angles)])

def create_badges():
    for key, *_ in CLASSES:
        (HERE / f'class-{key}.svg').write_text(badge_svg(key), encoding='utf-8')

def render_board():
    scale = 2
    canvas = Image.new('RGB', (1280 * scale, 1120 * scale), '#80b0e7')
    draw = ImageDraw.Draw(canvas)
    font_path = ROOT / 'game/ui/fonts/PaytoneOne-Regular.ttf'
    body_font = Path('C:/Windows/Fonts/arial.ttf')
    items = []

    def rounded(x, y, w, h, fill, radius=20, stroke=INK, sw=3):
        draw.rounded_rectangle(tuple(int(v * scale) for v in (x,y,x+w,y+h)),
                               radius=radius*scale, fill=fill, outline=stroke, width=sw*scale)
        items.append(dict(type='rect', x=x,y=y,w=w,h=h,fill=fill,radius=radius,stroke=stroke,sw=sw))

    def text(x, y, value, size, color=INK, center=False, body=False):
        font = ImageFont.truetype(str(body_font if body else font_path), size*scale)
        draw.text((x*scale,y*scale), value, font=font, fill=color, anchor='mt' if center else 'lt')
        items.append(dict(type='text',x=x,y=y,text=value,size=size,color=color,center=center,body=body))

    def icon(key, x, y, size):
        img = Image.open(HERE / f'class-{key}.png').convert('RGBA')
        img = img.resize((size*scale,size*scale), Image.Resampling.LANCZOS)
        canvas.paste(img, (x*scale,y*scale), img)
        items.append(dict(type='icon',key=key,x=x,y=y,size=size))

    text(48,32,'GEAR MEOW  /  BẢN DUYỆT 01',18)
    text(48,70,'Biểu tượng & khắc chế hệ',40)
    text(50,133,'Bốn hình tượng riêng, cùng nét viền nâu và huy hiệu kem của game.',18,body=True)
    rounded(48,190,448,650,'#fff0d6')
    rounded(520,190,712,650,'#fff0d6')
    text(72,214,'4 HỆ QUÂN',23)
    text(548,214,'VÒNG KHẮC CHẾ',23)

    for i,(key,name,caption,color) in enumerate(CLASSES):
        x = 68 + (i % 2)*208
        y = 264 + (i // 2)*250
        rounded(x,y,192,230,'#f7e4c1',16,'#d2b78a',2)
        icon(key,x+30,y+10,132)
        text(x+96,y+150,name,25,center=True)
        text(x+96,y+190,caption,16,center=True,body=True)
    text(272,796,'Hình khối rõ · màu nhấn nhẹ',16,center=True,body=True)

    cx,cy=876,523
    for start,end in [(-68,-32),(22,58),(112,148),(202,238)]:
        pts=arrow_points(cx,cy,start,end)
        draw.polygon([(int(x*scale),int(y*scale)) for x,y in pts],fill='#f5c565')
        draw.line([(int(x*scale),int(y*scale)) for x,y in pts+[pts[0]]],fill=INK,width=3*scale,joint='curve')
        items.append(dict(type='arrow',points=pts,fill='#f5c565',stroke=INK,sw=3))

    for key,name,x,y in [('ranged','Tầm xa',876,343),('infantry','Bộ binh',1056,523),
                          ('mage','Pháp sư',876,703),('cavalry','Kỵ binh',696,523)]:
        icon(key,x-55,y-55,110)
    text(cx,477,'SÁT THƯƠNG',17,center=True)
    text(cx,503,'KHẮC CHẾ',20,center=True)
    text(cx,538,'×2',43,center=True)
    for angle in [-45,45,135,225]:
        x,y=p(cx,cy,233,angle)
        rounded(x-27,y-17,54,34,'#fff7e9',12,'#c6a46c',2)
        text(x,y-12,'×2',21,center=True)
    text(876,803,'Mũi tên chỉ hệ bị khắc',17,center=True,body=True)

    rounded(48,866,1184,202,'#fff0d6')
    text(72,886,'KIỂM TRA KHI THU NHỎ',22)
    text(1080,890,'48 / 32 / 24 px',17,body=True)
    rounded(72,932,1136,108,'#dce8ef',12,'#c5d3d9',1)
    for i,(key,name,*_) in enumerate(CLASSES):
        x=100+i*282
        icon(key,x,949,48)
        icon(key,x+65,957,32)
        icon(key,x+113,961,24)
        text(x+155,967,name,19)
    text(48,1090,'4 hệ · Mũi tên chỉ chiều khắc chế · Sát thương ×2',17)
    text(1218,1092,'DRAFT · 01',14,center=True,body=True)
    canvas.resize((1280,1120),Image.Resampling.LANCZOS).save(HERE/'preview.png')
    canvas.save(HERE/'preview@2x.png')
    (HERE/'layout.json').write_text(json.dumps({'width':1280,'height':1120,'items':items},ensure_ascii=False,indent=2),encoding='utf-8')
    print('Built preview.png and layout.json')

if __name__=='__main__':
    import sys
    if '--badges' in sys.argv:
        create_badges()
    else:
        render_board()
