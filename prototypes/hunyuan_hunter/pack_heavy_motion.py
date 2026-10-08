"""Export the cleaned heavy-cleaver study and review its real rendered layers."""

import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.character_factory import _map_to_palette, pack_sheet, write_godot_spriteframes
from prototypes.hunyuan_hunter.stylize_texture import PALETTE

DIRECTORY = Path(__file__).resolve().parent
WEAPON_COLOURS = [(91, 117, 143), (174, 195, 209), (241, 249, 254), (191, 145, 65), (105, 71, 35), (76, 48, 37)]
PHASES = {"ready": "Sẵn sàng", "anticipation": "Lấy đà", "charge": "Giữ kiếm",
          "descent": "Vung xuống", "impact": "Chém nặng", "follow_through": "Theo đà", "recovery": "Hồi thế"}


def load_rgba(path):
    with Image.open(path) as source:
        return source.convert("RGBA")


def main():
    directory = DIRECTORY / "heavy_motion"
    metadata = json.loads((directory / "metadata.json").read_text())
    palette = PALETTE + WEAPON_COLOURS
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 20)
    small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 15)
    accepted = {"body": [], "weapon": []}
    sockets = {"right_hand": {}, "left_hand": {}}
    images, frame_qa = [], []
    for frame in metadata["frames"]:
        number = frame["frame"]
        current = {}
        row = {"frame": number, "phase": frame["phase"]}
        for layer in ("body", "weapon"):
            image = load_rgba(directory / frame[layer])
            image.putalpha(image.getchannel("A").point(lambda value: 255 if value >= 128 else 0))
            image = _map_to_palette(image, palette)
            target = directory / "sprites" / layer / f"heavy_cut_{number:02}.png"
            target.parent.mkdir(parents=True, exist_ok=True)
            image.save(target)
            accepted[layer].append(target)
            current[layer] = image
            box = image.getchannel("A").getbbox()
            if box is None or box[0] <= 0 or box[1] <= 0 or box[2] >= image.width or box[3] >= image.height:
                raise RuntimeError(f"{layer} frame {number} is empty or clipped: {box}")
            colors = {pixel[:3] for pixel in image.get_flattened_data() if pixel[3]}
            row[layer + "_bbox"] = list(box)
            row[layer + "_colours"] = len(colors)
        base = Image.new("RGBA", (256, 256), "#344b60")
        draw = ImageDraw.Draw(base)
        draw.line((20, 180, 245, 180), fill="#65809b", width=1)
        base.alpha_composite(current["body"], (64, 64))
        base.alpha_composite(current["weapon"])
        preview = base.resize((512, 512), Image.Resampling.NEAREST).convert("RGB")
        ImageDraw.Draw(preview).text((16, 18), PHASES[frame["phase"]], font=font, fill="#edf5ff")
        images.append(preview)
        for name, point in frame["attachment_points"].items():
            sockets[name][f"heavy_cut/{number:02}"] = {"position": point, "rotation": frame["weapon_rotation"]}
        frame_qa.append(row)
    for layer, paths in accepted.items():
        sheet, meta = pack_sheet({"heavy_cut": paths}, directory / "sprites", "hunter_" + layer,
                                (64, 116) if layer == "body" else (128, 180),
                                116 if layer == "body" else 180,
                                sockets if layer == "body" else None,
                                max_columns=8 if layer == "body" else 4)
        packed = json.loads(meta.read_text())
        for region, source in zip(packed["animations"]["heavy_cut"]["frames"], metadata["frames"]):
            region["duration"] = source["duration"] * 6
            region["phase"] = source["phase"]
        packed["weapon_canvas_offset"] = metadata["weapon_canvas_offset"]
        meta.write_text(json.dumps(packed, indent=2), encoding="utf-8")
        write_godot_spriteframes(meta, "res://" + sheet.relative_to(ROOT).as_posix(),
                                directory / "sprites" / f"hunter_{layer}_spriteframes.tres", fps=6)
    durations = [round(frame["duration"] * 1000) for frame in metadata["frames"]]
    images[0].save(directory / "heavy_cut_preview.gif", save_all=True, append_images=images[1:],
                   duration=durations, loop=0, disposal=2)
    columns = 5
    contact = Image.new("RGB", (columns * 256, math.ceil(len(images) / columns) * 276), "#203247")
    draw = ImageDraw.Draw(contact)
    for index, (image, frame) in enumerate(zip(images, metadata["frames"])):
        x, y = (index % columns) * 256, (index // columns) * 276
        contact.paste(image.resize((256, 256), Image.Resampling.NEAREST), (x, y))
        draw.text((x + 8, y + 254), f"{frame['source_frame']:02} · {PHASES[frame['phase']]}", font=small, fill="#edf5ff")
    contact.save(directory / "heavy_cut_contact.png")
    rig = Image.new("RGBA", (512, 512), "#344b60")
    rig.alpha_composite(load_rgba(directory / "rig_front.png"))
    draw = ImageDraw.Draw(rig)
    for name, bone in metadata["bones_front"].items():
        color = "#edc666" if name.endswith(".R") else ("#60dfbb" if name.endswith(".L") else "#ffffff")
        draw.line([tuple(bone["head"]), tuple(bone["tail"])], fill=color, width=2)
        x, y = bone["head"]
        draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=color)
    rig.convert("RGB").save(directory / "rig_skeleton.png")
    comparison = Image.new("RGB", (1024, 594), "#203247")
    draw = ImageDraw.Draw(comparison)
    labels = ["Texture gốc — trước", "Texture sạch — trước", "Texture gốc — ngang", "Texture sạch — ngang"]
    pairs = [("inspection", "front"), ("clean_inspection", "front"), ("inspection", "left"), ("clean_inspection", "left")]
    for index, ((folder, view), label) in enumerate(zip(pairs, labels)):
        draw.text((index * 256 + 8, 10), label, font=small, fill="#edf5ff")
        for y, resolution in ((42, 512), (332, 128)):
            tile = Image.new("RGBA", (256, 256), "#344b60")
            rendered = load_rgba(DIRECTORY / folder / f"{view}_{resolution}.png")
            tile.alpha_composite(rendered.resize((256, 256), Image.Resampling.NEAREST if resolution == 128 else Image.Resampling.LANCZOS))
            comparison.paste(tile.convert("RGB"), (index * 256, y))
    draw.text((12, 306), "Cùng khung 128 px — phóng to 2×", font=font, fill="#edf5ff")
    comparison.save(DIRECTORY / "clean_inspection/texture_before_after.png")
    report = {
        "frames": len(images), "duration_seconds": sum(frame["duration"] for frame in metadata["frames"]),
        "palette_colors": len(palette), "max_wrist_error_pixels": max(max(f["wrist_ik_error_pixels"].values()) for f in metadata["frames"]),
        "max_sole_vertical_error_pixels": max(f["sole_vertical_error_pixels"] for f in metadata["frames"]),
        "feet_boundary_rows": sorted({row["body_bbox"][3] for row in frame_qa}),
        "all_layers_inside_canvas": True, "frame_checks": frame_qa,
    }
    (directory / "review.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({key: value for key, value in report.items() if key != "frame_checks"}, indent=2), flush=True)


if __name__ == "__main__":
    main()
