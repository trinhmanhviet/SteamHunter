"""Technical comparison sheet of actual prepared scene renders."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
OUT=Path(__file__).parent
board=Image.new('RGB',(1536,730),'#192f3e')
d=ImageDraw.Draw(board)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',21)
title=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',28)
d.text((22,16),'BẢN THỬ CHỈNH POSE — GIÁP CỨNG, CHÂN KHÔNG XOẮN SAI',font=title,fill='white')
d.text((22,56),'Ba tư thế có thể chỉnh trực tiếp trong Blender · Kiếm và hai tay giữ cùng điểm cầm',font=font,fill='#d8e7ee')
for i,(name,label) in enumerate([('hold','Giữ charge — frame 1'),('cut','Bổ xuống — frame 15'),('finish','Kết thúc — frame 30')]):
    x=12+i*512
    image=Image.open(OUT/(name+'_384.png')).convert('RGBA')
    panel=Image.new('RGBA',(384,384),'#476579');panel.alpha_composite(image)
    ImageDraw.Draw(panel).line((0,244,383,244),fill='#dce9ce',width=1)
    crop=panel.crop((15,90,384,260)).resize((492,227),Image.Resampling.NEAREST)
    board.paste(crop.convert('RGB'),(x,130))
    d.text((x+10,97),label,font=font,fill='#ffe5a0')
    detail=panel.crop((153,203,229,247)).resize((380,220),Image.Resampling.NEAREST)
    board.paste(detail.convert('RGB'),(x+55,416))
    d.text((x+55,383),'Giáp gối, giáp ống chân và điểm tỳ',font=font,fill='#d8e7ee')
d.text((22,664),'Điểm điều khiển: Kiếm · Hông · Thân · Chân trước · Chân sau',font=font,fill='#ffe5a0')
d.text((22,696),'G để kéo, R để xoay; xoay chân quanh điểm tỳ mũi chân. Đây là bản thử tư thế, chưa thay asset trong game.',font=font,fill='#d8e7ee')
board.save(OUT/'pose_review.png')
