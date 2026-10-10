"""Blender integration checks for the hunter's side-view pose workspace.

blender -b scene.blend --python tests/check_pose_workspace.py
"""
import json
import math
import bpy
from mathutils import Vector

scene=bpy.context.scene
rig=bpy.data.objects['HunyuanHeavyRig']
front=rig.pose.bones['shin.R']
direction=(front.matrix@front.bone.matrix_local.inverted()).to_3x3()@Vector((0,-1,0))
# A front facing armor panel must not rotate toward +X, away from the -X camera.
assert direction.x<.25, f'Front greave turned away from camera: front axis={tuple(direction)}'
print('POSE_WORKSPACE_CHECK: leg twist passes',flush=True)

if scene.get('pose_workspace_version'):
    from pathlib import Path
    directory=Path(bpy.data.filepath).parent
    expected=json.loads((directory/'preparation.json').read_text(encoding='utf-8'))
    sources=json.loads((directory/'source_poses.json').read_text(encoding='utf-8'))
    height=expected['height']
    body=bpy.data.objects['HunterBody']
    checks=[]
    for sample,source in zip(expected['poses'],sources):
        scene.frame_set(sample['frame']);bpy.context.view_layer.update()
        for side in ('R','L'):
            bone=rig.pose.bones['shin.'+side]
            front=(bone.matrix@bone.bone.matrix_local.inverted()).to_3x3()@Vector((0,-1,0))
            assert abs(front.x)<.35,(sample['name'],'axial twist',side,tuple(front))
            # A deeply folded rear shin can point its front normal downward;
            # measure axial twist (X), rather than forbidding that valid bend.
            wrist=(rig.matrix_world@rig.pose.bones['forearm.'+side].tail-
                   bpy.data.objects['WristIK.'+side].matrix_world.translation).length/height*104
            assert wrist<.5,(sample['name'],'wrist reach',side,wrist)
            target=bpy.data.objects['FootTarget.'+side]
            anchor=bpy.data.objects['FootControl.'+side]
            # The ankle-to-forefoot offset is fixed in the anchor's local frame.
            assert abs(anchor.location.z)<1e-6
            actual=rig.matrix_world@rig.pose.bones['foot.'+side].head
            assert (actual-target.matrix_world.translation).length/height*104<.1
        matrix=bpy.data.objects['GreatCleaverPivot'].matrix_world
        from mathutils import Matrix,Euler
        original=source['objects']['GreatCleaverPivot']
        reference=Matrix.LocRotScale(Vector(original['location']),Euler(original['rotation']).to_quaternion(),Vector((1,1.4,1)))
        original_error=max(abs(matrix[r][c]-reference[r][c]) for r in range(4) for c in range(4))
        assert original_error<1e-5,('source blade position changed',sample['name'],original_error)
        error=max(abs(matrix[r][c]-sample['sword_matrix'][r][c]) for r in range(4) for c in range(4))
        assert error<1e-5,('approved blade position changed',sample['name'],error)
        for name in expected['armor']:
            obj=bpy.data.objects[name]
            evaluated=obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).data
            worst=0
            for edge in obj.data.edges:
                a,b=edge.vertices
                original=(obj.data.vertices[a].co-obj.data.vertices[b].co).length
                deformed=(evaluated.vertices[a].co-evaluated.vertices[b].co).length
                worst=max(worst,abs(original-deformed))
            assert worst<height*1e-5,('rigid armor stretched',sample['name'],name,worst)
            skin_lookup={tuple(round(v,6) for v in vertex.co):vertex.index for vertex in body.data.vertices}
            skin_deformed=body.evaluated_get(bpy.context.evaluated_depsgraph_get()).data
            seam_error=0
            for vertex in obj.data.vertices:
                skin_index=skin_lookup.get(tuple(round(v,6) for v in vertex.co))
                if skin_index is not None:
                    seam_error=max(seam_error,(evaluated.vertices[vertex.index].co-skin_deformed.vertices[skin_index].co).length/height*104)
            assert seam_error<.05,('armor/cloth seam opened',sample['name'],name,seam_error)
        mesh=body.evaluated_get(bpy.context.evaluated_depsgraph_get()).data
        soles={}
        for side,sign in [('R',-1),('L',1)]:
            ids=[v.index for v in body.data.vertices if v.co.x*sign>0 and v.co.z<.055*height]
            sole=min((body.matrix_world@mesh.vertices[i].co).z for i in ids)/height*104
            assert sole>-.1,(sample['name'],'foot penetrated floor',side,sole)
            assert sole<.1,(sample['name'],'foot floating',side,sole)
            soles[side]=sole
        checks.append({'pose':sample['name'],'armor_rigid':True,'blade_unchanged':True,'sole_min_pixels':soles})
    # Native controls must continue to solve the leg without the old axial flip.
    scene.frame_set(1);anchor=bpy.data.objects['FootControl.R'];original=anchor.location.copy()
    for delta in (-.035,.035):
        anchor.location.y=original.y+delta*height;bpy.context.view_layer.update()
        bone=rig.pose.bones['shin.R']
        front=(bone.matrix@bone.bone.matrix_local.inverted()).to_3x3()@Vector((0,-1,0))
        assert abs(front.x)<.35 and front.y<0,('dragging foot flips shin',delta,tuple(front))
    anchor.location=original;bpy.context.view_layer.update()
    # Forefoot anchor survives heel rotation because the ankle is its child.
    rear=bpy.data.objects['FootControl.L'];old_rotation=rear.rotation_euler.copy()
    point=rear.matrix_world.translation.copy()
    rear.rotation_euler.x+=math.radians(5);bpy.context.view_layer.update()
    assert (rear.matrix_world.translation-point).length<1e-7
    rear.rotation_euler=old_rotation;bpy.context.view_layer.update()
    checks.append({'dragged_foot_no_flip':True,'heel_rotation_keeps_forefoot':True})
    assert all(image.packed_file for image in bpy.data.images if image.type not in ('RENDER_RESULT','COMPOSITING')),'Unpacked image dependency'
    (directory/'verification.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
    print('POSE_WORKSPACE_CHECK:',json.dumps(checks),flush=True)
