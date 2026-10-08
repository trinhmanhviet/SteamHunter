"""Rig the cleaned Hunyuan hunter and render a planted, two-handed heavy-cut study."""

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
import bmesh
import numpy as np
from mathutils import Vector, Quaternion

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hunter_rig_weights import LANDMARKS, compute_weights
from rig_hunter_prototype import project, paint_object
from blender_sprite_contract import sample_frames


def rest_colours(body):
    image = next(node.image for slot in body.material_slots for node in slot.material.node_tree.nodes
                 if node.type == "TEX_IMAGE" and node.image)
    pixels = np.empty(len(image.pixels), dtype=np.float32)
    image.pixels.foreach_get(pixels)
    pixels = pixels.reshape(image.size[1], image.size[0], image.channels)
    loops = np.array([loop.vertex_index for loop in body.data.loops])
    uv = np.array([tuple(point.uv) for point in body.data.uv_layers.active.data])
    vertex_uv = np.zeros((len(body.data.vertices), 2))
    vertex_uv[loops] = uv
    x = np.clip((vertex_uv[:, 0] * image.size[0]).astype(int), 0, image.size[0] - 1)
    y = np.clip((vertex_uv[:, 1] * image.size[1]).astype(int), 0, image.size[1] - 1)
    return pixels[y, x, :3]


def build_rig(body, height):
    # Rejoin duplicate UV seam vertices for Blender's heat binding. Loop UVs survive.
    mesh = bmesh.new()
    mesh.from_mesh(body.data)
    bmesh.ops.remove_doubles(mesh, verts=list(mesh.verts), dist=height * 1e-6)
    mesh.to_mesh(body.data)
    mesh.free()
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    rig = bpy.context.object
    rig.name = "HunyuanHeavyRig"
    rig.data.edit_bones.remove(rig.data.edit_bones[0])
    for name, (head, tail, parent) in LANDMARKS.items():
        bone = rig.data.edit_bones.new(name)
        bone.head, bone.tail = Vector(head) * height, Vector(tail) * height
        if parent:
            bone.parent = rig.data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.show_in_front = True
    points = np.array([tuple(body.matrix_world @ v.co) for v in body.data.vertices]) / height
    names, weights = compute_weights(points, rest_colours(body))
    # Smooth the cloth/limb transitions along real mesh edges. Colour boundaries
    # are not physical cuts and must not create discontinuous bone transforms.
    edges = np.array([tuple(edge.vertices) for edge in body.data.edges])
    degree = np.bincount(edges.ravel(), minlength=len(points)).astype(float)
    fixed = weights.copy()
    protected = (points[:, 2] >= .855) | (points[:, 2] < .13) | (
        (np.abs(points[:, 0]) > .195) & (points[:, 2] < .485) & (points[:, 2] > .345))
    for _ in range(12):
        total = np.zeros_like(weights)
        np.add.at(total, edges[:, 0], weights[edges[:, 1]])
        np.add.at(total, edges[:, 1], weights[edges[:, 0]])
        weights = .4 * weights + .6 * total / np.maximum(degree[:, None], 1)
        weights[protected] = fixed[protected]
        weights /= np.maximum(weights.sum(axis=1, keepdims=True), 1e-9)
    groups = [body.vertex_groups.new(name=name) for name in names]
    for index, row in enumerate(weights):
        for bone_index in np.flatnonzero(row):
            groups[bone_index].add([index], float(row[bone_index]), "REPLACE")
    modifier = body.modifiers.new("Anatomy-restricted protected skin", "ARMATURE")
    modifier.object = rig
    modifier.use_deform_preserve_volume = True
    return rig, points


def empty(name, position):
    bpy.ops.object.empty_add(location=position)
    result = bpy.context.object
    result.name = name
    return result


def set_emission_colour(obj, rgb):
    paint_object(obj, rgb)
    material = bpy.data.materials.new(obj.name + "_FlatColour")
    material.use_nodes = True
    nodes, links = material.node_tree.nodes, material.node_tree.links
    nodes.clear()
    vertex = nodes.new("ShaderNodeVertexColor")
    vertex.layer_name = "WeaponColor"
    emission = nodes.new("ShaderNodeEmission")
    output = nodes.new("ShaderNodeOutputMaterial")
    links.new(vertex.outputs["Color"], emission.inputs["Color"])
    links.new(emission.outputs["Emission"], output.inputs["Surface"])
    obj.data.materials.append(material)


