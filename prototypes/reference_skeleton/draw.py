"""Manual 2D pose notes traced against the user's clip; no pose invention/interpolation."""
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tools/clip_studio/outputs/MonsterHunterWildsGreatSwordTu_20261010_030034/frames'
OUT = ROOT / 'prototypes/reference_skeleton'
OUT.mkdir(parents=True, exist_ok=True)
# Head, neck, near shoulder/elbow/wrist/hip/knee/ankle/toe,
# far shoulder/elbow/wrist/hip/knee/ankle/toe, blade guard, blade tip.
# Coordinates are in the supplied 640x360 images. Occluded joint centers are estimates.
NAMES = ['head','neck','shoulder_near','elbow_near','wrist_near','hip_near',
         'knee_near','ankle_near','toe_near','shoulder_far','elbow_far','wrist_far',
         'hip_far','knee_far','ankle_far','toe_far','guard','tip']
ROWS = [
 (23,'Bắt đầu nâng',[(304,234),(306,250),(316,255),(334,239),(326,224),(320,281),(327,292),(331,308),(339,311),(299,253),(292,235),(319,228),(310,279),(296,291),(290,300),(283,303),(347,199),(486,189)]),
 (24,'Nâng kiếm',[(303,235),(307,249),(317,254),(333,236),(320,215),(322,281),(331,293),(336,310),(343,313),(298,251),(288,238),(313,221),(310,278),(298,291),(294,300),(287,303),(344,190),(480,164)]),
 (26,'Giữ charge / kiếm ra sau',[(303,237),(308,251),(319,257),(325,236),(306,211),(324,283),(335,294),(341,311),(347,315),(299,252),(281,246),(299,219),(314,279),(302,291),(299,301),(291,304),(327,178),(447,111)]),
 (28,'Nhả / đưa kiếm lên',[(308,247),(313,261),(324,269),(305,280),(283,247),(335,288),(343,300),(347,315),(353,318),(302,263),(284,268),(282,237),(323,284),(302,293),(281,300),(273,303),(303,197),(381,73)]),
 (29,'Chuyển sang bổ',[(310,253),(317,266),(325,272),(300,284),(282,257),(336,291),(344,302),(349,316),(356,320),(304,266),(282,269),(279,246),(324,286),(302,294),(280,300),(272,303),(267,205),(312,69)]),
 (30,'Bắt đầu bổ',[(307,276),(318,287),(326,293),(325,308),(292,287),(337,303),(345,312),(351,321),(357,324),(307,286),(303,302),(285,277),(324,298),(310,307),(292,312),(282,313),(263,231),(216,103)]),
 (31,'Bổ nhanh',[(303,292),(315,298),(323,303),(315,320),(291,307),(341,306),(352,314),(359,323),(365,327),(309,291),(299,309),(284,300),(328,301),(315,311),(301,320),(293,323),(264,286),(139,202)]),
 (32,'Kiếm chạm đất',[(293,296),(307,291),(319,298),(309,319),(289,312),(342,305),(351,316),(363,324),(369,326),(308,283),(295,305),(283,307),(329,300),(329,316),(327,329),(320,332),(263,310),(142,332)]),
 (40,'Chịu đà',[(293,297),(307,292),(321,299),(312,319),(292,314),(341,305),(355,313),(372,321),(379,322),(307,282),(296,307),(284,309),(330,301),(334,317),(332,329),(325,332),(268,306),(138,329)]),
 (68,'Bắt đầu hồi',[(302,276),(311,286),(324,291),(310,310),(292,302),(334,305),(347,309),(365,319),(372,321),(307,275),(296,289),(286,297),(324,299),(333,317),(324,330),(317,332),(271,295),(129,342)]),
 (76,'Nhấc thân / kéo kiếm',[(320,270),(321,286),(330,289),(315,306),(294,299),(334,304),(348,310),(363,318),(372,321),(310,281),(299,292),(287,295),(322,299),(328,316),(316,328),(311,330),(271,291),(121,321)]),
 (84,'Về thế chuẩn bị',[(325,249),(325,267),(336,273),(320,282),(294,260),(331,291),(339,306),(343,320),(351,324),(310,273),(298,271),(286,254),(317,290),(291,295),(295,311),(288,315),(261,233),(169,144)]),
]
NEAR = '#52ecfa'
FAR = '#ff9c80'
CORE = '#f0f3f6'
SWORD = '#ffd469'
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',25)
small = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
title_font = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',34)
data=[]

