"""Render a back-mounted sword run cycle and forward-held idle on the current rig."""
import argparse,json,math,sys
from pathlib import Path
import bpy
from mathutils import Vector,Matrix,Euler,Quaternion

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'tools'))
from run_cycle import foot_pose,CYCLE_SECONDS
from render_user_pose_animation import fit_grips,is_weapon
from render_overhead_demo import convex_hull
from rig_hunter_heavy import holdout_material,choose_pole
from rig_hunter_prototype import project

HEIGHT=1.9702799916267395


def prepare(scene,rig):
    scene.frame_set(1);bpy.context.view_layer.update()
    for obj in scene.objects:
        if obj.animation_data:obj.animation_data.action=None
    wrists={s:bpy.data.objects['WristIK.'+s].matrix_basis.copy() for s in ('R','L')}
    for side in ('R','L'):
        hand=rig.pose.bones['hand.'+side]
        constraint=hand.constraints.new('COPY_ROTATION');constraint.name='Running hand orientation'
        constraint.target=bpy.data.objects['WristIK.'+side]
        constraint.owner_space=constraint.target_space='WORLD';constraint.influence=0
    return wrists


def feet_pose(side,ankle_y,clearance,heel):
    anchor=bpy.data.objects['FootControl.'+side]
    anchor.rotation_euler=(math.radians(heel),0,0)
    offset=Quaternion((1,0,0),math.radians(heel))@bpy.data.objects['FootTarget.'+side].location
    anchor.location.y=ankle_y*HEIGHT-offset.y;anchor.location.z=clearance*HEIGHT


def torso_pose(rig,hip_z,lean):
    bpy.data.objects['HipControl'].location=Vector((0,-.025,hip_z))*HEIGHT
    bpy.data.objects['TorsoControl'].rotation_euler=(math.radians(lean),0,0)
    rig.pose.bones['hips'].rotation_euler=(0,0,0)
    rig.pose.bones['head'].rotation_euler.y=0
    bpy.context.view_layer.update()


def hold_hands(rig,pivot,wrists):
    for side in ('R','L'):
        target=bpy.data.objects['WristIK.'+side]
        target.parent=pivot;target.matrix_parent_inverse.identity();target.matrix_basis=wrists[side]
        hand=rig.pose.bones['hand.'+side]
        copies=[c for c in hand.constraints if c.type=='COPY_ROTATION']
        copies[0].influence=1;copies[1].influence=0
    bpy.context.view_layer.update()


def run_hands(rig,pivot,phase):
    for side,sign,p in [('R',-1,phase),('L',1,phase+.5)]:
        target=bpy.data.objects['WristIK.'+side]
        target.parent=None;target.rotation_mode='QUATERNION'
        shoulder=rig.matrix_world@rig.pose.bones['upper_arm.'+side].head
        swing=math.cos(math.tau*p)
        target.location=shoulder+Vector((sign*.01,.19*swing,-.12+.025*swing))*HEIGHT
        pole=bpy.data.objects['ElbowPole.'+side]
        pole.location=shoulder.lerp(target.location,.5)+Vector((sign*.20,.08,-.13))*HEIGHT
        hand=rig.pose.bones['hand.'+side]
        copies=[c for c in hand.constraints if c.type=='COPY_ROTATION']
        copies[0].influence=0;copies[1].influence=1
        bpy.context.view_layer.update()
        forearm=rig.pose.bones['forearm.'+side]
        deformation=forearm.matrix.to_quaternion()@forearm.bone.matrix_local.to_quaternion().inverted()
        target.rotation_quaternion=deformation@hand.bone.matrix_local.to_quaternion()
    bpy.context.view_layer.update()


