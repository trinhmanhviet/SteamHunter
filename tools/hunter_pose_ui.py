"""Session-local controls for the prepared Blender scene; no plugin installation."""
import json
import sys
from pathlib import Path
import bpy

CONTROLS={'SWORD':'GreatCleaverPivot','HIP':'HipControl','TORSO':'TorsoControl',
          'FRONT':'FootControl.R','REAR':'FootControl.L'}


class HUNTERPOSE_OT_frame(bpy.types.Operator):
    bl_idname='hunterpose.frame';bl_label='Chọn tư thế';bl_options={'UNDO'}
    frame:bpy.props.IntProperty(default=1)
    def execute(self,context):
        context.scene.frame_set(self.frame)
        return {'FINISHED'}


class HUNTERPOSE_OT_select(bpy.types.Operator):
    bl_idname='hunterpose.select';bl_label='Chọn điểm điều khiển'
    control:bpy.props.StringProperty(default='SWORD')
    def execute(self,context):
        obj=bpy.data.objects.get(CONTROLS[self.control])
        if not obj:return {'CANCELLED'}
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True);context.view_layer.objects.active=obj
        return {'FINISHED'}


class HUNTERPOSE_OT_reset(bpy.types.Operator):
    bl_idname='hunterpose.reset';bl_label='Khôi phục tư thế';bl_options={'UNDO'}
    def execute(self,context):
        frame=context.scene.frame_current
        presets=json.loads(bpy.data.texts['POSE_PRESETS'].as_string())
        if str(frame) not in presets:
            self.report({'WARNING'},'Chọn frame mẫu 1, 15 hoặc 30 trước khi khôi phục.')
            return {'CANCELLED'}
        for name,data in presets[str(frame)].items():
            obj=bpy.data.objects[name]
            obj.location=data['location'];obj.rotation_euler=data['rotation']
            obj.keyframe_insert('location',frame=frame);obj.keyframe_insert('rotation_euler',frame=frame)
        context.view_layer.update()
        return {'FINISHED'}


def export_sprite(context,path=None):
    scene=context.scene
    output=Path(path) if path else Path(bpy.data.filepath).parent/'exports'/f'pose_{scene.frame_current:03}.png'
    output.parent.mkdir(parents=True,exist_ok=True)
    old=(scene.render.resolution_x,scene.render.resolution_y,scene.render.resolution_percentage,
         scene.render.filepath,scene.render.film_transparent)
    try:
        scene.render.resolution_x=scene.render.resolution_y=384
        scene.render.resolution_percentage=100;scene.render.film_transparent=True
        scene.render.filepath=str(output)
        bpy.ops.render.render(write_still=True)
        preview=bpy.data.images.get('SpritePreview')
        if preview:
            if preview.packed_file:preview.unpack(method='REMOVE')
            preview.filepath=str(output);preview.reload();preview.pack()
    finally:
        scene.render.resolution_x,scene.render.resolution_y,scene.render.resolution_percentage,scene.render.filepath,scene.render.film_transparent=old
    return output


class HUNTERPOSE_OT_export(bpy.types.Operator):
    bl_idname='hunterpose.export';bl_label='Xuất sprite'
    def execute(self,context):
        output=export_sprite(context)
        self.report({'INFO'},'Đã xuất: '+str(output))
        return {'FINISHED'}


class HUNTERPOSE_PT_tools(bpy.types.Panel):
    bl_label='Pose Hunter';bl_idname='HUNTERPOSE_PT_tools'
    bl_space_type='VIEW_3D';bl_region_type='UI';bl_category='Item';bl_order=-10
    @classmethod
    def poll(cls,context):return 'HipControl' in bpy.data.objects
    def draw(self,context):
        layout=self.layout
        col=layout.column(align=True)
        for label,frame in [('Giữ charge',1),('Bổ xuống',15),('Kết thúc',30)]:
            op=col.operator('hunterpose.frame',text=label);op.frame=frame
        layout.separator()
        for label,key in [('Kiếm / hai tay','SWORD'),('Hông','HIP'),('Thân người','TORSO'),
                          ('Chân trước','FRONT'),('Chân sau','REAR')]:
            op=layout.operator('hunterpose.select',text=label);op.control=key
        layout.label(text='G: kéo  ·  R: xoay')
        layout.label(text='Esc: hủy  ·  Ctrl+Z: hoàn tác')
        layout.prop(context.scene.tool_settings,'use_keyframe_insert_auto',text='Tự lưu keyframe')
        layout.separator()
        layout.operator('hunterpose.reset')
        layout.operator('hunterpose.export',icon='RENDER_STILL')
        rig=bpy.data.objects['HunyuanHeavyRig']
        height=1.9702799916267395
        gap=max((rig.matrix_world@rig.pose.bones['forearm.'+s].tail-
                 bpy.data.objects['WristIK.'+s].matrix_world.translation).length/height*104 for s in ('R','L'))
        if gap>.5:layout.label(text='Kiếm xa quá: tay không với tới!',icon='ERROR')
        else:layout.label(text='Hai tay đang bám cán kiếm',icon='CHECKMARK')


CLASSES=(HUNTERPOSE_OT_frame,HUNTERPOSE_OT_select,HUNTERPOSE_OT_reset,HUNTERPOSE_OT_export,HUNTERPOSE_PT_tools)


