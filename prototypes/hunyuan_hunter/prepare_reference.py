"""Create the foreground mask used by Hunyuan without changing the ImageGen master."""

import os
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
cache = ROOT / ".tools/hunyuan-rembg"
cache.mkdir(parents=True, exist_ok=True)
os.environ["U2NET_HOME"] = str(cache)
os.environ["NUMBA_CACHE_DIR"] = str(ROOT / ".tools/hunyuan-numba")
previous_weight = ROOT / ".tools/rembg-cache/u2net.onnx"
if previous_weight.exists() and not (cache / "u2net.onnx").exists():
    shutil.copyfile(previous_weight, cache / "u2net.onnx")

from PIL import Image
from rembg import new_session, remove

source = ROOT / "prototypes/blender_hunter/reference/master_apose_imagegen.png"
target = Path(__file__).resolve().parent / "reference/master_cutout.png"
target.parent.mkdir(parents=True, exist_ok=True)
with Image.open(source) as image:
    output = remove(image.convert("RGB"), session=new_session("u2net", providers=["CPUExecutionProvider"]))
    output.save(target)
foreground = output.crop(output.getchannel("A").getbbox())
scale = 435 / max(foreground.size)
size = (round(foreground.width * scale), round(foreground.height * scale))
foreground = foreground.resize(size, Image.Resampling.LANCZOS)
square = Image.new("RGBA", (512, 512), (255, 255, 255, 0))
square.alpha_composite(foreground, ((512 - size[0]) // 2, (512 - size[1]) // 2))
square.save(target.parent / "model_input_square.png")
input_dir = ROOT / ".tools/comfy-hunyuan/input"
input_dir.mkdir(parents=True, exist_ok=True)
shutil.copyfile(target.parent / "model_input_square.png", input_dir / "hunter_imagegen_cutout.png")
print("CUTOUT_READY " + str(target), flush=True)
