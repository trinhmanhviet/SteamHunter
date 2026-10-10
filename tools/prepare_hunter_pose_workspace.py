"""Prepare the approved hunter as a small, direct-manipulation Blender workspace.

Uses the bundled Blender; does not modify game atlases or the source scenes.
"""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector, Quaternion

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from rig_hunter_heavy import rest_colours

OUT=ROOT/'prototypes/hunter_pose_workspace'
OUT.mkdir(parents=True,exist_ok=True)
HEIGHT=1.9702799916267395
POSES=[('Giữ charge',1),('Bổ xuống',15),('Kết thúc',30)]
BASE=ROOT/'prototypes/hunyuan_hunter/overhead_motion/overhead_rig.blend'


def snapshot(path,frame):
    bpy.ops.wm.open_mainfile(filepath=str(path))
    scene=bpy.context.scene;scene.frame_set(frame);bpy.context.view_layer.update()
    rig=bpy.data.objects['HunyuanHeavyRig']
    return {'objects':{name:{'location':list(bpy.data.objects[name].matrix_world.translation),
                             'rotation':list(bpy.data.objects[name].rotation_euler),
                             'quaternion':list(bpy.data.objects[name].matrix_world.to_quaternion())}
                       for name in ('GreatCleaverPivot','FootTarget.R','FootTarget.L','ElbowPole.R','ElbowPole.L')},
            'bones':{b.name:{'location':list(b.location),'rotation':list(b.rotation_euler)} for b in rig.pose.bones},
            'arm_pole_angles':{s:next(c.pole_angle for c in rig.pose.bones['forearm.'+s].constraints if c.type=='IK') for s in ('R','L')},
            'hip_position':list(rig.matrix_world@rig.pose.bones['hips'].head)}


def fix_leg_rest(rig):
    """A slight forward rest bend defines the hinge; roll keeps steel facing forward."""
    bpy.ops.object.select_all(action='DESELECT')
    rig.select_set(True);bpy.context.view_layer.objects.active=rig
    bpy.ops.object.mode_set(mode='EDIT')
    for side in ('R','L'):
        thigh=rig.data.edit_bones['thigh.'+side];shin=rig.data.edit_bones['shin.'+side]
        thigh.tail.y=shin.head.y=-.015*HEIGHT
        for bone in (thigh,shin):bone.align_roll(Vector((0,1,0)))
    bpy.ops.object.mode_set(mode='OBJECT')
    for side in ('R','L'):
        ik=next(c for c in rig.pose.bones['shin.'+side].constraints if c.type=='IK')
        ik.pole_angle=-math.pi/2
        for name in ('thigh.','shin.'):
            rig.pose.bones[name+side].ik_stretch=0


def bind_skin_legs(body):
    points=np.array([tuple(body.matrix_world@v.co) for v in body.data.vertices])/HEIGHT
    indices=np.flatnonzero(points[:,2]<.325)
    for group in body.vertex_groups:group.remove(indices.tolist())
    for i in indices:
        x,_,z=points[i];side='R' if x<0 else 'L'
        ankle=float(np.clip((z-.060)/.030,0,1));knee=float(np.clip((z-.260)/.030,0,1))
        for name,w in [('foot.',1-ankle),('shin.',ankle*(1-knee)),('thigh.',knee)]:
            if w:body.vertex_groups[name+side].add([int(i)],w,'REPLACE')
    return points


def mesh_subset(body,polygons,name):
    """Copy a surface subset, including its exact loop UVs and vertex weights."""
    source=body.data
    ids=sorted({i for p in polygons for i in p.vertices})
    remap={original:new for new,original in enumerate(ids)}
    mesh=bpy.data.meshes.new(name+'Mesh')
    mesh.from_pydata([source.vertices[i].co for i in ids],[],
                     [[remap[i] for i in p.vertices] for p in polygons])
    mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
    obj.matrix_world=body.matrix_world.copy()
    for slot in body.material_slots:mesh.materials.append(slot.material)
    uv=mesh.uv_layers.new(name=source.uv_layers.active.name)
    for p,new in zip(polygons,mesh.polygons):
        new.material_index=p.material_index;new.use_smooth=p.use_smooth
        for src_loop,dst_loop in zip(p.loop_indices,new.loop_indices):
            uv.data[dst_loop].uv=source.uv_layers.active.data[src_loop].uv
    return obj,ids


