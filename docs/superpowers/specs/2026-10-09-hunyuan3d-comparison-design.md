# Hunyuan3D-2 Shape and Paint Comparison

The user approved a second image-to-3D comparison, using Hunyuan3D-2 through a separate ComfyUI environment. Reuse the selected ChatGPT ImageGen A-pose master without redesigning it. Generate shape and a full texture, export a GLB, render front/right/back/left views and 128px game-sized previews, and show the actual results after each major stage.

## Isolation

ComfyUI source and its Hunyuan wrapper live under `.tools/comfy-hunyuan`. CPython 3.12 and all Python packages live in `.tools/hunyuan-env`, with system site packages disabled. Start that interpreter on loopback port 8189. Existing ComfyUI on 8188, its embedded interpreter, custom nodes and model directories must not be modified. Put Hunyuan model/cache/input/output data under the new project-local tool directories. Use Torch 2.6.0/CUDA 12.6 to match the wrapper's provided Windows rasterizer wheel; if a binary is incompatible, compile it within this environment or report the actual failure.

## Comparison

Run the 2.0 shape model and 2.0 paint stage, not a shape-only or vertex-colour substitute. Save the untextured mesh as an intermediate artifact so shape completion can be inspected independently of paint. Save workflow graphs, parameters, seeds, upstream commits and package versions. The textured preview must use the exported UV/base-color texture with flat lighting; it must not use Blender's vertex-colour-only workbench path. Keep orthographic camera scale and ground alignment equivalent to the TRELLIS comparison. Save a combined native-size comparison with the previous render.

## Completion

A valid textured GLB, saved source image/workflow, four rendered views, a 128px preview/comparison, and repeatable launch instructions are required. A running server alone is not completion. Report geometry, face/hand detail, texture readability, and any remaining mismatch with the selected master. Rig and runtime integration are outside this comparison; those begin only after seeing the new art.
