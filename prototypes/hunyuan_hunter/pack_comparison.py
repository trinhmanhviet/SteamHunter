"""Pack real Hunyuan renders and compare both generators using one master palette."""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.character_factory import _map_to_palette

DIRECTORY = Path(__file__).resolve().parent
DESIGN_PALETTE = [
    (20, 27, 43), (27, 41, 65), (41, 56, 81), (61, 77, 106),
    (55, 32, 31), (90, 52, 43), (133, 87, 65),
    (94, 34, 26), (126, 45, 33), (163, 57, 37), (197, 72, 39), (226, 100, 53), (242, 139, 75),
    (168, 100, 66), (218, 148, 98), (241, 181, 128), (255, 217, 167), (255, 235, 206),
    (137, 86, 26), (185, 120, 33), (226, 160, 49), (251, 199, 84), (255, 224, 137),
    (173, 138, 96), (226, 199, 151), (254, 237, 200),
    (44, 72, 106), (62, 96, 141), (94, 134, 183), (145, 180, 217), (191, 217, 239), (231, 244, 253),
]


def sprite_from(path, palette):
    with Image.open(path) as image:
        sprite = image.convert("RGBA")
    sprite.putalpha(sprite.getchannel("A").point(lambda value: 255 if value >= 128 else 0))
    return _map_to_palette(sprite, palette)


def tile(image, size=256):
    canvas = Image.new("RGBA", (size, size), "#344b60")
    canvas.alpha_composite(image.resize((size, size), Image.Resampling.NEAREST))
    return canvas.convert("RGB")


def main():
    # Reserve colours for every design material instead of allowing the large
    # coat area to crowd hair/skin colours out of a frequency-only palette.
    palette = DESIGN_PALETTE
    font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", size=18)
    sheet = Image.new("RGB", (1024, 614), "#203247")
    draw = ImageDraw.Draw(sheet)
    draw.text((14, 10), "Hunyuan3D-2: Shape + Paint, texture 2048px", fill="#edf4f7", font=font)
    draw.text((14, 314), "Sprite 128 × 128 — bảng 32 màu theo thiết kế ImageGen", fill="#edf4f7", font=font)
    labels = ["Trước", "Hông phải", "Sau", "Hông trái"]
    for index, (view, label) in enumerate(zip(("front", "right", "back", "left"), labels)):
        with Image.open(DIRECTORY / f"inspection/{view}_512.png") as source:
            image = source.convert("RGBA").resize((256, 256), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (256, 256), "#344b60")
        canvas.alpha_composite(image)
        sheet.paste(canvas.convert("RGB"), (index * 256, 42))
        draw.text((index * 256 + 14, 282), label, fill="#edf4f7", font=font)
        sprite = sprite_from(DIRECTORY / f"inspection/{view}_128.png", palette)
        sprite.save(DIRECTORY / f"inspection/{view}_sprite_128.png")
        sheet.paste(tile(sprite), (index * 256, 346))
    sheet.save(DIRECTORY / "inspection/contact_sheet.png")
    comparison = Image.new("RGB", (1024, 640), "#203247")
    draw = ImageDraw.Draw(comparison)
    draw.text((14, 10), "Ảnh render gốc: TRELLIS màu trên mesh / Hunyuan Shape + Paint", fill="#edf4f7", font=font)
    draw.text((14, 340), "Cùng khung 128 px, cao 104 px và bảng 32 màu — phóng to 2×", fill="#edf4f7", font=font)
    paths = [
        ROOT / "prototypes/blender_hunter/inspection/front_128.png",
        DIRECTORY / "inspection/front_128.png",
        ROOT / "prototypes/blender_hunter/inspection/left_128.png",
        DIRECTORY / "inspection/left_128.png",
    ]
    names = ["TRELLIS — trước", "Hunyuan — trước", "TRELLIS — ngang", "Hunyuan — ngang"]
    for index, (path, name) in enumerate(zip(paths, names)):
        draw.text((index * 256 + 12, 38), name, fill="#edf4f7", font=font)
        with Image.open(path) as source:
            comparison.paste(tile(source.convert("RGBA")), (index * 256, 68))
        comparison.paste(tile(sprite_from(path, palette)), (index * 256, 372))
    comparison.save(DIRECTORY / "inspection/trellis_hunyuan_comparison.png")
    (DIRECTORY / "inspection/palette.json").write_text(json.dumps(palette, indent=2), encoding="utf-8")
    print("COMPARISON_READY " + str(DIRECTORY / "inspection/trellis_hunyuan_comparison.png"), flush=True)


if __name__ == "__main__":
    main()
