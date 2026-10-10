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
from rig_hunter_heavy import global_bone_shift, holdout_material, choose_pole
from rig_hunter_prototype import project
from hunter_rig_weights import lower_leg_weights

# frame, grip forward/height/angle, hip forward/drop/yaw, lean, shoulder yaw,
# front foot forward, rear heel pitch. Forward is world -Y, screen right.
POSES = [
    (1, -.30, .575, 12, 0, -.015, -4, 5, 4, -.120, 0),
    (4, -.25, .735, 62, .010, -.040, -8, -3, 9, -.145, 3),
    (8, -.100, .835, 118, .010, -.075, -13, -7, 14, -.170, 6),
    (9, -.100, .835, 118, .010, -.075, -13, -7, 14, -.170, 6),
    (12, -.097, .832, 119, .008, -.079, -13, -6, 13, -.170, 5),
    (15, -.100, .837, 118, .010, -.074, -13, -7, 14, -.170, 6),
    (18, -.103, .833, 117, .012, -.078, -13, -8, 15, -.170, 7),
    (20, -.100, .835, 118, .010, -.075, -13, -7, 14, -.170, 6),
    (21, -.100, .835, 118, .010, -.075, -13, -7, 14, -.170, 6),
    (22, -.33, .615, 45, -.035, -.090, 0, 22, 2, -.19, 9),
    (23, -.440, .390, -15.8, -.070, -.115, 8, 36, -5, -.205, 12),
    (24, -.445, .385, -15.6, -.075, -.120, 9, 38, -6, -.205, 12),
    (27, -.450, .380, -15.4, -.078, -.125, 9, 39, -6, -.205, 11),
    (35, -.440, .390, -15.8, -.070, -.115, 8, 36, -5, -.205, 10),
    (45, -.435, .395, -16.0, -.065, -.110, 7, 34, -4, -.205, 9),
    (56, -.420, .410, -16.7, -.060, -.105, 7, 32, -4, -.205, 8),
    (57, -.415, .412, -16.8, -.055, -.105, 7, 31, -4, -.205, 8),
    (62, -.38, .46, -9, -.040, -.075, 4, 24, -1, -.180, 5),
    (67, -.33, .535, 2, -.020, -.040, 0, 13, 1, -.145, 2),
    (74, -.30, .575, 12, 0, -.015, -4, 5, 4, -.120, 0),
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
    # Longitudinal scale applies equally to blade and handle; width stays fixed.
    pivot.scale.y = 1.4
    # Pivot has a 180-degree facing rotation: reverse local X so each wrist
    # remains on its anatomical side instead of crossing through the other arm.
    for suffix, local_x in (("R", .024), ("L", -.024)):
        bpy.data.objects["Grip." + suffix].location.x = local_x * height
        bpy.data.objects["WristIK." + suffix].location.x = local_x * height
    rig.pose.bones["hips"].rotation_mode = "XYZ"
    # Greaves are solid pieces along the shin, not cloth spanning three joints.
    points = np.array([tuple(body.matrix_world @ v.co) for v in body.data.vertices]) / height
    indices = np.flatnonzero(points[:, 2] < .325)
    names = [group.name for group in body.vertex_groups]
    weights = lower_leg_weights(points[indices], names)
    for group in body.vertex_groups:
        group.remove(indices.tolist())
    for vertex, row in zip(indices, weights):
        for column in np.flatnonzero(row):
            body.vertex_groups[names[column]].add([int(vertex)], float(row[column]), "REPLACE")
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
                                             -.16 + .10 * lifted + hip_y,
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
    metal = [obj for obj in weapons if obj.name in {"HeavyBlade", "BladeBevel", "BladeSpine"}]
    scene.frame_set(1)
    for suffix, side in (("R", -1), ("L", 1)):
        ik = next(c for c in rig.pose.bones["forearm." + suffix].constraints if c.type == "IK")
        choose_pole(scene, rig, ik, "forearm." + suffix,
                    Vector((side * .23, -.12, .61)) * height, height)
        leg = next(c for c in rig.pose.bones["shin." + suffix].constraints if c.type == "IK")
        choose_pole(scene, rig, leg, "shin." + suffix,
                    Vector((side * .12, -.08 if suffix == "R" else .01, .27)) * height, height)
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
        origin = project(scene, camera, pivot.matrix_world.translation, (128, 128))
        tip = project(scene, camera, pivot.matrix_world @ Vector((0, .91 * height, 0)), (128, 128))
        projected = [project(scene, camera, obj.matrix_world @ vertex.co, (128, 128))
                     for obj in metal for vertex in obj.data.vertices]
        blade = convex_hull(projected)
        angle = -pivot.rotation_euler.x
        local = [[math.cos(angle) * (x-origin[0]) + math.sin(angle) * (y-origin[1]),
                  -math.sin(angle) * (x-origin[0]) + math.cos(angle) * (y-origin[1])]
                 for x, y in blade]
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
                         "grip": grip, "tip": tip, "wrist_error_pixels": gap,
                         "blade_polygon": blade, "weapon_origin": origin,
                         "weapon_angle": angle, "blade_local": local})
    for slot, material in zip(body.material_slots, materials):
        slot.material = material
    camera.data.ortho_scale = scale
    camera.location.z = center
    scene.render.resolution_x = scene.render.resolution_y = 128
    scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str((args.output / "overhead_rig.blend").resolve()))
    (args.output / "render.json").write_text(json.dumps({"fps": 30, "stages": STAGES,
        "body_pivot": [64, 116], "weapon_pivot": [192, 244],
        "weapon_length_multiplier": 1.4, "frames": exported}, indent=2))
    print("OVERHEAD_RENDER_DONE", len(exported), flush=True)


def convex_hull(points):
    points = sorted(set(tuple(p) for p in points))
    def cross(o, a, b):
        return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
    lower, upper = [], []
    for p in points:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0: lower.pop()
        lower.append(p)
    for p in reversed(points):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0: upper.pop()
        upper.append(p)
    return [list(p) for p in lower[:-1] + upper[:-1]]


if __name__ == "__main__":
    main()
