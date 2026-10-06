"""Generic execution layer for Character Asset Factory definitions."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

try:
	from tools.character_factory import extract_palette, load_definition, normalize_frame, pack_sheet, qa_frame, write_godot_spriteframes, write_preview
	from tools.character_factory_workflow import generate_frame
except ModuleNotFoundError:
	from character_factory import extract_palette, load_definition, normalize_frame, pack_sheet, qa_frame, write_godot_spriteframes, write_preview
	from character_factory_workflow import generate_frame


def run_factory(definition_path: Path, client, generate=generate_frame) -> dict[str, Path]:
	"""Generate every manifest frame, retry failed QA, then package Godot exports."""
	definition_path = definition_path.resolve()
	root = definition_path.parent
	definition = load_definition(definition_path)
	asset_role = str(definition.get("asset_role", "body"))
	canvas = tuple(definition["sprite_size"])
	pivot = tuple(definition["pivot"])
	master_path = root / definition["references"][0]
	with Image.open(master_path) as master:
		palette = extract_palette(master, definition["palette_colors"])
	accepted: dict[str, list[Path]] = {}
	report: dict[str, object] = {"character": definition["character"], "frames": {}}

	for animation, frames in definition["animations"].items():
		accepted[animation] = []
		for frame_index, frame in enumerate(frames):
			frame_id = frame["frame"]
			references = [root / item for item in definition["references"]]
			references.append(root / frame["template"])
			frame_key = f"{animation}/{frame_id}"
			for attempt in range(definition.get("max_retries", 3)):
				seed = int(definition.get("seed", 620941)) + frame_index * 100 + attempt
				prefix = f"factory/{definition['character']}/{animation}_{frame_id}_try{attempt + 1}"
				output = generate(client, references, frame["pose"], seed, prefix, asset_role)
				raw_path = root / "raw" / animation / f"{frame_id}_try{attempt + 1}.png"
				client.download_image(output, raw_path)
				with Image.open(raw_path) as raw:
					normalized = normalize_frame(raw, canvas, definition["target_height"], definition["ground_y"], palette)
				errors = qa_frame(normalized, definition["target_height"], definition["ground_y"], definition["palette_colors"], canvas)
				report["frames"][frame_key] = {"attempt": attempt + 1, "errors": errors, "raw": str(raw_path.relative_to(root))}
				if errors:
					continue
				frame_path = root / "frames" / animation / f"{frame_id}.png"
				frame_path.parent.mkdir(parents=True, exist_ok=True)
				normalized.save(frame_path)
				accepted[animation].append(frame_path)
				break
			else:
				raise RuntimeError(f"No accepted frame for {frame_key}: {report['frames'][frame_key]['errors']}")

	sprite_dir = root / "sprites"
	sheet_path, metadata_path = pack_sheet(
		accepted,
		sprite_dir,
		definition["character"],
		pivot,
		definition["ground_y"],
		definition.get("attachment_points"),
	)
	palette_path = sprite_dir / f"{definition['character']}_palette.png"
	_write_palette(palette, palette_path)
	report_path = root / "reports" / f"{definition['character']}_qa.json"
	report_path.parent.mkdir(parents=True, exist_ok=True)
	report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
	texture_resource_path = _to_resource_path(sheet_path)
	spriteframes_path = sprite_dir / f"{definition['character']}_spriteframes.tres"
	write_godot_spriteframes(metadata_path, texture_resource_path, spriteframes_path, fps=float(definition.get("fps", 6)))
	preview_path = write_preview(sheet_path, sprite_dir / f"{definition['character']}_spritesheet_preview.png")
	return {"sheet": sheet_path, "metadata": metadata_path, "palette": palette_path, "report": report_path, "spriteframes": spriteframes_path, "preview": preview_path}


def _write_palette(palette: list[tuple[int, int, int]], path: Path) -> None:
	image = Image.new("RGBA", (max(1, len(palette)) * 8, 8), (0, 0, 0, 0))
	for index, color in enumerate(palette):
		for x in range(index * 8, index * 8 + 8):
			for y in range(8):
				image.putpixel((x, y), (*color, 255))
	path.parent.mkdir(parents=True, exist_ok=True)
	image.save(path)


def _to_resource_path(path: Path) -> str:
	parts = path.resolve().parts
	try:
		art_index = parts.index("art")
	except ValueError as error:
		raise ValueError(f"asset must live below an art directory: {path}") from error
	return "res://" + "/".join(parts[art_index:])