def separate_armor(body,rig,points):
    """Extract existing visible steel; preserve the original geometry and texture."""
    colours=rest_colours(body)
    groups={name:[] for name in ('Greave.R','Greave.L','KneePlate.R','KneePlate.L')}
    remaining=[]
    for polygon in body.data.polygons:
        indices=list(polygon.vertices)
        x,y,z=points[indices].mean(axis=0)
        c=colours[indices].mean(axis=0)
        # Steel is the light cyan material on the front of each leg. Dark navy
        # trousers and back straps stay with the deformable body surface.
        steel=c[2]>c[0]*1.3 and c[1]>.16 and c.max()>.28
        if .090<z<.325 and steel:
            side='R' if x<0 else 'L'
            groups[('KneePlate.' if z>=.25 else 'Greave.')+side].append(polygon)
        else:remaining.append(polygon)
    original_faces=len(body.data.polygons)
    # Every vertex shared with rigid steel must have the same binding on both
    # surfaces. Otherwise separating a painted plate exposes a moving crack.
    for name,polygons in groups.items():
        ids=sorted({i for p in polygons for i in p.vertices})
        for group in body.vertex_groups:group.remove(ids)
        body.vertex_groups['shin.'+name[-1]].add(ids,1,'REPLACE')
    replacement,ids=mesh_subset(body,remaining,'HunterSkinReplacement')
    for group in body.vertex_groups:replacement.vertex_groups.new(name=group.name)
    for new,old in enumerate(ids):
        for weight in body.data.vertices[old].groups:
            replacement.vertex_groups[weight.group].add([new],weight.weight,'REPLACE')
    modifier=replacement.modifiers.new('Skin','ARMATURE');modifier.object=rig
    modifier.use_deform_preserve_volume=True
    report={}
    for name,polygons in groups.items():
        if not polygons:raise RuntimeError('Armor segmentation empty: '+name)
        obj,_=mesh_subset(body,polygons,name)
        bone='shin.'+name[-1]
        group=obj.vertex_groups.new(name=bone)
        group.add(list(range(len(obj.data.vertices))),1,'REPLACE')
        modifier=obj.modifiers.new('Rigid steel attachment','ARMATURE');modifier.object=rig
        modifier.use_deform_preserve_volume=False
        obj['rigid_armor']=True;obj['attachment_bone']=bone
        obj.hide_select=True
        report[name]={'faces':len(polygons),'vertices':len(obj.data.vertices),'bone':bone}
    bpy.data.objects.remove(body,do_unlink=True)
    replacement.name='HunterBody';replacement.hide_select=True
    assert len(replacement.data.polygons)+sum(v['faces'] for v in report.values())==original_faces
    return replacement,report


def control(name,label,display,size,colour,position):
    obj=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(obj)
    obj.empty_display_type=display;obj.empty_display_size=size*HEIGHT
    obj.location=position;obj.color=colour;obj.show_in_front=True
    obj['label']=label
    return obj


def colored_handle(obj,size,colour):
    """Viewport-only colored rings, with the actual control at their center."""
    curve=bpy.data.curves.new(obj.name+'Handle','CURVE');curve.dimensions='3D'
    curve.bevel_depth=.002*HEIGHT;curve.bevel_resolution=1
    spline=curve.splines.new('POLY');spline.points.add(31)
    for i,point in enumerate(spline.points):
        angle=i*math.tau/32
        point.co=(-.45*HEIGHT,math.cos(angle)*size*HEIGHT,math.sin(angle)*size*HEIGHT,1)
    spline.use_cyclic_u=True
    glyph=bpy.data.objects.new(obj.name+'Handle',curve);bpy.context.collection.objects.link(glyph)
    glyph.parent=obj;glyph.hide_render=True;glyph.hide_select=True
    mat=bpy.data.materials.new(obj.name+'HandleColor');mat.use_nodes=True
    mat.node_tree.nodes.clear()
    emission=mat.node_tree.nodes.new('ShaderNodeEmission');emission.inputs['Color'].default_value=colour
    output=mat.node_tree.nodes.new('ShaderNodeOutputMaterial')
    mat.node_tree.links.new(emission.outputs['Emission'],output.inputs['Surface'])
    curve.materials.append(mat)


