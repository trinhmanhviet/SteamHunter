"""Submit Shape/Paint graphs to the isolated Hunyuan ComfyUI service."""

import argparse
import json
import shutil
import time
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from hunyuan_comfy_workflow import shape_graph, paint_graph

ROOT = Path(__file__).resolve().parents[1]
COMFY_OUTPUT = ROOT / ".tools/comfy-hunyuan/output/hunyuan"
ARTIFACTS = ROOT / "prototypes/hunyuan_hunter"


def get_json(url):
    with urlopen(url, timeout=30) as response:
        return json.load(response)


def queue_and_wait(base_url, graph, stage, timeout):
    graphs = ARTIFACTS / "workflows"
    graphs.mkdir(parents=True, exist_ok=True)
    (graphs / f"{stage}_api.json").write_text(json.dumps(graph, indent=2), encoding="utf-8")
    request = Request(base_url + "/prompt", data=json.dumps({"prompt": graph, "client_id": "mist-and-iron-hunyuan"}).encode(),
                      headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urlopen(request, timeout=30) as response:
            payload = json.load(response)
    except HTTPError as error:
        raise RuntimeError(error.read().decode()) from error
    prompt_id = payload["prompt_id"]
    print(f"QUEUED {stage}: {prompt_id}", flush=True)
    (graphs / f"{stage}_job.json").write_text(json.dumps(payload, indent=2))
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        history = get_json(base_url + "/history/" + prompt_id).get(prompt_id)
        if history:
            status = history.get("status", {})
            if status.get("status_str") == "error" or status.get("completed"):
                (graphs / f"{stage}_history.json").write_text(json.dumps(history, indent=2), encoding="utf-8")
                if status.get("status_str") != "success":
                    raise RuntimeError(json.dumps(status.get("messages"), indent=2))
                return history
        time.sleep(1)
    raise TimeoutError(f"{stage} did not finish before timeout; job remains visible in ComfyUI")


def copy_latest(prefix, target):
    candidates = sorted(COMFY_OUTPUT.glob(prefix + "_*.glb"), key=lambda path: path.stat().st_mtime)
    if not candidates:
        raise RuntimeError(f"No mesh exported for {prefix}")
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(candidates[-1], target)
    return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stage", choices=("shape", "paint"))
    parser.add_argument("--url", default="http://127.0.0.1:8189")
    parser.add_argument("--timeout", type=float, default=1800)
    args = parser.parse_args()
    prepared = ARTIFACTS / "mesh/hunter_shape_prepared.glb"
    if args.stage == "paint" and not prepared.exists():
        raise RuntimeError("Run shape before paint")
    graph = shape_graph() if args.stage == "shape" else paint_graph(str(prepared.resolve()))
    history = queue_and_wait(args.url, graph, args.stage, args.timeout)
    if args.stage == "shape":
        copy_latest("shape_raw", ARTIFACTS / "mesh/hunter_shape_raw.glb")
        copy_latest("shape_prepared", prepared)
        print("SHAPE_READY " + str(prepared), flush=True)
    else:
        target = copy_latest("hunter_textured", ARTIFACTS / "mesh/hunter_textured.glb")
        output = ARTIFACTS / "paint"
        output.mkdir(parents=True, exist_ok=True)
        for filename in COMFY_OUTPUT.glob("*.png"):
            shutil.copyfile(filename, output / filename.name)
        print("TEXTURED_MESH_READY " + str(target), flush=True)


if __name__ == "__main__":
    main()
