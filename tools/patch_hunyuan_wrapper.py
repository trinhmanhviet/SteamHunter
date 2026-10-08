"""Fix wrapper dynamic imports for ComfyUI's escaped path module namespace."""

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WRAPPER = ROOT / ".tools/comfy-hunyuan/custom_nodes/ComfyUI-Hunyuan3DWrapper"
TARGET = WRAPPER / "hy3dgen/shapegen/pipelines.py"

OLD = '''def get_obj_from_str(string, reload=False):
    module, cls = string.rsplit(".", 1)
    if reload:
        module_imp = importlib.import_module(module)
        importlib.reload(module_imp)
    try:
        obj = getattr(importlib.import_module(module, package=os.path.basename(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))), cls)
    except:
        obj = getattr(importlib.import_module(module, package=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath( __file__ ))))), cls)
    return obj'''

NEW = '''def get_obj_from_str(string, reload=False):
    module, cls = string.rsplit(".", 1)
    # ComfyUI 0.3.40 registers custom nodes under an escaped filesystem namespace.
    # Use the actual Python package instead of reconstructing a raw directory name.
    wrapper_package = __package__.split(".hy3dgen", 1)[0]
    module_imp = importlib.import_module(module, package=wrapper_package)
    if reload:
        importlib.reload(module_imp)
    return getattr(module_imp, cls)'''

source = TARGET.read_text(encoding="utf-8")
if OLD in source:
    TARGET.write_text(source.replace(OLD, NEW), encoding="utf-8")
elif NEW not in source:
    raise RuntimeError("Wrapper changed: inspect get_obj_from_str before patching")
destination = ROOT / "prototypes/hunyuan_hunter/patches/wrapper_namespace.patch"
destination.parent.mkdir(parents=True, exist_ok=True)
diff = subprocess.check_output(["git", "-C", str(WRAPPER), "diff", "--", "hy3dgen/shapegen/pipelines.py"], text=True)
destination.write_text(diff, encoding="utf-8")
print("PATCHED_NAMESPACE " + str(TARGET))
