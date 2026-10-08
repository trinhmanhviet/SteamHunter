"""Build a provisional humanoid rig on the generated mesh and render a heavy-cut study.

This uses landmark proportions and distance skinning, not verified production topology
or Mixamo motion. Blender runs this against the inspection .blend in background mode.
"""

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

sys.path.insert(0, str(Path(__file__).resolve().parent))
from blender_sprite_contract import project_ndc, sample_frames, srgb_to_linear


def build_rig(body, height):
    bpy.ops.object.armature_add(enter_editmode=True)
    rig = bpy.context.object
    rig.name = "HunterDraftRig"
    rig.data.edit_bones.remove(rig.data.edit_bones[0])
    landmarks = {
        "hips": ((0, 0, .50), (0, 0, .60), None),
        "spine": ((0, 0, .60), (0, 0, .755), "hips"),
        "neck": ((0, 0, .755), (0, 0, .845), "spine"),
        "head": ((0, 0, .845), (0, 0, .98), "neck"),
    }
    for suffix, sign in (("R", -1), ("L", 1)):
        landmarks.update({
            f"upper_arm.{suffix}": ((sign * .13, 0, .765), (sign * .20, 0, .645), "spine"),
            f"forearm.{suffix}": ((sign * .20, 0, .645), (sign * .255, -.005, .545), f"upper_arm.{suffix}"),
            f"hand.{suffix}": ((sign * .255, -.005, .545), (sign * .26, -.01, .50), f"forearm.{suffix}"),
            f"thigh.{suffix}": ((sign * .075, 0, .50), (sign * .10, 0, .285), "hips"),
            f"shin.{suffix}": ((sign * .10, 0, .285), (sign * .12, 0, .07), f"thigh.{suffix}"),
            f"foot.{suffix}": ((sign * .12, 0, .07), (sign * .12, -.06, .025), f"shin.{suffix}"),
        })
    for name, (head, tail, parent) in landmarks.items():
        bone = rig.data.edit_bones.new(name)
        bone.head = Vector(head) * height
        bone.tail = Vector(tail) * height
        if parent:
            bone.parent = rig.data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.show_in_front = True
    coordinates = np.array([tuple(body.matrix_world @ v.co) for v in body.data.vertices])
    distances = []
    for head, tail, _ in landmarks.values():
        a, b = np.array(head) * height, np.array(tail) * height
        segment = b - a
        t = np.clip(((coordinates - a) @ segment) / (segment @ segment), 0, 1)
        distances.append(np.sum((coordinates - (a + t[:, None] * segment)) ** 2, axis=1))
    distances = np.stack(distances, axis=1)
    nearest = np.argsort(distances, axis=1)[:, :2]
    groups = [body.vertex_groups.new(name=name) for name in landmarks]
    for index in range(len(coordinates)):
        choices = nearest[index]
        inverse = 1 / np.maximum(distances[index, choices], height * height * .0001) ** 2
        weights = inverse / inverse.sum()
        for choice, weight in zip(choices, weights):
            groups[choice].add([index], float(weight), "REPLACE")
    modifier = body.modifiers.new("Draft distance skin", "ARMATURE")
    modifier.object = rig
    modifier.use_deform_preserve_volume = True
    return rig


def paint_object(obj, rgb):
    color = obj.data.color_attributes.new(name="WeaponColor", type="FLOAT_COLOR", domain="CORNER")
    linear = tuple(srgb_to_linear(value) for value in rgb) + (1,)
    for item in color.data:
        item.color = linear
    obj.data.color_attributes.active_color = color


def build_weapon(height):
    bpy.ops.object.empty_add()
    pivot = bpy.context.object
    pivot.name = "GreatCleaverPivot"
    outline = [(-.065, .05), (.055, .05), (.080, .68), (.020, .83), (-.065, .77)]
    # The game camera views along X, so the broad blade plane must be YZ.
    verts = [(z * height, y * height, x * height) for z in (-.015, .015) for x, y in outline]
    count = len(outline)
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count) for i in range(count)]
    data = bpy.data.meshes.new("CleaverBladeMesh")
    data.from_pydata(verts, [], faces)
    blade = bpy.data.objects.new("CleaverBlade", data)
    bpy.context.collection.objects.link(blade)
    blade.parent = pivot
    paint_object(blade, (.65, .82, .93))
    parts = [blade]
    for name, location, scale, rgb in (
        ("CleaverGuard", (0, .03, 0), (.03, .022, .09), (.88, .65, .27)),
        ("CleaverHandle", (0, -.08, 0), (.018, .10, .020), (.24, .16, .18)),
        ("CleaverPommel", (0, -.19, 0), (.024, .022, .026), (.88, .65, .27)),
    ):
        bpy.ops.mesh.primitive_cube_add(size=2)
        part = bpy.context.object
        part.name = name
        part.parent = pivot
        part.location = Vector(location) * height
        part.scale = Vector(scale) * height
        paint_object(part, rgb)
        parts.append(part)
    grips = {}
    for suffix, x, y in (("R", -.018, -.035), ("L", .018, -.12)):
        bpy.ops.object.empty_add()
        target = bpy.context.object
        target.name = "Grip." + suffix
        target.parent = pivot
        target.location = Vector((x, y, 0)) * height
        grips[suffix] = target
    return pivot, parts, grips


