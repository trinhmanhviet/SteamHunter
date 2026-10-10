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

REFERENCE = Path(__file__).resolve().parents[1] / "prototypes/reference_skeleton/poses.json"
# Game frame, approved source frame, grip Y/Z, hip Y/drop/yaw, shoulder yaw,
# front/rear foot Y, rear heel pitch. Keep anatomical lengths in the side view.
CONTROLS = [
    (1, 23, .060, .910, 0, -.035, -4, 7, -.160, .140, 0),
    (2, 23, .060, .910, 0, -.035, -4, 7, -.160, .140, 0),
    (3, 24, .020, .940, .005, -.040, -6, 9, -.175, .145, 0),
    (5, 26, .020, .930, -.015, -.120, -12, 14, -.280, .190, 3),
    (7, 28, -.270, .860, -.010, -.110, -12, 14, -.265, .185, 3),
    (8, 29, -.310, .790, -.015, -.120, -12, 14, -.280, .190, 3),
    (9, 26, .020, .930, -.015, -.120, -12, 14, -.280, .190, 3),
    (12, 26, .020, .933, -.015, -.122, -12, 14, -.280, .190, 3),
    (15, 26, .020, .930, -.015, -.120, -12, 14, -.280, .190, 3),
    (18, 26, .020, .927, -.015, -.118, -12, 14, -.280, .190, 3),
    (20, 26, .020, .930, -.015, -.120, -12, 14, -.280, .190, 3),
    (21, 30, -.430, .660, -.010, -.145, 0, 2, -.240, .200, 5),
    (22, 31, -.510, .430, .010, -.200, 7, -5, -.200, .205, 6),
    (23, 32, -.480, .290, .025, -.220, 9, -7, -.180, .210, 6),
    (24, 32, -.480, .290, .025, -.220, 9, -7, -.180, .210, 6),
    (35, 40, -.480, .290, .025, -.220, 9, -7, -.180, .210, 5),
    (56, 68, -.470, .420, .010, -.150, 6, -3, -.180, .195, 3),
    (57, 68, -.470, .420, .010, -.150, 6, -3, -.180, .195, 3),
    (62, 76, -.360, .460, 0, -.090, 2, 0, -.175, .180, 1),
    (67, 84, -.320, .660, -.005, -.040, -1, 3, -.165, .155, 0),
    (74, 23, .060, .910, 0, -.035, -4, 7, -.160, .140, 0),
]


def reference_angles(source):
    joints = source["joints"]
    guard, tip, neck = joints["guard"], joints["tip"], joints["neck"]
    pelvis = [(joints["hip_near"][i] + joints["hip_far"][i]) / 2 for i in range(2)]
    # Mirror the clip's leftward cut to the game's default right-facing hunter.
    blade = math.degrees(math.atan2(guard[1] - tip[1], guard[0] - tip[0]))
    lean = math.degrees(math.atan2(pelvis[0] - neck[0], pelvis[1] - neck[1]))
    # The original blade is curved and shown in perspective. Limit floor dips and
    # extreme projected trunk angles when applied to a straight side-view blade.
    return max(-17, blade), min(68, max(-3, lean))

STAGES = {"ready": [1], "raise": list(range(2, 6)), "release": list(range(6, 9)), "hold": list(range(9, 21)),
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
    references = {f["source_frame"]: f for f in json.loads(REFERENCE.read_text(encoding="utf-8"))["frames"]}
    for row in CONTROLS:
        frame, source_frame, y, z, hip_y, drop, yaw, chest, front, rear, heel = row
        scene.frame_set(frame)
        angle, lean = reference_angles(references[source_frame])
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
            feet[suffix].location = Vector((side * .12, front if suffix == "R" else rear,
                                           .075 + .045 * pitch / 30)) * height
            feet[suffix].rotation_quaternion = Quaternion((1, 0, 0), math.radians(pitch)) @ base_foot[suffix]
            feet[suffix].keyframe_insert("location", frame=frame)
            feet[suffix].keyframe_insert("rotation_quaternion", frame=frame)
            bpy.context.view_layer.update()
            shoulder = rig.matrix_world @ rig.pose.bones["upper_arm." + suffix].head
            wrist = bpy.data.objects["WristIK." + suffix].matrix_world.translation
            # The approved sketches fold the elbows below the hands. Use the
            # existing arm IK, keeping each elbow on its anatomical side.
            elbows[suffix].location = shoulder.lerp(wrist, .5) + Vector((side * .20, 0, -.12)) * height
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
                    Vector((side * .23, 0, .78)) * height, height)
        leg = next(c for c in rig.pose.bones["shin." + suffix].constraints if c.type == "IK")
        choose_pole(scene, rig, leg, "shin." + suffix,
                    Vector((side * .12, -.08 if suffix == "R" else .01, .27)) * height, height)
    frames = [row[0] for row in CONTROLS] if args.keys else list(range(1, 75))
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
        joint_positions = {name: {"head": project(scene, camera, rig.matrix_world @ bone.head, (128, 128)),
                                  "tail": project(scene, camera, rig.matrix_world @ bone.tail, (128, 128))}
                           for name, bone in rig.pose.bones.items()}
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
                         "weapon_angle": angle, "blade_local": local, "rig_joints": joint_positions})
    for slot, material in zip(body.material_slots, materials):
        slot.material = material
    camera.data.ortho_scale = scale
    camera.location.z = center
    scene.render.resolution_x = scene.render.resolution_y = 128
    scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str((args.output / "overhead_rig.blend").resolve()))
    (args.output / "render.json").write_text(json.dumps({"fps": 30, "stages": STAGES,
        "body_pivot": [64, 116], "weapon_pivot": [192, 244],
        "weapon_length_multiplier": 1.4, "reference": REFERENCE.relative_to(Path(__file__).resolve().parents[1]).as_posix(),
        "reference_controls": [{"game_frame": row[0], "source_frame": row[1],
                                "blade_degrees": reference_angles(references[row[1]])[0],
                                "trunk_lean_degrees": reference_angles(references[row[1]])[1]}
                               for row in CONTROLS], "frames": exported}, indent=2))
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