def register():
    for cls in CLASSES:
        old=getattr(bpy.types,cls.__name__,None)
        if old:bpy.utils.unregister_class(old)
        bpy.utils.register_class(cls)
    for area in bpy.context.screen.areas if bpy.context.screen else []:
        if area.type=='OUTLINER':
            area.type='IMAGE_EDITOR'
            area.spaces.active.image=bpy.data.images.get('SpritePreview')
        elif area.type=='PROPERTIES':
            area.type='TEXT_EDITOR';space=area.spaces.active
            text=bpy.data.texts.get('THAO_TAC_NHANH') or bpy.data.texts.new('THAO_TAC_NHANH')
            text.clear();text.write('CHỈNH POSE HUNTER\n\n1. Chọn tư thế trong bảng Pose Hunter.\n\n2. Chọn Kiếm, Hông, Thân hoặc Chân.\n\n3. G để kéo, R để xoay.\n   Bấm trái: xác nhận. Esc: hủy.\n\n4. Chân xoay quanh mũi chân.\n   Kéo Hông để chùng gối.\n\n5. Ctrl+Z: hoàn tác.\n   Ctrl+S: lưu file.\n\n6. Xuất sprite để xem ảnh pixel ở ô phía trên.\n\nHai tay đi theo kiếm. Kéo kiếm quá xa sẽ có cảnh báo.\n\nGiữ charge: frame 1.\nBổ xuống: frame 15.\nKết thúc: frame 30.\n\nĐây là bản thử tư thế, chưa thay asset game.')
            space.text=text;space.show_line_numbers=False
            space.show_word_wrap=True;space.font_size=15
            region=next(r for r in area.regions if r.type=='WINDOW')
            with bpy.context.temp_override(area=area,region=region):bpy.ops.text.jump(line=1)
        elif area.type=='DOPESHEET_EDITOR':
            region=next(r for r in area.regions if r.type=='WINDOW')
            with bpy.context.temp_override(area=area,region=region):bpy.ops.action.view_all()
        if area.type=='VIEW_3D':
            area.spaces.active.show_region_ui=True
            with bpy.context.temp_override(area=area):
                bpy.ops.wm.tool_set_by_id(name='builtin.move')


def smoke_test():
    """Run actual panel operators and capture the Blender window for visual QA."""
    directory=Path(bpy.data.filepath).parent
    reports=[]
    area=next(a for a in bpy.context.screen.areas if a.type=='VIEW_3D')
    region=next(r for r in area.regions if r.type=='WINDOW')
    with bpy.context.temp_override(area=area,region=region):
        for frame in (1,15,30):
            assert bpy.ops.hunterpose.frame(frame=frame)=={'FINISHED'}
            for name in CONTROLS:
                assert bpy.ops.hunterpose.select(control=name)=={'FINISHED'}
                assert bpy.context.view_layer.objects.active.name==CONTROLS[name]
            assert bpy.ops.hunterpose.reset()=={'FINISHED'}
            reports.append({'frame':frame,'preset_selection':True,'control_selection':True,'reset':True})
        # Exercise the same native transforms as G and R, including automatic
        # key insertion and pose persistence when changing frames.
        bpy.ops.hunterpose.frame(frame=1);bpy.ops.hunterpose.select(control='FRONT')
        front=bpy.data.objects['FootControl.R'];original=front.location.copy()
        bpy.ops.transform.translate(value=(0,-.015*1.9702799916267395,0),orient_type='GLOBAL')
        changed=front.location.copy()
        assert (changed-original).length>.01
        assert abs(changed.x-original.x)<1e-6
        bpy.ops.hunterpose.frame(frame=15);bpy.ops.hunterpose.frame(frame=1)
        assert (front.location-changed).length<1e-5,'Auto key did not preserve dragged foot'
        bpy.ops.hunterpose.select(control='REAR')
        rear=bpy.data.objects['FootControl.L'];position=rear.matrix_world.translation.copy()
        rotation=rear.rotation_euler.x
        bpy.ops.transform.rotate(value=.07,orient_axis='X',orient_type='GLOBAL')
        assert abs(rear.rotation_euler.x-rotation)>.05
        assert (rear.matrix_world.translation-position).length<1e-5,'Heel rotation moved the forefoot'
        bpy.ops.hunterpose.reset()
        reports.append({'native_drag':True,'auto_key_persistence':True,'native_heel_rotation':True})
        bpy.ops.hunterpose.frame(frame=15);bpy.ops.hunterpose.export()
        bpy.ops.hunterpose.frame(frame=1);bpy.ops.hunterpose.select(control='SWORD')
        bpy.ops.hunterpose.export()
        bpy.ops.wm.save_as_mainfile(filepath=bpy.data.filepath)
    (directory/'ui_verification.json').write_text(json.dumps({'operators':reports,'export':str(directory/'exports/pose_001.png')},indent=2),encoding='utf-8')
    def screenshot():
        bpy.ops.screen.screenshot(filepath=str(directory/'workspace.png'))
        return None
    bpy.app.timers.register(screenshot,first_interval=3)
    return None


if __name__=='__main__':
    register()
    if '--pose-smoke-test' in sys.argv:bpy.app.timers.register(smoke_test,first_interval=5)