def project(scene, camera, world, canvas):
    ndc = world_to_camera_view(scene, camera, world)
    return list(project_ndc((ndc.x, ndc.y), canvas))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    args.output.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    body = next(obj for obj in scene.objects if obj.type == "MESH")
    body.name = "HunterBody"
    points = [body.matrix_world @ v.co for v in body.data.vertices]
    height = max(v.z for v in points) - min(v.z for v in points)
    rig = build_rig(body, height)
    pivot, weapons, grips = build_weapon(height)
    for suffix in ("R", "L"):
        ik = rig.pose.bones["forearm." + suffix].constraints.new("IK")
        ik.target = grips[suffix]
        ik.chain_count = 2
        ik.use_stretch = False
    camera = scene.camera
    original_scale = camera.data.ortho_scale
    scene.render.fps = 30
    scene.frame_start, scene.frame_end = 1, 40
    # Heavy-cut timing: preparation, hold above shoulder, quick descent, recovery.
    keys = [
        (1, -.10, .65, 20, 0), (8, -.08, .69, 48, -3),
        (16, -.075, .80, 100, -4), (21, -.08, .81, 108, -4),
        (24, -.17, .60, -25, 7), (29, -.16, .61, -18, 5),
        (35, -.11, .64, 10, 1), (40, -.10, .65, 20, 0),
    ]
    for frame, y, z, angle, lean in keys:
        pivot.location = Vector((0, y, z)) * height
        pivot.rotation_euler = (math.radians(angle), 0, math.pi)
        pivot.keyframe_insert("location", frame=frame)
        pivot.keyframe_insert("rotation_euler", frame=frame)
        rig.pose.bones["spine"].rotation_mode = "XYZ"
        rig.pose.bones["spine"].rotation_euler.x = math.radians(lean)
        rig.pose.bones["spine"].keyframe_insert("rotation_euler", frame=frame)
    # Record actual deformed skeleton positions for a review overlay.
    scene.frame_set(1)
    bpy.context.view_layer.update()
    camera.location.x = 0
    camera.location.y = -original_scale * 5
    camera.rotation_euler = (Vector((0, 0, camera.location.z)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    bones = {}
    for bone in rig.pose.bones:
        bones[bone.name] = {
            "head": project(scene, camera, rig.matrix_world @ bone.head, (512, 512)),
            "tail": project(scene, camera, rig.matrix_world @ bone.tail, (512, 512)),
        }
    for part in weapons:
        part.hide_render = True
    scene.render.resolution_x = scene.render.resolution_y = 512
    scene.render.filepath = str((args.output / "rig_front.png").resolve())
    bpy.ops.render.render(write_still=True)
    # Game side view facing right, constant body framing across the clip.
    camera.location.x = -original_scale * 5
    camera.location.y = 0
    camera.rotation_euler = (Vector((0, 0, camera.location.z)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    frames = []
    sampled = sorted(set(sample_frames(1, 40, 30, 6) + [24]))
    for index, frame in enumerate(sampled):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        camera.data.ortho_scale = original_scale
        scene.render.resolution_x = scene.render.resolution_y = 128
        body.hide_render = False
        for part in weapons:
            part.hide_render = True
        target = args.output / "body" / f"heavy_cut_{index:02}.png"
        target.parent.mkdir(exist_ok=True)
        scene.render.filepath = str(target.resolve())
        bpy.ops.render.render(write_still=True)
        sockets = {}
        wrist_gaps = {}
        for suffix, name in (("R", "right_hand"), ("L", "left_hand")):
            sockets[name] = project(scene, camera, grips[suffix].matrix_world.translation, (128, 128))
            wrist_world = rig.matrix_world @ rig.pose.bones["forearm." + suffix].tail
            wrist_gaps[name] = round((wrist_world - grips[suffix].matrix_world.translation).length / height * 104, 2)
        tip_world = pivot.matrix_world @ Vector((0, .83 * height, 0))
        tip = project(scene, camera, tip_world, (128, 128))
        grip = sockets["right_hand"]
        angle = math.atan2(tip[1] - grip[1], tip[0] - grip[0])
        camera.data.ortho_scale = original_scale * 2
        scene.render.resolution_x = scene.render.resolution_y = 256
        body.hide_render = True
        for part in weapons:
            part.hide_render = False
        weapon_target = args.output / "weapon" / f"heavy_cut_{index:02}.png"
        weapon_target.parent.mkdir(exist_ok=True)
        scene.render.filepath = str(weapon_target.resolve())
        bpy.ops.render.render(write_still=True)
        frames.append({
            "frame": index, "source_frame": frame, "time_seconds": (frame - 1) / 30,
            "duration": ((sampled[index + 1] if index + 1 < len(sampled) else 41) - frame) / 30,
            "body": str(target.relative_to(args.output)),
            "weapon": str(weapon_target.relative_to(args.output)),
            "attachment_points": sockets, "weapon_tip": tip,
            "weapon_rotation": angle, "wrist_ik_error_pixels": wrist_gaps,
        })
    body.hide_render = False
    for part in weapons:
        part.hide_render = False
    camera.data.ortho_scale = original_scale
    scene.render.resolution_x = scene.render.resolution_y = 128
    scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str((args.output / "hunter_draft_rig.blend").resolve()))
    metadata = {
        "status": "draft rig, landmark proportions and distance skinning; visually review deformation",
        "body_canvas": [128, 128], "weapon_canvas": [256, 256],
        "weapon_canvas_offset": [-64, -64], "ground_pivot": [64, 116],
        "source_fps": 30, "output_fps": 6, "animation": "heavy_cut",
        "bones_front": bones, "frames": frames,
    }
    (args.output / "metadata.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print(f"DRAFT_RIG_COMPLETE {len(frames)} frames, 2 hand sockets, separate weapon layer", flush=True)


if __name__ == "__main__":
    main()
