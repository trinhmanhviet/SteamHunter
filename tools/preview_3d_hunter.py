"""Render a generated GLB from four orthographic views using portable Blender.

blender --background --factory-startup --python tools/preview_3d_hunter.py -- model.glb output_dir
"""

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector, Matrix

sys.path.insert(0, str(Path(__file__).resolve().parent))
from blender_sprite_contract import ortho_framing, srgb_to_linear


def vertices_in_world(objects):
    return [obj.matrix_world @ vertex.co for obj in objects for vertex in obj.data.vertices]


def orient_and_center(objects):
    points = vertices_in_world(objects)
    extents = [max(p[i] for p in points) - min(p[i] for p in points) for i in range(3)]
    axis = max(range(3), key=lambda index: extents[index])
    # GLB import converts Y-up to Z-up; restore generated model's longest (height) axis.
    rotation = Matrix.Identity(4)
    if axis == 1:
        rotation = Matrix.Rotation(-math.pi / 2, 4, "X")
    elif axis == 0:
        rotation = Matrix.Rotation(-math.pi / 2, 4, "Y")
    for obj in objects:
        obj.matrix_world = rotation @ obj.matrix_world
    points = vertices_in_world(objects)
    low = Vector(tuple(min(p[i] for p in points) for i in range(3)))
    high = Vector(tuple(max(p[i] for p in points) for i in range(3)))
    translation = Matrix.Translation(Vector((-(low.x + high.x) / 2, -(low.y + high.y) / 2, -low.z)))
    for obj in objects:
        obj.matrix_world = translation @ obj.matrix_world
    return high.z - low.z, axis


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--source-colours", choices=("srgb", "linear"), default="srgb")
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    args.output.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(args.input.resolve()))
    objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not objects:
        raise RuntimeError("Input has no mesh")
    if args.source_colours == "srgb":
        # TRELLIS mesh colours predict image sRGB; glTF colour attributes are linear.
        # Correct the imported attribute before Workbench applies its display transfer.
        for obj in objects:
            for attribute in obj.data.color_attributes:
                for item in attribute.data:
                    colour = item.color
                    item.color = tuple(srgb_to_linear(v) for v in colour[:3]) + (colour[3],)
    rest_height, imported_axis = orient_and_center(objects)
    scale, center_z = ortho_framing(rest_height)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.film_transparent = True
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.display.shading.light = "FLAT"
    scene.display.shading.color_type = "VERTEX"
    scene.display.shading.show_shadows = False
    scene.display.shading.show_cavity = False
    scene.display.shading.show_object_outline = True
    scene.display.shading.object_outline_color = (0.035, 0.06, 0.1)
    scene.display.shading.background_type = "WORLD"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.display.render_aa = "OFF"
    scene.render.filter_size = 0.01
    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = "SpriteCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = scale
    camera.data.clip_start = 0.001
    camera.data.clip_end = 1000
    scene.camera = camera
    output_files = []
    for name, angle in (("front", 0), ("right", 90), ("back", 180), ("left", 270)):
        rad = math.radians(angle)
        target = Vector((0, 0, center_z))
        camera.location = Vector((math.sin(rad) * scale * 5, -math.cos(rad) * scale * 5, center_z))
        camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
        for resolution in (512, 128):
            scene.render.resolution_x = resolution
            scene.render.resolution_y = resolution
            path = args.output / f"{name}_{resolution}.png"
            scene.render.filepath = str(path.resolve())
            bpy.ops.render.render(write_still=True)
            output_files.append(path.name)
    # Leave a native-sized side view in the saved scene.
    bpy.ops.wm.save_as_mainfile(filepath=str((args.output / "hunter_inspection.blend").resolve()))
    report = {
        "source": str(args.input), "rigged": False,
        "rest_height_world": rest_height, "longest_imported_axis": imported_axis,
        "orthographic_scale": scale, "camera_center_z": center_z,
        "native_canvas": [128, 128], "rest_height_pixels": 104, "ground_y": 116,
        "lighting": "flat vertex colour", "outputs": output_files,
        "source_colour_space": args.source_colours,
    }
    (args.output / "preview_metadata.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("PREVIEW_COMPLETE " + str(args.output.resolve()), flush=True)


if __name__ == "__main__":
    main()
