# Blender Sprite Prototype Implementation Plan

> Execute in this session using executing-plans. No subagent delegation is required for this sequential experiment.

**Goal:** Produce a reviewable local 3D-to-2D rendering experiment and identify the remaining image-to-3D/rigging requirements.

**Architecture:** A pure contract module owns camera calibration, projection coordinates, frame timing, and output packing. A Blender script imports a rig or builds an explicitly labelled fixture and renders matching body/weapon layers with grip metadata. An isolated tool directory contains portable Blender and image-to-3D dependency inspection.

**Tech Stack:** Blender 4.5 LTS, Python, Pillow, local ComfyUI/TRELLIS, Godot SpriteFrames output.

- [x] Install official portable Blender and verify SHA256.
- [x] Inspect TRELLIS Windows wheel/dependency support and create isolated `trellis-env`; run official image-to-mesh model successfully.
- [x] Generate a neutral reference with ChatGPT ImageGen for the image-to-3D stage and save its brief/provenance.
- [x] Add failing mathematical checks for camera framing, projection rounding, 30-to-6-FPS sampling and sRGB conversion; implement the contract.
- [x] Implement `tools/preview_3d_hunter.py` and `tools/rig_hunter_prototype.py` with fixed camera, 128px body rendering, padded weapon layer and two projected grip targets. Generic FBX/clip importing remains outside this first experiment.
- [x] Rig the actual AI-generated mesh with explicitly provisional landmark/distance skinning and one original heavy-cut study. An unrelated fixture is no longer needed now that mesh generation works.
- [x] Package body/weapon layers and metadata without frame-wise renormalization; generate contact sheet and animated preview.
- [x] Render and visually review the actual generated mesh/rig, inspect native-size silhouette, and record what is and is not proven.
- [x] Verify both SpriteFrames resources in a separate Godot project: nine frames, matching 1.333333-second timing. Body feet remain at row 116 across the clip; no body or padded weapon alpha bounds touch the canvas edge.
- [x] Report mesh views, rig diagram, the animated heavy-cut study and remaining art/motion limitations. No user account or manual rig step was necessary for the draft.
