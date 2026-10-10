"""Render the three saved poses at game pixel scale and at 4x inspection scale.

Run with bundled Blender: -b prototypes/hunter_pose_workspace/hunter_pose.blend
 --python tools/render_hunter_pose_workspace.py
"""
import json
from pathlib import Path
import bpy

OUT=Path(__file__).resolve().parents[1]/'prototypes/hunter_pose_workspace'
scene=bpy.context.scene
rig=bpy.data.objects['HunyuanHeavyRig'];height=1.9702799916267395
report=[]
for label,frame in [('hold',1),('cut',15),('finish',30)]:
    scene.frame_set(frame);bpy.context.view_layer.update()
    wrists={s:(rig.matrix_world@rig.pose.bones['forearm.'+s].tail-
               bpy.data.objects['WristIK.'+s].matrix_world.translation).length/height*104 for s in ('R','L')}
    report.append({'pose':label,'frame':frame,'wrists':wrists,
                   'knees':{s:list(rig.pose.bones['shin.'+s].head) for s in ('R','L')}})
    for size in (384,1536):
        scene.render.resolution_x=scene.render.resolution_y=size
        scene.render.filepath=str(OUT/(label+f'_{size}.png'))
        bpy.ops.render.render(write_still=True)
(OUT/'render_checks.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('POSE_RENDER_CHECKS',json.dumps(report),flush=True)
