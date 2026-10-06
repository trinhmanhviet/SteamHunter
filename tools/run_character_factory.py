"""Run a Character Asset Factory manifest against the local ComfyUI server."""

from __future__ import annotations

import argparse
from pathlib import Path

from character_factory_runner import run_factory
from comfy_client import ComfyClient


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate and package a character asset manifest.")
    parser.add_argument("definition", type=Path, help="Path to character.json")
    parser.add_argument("--comfy-url", default="http://127.0.0.1:8188")
    parser.add_argument("--timeout", type=float, default=600.0)
    return parser


def main() -> None:
    args = build_parser().parse_args()
    output = run_factory(args.definition, ComfyClient(args.comfy_url, timeout_seconds=args.timeout))
    for label, path in output.items():
        print(f"{label}: {path}")


if __name__ == "__main__":
    main()
