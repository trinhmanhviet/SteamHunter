"""Build stable pixel-character assets from locked reference material."""

from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

from PIL import Image


REQUIRED_DEFINITION_FIELDS = (
	"character",
	"sprite_size",
	"ground_y",
	"pivot",
	"palette_colors",
	"animations",
)


def load_definition(path: Path) -> dict:
	"""Load a character definition and reject incomplete asset contracts."""
	definition = json.loads(path.read_text(encoding="utf-8"))
	for field in REQUIRED_DEFINITION_FIELDS:
		if field not in definition:
			raise ValueError(field)
	return definition


def visible_bbox(image: Image.Image) -> tuple[int, int, int, int]:
	"""Return the exclusive RGBA bounds of the visible figure."""
	alpha = image.convert("RGBA").getchannel("A")
	bbox = alpha.getbbox()
	if bbox is None:
		raise ValueError("empty frame")
	return bbox


def extract_palette(image: Image.Image, limit: int) -> list[tuple[int, int, int]]:
	"""Return the master image's most frequent opaque colors in deterministic order."""
	if limit < 1:
		raise ValueError("palette limit must be positive")
	colors = Counter(pixel[:3] for pixel in image.convert("RGBA").get_flattened_data() if pixel[3] >= 128)
	if not colors:
		raise ValueError("cannot extract a palette from an empty image")
	if len(colors) > limit * 2:
		grouped: Counter[tuple[int, int, int]] = Counter()
		for color, count in colors.items():
			bucket = tuple(min(255, (channel // 16) * 16 + 8) for channel in color)
			grouped[bucket] += count
		colors = grouped
	return [color for color, _ in colors.most_common(limit)]


def normalize_frame(
	source: Image.Image,
	canvas: tuple[int, int],
	target_height: int,
	ground_y: int,
	palette: list[tuple[int, int, int]],
) -> Image.Image:
	"""Center a character, lock its ground line, and map it to a master palette."""
	image = source.convert("RGBA")
	bbox = visible_bbox(image)
	cropped = image.crop(bbox)
	scale = target_height / cropped.height
	width = max(1, round(cropped.width * scale))
	scaled = cropped.resize((width, target_height), Image.Resampling.NEAREST)
	quantized = _map_to_palette(scaled, palette)
	result = Image.new("RGBA", canvas, (0, 0, 0, 0))
	result.alpha_composite(quantized, ((canvas[0] - width) // 2, ground_y - target_height + 1))
	return result


def _map_to_palette(image: Image.Image, palette: list[tuple[int, int, int]]) -> Image.Image:
	if not palette:
		raise ValueError("palette must not be empty")
	result = Image.new("RGBA", image.size, (0, 0, 0, 0))
	for y in range(image.height):
		for x in range(image.width):
			r, g, b, a = image.getpixel((x, y))
			if a == 0:
				continue
			color = min(palette, key=lambda candidate: (r - candidate[0]) ** 2 + (g - candidate[1]) ** 2 + (b - candidate[2]) ** 2)
			result.putpixel((x, y), (*color, a))
	return result


def qa_frame(image: Image.Image, target_height: int, ground_y: int, palette_colors: int, canvas: tuple[int, int] = (128, 128)) -> list[str]:
	"""Return machine-readable reasons an art frame cannot enter a sprite sheet."""
	errors: list[str] = []
	frame = image.convert("RGBA")
	if frame.size != canvas:
		errors.append("wrong canvas size")
	try:
		bbox = visible_bbox(frame)
	except ValueError:
		return [*errors, "empty frame"]
	if abs((bbox[3] - bbox[1]) - target_height) > 2:
		errors.append("character height outside tolerance")
	if abs(bbox[3] - (ground_y + 1)) > 2:
		errors.append("feet outside ground tolerance")
	if bbox[0] == 0 or bbox[1] == 0 or bbox[2] == frame.width or bbox[3] == frame.height:
		errors.append("alpha touches canvas border")
	colors = {pixel[:3] for pixel in frame.get_flattened_data() if pixel[3] > 0}
	if len(colors) > palette_colors:
		errors.append("palette exceeds limit")
	return errors


def pack_sheet(
	animations: dict[str, list[Path]],
	output_dir: Path,
	character: str,
	pivot: tuple[int, int],
	ground_y: int,
	attachment_points: dict | None = None,
) -> tuple[Path, Path]:
	"""Pack ordered RGBA frames into one row and write Godot-friendly region metadata."""
	frames = [(animation, path) for animation, paths in animations.items() for path in paths]
	if not frames:
		raise ValueError("no frames to pack")
	first = Image.open(frames[0][1]).convert("RGBA")
	frame_width, frame_height = first.size
	sheet = Image.new("RGBA", (frame_width * len(frames), frame_height), (0, 0, 0, 0))
	metadata = {
		"character": character,
		"frame_size": [frame_width, frame_height],
		"pivot": list(pivot),
		"ground_y": ground_y,
		"attachment_points": attachment_points or {},
		"animations": {name: {"frames": []} for name in animations},
	}
	for index, (animation, path) in enumerate(frames):
		image = Image.open(path).convert("RGBA")
		if image.size != (frame_width, frame_height):
			raise ValueError(f"frame size mismatch: {path}")
		x = index * frame_width
		sheet.alpha_composite(image, (x, 0))
		metadata["animations"][animation]["frames"].append({"x": x, "y": 0, "w": frame_width, "h": frame_height})
	output_dir.mkdir(parents=True, exist_ok=True)
	sheet_path = output_dir / f"{character}_spritesheet.png"
	metadata_path = output_dir / f"{character}_animations.json"
	sheet.save(sheet_path)
	metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")
	return sheet_path, metadata_path


def write_godot_spriteframes(metadata_path: Path, texture_resource_path: str, output_path: Path, fps: float = 6.0) -> Path:
	"""Write a Godot SpriteFrames resource from packed-region metadata."""
	metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
	subresources: list[str] = []
	animations: list[str] = []
	for animation, details in metadata["animations"].items():
		frame_resources: list[str] = []
		for index, frame in enumerate(details["frames"]):
			resource_id = f"Atlas_{animation}_{index}"
			subresources.extend((
				f'[sub_resource type="AtlasTexture" id="{resource_id}"]',
				'atlas = ExtResource("1_sheet")',
				f'region = Rect2({frame["x"]}, {frame["y"]}, {frame["w"]}, {frame["h"]})',
				"",
			))
			frame_resources.append('{"duration": 1.0, "texture": SubResource("%s")}' % resource_id)
		loop = "true" if animation in {"idle", "walk", "run"} else "false"
		animations.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": %s}' % (", ".join(frame_resources), loop, animation, fps))
	output_path.parent.mkdir(parents=True, exist_ok=True)
	content = "\n".join((
		f'[gd_resource type="SpriteFrames" load_steps={len(subresources) // 4 + 2} format=3]',
		"",
		f'[ext_resource type="Texture2D" path="{texture_resource_path}" id="1_sheet"]',
		"",
		*subresources,
		"[resource]",
		"animations = [" + ", ".join(animations) + "]",
		"",
	))
	output_path.write_text(content, encoding="utf-8")
	return output_path


def write_preview(sheet_path: Path, output_path: Path, scale: int = 4) -> Path:
	"""Render a checker-backed nearest-neighbor preview for quick visual review."""
	if scale < 1:
		raise ValueError("preview scale must be positive")
	with Image.open(sheet_path) as source:
		sheet = source.convert("RGBA")
	preview = Image.new("RGBA", sheet.size, "#60758d")
	for y in range(0, sheet.height, 16):
		for x in range(0, sheet.width, 16):
			if (x // 16 + y // 16) % 2:
				preview.paste("#536a83", (x, y, x + 16, y + 16))
	preview.alpha_composite(sheet)
	output_path.parent.mkdir(parents=True, exist_ok=True)
	preview.resize((preview.width * scale, preview.height * scale), Image.Resampling.NEAREST).convert("RGB").save(output_path)
	return output_path