def transform_driver(obj,index,expression,variables):
    driver=obj.driver_add('location',index).driver;driver.expression=expression
    for name,target,axis in variables:
        var=driver.variables.new();var.name=name;var.type='TRANSFORMS'
        var.targets[0].id=target;var.targets[0].transform_type='LOC_'+axis
        var.targets[0].transform_space='WORLD_SPACE'


def configure_controls(body,rig,snapshots,rest_points):
    hip=control('HipControl','Hông','SPHERE',.065,(1,.5,.15,1),snapshots[0]['hip_position'])
    hip.lock_location=(True,False,False);hip.lock_rotation=(True,True,True);hip.lock_scale=(True,True,True)
    rig.pose.bones['hips'].location=(0,0,0)
    c=rig.pose.bones['hips'].constraints.new('COPY_LOCATION');c.target=hip
    c.owner_space=c.target_space='WORLD'
    torso=control('TorsoControl','Thân người','CUBE',.035,(1,.3,.3,1),(0,0,.25*HEIGHT))
    torso.parent=hip;torso.lock_location=(True,True,True);torso.lock_rotation=(False,True,True)
    torso.lock_scale=(True,True,True)
    rig.pose.bones['spine'].rotation_euler=(0,0,0)
    c=rig.pose.bones['spine'].constraints.new('COPY_ROTATION');c.target=torso
    c.owner_space=c.target_space='LOCAL'
    rig.pose.bones['head'].driver_remove('rotation_euler',0)
    d=rig.pose.bones['head'].driver_add('rotation_euler',0).driver
    d.expression='-.42*lean'
    var=d.variables.new();var.name='lean';var.type='SINGLE_PROP'
    var.targets[0].id=torso;var.targets[0].data_path='rotation_euler[0]'
    sword=bpy.data.objects['GreatCleaverPivot']
    sword.empty_display_type='ARROWS';sword.empty_display_size=.13*HEIGHT
    sword.color=(1,.85,.15,1);sword.show_in_front=True;sword['label']='Kiếm / hai tay'
    sword.lock_location=(True,False,False);sword.lock_rotation=(False,True,True);sword.lock_scale=(True,True,True)
    anchors={};toe_local={}
    # Read sole geometry from the source's preserved rest coordinates; feet have
    # not changed rest joints. Each controller pivots on a real forefoot vertex.
    for side,sign in [('R',-1),('L',1)]:
        bone=rig.data.bones['foot.'+side]
        neutral=bone.matrix_local.to_quaternion()
        candidates=np.flatnonzero((rest_points[:,0]*sign>0)&(rest_points[:,2]<.055))
        local=[bone.matrix_local.inverted()@(Vector(rest_points[int(i)])*HEIGHT) for i in candidates]
        pitch=24 if side=='L' else 0
        rot=Quaternion((1,0,0),math.radians(pitch))@neutral
        toe_local[side]=min(local,key=lambda v:(rot@v).z)
        target=bpy.data.objects['FootTarget.'+side]
        anchor=control('FootControl.'+side,'Chân trước' if side=='R' else 'Chân sau',
                       'CIRCLE',.075,(.1,.85,1,1),target.location+rot@toe_local[side])
        anchor.rotation_mode='XYZ';anchor.rotation_euler=(math.radians(pitch),0,0)
        anchor.lock_location=(True,False,False);anchor.lock_rotation=(False,True,True);anchor.lock_scale=(True,True,True)
        target.parent=anchor;target.matrix_parent_inverse.identity()
        target.location=-(neutral@toe_local[side])
        target.rotation_mode='QUATERNION';target.rotation_quaternion=neutral
        target.hide_select=True;target.empty_display_size=.001
        anchors[side]=anchor
        pole=bpy.data.objects['KneePole.'+side]
        for index,axis in enumerate(('X','Y','Z')):
            offset=sign*.075*HEIGHT/2 if index==0 else (-HEIGHT if index==1 else 0)
            transform_driver(pole,index,f'(hip+foot)*.5+({offset})',[("hip",hip,axis),("foot",target,axis)])
        pole.hide_select=True;pole.empty_display_size=.001
    keys=[]
    for (label,frame),snap in zip(POSES,snapshots):
        for name,data in snap['bones'].items():
            bone=rig.pose.bones[name]
            if name not in ('hips','spine'):
                bone.location=data['location'];bone.rotation_euler=data['rotation']
                if name=='head':bone.rotation_euler.x=-.42*snap['bones']['spine']['rotation'][0]
                bone.keyframe_insert('location',frame=frame);bone.keyframe_insert('rotation_euler',frame=frame)
        rig.pose.bones['hips'].rotation_euler=snap['bones']['hips']['rotation']
        rig.pose.bones['hips'].keyframe_insert('rotation_euler',frame=frame)
        hip.location=snap['hip_position'];hip.keyframe_insert('location',frame=frame)
        torso.rotation_euler=snap['bones']['spine']['rotation'];torso.keyframe_insert('rotation_euler',frame=frame)
        sword.location=snap['objects']['GreatCleaverPivot']['location']
        sword.rotation_euler=snap['objects']['GreatCleaverPivot']['rotation']
        sword.keyframe_insert('location',frame=frame);sword.keyframe_insert('rotation_euler',frame=frame)
        for side,anchor in anchors.items():
            data=snap['objects']['FootTarget.'+side]
            neutral=rig.data.bones['foot.'+side].matrix_local.to_quaternion()
            rotation=Quaternion(data['quaternion'])
            pitch=(rotation@neutral.inverted()).to_euler('XYZ').x
            # The middle cut receives the same stable toe contact as the two
            # reviewed endpoints, with a rear heel halfway through its rise.
            if frame==15:
                pitch=math.radians(30 if side=='L' else 0)
                rotation=Quaternion((1,0,0),pitch)@neutral
                ankle=Vector(((-.12 if side=='R' else .12),(-.18 if side=='R' else .23),.075))*HEIGHT
                point=ankle+neutral@toe_local[side]
            else:point=Vector(data['location'])+rotation@toe_local[side]
            point.z=0
            anchor.location=point;anchor.rotation_euler=(pitch,0,0)
            anchor.keyframe_insert('location',frame=frame);anchor.keyframe_insert('rotation_euler',frame=frame)
        scene=bpy.context.scene;scene.timeline_markers.new(label,frame=frame)
        scene.frame_set(frame);bpy.context.view_layer.update()
        keys.append({'name':label,'frame':frame,'sword_matrix':[list(row) for row in sword.matrix_world]})
    return hip,torso,sword,anchors,keys


