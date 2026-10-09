"""Author a reference-driven overhead study on the saved Hunyuan rig.

blender -b prototypes/hunyuan_hunter/heavy_motion/hunter_heavy_rig.blend
 --python tools/render_overhead_demo.py -- output_directory [--keys]
"""
import argparse
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Quaternion, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from rig_hunter_heavy import global_bone_shift, holdout_material
from rig_hunter_prototype import project

# frame, grip forward/height/angle, hip forward/drop/yaw, lean, shoulder yaw,
# front foot forward, rear heel pitch. Forward is world -Y, screen right.
POSES = [
    (1, -.13, .615, 12, 0, -.035, -8, 4, 8, -.165, 0),
    (4, -.05, .705, 62, .015, -.065, -13, -4, 13, -.18, 6),
    (8, .020, .785, 118, .020, -.10, -17, -11, 18, -.21, 15),
    (9, .020, .785, 118, .020, -.10, -17, -11, 18, -.21, 15),
    (12, .017, .782, 119, .018, -.104, -17, -10, 17, -.21, 14),
    (15, .020, .787, 118, .020, -.099, -17, -11, 18, -.21, 15),
    (18, .023, .783, 117, .022, -.103, -17, -12, 19, -.21, 16),
    (20, .020, .785, 118, .020, -.10, -17, -11, 18, -.21, 15),
    (21, .020, .785, 118, .020, -.10, -17, -11, 18, -.21, 15),
    (22, -.22, .57, 45, -.055, -.13, -1, 25, 3, -.23, 26),
    (23, -.37, .395, -23, -.10, -.19, 13, 48, -9, -.245, 30),
    (24, -.375, .39, -23, -.11, -.20, 14, 50, -10, -.245, 30),
    (27, -.38, .385, -22, -.115, -.205, 14, 51, -10, -.245, 28),
    (35, -.372, .395, -23, -.105, -.195, 13, 48, -9, -.245, 25),
    (45, -.37, .40, -23, -.10, -.19, 12, 47, -8, -.245, 21),
    (56, -.36, .414, -24, -.095, -.18, 11, 45, -7, -.245, 18),
    (57, -.355, .416, -24, -.09, -.18, 11, 44, -7, -.245, 18),
    (62, -.31, .45, -15, -.07, -.14, 6, 34, -3, -.23, 12),
    (67, -.22, .53, -2, -.035, -.085, 0, 20, 1, -.20, 5),
    (74, -.13, .615, 12, 0, -.035, -8, 4, 8, -.165, 0),
]
STAGES = {"ready": [1], "raise": list(range(2, 9)), "hold": list(range(9, 21)),
          "strike": list(range(21, 24)), "settle": list(range(24, 57)),
          "recover": list(range(57, 75))}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--keys", action="store_true")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    args.output.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    body, rig = bpy.data.objects["HunterBody"], bpy.data.objects["HunyuanHeavyRig"]
    pivot, camera = bpy.data.objects["GreatCleaverPivot"], scene.camera
    height = max(v.co.z for v in body.data.vertices) - min(v.co.z for v in body.data.vertices)
    for obj in scene.objects:
        obj.animation_data_clear()
    rig.pose.bones["hips"].rotation_mode = "XYZ"
    feet = {s: bpy.data.objects["FootTarget." + s] for s in ("R", "L")}
    elbows = {s: bpy.data.objects["ElbowPole." + s] for s in ("R", "L")}
    base_foot = {s: feet[s].rotation_quaternion.copy() for s in feet}
    for row in POSES:
        frame, y, z, angle, hip_y, drop, yaw, lean, chest, front, heel = row
        pivot.location = Vector((-.010, y, z)) * height
        pivot.rotation_euler = (math.radians(angle), 0, math.pi)
        pivot.keyframe_insert("location", frame=frame)
        pivot.keyframe_insert("rotation_euler", frame=frame)
        hips = rig.pose.bones["hips"]
        global_bone_shift(hips, Vector((0, hip_y, drop)) * height)
        hips.rotation_euler = (0, math.radians(yaw), 0)
        hips.keyframe_insert("location", frame=frame)
        hips.keyframe_insert("rotation_euler", frame=frame)
        for name, rotation in (("spine", (lean, chest, 0)),
                               ("head", (-lean * .42, -yaw - chest, 0))):
            bone = rig.pose.bones[name]
            bone.rotation_mode = "XYZ"
            bone.rotation_euler = tuple(math.radians(v) for v in rotation)
            bone.keyframe_insert("rotation_euler", frame=frame)
        for suffix, side in (("R", -1), ("L", 1)):
            pitch = heel if suffix == "L" else 0
            feet[suffix].location = Vector((side * .12, front if suffix == "R" else .105,
                                           .075 + .045 * pitch / 30)) * height
            feet[suffix].rotation_quaternion = Quaternion((1, 0, 0), math.radians(pitch)) @ base_foot[suffix]
            feet[suffix].keyframe_insert("location", frame=frame)
            feet[suffix].keyframe_insert("rotation_quaternion", frame=frame)
            # Elbows lift behind the hands overhead, open out as the body folds.
            lifted = max(0, min(1, (angle - 20) / 98))
            elbows[suffix].location = Vector((side * (.34 + .06 * lifted),
                                             .02 + .15 * lifted + hip_y,
                                             .56 + .14 * lifted + drop * .35)) * height
            elbows[suffix].keyframe_insert("location", frame=frame)
    scene.render.fps = 30
    scene.frame_start, scene.frame_end = 1, 74
    # Deliberate linear pose transitions; per-phase timing does the acceleration.
    for obj in scene.objects:
        if obj.animation_data and obj.animation_data.action:
            for curve in obj.animation_data.action.fcurves:
                for key in curve.keyframe_points:
                    key.interpolation = "LINEAR"
    scale, center = camera.data.ortho_scale, camera.location.z
    camera.location = Vector((-scale * 5, 0, center))
    camera.rotation_euler = (Vector((0, 0, center)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    materials = [slot.material for slot in body.material_slots]
    holdout = holdout_material()
    weapons = [obj for obj in scene.objects if obj.type == "MESH" and obj != body]
    frames = [row[0] for row in POSES] if args.keys else list(range(1, 75))
    rest = np.array([tuple(v.co) for v in body.data.vertices])
    # Ground both foot meshes at their lowest visible point, permitting heel lift.
    soles = {s: np.flatnonzero((rest[:, 2] < height * .13) &
                              (rest[:, 0] * side > 0)) for s, side in (("R", -1), ("L", 1))}
    exported = []
    for frame in frames:
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        for suffix in feet:
            evaluated = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
            low = min(evaluated.data.vertices[int(i)].co.z for i in soles[suffix])
            feet[suffix].location.z -= low
            bpy.context.view_layer.update()
        gap = {s: (rig.pose.bones["forearm." + s].tail -
                   bpy.data.objects["WristIK." + s].matrix_world.translation).length / height * 104 for s in feet}
        camera.data.ortho_scale = scale
        scene.render.resolution_x = scene.render.resolution_y = 128
        for slot, material in zip(body.material_slots, materials):
            slot.material = material
        for weapon in weapons:
            weapon.hide_render = True
        path = args.output / "body" / f"overhead_{frame:03}.png"
        path.parent.mkdir(exist_ok=True)
        scene.render.filepath = str(path.resolve())
        bpy.ops.render.render(write_still=True)
        grip = project(scene, camera, bpy.data.objects["Grip.R"].matrix_world.translation, (128, 128))
        tip = project(scene, camera, pivot.matrix_world @ Vector((0, .91 * height, 0)), (128, 128))
        for slot in body.material_slots:
            slot.material = holdout
        for weapon in weapons:
            weapon.hide_render = False
        camera.data.ortho_scale = scale * 3
        scene.render.resolution_x = scene.render.resolution_y = 384
        weapon_path = args.output / "weapon" / path.name
        weapon_path.parent.mkdir(exist_ok=True)
        scene.render.filepath = str(weapon_path.resolve())
        bpy.ops.render.render(write_still=True)
        exported.append({"frame": frame, "body": path.relative_to(args.output).as_posix(),
                         "weapon": weapon_path.relative_to(args.output).as_posix(),
                         "grip": grip, "tip": tip, "wrist_error_pixels": gap})
    for slot, material in zip(body.material_slots, materials):
        slot.material = material
    camera.data.ortho_scale = scale
    camera.location.z = center
    scene.render.resolution_x = scene.render.resolution_y = 128
    scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str((args.output / "overhead_rig.blend").resolve()))
    (args.output / "render.json").write_text(json.dumps({"fps": 30, "stages": STAGES,
        "body_pivot": [64, 116], "weapon_pivot": [192, 244], "frames": exported}, indent=2))
    print("OVERHEAD_RENDER_DONE", len(exported), flush=True)


if __name__ == "__main__":
    main()