def mount_sword(rig,pivot):
    # Attach the existing rigid blade to the upper back, hilt above the shoulder
    # and metal descending behind the body. It follows the spine's movement.
    spine=rig.pose.bones['spine']
    deformation=rig.matrix_world@spine.matrix@spine.bone.matrix_local.inverted()
    direction=Vector((.68,.42,-.60)).normalized()
    normal=(Vector((1,0,0))-direction*direction.x).normalized()
    edge=normal.cross(direction)
    rotation=Matrix((normal,direction,edge)).transposed().to_quaternion()
    rest=Matrix.LocRotScale(Vector((-.15,.14,1.035))*HEIGHT,rotation,Vector((1,1.4,1)))
    pivot.matrix_world=deformation@rest
    bpy.context.view_layer.update()


def idle_pose(rig,pivot,wrists,draw=1):
    torso_pose(rig,.37,5)
    feet_pose('R',-.24,0,0);feet_pose('L',.26,0,0)
    hold_hands(rig,pivot,wrists)
    t=draw
    pivot.location=Vector((-.01,.10+(-.24-.10)*t,.90+(.48-.90)*t))*HEIGHT
    pivot.rotation_mode='XYZ';pivot.rotation_euler=(math.radians(220+(48-220)*t),0,math.pi)
    pivot.scale=Vector((1,1.4,1))
    bpy.context.view_layer.update()
    result=fit_grips(rig,pivot)[0]
    for side in ('R','L'):
        target=bpy.data.objects['WristIK.'+side];world=target.matrix_world.copy()
        target.parent=None;target.matrix_world=world
    bpy.context.view_layer.update()
    return result


