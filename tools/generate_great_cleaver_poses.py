"""Generate and pack the Great Cleaver hunter through the Character Asset Factory."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from character_factory import extract_palette, load_definition, normalize_frame, pack_sheet, qa_frame
from character_factory_workflow import generate_frame
from comfy_client import ComfyClient


ROOT = Path(__file__).resolve().parents[1]
CHARACTER_ROOT = ROOT / "art" / "characters" / "great_cleaver_hunter"


def main() -> None:
	definition = load_definition(CHARACTER_ROOT / "character.json")
	canvas = tuple(definition["sprite_size"])
	pivot = tuple(definition["pivot"])
	master = Image.open(CHARACTER_ROOT / "reference" / "master_side.png").convert("RGBA")
	palette = extract_palette(master, definition["palette_colors"])
	client = ComfyClient("http://127.0.0.1:8188", timeout_seconds=240)
	accepted: dict[str, list[Path]] = {}
	report: dict[str, dict] = {"character": definition["character"], "frames": {}}

	for animation, frames in definition["animations"].items():
		accepted[animation] = []
		for index, frame in enumerate(frames):
			frame_id = frame["frame"]
			references = [CHARACTER_ROOT / item for item in definition["references"]]
			references.append(CHARACTER_ROOT / frame["template"])
			for attempt in range(definition["max_retries"]):
				seed = 620941 + index * 100 + attempt
				prefix = f"factory/{definition['character']}/{animation}_{frame_id}_try{attempt + 1}"
				output = generate_frame(client, references, frame["pose"], seed, prefix)
				raw_path = CHARACTER_ROOT / "raw" / animation / f"{frame_id}_try{attempt + 1}.png"
				client.download_image(output, raw_path)
				with Image.open(raw_path) as raw:
					normalized = normalize_frame(raw, canvas, definition["target_height"], definition["ground_y"], palette)
				errors = qa_frame(normalized, definition["target_height"], definition["ground_y"], definition["palette_colors"], canvas)
				report["frames"][f"{animation}/{frame_id}"] = {"attempt": attempt + 1, "errors": errors, "raw": str(raw_path.relative_to(CHARACTER_ROOT))}
				if errors:
					continue
				frame_path = CHARACTER_ROOT / "frames" / animation / f"{frame_id}.png"
				frame_path.parent.mkdir(parents=True, exist_ok=True)
				normalized.save(frame_path)
				accepted[animation].append(frame_path)
				break
			else:
				raise RuntimeError(f"No accepted frame for {animation}/{frame_id}: {report['frames'][f'{animation}/{frame_id}']['errors']}")

	sprite_dir = CHARACTER_ROOT / "sprites"
	pack_sheet(accepted, sprite_dir, definition["character"], pivot, definition["ground_y"])
	_write_palette(palette, sprite_dir / f"{definition['character']}_palette.png")
	report_path = CHARACTER_ROOT / "reports" / f"{definition['character']}_qa.json"
	report_path.parent.mkdir(parents=True, exist_ok=True)
	report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")


def _write_palette(palette: list[tuple[int, int, int]], path: Path) -> None:
	image = Image.new("RGBA", (max(1, len(palette)) * 8, 8), (0, 0, 0, 0))
	for index, color in enumerate(palette):
		for x in range(index * 8, index * 8 + 8):
			for y in range(8):
				image.putpixel((x, y), (*color, 255))
	path.parent.mkdir(parents=True, exist_ok=True)
	image.save(path)


if __name__ == "__main__":
	main()
