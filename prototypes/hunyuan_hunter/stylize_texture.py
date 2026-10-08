"""Technical UV cleanup/quantization for the approved pixel-asset pipeline."""

import json
import sys
from pathlib import Path

import numpy as np
import trimesh
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
DIRECTORY = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))
from tools.character_factory import _map_to_palette

# Large, readable colour groups: ink/navy, leather, coat, skin, hair, scarf and steel.
PALETTE = [
    (20, 27, 43), (31, 46, 70), (55, 74, 105),
    (57, 34, 31), (100, 61, 46), (143, 94, 66),
    (103, 36, 28), (173, 56, 35), (219, 83, 43),
    (182, 108, 72), (242, 181, 130), (255, 223, 180),
    (148, 91, 27), (227, 157, 47), (255, 211, 102),
    (181, 148, 106), (232, 208, 165), (255, 238, 205),
    (49, 78, 118), (92, 134, 181), (154, 192, 228), (225, 241, 253),
]


def main():
    original = DIRECTORY / "mesh/hunter_textured.glb"
    scene = trimesh.load(original, force="scene", process=False)
    texture_dir = DIRECTORY / "clean_texture"
    texture_dir.mkdir(parents=True, exist_ok=True)
    before_counts = []
    after_counts = []
    for index, mesh in enumerate(scene.geometry.values()):
        material = mesh.visual.material
        texture = material.baseColorTexture.convert("RGBA")
        before_counts.append(len(mesh.vertices))
        # A small filter in atlas space removes specks without blurring UV layout.
        filtered = texture.convert("RGB").filter(ImageFilter.MedianFilter(7)).convert("RGBA")
        filtered.putalpha(texture.getchannel("A"))
        cleaned = _map_to_palette(filtered, PALETTE)
        material.baseColorTexture = cleaned
        cleaned.save(texture_dir / f"atlas_clean_{index}.png")
        after_counts.append(len(mesh.vertices))
    target = DIRECTORY / "mesh/hunter_clean.glb"
    scene.export(target)
    (texture_dir / "palette.json").write_text(json.dumps(PALETTE, indent=2), encoding="utf-8")
    (texture_dir / "cleanup.json").write_text(json.dumps({
        "source": original.name, "output": target.name,
        "median_kernel": 7, "palette_colors": len(PALETTE),
        "vertices_before": before_counts, "vertices_after": after_counts,
        "geometry_uvs_preserved": True,
    }, indent=2), encoding="utf-8")
    print("CLEAN_TEXTURE_READY " + str(target), flush=True)


if __name__ == "__main__":
    main()