def trace(draw, points, transform, width=4):
    def p(name): return transform(points[name])
    def line(a,b,color,dashed=False,w=width):
        x,y=p(a);xx,yy=p(b)
        if dashed:
            length=math.hypot(xx-x,yy-y)
            for start in range(0,max(1,int(length)),12):
                lo=start/max(1,length);hi=min(1,(start+7)/max(1,length))
                draw.line((x+(xx-x)*lo,y+(yy-y)*lo,x+(xx-x)*hi,y+(yy-y)*hi),fill=color,width=w)
        else: draw.line((x,y,xx,yy),fill=color,width=w)
    # Limb identity uses camera-near/far, not inferred anatomical left/right.
    for side,color in [('far',FAR),('near',NEAR)]:
        # Both shoulders and hips are hidden by armor. Do not imply measured centers.
        line('neck','shoulder_'+side,color,True)
        line('shoulder_'+side,'hip_'+side,color,True)
        for a,b in [('shoulder','elbow'),('elbow','wrist'),('hip','knee'),('knee','ankle'),('ankle','toe')]:
            line(a+'_'+side,b+'_'+side,color,side=='far' or a in ('shoulder','hip'))
    line('hip_near','hip_far',CORE,True)
    line('neck','head',CORE,True)
    pelvis=tuple((points['hip_near'][i]+points['hip_far'][i])/2 for i in range(2))
    draw.line([p('neck'),transform(pelvis)],fill=CORE,width=max(2,width-1))
    head=p('head');r=9*abs(transform((1,0))[0]-transform((0,0))[0])
    draw.ellipse((head[0]-r,head[1]-r,head[0]+r,head[1]+r),outline=CORE,width=width)
    line('guard','tip',SWORD,False,width+2)
    # The ornate blade curves away from the handle. Trace the handle through the
    # hand locations instead of incorrectly extrapolating the tip/guard chord.
    guard=points['guard']
    wrists=sorted([points['wrist_near'],points['wrist_far']],key=lambda v:math.dist(v,guard))
    dx,dy=wrists[1][0]-wrists[0][0],wrists[1][1]-wrists[0][1];length=max(1,math.hypot(dx,dy))
    end=(wrists[1][0]+dx/length*8,wrists[1][1]+dy/length*8)
    draw.line([transform(v) for v in [guard,*wrists,end]],fill='#b7c9d8',width=width)
    for name,pos in points.items():
        if name in ('head','tip'):continue
        x,y=transform(pos);r=3.5
        color=FAR if name.endswith('far') else SWORD if name in ('guard','wrist_near') else NEAR if name.endswith('near') else CORE
        draw.ellipse((x-r,y-r,x+r,y+r),fill=color,outline='#122535',width=1)

def card(frame,label,points,reference=False,body_only=False):
    box=(250,210,385,335) if body_only else (110,55,510,350)
    scale=4 if body_only else 1.5
    w,h=round((box[2]-box[0])*scale),round((box[3]-box[1])*scale)
    im=Image.new('RGB',(w,h+64),'#122535')
    if reference:
        raw=Image.open(SOURCE/f'frame_{frame:05}.png').convert('RGB').crop(box).resize((w,h),Image.Resampling.LANCZOS)
        im.paste(raw,(0,0))
    d=ImageDraw.Draw(im)
    transform=lambda v:((v[0]-box[0])*scale,(v[1]-box[1])*scale)
    trace(d,points,transform,3 if reference else 4)
    d.text((12,h+7),f'F{frame:03} · {label}',font=font,fill='white')
    return im

