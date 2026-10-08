# Hunyuan3D-2 Shape + Paint comparison

This experiment uses the same ChatGPT ImageGen hunter master as the TRELLIS trial, with a square padded input so the Hunyuan wrapper's DINO centre crop cannot remove the head/boots. It generates actual shape and full Paint 2.0 texture, not vertex colour alone.

## Results

- `reference/master_cutout.png`: full original design with a foreground alpha mask.
- `reference/model_input_square.png`: 512px square input, full figure occupying 85% of the height.
- `mesh/hunter_shape_raw.glb`: original high-resolution generated mesh.
- `mesh/hunter_shape_prepared.glb`: 45,000-triangle mesh prepared for UV/texturing.
- `mesh/hunter_textured.glb`: full GLB with UVs and a 2048px base-colour texture.
- `shape_inspection/`: untextured anatomy views.
- `paint/`: six generated views, normal controls and final UV atlas.
- `inspection/contact_sheet.png`: four textured views and 128px palette-limited samples.
- `inspection/trellis_hunyuan_comparison.png`: prior TRELLIS and new Hunyuan renders, then both mapped to the same 32-colour design palette.
- `inspection/hunter_inspection.blend`: model with flat texture preview shaders and the comparison camera.
- `workflows/`: the exact ComfyUI API graphs, job IDs and completion history.

The upper comparison uses the prior TRELLIS vertex-colour export and the full Hunyuan texture. It compares the two experiments that actually ran; it is not a benchmark of fully textured TRELLIS versus Hunyuan.

## Isolated server

ComfyUI is under `.tools/comfy-hunyuan`. Python is `.tools/hunyuan-env/Scripts/python.exe`, with system site packages disabled. The server listens only on `http://127.0.0.1:8189`. Existing ComfyUI on 8188 and the TRELLIS environment were not changed.

- ComfyUI 0.3.40: `866f6cdab4bd5de95ee6296d1b418c455f67f929`.
- Hunyuan wrapper: `2609efa38f6a98292476f714839b7c1e5f9b699a`.
- Torch 2.6.0+cu126, Python 3.12.10, Transformers 4.51.3, Diffusers 0.33.1.
- Dependencies are captured in `requirements-hunyuan.lock`; model revisions are in `model_revisions.json`.
- Models are cached in the separate ComfyUI tree; HF/Torch/rembg caches are project-local Hunyuan directories.

When the server is stopped, start it with:

```powershell
.\tools\start_hunyuan_comfy.ps1
```

This launch script opens no browser. Its process record and logs are under `.tools/hunyuan-session`.

## Reproduce

```powershell
.\.tools\hunyuan-env\Scripts\python.exe tools\download_hunyuan_models.py
.\.tools\hunyuan-env\Scripts\python.exe prototypes\hunyuan_hunter\prepare_reference.py
.\.tools\hunyuan-env\Scripts\python.exe tools\run_hunyuan_comfy.py shape
.\.tools\hunyuan-env\Scripts\python.exe tools\run_hunyuan_comfy.py paint
.\.tools\blender\blender-4.5.4-windows-x64\blender.exe --background --factory-startup --python tools\preview_3d_hunter.py -- prototypes\hunyuan_hunter\mesh\hunter_textured.glb prototypes\hunyuan_hunter\inspection --appearance texture --source-colours linear
py -3 prototypes\hunyuan_hunter\pack_comparison.py
```

## Compatibility fixes

The latest ComfyUI checkout's comfy-kitchen operators were incompatible with Torch 2.6, so this instance is pinned to 0.3.40 and its matching frontend. The wrapper constructed raw filesystem names for dynamic Python imports; `tools/patch_hunyuan_wrapper.py` fixes that using the actual package namespace. The patch is recorded under `patches/`.

The supplied Torch 2.6 rasterizer wheel only included `sm_89` (4090). The 3090 Ti requires `sm_86`; `tools/build_hunyuan_rasterizer.ps1` compiles for 8.6 using the installed CUDA 12.4 and MSVC 14.44, then installs into the private environment. CUDA/MSVC compatibility flags are contained in this extension build only. The kernel was inspected with cuobjdump and exercised on an actual CUDA triangle before texture generation succeeded.

Do not use the unpadded portrait as direct node input: its centre crop produced a headless first attempt. Keep all legitimate disconnected parts during preparation instead of running a largest-component-only floater remover.

## Visual assessment

The new full texture retains eyes, hair colour, scarf, red coat trim and blue armor details more clearly than the previous vertex-colour experiment. Some generated texture flecks and painted lighting remain, and the native 128px output needs cleaner pixel clusters. Geometry, especially fingers and hair, still needs review before rigging. This comparison has not been rigged or integrated into gameplay.

Model weights and third-party source environments are not committed. Refer to the upstream Tencent Hunyuan and wrapper licenses for tool/model terms; this repository records the generated experiment and reproducibility information.
