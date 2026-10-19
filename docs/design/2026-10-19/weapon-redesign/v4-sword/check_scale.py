from prepare_review import *

sword=Image.open(OUT/'kiem.png').convert('RGBA')
board=Image.new('RGBA',(1024,800),BG); d=ImageDraw.Draw(board)
for i,(angle,height) in enumerate([(-40,145),(-36,160),(-32,175),(-30,185)]):
    unit,p=hold(sword,angle,height)
    paste(board,unit,(i%2*512,i//2*400,512,360))
    d.text((i%2*512+20,i//2*400+360),f'{angle} deg / {height}px',font=font(20),fill=INK)
board.convert('RGB').save(HERE/'scale-contact-sheet.png')
