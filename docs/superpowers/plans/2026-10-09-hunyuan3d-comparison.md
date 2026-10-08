# Hunyuan3D-2 Comparison Implementation Plan

> Execute in this session using executing-plans. Follow the user's existing approval; no additional design confirmation or agent delegation is needed.

**Goal:** Generate and show a Hunyuan3D-2 mesh with full paint textures in an isolated ComfyUI environment.

**Architecture:** One project-local ComfyUI instance on port 8189 owns the Hunyuan wrapper, model loader, shape sampler and paint/rasterizer stages. A small runner submits API graphs and saves intermediate/output artifacts. Blender loads the exported textured GLB for flat orthographic previews; a packer compares the 128px output against TRELLIS.

**Tech Stack:** Python 3.12, Torch 2.6.0/CUDA 12.6, ComfyUI, Kijai Hunyuan wrapper, Hunyuan3D-2 Shape and Paint, Blender 4.5.4.

- [x] Clone isolated ComfyUI and wrapper; install Torch and compatible requirements into `hunyuan-env`. Pin ComfyUI 0.3.40 after verifying latest comfy-kitchen incompatibility.
- [x] Install rasterizer/mesh extensions; verify import paths and CUDA. Rebuild rasterizer for sm_86 after detecting that the supplied wheel only had sm_89.
- [x] Start the separate service on loopback 8189 and confirm wrapper nodes load through `/object_info`. Patch dynamic import namespace handling for the `.tools` path.
- [x] Download shape and paint models to the separate environment; save the exact model revisions and graph.
- [x] Run shape generation and export/show the intermediate mesh. Pad input to a square after tracing the first attempt's missing head to the image encoder centre crop.
- [x] Run full texture generation and export the textured GLB; show its preview.
- [x] Render textured front/right/back/left 512px and 128px views at the prior camera scale.
- [x] Package a comparison image, visually inspect faces/hands/outfit and record limitations.
- [x] Save launch instructions and dependency lock. Final verification and commit/push follow.