def prism(name, outline, thickness, height, rgb, parent):
    count = len(outline)
    verts = [(x * height, y * height, z * height) for x in (-thickness, thickness) for z, y in outline]
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count) for i in range(count)]
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.parent = parent
    set_emission_colour(obj, rgb)
    return obj


def build_cleaver(height):
    pivot = empty("GreatCleaverPivot", (0, 0, 0))
    outline = [(-.074, .035), (.059, .035), (.081, .75), (.026, .91), (-.063, .86)]
    blade = prism("HeavyBlade", outline, .018, height, (.68, .77, .82), pivot)
    edge_outline = [(-.074, .04), (-.05, .05), (-.041, .842), (.026, .91), (-.063, .86)]
    edge = prism("BladeBevel", edge_outline, .019, height, (.94, .977, .996), pivot)
    spine_outline = [(.040, .08), (.057, .08), (.078, .744), (.026, .91), (.04, .794)]
    spine = prism("BladeSpine", spine_outline, .020, height, (.36, .46, .56), pivot)
    parts = [blade, edge, spine]
    for name, location, scale, rgb in (
        ("BrassGuard", (0, .025, 0), (.031, .020, .103), (.75, .568, .255)),
        ("LeatherGrip", (0, -.082, 0), (.020, .086, .022), (.298, .188, .145)),
        ("BrassPommel", (0, -.180, 0), (.027, .024, .030), (.75, .568, .255)),
        ("BladeRivet", (-.021, .10, .015), (.004, .016, .010), (.41, .278, .137)),
    ):
        bpy.ops.mesh.primitive_cube_add(size=2)
        obj = bpy.context.object
        obj.name, obj.parent = name, pivot
        obj.location, obj.scale = Vector(location) * height, Vector(scale) * height
        set_emission_colour(obj, rgb)
        parts.append(obj)
    grips, wrists = {}, {}
    for suffix, side, y in (("R", -1, -.028), ("L", 1, -.108)):
        grip = empty("Grip." + suffix, (0, 0, 0))
        grip.parent = pivot
        grip.location = Vector((side * .024, y, 0)) * height
        wrist = empty("WristIK." + suffix, (0, 0, 0))
        wrist.parent = pivot
        wrist.location = Vector((side * .024, y - .023, 0)) * height
        grips[suffix], wrists[suffix] = grip, wrist
    return pivot, parts, grips, wrists


def choose_pole(scene, rig, constraint, bone_name, desired, height):
    best = None
    for angle in (0, math.pi / 2, math.pi, -math.pi / 2):
        constraint.pole_angle = angle
        bpy.context.view_layer.update()
        point = rig.matrix_world @ rig.pose.bones[bone_name].head
        score = ((point - desired) / height).length_squared
        if best is None or score < best[0]:
            best = score, angle
    constraint.pole_angle = best[1]
    bpy.context.view_layer.update()
    return best[1]


def global_bone_shift(bone, delta):
    bone.location = bone.bone.matrix_local.to_3x3().inverted() @ delta


