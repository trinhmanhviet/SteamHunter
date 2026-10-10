"""Append locomotion to the accepted combat atlas without altering old cells."""
import json,sys,math
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT))
from tools.character_factory import _map_to_palette
from tools.pack_overhead_demo import COLOURS

SOURCE=ROOT/'prototypes/hunter_locomotion/combat_assets'
DIRECTORY=ROOT/'prototypes/hunter_locomotion/motion'
OUT=ROOT/'prototypes/hunter_locomotion/assets'


def main():
    OUT.mkdir(exist_ok=True)
    data=json.loads((DIRECTORY/'render.json').read_text())
    manifest=json.loads((SOURCE/'frames.json').read_text())
    old_count=len(manifest['frames']);count=old_count+len(data['frames'])
    sheets={};old_sheets={};locomotion={'idle':[],'run':[],'draw':[],
                                     'cycle_seconds':data['cycle_seconds'],'draw_seconds':data['draw_seconds']}
    for layer,size in [('body',128),('weapon',384)]:
        old=Image.open(SOURCE/(layer+'.png')).convert('RGBA');old_sheets[layer]=old
        sheet=Image.new('RGBA',(size*8,size*math.ceil(count/8)));sheet.paste(old,(0,0));sheets[layer]=sheet
    composites={}
    for frame in data['frames']:
        index=len(manifest['frames']);row={}
        assert max(frame['wrist_error_pixels'].values())<.5
        tile=Image.new('RGBA',(384,384),'#476579')
        ImageDraw.Draw(tile).line((0,244,383,244),fill='#dce9ce')
        for layer,offset in [('body',(128,128)),('weapon',(0,0))]:
            im=Image.open(DIRECTORY/frame[layer]).convert('RGBA')
            im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0))
            im=_map_to_palette(im,COLOURS);box=im.getbbox()
            if not box or min(box[:2])<1 or box[2]>=im.width or box[3]>=im.height:
                raise RuntimeError(f'Locomotion clipped: {layer} {frame["phase"]}/{frame["cell"]} {box}')
            size=im.width;region=[index%8*size,index//8*size,size,size]
            sheets[layer].paste(im,tuple(region[:2]));row[layer]=region;tile.alpha_composite(im,offset)
        for key in ('blade_polygon','weapon_origin','weapon_angle'):row[key]=frame[key]
        row['pose_kind']=frame['phase'];manifest['frames'].append(row)
        locomotion[frame['phase']].append(index);composites[index]=tile
    manifest['locomotion']=locomotion
    manifest['locomotion_reference']='prototypes/hunter_locomotion/motion/locomotion_rig.blend'
    for layer,sheet in sheets.items():
        old=old_sheets[layer]
        for frame in manifest['frames'][:old_count]:
            x,y,w,h=frame[layer];box=(x,y,x+w,y+h)
            assert sheet.crop(box).tobytes()==old.crop(box).tobytes(), 'Accepted combat cell changed'
        sheet.save(OUT/(layer+'.png'))
    (OUT/'frames.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',22)
    running=[];durations=[]
    for i,index in enumerate(locomotion['run']):
        im=composites[index].resize((768,768),Image.Resampling.NEAREST)
        ImageDraw.Draw(im).text((20,20),'Chạy — kiếm sau lưng',font=font,fill='white')
        running.append(im.convert('RGB'))
        durations.append((round((i+1)*data['cycle_seconds']*100)-round(i*data['cycle_seconds']*100))*10)
    running[0].save(DIRECTORY/'run_preview.gif',save_all=True,append_images=running[1:],duration=durations,loop=0,disposal=2)
    sequence=locomotion['run']*3+locomotion['draw']+locomotion['idle']
    images=[];times=[]
    for i,index in enumerate(sequence):
        images.append(composites[index].resize((768,768),Image.Resampling.NEAREST).convert('RGB'))
        times.append(durations[i%12] if i<36 else (40 if i<40 else 900))
    images[0].save(DIRECTORY/'run_stop_preview.gif',save_all=True,append_images=images[1:],duration=times,loop=0,disposal=2)
    (DIRECTORY/'review.json').write_text(json.dumps({'base_combat_cells':old_count,'protected_original_combat_cells':51,
        'locomotion_cells':len(data['frames']),'run_cells':len(locomotion['run']),
        'no_layer_clipping':True,'max_wrist_error_pixels':max(max(f['wrist_error_pixels'].values()) for f in data['frames']),
        'cycle_seconds':data['cycle_seconds'],'draw_seconds':data['draw_seconds'],
        'atlas_sizes':{layer:list(im.size) for layer,im in sheets.items()}},indent=2),encoding='utf-8')
    print('LOCOMOTION_PACKED',locomotion,flush=True)


if __name__=='__main__':main()
