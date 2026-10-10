"""Pack fixed-camera 2D layers and build honest-time animation previews."""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from tools.character_factory import _map_to_palette
from prototypes.hunyuan_hunter.stylize_texture import PALETTE

DIRECTORY = ROOT / "prototypes/hunyuan_hunter/overhead_motion"
ASSETS = ROOT / "prototypes/overhead_demo/assets"
COLOURS = PALETTE + [(91, 117, 143), (174, 195, 209), (241, 249, 254),
                    (191, 145, 65), (105, 71, 35), (76, 48, 37)]
LABELS = {"ready": "Sẵn sàng", "raise": "Nâng kiếm", "hold": "Giữ charge",
          "strike": "Bổ xuống", "settle": "Theo đà", "recover": "Hồi thế"}
LENGTHS = {"raise": .2, "strike": .1, "settle": 1.1, "recover": .6, "hold": .4}


def main():
    ASSETS.mkdir(parents=True, exist_ok=True)
    data = json.loads((DIRECTORY / "render.json").read_text())
    count = len(data["frames"])
    sheets = {layer: Image.new("RGBA", (size * 8, size * ((count + 7) // 8)))
              for layer, size in (("body", 128), ("weapon", 384))}
    manifest = {"body_pivot": [64, 116], "weapon_pivot": [192, 244],
                "stages": {k: [n - 1 for n in v] for k, v in data["stages"].items()},
                "weapon_length_multiplier": data["weapon_length_multiplier"],
                "blade_local": data["frames"][0]["blade_local"],
                "frames": []}
    composite, bounds = {}, []
    for index, frame in enumerate(data["frames"]):
        layers, row = {}, {}
        for layer in sheets:
            im = Image.open(DIRECTORY / frame[layer]).convert("RGBA")
            im.putalpha(im.getchannel("A").point(lambda a: 255 if a >= 128 else 0))
            im = _map_to_palette(im, COLOURS)
            box = im.getbbox()
            if box is None or min(box[:2]) < 1 or box[2] >= im.width or box[3] >= im.height:
                raise RuntimeError(f"Clipped/empty {layer} frame {frame['frame']}: {box}")
            size = im.width
            region = [index % 8 * size, index // 8 * size, size, size]
            sheets[layer].paste(im, tuple(region[:2]))
            row[layer] = region
            layers[layer] = im
            bounds.append({"frame": frame["frame"], "layer": layer, "bbox": box})
        for name in ("blade_polygon", "weapon_origin", "weapon_angle"):
            row[name] = frame[name]
        manifest["frames"].append(row)
        tile = Image.new("RGBA", (384, 384), "#426078")
        ImageDraw.Draw(tile).line((0, 244, 384, 244), fill="#a6c5bf")
        tile.alpha_composite(layers["body"], (128, 128))
        tile.alpha_composite(layers["weapon"])
        composite[frame["frame"] - 1] = tile.convert("RGB")
    for layer, sheet in sheets.items():
        sheet.save(ASSETS / (layer + ".png"))
    (ASSETS / "frames.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 21)
    for name, loops in (("normal", 0), ("charge", 3)):
        timeline = [(0, .4, "ready")]
        for stage in ("raise", "hold", "strike", "settle", "recover"):
            if stage == "hold" and not loops:
                continue
            for _ in range(loops if stage == "hold" else 1):
                numbers = manifest["stages"][stage]
                timeline += [(n, LENGTHS[stage] / len(numbers), stage) for n in numbers]
        timeline.append((0, .4, "ready"))
        images, durations = [], []
        elapsed, previous_tick = 0.0, 0
        for n, length, stage in timeline:
            image = composite[n].resize((768, 768), Image.Resampling.NEAREST)
            ImageDraw.Draw(image).text((20, 22), LABELS[stage], font=font, fill="#f3f7ed")
            images.append(image)
            elapsed += length
            tick = round(elapsed * 100)
            durations.append((tick - previous_tick) * 10)
            previous_tick = tick
        images[0].save(DIRECTORY / f"{name}_preview.gif", save_all=True,
                       append_images=images[1:], duration=durations, loop=0, disposal=2)
    selected = [1, 4, 8, 22, 23, 27, 56, 62, 67, 74]
    board = Image.new("RGB", (1600, 690), "#263e50")
    draw = ImageDraw.Draw(board)
    for i, frame in enumerate(selected):
        x, y = i % 5 * 320, i // 5 * 345
        board.paste(composite[frame - 1].resize((320, 320), Image.Resampling.NEAREST), (x, y))
        draw.text((x + 10, y + 319), f"Pose {frame}", font=font, fill="#f3f7ed")
    board.save(DIRECTORY / "key_poses.png")
    report = {"frames": count, "normal_seconds": 2.0, "hold_loop_seconds": .4,
              "palette_size": len(COLOURS), "no_layer_clipping": True,
              "max_wrist_error_pixels": max(max(f["wrist_error_pixels"].values()) for f in data["frames"]),
              "atlas_sizes": {k: list(v.size) for k, v in sheets.items()}, "bounds": bounds}
    (DIRECTORY / "review.json").write_text(json.dumps(report, indent=2))
    print(json.dumps({k: v for k, v in report.items() if k != "bounds"}, indent=2))


if __name__ == "__main__":
    main()
