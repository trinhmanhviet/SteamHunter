"""Bake the user's three edited poses into the existing 74-cell GS contract.

Run Blender on prototypes/user_pose_animation/user_poses.blend with this script.
"""
import argparse,json,math,sys
from pathlib import Path
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'tools'))
from pose_motion import fit_grip_position
from rig_hunter_heavy import holdout_material
from rig_hunter_prototype import project
from render_overhead_demo import convex_hull,STAGES

HEIGHT=1.9702799916267395
CONTROLS=('GreatCleaverPivot','HipControl','TorsoControl','FootControl.R','FootControl.L')


def snapshot(scene,rig,frame):
    scene.frame_set(frame);bpy.context.view_layer.update()
    return {'controls':{n:{'location':list(bpy.data.objects[n].location),
                            'rotation':list(bpy.data.objects[n].rotation_euler)} for n in CONTROLS},
            'hip_rotation':list(rig.pose.bones['hips'].rotation_euler),
            'head_rotation':list(rig.pose.bones['head'].rotation_euler)}


def blend(a,b,t):
    result={'controls':{}}
    for name in CONTROLS:
        result['controls'][name]={key:[x+(y-x)*t for x,y in zip(a['controls'][name][key],b['controls'][name][key])]
                                  for key in ('location','rotation')}
    for key in ('hip_rotation','head_rotation'):
        result[key]=[x+(y-x)*t for x,y in zip(a[key],b[key])]
    return result


def authored_pose(frame,a,b,c,idle=None):
    if frame<=5:
        t=max(0,(frame-2)/3) if idle else (frame-1)/4
        return blend(idle or a,a,t),'raise' if frame>1 else 'ready'
    if frame<=8:return blend(a,b,{6:.10,7:.30,8:.52}[frame]),'release'
    if frame<=20:
        pose=blend(a,a,0)
        breath=math.sin((frame-9)/12*math.tau)
        pose['controls']['HipControl']['location'][2]+=.003*HEIGHT*breath
        pose['controls']['TorsoControl']['rotation'][0]+=math.radians(.35)*breath
        return pose,'hold'
    if frame==21:return blend(a,b,.8),'strike'
    if frame==22:return blend(b,b,0),'strike'
    if frame==23:return blend(c,c,0),'strike'
    if frame<=56:return blend(c,c,0),'settle'
    t=(frame-56)/18;t=t*t*(3-2*t)
    return blend(c,idle or a,t),'recover'


def apply_pose(rig,pose):
    for name,data in pose['controls'].items():
        obj=bpy.data.objects[name];obj.location=data['location'];obj.rotation_euler=data['rotation']
    # Keep the planted foot on the floor; leave the lifted rear leg authored by
    # the user intact. The correction is less than half a native pixel at hold.
    bpy.data.objects['FootControl.R'].location.z=0
    rig.pose.bones['hips'].rotation_euler=pose['hip_rotation']
    rig.pose.bones['head'].rotation_euler=pose['head_rotation']
    bpy.context.view_layer.update()


def fit_grips(rig,pivot):
    """Move only the sword pivot the minimum distance needed by both arms."""
    original=pivot.location.copy();discs=[]
    for side in ('R','L'):
        shoulder=rig.matrix_world@rig.pose.bones['upper_arm.'+side].head
        target=bpy.data.objects['WristIK.'+side].matrix_world.translation
        center=shoulder-(target-original)
        reach=(rig.data.bones['upper_arm.'+side].length+rig.data.bones['forearm.'+side].length)*.995
        depth=original.x-center.x
        if abs(depth)>=reach:raise ValueError('Grip is outside anatomical depth reach')
        discs.append((center.y,center.z,math.sqrt(reach*reach-depth*depth)))
    y,z=fit_grip_position((original.y,original.z),discs)
    pivot.location.y=y;pivot.location.z=z;bpy.context.view_layer.update()
    for side,sign in [('R',-1),('L',1)]:
        shoulder=rig.matrix_world@rig.pose.bones['upper_arm.'+side].head
        wrist=bpy.data.objects['WristIK.'+side].matrix_world.translation
        bpy.data.objects['ElbowPole.'+side].location=shoulder.lerp(wrist,.5)+Vector((sign*.20,0,-.12))*HEIGHT
    bpy.context.view_layer.update()
    gaps={s:(rig.matrix_world@rig.pose.bones['forearm.'+s].tail-
             bpy.data.objects['WristIK.'+s].matrix_world.translation).length/HEIGHT*104 for s in ('R','L')}
    if max(gaps.values())>.5:raise RuntimeError('Fitted grip still unreachable: '+str(gaps))
    return gaps,list((pivot.location-original)/HEIGHT*104)


