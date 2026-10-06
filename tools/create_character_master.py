"""Create an approved master and derived reference layers for a Character Asset Factory manifest."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from character_factory_workflow import build_master_workflow
from character_master import derive_reference_crops
from comfy_client import ComfyClient


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate a master sprite and its reusable reference layers.")
    parser.add_argument("definition", type=Path, help="Path to character.json")
    parser.add_argument("--prompt", help="Overrides the manifest master_prompt")
    parser.add_argument("--seed", type=int)
    parser.add_argument("--comfy-url", default="http://127.0.0.1:8188")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    definition_path = args.definition.resolve()
    definition = json.loads(definition_path.read_text(encoding="utf-8"))
    prompt = args.prompt or definition.get("master_prompt")
    if not prompt:
        raise ValueError("master_prompt")
    seed = args.seed if args.seed is not None else int(definition.get("seed", 620941))
    root = definition_path.parent
    client = ComfyClient(args.comfy_url, timeout_seconds=600)
    output = client.queue_and_wait(build_master_workflow(prompt, seed, f"factory/{definition['character']}/master_side"))
    master = client.download_image(output, root / "reference" / "master_side.png")
    outputs = derive_reference_crops(master, root / "reference")
    print(f"master: {master}")
    for name, path in outputs.items():
        print(f"{name}: {path}")


if __name__ == "__main__":
    main()