def holdout_material():
    material = bpy.data.materials.new("BodyDepthHoldout")
    material.use_nodes = True
    material.node_tree.nodes.clear()
    mask = material.node_tree.nodes.new("ShaderNodeHoldout")
    output = material.node_tree.nodes.new("ShaderNodeOutputMaterial")
    material.node_tree.links.new(mask.outputs[0], output.inputs["Surface"])
    return material


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    args.output.mkdir(parents=True, exist_ok=True)
    scene, camera = bpy.context.scene, bpy.context.scene.camera
    body = next(obj for obj in scene.objects if obj.type == "MESH")
    body.name = "HunterBody"
    world_points = [body.matrix_world @ v.co for v in body.data.vertices]
    height = max(v.z for v in world_points) - min(v.z for v in world_points)
    rig, rest_points = build_rig(body, height)
    pivot, weapons, grips, wrists = build_cleaver(height)
    feet, poles = {}, {}
    for suffix, sign, forward in (("R", -1, -.165), ("L", 1, .105)):
        feet[suffix] = empty("FootTarget." + suffix, Vector((sign * .12, forward, .075)) * height)
        feet[suffix].rotation_mode = "QUATERNION"
        feet[suffix].rotation_quaternion = rig.data.bones["foot." + suffix].matrix_local.to_quaternion()
        pole = empty("KneePole." + suffix, Vector((sign * .12, -.4, .25)) * height)
        leg = rig.pose.bones["shin." + suffix].constraints.new("IK")
        leg.target, leg.pole_target, leg.chain_count, leg.use_stretch = feet[suffix], pole, 2, False
        ankle = rig.pose.bones["foot." + suffix].constraints.new("COPY_ROTATION")
        ankle.target, ankle.owner_space, ankle.target_space = feet[suffix], "WORLD", "WORLD"
        elbow = empty("ElbowPole." + suffix, Vector((sign * .38, .10, .62)) * height)
        arm = rig.pose.bones["forearm." + suffix].constraints.new("IK")
        arm.target, arm.pole_target, arm.chain_count, arm.use_stretch = wrists[suffix], elbow, 2, False
        hand = rig.pose.bones["hand." + suffix].constraints.new("COPY_ROTATION")
        hand.target, hand.owner_space, hand.target_space = pivot, "WORLD", "WORLD"
        poles[suffix] = (leg, arm)
    scene.render.fps = 30
    scene.frame_start, scene.frame_end = 1, 66
    keys = [
        # frame, sword forward/height/angle, hip forward/drop, torso lean
        (1, -.105, .635, 16, 0, -.045, 5),
        (10, -.075, .67, 48, .030, -.085, -3),
        (22, -.080, .790, 108, .025, -.085, -8),
        (30, -.085, .780, 108, .020, -.078, -6),
        (33, -.12, .700, 75, -.025, -.095, 7),
        (36, -.245, .520, -32, -.085, -.110, 26),
        (42, -.22, .510, -29, -.080, -.095, 22),
        (54, -.16, .585, -8, -.035, -.072, 10),
        (66, -.105, .635, 16, 0, -.045, 5),
    ]
    for frame, y, z, angle, hip_y, drop, lean in keys:
        pivot.location = Vector((-.010, y, z)) * height
        pivot.rotation_euler = (math.radians(angle), 0, math.pi)
        pivot.keyframe_insert("location", frame=frame)
        pivot.keyframe_insert("rotation_euler", frame=frame)
        hips = rig.pose.bones["hips"]
        global_bone_shift(hips, Vector((0, hip_y, drop)) * height)
        hips.keyframe_insert("location", frame=frame)
        for name, value in (("spine", lean), ("head", -lean * .35)):
            bone = rig.pose.bones[name]
            bone.rotation_mode = "XYZ"
            bone.rotation_euler.x = math.radians(value)
            bone.keyframe_insert("rotation_euler", frame=frame)
    scene.frame_set(1)
    bpy.context.view_layer.update()
    pole_angles = {}
    for suffix, sign in (("R", -1), ("L", 1)):
        leg, arm = poles[suffix]
        pole_angles[suffix] = {
            "knee": choose_pole(scene, rig, leg, "shin." + suffix, Vector((sign * .12, -.20, .27)) * height, height),
            "elbow": choose_pole(scene, rig, arm, "forearm." + suffix, Vector((sign * .23, .08, .61)) * height, height),
        }
    base_scale, center_z = camera.data.ortho_scale, camera.location.z
    materials = [slot.material for slot in body.material_slots]
    holdout = holdout_material()
    for part in weapons:
        part.hide_render = True
    camera.location = Vector((0, -base_scale * 5, center_z))
    camera.rotation_euler = (Vector((0, 0, center_z)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    bones = {bone.name: {
        "head": project(scene, camera, rig.matrix_world @ bone.head, (512, 512)),
        "tail": project(scene, camera, rig.matrix_world @ bone.tail, (512, 512)),
    } for bone in rig.pose.bones}
    scene.render.resolution_x = scene.render.resolution_y = 512
    scene.render.filepath = str((args.output / "rig_front.png").resolve())
    bpy.ops.render.render(write_still=True)
    camera.location = Vector((-base_scale * 5, 0, center_z))
    camera.rotation_euler = (Vector((0, 0, center_z)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    frames = []
    sampled = sorted(set(sample_frames(1, 66, 30, 6) + [10, 22, 30, 33, 36, 42, 54]))
    sole_indices = np.where(rest_points[:, 2] < .006)[0]
    for index, frame in enumerate(sampled):
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        camera.data.ortho_scale = base_scale
        scene.render.resolution_x = scene.render.resolution_y = 128
        for slot, material in zip(body.material_slots, materials):
            slot.material = material
        for part in weapons:
            part.hide_render = True
        path = args.output / "body" / f"heavy_cut_{index:02}.png"
        path.parent.mkdir(exist_ok=True)
        scene.render.filepath = str(path.resolve())
        bpy.ops.render.render(write_still=True)
        sockets = {name: project(scene, camera, grips[suffix].matrix_world.translation, (128, 128))
                   for suffix, name in (("R", "right_hand"), ("L", "left_hand"))}
        tip = project(scene, camera, pivot.matrix_world @ Vector((0, .91 * height, 0)), (128, 128))
        gap = {suffix: round((rig.matrix_world @ rig.pose.bones["forearm." + suffix].tail
                             - wrists[suffix].matrix_world.translation).length / height * 104, 4) for suffix in ("R", "L")}
        evaluated = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
        sole_error = max(abs((body.matrix_world @ evaluated.data.vertices[int(v)].co).z / height
                             - rest_points[int(v), 2]) * 104 for v in sole_indices)
        camera.data.ortho_scale = base_scale * 2
        scene.render.resolution_x = scene.render.resolution_y = 256
        for slot in body.material_slots:
            slot.material = holdout
        for part in weapons:
            part.hide_render = False
        weapon_path = args.output / "weapon" / f"heavy_cut_{index:02}.png"
        weapon_path.parent.mkdir(exist_ok=True)
        scene.render.filepath = str(weapon_path.resolve())
        bpy.ops.render.render(write_still=True)
        phase = "ready" if frame < 10 else ("anticipation" if frame < 22 else (
            "charge" if frame < 33 else ("descent" if frame < 36 else (
                "impact" if frame < 42 else ("follow_through" if frame < 54 else "recovery")))))
        grip = sockets["right_hand"]
        frames.append({
            "frame": index, "source_frame": frame, "phase": phase,
            "duration": ((sampled[index + 1] if index + 1 < len(sampled) else 67) - frame) / 30,
            "body": path.relative_to(args.output).as_posix(),
            "weapon": weapon_path.relative_to(args.output).as_posix(),
            "attachment_points": sockets, "weapon_tip": tip,
            "weapon_rotation": math.atan2(tip[1] - grip[1], tip[0] - grip[0]),
            "wrist_ik_error_pixels": gap, "sole_vertical_error_pixels": round(sole_error, 5),
        })
    for slot, material in zip(body.material_slots, materials):
        slot.material = material
    for part in weapons:
        part.hide_render = False
    camera.data.ortho_scale = base_scale
    scene.render.resolution_x = scene.render.resolution_y = 128
    scene.frame_set(1)
    bpy.ops.wm.save_as_mainfile(filepath=str((args.output / "hunter_heavy_rig.blend").resolve()))
    metadata = {
        "animation": "heavy_cut", "source_fps": 30, "output_fps_base": 6,
        "body_canvas": [128, 128], "weapon_canvas": [256, 256],
        "weapon_canvas_offset": [-64, -64], "ground_pivot": [64, 116],
        "body_weapon_depth_holdout": True, "bone_pole_angles": pole_angles,
        "skin_binding": "Anatomy-restricted segment weights after UV seam weld, with protected face/palms/soles/coat",
        "bones_front": bones, "frames": frames,
    }
    (args.output / "metadata.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print("HEAVY_RIG_READY " + str(args.output.resolve()), flush=True)


if __name__ == "__main__":
    main()
