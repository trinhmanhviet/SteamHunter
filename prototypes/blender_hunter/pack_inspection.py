"""Make a review sheet from actual Blender output, including locked-palette sprites."""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.character_factory import extract_palette, _map_to_palette


def main():
    directory = Path(__file__).resolve().parent / "inspection"
    names = ["front", "right", "back", "left"]
    labels = ["Truoc", "Hong phai", "Sau", "Hong trai"]
    with Image.open(directory / "front_512.png") as front:
        palette = extract_palette(front, 32)
    sheet = Image.new("RGB", (1024, 610), "#203247")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=18)
    draw.text((14, 10), "Model TRELLIS - render 3D", fill="#edf4f7", font=font)
    draw.text((14, 314), "Sprite 128 x 128 - 32 mau - phong to 2x", fill="#edf4f7", font=font)
    for index, (name, label) in enumerate(zip(names, labels)):
        with Image.open(directory / f"{name}_512.png") as source:
            view = source.convert("RGBA").resize((256, 256), Image.Resampling.LANCZOS)
        tile = Image.new("RGBA", (256, 256), "#344b60")
        tile.alpha_composite(view)
        sheet.paste(tile.convert("RGB"), (index * 256, 42))
        draw.text((index * 256 + 14, 282), label, fill="#edf4f7", font=font)
        with Image.open(directory / f"{name}_128.png") as source:
            sprite = source.convert("RGBA")
        sprite.putalpha(sprite.getchannel("A").point(lambda alpha: 255 if alpha >= 128 else 0))
        sprite = _map_to_palette(sprite, palette)
        sprite.save(directory / f"{name}_sprite_128.png")
        tile = Image.new("RGBA", (256, 256), "#344b60")
        tile.alpha_composite(sprite.resize((256, 256), Image.Resampling.NEAREST))
        sheet.paste(tile.convert("RGB"), (index * 256, 346))
    output = directory / "contact_sheet.png"
    sheet.save(output)
    print(output, flush=True)


if __name__ == "__main__":
    main()