def is_weapon(obj,pivot):
    parent=obj.parent
    while parent:
        if parent==pivot:return True
        parent=parent.parent
    return False


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output',type=Path);parser.add_argument('--keys',action='store_true')
    parser.add_argument('--idle-controls',type=Path);parser.add_argument('--transitions-only',action='store_true')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:]);args.output.mkdir(parents=True,exist_ok=True)
    scene=bpy.context.scene;rig=bpy.data.objects['HunyuanHeavyRig']
    pivot=bpy.data.objects['GreatCleaverPivot'];camera=scene.camera
    a,b,c=[snapshot(scene,rig,frame) for frame in (1,15,30)]
    idle=json.loads(args.idle_controls.read_text(encoding='utf-8'))['idle_controls'] if args.idle_controls else None
    # Preserve drivers for toe anchors, knee poles, head and body controls.
    for obj in scene.objects:
        if obj.animation_data:obj.animation_data.action=None
    weapons=[obj for obj in scene.objects if obj.type=='MESH' and is_weapon(obj,pivot)]
    bodies=[obj for obj in scene.objects if obj.type=='MESH' and obj not in weapons]
    metal=[obj for obj in weapons if obj.name in ('HeavyBlade','BladeBevel','BladeSpine')]
    materials={obj.name:[slot.material for slot in obj.material_slots] for obj in bodies}
    mask=holdout_material();scale=camera.data.ortho_scale/3
    frames=[1,5,6,7,8,9,20,21,22,23,35,56,57,62,67,74] if args.keys else list(range(1,75))
    if args.transitions_only:frames=list(range(1,6))+list(range(57,75))
    scene.render.resolution_percentage=100;scene.render.film_transparent=True
    scene.render.fps=30;scene.frame_start=1;scene.frame_end=74
    exported=[]
    for frame in frames:
        scene.frame_set(frame);pose,phase=authored_pose(frame,a,b,c,idle)
        apply_pose(rig,pose);gaps,adjustment=fit_grips(rig,pivot)
        for name in CONTROLS:
            obj=bpy.data.objects[name]
            obj.keyframe_insert('location',frame=frame);obj.keyframe_insert('rotation_euler',frame=frame)
        rig.pose.bones['hips'].keyframe_insert('rotation_euler',frame=frame)
        rig.pose.bones['head'].keyframe_insert('rotation_euler',frame=frame)
        for side in ('R','L'):bpy.data.objects['ElbowPole.'+side].keyframe_insert('location',frame=frame)
        for obj in bodies:
            obj.hide_render=False
            for slot,material in zip(obj.material_slots,materials[obj.name]):slot.material=material
        for obj in weapons:obj.hide_render=True
        camera.data.ortho_scale=scale;scene.render.resolution_x=scene.render.resolution_y=128
        path=args.output/'body'/f'overhead_{frame:03}.png';path.parent.mkdir(exist_ok=True)
        scene.render.filepath=str(path.resolve());bpy.ops.render.render(write_still=True)
        origin=project(scene,camera,pivot.matrix_world.translation,(128,128))
        blade=convex_hull([project(scene,camera,obj.matrix_world@v.co,(128,128)) for obj in metal for v in obj.data.vertices])
        angle=-pivot.rotation_euler.x
        local=[[math.cos(angle)*(x-origin[0])+math.sin(angle)*(y-origin[1]),
                -math.sin(angle)*(x-origin[0])+math.cos(angle)*(y-origin[1])] for x,y in blade]
        joints={name:{'head':project(scene,camera,rig.matrix_world@bone.head,(128,128)),
                      'tail':project(scene,camera,rig.matrix_world@bone.tail,(128,128))} for name,bone in rig.pose.bones.items()}
        grip=project(scene,camera,bpy.data.objects['Grip.R'].matrix_world.translation,(128,128))
        # Use the actual mesh's furthest metal point rather than a guessed sword length.
        tip=max(blade,key=lambda p:(p[0]-origin[0])**2+(p[1]-origin[1])**2)
        for obj in bodies:
            for slot in obj.material_slots:slot.material=mask
        for obj in weapons:obj.hide_render=False
        camera.data.ortho_scale=scale*3;scene.render.resolution_x=scene.render.resolution_y=384
        weapon_path=args.output/'weapon'/path.name;weapon_path.parent.mkdir(exist_ok=True)
        scene.render.filepath=str(weapon_path.resolve());bpy.ops.render.render(write_still=True)
        exported.append({'frame':frame,'phase':phase,'body':path.relative_to(args.output).as_posix(),
                         'weapon':weapon_path.relative_to(args.output).as_posix(),'grip':grip,'tip':tip,
                         'wrist_error_pixels':gaps,'grip_adjustment_pixels':adjustment,
                         'blade_polygon':blade,'weapon_origin':origin,'weapon_angle':angle,
                         'blade_local':local,'rig_joints':joints})
        print('POSE_BAKE',frame,'wrist',round(max(gaps.values()),5),'adjustment',adjustment,flush=True)
    for obj in bodies:
        for slot,material in zip(obj.material_slots,materials[obj.name]):slot.material=material
    for obj in scene.objects:
        if obj.animation_data and obj.animation_data.action:
            for curve in obj.animation_data.action.fcurves:
                for key in curve.keyframe_points:key.interpolation='LINEAR'
    camera.data.ortho_scale=scale;scene.render.resolution_x=scene.render.resolution_y=128
    scene.frame_set(1);bpy.context.view_layer.update()
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output/'overhead_rig.blend'))
    data={'fps':30,'stages':STAGES,'body_pivot':[64,116],'weapon_pivot':[192,244],
          'weapon_length_multiplier':1.4,'reference':'prototypes/user_pose_animation/user_poses.blend',
          'reference_controls':[{'game_frame':f,'source_frame':1 if f<=20 else (15 if f<=22 else 30),
                                 'blade_degrees':-p['weapon_angle']*180/math.pi,
                                 'trunk_lean_degrees':math.degrees(authored_pose(f,a,b,c,idle)[0]['controls']['TorsoControl']['rotation'][0])}
                                for f,p in zip(frames,exported)],
          'user_key_poses':[a,b,c],'frames':exported}
    (args.output/'render.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
    print('USER_POSE_BAKE_DONE',len(frames),flush=True)


if __name__=='__main__':main()
