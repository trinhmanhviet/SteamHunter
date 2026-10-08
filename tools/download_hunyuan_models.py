"""Fetch pinned Shape/Paint 2.0 weights into the isolated Hunyuan ComfyUI tree."""

import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
os.environ.setdefault("HF_HOME", str(ROOT / ".tools/hunyuan-hf"))
os.environ.setdefault("HF_HUB_DISABLE_SYMLINKS_WARNING", "1")

from huggingface_hub import HfApi, hf_hub_download, snapshot_download


def main():
    target = ROOT / "prototypes/hunyuan_hunter"
    target.mkdir(parents=True, exist_ok=True)
    record_path = target / "model_revisions.json"
    if record_path.exists():
        record = json.loads(record_path.read_text())
    else:
        api = HfApi()
        record = {repo: api.model_info(repo).sha for repo in (
            "Kijai/Hunyuan3D-2_safetensors", "tencent/Hunyuan3D-2",
        )}
        record_path.write_text(json.dumps(record, indent=2), encoding="utf-8")
    models = ROOT / ".tools/comfy-hunyuan/models"
    print("DOWNLOAD shape FP16", flush=True)
    hf_hub_download(
        "Kijai/Hunyuan3D-2_safetensors", "hunyuan3d-dit-v2-0-fp16.safetensors",
        revision=record["Kijai/Hunyuan3D-2_safetensors"], local_dir=models / "diffusion_models",
    )
    print("DOWNLOAD full Paint 2.0", flush=True)
    snapshot_download(
        "tencent/Hunyuan3D-2", revision=record["tencent/Hunyuan3D-2"],
        allow_patterns=["hunyuan3d-paint-v2-0/**"],
        ignore_patterns=["*/unet/diffusion_pytorch_model.bin", "*/vae/diffusion_pytorch_model.bin", "*image_encoder*"],
        local_dir=models / "diffusers", max_workers=4,
    )
    print("MODELS_READY", flush=True)


if __name__ == "__main__":
    main()
