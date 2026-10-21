"""Proof sheet and direct raster QA for the authored bow refinement."""
from pathlib import Path
import json, math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parents[5]
SOURCES=PROJECT/'docs/design/2026-10-19/hero-equipment/sources'
layer=Image.open(ROOT/'bow-refined-layer.png').convert('RGBA')
base=Image.open(SOURCES/'hero-base.png').convert('RGBA')
base.alpha_composite(layer)
base.alpha_composite(Image.open(SOURCES/'hero-paws.png').convert('RGBA'))
base.save(ROOT/'hero-bow-refined.png')
base.resize((128,120),Image.Resampling.LANCZOS).save(ROOT/'hero-bow-refined-128.png')
bbox=layer.getbbox()
isolated=layer.crop(bbox)
isolated.save(ROOT/'bow-refined-isolated.png')
icon=Image.new('RGBA',(64,64))
thumb=isolated.copy()
thumb.thumbnail((60,60),Image.Resampling.LANCZOS)
icon.alpha_composite(thumb,((64-thumb.width)//2,(64-thumb.height)//2))
icon.save(ROOT/'bow-refined-64.png')
# Measure a normal across the authored outer upper shoulder, away from joins.
p0=np.array([173.,108.]);p1=np.array([158.,120.]);p2=np.array([151.,133.]);p3=np.array([152.,141.])
t=.55
p=(1-t)**3*p0+3*(1-t)**2*t*p1+3*(1-t)*t*t*p2+t**3*p3
v=3*(1-t)**2*(p1-p0)+6*(1-t)*t*(p2-p1)+3*t*t*(p3-p2)
n=np.array([-v[1],v[0]])/np.linalg.norm(v)
a=np.array(layer)
steps=np.arange(-18,18.01,.125)
xy=np.rint((p[None,:]+steps[:,None]*n[None,:])*3).astype(int)
px=a[xy[:,1],xy[:,0],:]
ink=(np.linalg.norm(px[:,:3]-np.array([88,63,33]),axis=1)<5)&(px[:,3]>127)
mid=np.abs(steps).argmin();lo=mid;hi=mid
while lo>0 and ink[lo-1]:lo-=1
while hi<len(ink)-1 and ink[hi+1]:hi+=1
width=float(steps[hi]-steps[lo]+.125)
grip_row=a[166*3,:,:]
grip_pixels=np.where((np.linalg.norm(grip_row[:,:3]-np.array([231,120,91]),axis=1)<1)&(grip_row[:,3]>254))[0]
grip_pixels=grip_pixels[(grip_pixels>140*3)&(grip_pixels<180*3)]
grip_raster_center=float((grip_pixels.min()+grip_pixels.max()+1)/2/3)
report={
 'source_generation':'../raw/bow-iteration-4.png',
 'source_model':'gpt-image-2.5-sunburst','source_file':'2uKzqvXeOSPQqfaow6s7TU','source_node':'54:2',
 'source_review':'Generated recurve shape retained as design reference;21–26sourcepx contour failed final thickness.',
 'authorship':'Hand-authored SVG cubic Bezier silhouette and fill proportions, based on generated recurve; no morphology, dilation, skeletonization or global outline processing.',
 'svg':'bow-refined.svg','canvas':[256,240],'raster':[768,720],'render_scale':3,
 'main_stroke_native':9,'main_stroke_raster':27,'string_native':1.4,'leather_seams_native':1.8,
 'palette':{'main':'#583f21','wood':'#b87b42','brass':'#dfac58','coral':'#e7785b','seam':'#984e39','string':'#9c8564'},
 'grip':[160,166],'orientation':'upright ready/carry, string outward on right; no arrow or drawn pose',
 'grip_alignment':{'riser_path_x':[148,172],'riser_center_x':160,'upper_join_y':151,'lower_join_y':181,'join_midpoint_y':166,'raster_coral_center_x_at_y166':grip_raster_center,'construction':'One continuous body path; coral material clipped inside it; main silhouette drawn once. No separately outlined grip pad.'},
 'native_bounds':[round(v/3,3) for v in bbox],'clipped':not(0<=bbox[0]<bbox[2]<=768 and 0<=bbox[1]<bbox[3]<=720),
 'normal_measurement':{'curve_parameter':t,'point_native':p.tolist(),'measured_opaque_ink_native':width,'note':'Raster sample perpendicular to upper shoulder; thresholded opaque ink. SVG geometry is9px, antialias sampling may vary within one rasterpixel.'},
 'render_engine':'Godot4.7.2 Image.load_svg_from_string at3x; transparentPNG',
 'integration':'Review layer only, production unchanged',
}
(ROOT/'authored-processing.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
fontdir=Path('C:/Windows/Fonts')
def f(size,b=False):return ImageFont.truetype(str(fontdir/('segoeuib.ttf' if b else 'segoeui.ttf')),size)
board=Image.new('RGB',(1080,820),'#d7e4dd')
d=ImageDraw.Draw(board)
d.text((26,18),'CUNG - CHINH NET VA TI LE',font=f(30,True),fill='#583f21')
d.text((26,62),'Recurve authored from bow4 reference / main9px / string1.4px / quieter material seams',font=f(17),fill='#54685f')
d.rounded_rectangle((18,105,340,793),16,fill='#eaf0e8')
d.rounded_rectangle((358,105,1062,555),16,fill='#eaf0e8')
d.rounded_rectangle((358,575,1062,793),16,fill='#eaf0e8')
d.text((36,120),'New silhouette',font=f(22,True),fill='#583f21')
big=isolated.copy();big.thumbnail((245,555),Image.Resampling.LANCZOS)
board.paste(big,(179-big.width//2,168),big)
d.text((36,738),'Main contour:9nativepx',font=f(18),fill='#54685f')
d.text((36,765),'No dilation / no more generation',font=f(16),fill='#54685f')
d.text((382,120),'Fixed paw / face clear',font=f(22,True),fill='#583f21')
hero=base.resize((432,405),Image.Resampling.LANCZOS)
board.paste(hero,(520,144),hero)
d.text((382,590),'Native-scale review',font=f(21,True),fill='#583f21')
native=base.resize((128,120),Image.Resampling.LANCZOS)
board.paste(native,(430,639),native)
board.paste(icon,(645,669),icon)
d.text((430,762),'128x120',font=f(15),fill='#54685f')
d.text((645,741),'64px icon',font=f(15),fill='#54685f')
d.text((788,642),'Main9px',font=f(20,True),fill='#583f21')
d.text((788,680),'String1.4px',font=f(18),fill='#54685f')
d.text((788,718),'Surface1.8px',font=f(18),fill='#54685f')
board.save(ROOT/'bow-refined-review.png')
print(json.dumps(report,ensure_ascii=False))