def run_pose(rig,pivot,phase):
    torso_pose(rig,.390+.015*math.cos(math.tau*2*phase),12)
    for side,p in [('R',phase),('L',phase+.5)]:feet_pose(side,*foot_pose(p))
    bpy.context.view_layer.update()
    run_hands(rig,pivot,phase);mount_sword(rig,pivot)
    return {s:(rig.matrix_world@rig.pose.bones['forearm.'+s].tail-bpy.data.objects['WristIK.'+s].matrix_world.translation).length/HEIGHT*104 for s in ('R','L')}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output',type=Path);parser.add_argument('--keys',action='store_true')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:]);args.output.mkdir(parents=True,exist_ok=True)
    scene=bpy.context.scene;rig=bpy.data.objects['HunyuanHeavyRig']
    pivot=bpy.data.objects['GreatCleaverPivot'];camera=scene.camera
    wrists=prepare(scene,rig)
    idle_angles={side:next(c.pole_angle for c in rig.pose.bones['forearm.'+side].constraints if c.type=='IK') for side in ('R','L')}
    weapons=[obj for obj in scene.objects if obj.type=='MESH' and is_weapon(obj,pivot)]
    bodies=[obj for obj in scene.objects if obj.type=='MESH' and obj not in weapons]
    metal=[obj for obj in weapons if obj.name in ('HeavyBlade','BladeBevel','BladeSpine')]
    mats={obj.name:[slot.material for slot in obj.material_slots] for obj in bodies}
    mask=holdout_material();scale=camera.data.ortho_scale
    # Calibrate arm poles against a bent running elbow once, then keep their
    # native plane consistent for the whole cycle.
    run_pose(rig,pivot,0)
    for side,sign in [('R',-1),('L',1)]:
        shoulder=rig.pose.bones['upper_arm.'+side].head
        ik=next(c for c in rig.pose.bones['forearm.'+side].constraints if c.type=='IK')
        choose_pole(scene,rig,ik,'forearm.'+side,shoulder+Vector((sign*.03,.10,-.17))*HEIGHT,HEIGHT)
    run_angles={side:next(c.pole_angle for c in rig.pose.bones['forearm.'+side].constraints if c.type=='IK') for side in ('R','L')}
    frames=[('idle',0,1.0)]+[('run',i,i/12) for i in range(12)]+[('draw',i,(i+1)/4) for i in range(4)]
    if args.keys:frames=[frames[i] for i in (0,1,4,7,10,13,16)]
    exported=[];idle_controls={}
    for index,(phase,n,t) in enumerate(frames):
        scene.frame_set(index+1);bpy.context.view_layer.update()
        for side in ('R','L'):
            next(c for c in rig.pose.bones['forearm.'+side].constraints if c.type=='IK').pole_angle=(run_angles if phase=='run' else idle_angles)[side]
        gap=run_pose(rig,pivot,t) if phase=='run' else idle_pose(rig,pivot,wrists,t)
        if max(gap.values())>.5:raise RuntimeError(f'{phase}/{n}: arm target unreachable: {gap}')
        bpy.context.view_layer.update()
        # Rendering reevaluates scene animation. Record this pose first so the
        # render job cannot restore the previous cell's animated values.
        for name in ('GreatCleaverPivot','HipControl','TorsoControl','FootControl.R','FootControl.L','WristIK.R','WristIK.L','ElbowPole.R','ElbowPole.L'):
            obj=bpy.data.objects[name];obj.keyframe_insert('location',frame=index+1)
            obj.keyframe_insert('rotation_euler' if obj.rotation_mode!='QUATERNION' else 'rotation_quaternion',frame=index+1)
        for side in ('R','L'):
            for constraint in rig.pose.bones['hand.'+side].constraints:
                if constraint.type=='COPY_ROTATION':constraint.keyframe_insert('influence',frame=index+1)
        for obj in bodies:
            obj.hide_render=False
            for slot,material in zip(obj.material_slots,mats[obj.name]):slot.material=material
        for obj in weapons:obj.hide_render=True
        camera.data.ortho_scale=scale;scene.render.resolution_x=scene.render.resolution_y=128
        path=args.output/'body'/f'{phase}_{n:02}.png';path.parent.mkdir(exist_ok=True)
        scene.render.filepath=str(path.resolve());bpy.ops.render.render(write_still=True)
        origin=project(scene,camera,pivot.matrix_world.translation,(128,128))
        polygon=convex_hull([project(scene,camera,obj.matrix_world@v.co,(128,128)) for obj in metal for v in obj.data.vertices])
        joints={name:{'head':project(scene,camera,rig.matrix_world@bone.head,(128,128)),
                      'tail':project(scene,camera,rig.matrix_world@bone.tail,(128,128))} for name,bone in rig.pose.bones.items()}
        if phase=='idle':
            idle_controls={'controls':{name:{'location':list(bpy.data.objects[name].location),'rotation':list(bpy.data.objects[name].rotation_euler)}
                                       for name in ('GreatCleaverPivot','HipControl','TorsoControl','FootControl.R','FootControl.L')},
                           'hip_rotation':list(rig.pose.bones['hips'].rotation_euler),'head_rotation':list(rig.pose.bones['head'].rotation_euler)}
        for obj in bodies:
            for slot in obj.material_slots:slot.material=mask
        for obj in weapons:obj.hide_render=False
        camera.data.ortho_scale=scale*3;scene.render.resolution_x=scene.render.resolution_y=384
        wp=args.output/'weapon'/path.name;wp.parent.mkdir(exist_ok=True)
        scene.render.filepath=str(wp.resolve());bpy.ops.render.render(write_still=True)
        exported.append({'phase':phase,'cell':n,'body':path.relative_to(args.output).as_posix(),
                         'weapon':wp.relative_to(args.output).as_posix(),'weapon_origin':origin,
                         'weapon_angle':-pivot.rotation_euler.x,'blade_polygon':polygon,
                         'wrist_error_pixels':gap,'rig_joints':joints})
        print('LOCOMOTION_RENDER',phase,n,'wrist',max(gap.values()),flush=True)
    for obj in bodies:
        for slot,material in zip(obj.material_slots,mats[obj.name]):slot.material=material
    camera.data.ortho_scale=scale;scene.render.resolution_x=scene.render.resolution_y=128
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output/'locomotion_rig.blend'))
    (args.output/'render.json').write_text(json.dumps({'cycle_seconds':CYCLE_SECONDS,'draw_seconds':.16,'idle_controls':idle_controls,'frames':exported},indent=2),encoding='utf-8')


if __name__=='__main__':main()
