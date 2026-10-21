"""Offline illustration of the two frame proposals; no browser or game changes."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SCALE = 2
LINE = '#583f21'
INK = '#4b3927'
FONT = ROOT / 'game/ui/fonts/PaytoneOne-Regular.ttf'
SYMBOL_FONT = ROOT / 'game/ui/fonts/DejaVuSans.ttf'


class Canvas:
    def __init__(self, w, h, fill):
        self.im = Image.new('RGB', (w*SCALE, h*SCALE), fill)
        self.d = ImageDraw.Draw(self.im)

    def box(self, rect, fill, radius=0, line=None, width=1):
        self.d.rounded_rectangle(tuple(round(v*SCALE) for v in rect), round(radius*SCALE), fill=fill, outline=line, width=round(width*SCALE))

    def text(self, pos, text, size=14, fill=INK, game=False, bold=False, anchor='lt', stroke=0, symbols=False):
        # Match UiKit.game_font(): every caption uses the same Paytone One face.
        font = ImageFont.truetype(str(SYMBOL_FONT if symbols else FONT), round(size*SCALE))
        self.d.text((round(pos[0]*SCALE), round(pos[1]*SCALE)), text, font=font,
                    fill=fill, anchor=anchor, stroke_width=round(stroke*SCALE), stroke_fill='#2e1c1c')

    def wrap(self, pos, text, width, size=13, fill='#5b695a', leading=19):
        font = ImageFont.truetype(str(FONT), round(size*SCALE))
        words = text.split(); line = ''; y = pos[1]
        for word in words:
            test = (line + ' ' + word).strip()
            if font.getlength(test) > width*SCALE and line:
                self.text((pos[0], y), line, size, fill)
                y += leading; line = word
            else:
                line = test
        if line:
            self.text((pos[0], y), line, size, fill)

    def paste(self, source, rect):
        if not isinstance(source, Image.Image):
            source = Image.open(source)
        source = source.convert('RGBA')
        x,y,w,h = rect
        source = source.resize((round(w*SCALE), round(h*SCALE)), Image.Resampling.LANCZOS)
        self.im.paste(source, (round(x*SCALE),round(y*SCALE)), source)


def coin(c,x,y,size=18):
    c.box((x,y,x+size,y+size),'#ffdc62',size/2,LINE,1.5)
    c.box((x+3,y+3,x+size-3,y+size-3),'#ffdf68',size/2,'#fff0a0',1)
    c.text((x+size/2,y+size/2),'•',12,'#b07b27',anchor='mm')


def button(c,x,y,w,h,text,tone='yellow',size=14,icon=False):
    # Exact source art and 9-slice margins from game_theme.tres. Preview is 0.5x game.
    source = Image.open(HERE/f'button-{tone}-source.png').convert('RGBA')
    sw,sh = source.size
    sx,sy = [0,80,sw-80,sw],[0,66,sh-72,sh]
    dw,dh = round(w*SCALE),round(h*SCALE)
    dx,dy = [0,40,dw-40,dw],[0,33,dh-36,dh]
    if dw < 80 or dh < 69:
        raise ValueError('Original button art needs at least 40 x 34.5 preview pixels')
    layer = Image.new('RGBA',(dw,dh))
    for row in range(3):
        for col in range(3):
            patch = source.crop((sx[col],sy[row],sx[col+1],sy[row+1]))
            patch = patch.resize((dx[col+1]-dx[col],dy[row+1]-dy[row]),Image.Resampling.LANCZOS)
            layer.paste(patch,(dx[col],dy[row]))
    c.paste(layer,(x,y,w,h))
    # Match the measured original capture: ~1 preview pixel of outer text outline.
    # Godot outline_size is not a portable Pillow/CSS outer-stroke radius.
    if icon:
        font = ImageFont.truetype(str(FONT), round(size*SCALE))
        group_w = font.getlength(text)/SCALE+16
        c.paste(HERE/'back-icon.png',(x+(w-group_w)/2,y+h/2-9,12,12))
        c.text((x+w/2+8,y+h/2-3),text,size,'#ffffff',anchor='mm',stroke=1)
    else:
        c.text((x+w/2,y+h/2-3),text,size,'#ffffff',anchor='mm',stroke=1)


def pattern(c):
    for x,y in [(29,109),(190,92),(300,180),(70,320),(245,363),(23,460),(310,510)]:
        col='#c1d0ac'
        c.box((x,y+11,x+22,y+29),col,10)
        for dx,dy in [(-3,2),(5,-3),(14,-2),(21,4)]:
            c.box((x+dx,y+dy,x+dx+7,y+dy+9),col,5)


def stage(c,x,y,w,h):
    layer=Canvas(w,h,'#91ac65')
    layer.d.ellipse((-80*SCALE,-38*SCALE,(w+30)*SCALE,30*SCALE),fill='#a4bc7a')
    layer.d.ellipse((-10*SCALE,(h-10)*SCALE,(w+30)*SCALE,(h+14)*SCALE),fill='#829c5a')
    cat_h = min(61, h - 28)
    cat_w = cat_h * 55 / 61
    for i,name in enumerate(['giao','kiem','cung','gay_phep']):
        source=Image.open(ROOT / f'game/ui/art/unit_{name}.png').convert('RGBA')
        source.thumbnail((110,122),Image.Resampling.LANCZOS)
        layer.paste(source,(12+i*(w-25)/4,(h-cat_h)/2-4+(8 if i%2 else 0),cat_w,cat_h))
    c.paste(layer.im,(x,y,w,h))


def progress(c,x,y,w=300):
    c.box((x,y,x+w,y+12),'#a5b58c',7)
    c.box((x,y,x+w*.375,y+12),'#eac25d',7)


def phone(kind):
    c=Canvas(360,640,'#adbf96');pattern(c)
    c.paste(HERE/'game-header.png',(0,0,360,52))
    button(c,12,58,94,36,'Quay lại','red',10,icon=True)
    if kind=='A':
        c.box((12,112,348,462),'#7e9467',22)
        c.box((12,108,348,458),'#d0dbb8',22,LINE,3)
        c.text((28,124),'Tuần tra',19,game=True)
        coin(c,217,123,18);c.text((240,127),'180 vàng / giờ',10)
        stage(c,15,155,330,99)
        c.text((30,269),'KHO VÀNG',10,'#61704a',bold=True)
        c.text((29,283),'540',28,game=True)
        c.text((96,299),'/ 1.440',12,'#68754f',bold=True)
        c.text((331,298),'Tích lũy tối đa 8 giờ',11,'#5d6a4b',anchor='rt')
        progress(c,29,323)
        c.text((29,343),'Đầy sau 05:00:00',11,'#596843')
        c.text((330,343),'37,5%',11,'#596843',anchor='rt')
        button(c,29,400,302,42,'THU HOẠCH')
        c.box((12,479,348,545),'#94ad79',17,'#657b50',2)
        c.text((27,493),'Tuần tra nhanh',13,game=True)
        c.text((27,516),'Nhận ngay 2 giờ tích lũy',10,'#3f5533')
        button(c,224,492,110,38,'Miễn phí 2/2','red',10)
    else:
        c.box((12,112,348,240),'#7e9467',22)
        c.box((12,108,348,236),'#91ac65',22,LINE,3)
        stage(c,15,137,330,80)
        c.text((29,119),'Tuần tra',17,game=True)
        c.box((12,271,348,486),'#7e9467',22)
        c.box((12,267,348,482),'#d0dbb8',22,LINE,3)
        c.box((28,253,129,282),'#e9c578',11,LINE,2)
        c.text((78,267),'Kho vàng',13,game=True,anchor='mm')
        c.text((180,299),'540 / 1.440',27,game=True,anchor='mt')
        coin(c,119,339,17);c.text((142,343),'180 vàng / giờ',11)
        progress(c,29,369)
        c.text((29,389),'Đầy sau 05:00:00',10.5,'#596843')
        c.text((330,389),'Tối đa 8 giờ',10.5,'#596843',anchor='rt')
        button(c,29,425,302,42,'THU HOẠCH')
        c.text((14,505),'Tuần tra nhanh',12)
        c.text((14,526),'Nhận ngay 2 giờ tích lũy',10,'#3f5533')
        button(c,234,503,114,38,'Miễn phí 2/2','red',10)
    c.paste(HERE/'game-nav.png',(0,560,360,80))
    mask=Image.new('L',c.im.size,0)
    ImageDraw.Draw(mask).rounded_rectangle((0,0,720,1280),40,fill=255)
    result=c.im.convert('RGBA');result.putalpha(mask)
    result.save(HERE/f'patrol-{kind.lower()}.png')
    return result


def main():
    c=Canvas(1200,1215,'#e5ece8')
    c.text((24,25),'GEAR DEFENDERS · ĐỀ XUẤT HÌNH DÁNG & BỐ CỤC KHUNG',12,'#657464',bold=True)
    c.text((24,50),'Khung nhẹ hơn, thông tin rõ hơn',30,'#344739',bold=True)
    c.wrap((24,95),'Học từ khung bo mềm, một nét bao và gờ đáy của Cat Gunner. Hai bản A/B là thiết kế đề xuất cho game mình, chưa thay vào game.',1120,15,leading=22)
    labels=[('Hiện tại','Ảnh chụp game sau đợt đổi màu'),('A · Khung liền khối','Phương án so sánh'),('B · Khung gắn nhãn','HƯỚNG ĐÃ CHỌN · Button gốc · Font game')]
    shots=[ROOT/'docs/ui_review/2026-10-21/menu-panel-palette/patrol_360x640.png',phone('A'),phone('B')]
    notes=[
        'Nhiều lớp viền lồng nhau. Cảnh, số liệu và hành động bị chia rời; các dòng chữ nhỏ thiếu điểm nhìn chính.',
        'Phương án đối chiếu: ghép cảnh và số liệu vào một khung. Không tiếp tục hướng này sau khi chọn B.',
        'ĐÃ CHỌN: nhãn bám mép trên, cảnh mèo riêng. Dùng button gốc và Paytone One cho cả tiêu đề, số liệu, chú thích.'
    ]
    for i in range(3):
        x=24+i*384
        c.text((x,154),labels[i][0],18,'#344739',bold=True)
        c.text((x,181),labels[i][1],12,'#657464')
        c.paste(shots[i],(x,205,360,640))
        c.wrap((x,861),notes[i],355,13,leading=19)
    c.box((24,975,1176,976),'#bdcdbf')
    c.text((24,995),'Áp dụng cùng một hệ khung',18,'#344739')
    c.wrap((24,1027),'Shop: icon trái, thông tin giữa, giá bên phải. Thành / trang bị: một khung nhóm, chia dòng bằng khoảng cách hoặc vạch mảnh.',345,12,leading=21)
    for x in (408,792):
        c.box((x,1024,x+360,1124),'#7ca0b4',20)
        c.box((x,1020,x+360,1120),'#aac9d7',20,LINE,3)
    c.paste(HERE/'chest.png',(425,1038,55,55))
    c.text((494,1037),'Rương Bạc',16)
    c.text((494,1066),'8 thẻ lính',12)
    button(c,670,1047,78,37,'600',size=13)
    c.text((812,1037),'Thông tin trang bị',14)
    c.text((812,1068),'Công',12)
    c.text((1080,1068),'40',12,anchor='rt')
    c.text((1097,1068),'→',12,anchor='mt',symbols=True)
    c.text((1131,1068),'45',12,anchor='rt')
    c.box((812,1088,1131,1089),'#7b9ba9')
    c.text((812,1097),'Máu',12);c.text((1131,1097),'1.590',12,anchor='rt')
    c.wrap((24,1163),'Nguồn: sprite gốc Cat Gunner 1.1.64. Bố cục A/B là đề xuất riêng; chưa áp dụng vào game.',1152,11,leading=18)
    c.im.resize((1200,1215),Image.Resampling.LANCZOS).save(HERE/'proposal.png')

    review=Canvas(840,850,'#e5ece8')
    review.text((24,25),'GEAR DEFENDERS · BẢN DUYỆT KHUNG MENU',11,'#657464')
    review.text((24,54),'Phương án B · Button gốc & font game',23,'#344739')
    review.wrap((24,100),'Giữ khung gắn nhãn và cảnh mèo riêng. Đồng bộ lại button và toàn bộ chữ theo bộ UI đang dùng trong game.',790,12,leading=20)
    review.paste(shots[2],(24,168,360,640))
    review.text((420,181),'Font Paytone One',18,'#344739')
    review.wrap((420,218),'Dùng cho tiêu đề, số vàng, thời gian và chú thích. Chỉnh cỡ chữ và khoảng cách để không chồng nhau.',385,12,leading=22)
    review.text((420,320),'Button gốc của game',18,'#344739')
    review.wrap((420,357),'Giữ nguyên art, viền nâu, gờ đáy và dấu chân mèo. Chữ trắng có viền như theme hiện tại.',385,12,leading=22)
    button(review,420,451,360,42,'THU HOẠCH')
    button(review,420,519,150,38,'Miễn phí 2/2','red',10)
    review.text((420,617),'Khung B giữ bố cục đã chọn',16,'#344739')
    review.wrap((420,653),'Cảnh mèo phía trên, nhãn Kho vàng gắn mép, nút Thu hoạch trong khung. Tuần tra nhanh nằm ở hàng phụ.',385,12,leading=22)
    review.wrap((420,765),'Bản đề xuất để duyệt; chưa thay vào game.',385,10,leading=18)
    review.im.resize((840,850),Image.Resampling.LANCZOS).save(HERE/'proposal-b.png')
    print(HERE/'proposal.png')


if __name__=='__main__':
    main()
