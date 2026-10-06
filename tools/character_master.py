"""Reference extraction helpers for the master-character stage of the asset factory."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

try:
	from tools.character_factory import visible_bbox
except ModuleNotFoundError:
	from character_factory import visible_bbox


def derive_reference_crops(master_path: Path, output_dir: Path, canvas: tuple[int, int] = (128, 128)) -> dict[str, Path]:
    """Create identity, equipment, and full-body references from one approved master."""
    with Image.open(master_path) as source:
        master = source.convert("RGBA")
    left, top, right, bottom = visible_bbox(master)
    height = bottom - top
    crops = {
        "identity": (left, top, right, min(bottom, top + round(height * 0.46))),
        "equipment": (left, top + round(height * 0.30), right, min(bottom, top + round(height * 0.78))),
        "full": (left, top, right, bottom),
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    outputs: dict[str, Path] = {}
    for name, region in crops.items():
        result = _center(master.crop(region), canvas)
        path = output_dir / f"{name}.png"
        result.save(path)
        outputs[name] = path
    return outputs


def _center(source: Image.Image, canvas: tuple[int, int]) -> Image.Image:
    result = Image.new("RGBA", canvas, (0, 0, 0, 0))
    scale = min(canvas[0] / source.width, canvas[1] / source.height)
    size = (max(1, round(source.width * scale)), max(1, round(source.height * scale)))
    centered = source.resize(size, Image.Resampling.NEAREST)
    result.alpha_composite(centered, ((canvas[0] - size[0]) // 2, (canvas[1] - size[1]) // 2))
    return result
