"""Generate original, swappable pixel-art weapon assets with an explicit grip anchor."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


CANVAS = (192, 64)
GRIP = (28, 45)


def build_great_cleaver(output_dir: Path) -> dict[str, Path]:
    """Write the base Great Cleaver plus a recolorable skin contract."""
    output_dir.mkdir(parents=True, exist_ok=True)
    texture = _draw_great_cleaver()
    texture_path = output_dir / "great_cleaver_base.png"
    texture.save(texture_path)
    ember_path = output_dir / "great_cleaver_ember.png"
    _draw_great_cleaver(steel="#e4a264", highlight="#ffe2a8", shadow="#9c4538").save(ember_path)
    contract_path = output_dir / "great_cleaver_weapon.json"
    contract_path.write_text(json.dumps({
        "weapon": "great_cleaver",
        "canvas": list(CANVAS),
        "grip": list(GRIP),
        "anchor_name": "right_hand",
        "skins": {
            "base": texture_path.name,
            "ember": ember_path.name,
        },
    }, indent=2), encoding="utf-8")
    return {"texture": texture_path, "ember": ember_path, "contract": contract_path}


def _draw_great_cleaver(steel: str = "#a9d3e9", highlight: str = "#edf8ff", shadow: str = "#4e7596") -> Image.Image:
    """Draw a long, broad original blade in a limited bright palette."""
    image = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    outline = "#172338"
    dark = "#293a52"
    brass_dark = "#805331"
    brass = "#dcae58"
    leather = "#62343b"

    # Pommel, grip, and guard: the grip is intentionally at GRIP for hand attachment.
    draw.rectangle((8, 39, 20, 49), fill=outline)
    draw.rectangle((10, 40, 18, 47), fill=brass_dark)
    draw.rectangle((12, 40, 17, 45), fill=brass)
    draw.polygon([(18, 37), (38, 33), (43, 50), (23, 54)], fill=outline)
    draw.polygon([(21, 39), (35, 36), (39, 48), (25, 51)], fill=leather)
    draw.line((24, 40, 34, 48), fill="#b56857", width=2)
    draw.rectangle((35, 28, 48, 55), fill=outline)
    draw.rectangle((38, 30, 45, 53), fill=brass_dark)
    draw.rectangle((40, 31, 44, 52), fill=brass)

    # Long, heavy cleaver body. The oversized silhouette remains legible at 128px character scale.
    outer = [(44, 27), (160, 4), (186, 10), (190, 21), (171, 39), (68, 57), (45, 51)]
    draw.polygon(outer, fill=outline)
    blade = [(50, 30), (160, 9), (181, 13), (183, 20), (166, 34), (70, 52), (50, 48)]
    draw.polygon(blade, fill=shadow)
    mid = [(57, 31), (159, 12), (176, 15), (168, 29), (71, 47), (53, 44)]
    draw.polygon(mid, fill=steel)
    shine = [(73, 29), (158, 14), (168, 16), (100, 30), (61, 40)]
    draw.polygon(shine, fill=highlight)
    draw.line((67, 49, 167, 31), fill="#7195b5", width=2)
    draw.line((77, 24, 159, 9), fill="#d6edff", width=2)

    # Rivets and a notch keep the art from reading as a generic rectangle.
    draw.rectangle((47, 31, 53, 46), fill=dark)
    draw.rectangle((49, 34, 51, 42), fill=brass)
    draw.rectangle((121, 18, 126, 21), fill=outline)
    draw.rectangle((122, 18, 125, 19), fill=highlight)
    return image
