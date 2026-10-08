# Hunter 3D-to-2D experiment

The selected master was generated with ChatGPT ImageGen. Official Microsoft TRELLIS generated the mesh locally. Blender rendered the model and a draft rig from that single mesh. The character reference, generated geometry, and render output are original project assets; the draft animation is authored by this experiment.

## View results

- `reference/master_apose_imagegen.png`: selected modelling reference.
- `inspection/contact_sheet.png`: four mesh views and native 128px palette-locked renders.
- `motion/rig_skeleton.png`: actual posed rig with projected bones.
- `motion/heavy_cut_preview.gif`: heavy-cut study with body and weapon layers composited at the same pixel scale.
- `motion/heavy_cut_contact.png`: all nine selected frames.
- `motion/hunter_draft_rig.blend`: generated mesh, draft rig, two hand targets, separate weapon, and authored motion.
- `motion/sprites/*`: body/weapon PNG sequences, packed sheets, animation JSON, and SpriteFrames resources.

The prototype folder is excluded from the main Godot project's automatic import through `.gdignore`. Resources are validated in a separate small Godot project. Promotion into `art/` and gameplay integration is a separate step after visual review.

## Isolated tooling

Python: `D:\Projects\MH-Clone\.tools\trellis-env\Scripts\python.exe`, CPython 3.12.10. System site packages are disabled. Torch 2.5.1+cu124, torchvision 0.20.1+cu124, xFormers 0.0.28.post3, spconv-cu124 2.3.8, Kaolin 0.17.0, Transformers 4.46.3 and Open3D 0.19.0 are installed in that environment. All installed versions are captured in `requirements-trellis.lock`.

Blender: official portable 4.5.4 LTS under `.tools/blender`, verified against the official SHA256. Existing ComfyUI Python, Torch, custom nodes, and models were not modified.

Official TRELLIS source commit: `442aa1e1afb9014e80681d3bf604e8d728a86ee7`. Model revision: `25e0d31ffbebe4b5a97464dd851910efc3002d96`. The selected mesh decoder includes vertex colours, so Gaussian texture-baking dependencies are unnecessary for this study. Models and caches live under `.tools`.

## Reproduce on this workstation

```powershell
.\.tools\trellis-env\Scripts\python.exe tools\generate_3d_hunter.py
.\.tools\blender\blender-4.5.4-windows-x64\blender.exe --background --factory-startup --python tools\preview_3d_hunter.py -- prototypes\blender_hunter\mesh\hunter_trellis_vertexcolor.glb prototypes\blender_hunter\inspection
py -3 prototypes\blender_hunter\pack_inspection.py
.\.tools\blender\blender-4.5.4-windows-x64\blender.exe --background prototypes\blender_hunter\inspection\hunter_inspection.blend --python tools\rig_hunter_prototype.py -- prototypes\blender_hunter\motion
py -3 prototypes\blender_hunter\pack_motion.py
```

## What this proves

One ImageGen image can become a local mesh and render as consistently shaped sprites. Two hand targets can remain attached to an interchangeable weapon. The fixed camera preserves ground row 116 in every rendered frame. The weapon uses a padded 256px layer with local offset [-64,-64], avoiding clipping while preserving the body's 128px pixel scale. The palette is shared across layers and frames. Per-frame timing is preserved in the Godot resource, including the short impact frame.

## What still needs work

The mesh has 281,704 triangles and has not been retopologized. The rig uses approximate landmarks and distance weights; shoulder and hand deformation still need review. The legs are stationary and the torso only has a small lean, so the cut does not yet have the intended Great Cleaver weight. Face/hands and pixel colour clusters need art cleanup. This is a renderer/rig feasibility experiment, not final game animation.
