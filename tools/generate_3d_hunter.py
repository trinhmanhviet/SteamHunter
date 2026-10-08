"""Create a coloured mesh from an ImageGen master using isolated official TRELLIS.

Run with .tools/trellis-env/Scripts/python.exe, not ComfyUI's embedded interpreter.
This first experiment exports vertex colour instead of Gaussian texture baking.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODEL_REPO = "microsoft/TRELLIS-image-large"
REQUIRED_MODELS = {
    "sparse_structure_decoder", "sparse_structure_flow_model",
    "slat_decoder_mesh", "slat_flow_model",
}


def download_models(model_dir: Path) -> None:
    from huggingface_hub import HfApi, hf_hub_download

    model_dir.mkdir(parents=True, exist_ok=True)
    revision_file = model_dir / "upstream_revision.json"
    if revision_file.exists():
        revision = json.loads(revision_file.read_text())["revision"]
    else:
        revision = HfApi().model_info(MODEL_REPO).sha
        revision_file.write_text(json.dumps({"repo": MODEL_REPO, "revision": revision}, indent=2))
    upstream_file = hf_hub_download(MODEL_REPO, "pipeline.json", revision=revision)
    config = json.loads(Path(upstream_file).read_text())
    (model_dir / "upstream_pipeline.json").write_text(json.dumps(config, indent=2))
    config["args"]["models"] = {
        name: value for name, value in config["args"]["models"].items() if name in REQUIRED_MODELS
    }
    for name, checkpoint in config["args"]["models"].items():
        for extension in ("json", "safetensors"):
            filename = f"{checkpoint}.{extension}"
            print(f"DOWNLOAD {name}: {filename}", flush=True)
            hf_hub_download(MODEL_REPO, filename, local_dir=model_dir, revision=revision)
    (model_dir / "pipeline.json").write_text(json.dumps(config, indent=2))


def generate(input_path: Path, output_dir: Path, model_dir: Path, seed: int, steps: int) -> Path:
    import numpy as np
    import torch
    import trimesh
    from PIL import Image
    from trellis.pipelines import TrellisImageTo3DPipeline

    if not torch.cuda.is_available():
        raise RuntimeError("TRELLIS requires CUDA; no CUDA device is available")
    free, total = torch.cuda.mem_get_info()
    if free < 16 * 1024 ** 3:
        raise RuntimeError(f"Insufficient free VRAM: {free / 1024**3:.1f} GiB; free 16 GiB before generating")
    output_dir.mkdir(parents=True, exist_ok=True)
    started = time.perf_counter()
    print(f"CUDA {torch.cuda.get_device_name()}; free {free / 1024**3:.1f}/{total / 1024**3:.1f} GiB", flush=True)
    print("LOAD TRELLIS and DINOv2", flush=True)
    pipeline = TrellisImageTo3DPipeline.from_pretrained(str(model_dir))
    pipeline.cuda()
    with Image.open(input_path) as image:
        # The selected white-background image must pass through upstream rembg.
        input_image = image.convert("RGB")
        print("GENERATE coloured mesh", flush=True)
        output = pipeline.run(
            input_image, seed=seed, formats=["mesh"],
            sparse_structure_sampler_params={"steps": steps},
            slat_sampler_params={"steps": steps},
        )
    mesh = output["mesh"][0]
    if not mesh.success or mesh.vertex_attrs is None:
        raise RuntimeError("TRELLIS did not produce a valid coloured mesh")
    vertices = mesh.vertices.detach().float().cpu().numpy()
    faces = mesh.faces.detach().cpu().numpy()
    rgb = mesh.vertex_attrs[:, :3].detach().float().cpu().numpy()
    colours = np.concatenate((np.clip(rgb, 0, 1) * 255, np.full((len(rgb), 1), 255)), axis=1).astype(np.uint8)
    exported = trimesh.Trimesh(vertices=vertices, faces=faces, vertex_colors=colours, process=False)
    target = output_dir / "hunter_trellis_vertexcolor.glb"
    exported.export(target)
    source_revision = subprocess.check_output(
        ["git", "-C", str(ROOT / ".tools/trellis-official"), "rev-parse", "HEAD"], text=True,
    ).strip()
    report = {
        "input": str(input_path.relative_to(ROOT)), "generator": MODEL_REPO,
        "trellis_revision": source_revision,
        "model_revision": json.loads((model_dir / "upstream_revision.json").read_text())["revision"],
        "seed": seed, "steps": steps, "vertices": len(vertices), "triangles": len(faces),
        "bounds": exported.bounds.tolist(), "elapsed_seconds": round(time.perf_counter() - started, 2),
        "appearance": "mesh-decoder vertex colours; no baked texture", "rigged": False,
        "output": target.name,
    }
    (output_dir / "generation.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"MESH {target}; {len(vertices)} vertices, {len(faces)} triangles", flush=True)
    return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=ROOT / "prototypes/blender_hunter/reference/master_apose_imagegen.png")
    parser.add_argument("--output", type=Path, default=ROOT / "prototypes/blender_hunter/mesh")
    parser.add_argument("--seed", type=int, default=834625)
    parser.add_argument("--steps", type=int, default=25)
    parser.add_argument("--prepare-only", action="store_true")
    args = parser.parse_args()
    source = ROOT / ".tools/trellis-official"
    if not (source / "trellis").is_dir():
        raise RuntimeError(f"Official TRELLIS source missing: {source}")
    sys.path.insert(0, str(source))
    os.environ.setdefault("ATTN_BACKEND", "xformers")
    os.environ.setdefault("SPCONV_ALGO", "native")
    os.environ.setdefault("HF_HOME", str(ROOT / ".tools/huggingface"))
    os.environ.setdefault("TORCH_HOME", str(ROOT / ".tools/torch-cache"))
    os.environ.setdefault("U2NET_HOME", str(ROOT / ".tools/rembg-cache"))
    os.environ.setdefault("NUMBA_CACHE_DIR", str(ROOT / ".tools/numba-cache"))
    os.environ.setdefault("WARP_CACHE_PATH", str(ROOT / ".tools/warp-cache"))
    model_dir = ROOT / ".tools/trellis-models/image-large-mesh"
    download_models(model_dir)
    if not args.prepare_only:
        generate(args.input.resolve(), args.output.resolve(), model_dir, args.seed, args.steps)


if __name__ == "__main__":
    main()