for frame,label,row in ROWS:
    points=dict(zip(NAMES,row))
    data.append({'source_frame':frame,'clip_time_seconds':round((frame-1)/29.97,4),
                 'phase':label,'joints':points,
                 'interpretation':'Manual screen-space sketch; armor-occluded joints estimated, dashed connections. No 3D reconstruction.'})
    card(frame,label,points,True).save(OUT/f'overlay_{frame:03}.png')
    card(frame,label,points).save(OUT/f'skeleton_{frame:03}.png')
    # Editable vector skeleton in original reference coordinates.
    svg=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="110 55 400 295">', '<rect x="110" y="55" width="400" height="295" fill="#122535"/>']
    for side,color in [('far',FAR),('near',NEAR)]:
        for a,b in [('shoulder','elbow'),('elbow','wrist'),('shoulder','hip'),('hip','knee'),('knee','ankle'),('ankle','toe')]:
            x,y=points[a+'_'+side];xx,yy=points[b+'_'+side]
            dash='stroke-dasharray="4 3"' if side=='far' or a in ('shoulder','hip') else ''
            svg.append(f'<line x1="{x}" y1="{y}" x2="{xx}" y2="{yy}" stroke="{color}" stroke-width="2" {dash}/>')
    x,y=points['guard'];xx,yy=points['tip'];svg.append(f'<line x1="{x}" y1="{y}" x2="{xx}" y2="{yy}" stroke="{SWORD}" stroke-width="3"/>')
    wrists=sorted([points['wrist_near'],points['wrist_far']],key=lambda v:math.dist(v,points['guard']))
    dx,dy=wrists[1][0]-wrists[0][0],wrists[1][1]-wrists[0][1];length=max(1,math.hypot(dx,dy))
    end=(wrists[1][0]+dx/length*8,wrists[1][1]+dy/length*8)
    path=' '.join(f'{x},{y}' for x,y in [points['guard'],*wrists,end])
    svg.append(f'<polyline points="{path}" fill="none" stroke="#b7c9d8" stroke-width="2"/>')
    pelvis=tuple((points['hip_near'][i]+points['hip_far'][i])/2 for i in range(2))
    x,y=points['neck'];xx,yy=pelvis;svg.append(f'<line x1="{x}" y1="{y}" x2="{xx}" y2="{yy}" stroke="{CORE}" stroke-width="2"/>')
    for a,b in [('neck','head'),('neck','shoulder_near'),('neck','shoulder_far'),('hip_near','hip_far')]:
        x,y=points[a];xx,yy=points[b];svg.append(f'<line x1="{x}" y1="{y}" x2="{xx}" y2="{yy}" stroke="{CORE}" stroke-width="1.5" stroke-dasharray="4 3"/>')
    x,y=points['head'];svg.append(f'<circle cx="{x}" cy="{y}" r="9" fill="none" stroke="{CORE}" stroke-width="2"/>')
    for name,(x,y) in points.items():
        if name not in ('head','tip'):svg.append(f'<circle cx="{x}" cy="{y}" r="2" fill="{FAR if name.endswith("far") else NEAR}"/>')
    svg.append('</svg>');(OUT/f'skeleton_{frame:03}.svg').write_text('\n'.join(svg),encoding='utf-8')

(OUT/'poses.json').write_text(json.dumps({'reference':str(SOURCE.relative_to(ROOT)).replace('\\','/'),
 'source_size':[640,360],'fps':29.97,'method':'Hand-annotated key poses, perspective retained; no interpolation.',
 'frames':data},ensure_ascii=False,indent=2),encoding='utf-8')

for reference,name in [(False,'skeleton_keyframes'),(True,'reference_overlays')]:
    board=Image.new('RGB',(1800,4*507+130),'#0b1c29');d=ImageDraw.Draw(board)
    d.text((25,18),'GS — KHUNG XƯƠNG THEO FRAME GỐC',font=title_font,fill='white')
    d.text((25,65),'Xanh: chi gần · Cam: chi xa · Vàng: trục kiếm · Nét đứt: phần bị che / ước lượng',font=small,fill='#c4d4dc')
    for i,(frame,label,row) in enumerate(ROWS):
        board.paste(card(frame,label,dict(zip(NAMES,row)),reference),(i%3*600,130+i//3*507))
    board.save(OUT/(name+'.png'))

detail=Image.new('RGB',(1080,2*564+100),'#0b1c29');d=ImageDraw.Draw(detail)
d.text((15,14),'ĐỐI CHIẾU MỐC GIỮ VÀ MỐC NHẢ',font=title_font,fill='white')
d.text((15,58),'Trái: khung xương trên ảnh gốc · Phải: tách khung xương, cùng tọa độ',font=small,fill='#c4d4dc')
for i,frame in enumerate([26,29]):
    f,label,row=next(x for x in ROWS if x[0]==frame)
    for j,ref in enumerate([True,False]):detail.paste(card(f,label,dict(zip(NAMES,row)),ref,True),(j*540,100+i*564))
detail.save(OUT/'charge_reference_comparison.png')
body_board=Image.new('RGB',(1620,4*564+115),'#0b1c29');d=ImageDraw.Draw(body_board)
d.text((25,15),'12 FRAME MỐC — PHÓNG TO KHUNG XƯƠNG THÂN NGƯỜI',font=title_font,fill='white')
d.text((25,63),'Giữ cùng tỉ lệ / tọa độ; phần kiếm ngoài khung được cắt để nhìn rõ tư thế.',font=small,fill='#c4d4dc')
for i,(frame,label,row) in enumerate(ROWS):
    body_board.paste(card(frame,label,dict(zip(NAMES,row)),False,True),(i%3*540,115+i//3*564))
body_board.save(OUT/'body_keyframes.png')
print('Saved 12 skeletons, overlays, editable SVGs, poses.json and review boards to',OUT)
