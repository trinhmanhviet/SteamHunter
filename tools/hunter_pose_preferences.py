"""Initialize only the pose workspace's isolated Blender preferences."""
import bpy
import os
from pathlib import Path

expected=Path(__file__).resolve().parents[1]/'prototypes/hunter_pose_workspace/blender_config'
actual=Path(os.environ.get('BLENDER_USER_CONFIG','')).resolve()
if actual!=expected.resolve():raise RuntimeError('Refusing to save global Blender preferences')
actual.mkdir(parents=True,exist_ok=True)
bpy.context.preferences.view.show_splash=False
bpy.ops.wm.save_userpref()
print('POSE_PREFERENCES',str(actual),flush=True)
print('REGION_PROPERTIES',list(bpy.types.Region.bl_rna.properties.keys()),flush=True)
