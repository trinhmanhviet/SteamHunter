"""Package real Blender animation layers and make a review GIF and rig diagram."""

import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.character_factory import _map_to_palette, extract_palette, pack_sheet, write_godot_spriteframes


def main():
    directory = Path(__file__).resolve().parent / "motion"
    metadata = json.loads((directory / "metadata.json").read_text())
    palette_sources = Image.new("RGBA", (256, 128), (0, 0, 0, 0))
    with Image.open(directory.parent / "inspection/front_512.png") as source:
        palette_sources.alpha_composite(source.resize((128, 128)), (0, 0))
    with Image.open(directory / metadata["frames"][0]["weapon"]) as source:
        palette_sources.alpha_composite(source.resize((128, 128)), (128, 0))
    palette = extract_palette(palette_sources, 32)
    packed = {"body": [], "weapon": []}
    preview = []
    socket_contract = {"right_hand": {}, "left_hand": {}}
    max_gap = 0
    for frame in metadata["frames"]:
        index = frame["frame"]
        for layer in ("body", "weapon"):
            with Image.open(directory / frame[layer]) as source:
                image = source.convert("RGBA")
            image.putalpha(image.getchannel("A").point(lambda alpha: 255 if alpha >= 128 else 0))
            image = _map_to_palette(image, palette)
            path = directory / "sprites" / layer / f"heavy_cut_{index:02}.png"
            path.parent.mkdir(parents=True, exist_ok=True)
            image.save(path)
            packed[layer].append(path)
        with Image.open(packed["body"][-1]) as source:
            body = source.convert("RGBA")
        with Image.open(packed["weapon"][-1]) as source:
            weapon = source.convert("RGBA")
        tile = Image.new("RGBA", (256, 256), "#344b60")
        # Common pixel scale; padded weapon layer has a -64,-64 local offset.
        tile.alpha_composite(body, (64, 64))
        tile.alpha_composite(weapon)
        preview.append(tile.resize((512, 512), Image.Resampling.NEAREST).convert("RGB"))
        for name, position in frame["attachment_points"].items():
            socket_contract[name][f"heavy_cut/{index:02}"] = {
                "position": position, "rotation": frame["weapon_rotation"],
            }
        max_gap = max(max_gap, *frame["wrist_ik_error_pixels"].values())
    for layer, paths in packed.items():
        ground_y = 116 if layer == "body" else 180
        pivot = (64, 116) if layer == "body" else (128, 180)
        sheet, animation_metadata = pack_sheet(
            {"heavy_cut": paths}, directory / "sprites", f"hunter_{layer}", pivot, ground_y,
            socket_contract if layer == "body" else None,
        )
        animation_data = json.loads(animation_metadata.read_text())
        for region, frame in zip(animation_data["animations"]["heavy_cut"]["frames"], metadata["frames"]):
            region["duration"] = frame["duration"] * 6
        animation_metadata.write_text(json.dumps(animation_data, indent=2), encoding="utf-8")
        write_godot_spriteframes(
            animation_metadata, "res://" + sheet.relative_to(ROOT).as_posix(),
            directory / "sprites" / f"hunter_{layer}_spriteframes.tres", fps=6,
        )
    durations = [round(frame["duration"] * 1000) for frame in metadata["frames"]]
    preview[0].save(directory / "heavy_cut_preview.gif", save_all=True, append_images=preview[1:],
                    duration=durations, loop=0, disposal=2)
    contact = Image.new("RGB", (1024, math.ceil(len(preview) / 4) * 256), "#344b60")
    for index, frame in enumerate(preview):
        contact.paste(frame.resize((256, 256), Image.Resampling.NEAREST), ((index % 4) * 256, (index // 4) * 256))
    contact.save(directory / "heavy_cut_contact.png")
    with Image.open(directory / "rig_front.png") as source:
        rig_image = Image.new("RGBA", source.size, "#344b60")
        rig_image.alpha_composite(source.convert("RGBA"))
    draw = ImageDraw.Draw(rig_image)
    for name, endpoints in metadata["bones_front"].items():
        color = "#eec263" if name.endswith(".R") else ("#50e2b8" if name.endswith(".L") else "#ffffff")
        draw.line([tuple(endpoints["head"]), tuple(endpoints["tail"])], fill=color, width=3)
        x, y = endpoints["head"]
        draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=color)
    rig_image.convert("RGB").save(directory / "rig_skeleton.png")
    report = {
        "frames": len(preview), "maximum_wrist_ik_error_pixels": max_gap,
        "palette_colors": len(palette), "body_canvas": [128, 128], "weapon_canvas": [256, 256],
        "status": "render experiment; visually review skinning, silhouette and combat timing",
        "known_limits": [
            "Landmark distance skinning is provisional and does not provide production deformation quality.",
            "Flat mesh-decoder colour needs pixel-cluster cleanup.",
            "6-FPS base plus the authored impact frame; timing is a study, not integrated gameplay timing.",
        ],
    }
    (directory / "review.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2), flush=True)


if __name__ == "__main__":
    main()