def save_workspace(rig,sword,armor_report,keys):
    scene=bpy.context.scene
    scene.frame_start=1;scene.frame_end=30;scene.frame_set(1)
    scene.tool_settings.use_keyframe_insert_auto=True
    scene.render.resolution_x=scene.render.resolution_y=384
    scene['pose_workspace_version']=1;scene['pose_frames']='1,15,30'
    for obj in scene.objects:
        if obj not in (sword,bpy.data.objects['HipControl'],bpy.data.objects['TorsoControl'],
                       bpy.data.objects['FootControl.R'],bpy.data.objects['FootControl.L']):
            obj.hide_select=True
            if obj.type=='EMPTY':obj.empty_display_size=.001
    rig.hide_set(True)
    for obj,size in [(sword,.035),(bpy.data.objects['HipControl'],.045),
                     (bpy.data.objects['TorsoControl'],.035),
                     (bpy.data.objects['FootControl.R'],.04),(bpy.data.objects['FootControl.L'],.04)]:
        colored_handle(obj,size,obj.color)
    floor=bpy.data.curves.new('GroundGuide','CURVE');floor.dimensions='3D'
    floor.bevel_depth=.0015*HEIGHT
    line=floor.splines.new('POLY');line.points.add(1)
    line.points[0].co=(-.8*HEIGHT,-2*HEIGHT,0,1);line.points[1].co=(-.8*HEIGHT,2*HEIGHT,0,1)
    ground=bpy.data.objects.new('GroundGuide',floor);bpy.context.collection.objects.link(ground)
    ground.hide_render=True;ground.hide_select=True
    floor.materials.append(bpy.data.materials['FootControl.RHandleColor'])
    # Show the whole sword in the initial camera view, preserving pixel scale
    # during export by rendering the full 384px canvas.
    scene.camera.data.ortho_scale*=3
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type=='VIEW_3D':
                space=area.spaces.active
                space.region_3d.view_perspective='CAMERA'
                space.region_3d.view_camera_zoom=4
                space.shading.type='MATERIAL'
                space.shading.use_scene_lights=False;space.shading.use_scene_world=False
                space.overlay.show_floor=False;space.overlay.show_axis_x=False;space.overlay.show_axis_y=False
                space.overlay.show_relationship_lines=False
                space.overlay.show_cursor=False
                space.show_region_ui=True
                space.clip_start=.001
    for name in ('HUONG_DAN','POSE_PRESETS'):
        if name in bpy.data.texts:bpy.data.texts.remove(bpy.data.texts[name])
    bpy.data.texts.new('HUONG_DAN').write((OUT/'README.md').read_text(encoding='utf-8'))
    bpy.data.workspaces['Layout'].name='Pose Hunter'
    preview=bpy.data.images.load(str(OUT/'hold_384.png'),check_existing=True)
    preview.name='SpritePreview';preview.use_fake_user=True;preview.pack()
    defaults={}
    for key in keys:
        scene.frame_set(key['frame']);bpy.context.view_layer.update()
        defaults[str(key['frame'])]={name:{'location':list(bpy.data.objects[name].location),
                                              'rotation':list(bpy.data.objects[name].rotation_euler)}
                                    for name in ('HipControl','TorsoControl','GreatCleaverPivot','FootControl.R','FootControl.L')}
    bpy.data.texts.new('POSE_PRESETS').write(json.dumps(defaults))
    scene.frame_set(1)
    bpy.ops.object.select_all(action='DESELECT');sword.select_set(True);bpy.context.view_layer.objects.active=sword
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'hunter_pose.blend'))
    (OUT/'preparation.json').write_text(json.dumps({'height':HEIGHT,'armor':armor_report,'poses':keys,
        'source':'Approved Hunyuan model and sword; native hinge rig correction',
        'camera_scale':scene.camera.data.ortho_scale},indent=2),encoding='utf-8')
    print('POSE_WORKSPACE_SAVED',str(OUT/'hunter_pose.blend'),json.dumps(armor_report),flush=True)


if __name__=='__main__':
    snapshots=json.loads((OUT/'source_poses.json').read_text(encoding='utf-8'))
    bpy.ops.wm.open_mainfile(filepath=str(BASE))
    scene=bpy.context.scene;scene.frame_set(1);bpy.context.view_layer.update()
    for obj in scene.objects:obj.animation_data_clear()
    scene.timeline_markers.clear()
    body=bpy.data.objects['HunterBody'];rig=bpy.data.objects['HunyuanHeavyRig']
    for side in ('R','L'):
        bpy.data.objects['ElbowPole.'+side].location=snapshots[0]['objects']['ElbowPole.'+side]['location']
        next(c for c in rig.pose.bones['forearm.'+side].constraints if c.type=='IK').pole_angle=snapshots[0]['arm_pole_angles'][side]
    rest=bind_skin_legs(body)
    fix_leg_rest(rig)
    body,armor_report=separate_armor(body,rig,rest)
    hip,torso,sword,anchors,keys=configure_controls(body,rig,snapshots,rest)
    save_workspace(rig,sword,armor_report,keys)
