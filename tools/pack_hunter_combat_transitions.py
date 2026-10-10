"""Replace ready/raise/recovery around reference idle, retain accepted cut cells."""
import json,shutil,sys
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT))
from tools import pack_overhead_demo as pack


def main():
    old=ROOT/'prototypes/user_pose_animation/motion'
    changed=ROOT/'prototypes/hunter_locomotion/combat_transitions'
    merged=ROOT/'prototypes/hunter_locomotion/combat_motion';merged.mkdir(exist_ok=True)
    original=json.loads((old/'render.json').read_text())
    transitions=json.loads((changed/'render.json').read_text())
    replacements={f['frame']:f for f in transitions['frames']}
    rows=[]
    for row in original['frames']:
        frame=row['frame'];source=changed if frame in replacements else old
        new=replacements.get(frame,row);rows.append(new)
        for layer in ('body','weapon'):
            target=merged/new[layer];target.parent.mkdir(exist_ok=True)
            shutil.copy2(source/new[layer],target)
    original['frames']=rows
    original['idle_reference']='prototypes/hunter_locomotion/motion/render.json'
    (merged/'render.json').write_text(json.dumps(original,indent=2),encoding='utf-8')
    pack.DIRECTORY=merged;pack.ASSETS=ROOT/'prototypes/hunter_locomotion/combat_assets';pack.main()
    source=ROOT/'prototypes/user_pose_animation/assets'
    old_manifest=json.loads((source/'frames.json').read_text())
    new_manifest=json.loads((pack.ASSETS/'frames.json').read_text())
    # The metal shape is unchanged; keep its established canonical collision
    # outline rather than introducing new pixel-rounding from the idle angle.
    new_manifest['blade_local']=old_manifest['blade_local']
    (pack.ASSETS/'frames.json').write_text(json.dumps(new_manifest,indent=2),encoding='utf-8')
    for layer in ('body','weapon'):
        a=Image.open(source/(layer+'.png')).convert('RGBA')
        b=Image.open(pack.ASSETS/(layer+'.png')).convert('RGBA')
        for row in old_manifest['frames'][5:56]:
            x,y,w,h=row[layer];box=(x,y,x+w,y+h)
            assert a.crop(box).tobytes()==b.crop(box).tobytes(), 'Accepted hold/release/contact/settle cell changed'
    for frame in range(5,56):
        for key in ('blade_polygon','weapon_origin','weapon_angle'):
            assert new_manifest['frames'][frame][key]==old_manifest['frames'][frame][key]
    assert new_manifest['stages']==old_manifest['stages']
    print('REFERENCE_IDLE_COMBAT: ready/raise/recovery updated; 51 accepted contact/hold/release cells unchanged',flush=True)


if __name__=='__main__':main()
